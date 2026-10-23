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
createRoot(document.getElementById('root')).render(<ChakraProvider theme={theme}><MemoryRouter initialEntries={['/onboarding']}>{query.get('screen')==='first-run'?<FirstRunPreview/>:<Preview/>}</MemoryRouter></ChakraProvider>);
