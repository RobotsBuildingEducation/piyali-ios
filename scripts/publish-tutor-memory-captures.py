#!/usr/bin/env python3
"""Publish public Tutor/Memory component pairs and the normal native UI journey."""
import argparse,hashlib,io,json
from pathlib import Path
from PIL import Image,ImageCms,ImageDraw
p=argparse.ArgumentParser();p.add_argument('--comparison',type=Path,required=True);p.add_argument('--journey',type=Path,required=True);p.add_argument('--output',type=Path,required=True);p.add_argument('--result',required=True);a=p.parse_args();a.output.mkdir(parents=True,exist_ok=True);records=[]
def keep(directory,label,name,width=402):
 rows=[r for t in json.loads((directory/'manifest.json').read_text()) for r in t['attachments']]
 matches=[r for r in rows if r['suggestedHumanReadableName'].startswith(label+'_')];assert len(matches)==1,(label,len(matches));row=matches[0];src=directory/row['exportedFileName'];dest=a.output/name
 if src.suffix=='.png':
  image=Image.open(src);profile=image.info.get('icc_profile');image=image.convert('RGB')
  if profile:image=ImageCms.profileToProfile(image,ImageCms.ImageCmsProfile(io.BytesIO(profile)),ImageCms.createProfile('sRGB'),outputMode='RGB')
  image=image.resize((width,round(image.height*width/image.width)),Image.Resampling.LANCZOS);image.save(dest,optimize=True)
 else:dest.write_bytes(src.read_bytes())
 record(dest,attachment=row['suggestedHumanReadableName']);return dest

def record(file,**extra):records.append({'file':file.name,'sha256':hashlib.sha256(file.read_bytes()).hexdigest(),**extra})
for language in ['en','ar']:
 for state in ['captured','drawer']:
  images=[]
  for side in ['Source','Native']:images.append(keep(a.comparison,f'{side} Tutor Memory {state} {language}',f'{side.lower()}-{state}-{language}.png'))
  pair=Image.new('RGB',(804,902),'#dedede');draw=ImageDraw.Draw(pair)
  for index,file in enumerate(images):pair.paste(Image.open(file),(index*402,28));draw.text((index*402+10,8),('Source' if index==0 else 'Native')+' '+language,fill='black')
  dest=a.output/f'pair-{state}-{language}.png';pair.save(dest,optimize=True);record(dest,scope='sRGB-managed 402×874 logical viewport, source left/native right; no whole-shell claim')
 keep(a.comparison,f'Tutor Memory semantic trace {language}',f'semantic-trace-{language}.json')
for state,label in [('capture','Native Tutor low-confidence semantic Memory capture in product shell'),('enriched','Native captured Tutor Memory enriched after End'),('relaunch','Native Tutor Memory retained exactly once after process relaunch')]:keep(a.journey,label,f'native-product-{state}.png')
(a.output/'manifest.json').write_text(json.dumps({'referenceRevision':'b269524ddc578027c549616fc47f5954991d9f6f','result':a.result,'scope':'Actual source Tutor with public transcript/model/cloud I/O, original initial note builder, actual source NotesDrawer receiving the observed public capture note, native component hosts and full native signup/setup → Tutor → enriched Memory → process-relaunch journey. No source Firebase/enrichment network execution, full-shell source/native equivalence or physical speech claim. Source left, native right.','records':records},indent=2)+'\n');print('Published',len(records),'public captures/traces/pairs')
