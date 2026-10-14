import fs from 'node:fs/promises';
import path from 'node:path';
import zlib from 'node:zlib';
const reference=path.resolve(process.argv[2] || '../nosabos/nosabos');
const esbuild=await import(path.join(reference,'node_modules/esbuild/lib/main.js'));
const source=path.join(reference,'src/features/stories');
const result=await esbuild.build({stdin:{contents:`export * from ${JSON.stringify(path.join(source,'storySession.js'))};export * from ${JSON.stringify(path.join(source,'storyPrompts.js'))};export * from ${JSON.stringify(path.join(source,'practiceStoryRewards.js'))};`,resolveDir:reference},bundle:true,platform:'node',format:'esm',write:false});
const web=await import('data:text/javascript;base64,'+Buffer.from(result.outputFiles[0].text).toString('base64'));
const episode={title:'A surprise',segments:[
 {turns:[{speaker:'Ana',target:'Tengo flores rojas.',support:'I have red flowers.'},{speaker:'Luis',target:'Son para mi madre.',support:'They are for my mother.'}],question:{type:'select_words',prompt:'Select two words you hear.',options:['azules','flores','rojas','nunca'],answer:[1,2],audioTurn:0,explanation:'Ana has red flowers.'}},
 {turns:[{speaker:'Ana',target:'¿Es su cumpleaños?',support:'Is it her birthday?'},{speaker:'Luis',target:'Sí, es hoy.',support:'Yes, it is today.'}],question:{type:'order_words',prompt:'Build what you hear.',options:['hoy','Sí','es'],answer:[1,2,0],audioTurn:1,explanation:'Her birthday is today.'}}
]};
const cases=[];
function check(raw,target='',prepare=false) { let valid=true;try { const value=prepare ? web.prepareGeneratedStorySession(raw,{targetLang:target}) : web.parseStorySession(raw);if(target&&!prepare) web.assertStorySessionLanguage(value,target); } catch { valid=false };cases.push({raw:structuredClone(raw),target,prepare,valid}); }
check(episode,'es');check('```json\n'+JSON.stringify(episode)+'\n```','es');
for(const mutate of [s=>s.title='',s=>s.segments=[],s=>s.segments[0].turns=[],s=>s.segments[0].question.answer=[8],s=>s.segments[0].question.answer=[1,1],s=>s.segments[0].question.audioTurn=8,s=>s.segments[0].question.options[0]='Tengo',s=>s.segments[1].question.answer=[0,1,2],s=>s.segments[1].turns[0].speaker='Other',s=>s.segments[1].question.type='unknown',s=>s.segments[0].question.options[0]='flores',s=>s.segments[0].question.explanation='']) {const raw=structuredClone(episode);mutate(raw);check(raw,'es');}
for(const [lang,text,words] of [['ja','赤い花があります。',['青い','赤い','花','明日']],['zh','今天是她的生日。',['昨天','今天','生日','我']],['ar','هذا البيت جميل جدا',['قديم','البيت','جميل','غدا']]]) {
 const raw=structuredClone(episode);raw.segments[0].turns[0].target=text;raw.segments[0].turns[1].target=text;raw.segments[0].question.options=words;raw.segments[1].turns.forEach(t=>t.target=text);raw.segments[1].question.type='choice';raw.segments[1].question.options=['Yes','No'];raw.segments[1].question.answer=[0];check(raw,lang);check(episode,lang);
}
for(const type of ['choice','true_false','reply']) {const raw=structuredClone(episode);raw.segments[0].question={type,prompt:'What happens?',options:type==='true_false'?['True','False']:['Flores','Azules','Madre'],answer:[0],explanation:'Listen to the dialogue.'};check(raw,'es');raw.segments[0].question.answer=[0,1];check(raw,'es');}
const badTiles=structuredClone(episode);badTiles.segments[1].turns[1].target='La fiesta empieza a las ocho de la noche.';badTiles.segments[1].question.options=['las','a','empieza','la','noche','fiesta','de','a.m.chochte'];badTiles.segments[1].question.answer=[5,2,1,0,6,4];check(badTiles,'es');check(badTiles,'es',true);
const answers=[];for(const segment of episode.segments) for(const selected of [[],[0],[1],[1,2],[2,1],[1,1],[1,2,0],[0,1,2]]) answers.push({question:segment.question,selected,correct:web.isStoryAnswerCorrect(segment.question,selected)});
const tiles=['Sí, es hoy.','Muy, muy, muy bien.','La casa es bonita y la casa es grande.','今日は母の誕生日です。','今天是她的生日。','هذا البيت جميل جدا'].map(text=>{const q=web.buildStoryWordTiles(text,()=>0.5);return {text,canonical:q.answer.map(i=>q.options[i]).join(' ')};});
const modes=[];for(const content of [null,{topic:'tutorial',storyMode:'radio'},{storyMode:'radio'}]) for(const random of [0,0.4,0.9]) modes.push({content,random,selected:web.chooseStoryMode(content,()=>random),rotated:web.rotateStoryMode('speaking',content,()=>random)});
const args={targetName:'{{targetName}}',targetLang:'{{target}}',supportName:'{{supportName}}',supportLang:'{{support}}',difficulty:web.getStoryDifficulty('{{level}}'),context:'{{context}}',userCharacterName:'You'};
// getStoryDifficulty normalizes unknown placeholders; substitute a real CEFR token afterwards.
args.difficulty=web.getStoryDifficulty('A1').replace('CEFR A1','CEFR {{level}}');
const prompts={radio:web.buildStorySessionPrompt({...args,mode:'radio'}),conversation:web.buildStorySessionPrompt({...args,mode:'conversation'}),speaking:web.buildSpeakingStoryPrompt({...args,isTutorial:false,scenarioDirective:'{{context}}'}).split('Output protocol:')[0],writing:web.buildStoryWritingBrief({mode:'speaking',includeTranslations:false})};
const speechPath=path.join(reference,'src/utils/speechEvaluation.js');
const speechBundle=await esbuild.build({stdin:{contents:(await fs.readFile(speechPath,'utf8'))+'\nexport {STOPWORDS,STRICT};',resolveDir:path.dirname(speechPath)},bundle:true,platform:'node',format:'esm',write:false});
const speechWeb=await import('data:text/javascript;base64,'+Buffer.from(speechBundle.outputFiles[0].text).toString('base64'));
const speech=[];for(const lang of ['es','en','pt','fr','it','nl','nah']) for(const targetSentence of ['Hola, tengo flores rojas.','The flowers are for my mother.','Café, café, muy bonito.','Sí, es hoy.']) for(const recognizedText of [targetSentence,targetSentence.toUpperCase(),'not the right phrase']) for(const confidence of [0,0.2,0.9]) {
 const input={lang,targetSentence,recognizedText,confidence};speech.push({input,expected:speechWeb.evaluateAttemptStrict(input)});
}
const speechRules=JSON.stringify({thresholds:speechWeb.STRICT,stopwords:Object.fromEntries(Object.entries(speechWeb.STOPWORDS).map(([lang,set])=>[lang,[...set]]))});
await fs.writeFile(new URL('../Piyali/Core/StorySpeechRules.swift',import.meta.url),'// Generated from the read-only reference speechEvaluation.js. Re-export with scripts/export-story-fixtures.mjs.\nimport Foundation\nenum StorySpeechRules { static let configuration=try! JSONDecoder().decode(JSONValue.self,from:Data(#\"'+speechRules+'\"#.utf8)) }\n');
await fs.writeFile(new URL('../Tests/PiyaliCoreTests/Fixtures/stories.json',import.meta.url),JSON.stringify({cases,answers,tiles,modes,speech},null,2)+'\n');
await fs.writeFile(new URL('../Piyali/Resources/story-prompts.json.gz',import.meta.url),zlib.gzipSync(JSON.stringify(prompts),{level:9}));
await fs.writeFile(new URL('../Piyali/Resources/story-test-episode.json.gz',import.meta.url),zlib.gzipSync(JSON.stringify(episode),{level:9}));
console.log(`Exported ${cases.length} episode validations, ${answers.length} answers, ${tiles.length} tile sentences, ${modes.length} mode cases and source writing prompts.`);
