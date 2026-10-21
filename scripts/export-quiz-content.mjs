// Enrich existing native lessons with omitted source metadata; do not rewrite other content.
import fs from 'node:fs/promises';
import path from 'node:path';
import {gzipSync,gunzipSync} from 'node:zlib';
const reference=path.resolve(process.argv[2] || '../nosabos/nosabos');
const esbuild=await import(path.join(reference,'node_modules/esbuild/lib/main.js'));
const bundle=await esbuild.build({stdin:{contents:`export {LEARNING_PATHS} from ${JSON.stringify(path.join(reference,'src/data/skillTreeData.js'))}; export {getDelightQuizOutcome} from ${JSON.stringify(path.join(reference,'src/utils/delightQuizProgress.js'))};`,resolveDir:reference},bundle:true,platform:'node',format:'esm',write:false});
const web=await import('data:text/javascript;base64,'+Buffer.from(bundle.outputFiles[0].text).toString('base64'));
let lessons=0,quizzes=0;
for(const [language,levels] of Object.entries(web.LEARNING_PATHS)) {
 const file=new URL(`../Piyali/Resources/curriculum-${language}.json.gz`,import.meta.url),native=JSON.parse(gunzipSync(await fs.readFile(file)));
 for(const [level,units] of Object.entries(native)) {
  const source=new Map(levels[level].flatMap(u=>u.lessons).map(l=>[l.id,l]));
  for(const unit of units) for(const lesson of unit.lessons) {
   const original=source.get(lesson.id);if(!original) throw new Error('Unmatched source lesson '+lesson.id);
   lesson.isFinalQuiz=!!original.isFinalQuiz;lesson.quizConfig=original.quizConfig || null;lesson.cefrLevel=level;lessons++;if(lesson.isFinalQuiz) quizzes++;
  }
 }
 await fs.writeFile(file,gzipSync(JSON.stringify(native),{level:9}));
}
const outcomes=[];
for(const config of [{},{questionsRequired:10,passingScore:8},{questionsRequired:3,passingScore:2},{questionsRequired:1,passingScore:1},{questionsRequired:5,passingScore:7},{questionsRequired:12,passingScore:10}]) {
 for(let mask=0;mask<2**(config.questionsRequired === 12 ? 12 : 10);mask++) {
  const history=Array.from({length:config.questionsRequired === 12 ? 12 : 10},(_,i)=>!!(mask&(1<<i)));
  // Exercise every reachable prefix, stopping at the same early pass/fail as the browser.
  let prefix=[];for(const value of history) { if(web.getDelightQuizOutcome(prefix,config).completed) break;prefix.push(value); }
  outcomes.push({config,history:prefix,expected:web.getDelightQuizOutcome(prefix,config)});
 }
}
await fs.writeFile(new URL('../Tests/PiyaliCoreTests/Fixtures/quiz-outcomes.json',import.meta.url),JSON.stringify(outcomes)+'\n');
console.log(JSON.stringify({lessons,quizzes,outcomes:outcomes.length}));
