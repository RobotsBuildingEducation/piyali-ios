// Only pure source prompt/presentation expressions; no lifecycle or network effects.
export function readingPolicyFragments({source,parser,traverse}) {
 const ast=parser.parse(source,{sourceType:'module',plugins:['jsx']}),prompts=new Map();
 const wanted=new Map([['checkReviewAnswer','judge'],['explainReviewAnswer','explain'],['translateLectureLines','translate'],['gradeSpeechAttempt','speech']]);
 traverse(ast,{VariableDeclarator(path){if(path.node.id.name!=='prompt') return;const fn=path.findParent(p=>p.isFunctionDeclaration());const operation=wanted.get(fn?.node.id.name);if(operation) prompts.set(operation,source.slice(path.node.init.start,path.node.init.end));}});
 if(prompts.size!==wanted.size) throw Error('Reading prompt locations moved; review extraction.');
 const captures=new Set(['LANG_NAME','viewLecture','reviewQuestion','reviewAnswer','targetLang','supportLang','targetSentences','originalText','speechTranscript','langName','supportName']);
 for(const expression of prompts.values()) traverse(parser.parse('const prompt='+expression,{sourceType:'module'}),{ReferencedIdentifier(p){if(!p.scope.getBinding(p.node.name)&&!captures.has(p.node.name)) throw Error('Unexpected reading prompt dependency '+p.node.name);}});
 let criteria,color,unavailable;
 traverse(ast,{VariableDeclarator(p){if(p.node.id.name==='SPEECH_CRITERIA') criteria=source.slice(p.node.init.start,p.node.init.end);},FunctionDeclaration(p){if(p.node.id.name==='speechScoreColor') color=source.slice(p.node.start,p.node.end);},CallExpression(p){if(p.node.callee.name!=='setSpeechFeedback'||p.findParent(n=>n.isFunctionDeclaration())?.node.id.name!=='gradeSpeechAttempt') return;const summary=p.node.arguments[0]?.properties?.find(n=>n.key.name==='summary')?.value;if(summary?.callee?.name==='uiCopy'&&summary.arguments[1]?.type==='ObjectExpression') unavailable=source.slice(summary.arguments[1].start,summary.arguments[1].end);}});
 if(!criteria||!color||!unavailable) throw Error('Reading speech presentation moved; review extraction.');
 return {code:`const viewLecture={target:p.passage||''},reviewQuestion=p.reviewQuestion||{},reviewAnswer=p.answer||'',targetLang=p.targetLang,supportLang=p.supportLang,targetSentences=p.sentences||[],originalText=viewLecture.target,speechTranscript=reviewAnswer,langName=LANG_NAME(targetLang),supportName=LANG_NAME(supportLang);\n${[...prompts].map(([key,value])=>`if(operation===${JSON.stringify(key)}) return ${value};`).join('\n')}\nthrow Error('Unsupported reading operation');`,bindings:[...wanted.keys()].map(name=>name+':prompt'),criteria,color,unavailable};
}
