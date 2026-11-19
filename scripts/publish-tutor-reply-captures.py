#!/usr/bin/env python3
"""Publish original AlignedBubble/native pairs or the normal Tutor product journey."""
import argparse,hashlib,io,json
from pathlib import Path
from PIL import Image,ImageCms
p=argparse.ArgumentParser();p.add_argument('attachments',type=Path);p.add_argument('--result',required=True);p.add_argument('--product',action='store_true');a=p.parse_args();rows=[r for t in json.loads((a.attachments/'manifest.json').read_text()) for r in t['attachments']];records=[]
def keep(label,dest,width=None):
 matches=[r for r in rows if r['suggestedHumanReadableName'].startswith(label+'_')];assert len(matches)==1,(label,len(matches));r=matches[0];src=a.attachments/r['exportedFileName'];dest=Path(dest)
 if src.suffix=='.png':
  im=Image.open(src);profile=im.info.get('icc_profile');im=im.convert('RGB')
  if profile:im=ImageCms.profileToProfile(im,ImageCms.ImageCmsProfile(io.BytesIO(profile)),ImageCms.createProfile('sRGB'),outputMode='RGB')
  if width:im=im.resize((width,round(im.height*width/im.width)),Image.Resampling.LANCZOS)
  im.save(dest,optimize=True)
 else:dest.write_bytes(src.read_bytes())
 records.append({'file':str(dest),'sha256':hashlib.sha256(dest.read_bytes()).hexdigest(),'attachment':r['suggestedHumanReadableName']})
if a.product:
 states={'reply':'Native Tutor long reply with translated phrase cards','selected':'Native Tutor repeated phrases selected','paused':'Native Tutor long reply paused controls','history':'Native Tutor long reply retained in private history','relaunch':'Native Tutor long reply stays private after relaunch'}
 for language in ['en','ar']:
  for key,label in states.items():keep(label+' '+language,f'docs/native/tutor-reply-{key}-{language}-product.png',402)
 name='product';scope='Normal native entry/onboarding/product menu, scripted voice protocol welcome/target response with original translation pipeline, four phrase cards, actual phrase tap/selection, anchored mute/pause/resume/end, private history and process relaunch. Isolated QA identity and explicit public provider fixture; no prefilled progress or physical/live-provider claim.'
else:
 for width in [375,402]:
  for language in ['en','ar']:
   for state in ['short','long','hidden']:
    key=f'{language}-{width}-{state}'
    for prefix,directory in [('Source','reference'),('Native','native')]:keep(f'{prefix} Tutor reply {language} {width} {state}',f'docs/{directory}/tutor-reply-{key}.png',width)
    keep(f'Source Tutor reply {language} {width} {state} metrics',f'docs/reference/tutor-reply-{key}-metrics.json')
 name='comparison';scope='Original source AlignedBubble and native TutorReplyView at 375x667 and 402x874, English/light and Arabic/dark support, short/long/hidden translations, repeated/overlapping visible phrases and excluded absent pairs. Original replay callback and phrase click execute. Native panel width/height compared to original computed bounds. Shared neutral backdrop; no whole-product, motion, physical-audio or provider-quality claim.'
Path(f'docs/reference/tutor-reply-{name}-captures.json').write_text(json.dumps({'result':a.result,'scope':scope,'records':records},indent=2)+'\n');print('Published',len(records),'records')
