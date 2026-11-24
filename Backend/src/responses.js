import {HTTPError} from './auth.js';
import {rpgOutputFormat} from './rpg-output.js';
import {storyOutputFormat} from './story-output.js';
export function responsesBody(data,env) {
  const allowed=(env.ALLOWED_RESPONSE_MODELS ?? 'gpt-6-luna,gpt-5-nano').split(',');
  if(typeof data.model!=='string' || !allowed.includes(data.model)) throw new HTTPError(400,'Choose a supported tutor model.');
  if(typeof data.input!=='string' || !data.input.trim() || data.input.length>110000) throw new HTTPError(400,'Provide a tutor prompt within the size limit.');
  const format=data.text?.format?.type ?? 'text';
  if(!['text','json_object'].includes(format)) throw new HTTPError(400,'Unsupported tutor output format.');
  const output=data.outputProfile===undefined ? {type:format} : rpgOutputFormat(data.outputProfile) ?? storyOutputFormat(data.outputProfile);
  if(!output) throw new HTTPError(400,'Unsupported tutor output profile.');
  const effort=data.reasoning?.effort ?? (data.model.includes('luna')?'none':'minimal');
  const efforts=data.model.includes('luna') ? ['none','low','medium'] : ['minimal','low','medium'];
  if(!efforts.includes(effort)) throw new HTTPError(400,'Unsupported tutor reasoning effort.');
  const limit=data.max_output_tokens ?? 4096;
  if(!Number.isInteger(limit) || limit<16 || limit>8192) throw new HTTPError(400,'Invalid tutor output limit.');
  if(data.stream!==undefined && typeof data.stream!=='boolean') throw new HTTPError(400,'Invalid tutor stream option.');
  return {model:data.model,input:data.input,store:false,stream:data.stream===true,max_output_tokens:limit,
    reasoning:{effort},text:{format:output,verbosity:'low'}};
}
export async function proxyResponses(data,env,fetchUpstream=fetch) {
  const payload=responsesBody(data,env);
  if(!env.OPENAI_API_KEY) throw new HTTPError(503,'The tutor is not configured.');
  const controller=new AbortController(),timer=setTimeout(()=>controller.abort(),40000);
  let streaming=false;
  try {
    const upstream=await fetchUpstream('https://api.openai.com/v1/responses',{method:'POST',headers:{Authorization:`Bearer ${env.OPENAI_API_KEY}`,'Content-Type':'application/json'},body:JSON.stringify(payload),signal:controller.signal,redirect:'manual'});
    if(!upstream.ok) return new Response(JSON.stringify({error:upstream.status===429?'The tutor is busy. Try again shortly.':'The tutor provider could not complete this request.'}),{status:upstream.status===429?429:502,headers:{'Content-Type':'application/json','Cache-Control':'no-store'}});
    if(payload.stream) {
      if(!upstream.body || !upstream.headers.get('Content-Type')?.toLowerCase().startsWith('text/event-stream')) throw new HTTPError(502,'The tutor is unavailable. Try again shortly.');
      const reader=upstream.body.getReader();
      let closed=false,output;
      const cleanup=()=>{closed=true;clearTimeout(timer);controller.signal.removeEventListener('abort',abort);};
      const abort=()=>{
        if(closed) return;
        cleanup();output.error(new Error('The tutor stream was interrupted.'));
        reader.cancel().catch(()=>{});
      };
      const stream=new ReadableStream({
        start(destination){output=destination;controller.signal.addEventListener('abort',abort,{once:true});if(controller.signal.aborted) abort();},
        async pull(destination){
          try {
            const {value,done}=await reader.read();if(closed) return;
            if(done){cleanup();destination.close();}else destination.enqueue(value);
          }catch{if(!closed){cleanup();controller.abort();destination.error(new Error('The tutor stream was interrupted.'));}}
        },
        async cancel(){if(closed) return;cleanup();controller.abort();await reader.cancel().catch(()=>{});}
      });
      streaming=true;
      return new Response(stream,{headers:{'Content-Type':'text/event-stream; charset=utf-8','Cache-Control':'no-store, no-transform'}});
    }
    return new Response(await upstream.text(),{headers:{'Content-Type':'application/json','Cache-Control':'no-store'}});
  } catch { throw new HTTPError(controller.signal.aborted?504:502,'The tutor is unavailable. Try again shortly.'); }
  finally { if(!streaming) clearTimeout(timer); }
}
