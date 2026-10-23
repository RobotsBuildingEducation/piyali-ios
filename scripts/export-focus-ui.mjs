// Read only source extraction. Outputs belong exclusively to the iPhone repo.
import fs from 'node:fs/promises';
import path from 'node:path';
import {createRequire} from 'node:module';
import {gzipSync,gunzipSync} from 'node:zlib';
import {createHash} from 'node:crypto';
const reference=path.resolve(process.argv[2]||'../nosabos/nosabos');
const require=createRequire(path.join(reference,'package.json'));
const {parse}=require('@babel/parser'),{build}=require('esbuild');
const sources={};
async function declaration(file,name){
 const source=sources[file]??=await fs.readFile(path.join(reference,'src',file),'utf8');
 const ast=parse(source,{sourceType:'module',plugins:['jsx']});
 for(const statement of ast.program.body){const node=statement.declaration||statement;
  if(node.type==='FunctionDeclaration'&&node.id.name===name)return source.slice(node.start,node.end);
  if(node.type==='VariableDeclaration'){const found=node.declarations.find(d=>d.id.name===name);if(found)return `const ${source.slice(found.start,found.end)};`;}
 }
 throw Error(`Source declaration changed: ${file}:${name}`);
}
const petFile='components/PlatePetPanel.jsx';
const getPetCopy=Function(await declaration(petFile,'getCopy')+';return getCopy;')();
const levels=Function(await declaration(petFile,'COMPANION_LEVEL_LABELS')+';return COMPANION_LEVEL_LABELS;')();
const score=Function(await declaration('components/PlateScoreJourney.jsx','COPY')+';return COPY;')();
const result=await build({stdin:{contents:`export {IMMERSION_COPY} from './src/components/immersionCopy.js';export {getCustomizeModalCopy} from './src/components/companionCustomizeCopy.js';export {achievementText} from './src/achievements/copy.js';`,resolveDir:reference},bundle:true,platform:'node',format:'esm',write:false});
const copy=await import('data:text/javascript;base64,'+Buffer.from(result.outputFiles[0].text).toString('base64'));
const appCopy=JSON.parse(gunzipSync(await fs.readFile(new URL('../Piyali/Resources/app-copy.json.gz',import.meta.url))));
const locales=['en','es','pt','fr','it','de','ja','hi','ar','zh'];
const ui=Object.fromEntries(locales.map(language=>[language,{pet:getPetCopy(language),level:levels[language],score:score[language].score,customize:copy.getCustomizeModalCopy(language),immersion:copy.IMMERSION_COPY[language],activity:appCopy[language].daily_plate_view_activity,companion:appCopy[language].daily_plate_see_companion,achievements:copy.achievementText('achievements',language)}]));
// Preserve the exact source React icon paths as template SVG assets.
const React=require('react'),{renderToStaticMarkup}=require('react-dom/server');
const iconFiles={'utils/dailyPlateCopy.js':'PLATE_COURSE_META','components/PlateScoreJourney.jsx':'ICONS'};
for(const [file,name] of Object.entries(iconFiles)){
 const source=sources[file]??=await fs.readFile(path.join(reference,'src',file),'utf8');
 const imports=[...source.matchAll(/import\s*\{([^}]+)\}\s*from\s*["'](react-icons\/[^"']+)["']/g)];
 const icons=Object.assign({},...imports.map(([,names,module])=>Object.fromEntries(names.split(',').map(s=>s.trim()).filter(Boolean).map(name=>[name,require(module)[name]]))));
 const keys=Object.keys(icons),object=Function(...keys,(await declaration(file,name))+`;return ${name};`)(...keys.map(key=>icons[key]));
 for(const [key,meta] of Object.entries(object)){
  const icon=typeof meta==='function'?meta:meta.icon;if(!icon)throw Error('Missing source icon '+key);
  const asset=`Focus-${name==='ICONS'?'score':'course'}-${key}`,destination=new URL(`../Piyali/Resources/BrandAssets.xcassets/${asset}.imageset/`,import.meta.url);
  await fs.mkdir(destination,{recursive:true});
  await fs.writeFile(new URL('icon.svg',destination),renderToStaticMarkup(React.createElement(icon,{size:24,color:'#000000'})));
  await fs.writeFile(new URL('Contents.json',destination),JSON.stringify({images:[{filename:'icon.svg',idiom:'universal'}],info:{author:'xcode',version:1},properties:{'preserves-vector-representation':true,'template-rendering-intent':'template'}}));
 }
}
const drawing=await import(path.join(reference,'src/components/companionDrawing.js'));
const {PET_TYPES}=await import(path.join(reference,'src/utils/petTypes.js'));
const stages={},frames={};
for(const health of [0,24,49,74,99,100]){
 const stage=drawing.getPetStage(health,getPetCopy('en'),true);
 stages[stage.key]={light:stage,dark:drawing.getPetStage(health,getPetCopy('en'),false)};
 frames[stage.key]={};
 for(const type of PET_TYPES){frames[stage.key][type]=[];for(let frame=0;frame<12;frame++){
  const rectangles=[];let x=0,y=0;const stack=[];
  const ctx={fillStyle:'#000',globalAlpha:1,save(){stack.push({x,y,fill:this.fillStyle,alpha:this.globalAlpha});},restore(){const s=stack.pop();x=s.x;y=s.y;this.fillStyle=s.fill;this.globalAlpha=s.alpha;},translate(dx,dy){x+=dx;y+=dy;},fillRect(rx,ry,w,h){rectangles.push([rx+x,ry+y,w,h,this.fillStyle,this.globalAlpha]);}};
  drawing.drawCompanionCharacter(ctx,frame,stage,type);frames[stage.key][type].push(rectangles);
 }}
}
for(const [name,value] of Object.entries({'focus-ui':{copy:ui,stages},'companion-stages':frames}))await fs.writeFile(new URL(`../Piyali/Resources/${name}.json.gz`,import.meta.url),gzipSync(JSON.stringify(value),{level:9}));
for(const file of ['components/immersionCopy.js','components/companionCustomizeCopy.js','achievements/copy.js','utils/petTypes.js','components/companionDrawing.js','components/CompanionQuestBubble.jsx','components/ImmersionTasksContent.jsx','components/DailyPlateHome.jsx','theme.js','index.css'])sources[file]??=await fs.readFile(path.join(reference,'src',file),'utf8');
await fs.writeFile(new URL('../docs/reference/focus-source-manifest.json',import.meta.url),JSON.stringify(Object.fromEntries(Object.entries(sources).map(([file,source])=>[file,createHash('sha256').update(source).digest('hex')])),null,2)+'\n');
console.log(`Exported ${locales.length} focus locales and ${Object.keys(stages).length} health stages × ${PET_TYPES.length} companions × 12 frames.`);
