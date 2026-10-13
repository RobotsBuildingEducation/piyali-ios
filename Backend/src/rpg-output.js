// Fixed native RPG formats: callers cannot upload arbitrary provider schemas.
const string={type:'string'};
const object=properties=>({type:'object',properties,required:Object.keys(properties),additionalProperties:false});
const bilingual=object({target:string,support:string});
const beat=object({mode:{type:'string',enum:['choice','speech']},sceneLine:string,coverage:string,npcLine:string,
 options:{type:'array',items:string,minItems:0,maxItems:3},correctIndex:{type:['integer','null'],minimum:0,maximum:2},
 speechGoal:string,speechExample:string,concept:string,expectedAnswer:string,right:string,wrong:string});
export function rpgOutputFormat(profile) {
 const schema=profile==='rpg_story' ? object({title:string,intro:bilingual,personas:{type:'array',items:string,maxItems:8},beats:{type:'array',items:beat,minItems:7,maxItems:7},epilogue:bilingual})
  : profile==='rpg_speech' ? object({grade:{type:'string',enum:['full','partial','miss']},reply:string,tip:string}) : null;
 return schema ? {type:'json_schema',name:profile,strict:true,schema} : null;
}
