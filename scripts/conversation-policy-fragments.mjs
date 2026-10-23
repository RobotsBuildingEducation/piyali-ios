// Lift original lexical prompts with explicit private refs, without React,
// storage, credentials, audio or provider calls.
export function conversationPolicyFragments({source,starterSource,parser,traverse}) {
 const ast=parser.parse(source,{sourceType:'module',plugins:['jsx']});let fragment;const expressions=new Map();
 traverse(ast,{FunctionDeclaration(p){if(p.node.id?.name==='buildLanguageInstructionsBase')fragment=source.slice(p.node.start,p.node.end);},VariableDeclarator(p){const parent=p.findParent(q=>q.isFunctionDeclaration()),name=parent?.node.id?.name;if(['generateConversationTopic','generateContextualGoal','evaluateGoalCompletion'].includes(name)&&p.node.id.name&&p.node.init)expressions.set(name+':'+p.node.id.name,source.slice(p.node.init.start,p.node.init.end));}});
 const value=(fn,name)=>{const result=expressions.get(fn+':'+name);if(!result)throw Error('Conversation source prompt moved: '+fn+':'+name);return result;};
 const prompt=(name,fn,fields,prefix='')=>`function ${name}(){${prefix}${fields.map(field=>`const ${field}=${value(fn,field)};`).join('\n')}return ${value(fn,'prompt')};}`;
 const goal=prompt('sourceInitialGoal','generateConversationTopic',['responseLang','levelDescription','customSubjectsPrompt']);
 const next=prompt('sourceNextGoal','generateContextualGoal',['recentMessages','lastAiMessage','customSubjectsHint','goalAlignmentHint','previousGoalLine']);
 const judge=prompt('sourceConversationJudge','evaluateGoalCompletion',['languageName','feedbackLanguage'],'const goalText=goal.text.en,tLang=targetLangRef.current,sLang=resolvedSupportLang;');
 if(!fragment)throw Error('Conversation instruction builder moved.');
 let starterPrompt,parseStarter;
 traverse(parser.parse(starterSource,{sourceType:'module'}),{VariableDeclarator(p){if(p.node.id.name==='prompt'&&p.findParent(q=>q.isFunctionDeclaration()&&q.node.id.name==='generateStarterPhrase'))starterPrompt=starterSource.slice(p.node.init.start,p.node.init.end);},FunctionDeclaration(p){if(p.node.id.name==='parseStarterPhrase')parseStarter=starterSource.slice(p.node.start,p.node.end);}});
 if(!starterPrompt||!parseStarter)throw Error('Source starter prompt moved.');
 const starter=`function sourceStarter(goal,level,targetName,supportName,lastAiMessage){return ${starterPrompt};}\n${parseStarter}`;
 const fragments=[fragment,goal,next,judge,starter].join('\n');
 const captured=new Set(['targetLangRef','voicePersonaRef','conversationSettingsRef','currentGoalRef','goalShepherdRef','useUserStore','resolvedSupportLang','selectedLevel','customSubjects','skillTreeTopics','messagesRef','currentGoal','goal','previousGoalAbandoned','userMessage','aiResponse']);
 const globals=new Set(['String','Number','Boolean','Math','JSON','Object','Array','Date','Set']);const imports=new Set();
 traverse(parser.parse(fragments,{sourceType:'module'}),{ReferencedIdentifier(p){const name=p.node.name;if(!p.scope.getBinding(name)&&!captured.has(name)&&!globals.has(name))imports.add(name);}});
 for(const name of ['buildConversationResponseCreateEvent','buildConversationTurnDetection','buildRealtimeResumeContext'])imports.add(name);
 return {imports:[...imports],bindings:['buildLanguageInstructionsBase','generateConversationTopic:prompt','generateContextualGoal:prompt','evaluateGoalCompletion:prompt'],code:`const {${[...imports].join(',')}}=conversationOriginal;
 const targetLangRef={current:p.targetLang},voicePersonaRef={current:p.personality||''},conversationSettingsRef={current:{practicePronunciation:!!p.pronunciation,conversationSubjects:p.interests||''}},currentGoalRef={current:p.goal||null},goalShepherdRef={current:p.guidance||''},useUserStore={getState:()=>({user:p.user||{}})},resolvedSupportLang=p.supportLang||'en',selectedLevel=practiceLevelForElo(eloForUser(p.user||{},p.targetLang)),customSubjects=p.interests||'',skillTreeTopics=p.topics||[],messagesRef={current:p.messages||[]},goal=p.goal||{text:{en:''}},currentGoal=goal,previousGoalAbandoned=!!p.abandoned,userMessage=p.utterance||'',aiResponse=p.answered||'';
 ${fragments}
 if(operation==='starter')return sourceStarter(goal.text.en,selectedLevel,getLanguagePromptName(p.targetLang)||'English',getLanguagePromptName(resolvedSupportLang)||'English',[...messagesRef.current].reverse().find(m=>m.role==='assistant')?.textFinal||'');if(operation==='parseStarter')return JSON.stringify(parseStarterPhrase(p.raw));
 if(operation==='goal')return sourceInitialGoal();if(operation==='contextualGoal')return sourceNextGoal();if(operation==='judge')return sourceConversationJudge();
 const instructions=[buildLanguageInstructionsBase(),buildRealtimeResumeContext(p.messages||[])].filter(Boolean).join('\\n\\n');
 if(operation==='instructions')return instructions;
 if(operation==='response')return JSON.stringify(buildConversationResponseCreateEvent({sessionInstructions:instructions,persona:p.personality||''}));
 if(operation==='vad')return JSON.stringify(buildConversationTurnDetection(p.pauseMs));
 throw Error('Unsupported conversation policy');`};
}
