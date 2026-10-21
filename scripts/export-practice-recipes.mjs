import fs from 'node:fs/promises';
import path from 'node:path';
import crypto from 'node:crypto';
import vm from 'node:vm';
import {gzipSync,gunzipSync} from 'node:zlib';

// Lift only the original pure prompt builders and their lexical dependencies.
// The reference stays read-only. React components, storage, audio and network
// effects are neither bundled nor exposed to the native recipe interpreter.
const reference=path.resolve(process.argv[2] || '../nosabos/nosabos');
const parser=await import(path.join(reference,'node_modules/@babel/parser/lib/index.js'));
const traversal=await import(path.join(reference,'node_modules/@babel/traverse/lib/index.js'));
const traverse=traversal.default.default ?? traversal.default;
const esbuild=await import(path.join(reference,'node_modules/esbuild/lib/main.js'));
const modules=new Map();
const pending=[];
const forbidden=new Set(['window','document','localStorage','sessionStorage','fetch','XMLHttpRequest','React','navigator','process']);
const storeFile=path.join(reference,'src/hooks/useUserStore.js');
const translationFile=path.join(reference,'src/utils/translation.jsx');
const flagsFile=path.join(reference,'src/components/flagsIcons/flags.jsx');
const languageCopy=JSON.parse(gunzipSync(await fs.readFile(new URL('../Piyali/Resources/app-copy.json.gz',import.meta.url))));
const labels=Object.fromEntries(Object.entries(languageCopy).map(([lang,strings])=>[lang,Object.fromEntries(Object.entries(strings).filter(([key])=>key.startsWith('language_')))]));
async function resolve(specifier,importer) {
 if(!specifier.startsWith('.') && !path.isAbsolute(specifier)) throw Error(`Non-local dependency ${specifier} in ${importer}`);
 const base=path.resolve(path.dirname(importer),specifier);
 for(const candidate of [base,base+'.js',base+'.jsx',path.join(base,'index.js')]) {
  if(await fs.stat(candidate).then(s=>s.isFile()).catch(()=>false)) return candidate;
 }
 throw Error(`Missing source dependency: ${specifier}`);
}
async function moduleFor(file) {
 if(modules.has(file)) return modules.get(file);
 const source=await fs.readFile(file,'utf8'),ast=parser.parse(source,{sourceType:'module',plugins:['jsx']});
 let program;
 traverse(ast,{Program(p){program=p;p.stop();}});
 const record={file,source,program,required:new Set(),declarations:new Map(),imports:new Map(),exports:new Map()};
 if(file===storeFile) record.adapter='let user={};export function provide(value){user=value||{};}export default {getState:()=>({user})};';
 if(file===translationFile) record.adapter='export const translations='+JSON.stringify(labels)+';export default translations;';
 if(file===flagsFile) record.adapter='flags';
 modules.set(file,record);return record;
}
async function requireSymbol(file,symbol) {
 const record=await moduleFor(file);
 if(!record.required.has(symbol)) { record.required.add(symbol);pending.push({record,symbol}); }
}
async function collect(record,node) {
 const names=new Set();
 node.traverse({ReferencedIdentifier(p) {
  const name=p.node.name,binding=p.scope.getBinding(name);
  if(binding?.scope===record.program.scope) names.add(name);
  else if(!binding && forbidden.has(name)) throw Error(`Effectful dependency ${name} in ${record.file}`);
 }});
 for(const name of names) await requireSymbol(record.file,name);
}
async function lift({record,symbol}) {
 if(record.adapter) {
  if(record.file===flagsFile) { const declaration=record.program.scope.getBinding(symbol)?.path;if(!declaration || !(declaration.isFunctionDeclaration() || declaration.isVariableDeclarator() && declaration.get('init').isArrowFunctionExpression())) throw Error('Unsupported flag reference '+symbol);return; }
  if(!(record.file===translationFile ? ['default','translations'] : ['default','provide']).includes(symbol)) throw Error('Unsupported native adapter binding '+symbol);return;
 }
 const binding=record.program.scope.getBinding(symbol);
 if(!binding) throw Error(`Missing pure binding ${symbol} in ${record.file}`);
 if(binding.kind==='module') {
  const declaration=binding.path.parentPath;
  if(!declaration.isImportDeclaration()) throw Error('Unsupported imported binding '+symbol);
  if(!binding.path.isImportSpecifier() && !binding.path.isImportDefaultSpecifier()) throw Error('Unsupported pure import: '+symbol);
  const imported=binding.path.isImportDefaultSpecifier() ? 'default' : binding.path.node.imported.name;
  const file=await resolve(declaration.node.source.value,record.file);
  const imports=record.imports.get(file) ?? new Map();imports.set(symbol,imported);record.imports.set(file,imports);
  await requireSymbol(file,imported);
 } else {
  let statement=binding.path.getStatementParent();
  if(statement.isExportNamedDeclaration()) statement=statement.get('declaration');
  if(!statement.isFunctionDeclaration() && !statement.isVariableDeclaration()) throw Error('Unsupported pure declaration '+symbol);
  if(!record.declarations.has(statement.node.start)) { record.declarations.set(statement.node.start,statement);await collect(record,statement); }
 }
 record.exports.set(symbol,symbol);
}
const grammar=path.join(reference,'src/components/GrammarBook.jsx');
const vocabulary=path.join(reference,'src/components/Vocabulary.jsx');
const flashcard=path.join(reference,'src/components/LessonFlashcard.jsx');
const delight=path.join(reference,'src/utils/delightQuestionVariants.js');
const options=path.join(reference,'src/features/lessonPreparation/options.js');
const recipes={
 grammar:{fill:'buildFillStreamPrompt',mc:'buildMCStreamPrompt',ma:'buildMAStreamPrompt',speak:'buildSpeakGrammarStreamPrompt',match:'buildMatchStreamPrompt',translate:'buildTranslateStreamPrompt',repeat:'buildTranslateStreamPrompt',judgeFill:'buildFillJudgePrompt',judgeMC:'buildMCJudgePrompt',judgeMA:'buildMAJudgePrompt',judgeTranslate:'buildTranslateJudgePrompt'},
 vocabulary:{fill:'buildFillVocabStreamPrompt',mc:'buildMCVocabStreamPrompt',ma:'buildMAVocabStreamPrompt',speak:'buildSpeakVocabStreamPrompt',match:'buildMatchVocabStreamPrompt',translate:'buildVocabTranslateStreamPrompt',repeat:'buildVocabTranslateStreamPrompt',judgeFill:'buildFillVocabJudgePrompt',judgeMC:'buildMCVocabJudgePrompt',judgeMA:'buildMAVocabJudgePrompt',judgeMatch:'buildMatchVocabJudgePrompt',judgeTranslate:'buildVocabTranslateJudgePrompt'}
};
for(const [kind,file] of [['grammar',grammar],['vocabulary',vocabulary]]) for(const symbol of Object.values(recipes[kind])) await requireSymbol(file,symbol);
await requireSymbol(flashcard,'buildLessonFlashcardPrompt');await requireSymbol(flashcard,'buildFlashcardJudgePrompt');
for(const symbol of ['DELIGHT_VARIANTS','DELIGHT_VARIANT_IDS','buildDelightQuestionPrompt','buildDelightResponseJudgePrompt','normalizeDelightQuestion','isDelightQuestionLanguageConsistent','getInitialDelightResponse','gradeDelightResponse','isDelightResponseReady','calculateDelightQuestionXp','getDelightFallbackQuestion','buildSentenceDetectivePrompt','validateMorphologyForgeQuestion']) await requireSymbol(delight,symbol);
await requireSymbol(options,'createQuestionOptionSelector');
await requireSymbol(storeFile,'provide');
for(let i=0;i<pending.length;i++) await lift(pending[i]);
const virtual=new Map();
for(const record of modules.values()) {
 if(record.adapter) { virtual.set(record.file,record.file===flagsFile ? Array.from(record.required,name=>`export function ${name}(){return null;}`).join('\n') : record.adapter);continue; }
 const imports=Array.from(record.imports,([file,names])=>`import {${Array.from(names,([local,original])=>`${original} as ${local}`).join(',')}} from ${JSON.stringify(file)};`);
 const declarations=Array.from(record.declarations).sort(([a],[b])=>a-b).map(([,p])=>record.source.slice(p.node.start,p.node.end));
 virtual.set(record.file,imports.join('\n')+'\n'+declarations.join('\n')+`\nexport {${Array.from(record.exports.keys()).join(',')}};`);
}
const entry=`import * as grammar from ${JSON.stringify(grammar)};import * as vocabulary from ${JSON.stringify(vocabulary)};import * as flashcard from ${JSON.stringify(flashcard)};import * as delight from ${JSON.stringify(delight)};import {createQuestionOptionSelector} from ${JSON.stringify(options)};import {provide} from ${JSON.stringify(storeFile)};
const recipes={grammar:${JSON.stringify(recipes.grammar)},vocabulary:${JSON.stringify(recipes.vocabulary)}};
function withParameters(parametersJSON,operation) {
 const parameters=JSON.parse(parametersJSON);provide(parameters.user);
 const previousRandom=Math.random;
 if(Number.isFinite(parameters.randomSeed)) { let state=parameters.randomSeed>>>0;Math.random=()=>{state=(state+0x6d2b79f5)>>>0;let t=Math.imul(state^(state>>>15),1|state);t=(t+Math.imul(t^(t>>>7),61|t))^t;return ((t^(t>>>14))>>>0)/4294967296;}; }
 try { return operation(parameters); }
 finally { Math.random=previousRandom; }
}
export function build(module,kind,parametersJSON) { return withParameters(parametersJSON,parameters=>{
 if(kind.startsWith('delight:')) { const variant=kind.slice(8);if(!delight.DELIGHT_VARIANT_IDS.includes(variant)) throw Error('Unsupported delight recipe');return (variant==='sentence_detective' ? delight.buildSentenceDetectivePrompt : delight.buildDelightQuestionPrompt)({...parameters,variant,moduleType:module}); }
 if(kind==='preflightMorphology') { let prompt='';void delight.validateMorphologyForgeQuestion(parameters.question,{...parameters,judge:input=>{prompt=input;return 'YES';}});if(!prompt) throw Error('Invalid morphology reference');return prompt;}
 if(kind==='judgeDelight') return delight.buildDelightResponseJudgePrompt({...parameters,moduleType:module});
 if(kind==='flashcard') return flashcard.buildLessonFlashcardPrompt({...parameters,moduleType:module,collectedConcepts:parameters.collectedConcepts || []});if(kind==='judgeFlashcard') return flashcard.buildFlashcardJudgePrompt(parameters);const name=recipes[module]?.[kind];if(!name) throw Error('Unsupported exercise recipe');return (module==='grammar'?grammar:vocabulary)[name](parameters);
}); }
const selector=createQuestionOptionSelector();
export function select(mode,parametersJSON) { return withParameters(parametersJSON,p=>JSON.stringify(selector(mode,p.context))); }
export function resetOptions() { selector.reset();return '{}'; }
export function inspect(operation,parametersJSON) { return withParameters(parametersJSON,p=>{
 const q=p.question,r=p.response;
 const operations={variants:()=>delight.DELIGHT_VARIANTS,normalize:()=>delight.normalizeDelightQuestion(p.variant,p.raw,{targetLang:p.targetLang}),languageConsistent:()=>delight.isDelightQuestionLanguageConsistent(q,p),initialResponse:()=>delight.getInitialDelightResponse(q),grade:()=>delight.gradeDelightResponse(q,r),ready:()=>delight.isDelightResponseReady(q,r),xp:()=>delight.calculateDelightQuestionXp(q,r,p.options),fallback:()=>delight.getDelightFallbackQuestion(p.variant,p.moduleType || 'grammar',p.targetLang,p.supportLang)};
 if(!operations[operation]) throw Error('Unsupported exercise operation');return JSON.stringify(operations[operation]());
}); }`;
const result=await esbuild.build({stdin:{contents:entry,resolveDir:reference},bundle:true,format:'iife',globalName:'PiyaliPracticeRecipes',platform:'neutral',target:'es2020',write:false,plugins:[{name:'pure-source-only',setup(build){build.onResolve({filter:/.*/},async args=>({path:await resolve(args.path,args.importer || path.join(reference,'entry.js')),namespace:'pure-source'}));build.onLoad({filter:/.*/,namespace:'pure-source'},args=>{const contents=virtual.get(args.path);if(!contents) throw Error('Unreviewed module '+args.path);return {contents,loader:'js'};});}}]});
const code=result.outputFiles[0].text.replaceAll('// pure-source:'+reference+'/','// Reference: ');
await fs.writeFile(new URL('../Piyali/Resources/practice-recipes.js',import.meta.url),code);
const manifest=Array.from(modules.values()).map(m=>({file:path.relative(reference,m.file),sha256:crypto.createHash('sha256').update(m.source).digest('hex'),bindings:Array.from(m.required).sort(),...(m.adapter ? {nativeAdapter:m.file===storeFile ? 'Read-only user supplied as a Swift recipe argument; no web store or effects.' : m.file===flagsFile ? 'Flag renderers omitted from text-only language metadata.' : 'Original language-name strings only; no JSX UI.'} : {})}));
await fs.writeFile(new URL('../Piyali/Resources/practice-recipes.manifest.json',import.meta.url),JSON.stringify(manifest,null,2)+'\n');
const context={};vm.runInNewContext(code,context,{timeout:1000});
const canonical=value=>Array.isArray(value) ? value.map(canonical) : value && typeof value==='object' ? Object.fromEntries(Object.keys(value).sort().map(key=>[key,canonical(value[key])])) : value;
const fixtures=[];
for(const module of ['grammar','vocabulary']) for(const kind of ['fill','mc','ma','speak','match','translate','repeat','flashcard']) for(const [target,support,level] of [['es','en','Pre-A1'],['ja','es','A2'],['fr','de','B2'],['en','ar','C1']]) {
 const parameters=canonical({cefrLevel:level,targetLang:target,supportLang:support,showTranslations:true,appUILang:support,recentGood:['a previously answered item'],lessonContent:{topic:'greetings',focusPoints:['introduce yourself','polite replies'],cefrLevel:level},collectedConcepts:[],randomSeed:fixtures.length+1});
 fixtures.push({module,kind,parameters,expected:context.PiyaliPracticeRecipes.build(module,kind,JSON.stringify(parameters))});
}
const variants=JSON.parse(context.PiyaliPracticeRecipes.inspect('variants','{}'));
for(const module of ['grammar','vocabulary']) for(const {id} of variants) for(const [target,support,level] of [['es','en','Pre-A1'],['ja','es','A2'],['fr','de','B2'],['en','ar','C1']]) {
 const parameters=canonical({targetLang:target,supportLang:support,cefrLevel:level,lessonContent:{topic:'greetings',focusPoints:['introduce yourself','polite replies'],cefrLevel:level},recentQuestions:[],randomSeed:fixtures.length+1});
 fixtures.push({module,kind:'delight:'+id,parameters,expected:context.PiyaliPracticeRecipes.build(module,'delight:'+id,JSON.stringify(parameters))});
}
await fs.writeFile(new URL('../Tests/PiyaliCoreTests/Fixtures/practice-prompts.json.gz',import.meta.url),gzipSync(JSON.stringify(fixtures),{level:9}));
console.log(`Exported ${modules.size} pure source modules (${code.length} characters) and ${fixtures.length} prompt fixtures.`);
