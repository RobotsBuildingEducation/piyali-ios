import fs from 'node:fs/promises';
import path from 'node:path';
import vm from 'node:vm';
import {gzipSync} from 'node:zlib';
import {storyPolicyFragments} from './story-policy-fragments.mjs';
const reference=path.resolve(process.argv[2]||'../nosabos/nosabos');
const esbuild=await import(path.join(reference,'node_modules/esbuild/lib/main.js')),parser=await import(path.join(reference,'node_modules/@babel/parser/lib/index.js')),traversal=await import(path.join(reference,'node_modules/@babel/traverse/lib/index.js')),traverse=traversal.default.default??traversal.default;
const fragment=storyPolicyFragments({source:await fs.readFile(path.join(reference,'src/components/Stories.jsx'),'utf8'),parser,traverse});
const modulePath=file=>JSON.stringify(path.join(reference,'src',file));
const entry=`import {createStoryPlan,buildStoryDiversityPrompt,getStoryNoveltyIssues} from ${modulePath('features/stories/storyDiversity.js')};import {getStoryDifficulty,buildSpeakingStoryPrompt} from ${modulePath('features/stories/storyPrompts.js')};import {focusedLessonPrompt} from ${modulePath('utils/learningIntelligenceModel.js')};import {generationPerformanceContextFor} from ${modulePath('utils/performanceEloModel.js')};import {buildStorySessionPrompt,buildStorySessionStreamPrompt} from ${modulePath('features/stories/storySession.js')};import {isExactActivityRepeat} from ${modulePath('utils/activityGeneration.js')};import {assessGeneratedQuestionWorths} from ${modulePath('utils/questionDifficultyAssessment.js')};import {buildActivityReviewRequest} from ${modulePath('utils/activityQualityReview.js')};${fragment.code}\nexport {assessGeneratedQuestionWorths,createStoryPlan,buildStoryDiversityPrompt,getStoryNoveltyIssues,sourceSpeakingPreparation,buildStorySessionPrompt,buildStorySessionStreamPrompt,getStoryDifficulty,isExactActivityRepeat,buildActivityReviewRequest};`;
const bundle=await esbuild.build({stdin:{contents:entry,resolveDir:reference},logLevel:'error',bundle:true,platform:'neutral',target:'es2020',format:'iife',globalName:'SourceStories',write:false});
let history=[];
const oracle=vm.createContext({window:{localStorage:{getItem:()=>JSON.stringify(history)}}});vm.runInContext(bundle.outputFiles[0].text,oracle);const web=oracle.SourceStories;
const native={};vm.runInNewContext(await fs.readFile(new URL('../Piyali/Resources/practice-recipes.js',import.meta.url),'utf8'),native);const policies=native.PiyaliPracticeRecipes;
const canonical=v=>Array.isArray(v)?v.map(canonical):v&&typeof v==='object'?Object.fromEntries(Object.keys(v).sort().map(key=>[key,canonical(v[key])])):v;
function seed(value){vm.runInContext(`{let state=${value}>>>0;Math.random=()=>{state=(state+0x6d2b79f5)>>>0;let t=Math.imul(state^(state>>>15),1|state);t=(t+Math.imul(t^(t>>>7),61|t))^t;return ((t^(t>>>14))>>>0)/4294967296;};}`,oracle);}
const fixtures=[];
function add(operation,parameters,expected){const p=canonical(parameters),actual=JSON.parse(policies.story(operation,JSON.stringify(p)));if(JSON.stringify(canonical(actual))!==JSON.stringify(canonical(expected)))throw Error('Native policy differs from original source: '+operation);fixtures.push({operation,parameters:p,expected});}
for(const [target,support,level,content] of [
 ['es','en','Pre-A1',{topic:'tutorial'}],['fr','de','B2',{topic:'tutorial',tutorialPracticeLevel:'B2'}],['ja','es','A2',{topic:'family',storySubjects:[{id:'siblings',name:'Siblings',guidance:'Work out the relationship.'},{id:'parents',name:'Parents',guidance:'Use a family relationship to decide.'}]}],['ar','en','A1',{topic:'changing a plan',storyScope:{objective:'Decide who can help when a plan changes.'}}]
])for(const recent of [[],[{lessonId:'lesson-family',title:'A previous plan',mode:'radio',targetText:'My sister called me yesterday. We changed our plan.',subject:'siblings',purpose:'purpose-0'}]]){
 history=recent;const p=canonical({lessonContent:content,lessonId:'lesson-family',npub:'fixture-only',targetLang:target,targetName:{es:'Spanish',fr:'French',ja:'Japanese',ar:'Arabic'}[target],supportLang:support,supportName:{en:'English',de:'German',es:'Spanish'}[support],cefrLevel:level,curriculumCefrLevel:level,user:{},history:recent,randomSeed:fixtures.length+19});
 seed(p.randomSeed);const plan=web.createStoryPlan({...p,mode:'practice'});add('plan',{...p,mode:'practice'},plan);
 seed(p.randomSeed);const prepared=web.sourceSpeakingPreparation({...p,lesson:{id:p.lessonId},account:p.npub},{storyMode:'speaking',cefrLevel:level,curriculumCefrLevel:level});add('prepareSpeak',p,prepared);
 add('diversity',{plan},web.buildStoryDiversityPrompt(plan));
 for(const mode of ['radio','conversation']){
  const args={mode,targetName:p.targetName,supportName:p.supportName,targetLang:target,supportLang:support,difficulty:web.getStoryDifficulty(level),context:[plan.objective,web.buildStoryDiversityPrompt(plan)].filter(Boolean).join('\n'),userCharacterName:'You'};
  add('sessionPrompt',{...p,plan,mode},web.buildStorySessionPrompt(args));add('sessionStreamPrompt',{...p,plan,mode},web.buildStorySessionStreamPrompt(args));
 }
 const candidate={title:'A new day',target:'My sister called me yesterday. We changed our plan.'};
 add('novelty',{candidate,plan},web.getStoryNoveltyIssues(candidate,plan));add('exactRepeat',{candidate,plan},web.isExactActivityRepeat(candidate.target,plan.recentEntries));
 add('reviewPrompt',{candidate,plan},web.buildActivityReviewRequest({candidate,recentEntries:plan.recentEntries,objective:plan.objective,selection:{subject:plan.subject,purpose:plan.purpose},mode:plan.mode,targetLang:target}).contents[0].parts[0].text);
}
for(const raw of ['{"difficultyScores":[0,100]}','{"difficultyScores":[-1,70]}','{"difficultyScores":[7.5,20]}','{"difficultyScores":["5",40]}','{"difficultyScores":[20]}','null','bad json','```json\n{"difficultyScores":[10,70]}\n```']) {
 const p=canonical({questions:[{sentence:'Hola.',task:'Understand and pronounce this sentence'},{sentence:'Si hubiera sabido la verdad, habría llegado antes.',task:'Understand and pronounce this sentence'}],questionLevel:'A1',targetLang:'es',mode:'story',user:{},raw});
 let prompt;const expected=await web.assessGeneratedQuestionWorths({...p,generateAssessment:async value=>{prompt=value;return raw;}});
 add('batchDifficultyPrompt',p,prompt);add('batchWorth',p,expected);
}
await fs.writeFile(new URL('../Tests/PiyaliCoreTests/Fixtures/story-policies.json.gz',import.meta.url),gzipSync(JSON.stringify(fixtures),{level:9}));
console.log(`Compared and exported ${fixtures.length} native policy results against original source modules with read-only browser history.`);
