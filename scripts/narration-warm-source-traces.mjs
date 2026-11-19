import vm from'node:vm';
// Execute the actual source pool with public fake media/SDP and a deterministic clock.
export async function warmSourceTraces(source){
 const create=vm.runInNewContext('('+source.replace('export function','function')+')',{AbortController});
 function harness(){let time=0,fail=false,posts=0,id=0;const peers=[],timers=new Map();
  const stream=()=>({tracks:[],addTrack(t){this.tracks.push(t)},getTracks(){return this.tracks},getAudioTracks(){return this.tracks.filter(t=>t.kind==='audio')}});
  const pool=create({url:'https://public.invalid/realtime',model:'public-test-model',exchange:async()=>{posts++;return{ok:!fail,text:async()=>'v=0\r\nm=audio public'}},createStream:stream,createAudio:()=>({muted:false,pause(){},play(){return Promise.resolve()}}),now:()=>time,setTimer:(f,ms)=>{timers.set(++id,{f,at:time+ms});return id},clearTimer:key=>timers.delete(key),createPeer:()=>{const track={kind:'audio',stopped:false,stop(){this.stopped=true}},dc={readyState:'connecting',close(){this.readyState='closed'}},pc={connectionState:'new',track,dc,addTransceiver(kind,options){this.direction=options.direction},createDataChannel(){return dc},createOffer:async()=>({sdp:'v=0\r\nm=audio public'}),setLocalDescription:async()=>{},setRemoteDescription:async()=>{pc.connectionState='connected';dc.readyState='open';pc.ontrack?.({track,streams:[]});dc.onopen?.()},close(){this.connectionState='closed'}};peers.push(pc);return pc}});
  return{pool,peers,timers,get posts(){return posts},set fail(v){fail=v},advance(ms){time+=ms}};
 }
 const result={};
 {const h=harness();result.singleFlight={first:await h.pool.warm(),second:await h.pool.warm()};const lease=await h.pool.take(),second=await h.pool.take();h.pool.clear();Object.assign(result.singleFlight,{posts:h.posts,claimed:!!lease,secondClaim:!!second,claimedStillOpen:lease.pc.connectionState==='connected',receiveOnly:h.peers[0].direction});lease.close()}
 {const h=harness();h.fail=true;const first=await h.pool.warm(),second=await h.pool.warm(),blockedPosts=h.posts;h.advance(30000);h.fail=false;const retry=await h.pool.warm();result.backoff={first,second,blockedPosts,retry,posts:h.posts};h.pool.clear()}
 {const h=harness();await h.pool.warm();h.advance(240000);result.expiry={claimed:!!(await h.pool.take()),closed:h.peers[0].connectionState==='closed'};h.pool.clear()}
 {const h=harness();await h.pool.warm();const lease=await h.pool.take();await h.pool.warm();h.pool.clear();result.clearUnused={posts:h.posts,claimedStillOpen:lease.pc.connectionState==='connected',unusedClosed:h.peers[1].connectionState==='closed'};lease.close()}
 return result;
}
