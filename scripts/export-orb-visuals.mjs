// Execute pure original eye/reaction policies; adapt only the surface shader syntax.
import fs from 'node:fs/promises';import path from 'node:path';import vm from 'node:vm';import {gzipSync} from 'node:zlib';import {createHash} from 'node:crypto';
const root=process.cwd(),reference=path.resolve(root,'../nosabos/nosabos');
const files=['src/components/orbing/orbModel.js','src/components/orbing/orbEyeMorph.js','src/components/orbing/orbFace.js','src/components/orbing/createOrbScene.js','src/utils/tutorVoiceEnvelope.js','node_modules/three/examples/jsm/environments/RoomEnvironment.js'];
const sources=await Promise.all(files.map(file=>fs.readFile(path.join(reference,file),'utf8')));
const strip=s=>s.replace(/export \{[^}]+\};/g,'').replace(/\bexport /g,'');
const model=vm.runInNewContext(`(()=>{${strip(sources[0])};return {ORB_FLOW,ORB_PALETTES,REACTION_DURATION,reactionPose,randomTutorFeedback}})()`);
const eye=vm.runInNewContext(`(()=>{${strip(sources[1])};return {EXPRESSIONS,createEyeMorph,advanceEyeMorph}})()`);
const expressions=Object.fromEntries(Object.entries(eye.EXPRESSIONS).map(([key,value])=>[key,Array.from(value)]));
const cases=[];
for(const kind of Object.keys(model.REACTION_DURATION))for(const elapsed of [-0.1,0,0.15,0.5,1.2,2,3,4])for(const amount of [0,0.7,1.5])cases.push({kind,elapsed,amount,pose:model.reactionPose(kind,elapsed,amount)});
const envelope=vm.runInNewContext(`(()=>{${strip(sources[4])};return createTutorVoiceEnvelope})()`),envelopeCases=[];
for(const microphone of [true,false]) { const sample=envelope({microphone}),inputs=[0,0.003,0.007,0.06,0.06,0.03,0.001,0.001,0,0,0.15,0.15,0.1,0],steps=inputs.map(amplitude=>({amplitude,elapsedMs:50,value:sample(amplitude,50)}));envelopeCases.push({microphone,steps}); }
const morphCases=[];
for(const mood of Object.keys(expressions))for(const state of ['idle','thinking']) {const morph=eye.createEyeMorph('sleepy');for(const dt of [0.025,0.05,0.01])eye.advanceEyeMorph(morph,{mood,state,time:1.7,dt});morphCases.push({mood,state,time:1.7,steps:[0.025,0.05,0.01],values:Array.from(morph.values),velocity:Array.from(morph.velocity)});}
const scene=sources[3],noise=scene.match(/float orbNoise\(vec2 p\) \{[\s\S]*?\n      \}/)?.[0],pigment=scene.match(/vec3 p = vOrbPosition;([\s\S]*?)\n      \}\n      diffuseColor/)?.[1];
if(!noise||!pigment)throw Error('Original orb surface moved; review adapter.');
const metal=s=>s.replace(/\bvec([234])\b/g,'float$1');
const shader=`#pragma arguments\nfloat orbTime;\nfloat orbVoice;\nfloat orbRipple;\nfloat orbSpiral;\nfloat orbWarp;\nfloat orbTurbulence;\nfloat3 orbDeep;\nfloat3 orbMid;\nfloat3 orbLight;\n#pragma varyings\nfloat3 orbPosition;\n#pragma declaration\n${metal(noise)}\n#pragma body\nfloat orbWaveScale=1.0;float orbWashAlpha=0.83;float orbVoiceMod=1.0;float3 pigment;float3 p=in.orbPosition;\n${metal(pigment)}\n_surface.diffuse.rgb *= pigment;\n`;
await fs.writeFile(path.join(root,'Piyali/Resources/orb-surface.shader'),shader);
const toneFile='node_modules/three/src/renderers/shaders/ShaderChunk/tonemapping_pars_fragment.glsl.js',tone=await fs.readFile(path.join(reference,toneFile),'utf8'),fit=tone.match(/vec3 RRTAndODTFit[\s\S]*?\n\}/)?.[0],aces=tone.match(/vec3 ACESFilmicToneMapping[\s\S]*?\n\}/)?.[0];
if(!fit||!aces)throw Error('Three ACES policy moved.');
await fs.writeFile(path.join(root,'Piyali/Resources/orb-tone.shader'),'#pragma declaration\n'+metal(fit+'\n'+aces).replace(/\bmat3\b/g,'float3x3').replace(/toneMappingExposure/g,'1.2')+'\n#pragma body\n_output.color.rgb = ACESFilmicToneMapping(_output.color.rgb);\n');

await fs.writeFile(path.join(root,'Piyali/Resources/orb-visuals.json.gz'),gzipSync(JSON.stringify({expressions,flow:model.ORB_FLOW,palettes:model.ORB_PALETTES,durations:model.REACTION_DURATION})));
await fs.writeFile(path.join(root,'Tests/PiyaliCoreTests/Fixtures/orb-visuals.json'),JSON.stringify({cases,morphCases,envelopeCases})+'\n');
await fs.writeFile(path.join(root,'docs/reference/orb-visuals-manifest.json'),JSON.stringify({sources:files.map((file,i)=>({file,sha256:createHash('sha256').update(sources[i]).digest('hex')})),environment:{file:'orb-room.hdr',sha256:createHash('sha256').update(await fs.readFile(path.join(root,'Piyali/Resources/orb-room.hdr'))).digest('hex'),source:'Three RoomEnvironment, captured as linear RGBE through the isolated reference fixture; no display tone mapping'},tone:{file:toneFile,sha256:createHash('sha256').update(tone).digest('hex')},scope:'Original eye outlines, palettes, flow and reaction poses. Native spring/reaction math compared against executed source. Original default pigment expression converted from GLSL vectors to Metal for SceneKit; reward-only experimental surfaces excluded.'},null,2)+'\n');
await fs.copyFile(path.join(reference,'node_modules/three/LICENSE'),path.join(root,'Piyali/Resources/ThirdParty/Three-LICENSE.txt'));
console.log(`Exported eight expressions, ${cases.length} reaction poses and ${morphCases.length} spring trajectories.`);
