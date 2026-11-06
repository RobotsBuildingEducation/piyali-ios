#!/usr/bin/env python3
"""Retain original JSX/native authored recap pairs and the complete product replay."""
import argparse,hashlib,io,json
from pathlib import Path
from PIL import Image,ImageCms
p=argparse.ArgumentParser();p.add_argument('attachments',type=Path);p.add_argument('--result',required=True);p.add_argument('--product',action='store_true');a=p.parse_args();rows=[r for t in json.loads((a.attachments/'manifest.json').read_text()) for r in t['attachments']];records=[]
def publish(label,destination,width=None):
 matches=[r for r in rows if r['suggestedHumanReadableName'].startswith(label+'_')];assert len(matches)==1,(label,len(matches));r=matches[0];raw=a.attachments/r['exportedFileName'];destination=Path(destination)
 if raw.suffix=='.png':
  im=Image.open(raw);profile=im.info.get('icc_profile');im=im.convert('RGB')
  if profile:im=ImageCms.profileToProfile(im,ImageCms.ImageCmsProfile(io.BytesIO(profile)),ImageCms.createProfile('sRGB'),outputMode='RGB')
  if width:im=im.resize((width,round(im.height*width/im.width)),Image.Resampling.LANCZOS)
  im.save(destination,optimize=True)
 else:destination.write_bytes(raw.read_bytes())
 records.append({'file':str(destination),'sha256':hashlib.sha256(destination.read_bytes()).hexdigest(),'attachment':r['suggestedHumanReadableName']})
if a.product:
 states={'world':'Native prepared chapter world','cancel':'Native prepared speech cancellation','resume':'Native prepared chapter restored','recap':'Native prepared chapter recap','reward':'Native prepared lesson reward precedes celebration','goal':'Native prepared daily goal celebration','replay':'Native cached prepared replay','replay-recap':'Native cached replay two star recap','relaunch':'Native replay returns to completed path after relaunch'}
 for key,label in states.items():publish(label,f'docs/native/rpg-completion-{key}-product.png',402)
 output='docs/reference/rpg-completion-product-captures.json';scope='Normal entry, onboarding and self-reported A1 placement; public prepared seven-task review, pending speech cancellation, Back/process resume, one lesson reward and daily-goal celebration, offline cached full replay with three deliberate first-task misses, two-star recap, completed path and relaunch. Explicit isolated QA identity; no prefilled progress, physical audio or live provider claim.'
else:
 for width in [375,402]:
  for language in ['en','ar']:
   for score in [0,700,800]:
    key=f'{language}-{width}-{score}'
    for prefix,directory in [('Source','reference'),('Native','native')]:publish(f'{prefix} RPG recap {language} {width} {score}',f'docs/{directory}/rpg-completion-{key}.png',width)
    publish(f'Source RPG recap {language} {width} {score} metrics',f'docs/reference/rpg-completion-{key}-metrics.json')
 output='docs/reference/rpg-completion-comparison-captures.json';scope='Original source authored-completion JSX and native reusable recap over a shared neutral backdrop. English/light and Arabic/dark at 375x667 and 402x874; score 0 fallback title, 700/two stars and 800/three stars. Original WaveBar, theme, CSS, fonts and bidi helpers; public prepared scenario. Does not compare maps, transition motion or whole-product parity.'
Path(output).write_text(json.dumps({'result':a.result,'scope':scope,'records':records},indent=2)+'\n');print(f'Published {len(records)} captures/metrics')
