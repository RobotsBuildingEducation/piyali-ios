// Execute the actual App.jsx conductor callbacks with explicit native I/O snapshots.
import fs from 'node:fs/promises';
import path from 'node:path';
import {createRequire} from 'node:module';
import {createHash} from 'node:crypto';
import {gzipSync} from 'node:zlib';
import vm from 'node:vm';
const root=process.cwd(),reference=path.resolve(root,'../nosabos/nosabos'),require=createRequire(path.join(reference,'package.json'));
const {parse}=require('@babel/parser'),traverse=require('@babel/traverse').default;
const source=await fs.readFile(path.join(reference,'src/App.jsx'),'utf8'),ast=parse(source,{sourceType:'module',plugins:['jsx']});
let bindings,effect;
traverse(ast,{FunctionDeclaration(p){if(p.node.id?.name==='App'){bindings=p.scope.bindings;}},CallExpression(p){if(p.node.callee.name==='useEffect'&&p.node.arguments[0]?.type==='ArrowFunctionExpression'){const fn=p.node.arguments[0],text=source.slice(fn.start,fn.end);if(text.includes('const justDone = plateSnapshot.courses'))effect=text;}}});
if(!bindings||!effect)throw Error('Actual plate conductor moved.');
const callback=name=>{const node=bindings[name]?.path.node.init;if(node?.callee?.name!=='useCallback')throw Error('Missing '+name);return source.slice(node.arguments[0].start,node.arguments[0].end)};
const named=name=>{const node=bindings[name]?.path.node;if(node?.type!=='VariableDeclarator')throw Error('Missing '+name);return source.slice(node.init.start,node.init.end)};
const stateFile=await fs.readFile(path.join(reference,'src/utils/dailyQuestState.js'),'utf8');let keyFunction;
traverse(parse(stateFile,{sourceType:'module'}),{FunctionDeclaration(p){if(p.node.id.name==='buildPlateCelebrationKey')keyFunction=stateFile.slice(p.node.start,p.node.end)}});
const script=`// Generated from the read-only web App's plate callbacks. Native code owns UI, persistence and activity routing.
(function(){
${keyFunction}
let scope='',clock=0,nextTimer=0,timers=new Map(),p={},actions=[],lastSnapshot='',plateSnapshot={},plateSessionActive=false,plateCelebration=null;
let platePrevSnapshotRef={current:null},plateConductorArmedRef={current:false},pendingPlateCelebrationRef={current:null},plateCelebrationFlushTimerRef={current:null},plateClearedCelebratedKeyRef={current:''},plateCourseCelebratedKeysRef={current:new Set()},plateCelebrationBlockersRef={current:{}},lessonCompletionSequenceActiveRef={current:false},pendingLessonCompletionRef={current:null},pendingDailyGoalCelebrationRef={current:null},pendingTutorialBitcoinModalRef={current:null};
const Date={now:()=>clock},document={},window={setTimeout:(fn,delay)=>{const id=++nextTimer;timers.set(id,{at:clock+(Number(delay)||0),fn});return id},clearTimeout:id=>timers.delete(id),dispatchEvent:event=>actions.push({type:'courseComplete',kind:event.detail.kind})},setTimeout=window.setTimeout,clearTimeout=window.clearTimeout;
function CustomEvent(type,{detail}){this.type=type;this.detail=detail;}
const useModalStore={getState:()=>({})},isTutorCompletionSequencePending=()=>false,hasVisibleChakraModalSurface=()=>false;
const playSound=name=>actions.push({type:'sound',name}),setPlateCelebration=value=>{plateCelebration=typeof value==='function'?value(plateCelebration):value;plateCelebrationBlockersRef.current.plateCelebrationOpen=!!plateCelebration;},endPlateSession=()=>{plateSessionActive=false;actions.push({type:'endSession'})},getNextPlateCourse=snap=>snap.courses.find(c=>!c.done)?.kind||null,getGoalCompletionDetails=()=>p.goalDetails||null,getRepairCompletionDetails=()=>p.repairDetails||null;
const navigateToPlateCourse=course=>actions.push({type:'navigate',course}),goToSkillTreeMode=mode=>actions.push({type:'surface',mode});
let viewMode='skillTree',activeLesson=null;
const flushPlateCelebrationWhenQuiet=${callback('flushPlateCelebrationWhenQuiet')};
const requestPlateCelebration=${callback('requestPlateCelebration')};
const observe=${effect};
const handlePlateCelebrationContinue=${named('handlePlateCelebrationContinue')};
function reset(next){scope=next;timers.clear();platePrevSnapshotRef.current=null;plateConductorArmedRef.current=false;pendingPlateCelebrationRef.current=null;plateCelebrationFlushTimerRef.current=null;plateClearedCelebratedKeyRef.current='';plateCourseCelebratedKeysRef.current=new Set();plateCelebration=null;lastSnapshot='';window.setTimeout(()=>{plateConductorArmedRef.current=true},2000);}
return {run:function(op,input){p=JSON.parse(input||'{}');clock=Number(p.now)||0;actions=[];if(scope!==p.scope)reset(p.scope);plateSnapshot=p.snapshot||{courses:[],byKind:{}};plateSessionActive=!!p.guided;viewMode=p.ephemeralLesson?'lesson':'skillTree';activeLesson=p.ephemeralLesson?{isRepair:true}:null;plateCelebrationBlockersRef.current={native:!!p.blocked,plateCelebrationOpen:!!plateCelebration};
if(op==='continue')handlePlateCelebrationContinue();else if(op==='step'){const encoded=JSON.stringify(plateSnapshot);if(lastSnapshot!==encoded){lastSnapshot=encoded;observe();}if(p.bonusJustClaimed)requestPlateCelebration({type:'cleared'});const due=[...timers].filter(([,v])=>v.at<=clock).sort((a,b)=>a[1].at-b[1].at||a[0]-b[0]);for(const[id,timer]of due){if(timers.delete(id))timer.fn();}}
else throw Error('Unknown plate operation '+op);
return JSON.stringify({pending:pendingPlateCelebrationRef.current,visible:plateCelebration,actions,nextWake:timers.size?Math.min(...[...timers.values()].map(v=>v.at)):null,armed:plateConductorArmedRef.current});}};})()`;
await fs.writeFile(path.join(root,'Piyali/Resources/plate-session-policy.js'),script);
const snapshot=counts=>{const courses=Object.entries(counts).map(([kind,count])=>({kind,count,target:kind==='review'?5:1,done:count>=(kind==='review'?5:1)}));return {langKey:'es',dayKey:'2026-10-25',courses,byKind:Object.fromEntries(courses.map(c=>[c.kind,c])),isCleared:courses.every(c=>c.done)}};
const rows=[];
function journey(name,steps){const api=vm.runInNewContext(script),base={scope:'alice:es:2026-10-25',now:0,guided:true,blocked:false,snapshot:snapshot({speak:0,learn:0,review:0})};let args=base;const cases=[];for(const step of steps){args={...args,...step};const operation=step.operation||'step';delete args.operation;cases.push({operation,input:args,expected:JSON.parse(api.run(operation,JSON.stringify(args)))});}rows.push({name,cases});}
journey('Tutor chain, two quiet checks, next route, duplicate snapshot',[{}, {now:2100},{now:2200,snapshot:snapshot({speak:1,learn:0,review:0}),blocked:true},{now:2600},{now:2720,blocked:false},{now:2970},{now:3000,operation:'continue'},{now:3200}]);
journey('Standalone lesson stays on its surface',[{guided:false},{now:2100},{now:2200,snapshot:snapshot({speak:0,learn:1,review:0})},{now:2600},{now:4900},{now:5000,operation:'continue'}]);
journey('Clear before bonus, duplicate bonus, home on dismissal',[{}, {now:2100},{now:2200,snapshot:snapshot({speak:1,learn:1,review:5})},{now:2600},{now:4900},{now:5000,bonusJustClaimed:true,guided:false},{now:5100,operation:'continue',bonusJustClaimed:false}]);
journey('Hydration cannot celebrate saved completions',[{snapshot:snapshot({speak:1,learn:1,review:5})},{now:2100},{now:2500},{now:9000}]);
journey('Standalone final bonus acknowledgement',[{guided:false},{now:2100},{now:2200,snapshot:snapshot({speak:1,learn:1,review:5}),bonusJustClaimed:true},{now:2300,bonusJustClaimed:false},{now:2400,operation:'continue'}]);
journey('Repair intermediate step routes without a modal',[{snapshot:{...snapshot({repair:0,review:0}),courses:[{kind:'repair',count:0,target:3,done:false},{kind:'review',count:0,target:5,done:false}],byKind:{repair:{count:0,target:3,done:false},review:{count:0,target:5,done:false}}}},{now:2100},{now:2200,snapshot:{...snapshot({repair:0,review:0}),courses:[{kind:'repair',count:1,target:3,done:false},{kind:'review',count:0,target:5,done:false}],byKind:{repair:{count:1,target:3,done:false},review:{count:0,target:5,done:false}}}},{now:2201}]);
await fs.writeFile(path.join(root,'Tests/PiyaliCoreTests/Fixtures/plate-session-policy.json.gz'),gzipSync(JSON.stringify(rows),{level:9}));
await fs.writeFile(path.join(root,'docs/reference/plate-session-source-manifest.json'),JSON.stringify({sources:[{file:'src/App.jsx',sha256:createHash('sha256').update(source).digest('hex'),declarations:['flushPlateCelebrationWhenQuiet','requestPlateCelebration','handlePlateCelebrationContinue','course-completion useEffect']},{file:'src/utils/dailyQuestState.js',sha256:createHash('sha256').update(stateFile).digest('hex'),declarations:['buildPlateCelebrationKey']}],adapters:'Explicit plate snapshots, guided flag, native modal blockers, Goal/repair details, deterministic Date/timers, route/sound/voice-stop actions. No React, DOM, Firebase, browser storage or network executes. Source course effect and quiet-queue callbacks are unchanged.',journeys:rows.length,cases:rows.reduce((sum,v)=>sum+v.cases.length,0)},null,2)+'\n');
console.log('Exported original plate conductor: '+rows.length+' journeys.');
// Copy strings and the actual source modal into the read-only browser harness.
const esbuild=require('esbuild');
const built=await esbuild.build({stdin:{contents:`export * from ${JSON.stringify(path.join(reference,'src/utils/dailyPlateCopy.js'))};`,resolveDir:reference},bundle:true,platform:'node',format:'esm',write:false,plugins:[{name:'copy-icons',setup(build){build.onResolve({filter:/^react-icons\//},()=>({path:'icons',namespace:'copy'}));build.onLoad({filter:/.*/,namespace:'copy'},()=>({contents:'export const PiCardsBold=null,PiPath=null,RiBook2Line=null,RiChat3Line=null,RiMagicLine=null,LuLanguages=null;'}));}}]});
const copy=await import('data:text/javascript;base64,'+Buffer.from(built.outputFiles[0].text).toString('base64')),locales=['en','es','pt','fr','it','de','ja','hi','ar','zh'];
await fs.writeFile(path.join(root,'Piyali/Resources/plate-completion-copy.json.gz'),gzipSync(JSON.stringify(Object.fromEntries(locales.map(lang=>[lang,Object.fromEntries(Object.entries(copy.PLATE_PRACTICE_DETAILS_COPY).map(([key,value])=>[key,copy.plateUiCopy(lang,value)]))]))),{level:9}));
const functions={};let modal;
traverse(ast,{FunctionDeclaration(p){if(['PracticeCompletionDetails','SparkleFrame','SparkleShape'].includes(p.node.id?.name))functions[p.node.id.name]=source.slice(p.node.start,p.node.end)},JSXElement(p){const name=p.node.openingElement.name;if(name.type==='JSXIdentifier'&&name.name==='Modal'&&source.slice(p.node.start,p.node.start+100).includes('isOpen={!!plateCelebration}'))modal=source.slice(p.node.start,p.node.end)}});
if(!modal||Object.keys(functions).length!==3)throw Error('Original plate modal moved.');
const harness=`// Actual source modal and helpers. Only its state, navigation and content inputs are public fixtures.
import React,{useMemo,useState} from 'react';import {Box,VStack,HStack,Text,Button,Modal,ModalOverlay,ModalContent,ModalBody,Accordion,AccordionItem,AccordionButton,AccordionIcon,AccordionPanel} from '@chakra-ui/react';
import RandomCharacter from '/src/components/RandomCharacter';import {PLATE_BONUS_TOAST_COPY,PLATE_CLEARED_COPY,PLATE_CLOSE_COPY,PLATE_CONTINUE_COPY,PLATE_COURSE_META,PLATE_EXERCISE_COMPLETE_COPY,PLATE_PRACTICE_DETAILS_COPY,PLATE_NEXT_COPY,PLATE_VIEW_NOTES_COPY,plateUiCopy} from '/src/utils/dailyPlateCopy';
const DAILY_PLATE_BONUS_XP=25;${Object.values(functions).join('\n')}
export default function SourcePlateCompletion(){const q=new URLSearchParams(location.search),appLanguage=q.get('language')||'en',kind=q.get('kind')||'course',details=q.get('details')==='1'?{what:'Greet a relative',why:'A short family call'}:null;const [plateCelebration,setPlateCelebration]=useState(kind==='cleared'?{type:'cleared',details}:{type:'course',completed:'speak',next:q.get('standalone')==='1'?null:'learn',details}),[notes,setNotesOpen]=useState(false);const nativeModalMotionProps=undefined,nativeOverlayMotionProps=undefined,handlePlateCelebrationContinue=()=>setPlateCelebration(null);return <><Box data-testid='plate-result' display='none'>{notes?'notes':plateCelebration?'open':'closed'}</Box>${modal}</>;}
`;
await fs.writeFile(path.join(root,'.reference-preview/reference-plate-completion.jsx'),harness);
let dailyModal,dailyNode;
traverse(ast,{JSXElement(p){if(p.node.openingElement.name.name==='Modal'&&source.slice(p.node.start,p.node.start+100).includes('isOpen={celebrateOpen}')){dailyModal=source.slice(p.node.start,p.node.end);dailyNode=p.node}}});
if(!dailyModal)throw Error('Daily goal modal moved');
const dailyObjects=[];
traverse(dailyNode,{noScope:true,CallExpression(p){if(p.node.callee.name==='uiCopy'){const obj=p.node.arguments[1];if(obj.type==='ObjectExpression')dailyObjects.push(Object.fromEntries(obj.properties.map(v=>[v.key.name??v.key.value,v.value.value])))}}});
const dailyKeys=['title','subtitle','goal','streak','continue'];if(dailyObjects.length!==dailyKeys.length)throw Error('Daily modal copy changed');
await fs.writeFile(path.join(root,'Piyali/Resources/daily-goal-celebration-copy.json.gz'),gzipSync(JSON.stringify(Object.fromEntries(locales.map(lang=>[lang,Object.fromEntries(dailyKeys.map((key,i)=>[key,dailyObjects[i][lang]??dailyObjects[i].en]))]))),{level:9}));
const dailyHarness=`import React from 'react';import {Box,VStack,HStack,Text,Button,Modal,ModalOverlay,ModalContent,ModalBody} from '@chakra-ui/react';import DailyGoalPetPanel from '/src/components/DailyGoalPetPanel';
export default function SourceDailyGoalReward(){const q=new URLSearchParams(location.search),appLanguage=q.get('language')||'en',celebrateOpen=true,nativeModalMotionProps=undefined,nativeOverlayMotionProps=undefined,handleCloseDailyGoalModal=()=>{},uiCopy=(lang,copy)=>copy[lang]||copy.en,dailyGoalTarget=100,celebrationPetHealth=100,celebrationPetDelta=15,user={},dailyGoalPetType='ghost',companionLevel=2;return ${dailyModal};}`;
await fs.writeFile(path.join(root,'.reference-preview/reference-daily-goal-completion.jsx'),dailyHarness);
// Record the actual SoundManager note/envelope calls and render their sine
// voices to portable PCM. No Tone/browser audio runtime is shipped in the app.
const soundSource=await fs.readFile(path.join(reference,'src/utils/SoundManager.js'),'utf8'),soundNodes={};
traverse(parse(soundSource,{sourceType:'module',plugins:['classProperties']}),{ObjectProperty(p){if(['questComplete','questCleared'].includes(p.node.key.name))soundNodes[p.node.key.name]=soundSource.slice(p.node.value.start,p.node.value.end)}});
const soundRows=[];
for(const [name,fn] of Object.entries(soundNodes)){
 const notes=[],adapter={createDisposablePolySynth:(envelope,volume)=>({triggerAttackRelease:(pitch,duration,at)=>{for(const note of Array.isArray(pitch)?pitch:[pitch])notes.push({note,duration,at,envelope,volume})}})};
 const callback=vm.runInNewContext(`(function(){return ${fn}})`,{Tone:{now:()=>0},VOL:{SOFT:-16,NORMAL:-12,PROMINENT:-10,LOUD:-8}}).call(adapter);callback();
 const rate=44100,length=Math.ceil(Math.max(...notes.map(n=>n.at+2/Number(n.duration.slice(0,-1))+n.envelope.release))*rate),samples=new Float64Array(length);
 for(const note of notes){const match=/^([A-G])(#?)(\d)$/.exec(note.note),semitone={C:0,D:2,E:4,F:5,G:7,A:9,B:11}[match[1]]+(match[2]?1:0),frequency=440*2**(((Number(match[3])+1)*12+semitone-69)/12),hold=2/Number(note.duration.slice(0,-1)),env=note.envelope,gain=0.7*10**(note.volume/20);
  const envelope=t=>t<env.attack?t/env.attack:t<env.attack+env.decay?env.sustain+(1-env.sustain)*Math.exp(-6*(t-env.attack)/env.decay):env.sustain;
  for(let i=Math.floor(note.at*rate);i<Math.min(length,Math.ceil((note.at+hold+env.release)*rate));i++){const t=i/rate-note.at,level=t<hold?envelope(Math.max(0,t)):envelope(hold)*Math.exp(-8*(t-hold)/env.release);samples[i]+=Math.sin(2*Math.PI*frequency*t)*level*gain;}
 }
 const output=Buffer.alloc(44+length*2);output.write('RIFF');output.writeUInt32LE(36+length*2,4);output.write('WAVEfmt ',8);output.writeUInt32LE(16,16);output.writeUInt16LE(1,20);output.writeUInt16LE(1,22);output.writeUInt32LE(rate,24);output.writeUInt32LE(rate*2,28);output.writeUInt16LE(2,32);output.writeUInt16LE(16,34);output.write('data',36);output.writeUInt32LE(length*2,40);
 samples.forEach((v,i)=>output.writeInt16LE(Math.round(Math.max(-1,Math.min(1,v))*32767),44+i*2));await fs.writeFile(path.join(root,'Piyali/Resources',name+'.wav'),output);soundRows.push({name,notes,seconds:length/rate});
}
const manifestPath=path.join(root,'docs/reference/plate-session-source-manifest.json'),manifest=JSON.parse(await fs.readFile(manifestPath,'utf8'));manifest.sources.push({file:'src/utils/SoundManager.js',sha256:createHash('sha256').update(soundSource).digest('hex'),declarations:Object.keys(soundNodes)});for(const file of ['src/utils/dailyPlateCopy.js','src/theme.js','src/index.css','src/components/DailyGoalPetPanel.jsx']){const content=await fs.readFile(path.join(reference,file),'utf8');manifest.sources.push({file,sha256:createHash('sha256').update(content).digest('hex')});}
manifest.nativeAudio='Actual source note pitches, timing, envelope parameters and gain. PCM synthesis approximates Tone exponential envelopes at 120 BPM; no network or audio runtime executes.';manifest.sounds=soundRows;await fs.writeFile(manifestPath,JSON.stringify(manifest,null,2)+'\n');
