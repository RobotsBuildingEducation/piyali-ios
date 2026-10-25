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
const languageModule=await moduleFor('src/constants/languages.js');await select(languageModule,'getLanguageLocale');
const study=await moduleFor('src/utils/noteGeneration.js');await select(study,'generateNoteContent');
const memory=await moduleFor('src/utils/companionMemory.js'),copy=await moduleFor('src/utils/companionMemoryCopy.js'),journey=await moduleFor('src/utils/voiceJourneyCopy.js'),journeyModel=await moduleFor('src/utils/voiceJourneyModel.js');
const roots=['generateMemorySummaryText','enrichNoteFields','memoryLogSignature','memoryNoteMatchesSupportLanguage','cleanMemoryConceptForSupportLanguage','getCompanionNotes'];
for(const name of roots)await select(memory,name);
for(const name of ['memoryCopy','MEMORY_CARD_COPY','MEMORY_DRAWER_COPY','memoryStatusLabel'])await select(copy,name);
await select(journey,'journeyCopy');
for(const name of ['JOURNEY_MILESTONES','journeySessionCount','completeJourneyQuest','pendingJourneyMilestone','journeyBaseline','isJourneyMilestoneExpired','canRecordJourneyMilestone'])await select(journeyModel,name);
const drawer=await moduleFor('src/components/NotesDrawer.jsx'),cards=await moduleFor('src/components/CompanionMemoryList.jsx');
for(const name of ['CEFR_LEVELS','CEFR_COLORS','CEFR_TEXT_COLORS','MODULE_LABELS'])await select(drawer,name);
for(const name of ['SOURCE_LABELS','STATUS_ACCENT','resolveStatus'])await select(cards,name);
const emitted=new Set(),ordered=[];
function emit(m){if(emitted.has(m))return;for(const v of m.imports.values())if(v.module)emit(v.module);
 const imports=[...m.imports].map(([name,v])=>`const ${name}=${v.responses?'callNativeResponses':v.model?"'source-default'":v.unusedVisual?'null':`M${v.module.index}.${v.local}`};`).join('\n');
 const declarations=[...m.selected].filter(n=>!m.imports.has(n)).map(n=>m.bindings.get(n)).sort((a,b)=>a.node.start-b.node.start).map(p=>{
  let text=(p.isVariableDeclarator()?'const ':'')+m.source.slice(p.node.start,p.node.end)+(p.isVariableDeclarator()?';':'');
  if(['generateMemorySummaryText','enrichNoteFields','generateNoteContent'].includes(p.node.id.name)){const count=(text.match(/await callResponses/g)||[]).length;if(count!==(p.node.id.name==='generateNoteContent'?1:2))throw Error('Response boundary moved: '+p.node.id.name);text=text.replace('async function','function').replaceAll('await callResponses','callResponses');}
  return text;
 }).join('\n');ordered.push(`// ${m.file}\nconst M${m.index}=(function(){${imports}\n${declarations}\nreturn {${[...m.selected].join(',')}};})();`);emitted.add(m);
}
for(const m of [memory,copy,journey,journeyModel,drawer,cards,study])emit(m);
// Inline copy expressions and formatting remain exactly as authored in NotesDrawer.
const names=['clearAllLabel','lessonLabel','noNotesLabel','noteTitleFallback','formatNoteCountLabel','listenLabel','deleteNoteLabel'];let scope;
traverse(drawer.ast,{FunctionDeclaration(p){if(p.node.id?.name==='NotesDrawer')scope=p.scope;}});
const labels=names.map(name=>{const node=scope.bindings[name]?.path.node;if(!node)throw Error('Drawer copy moved: '+name);return `const ${name}=${drawer.source.slice(node.init.start,node.init.end)};`}).join('\n');
const script=`// Generated source policies; Swift owns persistence, provider calls and UI.
(function(){const SystemDate=globalThis.Date;let Date=SystemDate,p={},requests=[],index=0;
const console={error:()=>{}};function callNativeResponses(request){requests.push(request.input);const value=(p.responses||[])[index++];if(value?.nativeFailure)throw Error('provider');return value||'';}
${ordered.join('\n')}
return {run:function(operation,json){p=JSON.parse(json||'{}');requests=[];index=0;const now=p.now?new SystemDate(p.now):new SystemDate();Date=class extends SystemDate{constructor(...args){super(...(args.length?args:[now.getTime()]));}static now(){return now.getTime();}};const lang=p.language||'en',locale=M${languageModule.index}.getLanguageLocale(lang);${labels}
const m=M${memory.index},c=M${copy.index},j=M${journeyModel.index};let value;
if(operation==='note')value=M${study.index}.generateNoteContent({...p,targetLang:p.target||'es',supportLang:lang});
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
await fs.writeFile(path.join(root,'Tests/PiyaliCoreTests/Fixtures/memory-policy.json.gz'),gzipSync(JSON.stringify(rows),{level:9}));
await fs.writeFile(path.join(root,'docs/reference/memory-source-manifest.json'),JSON.stringify({sources:[...modules.values()].filter(m=>m.selected.size).map(m=>({file:m.file,sha256:createHash('sha256').update(m.source).digest('hex'),declarations:[...m.selected]})),adapters:'Only provider awaits become explicit synchronous response snapshots; native code executes their recorded requests and retries. Original prompts, parsers, language guards, signatures, status and copy rules remain. No stores, React, DOM, Firebase or network executes.',cases:rows.length},null,2)+'\n');
console.log('Memory policy: '+rows.length+' source cases.');
