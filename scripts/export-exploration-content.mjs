// Read and execute the reference's legacy world/quest builders without network access.
import fs from 'node:fs/promises';
import path from 'node:path';
import zlib from 'node:zlib';
import {createHash} from 'node:crypto';
const reference=path.resolve(process.argv.slice(2).find(arg=>!arg.startsWith('--')) || '../nosabos/nosabos'),esbuild=await import(path.join(reference,'node_modules/esbuild/lib/main.js'));
const file=path.join(reference,'src/components/RPGGame/scenarios.js'),source=await fs.readFile(file,'utf8');
const built=await esbuild.build({stdin:{contents:source+'\nexport {fallbackScenario,normalizeQuest,buildPrompt}; export {WORLD_BLUEPRINTS} from "./worldGen.js";',resolveDir:path.dirname(file)},bundle:true,platform:'node',format:'esm',write:false,logLevel:'error',plugins:[{name:'no-network',setup(build){
  build.onResolve({filter:/utils\/llm$/},()=>({path:'llm',namespace:'mock'}));
  build.onLoad({filter:/.*/,namespace:'mock'},()=>({contents:'export async function callResponses(){return "{}"}',loader:'js'}));
}}]});
const web=await import('data:text/javascript;base64,'+Buffer.from(built.outputFiles[0].text).toString('base64'));
const levels=['Pre-A1','A1','A2','B1','B2','C1','C2'],themes=Object.fromEntries(web.WORLD_BLUEPRINTS.map(b=>[b.id,b.keywords.slice(0,4)]));
function serialize(s,theme,level,lang) {
 const maps=s.maps.map(m=>{const world={width:m.mapWidth,height:m.mapHeight,start:m.playerStart,tiles:m.generate(),solidTiles:Object.entries(m.tiles).filter(([,v])=>v.solid).map(([key])=>Number(key)),objects:m.objects.map(o=>({type:o.type,tx:o.tx,ty:o.ty}))},worldKey=createHash('sha256').update(JSON.stringify(world)).digest('hex').slice(0,24);scenes.push({...m,objects:world.objects,mapData:world.tiles,world,worldKey});return {id:m.id,name:m.name,world,worldKey,portals:m.portals};});
 const record={id:s.id,theme,level,baseLanguage:lang,name:s.name,startMapId:s.startMapId,maps,npcs:s.npcs,quest:s.quest,gatherPlacements:s.gatherPlacements};originalQuestions.set(JSON.stringify(record.quest),s.questions);return record;
}
const originalRandom=Math.random,templates=[],scenes=[],originalQuestions=new Map();
try {
 for(const lang of ['es','en']) for(const level of levels) for(const [theme,terms] of Object.entries(themes)) {
  // Two source variants guarantee both a conversation-only path and a gathering path.
  const byMode=new Map();
  for(let seed=1;seed<=64 && byMode.size<2;seed++) {
   Math.random=web.mulberry32(seed*101+levels.indexOf(level));const scenario=serialize(await web.fallbackScenario(web.REVIEW_WORLD_ID,lang,'en',terms,level),theme,level,lang);
   const gather=scenario.quest.steps.some(step=>step.nodes.some(n=>n.responseMode==='gather'));
   if(!byMode.has(gather)) byMode.set(gather,scenario);
  }
  const variants=[byMode.get(false),byMode.get(true)];if(variants.some(v=>!v)) throw Error('Source variants missing a quest mode');
  templates.push(...variants);console.log('Exported exploration '+lang+'/'+level+'/'+theme+': '+variants.length+' source variants');
 }
} finally { Math.random=originalRandom; }
await fs.mkdir(new URL('../.reference-preview/',import.meta.url),{recursive:true});await fs.writeFile(new URL('../.reference-preview/exploration-scenes.json',import.meta.url),JSON.stringify([...new Map(scenes.filter(m=>templates.some(t=>t.maps.some(a=>a.worldKey===m.worldKey))).map(m=>[m.worldKey,m])).values()]));
const sample=templates.find(s=>s.baseLanguage==='es'&&s.level==='A2'&&s.quest.steps.some(step=>step.nodes.some(n=>n.responseMode==='gather')));
await fs.writeFile(new URL('../.reference-preview/exploration-reference.json',import.meta.url),JSON.stringify({template:sample,questions:originalQuestions.get(JSON.stringify(sample.quest)),maps:scenes.filter(m=>sample.maps.some(a=>a.worldKey===m.worldKey))}));
if(process.argv.includes('--reference-only')){console.log('Prepared original legacy scenario/unused question table for renderer fixture');process.exit(0);}
await fs.writeFile(new URL('../Tests/PiyaliCoreTests/Fixtures/exploration.json',import.meta.url),JSON.stringify(sample,null,2)+'\n');
const client=await fs.readFile(path.join(reference,'src/components/RPGGame/index.jsx'),'utf8');
const copyStart=client.indexOf('function humanizeObjectType('),copyEnd=client.indexOf('function getRpgItemPrimaryLabel(',copyStart);
if(copyStart<0 || copyEnd<0) throw Error('Reference object labels changed');
const copyModule=await import('data:text/javascript;base64,'+Buffer.from(`const DEFAULT_SUPPORT_LANGUAGE='en';const normalizeSupportLanguage=(lang,fallback='en')=>lang;
${client.slice(copyStart,copyEnd)}
export {OBJECT_EXAMINE_FALLBACK_LABELS as labels,OBJECT_EXAMINE_FALLBACK_SENTENCES as sentences,buildFallbackObjectExamineText};`).toString('base64'));
const objectCopy={labels:copyModule.labels,sentences:Object.fromEntries(Object.entries(copyModule.sentences).map(([lang,fn])=>[lang,fn('{{object}}')]))};
await fs.writeFile(new URL('../Piyali/Resources/exploration.json.gz',import.meta.url),zlib.gzipSync(JSON.stringify({templates,objectCopy}),{level:9}));
const objectFixtures=['en','es','ja','fr'].flatMap(lang=>['counter','suitcaseStack','bookshelf'].map(type=>({lang,type,expected:copyModule.buildFallbackObjectExamineText({type},lang)})));
await fs.writeFile(new URL('../Tests/PiyaliCoreTests/Fixtures/exploration-objects.json',import.meta.url),JSON.stringify(objectFixtures,null,2)+'\n');
const keyStart=client.indexOf('  const getObjectExamineKey = useCallback('),keyEnd=client.indexOf('  const syncObjectExamineFromCache',keyStart);
const searchStart=client.indexOf('  const currentObjectSearchQuest = useMemo(() => {'),searchEnd=client.indexOf('  const isObjectSearchQuestStarted',searchStart);
if([keyStart,keyEnd,searchStart,searchEnd].some(n=>n<0)) throw Error('Reference object-search helpers changed');
const objectSearch=await import('data:text/javascript;base64,'+Buffer.from(`export function search(input,index){
 const scenario={...input,maps:input.maps.map(m=>({...m,objects:m.world.objects}))},quest=scenario.quest,questProgress={currentStepIdx:index},currentQuestStep=quest.steps[index],currentQuestNode={responseMode:'objectSearch'};
 const useMemo=fn=>fn(),useCallback=fn=>fn,getRpgItemCompactLabel=item=>item.name,objectSearchCopy={intro:()=>'',wrongItem:()=>'',success:()=>''},ui={wrongItem:'?'};
 ${client.slice(keyStart,keyEnd)}
 ${client.slice(searchStart,searchEnd)}
 return Object.fromEntries(currentObjectSearchQuest.assignments);
}`).toString('base64'));
const gatherIndex=sample.quest.steps.findIndex(step=>step.nodes.some(node=>node.responseMode==='gather')),assignments=objectSearch.search(sample,gatherIndex);
await fs.writeFile(new URL('../Tests/PiyaliCoreTests/Fixtures/exploration-search.json',import.meta.url),JSON.stringify({stepIndex:gatherIndex,assignments},null,2)+'\n');
const correctKey=Object.entries(assignments).find(([,item])=>item.isCorrect)?.[0];
const correctObject=sample.maps.flatMap(map=>map.world.objects.map((object,index)=>({key:`${map.id}:${object.tx},${object.ty}:${object.type}`,mapID:map.id,index}))).find(item=>item.key===correctKey);
const play={level:sample.level,maps:sample.maps.map(map=>({id:map.id,portals:map.portals.map(p=>p.toMapId)})),steps:sample.quest.steps.map(step=>({mapID:sample.npcs[step.npcIdx].mapId,nodes:step.nodes.map(node=>({id:node.id,mode:node.responseMode,line:node.npcLine,item:node.gatherItem?.name||''}))})),placements:sample.gatherPlacements.map(p=>({mapID:p.mapId,name:p.name})),search:{stepIndex:gatherIndex,...correctObject}};
await fs.writeFile(new URL('../Tests/PiyaliUITests/Fixtures/exploration-play.json',import.meta.url),JSON.stringify(play,null,2)+'\n');
console.log('Exported '+templates.length+' exploration templates from actual reference builders.');
