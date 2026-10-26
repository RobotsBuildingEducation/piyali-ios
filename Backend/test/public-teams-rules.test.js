import test from 'node:test';
import fs from 'node:fs';
import {initializeTestEnvironment,assertSucceeds,assertFails} from '@firebase/rules-unit-testing';
import {doc,getDoc,setDoc,updateDoc,writeBatch,collection,query,where,documentId,limit,getDocs} from 'firebase/firestore';
import {generateSecretKey,getPublicKey,nip19} from 'nostr-tools';

test('public roster mirrors require the creator and exact accepted invitation membership',{skip:process.env.PIYALI_RULES_EMULATOR!=='1'},async()=>{
 const env=await initializeTestEnvironment({projectId:'demo-piyali-ios-auth',firestore:{host:'127.0.0.1',port:8280,rules:fs.readFileSync(new URL('../firestore.rules',import.meta.url),'utf8')}});
 const identity=()=>{const hex=getPublicKey(generateSecretKey()),id=nip19.npubEncode(hex);return{id,db:env.authenticatedContext(id,{nostr_pubkey:hex,firebase:{sign_in_provider:'custom'}}).firestore()}};
 const a=identity(),b=identity(),c=identity(),id=crypto.randomUUID(),stamp='2026-10-25T12:00:00.000Z',nostr={id,identifier:'learning-team:'+id,relays:['wss://nos.lol']},member={npub:b.id,status:'accepted',addedAt:stamp,name:''};
 const roster={teamName:'Weekend',creatorName:'Ada',createdBy:a.id,createdAt:stamp,nostr,members:[member]},invitation={teamId:id,teamName:'Weekend',creatorNpub:a.id,invitedBy:a.id,invitedByName:'Ada',nostr,status:'accepted',createdAt:stamp};
 const team=db=>doc(db,'users',a.id,'teams',id),invite=(db,who)=>doc(db,'users',who,'teamInvites','team_'+id);
 try{
  await assertFails(setDoc(team(b.db),roster));await assertFails(setDoc(invite(a.db,c.id),invitation));
  const created=writeBatch(a.db);created.set(team(a.db),roster);created.set(invite(a.db,b.id),invitation);await assertSucceeds(created.commit());
  await assertSucceeds(getDoc(team(b.db)));
  const one=db=>query(collection(db,'users',a.id,'teams'),where(documentId(),'==',id),where('members','array-contains',member),limit(1));
  await assertSucceeds(getDocs(one(b.db)));await assertFails(getDocs(one(c.db)));await assertFails(getDocs(query(collection(b.db,'users',a.id,'teams'),limit(1))));await assertFails(getDocs(query(collection(b.db,'users',a.id,'teams'),where(documentId(),'==',id))));
  await assertFails(getDoc(team(c.db)));await assertFails(getDoc(doc(b.db,'users',a.id)));
  await assertFails(setDoc(invite(a.db,c.id),invitation));await assertFails(updateDoc(team(b.db),{teamName:'forged'}));
  await assertFails(updateDoc(team(a.db),{nostr:{...nostr,id:'wrong'}}));
  const renamed=writeBatch(a.db);renamed.update(team(a.db),{teamName:'Evening'});renamed.update(invite(a.db,b.id),{teamName:'Evening'});await assertSucceeds(renamed.commit());
  const added={npub:c.id,status:'accepted',addedAt:stamp,name:''},addition=writeBatch(a.db);addition.update(team(a.db),{members:[member,added]});addition.set(invite(a.db,c.id),{...invitation,teamName:'Evening'});await assertSucceeds(addition.commit());await assertSucceeds(getDoc(team(c.db)));
  const forgery=writeBatch(b.db);forgery.update(team(b.db),{members:[member],_memberChange:{before:added,after:null}});forgery.delete(invite(b.db,b.id));await assertFails(forgery.commit());
  const departure=writeBatch(b.db);departure.update(team(b.db),{members:[added],_memberChange:{before:member,after:null}});departure.delete(invite(b.db,b.id));await assertSucceeds(departure.commit());await assertFails(getDoc(team(b.db)));
  const deleted=writeBatch(a.db);deleted.delete(team(a.db));deleted.delete(invite(a.db,c.id));await assertSucceeds(deleted.commit());await assertFails(getDoc(team(c.db)));
 }finally{await env.cleanup()}
});

test('existing public pending invitations can accept only their own roster entry',{skip:process.env.PIYALI_RULES_EMULATOR!=='1'},async()=>{
 const env=await initializeTestEnvironment({projectId:'demo-piyali-ios-auth',firestore:{host:'127.0.0.1',port:8280,rules:fs.readFileSync(new URL('../firestore.rules',import.meta.url),'utf8')}});
 const hex=getPublicKey(generateSecretKey()),member=nip19.npubEncode(hex),creator=nip19.npubEncode(getPublicKey(generateSecretKey())),id=crypto.randomUUID(),stamp='2026-10-25T12:00:00.000Z',nostr={id,identifier:'learning-team:'+id,relays:['wss://nos.lol']},before={npub:member,status:'pending',addedAt:stamp,name:''},after={...before,status:'accepted'};
 const db=env.authenticatedContext(member,{nostr_pubkey:hex,firebase:{sign_in_provider:'custom'}}).firestore(),team=doc(db,'users',creator,'teams',id),invite=doc(db,'users',member,'teamInvites','team_'+id);
 try{
  await env.withSecurityRulesDisabled(async context=>{const admin=context.firestore();await setDoc(doc(admin,team.path),{teamName:'Legacy public',createdBy:creator,createdAt:stamp,nostr,members:[before]});await setDoc(doc(admin,invite.path),{teamId:id,teamName:'Legacy public',creatorNpub:creator,invitedBy:creator,nostr,status:'pending',createdAt:stamp})});
  const accepted=writeBatch(db);accepted.update(team,{members:[after],_memberChange:{before,after}});accepted.update(invite,{status:'accepted'});await assertSucceeds(accepted.commit());
  const rejected=writeBatch(db);rejected.update(team,{members:[],_memberChange:{before:after,after:null}});rejected.update(invite,{status:'rejected'});await assertSucceeds(rejected.commit());await assertFails(getDoc(team));
 }finally{await env.cleanup()}
});
