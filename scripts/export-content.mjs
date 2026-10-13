// Reads the reference app only. All generated files are written into this repository.
import fs from 'node:fs';
import path from 'node:path';
import { createRequire } from 'node:module';
const reference = path.resolve(process.argv[2] || '../nosabos/nosabos');
const require = createRequire(path.join(reference, 'package.json'));
const { build } = require('esbuild');
const root = path.resolve(import.meta.dirname, '..');
const entry = `
import { LEARNING_PATHS } from '${reference}/src/data/skillTreeData.js';
import { FLASHCARDS_PRE_A1 } from '${reference}/src/data/flashcards/pre-a1.js';
import { FLASHCARD_DATA as STANDARD_FLASHCARDS } from '${reference}/src/data/flashcardData.js';
import { ACHIEVEMENTS } from '${reference}/src/achievements/catalog.js';
import { localizeAchievement } from '${reference}/src/achievements/copy.js';
import { PHONICS_TARGETS, PHONICS_SUPPORTS, PHONICS_LEVELS, getAuthoredPhonicsDeck } from '${reference}/src/data/phonics/index.js';
import fs from 'node:fs';
import { gzipSync } from 'node:zlib';
const write = (name, value) => fs.writeFileSync(destination+'/'+name+'.json.gz',gzipSync(JSON.stringify(value),{level:9}));
const destination = ${JSON.stringify(root + '/Piyali/Resources')};
const FLASHCARD_DATA = [...FLASHCARDS_PRE_A1, ...STANDARD_FLASHCARDS];
const lessons = Object.fromEntries(Object.entries(LEARNING_PATHS).map(([language, levels]) => [language,
Object.fromEntries(Object.entries(levels).map(([level, units]) => [level, units.filter(u => !u.isTutorial).map(u => ({
 id:u.id, title:u.title, description:u.description, lessons:u.lessons.map(l=>({
 id:l.id,title:l.title,description:l.description,xpReward:l.xpReward||20,modes:l.modes||[],agenda:l.agenda||{},content:l.content||{}
 }))
}))]))]));
for (const [language, levels] of Object.entries(lessons)) write('curriculum-'+language,levels);
write('flashcards',FLASHCARD_DATA);
write('curriculum-index',Object.fromEntries(Object.entries(lessons).map(([lang,levels])=>[lang,Object.fromEntries(Object.entries(levels).map(([level,units])=>[level,units.flatMap(u=>u.lessons.map(l=>l.id))]))])));
write('flashcard-index',Object.fromEntries(PHONICS_LEVELS.map(level=>[level,FLASHCARD_DATA.filter(c=>c.cefrLevel===level).map(c=>c.id)])));

const locales = ['en','es','pt','fr','it','de','ja','hi','ar','zh'];
write('achievements',Object.values(ACHIEVEMENTS).filter(a=>a.source==='nosabos').map(a=>({id:a.id,tier:a.tier,requirement:a.requirement,
 title:Object.fromEntries(locales.map(l=>[l,localizeAchievement(a,l).title])),description:Object.fromEntries(locales.map(l=>[l,localizeAchievement(a,l).desc]))})));

const phonics = {};
for (const target of PHONICS_TARGETS) for (const support of PHONICS_SUPPORTS) for (const level of PHONICS_LEVELS)
phonics[target+':'+support+':'+level] = getAuthoredPhonicsDeck(target,support,level);
write('phonics',phonics);
console.log(JSON.stringify({languages:Object.keys(lessons),lessons:Object.values(lessons).reduce((n,levels)=>n+Object.values(levels).flatMap(u=>u).reduce((n,u)=>n+u.lessons.length,0),0),flashcards:FLASHCARD_DATA.length,phonicsDecks:Object.keys(phonics).length}));
`;
const result = await build({stdin:{contents:entry,resolveDir:reference,sourcefile:'export-content.js'},bundle:true,platform:'node',format:'esm',write:false});
const bundled = path.join(root,'.export-content.mjs');
fs.writeFileSync(bundled,result.outputFiles[0].text);
await import(bundled+'?'+Date.now());
fs.unlinkSync(bundled);
