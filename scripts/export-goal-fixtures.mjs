import fs from 'node:fs/promises';
import path from 'node:path';
const reference = process.argv[2];
if (!reference) throw new Error('Supply the read-only reference checkout path.');
const source = await fs.readFile(path.join(reference,'src/utils/learningIntelligenceModel.js'),'utf8');
const model = await import('data:text/javascript;base64,'+Buffer.from(source).toString('base64'));
const modes = [];
for (const goalId of ['goal-one','goal-two','language-ñ','learner-🐈']) {
  for (const preferredMode of ['tutor','phonics','flashcards','lesson','']) {
    for (const allowFocusedCards of [true,false]) {
      const input = {goalId,dayKey:'2026-10-13',preferredMode,allowFocusedCards};
      modes.push({...input,expected:model.selectGoalModes(input)});
    }
  }
}
const now = '2026-10-13T12:00:00.000Z';
const event = {id:'evidence-one',target:'Order a meal',mode:'flashcards',domain:'recall',support:'prompted',success:true,observation:'Correct recall of a food phrase',expectedAnswer:'Quisiera una sopa.'};
const evidence = model.mergeEvidence({},event,'goal',now);
// Execute the actual web completion function with isolated in-memory Firebase/store adapters.
// No reference files, Firebase accounts or remote services are written.
const esbuild = await import(path.join(reference,'node_modules/esbuild/lib/main.js'));
const mocks = {
  'firebase/firestore': `
    export const doc=(...parts)=>parts.join('/');
    export async function getDoc(){ return {exists:()=>true,data:()=>structuredClone(globalThis.piyaliGoalFixture.user)}; }
    export async function runTransaction(db,work){ return work({get:getDoc,update(ref,patch){
      for(const [key,value] of Object.entries(patch)) { const parts=key.split('.'); let node=globalThis.piyaliGoalFixture.user;
        for(const part of parts.slice(0,-1)) node=node[part] ??= {}; node[parts.at(-1)]=value; }
    }}); }
    export const setDoc=()=>{throw Error('Unexpected fixture write')};
    export const updateDoc=setDoc,collection=doc,getDocs=getDoc,query=doc,where=doc,increment=x=>x,serverTimestamp=()=>null,deleteField=()=>null,documentId=()=>"__name__";`,
  'firebase/analytics': 'export const logEvent=()=>{};',
  firebaseResources: 'export const database={},analytics=null;',
  useUserStore: 'export default {getState:()=>({user:globalThis.piyaliGoalFixture.user,patchUser:patch=>Object.assign(globalThis.piyaliGoalFixture.user,patch)})};',
  useGoalFocusStore: 'export default {getState:()=>({focus:null,clearFocus(){}})};',
  llm: 'export const callResponses=()=>{throw Error("AI disabled in source fixture export")};',
  questionDifficultyAssessment: 'export const assessGeneratedQuestionWorth=()=>null;'
};
const bundle = await esbuild.build({stdin:{contents:'export { recordGoalAttempt } from '+JSON.stringify(path.join(reference,'src/utils/learningIntelligence.js'))+';',resolveDir:reference,sourcefile:'piyali-goal-fixture.mjs'},bundle:true,format:'esm',platform:'node',write:false,
  define:{'import.meta.env.VITE_ASTRA_GOALS_ENABLED':'"true"'},plugins:[{name:'isolated-goal-fixture',setup(build){
    build.onResolve({filter:/.*/},args=>{ const name=mocks[args.path] ? args.path : path.basename(args.path); return mocks[name] ? {path:name,namespace:'goal-fixture'} : null; });
    build.onLoad({filter:/.*/,namespace:'goal-fixture'},args=>({contents:mocks[args.path],loader:'js'}));
  }}]});
const runtime = await import('data:text/javascript;base64,'+Buffer.from(bundle.outputFiles[0].text).toString('base64'));
const blueprint = {goalId:'goal-one',goalText:'Order a meal',dayKey:'2026-10-13',lang:'es',mode:'tutor',modes:['lesson','tutor'],objective:'Ask for soup'};
const bucket = {version:1,activeGoal:{id:'goal-one',text:'Order a meal',status:'active'},goalProgress:{},dailyGoal:{blueprint,completed:false,modeProgress:{lesson:20,tutor:0},modeEventIds:[],evidence:[]}};
const completionEvent = {id:'00000000-0000-0000-0000-000000000001',success:true,support:'prompted',domain:'production',observation:'Asked for soup politely after a hint'};
const originalDate = globalThis.Date;
const originalWindow = globalThis.window, originalEvent = globalThis.CustomEvent;
globalThis.piyaliGoalFixture = {user:{local_npub:'fixture-user',xp:17,learningIntelligence:{es:structuredClone(bucket)},progress:{}}};
globalThis.Date = class extends originalDate { constructor(...args){super(...(args.length ? args : [now]));} static now(){return originalDate.parse(now);} };
globalThis.window = {dispatchEvent(){}};
globalThis.CustomEvent = class {constructor(type,options){this.type=type;this.detail=options?.detail;}};
let modeCompletion;
try {
  const completed = await runtime.recordGoalAttempt({npub:'fixture-user',targetLang:'es',supportLang:'en',blueprint},completionEvent);
  modeCompletion = {bucket,event:completionEvent,now,completed,expected:globalThis.piyaliGoalFixture.user.learningIntelligence.es,xpBefore:17,xpAfter:globalThis.piyaliGoalFixture.user.xp};
} finally { globalThis.Date=originalDate;globalThis.window=originalWindow;globalThis.CustomEvent=originalEvent;delete globalThis.piyaliGoalFixture; }
const output = {modes,evidence:{event,now,expected:evidence},modeCompletion};
await fs.writeFile(new URL('../Tests/PiyaliCoreTests/Fixtures/goal-practice.json',import.meta.url),JSON.stringify(output,null,2)+'\n');
console.log(`Exported ${modes.length} daily bundle cases, shared evidence and real web completion bookkeeping from the read-only reference.`);
