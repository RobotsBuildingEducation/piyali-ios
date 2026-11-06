// Execute the original recorder with synthetic Web Speech events and timers.
import fs from 'node:fs/promises';
import path from 'node:path';
import {pathToFileURL} from 'node:url';
import {gzipSync} from 'node:zlib';
import {createHash} from 'node:crypto';
const reference=path.resolve(process.argv[2]||'../nosabos/nosabos');
const {createReadingSpeechRecorder}=await import(pathToFileURL(path.join(reference,'src/utils/readingSpeechRecorder.js')));
const {getSpeechPracticeErrorFeedback}=await import(pathToFileURL(path.join(reference,'src/utils/speechPracticeFeedback.js')));
const cases=[
 ['continue, duplicate end and old replay',[['start'],['result',1,'Primera frase'],['end',1],['end',1],['tick',100],['result',2,'Segunda fr'],['result',2,'Segunda frase'],['result',1,'Old replay'],['stop'],['end',2]]],
 ['deliberate repeat',[['start'],['result',1,'sí sí'],['end',1],['tick',100],['result',2,'sí sí'],['stop'],['end',2]]],
 ['late final after Stop',[['start'],['result',1,'Una fr'],['stop'],['result',1,'Una frase'],['end',1],['tick',100]]],
 ['Stop between utterances',[['start'],['result',1,'Hola'],['end',1],['stop'],['tick',100]]],
 ['missing end after Stop',[['start'],['result',1,'Hola'],['stop'],['tick',1500],['end',1]]],
 ['cancel and late callbacks',[['start'],['result',1,'Hola'],['cancel'],['result',1,'Late text'],['end',1],['tick',180000]]],
 ['fresh recording fences older one',[['start'],['result',1,'Old text'],['start'],['result',1,'Old final'],['end',1],['result',2,'New text']]],
 ['three empty sessions',[['start'],['error',1,'no-speech'],['tick',1500],['tick',300],['error',2,'no-speech'],['tick',1500],['tick',300],['error',3,'no-speech'],['tick',1500],['tick',300]]],
 ['bounded network retries',[['start'],['error',1,'network'],['end',1],['tick',300],['error',2,'network'],['end',2],['tick',300],['error',3,'network'],['end',3]]],
 ['permission denied',[['start'],['error',1,'not-allowed'],['end',1],['tick',300]]],
 ['three-minute limit between utterances',[['start'],['result',1,'Hola'],['end',1],['tick',180000],['tick',100]]],
 ['replace and shrink partial snapshot',[['start'],['result',1,'Hola mun eco'],['result',1,'Hola mundo'],['result',1,'Hola mundo'],['stop'],['end',1]]],
 ['new speech resets network counter',[['start'],['error',1,'network'],['end',1],['tick',300],['result',2,'Hola'],['error',2,'network'],['end',2],['tick',100],['error',3,'network'],['end',3],['tick',300],['error',4,'network']]],
 ['error during finalization is not a new failure',[['start'],['result',1,'Últimas pa'],['stop'],['error',1,'not-allowed'],['result',1,'Últimas palabras'],['end',1]]],
 ['service failure is not a connection error',[['start'],['error',1,'audio-capture'],['end',1]]],
];
const fixtures=cases.map(([name,steps])=>{
 let text='',phase='idle',issue=null,sequence=0;const sessions=[],timers=new Map();
 class Recognition {constructor(){this.starts=0;this.stops=0;this.aborts=0;sessions.push(this);}start(){this.starts++;}stop(){this.stops++;}abort(){this.aborts++;}}
 const recorder=createReadingSpeechRecorder({Recognition,singleUtterance:false,onTranscript:v=>text=v,onState:v=>phase=v,onError:e=>issue=e.code,setTimer:(fn,delay)=>{const id=++sequence;timers.set(id,{fn,delay});return id;},clearTimer:id=>timers.delete(id)});
 const expected=[];
 for(const [kind,id,value] of steps){
  if(kind==='start'){text='';issue=null;recorder.start('es-MX');} // History.startListening clears these UI fields.
  else if(kind==='stop')recorder.stop();else if(kind==='cancel')recorder.cancel();
  else if(kind==='result')sessions[id-1].onresult({results:[Object.assign([{transcript:value}],{isFinal:false})],resultIndex:0});
  else if(kind==='end')sessions[id-1].onend();else if(kind==='error')sessions[id-1].onerror({error:value});
  else if(kind==='tick')for(const [key,timer] of [...timers])if(timer.delay===id&&timers.has(key)){timers.delete(key);timer.fn();}
  expected.push({text,phase,issue,timers:[...timers.values()].map(v=>v.delay).sort((a,b)=>a-b),sessions:sessions.map(s=>({starts:s.starts,stops:s.stops,aborts:s.aborts}))});
 }
 recorder.dispose();return {name,steps,expected};
});
const errors=['no-speech','connection-failed','connection-timeout','transcription-failed','mic-denied','recording-failed','aborted'].map(code=>({code,expected:getSpeechPracticeErrorFeedback({code},key=>key)}));
const sources=await Promise.all(['src/utils/readingSpeechRecorder.js','src/utils/speechPracticeFeedback.js'].map(async file=>({file,sha256:createHash('sha256').update(await fs.readFile(path.join(reference,file))).digest('hex')})));
await fs.writeFile(new URL('../Tests/PiyaliCoreTests/Fixtures/reading-capture.json.gz',import.meta.url),gzipSync(JSON.stringify({sources,fixtures,errors}),{level:9}));
console.log(`Exported ${fixtures.length} original recorder journeys and ${errors.length} original error presentations.`);
