import fs from 'node:fs/promises';
import path from 'node:path';
import {createRequire} from 'node:module';
import {createHash} from 'node:crypto';
import {gzipSync} from 'node:zlib';
const root=path.resolve(process.argv[2]||'../nosabos/nosabos'),require=createRequire(path.join(root,'package.json'));
const React=require('react'),{renderToStaticMarkup}=require('react-dom/server'),parser=require('@babel/parser'),traverse=require('@babel/traverse').default;
const app=await fs.readFile(path.join(root,'src/App.jsx'),'utf8'),clock=await fs.readFile(path.join(root,'src/components/SessionTimerModal.jsx'),'utf8');
const ast=parser.parse(app,{sourceType:'module',plugins:['jsx']}),labels={};
traverse(ast,{CallExpression(p){if(p.node.callee.name!=='uiCopy'||p.node.start<app.indexOf('function TopBar(')||p.node.end>app.indexOf('function App('))return;const o=p.node.arguments[1];if(o?.type!=='ObjectExpression')return;const values=Object.fromEntries(o.properties.filter(p=>p.value?.type==='StringLiteral').map(p=>[p.key.name||p.key.value,p.value.value]));if(['Daily XP','Open daily goal','Open timer','Pause timer','Resume timer'].includes(values.en))labels[values.en]=values;}});
if(Object.keys(labels).length!==5)throw Error('Missing original header copy');
// Render the exact source header subtree in QA, without mounting App's auth,
// account and daily-reset effects. All props/actions are explicit public fixtures.
let topBar;
traverse(ast,{FunctionDeclaration(p){if(p.node.id?.name==='TopBar')topBar=p.node;}});
const returnNode=topBar.body.body.find(n=>n.type==='ReturnStatement'),header=returnNode.argument.children.find(n=>n.type==='JSXElement' && n.openingElement.name.name==='Box');
const declarations=topBar.body.body.filter(n=>n.type==='VariableDeclaration').flatMap(n=>n.declarations);
const names=['topBarControlProps','dailyRawPct','dailyDone','dailyGoalHudColor','dailyGoalHudTextColor','dailyGoalLabel'];
const constants=names.map(name=>{const d=declarations.find(d=>d.id.name===name);if(!d)throw Error('Missing header declaration '+name);return 'const '+app.slice(d.start,d.end)+';';}).join('\n');
await fs.writeFile(new URL('./reference-topbar.jsx',import.meta.url),`// Generated from the unmodified source header. Public QA fixtures only.\nimport React from 'react';\nimport {Box,HStack,IconButton,Text,Spacer} from '@chakra-ui/react';\nimport {FaCalendarAlt,FaCalendarCheck} from 'react-icons/fa';\nimport {MdShowChart} from 'react-icons/md';\nimport {FiClock,FiPause,FiPlay} from 'react-icons/fi';\nimport GlassContainer from '/src/components/GlassContainer';\nimport {WaveBar} from '/src/components/WaveBar';\nimport SessionTimerBadge from '/src/components/SessionTimerBadge';\nimport {setRemainingSeconds} from '/src/provider/SessionTimerProvider';\nimport {useThemeStore} from '/src/useThemeStore';\nexport default function SourceTopBar({appLanguage='en',dailyXp=0,dailyGoalXp=100,hasTimer=false,timerPaused=false,onOpenDailyGoalModal=()=>{},onOpenTimerModal=()=>{},onTogglePauseTimer=()=>{}}){\nconst themeMode=useThemeStore(s=>s.themeMode),showUpdateBar=false,isTimerRunning=hasTimer&&!timerPaused,timerDurationSeconds=1200;setRemainingSeconds(hasTimer?600:null);\nconst uiCopy=(language,values)=>values[language]||values.en;\nconst getTopBarPressProps=(key,action)=>({onClick:action});\n${constants}\nreturn (${app.slice(header.start,header.end)});\n}\n`);
await fs.writeFile(new URL('../Piyali/Resources/session-tools-ui.json.gz',import.meta.url),gzipSync(JSON.stringify(labels),{level:9}));
for(const [module,names]of Object.entries({'react-icons/fa':['FaCalendarAlt','FaCalendarCheck'],'react-icons/md':['MdShowChart'],'react-icons/fi':['FiClock','FiPause','FiPlay','FiHeart','FiTrendingUp','FiTrendingDown']}))for(const name of names){
 const folder=new URL(`../Piyali/Resources/BrandAssets.xcassets/Session-${name}.imageset/`,import.meta.url);await fs.mkdir(folder,{recursive:true});
 await fs.writeFile(new URL('icon.svg',folder),renderToStaticMarkup(React.createElement(require(module)[name],{size:24,color:'#000'})));
 await fs.writeFile(new URL('Contents.json',folder),JSON.stringify({images:[{filename:'icon.svg',idiom:'universal'}],info:{author:'xcode',version:1},properties:{'preserves-vector-representation':true,'template-rendering-intent':'template'}}));
}
const goalExpr=app.slice(app.indexOf('const parsedGoal =',app.indexOf('const handleDailyGoalSave')),app.indexOf('const now =',app.indexOf('const handleDailyGoalSave'))).replace('const parsedGoal =','return');
const goal=Function('goalValue',goalExpr),minutesExpr=app.slice(app.indexOf('const parsedSource =',app.indexOf('const handleStartTimer')),app.indexOf('flushSync(',app.indexOf('const handleStartTimer'))),minutes=Function('source',minutesExpr+'return parsedMinutes;');
const inputs=['',' ','-100','0','0.49','0.5','1','1.5','9.5','10','20','50','100','150','240','240.5','300','999.5','1000','1001','invalid','Infinity','-Infinity'];
const cases=inputs.map(input=>({input,goal:goal(input),minutes:minutes(input)}));
await fs.writeFile(new URL('../Tests/PiyaliCoreTests/Fixtures/session-tools-source.json',import.meta.url),JSON.stringify(cases,null,2)+'\n');
const random=await fs.readFile(path.join(root,'src/components/RandomCharacter.jsx'),'utf8');
if(!random.includes('32: character33') || !random.includes('import character33 from "../assets/33.webp"'))throw Error('Review the original time-up character mapping.');
await fs.copyFile(path.join(root,'src/assets/33.webp'),new URL('../Piyali/Resources/Brand/session-timer-character.webp',import.meta.url));
const files=['src/App.jsx','src/components/DailyGoalModal.jsx','src/components/SessionTimerModal.jsx','src/components/SessionTimerBadge.jsx','src/components/DailyGoalPetPanel.jsx','src/components/RandomCharacter.jsx','src/assets/33.webp'];
await fs.writeFile(new URL('../docs/reference/session-tools-manifest.json',import.meta.url),JSON.stringify(Object.fromEntries(await Promise.all(files.map(async file=>[file,createHash('sha256').update(await fs.readFile(path.join(root,file))).digest('hex')]))),null,2)+'\n');
console.log(`Exported ${Object.keys(labels).length} original header labels, nine SVG icons and ${cases.length} executed numeric cases.`);
