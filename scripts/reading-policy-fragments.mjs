// Only source prompt expressions; no component lifecycle or network effects.
export function readingPolicyFragments({source,parser,traverse}) {
 const ast=parser.parse(source,{sourceType:'module',plugins:['jsx']}),prompts=new Map();
 const wanted=new Map([['checkReviewAnswer','judge'],['explainReviewAnswer','explain'],['translateLectureLines','translate']]);
 traverse(ast,{VariableDeclarator(path){if(path.node.id.name!=='prompt') return;const fn=path.findParent(p=>p.isFunctionDeclaration());const operation=wanted.get(fn?.node.id.name);if(operation) prompts.set(operation,source.slice(path.node.init.start,path.node.init.end));}});
 if(prompts.size!==wanted.size) throw Error('Reading prompt locations moved; review extraction.');
 const captures=new Set(['LANG_NAME','viewLecture','reviewQuestion','reviewAnswer','targetLang','supportLang','targetSentences']);
 for(const expression of prompts.values()) traverse(parser.parse('const prompt='+expression,{sourceType:'module'}),{ReferencedIdentifier(p){if(!p.scope.getBinding(p.node.name)&&!captures.has(p.node.name)) throw Error('Unexpected reading prompt dependency '+p.node.name);}});
 return {code:`const viewLecture={target:p.passage||''},reviewQuestion=p.reviewQuestion||{},reviewAnswer=p.answer||'',targetLang=p.targetLang,supportLang=p.supportLang,targetSentences=p.sentences||[];\n${[...prompts].map(([key,value])=>`if(operation===${JSON.stringify(key)}) return ${value};`).join('\n')}\nthrow Error('Unsupported reading operation');`,bindings:[...wanted.keys()].map(name=>name+':prompt')};
}
