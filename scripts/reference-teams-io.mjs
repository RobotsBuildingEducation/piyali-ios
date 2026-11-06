import fs from'node:fs/promises';import path from'node:path';
export function teamsFixture(root,reference){const entry=path.join(reference,'__piyali-teams.jsx');return{name:'piyali-source-teams',enforce:'pre',resolveId(id,importer){if(id==='/__piyali-teams.jsx')return entry;if(importer?.includes('/components/Teams/')){if(id.endsWith('/teams'))return '\0piyali-teams-io';if(id.endsWith('/learningTeams'))return '\0piyali-teams-progress';}},async load(id){if(id===entry)return fs.readFile(path.join(root,'scripts/reference-teams.jsx'),'utf8');if(id==='\0piyali-teams-progress')return `export * from '/src/utils/learningTeams.js';export const publishLearningProgress=async(...args)=>{window.__teamsPublishes=(window.__teamsPublishes||0)+1};`;

if(id==='\0piyali-teams-io')return `
const f=()=>window.__teamsFixture,state=new URLSearchParams(location.search).get('state'),watchers=new Set(),rowReads=[];
window.__teamRowRequests=rowReads;
window.__emitTeamRecord=value=>Promise.all([...watchers].map(w=>w.callback(value)));
window.__releaseTeamRow=(index,rows)=>rowReads[index].resolve(rows);
window.__rejectTeamRow=index=>rowReads[index].reject(Error('Public member read failure'));
export const getUserTeams=async()=>state==='loading'?new Promise(resolve=>{window.__releaseTeamLoad=()=>resolve(f().teams)}):state==='stream'?new Promise(resolve=>{window.__releaseRosterRead=()=>resolve(f().teams)}):f().teams,
getUserTeamInvites=async()=>f().invites,
getTeamMemberProgress=async(creator,id)=>state==='stream'?new Promise((resolve,reject)=>{rowReads.push({creator,id,resolve,reject})}):f().rows[id]||[],
getUserData=async()=>({name:'New Learner'}),
subscribeToTeamInvites=(n,cb)=>{cb(f().invites);return()=>{}},
subscribeToTeamUpdates=(creator,id,callback)=>{const value={creator,id,callback};watchers.add(value);return()=>watchers.delete(value)},
acceptTeamInvite=async()=>({groupListSynced:true}),rejectTeamInvite=async()=>({groupListSynced:true}),
renameTeam=async(n,t,name)=>{if(state==='rename-error')throw Error('Public rename rejection');return{name,mirrorSynced:state!=='rename-warning'}},
deleteTeam=async()=>{},leaveTeam=async()=>{},createTeam=async()=>'fixture-new',addMembersToTeam=async()=>({mirrorSynced:true});
`;
},configureServer(server){server.middlewares.use('/__piyali-teams',async(req,res,next)=>{if((req.originalUrl||req.url).split('?')[0].endsWith('.jsx'))return next();const fixture=await fs.readFile(path.join(root,'Tests/PiyaliAppTests/Fixtures/teams-panel-preview.json'),'utf8');const html=await server.transformIndexHtml('/__piyali-teams',`<!doctype html><html><head><meta name="viewport" content="width=device-width,initial-scale=1"><style>html,body,#root{margin:0;width:100%;height:100%;overflow:hidden}</style></head><body><div id="root"></div><script>window.__teamsFixture=${fixture};const originalFetch=window.fetch.bind(window);window.fetch=(input,...args)=>{const u=new URL(typeof input==='string'?input:input.url,location.href);if(u.hostname!=='127.0.0.1')return Promise.reject(Error('External I/O disabled in source Teams fixture'));return originalFetch(input,...args)};const Socket=window.WebSocket;window.WebSocket=class extends Socket{constructor(url,...args){if(new URL(url,location.href).hostname!=='127.0.0.1')throw Error('External relay disabled in source Teams fixture');super(url,...args)}};</script><script type="module" src="/__piyali-teams.jsx"></script></body></html>`);res.setHeader('Content-Type','text/html');res.end(html)})}}}
