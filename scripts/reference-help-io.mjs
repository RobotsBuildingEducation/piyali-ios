import fs from 'node:fs/promises';import path from 'node:path';
export function helpFixture(root,reference){const entry=path.join(reference,'__piyali-help.jsx');return {name:'piyali-source-help',enforce:'pre',resolveId(id,importer){
 if(id==='/__piyali-help.jsx')return entry;
 if(!importer?.endsWith('/HelpChatFab.jsx'))return;
 if(id.endsWith('/firebaseResources'))return '\0piyali-help-ai';
 if(id.endsWith('/tts'))return '\0piyali-help-tts';
 if(id.endsWith('/useSoundSettings'))return '\0piyali-help-sound';
},async load(id){
 if(id===entry)return fs.readFile(path.join(root,'scripts/reference-help.jsx'),'utf8');
 if(id==='\0piyali-help-ai')return String.raw`const reply=()=>new URLSearchParams(location.search).get('language')==='ar'?'استخدم **hermana** للكلام عن أختك.\n// Mi hermana vive aquí.':'Use **hermana** to talk about your sister.\n// Mi hermana vive aquí.';export const simplemodel={generateContent:async()=>({response:{text:()=>JSON.stringify({translation:'sister',targetText:'hermana'})}}),generateContentStream:async()=>({stream:(async function*(){yield{text:()=>reply()};})()})},appCheckFetch=async()=>{throw Error('Voice disabled in public Help fixture')};`;
 if(id==='\0piyali-help-tts')return `export const TTS_LANG_TAG={es:'es-ES',en:'en-US'},getPreferredTTSVoice=()=> 'ash',getTTSPlayer=async()=>{throw Error('Playback disabled in public Help fixture')},startTTSPlayback=()=>{};`;
 if(id==='\0piyali-help-sound')return 'export default select=>select({playSound:()=>{}});';
},configureServer(server){server.middlewares.use('/__piyali-help',async(req,res,next)=>{if((req.originalUrl||req.url).split('?')[0].endsWith('.jsx'))return next();const html=await server.transformIndexHtml('/__piyali-help',`<!doctype html><html><head><meta name="viewport" content="width=device-width,initial-scale=1"><style>html,body,#root{margin:0;width:100%;height:100%;overflow:hidden}</style></head><body><div id="root"></div><script>const originalFetch=window.fetch.bind(window);window.fetch=(input,...args)=>{const url=new URL(typeof input==='string'?input:input.url,location.href);if(url.hostname!=='127.0.0.1')return Promise.reject(Error('External I/O disabled in source Help fixture'));return originalFetch(input,...args)};window.RTCPeerConnection=class{constructor(){throw Error('Voice disabled in source Help fixture')}};window.WebSocket=class{constructor(){throw Error('Relay disabled in source Help fixture')}};</script><script type="module" src="/__piyali-help.jsx"></script></body></html>`);res.setHeader('Content-Type','text/html');res.end(html)})}}}
