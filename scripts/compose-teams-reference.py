#!/usr/bin/env python3
import argparse,io,json
from pathlib import Path
from PIL import Image,ImageCms,ImageDraw
p=argparse.ArgumentParser();p.add_argument('attachments',type=Path);p.add_argument('--products',type=Path);p.add_argument('--output',type=Path,default=Path('docs/native'));a=p.parse_args();a.output.mkdir(parents=True,exist_ok=True)
def rows(directory):return [v for t in json.loads((directory/'manifest.json').read_text()) for v in t['attachments']]
def find(directory,title):
 matches=[r for r in rows(directory) if r['suggestedHumanReadableName'].startswith(title+'_') and r['exportedFileName'].endswith('.png')];assert len(matches)==1,(title,len(matches))
 im=Image.open(directory/matches[0]['exportedFileName']);profile=im.info.get('icc_profile');im=im.convert('RGB')
 if profile:im=ImageCms.profileToProfile(im,ImageCms.ImageCmsProfile(io.BytesIO(profile)),ImageCms.createProfile('sRGB'),outputMode='RGB')
 return im.resize((402,874),Image.Resampling.LANCZOS)
for lang in ['en','ar']:
 for state in ['empty','single','multi','pending','create','queued','rename','feed']:
  out=Image.new('RGB',(804,902),'white');out.paste(find(a.attachments,f'Source Teams {state} {lang}'),(0,28));out.paste(find(a.attachments,f'Native Teams {state} {lang}'),(402,28));d=ImageDraw.Draw(out);d.text((12,8),'Web reference',fill='black');d.text((414,8),'Native Swift',fill='black');dest=a.output/f'teams-{state}-{lang}.png';out.save(dest,optimize=True);print(dest)
if a.products:
 for title,name in [('Native Teams empty product','teams-product'),('Native Teams queued product','teams-queue-product'),('Native Teams single product','teams-single-product'),('Native Teams restored product','teams-restored-product'),('Native Teams feed product','teams-feed-product')]:
  find(a.products,title).save(a.output/(name+'.png'),optimize=True)
