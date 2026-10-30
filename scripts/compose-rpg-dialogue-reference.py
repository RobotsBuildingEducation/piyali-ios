#!/usr/bin/env python3
import argparse,io,json
from pathlib import Path
from PIL import Image,ImageCms,ImageDraw
p=argparse.ArgumentParser();p.add_argument('attachments',type=Path);p.add_argument('--output',type=Path,default=Path('docs/native'));a=p.parse_args();a.output.mkdir(parents=True,exist_ok=True);rows=[r for t in json.loads((a.attachments/'manifest.json').read_text()) for r in t['attachments']]
def picture(prefix):
 matches=[r for r in rows if r['suggestedHumanReadableName'].startswith(prefix+'_') and r['exportedFileName'].endswith('.png')];assert len(matches)==1,(prefix,len(matches));im=Image.open(a.attachments/matches[0]['exportedFileName']);profile=im.info.get('icc_profile');im=im.convert('RGB')
 if profile:im=ImageCms.profileToProfile(im,ImageCms.ImageCmsProfile(io.BytesIO(profile)),ImageCms.createProfile('sRGB'),outputMode='RGB')
 return im.resize((402,874),Image.Resampling.LANCZOS)
for support in ['en','ar']:
 for state in ['translated','undo','partial','failure']:
  out=Image.new('RGB',(804,902),'white');out.paste(picture(f'Source dialogue {state} {support}'),(0,28));out.paste(picture(f'Native dialogue {state} {support}'),(402,28));d=ImageDraw.Draw(out);d.text((12,8),'Web reference',fill='black');d.text((414,8),'Native Swift',fill='black');dest=a.output/f'rpg-dialogue-{state}-{support}.png';out.save(dest,optimize=True);print(dest)
for title,name in [('Native RPG translation partial','partial'),('Native RPG translation complete','complete'),('Native RPG translation close recovery','close-recovery'),('Native RPG translation restored original','restored')]:
 if any(r['suggestedHumanReadableName'].startswith(title+'_') for r in rows):
  dest=a.output/f'rpg-dialogue-{name}-product.png';picture(title).save(dest,optimize=True);print(dest)
