// Execute the reference's actual lazy path builder in memory. Never write into it.
import fs from 'node:fs/promises';
import path from 'node:path';
import {gzipSync} from 'node:zlib';
import {createHash} from 'node:crypto';
const root=process.cwd(),reference=path.resolve(root,'../nosabos/nosabos'),esbuild=await import(path.join(reference,'node_modules/esbuild/lib/main.js'));
const source=`export {loadLearningPath} from ${JSON.stringify(path.join(reference,'src/data/skillTree/index.js'))};`;
const built=await esbuild.build({stdin:{contents:source,resolveDir:reference},bundle:true,platform:'node',format:'esm',write:false,metafile:true,logLevel:'error'}),web=await import('data:text/javascript;base64,'+Buffer.from(built.outputFiles[0].text).toString('base64'));
const targets=['es','en','pt','fr','it','nl','nah','ja','ru','de','el','pl','ga','yua'],levels=['Pre-A1','A1','A2','B1','B2','C1','C2'],counts={},index={};
for(const target of targets){const data={};index[target]={};counts[target]={};for(const level of levels){const units=await web.loadLearningPath(target,level);data[level]=JSON.parse(JSON.stringify(units.map(unit=>({...unit,cefrLevel:level,lessons:unit.lessons.map(lesson=>({...lesson,cefrLevel:level,xpReward:lesson.xpReward||20,modes:lesson.modes||[],agenda:lesson.agenda||{},content:lesson.content||{}}))}))));index[target][level]=units.flatMap(u=>u.lessons.map(l=>l.id));counts[target][level]=index[target][level].length;}
 await fs.writeFile(path.join(root,'Piyali/Resources/tutor-curriculum-'+target+'.json.gz'),gzipSync(JSON.stringify(data),{level:9}));}
await fs.writeFile(path.join(root,'Piyali/Resources/tutor-curriculum-index.json.gz'),gzipSync(JSON.stringify(index),{level:9}));
const sources=await Promise.all(Object.keys(built.metafile.inputs).filter(file=>file!=='<stdin>').map(async file=>{const absolute=path.isAbsolute(file)?file:path.resolve(root,file);return {file:path.relative(reference,absolute),sha256:createHash('sha256').update(await fs.readFile(absolute)).digest('hex')};}));
await fs.writeFile(path.join(root,'docs/reference/tutor-content-manifest.json'),JSON.stringify({counts,sources,scope:'Actual loadLearningPath builder executed for all 14 practice languages and seven levels. Source unit/lesson fields are preserved, including tutorial, path colors/positions, tutorPurpose, game launch, target forms and capability evidence. Only plain JSON is exported; no provider, account or progress is read.'},null,2)+'\n');
console.log(JSON.stringify({targets:targets.length,levels:levels.length,lessons:Object.values(counts).flatMap(Object.values).reduce((a,b)=>a+b,0),first:index.es['Pre-A1'][0],firstA1:index.es.A1[0]}));
