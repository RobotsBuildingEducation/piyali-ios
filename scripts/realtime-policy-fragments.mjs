// Extract the original pure realtime policies, including lexical functions
// inside the React component. Capture only the explicitly listed JSON refs.
export function realtimePolicyFragments({source,parser,traverse}) {
 const ast=parser.parse(source,{sourceType:'module',plugins:['jsx']});
 const names=['computeXpDelta','goalTitleForTarget','goalRubricForTarget','buildLanguageInstructionsBase','buildTutorialGoal'];
 const functions=new Map();let judge;
 traverse(ast,{FunctionDeclaration(p){if(names.includes(p.node.id?.name)) functions.set(p.node.id.name,source.slice(p.node.start,p.node.end));},VariableDeclarator(p){if(p.node.id.name==='judgePrompt' && p.findParent(q=>q.isFunctionDeclaration() && q.node.id.name==='evaluateAndMaybeAdvanceGoal')) judge=source.slice(p.node.init.start,p.node.init.end);}});
 if(functions.size!==names.length || !judge) throw Error('Realtime source policy moved; review extraction.');
 const fragments=[...functions.values(),`function goalJudgePrompt(){return ${judge};}`].join('\n');
 const captured=new Set(['targetLangRef','cefrLevelRef','lessonContentRef','helpRequestRef','practicePronunciationRef','goalRef','lessonContent','curriculumCefrLevel','currentGoal','uiLang','isoNow','titleTL','rubricTL','uiLangName','goal']);
 const globals=new Set(['String','Number','Boolean','Math','JSON','Object','Array','Date','Set']);
 const imports=new Set();
 traverse(parser.parse(fragments,{sourceType:'module'}),{ReferencedIdentifier(p){const name=p.node.name;if(!p.scope.getBinding(name) && !captured.has(name) && !globals.has(name)) imports.add(name);}});
 const code=`const targetLangRef={current:p.targetLang},cefrLevelRef={current:p.cefrLevel},lessonContent=p.lessonContent||{},lessonContentRef={current:lessonContent},helpRequestRef={current:p.helpRequest||''},practicePronunciationRef={current:!!p.pronunciation},goal=p.goal||{},goalRef={current:goal},currentGoal=p.goal||null,uiLang=p.supportLang||'en',curriculumCefrLevel=p.curriculumCefrLevel||p.cefrLevel,isoNow=()=>p.now||'';
 ${fragments}
 const titleTL=goalTitleForTarget(goal),rubricTL=goalRubricForTarget(goal),uiLangName=getLanguagePromptName(uiLang)||'English';
 if(operation==='instructions') return buildLanguageInstructionsBase();
 if(operation==='judge') return goalJudgePrompt()+'\\n\\nUtterance:\\n'+String(p.utterance||'');
 if(operation==='xp') return JSON.stringify(computeXpDelta(p));
 if(operation==='tutorialGoal') return JSON.stringify(buildTutorialGoal());
 throw Error('Unsupported realtime operation');`;
 // The judge wrapper itself uses the imported language-name policy.
 imports.add('getLanguagePromptName');
 return {code,imports:[...imports],bindings:[...names,'evaluateAndMaybeAdvanceGoal:judgePrompt']};
}
