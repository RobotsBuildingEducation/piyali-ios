import test from 'node:test';
import assert from 'node:assert/strict';
import {handler} from '../src/index.js';
import {realtimeOffer} from '../src/realtime.js';
const sdp='v=0\r\nm=audio 9 UDP/TLS/RTP/SAVPF 111\r\n';
const data={sdp,session:{type:'realtime',model:'gpt-realtime-2.1-mini',instructions:'Practice Spanish at A1.',tools:[{type:'function'}],audio:{input:{turn_detection:{type:'server_vad',silence_duration_ms:2000,create_response:false,interrupt_response:true}},output:{voice:'ash'}}}};
const env={OPENAI_API_KEY:'fixture-not-a-key',REALTIME_RATE_LIMITER:{limit:async()=>({success:true})}};
const request=(value=data)=>new Request('https://piyali.test/realtime',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(value)});
test('Realtime accepts source audio settings and strips unrelated client overrides',()=>{
 const value=realtimeOffer(data,env);assert.equal(value.session.model,'gpt-realtime-2.1-mini');assert.equal(value.session.tools,undefined);
 assert.deepEqual(value.session.audio.input.turn_detection,{type:'server_vad',silence_duration_ms:2000,threshold:0.35,prefix_padding_ms:120,create_response:false,interrupt_response:false});
 assert.equal(value.session.audio.input.transcription.model,'gpt-4o-mini-transcribe');assert.equal(value.session.audio.output.voice,'ash');
 for(const bad of [{...data,sdp:'not-sdp'},{...data,sdp:'v=0\nm=video 9 x\n'},{...data,sdp:sdp+'x'.repeat(65536)},{...data,session:{...data.session,model:'arbitrary'}},{...data,session:{...data.session,instructions:'x'.repeat(30001)}},{...data,session:{...data.session,audio:{output:{voice:'invalid'}}}}]) assert.throws(()=>realtimeOffer(bad,env));
});
test('App Check, owner authentication, and connection limits precede any upstream call',async()=>{
 let calls=0;const fetcher=async()=>{calls++;return new Response(sdp);};
 const denied=handler(async()=>{throw Error();},async()=> 'npub',fetcher);assert.equal((await denied.fetch(request(),env)).status,401);
 const wrongOwner=handler(async()=>{},async()=>{const e=Error();e.status=401;throw e;},fetcher);assert.equal((await wrongOwner.fetch(request(),env)).status,401);
 const worker=handler(async()=>{},async()=> 'npub',fetcher);
 assert.equal((await worker.fetch(request(),{...env,REALTIME_RATE_LIMITER:undefined})).status,503);
 assert.equal((await worker.fetch(request(),{...env,REALTIME_RATE_LIMITER:{limit:async({key})=>{assert.equal(key,'npub');return {success:false};}}})).status,429);
 assert.equal(calls,0);
});
test('explicit narration disables VAD/transcription and preserves bounded source narration settings',async()=>{
 const narration={...data,purpose:'narration',session:{...data.session,audio:{input:{turn_detection:null,transcription:{model:'arbitrary'}},output:{voice:'ash'}}}};
 const value=realtimeOffer(narration,env);assert.deepEqual(value.session.audio.input,{turn_detection:null});assert.equal(value.session.tools,undefined);assert.equal(value.session.model,'gpt-realtime-2.1-mini');assert.deepEqual(value.session.output_modalities,['audio']);
 for(const bad of [{...narration,purpose:'arbitrary'},{...narration,purpose:undefined},{...data,purpose:'narration'},{...narration,session:{...narration.session,model:'arbitrary'}},{...narration,session:{...narration.session,audio:{input:{turn_detection:null},output:{voice:'invalid'}}}}]) assert.throws(()=>realtimeOffer(bad,env));
 const worker=handler(async()=>{},async()=> 'npub',async(url,options)=>{const sent=JSON.parse(options.body.get('session'));assert.deepEqual(sent.audio.input,{turn_detection:null});assert.equal(sent.audio.output.voice,'ash');return new Response(sdp);});
 assert.equal((await worker.fetch(request(narration),env)).status,200);
});
test('authenticated SDP is exchanged using multipart at the official calls endpoint',async()=>{
 const worker=handler(async()=>{},async()=> 'npub',async(url,options)=>{
  assert.equal(url,'https://api.openai.com/v1/realtime/calls');assert.equal(options.headers.Authorization,'Bearer fixture-not-a-key');assert.equal(options.redirect,'manual');
  assert.equal(options.body.get('sdp'),sdp);assert.equal(JSON.parse(options.body.get('session')).model,'gpt-realtime-2.1-mini');return new Response(sdp);
 });
 const result=await worker.fetch(request(),env);assert.equal(result.status,200);assert.equal(await result.text(),sdp);assert.equal(result.headers.get('cache-control'),'no-store');
});
test('upstream failures and malformed answers never expose provider response bodies',async()=>{
 for(const [upstream,status] of [[new Response('secret diagnostic',{status:400}),502],[new Response('secret diagnostic',{status:429}),429],[new Response('not SDP'),502]]) {
  const result=await handler(async()=>{},async()=> 'npub',async()=>upstream).fetch(request(),env);assert.equal(result.status,status);assert.doesNotMatch(await result.text(),/secret diagnostic|fixture-not-a-key/);
 }
 const result=await handler(async()=>{},async()=> 'npub',async()=>{throw Error('secret transport diagnostic');}).fetch(request(),env);assert.equal(result.status,502);assert.doesNotMatch(await result.text(),/secret transport/);
});

test('source Tutor ASR language and vocabulary context survive the authenticated offer',()=>{
 const source={...data,session:{...data.session,audio:{...data.session.audio,input:{...data.session.audio.input,transcription:{model:'arbitrary',language:'es',prompt:'Spanish lesson; English questions. Current phrase: hola.',extra:'ignored'}}}}};
 const input=realtimeOffer(source,env).session.audio.input;
 assert.deepEqual(input.transcription,{model:'gpt-4o-mini-transcribe',language:'es',prompt:'Spanish lesson; English questions. Current phrase: hola.'});
 assert.equal(input.turn_detection.create_response,false);
 for(const hint of [{language:'es-ES'},{language:['es']},{prompt:'x'.repeat(4097)},{prompt:{bad:true}}])assert.throws(()=>realtimeOffer({...source,session:{...source.session,audio:{...source.session.audio,input:{...source.session.audio.input,transcription:hint}}}},env));
});
