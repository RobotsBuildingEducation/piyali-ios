// Copy original, effect-free placement labels/details and artwork. Reference is read-only.
import fs from 'node:fs/promises';
import path from 'node:path';
import {gzipSync} from 'node:zlib';
import {createHash} from 'node:crypto';
const reference=path.resolve(process.argv[2]||'../nosabos/nosabos');
const files=['src/utils/proficiencyModalTranslations.js','src/utils/cefrLevelInfo.js'];
const sources=await Promise.all(files.map(file=>fs.readFile(path.join(reference,file),'utf8')));
for(const source of sources) if(/^import\s/m.test(source)) throw Error('Placement copy gained a dependency; review export.');
const [copy,details]=await Promise.all(sources.map(source=>import('data:text/javascript;base64,'+Buffer.from(source).toString('base64'))));
await fs.writeFile(new URL('../Piyali/Resources/placement-copy.json.gz',import.meta.url),gzipSync(JSON.stringify({translations:copy.PROFICIENCY_MODAL_TRANSLATIONS,levels:details.CEFR_LEVEL_INFO}),{level:9}));
await fs.copyFile(path.join(reference,'src/assets/10.webp'),new URL('../Piyali/Resources/Brand/placement-dog.webp',import.meta.url));
await fs.writeFile(new URL('../Piyali/Resources/placement-copy.manifest.json',import.meta.url),JSON.stringify(files.map((file,index)=>({file,sha256:createHash('sha256').update(sources[index]).digest('hex')})),null,2)+'\n');
console.log('Exported original placement translations, CEFR details and dog artwork.');
