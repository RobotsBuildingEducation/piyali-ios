// Execute the reference's pure filters without changing or running the web app.
import fs from 'node:fs/promises';
import path from 'node:path';
const reference=path.resolve(process.argv[2] || '../nosabos/nosabos');
const text=await fs.readFile(path.join(reference,'src/components/Teams/TeamFeed.jsx'),'utf8');
const sanitize=text.match(/const sanitizeProfiles = \(profiles = \[\]\) => \{[\s\S]*?\n\};/)?.[0];
const extract=text.match(/const extractQuestionNumber = \(text = ""\) => \{[\s\S]*?\n  \};/)?.[0];
if(!sanitize || !extract) throw new Error('Reference feed helpers changed; inspect before exporting');
const helpers=Function(`${sanitize}\n${extract}\nreturn {sanitizeProfiles,extractQuestionNumber}`)();
const cases=[];
for(const name of ['Ada','TEST','data','hi','text','hii','']) for(const content of ['hello','question 0','Finished QUESTION 30','question 180','I just reached 123 XP','A new scholarship']) {
 const question=helpers.extractQuestionNumber(content);
 const allowed=helpers.sanitizeProfiles([{profile:{name}}]).length>0;
 cases.push({name,content,visible:allowed && !!(question || content.toLowerCase().includes('i just reached') || content.toLowerCase().includes('a new scholarship')),question:question || null,percent:question ? Math.min(100,question/120*100) : null});
}
await fs.writeFile(new URL('../Tests/PiyaliCoreTests/Fixtures/community-feed.json',import.meta.url),JSON.stringify(cases,null,2)+'\n');
console.log(`Exported ${cases.length} reference feed comparisons.`);
