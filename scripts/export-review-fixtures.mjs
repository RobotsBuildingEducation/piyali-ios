// Expected schedules come from the reference implementation, not the Swift port.
import fs from 'node:fs';
import path from 'node:path';
import { createRequire } from 'node:module';
const reference = path.resolve(process.argv[2] || '../nosabos/nosabos');
const root = path.resolve(import.meta.dirname,'..');
const { build } = createRequire(path.join(reference,'package.json'))('esbuild');
const output = path.join(root,'.export-review.mjs');
await build({stdin:{contents:`export { buildFlashcardReviewUpdate } from '${reference}/src/utils/flashcardReview.js'`,resolveDir:reference},bundle:true,format:'esm',platform:'node',outfile:output,plugins:[{name:'pure-review-fixture',setup(build){
  build.onResolve({filter:/constants\/languages$|userDataSchema\.js$/},args=>({path:args.path,namespace:'fixture-labels'}));
  build.onLoad({filter:/.*/,namespace:'fixture-labels'},()=>({contents:`export const DEFAULT_SUPPORT_LANGUAGE='en'; export const getLanguageLocale=()=> 'en-US'; export const normalizeSupportLanguage=x=>x; export const getLocalCalendarDayKey=d=>d.toISOString().slice(0,10);`,loader:'js'}));
}}]});
const { buildFlashcardReviewUpdate } = await import(output);
const now = new Date('2026-10-12T18:00:00.000Z');
const inputs = [{}];
for(const state of ['new','learning','relearning','review']) for(const index of [0,1]) for(const interval of [1,4,30])
 inputs.push({schedulerState:state,learningStepIndex:index,intervalDays:interval,easeFactor:2.5,reviewCount:3,successfulReviews:2,lapseCount:1,consecutiveCorrect:1,completed:state==='review'||state==='relearning',completedAt:state==='review'||state==='relearning'?'2026-10-01T18:00:00.000Z':null});
inputs.push({completed:true,intervalHours:96,nextReviewAt:'2026-10-12T17:00:00.000Z'},{schedulerState:'review',easeFactor:1.3,intervalDays:10},{schedulerState:'learning',easeFactor:3.5,learningStepIndex:1},{schedulerState:'relearning',postLapseIntervalDays:7,intervalDays:7});
const fixtures = inputs.flatMap((progress,index)=>['again','hard','good','easy'].map(rating=>({name:`${index}-${rating}`,progress,rating,now:now.toISOString(),expected:buildFlashcardReviewUpdate(progress,rating,now)})));
fs.writeFileSync(path.join(root,'Tests/PiyaliCoreTests/Fixtures/review-schedules.json'),JSON.stringify(fixtures,null,2)+'\n');
fs.unlinkSync(output);
console.log(`Exported ${fixtures.length} reference review schedules.`);
