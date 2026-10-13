import { verifyFirebaseAuth } from './firebase-auth.js';
import { proxyResponses } from './responses.js';
import { verifyAppCheck } from './app-check.js';
import { HTTPError, publicIdentity, challengeFor, verifyChallenge, customToken } from './auth.js';
const json = (value,status=200) => new Response(JSON.stringify(value),{status,headers:{'Content-Type':'application/json','Cache-Control':'no-store'}});
async function body(request,limit=8192) {
  if (!request.headers.get('Content-Type')?.startsWith('application/json')) throw new HTTPError(415,'Send JSON.');
  const reader=request.body?.getReader();
  if(!reader) throw new HTTPError(400,'Send a request body.');
  const chunks=[]; let size=0;
  try {
    while(true) {
      const {done,value}=await reader.read(); if(done) break;
      size+=value.byteLength;
      if(size>limit) { await reader.cancel(); throw new HTTPError(413,'Request is too large.'); }
      chunks.push(value);
    }
  } finally { reader.releaseLock(); }
  const bytes=new Uint8Array(size);let offset=0;
  for(const chunk of chunks) { bytes.set(chunk,offset);offset+=chunk.byteLength; }
  const text=new TextDecoder().decode(bytes);
  try {
    const value = JSON.parse(text);
    if (!value || typeof value !== 'object' || Array.isArray(value)) throw Error();
    return value;
  } catch { throw new HTTPError(400,'Invalid JSON.'); }
}
export class SignInChallenge {
  constructor(ctx) { this.ctx = ctx; }
  async fetch(request) {
    try {
      const data = await body(request);
      if (new URL(request.url).pathname === '/issue') {
        const record = challengeFor(data.npub,data.url,data.nonce);
        await this.ctx.storage.put('challenge',record);
        await this.ctx.storage.setAlarm(record.expiresAt+1000);
        return json({challengeId:data.nonce,event:{...record.event,pubkey:record.pubkey},expiresAt:record.expiresAt});
      }
      if (new URL(request.url).pathname !== '/consume') throw new HTTPError(404,'Not found.');
      const npub = await this.ctx.storage.transaction(async store => {
        const record = await store.get('challenge');
        const npub = verifyChallenge(record,data.event);
        await store.delete('challenge');
        return npub;
      });
      return json({npub});
    } catch (error) { return json({error:error instanceof HTTPError ? error.message : 'Sign-in could not be completed.'},error.status ?? 500); }
  }
  async alarm() { await this.ctx.storage.deleteAll(); }
}
export function handler(check = verifyAppCheck, authenticate = verifyFirebaseAuth, fetchUpstream = fetch) {
  return {
    async fetch(request,env) {
      try {
        const url = new URL(request.url);
        if (url.pathname === '/health' && request.method === 'GET') return json({ok:true,project:env.FIREBASE_PROJECT_ID});
        if (!['/auth/challenge','/auth/sign-in','/proxyResponses'].includes(url.pathname)) throw new HTTPError(404,'Not found.');
        if (request.method !== 'POST') throw new HTTPError(405,'Use POST.');
        try { await check(request.headers.get('X-Firebase-AppCheck') ?? '',env); }
        catch { throw new HTTPError(401,'A valid Piyali App Check token is required.'); }
        if(url.pathname==='/proxyResponses') {
          const npub=await authenticate(request,env);
          if(!env.AI_RATE_LIMITER) throw new HTTPError(503,'The tutor is not configured.');
          const {success}=await env.AI_RATE_LIMITER.limit({key:npub});
          if(!success) throw new HTTPError(429,'Too many tutor requests. Try again shortly.');
          return proxyResponses(await body(request,131072),env,fetchUpstream);
        }
        if (!env.AUTH_RATE_LIMITER || !env.SIGN_IN_CHALLENGES) throw new HTTPError(503,'Sign-in is not configured.');
        const {success} = await env.AUTH_RATE_LIMITER.limit({key:request.headers.get('CF-Connecting-IP') ?? 'unknown'});
        if (!success) throw new HTTPError(429,'Too many sign-in attempts. Try again shortly.');
        const data = await body(request);
        if (url.pathname === '/auth/challenge') {
          publicIdentity(data.npub);
          const nonce = crypto.randomUUID();
          return env.SIGN_IN_CHALLENGES.get(env.SIGN_IN_CHALLENGES.idFromName(nonce)).fetch('https://challenge.internal/issue',{
            method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({npub:data.npub,nonce,url:new URL('/auth/sign-in',url).href})
          });
        }
        if (typeof data.challengeId !== 'string' || !/^[0-9a-f-]{36}$/.test(data.challengeId)) throw new HTTPError(400,'A valid challenge is required.');
        const result = await env.SIGN_IN_CHALLENGES.get(env.SIGN_IN_CHALLENGES.idFromName(data.challengeId)).fetch('https://challenge.internal/consume',{
          method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({event:data.event})
        });
        if (!result.ok) return result;
        const {npub} = await result.json();
        return json({npub,token:await customToken(npub,env)});
      } catch (error) { return json({error:error instanceof HTTPError ? error.message : 'Sign-in could not be completed.'},error.status ?? 500); }
    }
  };
}
export default handler();
