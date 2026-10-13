import {HTTPError} from './auth.js';
export function responsesBody(data,env) {
  const allowed=(env.ALLOWED_RESPONSE_MODELS ?? 'gpt-6-luna,gpt-5-nano').split(',');
  if(typeof data.model!=='string' || !allowed.includes(data.model)) throw new HTTPError(400,'Choose a supported tutor model.');
  if(typeof data.input!=='string' || !data.input.trim() || data.input.length>110000) throw new HTTPError(400,'Provide a tutor prompt within the size limit.');
  const format=data.text?.format?.type ?? 'text';
  if(!['text','json_object'].includes(format)) throw new HTTPError(400,'Unsupported tutor output format.');
  const limit=data.max_output_tokens ?? 4096;
  if(!Number.isInteger(limit) || limit<16 || limit>8192) throw new HTTPError(400,'Invalid tutor output limit.');
  return {model:data.model,input:data.input,store:false,stream:false,max_output_tokens:limit,
    reasoning:{effort:data.model.includes('luna')?'none':'minimal'},text:{format:{type:format},verbosity:'low'}};
}
export async function proxyResponses(data,env,fetchUpstream=fetch) {
  const payload=responsesBody(data,env);
  if(!env.OPENAI_API_KEY) throw new HTTPError(503,'The tutor is not configured.');
  const controller=new AbortController(),timer=setTimeout(()=>controller.abort(),40000);
  try {
    const upstream=await fetchUpstream('https://api.openai.com/v1/responses',{method:'POST',headers:{Authorization:`Bearer ${env.OPENAI_API_KEY}`,'Content-Type':'application/json'},body:JSON.stringify(payload),signal:controller.signal,redirect:'manual'});
    if(!upstream.ok) return new Response(JSON.stringify({error:upstream.status===429?'The tutor is busy. Try again shortly.':'The tutor provider could not complete this request.'}),{status:upstream.status===429?429:502,headers:{'Content-Type':'application/json','Cache-Control':'no-store'}});
    return new Response(await upstream.text(),{headers:{'Content-Type':'application/json','Cache-Control':'no-store'}});
  } catch { throw new HTTPError(controller.signal.aborted?504:502,'The tutor is unavailable. Try again shortly.'); }
  finally { clearTimeout(timer); }
}
