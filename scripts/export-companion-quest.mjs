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
 const source=await fs.readFile(path.join(reference,file),'utf8'),ast=parse(source,{sourceType:'module'}),m={file,source,ast,bindings:new Map(),exports:new Map(),selected:new Set(),imports:new Map(),index:modules.size};modules.set(file,m);
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
 const p=m.bindings.get(name);if(!p)throw Error(`Missing binding ${m.file}:${name}`);
 if(m.file==='src/data/phonics/index.js'&&name==='getAuthoredPhonicsDeck')return; // Explicit authored-deck snapshot adapter, never a generated pronunciation fallback.
 if(m.file==='src/utils/companionMemory.js'&&name==='generateRepairDeckEntries'){await select(m,'langName');await select(m,'repairLessonLevelGuard');return;}
 if(p.isImportSpecifier()||p.isImportDefaultSpecifier()){
  const spec=p.parentPath.node.source.value;
  if(m.file==='src/utils/companionMemory.js'&&spec==='../hooks/useUserStore'){m.imports.set(name,{snapshot:true});return;}
  if(m.file==='src/constants/languages.js'&&spec==='../components/flagsIcons/flags'){m.imports.set(name,{unusedVisual:true});return;}
  if(!spec.startsWith('.'))throw Error(`Impure external dependency ${m.file}:${spec}`);
  let file=path.posix.normalize(path.posix.join(path.posix.dirname(m.file),spec));if(!path.extname(file))file+='.js';
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
for(const name of ['activeGoalFor','compactSummary','mergeEvidence'])await select(model,name);
const emitted=new Set(),ordered=[];
function emit(m,visiting=new Set()){
 if(emitted.has(m))return;if(visiting.has(m))throw Error('Circular pure module graph: '+m.file);visiting.add(m);
 for(const i of m.imports.values())if(i.module)emit(i.module,visiting);visiting.delete(m);
 const imports=[...m.imports].map(([name,i])=>`const ${name}=${i.snapshot?'snapshotStore':i.unusedVisual?'null':`M${i.module.index}.${i.local}`};`).join('\n');
 const declarations=[...m.selected].filter(n=>!m.imports.has(n)).map(n=>m.bindings.get(n)).sort((a,b)=>a.node.start-b.node.start).map(p=>{
 if(m.file==='src/data/phonics/index.js'&&p.node.id?.name==='getAuthoredPhonicsDeck')return 'function getAuthoredPhonicsDeck(target,support,level){return snapshotDecks[target+":"+support+":"+level]||[];}';
 if(m.file==='src/utils/companionMemory.js'&&p.node.id?.name==='generateRepairDeckEntries'){const original=m.source.slice(p.node.start,p.node.end);return original.slice(0,original.indexOf('  let raw =')).replace('async function','function')+'  return input;\n}';}
 return (p.isVariableDeclarator()?'const ':'')+m.source.slice(p.node.start,p.node.end)+(p.isVariableDeclarator()?';':'');}).join('\n');
 ordered.push(`// ${m.file}\nconst M${m.index}=(function(){\n${imports}\n${declarations}\nreturn {${[...m.selected].join(',')}};})();`);emitted.add(m);
}
emit(memory);emit(copy);emit(model);emit(phonics);
const deckFunction=memory.bindings.get('generateRepairDeckEntries').node,deckSource=memory.source.slice(deckFunction.start,deckFunction.end),deckParser='function parseRepairEntries(raw){'+deckSource.slice(deckSource.indexOf('  const text = String(raw'));
const bridge=`function run(operation,json){const p=JSON.parse(json),now=new SystemDate(p.now||SystemDate.now());Date=class extends SystemDate{constructor(...args){super(...(args.length?args:[now.getTime()]));}static now(){return now.getTime();}};snapshotUser=p.user||{};snapshotDecks=p.decks||{};try{const m=M${memory.index},c=M${copy.index},model=M${model.index};let value;
if(operation==='reusable')value=m.getReusableMemory(p.user,p.targetLang,now);
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
else if(operation==='bubble')value=c.buildQuestBubble(p);
else if(operation==='summary')value=c.companionMemorySummary(p.lang,p.concept);
else if(operation==='prepare'){const ranked=m.rankReusableNotes(p.notes||[]),goal=model.activeGoalFor(p.user,p.targetLang),goalProgress=model.compactSummary(p.user?.learningIntelligence?.[p.targetLang]?.goalProgress,'goal'),args={ranked,langKey:p.targetLang,appLanguage:p.appLanguage,todayCleared:p.todayCleared,carryOverKinds:p.carryOverKinds||[],targetDayKey:p.dayKey,now,goal};value={ranked,fallback:m.buildDeterministicBlueprint(args),prompt:m.buildBatchInput({...args,targetLang:p.targetLang,cefrLevel:p.cefrLevel,goal,goalProgress,performance:p.performance||m.generationPerformanceContextFor(p.user,p.targetLang)})};}
else if(operation==='assemble'){const parsed=m.parseBlueprintJson(p.raw);value=parsed?m.assembleAiBlueprint({...p,parsed,langKey:p.targetLang,targetDayKey:p.dayKey,now}):p.fallback;}
else throw Error('Unknown companion operation');return JSON.stringify(value??null);}finally{snapshotUser={};snapshotDecks={};Date=SystemDate;}}`;
const script=`// Generated source policy; no network, Firebase, UI stores or host bindings.\nvar PiyaliCompanionQuest=(function(SystemDate){\nlet Date=SystemDate,snapshotUser={},snapshotDecks={};const snapshotStore={getState:()=>({user:snapshotUser})};\n${ordered.join('\n')}\n${deckParser}\n${bridge}\nreturn {run};})(Date);\n`;
const api=Function(script+';return PiyaliCompanionQuest;')();
const rows=[],now='2026-10-23T12:00:00',dayKey='2026-10-23',targetLang='es';
const notes=[['a','Pronunciation','phonics',3],['b','Verb agreement','grammar',2],['c','Greetings','vocabulary',1],['d','  verb AGREEMENT  ','grammar',1]].map(([id,concept,errorType,severity])=>({id,concept,errorType,severity,createdDayKey:'2026-10-22',status:'captured',expectedAnswer:'Hola',userAnswer:'Ola',cefrLevel:'A1'}));
const user={schemaVersion:2,questDaysLoaded:{es_2026_10_23:true,'es_2026-10-23':true},companionMemory:{es:{notes}},learningIntelligence:{es:{activeGoal:{id:'goal',text:'Speak with family',status:'active'},goalProgress:{},repairSummary:{}}}};
function record(operation,input){const expected=JSON.parse(api.run(operation,JSON.stringify(input)));rows.push({operation,input,expected});return expected;}
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
await fs.writeFile(path.join(root,'Piyali/Resources/companion-quest-policy.js'),script);
await fs.writeFile(path.join(root,'Tests/PiyaliCoreTests/Fixtures/companion-quest-policy.json.gz'),gzipSync(JSON.stringify(rows),{level:9}));
await fs.writeFile(path.join(root,'docs/reference/companion-quest-source-manifest.json'),JSON.stringify({modules:[...modules.values()].filter(m=>m.selected.size).map(m=>({file:m.file,sha256:createHash('sha256').update(m.source).digest('hex'),declarations:[...m.selected]})),fixtureCount:rows.length,fixtureEncoding:"gzip(JSON)",snapshotAdapter:'An explicit clock scopes Date during each call for reproducibility. Only useUserStore.getState().user is replaced by the explicit plain input snapshot; all source I/O functions are excluded. The deck prompt and parser are split at the source network call; no provider code executes. Authored phonics selection reads the exact pre-exported deck snapshot. Unread flag component fields in language metadata are null; language labels/normalization remain source functions.'},null,2)+'\n');
console.log(`Exported ${rows.length} source-executed companion cases, ${script.length} bytes of pure policy.`);
