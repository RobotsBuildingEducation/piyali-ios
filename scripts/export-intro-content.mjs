// Run the reference introduction/adventure helpers in memory; write only native files.
import fs from 'node:fs/promises';
import path from 'node:path';
import {gzipSync,gunzipSync} from 'node:zlib';
import {createHash} from 'node:crypto';
const reference=path.resolve(process.argv[2] || '../nosabos/nosabos');
const esbuild=await import(path.join(reference,'node_modules/esbuild/lib/main.js'));
const entry=`export {LEARNING_PATHS} from ${JSON.stringify(path.join(reference,'src/data/skillTreeData.js'))};export {adaptIntroTutorialUnit,needsIntroTutorial} from ${JSON.stringify(path.join(reference,'src/utils/introTutorial.js'))};export {buildLegacyEpisodeScenario} from ${JSON.stringify(path.join(reference,'src/components/RPGGame/episodes/legacyScenario.js'))};export {buildGameReviewContext} from ${JSON.stringify(path.join(reference,'src/utils/gameReviewContext.js'))};`;
const built=await esbuild.build({stdin:{contents:entry,resolveDir:reference},bundle:true,platform:'node',format:'esm',write:false,logLevel:'error'});
const web=await import('data:text/javascript;base64,'+Buffer.from(built.outputFiles[0].text).toString('base64'));
const root=new URL('../',import.meta.url),supports=['en','es','pt','fr','it','de','ja','hi','ar','zh'];
let variants=0,repaired=0;
for(const [target,levels] of Object.entries(web.LEARNING_PATHS)) {
 const original=levels['Pre-A1'].find(u=>u.isTutorial);
 if(!original) throw new Error('Reference has no introductory unit for '+target);
 const data={target,units:{},games:{},worlds:{}};
 for(const level of Object.keys(levels)) {
  const unit=web.adaptIntroTutorialUnit(original,level),lesson=unit.lessons.find(l=>l.id==='lesson-tutorial-1');
  if(lesson.xpReward!==50 || lesson.modes.length!==6) throw new Error('Reference introduction contract changed: '+JSON.stringify({target,level,xp:lesson.xpReward,modes:lesson.modes}));
  data.units[level]={id:unit.id,title:unit.title,description:unit.description,lessons:[{id:lesson.id,title:lesson.title,description:lesson.description,xpReward:lesson.xpReward,cefrLevel:level,modes:lesson.modes,agenda:lesson.agenda??{},content:lesson.content,objectives:lesson.objectives??{}}]};
  const context=web.buildGameReviewContext({lesson,unit,fallbackLevel:level,targetLang:target}),review={context,bySupport:{}};
  for(const support of supports) {
   const s=web.buildLegacyEpisodeScenario({lesson:{...lesson,gameReviewContext:context},targetLang:target,supportLang:support});
   if(s.quest.steps.length!==7) {
    const source=s.quest.steps;if(!source.length) throw new Error('Empty introductory adventure');
    s.quest.steps=Array.from({length:7},(_,index)=>{const id=index===6?'finale':`b${index+1}`,existing=source.find(step=>step.id===id);if(existing) return existing;const step=structuredClone(source[index%source.length]),weight=index===6?2:1;return {...step,id,weight,nodes:step.nodes.map(node=>({...node,id:id+'-check',weight}))};});
    repaired++;
   }
   const world={width:s.mapWidth,height:s.mapHeight,start:s.playerStart,tiles:s.generate(),solidTiles:Object.entries(s.tiles).filter(([,v])=>v.solid).map(([k])=>Number(k)),objects:s.objects};
   const worldKey=createHash('sha256').update(JSON.stringify(world)).digest('hex').slice(0,24);data.worlds[worldKey]=world;
   review.bySupport[support]={id:s.id,name:s.name,emoji:s.emoji,npcs:s.npcs,quest:s.quest,authoredEpisode:s.authoredEpisode,worldKey};variants++;
  }
  data.games[level]=review;
 }
 await fs.writeFile(new URL('Piyali/Resources/intro-'+target+'.json.gz',root),gzipSync(JSON.stringify(data),{level:9}));
}
const visibility=[];
for(const level of ['Pre-A1','A1','A2','B1','B2','C1','C2']) for(const hasFirstQuestHistory of [false,true]) for(const status of ['', 'in_progress','completed']) {
 const args={level,hasFirstQuestHistory,lessons:status ? {'lesson-tutorial-1':{status}} : {}};
 visibility.push({...args,expected:web.needsIntroTutorial(args)});
}
await fs.writeFile(new URL('Tests/PiyaliCoreTests/Fixtures/intro.json',root),JSON.stringify({visibility,variants,repaired},null,2)+'\n');
const play=JSON.parse(gunzipSync(await fs.readFile(new URL('Piyali/Resources/intro-es.json.gz',root)))).games['Pre-A1'].bySupport.en;
await fs.mkdir(new URL('Tests/PiyaliUITests/Fixtures/',root),{recursive:true});
await fs.writeFile(new URL('Tests/PiyaliUITests/Fixtures/intro-play.json',root),JSON.stringify({steps:play.quest.steps.map(step=>{const node=step.nodes[0];return {mode:node.responseMode,correct:node.choices.findIndex(c=>c.correct),example:node.speechTarget??node.expectedAnswer};})},null,2)+'\n');
console.log(JSON.stringify({languages:Object.keys(web.LEARNING_PATHS).length,levels:7,variants,repaired,visibility:visibility.length}));
