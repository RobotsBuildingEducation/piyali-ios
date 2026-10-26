#!/usr/bin/env python3
import argparse,io,json
from pathlib import Path
from PIL import Image,ImageCms,ImageDraw
p=argparse.ArgumentParser();p.add_argument('attachments',type=Path);p.add_argument('--products-only',action='store_true');p.add_argument('--output',type=Path,default=Path('docs/native'));a=p.parse_args();a.output.mkdir(parents=True,exist_ok=True)
rows=[v for t in json.loads((a.attachments/'manifest.json').read_text())for v in t['attachments']]
def find(title):
 matches=[r for r in rows if r['suggestedHumanReadableName'].startswith(title+'_')and r['exportedFileName'].endswith('.png')];assert len(matches)==1,(title,len(matches));im=Image.open(a.attachments/matches[0]['exportedFileName']);profile=im.info.get('icc_profile');im=im.convert('RGB')
 if profile:im=ImageCms.profileToProfile(im,ImageCms.ImageCmsProfile(io.BytesIO(profile)),ImageCms.createProfile('sRGB'),outputMode='RGB')
 return im.resize((402,874),Image.Resampling.LANCZOS)
if not a.products_only:
 for lang in ['en','ar']:
  for state in ['empty','earned','robots','pending','storage']:
   out=Image.new('RGB',(804,902),'white');out.paste(find(f'Source Achievements {state} {lang}'),(0,28));out.paste(find(f'Native Achievements {state} {lang}'),(402,28));d=ImageDraw.Draw(out);d.text((12,8),'Web reference',fill='black');d.text((414,8),'Native Swift',fill='black');dest=a.output/f'achievements-{state}-{lang}.png';out.save(dest,optimize=True);print(dest)
for title,filename in [('Native achievement collection from Focus','achievements-product-focus.png'),('Native achievement cross-platform tab','achievements-product-robots.png'),('Native achievement collection scrolled with fixed footer','achievements-product-scroll.png'),('Native achievement collection after relaunch','achievements-product-relaunch.png')]:
 if any(r['suggestedHumanReadableName'].startswith(title+'_')for r in rows):dest=a.output/filename;find(title).save(dest,optimize=True);print(dest)
