// Lift the reference's lexical conversation prompt with explicit private state.
export function conversationPolicyFragments({source,parser,traverse}) {
 const ast=parser.parse(source,{sourceType:'module',plugins:['jsx']});let fragment;
 traverse(ast,{FunctionDeclaration(p){if(p.node.id?.name==='buildLanguageInstructionsBase') fragment=source.slice(p.node.start,p.node.end);}});
 if(!fragment) throw Error('Conversation source prompt moved; review extraction.');
 const captured=new Set(['targetLangRef','voicePersonaRef','conversationSettingsRef','currentGoalRef','goalShepherdRef','useUserStore']);
 const globals=new Set(['String','Number','Boolean','Math','JSON','Object','Array','Date','Set']);const imports=new Set();
 traverse(parser.parse(fragment,{sourceType:'module'}),{ReferencedIdentifier(p){const name=p.node.name;if(!p.scope.getBinding(name)&&!captured.has(name)&&!globals.has(name)) imports.add(name);}});
 imports.add('buildConversationResponseCreateEvent');imports.add('buildConversationTurnDetection');imports.add('buildRealtimeResumeContext');
 return {imports:[...imports],code:`const {${[...imports].join(',')}}=conversationOriginal;
 const targetLangRef={current:p.targetLang},voicePersonaRef={current:p.personality||''},conversationSettingsRef={current:{practicePronunciation:!!p.pronunciation,conversationSubjects:p.interests||''}},currentGoalRef={current:p.goal||null},goalShepherdRef={current:p.guidance||''},useUserStore={getState:()=>({user:p.user||{}})};
 ${fragment}
 const instructions=[buildLanguageInstructionsBase(),buildRealtimeResumeContext(p.messages||[])].filter(Boolean).join('\\n\\n');
 if(operation==='instructions')return instructions;
 if(operation==='response')return JSON.stringify(buildConversationResponseCreateEvent({sessionInstructions:instructions,persona:p.personality||''}));
 if(operation==='vad')return JSON.stringify(buildConversationTurnDetection(p.pauseMs));
 throw Error('Unsupported conversation policy');`};
}
