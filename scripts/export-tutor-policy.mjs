// Read-only Tutor extraction: Swift owns UI, audio, network and storage.
import fs from 'node:fs/promises';
import path from 'node:path';
import {createRequire} from 'node:module';
import {createHash} from 'node:crypto';
import {gzipSync,gunzipSync} from 'node:zlib';
import vm from 'node:vm';
const root=process.cwd(),reference=path.resolve(root,'../nosabos/nosabos'),require=createRequire(path.join(reference,'package.json'));
const {parse}=require('@babel/parser'),traverse=require('@babel/traverse').default,generator=require('@babel/generator').default;
const modules=new Map(),globals=new Set(['undefined','NaN','Infinity','String','Number','Boolean','Object','Array','JSON','Date','Math','Set','Map','RegExp','Error','Intl','parseInt','parseFloat','isNaN','isFinite']);
const translations=JSON.parse(gunzipSync(await fs.readFile(path.join(root,'Piyali/Resources/app-copy.json.gz'))));
const statusTranslations=Object.fromEntries(Object.entries(translations).map(([lang,copy])=>[lang,Object.fromEntries(['proficiency_speaking','proficiency_listening','proficiency_thinking'].map(key=>[key,copy[key]]))]));
const adapters=new Set(['inlineFeedbackRef','supportLang','selectedTutorLessonRef','selectedTutorUnitRef','supportLangRef','resolvedSupportLang','targetLangRef','targetLang','conversationSettingsRef','maxProficiencyLevel','messagesRef','realtimeProviderRef','turnCountRef','openAIRegularAgendaRef','tutorStarterAgendaProgressRef','tutorLessonEarnedXpRef','tutorLessonCompletionTriggeredRef','tutorRestoredConversationNeedsContextRef','tutorConversationResumeContextRef','tutorItemRetryCountRef','voicePersonaRef','pausedMessagesRef','getOpenAIRegularTutorAgendaSnapshot','currentRepairFocus','currentGoalFocus','useUserStore']);
async function moduleFor(file){
 if(modules.has(file))return modules.get(file);
 const source=await fs.readFile(path.join(reference,file),'utf8'),ast=parse(source,{sourceType:'module',plugins:['jsx']}),m={file,source,ast,bindings:new Map(),exports:new Map(),selected:new Set(),imports:new Map(),index:modules.size};modules.set(file,m);
 traverse(ast,{Program(p){for(const[name,b]of Object.entries(p.scope.bindings))m.bindings.set(name,b.path);p.stop();}});
 if(file==='src/components/Tutor.jsx')traverse(ast,{FunctionDeclaration(p){if(p.node.id?.name==='Tutor'){for(const[name,b]of Object.entries(p.scope.bindings))if(!m.bindings.has(name))m.bindings.set(name,b.path);p.stop();}}});
 for(const statement of ast.program.body){if(statement.type==='ExportNamedDeclaration'){const d=statement.declaration;if(d?.type==='FunctionDeclaration')m.exports.set(d.id.name,d.id.name);if(d?.type==='VariableDeclaration')for(const v of d.declarations)m.exports.set(v.id.name,v.id.name);for(const s of statement.specifiers||[])m.exports.set(s.exported.name,s.local.name);}if(statement.type==='ExportDefaultDeclaration'&&statement.declaration.type==='Identifier')m.exports.set('default',statement.declaration.name);}
 return m;
}
async function select(m,name){
 if(m.selected.has(name))return;m.selected.add(name);
 if(m.file==='src/components/Tutor.jsx'&&adapters.has(name))return;
 const p=m.bindings.get(name);if(!p)throw Error(`Missing ${m.file}:${name}`);
 if(p.isImportSpecifier()||p.isImportDefaultSpecifier()){
  const spec=p.parentPath.node.source.value;
  if(m.file==='src/components/Tutor.jsx'&&name==='translations'){m.imports.set(name,{literal:JSON.stringify(statusTranslations)});return;}
  if(m.file==='src/constants/languages.js'&&spec==='../components/flagsIcons/flags'){m.imports.set(name,{literal:'null'});return;}
  if(!spec.startsWith('.'))throw Error(`Impure import ${m.file}:${spec}:${name}; recent ${[...m.selected].slice(-10).join(",")}`);
  let file=path.posix.normalize(path.posix.join(path.posix.dirname(m.file),spec));if(!path.extname(file)){try{await fs.access(path.join(reference,file+'.js'));file+='.js';}catch{file+='.jsx';}}const dep=await moduleFor(file),key=p.isImportDefaultSpecifier()?'default':p.node.imported.name,local=dep.exports.get(key);if(!local)throw Error(`Missing export ${file}:${key}`);m.imports.set(name,{module:dep,local});await select(dep,local);return;
 }
 if(!p.isFunctionDeclaration()&&!p.isVariableDeclarator())throw Error(`Unsupported ${m.file}:${name}:${p.type}`);
 const refs=new Set();p.traverse({ReferencedIdentifier(r){const b=r.scope.getBinding(r.node.name);if(b&&(b.scope.path.isProgram()||m.file==='src/components/Tutor.jsx'&&m.bindings.get(r.node.name)===b.path))refs.add(r.node.name);else if(!b&&!globals.has(r.node.name))throw Error(`Unbound ${m.file}:${name}:${r.node.name}`);}});
 for(const ref of refs)if(ref!==name)await select(m,ref);
}
const tutor=await moduleFor('src/components/Tutor.jsx');
const roots=['buildTutorRepairLessonFromFocus','tidyPairs','findLatestTutorUnlockedLesson','isTutorLessonUnlockedById','findNextTutorLessonAfter','getTutorStarterAgendaCandidateItemIds','getLocalTutorTurnSuccessfulForXp','transcriptDemonstratesOpenAIRegularObjective','buildOpenAIResponseInstructionsPrefix','normalizeOpenAITutorVoice','buildTutorInputTranscription','hasUnexpectedTutorTranscriptScript','getCurrentTutorInputLanguageCodes','getCurrentTutorTranscriptionKeywords','buildTutorTurnDetection','buildMessageTranslationPrompt','getTutorLessonXpRequired','getTutorLessonAgendaTitle','getTutorLessonAgendaSubtitle','getTutorLessonFocusAgendaItems','getTutorLessonPreviewAgendaItems','buildTutorCompletedAgendaData','getTutorStarterAgendaMatches','getNextTutorStarterAgendaItem','normalizeTutorStarterAgendaProgress','isTutorStarterAgendaComplete','tutorPhraseMatchesTranscript','tutorPhraseIsDirectAnswer','anyTutorPhraseIsDirectAnswer','hasTutorMeaningfulTranscript','extractPromptedTutorPhrases','isTutorPracticePhraseAllowedForTarget','isTutorRawSourceConceptPhrase','buildOpenAIResponseInstructionsPrefixBase','buildTutorResponseInstructionsSuffix','buildTutorWelcomeInstructions','buildTutorKickoffInstructions','buildTutorFollowupInstructions','buildTutorTurnSuccessJudgePrompt','buildOpenAIRegularTutorAgendaInstruction','buildTutorAgendaResponseInstructions','TUTOR_STARTER_AGENDA_ITEMS','PAPER_PANEL_SX','MATRIX_PANEL_SX','uiStateLabel','TUTOR_LEVEL_INFO','getTutorPathCopy','getTutorLessonLaunchMode'];
for(const name of roots)await select(tutor,name);
const flow=await moduleFor('src/utils/tutorAgendaFlow.js');for(const name of ['getTutorAgendaSnapshot','advanceTutorAgendaProgress','advanceTutorQuizAttempt','normalizeTutorAgendaProgress','isLegacyTutorAgendaProgress'])await select(flow,name);
const draft=await moduleFor('src/utils/tutorConversationDraft.js');for(const name of ['normalizeTutorConversationDraftMessages','getTutorConversationSessionState'])await select(draft,name);
const controls=await moduleFor('src/utils/realtimeSessionControls.js');for(const name of ['buildRealtimeResumeContext','snapshotRealtimeMessages','resumeRealtimeSpeech'])await select(controls,name);
const composition=await moduleFor('src/utils/openaiRealtimeResponseInstructions.js');await select(composition,'composeOpenAIRealtimeResponseInstructions');
const verdict=await moduleFor('src/utils/tutorTurnVerdict.js');await select(verdict,'resolveTutorTurnVerdict');
const progression=await moduleFor('src/achievements/proficiencyCompletion.js');await select(progression,'tutorLevelFromCompletions');
const course=await moduleFor('src/utils/courseProgress.js');await select(course,'getCourseLevelStats');
const copy={};traverse(tutor.ast,{CallExpression(p){if(p.node.callee.name==='tutorCopy'&&p.node.arguments[1]?.type==='ObjectExpression'){const n=p.node.arguments[1],en=n.properties.find(v=>v.key?.name==='en')?.value?.value;if(en&&!copy[en])copy[en]=tutor.source.slice(n.start,n.end);}}});
const context=`const targetLang=p.target||'es',resolvedSupportLang=p.support||'en',supportLang=resolvedSupportLang,maxProficiencyLevel=p.level||p.lesson?.cefrLevel||'Pre-A1';
const inlineFeedbackRef={current:p.feedback||''},pausedMessagesRef={current:p.pausedMessages||[]};
const selectedTutorLessonRef={current:p.lesson||null},selectedTutorUnitRef={current:p.unit||null},targetLangRef={current:targetLang},supportLangRef={current:resolvedSupportLang},conversationSettingsRef={current:{proficiencyLevel:maxProficiencyLevel,...p.settings}},messagesRef={current:p.messages||[]},realtimeProviderRef={current:'openai'},turnCountRef={current:p.turn||0},openAIRegularAgendaRef={current:{progress:p.progress||{},quizLastFeedback:p.quizLastFeedback,quizPreviousAttemptResult:p.quizPreviousAttemptResult}},tutorStarterAgendaProgressRef={current:p.progress||{}},tutorLessonEarnedXpRef={current:p.earned||0},tutorLessonCompletionTriggeredRef={current:!!p.completed},tutorRestoredConversationNeedsContextRef={current:!!p.resume?.length},tutorConversationResumeContextRef={current:p.resume||[]},tutorItemRetryCountRef={current:p.retry||0},voicePersonaRef={current:p.persona||''};
const currentGoalFocus=()=>p.goalFocus||null,currentRepairFocus=()=>p.repairFocus||null,useUserStore={getState:()=>({user:p.user||null})};
function getOpenAIRegularTutorAgendaSnapshot(){const lesson=p.lesson;if(!lesson||lesson.isGoal||lesson.isRepair||isTutorStarterAgendaLesson(lesson))return null;const items=getTutorLessonFocusAgendaItems(lesson,resolvedSupportLang,targetLang,p.unit);return items.length?{lesson,items,...getTutorAgendaSnapshot(items,p.progress||{})}:null;}`;
// Imported snapshot helper is explicitly aliased into the component's pure closure.
await select(tutor,'getTutorAgendaSnapshot');
const emitted=new Set(),ordered=[];
function emit(m){if(emitted.has(m))return;for(const i of m.imports.values())if(i.module)emit(i.module);
 const imports=[...m.imports].map(([name,i])=>`const ${name}=${i.literal??`M${i.module.index}.${i.local}`};`).join('\n');
 const definitions=[...m.selected].filter(n=>!m.imports.has(n)&&!(m===tutor&&adapters.has(n))).map(n=>m.bindings.get(n)).sort((a,b)=>a.node.start-b.node.start).map(p=>(p.isVariableDeclarator()?'const ':'')+m.source.slice(p.node.start,p.node.end)+(p.isVariableDeclarator()?';':'')).join('\n');
 const names=[...m.selected].filter(n=>!(m===tutor&&adapters.has(n)));
 ordered.push(`// ${m.file}\nconst M${m.index}=${m===tutor?'function(p)':'(function()'}{\n${imports}\n${m===tutor?context:''}\n${definitions}\nreturn {${names.join(',')}};}${m===tutor?'':')()'};`);emitted.add(m);
}
emit(tutor);emit(flow);emit(draft);emit(verdict);emit(controls);emit(composition);emit(progression);emit(course);
const script=`// Generated from read-only reference Tutor pure declarations. Never execute source UI/network/store code.\n(function(){${ordered.join('\n')}\nconst localizedCopy={${Object.entries(copy).map(([k,v])=>JSON.stringify(k)+':'+v).join(',')}};
return {run:function(op,input){const p=JSON.parse(input||'{}'),t=M${tutor.index}(p),f=M${flow.index},d=M${draft.index};let value;
switch(op){
case 'focusLesson':value=t.buildTutorRepairLessonFromFocus(p.focus);break;
case 'xp':value=t.getTutorLessonXpRequired(p.lesson);break;
case 'content':value={title:t.getTutorLessonAgendaTitle(p.lesson,p.unit,p.support),subtitle:t.getTutorLessonAgendaSubtitle(p.lesson,p.unit,p.support),items:t.getTutorLessonFocusAgendaItems(p.lesson,p.support,p.target,p.unit),preview:t.getTutorLessonPreviewAgendaItems(p.lesson,p.support,p.target,p.unit),launch:t.getTutorLessonLaunchMode(p.lesson)};break;
case 'starter':value=t.TUTOR_STARTER_AGENDA_ITEMS;break;
case 'path':value={statuses:Object.fromEntries((p.units||[]).flatMap(unit=>(unit.lessons||[]).map(lesson=>[lesson.id,['completed','in_progress'].includes(p.records?.[lesson.id]?.status)?p.records[lesson.id].status:t.isTutorLessonUnlockedById(p.units||[],p.records||{},lesson.id,p.placement)?'available':'locked']))),current:t.findLatestTutorUnlockedLesson(p.units||[],p.records||{},p.placement),allowed:t.isTutorLessonUnlockedById(p.units||[],p.records||{},p.id,p.placement),next:p.id?t.findNextTutorLessonAfter(p.units||[],p.id,p.records||{}):null};break;
case 'state':{const starter=t.isTutorStarterAgendaLesson(p.lesson),items=starter?t.TUTOR_STARTER_AGENDA_ITEMS.map(item=>({id:item.id,phrase:t.getTutorStarterItemModelPhrase(item,p.target),label:t.getTutorStarterItemSupportTask(item,p.support),meaning:t.getTutorStarterItemSupportMeaning(item,p.support),targetForms:[t.getTutorStarterItemModelPhrase(item,p.target)]})):t.getTutorLessonFocusAgendaItems(p.lesson,p.support,p.target,p.unit);value={starter,required:t.getTutorLessonXpRequired(p.lesson),level:t.getTutorAdaptiveLevel(p.level||p.unit?.cefrLevel||'Pre-A1'),items,...f.getTutorAgendaSnapshot(items,p.progress||{})};break;}
case 'classify':{const starter=t.isTutorStarterAgendaLesson(p.lesson),candidateIds=t.getTutorStarterAgendaCandidateItemIds(),exact=starter?t.getTutorStarterAgendaMatches(p.answer,p.target):[],phrases=starter?candidateIds.map(id=>t.TUTOR_STARTER_AGENDA_ITEMS.find(item=>item.id===id)).filter(Boolean).map(item=>t.getTutorStarterItemModelPhrase(item,p.target)):t.getRegularTutorAcceptedPhrases(),regular=!starter&&phrases.some(phrase=>t.tutorPhraseMatchesTranscript(phrase,p.answer)),direct=t.anyTutorPhraseIsDirectAnswer(phrases,p.answer),local=t.getLocalTutorTurnSuccessfulForXp({isStarterLesson:starter,starterCandidateItemIds:candidateIds,exactStarterMatches:exact,regularTurnAccepted:regular,directPhraseAnswer:direct}),objectiveLocal=!starter&&local?t.transcriptDemonstratesOpenAIRegularObjective(p.answer):false;value={starter,candidateIds,phrases,local,objectiveLocal,options:{starterCandidateItemIds:candidateIds,exactStarterMatches:exact,regularPhraseMatch:regular,directPhraseAnswer:direct,acceptedPhrases:phrases}};break;}

case 'earnedLevel':value=M${progression.index}.tutorLevelFromCompletions(p.status);break;
case 'levelStats':{const stats=M${course.index}.getCourseLevelStats(p.summary,'tutor',p.level,p.fallbackTotal),total=stats.total||p.fallbackTotal,completed=stats.completed??p.localCompleted;value={total,completed,isComplete:total>0&&completed>=total,progress:total>0?Math.round(completed/total*100):0};break;}
case 'levels':value=t.TUTOR_LEVEL_INFO;break;
case 'copy':value=t.tutorCopy(p.support,localizedCopy[p.text]||{en:p.text});break;
case 'pathCopy':value=t.getTutorPathCopy(p.key,p.support);break;
case 'status':value=t.uiStateLabel(p.state,p.support);break;
case 'agenda':value=f.getTutorAgendaSnapshot(p.items||[],p.progress||{});break;
case 'advance':value=f.advanceTutorAgendaProgress(p.items||[],p.progress||{});break;
case 'quiz':value=f.advanceTutorQuizAttempt(p.items||[],p.progress||{},p.correctItems||{},{correct:!!p.correct,passingScore:Infinity});break;
case 'matches':value={starter:t.getTutorStarterAgendaMatches(p.answer,p.target),direct:t.anyTutorPhraseIsDirectAnswer(p.phrases||[],p.answer),matches:(p.phrases||[]).filter(v=>t.tutorPhraseMatchesTranscript(v,p.answer)),prompted:t.extractPromptedTutorPhrases(p.assistant||''),meaningful:t.hasTutorMeaningfulTranscript(p.answer)};break;
case 'grade':{const a=p.parsed||{},confidence=a.confidence===undefined?1:Math.max(0,Math.min(1,Number(a.confidence)||0)),successful=(a.successful===true||a.success===true||a.accepted===true)&&confidence>=0.55;value={...a,confidence,successful,verdict:M${verdict.index}.resolveTutorTurnVerdict({localSuccessful:!!p.local,semanticAttempted:!!p.attempted,semanticSuccessful:successful,semanticConfidence:confidence})};break;}
case 'session':value={type:'realtime',model:p.model||'gpt-realtime-2.1-mini',output_modalities:['audio'],instructions:t.buildOpenAIResponseInstructionsPrefix(),audio:{input:{turn_detection:t.buildTutorTurnDetection(p.pause),transcription:t.buildTutorInputTranscription({inputLanguageCodes:t.getCurrentTutorInputLanguageCodes(),keywords:t.getCurrentTutorTranscriptionKeywords()})},output:{voice:t.normalizeOpenAITutorVoice(p.voice)}}};break;
case 'voice':value=t.normalizeOpenAITutorVoice(p.voice);break;
case 'sanitize':value=t.sanitizeTutorAssistantText(p.text);break;
case 'pairs':value=t.tidyPairs(p.pairs||[],p.text||'');break;
case 'translation':value=t.buildMessageTranslationPrompt(p.support,p.source);break;
case 'script':value=t.hasUnexpectedTutorTranscriptScript(p.text,[p.target,p.support]);break;
case 'resumeContext':value=M${controls.index}.buildRealtimeResumeContext(p.messages||[]);break;
case 'snapshotMessages':value=M${controls.index}.snapshotRealtimeMessages(p.messages||[]);break;
case 'resumeSpeech':{const events=[];M${controls.index}.resumeRealtimeSpeech({channel:{readyState:'open',send:raw=>events.push(JSON.parse(raw))},speech:p.speech,instructions:p.instructions||'',onComplete:()=>{}});value=events[0]||null;break;}
case 'response':value=M${composition.index}.composeOpenAIRealtimeResponseInstructions(t.buildOpenAIResponseInstructionsPrefix(),p.welcome?t.buildTutorWelcomeInstructions():p.kickoff?t.buildTutorKickoffInstructions():t.buildTutorFollowupInstructions(p.answer||'',p.accepted||[],p.verdict||'uncertain'),t.buildTutorResponseInstructionsSuffix());break;
case 'judge':value=t.buildTutorTurnSuccessJudgePrompt(p.answer||'',p.options||{});break;
case 'draft':value=d.normalizeTutorConversationDraftMessages(p.messages||[]);break;
case 'resume':value=d.getTutorConversationSessionState(p.record);break;
case 'completed':value=t.buildTutorCompletedAgendaData({lesson:p.lesson,unit:p.unit,targetLang:p.target,supportLang:p.support,starterProgress:p.progress,xpEarned:p.earned,forceComplete:true});break;
default:throw Error('Unknown Tutor operation '+op);}
return JSON.stringify(value===undefined?null:value);}};})()`;
const api=vm.runInNewContext(script,{console,Date,Math,JSON,Object,Array,String,Number,Boolean,Set,Map,RegExp,Intl});
await fs.writeFile(path.join(root,'Piyali/Resources/tutor-policy.js'),script);
await fs.writeFile(path.join(root,'docs/reference/tutor-source-manifest.json'),JSON.stringify({modules:[...modules.values()].filter(m=>m.selected.size).map(m=>({file:m.file,sha256:createHash('sha256').update(m.source).digest('hex'),declarations:[...m.selected].filter(n=>!(m===tutor&&adapters.has(n)))})),adapters:[...adapters],boundary:'Original pure declarations and prompt builders with explicit learner/lesson/agenda/reconnect snapshots. No React, source stores, Firebase, provider or transport executes. Regular agenda snapshot uses original item and progress helpers without its mount-time ref mutation; Swift owns sequencing and persistence.'},null,2)+'\n');
console.log(`Exported Tutor policy: ${script.length} bytes from ${emitted.size} modules.`);
for(const operation of ['starter','levels'])JSON.parse(api.run(operation,'{}'));

const canonical=value=>Array.isArray(value)?value.map(canonical):value&&typeof value==='object'?Object.fromEntries(Object.keys(value).sort().map(key=>[key,canonical(value[key])])):value;
const rows=[];const record=(operation,input)=>rows.push({operation,input,expected:JSON.parse(api.run(operation,JSON.stringify(canonical(input))))});
{const levels=JSON.parse(gunzipSync(await fs.readFile(path.join(root,'Piyali/Resources/tutor-curriculum-es.json.gz'))));for(const level of ['Pre-A1','A1']){const unit=levels[level][0],lesson=unit.lessons[0],p={target:'es',support:'en',level,lesson,unit,progress:{},earned:50,completed:true,answer:'hola'};for(const op of ['classify','response','judge'])record(op,p);}}
const focusBlueprint={goalId:'family',goalText:'Speak with family',dayKey:'2026-10-25',lang:'es',cefrLevel:'A1',curriculumCefrLevel:'A1',mode:'tutor',modes:['tutor','flashcards'],objective:'Greet a relative and ask how they are',scenario:'A short family call',targetLanguage:['Hola','¿Cómo estás?'],successCriteria:['Produce a greeting','Ask a question'],supports:['One model, then a fresh attempt']};
for(const support of ['en','ar'])for(const focus of [{surface:'tutor',targetLang:'es',supportLang:support,blueprint:focusBlueprint},{surface:'tutor',targetLang:'es',supportLang:support,mode:'tutor',stepIndex:1,plan:{dayKey:'2026-10-25',items:[{concept:'A greeting',expectedAnswer:'hola',cefrLevel:'Pre-A1'}],memoryIds:['public-memory']}},{surface:'tutor',targetLang:'ja',supportLang:support,stepIndex:0,plan:{dayKey:'2026-10-25',items:[{concept:'A greeting',expectedAnswer:'こんにちは',cefrLevel:'B1'}]}},{surface:'tutor',plan:{items:[]}}]){
 record('focusLesson',{focus});const lesson=JSON.parse(api.run('focusLesson',JSON.stringify({focus})));if(lesson){const p={target:focus.targetLang||'es',support,level:lesson.cefrLevel,unit:{cefrLevel:lesson.cefrLevel},lesson,earned:0,progress:{},goalFocus:focus.blueprint?focus:null,repairFocus:focus.blueprint?null:focus};for(const op of ['xp','content','state','session','response','judge','classify'])record(op,{...p,kickoff:true,answer:'hola'});}
}
const cefr=['Pre-A1','A1','A2','B1','B2','C1','C2'];
for(let mask=0;mask<128;mask++)record('earnedLevel',{status:Object.fromEntries(cefr.map((level,i)=>[level,{isComplete:!!(mask&(1<<i))}]))});
for(const entry of [null,{},{completed:0},{completed:86,total:86},{completed:87,total:86},{completed:10,total:0},{completed:'5',total:'5'},{completed:null,total:null},{completed:'unknown',total:'unknown'},{completed:-1,total:-1}])record('levelStats',{summary:entry===null?{}:{tutor:{levels:{pre_a1:entry}}},level:'Pre-A1',fallbackTotal:87,localCompleted:12});
const languages=['en','es','pt','fr','it','de','ja','hi','ar','zh'];
for(const target of ['es','ja','fr']){const levels=JSON.parse(gunzipSync(await fs.readFile(path.join(root,'Piyali/Resources/tutor-curriculum-'+target+'.json.gz'))));
 for(const level of ['Pre-A1','A1','B2']){const unit=levels[level][0],lesson=unit.lessons[0];
  for(const support of ['en','ar','hi']){const p={target,support,level,unit,lesson,progress:{},earned:0,turn:0,user:null,messages:[],persona:'Calm and clear'};for(const operation of ['content','state','classify','xp','session','response','judge','completed'])record(operation,{...p,answer:target==='es'?'hola':'public fixture',kickoff:true});if(level==='Pre-A1')record('response',{...p,welcome:true});}
 }}
{const levels=JSON.parse(gunzipSync(await fs.readFile(path.join(root,'Piyali/Resources/tutor-curriculum-es.json.gz')))),units=levels['Pre-A1'].slice(0,2),first=units[0].lessons[0].id,next=units[1].lessons[0].id;for(const records of [{},{[first]:{status:'completed'}},{[first]:{status:'completed'},[next]:{status:'in_progress'}},Object.fromEntries(units.flatMap(u=>u.lessons.map(l=>[l.id,{status:'completed'}])))])record('path',{units,records,id:first});}
for(const support of languages)for(const text of ['Continue','Lesson objectives','Lesson Review','Lesson progress'])record('copy',{support,text});
for(const answer of ['hola','¿cómo se dice hola?','me llamo Ana','こんにちは','I do not know','WRONG_FIXTURE',''])record('matches',{target:'es',answer,phrases:['hola'],assistant:'Say "hola".'});
for(const parsed of [{successful:true,confidence:0.9,objectiveAdvanced:true},{successful:true,confidence:0.2},{successful:false,confidence:0.9,mistake:true},{success:true},{accepted:true},{successful:false,confidence:0}])record('grade',{parsed,attempted:true});
const items=[{id:'a',goal:'Greet'},{id:'b',goal:'Ask a name'}];for(const progress of [{},{a:true},{a:true,b:true},{a:true,foreign:true}]){record('agenda',{items,progress});record('advance',{items,progress});record('quiz',{items,progress,correct:false,correctItems:{a:true}});}
record('draft',{messages:[{id:'a',role:'assistant',textFinal:'Hola',done:true,ts:1000},{id:'b',role:'assistant',textStream:'pending',done:false,ts:2000},{id:'c',role:'user',text:'Buenos días',ts:3000}]});
record('resume',{record:{status:'in_progress',conversationDraft:{version:1,messages:[{id:'a',role:'assistant',text:'Hola',ts:1000}]}}});
for(const voice of ['', 'ash','Aoede','marin','cedar','coral'])record('voice',{voice});
record('resumeSpeech',{speech:{text:'Say hola.'},instructions:'Public policy'});record('resumeContext',{messages:[{role:'assistant',textFinal:'Say hola.',interrupted:true}]});
for(const support of ['en','ar','hi'])record('translation',{support,source:'es'});
await fs.writeFile(path.join(root,'Tests/PiyaliCoreTests/Fixtures/tutor-source-policy.json.gz'),gzipSync(JSON.stringify(rows),{level:9}));
console.log(`Verified ${rows.length} source-executed Tutor cases.`);
const manifestPath=path.join(root,'docs/reference/tutor-source-manifest.json'),manifest=JSON.parse(await fs.readFile(manifestPath,'utf8'));manifest.fixtureCount=rows.length;manifest.translationAdapter={resource:'Piyali/Resources/app-copy.json.gz',sha256:createHash('sha256').update(await fs.readFile(path.join(root,'Piyali/Resources/app-copy.json.gz'))).digest('hex'),keys:['proficiency_speaking','proficiency_listening','proficiency_thinking']};await fs.writeFile(manifestPath,JSON.stringify(manifest,null,2)+'\n');
