#!/usr/bin/env python3
"""Publish only completed source/native legacy comparisons and their metrics."""
import argparse,hashlib,io,json
from pathlib import Path
from PIL import Image,ImageCms
p=argparse.ArgumentParser();p.add_argument('attachments',type=Path);p.add_argument('--result',required=True);a=p.parse_args()
rows=[r for t in json.loads((a.attachments/'manifest.json').read_text()) for r in t['attachments']];records=[]
for language in ['en','ar']:
 for state in ['world','dialogue','inventory']:
  for prefix,folder in [('Source','reference'),('Native','native')]:
   matches=[r for r in rows if r['suggestedHumanReadableName'].startswith(f'{prefix} legacy {state} {language}_') and r['exportedFileName'].endswith('.png')]
   assert len(matches)==1,(prefix,state,language,len(matches))
   raw=a.attachments/matches[0]['exportedFileName'];im=Image.open(raw);profile=im.info.get('icc_profile');im=im.convert('RGB')
   if profile:im=ImageCms.profileToProfile(im,ImageCms.ImageCmsProfile(io.BytesIO(profile)),ImageCms.createProfile('sRGB'),outputMode='RGB')
   dest=Path('docs')/folder/f'legacy-{state}-{language}.png';im.resize((402,874),Image.Resampling.LANCZOS).save(dest,optimize=True);records.append({'file':str(dest),'sha256':hashlib.sha256(dest.read_bytes()).hexdigest(),'attachment':matches[0]['suggestedHumanReadableName']})
  metrics=[r for r in rows if r['suggestedHumanReadableName'].startswith(f'Source legacy {state} {language} metrics_')]
  assert len(metrics)==1,(state,language,'metrics',len(metrics))
  dest=Path('docs/reference')/f'legacy-{state}-{language}-metrics.json';dest.write_bytes((a.attachments/metrics[0]['exportedFileName']).read_bytes());records.append({'file':str(dest),'sha256':hashlib.sha256(dest.read_bytes()).hexdigest(),'attachment':metrics[0]['suggestedHumanReadableName']})
Path('docs/reference/exploration-captures.json').write_text(json.dumps({'result':a.result,'viewport':{'width':402,'height':874},'states':'Original GameRouter/legacy renderer and native SwiftUI/SpriteKit using the same public search-chapter scenario. Original source cast is randomly assigned. Native legacy cast retains saved names; exact cast/name parity and ambient decoration remain open. This is renderer evidence, not a normal root-product launch.','records':records},indent=2)+'\n');print(f'Published {len(records)} capture/metric records')
