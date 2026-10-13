import fs from 'node:fs/promises';
import path from 'node:path';
import zlib from 'node:zlib';
const reference=path.resolve(process.argv[2] || '../nosabos/nosabos');
const esbuild=await import(path.join(reference,'node_modules/esbuild/lib/main.js'));
// Generation's injected function avoids calling Firebase, OpenAI, or a host adapter.
const bundled=await esbuild.build({stdin:{contents:`export * from ${JSON.stringify(path.join(reference,'src/utils/dailyImmersion.js'))};export * from ${JSON.stringify(path.join(reference,'src/utils/immersionCurriculumContext.js'))};export * from ${JSON.stringify(path.join(reference,'src/utils/scoreMilestones.js'))};`,resolveDir:reference},bundle:true,format:'esm',platform:'node',write:false,external:['../firebaseResources/firebaseResources.js']});
const web=await import('data:text/javascript;base64,'+Buffer.from(bundled.outputFiles[0].text).toString('base64'));
const day='2026-09-24',tasks=[1,2,3].map(i=>({title:`Task ${i}`,description:`Practice privately at home ${i}.`}));
const base={targetLang:'de',appLanguage:'en',dayKey:day,generationVersion:4,generatedAt:'2026-09-24T09:00:00.000Z',tasks,completed:[false,false,false],rewarded:false,placementAt:'placement'};
const states=[];
for(const completed of [[false,false,false],[true,false,false]]) for(const version of [3,4]) for(const placementAt of ['placement','new-placement']) for(const goal of [null,{id:'goal',text:'Read a recipe'}]) {
 const batch={...base,completed,generationVersion:version},context={dayKey:day,targetLang:'de',appLanguage:'en',placementAt,goal};states.push({batch,context,expected:web.getDailyImmersionState(batch,context)});
}
for(const [batch,context] of [[{...base,tasks:[...tasks,{title:'Read a recipe',description:'Find an ingredient.'}],goalId:'goal',goalText:'Read a recipe',completed:[true,false,false,true]}, {dayKey:day,targetLang:'de',appLanguage:'en',placementAt:'placement',goal:{id:'goal',text:'Read a recipe'}}],[{...base,completed:[true,false,false]}, {dayKey:'2026-09-25',targetLang:'de'}],[base,{dayKey:day,targetLang:'fr'}],[base,{dayKey:day,targetLang:'de',appLanguage:'es'}],[{...base,rewarded:true,generationVersion:0},{dayKey:day,targetLang:'de'}]]) states.push({batch,context,expected:web.getDailyImmersionState(batch,context)});
const normalize=[];
for(const raw of [{tasks},JSON.stringify({tasks}),`\`\`\`json\n${JSON.stringify({tasks})}\n\`\`\``,{tasks:[...tasks.slice(0,2),{title:'Task 1',description:'different'}]},{tasks:[{title:'Visit a store',description:'Ask a cashier a question'},...tasks.slice(1)]},{tasks:[{title:'Create an account',description:'Post publicly'},...tasks.slice(1)]},{tasks:[{title:'  A   private recording ',description:'   Speak   into a phone. '},...tasks.slice(1)]},{tasks:[{title:'Ｔａｓｋ ２',description:'Different'},...tasks.slice(1)]}]) normalize.push({raw,count:3,recent:[],expected:web.normalizeDailyImmersionTasks(raw,3)});
normalize.push({raw:{tasks},count:3,recent:[tasks[0]],expected:web.normalizeDailyImmersionTasks({tasks},3,[tasks[0]])});
const history=[];
for(const [old,adding] of [[[],tasks],[tasks,[tasks[0]]],[Array.from({length:30},(_,i)=>({title:`Past ${i}`,description:'Past description'})),tasks],[[],[{title:'  Read  ',description:' text '},{title:'read',description:'text'},{title:'',description:'ignore'}]]]) history.push({old,adding,expected:web.appendImmersionHistory(old,adding)});
let prompt='';await web.generateDailyImmersionTasks({targetLang:'de',appLanguage:'en',cefrLevel:'A2',generate:async value=>{prompt=value;return {tasks}}});
const instructions=prompt.split('\n').filter(line=>line.startsWith('Every task')||line.startsWith('Never require')||line.startsWith('Avoid vague')||line.startsWith('Use evidence')||line.startsWith('Adapt the language')||line.startsWith('Do not give')).map(line=>line.replaceAll('English','{{support}}').replaceAll('German','{{target}}'));
const gzip=(name,value)=>fs.writeFile(new URL(`../Piyali/Resources/${name}.json.gz`,import.meta.url),zlib.gzipSync(JSON.stringify(value),{level:9}));
await gzip('immersion-coaching',instructions);await gzip('score-milestones',web.SCORE_MILESTONES);
const candidates=[];
for(const [skillCount,tutorCount,skillLevel,tutorLevel,progress,priority] of [[1,3,'A2','A2',{},null],[0,2,'B1','A2',{},null],[0,0,'B1','B1',{one:{status:'completed'},two:{status:'in_progress'}},null],[2,0,'A2','A2',{},'one'],[0,0,'A1','B1',{},null],[8,9,'A1','A1',{},null]]) {
 const lessons=['one','two','three','four'].map(id=>({id})),units=[{lessons}];
 const skill=web.immersionLessonCandidate({units,completedCount:skillCount,level:skillLevel,mode:'Lessons',priorityLessonId:priority});
 const tutor=web.immersionLessonCandidate({units,progress,completedCount:tutorCount,level:tutorLevel,mode:'Tutor'}),leading=web.leadingImmersionLesson(skill,tutor);
 candidates.push({skillCount,tutorCount,skillLevel,tutorLevel,progress,priority,expected:{id:leading.lesson.id,index:leading.index,mode:leading.mode,level:leading.level}});
}
const lesson={id:'context',title:{en:'Describe past events',es:'Describir el pasado'},description:{en:'Tell a brief personal story'},cefrLevel:'B1',objectives:{communicativeObjectives:['Can narrate events in sequence.']},content:{grammar:{focusPoints:['past tense','sequence markers']},vocabulary:{focusPoints:['journeys','past tense']},stories:{prompt:'Do not send the whole lesson'}}};
const context={lesson,support:'es',expected:{...web.summarizeImmersionLesson(lesson,'es'),source:'Tutor'}};
await fs.writeFile(new URL('../Tests/PiyaliCoreTests/Fixtures/immersion.json',import.meta.url),JSON.stringify({states,normalize,history,candidates,context},null,2)+'\n');
console.log(`Exported ${states.length} states, ${normalize.length} quality cases, ${history.length} history cases and original coaching instructions.`);
