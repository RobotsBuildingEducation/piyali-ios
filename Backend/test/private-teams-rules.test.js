import test from 'node:test';
import fs from 'node:fs';
import {initializeTestEnvironment,assertSucceeds,assertFails} from '@firebase/rules-unit-testing';
import {doc,getDoc,setDoc,updateDoc,deleteDoc,writeBatch,collection,getDocs} from 'firebase/firestore';
import {generateSecretKey,getPublicKey,nip19} from 'nostr-tools';

test('private teams allow only creator edits, scoped member responses and accepted progress access',{skip:process.env.PIYALI_RULES_EMULATOR!=='1'},async()=>{
  const env=await initializeTestEnvironment({projectId:'demo-piyali-ios-auth',firestore:{host:'127.0.0.1',port:8280,rules:fs.readFileSync(new URL('../firestore.rules',import.meta.url),'utf8')}});
  const identity=()=>{const hex=getPublicKey(generateSecretKey()),id=nip19.npubEncode(hex);return {id,db:env.authenticatedContext(id,{nostr_pubkey:hex,firebase:{sign_in_provider:'custom'}}).firestore()};};
  const a=identity(),b=identity(),c=identity(),outside=identity(),guest=env.unauthenticatedContext().firestore(),id=crypto.randomUUID();
  const team=db=>doc(db,'users',a.id,'teams',id),invite=(db,member)=>doc(db,'users',member,'teamInvites','team_'+id),progress=(db,member)=>doc(db,'users',a.id,'teams',id,'progress',member);
  const bob={npub:b.id,status:'pending',name:'Bob',addedAt:'original',legacy:'retain'},carol={npub:c.id,status:'pending',name:'Carol',addedAt:'original'};
  const invitation=member=>({teamId:id,teamName:'Weekend',creatorNpub:a.id,invitedBy:a.id,invitedByName:'Ada',status:'pending',createdAt:'original',member});
  try {
    const batch=writeBatch(a.db);batch.set(team(a.db),{teamName:'Weekend',creatorName:'Ada',createdBy:a.id,createdAt:'original',members:[bob,carol]});batch.set(invite(a.db,b.id),invitation(bob));batch.set(invite(a.db,c.id),invitation(carol));await assertSucceeds(batch.commit());
    await assertSucceeds(getDoc(invite(b.db,b.id)));await assertSucceeds(getDoc(team(b.db)));await assertSucceeds(getDocs(collection(a.db,'users',a.id,'teams')));
    await assertFails(getDoc(team(outside.db)));await assertFails(getDoc(team(guest)));await assertFails(getDocs(collection(b.db,'users',a.id,'teams')));
    await assertFails(setDoc(invite(outside.db,outside.id),invitation({...bob,npub:outside.id})));
    await assertFails(updateDoc(invite(b.db,b.id),{creatorNpub:b.id}));await assertFails(updateDoc(invite(b.db,b.id),{status:'accepted'}));
    await assertFails(updateDoc(team(b.db),{teamName:'Taken over'}));await assertFails(updateDoc(team(b.db),{members:[bob],_memberChange:{before:carol,after:null}}));
    await assertFails(setDoc(progress(b.db,b.id),{schemaVersion:2,name:'Bob',xp:5}));
    await assertSucceeds(setDoc(progress(a.db,a.id),{schemaVersion:2,name:'Ada',xp:100}));await assertFails(getDoc(progress(b.db,a.id)));
    const accepted={...bob,status:'accepted'},accept=writeBatch(b.db);accept.update(team(b.db),{members:[carol,accepted],_memberChange:{before:bob,after:accepted}});accept.update(invite(b.db,b.id),{status:'accepted'});await assertSucceeds(accept.commit());
    await assertSucceeds(getDoc(progress(b.db,a.id)));await assertSucceeds(getDocs(collection(b.db,'users',a.id,'teams',id,'progress')));
    await assertSucceeds(setDoc(progress(b.db,b.id),{schemaVersion:2,name:'Bob',xp:5}));await assertFails(setDoc(progress(b.db,c.id),{schemaVersion:2,name:'forged',xp:999}));
    await assertFails(setDoc(progress(b.db,b.id),{schemaVersion:2,iosStateJSON:'private conversations'}));await assertFails(getDoc(doc(b.db,'users',a.id)));
    await assertFails(getDoc(progress(c.db,b.id)));await assertFails(getDoc(progress(outside.db,b.id)));await assertFails(getDoc(progress(guest,b.id)));
    await assertFails(updateDoc(team(b.db),{members:[{...carol,name:'forged'},accepted],_memberChange:{before:accepted,after:accepted}}));
    const renamed=writeBatch(a.db);renamed.update(team(a.db),{teamName:'Evening'});renamed.update(invite(a.db,b.id),{teamName:'Evening'});renamed.update(invite(a.db,c.id),{teamName:'Evening'});await assertSucceeds(renamed.commit());
    const decline=writeBatch(c.db);decline.update(team(c.db),{members:[accepted],_memberChange:{before:carol,after:null}});decline.update(invite(c.db,c.id),{status:'rejected'});await assertSucceeds(decline.commit());await assertFails(getDoc(team(c.db)));
    const leave=writeBatch(b.db);leave.update(team(b.db),{members:[],_memberChange:{before:accepted,after:null}});leave.delete(invite(b.db,b.id));leave.delete(progress(b.db,b.id));await assertSucceeds(leave.commit());
    await assertFails(getDoc(team(b.db)));await assertFails(getDoc(progress(b.db,a.id)));await assertFails(updateDoc(team(b.db),{members:[accepted],_memberChange:{before:accepted,after:accepted}}));
    await assertSucceeds(deleteDoc(team(a.db)));await assertFails(getDoc(progress(a.db,a.id)));
  } finally { await env.cleanup(); }
});
