// Execute only the original text preparation expressions; never import provider, UI or stores.
import fs from 'node:fs/promises';
import path from 'node:path';
import vm from 'node:vm';
import {createRequire} from 'node:module';
import {createHash} from 'node:crypto';
const root=process.cwd(),reference=path.resolve(root,'../nosabos/nosabos');
const require=createRequire(path.join(reference,'package.json')),{parse}=require('@babel/parser'),traverse=require('@babel/traverse').default;
const cases=[],sources=[];
for(const [module,file]of [['vocabulary','src/components/Vocabulary.jsx'],['grammar','src/components/GrammarBook.jsx']]){
 const source=await fs.readFile(path.join(reference,file),'utf8'),ast=parse(source,{sourceType:'module',plugins:['jsx']}),expressions={};
 traverse(ast,{VariableDeclarator(p){const kind={handlePlayQuestionTTS:'question',handlePlayMatchWordTTS:'word',handleToggleSpeakPlayback:'spoken'}[p.node.id.name];if(!kind)return;const callback=p.node.init.arguments[0],name=kind==='spoken'?'text':'ttsText',declaration=callback.body.body.find(s=>s.type==='VariableDeclaration'&&s.declarations.some(d=>d.id.name===name)),init=declaration.declarations.find(d=>d.id.name===name).init;expressions[kind]=source.slice(init.start,init.end)}});
 if(Object.keys(expressions).length!==3)throw Error('Missing original audio expressions: '+module);
 for(const [kind,expression]of Object.entries(expressions))for(const input of[null,'','  Yo ___ pan.  ','uno___dos___tres','مرحباً، كيف حالك؟','こんにちは',' \n casa \t','\uFEFFhola\uFEFF','\u0085hola\u0085']){
  const output=vm.runInNewContext(expression,{text:input,sTarget:input});cases.push({module,kind,input,output});
 }
 sources.push({file,sha256:createHash('sha256').update(source).digest('hex'),expressions});
}
const tts=await fs.readFile(path.join(reference,'src/utils/tts.js'),'utf8');sources.push({file:'src/utils/tts.js',sha256:createHash('sha256').update(tts).digest('hex'),narrationPolicy:'The existing companion-quest export retains original narrationSession, locale map and voice sanitization. Main lesson callers use getPreferredTTSVoice() with no override, default ash.'});
for(const file of ['node_modules/@chakra-ui/react/dist/esm/spinner/spinner.mjs','node_modules/@chakra-ui/theme/dist/esm/components/spinner.mjs']){const source=await fs.readFile(path.join(reference,file),'utf8');sources.push({file,sha256:createHash('sha256').update(source).digest('hex'),scope:'Installed reference spinner implementation/theme: xs sizes.3, 2px half ring and 0.45s linear rotation.'})}
await fs.writeFile('Tests/PiyaliAppTests/Fixtures/lesson-audio-text.json',JSON.stringify(cases));
await fs.writeFile('docs/reference/lesson-audio-source-manifest.json',JSON.stringify({sources,cases:cases.length,scope:'Original pure preparation expressions before provider I/O; native receive-only transport owns question cancellation and playout.'},null,2)+'\n');
console.log(cases.length+' original lesson audio text cases');
