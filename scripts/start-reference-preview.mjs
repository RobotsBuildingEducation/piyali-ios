// Serve the reference read-only at an isolated origin. All Vite caches live in this repo.
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import fs from 'node:fs/promises';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const reference=path.resolve(process.argv[2] || path.join(root,'../nosabos/nosabos'));
const vite=await import(path.join(reference,'node_modules/vite/dist/node/index.js'));
const loaded=await vite.loadConfigFromFile({command:'serve',mode:'dev-direct'},path.join(reference,'vite.config.js'),reference,'warn',undefined,'runner');
if(!loaded) throw new Error('Reference configuration not found');
const flatten=(plugins)=>plugins.flat(Infinity).filter(Boolean);
// Same-origin mobile frame keeps browser accessibility/actions available while
// the original app receives an actual iPhone-width layout viewport.
const frameHTML=await fs.readFile(new URL('./reference-mobile-frame.html',import.meta.url),'utf8');
const mobileFrame={name:'piyali-reference-mobile-frame',configureServer(server){server.middlewares.use('/__piyali-mobile-frame',(req,res)=>{res.setHeader('Content-Type','text/html');res.end(frameHTML)})}};
// Source onboarding is rendered without creating a browser learner/account.
const onboardingID=path.join(reference,'__piyali-onboarding.jsx');
const toolsHeaderID=path.join(reference,'__piyali-topbar.jsx');
const toolsFixture={name:'piyali-session-tools-fixture',enforce:'pre',resolveId(id,importer){if(id==='/__piyali-topbar.jsx')return toolsHeaderID;if(id.replace(/\.js$/,'').endsWith('/useXpHistoryYear') && importer?.endsWith('/DailyGoalModal.jsx'))return '\0piyali-public-history';},async load(id){if(id===toolsHeaderID)return fs.readFile(new URL('./reference-topbar.jsx',import.meta.url),'utf8');if(id==='\0piyali-public-history')return 'export default function fixture({legacyDays={},legacyGoalDays=[]}){return {days:legacyDays,goalDays:legacyGoalDays}}';}};
const onboardingPreview={name:'piyali-reference-onboarding',resolveId(id){if(id==='/__piyali-onboarding.jsx')return onboardingID},async load(id){if(id===onboardingID)return fs.readFile(new URL('./reference-onboarding.jsx',import.meta.url),'utf8')},configureServer(server){server.middlewares.use('/__piyali-onboarding',async(req,res,next)=>{if((req.originalUrl || req.url).split('?')[0].endsWith('.jsx'))return next();const html=await server.transformIndexHtml('/__piyali-onboarding','<!doctype html><html><head><meta name="viewport" content="width=device-width,initial-scale=1"><style>html{scrollbar-width:none}::-webkit-scrollbar{display:none}</style></head><body><div id="root"></div><script type="module" src="/__piyali-onboarding.jsx"></script></body></html>');res.setHeader('Content-Type','text/html');res.end(html)})}};
// The reference stories harness supplies batch services but its newer component
// otherwise starts the real default stream. Keep this test entry on its own
// explicit fixture over the new protocol without changing the component or main app.
const storyFixtureCompatibility={name:'piyali-source-story-fixture',enforce:'pre',transform(source,id){
 if(id.split('?')[0]!==path.join(reference,'tests/browser/stories.jsx')) return null;
 const needle='const services = {';
 if(!source.includes(needle)) throw Error('Source stories fixture moved; review adapter.');
 let fixture=source.replace(needle,needle+`
  generateStream: async () => {
    const sample=JSON.parse(await services.generate()),records=[{type:"title",title:sample.title}];
    sample.segments.forEach((segment,index)=>{
      segment.turns.forEach(turn=>records.push({type:"turn",segment:index,...turn}));
      records.push({type:"question",segment:index,question:segment.question});
    });
    records.push({type:"done"});
    return {stream:(async function*(){yield {text:()=>records.map(item=>JSON.stringify(item)).join(String.fromCharCode(10))};})()};
  },`);
 fixture=fixture.replace('const [mode, setMode] = useState(() => Math.random() < 0.5 ? "radio" : "conversation");','const [mode, setMode] = useState(() => new URLSearchParams(window.location.search).get("mode") === "radio" ? "radio" : "conversation");');
 fixture=fixture.replace('applyThemeMode("dark");','applyThemeMode(new URLSearchParams(window.location.search).get("theme") === "light" ? "light" : "dark");');
 return fixture;
}};
// The actual flashcard component keeps its UI/state; only external I/O is replaced by explicit public fixtures.
const flashcardFixture={name:'piyali-source-flashcard-fixture',enforce:'pre',resolveId(id,importer){if(!importer?.endsWith('/FlashcardPractice.jsx'))return;if(id.endsWith('/llm'))return '\0piyali-flashcard-judge';if(id.endsWith('/firebaseResources'))return '\0piyali-flashcard-stream';if(id.endsWith('/learningIntelligence'))return '\0piyali-flashcard-score';if(id.endsWith('/companionMemory'))return '\0piyali-flashcard-memory';if(id.endsWith('/questionDifficultyAssessment'))return '\0piyali-flashcard-worth';},load(id){
 if(id==='\0piyali-flashcard-judge')return `export const DEFAULT_RESPONSES_MODEL='public-fixture';export const callResponses=async ({input})=>{await new Promise(r=>setTimeout(r,150));return input.includes('WRONG_FIXTURE')?'NO':'YES | 6'};`;
 if(id==='\0piyali-flashcard-stream')return `export const simplemodel={generateContentStream:async()=>({stream:(async function*(){yield {text:()=> 'ma'};await new Promise(r=>setTimeout(r,150));yield {text:()=> 'má'};})(),response:Promise.resolve({text:()=> 'mamá'})})};`;
 if(id==='\0piyali-flashcard-score')return 'export const recordGradedOutcome=async()=>{};';
 if(id==='\0piyali-flashcard-memory')return 'export const captureCompanionMemory=async()=>{};';
 if(id==='\0piyali-flashcard-worth')return 'export const assessGeneratedQuestionWorth=async()=>null;';
}};
const server=await vite.createServer({...loaded.config,configFile:false,root:reference,envDir:reference,cacheDir:path.join(root,'.reference-preview/cache'),plugins:[flashcardFixture,mobileFrame,toolsFixture,onboardingPreview,storyFixtureCompatibility,...flatten(loaded.config.plugins).filter(p=>!String(p.name).includes('pwa') && !String(p.name).includes('visualizer'))],server:{...loaded.config.server,host:'127.0.0.1',port:5181,strictPort:true}});
await server.listen();console.log('Read-only reference preview: http://127.0.0.1:5181');
