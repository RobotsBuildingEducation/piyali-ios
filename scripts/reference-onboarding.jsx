// Target-owned QA entry: render the unmodified source component with inert
// completion and disabled sounds. No web identity, profile or learner write.
import React,{useState} from 'react';
import {createRoot} from 'react-dom/client';
import {Box,ChakraProvider} from '@chakra-ui/react';
import {MemoryRouter} from 'react-router-dom';
import {theme} from '/src/theme';
import '/src/index.css';
import Onboarding from '/src/components/Onboarding';
import GettingStartedModal from '/src/components/GettingStartedModal';
import ProficiencyTestModal from '/src/components/ProficiencyTestModal';
import DailyPlateHome from '/src/components/DailyPlateHome';
import DailyGoalModal from '/src/components/DailyGoalModal';
import SessionTimerModal from '/src/components/SessionTimerModal';
import SourceMemoryPreview from '/__piyali-memory.jsx';
import SourceDailyGoalReward from '/__piyali-daily-goal-completion.jsx';
import SourcePlateCompletion from '/__piyali-plate-completion.jsx';
import Tutor from '/src/components/Tutor';
import AlphabetBootcamp from '/src/components/AlphabetBootcamp';
import useRepairFocusStore from '/src/hooks/useRepairFocusStore';
import FlashcardPractice from '/src/components/FlashcardPractice';
import FlashcardSkillTree from '/src/components/FlashcardSkillTree';
import CEFRLevelNavigator from '/src/components/CEFRLevelNavigator';
import CourseProgressHeader from '/src/components/CourseProgressHeader';
import GoalFocusBanner from '/src/components/GoalFocusBanner';
import {LearningGoalField} from '/src/components/LearningGoalSettings';
import useGoalFocusStore from '/src/hooks/useGoalFocusStore';
import useUserStore from '/src/hooks/useUserStore';
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
function TutorPreview(){
 localStorage.setItem('appLanguage',language);
 const kind=query.get('focus'),npub='piyali-public-fixture-no-account',date=new Date(),dayKey=[date.getFullYear(),String(date.getMonth()+1).padStart(2,'0'),String(date.getDate()).padStart(2,'0')].join('-');
 const blueprint={goalId:'public-tutor-goal',goalText:'Speak with family',dayKey,lang:'es',mode:'tutor',modes:['tutor','flashcards'],modeTargets:{tutor:25,flashcards:3},cefrLevel:'Pre-A1',objective:language==='ar'?'حيّ أفراد عائلتك':'Greet a family member',scenario:language==='ar'?'أنت تزور عائلتك. ابدأ محادثة قصيرة بالإسبانية.':'You are visiting family. Start a short conversation in Spanish.',targetLanguage:['Hola','¿Cómo estás?'],supports:language==='ar'?['تدرّب على تحية','استخدم نموذجًا']:['Rehearse a greeting','Use a model'],successCriteria:language==='ar'?['قل مرحبًا','اسأل كيف حالهم']:['Say hello','Ask how they are']};
 const item={memoryId:'public-greeting',concept:language==='ar'?'حيّ أحد أقاربك':'Greet a relative',summary:language==='ar'?'تدرّب على تحية قصيرة':'Practice a short greeting',expectedAnswer:'Hola',cefrLevel:'Pre-A1',errorType:'conversation_flow'},plan={targetLang:'es',dayKey,target:1,items:[item],memoryIds:['public-greeting']};
 React.useLayoutEffect(()=>{useUserStore.setState({user:kind?{local_npub:npub,progress:{targetLang:'es'},learningIntelligence:{es:{activeGoal:{id:blueprint.goalId,text:blueprint.goalText,status:'active'},dailyGoal:{blueprint,modeProgress:{tutor:0,flashcards:0},completed:false}}}}:null});useGoalFocusStore.setState({focus:kind==='goal'?{npub,targetLang:'es',supportLang:language,surface:'tutor',blueprint}:null});useRepairFocusStore.setState({focus:kind==='repair'?{npub,targetLang:'es',supportLang:language,surface:'tutor',mode:'tutor',stepIndex:0,stepCount:1,plan}:null})},[]);
 return <Tutor activeNpub={npub} targetLang='es' supportLang={language} maxProficiencyLevel='Pre-A1'/>;
}
function PhonicsPreview(){localStorage.setItem('appLanguage',language);React.useLayoutEffect(()=>{useUserStore.setState({user:null});useGoalFocusStore.setState({focus:null});useRepairFocusStore.setState({focus:null})},[]);return <AlphabetBootcamp appLanguage={language} targetLang="es" npub="piyali-public-fixture-no-account" cefrLevel="Pre-A1"/>}
function FlashcardPreview(){
 const [open,setOpen]=useState(true),[result,setResult]=useState(null);localStorage.setItem('appLanguage',language);
 const card={id:'pre-a1-people-1',concept:{en:'mom',es:'mamá',ar:'ماما',fr:'maman'},cefrLevel:'Pre-A1',category:'people',type:'word',reviewProgress:{},practiceStatus:'active'};
 React.useLayoutEffect(()=>{useUserStore.setState({user:null});useGoalFocusStore.setState({focus:null})},[]);
 if(query.get('tool')==='deck')return <Box px={3} pt={3} pb={6}><CEFRLevelNavigator currentLevel="Pre-A1" activeCEFRLevel="Pre-A1" supportLang={language} onLevelChange={()=>{}}/><CourseProgressHeader totalXp={10} activeLevel="Pre-A1" percentage={0} supportLang={language}/><FlashcardSkillTree targetLang="es" supportLang={language} activeCEFRLevel="Pre-A1" dailyPlateSnapshot={{courses:[{kind:'review',target:5,count:0}]}} userProgress={{flashcards:{}}}/></Box>;
 return <>{result&&<pre id="flashcard-result">{JSON.stringify(result)}</pre>}<FlashcardPractice card={card} isOpen={open} targetLang="es" supportLang={language} languageXp={10} dailyReviewed={0} dailyTarget={5} onClose={()=>setOpen(false)} onComplete={value=>{setResult(value);setOpen(false)}}/></>;
}
function GoalPreview(){
 const [value,setValue]=useState('Speak with family'),dayKey=new Date().toLocaleDateString('en-CA'),npub='piyali-public-fixture-no-account';
 const blueprint={goalId:'public-goal',dayKey,lang:'es',mode:'lesson',modes:['lesson','tutor'],cefrLevel:'Pre-A1',objective:language==='ar'?'حيّ أفراد عائلتك':'Greet a family member',scenario:language==='ar'?'أنت تزور عائلتك. ابدأ محادثة قصيرة بالإسبانية.':'You are visiting family. Start a short conversation in Spanish.',targetLanguage:['Hola','¿Cómo estás?'],supports:language==='ar'?['تدرّب على تحية','استخدم نموذجًا']:['Rehearse a greeting','Use a model'],successCriteria:language==='ar'?['قل مرحبًا','اسأل كيف حالهم']:['Say hello','Ask how they are']};
 React.useLayoutEffect(()=>{useUserStore.setState({user:{local_npub:npub,progress:{targetLang:'es'},learningIntelligence:{es:{activeGoal:{id:blueprint.goalId,text:'Speak with family',status:'active'},dailyGoal:{blueprint,modeProgress:{lesson:0,tutor:0},completed:false}}}}});useGoalFocusStore.setState({focus:{npub,targetLang:'es',supportLang:language,surface:'lesson',blueprint}})},[]);
 return query.get('tool')==='editor'?<Box bg="gray.800" p={3} borderRadius="md" m={4}><LearningGoalField lang={language} value={value} onChange={setValue}/><Box minH="18px" mt={1}/></Box>:<GoalFocusBanner surface="lesson"/>;
}
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
createRoot(document.getElementById('root')).render(<ChakraProvider theme={theme}><MemoryRouter initialEntries={['/onboarding']}>{query.get('screen')==='memory'?<SourceMemoryPreview/>:query.get('screen')==='daily-goal-completion'?<SourceDailyGoalReward/>:query.get('screen')==='plate-completion'?<SourcePlateCompletion/>:query.get('screen')==='tutor'?<TutorPreview/>:query.get('screen')==='phonics'?<PhonicsPreview/>:query.get('screen')==='flashcards'?<FlashcardPreview/>:query.get('screen')==='focused-goal'?<GoalPreview/>:query.get('screen')==='tools'?<ToolsPreview/>:query.get('screen')==='first-run'?<FirstRunPreview/>:query.get('screen')==='focus'?<FocusPreview/>:<Preview/>}</MemoryRouter></ChakraProvider>);
