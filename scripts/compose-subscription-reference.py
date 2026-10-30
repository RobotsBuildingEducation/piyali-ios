#!/usr/bin/env python3
import argparse,io,json
from pathlib import Path
from PIL import Image,ImageCms,ImageDraw
p=argparse.ArgumentParser();p.add_argument('attachments',type=Path);p.add_argument('--products',type=Path);p.add_argument('--products-only',action='store_true');p.add_argument('--output',type=Path,default=Path('docs/native'));a=p.parse_args();a.output.mkdir(parents=True,exist_ok=True)
def find(directory,title):
 rows=[v for t in json.loads((directory/'manifest.json').read_text()) for v in t['attachments']];matches=[r for r in rows if r['suggestedHumanReadableName'].startswith(title+'_') and r['exportedFileName'].endswith('.png')];assert len(matches)==1,(title,len(matches))
 im=Image.open(directory/matches[0]['exportedFileName']);profile=im.info.get('icc_profile');im=im.convert('RGB')
 if profile:im=ImageCms.profileToProfile(im,ImageCms.ImageCmsProfile(io.BytesIO(profile)),ImageCms.createProfile('sRGB'),outputMode='RGB')
 return im.resize((402,874),Image.Resampling.LANCZOS)
for lang in ([] if a.products_only else ['en','ar']):
 for state in ['offer','checking','disabled','awaiting','unavailable','migration','replacement','replacement-expired','embedded','active','stale','payment','inactive','disconnect']:
  out=Image.new('RGB',(804,902),'white');out.paste(find(a.attachments,f'Source Subscription {state} {lang}'),(0,28));out.paste(find(a.attachments,f'Native Subscription {state} {lang}'),(402,28));d=ImageDraw.Draw(out);d.text((12,8),'Web reference',fill='black');d.text((414,8),'Native Swift',fill='black');dest=a.output/f'subscription-{state}-{lang}.png';out.save(dest,optimize=True);print(dest)

products=a.products or a.attachments
for title,filename in [
 ('Native subscription after earned quest sequence','subscription-product-trial.png'),
 ('Native subscription iPhone purchases and web link','subscription-product-purchases.png'),
 ('Native subscription offer in Settings','subscription-product-offer.png'),
 ('Native subscription awaiting checkout','subscription-product-awaiting.png'),
 ('Native subscription active membership','subscription-product-active.png'),
 ('Native subscription active after foreground resume','subscription-product-resume.png'),
 ('Native subscription payment issue','subscription-product-payment.png'),
 ('Native subscription disconnect confirmation','subscription-product-disconnect.png'),
 ('Native subscription disconnected after relaunch','subscription-product-relaunch.png'),
]:
 rows=[v for t in json.loads((products/'manifest.json').read_text()) for v in t['attachments']]
 if any(r['suggestedHumanReadableName'].startswith(title+'_') for r in rows):
  dest=a.output/filename;find(products,title).save(dest,optimize=True);print(dest)
