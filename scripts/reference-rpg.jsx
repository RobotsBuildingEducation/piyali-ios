import React from'react';import{createRoot}from'react-dom/client';import{ChakraProvider}from'@chakra-ui/react';import{MemoryRouter}from'react-router-dom';import{theme}from'/src/theme';import'/src/index.css';import'@fontsource/dm-sans/400.css';import'@fontsource/dm-sans/700.css';import GameRouter from'/src/components/RPGGame/GameRouter.jsx';import{buildLegacyEpisodeScenario,validatePreparedStory,applyPreparedBeats}from'/src/components/RPGGame/episodes/legacyScenario.js';import{useThemeStore}from'/src/useThemeStore';
const q=new URLSearchParams(location.search);useThemeStore.getState().syncThemeMode(q.get('theme')==='dark'?'dark':'light');localStorage.setItem('nosabos:rpg-companion:v2','ghost');
const fixture=await(await fetch('/__piyali-rpg-fixture.json')).json(),lesson=q.has('episode')?{id:'native-library-Pre-A1',content:{game:{cefrLevel:'Pre-A1'}}}:fixture.lesson,scenario=buildLegacyEpisodeScenario({lesson,targetLang:'es',supportLang:q.get('language')||'en',...(q.has('episode')?{forcedEpisodeId:q.get('episode')}:{})});
const rendered=q.get('prepared')==='1'?applyPreparedBeats(scenario,validatePreparedStory(await(await fetch('/__piyali-rpg-prepared-fixture.json?language='+(q.get('language')||'en'))).json())):scenario;
let legacy=null;
if(q.has('legacy')){
 const f=await(await fetch('/__piyali-exploration-fixture.json')).json(),t=f.template;
 const maps=t.maps.map(m=>{const raw=f.maps.find(r=>r.worldKey===m.worldKey);return {...raw,id:m.id,name:m.name,portals:m.portals,objects:m.world.objects,generate:()=>raw.mapData}});
 legacy={...maps[0],...t,maps,questions:f.questions,generate:maps[0].generate};
 if(q.get('legacy')==='search'){const steps=structuredClone(legacy.quest.steps),index=steps.findIndex(s=>s.nodes.some(n=>n.responseMode==='gather'));const first=steps[index],nodeIndex=first.nodes.findIndex(n=>n.responseMode==='gather');first.nodes=first.nodes.slice(nodeIndex);first.nodes[0].responseMode='objectSearch';legacy.quest={...legacy.quest,steps:steps.slice(index)};legacy.startMapId=legacy.npcs[first.npcIdx].mapId;}
}
createRoot(document.getElementById('root')).render(<ChakraProvider theme={theme}><MemoryRouter><GameRouter lessonContext={legacy?null:lesson} initialScenario={legacy||rendered} targetLang="es" supportLang={q.get('language')||'en'} onComplete={()=>{}}/></MemoryRouter></ChakraProvider>);
