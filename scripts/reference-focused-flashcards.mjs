import fs from 'node:fs/promises';
import path from 'node:path';
import {createRequire} from 'node:module';
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
 if(id==='\0piyali-focused-deck-io'){
  const source=await fs.readFile(path.join(reference,'src/utils/focusedPracticeDecks.js'),'utf8'),req=createRequire(path.join(reference,'package.json')),ast=req('@babel/parser').parse(source,{sourceType:'module'}),names=new Set(['goalPromptData','practiceArtifactKey','artifactField','practiceArtifact','getGoalFlashcards','savePracticeOutcome']),body=[];
  for(const statement of ast.program.body){const n=statement.declaration||statement;if(n.type==='FunctionDeclaration'&&names.has(n.id.name))body.push(source.slice(n.start,n.end));if(n.type==='VariableDeclaration'&&names.has(n.declarations[0].id.name))body.push(source.slice(n.start,n.end))}
  if(body.length!==names.size)throw Error('Original focused flashcard factory/cache moved');
  return `import useUserStore from'/src/hooks/useUserStore';import{generationPerformanceContextFor}from'/src/utils/performanceEloModel';import{readAccountScopedJson,writeAccountScopedJson}from'/src/utils/dailyQuestState';import{getLocalDayKey}from'/src/utils/flashcardReview';
const PHONICS_VERSION='unused',database={},doc=(...args)=>({path:args.slice(1).join('/')});
const getDoc=async()=>{window.__focused.calls.push('remote-read');if(window.__focused.offlineArtifacts)throw Error('Public artifact read failure');return{data:()=>window.__focused.document}};
const runTransaction=async(db,work)=>{window.__focused.calls.push('transaction');if(window.__focused.offlineArtifacts)throw Error('Public artifact transaction failure');return work({get:getDoc,set:(ref,patch)=>{window.__focused.document={...window.__focused.document,...patch};window.__focused.writes.push(['artifact',patch])}})};
const callResponses=async({input})=>{window.__focused.calls.push('generation');window.__focused.prompts.push(input);if(window.__focused.providerFailed)throw Error('Public generation failure');return window.__focused.raw};
const original=(()=>{${body.join('\n')};return{practiceArtifactKey,getGoalFlashcards,savePracticeOutcome}})();
export const practiceArtifactKey=original.practiceArtifactKey;
export const getGoalFlashcards=async focus=>{if(!window.__focused.freshFallback)return window.__focused.artifact;const artifact=await original.getGoalFlashcards(focus);window.__focused.artifact=artifact;return artifact},practiceArtifact=async()=>window.__focused.artifact,savePracticeOutcome=async(...args)=>{window.__focused.writes.push(['outcome',args]);if(window.__focused.freshFallback)return original.savePracticeOutcome(...args)};`;
 }
 if(id==='\0piyali-focused-repair-io')return `export const getOrBuildRepairDeck=async()=>window.__focused.artifact.cards,completeRepairFocus=async(...args)=>window.__focused.writes.push(['repair',args]);`;
 if(id==='\0piyali-focused-evidence-io')return `export {currentGoalFocus}from'/src/utils/learningIntelligence.js';export const recordGoalAttempt=async(...args)=>window.__focused.writes.push(['attempt',args]),recordLearningEvidence=async(...args)=>window.__focused.writes.push(['evidence',args]),evaluateGoalAttempt=async()=>{throw Error('Written evaluation outside focused recall capture')};`;
 if(id==='\0piyali-focused-xp-io')return `export const awardXp=async(...args)=>window.__focused.writes.push(['xp',args]);`;
 if(id===entry){const file=path.join(root,'scripts/reference-focused-flashcards.jsx');this.addWatchFile(file);return fs.readFile(file,'utf8');}
},configureServer(server){server.middlewares.use('/__piyali-focused-flashcards',async(req,res,next)=>{if((req.originalUrl||req.url).split('?')[0].endsWith('.jsx'))return next();const html=await server.transformIndexHtml('/__piyali-focused-flashcards',`<!doctype html><html><head><meta name="viewport" content="width=device-width,initial-scale=1"><style>html{scrollbar-width:none}::-webkit-scrollbar{display:none}</style></head><body><div id="root"></div><script>window.fixtureErrors=[];addEventListener('error',e=>fixtureErrors.push(e.message));addEventListener('unhandledrejection',e=>fixtureErrors.push(String(e.reason)));const fetchLocal=window.fetch.bind(window);window.fetch=(input,...args)=>{const u=new URL(typeof input==='string'?input:input.url,location.href);if(u.hostname!=='127.0.0.1')return Promise.reject(Error('External I/O disabled in public focused deck fixture'));return fetchLocal(input,...args)};window.WebSocket=class{constructor(){throw Error('External relay disabled in public focused deck fixture')}};</script><script type="module" src="/__piyali-focused-flashcards.jsx"></script></body></html>`);res.setHeader('Content-Type','text/html');res.end(html)})}}}
