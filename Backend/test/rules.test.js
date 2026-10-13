import test from 'node:test';
import fs from 'node:fs';
import { initializeTestEnvironment, assertSucceeds, assertFails } from '@firebase/rules-unit-testing';
import { doc,getDoc,setDoc,collection,getDocs } from 'firebase/firestore';
import { generateSecretKey,getPublicKey,nip19 } from 'nostr-tools';
test('production rules isolate Nostr-authenticated learners and protect subscription fields',{skip:process.env.PIYALI_RULES_EMULATOR!=='1'},async()=>{
  const hex=getPublicKey(generateSecretKey()),npub=nip19.npubEncode(hex),other=nip19.npubEncode(getPublicKey(generateSecretKey()));
  const env=await initializeTestEnvironment({projectId:'demo-piyali-ios-auth',firestore:{host:'127.0.0.1',port:8280,rules:fs.readFileSync(new URL('../firestore.rules',import.meta.url),'utf8')}});
  try {
    const db=env.authenticatedContext(npub,{nostr_pubkey:hex,firebase:{sign_in_provider:'custom'}}).firestore();
    const guest=env.unauthenticatedContext().firestore();
    const anonymous=env.authenticatedContext(npub,{firebase:{sign_in_provider:'anonymous'}}).firestore();
    await assertSucceeds(setDoc(doc(db,'users',npub),{local_npub:npub,displayName:'Learner'}));
    await assertSucceeds(setDoc(doc(db,'users',npub,'companion','es'),{notes:[]}));
    await assertSucceeds(getDoc(doc(db,'users',npub)));
    await assertFails(getDoc(doc(guest,'users',npub)));
    await assertFails(getDoc(doc(anonymous,'users',npub)));
    await assertFails(getDoc(doc(db,'users',other)));
    await assertFails(setDoc(doc(db,'users',other,'companion','es'),{notes:[]}));
    await assertFails(setDoc(doc(db,'users',npub),{local_npub:other}));
    await assertFails(setDoc(doc(db,'users',npub),{patreonVerified:true},{merge:true}));
    await assertFails(setDoc(doc(db,'users',npub,'entitlements','paid'),{active:true}));
    await assertFails(getDocs(collection(db,'users')));
  } finally { await env.cleanup(); }
});
