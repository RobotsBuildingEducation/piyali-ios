// Extract only pure collection functions; importing the web service would initialize host adapters.
import fs from 'node:fs/promises';
import path from 'node:path';
const reference=path.resolve(process.argv[2] || '../nosabos/nosabos');
const source=await fs.readFile(path.join(reference,'src/utils/achievements.js'),'utf8');
function section(start,end) { const a=source.indexOf(start),b=source.indexOf(end,a+start.length);if(a<0||b<0) throw new Error('Reference collection function changed');return source.slice(a,b); }
const esbuild=await import(path.join(reference,'node_modules/esbuild/lib/main.js'));
const entry=`export { ACHIEVEMENTS,completeCollectionAwards } from ${JSON.stringify(path.join(reference,'src/achievements/catalog.js'))};
const ACHIEVEMENT_KIND=30078,ACHIEVEMENT_D='learning-achievements',ACHIEVEMENT_TAG='learning-achievements',CATALOG_VERSION=8;
const ACHIEVEMENT_IDENTIFIERS=[ACHIEVEMENT_D,ACHIEVEMENT_D+':nosabos',ACHIEVEMENT_D+':robotsbuildingeducation'];
${section('export const buildAchievementEvent =','export async function restoreAchievements')}
${section('export function mergeAchievementMaps(','export function completeCourseAward')}`;
const bundled=await esbuild.build({stdin:{contents:entry,resolveDir:reference},bundle:true,format:'esm',platform:'node',write:false});
const web=await import('data:text/javascript;base64,'+Buffer.from(bundled.outputFiles[0].text).toString('base64'));
const merging=[];
for(const test of [false,true,0,1,'', 'false',[],{}]) {
 const maps=[{'legacy-slot':{unlockedAt:30,test,extra:'preserve'},'invalid':{unlockedAt:0}}, {'legacy-slot':{unlockedAt:40},'old_other':{unlockedAt:10,source:'robotsbuildingeducation'}}];
 merging.push({maps,expected:web.mergeAchievementMaps(...maps)});
}
const completion=[];
for(const map of [ {}, {'piyali_tutor_complete_b2':{unlockedAt:10,source:'nosabos'}}, {'piyali_goals_complete_c1':{unlockedAt:11,source:'nosabos'}}, {'piyali_full_curriculum_v4':{unlockedAt:20,source:'nosabos'},'robots_full_curriculum_v4':{unlockedAt:25,source:'robotsbuildingeducation'}}, {'piyali_full_curriculum_v4':{unlockedAt:20,source:'nosabos'},'robots_full_curriculum_v4':{unlockedAt:25,source:'robotsbuildingeducation',test:true}}, {'unknown-v1':{unlockedAt:8}}, {'piyali_tutor_complete_c2':{unlockedAt:9,test:true}} ]) completion.push({map,expected:web.completeCollectionAwards(map)});
const events=[];
for(const source of [undefined,'nosabos','robotsbuildingeducation']) { const records={'legacy-slot':{unlockedAt:123,extra:'日本語 / español'}};events.push({records,source:source ?? null,expected:web.buildAchievementEvent(records,{source,createdAt:1700000000})}); }
const fixture={merging,completion,events};
await fs.writeFile(new URL('../Tests/PiyaliCoreTests/Fixtures/nostr-collections.json',import.meta.url),JSON.stringify(fixture,null,2)+'\n');
console.log(`Exported ${merging.length} merges, ${completion.length} completion maps and ${events.length} event templates from the reference.`);
