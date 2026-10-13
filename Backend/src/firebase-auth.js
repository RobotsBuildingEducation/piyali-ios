import { createRemoteJWKSet, jwtVerify } from 'jose';
import { HTTPError,publicIdentity } from './auth.js';
const keys=createRemoteJWKSet(new URL('https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com'));
export async function verifyFirebaseAuth(request,env) {
  const header=request.headers.get('Authorization') ?? '';
  if(!header.startsWith('Bearer ') || header.length>8192) throw new HTTPError(401,'Sign in to Piyali first.');
  try {
    const {payload}=await jwtVerify(header.slice(7),keys,{algorithms:['RS256'],issuer:`https://securetoken.google.com/${env.FIREBASE_PROJECT_ID}`,audience:env.FIREBASE_PROJECT_ID,requiredClaims:['exp','iat','sub']});
    if(payload.firebase?.sign_in_provider!=='custom' || publicIdentity(payload.sub)!==payload.nostr_pubkey) throw Error();
    return payload.sub;
  } catch { throw new HTTPError(401,'Your Piyali sign-in expired. Sign in again.'); }
}
