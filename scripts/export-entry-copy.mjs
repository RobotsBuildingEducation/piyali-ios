import fs from 'node:fs/promises';
import path from 'node:path';
import {gzipSync} from 'node:zlib';
const reference=path.resolve(process.argv[2] || '../nosabos/nosabos');
const locales=['en','es','pt','fr','it','de','ja','hi','ar','zh'];
const copy={};
for(const code of locales) {
 const module=await import(path.join(reference,'src/features/publicCopy/landing',code+'.js'));
 copy[code]=Object.fromEntries(['copy','refresh','capabilities','tutor','ethos','atlas','companionNames'].map(key=>[key,module[key]]));
}
const esbuild=await import(path.join(reference,'node_modules/esbuild/lib/main.js'));
const bundle=await esbuild.build({stdin:{contents:`export {translations} from ${JSON.stringify(path.join(reference,'src/utils/translation.jsx'))}; export {goalOnboardingCopy,goalCopy} from ${JSON.stringify(path.join(reference,'src/utils/learningGoalCopy.js'))};`,resolveDir:reference},bundle:true,platform:'node',format:'esm',write:false,banner:{js:'const React={createElement:()=>null};'},plugins:[{name:'copy-only',setup(build){build.onResolve({filter:/^@chakra-ui\/react$/},()=>({path:'chakra',namespace:'copy-only'}));build.onLoad({filter:/.*/,namespace:'copy-only'},()=>({contents:'export const Button=()=>null,HStack=()=>null;'}));}}]});
const web=await import('data:text/javascript;base64,'+Buffer.from(bundle.outputFiles[0].text).toString('base64'));
const appCopy={};
for(const code of locales) {
 const strings=web.translations[code] || web.translations.en;
 appCopy[code]=Object.fromEntries(Object.entries(strings).filter(([,value])=>typeof value==='string'));
 copy[code].onboarding={...Object.fromEntries(Object.entries(strings).filter(([key,value])=>key.startsWith('onboarding_') && typeof value==='string')),goal:web.goalOnboardingCopy(code),goalField:web.goalCopy(code)};
}
await fs.writeFile(new URL('../Piyali/Resources/entry-copy.json.gz',import.meta.url),gzipSync(JSON.stringify(copy),{level:9}));
await fs.writeFile(new URL('../Piyali/Resources/app-copy.json.gz',import.meta.url),gzipSync(JSON.stringify(appCopy),{level:9}));
console.log('Exported original entry-page copy for '+locales.length+' languages.');

const {LANGUAGE_POSTCARDS}=await import(path.join(reference,'src/components/landingPostcards.js'));
await fs.writeFile(new URL('../Piyali/Resources/landing-postcards.json.gz',import.meta.url),gzipSync(JSON.stringify(LANGUAGE_POSTCARDS),{level:9}));
const {LANDING_GLOBE_GEOMETRY:g}=await import(path.join(reference,'src/components/landingGlobeGeometry.js'));
const globe=new URL('../Piyali/Resources/BrandAssets.xcassets/LandingGlobe.imageset/',import.meta.url);
await fs.mkdir(globe,{recursive:true});
await fs.writeFile(new URL('Contents.json',globe),JSON.stringify({images:[{filename:'globe.svg',idiom:'universal'}],info:{author:'xcode',version:1},properties:{'preserves-vector-representation':true}}));
await fs.writeFile(new URL('../Contents.json',globe),JSON.stringify({info:{author:'xcode',version:1}}));
await fs.writeFile(new URL('globe.svg',globe),`<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 500 500" fill="none"><defs><clipPath id="globe"><circle cx="250" cy="250" r="177"/></clipPath></defs><circle cx="250" cy="250" r="225" stroke="#4f8075" stroke-dasharray="2 9" opacity=".18"/><circle cx="250" cy="250" r="203" stroke="#4f8075" opacity=".12"/><circle cx="250" cy="250" r="177" fill="#d9e9dc" stroke="#4f8075" stroke-width="1.3" opacity=".9"/><g clip-path="url(#globe)"><path d="${g.graticule}" stroke="#4f8075" stroke-width=".65" opacity=".14"/><path d="${g.land}" fill="#4f8075" opacity=".2"/><path d="${g.borders}" stroke="#4f8075" stroke-width=".45" stroke-linejoin="round" opacity=".3"/></g></svg>`);

// Keep source illustrations as vectors, including their authored dark variants.
for (const [name,source] of Object.entries({LandingMission:'bitcoin-learning',LandingHuman:'ethos/human-guidance',LandingCommunity:'ethos/community-scholarships',LandingTechnology:'ethos/technology-imagination'})) {
 const destination=new URL(`../Piyali/Resources/BrandAssets.xcassets/${name}.imageset/`,import.meta.url);
 await fs.mkdir(destination,{recursive:true});
 for(const suffix of ['', '-dark']) await fs.copyFile(path.join(reference,'public/images',source+suffix+'.svg'),new URL('art'+suffix+'.svg',destination));
 await fs.writeFile(new URL('Contents.json',destination),JSON.stringify({images:[{filename:'art.svg',idiom:'universal'},{filename:'art-dark.svg',idiom:'universal',appearances:[{appearance:'luminosity',value:'dark'}]}],info:{author:'xcode',version:1},properties:{'preserves-vector-representation':true}}));
}
await fs.copyFile(path.join(reference,'docs/privacy-policy-draft.md'),new URL('../Piyali/Resources/privacy-policy.md',import.meta.url));

// Record the original pixel drawer, rather than substitute emoji for companions.
const drawing=await import(path.join(reference,'src/components/companionDrawing.js'));
const {PET_TYPES}=await import(path.join(reference,'src/utils/petTypes.js'));
const companionFrames={};
for(const type of PET_TYPES) {
 companionFrames[type]=[];
 for(let frame=0;frame<12;frame++) {
  const rectangles=[];let x=0,y=0;const stack=[];
  const ctx={fillStyle:'#000',globalAlpha:1,save(){stack.push({x,y,fill:this.fillStyle,alpha:this.globalAlpha});},restore(){const state=stack.pop();x=state.x;y=state.y;this.fillStyle=state.fill;this.globalAlpha=state.alpha;},translate(dx,dy){x+=dx;y+=dy;},fillRect(rx,ry,w,h){rectangles.push([rx+x,ry+y,w,h,this.fillStyle,this.globalAlpha]);}};
  drawing.drawCompanionCharacter(ctx,frame,{...drawing.getHealthyCompanionStage(),motion:'celebrate'},type);
  companionFrames[type].push(rectangles);
 }
}
await fs.writeFile(new URL('../Piyali/Resources/companion-preview.json.gz',import.meta.url),gzipSync(JSON.stringify(companionFrames),{level:9}));
const {LANDING_PROFICIENCY_STATS,LANDING_PROFICIENCY_LEVELS}=await import(path.join(reference,'src/components/landingProficiencyStats.js'));
await fs.writeFile(new URL('../Piyali/Resources/landing-proficiency.json.gz',import.meta.url),gzipSync(JSON.stringify({stats:LANDING_PROFICIENCY_STATS,levels:LANDING_PROFICIENCY_LEVELS}),{level:9}));
const demo=await import(path.join(reference,'src/utils/landingTutorDemo.js'));
const demoCopy={samples:demo.LANDING_TUTOR_SAMPLES,instructions:{},turns:{}};
for(const target of Object.keys(demo.LANDING_TUTOR_SAMPLES)) {
 demoCopy.instructions[target]=Object.fromEntries(locales.map(support=>[support,demo.buildLandingTutorInstructions({targetLanguage:target,supportLanguage:support})]));
 demoCopy.turns[target]=Array.from({length:6},(_,i)=>demo.buildLandingTutorTurnInstructions(i+1,{targetLanguage:target}));
}
await fs.writeFile(new URL('../Piyali/Resources/landing-demo.json.gz',import.meta.url),gzipSync(JSON.stringify(demoCopy),{level:9}));
const {LANGUAGE_TIMEZONES}=await import(path.join(reference,'src/utils/initialLanguage.js'));
await fs.writeFile(new URL('../Piyali/Resources/language-timezones.json.gz',import.meta.url),gzipSync(JSON.stringify(LANGUAGE_TIMEZONES),{level:9}));

const daily=await esbuild.build({stdin:{contents:`export * from ${JSON.stringify(path.join(reference,'src/utils/dailyPlateCopy.js'))};export * from ${JSON.stringify(path.join(reference,'src/utils/activityMenuCopy.js'))};export {buildQuestBubble} from ${JSON.stringify(path.join(reference,'src/utils/companionMemoryCopy.js'))};export * from ${JSON.stringify(path.join(reference,'src/utils/scoreMilestones.js'))};`,resolveDir:reference},bundle:true,platform:'node',format:'esm',write:false,plugins:[{name:'copy-icons',setup(build){build.onResolve({filter:/^react-icons\//},()=>({path:'icons',namespace:'copy-icons'}));build.onLoad({filter:/.*/,namespace:'copy-icons'},()=>({contents:'export const PiCardsBold=null,PiPath=null,RiBook2Line=null,RiChat3Line=null,RiMagicLine=null,LuLanguages=null;'}));}}]});
const productModule=await import('data:text/javascript;base64,'+Buffer.from(daily.outputFiles[0].text).toString('base64'));
const homeSource=await fs.readFile(path.join(reference,'src/components/DailyPlateHome.jsx'),'utf8');
const homeConstants=Array.from(homeSource.matchAll(/const (START_COPY|CONTINUE_COPY|SUBTITLE_COPY|RESET_COPY) = (\{[\s\S]*?\n\});/g));
const homeCopy=Function(homeConstants.map(m=>m[0]).join('\n')+';return {start:START_COPY,continue:CONTINUE_COPY,subtitle:SUBTITLE_COPY};')();
const product={};
for(const language of locales) {
 product[language]={...Object.fromEntries(Object.entries(productModule).filter(([key,value])=>key.startsWith('PLATE_') && key.endsWith('_COPY')).map(([key,value])=>[key,productModule.plateUiCopy(language,value)])),...Object.fromEntries(Object.entries(homeCopy).map(([key,value])=>[key,value[language] || value.en])),menu:productModule.getActivityMenuLabels(language,web.translations[language]),courses:Object.fromEntries(Object.entries(productModule.PLATE_COURSE_META).map(([kind,meta])=>[kind,productModule.plateUiCopy(language,meta.label)])),bubbles:Object.fromEntries(['welcome','welcomeGoal','fresh','repair','repairMulti'].map(leadKind=>[leadKind,productModule.buildQuestBubble({lang:language,leadKind,goal:'{goal}',concept:'{concept}',taskList:'{taskList}'}).long]))};
}
await fs.writeFile(new URL('../Piyali/Resources/product-copy.json.gz',import.meta.url),gzipSync(JSON.stringify(product),{level:9}));
await fs.writeFile(new URL('../Piyali/Resources/score-milestones.json.gz',import.meta.url),gzipSync(JSON.stringify(productModule.SCORE_MILESTONES),{level:9}));
const parser=await import(path.join(reference,'node_modules/@babel/parser/lib/index.js'));
// Dynamic Help policies and UI copy are exported by export-help-chat.mjs.
