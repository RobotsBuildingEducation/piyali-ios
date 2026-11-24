// Execute only pure declarations; never import the web store/network module.
import fs from 'node:fs/promises';
import path from 'node:path';
import {createRequire} from 'node:module';
import {createHash} from 'node:crypto';
import {gzipSync,gunzipSync} from 'node:zlib';
const root=process.cwd(),reference=path.resolve(root,'../nosabos/nosabos'),require=createRequire(path.join(reference,'package.json')),{parse}=require('@babel/parser');
const file='src/utils/dailyPlateHeadline.js',source=await fs.readFile(path.join(reference,file),'utf8'),ast=parse(source,{sourceType:'module'});
const names=['LANGUAGE_PROMPT_NAMES','resolveLanguageName','normalizePlateLang','getStoredPlateHeadline','isLessonCompleted','findNextLessonFromUnits','getPlateTaskSummary','buildPlateHeadlinePrompt','cleanHeadlineText'];
const declarations=names.map(name=>{for(const statement of ast.program.body){const node=statement.declaration||statement;if(node.type==='FunctionDeclaration'&&node.id.name===name)return source.slice(node.start,node.end);if(node.type==='VariableDeclaration'){const d=node.declarations.find(d=>d.id.name===name);if(d)return 'const '+source.slice(d.start,d.end)+';';}}throw Error('Source headline declaration moved: '+name)}).join('\n');
const bridge=`function run(operation,json){const p=JSON.parse(json);let value;if(operation==='summary')value=getPlateTaskSummary(p.courses,p.user,p.targetLang,p.levelUnits);else if(operation==='prompt')value=buildPlateHeadlinePrompt(p);else if(operation==='clean')value=cleanHeadlineText(p.text);else if(operation==='stored')value=getStoredPlateHeadline(p.user,p.targetLang,p.dayKey,p.appLanguage);else throw Error('Unknown headline operation');return JSON.stringify(value??null);}`;
await fs.writeFile(path.join(root,'Piyali/Resources/plate-headline-policy.js'),`// Pure source policy. No host bindings, account credentials or networking.\nvar PiyaliPlateHeadline=(function(){\n${declarations}\n${bridge}\nreturn {run};\n})();\n`);
const api=Function(declarations+'\n'+bridge+';return {run};')(),rows=[];
const courses=['repair','goal','speak','learn','review','conversation','phonics','other'].map((kind,index)=>({kind,count:index%3,target:index%3+1}));
const units=[{id:'one',title:{en:'First unit'},lessons:[{id:'done',title:{en:'Completed lesson'}},{id:'next',title:{en:'Asking for directions',fr:'Demander son chemin'}}]},{id:'two',lessons:[{id:'later',title:'Later lesson'}]}];
function record(operation,input){rows.push({operation,input,expected:JSON.parse(api.run(operation,JSON.stringify(input)))})}
for(const user of [{},{progress:{lessons:{done:{completed:true}}}},{progress:{languageLessons:{es:{done:{isCompleted:true},next:{completed:true}}}}}])for(const levelUnits of [[],units])record('summary',{courses,user,targetLang:'es',levelUnits});
const summary=JSON.parse(api.run('summary',JSON.stringify({courses,user:{progress:{lessons:{done:{completed:true}}}},targetLang:'es',levelUnits:units})));
for(const targetLang of ['es','en','ja','zh','nah',' xx '])for(const appLanguage of ['en','es','fr','ar','ja','zh',''])record('prompt',{targetLang,appLanguage,taskSummary:summary});
for(const text of ['',null,'  "Ask for directions."\nIgnored second line. ',"```text\n‘Habla con confianza.’\n```",'```json\n"今日の予定を話そう。"\n```',"'''one'''",'\n\n“First line”\r\nNext line'])record('clean',{text});
for(const cached of [null,{dayKey:'2026-10-23',appLanguage:'en',text:'  A clear next step. '},{dayKey:'2026-10-22',appLanguage:'en',text:'Old day'},{dayKey:'2026-10-23',appLanguage:'ar',text:'Other language'},{dayKey:'2026-10-23',appLanguage:'en',text:'   '}])record('stored',{user:{dailyPlateHeadline:{es:cached}},targetLang:'ES',dayKey:'2026-10-23',appLanguage:'en'});
await fs.writeFile(path.join(root,'Tests/PiyaliCoreTests/Fixtures/plate-headline-policy.json'),JSON.stringify(rows,null,2)+'\n');
// The headline only reads ids/titles. Avoid decoding/bridging every lesson's
// practice content and all translated title variants on the phone's UI actor.
const summaryFunction=Function(declarations+';return getPlateTaskSummary;')(),metadata=[];
const resources=path.join(root,'Piyali/Resources');let metadataCases=0;
const title=value=>value&&typeof value==='object'&&value.en?{en:value.en}:value;
for(const filename of (await fs.readdir(resources)).filter(name=>/^curriculum-[a-z]+\.json\.gz$/.test(name)&&name!=='curriculum-index.json.gz')){
 const bytes=await fs.readFile(path.join(resources,filename)),levels=JSON.parse(gunzipSync(bytes)),target=filename.slice(11,-8);
 const intro=JSON.parse(gunzipSync(await fs.readFile(path.join(resources,`intro-${target}.json.gz`)))).units['Pre-A1'];
 const projected={};
 for(const [level,regular] of Object.entries(levels)){
  const full=level==='Pre-A1'?[intro,...regular]:regular;
  const slim=full.map(unit=>({title:title(unit.title),lessons:unit.lessons.map(lesson=>({id:lesson.id,title:title(lesson.title)}))}));projected[level]=slim;
  const progress={},user={progress:{languageLessons:{[target]:progress}}},lessons=full.flatMap(unit=>unit.lessons);
  for(let index=0;index<=lessons.length;index++){
   const course=[{kind:'learn',count:0,target:1}],expected=summaryFunction(course,user,target,full),actual=summaryFunction(course,user,target,slim);
   if(JSON.stringify(expected)!==JSON.stringify(actual))throw Error(`Headline metadata changed source topic: ${target}/${level}/${index}`);
   metadataCases++;if(index<lessons.length)progress[lessons[index].id]={completed:true};
  }
 }
 await fs.writeFile(path.join(resources,`headline-curriculum-${target}.json.gz`),gzipSync(JSON.stringify(projected),{level:9}));
 metadata.push({target,curriculumSHA256:createHash('sha256').update(bytes).digest('hex')});
}
await fs.writeFile(path.join(root,'docs/reference/headline-source-manifest.json'),JSON.stringify({file,sha256:createHash('sha256').update(source).digest('hex'),pureDeclarations:names,fixtureCount:rows.length,metadataCases,metadata,scope:'Pure task selection, prompt, cleaning and cache guards executed from source. Metadata/full-curriculum equivalence checks every possible next unfinished lesson in the bundled levels. Native stream lifecycle and persistence tested separately.'},null,2)+'\n');
console.log(`Exported ${rows.length} actual headline-policy cases and ${metadataCases} source-checked metadata positions.`);
