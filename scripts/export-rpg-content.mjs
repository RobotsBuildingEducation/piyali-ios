// Execute the actual reference dealers in memory, writing only native resources/fixtures.
import fs from 'node:fs/promises';
import path from 'node:path';
import zlib from 'node:zlib';
import {createHash} from 'node:crypto';
const reference=path.resolve(process.argv[2] || '../nosabos/nosabos');
const esbuild=await import(path.join(reference,'node_modules/esbuild/lib/main.js'));
const legacy=await fs.readFile(path.join(reference,'src/components/RPGGame/episodes/legacyScenario.js'),'utf8');
function sourceSection(start,end) { const a=legacy.indexOf(start),b=legacy.indexOf(end,a+start.length);if(a<0||b<0) throw new Error('Reference story helpers changed');return legacy.slice(a,b); }
const entry=`export {LEARNING_PATHS} from ${JSON.stringify(path.join(reference,'src/data/skillTreeData.js'))};export {EPISODE_MANIFESTS} from ${JSON.stringify(path.join(reference,'src/components/RPGGame/episodes/manifests.js'))};export {CEFR_PROFILES,starsForScore,xpForRun} from ${JSON.stringify(path.join(reference,'src/components/RPGGame/episodes/profile.js'))};export {buildLegacyEpisodeScenario} from ${JSON.stringify(path.join(reference,'src/components/RPGGame/episodes/legacyScenario.js'))};export {buildGameReviewContext} from ${JSON.stringify(path.join(reference,'src/utils/gameReviewContext.js'))};export {matchSpokenTarget} from ${JSON.stringify(path.join(reference,'src/components/RPGGame/content/speechMatch.js'))};`;
const helpers=`import {splitDialogueSubtext} from ${JSON.stringify(path.join(reference,'src/utils/dialogueFormatting.js'))};${sourceSection('const SCRIPT_RANGES =','function hashSeed(')}${sourceSection('function cleanLine(','function parsePreparedJson(')}${sourceSection('function applyPreparedBeats(','export function buildLegacyEpisodeScenario(')} export {validatePreparedStory,preparedStoryMatchesLanguages,applyPreparedBeats,splitDialogueSubtext};`;
const built=await esbuild.build({stdin:{contents:entry+helpers,resolveDir:reference},bundle:true,platform:'node',format:'esm',write:false,logLevel:'error'});
const web=await import('data:text/javascript;base64,'+Buffer.from(built.outputFiles[0].text).toString('base64'));
const root=new URL('../',import.meta.url),supports=['en','es','pt','fr','it','de','ja','hi','ar','zh'];
async function resource(name,data) { await fs.writeFile(new URL('Piyali/Resources/'+name+'.json.gz',root),zlib.gzipSync(JSON.stringify(data),{level:9})); }
function scenario(args, worlds) {
 const s=web.buildLegacyEpisodeScenario(args),map=s.maps[0];
 const world={width:s.mapWidth,height:s.mapHeight,start:s.playerStart,tiles:s.generate(),solidTiles:Object.entries(s.tiles).filter(([,v])=>v.solid).map(([k])=>Number(k)),objects:s.objects};
 const worldKey=createHash('sha256').update(JSON.stringify(world)).digest('hex').slice(0,24);worlds[worldKey]=world;
 return {id:s.id,name:s.name,emoji:s.emoji,npcs:s.npcs,quest:s.quest,authoredEpisode:s.authoredEpisode,worldKey};
}
let reviews=0,catalogRuns=0,repairedReviews=0;
function completeLocalReview(s) {
 if(s.quest.steps.length===7) return s;
 if(!s.quest.steps.length) throw new Error('Reference review has no usable chapter tasks');
 const original=s.quest.steps;
 s.quest.steps=Array.from({length:7},(_,index)=>{
  const id=index===6?'finale':`b${index+1}`,existing=original.find(step=>step.id===id);
  if(existing) return existing;
  const step=structuredClone(original[index%original.length]),weight=index===6?2:1;
  step.id=id;step.weight=weight;step.nodes=step.nodes.map(node=>({...node,id:id+'-check',weight}));
  return step;
 });
 return s;
}
for(const [target,levels] of process.argv.includes("--fixtures-only") ? [] : Object.entries(web.LEARNING_PATHS)) {
 const data={catalog:{},reviews:{},worlds:{}};
 for(const [level,units] of Object.entries(levels)) {
  data.catalog[level]={};
  for(const support of supports) {
   data.catalog[level][support]=Object.keys(web.EPISODE_MANIFESTS).map(episode=>scenario({lesson:{id:'native-library-'+level,content:{game:{cefrLevel:level}}},targetLang:target,supportLang:support,forcedEpisodeId:episode},data.worlds));
   catalogRuns+=data.catalog[level][support].length;
  }
  for(const unit of units.filter(u=>!u.isTutorial)) for(const lesson of unit.lessons.filter(l=>l.isGame)) {
   const context=web.buildGameReviewContext({lesson,unit,fallbackLevel:level,targetLang:target}),item={context,bySupport:{}};
   for(const support of supports) { const local=scenario({lesson:{...lesson,gameReviewContext:context},targetLang:target,supportLang:support},data.worlds);if(support==='en' && local.quest.steps.length!==7) repairedReviews++;item.bySupport[support]=completeLocalReview(local); }
   data.reviews[lesson.id]=item;reviews++;
  }
 }
 await resource('rpg-'+target,data);
 console.log(`Exported ${target}: ${Object.keys(data.reviews).length} unit reviews, seven levels, twelve episodes, ten support languages.`);
}
await resource('rpg-manifests',web.EPISODE_MANIFESTS);await resource('rpg-profiles',web.CEFR_PROFILES);
const scoring=[];
for(const xpReward of [20,30,80]) for(const baseScore of [0,100,559,560,719,720,800]) for(const flairScore of [0,400]) scoring.push({xpReward,baseScore,flairScore,stars:web.starsForScore(baseScore),xp:web.xpForRun({xpReward,baseScore,flairScore})});
const speech=[];
for(const [lang,target,transcripts] of [ ['es','El café está aquí',['el cafe esta aqui','café aquí','Wrong words','']],['en','I am happy',['I am happy','am happy','I am I am','']],['fr','Il est déjà prêt',['il est deja pret','deja pret','I am ready']],['ja','お茶が好き',['お茶が好き','お茶','私はお茶が好きです']],['zh','我喜欢茶',['我喜欢茶','茶','我很喜欢茶']],['hi','मुझे चाय चाहिए',['मुझे चाय चाहिए','चाय','I want tea']],['ar','أريد قهوة',['أريد قهوة','قهوة','coffee']],['ru','Я хочу чай',['Я хочу чай','чай','I want tea']] ]) for(const level of Object.keys(web.CEFR_PROFILES)) for(const transcript of transcripts) { const args={lang,target,transcript,level};speech.push({...args,...web.matchSpokenTarget(args)}); }
const base=scenario({lesson:{id:'native-fixture',content:{game:{cefrLevel:'Pre-A1'}}},targetLang:'es',supportLang:'en',forcedEpisodeId:'marketRush'},{});
const valid={title:'La ayuda',intro:{target:'Una amiga necesita ayuda.',support:'A friend needs help.'},personas:['Friendly vendor','Quiet customer','Curious neighbor'],beats:Array.from({length:7},(_,index)=>({mode:[2,6].includes(index) ? 'speech' : 'choice',npcLine:'¡Hola! ¿Cómo te llamas?',sceneLine:'A friendly person greets you.',coverage:'Introduce yourself',options:['Hola','Adiós','Gracias'],correctIndex:0,speechExample:'Hola, soy Ana.',speechGoal:'Introduce yourself',concept:'Greetings',expectedAnswer:'Hola',right:'*smiles* ¡Muy bien!',wrong:'[looks puzzled] Hola, por favor.'})),epilogue:{target:'Gracias por tu ayuda.',support:'Thank you for helping.'}};
const stories=[];
for(const mode of ['valid','six','allChoice','fourSpeech','badIndex','emptyLine','emptyChoice','emptySpeech','noPersonas','wrongScript','stringIndex','malformedIndex','missingReplies','emptyCaption','longIntro']) {
 const raw=structuredClone(valid);let target='es',support='en';
 if(mode==='six') raw.beats.pop();if(mode==='allChoice') raw.beats.forEach(b=>b.mode='choice');if(mode==='fourSpeech') raw.beats.forEach((b,i)=>b.mode=i<4?'speech':'choice');if(mode==='badIndex') raw.beats[0].correctIndex=4;if(mode==='emptyLine') raw.beats[0].npcLine='';if(mode==='emptyChoice') raw.beats[0].options[0]='';if(mode==='emptySpeech') raw.beats[2].speechExample='';if(mode==='noPersonas') raw.personas=[];if(mode==='wrongScript') target='ja';if(mode==='stringIndex') raw.beats[0].correctIndex='1';if(mode==='malformedIndex') raw.beats[0].correctIndex='bad';if(mode==='missingReplies') {raw.beats[0].right='';raw.beats[0].wrong='';}if(mode==='emptyCaption') raw.beats[0].sceneLine='';if(mode==='longIntro') raw.intro.target='Hola '.repeat(100);
 const prepared=web.validatePreparedStory(raw),expected=prepared && web.preparedStoryMatchesLanguages(prepared,target,support) ? web.applyPreparedBeats(base,prepared) : null;
 stories.push({mode,base,raw,target,support,expected});
}
const dialogue=['Hello!','"Hello!"',"*smiles* Hello!",'[looks up] Hello!',"She says, 'Hello.'",'"Hello," she says.','Ada says: Hello.','Hello! *waves*','Hello! (smiles)','“Hola.”'].map(text=>({text,expected:web.splitDialogueSubtext(text)}));
await fs.writeFile(new URL('Tests/PiyaliCoreTests/Fixtures/rpg.json',root),JSON.stringify({scoring,speech,stories,dialogue},null,2)+'\n');
const uiLibrary=JSON.parse(zlib.gunzipSync(await fs.readFile(new URL('Piyali/Resources/rpg-es.json.gz',root))));
const uiLessonID='unit-pre-a1-people-game',uiScenario=uiLibrary.reviews[uiLessonID].bySupport.en;
await fs.mkdir(new URL('Tests/PiyaliUITests/Fixtures/',root),{recursive:true});
await fs.writeFile(new URL('Tests/PiyaliUITests/Fixtures/rpg-play.json',root),JSON.stringify({lessonID:uiLessonID,steps:uiScenario.quest.steps.map(s=>({mode:s.nodes[0].responseMode,correct:s.nodes[0].choices.findIndex(c=>c.correct),example:s.nodes[0].speechTarget ?? s.nodes[0].expectedAnswer}))},null,2)+'\n');
console.log(JSON.stringify({reviews,catalogRuns,repairedReviews,scoring:scoring.length,speech:speech.length,stories:stories.length,dialogue:dialogue.length}));
