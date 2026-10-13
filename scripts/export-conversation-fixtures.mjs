import fs from 'node:fs/promises';
import path from 'node:path';
import zlib from 'node:zlib';
const reference=path.resolve(process.argv[2] || '../nosabos/nosabos'),esbuild=await import(path.join(reference,'node_modules/esbuild/lib/main.js'));
const code=`export {fallbackTopics} from ${JSON.stringify(path.join(reference,'src/data/conversationTopics.js'))};export {questionWorthForUser,applyGradedOutcome} from ${JSON.stringify(path.join(reference,'src/utils/performanceEloModel.js'))};export {conversationCompletionEvent} from ${JSON.stringify(path.join(reference,'src/achievements/conversationProgress.js'))};`;
const result=await esbuild.build({stdin:{contents:code,resolveDir:reference},bundle:true,platform:'node',format:'esm',write:false});
const web=await import('data:text/javascript;base64,'+Buffer.from(result.outputFiles[0].text).toString('base64'));
const worth=[],graded=[];
for(const rating of [800,1000,1800]) for(const level of ['Pre-A1','A1','A2','B1','B2','C1','C2']) for(const difficulty of [null,35.5]) {
 const bucket={version:1,elo:{rating,scaleVersion:4,totalGraded:2,recentEventIds:[]},performanceSummary:{recentResults:[0,1]},unknown:'preserve'},user={learningIntelligence:{es:bucket}};
 const quote=web.questionWorthForUser(user,'es',level,difficulty===null ? null : {difficultyScore:difficulty});worth.push({rating,level,difficulty,expected:quote});
 for(const success of [false,true]) { const event={id:'10000000-0000-0000-0000-000000000001',success,questionLevel:level,worth:quote,concept:'Ask how they feel',support:'independent',mode:'conversation'};graded.push({bucket,event,expected:web.applyGradedOutcome(bucket,event,'A1','2026-10-13T12:00:00.000Z')}); }
}
const goal={text:{en:'Say hello'}},first=web.conversationCompletionEvent({goal,language:'es',completed:true}),second=web.conversationCompletionEvent({goal,language:'es',completed:true});
if(first.id!==second.id||web.conversationCompletionEvent({goal,language:'es',completed:false})!==null) throw new Error('Unexpected reference completion contract');
await fs.writeFile(new URL('../Piyali/Resources/conversation-topics.json.gz',import.meta.url),zlib.gzipSync(JSON.stringify(web.fallbackTopics),{level:9}));
await fs.writeFile(new URL('../Tests/PiyaliCoreTests/Fixtures/conversation.json',import.meta.url),JSON.stringify({worth,graded},null,2)+'\n');
console.log(`Exported ${worth.length} quotes, ${graded.length} grading outcomes and seven levels of fallback goals from the reference.`);
