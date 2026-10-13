import test from 'node:test';
import assert from 'node:assert/strict';
import {handler} from '../src/index.js';
import {responsesBody} from '../src/responses.js';
const env={FIREBASE_PROJECT_ID:'piyali-ios',OPENAI_API_KEY:'fixture-not-a-key',AI_RATE_LIMITER:{limit:async()=>({success:true})}};
const input={model:'gpt-6-luna',input:'Teach me hola.',store:true,tools:[{type:'web_search'}]};
const request=body=>new Request('https://piyali.test/proxyResponses',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(body)});
test('tutor strips arbitrary tools/storage overrides and enforces model/prompt/output limits',()=>{
 const body=responsesBody(input,env);assert.equal(body.store,false);assert.equal(body.tools,undefined);assert.equal(body.reasoning.effort,'none');
 for(const bad of [{...input,model:'unknown'},{...input,input:''},{...input,input:'x'.repeat(110001)},{...input,max_output_tokens:100000}]) assert.throws(()=>responsesBody(bad,env));
});
test('tutor requires App Check and native Firebase ownership before upstream calls',async()=>{
 let calls=0;const fetcher=async()=>{calls++;return Response.json({output:[]});};
 const checkDenied=handler(async()=>{throw Error();},async()=> 'npub',fetcher);
 assert.equal((await checkDenied.fetch(request(input),env)).status,401);
 const authDenied=handler(async()=>{},async()=>{const e=new Error();e.status=401;throw e;},fetcher);
 assert.equal((await authDenied.fetch(request(input),env)).status,401);assert.equal(calls,0);
});
test('authorized tutor forwards only bounded text requests to the official Responses endpoint',async()=>{
 let sent;
 const worker=handler(async()=>{},async()=> 'npub',async(url,options)=>{assert.equal(url,'https://api.openai.com/v1/responses');sent=JSON.parse(options.body);return Response.json({output:[{content:[{type:'output_text',text:'Hola means hello.'}]}]});});
 const response=await worker.fetch(request(input),env);assert.equal(response.status,200);assert.equal(sent.input,input.input);assert.equal(sent.store,false);
 const limited={...env,AI_RATE_LIMITER:{limit:async()=>({success:false})}};
 assert.equal((await worker.fetch(request(input),limited)).status,429);
});
