// Target-owned QA entry: render the unmodified source component with inert
// completion and disabled sounds. No web identity, profile or learner write.
import React,{useState} from 'react';
import {createRoot} from 'react-dom/client';
import {ChakraProvider} from '@chakra-ui/react';
import {MemoryRouter} from 'react-router-dom';
import {theme} from '/src/theme';
import '/src/index.css';
import Onboarding from '/src/components/Onboarding';
import {useThemeStore} from '/src/useThemeStore';
const query=new URLSearchParams(window.location.search),language=query.get('language')||'en';
useThemeStore.getState().syncThemeMode(query.get('theme')==='dark'?'dark':'light');
function Preview(){const [saved,setSaved]=useState(null);return saved?<pre data-testid="onboarding-result">{JSON.stringify({supportLang:saved.supportLang,targetLang:saved.targetLang,learningGoals:saved.learningGoals},null,2)}</pre>:<Onboarding userLanguage={language} initialDraft={{soundEnabled:false}} onComplete={payload=>setSaved(payload)}/>;}
createRoot(document.getElementById('root')).render(<ChakraProvider theme={theme}><MemoryRouter initialEntries={['/onboarding']}><Preview/></MemoryRouter></ChakraProvider>);
