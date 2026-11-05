import React from 'react';
import {createRoot}from'react-dom/client';
import {Box,ChakraProvider}from'@chakra-ui/react';
import{theme}from'/src/theme';
import{useThemeStore}from'/src/useThemeStore';
import{syncDocumentLanguage}from'/src/utils/documentLanguage';
import'/src/index.css';import'@fontsource/dm-sans/400.css';import'@fontsource/dm-sans/700.css';
import FlashcardSkillTree from'/src/components/FlashcardSkillTree';
import CEFRLevelNavigator from'/src/components/CEFRLevelNavigator';
import CourseProgressHeader from'/src/components/CourseProgressHeader';
import useUserStore from'/src/hooks/useUserStore';
import useGoalFocusStore from'/src/hooks/useGoalFocusStore';
import useRepairFocusStore from'/src/hooks/useRepairFocusStore';
const query=new URLSearchParams(location.search),input=JSON.parse(query.get('snapshot')),language=input.language;
localStorage.setItem('appLanguage',language);syncDocumentLanguage(language);useThemeStore.getState().syncThemeMode(query.get('theme')||'light');
window.__focused={...input,writes:[]};useUserStore.setState({user:input.user});useGoalFocusStore.setState({focus:input.kind==='goal'?input.focus:null});useRepairFocusStore.setState({focus:input.kind==='repair'?input.focus:null});
// Isolated tree comparison: Goal/repair banners and app chrome are covered by
// separate journeys. The section begins at the source level navigator.
createRoot(document.getElementById('root')).render(<ChakraProvider theme={theme}><Box px={3} pt={3} pb={6}><CEFRLevelNavigator currentLevel="Pre-A1" activeCEFRLevel="Pre-A1" supportLang={language} onLevelChange={()=>{}}/><CourseProgressHeader totalXp={input.xp} activeLevel="Pre-A1" percentage={0} supportLang={language}/><FlashcardSkillTree targetLang="es" supportLang={language} activeCEFRLevel="Pre-A1" dailyPlateSnapshot={{courses:[{kind:'review',target:5,count:0}]}} userProgress={{flashcards:{}}}/></Box></ChakraProvider>);

// Exercise the original tile -> modal -> grading -> chosen rating handlers.
// Test callers receive recorded I/O, never synthesized completion or XP.
window.runFocusedRecall=async(index)=>{
 const until=async check=>{for(let i=0;i<300;i++){const value=check();if(value)return value;await new Promise(r=>setTimeout(r,30))}throw Error('Original focused recall control did not settle')};
 const {translations}=await import('/src/utils/translation'),t=key=>translations[language]?.[key]||translations.en[key]||key,card=input.artifact.cards[index],cue=card.concept[language]||card.concept.en;
 const tile=[...document.querySelectorAll('p')].find(p=>p.textContent===cue);if(!tile)throw Error('Missing original focused tile '+cue);tile.click();
 const field=await until(()=>document.querySelector('.chakra-modal__content input'));field.focus();Object.getOwnPropertyDescriptor(HTMLInputElement.prototype,'value').set.call(field,card.concept.es);field.dispatchEvent(new Event('input',{bubbles:true}));field.blur();
 await new Promise(r=>setTimeout(r,100));const submit=[...document.querySelectorAll('.chakra-modal__content button')].find(b=>b.textContent.includes(t('flashcard_submit')));if(!submit)throw Error('Missing source submit');submit.click();
 const good=await until(()=>[...document.querySelectorAll('.chakra-modal__content button')].find(b=>b.textContent.includes(t('flashcard_button_good'))));good.click();await until(()=>!document.querySelector('.chakra-modal__content'));await new Promise(r=>setTimeout(r,150));return window.__focused.writes;
};
