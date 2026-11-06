import{loadGlobalTeamFeed,getCachedGlobalTeamFeed}from'/src/utils/globalTeamFeedCache';
import{syncDocumentLanguage}from'/src/utils/documentLanguage';import React,{useState}from'react';import{createRoot}from'react-dom/client';import{ChakraProvider}from'@chakra-ui/react';import{theme}from'/src/theme';import{useThemeStore}from'/src/useThemeStore';import TeamsDrawer from'/src/components/Teams/TeamsDrawer.jsx';import{translations}from'/src/utils/translation.jsx';import'/src/index.css';
const q=new URLSearchParams(location.search),language=q.get('language')||'en',state=q.get('state')||'single',f=window.__teamsFixture;syncDocumentLanguage(language);useThemeStore.getState().syncThemeMode(q.get('theme')==='dark'?'dark':'light');if(state==='empty'||state==='create'||state==='queued'||state==='loading')f.teams=[];if(state==='multi')f.teams.push({...f.teams[0],id:'fixture-two',teamName:'Evening practice'});if(state!=='pending'&&state!=='loading')f.invites=[];localStorage.setItem('local_npub',f.creator);
// Only the fetch boundary is controlled; TeamFeed and its real shared cache remain original.
if(state==='feed-question')f.posts=f.posts.map(post=>({...post,content:'Finished question 30! https://piyali.app **literal** #LearnWithNostr',tags:[]}));
const feedBase=f.posts[0],entry=(id,content,name='Ada',createdAt=1700000001)=>({...feedBase,id,content,profile:{name},tags:[],createdAt});
if(state==='feed-ordinary')f.posts=[entry('ordinary','A community greeting')];
if(state==='feed-zero')f.posts=[entry('zero','Finished question 0')];
if(state==='feed-scholarship')f.posts=[entry('scholarship','A new scholarship')];
if(state==='feed-banned')f.posts=[{...feedBase,profile:{name:'TEST'}}];
if(state==='feed-mixed')f.posts=[entry('ordinary','A community greeting','Ada',1700000003),{...feedBase,id:'blocked',profile:{name:'TEST'},createdAt:1700000004},{...feedBase,id:'visible',createdAt:1700000001}];
if(state==='feed-fallback')f.posts=[{...feedBase,profile:{name:'New Private User'}}];
window.__teamsCachedFeed=()=>getCachedGlobalTeamFeed();
window.__feedRequests=[];
const fetchFeed=async hashtag=>{window.__feedRequests.push(hashtag);if(state==='feed-loading'||state==='feed-cached-refresh'||(state==='feed-error'&&window.__feedRequests.length>1))return new Promise((resolve,reject)=>{window.__releaseFeed=(posts=f.posts)=>resolve(posts);window.__rejectFeed=()=>reject(Error('Community relay unavailable'));});if(state==='feed-error')throw Error('Community relay unavailable');return state==='feed-empty'?[]:f.posts;};
if(state==='feed-cached-refresh'){const clock=Date.now;Date.now=()=>clock()-121000;try{await loadGlobalTeamFeed(async()=>f.posts)}finally{Date.now=clock}}
else if(!state.startsWith('feed-'))await loadGlobalTeamFeed(async()=>f.posts);
function Preview(){const[open,setOpen]=useState(true);return <ChakraProvider theme={theme}><div style={{height:'100%',background:q.get('theme')==='dark'?'#0b1220':'#f7f1e7'}}/><TeamsDrawer isOpen={open} onClose={()=>setOpen(false)} userLanguage={language} t={translations[language]} initialTeams={state==='loading'?null:f.teams} initialTeamMemberProgress={f.rows} initialTeamInvites={f.invites} pendingInviteCount={f.invites.length} hasUnseenInvites={false} fetchGlobalTeamFeed={fetchFeed}/></ChakraProvider>}createRoot(document.getElementById('root')).render(<Preview/>);
