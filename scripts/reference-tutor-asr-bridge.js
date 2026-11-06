// Explicit, public protocol input for the unchanged source Tutor. No microphone,
// provider, identity or cloud transport. Other Tutor previews remain disconnected.
export async function createOpenAIRealtimeBridge({onEvent}) {
  if(new URLSearchParams(location.search).get('tutorASR')!=='1')throw Error('Public Tutor fixture: microphone unavailable');
  const trace={sent:[],received:[],microphone:true,closed:false,judges:0,learnerJudges:0,grades:0,notes:0,awards:0,awardAmounts:[],gradedIDs:[],agendaWrites:[],earnedWrites:[],completed:0};
  const track={enabled:true,stop(){this.enabled=false}},bridge={readyState:'open',mediaStream:{getAudioTracks:()=>[track],getTracks:()=>[track]},setInputAudioEnabled(value){trace.microphone=value;track.enabled=value},setOutputGain(){},close(){trace.closed=true;bridge.readyState='closed'},send(raw){const event=JSON.parse(raw);trace.sent.push(event);if(event.type==='session.update')queueMicrotask(()=>onEvent({data:JSON.stringify({type:'session.updated'})}))}};
  trace.emit=async event=>{trace.received.push(event);await onEvent({data:JSON.stringify(event)})};
  window.__tutorASR=trace;return bridge;
}
export const createGeminiLiveRealtimeBridge=createOpenAIRealtimeBridge;
