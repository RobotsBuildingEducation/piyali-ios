import fs from 'node:fs/promises';import path from 'node:path';import vm from 'node:vm';import {createHash} from 'node:crypto';
const root=process.cwd(),reference=path.resolve(root,'../nosabos/nosabos'),file='src/App.jsx',source=await fs.readFile(path.join(reference,file),'utf8'),parser=await import(path.join(reference,'node_modules/@babel/parser/lib/index.js'));
const ast=parser.parse(source,{sourceType:'module',plugins:['jsx']});
function find(node,name,out=[]){if(!node||typeof node!=='object')return out;if(node.type==='VariableDeclarator'&&node.id?.name===name)out.push(node);for(const value of Object.values(node))for(const child of Array.isArray(value)?value:[value])find(child,name,out);return out}
const callbackCache=new Map();
function callback(name){if(callbackCache.has(name))return callbackCache.get(name);const nodes=find(ast,name);if(nodes.length!==1)throw Error('Source callback moved: '+name);const node=nodes[0].init.arguments[0];const text=source.slice(node.start,node.end);callbackCache.set(name,text);return text}
const scopes=['fixture:es','other:es'],rows=[];
for(const shown of [null,false,true,'true'])for(const profile of [{},{proficiencyPlacements:{}},{proficiencyPlacements:{es:'Pre-A1'}},{proficiencyPlacements:{fr:'A1'}},{proficiencyPlacement:'A2'},{proficiencyPlacement:''}])for(const prompted of [null,...scopes]){
 const fields={...profile,...(shown===null?{}:{gettingStartedModalShown:shown}),progress:{targetLang:'es'}},ref={current:prompted};let install=false,placement=false;
 const context=vm.createContext({user:fields,useUserStore:{getState:()=>({user:fields})},resolvedTargetLang:'es',activeNpub:'fixture',proficiencyPromptOpenedForRef:ref,setProficiencyTestOpen:x=>placement=x,setGettingStartedOpen:x=>install=x,markGettingStartedShown:()=>{fields.gettingStartedModalShown=true},flushSync:f=>f(),runAfterNextPaint:f=>f()});
 context.openProficiencyPromptIfNeeded=vm.runInContext('('+callback('openProficiencyPromptIfNeeded')+')',context);
 vm.runInContext('('+callback('handleCompanionContinue')+')()',context);
 const initial=install?'gettingStarted':placement?'placement':null,hasPlacement=Boolean(profile.proficiencyPlacements?.es||(!profile.proficiencyPlacements?profile.proficiencyPlacement:null));
 if(install)vm.runInContext('('+callback('handleGettingStartedSkip')+')()',context);
 rows.push({shown,prompted,fields:{...profile,progress:{targetLang:'es'}},hasPlacement,initial,afterAck:install?'gettingStarted':placement?'placement':null,promptAfter:ref.current});
}
const guide=await fs.readFile(path.join(reference,'src/components/GettingStartedModal.jsx'),'utf8'),ids=[...guide.matchAll(/notSoRandomCharacter=\{["'](\d+)["']\}/g)].map(m=>m[1]);if(ids.length!==1)throw Error('GettingStarted character selection moved');
const portraitFile='src/components/RandomCharacter.jsx',portraits=await fs.readFile(path.join(reference,portraitFile),'utf8'),portraitAST=parser.parse(portraits,{sourceType:'module',plugins:['jsx']}),maps=find(portraitAST,'characterImagesMap');if(maps.length!==1)throw Error('Source portrait map moved');
const alias=maps[0].init.properties.find(p=>String(p.key.value??p.key.name)===ids[0])?.value?.name,importNode=portraitAST.program.body.find(n=>n.type==='ImportDeclaration'&&n.specifiers.some(s=>s.local.name===alias));if(!importNode)throw Error('Source character import moved');
const portrait=path.relative(reference,path.resolve(reference,'src/components',importNode.source.value));
await fs.copyFile(path.join(reference,portrait),path.join(root,'Piyali/Resources/Brand/getting-started-character.webp'));
await fs.writeFile(path.join(root,'Tests/PiyaliCoreTests/Fixtures/first-run-policy.json'),JSON.stringify(rows)+'\n');
const files=[file,'src/components/GettingStartedModal.jsx','src/components/ProficiencyTestModal.jsx','src/components/DailyPlateHome.jsx','src/theme.js','src/index.css',portraitFile,portrait];
await fs.writeFile(path.join(root,'docs/reference/first-run-manifest.json'),JSON.stringify({character:{id:ids[0],file:portrait},sources:await Promise.all(files.map(async file=>({file,sha256:createHash('sha256').update(await fs.readFile(path.join(reference,file))).digest('hex')}))),scope:'Actual companion Continue, proficiency guard and GettingStarted Skip callbacks executed directly for 72 combinations, with identity/storage/render/sound/network effects replaced by inert fixture setters. Flag writing is stubbed; native Firestore behavior is checked separately. Native app-installed acknowledgement and authenticated expiring/local-only key copying are platform adaptations. The five original browser installation steps remain available.'},null,2)+'\n');
console.log('Exported '+rows.length+' actual first-run callback journeys.');
