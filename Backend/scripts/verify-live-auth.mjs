// Opt-in integration check against the dedicated Piyali development project.
// Uses an ephemeral Nostr identity; removes its auth fixture and never prints credentials.
import fs from 'node:fs';
import {execFileSync} from 'node:child_process';
import {generateSecretKey,getPublicKey,finalizeEvent,nip19} from 'nostr-tools';
import assert from 'node:assert/strict';
const root=new URL('../../',import.meta.url);
const config=JSON.parse(execFileSync('plutil',['-convert','json','-o','-',new URL('Piyali/Resources/GoogleService-Info.plist',root).pathname],{encoding:'utf8'}));
assert.equal(config.PROJECT_ID,'piyali-ios');
const debug=JSON.parse(fs.readFileSync(new URL('.secrets/app-check-debug.json',root)));
const base='https://piyali-ios-api.robotsbuildingeducation.workers.dev';
async function json(url,body,headers={}) {
  const response=await fetch(url,{method:'POST',headers:{'Content-Type':'application/json',...headers},body:JSON.stringify(body)});
  const value=await response.json(); return {response,value};
}
const appcheck=await json(`https://firebaseappcheck.googleapis.com/v1/projects/861709486546/apps/${config.GOOGLE_APP_ID}:exchangeDebugToken?key=${config.API_KEY}`,{debugToken:debug.token});
if (!appcheck.response.ok) console.error('App Check:', appcheck.value.error?.message);
assert.equal(appcheck.response.status,200,'App Check debug exchange');
const headers={'X-Firebase-AppCheck':appcheck.value.token};
assert.equal((await json(base+'/auth/challenge',{npub:'invalid'})).response.status,401);
const secret=generateSecretKey(),npub=nip19.npubEncode(getPublicKey(secret));
const challenge=await json(base+'/auth/challenge',{npub},headers);
assert.equal(challenge.response.status,200,'Challenge issue');
const {challengeId,event}=challenge.value;
const signed=finalizeEvent({...event},secret);
const wrong=await json(base+'/auth/sign-in',{challengeId,event:finalizeEvent({...event},generateSecretKey())},headers);
assert.equal(wrong.response.status,401,'Wrong key rejected');
const signIn=await json(base+'/auth/sign-in',{challengeId,event:signed},headers);
if (!signIn.response.ok) console.error('Sign-in:', signIn.value.error);
assert.equal(signIn.response.status,200,'Signed challenge consumed');
assert.equal(signIn.value.npub,npub);
assert.equal((await json(base+'/auth/sign-in',{challengeId,event:signed},headers)).response.status,401,'Replay rejected');
const firebase=await json(`https://identitytoolkit.googleapis.com/v1/accounts:signInWithCustomToken?key=${config.API_KEY}`,{token:signIn.value.token,returnSecureToken:true});
assert.equal(firebase.response.status,200,'Firebase custom authentication');
const token=firebase.value.idToken;
const claims=JSON.parse(Buffer.from(token.split('.')[1],'base64url'));
assert.equal(claims.user_id,npub); assert.equal(claims.nostr_pubkey,getPublicKey(secret));
const authHeaders={Authorization:'Bearer '+token,'Content-Type':'application/json'};
const docs='https://firestore.googleapis.com/v1/projects/piyali-ios/databases/(default)/documents/users/';
const own=docs+npub;
try {
  const write=await fetch(own,{method:'PATCH',headers:authHeaders,body:JSON.stringify({fields:{local_npub:{stringValue:npub},integrationFixture:{booleanValue:true}}})});
  assert.equal(write.status,200,'Own progress write');
  assert.equal((await fetch(own,{headers:authHeaders})).status,200,'Own progress read');
  const other=docs+nip19.npubEncode(getPublicKey(generateSecretKey()));
  assert.equal((await fetch(other,{headers:authHeaders})).status,403,'Other learner read denied');
  const protectedWrite=await fetch(own+'?updateMask.fieldPaths=patreonVerified',{method:'PATCH',headers:authHeaders,body:JSON.stringify({fields:{patreonVerified:{booleanValue:true}}})});
  assert.equal(protectedWrite.status,403,'Client entitlement forgery denied');
  if(process.env.PIYALI_LIVE_AI==='1') {
    const missing=await json(base+'/proxyResponses',{model:'gpt-6-luna',input:'Hello'},headers);
    assert.equal(missing.response.status,401,'Tutor rejects missing Firebase identity');
    const parts=token.split('.'),forgedClaims=JSON.parse(Buffer.from(parts[1],'base64url')); forgedClaims.sub=nip19.npubEncode(getPublicKey(generateSecretKey()));
    const forged=[parts[0],Buffer.from(JSON.stringify(forgedClaims)).toString('base64url'),parts[2]].join('.');
    const denied=await json(base+'/proxyResponses',{model:'gpt-6-luna',input:'Hello'},{...headers,Authorization:'Bearer '+forged});
    assert.equal(denied.response.status,401,'Tutor rejects forged Firebase owner claims');
    const tutor=await json(base+'/proxyResponses' ,{model:'gpt-6-luna',input:'Return JSON with passage, question, choices, answer, explanation for one Pre-A1 Spanish greeting exercise with English instructions. Keep it short.',text:{format:{type:'json_object'}},max_output_tokens:512},{...headers,Authorization:'Bearer '+token});
    if(!tutor.response.ok) console.error('Tutor status:',tutor.response.status,tutor.value.error);
    assert.equal(tutor.response.status,200,'Live tutor response');
    const output=tutor.value.output?.flatMap(item=>item.content ?? []).filter(item=>item.type==='output_text').map(item=>item.text).join('');
    const exercise=JSON.parse(output);
    for(const key of ['passage','question','answer','explanation']) assert.equal(typeof exercise[key],'string');
    assert.ok(Array.isArray(exercise.choices));
    console.log('LIVE AI PASS: authenticated tutor generated a valid Spanish exercise JSON.');
  }
  console.log('LIVE PASS: App Check, Nostr signature, replay defense, Firebase custom sign-in, own progress and cross-account/subscription isolation.');
} finally {
  // These fixtures belong exclusively to this ephemeral check, never a learner account.
  // Root deletion is denied to clients; the small progress fixture is retained for admin cleanup.
  const removed=await json(`https://identitytoolkit.googleapis.com/v1/accounts:delete?key=${config.API_KEY}`,{idToken:token});
  assert.equal(removed.response.status,200,'Ephemeral auth fixture removed');
}
