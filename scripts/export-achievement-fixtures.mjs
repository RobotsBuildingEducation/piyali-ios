// Pure reference functions only; all generated output stays in the iOS repository.
import fs from 'node:fs/promises';
import path from 'node:path';
const reference=path.resolve(process.argv[2] || '../nosabos/nosabos');
const esbuild=await import(path.join(reference,'node_modules/esbuild/lib/main.js'));
const exports={
 'achievements/progressionEvidence.js':['meetsProgressionRequirement','earnedProgressionIds','addProgressEvents','ledgerCounters'],
 'achievements/learningCounts.js':['learningCompletionCounters'],
 'achievements/progressionRuntime.js':['mergeProgressLedgers'],
 'achievements/flashcardProgress.js':['flashcardCompletionEvent'],
 'achievements/phonicsProgress.js':['phonicsCompletionEvidence'],
 'achievements/catalog.js':['ACHIEVEMENTS','earnedTutorAchievementIds'],
 'achievements/proficiencyCompletion.js':['tutorLevelFromCompletions'],
 'achievements/firestoreRecords.js':['completionDocumentId'],
 'utils/piyaliAchievementProgress.js':['piyaliCompletionProof']
};
const bundled=await esbuild.build({stdin:{contents:Object.entries(exports).map(([file,names])=>`export {${names.join(',')}} from ${JSON.stringify(path.join(reference,'src',file))};`).join('\n'),resolveDir:reference},bundle:true,format:'esm',platform:'node',write:false});
const web=await import('data:text/javascript;base64,'+Buffer.from(bundled.outputFiles[0].text).toString('base64'));
const requirements=[];
const complete={total:2,completed:2},empty={total:0,completed:0},partial={total:2,completed:1};
const evidences=[{}, {language:'es',counters:{skill_tree_lessons:5,flashcards_completed:10}},
 {language:'es',levels:{tutor:{a2:complete},skillTree:{b2:complete},flashcards:{c2:complete}}},
 {language:'es',levels:{tutor:{a1:empty},skillTree:{b1:partial},flashcards:{c2:{total:2,completed:2.5}}}},
 {levelCounts:{goals:{b2:1},repairs:{c1:1}},counters:{phonics_decks:20,conversation_goals:5}},
 {language:'es',sets:{phonics_cards:{required:['a','b'],completed:['b','a','a']}}},
 {language:'es',sets:{phonics_cards:{required:[],completed:[]}}},
 {language:'es',levels:Object.fromEntries(['tutor','skillTree','flashcards'].map(mode=>[mode,Object.fromEntries(['pre_a1','a1','a2','b1','b2','c1','c2'].map(level=>[level,complete]))]))}
];
for(const a of Object.values(web.ACHIEVEMENTS).filter(a=>a.source==='nosabos' && a.progression)) for(const evidence of evidences) requirements.push({id:a.id,requirement:a.requirement,evidence,expected:web.meetsProgressionRequirement(a.requirement,evidence)});
const cards=[];
for(const language of ['es','fr','invalid-language!']) for(const id of ['a1-greet-1','repair-1','pre-a1-one']) for(const progress of [{},{completed:true},{successfulReviews:1},{successfulReviews:1,lastReviewOutcome:'good'},{successfulReviews:1,lastReviewOutcome:'again',consecutiveCorrect:0},{successfulReviews:1,consecutiveCorrect:1},{completed:true,isGoal:true}]) cards.push({language,id,progress,expected:web.flashcardCompletionEvent(language,id,progress)});
const proofs=[];
const blueprint={modes:['lesson','tutor'],cefrLevel:'B1',dayKey:'2026-10-13',goalId:'goal-1'};
const summary={migration:{complete:true},tutor:{levels:{a1:complete}},skillTree:{levels:{a1:partial}},flashcards:{levels:{a1:complete}}};
for(const completed of [true,false]) for(const counts of [{lesson:20,tutor:25},{lesson:20,tutor:24}]) {
 const profile={learningIntelligence:{es:{dailyGoal:{completed,blueprint,modeProgress:counts}}},progress:{repairDailyActivity:{es:{'2026-10-13':2}}},realWorldTasks:{targetLang:'es',generatedAt:'2026-10-13T12:00:00Z',dayKey:'2026-10-13',tasks:['a','b'],completed:{0:true,1:true},rewarded:true}};
 const quest={repair:{items:[{cefrLevel:'B1'},{cefrLevel:'B2'}],target:2,createdAt:'2026-10-13T12:00:00Z'}};
 for(const s of [summary,{...summary,migration:{complete:false}}]) {const input={profile,summary:s,quest,language:'es',dayKey:'2026-10-13'};proofs.push({input,expected:web.piyaliCompletionProof(input)});}
}
const phonics=[];
for(const authored of [true,false]) for(const done of [0,1,2]) {
 const base=[{id:'a',authored,deckId:'deck'},{id:'b',authored,deckId:'deck'}],documents=base.slice(0,done).map(card=>({targetLang:'es',letterId:card.id,correctCount:1}));
 phonics.push({language:'es',base,documents,expected:web.phonicsCompletionEvidence('es',base,documents)});
}
const hashes=[];
for(const [metric,id] of [['goals:b1','es:day:goal'],['phonics_decks','ja:deck/猫'],['conversation_goals','es:a"b\n']]) hashes.push({metric,id,expected:await web.completionDocumentId(metric,id)});
await fs.writeFile(new URL('../Tests/PiyaliAppTests/Fixtures/achievement-hashes.json',import.meta.url),JSON.stringify(hashes,null,2)+'\n');
const fixture={requirements,cards,proofs,phonics};
await fs.writeFile(new URL('../Tests/PiyaliCoreTests/Fixtures/achievements.json',import.meta.url),JSON.stringify(fixture,null,2)+'\n');
console.log(`Exported ${requirements.length} requirements, ${cards.length} card cases, ${proofs.length} completion proofs and ${phonics.length} phonics proofs.`);
