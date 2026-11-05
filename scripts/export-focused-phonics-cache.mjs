// Original cache/transaction functions plus the complete original authored factory.
import fs from 'node:fs/promises';
import path from 'node:path';
import vm from 'node:vm';
import {createRequire} from 'node:module';
import {createHash} from 'node:crypto';
import {gzipSync} from 'node:zlib';
const reference=path.resolve('../nosabos/nosabos'),require=createRequire(path.join(reference,'package.json'));
const file='src/utils/focusedPracticeDecks.js',source=await fs.readFile(path.join(reference,file),'utf8');
const ast=require('@babel/parser').parse(source,{sourceType:'module'});
const names=['practiceArtifactKey','artifactField','practiceArtifact','getFocusedPhonicsDeck'];
const bodies=names.map(name=>{const n=ast.program.body.map(s=>s.declaration||s).find(n=>n.id?.name===name||n.declarations?.[0].id.name===name);if(!n)throw Error('Original '+name+' moved');return source.slice(n.start,n.end)}).join('\n');
const bundle=await require('esbuild').build({entryPoints:[path.join(reference,'src/data/phonics/index.js')],bundle:true,write:false,format:'iife',globalName:'OriginalAuthored',platform:'neutral'});
const authored=vm.runInNewContext(bundle.outputFiles[0].text+';OriginalAuthored');
const rows=[],scenarios=['both-network-fail','read-fails-write-succeeds','read-empty-write-fails','remote-existing','transaction-existing','local-existing','empty-local-network-fail'];
for(const goal of [true,false])for(const scenario of scenarios){
  const focus={npub:'public-phonics-cache',targetLang:'es',supportLang:'en',...(goal?{blueprint:{goalId:'public-cache-goal',dayKey:'2026-11-05',cefrLevel:'Pre-A1',targetLanguage:['casa']}}:{stepIndex:0,plan:{dayKey:'2026-11-05',items:[{memoryId:'public-sound',expectedAnswer:'casa',cefrLevel:'Pre-A1',mode:'phonics',errorType:'phonics'}]}})};
  let local=null,document={},existing;const calls=[];
  const context={...authored,doc:(...args)=>({path:args.slice(1).join('/')}),database:{},getLocalDayKey:()=>{throw Error('Explicit public day required')},readAccountScopedJson:(key,npub)=>{calls.push(['read-local',key,npub]);return local},writeAccountScopedJson:(key,npub,artifact)=>{calls.push(['write-local',key,npub]);local=structuredClone(artifact)},getDoc:async ref=>{calls.push(['read-remote',ref.path]);if(['both-network-fail','read-fails-write-succeeds','empty-local-network-fail'].includes(scenario))throw Error('Fixture remote read offline');return{data:()=>document}},runTransaction:async(db,work)=>{calls.push(['transaction']);if(['both-network-fail','read-empty-write-fails','empty-local-network-fail'].includes(scenario))throw Error('Fixture transaction offline');return work({get:async ref=>{calls.push(['transaction-read',ref.path]);return{data:()=>scenario==='transaction-existing'?{[context.artifactField(focus,'phonics')]:existing}:document}},set:(ref,patch,options)=>{calls.push(['transaction-set',ref.path,options]);document={...document,...patch}}})}};
  vm.createContext(context);vm.runInContext(bodies,context);context.artifactField=vm.runInContext("artifactField",context);
  const selected=authored.getAuthoredPhonicsFocusCards(focus),ownerKey=context.practiceArtifactKey(focus,'phonics');
  existing={version:1,ownerKey,cards:selected.map((c,i)=>({...c,authoredId:c.id,id:'remote-owned-'+i,practiceRole:i===0?'original':i===(goal?1:2)?'transfer':'contrast',practiceWord:'STALE_COPY'})),outcomes:{'remote-owned-0':{success:true,item:'captured casa',support:'modeled'}}};
  if(scenario==='local-existing')local=structuredClone(existing);
  if(scenario==='empty-local-network-fail')local={version:1,ownerKey,cards:[],outcomes:{}};
  if(scenario==='remote-existing')document={[context.artifactField(focus,'phonics')]:existing};
  const input={focus,alphabet:authored.getAuthoredPhonicsDeck('es','en','Pre-A1').slice(0,1),scenario};
  const expected=JSON.parse(JSON.stringify(await context.getFocusedPhonicsDeck(focus,input.alphabet)));
  if(!expected.cards.length||expected.cards.some(c=>c.practiceWord==='STALE_COPY'))throw Error('Canonical source deck unavailable');
  const retained=['remote-existing','transaction-existing','local-existing'].includes(scenario);
  if(retained?!expected.outcomes['remote-owned-0']?.success:Object.keys(expected.outcomes).length)throw Error('Unexpected source outcomes');
  rows.push({name:(goal?'goal-':'repair-')+scenario,input,expected,cached:local,calls});
}
await fs.writeFile('Tests/PiyaliCoreTests/Fixtures/focused-phonics-cache.json.gz',gzipSync(JSON.stringify({rows}),{level:9}));
await fs.writeFile('docs/reference/focused-phonics-cache-manifest.json',JSON.stringify({cases:rows.length,source:{file,sha256:createHash('sha256').update(source).digest('hex'),functions:names},authoredBundleSha256:createHash('sha256').update(bundle.outputFiles[0].text).digest('hex'),scope:'Unmodified original practiceArtifactKey/artifactField/practiceArtifact/getFocusedPhonicsDeck and independently bundled original authored module; public in-memory local/read/transaction boundaries, including read/transaction failures and authoritative winners. No external I/O.'},null,2)+'\n');
console.log(rows.length,'original focused Phonics cache and network-failure cases');
