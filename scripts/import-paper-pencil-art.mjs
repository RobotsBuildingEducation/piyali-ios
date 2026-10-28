// Import authored, transparent layers captured by PaperPencilReferenceTests on iPhone WebKit.
import fs from 'node:fs/promises';
import path from 'node:path';
import {createHash} from 'node:crypto';
const source=process.argv[2];if(!source)throw Error('Pass xcresult exported attachment directory');
const manifest=JSON.parse(await fs.readFile(path.join(source,'manifest.json'),'utf8')).flatMap(row=>row.attachments);
const find=prefix=>{const matches=manifest.filter(row=>row.suggestedHumanReadableName.startsWith(prefix+'_0_'));if(matches.length!==1)throw Error('Expected one '+prefix);return matches[0]};
const read=async prefix=>fs.readFile(path.join(source,find(prefix).exportedFileName));
const root='docs/reference/paper-pencil',hash=bytes=>createHash('sha256').update(bytes).digest('hex'),rows=[];await fs.mkdir(root,{recursive:true});
for(const theme of ['light','dark'])for(const layer of ['header','base','pencil','sparkle-left','sparkle-right','tail']){
 const png=await read(`Paper art ${theme} ${layer}`),svg=await read(`Paper SVG ${theme} ${layer}`),width=png.readUInt32BE(16),height=png.readUInt32BE(20);if(width!==(layer==='header'?192:1020)||height!==(layer==='header'?192:588))throw Error('Unexpected PNG scale');
 if(layer==='header'&&theme==='dark'){if(hash(svg)!==rows.find(row=>row.layer==='header').svgSHA256)throw Error('Header differs by theme');continue;}
 const name='PaperPencil-'+(layer==='header'?'header':theme+'-'+layer),dir=`Piyali/Resources/BrandAssets.xcassets/${name}.imageset`;await fs.mkdir(dir,{recursive:true});await fs.writeFile(dir+'/art@3x.png',png);await fs.writeFile(dir+'/Contents.json',JSON.stringify({images:[{idiom:'universal',filename:'art@3x.png',scale:'3x'}],info:{author:'xcode',version:1}},null,2)+'\n');await fs.writeFile(`${root}/${theme}-${layer}.svg`,svg);rows.push({theme,layer,asset:name,width,height,pngSHA256:hash(png),svgSHA256:hash(svg)});
}
for(const language of ['en','ar']){await fs.writeFile(`${root}/source-${language}.png`,await read('Source Paper modal '+language));await fs.writeFile(`${root}/source-${language}.json`,await read('Source Paper geometry and motion '+language));}
await fs.writeFile(`${root}/art-manifest.json`,JSON.stringify({renderer:'iPhone WebKit, iOS 26.4.1, 3x transparent authored SVG layers',sourceCommit:'5c8f8f0595f31a0d6532d660cad73135e8223cc2',rows},null,2)+'\n');console.log('Imported '+rows.length+' authored assets and two source geometry/motion captures.');
