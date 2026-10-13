import test from 'node:test';
import assert from 'node:assert/strict';
import { generateKeyPair, SignJWT } from 'jose';
import { verifyAppCheck } from './app-check.js';
const { publicKey, privateKey } = await generateKeyPair('RS256');
const env = { FIREBASE_PROJECT_NUMBER:'123',FIREBASE_APP_ID:'web-app',FIREBASE_APP_IDS:'ios-app' };
const token = (sub, overrides = {}) => new SignJWT({sub,...overrides})
 .setProtectedHeader({alg:'RS256',typ:'JWT'}).setIssuer('https://firebaseappcheck.googleapis.com/123').setAudience('projects/123').setIssuedAt().setExpirationTime('1h').sign(privateKey);
test('accepts configured web and native IDs',async()=>{ for(const id of ['web-app','ios-app']) assert.equal((await verifyAppCheck(await token(id),env,publicKey)).sub,id); });
test('rejects unrelated app ID',async()=>assert.rejects(verifyAppCheck(await token('another-app'),env,publicKey)));
test('rejects wrong audience',async()=>{ const t=await new SignJWT({sub:'ios-app'}).setProtectedHeader({alg:'RS256',typ:'JWT'}).setIssuer('https://firebaseappcheck.googleapis.com/123').setAudience('projects/999').setIssuedAt().setExpirationTime('1h').sign(privateKey); await assert.rejects(verifyAppCheck(t,env,publicKey)); });
test('rejects expired token',async()=>{ const t=await new SignJWT({sub:'ios-app'}).setProtectedHeader({alg:'RS256',typ:'JWT'}).setIssuer('https://firebaseappcheck.googleapis.com/123').setAudience('projects/123').setIssuedAt().setExpirationTime(Math.floor(Date.now()/1000)-5).sign(privateKey); await assert.rejects(verifyAppCheck(t,env,publicKey)); });
