import fs from 'node:fs/promises';import path from 'node:path';import vm from 'node:vm';import {createHash} from 'node:crypto';
const root=process.cwd(),reference=path.resolve(root,'../nosabos/nosabos'),file='src/utils/landingTutorDemo.js',source=await fs.readFile(path.join(reference,file),'utf8');
const module=vm.runInNewContext(`(()=>{${source.replace(/^export /gm,'')};return {LandingTutorDemoSession,buildLandingTutorTurnInstructions,LANDING_TUTOR_CONNECT_TIMEOUT_MS,LANDING_TUTOR_TURN_LIMIT}})()`,{AbortController});
async function journey(name,steps) {
 let options,requests=[],mic=[],closes=0;
 const bridge={send:raw=>requests.push(JSON.parse(raw).response.instructions),setInputAudioEnabled:value=>mic.push(value),close:async()=>{closes++}};
 const controller=new module.LandingTutorDemoSession({createBridge:async input=>{options=input;return bridge},setTimeout:()=>1,clearTimeout:()=>{},onChange:()=>{}});
 await controller.start({targetLanguage:'es',supportLanguage:'en'});
 const snapshot=()=>({state:{...controller.state},requests:[...requests],mic:[...mic],closes});
 const trace=[{step:{type:'opened'},...snapshot()}];
 for(const step of steps){if(step.type==='stop')controller.stop();else options.onEvent({data:JSON.stringify(step)});trace.push({step,...snapshot()})}
 return {name,trace};
}
const done=id=>({type:'response.done',response_id:id}),input=transcript=>({type:'conversation.item.input_audio_transcription.completed',transcript});
const cases=[];
cases.push(await journey('whole lesson with duplicate/early/empty input',[{type:'response.created',response:{id:'opening'}},{type:'response.audio_transcript.delta',delta:'¡Hola!'},input('too early'),done('opening'),done('opening'),input('  '),input('ola'),input('duplicate'),done('feedback'),done('feedback'),done('word2'),input('gracias'),done('review1'),input('hola'),done('review2'),input('gracias'),done('goodbye'),input('keep going')]));
cases.push(await journey('stop before first completed response',[{type:'response.audio_transcript.delta',delta:'partial'}, {type:'stop'},done('late')]));
cases.push(await journey('stop after a completed response',[done('first'),{type:'stop'},input('late')]));
cases.push(await journey('provider error',[{type:'error'},done('late')]));
cases.push(await journey('missing ID and cancellation',[done(''),{type:'response.canceled'},{type:'response.canceled',error:false},done('first'),input('hola'),{type:'response.canceled',error:{message:'failed'}}]));
cases.push(await journey('transcription bounds',[done('first'),input('x'.repeat(1700))]));
await fs.writeFile(path.join(root,'Tests/PiyaliCoreTests/Fixtures/landing-demo-policy.json'),JSON.stringify({timeout:module.LANDING_TUTOR_CONNECT_TIMEOUT_MS,limit:module.LANDING_TUTOR_TURN_LIMIT,cases})+'\n');
await fs.writeFile(path.join(root,'docs/reference/landing-demo-policy-manifest.json'),JSON.stringify({sources:[{file,sha256:createHash('sha256').update(source).digest('hex')}],scope:'Six journeys executed by the original controller: full five-turn lesson plus final feedback; input gating, duplicate completions, stop, provider errors and transcription bounds. Original per-turn prompts captured in each trace.'},null,2)+'\n');
console.log('Exported six original public-demo controller journeys.');
