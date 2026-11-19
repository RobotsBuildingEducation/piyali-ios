import fs from 'node:fs/promises';
import path from 'node:path';
import vm from 'node:vm';
import {createRequire} from 'node:module';
import {createHash} from 'node:crypto';
const ref=path.resolve(process.cwd(),'../nosabos/nosabos'),file='src/components/Stories.jsx',source=await fs.readFile(path.join(ref,file),'utf8');
const require=createRequire(path.join(ref,'package.json')),{parse}=require('@babel/parser'),traverse=require('@babel/traverse').default;
let callback;traverse(parse(source,{sourceType:'module',plugins:['jsx']}),{VariableDeclarator(p){if(p.node.id.name==='tryConsumeLine' && source.slice(p.node.init.start,p.node.init.end).includes('collectedSentences')){if(callback)throw Error('Duplicate callback');callback=source.slice(p.node.init.start,p.node.init.end)}}});
if(!callback)throw Error('Story callback not found');
const cases=[['{"type":"sentence","character":"Sheilfer","tgt":"Hola,',' ¿cómo estás?","sup":"Hello","gender":"female"}\n','{broken}\n{"type":"sentence","character":"Fernanda","tgt":"Muy bien."}\n','{"type":"sentence","tgt":"Hasta luego."}'],['```json\n{"type":"sentence","tgt":"مرحبا"}\n','{"type":"done"}\n','{"type":"sentence","character":"Fernanda","tgt":"أهلاً"}\n']];
const rows=[];for(const chunks of cases){const ctx=vm.createContext({cefrLevel:'A1',worth:2,setIsLoading:()=>{},setStoryType:()=>{},setStoryData:x=>{ctx.current=typeof x==='function'?x(ctx.current):x}});vm.runInContext(`let revealed=false;const collectedSentences=[];const tryConsumeLine=${callback};globalThis.consume=tryConsumeLine;`,ctx);let buffer='',snapshot='';for(const chunk of chunks){buffer+=chunk;snapshot+=chunk;let n;while((n=buffer.indexOf('\n'))!==-1){ctx.consume(buffer.slice(0,n));buffer=buffer.slice(n+1)}rows.push({snapshot,expected:ctx.current?.sentences||[]})}if(buffer.trim()){ctx.consume(buffer.trim());rows.push({snapshot,includeTrailing:true,expected:ctx.current?.sentences||[]})}}
await fs.writeFile('Tests/PiyaliCoreTests/Fixtures/story-stream.json',JSON.stringify(rows,null,2)+'\n');
await fs.writeFile('docs/reference/story-stream-manifest.json',JSON.stringify({source:file,sha256:createHash('sha256').update(source).digest('hex'),cases:rows.length,scope:'Original Speak tryConsumeLine callback executed with in-memory React setters; no provider, browser, or reward assessment.'},null,2)+'\n');console.log(`Exported ${rows.length} source streaming snapshots.`);
