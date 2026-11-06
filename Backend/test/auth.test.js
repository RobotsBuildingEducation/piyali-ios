import test from 'node:test';
import assert from 'node:assert/strict';
import { generateSecretKey, getPublicKey, finalizeEvent, nip19 } from 'nostr-tools';
import { generateKeyPair, exportPKCS8, jwtVerify } from 'jose';
import { challengeFor,verifyChallenge,customToken,landingDemoToken,LANDING_DEMO_UID } from '../src/auth.js';
import { handler,SignInChallenge } from '../src/index.js';
const privateKey=generateSecretKey(),pubkey=getPublicKey(privateKey),npub=nip19.npubEncode(pubkey),now=Date.now();
const record=challengeFor(npub,'https://piyali.test/auth/sign-in','nonce',now);
test('signed HTTP-bound challenge proves the exact npub',()=>{
  const event=finalizeEvent(record.event,privateKey);
  assert.equal(verifyChallenge(record,event,now),npub);
});
test('tampered, wrong-key, wrong-route and expired challenges fail',()=>{
  const good=finalizeEvent(record.event,privateKey);
  for(const event of [{...good,sig:'0'.repeat(128)},finalizeEvent(record.event,generateSecretKey()),finalizeEvent({...record.event,tags:[['u','https://evil.test']]},privateKey)]) assert.throws(()=>verifyChallenge(record,event,now));
  assert.throws(()=>verifyChallenge(record,good,record.expiresAt));
});
test('custom token has the bound UID and Firebase audience',async()=>{
  const keys=await generateKeyPair('RS256',{extractable:true});
  const email='piyali-auth@piyali-ios.iam.gserviceaccount.com';
  const token=await customToken(npub,{FIREBASE_PROJECT_ID:'piyali-ios',FIREBASE_CLIENT_EMAIL:email,FIREBASE_PRIVATE_KEY:await exportPKCS8(keys.privateKey)},now);
  const {payload}=await jwtVerify(token,keys.publicKey,{issuer:email,audience:'https://identitytoolkit.googleapis.com/google.identity.identitytoolkit.v1.IdentityToolkit'});
  assert.equal(payload.uid,npub); assert.equal(payload.claims.nostr_pubkey,pubkey); assert.equal(payload.exp-payload.iat,3600);
});
test('public lesson token has a fixed service UID, no Nostr rights and a five-minute exchange window',async()=>{
  const keys=await generateKeyPair('RS256',{extractable:true});
  const email='piyali-auth@piyali-ios.iam.gserviceaccount.com';
  const env={FIREBASE_PROJECT_ID:'piyali-ios',FIREBASE_CLIENT_EMAIL:email,FIREBASE_PRIVATE_KEY:await exportPKCS8(keys.privateKey),DEMO_RATE_LIMITER:{limit:async()=>({success:true})}};
  const token=await landingDemoToken(env,now);
  const {payload}=await jwtVerify(token,keys.publicKey,{issuer:email,audience:'https://identitytoolkit.googleapis.com/google.identity.identitytoolkit.v1.IdentityToolkit'});
  assert.equal(payload.uid,LANDING_DEMO_UID);assert.equal(payload.claims.piyali_public_demo,true);assert.equal(payload.claims.nostr_pubkey,undefined);assert.equal(payload.exp-payload.iat,300);
  const request=data=>new Request('https://piyali.test/auth/landing-demo',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(data)});
  const worker=handler(async()=>{});
  assert.equal((await worker.fetch(request({uid:npub}),env)).status,400);
  assert.equal((await worker.fetch(request({}),env)).status,200);
  env.DEMO_RATE_LIMITER.limit=async()=>({success:false});assert.equal((await worker.fetch(request({}),env)).status,429);
  assert.equal((await handler(async()=>{throw Error();}).fetch(request({}),env)).status,401);
});
function storage() {
  const values=new Map(); let queue=Promise.resolve();
  const store={get:async k=>values.get(k),put:async(k,v)=>values.set(k,v),delete:async k=>values.delete(k),setAlarm:async()=>{},deleteAll:async()=>values.clear()};
  store.transaction=fn=>{ const next=queue.then(()=>fn(store)); queue=next.catch(()=>{}); return next; }; return store;
}
test('a challenge is consumed atomically and cannot be replayed',async()=>{
  const store=storage(),object=new SignInChallenge({storage:store});
  await store.put('challenge',record);
  const request=()=>new Request('https://challenge.internal/consume',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({event:finalizeEvent(record.event,privateKey)})});
  const results=await Promise.all([object.fetch(request()),object.fetch(request())]);
  assert.deepEqual(results.map(r=>r.status).sort(),[200,401]);
});
test('public worker rejects missing App Check and disallowed methods',async()=>{
  const worker=handler(async()=>{throw Error('invalid');});
  assert.equal((await worker.fetch(new Request('https://piyali.test/auth/challenge',{method:'POST'}),{})).status,401);
  assert.equal((await worker.fetch(new Request('https://piyali.test/auth/challenge'),{})).status,405);
  assert.equal((await worker.fetch(new Request('https://piyali.test/other'),{})).status,404);
});
test('worker refuses over-limit and oversized bodies before issuing a challenge',async()=>{
  const worker=handler(async()=>{}),base={AUTH_RATE_LIMITER:{limit:async()=>({success:false})},SIGN_IN_CHALLENGES:{}};
  const req=text=>new Request('https://piyali.test/auth/challenge',{method:'POST',headers:{'Content-Type':'application/json'},body:text});
  assert.equal((await worker.fetch(req('{}'),base)).status,429);
  base.AUTH_RATE_LIMITER.limit=async()=>({success:true});
  assert.equal((await worker.fetch(req('x'.repeat(9000)),base)).status,413);
});
