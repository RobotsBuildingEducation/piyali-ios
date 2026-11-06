// Execute the current reference evaluator as a pure function; never mutate the web checkout.
import fs from 'node:fs/promises';
import path from 'node:path';
import {createHash} from 'node:crypto';
import {createRequire} from 'node:module';
const root=process.cwd(),reference=path.resolve(process.argv[2] || '../nosabos/nosabos');
const file='src/utils/speechEvaluation.js',source=await fs.readFile(path.join(reference,file),'utf8');
const require=createRequire(path.join(reference,'package.json')),{build}=require('esbuild');
const bundle=await build({stdin:{contents:"export { evaluateAttemptStrict } from './src/utils/speechEvaluation.js'",resolveDir:reference},bundle:true,platform:'node',format:'esm',write:false});
const original=await import('data:text/javascript;base64,'+Buffer.from(bundle.outputFiles[0].text).toString('base64'));
const targets=[['ar','هذا البيت جميل'],['el','Το σπίτι είναι όμορφο'],['hi','यह घर अच्छा है'],['ja','今日は母の誕生日です'],['ru','Этот дом красивый'],['zh','今天是她的生日'],['es','Tengo flores rojas'],['en','The flowers are red'],['nah','Nimitztlazohtla nochan']];
const cases=[];
for(const [lang,targetSentence] of targets) for(const recognizedText of [targetSentence,targetSentence.toUpperCase(),`${targetSentence} hello`,'wrong phrase','']) for(const confidence of [0,-0.1,0.2,0.9]) for(const audioMetrics of [null,{duration:1.8,rms:0.04,zeroCrossings:1800},{duration:0.1,rms:0,zeroCrossings:0}]) {
 const input={lang,targetSentence,recognizedText,confidence,audioMetrics};cases.push({input,expected:original.evaluateAttemptStrict(input)});
}
await fs.writeFile(path.join(root,'Tests/PiyaliCoreTests/Fixtures/story-strict-evaluation.json'),JSON.stringify(cases,null,2)+'\n');
await fs.writeFile(path.join(root,'docs/reference/story-strict-evaluation-manifest.json'),JSON.stringify({source:file,sha256:createHash('sha256').update(source).digest('hex'),cases:cases.length,scope:'Original evaluateAttemptStrict and its pure scoring dependencies. Public synthetic transcripts and audio metrics; no network, microphone, user state or rewards.'},null,2)+'\n');
console.log(`Exported ${cases.length} source strict-evaluation cases`);
