import fs from'node:fs/promises';import path from'node:path';
export function rpgFixture(root,reference){const entry=path.join(reference,'__piyali-rpg.jsx');return{name:'piyali-rpg-reference',enforce:'pre',resolveId(id,importer){
 if(id==='/__piyali-rpg.jsx')return entry;
 const game=importer?.endsWith('/RPGGame/index.jsx');
 if(game&&id.endsWith('/HelpChatFab'))return '\0rpg-help';
 if(game&&id.endsWith('/useUserStore'))return '\0rpg-user';
 if(game&&id.endsWith('/useSoundSettings'))return '\0rpg-sound';
 if(game&&id.endsWith('/useSpeechPractice'))return '\0rpg-speech';
 if(game&&id.endsWith('/tts'))return '\0rpg-tts';
 if((game||importer?.endsWith('/RPGGame/scenarios.js'))&&id.endsWith('/llm'))return '\0rpg-llm';
 if(game&&id==='firebase/firestore')return '\0rpg-firestore';
 if(game&&id.endsWith('/firebaseResources'))return '\0rpg-firebase';
},transform(code,id){if(id.split('?')[0]!==path.join(reference,'src/components/RPGGame/index.jsx'))return null;const marker='const seed = Date.now();';if(code.split(marker).length!==2)throw Error('RPG art clock moved; review fixture adapter');let fixture=code.replace(marker,'const seed = 1792936800000; /* fixed art clock for source/native captures */');
 const ambient='const ambientTime = time * 0.001;';if(fixture.split(ambient).length!==2)throw Error('Main ambient frame loop moved');fixture=fixture.replace(ambient,"const ambientTime = new URLSearchParams(location.search).has('environmentTime') ? Number(new URLSearchParams(location.search).get('environmentTime')) : time * 0.001;");
 const render='      renderer.render(scene, camera);';if(fixture.split(render).length!==2)throw Error('Main render loop moved');return fixture.replace(render,"      if (new URLSearchParams(location.search).get('environmentOnly') === '1') { window.__piyaliEnvironmentPosition={x:gs.playerX,y:gs.playerY};playerSprite.visible=false; npcSprites.forEach(s=>{if(s)s.visible=false});npcIndicators.forEach(s=>{if(s)s.visible=false}); }\n"+render);},async load(id){if(id===entry)return fs.readFile(path.join(root,'scripts/reference-rpg.jsx'),'utf8');
 if(id==='\0rpg-help')return 'export default ()=>null;';
 if(id==='\0rpg-user')return `const lang=new URLSearchParams(location.search).get('language')||'en';const state={user:{progress:{targetLang:'es',supportLang:lang},dailyGoalPetType:'ghost',xp:0},patchUser:async()=>{}};export const useUserStore=selector=>selector(state);useUserStore.getState=()=>state;useUserStore.setState=()=>{};export default useUserStore;`;
 if(id==='\0rpg-sound')return 'const state={playSound:()=>{},warmupAudio:async()=>{},soundEnabled:false};const hook=f=>f(state);hook.getState=()=>state;export default hook;';
 if(id==='\0rpg-speech')return 'export const useSpeechPractice=()=>({startRecording:async()=>{},stopRecording:()=>{},isRecording:false,isConnecting:false,isEvaluating:false,stream:null,supportsSpeech:false});';
 if(id==='\0rpg-firestore')return 'export const doc=()=>({}),setDoc=async()=>{};';
 if(id==='\0rpg-firebase')return 'export const database={},simplemodel={generateContent:async()=>{throw Error("Provider disabled in source RPG fixture")}};';
 if(id==='\0rpg-llm')return 'export const callResponses=async()=>{throw Error("Provider disabled in source RPG fixture")};';
 if(id==='\0rpg-tts')return `export const createWarmTTSAudio=()=>null,getTTSPlayer=async()=>({audio:{addEventListener(){},removeEventListener(){},play:async()=>{},pause(){}},ready:Promise.resolve(),finalize:Promise.resolve(),cleanup(){}}),startTTSPlayback=()=>{},TTS_LANG_TAG={es:'es-ES',en:'en-US',ar:'ar'},getCharacterVoice=()=>'',getCharacterPersonality=()=>'',getPreferredTTSVoice=()=>'';`;
},configureServer(server){
 server.middlewares.use('/__piyali-rpg-fixture.json',async(req,res)=>{res.setHeader('Content-Type','application/json');res.end(await fs.readFile(path.join(root,'.reference-preview/rpg-reference.json'),'utf8'))});
 server.middlewares.use('/__piyali-rpg',async(req,res,next)=>{if((req.originalUrl||req.url).split('?')[0].endsWith('.jsx'))return next();const html=await server.transformIndexHtml('/__piyali-rpg',`<!doctype html><html><head><meta name="viewport" content="width=device-width,initial-scale=1"><style>html,body,#root{margin:0;width:100%;height:100%;overflow:hidden}</style></head><body><div id="root"></div><script>const originalFetch=window.fetch.bind(window);window.fetch=(input,...args)=>{const url=new URL(typeof input==='string'?input:input.url,location.href);if(url.hostname!=='127.0.0.1')return Promise.reject(Error('External I/O disabled in source RPG fixture'));return originalFetch(input,...args)};const OriginalSocket=window.WebSocket;window.WebSocket=class extends OriginalSocket{constructor(url,...args){if(new URL(url,location.href).hostname!=='127.0.0.1')throw Error('External relay disabled in source RPG fixture');super(url,...args)}};</script><script type="module" src="/__piyali-rpg.jsx"></script></body></html>`);res.setHeader('Content-Type','text/html');res.end(html)});
}}}
