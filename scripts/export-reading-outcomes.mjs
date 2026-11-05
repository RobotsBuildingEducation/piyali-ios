// Execute the unchanged source Reading generator with synthetic streamed records.
import fs from 'node:fs/promises';import path from 'node:path';import vm from 'node:vm';import {createRequire} from 'node:module';import {createHash} from 'node:crypto';
const root=process.cwd(),ref=path.resolve(root,'../nosabos/nosabos'),require=createRequire(path.join(ref,'package.json')),{parse}=require('@babel/parser'),traverse=require('@babel/traverse').default;
const files=['src/components/History.jsx','src/utils/readingHistoryStore.js'],sources=await Promise.all(files.map(f=>fs.readFile(path.join(ref,f),'utf8')));
function extract(source,names){const ast=parse(source,{sourceType:'module',plugins:['jsx']}),found=new Map();traverse(ast,{VariableDeclarator(p){if(names.includes(p.node.id.name))found.set(p.node.id.name,`const ${p.node.id.name}=${source.slice(p.node.init.start,p.node.init.end)};`)},FunctionDeclaration(p){if(names.includes(p.node.id.name))found.set(p.node.id.name,source.slice(p.node.start,p.node.end))}});return names.map(n=>{if(!found.has(n))throw Error('Missing '+n);return found.get(n)}).join('\n')}
const helpers=extract(sources[0],['LANG_NAME','LANGUAGE_LABELS','GENERIC_LANGUAGE_PREFIXES','SPECIAL_REGEX_CHARS','escapeRegExp','buildLabelTokens','stripLineLabel','sanitizeLectureBlock','normalizeForCompare','normalizeReviewQuestion','generateNextLectureGeminiStream']);
const history=extract(sources[1],['META_PREAMBLE_PATTERNS','SPEAKER_LABEL_PATTERN','stripMetaNarratorPreamble','stripSpeakerPrefix']);
const title='{"type":"title","text":"El jardín"}\n',target='{"type":"target","text":"La flor crece."}\n',question='{"type":"review_question","questionType":"text","question":"What grows?","answer":"A flower"}\n',takeaway='{"type":"takeaway","text":"A flower grows."}\n';
const cases=[{name:'target-only',chunks:[target]},{name:'title-only',chunks:[title]},{name:'valid-question-no-done',chunks:[title,target,question,takeaway]},{name:'trailing-record',chunks:[title,target.trimEnd(),]},{name:'invalid-question',chunks:[target,'{"type":"review_question","questionType":"text"}\n']},{name:'no-reveal',chunks:['garbage\n']},{name:'error-after-reveal',chunks:[title,target],fail:true},{name:'error-before-reveal',chunks:['bad\n'],fail:true},{name:'no-reveal-backend-error',chunks:['bad\n'],fallbackFail:true},{name:'stream-error-backend-error',chunks:[title,target],fail:true,fallbackFail:true}];
class FixtureDate extends Date {static now(){return 1700000000000}}
const rows=[];for(const spec of cases){let currentDraft=null;const result={lectures:[],fallback:0,history:0,error:false,fallbackDrafts:[]},preparedQuestion={ticket:null,cancelled:false,discard(){},stream:async fn=>fn(),assess:async()=>({rating:1})},ctx=vm.createContext({npub:'fixture',generatingRef:{current:false},isGenerating:false,setIsGenerating(){},setGenerationError:x=>{result.error=x},setDraftLecture(value){currentDraft=value},lessonContent:{},lesson:null,targetLang:'es',supportLang:'en',cefrLevel:'A1',getReadingComparisonHistory:()=>[],lectures:[],randomReviewQuestionType:()=>'text',buildStreamingPrompt:()=>'',readingModel:{generateContentStream:async()=>({stream:(async function*(){for(const text of spec.chunks)yield{text:()=>text};if(spec.fail)throw Error('fixture error')})()})},preparedQuestion,textFromChunk:x=>x.text(),generateNextLectureBackend:async()=>{result.fallback++;result.fallbackDrafts.push(currentDraft);if(spec.fallbackFail)throw Error('fixture backend error')},getRandomHistoryXp:()=>6,hasSpeechRecognition:false,useUserStore:{getState:()=>({user:{}})},isDuplicateOfLast:()=>false,crypto:{randomUUID:()=>'fixture-id'},setLectures:f=>{result.lectures=f(result.lectures)},setActiveId(){},recordReadingHistory(){result.history++},REVIEW_QUESTION_TYPES:['text','fill','mc'],console:{error(){}},Date:FixtureDate,Math});
 await vm.runInContext(`${history}\n${helpers}\ngenerateNextLectureGeminiStream()`,ctx);rows.push({input:spec,expected:JSON.parse(JSON.stringify(result))});}
await fs.writeFile(path.join(root,'Tests/PiyaliCoreTests/Fixtures/reading-outcomes.json'),JSON.stringify(rows,null,2)+'\n');await fs.writeFile(path.join(root,'docs/reference/reading-outcomes-manifest.json'),JSON.stringify({sources:files.map((file,i)=>({file,sha256:createHash('sha256').update(sources[i]).digest('hex')})),cases:rows.length,scope:'Original Reading generation callback, normalizer and cleaning helpers executed with fake streams and in-memory state; no provider or learner data.'},null,2)+'\n');console.log(rows.map(r=>`${r.input.name}: lectures=${r.expected.lectures.length} fallback=${r.expected.fallback} question=${!!r.expected.lectures[0]?.reviewQuestion}`).join('\n'));
// Execute the source's on-demand question routine up to its Responses request.
const review=extract(sources[0],['LANG_NAME','generateReviewQuestion']),prompts=[];
for(const type of ['text','fill','mc'])for(const [target,support] of [['es','en'],['pt','fr'],['ja','ar'],['hi','en'],['en','hi']]){let captured='';const ctx=vm.createContext({viewLecture:{target:'A short fixture passage.'},isGeneratingQuestion:false,setIsGeneratingQuestion(){},setReviewQuestion(){},setReviewAnswer(){},setReviewSubmitted(){},setReviewCorrect(){},REVIEW_QUESTION_TYPES:['text','fill','mc'],randomReviewQuestionType:()=>'text',targetLang:target,supportLang:support,MODEL:'fixture',callResponses:async({input})=>{captured=input;return '{}'},safeParseJSON:()=>null,console:{error(){} }});await vm.runInContext(`${review}\ngenerateReviewQuestion(${JSON.stringify(type)})`,ctx);prompts.push({type,target,support,text:'A short fixture passage.',expected:captured})}
await fs.writeFile(path.join(root,'Tests/PiyaliCoreTests/Fixtures/reading-review-prompts.json'),JSON.stringify(prompts,null,2)+'\n');console.log(`Exported ${prompts.length} original question fallback prompts.`);

// Exercise the actual JSON-backend callback, retaining its cleaning/validation.
const backend=extract(sources[0],['generateNextLectureBackend']),backendRows=[];
for(const payload of [
 {title:'Spanish: El jardín',target:'Spanish: María: La flor crece.\nTarget: La planta es verde.',takeaways:['English: A flower grows.','• The plant is green.','Third','Fourth'],reviewQuestion:{type:'text',question:'Ignored?',answer:'Ignored'}},
 {target:'Una flor.'}, {title:'Empty',target:''}, {title:'No target'}, {target:'Spanish: '}
]) {
 const result={lectures:[],history:0,error:false},ctx=vm.createContext({lessonContent:{},lesson:null,targetLang:'es',supportLang:'en',cefrLevel:'A1',getRecentReadingHistory:()=>[],lectures:[],buildSeedLecturePrompt:()=>'',buildLecturePrompt:()=>'',callResponses:async()=>JSON.stringify(payload),MODEL:'fixture',READING_WRITER_INSTRUCTION:'',safeParseJSON:JSON.parse,getRandomHistoryXp:()=>6,hasSpeechRecognition:false,preparedQuestion:{assess:async()=>({rating:1})},useUserStore:{getState:()=>({user:{}})},isDuplicateOfLast:()=>false,crypto:{randomUUID:()=>'fixture-id'},setLectures:f=>{result.lectures=f(result.lectures)},setActiveId(){},recordReadingHistory(){result.history++},Date:FixtureDate,Math});
 try {await vm.runInContext(`${history}\n${helpers}\n${backend}\ngenerateNextLectureBackend()`,ctx)} catch {result.error=true}
 backendRows.push({input:payload,expected:JSON.parse(JSON.stringify(result))});
}
await fs.writeFile(path.join(root,'Tests/PiyaliCoreTests/Fixtures/reading-backend-outcomes.json'),JSON.stringify(backendRows,null,2)+'\n');
console.log(`Exported ${backendRows.length} original backend outcomes.`);

const manifestPath=path.join(root,'docs/reference/reading-outcomes-manifest.json'),manifest=JSON.parse(await fs.readFile(manifestPath,'utf8'));
manifest.backendCases=backendRows.length;manifest.scope+=' Also executes the original JSON backend callback and cleaning helpers.';
await fs.writeFile(manifestPath,JSON.stringify(manifest,null,2)+'\n');

// Run the original session-local duplicate guard with boundary and normalization cases.
const duplicateRule=extract(sources[0],['isDuplicateOfLast']),duplicateRows=[],epoch=1700000000000;
const last={id:'original-run',title:'El jardín',target:'La flor crece.',createdAtClient:epoch,awarded:true};
for(const [name,lectures,newTitle,newTarget,now] of [
 ['no-last',[],'El jardín','La flor crece.',epoch],
 ['same',[last],'El jardín','La flor crece.',epoch],
 ['normalized',[last],'  EL   JARDÍN\n',' LA\tFLOR CRECE. ',epoch+14999],
 ['exact-boundary',[last],'El jardín','La flor crece.',epoch+15000],
 ['expired',[last],'El jardín','La flor crece.',epoch+15001],
 ['changed-title',[last],'Otro jardín','La flor crece.',epoch],
 ['changed-body',[last],'El jardín','La flor crece hoy.',epoch],
 ['only-last-counts',[last,{...last,title:'Otra lectura'}],'El jardín','La flor crece.',epoch],
 ['clock-backward',[last],'El jardín','La flor crece.',epoch-1000],
 ['missing-timestamp',[{title:last.title,target:last.target}],'El jardín','La flor crece.',epoch],
 ['cjk',[{...last,title:'庭',target:'花が咲きます。'}],'庭','花が咲きます。',epoch+100],
 ['rtl',[{...last,title:'الحديقة',target:'تنمو الزهرة.'}],'الحديقة','تنمو الزهرة.',epoch+100],
 ['empty-last',[{...last,title:'',target:''}],'','',epoch+100]
]) {
 const input={name,lectures,title:newTitle,target:newTarget,now},ctx=vm.createContext({lectures,Date:{now:()=>now}});
 const expected=vm.runInContext(`${duplicateRule}\nisDuplicateOfLast(${JSON.stringify(newTitle)},${JSON.stringify(newTarget)})`,ctx);
 duplicateRows.push({input,expected});
}
await fs.writeFile(path.join(root,'Tests/PiyaliCoreTests/Fixtures/reading-duplicates.json'),JSON.stringify(duplicateRows,null,2)+'\n');
manifest.duplicateCases=duplicateRows.length;manifest.scope+=' Also executes the original session-local duplicate guard.';
await fs.writeFile(manifestPath,JSON.stringify(manifest,null,2)+'\n');
console.log(`Exported ${duplicateRows.length} original duplicate cases.`);

await fs.writeFile(path.join(root,'Tests/PiyaliAppTests/Fixtures/reading-outcomes.json'),JSON.stringify(rows.filter(row=>row.expected.fallback>0),null,2)+'\n');
