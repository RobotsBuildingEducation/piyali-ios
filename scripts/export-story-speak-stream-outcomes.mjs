// Run the current source's actual Speak streaming callback with public fake providers.
import fs from 'node:fs/promises';import path from 'node:path';import vm from 'node:vm';import {createHash} from 'node:crypto';import {createRequire} from 'node:module';
const root=process.cwd(),ref=path.resolve(process.argv[2]||'../nosabos/nosabos'),file='src/components/Stories.jsx',source=await fs.readFile(path.join(ref,file),'utf8');
const require=createRequire(path.join(ref,'package.json')),{parse}=require('@babel/parser'),traverse=require('@babel/traverse').default;let callback;
traverse(parse(source,{sourceType:'module',plugins:['jsx']}),{VariableDeclarator(p){if(p.node.id.name==='generateStoryGeminiStream'){const node=p.node.init.arguments?.[0];if(!node?.async)throw Error('Source Speak callback moved');callback=source.slice(node.start,node.end);p.stop()}}});if(!callback)throw Error('Source Speak callback missing');
const specs=[
 {name:'one-complete-no-done',chunks:['{"type":"sentence","tgt":"Hola."}\n']},
 {name:'trailing-complete-no-newline',chunks:['{"type":"sentence","tgt":"Hola."}']},
 {name:'two-without-done',chunks:['{"type":"sentence","character":"Ana","tgt":"Hola."}\n','{"type":"sentence","character":"Ana","tgt":"Bien."}\n']},
 {name:'failure-after-reveal',chunks:['{"type":"sentence","tgt":"Hola."}\n'],fail:true},
 {name:'failure-after-reveal-with-unfinished-record',chunks:['{"type":"sentence","tgt":"Hola."}\n{"type":"sentence","tgt":"Buen'],fail:true},
 {name:'failure-before-reveal',chunks:['{"type":"sentence","tgt":"Buen'],fail:true},
 {name:'empty-stream',chunks:['not json\n']},
 {name:'numeric-truthy-target',chunks:['{"type":"sentence","tgt":7}\n']},
];
const rows=[];
for(const spec of specs){
 const state={story:null,assess:0,fallback:0,history:0,discard:0,error:false};
 const preparedQuestion={ticket:null,cancelled:false,discard(){state.discard++},async stream(run){return run()},async assessMany({questions}){state.assess++;return questions.map(()=>({difficulty:1}))}};
 const ctx=vm.createContext({generationRequestRef:{current:0},questionWorthForUser:()=>({base:true}),user:{},targetLang:'es',cefrLevel:'A1',storyCacheRef:{current:null},storyWorthReadyRef:{current:null},setIsLoading:()=>{},setIsStreaming:()=>{},isStreamingRef:{current:false},setGenerationError:x=>{state.error=x},stopAllAudio:()=>{},setRevealedTranslations:()=>{},setSentenceTranslations:()=>{},setTranslatingSentences:()=>{},setSessionXp:()=>{},sessionAwardedRef:{current:false},rewardedSentenceKeysRef:{current:new Set()},usageStatsRef:{current:{storyGenerations:0}},preparedQuestion,createStoryPlan:()=>({isTutorial:true,objective:''}),lessonContent:{topic:'tutorial'},lesson:{id:'fixture'},npub:'public-fixture',buildSpeakingStoryPrompt:()=>'',LLM_LANG_NAME:x=>x,getStoryDifficulty:()=>'',focusedLessonPrompt:()=>'',generationPerformanceContextFor:()=>({}),curriculumCefrLevel:'A1',buildStoryDiversityPrompt:()=>'',setStoryType:()=>{},setStoryData:x=>{state.story=typeof x==='function'?x(state.story):x},storyModel:{async generateContentStream(){return{stream:(async function*(){for(const text of spec.chunks)yield{text};if(spec.fail)throw Error('fixture stream failure')})()}}},storyRevisionModel:{},useUserStore:{getState:()=>({user:{}})},recordStoryHistory:()=>{state.history++},storyServices:{review:null},generatePracticeStory:async()=>{state.fallback++;return{fullStory:{tgt:'Fallback',sup:''},sentences:[{tgt:'Fallback',sup:'',character:'Sheilfer'}],storyType:'conversation'}},console:{warn(){},error(){},debug(){}},Promise,Error});
 await vm.runInContext(`(${callback})()`,ctx);
 rows.push({input:spec,expected:{sentences:state.story?.sentences||[],assess:state.assess,fallback:state.fallback,history:state.history,discard:state.discard,error:state.error}});
}
await fs.writeFile(path.join(root,'Tests/PiyaliCoreTests/Fixtures/story-speak-stream-outcomes.json'),JSON.stringify(rows,null,2)+'\n');await fs.writeFile(path.join(root,'docs/reference/story-speak-stream-outcomes-manifest.json'),JSON.stringify({source:file,sha256:createHash('sha256').update(source).digest('hex'),cases:rows.length,scope:'Original generateStoryGeminiStream callback executed with in-memory state, fake stream and assessment, and public fixtures; no learner, provider, microphone or network.'},null,2)+'\n');console.log(rows.map(r=>`${r.input.name}: ${r.expected.sentences.length} lines; fallback=${r.expected.fallback}; assess=${r.expected.assess}; history=${r.expected.history}`).join('\n'));
