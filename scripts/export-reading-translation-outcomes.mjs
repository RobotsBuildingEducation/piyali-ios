// Execute History's actual translation callback with public, in-memory provider outcomes.
import fs from 'node:fs/promises';import path from 'node:path';import vm from 'node:vm';import {createRequire} from 'node:module';import {createHash} from 'node:crypto';
const root=process.cwd(),reference=path.resolve(root,'../nosabos/nosabos'),require=createRequire(path.join(reference,'package.json')),{parse}=require('@babel/parser'),traverse=require('@babel/traverse').default;
const file='src/components/History.jsx',source=await fs.readFile(path.join(reference,file),'utf8'),names=['LANG_NAME','splitIntoSentences','translateLectureLines'],found=new Map();
traverse(parse(source,{sourceType:'module',plugins:['jsx']}),{FunctionDeclaration(p){if(names.includes(p.node.id.name))found.set(p.node.id.name,source.slice(p.node.start,p.node.end))},VariableDeclarator(p){if(names.includes(p.node.id.name))found.set(p.node.id.name,`const ${p.node.id.name}=${source.slice(p.node.init.start,p.node.init.end)};`)}});
const code=names.map(n=>{if(!found.has(n))throw Error('Source translation binding moved: '+n);return found.get(n)}).join('\n');
const cases=[
 {name:'complete',chunks:['1. One.\n2) Two.\n','3: Three.']},
 {name:'incomplete',chunks:['One.\nTwo.\n']},
 {name:'empty',chunks:['\n  \n']},
 {name:'extra-lines',chunks:['One.\nTwo.\nThree.\nFour.\n']},
 {name:'throw-after-line',chunks:['One.\n'],fail:true},
 {name:'throw-after-all-lines',chunks:['One.\nTwo.\nThree.\n'],fail:true},
 {name:'throw-before-line',chunks:[],fail:true},
 {name:'throw-unterminated-line',chunks:['One.'],fail:true},
 {name:'no-provider',chunks:[],noProvider:true},
 {name:'incomplete-with-support',chunks:['Partial.\n'],support:'One. Two. Three.'},
 {name:'throw-with-support',chunks:['Partial.\n'],support:'One. Two. Three.',fail:true},
 {name:'incomplete-bad-support',chunks:['Partial.\n'],support:'Only one.'},
 {name:'throw-bad-support',chunks:['Partial.\n'],support:'Only one.',fail:true}
];
const rows=[];for(const input of cases){const state={loading:false,visible:false,lines:null},trace=[],record=()=>trace.push(JSON.parse(JSON.stringify(state)));let requests=0;
 const ctx=vm.createContext({viewLecture:{id:'fixture',target:'Una. Dos. Tres.',support:input.support||''},targetSentences:['Una.','Dos.','Tres.'],targetLang:'es',supportLang:'en',isTranslatingLecture:false,lineTranslationsByLecture:{},
 setIsTranslatingLecture:value=>{state.loading=value;record()},setTranslationsVisibleByLecture:update=>{state.visible=update({fixture:state.visible}).fixture;record()},setLineTranslationsByLecture:update=>{state.lines=update(state.lines?{fixture:state.lines}:{}).fixture??null;record()},
 simplemodel:input.noProvider?null:{generateContentStream:async()=>{requests++;return {stream:(async function*(){for(const chunk of input.chunks)yield{text:()=>chunk};if(input.fail)throw Error('public fixture failure')})()}}},textFromChunk:x=>x.text(),console:{error(){}}});
 await vm.runInContext(code+'\ntranslateLectureLines()',ctx);rows.push({input,expected:{...state,requests,trace}});
}
const json=JSON.stringify(rows,null,2)+'\n';await fs.writeFile(path.join(root,'Tests/PiyaliCoreTests/Fixtures/reading-translation-outcomes.json'),json);await fs.writeFile(path.join(root,'Tests/PiyaliAppTests/Fixtures/reading-translation-outcomes.json'),json);
await fs.writeFile(path.join(root,'docs/reference/reading-translation-outcomes-manifest.json'),JSON.stringify({source:{file,sha256:createHash('sha256').update(source).digest('hex')},cases:rows.length,scope:'Original translateLectureLines, LANG_NAME and sentence splitter executed with synthetic provider chunks and in-memory setters. Source support fallback cases are conditional; current main-product creation paths set support to an empty string.'},null,2)+'\n');
console.log(rows.map(r=>`${r.input.name}: lines=${r.expected.lines?.length||0} visible=${r.expected.visible} requests=${r.expected.requests}`).join('\n'));
