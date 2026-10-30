// Extract the original speaking preparation branch; React and dynamic imports stay out.
export function storyPolicyFragments({source,parser,traverse}) {
 const ast=parser.parse(source,{sourceType:'module',plugins:['jsx']});
 const declaration=ast.program.body.find(node=>node.type==='ExportNamedDeclaration'&&node.declaration?.id?.name==='buildLessonPreparationRecipe')?.declaration;
 const branch=declaration?.body.body[0];
 if(branch?.type!=='IfStatement'||branch.test?.operator!=='!=='||branch.test.right?.value!=='speaking'||branch.test.left?.property?.name!=='storyMode')throw Error('Speaking preparation branch moved; review extraction.');
 const body=source.slice(branch.end,declaration.body.end-1);
 const captures=new Set(['buildStoryDiversityPrompt','createStoryPlan','buildSpeakingStoryPrompt','getStoryDifficulty','focusedLessonPrompt','generationPerformanceContextFor','Boolean','JSON']);
 traverse(parser.parse('function sourceSpeakingPreparation(context,options){'+body+'}',{sourceType:'module'}),{ReferencedIdentifier(p){if(!p.scope.getBinding(p.node.name)&&!captures.has(p.node.name))throw Error('Unexpected speaking policy dependency '+p.node.name);}});
 return {code:'function sourceSpeakingPreparation(context,options){'+body+'}',bindings:[...captures].filter(value=>!['JSON','Boolean'].includes(value))};
}

export function batchWorthFragments({source,parser,traverse}) {
 const ast=parser.parse(source,{sourceType:'module'});
 let fn,prompt,items,fallback,parseValue,parseScores,accept;
 traverse(ast,{FunctionDeclaration(p){if(p.node.id?.name==='assessGeneratedQuestionWorths')fn=p;}});
 if(!fn)throw Error('Batch assessment policy moved');
 fn.traverse({VariableDeclarator(p){const name=p.node.id.name;if(name==='prompt')prompt=p.node.init;if(name==='items')items=p.node.init;if(name==='fallback')fallback=p.node.init;if(name==='value')parseValue=p.node.init;if(name==='scores')parseScores=p.node.init;},IfStatement(p){if(p.node.consequent.type==='BlockStatement'&&p.node.consequent.body[0]?.type==='ReturnStatement'&&p.node.consequent.body[0].argument?.callee?.object?.name==='scores')accept=p.node;}});
 if(![prompt,items,fallback,parseValue,parseScores,accept].every(Boolean))throw Error('Batch assessment statements moved; review extraction');
 const text=node=>source.slice(node.start,node.end);
 return {prompt:`function sourceBatchDifficultyPrompt(p){const {questions,mode,targetLang,questionLevel}=p;const items=${text(items)};return ${text(prompt)};}`,parse:`function sourceBatchWorth(p){const {user,targetLang,questionLevel,questions,raw}=p;const fallback=${text(fallback)};try{const value=${text(parseValue)};const scores=${text(parseScores)};${text(accept)}}catch{}return fallback();}`};
}

export function storyRevisionFragment({source,parser,traverse,name}) {
 let expression;
 traverse(parser.parse(source,{sourceType:'module'}),{ObjectProperty(p){if(p.node.key.name==='buildRevisionPrompt')expression=p.node.value;}});
 if(expression?.type!=='ArrowFunctionExpression')throw Error('Story revision prompt moved');
 return `function ${name}(p){const prompt=p.prompt;return (${source.slice(expression.start,expression.end)})({stage:p.stage,raw:p.raw,error:{message:p.error||''}});}`;
}
