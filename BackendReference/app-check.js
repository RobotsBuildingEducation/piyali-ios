// Integration reference for the separately managed existing Cloudflare worker.
import { createRemoteJWKSet, jwtVerify } from 'jose';
const firebaseKeys = createRemoteJWKSet(new URL('https://firebaseappcheck.googleapis.com/v1/jwks'), { cacheMaxAge: 21600000, timeoutDuration: 5000 });
export async function verifyAppCheck(token, env, keys = firebaseKeys) {
  const allowed = new Set([env.FIREBASE_APP_ID, ...(env.FIREBASE_APP_IDS || '').split(',')].map(id => (id || '').trim()).filter(Boolean));
  if (!env.FIREBASE_PROJECT_NUMBER || !allowed.size) throw new Error('App Check is not configured.');
  const { payload, protectedHeader } = await jwtVerify(token, keys, {
    algorithms: ['RS256'],
    issuer: `https://firebaseappcheck.googleapis.com/${env.FIREBASE_PROJECT_NUMBER}`,
    audience: `projects/${env.FIREBASE_PROJECT_NUMBER}`,
    requiredClaims: ['exp','iat','sub'],
  });
  if (protectedHeader.typ !== 'JWT' || !allowed.has(payload.sub)) throw new Error('Invalid App Check token.');
  return payload;
}
