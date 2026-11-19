// Read the actual session and completion copy; write only native resources.
import fs from 'node:fs/promises';
import path from 'node:path';
import vm from 'node:vm';
import {createRequire} from 'node:module';
import {gzipSync} from 'node:zlib';
const reference=path.resolve(process.argv[2] || '../nosabos/nosabos');
const require=createRequire(path.join(reference,'package.json')),parser=require('@babel/parser'),traverse=require('@babel/traverse').default;
const source=await fs.readFile(path.join(reference,'src/App.jsx'),'utf8');
const ast=parser.parse(source,{sourceType:'module',plugins:['jsx']});
const start=source.indexOf('isOpen={showCompletionModal}'),end=source.indexOf('Daily Plate celebration modal',start);
if(start<0 || end<0) throw Error('Original completion modal is missing');
const completion={};
traverse(ast,{CallExpression(p){
 if(p.node.start<start || p.node.end>end || p.node.callee.name!=='uiCopy') return;
 const object=p.node.arguments[1];if(object?.type!=='ObjectExpression')return;
 const entries=object.properties.filter(p=>p.type==='ObjectProperty' && p.value.type==='StringLiteral').map(p=>[p.key.name || p.key.value,p.value.value]);
 const value=Object.fromEntries(entries);if(value.en) completion[value.en]=value;
}});
const stepper=await fs.readFile(path.join(reference,'src/components/TutorialStepper.jsx'),'utf8');
const stepAst=parser.parse(stepper,{sourceType:'module',plugins:['jsx']});
const config=stepAst.program.body.flatMap(n=>n.type==='VariableDeclaration'?n.declarations:[]).find(n=>n.id.name==='MODULE_CONFIG')?.init;
if(config?.type!=='ObjectExpression')throw Error('Original tutorial module config is missing');
const modules=Object.fromEntries(config.properties.map(module=>[module.key.name || module.key.value,Object.fromEntries(module.value.properties.filter(p=>['label','shortLabel','description','color'].includes(p.key.name)).map(p=>[p.key.name,vm.runInNewContext('('+stepper.slice(p.value.start,p.value.end)+')',{}, {timeout:1000})]))]));
await fs.writeFile(new URL('../Piyali/Resources/lesson-session-copy.json.gz',import.meta.url),gzipSync(JSON.stringify({completion,modules}),{level:9}));
console.log(JSON.stringify({completionLabels:Object.keys(completion),modules:Object.keys(modules)}));
