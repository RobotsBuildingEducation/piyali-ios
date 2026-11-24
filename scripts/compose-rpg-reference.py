#!/usr/bin/env python3
import argparse,io,json
from pathlib import Path
from PIL import Image,ImageCms,ImageDraw
p=argparse.ArgumentParser();p.add_argument('attachments',type=Path);p.add_argument('--products',type=Path);p.add_argument('--output',type=Path,default=Path('docs/native'));a=p.parse_args();a.output.mkdir(parents=True,exist_ok=True);rows=[v for t in json.loads((a.attachments/'manifest.json').read_text()) for v in t['attachments']]
for lang in ['en','ar']:
 for state in ['world','quest','inventory','companion']:
  imgs=[]
  for prefix in ['Source','Native']:
   matches=[r for r in rows if r['suggestedHumanReadableName'].startswith(f'{prefix} RPG {state} {lang}_') and r['exportedFileName'].endswith('.png')];assert len(matches)==1,(prefix,state,lang,len(matches))
   im=Image.open(a.attachments/matches[0]['exportedFileName']);profile=im.info.get('icc_profile');im=im.convert('RGB')
   if profile:im=ImageCms.profileToProfile(im,ImageCms.ImageCmsProfile(io.BytesIO(profile)),ImageCms.createProfile('sRGB'),outputMode='RGB')
   imgs.append(im.resize((402,874),Image.Resampling.LANCZOS))
  out=Image.new('RGB',(804,902),'white');out.paste(imgs[0],(0,28));out.paste(imgs[1],(402,28));draw=ImageDraw.Draw(out);draw.text((12,8),'Web reference',fill='black');draw.text((414,8),'Native Swift',fill='black');dest=a.output/f'rpg-{state}-{lang}.png';out.save(dest,optimize=True);print(dest)

if a.products:
 productRows=[v for t in json.loads((a.products/'manifest.json').read_text()) for v in t['attachments']]
 for title,name in [('Native source-art course game','rpg-product'),('Native RPG choice','rpg-dialogue-product'),('Native RPG pending task restored','rpg-restored-product'),('Native RPG resolved speech','rpg-speech-product'),('Native RPG completion','rpg-completion-product'),('Native actual game lesson reward','rpg-reward-product')]:
  matches=[r for r in productRows if r['suggestedHumanReadableName'].startswith(title+'_') and r['exportedFileName'].endswith('.png')];assert len(matches)==1,(title,len(matches))
  im=Image.open(a.products/matches[0]['exportedFileName']);profile=im.info.get('icc_profile');im=im.convert('RGB')
  if profile:im=ImageCms.profileToProfile(im,ImageCms.ImageCmsProfile(io.BytesIO(profile)),ImageCms.createProfile('sRGB'),outputMode='RGB')
  im.resize((402,874),Image.Resampling.LANCZOS).save(a.output/(name+'.png'),optimize=True)
