import fs from 'node:fs/promises';
import path from 'node:path';
const root=path.resolve(process.argv[2] || '../nosabos/nosabos');
const source=await fs.readFile(path.join(root,'src/components/SkillTree.jsx'),'utf8');
const start=source.indexOf('const lessonProgress = lessonProgressById[lesson.id];');
const end=source.indexOf('// Create zigzag pattern',start);
if(start < 0 || end < start) throw Error('Reference renderer changed; review its access rules.');
const resolve=Function('lesson','lessonIndex','lessonProgressById','index','previousUnitLastLessonStatus','isTutorialComplete','isPlacementUnlocked','unit','SKILL_STATUS','isMasterUnlockActive',source.slice(start,end)+'return status;');
const status={LOCKED:'locked',AVAILABLE:'available',IN_PROGRESS:'in_progress',COMPLETED:'completed'};
const units=Array.from({length:3},(_,u)=>({lessons:Array.from({length:2},(_,l)=>({id:`u${u}l${l}`}))}));
const patterns=[{},...units.flatMap(u=>u.lessons).flatMap(lesson=>['in_progress','completed'].map(s=>({[lesson.id]:{status:s}}))),Object.fromEntries(units.flatMap(u=>u.lessons).map(lesson=>[lesson.id,{status:'completed'}]))];
const cases=[];
for(const progress of patterns) for(const tutorial of [false,true]) for(const placed of [false,true]) for(const [u,unit] of units.entries()) for(const [l,lesson] of unit.lessons.entries()) {
 const previous=units[u-1]?.lessons.at(-1)?.id;
 cases.push({units:units.map(x=>x.lessons.map(l=>l.id)),lesson:lesson.id,progress:Object.fromEntries(Object.entries(progress).map(([id,p])=>[id,p.status])),tutorial,placed,expected:resolve(lesson,l,progress,u,progress[previous]?.status ?? '',tutorial,placed,unit,status,()=>false)});
}
await fs.writeFile(new URL('../Tests/PiyaliCoreTests/Fixtures/lesson-access.json',import.meta.url),JSON.stringify(cases));
console.log(`Exported ${cases.length} cases from the actual lesson renderer.`);
