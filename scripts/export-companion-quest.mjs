// Read-only extraction of pure source policy. UI stores, Firebase and provider modules are never imported/executed.
import fs from 'node:fs/promises';
import path from 'node:path';
import {createRequire} from 'node:module';
import {createHash} from 'node:crypto';
import {gunzipSync,gzipSync} from 'node:zlib';
const root=process.cwd(),reference=path.resolve(root,'../nosabos/nosabos');
const require=createRequire(path.join(reference,'package.json')),{parse}=require('@babel/parser'),traverse=require('@babel/traverse').default;
const modules=new Map(),globals=new Set(['undefined','NaN','Infinity','String','Number','Boolean','Object','Array','JSON','Date','Math','Set','Map','RegExp','Error','Intl','parseInt','parseFloat','isNaN','isFinite']);
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
const memory=await moduleFor('src/utils/companionMemory.js'),copy=await moduleFor('src/utils/companionMemoryCopy.js'),model=await moduleFor('src/utils/learningIntelligenceModel.js');
const roots=['getTodaysCapturedNotes','getReusableMemory','rankReusableNotes','buildRepairPlan','getStoredRepairPlan','getStoredQuestExplanation','getStoredBlueprint','shouldRunDailyBatch','buildDeterministicBlueprint','buildBatchInput','parseBlueprintJson','assembleAiBlueprint','getRepairSteps','getNextRepairStep','buildEphemeralRepairLesson','generationPerformanceContextFor','buildRepairCard','generateRepairDeckEntries'];
for(const name of roots)await select(memory,name);
for(const name of ['buildQuestBubble','companionMemorySummary'])await select(copy,name);
const phonics=await moduleFor('src/data/phonics/index.js');await select(phonics,'getAuthoredPhonicsFocusCards');
for(const name of ['activeGoalFor','compactSummary','mergeEvidence','normalizeGoalBlueprint','goalModesFor','nextGoalMode','buildGoalLesson','goalInstructions'])await select(model,name);
const goalLessonProgress=await moduleFor('src/utils/lessonProgress.js'),goalCopy=await moduleFor('src/utils/learningGoalCopy.js');
for(const name of ['getGoalPreparationXp','nextGoalPreparationXp','isGoalLessonReady'])await select(goalLessonProgress,name);
for(const name of ['goalCopy','goalLessonCompletionCopy'])await select(goalCopy,name);
const review=await moduleFor('src/utils/flashcardReview.js'),flash=await moduleFor('src/components/FlashcardPractice.jsx'),flashTree=await moduleFor('src/components/FlashcardSkillTree.jsx'),flashColors=await moduleFor('src/data/flashcards/common.js');
for(const name of ['getFlashcardReviewSnapshot','getSchedulerRatingOptions','mapXpToReviewOutcome','formatAbsoluteReviewTime'])await select(review,name);
for(const name of ['buildFlashcardJudgePrompt','getFlashcardModalTrimTheme','getTranslation','LANG_NAME','getEffectiveCardLanguage'])await select(flash,name);
for(const name of ['getCardDecor','getWeaknessScore','isWeakCardSnapshot','buildFallbackActivityMap','APP_TEXT_PRIMARY'])await select(flashTree,name);
await select(flashColors,'CEFR_COLORS');
const flashSpeech=await moduleFor('src/hooks/useSpeechPractice.js');await select(flashSpeech,'buildRealtimeSpeechSession');
const flashNote=await moduleFor('src/utils/noteGeneration.js');await select(flashNote,'LANG_NAME');
const flashActivity=await moduleFor('src/utils/flashcardActivity.js');for(const name of ['mergeFlashcardActivityCounts','getFlashcardReviewPreviewCount'])await select(flashActivity,name);
const flashTarget=await moduleFor('src/utils/dailyQuestTargets.js');await select(flashTarget,'getFlashcardDailyTarget');
const flashLevels=await moduleFor('src/utils/cefrLevelInfo.js');await select(flashLevels,'CEFR_LEVEL_INFO');
const flashAppTokens=[...flash.bindings.keys()].filter(n=>n.startsWith('APP_'));for(const name of flashAppTokens)await select(flash,name);
const alphabet=await moduleFor('src/components/AlphabetBootcamp.jsx');
for(const name of ['uiText','PHONICS_CONTROLS','getLanguageName','getLetterName','getLetterSound','getLetterTip','getMeaningText','getPracticeLetterMarker','getHighlightedWordParts','buildAlphabetJudgePrompt'])await select(alphabet,name);
const phonicsCourse=await moduleFor('src/utils/phonicsCourseProgress.js');for(const name of ['getPhonicsCourseProgress','canAccessPhonicsLevel','resolvePhonicsLevel'])await select(phonicsCourse,name);
await select(phonics,'partitionPhonicsProgress');
const phonicsExtra=await moduleFor('src/utils/supplementalPhonics.js');for(const name of ['buildSupplementalPhonicsDeck','supplementalPhonicsRecord','restoreSupplementalPhonics','supplementalPhonicsEvents'])await select(phonicsExtra,name);
const narration=await moduleFor('src/utils/tts.js');for(const name of ['TTS_LANG_TAG','sanitizeVoice'])await select(narration,name);
const sourceTargets=Object.keys(phonics.bindings.get('PHONICS_CURRICULUM').node.init.arguments[0].properties.reduce((result,property)=>({...result,[property.key.name]:true}),{}));
const emitted=new Set(),ordered=[];
function emit(m,visiting=new Set()){
 if(emitted.has(m))return;if(visiting.has(m))throw Error('Circular pure module graph: '+m.file);visiting.add(m);
 for(const i of m.imports.values())if(i.module)emit(i.module,visiting);visiting.delete(m);
 const imports=[...m.imports].map(([name,i])=>`const ${name}=${i.literal?i.literal:i.flashcardCopy?'new Proxy({}, {get:(_,key)=>snapshotTranslations[key]})':i.snapshot?'snapshotStore':i.unusedVisual?'null':`M${i.module.index}.${i.local}`};`).join('\n');
 const declarations=[...m.selected].filter(n=>!m.imports.has(n)).map(n=>m.bindings.get(n)).sort((a,b)=>a.node.start-b.node.start).map(p=>{
 if(m.file==='src/components/FlashcardPractice.jsx'&&p.node.id?.name==='getAppLanguage')return 'const getAppLanguage=()=>snapshotAppLanguage;';
 if(m.file==='src/data/phonics/index.js'&&p.node.id?.name==='PHONICS_TARGETS')return 'const PHONICS_TARGETS=Object.freeze('+JSON.stringify(sourceTargets)+');';
 if(m.file==='src/data/phonics/index.js'&&p.node.id?.name==='getAuthoredPhonicsDeck')return 'function getAuthoredPhonicsDeck(target,support,level){return snapshotDecks[target+":"+support+":"+level]||[];}';
 if(m.file==='src/utils/companionMemory.js'&&p.node.id?.name==='generateRepairDeckEntries'){const original=m.source.slice(p.node.start,p.node.end);return original.slice(0,original.indexOf('  let raw =')).replace('async function','function')+'  return input;\n}';}
 return (p.isVariableDeclarator()?'const ':'')+m.source.slice(p.node.start,p.node.end)+(p.isVariableDeclarator()?';':'');}).join('\n');
 ordered.push(`// ${m.file}\nconst M${m.index}=(function(){\n${imports}\n${declarations}\nreturn {${[...m.selected].join(',')}};})();`);emitted.add(m);
}
emit(memory);emit(copy);emit(model);emit(phonics);emit(goalLessonProgress);emit(goalCopy);emit(review);emit(flash);emit(flashTree);emit(flashColors);emit(flashSpeech);emit(flashNote);emit(flashLevels);emit(flashActivity);emit(flashTarget);emit(alphabet);emit(phonicsCourse);emit(phonicsExtra);emit(narration);
const intelligenceFile='src/utils/learningIntelligence.js',intelligenceText=await fs.readFile(path.join(reference,intelligenceFile),'utf8');
let goalPlanTemplate,goalJudgeTemplate;traverse(parse(intelligenceText,{sourceType:'module'}),{TemplateLiteral(p){if(p.parentPath.isObjectProperty()&&p.parentPath.node.key.name==='input'&&intelligenceText.slice(p.node.start,p.node.end).includes('Plan ONE daily language Goal task.'))goalPlanTemplate=intelligenceText.slice(p.node.start,p.node.end);if(p.parentPath.isObjectProperty()&&p.parentPath.node.key.name==='input'&&intelligenceText.slice(p.node.start,p.node.end).includes("Evaluate this learner's attempt at their language goal."))goalJudgeTemplate=intelligenceText.slice(p.node.start,p.node.end);}});
if(!goalPlanTemplate||!goalJudgeTemplate)throw Error('Original daily Goal planner moved.');
const generator=require('@babel/generator').default;
function expression(m,name,owner){let found;traverse(m.ast,{VariableDeclarator(p){if(p.node.id.name!==name)return;if(owner&&!p.findParent(a=>a.isVariableDeclarator()&&a.node.id.name===owner))return;found=p.node.init;}});if(!found)throw Error('Flashcard expression moved: '+name+':'+owner);const copy=JSON.parse(JSON.stringify(found));traverse({type:'File',program:{type:'Program',sourceType:'module',body:[{type:'ExpressionStatement',expression:copy}]}},{JSXElement(p){p.replaceWith({type:'NullLiteral'});}});return generator(copy).code;}
const shells=['defaultModalShell','resultTheme','reviewButtonThemes'].map(name=>'const '+name+'='+expression(flash,name)+';').join('\n');
let cardPseudo;traverse(flashTree.ast,{JSXAttribute(p){if(p.node.name.name==='sx'&&p.findParent(a=>a.isVariableDeclarator()&&a.node.id.name==='FlashcardCard'))cardPseudo=generator(p.node.value.expression).code;}});if(!cardPseudo)throw Error('Original flashcard pseudo styles moved');
const cardVisualExpressions=['cardTextColor','cardTextShadow','glowColor','softGlowColor'].map(name=>'const '+name+'='+expression(flashTree,name,'FlashcardCard')+';').join('\n');
const revealTemplate=expression(flash,'prompt','revealAnswer'),explainTemplate=expression(flash,'prompt','handleExplainAnswer');
const gradeOwner=flash.bindings.get('FlashcardPractice'),gradeText=flash.source.slice(gradeOwner.node.start,gradeOwner.node.end),gradeParser=gradeText.slice(gradeText.indexOf('      const trimmed = (response'),gradeText.indexOf('      setIsCorrect(isYes)'));
if(!gradeParser.includes('let xp = 5'))throw Error('Flashcard grade parser moved');
const noteNode=flashNote.bindings.get('generateNoteContent').node,noteBody=flashNote.source.slice(noteNode.body.start+1,noteNode.body.end-1),notePromptBody=noteBody.slice(0,noteBody.indexOf('  try {'));
const noteParser=noteBody.slice(noteBody.indexOf('    const trimmed = (response'),noteBody.indexOf('  } catch'));
const noteFallback=noteBody.slice(noteBody.indexOf('    return {',noteBody.indexOf('  } catch')),noteBody.lastIndexOf('  }'));
const earnedExpression=expression(flash,'earnedXp','handleReviewRating');
const flashApp=await moduleFor('src/App.jsx'),persistedExpression=expression(flashApp,'xpAmount','persistFlashcardReview');
const flashRuntime=`function flashRun(op,p,now){const f=M${flash.index},r=M${review.index},t=M${flashTree.index},c=M${flashColors.index},isLightTheme=p.light!==false,isCorrect=Boolean(p.correct),assessmentMode=p.assessment||'ai',getTranslation=f.getTranslation,cefrColor=c.CEFR_COLORS[p.level||'Pre-A1'];
if(op==='flashPreview')return M${flashActivity.index}.getFlashcardReviewPreviewCount(p.saved,p.base);
if(op==='flashActivity')return M${flashActivity.index}.mergeFlashcardActivityCounts(p.saved,t.buildFallbackActivityMap(p.reviews));
if(op==='flashTarget')return M${flashTarget.index}.getFlashcardDailyTarget(p);
if(op==='flashLevels')return M${flashLevels.index}.CEFR_LEVEL_INFO;
if(op==='flashNotePrompt'){const {concept,userAnswer,wasCorrect,targetLang,supportLang,cefrLevel,moduleType}=p,LANG_NAME=M${flashNote.index}.LANG_NAME;${notePromptBody};return prompt;}
if(op==='flashNoteParse'){const response=p.raw,concept=p.concept,cefrLevel=p.cefrLevel,moduleType='flashcard';try{${noteParser}}catch{${noteFallback}}}
if(op==='flashSpeech')return M${flashSpeech.index}.buildRealtimeSpeechSession(p);
if(op==='flashGrade'){const response=p.raw;${gradeParser};return {correct:isYes,xp:isYes?xp:0,suggested:isYes?r.mapXpToReviewOutcome(xp):'again'};}
if(op==='flashReward'){const rating=p.rating,xpAwarded=p.xp||0;const earnedXp=${earnedExpression},card={xpReward:earnedXp},persistedXp=${persistedExpression};return {displayXp:earnedXp,persistedXp:p.focused?(rating==='good'||rating==='easy'?2:0):persistedXp,success:rating==='good'||rating==='easy'};}
if(op==='flashJudge')return f.buildFlashcardJudgePrompt(p);
if(op==='flashReveal'||op==='flashExplain'){const sourceText=p.concept,concept=p.concept,userAnswer=p.answer,effectiveCardLanguage=p.supportLang,targetLang=p.targetLang,LANG_NAME=f.LANG_NAME;return op==='flashReveal'?${revealTemplate}:${explainTemplate};}
if(op==='flashSnapshot')return r.getFlashcardReviewSnapshot(p.progress||{},now);
if(op==='flashRatings')return r.getSchedulerRatingOptions(p.progress||{},now);
if(op==='flashDate')return r.formatAbsoluteReviewTime(p.date,p.language,now);
if(op==='flashTheme'){const {${flashAppTokens.join(',')}}=f;${shells};return {shell:defaultModalShell,result:resultTheme,ratings:reviewButtonThemes,trim:f.getFlashcardModalTrimTheme(p.card||{},cefrColor,isLightTheme),decor:t.getCardDecor(p.status||'active',cefrColor,isLightTheme),cefr:cefrColor,visuals:(()=>{const status=p.status||'active',isDue=status==='due',isWeak=status==='weak',isLocked=status==='locked',isActionable=['active','due','weak'].includes(status),APP_TEXT_PRIMARY=t.APP_TEXT_PRIMARY;${cardVisualExpressions};return {sx:${cardPseudo},cardTextColor,cardTextShadow,glowColor,softGlowColor};})()};}
if(op==='flashWeak')return {weak:t.isWeakCardSnapshot(p.snapshot),score:t.getWeaknessScore(p.snapshot)};
throw Error('Unknown flashcard operation');}`;
const alphaText=alphabet.source.slice(alphabet.bindings.get('LetterCard').node.start,alphabet.bindings.get('LetterCard').node.end),alphaParser=alphaText.slice(alphaText.indexOf('      const trimmed = (response'),alphaText.indexOf('      setIsCorrect(isYes)'));
if(!alphaParser.includes('let xp = 1'))throw Error('Phonics grade parser moved');
const phonicsGeneration=await moduleFor('src/utils/phonicsDeckGeneration.js');let extraPrompt;
traverse(phonicsGeneration.ast,{CallExpression(p){if(p.node.callee.name==='callResponses')extraPrompt=generator(p.node.arguments[0].properties.find(p=>p.key.name==='input').value).code;}});if(!extraPrompt)throw Error('Phonics generation prompt moved');
const generationBody=phonicsGeneration.source.slice(phonicsGeneration.bindings.get('generateSupplementalPhonicsDeck').node.body.start+1,phonicsGeneration.bindings.get('generateSupplementalPhonicsDeck').node.body.end-1),extraParser=generationBody.slice(generationBody.indexOf('  const text ='));
const narrationExpression=expression(narration,'narrationSession');
const phonicsRuntime=`function phonicsRun(op,p,now){const a=M${alphabet.index},e=M${phonicsExtra.index},c=M${phonicsCourse.index};
if(op==='ph_tts'){const personality=p.personality||'',targetLangTag=M${narration.index}.TTS_LANG_TAG[p.language]||M${narration.index}.TTS_LANG_TAG.es,sanitizedVoice=M${narration.index}.sanitizeVoice(p.voice);return ${narrationExpression};}
if(op==='ph_copy')return {text:a.uiText(p.language,p.key,p.params),controls:a.PHONICS_CONTROLS[p.language],headline:a.uiText(p.language,'alphabetHeadline',{language:a.getLanguageName(p.targetLang,p.language)})};
if(op==='ph_card')return {name:a.getLetterName(p.card,p.language),sound:a.getLetterSound(p.card,p.language),tip:a.getLetterTip(p.card,p.language),meaning:a.getMeaningText(p.card.practiceWordMeaning,p.language),parts:a.getHighlightedWordParts(p.card.practiceWord,a.getPracticeLetterMarker(p.card))};
if(op==='ph_judge')return a.buildAlphabetJudgePrompt(p);
if(op==='ph_grade'){const response=p.raw;${alphaParser};return {correct:isYes,xp:isYes?xp:0};}
if(op==='ph_course')return c.getPhonicsCourseProgress(p);
if(op==='ph_access')return {allowed:c.canAccessPhonicsLevel(p.level,p.unlockedLevel,p.masterUnlocked),resolved:c.resolvePhonicsLevel(p.level,p.unlockedLevel,p.masterUnlocked)};
if(op==='ph_partition')return M${phonics.index}.partitionPhonicsProgress(p.cards,p.records);
if(op==='ph_generatePrompt'){const {target,support,level,existingWords=[]}=p,LANGUAGE_PROMPT_LABELS=a.LANGUAGE_PROMPT_LABELS,SUPPLEMENTAL_DECK_SIZE=6;return ${extraPrompt};}
if(op==='ph_generateParse'){const {raw,target,support,level,existingWords=[],batchId}=p,buildSupplementalPhonicsDeck=e.buildSupplementalPhonicsDeck;${extraParser}}
if(op==='ph_extraRecord')return e.supplementalPhonicsRecord(p.card);
if(op==='ph_extraRestore')return e.restoreSupplementalPhonics(p.target,p.support,p.level,p.records);
if(op==='ph_extraEvents')return e.supplementalPhonicsEvents(p.target,p.records);
throw Error('Unknown phonics operation');}`;
const deckFunction=memory.bindings.get('generateRepairDeckEntries').node,deckSource=memory.source.slice(deckFunction.start,deckFunction.end),deckParser='function parseRepairEntries(raw){'+deckSource.slice(deckSource.indexOf('  const text = String(raw'));
const bridge=`function run(operation,json){const p=JSON.parse(json),now=new SystemDate(p.now||SystemDate.now());Date=class extends SystemDate{constructor(...args){super(...(args.length?args:[now.getTime()]));}static now(){return now.getTime();}};snapshotUser=p.user||{};snapshotDecks=p.decks||{};snapshotTranslations=p.copy||{};snapshotAppLanguage=p.language||p.supportLang||'en';try{const m=M${memory.index},c=M${copy.index},model=M${model.index};let value;
if(operation.startsWith('ph_'))value=phonicsRun(operation,p,now);
else if(operation.startsWith('flash'))value=flashRun(operation,p,now);
else if(operation==='reusable')value=m.getReusableMemory(p.user,p.targetLang,now);
else if(operation==='captured')value=m.getTodaysCapturedNotes(p.user,p.targetLang,now);
else if(operation==='rank')value=m.rankReusableNotes(p.notes||[]);
else if(operation==='stored')value={blueprint:m.getStoredBlueprint(p.user,p.targetLang,p.dayKey),repair:m.getStoredRepairPlan(p.user,p.targetLang,p.dayKey),explanation:m.getStoredQuestExplanation(p.user,p.targetLang,p.dayKey),shouldRun:m.shouldRunDailyBatch(p.user,p.targetLang,p.dayKey,now)};
else if(operation==='steps')value=m.getRepairSteps(p.plan);
else if(operation==='next')value=m.getNextRepairStep(p.plan,p.completedCount);
else if(operation==='lesson')value=m.buildEphemeralRepairLesson(p);
else if(operation==='performance')value=m.generationPerformanceContextFor(p.user,p.targetLang);
else if(operation==='deckPrompt')value=m.generateRepairDeckEntries(p);
else if(operation==='deckCard')value=m.buildRepairCard(p);
else if(operation==='deckEntries')value=parseRepairEntries(p.raw);
else if(operation==='phonics')value=M${phonics.index}.getAuthoredPhonicsFocusCards(p.focus);
else if(operation==='evidence')value=model.mergeEvidence(p.summary,p.event,'repair',now.toISOString());
else if(operation==='goalPlan'){const user=p.user||{},lang=model.languageKey(p.targetLang),supportLang=p.supportLang||'en',dayKey=p.dayKey,cefrLevel=p.cefrLevel||'Pre-A1',goal=model.activeGoalFor(user,lang),bucket=user.learningIntelligence?.[lang]||{},compactSummary=model.compactSummary,context={goal,targetLang:lang,dayKey,cefrLevel,goalProgress:bucket.goalProgress,performance:m.generationPerformanceContextFor(user,lang,{curriculumCefrLevel:cefrLevel})};value=goal?{context,prompt:${goalPlanTemplate},fallback:model.normalizeGoalBlueprint(null,context)}:null;}
else if(operation==='goalJudgePrompt'){const focus={blueprint:p.blueprint,targetLang:p.targetLang,supportLang:p.supportLang},response=p.response||'',context=p.context||'';value=${goalJudgeTemplate};}
else if(operation==='goalParse')value=m.parseBlueprintJson(p.raw);
else if(operation==='goalNormalize')value=model.normalizeGoalBlueprint(p.raw,p.context);
else if(operation==='goalLesson')value=model.buildGoalLesson(p.blueprint);
else if(operation==='goalInstructions')value=model.goalInstructions(p.blueprint,p.supportLang);
else if(operation==='goalNext')value=model.nextGoalMode(p.bucket,p.blueprint);
else if(operation==='goalPreparation')value=M${goalLessonProgress.index}.nextGoalPreparationXp(p);
else if(operation==='goalReady')value=M${goalLessonProgress.index}.isGoalLessonReady(p.bucket,p.lesson);
else if(operation==='goalCopy')value=M${goalCopy.index}.goalCopy(p.lang);
else if(operation==='goalCompletionCopy')value=M${goalCopy.index}.goalLessonCompletionCopy(p.lang);
else if(operation==='bubble')value=c.buildQuestBubble(p);
else if(operation==='summary')value=c.companionMemorySummary(p.lang,p.concept);
else if(operation==='prepare'){const ranked=m.rankReusableNotes(p.notes||[]),goal=model.activeGoalFor(p.user,p.targetLang),goalProgress=model.compactSummary(p.user?.learningIntelligence?.[p.targetLang]?.goalProgress,'goal'),args={ranked,langKey:p.targetLang,appLanguage:p.appLanguage,todayCleared:p.todayCleared,carryOverKinds:p.carryOverKinds||[],targetDayKey:p.dayKey,now,goal};value={ranked,fallback:m.buildDeterministicBlueprint(args),prompt:m.buildBatchInput({...args,targetLang:p.targetLang,cefrLevel:p.cefrLevel,goal,goalProgress,performance:p.performance||m.generationPerformanceContextFor(p.user,p.targetLang)})};}
else if(operation==='assemble'){const parsed=m.parseBlueprintJson(p.raw);value=parsed?m.assembleAiBlueprint({...p,parsed,langKey:p.targetLang,targetDayKey:p.dayKey,now}):p.fallback;}
else throw Error('Unknown companion operation');return JSON.stringify(value??null);}finally{snapshotUser={};snapshotDecks={};snapshotTranslations={};Date=SystemDate;}}`;
const script=`// Generated source policy; no network, Firebase, UI stores or host bindings.\nvar PiyaliCompanionQuest=(function(SystemDate){\nlet Date=SystemDate,snapshotUser={},snapshotDecks={},snapshotTranslations={},snapshotAppLanguage='en';const snapshotStore={getState:()=>({user:snapshotUser})};\n${ordered.join('\n')}\n${deckParser}\n${flashRuntime}\n${phonicsRuntime}\n${bridge}\nreturn {run};})(Date);\n`;
const api=Function(script+';return PiyaliCompanionQuest;')();
function stableJSON(value){return JSON.stringify(value,(_,v)=>v&&typeof v==='object'&&!Array.isArray(v)?Object.fromEntries(Object.keys(v).sort().map(k=>[k,v[k]])):v);}
const rows=[],now='2026-10-23T12:00:00',dayKey='2026-10-23',targetLang='es';
const notes=[['a','Pronunciation','phonics',3],['b','Verb agreement','grammar',2],['c','Greetings','vocabulary',1],['d','  verb AGREEMENT  ','grammar',1]].map(([id,concept,errorType,severity])=>({id,concept,errorType,severity,createdDayKey:'2026-10-22',status:'captured',expectedAnswer:'Hola',userAnswer:'Ola',cefrLevel:'A1'}));
const user={schemaVersion:2,questDaysLoaded:{es_2026_10_23:true,'es_2026-10-23':true},companionMemory:{es:{notes}},learningIntelligence:{es:{activeGoal:{id:'goal',text:'Speak with family',status:'active'},goalProgress:{},repairSummary:{}}}};
function record(operation,input){const expected=JSON.parse(api.run(operation,stableJSON(input)));rows.push({operation,input,expected});return expected;}
for(const lang of ['en','es','pt','fr','it','de','ja','zh','ru','ar','hi'])for(const leadKind of ['welcome','welcomeGoal','fresh','repair','repairMulti'])for(const cleared of [false,true])record('bubble',{lang,leadKind,goal:'Speak with family',concept:'saludos',taskList:'Learn, Speak',cleared});
record('rank',{notes});record('reusable',{user,targetLang,now});record('captured',{user,targetLang,now});
for(const status of [null,'ready','failed','generating','other'])for(const startedAt of [0,Date.parse(now)-1])record('stored',{user:{...user,dailyQuestBlueprint:{es:{[dayKey]:status?{status,startedAt}:null}}},targetLang,dayKey,now});
for(const appLanguage of ['en','ar','de'])for(const todayCleared of [false,true]){
 const input={user,notes,targetLang,dayKey,now,appLanguage,todayCleared,carryOverKinds:['learn'],cefrLevel:'A1',performance:{suggestedQuestionLevel:'A1'}};
 const prepared=record('prepare',input);const steps=record('steps',{plan:prepared.fallback.repair});for(const step of steps)record('lesson',{user,...step,targetLang,cefrLevel:'A1',dayKey,recommendedMode:step.mode,stepIndex:step.index});
 for(const raw of ['invalid','```json\n'+JSON.stringify({message:{long:'A new plan'},repair:{items:[{memoryId:'a',mode:'phonics',prompt:'Di hola',answer:'Hola',tip:'Listen'},{memoryId:'forged',mode:'tutor',prompt:'Invalid'},{memoryId:'b',mode:'invalid',prompt:'Agreement'}]}})+'\n```']){
  const assembled=record('assemble',{...input,...prepared,raw});record('next',{plan:assembled.repair,completedCount:99});
 }
}
const decks=JSON.parse(gunzipSync(await fs.readFile(path.join(root,'Piyali/Resources/phonics.json.gz'))));
for(const targetLang of ['es','ja','fr'])for(const supportLang of ['en','ar'])for(const word of ['missing word',decks[targetLang+':'+supportLang+':A1']?.[0]?.practiceWord]){
 record('phonics',{decks:Object.fromEntries(Object.entries(decks).filter(([k])=>k.startsWith(targetLang+':'+supportLang+':'))),focus:{targetLang,supportLang,plan:{items:[{expectedAnswer:word,cefrLevel:'A1'}]}}});
}
for(const level of ['Pre-A1','A1','B2'])record('deckPrompt',{item:notes[0],targetLang:'es',supportLang:'ar',level,count:3});
for(const raw of ['bad','[]','```json\n[{"support":" Hi ","target":" Hola "},{"support":"","target":"skip"}]\n```'])record('deckEntries',{raw});
record('deckCard',{support:'Greeting',target:'Hola',supportBase:'en',targetBase:'es',langKey:'es',dayKey,stepIndex:1,cardIndex:0,level:'A1'});
for(const success of [true,false])record('evidence',{now,event:{id:'repair:a',target:'saludos',expectedAnswer:'Hola',mode:'tutor',domain:'conversation_flow',success,support:'prompted',observation:'Produced a greeting correctly'},summary:{}});
const goalRows=[];
function goalRecord(operation,input){const expected=JSON.parse(api.run(operation,stableJSON(input)));goalRows.push({operation,input,expected});return expected;}
for(const lang of ['en','es','pt','fr','it','de','ja','zh','ru','ar','hi']){goalRecord('goalCopy',{lang});goalRecord('goalCompletionCopy',{lang});}
for(const level of ['Pre-A1','A1','B2'])for(const mode of ['lesson','flashcards','tutor','phonics','conversation']){
 const context={goal:{id:'public-goal',text:'Speak with family'},targetLang:'es',dayKey,cefrLevel:level,goalProgress:{},performance:{suggestedQuestionLevel:level,eloRating:1100,curriculumCefrLevel:'A1'}};
 const bp=goalRecord('goalNormalize',{raw:{mode,objective:'Greet a family member',scenario:'Say hello to your grandmother',targetLanguage:['Hola'],supports:['A short model'],successCriteria:['Produce a greeting'],rationale:'Practice a useful greeting'},context});
 goalRecord('goalInstructions',{blueprint:bp,supportLang:'ar'});goalRecord('goalLesson',{blueprint:{...bp,mode:'lesson'}});
 goalRecord('goalNext',{bucket:{dailyGoal:{modeProgress:Object.fromEntries(bp.modes.map((m,i)=>[m,i===0?99:0]))}},blueprint:bp});
}
for(const supportLang of ['en','ar']){goalRecord('goalPlan',{user,targetLang:'es',supportLang,dayKey,cefrLevel:'A1',now});goalRecord('goalJudgePrompt',{blueprint:{goalText:'Speak with family',objective:'Greet a relative',scenario:'Say hello',successCriteria:['Produce a greeting'],targetLanguage:['Hola']},targetLang:'es',supportLang,response:'Hola, mamá',context:'A model was provided'});}
const lessonBlueprint={goalId:'public-goal',dayKey,mode:'lesson',lang:'es'},goalLesson={id:'goal-public-goal-'+dayKey,isGoal:true,goalBlueprint:lessonBlueprint,xpReward:20};
for(const earned of [0,9,19,20,21])for(const active of [true,false]){
 const bucket={activeGoal:{id:'public-goal',status:active?'active':'paused'},dailyGoal:{blueprint:lessonBlueprint,preparationXp:earned}};
 goalRecord('goalReady',{bucket,lesson:goalLesson});
 for(const amount of [0,3])goalRecord('goalPreparation',{bucket,focus:{npub:'public',targetLang:'es',blueprint:lessonBlueprint},npub:'public',targetLang:'es',dayKey,lessonId:goalLesson.id,amount});
}
await fs.writeFile(path.join(root,'Tests/PiyaliCoreTests/Fixtures/goal-source-policy.json.gz'),gzipSync(JSON.stringify(goalRows),{level:9}));
const flashRows=[],appCopy=JSON.parse(gunzipSync(await fs.readFile(path.join(root,'Piyali/Resources/app-copy.json.gz'))));
function flashRecord(operation,input){const p={copy:appCopy,now:'2026-10-24T12:00:00',...input};flashRows.push({operation,input:p,expected:JSON.parse(api.run(operation,stableJSON(p)))});}
for(const raw of ['YES | 4','YES | 6','YES | 7','YES','yes | 9','NO','unknown','YES | 4.8'])flashRecord('flashGrade',{raw});
for(const focused of [false,true])for(const correct of [false,true])for(const rating of ['again','hard','good','easy'])for(const xp of [0,4,6,7])flashRecord('flashReward',{focused,correct,rating,xp});
for(const language of ['en','ar','fr']){flashRecord('flashJudge',{language,concept:'mom',userAnswer:'mamá',targetLang:'es',supportLang:language,cefrLevel:'Pre-A1'});for(const op of ['flashReveal','flashExplain'])flashRecord(op,{language,concept:'mom',answer:'mama',targetLang:'es',supportLang:language});}
for(const light of [true,false])for(const level of ['Pre-A1','A1','B2'])for(const correct of [true,false])flashRecord('flashTheme',{light,level,correct});
for(const progress of [{},{schedulerState:'learning',nextReviewAt:'2026-10-24T12:10:00'},{schedulerState:'review',intervalDays:10,lapseCount:2,consecutiveCorrect:0,nextReviewAt:'2026-10-25T12:00:00'}]){const p={progress};flashRecord('flashSnapshot',p);flashRecord('flashRatings',p);}
for(const supportLang of ['en','ar','fr'])flashRecord('flashNotePrompt',{concept:'mom',userAnswer:'mama',wasCorrect:false,targetLang:'es',supportLang,cefrLevel:'Pre-A1',moduleType:'flashcard'});
for(const raw of ['{"example":"Mi mamá","summary":"A family word"}','{bad}','no JSON'])flashRecord('flashNoteParse',{raw,concept:'mom',cefrLevel:'Pre-A1'});
for(const [saved,base] of [[0,null],[0,0],[1,0],[7,4],[0,4]])flashRecord('flashPreview',{saved,base});
for(const target of [null,5])flashRecord('flashTarget',{userKey:'public-source-fixture',langKey:'es',dayKey:'2026-10-24',plateSnapshot:target?{courses:[{kind:'review',target}]}:{courses:[]}});
flashRecord('flashActivity',{saved:{'2026-10-24':2},reviews:{one:{lastReviewedAt:'2026-10-24T12:00:00'},two:{lastReviewedAt:'2026-10-24T12:00:00'},three:{completedAt:'2026-10-24T12:00:00'}}});
for(const targetLang of ['es','ar','ja','nah'])flashRecord('flashSpeech',{targetLang,transcriptionHint:'',timeoutMs:2000});
await fs.writeFile(path.join(root,'Tests/PiyaliCoreTests/Fixtures/flashcard-source-policy.json.gz'),gzipSync(JSON.stringify(flashRows),{level:9}));
const phonicsRows=[];function phRecord(operation,input){const p={language:'en',...input};phonicsRows.push({operation,input:p,expected:JSON.parse(api.run(operation,stableJSON(p)))});}
for(const language of ['es','ar','ja','nah'])phRecord('ph_tts',{language,voice:'ash'});
for(const raw of ['YES | 1','YES | 2','YES','yes | 7','NO','unknown','YES | 1.8'])phRecord('ph_grade',{raw});
for(const language of ['en','es','pt','it','fr','de','ja','hi','ar','zh']){for(const key of ['practice','record','next','tryAgain','progress','newRound','generateDeckError'])phRecord('ph_copy',{language,key,targetLang:'es'});phRecord('ph_judge',{practiceWord:'casa',userAnswer:'kasa',targetLang:'es',phoneme:'/a/',cefrLevel:'Pre-A1'});}
for(const [word,letter] of [['casa','a · /a/'],['Ababa','a'],['語',''],['','a']])phRecord('ph_card',{card:{authored:true,supportLanguage:'en',letter,practiceWord:word,practiceWordMeaning:{en:'word'},sound:'A sound',tip:'A tip'},language:'en'});
for(const level of ['Pre-A1','B1'])for(const counts of [{},{one:1},{one:2,two:1}])phRecord('ph_course',{cards:[{id:'one',cefrLevel:'Pre-A1'},{id:'two',cefrLevel:'A1'}],counts,courseLevel:level});
const phUnits=Array.from({length:6},(_,i)=>({grapheme:'a',exampleWord:'casa'+i,sound:'A sound',tip:'Keep it clear',meaning:'house'+i}));
phRecord('ph_generatePrompt',{target:'es',support:'en',level:'Pre-A1',existingWords:['mamá']});phRecord('ph_generateParse',{raw:JSON.stringify(phUnits),target:'es',support:'en',level:'Pre-A1',batchId:1792830600000000});
const phCards=JSON.parse(api.run('ph_generateParse',stableJSON({raw:JSON.stringify(phUnits),target:'es',support:'en',level:'Pre-A1',batchId:1792830600000000}))),phRecords=phCards.map(card=>JSON.parse(api.run('ph_extraRecord',stableJSON({card}))));
for(const records of [phRecords,phRecords.slice(1)])phRecord('ph_extraRestore',{target:'es',support:'en',level:'Pre-A1',records});
phRecord('ph_partition',{cards:phCards,records:phRecords.map((r,i)=>({...r,correctCount:i%2}))});
await fs.writeFile(path.join(root,'Tests/PiyaliCoreTests/Fixtures/phonics-source-policy.json.gz'),gzipSync(JSON.stringify(phonicsRows),{level:9}));
await fs.writeFile(path.join(root,'Piyali/Resources/companion-quest-policy.js'),script);
await fs.writeFile(path.join(root,'Tests/PiyaliCoreTests/Fixtures/companion-quest-policy.json.gz'),gzipSync(JSON.stringify(rows),{level:9}));
await fs.writeFile(path.join(root,'docs/reference/companion-quest-source-manifest.json'),JSON.stringify({modules:[...modules.values()].filter(m=>m.selected.size).map(m=>({file:m.file,sha256:createHash('sha256').update(m.source).digest('hex'),declarations:[...m.selected]})),fixtureCount:rows.length,goalFixtureCount:goalRows.length,flashcardFixtureCount:flashRows.length,phonicsFixtureCount:phonicsRows.length,phonicsAdapters:{targetLabels:{file:"src/data/phonics/names.js",sha256:createHash("sha256").update(modules.get("src/data/phonics/names.js").source).digest("hex"),scope:"Original literal default export; no source module is imported at runtime."},narration:"Original narrationSession expression and locale/voice helpers; native receive-only transport requires successful generation, buffer-stopped and the source minimum jitter-buffer tail before completion.",targets:"Exact PHONICS_CURRICULUM object keys replace loading authored payload modules; deck selection still uses exported authored snapshots.",grade:"Original 1-2 XP parser and pronunciation prompt; no source providers or stores execute.",generation:{file:phonicsGeneration.file,sha256:createHash('sha256').update(phonicsGeneration.source).digest('hex'),scope:"Original input expression and parser split at the network boundary."}},flashcardAdapters:{uiLanguage:"Explicit p.language snapshot replaces getAppLanguage; p.copy supplies the previously exported source string dictionaries.",visuals:"JSX icon elements are omitted from original plain theme values. UI and source provider/store code never execute in this bundle.",prompts:"Original judge, reveal, explanation, note prompts and parser are split at network boundaries; the original native capture session configuration is unchanged.",rewardHandler:{file:flashApp.file,sha256:createHash('sha256').update(flashApp.source).digest('hex'),expression:persistedExpression}},goalPlanner:{file:intelligenceFile,sha256:createHash('sha256').update(intelligenceText).digest('hex'),scope:'Original callResponses input template; source network/persistence code is excluded.'},fixtureEncoding:"gzip(JSON)",snapshotAdapter:'An explicit clock scopes Date during each call for reproducibility. Only useUserStore.getState().user is replaced by the explicit plain input snapshot; all source I/O functions are excluded. The deck prompt and parser are split at the source network call; no provider code executes. Authored phonics selection reads the exact pre-exported deck snapshot. Unread flag component fields in language metadata are null; language labels/normalization remain source functions.'},null,2)+'\n');
console.log(`Exported ${rows.length} source-executed companion cases and ${goalRows.length} goal cases, ${flashRows.length} flashcard cases, ${script.length} bytes of pure policy.`);
