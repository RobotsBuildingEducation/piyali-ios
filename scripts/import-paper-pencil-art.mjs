// Publish current iPhone WebKit/native manga comparisons. The app uses the
// unmodified reference WebP; screenshots remain verification artifacts.
import fs from'node:fs/promises';import path from'node:path';import{createHash}from'node:crypto';
const attachments=process.argv[2],result=process.argv[3];if(!attachments||!result)throw Error('Pass exported attachments and source xcresult name');
const rows=JSON.parse(await fs.readFile(path.join(attachments,'manifest.json'),'utf8')).flatMap(t=>t.attachments),records=[],hash=data=>createHash('sha256').update(data).digest('hex');
async function keep(label,destination){const matches=rows.filter(r=>r.suggestedHumanReadableName.startsWith(label+'_'));if(matches.length!==1)throw Error('Expected one '+label);const r=matches[0],data=await fs.readFile(path.join(attachments,r.exportedFileName));await fs.mkdir(path.dirname(destination),{recursive:true});await fs.writeFile(destination,data);records.push({file:destination,sha256:hash(data),attachment:r.suggestedHumanReadableName});return data}
for(const [width,height]of[[320,568],[375,667],[402,874],[874,402]])for(const language of['en','ar']){
 const label=`${language} ${width}x${height}`;
 for(const kind of['Source','Native']){
  const destination=kind==='Source'?`docs/reference/paper-pencil/current-${language}-${width}x${height}`:`docs/native/paper-pencil-current-${language}-${width}x${height}`;
  const png=await keep(`${kind} manga Paper modal ${label}`,destination+'.png');await keep(`${kind} manga Paper geometry ${label}`,destination+'.json');
  if(width===402)await fs.writeFile(kind==='Source'?`docs/reference/paper-pencil/source-${language}.png`:`docs/native/paper-pencil-${language}.png`,png);
 }
}
const resource='Piyali/Resources/paper-pencil-manga.webp',original=path.resolve('../nosabos/nosabos/src/assets/paper_pencil_manga.webp'),art=await fs.readFile(resource);if(hash(art)!==hash(await fs.readFile(original)))throw Error('Native manga differs from reference');
await fs.writeFile('docs/reference/paper-pencil-manga-captures.json',JSON.stringify({result,artwork:{resource,sha256:hash(art),bytes:art.length},scope:'Current original modal in iPhone WebKit and native SwiftUI, English/light and Arabic/dark at 320x568, 375x667, 402x874 and 874x402. Original body-click/Understood callbacks execute; provider/identity/sound I/O disabled. Earlier SVG/motion files are historical and no longer describe the current artwork.',records},null,2)+'\n');console.log('Published',records.length,'current manga comparison/metric records.');
if(rows.some(r=>r.suggestedHumanReadableName.startsWith('Native manga initial onboarding paper '))){
 const product=[];
 for(const language of['en','ar'])for(const[key,label]of[['initial','Native manga initial onboarding paper'],['companion','Native manga companion paper'],['setup','Native manga paper to original setup'],['returning','Native manga returning initial paper']]){
  const destination=`docs/native/paper-pencil-${key}-${language}-product.png`;await keep(label+' '+language,destination);product.push(records.at(-1));
 }
 await fs.writeFile('docs/reference/paper-pencil-manga-product-captures.json',JSON.stringify({result,scope:'Actual isolated signup; initial modal before onboarding with blocked underlying controls and session-only close; companion-triggered acknowledgment/setup/placement; settings reopening; returning process mounts and per-language placement. Public offline QA accounts, no prefilled acknowledgment/XP or external service writes.',records:product},null,2)+'\n');console.log('Published eight current first-run product captures.');
}
