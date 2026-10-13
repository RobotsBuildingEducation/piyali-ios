import test from 'node:test';
import assert from 'node:assert/strict';
import {verifyFirebaseAuth} from '../src/firebase-auth.js';
import {generateSecretKey,getPublicKey,nip19} from 'nostr-tools';
test('Firebase sign-in verifier rejects missing credentials and unsigned owner claims',async()=>{
 const pubkey=getPublicKey(generateSecretKey()),npub=nip19.npubEncode(pubkey);
 const claims={sub:npub,nostr_pubkey:pubkey,aud:'piyali-ios',iss:'https://securetoken.google.com/piyali-ios',iat:Math.floor(Date.now()/1000),exp:Math.floor(Date.now()/1000)+3600,firebase:{sign_in_provider:'custom'}};
 const token=Buffer.from(JSON.stringify({alg:'none'})).toString('base64url')+'.'+Buffer.from(JSON.stringify(claims)).toString('base64url')+'.';
 for(const header of ['', 'Bearer malformed', 'Bearer '+token]) {
  const request=new Request('https://piyali.test/proxyResponses',{headers:{Authorization:header}});
  await assert.rejects(verifyFirebaseAuth(request,{FIREBASE_PROJECT_ID:'piyali-ios'}),error=>error.status===401);
 }
});
