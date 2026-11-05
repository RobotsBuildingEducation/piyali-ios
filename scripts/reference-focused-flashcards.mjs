import fs from 'node:fs/promises';
import path from 'node:path';
// Render the original focused tree. Public saved artifacts replace only external
// generation/save boundaries; ordinary library loading and all rendering stay original.
export function focusedFlashcardsFixture(root,reference){const entry=path.join(reference,'__piyali-focused-flashcards.jsx');return{name:'piyali-focused-flashcards',enforce:'pre',resolveId(id,importer){
 if(id==='/__piyali-focused-flashcards.jsx')return entry;
 const tree=importer?.endsWith('/FlashcardSkillTree.jsx');
 if(tree&&id.endsWith('/focusedPracticeDecks'))return '\0piyali-focused-deck-io';
 if(tree&&id.endsWith('/companionMemory'))return '\0piyali-focused-repair-io';
 if(tree&&id.endsWith('/learningIntelligence'))return '\0piyali-focused-evidence-io';
 if(tree&&id.endsWith('/utils/utils'))return '\0piyali-focused-xp-io';
},async load(id){
 if(id==='\0piyali-focused-deck-io'){const source=await fs.readFile(path.join(reference,'src/utils/focusedPracticeDecks.js'),'utf8'),key=source.slice(source.indexOf('export function practiceArtifactKey'),source.indexOf('const artifactField'));return `const PHONICS_VERSION='unused';const getLocalDayKey=()=>{throw Error('Fixture focus must provide day')};${key}
export const getGoalFlashcards=async()=>window.__focused.artifact,practiceArtifact=async()=>window.__focused.artifact,savePracticeOutcome=async(...args)=>window.__focused.writes.push(['outcome',args]);`;}
 if(id==='\0piyali-focused-repair-io')return `export const getOrBuildRepairDeck=async()=>window.__focused.artifact.cards,completeRepairFocus=async(...args)=>window.__focused.writes.push(['repair',args]);`;
 if(id==='\0piyali-focused-evidence-io')return `export {currentGoalFocus}from'/src/utils/learningIntelligence.js';export const recordGoalAttempt=async(...args)=>window.__focused.writes.push(['attempt',args]),recordLearningEvidence=async(...args)=>window.__focused.writes.push(['evidence',args]),evaluateGoalAttempt=async()=>{throw Error('Written evaluation outside focused recall capture')};`;
 if(id==='\0piyali-focused-xp-io')return `export const awardXp=async(...args)=>window.__focused.writes.push(['xp',args]);`;
 if(id===entry){const file=path.join(root,'scripts/reference-focused-flashcards.jsx');this.addWatchFile(file);return fs.readFile(file,'utf8');}
},configureServer(server){server.middlewares.use('/__piyali-focused-flashcards',async(req,res,next)=>{if((req.originalUrl||req.url).split('?')[0].endsWith('.jsx'))return next();const html=await server.transformIndexHtml('/__piyali-focused-flashcards',`<!doctype html><html><head><meta name="viewport" content="width=device-width,initial-scale=1"><style>html{scrollbar-width:none}::-webkit-scrollbar{display:none}</style></head><body><div id="root"></div><script>window.fixtureErrors=[];addEventListener('error',e=>fixtureErrors.push(e.message));addEventListener('unhandledrejection',e=>fixtureErrors.push(String(e.reason)));const fetchLocal=window.fetch.bind(window);window.fetch=(input,...args)=>{const u=new URL(typeof input==='string'?input:input.url,location.href);if(u.hostname!=='127.0.0.1')return Promise.reject(Error('External I/O disabled in public focused deck fixture'));return fetchLocal(input,...args)};window.WebSocket=class{constructor(){throw Error('External relay disabled in public focused deck fixture')}};</script><script type="module" src="/__piyali-focused-flashcards.jsx"></script></body></html>`);res.setHeader('Content-Type','text/html');res.end(html)})}}}
