const string={type:'string'};
const object=properties=>({type:'object',properties,required:Object.keys(properties),additionalProperties:false});
const turn=object({speaker:string,target:string,support:string});
const question=object({type:{type:'string',enum:['choice','true_false','select_words','order_words','reply']},prompt:string,options:{type:'array',items:string,maxItems:8},answer:{type:'array',items:{type:'integer'},maxItems:8},explanation:string,audioTurn:{type:'integer',minimum:0,maximum:5}});
export function storyOutputFormat(profile) {
 const schema=profile==='story_speaking' ? object({title:string,sentences:{type:'array',items:turn,minItems:2,maxItems:10}})
  : profile==='story_episode' ? object({title:string,segments:{type:'array',items:object({turns:{type:'array',items:turn,minItems:2,maxItems:6},question}),minItems:2,maxItems:4}}) : null;
 return schema ? {type:'json_schema',name:profile,strict:true,schema} : null;
}
