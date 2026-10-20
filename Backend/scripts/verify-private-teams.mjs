// Opt-in deployed-rule check. Only disposable identities and a unique private fixture are used.
import fs from 'node:fs';
import {execFileSync} from 'node:child_process';
import assert from 'node:assert/strict';
import {generateSecretKey,getPublicKey,finalizeEvent,nip19} from 'nostr-tools';
assert.equal(process.env.PIYALI_LIVE_PRIVATE_TEAMS,'1','Explicit live private-team opt-in is required.');
const root=new URL('../../',import.meta.url),config=JSON.parse(execFileSync('plutil',['-convert','json','-o','-',new URL('Piyali/Resources/GoogleService-Info.plist',root).pathname],{encoding:'utf8'}));
assert.equal(config.PROJECT_ID,'piyali-ios');
const debug=JSON.parse(fs.readFileSync(new URL('.secrets/app-check-debug.json',root)));
async function request(url,method='GET',body,headers={}) {
  const response=await fetch(url,{method,headers:{'Content-Type':'application/json',...headers},...(body===undefined?{}:{body:JSON.stringify(body)}),signal:AbortSignal.timeout(30000)});
  const value=await response.json();return {status:response.status,value};
}
const appcheck=await request(`https://firebaseappcheck.googleapis.com/v1/projects/861709486546/apps/${config.GOOGLE_APP_ID}:exchangeDebugToken?key=${config.API_KEY}`,'POST',{debugToken:debug.token});
assert.equal(appcheck.status,200,'App Check exchange');
const appHeaders={'X-Firebase-AppCheck':appcheck.value.token},actors=[];
async function signIn() {
  const secret=generateSecretKey(),npub=nip19.npubEncode(getPublicKey(secret)),base='https://piyali-ios-api.robotsbuildingeducation.workers.dev';
  const challenge=await request(base+'/auth/challenge','POST',{npub},appHeaders);assert.equal(challenge.status,200,'Isolated challenge');
  const signed=await request(base+'/auth/sign-in','POST',{challengeId:challenge.value.challengeId,event:finalizeEvent(challenge.value.event,secret)},appHeaders);assert.equal(signed.status,200,'Isolated sign-in');
  const auth=await request(`https://identitytoolkit.googleapis.com/v1/accounts:signInWithCustomToken?key=${config.API_KEY}`,'POST',{token:signed.value.token,returnSecureToken:true});assert.equal(auth.status,200,'Isolated Firebase identity');
  const actor={npub,token:auth.value.idToken};actors.push(actor);return actor;
}
const database='projects/piyali-ios/databases/(default)',base='https://firestore.googleapis.com/v1/'+database,teamId='native-verification-'+crypto.randomUUID();
const fields=value=>Object.fromEntries(Object.entries(value).map(([key,item])=>[key,encode(item)]));
function encode(value) {
  if(value===null) return {nullValue:null};if(typeof value==='string') return {stringValue:value};if(typeof value==='boolean') return {booleanValue:value};
  if(typeof value==='number') return Number.isInteger(value)?{integerValue:String(value)}:{doubleValue:value};
  if(Array.isArray(value)) return {arrayValue:{values:value.map(encode)}};return {mapValue:{fields:fields(value)}};
}
const headers=actor=>({...appHeaders,Authorization:'Bearer '+actor.token});
const write=(path,data)=>({update:{name:database+'/documents/'+path,fields:fields(data)}}),remove=path=>({delete:database+'/documents/'+path});
const commit=(actor,writes)=>request(base+'/documents:commit','POST',{writes},headers(actor));
const read=(actor,path)=>request(base+'/documents/'+path,'GET',undefined,headers(actor));
let owner,member,teamPath,invitePath;
try {
  owner=await signIn();member=await signIn();const outside=await signIn();
  teamPath=`users/${owner.npub}/teams/${teamId}`;invitePath=`users/${member.npub}/teamInvites/team_${teamId}`;
  const entry={npub:member.npub,status:'pending',name:'Verification member',addedAt:new Date().toISOString()};
  const team={teamName:'Native private-team verification',createdBy:owner.npub,creatorName:'Verification creator',createdAt:entry.addedAt,members:[entry]};
  const invite={teamId,teamName:team.teamName,creatorNpub:owner.npub,invitedBy:owner.npub,invitedByName:team.creatorName,status:'pending',createdAt:entry.addedAt,member:entry};
  assert.equal((await commit(owner,[write(teamPath,team),write(invitePath,invite)])).status,200,'Creator atomically creates a private team and invitation');
  assert.equal((await read(member,teamPath)).status,200,'Invited member reads roster');assert.equal((await read(outside,teamPath)).status,403,'Outside learner cannot read roster');
  const summary={schemaVersion:2,name:'Verification creator',xp:0};
  assert.equal((await commit(owner,[write(teamPath+'/progress/'+owner.npub,summary)])).status,200,'Creator shares a limited snapshot');
  assert.equal((await read(member,teamPath+'/progress/'+owner.npub)).status,403,'Pending invitation cannot read progress');
  assert.equal((await commit(member,[write(invitePath,{...invite,status:'accepted'})])).status,403,'Invitation-only forged acceptance is rejected');
  const accepted={...entry,status:'accepted'},joined={...team,members:[accepted],_memberChange:{before:entry,after:accepted}};
  assert.equal((await commit(member,[write(teamPath,joined),write(invitePath,{...invite,status:'accepted'})])).status,200,'Caller-only roster acceptance and invitation commit together');
  assert.equal((await read(member,teamPath+'/progress/'+owner.npub)).status,200,'Accepted member reads shared progress');
  assert.equal((await read(member,'users/'+owner.npub)).status,403,'Membership cannot read a private learner document');
  assert.equal((await read(outside,teamPath+'/progress/'+owner.npub)).status,403,'Outside learner cannot read progress');
  assert.equal((await commit(member,[write(teamPath+'/progress/'+owner.npub,{...summary,xp:999})])).status,403,'A member cannot forge another snapshot');
  const departed={...joined,members:[],_memberChange:{before:accepted,after:null}};
  assert.equal((await commit(member,[write(teamPath,departed),remove(invitePath)])).status,200,'Departure removes only caller membership');
  assert.equal((await read(member,teamPath+'/progress/'+owner.npub)).status,403,'Departure revokes progress access');
  console.log('LIVE PRIVATE TEAMS PASS: native authentication/App Check, atomic invitations, accepted-only sharing, forgery denial, learner isolation and departure revocation.');
} finally {
  let cleanupError;
  try {
    if(owner && teamPath) {
      const writes=[remove(teamPath+'/progress/'+owner.npub),remove(teamPath)];
      if(member && (await read(owner,invitePath)).status===200) writes.unshift(remove(invitePath));
      assert.equal((await commit(owner,writes)).status,200,'Private verification documents removed');
      assert.equal((await read(owner,teamPath)).status,404,'Private verification team removed');
    }
  } catch(error) { cleanupError=error; }
  for(const actor of actors) {
    try { assert.equal((await request(`https://identitytoolkit.googleapis.com/v1/accounts:delete?key=${config.API_KEY}`,'POST',{idToken:actor.token})).status,200,'Disposable auth identity removed'); }
    catch(error) { cleanupError ??= error; }
  }
  if(cleanupError) throw cleanupError;
  console.log('LIVE PRIVATE TEAMS CLEANUP PASS: verification documents and all disposable auth identities removed; no learner root document or public Nostr event was written.');
}
