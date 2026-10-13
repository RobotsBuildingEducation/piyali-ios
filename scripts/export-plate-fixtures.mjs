// Read-only reference exports: no accounts, API calls or reference files are changed.
import fs from 'node:fs/promises';
import path from 'node:path';
const reference = path.resolve(process.argv[2] || '../nosabos/nosabos');
const esbuild = await import(path.join(reference,'node_modules/esbuild/lib/main.js'));
const mocks = {
 'firebase/firestore':'export const doc=()=>null,getDoc=()=>null,runTransaction=()=>null,setDoc=()=>null,collection=()=>null,deleteField=()=>null,documentId=()=>null,getDocs=()=>null,query=()=>null,where=()=>null;',
 firebaseResources:'export const database=null;',useUserStore:'export default {};',
 learningIntelligence:'export const astraGoalsEnabled=()=>true;',voiceJourney:'export const prepareJourneyCompletion=()=>null;'
};
const bundle = await esbuild.build({stdin:{contents:'export { electDailyQuestCourses,getQuestNeglectWeights,getDailyPlateSnapshot } from '+JSON.stringify(path.join(reference,'src/utils/dailyPlate.js'))+';',resolveDir:reference,sourcefile:'plate-fixtures.mjs'},bundle:true,format:'esm',platform:'node',write:false,plugins:[{name:'isolated-reference',setup(build){
 build.onResolve({filter:/.*/},args=>{const name = mocks[args.path] ? args.path : path.basename(args.path); return mocks[name] ? {path:name,namespace:'fixture'} : null;});
 build.onLoad({filter:/.*/,namespace:'fixture'},args=>({contents:mocks[args.path],loader:'js'}));
}}]});
const web = await import('data:text/javascript;base64,'+Buffer.from(bundle.outputFiles[0].text).toString('base64'));
const elections=[];
for(const seed of ['npub1abc:es:2026-10-13','learner:fr:2026-10-14','learner-🐈:ja:2026-10-15','áéí:es:2026-10-16'])
 for(const score of [null,0,31,32,60,100]) for(const count of [undefined,2,4]) {
  const input={available:['speak','review','conversation','learn','phonics'],avoid:['review','learn'],seed,score,weights:{speak:8,review:1,conversation:6,learn:2,phonics:7},...(count===undefined?{}:{count})};
  elections.push({input,expected:web.electDailyQuestCourses(input)});
 }
const day='2026-10-13',lang='es',now=new Date(day+'T12:00:00');
const progress={dailyQuestFirstSeen:true,dailyQuestFirstDayKey:'2026-10-01',flashcardDailyActivity:{es:{[day]:4,'2026-10-12':2}},lessonDailyActivity:{es:{[day]:1}},speakDailyActivity:{es:{[day]:1}},conversationDailyActivity:{es:{[day]:3,'2026-10-11':2}},phonicsDailyActivity:{es:{[day]:2}},plateBonusDailyActivity:{es:{[day]:'2026-10-13T12:01:00Z'}}};
const snapshots=[];
for(const userKey of ['learner-one','learner-two','learner-🐈']) for(const first of [true,false]) {
 const user={local_npub:userKey,progress:{...progress,dailyQuestFirstDayKey:first?day:'2026-10-01'},xp:20};
 snapshots.push({user,day,lang,kinds:['speak','learn','review','conversation','phonics'],expected:web.getDailyPlateSnapshot(user,lang,now,['speak','learn','review','conversation','phonics'])});
}
const weights={progress,day,lang,kinds:['speak','review','conversation','learn','phonics'],expected:web.getQuestNeglectWeights({progress},lang,['speak','review','conversation','learn','phonics'],now)};
await fs.writeFile(new URL('../Tests/PiyaliCoreTests/Fixtures/daily-plate.json',import.meta.url),JSON.stringify({elections,snapshots,weights},null,2)+'\n');
console.log(`Exported ${elections.length} weighted election cases, ${snapshots.length} snapshots and neglect weights from the reference.`);
