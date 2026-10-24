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
import DailyGoalModal from '/src/components/DailyGoalModal';
import SessionTimerModal from '/src/components/SessionTimerModal';
import SourceTopBar from '/__piyali-topbar.jsx';
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
function ToolsPreview(){const [tool,setTool]=useState(query.get('tool')||'goal'),[minutes,setMinutes]=useState('20'),[result,setResult]=useState(null);return <><SourceTopBar appLanguage={language} onOpenDailyGoalModal={()=>setTool('goal')} onOpenTimerModal={()=>setTool('timer')}/><DailyGoalModal isOpen={tool==='goal'} dismissible lang={language} npub="piyali-public-fixture-no-account" defaultGoal={100} petHealth={100} onClose={()=>setTool('')} onSaveGoal={goal=>{setResult({goal});setTool('')}} onCustomizePet={()=>{}}/><SessionTimerModal isOpen={tool==='timer'} lang={language} t={Object.fromEntries(['title','description','minutes_label','max_hint','drag_hint','quick_picks','close','start','restart'].map(key=>['timer_modal_'+key,translate(language,'timer_modal_'+key)]))} minutes={minutes} onMinutesChange={setMinutes} onClose={()=>setTool('')} onStart={value=>{setResult({minutes:value});setTool('')}}/>{result&&<pre id="tools-result">{JSON.stringify(result)}</pre>}</>}
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
 const subtitle=state==='headline'?(language==='fr'?'Demande ton chemin avec confiance.':language==='ar'?'تحدث بثقة عن خططك لهذا اليوم.':"Ask about today's plans with confidence."):(language==='ar'?'أكمل مهامك واحصل على مكافأة XP':'Complete your tasks to earn an XP bonus');
 if(state==='returning')progress.dailyQuestFirstDayKey='2026-01-01';
 const user={progress,dailyPlateHeadline:{es:{dayKey,appLanguage:language,text:subtitle}}};
 if(state==='returning'){
 const message=language==='ar'?'حفظت لك تدريبًا قصيرًا على التحيات لتصبح أسهل اليوم. ثم سنواصل التقدم في تدريباتك المعتادة.':'I saved a quick warm-up for greetings so they feel easier today. Then we’ll keep moving forward with your regular practice.';
 user.onboarding={completed:true};user.learningIntelligence={es:{elo:{rating:800,scaleVersion:4,totalGraded:0}}};
 user.dailyQuestRepair={es:{[dayKey]:{targetLang:target,dayKey,target:1,items:[{memoryId:'public-greeting',concept:'saludos',mode:'flashcards',expectedAnswer:'Hola'}],memoryIds:['public-greeting']}}};
 user.dailyQuestBlueprint={es:{[dayKey]:{status:'ready',message:{long:message}}}};
 }
 if(state==='welcome'||state==='returning')localStorage.removeItem(dismissKey);else localStorage.setItem(dismissKey,'1');
 return <DailyPlateHome key={language+state} user={user} targetLang={target} appLanguage={language} dailyXp={state==='progress'?125:0} dailyGoalXp={state==='returning'?100:50} languageXp={state==='progress'?240:0} companionLevel={state==='progress'?3:1} petHealth={state==='progress'?49:100} petName={custom.name} petType={custom.petType} onCustomizePet={setCustom} questKinds={state==='returning'?['repair','speak','learn','review']:['speak','learn','review']} onStartPractice={()=>{}} onCompanionContinue={()=>{}} immersion={state==='immersion'?{awaitingPlacement:false,tasks:['Notice a familiar word','Listen for a useful detail','Describe something nearby'].map(title=>({title,description:'Practice privately at home, then mark this mission complete.'})),completed,status:'ready',rewarded:completed.every(Boolean),toggleTask:index=>setCompleted(old=>old.map((v,i)=>i===index?!v:v))}:{awaitingPlacement:true,tasks:[],completed:[],status:'new'}}/>;
}
createRoot(document.getElementById('root')).render(<ChakraProvider theme={theme}><MemoryRouter initialEntries={['/onboarding']}>{query.get('screen')==='tools'?<ToolsPreview/>:query.get('screen')==='first-run'?<FirstRunPreview/>:query.get('screen')==='focus'?<FocusPreview/>:<Preview/>}</MemoryRouter></ChakraProvider>);
