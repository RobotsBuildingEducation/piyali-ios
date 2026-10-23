import { HTTPError } from './auth.js';

const voices = new Set(['alloy','ash','ballad','coral','echo','sage','shimmer','verse','marin','cedar']);
// Match the reference app's Realtime model. Keys and arbitrary tool definitions
// never cross this authenticated SDP endpoint.
export function realtimeOffer(data, env) {
  if (typeof data.sdp !== 'string' || data.sdp.length > 65536 || !/^v=0\r?\n/.test(data.sdp) || !/^m=audio /m.test(data.sdp)) throw new HTTPError(400,'A valid audio offer is required.');
  const value=data.session;
  if (!value || typeof value !== 'object' || Array.isArray(value) || value.type !== 'realtime') throw new HTTPError(400,'A Realtime session is required.');
  const model=env.REALTIME_MODEL || 'gpt-realtime-2.1-mini';
  if (value.model !== model) throw new HTTPError(400,'Unsupported voice model.');
  if (typeof value.instructions !== 'string' || !value.instructions.trim() || value.instructions.length > 30000) throw new HTTPError(400,'Voice instructions are required.');
  const voice=value.audio?.output?.voice ?? 'ash';
  if (!voices.has(voice)) throw new HTTPError(400,'Unsupported voice.');
  const vad=value.audio?.input?.turn_detection;
  if (!vad || vad.type !== 'server_vad' || !Number.isFinite(vad.silence_duration_ms) || vad.silence_duration_ms < 200 || vad.silence_duration_ms > 10000) throw new HTTPError(400,'A valid speech pause is required.');
  return {sdp:data.sdp,session:{type:'realtime',model,instructions:value.instructions,output_modalities:['audio'],audio:{input:{transcription:{model:'gpt-4o-mini-transcribe'},turn_detection:{type:'server_vad',silence_duration_ms:vad.silence_duration_ms,threshold:0.35,prefix_padding_ms:120,create_response:vad.create_response !== false,interrupt_response:false}},output:{voice,format:{type:'audio/pcm',rate:24000}}}}};
}

export async function proxyRealtime(data,env,fetchUpstream=fetch) {
  const offer=realtimeOffer(data,env);
  if (!env.OPENAI_API_KEY) throw new HTTPError(503,'Live conversation is unavailable.');
  const form=new FormData();form.set('sdp',offer.sdp);form.set('session',JSON.stringify(offer.session));
  let result;
  try {
    result=await fetchUpstream('https://api.openai.com/v1/realtime/calls',{method:'POST',headers:{Authorization:`Bearer ${env.OPENAI_API_KEY}`},body:form,redirect:'manual',signal:AbortSignal.timeout(25000)});
  } catch { throw new HTTPError(502,'Live conversation could not connect. Try again.'); }
  if (!result.ok) throw new HTTPError(result.status === 429 ? 429 : 502,result.status === 429 ? 'Live conversation is busy. Try again shortly.' : 'Live conversation could not connect. Try again.');
  const sdp=await result.text();
  if (sdp.length > 65536 || !/^v=0\r?\n/.test(sdp) || !/^m=audio /m.test(sdp)) throw new HTTPError(502,'Live conversation returned an invalid connection.');
  return new Response(sdp,{headers:{'Content-Type':'application/sdp','Cache-Control':'no-store'}});
}
