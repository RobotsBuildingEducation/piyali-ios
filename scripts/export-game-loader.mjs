// Execute the original mini-game without React, providers, stores or browser I/O.
import fs from 'node:fs/promises';import path from 'node:path';import vm from 'node:vm';import {createRequire} from 'node:module';import {gzipSync} from 'node:zlib';import {createHash} from 'node:crypto';
const root=process.cwd(),ref=path.resolve(root,'../nosabos/nosabos'),require=createRequire(path.join(ref,'package.json')),{parse}=require('@babel/parser'),traverse=require('@babel/traverse').default,{build}=require('esbuild');
const file='src/components/LoadingMiniGame.jsx',source=await fs.readFile(path.join(ref,file),'utf8'),ast=parse(source,{sourceType:'module',plugins:['jsx']});let component;
traverse(ast,{FunctionDeclaration(p){if(p.node.id?.name==='LoadingMiniGame')component=p}});
function callback(name){const n=component.scope.bindings[name]?.path.node.init.arguments[0];if(!n)throw Error('Original loader callback moved: '+name);return 'const '+name+'='+source.slice(n.start,n.end)+';'}
const start=source.indexOf('const TILE ='),end=component.node.start,top=source.slice(start,end).replace(/export default\s*$/,'');
const stateNode=component.scope.bindings.stateRef.path.node.init.arguments[0],initial=source.slice(stateNode.start,stateNode.end);
const loopStart=source.indexOf('const s = stateRef.current;\n      s.frame++;'),loopEnd=source.indexOf('      animId = requestAnimationFrame(loop);\n    };',loopStart);if(loopStart<0||loopEnd<0)throw Error('Original loader frame moved');
const loop=source.slice(loopStart,loopEnd),callbacks=['showMessage','showRoomName','handleInteract','tryInteract','enterDoor','tryMove','faceTowardTile','moveOneStepToward','resolveTileAtClientPoint','handleTileSelection'];
function recorder(){
 const ops=[],stack=[];let fillStyle='#000',globalAlpha=1,font='10px sans-serif',textAlign='start',shape=[];
 const ctx={ops,clearRect(){},save(){stack.push({fillStyle,globalAlpha,font,textAlign});ops.push(['save'])},restore(){Object.assign(ctx,stack.pop());ops.push(['restore'])},translate(x,y){ops.push(['translate',x,y])},scale(x,y){ops.push(['scale',x,y])},fillRect(x,y,w,h){ops.push(['rect',x,y,w,h,fillStyle,globalAlpha])},beginPath(){shape=[]},arc(...args){shape.push(['arc',...args])},ellipse(...args){shape.push(['ellipse',...args])},fill(){ops.push(['path',shape,fillStyle,globalAlpha])},fillText(text,x,y){ops.push(['text',text,x,y,font,textAlign,fillStyle,globalAlpha])}};
 for(const key of ['fillStyle','globalAlpha','font','textAlign'])Object.defineProperty(ctx,key,{get(){return key==='fillStyle'?fillStyle:key==='globalAlpha'?globalAlpha:key==='font'?font:textAlign},set(v){if(key==='fillStyle')fillStyle=v;else if(key==='globalAlpha')globalAlpha=v;else if(key==='font')font=v;else textAlign=v}});
 return ctx;
}
const engineHead=[
 'function makeEngine(p){let now=p.now??1000000,nextTimer=0,message=null,roomName=null,objects=new Set(),sounds=[],timers=new Map();',
 'const Date={now:()=>now},setTimeout=(f,ms)=>{const id=++nextTimer;timers.set(id,{f,due:now+ms});return id},clearTimeout=id=>timers.delete(id);',
 'const supportLang=p.support||"en",world=generateWorld(p.seed),stateRef={current:'+initial+'},messageTimeoutRef={current:null},roomNameTimeoutRef={current:null},petTypeRef={current:p.pet||"ghost"};',
 'const setMessage=v=>message=v,setRoomName=v=>roomName=v,setObjectsFound=f=>objects=f(objects),playGameSound=name=>sounds.push(name);',
 'let width=402,height=874,ctx;const containerRef={current:{getBoundingClientRect:()=>({width,height})}},canvas={width,height,getBoundingClientRect:()=>({left:0,top:0,width,height})},canvasRef={current:canvas};',
 ...callbacks.map(callback),
 'function frame(){'+loop+'}',
 'function expire(){for(const [id,timer]of timers)if(timer.due<=now){timers.delete(id);timer.f()}}',
 'function snapshot(){const s=stateRef.current;return {state:{...s,keysDown:[...s.keysDown]},message,roomName,objects:[...objects],sounds:sounds.splice(0)}}',
 'showRoomName(world.rooms.outdoor.name[normalizeSupportLanguage(supportLang,DEFAULT_SUPPORT_LANGUAGE)]||world.rooms.outdoor.name.en);',
 'return {world,run(op,p){now=p.now??now;expire();if(op==="select")handleTileSelection(p.x,p.y);else if(op==="move")tryMove(p.direction);else if(op==="interact")tryInteract();else if(op==="click"){const t=resolveTileAtClientPoint(p.x,p.y);if(t)handleTileSelection(t.tileX,t.tileY,t.room)}else if(op==="pet")petTypeRef.current=p.pet;else if(op==="frame"){width=p.width||width;height=p.height||height;ctx=record();frame();return {...snapshot(),ops:ctx.ops}}else if(op!=="state")throw Error("Unknown loader operation "+op);return snapshot()}};}'
].join('\n');
const timing=await fs.readFile(path.join(ref,'src/utils/gameLoaderTiming.js'),'utf8');
const imports='import {DEFAULT_SUPPORT_LANGUAGE,SUPPORT_LANGUAGE_CODES,normalizeSupportLanguage} from '+JSON.stringify(path.join(ref,'src/constants/languages.js'))+';\nimport {drawDogCharacter,drawAlienCharacter,drawGhostCharacter,drawRobotCharacter,drawSlimeCharacter,drawAxolotlCharacter} from '+JSON.stringify(path.join(ref,'src/components/rpgCompanionSprites.js'))+';\nimport {GAME_LOADING_MESSAGES} from '+JSON.stringify(path.join(ref,'src/utils/gameLoadingMessages.js'))+';\n';
const entry=imports+top+'\nconst record='+recorder.toString()+';\n'+timing.replaceAll('export ','')+'\n'+engineHead+'\nlet engine;export const api={run(op,json){const p=JSON.parse(json);let result;if(op==="create"){engine=makeEngine(p);result={world:engine.world,...engine.run("state",{})}}else if(op==="delay")result=getGameLoaderExplorationDelay(p.random);else if(op==="copy")result=GAME_LOADING_MESSAGES[p.language]||GAME_LOADING_MESSAGES.en;else {if(!engine)throw Error("Create loader first");result=engine.run(op,p)}return JSON.stringify(result)}};';
const compiled=await build({stdin:{contents:entry,resolveDir:ref},bundle:true,platform:'neutral',format:'iife',globalName:'PiyaliGameLoader',write:false,logLevel:'error',plugins:[{name:'inert-flags',setup(b){b.onResolve({filter:/components\/flagsIcons\/flags$/},()=>({path:'flags',namespace:'flags'}));b.onLoad({filter:/.*/,namespace:'flags'},async()=>{const text=await fs.readFile(path.join(ref,'src/constants/languages.js'),'utf8'),names=text.match(/^import \{([\s\S]*?)\} from "\.\.\/components\/flagsIcons\/flags";/)[1].split(',').map(v=>v.trim()).filter(Boolean);return{contents:'export const '+names.map(n=>n+'=()=>null').join(',')+';'}})}}]});
const script=compiled.outputFiles[0].text+'\nPiyaliGameLoader.api;\n',api=vm.runInNewContext(script,{Intl}),run=(op,p={})=>JSON.parse(api.run(op,JSON.stringify(p))),cases=[];
function check(operation,input){const expected=run(operation,input);cases.push({operation,input,expected});return expected}
for(const seed of [1,7,104729,1793070000000])for(const support of ['en','es','ar','ja']){
 const initial=check('create',{seed,support,pet:'ghost'});check('frame',{width:402,height:874,now:1000000});
 for(const [i,direction]of ['up','right','down','left','right','right'].entries())check('move',{direction,now:1000150+i*150});
 check('frame',{width:402,height:874,now:1001200});check('state',{now:1005000});
 const room=initial.world.rooms.outdoor;
 for(const door of room.doors){check('select',{x:door.x,y:door.y,now:1006000});check('frame',{width:402,height:874,now:1006100})}
}

for(const support of ['en','ar']){
 const initial=check('create',{seed:7,support,pet:'axolotl'}),world=initial.world;let state=initial.state,now=1000000;
 const blocked=new Set([4,2,8,14,15,18,19,20,21,22,6,7,11,23,16,12]);
 function step(op,input){const value=check(op,{...input,now:now+=150});state=value.state;return value}
 function approach(x,y){const room=world.rooms[state.currentRoom],queue=[[state.px,state.py,[]]],seen=new Set();while(queue.length){const [px,py,route]=queue.shift(),key=px+','+py;if(seen.has(key))continue;seen.add(key);if(Math.abs(px-x)+Math.abs(py-y)===1){for(const direction of route)step('move',{direction});return true}for(const [dx,dy,direction]of [[0,-1,'up'],[1,0,'right'],[0,1,'down'],[-1,0,'left']]){const nx=px+dx,ny=py+dy,tile=room.map[ny]?.[nx];if(tile!=null&&!blocked.has(tile))queue.push([nx,ny,[...route,direction]])}}return false}
 function explore(){const room=world.rooms[state.currentRoom];for(let y=0;y<room.map.length;y++)for(let x=0;x<room.map[0].length;x++)if([6,7,11,23,16].includes(room.map[y][x])&&approach(x,y)){step('select',{x,y});step('select',{x,y});step('state',{});break}}
 explore();
 const outdoorDoor=world.rooms.outdoor.doors[0];if(!approach(outdoorDoor.x,outdoorDoor.y))throw Error('Fixture door inaccessible');step('select',{x:outdoorDoor.x,y:outdoorDoor.y});
 for(let i=0;i<26;i++)step('frame',{width:402,height:874});if(state.currentRoom!=='room1')throw Error('Source door did not enter room');explore();
 const back=world.rooms.room1.doors[0];if(!approach(back.x,back.y))throw Error('Return door inaccessible');step('select',{x:back.x,y:back.y});for(let i=0;i<26;i++)step('frame',{width:402,height:874});if(state.currentRoom!=='outdoor')throw Error('Source door did not return');
 check('state',{now:now+4001});
 for(const pet of ['dog','alien','ghost','robot','slime','axolotl']){step('pet',{pet});step('frame',{width:402,height:874})}
}

for(const random of [-1,0,.25,.5,.999,1,2,null])check('delay',{random});for(const language of ['en','es','ar','ja','fr','it','pt','de','hi','ru','unknown'])check('copy',{language});
async function save(file,data){const dest=path.join(process.env.PIYALI_LOADER_OUTPUT||root,file);await fs.mkdir(path.dirname(dest),{recursive:true});await fs.writeFile(dest,data)}
await save('Piyali/Resources/game-loader-policy.js',script);await save('Tests/PiyaliCoreTests/Fixtures/game-loader.json.gz',gzipSync(JSON.stringify(cases),{level:9}));
await save('docs/reference/game-loader-manifest.json',JSON.stringify({sources:await Promise.all([file,'src/components/rpgCompanionSprites.js','src/utils/gameLoaderTiming.js','src/utils/gameLoadingMessages.js','src/utils/bidiText.js','src/constants/languages.js','src/components/SkillTree.jsx','src/utils/tutorialGameLoader.js','src/App.jsx','src/index.css','src/theme.js'].map(async file=>({file,sha256:createHash('sha256').update(await fs.readFile(path.join(ref,file))).digest('hex')}))),cases:cases.length,adapters:'Original world generator, drawing functions, character drawers, initial state, movement/touch/interaction/door callbacks and frame loop. Native-sized canvas, recorded drawing commands, explicit clock/timer and sound-event adapters replace browser I/O. No React, providers, stores, Firebase or learner data executes.'},null,2)+'\n');
console.log('Exported '+cases.length+' original loader cases');
// Record the original note/envelope calls, then synthesize portable PCM.
const soundSource=await fs.readFile(path.join(ref,'src/utils/SoundManager.js'),'utf8'),soundNodes={};
traverse(parse(soundSource,{sourceType:'module',plugins:['classProperties']}),{ObjectProperty(p){if(['rpgStep','rpgDialogueOpen','rpgDialogueSelect'].includes(p.node.key.name))soundNodes[p.node.key.name]=soundSource.slice(p.node.value.start,p.node.value.end)}});
const sounds=[];
for(const[name,fn]of Object.entries(soundNodes)){
 let clock=0;const notes=[],pending=[];function synth(envelope,volume=-12){return{volume:{value:volume},triggerAttackRelease(pitch,duration,at=clock){for(const note of Array.isArray(pitch)?pitch:[pitch])notes.push({note,duration,at,envelope,volume:this.volume.value})}}}
 const adapter={getSynth:synth,createDisposablePolySynth:synth,releaseSynth(){}},callback=vm.runInNewContext('(function(){return '+fn+'})',{Tone:{now:()=>clock},VOL:{QUIET:-20,SOFT:-16,NORMAL:-12,PROMINENT:-10,LOUD:-8},setTimeout:(f,ms)=>pending.push({f,at:clock+ms/1000})}).call(adapter);callback();for(const task of pending.sort((a,b)=>a.at-b.at)){clock=task.at;task.f()}
 const rate=44100,length=Math.ceil(Math.max(...notes.map(n=>n.at+2/Number(n.duration.slice(0,-1))+n.envelope.release))*rate),samples=new Float64Array(length);
 for(const note of notes){const match=/^([A-G])(#?)(\d)$/.exec(note.note),midi=(Number(match[3])+1)*12+{C:0,D:2,E:4,F:5,G:7,A:9,B:11}[match[1]]+(match[2]?1:0),frequency=440*2**((midi-69)/12),hold=2/Number(note.duration.slice(0,-1)),e=note.envelope,gain=0.7*10**(note.volume/20),envelope=t=>t<e.attack?t/e.attack:t<e.attack+e.decay?e.sustain+(1-e.sustain)*Math.exp(-6*(t-e.attack)/e.decay):e.sustain;
  for(let i=Math.floor(note.at*rate);i<Math.min(length,Math.ceil((note.at+hold+e.release)*rate));i++){const t=i/rate-note.at,level=t<hold?envelope(Math.max(0,t)):envelope(hold)*Math.exp(-8*(t-hold)/e.release);samples[i]+=Math.sin(2*Math.PI*frequency*t)*level*gain}
 }
 const out=Buffer.alloc(44+length*2);out.write('RIFF');out.writeUInt32LE(36+length*2,4);out.write('WAVEfmt ',8);out.writeUInt32LE(16,16);out.writeUInt16LE(1,20);out.writeUInt16LE(1,22);out.writeUInt32LE(rate,24);out.writeUInt32LE(rate*2,28);out.writeUInt16LE(2,32);out.writeUInt16LE(16,34);out.write('data',36);out.writeUInt32LE(length*2,40);samples.forEach((v,i)=>out.writeInt16LE(Math.round(Math.max(-1,Math.min(1,v))*32767),44+i*2));await save('Piyali/Resources/'+name+'.wav',out);sounds.push({name,notes,seconds:length/rate})
}
const manifestPath=path.join(process.env.PIYALI_LOADER_OUTPUT||root,'docs/reference/game-loader-manifest.json'),manifest=JSON.parse(await fs.readFile(manifestPath,'utf8'));manifest.sources.push({file:'src/utils/SoundManager.js',sha256:createHash('sha256').update(soundSource).digest('hex')});manifest.sounds=sounds;manifest.nativeAudio='Original sine pitches, timing, envelopes and gain; portable PCM approximates Tone exponential envelopes at 120 BPM.';await fs.writeFile(manifestPath,JSON.stringify(manifest,null,2)+'\n');
