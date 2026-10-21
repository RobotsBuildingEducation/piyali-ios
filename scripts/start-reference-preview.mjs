// Serve the reference read-only at an isolated origin. All Vite caches live in this repo.
import path from 'node:path';
import {fileURLToPath} from 'node:url';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const reference=path.resolve(process.argv[2] || path.join(root,'../nosabos/nosabos'));
const vite=await import(path.join(reference,'node_modules/vite/dist/node/index.js'));
const loaded=await vite.loadConfigFromFile({command:'serve',mode:'dev-direct'},path.join(reference,'vite.config.js'),reference,'warn',undefined,'runner');
if(!loaded) throw new Error('Reference configuration not found');
const flatten=(plugins)=>plugins.flat(Infinity).filter(Boolean);
const server=await vite.createServer({...loaded.config,configFile:false,root:reference,envDir:reference,cacheDir:path.join(root,'.reference-preview/cache'),plugins:flatten(loaded.config.plugins).filter(p=>!String(p.name).includes('pwa') && !String(p.name).includes('visualizer')),server:{...loaded.config.server,host:'127.0.0.1',port:5181,strictPort:true}});
await server.listen();console.log('Read-only reference preview: http://127.0.0.1:5181');
