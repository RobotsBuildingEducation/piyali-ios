// Render the original Reading feedback subtree with fixed private QA data.
// No source edits, learner identity, provider requests or product state are used.
import fs from 'node:fs/promises';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {createServer} from 'node:http';
import {gunzipSync} from 'node:zlib';
import {createHash} from 'node:crypto';
import {readingPolicyFragments} from './reading-policy-fragments.mjs';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..'),reference=path.resolve(root,'../nosabos/nosabos'),output=path.join(root,'.reference-preview/reading-feedback');
const parser=await import(path.join(reference,'node_modules/@babel/parser/lib/index.js')),traversal=await import(path.join(reference,'node_modules/@babel/traverse/lib/index.js')),traverse=traversal.default.default??traversal.default,esbuild=await import(path.join(reference,'node_modules/esbuild/lib/main.js'));
const file=path.join(reference,'src/components/History.jsx'),source=await fs.readFile(file,'utf8'),ast=parser.parse(source,{sourceType:'module',plugins:['jsx']}),policy=readingPolicyFragments({source,parser,traverse});
let feedback;const declarations=[];
traverse(ast,{JSXElement(p){const n=p.node.openingElement;if(n.name.name==='Box'&&n.attributes.some(a=>a.name?.name==='role'&&a.value?.value==='status')&&n.attributes.some(a=>a.name?.name==='aria-live'&&a.value?.value==='polite')) { if(feedback) throw Error('Ambiguous source feedback');feedback=source.slice(p.node.start,p.node.end); }},VariableDeclarator(p){if(p.node.id.name?.startsWith('paper')||p.node.id.name==='speechAccentMap') declarations.push('const '+source.slice(p.node.start,p.node.end)+';');}});
if(!feedback||declarations.length!==11) throw Error('Source feedback moved; review the rendering fixture.');
const fixture=JSON.parse(gunzipSync(await fs.readFile(path.join(root,'Piyali/Resources/reading-test-passage.json.gz'))));
const relative=p=>JSON.stringify(path.join(reference,p));
const entry=`import React from 'react';import {createRoot} from 'react-dom/client';import {ChakraProvider,Box,VStack,HStack,Flex,Text,Grid,GridItem} from '@chakra-ui/react';import {theme} from ${relative('src/theme.js')};import {translations} from ${relative('src/utils/translation.jsx')};import RandomCharacter from ${relative('src/components/RandomCharacter.jsx')};import {WaveBar} from ${relative('src/components/WaveBar.jsx')};import {questionSquircleStyle} from ${relative('src/components/questionUiStyles.js')};
const params=new URLSearchParams(location.search),isLightTheme=params.get('theme')!=='dark',supportLang=params.get('language')||'en';const speechFeedback=${JSON.stringify(fixture.speechFeedback)},SPEECH_CRITERIA=${policy.criteria};${policy.color}
${declarations.join('\n')}
const t=key=>translations[supportLang]?.[key]??translations.en[key]??'',lessonProgress=params.has('lesson')?{pct:25,total:80,label:t('vocab_lesson_progress')}:null;
function Fixture(){return <ChakraProvider theme={{...theme,config:{initialColorMode:isLightTheme?'light':'dark',useSystemColorMode:false}}}><Box minH="100dvh" bg={isLightTheme?'#f5efe3':'#0f172a'} color={isLightTheme?paperText:'#e5e7eb'} px="12px" pt="12px" id="source-reading-feedback">${feedback}</Box></ChakraProvider>};createRoot(document.getElementById('root')).render(<Fixture/>);`;
await fs.mkdir(output,{recursive:true});
await esbuild.build({stdin:{contents:entry,sourcefile:'source-reading-feedback.jsx',resolveDir:reference,loader:'jsx'},jsx:'automatic',bundle:true,platform:'browser',format:'esm',target:'es2020',outdir:output,entryNames:'feedback',assetNames:'assets/[name]-[hash]',loader:{'.webp':'file','.png':'file','.svg':'file'},define:{'process.env.NODE_ENV':'"production"'},logLevel:'error'});
for(const weight of [400,500,600,700]) await fs.copyFile(path.join(root,`Piyali/Resources/Brand/DMSans-${weight}.ttf`),path.join(output,`DMSans-${weight}.ttf`));
const fontFaces=[400,500,600,700].map(weight=>`@font-face{font-family:"DM Sans";font-weight:${weight};src:url("/DMSans-${weight}.ttf")}`).join('');
await fs.writeFile(path.join(output,'index.html'),'<!doctype html><html><head><meta name="viewport" content="width=device-width,initial-scale=1"><style>'+fontFaces+'body,*{font-family:"DM Sans",sans-serif!important}body{margin:0}</style></head><body><div id="root"></div><script>if(!new URLSearchParams(location.search).has("frame")){const f=document.createElement("iframe");f.src="/?frame=1&"+location.search.slice(1);f.style="width:402px;height:874px;border:0;display:block";document.getElementById("root").append(f)}else{const s=document.createElement("script");s.type="module";s.src="/feedback.js";document.body.append(s)}</script></body></html>');
const sources=await Promise.all(['src/components/History.jsx','src/components/RandomCharacter.jsx','src/components/WaveBar.jsx','src/components/questionUiStyles.js','src/theme.js','src/utils/translation.jsx'].map(async file=>({file,sha256:createHash('sha256').update(await fs.readFile(path.join(reference,file))).digest('hex')})));
await fs.writeFile(path.join(output,'manifest.json'),JSON.stringify({sources,scope:'Original speech-feedback JSX subtree and original theme/copy/assets; fixed QA feedback, no learner/provider account',viewport:{width:402,height:874},savedCaptureCrop:{width:402,height:420}},null,2)+'\n');
console.log('Original Reading feedback fixture: http://127.0.0.1:5182');
if(process.argv.includes('--serve')) createServer(async(req,res)=>{try{const requested=new URL(req.url,'http://localhost').pathname,filename=path.join(output,requested==='/'?'index.html':requested);if(!filename.startsWith(output+path.sep)) throw Error();const data=await fs.readFile(filename);res.setHeader('Content-Type',filename.endsWith('.js')?'text/javascript':filename.endsWith('.html')?'text/html':filename.endsWith('.webp')?'image/webp':'application/octet-stream');res.end(data);}catch{res.statusCode=404;res.end('Not found');}}).listen(5182,'127.0.0.1');
