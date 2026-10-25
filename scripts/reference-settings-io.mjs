// Actual source Settings UI with public snapshots and inert external I/O.
import fs from 'node:fs/promises';
import path from 'node:path';
import {createRequire} from 'node:module';
export function settingsFixture(root,reference){
 const require=createRequire(path.join(reference,'package.json')),{parse}=require('@babel/parser'),traverse=require('@babel/traverse').default;
 const topbar=path.join(reference,'src/__piyali-settings-topbar.jsx'),entry=path.join(reference,'__piyali-settings.jsx');
 return {name:'piyali-settings-fixture',enforce:'pre',resolveId(id,importer){
  if(id==='/__piyali-settings.jsx')return entry;
  if(id==='/__piyali-settings-topbar.jsx')return topbar;
  if(importer===topbar&&id.endsWith('/useAppUpdate'))return '\0piyali-settings-update';
  if(importer?.endsWith('/IdentityDrawer.jsx')){
   if(id==='firebase/firestore')return '\0piyali-settings-firestore';
   if(id.endsWith('/firebaseResources'))return '\0piyali-settings-database';
  }
  if(id.endsWith('/useNostrWalletStore'))return '\0piyali-settings-wallet';
  if(id.endsWith('/tts')&&['/VoicePreferenceField.jsx','/tutorRealtime.js'].some(x=>importer?.endsWith(x)))return '\0piyali-settings-tts';
  if(importer?.endsWith('/VoicePreferenceField.jsx')&&id.endsWith('/geminiLiveBridge'))return '\0piyali-settings-gemini';
  if(importer?.endsWith('/LearningGoalSettings.jsx')&&id.endsWith('/learningIntelligence'))return '\0piyali-settings-goal';
 },async load(id){
  if(id===entry||id===topbar){const file=path.join(root,id===entry?'scripts/reference-settings.jsx':'.reference-preview/reference-settings-topbar.jsx');this.addWatchFile(file);return fs.readFile(file,'utf8')}
  if(id==='\0piyali-settings-update')return 'export default ()=>({isUpdateReady:false,uiState:"idle",errorMessage:"",applyUpdate:()=>{}});';
  if(id==='\0piyali-settings-firestore')return 'export const doc=()=>({}),updateDoc=async()=>{};';
  if(id==='\0piyali-settings-database')return 'export const database={};';
  if(id==='\0piyali-settings-wallet')return 'const state={walletBalance:0,cashuWallet:null,invoice:"",isCreatingWallet:false,errorMessage:"",init:async()=>false,initWallet:async()=>null,createNewWallet:async()=>{},initiateDeposit:async()=>{}};export const useNostrWalletStore=fn=>fn(state);useNostrWalletStore.getState=()=>state;';
  if(id==='\0piyali-settings-goal')return 'export const astraGoalsEnabled=()=>true,saveLearningGoal=async payload=>{window.dispatchEvent(new CustomEvent("public-settings-goal",{detail:payload}))};';
  if(id==='\0piyali-settings-gemini')return 'export const createGeminiLiveVoicePreviewPlayer=async()=>({play:async()=>{},stop:()=>{},cleanup:()=>{}});';
  if(id==='\0piyali-settings-tts'){
   const source=await fs.readFile(path.join(reference,'src/utils/tts.js'),'utf8'),ast=parse(source,{sourceType:'module'});let bindings;
   traverse(ast,{Program(p){bindings=p.scope.bindings;p.stop()}});
   const names=['DEFAULT_TTS_VOICE','SUPPORTED_TTS_VOICES','TTS_VOICE_OPTIONS','sanitizeVoice','normalizeTTSVoice','getTTSVoiceOption','TTS_LANG_TAG'];
   return names.map(name=>{const p=bindings[name]?.path;if(!p)throw Error('Settings TTS source moved: '+name);return (p.isVariableDeclarator()?'const ':'')+source.slice(p.node.start,p.node.end)+(p.isVariableDeclarator()?';':'')}).join('\n')+'\nexport {DEFAULT_TTS_VOICE,TTS_VOICE_OPTIONS,normalizeTTSVoice,getTTSVoiceOption,TTS_LANG_TAG};export const warmRealtimeTTS=async()=>{},primeTTSAudio=async()=>{},stopTTSPlayback=()=>{},getTTSPlayer=async()=>({play:async()=>{},stop:()=>{},cleanup:()=>{}});';
  }
 }}
}
