// Exercise the actual reference bridge with inert session/audio/clock adapters.
import fs from 'node:fs/promises';import path from 'node:path';import vm from 'node:vm';import {createRequire}from'node:module';import{createHash}from'node:crypto';import{gzipSync}from'node:zlib';
const root=process.cwd(),ref=path.resolve(root,'../nosabos/nosabos'),require=createRequire(path.join(ref,'package.json')),{parse}=require('@babel/parser'),generate=require('@babel/generator').default;
const files=['src/utils/geminiLiveBridge.js','src/utils/geminiLiveVoices.js'],sources=await Promise.all(files.map(f=>fs.readFile(path.join(ref,f),'utf8')));
function strip(source){const ast=parse(source,{sourceType:'module'});ast.program.body=ast.program.body.flatMap(n=>n.type==='ImportDeclaration'?[]:n.type==='ExportNamedDeclaration'?n.declaration?[n.declaration]:[]:[n]);for(const n of ast.program.body)if(n.type==='VariableDeclaration')for(const d of n.declarations)if(d.id.name==='env')d.init={type:'ObjectExpression',properties:[]};return generate(ast).code}
const code=strip(sources[1])+'\n'+strip(sources[0])+`\nuid=()=>String(++responseID);globalThis.createBridge=()=>new GeminiLiveRealtimeBridge({inputAudioEnabled:true,voice:'Vindemiatrix',onEvent:async event=>{const data=JSON.parse(event.data);events.push(data);if(data.type==='conversation.item.input_audio_transcription.completed'&&autoRequest)bridge.requestResponse('App-directed reply');}});`;
function sandbox(){let clock=10000,timerID=0;const timers=new Map(),frames=[];const box={responseID:0,events:[],sent:[],autoRequest:false,ResponseModality:{AUDIO:'AUDIO'},console:{info(){},warn(){},log(){}},performance:{now:()=>clock},setTimeout:(fn,ms)=>{timers.set(++timerID,{fn,ms});return timerID},clearTimeout:id=>timers.delete(id),btoa:s=>Buffer.from(s,'binary').toString('base64'),atob:s=>Buffer.from(s,'base64').toString('binary')};
 vm.createContext(box);vm.runInContext(code,box);box.bridge=box.createBridge();const b=box.bridge;
 const session=()=>({receive:async function*(){await new Promise(()=>{})},send:async(text,complete)=>box.sent.push({type:'text',text,complete}),sendAudioRealtime:async(audio)=>box.sent.push({type:'input',...audio}),close:async()=>box.sent.push({type:'close'})});
 b.session=session();b.readyState='open';b.connectLiveSession=()=>{box.sent.push({type:'connect'});return new Promise(resolve=>box.resolveReset=()=>resolve(session()))};
 b.audioContext={state:'running',get currentTime(){return clock/1000},resume:async()=>{},close:async()=>{},createBuffer:(_,count,rate)=>({duration:count/rate,getChannelData:()=>new Float32Array(count)}),createBufferSource:()=>{const frame={connect(){},start(time){frame.time=time;frames.push(frame)},stop(){frame.stopped=true}};return frame}};b.playbackAnalyser={disconnect(){}};
 return {box,b,frames,timers,advance(ms){clock+=ms},snapshot(){const cleanEvent=e=>JSON.parse(JSON.stringify(e));return {events:box.events.map(cleanEvent),sent:JSON.parse(JSON.stringify(box.sent)),audio:frames.map(f=>({bytes:Buffer.from(f.pausedPcm||new ArrayBuffer(0)).toString('base64'),stopped:!!f.stopped})),state:{closed:b.closed,inputEnabled:b.inputAudioEnabled,suppressAuto:b.suppressAutoTurn,active:b.activeResponse?.id||null,pending:b.pendingResponses.map(x=>x.id),queued:b.pendingManualResponses.map(x=>x.id),scheduled:b.scheduledSources.size,complete:b.serverTurnComplete,completed:b.completedResponsesSinceReset,resetting:b.resettingSession,resetPending:b.resetPending,gain:b.outputGain}}}}}
const pcm=(value,count=48)=>{const bytes=Buffer.alloc(count*2);for(let i=0;i<count;i++)bytes.writeInt16LE(value,i*2);return bytes.toString('base64')};
async function trace(name,steps){const s=sandbox(),rows=[];for(const command of steps){const b=s.b,p=command;
 if(p.op==='request')b.requestResponse(p.text||'Teach now',p.metadata||{});
 else if(p.op==='server')await b.handleServerMessage(p.message);
 else if(p.op==='play'){const source=s.frames[p.index??0];if(source)source.onended?.()}
 else if(p.op==='input')b.setInputAudioEnabled(p.enabled);
 else if(p.op==='pcm'){s.advance(p.advance||0);await vm.runInContext('bridge.handleInputAudioBuffer(fromBase64('+JSON.stringify(p.data)+'))',s.box)}
 else if(p.op==='gain')b.setOutputGain(p.value);
 else if(p.op==='clear')b.send(JSON.stringify({type:'input_audio_buffer.clear'}));
 else if(p.op==='cancel')b.send(JSON.stringify({type:'response.cancel'}));
 else if(p.op==='timeout'){const timer=[...s.timers.values()].find(t=>t.ms>=5000);timer?.fn()}
 else if(p.op==='resetReady')s.box.resolveReset?.();
 else if(p.op==='autoRequest')s.box.autoRequest=p.enabled;
 else if(p.op==='context')b.send(JSON.stringify({type:'session.update',session:{instructions:p.text}}));
 else if(p.op==='close')await b.close();
 else throw Error('Unknown trace command '+p.op);
 for(let i=0;i<10;i++)await Promise.resolve();rows.push({command,expected:s.snapshot()});
 }return {name,steps:rows}}
const output=(text='Hola',audio=true,complete=false)=>({serverContent:{modelTurn:{parts:audio?[{inlineData:{mimeType:'audio/pcm;rate=24000',data:pcm(1200)}}]:[{text:'Fallback'}]},outputTranscription:text?{text}:undefined,turnComplete:complete}}),server=message=>({op:'server',message});
const traces=[];
traces.push(await trace('transcription and playback completion',[{op:'request'},server(output('Hola')),server({serverContent:{generationComplete:true}}),server({serverContent:{turnComplete:true}}),{op:'play'}]));
traces.push(await trace('suppress unsolicited reply before synchronous transcript callback',[{op:'autoRequest',enabled:true},server({serverContent:{inputTranscription:{text:' hola '},modelTurn:{parts:[{text:'Unwanted auto reply'}]}}}),server({serverContent:{interrupted:true}}),server(output('Good')),server({serverContent:{turnComplete:true}}),{op:'play'}]));
traces.push(await trace('clear input and continuous enabled audio',[{op:'pcm',data:pcm(0)},{op:'pcm',data:pcm(1000)},{op:'pcm',data:pcm(1000),advance:1100},{op:'input',enabled:false},{op:'pcm',data:pcm(1000)},server({serverContent:{inputTranscription:{text:'discard'}}}),{op:'clear'},server({serverContent:{turnComplete:true}}),{op:'input',enabled:true},{op:'pcm',data:pcm(0)}]));
traces.push(await trace('queued responses cancellation late playback',[{op:'request',text:'First'},{op:'request',text:'Second'},server(output('One')),server({serverContent:{turnComplete:true}}),{op:'play'},server(output('Two')),{op:'cancel'},{op:'play',index:1},server({serverContent:{interrupted:true,turnComplete:true}})]));
traces.push(await trace('fallback only without transcript',[{op:'request'},server(output('',false)),server({serverContent:{modelTurn:{parts:[{text:'more'},{text:'thought',thought:true}]},turnComplete:true}})]));
traces.push(await trace('missing first response times out without hanging',[{op:'request',text:'First'},{op:'request',text:'Second'},{op:'timeout'},server(output('Recovered',false,true))]));
const reset=[];for(let i=0;i<4;i++)reset.push({op:'request',text:'Turn '+i},server(output('Reply '+i,false,true)));reset.push({op:'request',text:'After reset'},{op:'input',enabled:true},{op:'resetReady'},server(output('Still current',false,true)),{op:'close'});traces.push(await trace('four-turn reset retains queued prompt and desired input',reset));
traces.push(await trace('close during reset cannot reopen or dispatch',[...reset.slice(0,8),{op:'request',text:'Never send'},{op:'close'},{op:'resetReady'}]));
traces.push(await trace('gain follows source unity clamp',[-1,0,0.3,1,1.1,1.2,1.3,3.5,4].map(value=>({op:'gain',value}))));
await fs.writeFile(path.join(root,'Tests/PiyaliCoreTests/Fixtures/gemini-bridge.json.gz'),gzipSync(JSON.stringify(traces),{level:9}));
await fs.writeFile(path.join(root,'docs/reference/gemini-bridge-manifest.json'),JSON.stringify({sources:files.map((file,i)=>({file,sha256:createHash('sha256').update(sources[i]).digest('hex')})),traces:traces.length,steps:traces.reduce((n,t)=>n+t.steps.length,0),adapters:'Original bridge class executes in Node with inert session/audio/clock/ID adapters. No source Firebase, browser, microphone, relay or production network runs. Audio callbacks and reset completion are explicit commands; all policy branches remain original.'},null,2)+'\n');console.log(traces.length+' actual bridge traces; '+traces.reduce((n,t)=>n+t.steps.length,0)+' steps.');
