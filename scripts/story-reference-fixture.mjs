// Extract the reference's literal browser fixture as data, never execute JSX.
export function storyReferenceFixture(source,parser) {
 const ast=parser.parse(source,{sourceType:'module',plugins:['jsx']});
 const declaration=ast.program.body.flatMap(node=>node.type==='VariableDeclaration'?node.declarations:[]).find(node=>node.id.name==='episode');
 function literal(node) {
  if(['StringLiteral','NumericLiteral','BooleanLiteral'].includes(node?.type)) return node.value;
  if(node?.type==='NullLiteral') return null;
  if(node?.type==='ArrayExpression') return node.elements.map(literal);
  if(node?.type==='ObjectExpression') return Object.fromEntries(node.properties.map(property=>{
   if(property.type!=='ObjectProperty'||property.computed) throw Error('Fixture gained an effectful property');
   return [property.key.name ?? property.key.value,literal(property.value)];
  }));
  throw Error('Source story fixture is no longer literal data');
 }
 return literal(declaration?.init);
}
