// Execute original note handlers with public question/response state; no UI/store/provider imports.
import fs from 'node:fs/promises';import path from 'node:path';import vm from 'node:vm';import{createRequire}from'node:module';import{createHash}from'node:crypto';
const root=process.cwd(),ref=path.resolve(root,'../nosabos/nosabos'),req=createRequire(path.join(ref,'package.json')),{parse}=req('@babel/parser'),traverse=req('@babel/traverse').default;
const sources={};
for(const [key,file]of Object.entries({delight:'src/components/DelightQuestionLab.jsx',vocabulary:'src/components/Vocabulary.jsx',grammar:'src/components/GrammarBook.jsx'})){
 const source=await fs.readFile(path.join(ref,file),'utf8'),ast=parse(source,{sourceType:'module',plugins:['jsx']});let handler;const snapshots={};
 traverse(ast,{FunctionDeclaration(p){if(p.node.id?.name==='handleCreateNote')handler=source.slice(p.node.start,p.node.end)+';handleCreateNote()'},VariableDeclarator(p){if(p.node.id.name==='handleCreateNote'&&p.node.init?.type==='CallExpression')handler='('+source.slice(p.node.init.arguments[0].start,p.node.init.arguments[0].end)+')()'},CallExpression(p){if(p.node.callee.name!=='setCurrentQuestionData')return;const n=p.node.arguments[0];if(n?.type!=='ObjectExpression')return;const type=n.properties.find(x=>x.key?.name==='questionType')?.value.value;if(type&&!snapshots[type])snapshots[type]=source.slice(n.start,n.end)}});
 if(!handler)throw Error('Source handler moved '+file);sources[key]={file,source,handler,snapshots};
}
const advanced=JSON.parse(await fs.readFile('Tests/PiyaliAppTests/Fixtures/delight-bodies.json','utf8')),writing=JSON.parse(await fs.readFile('Tests/PiyaliAppTests/Fixtures/writing-bodies.json','utf8')),standard=JSON.parse(await fs.readFile('Piyali/Resources/standard-practice-fixture.json','utf8')),words=JSON.parse(await fs.readFile('Piyali/Resources/word-bank-practice-fixture.json','utf8')),oral=JSON.parse(await fs.readFile('Piyali/Resources/oral-practice-fixture.json','utf8'));
const samples={...advanced,...writing,natural_or_weird:{question:{variant:'natural_or_weird',sentence:'Yo somos Ana.',correction:'Yo soy Ana.'},responses:{filled:{choice:false}}}};
const rows=[];
async function record(module,kind,q,r,bank,order){
 const delight=kind.startsWith('delight:'),source=sources[delight?'delight':module],target='es',support='en';let captured,title;
 const ctx={question:q,response:r,moduleType:module,targetLang:target,supportLang:support,supportCode:support,cefrLevel:'A1',result:true,lastOk:true,lesson:null,isFinalQuiz:false,isCreatingNote:false,noteCreated:false,setIsCreatingNote(){},setNotesLoading(){},setNoteCreated(){},triggerDoneAnimation(){},addNote(){},toast(){},t:k=>k,console:{error(){}},generateNoteContent:async input=>{captured=input;return{example:'Public example',summary:'Public summary'}},buildNoteObject:input=>{title=input.lessonTitle;return input}};
 if(!delight){
  const picked=(r.indices||[]).map(i=>bank[i]),pairs=(q.left||[]).map((_,li)=>[li,r.pairs?.[li]]);
  Object.assign(ctx,{qFill:q.question,ansFill:r.text,hFill:q.hint,input:r.text,hint:q.hint,qMC:q.question,mcQ:q.question,pickMC:picked[0],mcPick:picked[0],answerMC:q.answer,mcAnswer:q.answer,hMC:q.hint,mcHint:q.hint,qMA:q.question,maQ:q.question,selectedStrings:picked,answersMA:q.answers,maAnswers:q.answers,hMA:q.hint,maHint:q.hint,mStem:q.stem,mHint:q.hint,userMappings:pairs.map(([li,ri])=>`${q.left[li]} → ${q.right[ri]}`).join(', '),tSentence:q.sentence,userWords:picked,tCorrectWords:q.correctWords,sPrompt:q.prompt,sStimulus:q.stimulus,sTarget:q.target,recognizedText:r.text});
  // Grammar's fill state is named question; other kinds retain their own bindings.
  if(kind==='fill')ctx.question=q.question;
  const snapshot=source.snapshots[kind==='repeat'?'translate':kind];if(!snapshot)throw Error('Missing original snapshot '+module+':'+kind);
  ctx.currentQuestionData=vm.runInNewContext('('+snapshot+')',ctx);
 }
 if(order)ctx.response={...r,assignments:Object.fromEntries(order.map(k=>[k,r.assignments[k]]))};
 await vm.runInNewContext(source.handler,ctx);if(!captured)throw Error('No note input '+module+':'+kind);
 const expected={concept:captured.concept,userAnswer:captured.userAnswer||'',wasCorrect:captured.wasCorrect,target:captured.targetLang,language:captured.supportLang,cefrLevel:captured.cefrLevel,moduleType:captured.moduleType};
 rows.push({module,kind,question:q,response:r,bank,order:order??null,expected,lessonTitle:title});
}
for(const module of ['vocabulary','grammar']){
 for(const[variant,s]of Object.entries(samples)){if(!s.question?.variant)continue;const r=s.responses.filled||s.responses.locked||s.responses.partial||{};await record(module,'delight:'+variant,s.question,r,[],variant==='word_neighborhoods'?Object.keys(r.assignments||{}).reverse():null)}
 for(const kind of ['fill','mc','ma','match']){const values=Object.values(standard[module]),s=values.find(s=>s.kind===kind);await record(module,kind,s.question,s.responses.filled||s.responses.locked, s.question.choices||[])}
 for(const kind of ['translate','repeat']){const s=Object.values(words).find(s=>s.kind===kind);if(!s)throw Error('Missing public '+kind);const bank=s.bank||[...s.question.correctWords,...s.question.distractors];await record(module,kind,s.question,s.responses.filled||s.responses.locked,bank)}
 const s=Object.values(oral).find(s=>s.kind==='speak');await record(module,'speak',s.question,s.responses?.filled||s.responses?.locked||{text:s.question.target},[]);
}
await fs.writeFile('Tests/PiyaliCoreTests/Fixtures/study-note-contexts.json',JSON.stringify(rows,null,2)+'\n');await fs.writeFile('docs/reference/study-note-contexts-manifest.json',JSON.stringify({sources:Object.values(sources).map(s=>({file:s.file,sha256:createHash('sha256').update(s.source).digest('hex')})),cases:rows.length,scope:'Original full handleCreateNote callbacks executed with public question/response state, original standard snapshot objects, in-memory setters and a recording provider boundary. No React/store/backend executes.'},null,2)+'\n');console.log('Original exercise note contexts:',rows.length);
