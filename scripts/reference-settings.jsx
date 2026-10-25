import React,{useState,useRef,useLayoutEffect} from 'react';
import SourceSettings from '/__piyali-settings-topbar.jsx';
import useUserStore from '/src/hooks/useUserStore';
const q=new URLSearchParams(location.search),language=q.get('language')||'en',npub='piyali-public-fixture-no-account';
localStorage.setItem('displayName','Settings Learner');
localStorage.setItem('tutorRealtimeProviderV3','openai');
export default function SourceSettingsPreview(){
 const [lang,setLang]=useState(language),[open,setOpen]=useState(true),[user,setUser]=useState({displayName:'Settings Learner',progress:{targetLang:'es',supportLang:language,tutorVoice:'marin',pauseMs:1200},allowPosts:false,soundEnabled:true}),pending=useRef(null);
 useLayoutEffect(()=>{useUserStore.setState({user:{learningIntelligence:{es:{activeGoal:{text:'Talk with family',status:'active'}}}}})},[]);
 return <SourceSettings user={user} appLanguage={lang} activeNpub={npub} activeNsec="fixture-only-no-private-key" auth={{signOut:async()=>{}}} settingsOpen={open} closeSettings={()=>setOpen(false)} onPatchSettings={partial=>setUser(old=>({...old,progress:{...old.progress,...partial}}))} onSupportLangChange={setLang} pendingLangRef={pending} allowPosts={user.allowPosts} onAllowPostsChange={value=>setUser(old=>({...old,allowPosts:value}))} soundEnabled={user.soundEnabled} onSoundEnabledChange={value=>setUser(old=>({...old,soundEnabled:value}))} playSound={()=>{}} isMobile openSubscriptionTab={q.get('tool')==='subscription'} patreonStatusResolved patreonStatusPayload={{linked:false,verified:false}} onOpenProficiencyModal={()=>{}}/>;
}
