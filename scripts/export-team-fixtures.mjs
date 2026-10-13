// Bundle pure reference helpers in memory; write only native fixtures.
import fs from 'node:fs/promises';
import path from 'node:path';
const reference=path.resolve(process.argv[2] || '../nosabos/nosabos');
const esbuild=await import(path.join(reference,'node_modules/esbuild/lib/main.js'));
const entry=`export {teamProgressRow,buildTeamEvent,parseTeamEvent,memberLeft} from ${JSON.stringify(path.join(reference,'src/utils/learningTeams.js'))}; export {reconcileUserTeams} from ${JSON.stringify(path.join(reference,'src/utils/reconcileTeams.js'))};`;
const bundle=await esbuild.build({stdin:{contents:entry,resolveDir:reference},bundle:true,platform:'node',format:'esm',write:false});
const web=await import('data:text/javascript;base64,'+Buffer.from(bundle.outputFiles[0].text).toString('base64'));
const rows=[];
for(const schemaVersion of [1,2]) for(const score of [null,'',0,14.9,42,101,'27','bad']) for(const companion of [null,{name:'  Coco  ',type:'dog',level:2,health:110},{name:'日本語',type:'DOG',level:40.8,health:-2}]) {
 const data={schemaVersion,score,scoreScale:'0-100',companion,name:'  Ada  ',targetLang:'es',level:'B1',streak:3,answeredStepsCount:8,progressPercent:67,xp:1200,goal:30,dailyXp:20};
 rows.push({data,expected:web.teamProgressRow('npub1fixture',data,true)});
}
const events=[];
for(const deleted of [false,true]) {
 const args={id:'local-team',name:'Equipo 日本語',memberHexes:['a'.repeat(64),'b'.repeat(64),'a'.repeat(64)],createdAt:1700000000,deleted};
 const expected=web.buildTeamEvent(args);expected.content=JSON.parse(expected.content);
 events.push({args,expected});
}
const departures=[];
for(const created of [100,101,200]) for(const left of [null,99,100,101,201]) departures.push({created,left,expected:web.memberLeft(created,left)});
const fixture={rows,events,departures};
await fs.writeFile(new URL('../Tests/PiyaliCoreTests/Fixtures/teams.json',import.meta.url),JSON.stringify(fixture,null,2)+'\n');
console.log(`Exported ${rows.length} progress rows, ${events.length} team templates and ${departures.length} departure comparisons from the reference.`);
