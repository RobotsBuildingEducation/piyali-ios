// Public I/O fixtures around the unmodified Tutor component. No learner identity or backend writes.
const prefix='\0piyali-public-tutor-';
export const tutorFixture={name:'piyali-source-tutor-fixture',enforce:'pre',resolveId(id,importer){
 if(!importer?.endsWith('/Tutor.jsx'))return;
 const map={'firebase/firestore':'firestore','firebase/analytics':'analytics','../firebaseResources/firebaseResources':'firebase','../utils/learningIntelligence':'intelligence','../utils/companionMemory':'memory','../utils/progressTracking':'tracking','../utils/achievements.js':'achievements','../utils/utils':'xp','../utils/dailyPlate':'activity','../utils/questionDifficultyAssessment':'worth','../utils/openaiRealtimeBridge':'bridge','../utils/geminiLiveBridge':'bridge','../utils/courseProgress':'course'};
 if(map[id])return prefix+map[id];
 },load(id){if(!id.startsWith(prefix))return;const name=id.slice(prefix.length);
 if(name==='firestore')return `const ref=(...args)=>({path:args.flatMap(v=>typeof v==='string'?[v]:v?.path?[v.path]:[]).join('/')});export const collection=ref,doc=ref,query=(q)=>q,where=()=>null;const snap=(r)=>({exists:()=>r.path.split('/').length===2,data:()=>({xp:0,progress:{targetLang:'es',supportLang:new URLSearchParams(location.search).get('language')||'en',showTranslations:true}}),docs:[],metadata:{fromCache:false,hasPendingWrites:false}});export const getDoc=async r=>snap(r),setDoc=async()=>{};export function onSnapshot(r,...args){const cb=args.find(x=>typeof x==='function'),timer=setTimeout(()=>cb(snap(r)),0);return()=>clearTimeout(timer)}`;
 if(name==='firebase')return `export const database={},analytics={};export const appCheckFetch=async()=>{throw Error('Public Tutor fixture: network disabled')};export const gradingLiteModel={generateContent:async()=>({response:{text:()=>JSON.stringify({successful:false,confidence:0.9,mistake:false,reason:'public fixture'})}})},simplemodel=gradingLiteModel;`;
 if(name==='analytics')return 'export const logEvent=()=>{};';
 if(name==='intelligence')return `import store from '/src/hooks/useGoalFocusStore';export const currentGoalFocus=(surface)=>{const f=store.getState().focus;return f&&(!surface||f.surface===surface)?f:null},evaluateGoalAttempt=async()=>({success:false}),recordGoalAttempt=async()=>{},recordGradedOutcome=async()=>{};`;
 if(name==='memory')return 'export const REPAIR_MAX_ITEMS=3,captureCompanionMemory=async()=>{},completeRepairFocus=async()=>{},completeRepairLesson=async()=>{};';
 if(name==='tracking')return 'export const TUTOR_AGENDA_PROGRESS_SCHEMA_VERSION=2,getLanguageXp=()=>0,startTutorLesson=async()=>{},completeTutorLesson=async()=>{},saveTutorAgendaProgress=async()=>{},saveTutorConversationDraft=async()=>{},saveTutorLessonEarnedXp=async()=>{};';
 if(name==='achievements')return 'export const awardTutorLevelAchievements=async()=>{};';
 if(name==='xp')return 'export const awardXp=async()=>({});';
 if(name==='activity')return 'export const recordPlateActivity=async()=>{};';
 if(name==='worth')return 'export const assessGeneratedQuestionWorth=async()=>null;';
 if(name==='bridge')return `export const createOpenAIRealtimeBridge=async()=>{throw Error('Public Tutor fixture: microphone unavailable')};export const createGeminiLiveRealtimeBridge=createOpenAIRealtimeBridge;`;
 if(name==='course')return `export {getCourseLevelStats,replaceProgressLevel} from '/src/utils/courseProgress.js';export const getCourseProgressSummary=async()=>({schemaVersion:1,targetLang:'es'});`;
 }};
