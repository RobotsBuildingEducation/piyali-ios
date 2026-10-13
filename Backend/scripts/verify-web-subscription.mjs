// Checks the existing external web payment service without changing its deployment.
import {generateSecretKey,getPublicKey,nip19,finalizeEvent} from 'nostr-tools';
import assert from 'node:assert/strict';
const base='https://piyali.app/api/patreon/',secret=generateSecretKey(),npub=nip19.npubEncode(getPublicKey(secret));
async function post(path,body) {
 const r=await fetch(base+path,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(body)});
 return {status:r.status,body:await r.json()};
}
const challenge=await post('link-challenge',{npub,action:'restore'});
assert.equal(challenge.status,200);assert.equal(challenge.body.eventTemplate.kind,27235);
assert.equal(challenge.body.eventTemplate.tags[0][1],'restore');
const signedEvent=finalizeEvent({...challenge.body.eventTemplate},secret);
const result=await post('key-status',{challengeId:challenge.body.challengeId,signedEvent});
assert.equal(result.status,200);assert.equal(result.body.authorized,false,'An unlinked account must remain paywalled');
const replay=await post('key-status',{challengeId:challenge.body.challengeId,signedEvent});
assert.equal(replay.status,401);
console.log('LIVE WEB PAYWALL PASS: signed restore works, unlinked key denied access, replay denied. No paid subscription or linking was created.');
