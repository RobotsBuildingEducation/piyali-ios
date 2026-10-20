import fs from 'node:fs/promises';
import path from 'node:path';
const reference=path.resolve(process.argv[2] || '../nosabos/nosabos');
const base=path.join(reference,'node_modules/@nostr-dev-kit/ndk-wallet');
const source=await fs.readFile(path.join(base,'src/wallets/cashu/wallet/index.ts'),'utf8');
const esbuild=await import(path.join(reference,'node_modules/esbuild/lib/main.js'));
const body=source.slice(source.indexOf('function payloadForEvent('));
const result=await esbuild.transform(body+'\nexport {payloadForEvent};',{loader:'ts',format:'esm'});
const {payloadForEvent}=await import('data:text/javascript;base64,'+Buffer.from(result.code).toString('base64'));
const keys=['1','2','3'].map(n=>'0'.repeat(63)+n),mints=['https://mint.minibits.cash/Bitcoin','https://second.example'];
const fixtures=[];for(const count of [1,2,3]) for(const mintCount of [1,2]) { const input={keys:keys.slice(0,count),mints:mints.slice(0,mintCount)};fixtures.push({...input,payload:payloadForEvent(input.keys,input.mints)}); }
const version=JSON.parse(await fs.readFile(path.join(base,'package.json'),'utf8')).version;
await fs.writeFile(new URL('../Tests/PiyaliCoreTests/Fixtures/wallet-import.json',import.meta.url),JSON.stringify({version,configurations:fixtures},null,2)+'\n');
console.log('Exported '+fixtures.length+' actual NDK wallet payloads, version '+version);
