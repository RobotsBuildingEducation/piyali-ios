// Read-only extraction of pure source policy. UI stores, Firebase and provider modules are never imported/executed.
import fs from 'node:fs/promises';
import path from 'node:path';
import {createRequire} from 'node:module';
import {createHash} from 'node:crypto';
import {gunzipSync,gzipSync} from 'node:zlib';
const root=process.cwd(),reference=path.resolve(root,'../nosabos/nosabos');
const require=createRequire(path.join(reference,'package.json')),{parse}=require('@babel/parser'),traverse=require('@babel/traverse').default;
const modules=new Map(),globals=new Set(['undefined','NaN','Infinity','String','Number','Boolean','Object','Array','JSON','Date','Math','Set','Map','RegExp','Error','Intl','parseInt','parseFloat','isNaN','isFinite','console']);
async function moduleFor(file){
 if(modules.has(file))return modules.get(file);
 const source=await fs.readFile(path.join(reference,file),'utf8'),ast=parse(source,{sourceType:'module',plugins:['jsx']}),m={file,source,ast,bindings:new Map(),exports:new Map(),selected:new Set(),imports:new Map(),index:modules.size};modules.set(file,m);
 traverse(ast,{Program(p){for(const [name,binding] of Object.entries(p.scope.bindings))m.bindings.set(name,binding.path);p.stop();}});
 for(const statement of ast.program.body){
  if(statement.type==='ExportNamedDeclaration'){
   const d=statement.declaration;if(d?.type==='FunctionDeclaration')m.exports.set(d.id.name,d.id.name);
   if(d?.type==='VariableDeclaration')for(const v of d.declarations)m.exports.set(v.id.name,v.id.name);
   for(const s of statement.specifiers||[])m.exports.set(s.exported.name,s.local.name);
  }
  if(statement.type==='ExportDefaultDeclaration'&&statement.declaration.type==='Identifier')m.exports.set('default',statement.declaration.name);
 }
 return m;
}
async function select(m,name){
 if(m.selected.has(name))return;m.selected.add(name);
 if(name==='DEFAULT_RESPONSES_MODEL'){m.imports.set(name,{model:true});return;}
 if(name==='callResponses'){m.imports.set(name,{responses:true});return;}
 if(name==='getAppLanguage' && m.file==='src/components/FlashcardPractice.jsx')return;
 const p=m.bindings.get(name);if(!p)throw Error(`Missing binding ${m.file}:${name}`);
 if(m.file==='src/data/phonics/index.js'&&['getAuthoredPhonicsDeck','PHONICS_TARGETS'].includes(name))return; // Explicit authored-deck snapshot adapter, never a generated pronunciation fallback.
 if(m.file==='src/utils/companionMemory.js'&&name==='generateRepairDeckEntries'){await select(m,'langName');await select(m,'repairLessonLevelGuard');return;}
 if(p.isImportSpecifier()||p.isImportDefaultSpecifier()){
  const spec=p.parentPath.node.source.value;
  if(m.file==='src/components/FlashcardPractice.jsx'&&name==='translations'){m.imports.set(name,{flashcardCopy:true});return;}
  if(m.file==='src/utils/companionMemory.js'&&spec==='../hooks/useUserStore'){m.imports.set(name,{snapshot:true});return;}
  if(m.file==='src/constants/languages.js'&&spec==='../components/flagsIcons/flags'){m.imports.set(name,{unusedVisual:true});return;}
  if(!spec.startsWith('.'))throw Error(`Impure external dependency ${m.file}:${spec}`);
  let file=path.posix.normalize(path.posix.join(path.posix.dirname(m.file),spec));if(!path.extname(file))file+='.js';
  if(file==='src/data/phonics/index.js'&&name==='PHONICS_TARGET_NAMES'){const labels=await moduleFor('src/data/phonics/names.js');const node=labels.ast.program.body.find(n=>n.type==='ExportDefaultDeclaration').declaration;m.imports.set(name,{literal:labels.source.slice(node.start,node.end)});return;}
  const dependency=await moduleFor(file),exported=p.isImportDefaultSpecifier()?'default':p.node.imported.name,local=dependency.exports.get(exported);
  if(!local)throw Error(`Missing export ${file}:${exported}`);
  m.imports.set(name,{module:dependency,local});await select(dependency,local);return;
 }
 if(!p.isFunctionDeclaration()&&!p.isVariableDeclarator())throw Error(`Unsupported declaration ${m.file}:${name}`);
 const refs=new Set();p.traverse({ReferencedIdentifier(r){const binding=r.scope.getBinding(r.node.name);if(binding&&binding.scope.path.isProgram())refs.add(r.node.name);else if(!binding&&!globals.has(r.node.name))throw Error(`Unbound global ${m.file}:${name}:${r.node.name}`);}});
 for(const ref of refs)if(ref!==name)await select(m,ref);
}
const languageModule=await moduleFor('src/constants/languages.js');await select(languageModule,'getLanguageLocale');await select(languageModule,'SUPPORT_LANGUAGE_CODES');
const study=await moduleFor('src/utils/noteGeneration.js');await select(study,'generateNoteContent');
const memory=await moduleFor('src/utils/companionMemory.js'),copy=await moduleFor('src/utils/companionMemoryCopy.js'),journey=await moduleFor('src/utils/voiceJourneyCopy.js'),journeyModel=await moduleFor('src/utils/voiceJourneyModel.js');
const roots=['normalizeConceptKey','buildMemoryNote','getCompanionDayKey','generateMemorySummaryText','enrichNoteFields','memoryLogSignature','memoryNoteMatchesSupportLanguage','cleanMemoryConceptForSupportLanguage','getCompanionNotes'];
for(const name of roots)await select(memory,name);
for(const name of ['memoryCopy','MEMORY_CARD_COPY','MEMORY_DRAWER_COPY','memoryStatusLabel'])await select(copy,name);
await select(journey,'journeyCopy');
for(const name of ['JOURNEY_MILESTONES','journeySessionCount','completeJourneyQuest','pendingJourneyMilestone','journeyBaseline','isJourneyMilestoneExpired','canRecordJourneyMilestone'])await select(journeyModel,name);
const drawer=await moduleFor('src/components/NotesDrawer.jsx'),cards=await moduleFor('src/components/CompanionMemoryList.jsx');
for(const name of ['CEFR_LEVELS','CEFR_COLORS','CEFR_TEXT_COLORS','MODULE_LABELS'])await select(drawer,name);
for(const name of ['SOURCE_LABELS','STATUS_ACCENT','resolveStatus'])await select(cards,name);
// Preserve the actual pre-persistence capture block. Its only store access is
// an explicit input snapshot; Node also executes the complete async callback.
const captureNode=memory.bindings.get('captureCompanionMemory').node,captureOriginal=memory.source.slice(captureNode.start,captureNode.end);
const captureStart=captureOriginal.indexOf('  const langKey = normalizePlateLang(targetLang);'),captureEnd=captureOriginal.indexOf('  await persistBucket(npub, langKey, {');
if(captureStart<0||captureEnd<captureStart||!captureOriginal.slice(captureStart,captureEnd).includes('const trimmed = notes.slice(0, 40);'))throw Error('Original capture snapshot boundary moved');
const capturePlan=`function capturePlan(input){const {targetLang,supportLang='en',sourceMode,concept,userAnswer,expectedAnswer,cefrLevel,sourceContext}=input;const now=new Date(input.now),useUserStore={getState:()=>({user:{companionMemory:{[normalizePlateLang(targetLang)]:{notes:input.notes||[],lastPrunedDayKey:''}}}})};
${captureOriginal.slice(captureStart,captureEnd)}
return {note:stored,notes:trimmed,shouldEnrich};}`;
const callerContracts=[];
for(const component of ['Vocabulary','GrammarBook','DelightQuestionLab','FlashcardPractice','Stories','AlphabetBootcamp','RealTimeTest','Tutor','History']){
 const file=`src/components/${component}.jsx`,source=await fs.readFile(path.join(reference,file),'utf8'),ast=parse(source,{sourceType:'module',plugins:['jsx']});
 const literals=node=>node?.type==='StringLiteral'?[node.value]:node?.type==='ConditionalExpression'?[...literals(node.consequent),...literals(node.alternate)]:[];
 traverse(ast,{CallExpression(p){if(p.node.callee.name!=='captureCompanionMemory')return;const props=p.node.arguments[0]?.properties||[],read=key=>props.find(v=>v.key?.name===key)?.value,modes=literals(read('sourceMode'));if(!modes.length)throw Error('Dynamic Memory caller requires an explicit contract: '+file);callerContracts.push({file,sha256:createHash('sha256').update(source).digest('hex'),line:p.node.loc.start.line,modes,explicitNpub:!!read('npub')});}});
}
const callerModes=new Map();for(const caller of callerContracts)for(const mode of caller.modes){if(callerModes.has(mode)&&callerModes.get(mode)!==caller.explicitNpub)throw Error('Mixed caller ownership for '+mode);callerModes.set(mode,caller.explicitNpub)}
const evidenceModes=[...callerModes].filter(([,present])=>present).map(([mode])=>mode);
let evidenceLiteral;traverse(memory.ast,{CallExpression(p){if(p.node.callee.name!=='recordLearningEvidence'||p.findParent(v=>v.isFunctionDeclaration())?.node.id?.name!=='captureCompanionMemory')return;const event=p.node.arguments[0]?.properties?.find(v=>v.key?.name==='event')?.value;if(event&&memory.source.slice(event.start,event.end).includes('stored.id'))evidenceLiteral=memory.source.slice(event.start,event.end);}});if(!evidenceLiteral)throw Error('Capture repair evidence moved');
const captureEvidence=`function captureEvidence(stored){return ${evidenceLiteral};}`;
const emitted=new Set(),ordered=[];
function emit(m){if(emitted.has(m))return;for(const v of m.imports.values())if(v.module)emit(v.module);
 const imports=[...m.imports].map(([name,v])=>`const ${name}=${v.responses?'callNativeResponses':v.model?"'source-default'":v.unusedVisual?'null':`M${v.module.index}.${v.local}`};`).join('\n');
 const declarations=[...m.selected].filter(n=>!m.imports.has(n)).map(n=>m.bindings.get(n)).sort((a,b)=>a.node.start-b.node.start).map(p=>{
  let text=(p.isVariableDeclarator()?'const ':'')+m.source.slice(p.node.start,p.node.end)+(p.isVariableDeclarator()?';':'');
  if(['generateMemorySummaryText','enrichNoteFields','generateNoteContent'].includes(p.node.id.name)){const count=(text.match(/await callResponses/g)||[]).length;if(count!==(p.node.id.name==='generateNoteContent'?1:2))throw Error('Response boundary moved: '+p.node.id.name);text=text.replace('async function','function').replaceAll('await callResponses','callResponses');}
  return text;
 }).join('\n');ordered.push(`// ${m.file}\nconst M${m.index}=(function(){${imports}\n${declarations}\n${m===memory?capturePlan+'\n'+captureEvidence:''}\nreturn {${[...m.selected].join(',')}${m===memory?',capturePlan,captureEvidence':''}};})();`);emitted.add(m);
}
for(const m of [memory,copy,journey,journeyModel,drawer,cards,study])emit(m);
// Inline copy expressions and formatting remain exactly as authored in NotesDrawer.
const names=['clearAllLabel','lessonLabel','noNotesLabel','noteTitleFallback','formatNoteCountLabel','listenLabel','deleteNoteLabel'];let scope;
traverse(drawer.ast,{FunctionDeclaration(p){if(p.node.id?.name==='NotesDrawer')scope=p.scope;}});
const labels=names.map(name=>{const node=scope.bindings[name]?.path.node;if(!node)throw Error('Drawer copy moved: '+name);return `const ${name}=${drawer.source.slice(node.init.start,node.init.end)};`}).join('\n');
const script=`// Generated source policies; Swift owns persistence, provider calls and UI.
(function(){const SystemDate=globalThis.Date,SystemMath=globalThis.Math;let Date=SystemDate,Math=SystemMath,p={},requests=[],index=0;
const console={error:()=>{}};function callNativeResponses(request){requests.push(request.input);const value=(p.responses||[])[index++];if(value?.nativeFailure)throw Error('provider');return value||'';}
${ordered.join('\n')}
return {run:function(operation,json){p=JSON.parse(json||'{}');requests=[];index=0;Math=p.random===undefined?SystemMath:Object.assign(Object.create(SystemMath),{random:()=>p.random});const now=p.now?new SystemDate(p.now):new SystemDate();Date=class extends SystemDate{constructor(...args){super(...(args.length?args:[now.getTime()]));}static now(){return now.getTime();}};const lang=p.language||'en',locale=M${languageModule.index}.getLanguageLocale(lang);${labels}
const m=M${memory.index},c=M${copy.index},j=M${journeyModel.index};let value;
if(operation==='capturePlan')value=m.capturePlan(p);
else if(operation==='captureEvidence')value=m.captureEvidence(p.note);
else if(operation==='captureMetadata')value={evidenceModes:${JSON.stringify(evidenceModes)},whitespace:Array.from({length:65536},(_,n)=>n).filter(n=>/\\s/.test(String.fromCharCode(n))),supports:M${languageModule.index}.SUPPORT_LANGUAGE_CODES,templates:Object.fromEntries(M${languageModule.index}.SUPPORT_LANGUAGE_CODES.map(code=>[code,M${copy.index}.companionMemorySummary(code,'{concept}')])),english:[...m.DISTINCTIVE_ENGLISH_WORDS]};
else if(operation==='captureNote'||operation==='initialNote')value=m.buildMemoryNote({...p,now,dayKey:m.getCompanionDayKey(now)});
else if(operation==='note')value=M${study.index}.generateNoteContent({...p,targetLang:p.target||'es',supportLang:lang});
else if(operation==='summary')value=m.generateMemorySummaryText({notes:p.notes||[],langKey:p.target||'es',supportLang:lang});
else if(operation==='enrich')value=m.enrichNoteFields({...p.note,targetLang:p.target||'es',supportLang:lang});
else if(operation==='signature')value=m.memoryLogSignature(p.notes||[],lang);
else if(operation==='localized')value=m.memoryNoteMatchesSupportLanguage(p.note,lang);
else if(operation==='clean')value=m.cleanMemoryConceptForSupportLanguage(p.text,lang);
else if(operation==='status')value=M${cards.index}.resolveStatus(p.note,p.yesterday);
else if(operation==='journey')value={count:j.journeySessionCount(p.data),pending:j.pendingJourneyMilestone(p.data),baseline:j.journeyBaseline(p.data),milestones:j.JOURNEY_MILESTONES.map(n=>({number:n,expired:j.isJourneyMilestoneExpired(p.data,n),ready:j.canRecordJourneyMilestone(p.data,n)}))};
else if(operation==='copy')value={locale,drawer:Object.fromEntries(Object.entries(c.MEMORY_DRAWER_COPY).map(([k,v])=>[k,c.memoryCopy(lang,v)])),card:Object.fromEntries(Object.entries(c.MEMORY_CARD_COPY).map(([k,v])=>[k,c.memoryCopy(lang,v)])),status:Object.fromEntries(['captured','used_in_quest','reinforced','expiring'].map(k=>[k,c.memoryStatusLabel(lang,k)])),source:Object.fromEntries(Object.entries(M${cards.index}.SOURCE_LABELS).map(([k,v])=>[k,c.memoryCopy(lang,v)])),accent:M${cards.index}.STATUS_ACCENT,levels:M${drawer.index}.CEFR_LEVELS,colors:M${drawer.index}.CEFR_COLORS,textColors:M${drawer.index}.CEFR_TEXT_COLORS,modules:Object.fromEntries(Object.entries(M${drawer.index}.MODULE_LABELS).map(([k,v])=>[k,v[lang]||v.en])),labels:{clearAllLabel,lessonLabel,noNotesLabel,noteTitleFallback,listenLabel,deleteNoteLabel,count:formatNoteCountLabel(p.count||0)}};
else if(operation==='journeyCopy')value=M${journey.index}.journeyCopy(lang,p.key,p.values||{});
else throw Error('Unknown Memory policy '+operation);
return JSON.stringify({value:value??null,requests});}};})()`;
await fs.writeFile(path.join(root,'Piyali/Resources/memory-policy.js'),script);
const vm=await import('node:vm'),api=vm.runInNewContext(script),rows=[];
const base={now:new Date(2026,9,25,12).getTime(),target:'es',language:'en'};
for(const language of ['en','es','pt','fr','it','de','ja','hi','ar','zh'])for(const operation of ['copy','journeyCopy']){const input={...base,language,key:'sessions',values:{n:1},count:3};rows.push({operation,input,expected:JSON.parse(api.run(operation,JSON.stringify(input)))});}
const note={id:'mem-public',concept:'hola (the word hello)',sourceMode:'grammar',createdDayKey:'2026-10-25',userAnswer:'ola',expectedAnswer:'hola',status:'captured',severity:2,supportLang:'en',mistake:'Missing the letter h.',tip:'Keep the silent h.',enriched:true};
for(const language of ['en','es','ar','ja'])for(const operation of ['signature','localized','clean','summary','enrich','status']){const input={...base,language,note,text:note.concept,notes:[note],responses:operation==='enrich'?['{"did":"Missing h","fix":"hola","tip":"Keep h"}','{"did":"نسيت حرف h","fix":"hola","tip":"افتكر حرف h"}']:['Hola kept its silent h.'],yesterday:true};rows.push({operation,input,expected:JSON.parse(api.run(operation,JSON.stringify(input)))});}
for(const count of [0,1,4,5,15,149,150]){const input={...base,data:{completedQuests:count,recordings:{1:{createdAt:'2026-01-01T00:00:00Z'}}}};rows.push({operation:'journey',input,expected:JSON.parse(api.run('journey',JSON.stringify(input)))});}
for(const responses of [[],['{\"example\":\"Hola, mamá.\",\"summary\":\"A family greeting.\"}'],['invalid'],[{nativeFailure:true}]]){const input={...base,concept:'hola',cefrLevel:'A1',moduleType:'grammar',wasCorrect:false,responses};rows.push({operation:'note',input,expected:JSON.parse(api.run('note',JSON.stringify(input)))});}
for(const language of ['en','ar','es'])for(const [concept,expectedAnswer] of [['A greeting','Hola'],['تحية (a greeting)','  Hola  '],['  A greeting  ','Hola']]){const input={...base,targetLang:'es',supportLang:language,sourceMode:'tutor',sourceContext:'tutor',concept,userAnswer:'a public attempt',expectedAnswer,cefrLevel:'Pre-A1'};const expected=JSON.parse(api.run('captureNote',JSON.stringify(input)));delete expected.value.id;rows.push({operation:'captureNote',input,expected});}
// Independent original asynchronous capture with only external I/O replaced.
const oracleMath=Object.assign(Object.create(Math),{random:()=>0.5}),helpers=vm.runInNewContext(`(()=>{const console={error:()=>{},warn:()=>{}},callNativeResponses=()=>'';${ordered.join('\n')}return M${memory.index};})()`,{Math:oracleMath});
const duplicateBase={now:new Date(2026,10,5,12).getTime(),random:0.5,targetLang:'es',concept:'  hola  ',sourceMode:'tutor',sourceContext:'changed-context',cefrLevel:'C1',expectedAnswer:'new correction'};
const day='2026-11-05',previous={id:'public-original',createdDayKey:day,createdAt:duplicateBase.now-1000,targetLang:'es',supportLang:'en',sourceMode:'tutor',sourceContext:'original-context',concept:'Hola',userAnswer:'first attempt',expectedAnswer:'HOLA',correction:'HOLA fixed',errorType:'conversation_flow',cefrLevel:'A1',severity:1,recommendedRepairMode:'tutor',companionSummary:'old summary',mistake:'Original diagnosis',tip:'Original tip',enriched:true,expiresAfterDayKey:'2026-11-06',usedInQuestDayKey:null,status:'captured',foreignField:'keep'};
const captureInputs=[];
for(const [oldSupport,supportLang]of [['en','en'],['en','es'],['es','en'],['en','ar'],['ar','ar'],['en-US','EN_us'],['arz','ar'],['unknown','en']])for(const severity of [1,2,3])for(const userAnswer of ['second attempt',''])for(const status of ['captured','reinforced'])for(const sourceMode of ['tutor','grammar']){
 const old={...previous,supportLang:oldSupport,severity,status,sourceMode,...(['ar','arz'].includes(oldSupport)?{mistake:'التحية ناقصة',tip:'افتكر التحية'}:{})};captureInputs.push({...duplicateBase,supportLang,userAnswer,sourceMode,notes:[old]});
}
for(const overrides of [{concept:'Hola (the word hello)',supportLang:'ar'},{concept:'Hola (familia)',supportLang:'es'},{concept:'x'.repeat(241)},{sourceMode:'grammar'},{now:duplicateBase.now+86400000},{concept:''},{concept:'   '},{userAnswer:'answer '.repeat(60)},...['en','es','ar'].map(supportLang=>({supportLang,notes:[{...previous,id:'public-other',concept:'another concept',createdAt:duplicateBase.now-500},previous]}))])captureInputs.push({...duplicateBase,supportLang:'en',userAnswer:'second attempt',notes:[previous],...overrides});
for(const input of captureInputs){let persisted=null,enrichments=0;const effects={};const context={...helpers,Date,Math:oracleMath,console:{warn:()=>{}},currentGoalFocus:()=>null,useUserStore:{getState:()=>({user:{companionMemory:{es:{notes:input.notes,lastPrunedDayKey:''}}}})},useNotesStore:{getState:()=>({triggerDoneAnimation:()=>{}})},recordGradedOutcome:async()=>{},recordLearningEvidence:async()=>{},persistBucket:async(_npub,_lang,bucket)=>{persisted=bucket.notes},enrichNoteFields:()=>{enrichments++;return Promise.resolve(null)},enrichAndPatchNote:async()=>{}};
 const execute=vm.runInNewContext('('+captureOriginal+')',context),note=await execute({...input,now:new Date(input.now),gradedOutcome:false});await Promise.resolve();const expected={value:note?{note,notes:persisted,shouldEnrich:enrichments>0}:null,requests:[]},actual=JSON.parse(api.run('capturePlan',JSON.stringify(input)));
 if(JSON.stringify(actual)!==JSON.stringify(JSON.parse(JSON.stringify(expected))))throw Error('Full original capture differs from snapshot: '+JSON.stringify({input,expected,actual}));rows.push({operation:'capturePlan',input,expected});
}
// The source updateBucket rejects an omitted npub, even though note persistence
// resolves a local account. Execute the actual evidence entry/update functions.
const learning=await moduleFor('src/utils/learningIntelligence.js'),recordNode=learning.bindings.get('recordLearningEvidence').node,updateNode=learning.bindings.get('updateBucket').node,questSource=await fs.readFile(path.join(root,'Piyali/Resources/companion-quest-policy.js'),'utf8'),quest=vm.runInNewContext(questSource+';PiyaliCompanionQuest');
const evidenceGateAudit=[];
for(const [mode,hasAccount]of callerModes){let patch=null;const context={database:{},doc:()=>({}),languageKey:x=>x,patchBucket:()=>{},mergeEvidence:(summary,event)=>JSON.parse(quest.run('evidence',JSON.stringify({summary,event,now:duplicateBase.now}))),runTransaction:async(_db,execute)=>execute({get:async()=>({data:()=>({})}),update:(_ref,value)=>{patch=value}})};
 const record=vm.runInNewContext(`(()=>{${learning.source.slice(updateNode.start,updateNode.end)};return (${learning.source.slice(recordNode.start,recordNode.end)});})()`,context);let error='';try{await record({npub:hasAccount?'public-account':undefined,targetLang:'es',event:helpers.captureEvidence({...previous,sourceMode:mode})})}catch(e){error=e.message}
 if(hasAccount?!patch:!error.includes('Sign in'))throw Error('Source learning evidence ownership changed');evidenceGateAudit.push({mode,hasAccount,writes:!!patch,error});
 const input={note:{...previous,sourceMode:mode},mode,hasAccount};rows.push({operation:'captureEvidence',input,expected:JSON.parse(api.run('captureEvidence',JSON.stringify(input)))});
}
for(const sourceMode of callerModes.keys())for(const supportLang of ['en','es','ar','zh'])for(const cefrLevel of ['Pre-A1','a1','pre_a1','invalid']){
 const input={...duplicateBase,sourceMode,supportLang,cefrLevel,concept:supportLang==='ar'?'تحية (the word hello)':'A greeting',userAnswer:'a public attempt',expectedAnswer:'Hola'};const expected=JSON.parse(api.run('initialNote',JSON.stringify(input)));delete expected.value.id;rows.push({operation:'initialNote',input,expected});
}
for(const extra of [{supportLang:'_ar'},{supportLang:'\uFEFFar'},{concept:'\uFEFFhola\uFEFF'},{concept:'hola\u0085word'},{concept:'😀'.repeat(120)+'x',userAnswer:'😀'.repeat(120)+'x',expectedAnswer:'😀'.repeat(120)+'x'},{cefrLevel:' A0 '},{cefrLevel:'pre a1'},{now:duplicateBase.now+0.4}]){
 const input={...duplicateBase,supportLang:'en',sourceMode:'reading',userAnswer:'a public attempt',...extra};const expected=JSON.parse(api.run('initialNote',JSON.stringify(input)));delete expected.value.id;rows.push({operation:'initialNote',input,expected});
}
const metadata=JSON.parse(api.run('captureMetadata','{}')).value,swiftPath=path.join(root,'Piyali/Core/CompanionMemory.swift'),begin='// BEGIN GENERATED MEMORY CAPTURE DATA',end='// END GENERATED MEMORY CAPTURE DATA';
const generated=begin+'\n// Original support codes, capture summaries and English tokens; export-memory.mjs.\nprivate enum MemoryCaptureSourceData {\n    static let summaries:[String:String] = ['+Object.entries(metadata.templates).map(([code,text])=>JSON.stringify(code)+':'+JSON.stringify(text)).join(',')+']\n    static let english:Set<String> = ['+metadata.english.map(JSON.stringify).join(',')+']\n    static let evidenceModes:Set<String> = ['+metadata.evidenceModes.map(JSON.stringify).join(',')+']\n    static let whitespace:[UInt32] = ['+metadata.whitespace.join(',')+']\n}\n'+end;
const originalSwift=await fs.readFile(swiftPath,'utf8');let swift=originalSwift;if(swift.includes(begin)){const first=swift.indexOf(begin),last=swift.indexOf(end,first);if(last<0)throw Error('Missing generated Memory data end');swift=swift.slice(0,first)+generated+swift.slice(last+end.length)}else swift+='\n'+generated+'\n';if(swift!==originalSwift)await fs.writeFile(swiftPath,swift);
await fs.writeFile(path.join(root,'Tests/PiyaliCoreTests/Fixtures/memory-policy.json.gz'),gzipSync(JSON.stringify(rows),{level:9}));
await fs.writeFile(path.join(root,'docs/reference/memory-source-manifest.json'),JSON.stringify({sources:[...modules.values()].filter(m=>m.selected.size).map(m=>({file:m.file,sha256:createHash('sha256').update(m.source).digest('hex'),declarations:[...m.selected]})),captureModule:memory.index,callerContracts,evidenceGateAudit,learningEvidenceSource:{file:learning.file,sha256:createHash('sha256').update(learning.source).digest('hex')},adapters:'Capture caller npub contracts are extracted from the active source components and verified against the actual recordLearningEvidence/updateBucket entry; omitted callers preserve its sign-in failure. Initial note and evidence payload fixtures execute original declarations. The original pre-persistence capture block runs with an explicit note-bucket snapshot; new capture cases are independently checked against the complete original async callback with inert persistence/evidence/enrichment I/O. A fixed random input is used only in the new fixtures. Original summary templates, supported UI codes and English-cleanup tokens are also generated into native Swift. Only provider awaits become explicit synchronous response snapshots; native code executes their recorded requests and retries. Original buildMemoryNote creates initial Tutor capture fields, including localized pending summary, blank enrichment, error/repair mode and the Pre-A1 fallback. Only its random note ID is excluded from fixture equality; production keeps the source ID generator. Original prompts, parsers, language guards, signatures, status and copy rules remain. No stores, React, DOM, Firebase or network executes.',cases:rows.length},null,2)+'\n');
console.log('Memory policy: '+rows.length+' source cases.');
