// Read the source without changing it. Export its literal content and parser examples.
import fs from 'node:fs/promises';import path from 'node:path';import {createRequire}from'node:module';import vm from'node:vm';import{gzipSync}from'node:zlib';
const root=process.cwd(),reference=path.resolve(root,'../nosabos/nosabos'),require=createRequire(path.join(reference,'package.json')),{parse}=require('@babel/parser'),traverse=require('@babel/traverse').default;
const identity=await fs.readFile(path.join(reference,'src/components/IdentityDrawer.jsx'),'utf8'),ast=parse(identity,{sourceType:'module',plugins:['jsx']}),wallet={};
traverse(ast,{VariableDeclarator(p){if(p.node.id.name!=='W')return;for(const s of p.node.init.body.body){if(s.type!=='VariableDeclaration')continue;for(const d of s.declarations)if(d.init?.type==='ObjectExpression')wallet[d.id.name]=vm.runInNewContext('('+identity.slice(d.init.start,d.init.end)+')')}p.stop()}});
if(Object.keys(wallet).length!==10)throw Error('Source wallet copy moved');
const source=await fs.readFile(path.join(reference,'src/components/NutzapTransactionsDrawer.jsx'),'utf8'),txAST=parse(source,{sourceType:'module',plugins:['jsx']});let transactions;
traverse(txAST,{VariableDeclarator(p){if(p.node.id.name==='COPY')transactions=vm.runInNewContext('('+source.slice(p.node.init.start,p.node.init.end)+')')}});
const {BITCOIN_RECIPIENTS:recipients}=await import(path.join(reference,'src/constants/bitcoinRecipients.js'));
await fs.writeFile(path.join(root,'Piyali/Resources/wallet-copy.json.gz'),gzipSync(JSON.stringify({wallet,transactions,recipients}),{level:9}));
// Run the actual NDK parser used by the drawer, with actual Nostr signatures.
const esbuild=require('esbuild');let parser;traverse(txAST,{FunctionDeclaration(p){if(p.node.id.name==='parseNutzap')parser=source.slice(p.node.start,p.node.end)}});
const built=await esbuild.build({stdin:{contents:`import NDK,{NDKEvent,NDKNutzap} from '@nostr-dev-kit/ndk';import {finalizeEvent} from 'nostr-tools';${parser};export {NDK,NDKEvent,NDKNutzap,parseNutzap,finalizeEvent};`,resolveDir:reference},bundle:true,platform:'node',format:'cjs',write:false});
const module={exports:{}};new Function('module','exports','require',built.outputFiles[0].text)(module,module.exports,require);const web=module.exports,key=new Uint8Array(32).fill(1),proof={amount:1,id:'00abc',secret:'public-fixture-only',C:'02'+'a'.repeat(64)},base={kind:9321,created_at:1700000000,tags:[['alt','This is a nutzap'],['p','b'.repeat(64)],['u','https://mint.example'],['proof',JSON.stringify(proof)]],content:'Robots Building Education'},fixtures=[];
for(const variant of [base,{...base,tags:[...base.tags,['p','c'.repeat(64)]]},{...base,tags:[...base.tags,['e','a'],['e','b']]},{...base,tags:base.tags.filter(t=>t[0]!=='u')},{...base,tags:base.tags.map(t=>t[0]==='proof'?['proof','bad-json']:t)},{...base,tags:base.tags.map(t=>t[0]==='proof'?['proof',JSON.stringify({...proof,amount:0})]:t)},{...base,tags:[...base.tags,['proof',JSON.stringify({...proof,amount:2})],['unit','msat'],['comment',' Robots Building Education ']]},{...base,tags:base.tags.filter(t=>t[0]!=='proof'),content:JSON.stringify([proof])},{...base,content:'Unrelated note'}]){
 const event=web.finalizeEvent(variant,key);const instance=new web.NDKEvent(new web.NDK(),event);fixtures.push({event,expected:web.parseNutzap(instance)});
}
const tampered={...fixtures[0].event,id:'f'.repeat(64),content:'Forged'};fixtures.push({event:tampered,expected:null});
await fs.writeFile(path.join(root,'Tests/PiyaliAppTests/Fixtures/wallet-public.json'),JSON.stringify(fixtures,null,2)+'\n');console.log(`Exported ${Object.keys(wallet).length} wallet locales, source recipients and ${fixtures.length} signed public parser examples.`);
