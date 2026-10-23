import fs from 'node:fs/promises';import path from 'node:path';import vm from 'node:vm';import {gzipSync} from 'node:zlib';import {createHash} from 'node:crypto';
const root=process.cwd(),reference=path.resolve(root,'../nosabos/nosabos'),file='src/constants/languages.js',source=await fs.readFile(path.join(reference,file),'utf8');
const flagNames=source.match(/^import \{([\s\S]*?)\} from "\.\.\/components\/flagsIcons\/flags";/)?.[1].split(',').map(s=>s.trim()).filter(Boolean);if(!flagNames?.length)throw Error('Flag imports moved');
const {SUPPORT_LANGUAGE_CODES}=await import(path.join(reference,'src/constants/supportLanguages.js'));
// Execute the actual option builder; graphics are not needed for its labels,
// tiers or Intl.Collator order. Native menu flags use the existing emoji set.
const module=vm.runInNewContext(`(()=>{${source.replace(/^import[\s\S]*?from "[^"]+";\n/gm,'').replace(/^export /gm,'')};return {getPracticeLanguageOptions}})()`,{Intl,CANONICAL_SUPPORT_LANGUAGE_CODES:SUPPORT_LANGUAGE_CODES,...Object.fromEntries(flagNames.map(name=>[name,()=>null]))});
const result={};for(const language of ['en','es','pt','fr','it','de','ja','hi','ar','zh']){const {copy}=await import(path.join(reference,'src/features/publicCopy/landing',language+'.js'));result[language]=module.getPracticeLanguageOptions({ui:copy,uiLang:language}).map(({value,label,tier})=>({value,label,tier}))}
await fs.writeFile(path.join(root,'Piyali/Resources/landing-language-options.json.gz'),gzipSync(JSON.stringify(result),{level:9}));
const files=[file,'src/constants/supportLanguages.js',...Object.keys(result).map(language=>'src/features/publicCopy/landing/'+language+'.js')];
await fs.writeFile(path.join(root,'docs/reference/landing-language-options-manifest.json'),JSON.stringify({sources:await Promise.all(files.map(async file=>({file,sha256:createHash('sha256').update(await fs.readFile(path.join(reference,file))).digest('hex')}))),scope:'Actual getPracticeLanguageOptions executed with each original public copy locale. Labels include source beta tags and source tier/locale sorting. Flag renderers replaced with null only during data export.'},null,2)+'\n');
console.log('Exported original public-demo menu labels and order for ten locales.');
