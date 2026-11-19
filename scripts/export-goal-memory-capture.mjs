// Execute the original complete capture callback until its Goal return / ordinary-clean boundary.
import fs from'node:fs/promises';import path from'node:path';import vm from'node:vm';import{createRequire}from'node:module';import{createHash}from'node:crypto';
const ref=path.resolve('../nosabos/nosabos'),req=createRequire(path.join(ref,'package.json')),{parse}=req('@babel/parser'),sourceFile='src/utils/companionMemory.js',source=await fs.readFile(path.join(ref,sourceFile),'utf8'),ast=parse(source,{sourceType:'module'});let callback;
for(const n of ast.program.body){const f=n.declaration;if(f?.type==='FunctionDeclaration'&&f.id.name==='captureCompanionMemory')callback=source.slice(f.start,f.end)}if(!callback)throw Error('Capture callback moved');
const policy=vm.runInNewContext((await fs.readFile('Piyali/Resources/companion-quest-policy.js','utf8'))+';PiyaliCompanionQuest');
const now='2026-11-05T12:00:00.000Z',blueprint={goalId:'goal-memory',dayKey:'2026-11-05',lang:'es',mode:'lesson',modes:['lesson','tutor']},focus={npub:'public-goal-learner',targetLang:'es',blueprint};
const rows=[];
for(const sample of [
 {name:'vocabulary',mode:'vocabulary',concept:'Match the items:',answer:'hola → goodbye',expected:'Check the correct pairings'},
 {name:'grammar',mode:'grammar',concept:'Use agreement',answer:'Yo somos',expected:'Yo soy'},
 {name:'reading',mode:'reading',concept:'Where is Ana?',answer:'The park',expected:'At home'},
 {name:'story',mode:'story',concept:'Hola, mamá.',answer:'Adiós',expected:'Hola, mamá.'},
 {name:'conversation-explicit-npub',mode:'conversation',concept:'Greet a relative',answer:'No sé',expected:'Hola'},
 {name:'empty-answer',mode:'grammar',concept:'A mystery word',answer:'',expected:'paraguas'},
 {name:'whitespace-answer',mode:'grammar',concept:'A mystery word',answer:' ',expected:'paraguas'},
 {name:'missing-npub-flashcard',mode:'flashcard',concept:'hola',answer:'ola',expected:'',omitNpub:true},
 {name:'missing-npub-conversation',mode:'conversation',concept:'Greet a relative',answer:'No sé',expected:'Hola',omitNpub:true},
 {name:'trimmed-concept',mode:'grammar',concept:'  Use agreement  ',answer:'Yo somos',expected:'Yo soy'},
 {name:'empty-concept',mode:'grammar',concept:'   ',answer:'wrong',expected:'Hola'},
 {name:'ordinary',mode:'vocabulary',concept:'hola',answer:'ola',expected:'hola',ordinary:true}]){
 let event,route;class Clock extends Date{constructor(...args){super(...(args.length?args:[now]))}static now(){return new Date(now).getTime()}}
 const ctx={Date:Clock,console:{warn(){}},currentGoalFocus:()=>sample.ordinary?null:focus,normalizePlateLang:x=>x,recordLearningEvidence:async input=>{event=input.event;route='goal'},recordGradedOutcome:async()=>{},normalizeMemorySupportLang:x=>x,cleanMemoryConceptForSupportLanguage:()=>{route='repairs';return''},resolveNpub:x=>x};
 vm.runInNewContext(callback,ctx);const input={targetLang:'es',supportLang:'en',sourceMode:sample.mode,concept:sample.concept,userAnswer:sample.answer,expectedAnswer:sample.expected,cefrLevel:'A1',gradedOutcome:false};if(!sample.omitNpub)input.npub=focus.npub;
 await ctx.captureCompanionMemory(input);
 const summary=event?JSON.parse(policy.run('goalEvidence',JSON.stringify({summary:{},event,now}))):null;
 rows.push({name:sample.name,input,focus:sample.ordinary?null:focus,route,event:event??null,summary,now});
}
const callers=[];for(const file of ['src/components/Vocabulary.jsx','src/components/GrammarBook.jsx','src/components/DelightQuestionLab.jsx','src/components/History.jsx','src/components/Stories.jsx','src/components/FlashcardPractice.jsx','src/components/RealTimeTest.jsx']){const text=await fs.readFile(path.join(ref,file),'utf8'),tree=parse(text,{sourceType:'module',plugins:['jsx']}),calls=[];function walk(node){if(!node||typeof node!=='object')return;if(node.type==='CallExpression'&&node.callee?.name==='captureCompanionMemory'){const arg=node.arguments[0];if(arg?.type==='ObjectExpression')calls.push({npub:arg.properties.some(p=>p.key?.name==='npub'),sourceMode:arg.properties.find(p=>p.key?.name==='sourceMode')?.value.value??'expression'})}for(const value of Object.values(node)){if(Array.isArray(value))value.forEach(walk);else if(value&&typeof value==='object')walk(value)}}walk(tree);callers.push({file,sha256:createHash('sha256').update(text).digest('hex'),calls})}
const summaryFile='src/utils/learningIntelligenceModel.js',summarySource={file:summaryFile,sha256:createHash('sha256').update(await fs.readFile(path.join(ref,summaryFile),'utf8')).digest('hex')},policySha256=createHash('sha256').update(await fs.readFile('Piyali/Resources/companion-quest-policy.js','utf8')).digest('hex');
await fs.writeFile('Tests/PiyaliCoreTests/Fixtures/goal-memory-capture.json',JSON.stringify(rows,null,2)+'\n');await fs.writeFile('docs/reference/goal-memory-capture-manifest.json',JSON.stringify({sourceFile,callers,summarySource,policySha256,sha256:createHash('sha256').update(source).digest('hex'),cases:rows.length,scope:'Full original captureCompanionMemory callback executed with explicit currentGoalFocus snapshots, clock and recording learning-evidence boundary. Ordinary-path cleaning is a recording stop boundary; no store, enrichment, provider or Firebase runs. Summary uses the original extracted mergeEvidence/compactSummary.'},null,2)+'\n');console.log('Source Goal capture cases:',rows.length);
