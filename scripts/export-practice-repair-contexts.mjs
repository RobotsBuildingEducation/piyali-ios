// Execute original repair snapshots and capture argument objects; reference stays read-only.
import fs from 'node:fs/promises';import path from 'node:path';import vm from 'node:vm';import{createRequire}from'node:module';import{createHash}from'node:crypto';
const ref=path.resolve('../nosabos/nosabos'),req=createRequire(path.join(ref,'package.json')),{parse}=req('@babel/parser'),traverse=req('@babel/traverse').default,sources={};
for(const[module,file]of Object.entries({delight:'src/components/DelightQuestionLab.jsx',vocabulary:'src/components/Vocabulary.jsx',grammar:'src/components/GrammarBook.jsx'})){
 const source=await fs.readFile(path.join(ref,file),'utf8'),ast=parse(source,{sourceType:'module',plugins:['jsx']}),snapshots={};let extract,capture;
 traverse(ast,{FunctionDeclaration(p){if(p.node.id?.name==='extractDelightMemoryItem')extract=source.slice(p.node.start,p.node.end)},CallExpression(p){const n=p.node;if(n.callee.name==='setCurrentQuestionData'&&n.arguments[0]?.type==='ObjectExpression'){const o=n.arguments[0],kind=o.properties.find(x=>x.key?.name==='questionType')?.value.value;if(kind&&!snapshots[kind])snapshots[kind]=source.slice(o.start,o.end)}if(n.callee.name==='captureCompanionMemory'&&n.arguments[0]?.type==='ObjectExpression')capture=source.slice(n.arguments[0].start,n.arguments[0].end)}});
 if(!capture||(module==='delight'&&!extract))throw Error('Source repair handler moved '+file);sources[module]={file,source,snapshots,extract,capture};
}
const samples=JSON.parse(await fs.readFile('Tests/PiyaliCoreTests/Fixtures/study-note-contexts.json','utf8'));
for(const module of ['vocabulary','grammar']){
 samples.push({module,kind:'flashcard',question:{concept:'A family greeting',answer:'Hola'},response:{text:'Adiós'},bank:[]});
 const matching=structuredClone(samples.find(x=>x.module===module&&x.kind==='match'));delete matching.question.stem;delete matching.question.hint;matching.case='stemless-match';samples.push(matching);
}
const rows=[];
for(const row of samples){
 const{module,kind,question:q,response:r,bank}=row,delight=kind.startsWith('delight:'),source=sources[delight?'delight':module],picked=(r.indices||[]).map(i=>bank[i]);
 const ctx={npub:'public-fixture',targetLang:'es',supportLang:'en',supportCode:'en',moduleType:module,cefrLevel:'A1',questionLevel:'A1',question:q,submittedResponse:r,
 qFill:q.question,ansFill:r.text,hFill:q.hint,input:r.text,hint:q.hint,qMC:q.question,mcQ:q.question,pickMC:picked[0],mcPick:picked[0],answerMC:q.answer,mcAnswer:q.answer,hMC:q.hint,mcHint:q.hint,qMA:q.question,maQ:q.question,selectedStrings:picked,answersMA:q.answers,maAnswers:q.answers,hMA:q.hint,maHint:q.hint,mStem:q.stem,mHint:q.hint,userMappings:(q.left||[]).map((left,i)=>`${left} → ${q.right[r.pairs?.[i]]}`).join(', '),tSentence:q.sentence,userWords:picked,tCorrectWords:q.correctWords,sPrompt:q.prompt,sStimulus:q.stimulus,sTarget:q.target,recognizedText:r.text,concept:q.concept,fcConcept:q.concept,userAnswer:r.text,correctAnswer:q.answer,fcAnswer:q.answer};
 if(delight){if(row.order)ctx.submittedResponse={...r,assignments:Object.fromEntries(row.order.map(k=>[k,r.assignments[k]]))};vm.runInNewContext(source.extract,ctx);ctx.mem=vm.runInNewContext('extractDelightMemoryItem(question,submittedResponse)',ctx)}
 else{if(kind==='fill')ctx.question=q.question;const expression=source.snapshots[kind==='repeat'?'translate':kind];if(!expression)throw Error('Missing snapshot '+module+kind);ctx.currentQuestionData={...vm.runInNewContext('('+expression+')',ctx),questionLevel:'A1',worth:1}}
 const captured=vm.runInNewContext('('+source.capture+')',ctx);
 rows.push({module,kind,case:row.case||kind,question:q,response:r,bank,order:row.order??null,expected:{concept:captured.concept,userAnswer:captured.userAnswer||'',expectedAnswer:captured.expectedAnswer||'',sourceContext:captured.sourceContext,cefrLevel:captured.cefrLevel,sourceMode:captured.sourceMode}});
}
await fs.writeFile('Tests/PiyaliCoreTests/Fixtures/practice-repair-contexts.json',JSON.stringify(rows,null,2)+'\n');await fs.writeFile('docs/reference/practice-repair-contexts-manifest.json',JSON.stringify({cases:rows.length,scope:'Original standard wrong-answer snapshots and actual capture argument objects; original pure Delight memory extractor and actual capture argument object. Public state only; no React, store, provider or backend executes.',sources:Object.values(sources).map(s=>({file:s.file,sha256:createHash('sha256').update(s.source).digest('hex')}))},null,2)+'\n');console.log('Source repair contexts:',rows.length);
