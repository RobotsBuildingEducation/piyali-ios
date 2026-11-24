// Execute the original source's advance/finish closures with a revealed episode.
import fs from 'node:fs/promises';import path from 'node:path';import vm from 'node:vm';import assert from 'node:assert/strict';import {createHash} from 'node:crypto';import {createRequire} from 'node:module';
const ref=path.resolve(process.argv[2]||'../nosabos/nosabos'),file='src/features/stories/StoryComprehension.jsx',source=await fs.readFile(path.join(ref,file),'utf8');
const require=createRequire(path.join(ref,'package.json')),{parse}=require('@babel/parser'),traverse=require('@babel/traverse').default,closures={};
traverse(parse(source,{sourceType:'module',plugins:['jsx']}),{VariableDeclarator(p){if(['advance','finish'].includes(p.node.id.name)&&p.node.init?.type==='ArrowFunctionExpression')closures[p.node.id.name]=source.slice(p.node.init.start,p.node.init.end)}});
assert.ok(closures.advance&&closures.finish,'Original Story closures moved');
for(const [part,count,expected] of [[0,1,true],[0,2,false],[1,2,true]]) {
 let awards=0,skips=0,next=null;const savingRef={current:false},awarded={current:false};
 const ctx=vm.createContext({episode:{segments:Array(count).fill({})},part,score:1,npub:'public-fixture',targetLang:'es',supportLang:'en',mode:'radio',lesson:{id:'fixture'},savingRef,awarded,mounted:{current:true},services:{award:async()=>{awards++},log:async()=>{}},stop(){},setSaving(){},setSaveError(){},playSound(){},completeSound:null,nextButtonSound:null,setReward(){},onSkip(){skips++},onNewStory:null,restart(){},console,setIsReplaying(){},setPart(n){next=n},setSelected(){},setResult(){},setSpeechResult(){},setHeard(){},setQuestionVisible(){},setAudioError(){},startSegment(){}});
 vm.runInContext(`const finish=${closures.finish};const advance=${closures.advance};advance();`,ctx);await new Promise(resolve=>setImmediate(resolve));
 assert.equal(awards,expected?1:0);assert.equal(skips,expected?1:0);assert.equal(next,expected?null:part+1);
 console.log(`part ${part+1}/${count}: ${expected?'award 6 and finish':'advance without award'}`);
}
console.log(`source SHA-256 ${createHash('sha256').update(source).digest('hex')}`);
