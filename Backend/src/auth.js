import { verifyEvent, nip19 } from 'nostr-tools';
import { importPKCS8, SignJWT } from 'jose';
export const AUTH_KIND = 27235;
export const AUTH_CONTENT = 'Piyali Firebase sign-in';
export const CHALLENGE_SECONDS = 120;
export class HTTPError extends Error {
  constructor(status, message) { super(message); this.status = status; }
}
export function publicIdentity(npub) {
  try {
    const decoded = nip19.decode(npub);
    if (decoded.type !== 'npub' || nip19.npubEncode(decoded.data) !== npub) throw Error();
    return decoded.data;
  } catch { throw new HTTPError(400,'A valid npub is required.'); }
}
export function challengeFor(npub, url, nonce, now = Date.now()) {
  return { npub, pubkey:publicIdentity(npub), expiresAt:now + CHALLENGE_SECONDS*1000,
    event:{ created_at:Math.floor(now/1000),kind:AUTH_KIND,tags:[['u',url],['method','POST'],['challenge',nonce]],content:AUTH_CONTENT } };
}
export function verifyChallenge(record, event, now = Date.now()) {
  if (!record || record.expiresAt <= now || !event || event.pubkey !== record.pubkey ||
      event.created_at !== record.event.created_at || event.kind !== AUTH_KIND || event.content !== AUTH_CONTENT ||
      JSON.stringify(event.tags) !== JSON.stringify(record.event.tags) || !verifyEvent({id:event.id,pubkey:event.pubkey,created_at:event.created_at,kind:event.kind,tags:event.tags,content:event.content,sig:event.sig})) {
    throw new HTTPError(401,'Sign-in proof is invalid or expired.');
  }
  return record.npub;
}
let signingKey;
let signingPEM;
export async function customToken(npub, env, now = Date.now()) {
  return signedToken(npub,{nostr_pubkey:publicIdentity(npub)},env,now,3600);
}
export const LANDING_DEMO_UID = 'piyali-landing-demo';
export async function landingDemoToken(env,now = Date.now()) {
  // This service identity never has a Nostr claim. Existing Firestore and
  // Responses authorization reject it, including its own /users document.
  return signedToken(LANDING_DEMO_UID,{piyali_public_demo:true},env,now,300);
}
async function signedToken(uid,claims,env,now,lifetime) {
  if (!env.FIREBASE_CLIENT_EMAIL?.endsWith(`@${env.FIREBASE_PROJECT_ID}.iam.gserviceaccount.com`) || !env.FIREBASE_PRIVATE_KEY) {
    throw new HTTPError(503,'Firebase sign-in is not configured.');
  }
  if (signingPEM !== env.FIREBASE_PRIVATE_KEY) {
    signingPEM = env.FIREBASE_PRIVATE_KEY;
    signingKey = importPKCS8(signingPEM,'RS256');
  }
  return new SignJWT({uid,claims})
    .setProtectedHeader({alg:'RS256',typ:'JWT'})
    .setIssuer(env.FIREBASE_CLIENT_EMAIL).setSubject(env.FIREBASE_CLIENT_EMAIL)
    .setAudience('https://identitytoolkit.googleapis.com/google.identity.identitytoolkit.v1.IdentityToolkit')
    .setIssuedAt(Math.floor(now/1000)).setExpirationTime(Math.floor(now/1000)+lifetime)
    .sign(await signingKey);
}
