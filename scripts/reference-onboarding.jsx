// Target-owned QA entry: render the unmodified source component with inert
// completion and disabled sounds. No web identity, profile or learner write.
import React,{useState} from 'react';
import {createRoot} from 'react-dom/client';
import {ChakraProvider} from '@chakra-ui/react';
import {MemoryRouter} from 'react-router-dom';
import {theme} from '/src/theme';
import '/src/index.css';
import Onboarding from '/src/components/Onboarding';
import GettingStartedModal from '/src/components/GettingStartedModal';
import ProficiencyTestModal from '/src/components/ProficiencyTestModal';
import DailyPlateHome from '/src/components/DailyPlateHome';
import '@fontsource/dm-sans/400.css';
import '@fontsource/dm-sans/700.css';
import useSoundSettings from '/src/hooks/useSoundSettings';
import {t as translate} from '/src/utils/translation';
import {syncDocumentLanguage} from '/src/utils/documentLanguage';
import {useThemeStore} from '/src/useThemeStore';
const query=new URLSearchParams(window.location.search),language=query.get('language')||'en';
useThemeStore.getState().syncThemeMode(query.get('theme')==='dark'?'dark':'light');
useSoundSettings.getState().setSoundEnabled(false);
syncDocumentLanguage(language);
function FirstRunPreview(){const [step,setStep]=useState('install');return <><GettingStartedModal isOpen={step==='install'} lang={language} secretKey="fixture-only-no-private-key" onClose={()=>setStep('placement')}/><ProficiencyTestModal isOpen={step==='placement'} lang={language} targetLangLabel={translate(language,'language_'+(language==='es'?'en':'es'))} onClose={()=>setStep('done')} onStartAtLevel={()=>setStep('done')} onTakeTest={()=>setStep('done')}/></>}
function Preview(){const [saved,setSaved]=useState(null);return saved?<pre data-testid="onboarding-result">{JSON.stringify({supportLang:saved.supportLang,targetLang:saved.targetLang,learningGoals:saved.learningGoals},null,2)}</pre>:<Onboarding userLanguage={language} initialDraft={{soundEnabled:false}} onComplete={payload=>setSaved(payload)}/>;}
function FocusPreview(){
 const now=new Date(),dayKey=[now.getFullYear(),String(now.getMonth()+1).padStart(2,'0'),String(now.getDate()).padStart(2,'0')].join('-');
 const target='es',dismissKey=`companionBubbleDismissed:${target}:${dayKey}`;
 const [custom,setCustom]=useState({name:'Piyali',petType:'ghost'});
 const [completed,setCompleted]=useState([false,false,false]);
 const state=query.get('state')||'welcome',progress={dailyQuestFirstSeen:true,dailyQuestFirstDayKey:dayKey};
 if(state==='progress'){progress.speakDailyActivity={es:{[dayKey]:1}};progress.lessonDailyActivity={es:{[dayKey]:0}};progress.flashcardDailyActivity={es:{[dayKey]:2}};}
 if(state==='cleared'){progress.speakDailyActivity={es:{[dayKey]:1}};progress.lessonDailyActivity={es:{[dayKey]:1}};progress.flashcardDailyActivity={es:{[dayKey]:5}};}
 // Source UI only: cached fixture headline avoids a real Gemini request. User
 // intentionally has no account id, so recap/activity services cannot write.
 const subtitle=language==='ar'?'أكمل مهامك واحصل على مكافأة XP':'Complete your tasks to earn an XP bonus';
 const user={progress,dailyPlateHeadline:{es:{dayKey,appLanguage:language,text:subtitle}}};
 if(state==='welcome')localStorage.removeItem(dismissKey);else localStorage.setItem(dismissKey,'1');
 return <DailyPlateHome key={language+state} user={user} targetLang={target} appLanguage={language} dailyXp={state==='progress'?125:0} dailyGoalXp={50} languageXp={state==='progress'?240:0} companionLevel={state==='progress'?3:1} petHealth={state==='progress'?49:100} petName={custom.name} petType={custom.petType} onCustomizePet={setCustom} questKinds={['speak','learn','review']} onStartPractice={()=>{}} onCompanionContinue={()=>{}} immersion={state==='immersion'?{awaitingPlacement:false,tasks:['Notice a familiar word','Listen for a useful detail','Describe something nearby'].map(title=>({title,description:'Practice privately at home, then mark this mission complete.'})),completed,status:'ready',rewarded:completed.every(Boolean),toggleTask:index=>setCompleted(old=>old.map((v,i)=>i===index?!v:v))}:{awaitingPlacement:true,tasks:[],completed:[],status:'new'}}/>;
}
createRoot(document.getElementById('root')).render(<ChakraProvider theme={theme}><MemoryRouter initialEntries={['/onboarding']}>{query.get('screen')==='first-run'?<FirstRunPreview/>:query.get('screen')==='focus'?<FocusPreview/>:<Preview/>}</MemoryRouter></ChakraProvider>);
