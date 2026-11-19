// Read the original, pure question-copy utilities. Write only into piyali-ios.
import fs from 'node:fs/promises';
import path from 'node:path';
import vm from 'node:vm';
import crypto from 'node:crypto';
import {createRequire} from 'node:module';
import {gzipSync} from 'node:zlib';
const reference=path.resolve(process.argv[2] || '../nosabos/nosabos');
const require=createRequire(path.join(reference,'package.json'));
const {build}=require('esbuild');
const variants={sentence_detective:'SentenceDetective',dialogue_fork:'DialogueFork',sentence_shapeshifter:'SentenceShapeshifter',word_neighborhoods:'WordNeighborhoods',morphology_forge:'MorphologyForge',three_clue_mystery:'ThreeClueMystery',listen_difference:'ListenDifference',three_word_challenge:'ThreeWordChallenge',natural_or_weird:'NaturalOrWeird'};
const sources=await Promise.all(Object.entries(variants).map(async([id,name])=>{
 const file='src/utils/'+name[0].toLowerCase()+name.slice(1)+'I18n.js';
 const source=await fs.readFile(path.join(reference,file),'utf8');
 return {id,name,file,sha256:crypto.createHash('sha256').update(source).digest('hex')};
}));
const entry=sources.map(s=>`import {get${s.name}Copy as ${s.id}} from ${JSON.stringify(path.join(reference,s.file))};`).join('\n')+'\nexport const copy={'+sources.map(s=>s.id).join(',')+'};';
const result=await build({stdin:{contents:entry,resolveDir:reference},bundle:true,format:'iife',globalName:'OriginalPracticeCopy',platform:'neutral',write:false});
const context={};vm.runInNewContext(result.outputFiles[0].text,context,{timeout:1000});
const languages=['en','es','pt','fr','it','de','ja','hi','ar','zh','nl','el','pl','ga','ru','nah','yua'];
const copy=Object.fromEntries(languages.map(lang=>[lang,Object.fromEntries(sources.map(s=>[s.id,context.OriginalPracticeCopy.copy[s.id](lang)]))]));
const parser=require('@babel/parser');
const flashcardSource=await fs.readFile(path.join(reference,'src/components/LessonFlashcard.jsx'),'utf8');
const flashcardAst=parser.parse(flashcardSource,{sourceType:'module',plugins:['jsx']});
const flashcardInit=flashcardAst.program.body.flatMap(n=>n.type==='VariableDeclaration'?n.declarations:[]).find(n=>n.id.name==='FLASHCARD_UI')?.init;
if(!flashcardInit) throw Error('Original flashcard UI copy is missing');
const flashcardCopy=vm.runInNewContext('('+flashcardSource.slice(flashcardInit.start,flashcardInit.end)+')',{}, {timeout:1000});
for(const language of languages) {
 const dictionary=flashcardCopy[language] || flashcardCopy.en;
 copy[language].flashcard=Object.fromEntries(Object.entries({...flashcardCopy.en,...dictionary}).map(([key,value])=>[key,typeof value==='function'?value('{language}'):value]));
}
sources.push({id:'flashcard',file:'src/components/LessonFlashcard.jsx',sha256:crypto.createHash('sha256').update(flashcardSource).digest('hex')});
await fs.writeFile(new URL('../Piyali/Resources/practice-copy.json.gz',import.meta.url),gzipSync(JSON.stringify(copy),{level:9}));
await fs.writeFile(new URL('../Piyali/Resources/practice-copy.manifest.json',import.meta.url),JSON.stringify(sources.map(({id,file,sha256})=>({id,file,sha256})),null,2)+'\n');
console.log(`Exported original copy for ${sources.length} question variants in ${languages.length} language selections.`);
