#!/usr/bin/env python3
"""Retain exact cache traces and pair the original/native offline deck frames."""
import argparse,hashlib,io,json
from pathlib import Path
from PIL import Image,ImageCms,ImageDraw
p=argparse.ArgumentParser();p.add_argument('attachments',type=Path);p.add_argument('--result',required=True);p.add_argument('--output',type=Path,default=Path('docs/native/phonics-offline-preparation-b269524d'));a=p.parse_args();dst=a.output;dst.mkdir(exist_ok=True,parents=True)
rows=[v for t in json.loads((a.attachments/'manifest.json').read_text()) for v in t['attachments']];records=[];originals=[]
def retain(file,title,data):
 (dst/file).write_bytes(data);records.append({'file':file,'attachment':title,'sha256':hashlib.sha256(data).hexdigest(),'bytes':len(data)})
def find(title):
 values=[v for v in rows if v['suggestedHumanReadableName'].startswith(title+'_')];assert len(values)==1,(title,len(values));return values[0]
def normal(file):
 im=Image.open(file)
 if im.info.get('icc_profile'):im=ImageCms.profileToProfile(im,ImageCms.ImageCmsProfile(io.BytesIO(im.info['icc_profile'])),ImageCms.createProfile('sRGB'),outputMode='RGB')
 else:im=im.convert('RGB')
 return im.resize((402,874),Image.Resampling.LANCZOS)
for kind in ['goal','repair']:
 for language in ['en','ar']:
  for state in ['front','practice']:
   pair=Image.new('RGB',(804,902),'white');draw=ImageDraw.Draw(pair)
   for i,(side,prefix) in enumerate([('source','Source'),('native','Native')]):
    title=f'{prefix} fresh offline phonics {kind} {state} {language}';row=find(title);data=(a.attachments/row['exportedFileName']).read_bytes();originals.append({'attachment':title,'sha256':hashlib.sha256(data).hexdigest(),'bytes':len(data),'exported_file':row['exportedFileName']})
    pair.paste(normal(a.attachments/row['exportedFileName']),(i*402,28));draw.text((i*402+10,8),f'{prefix} / {kind} / {state} / {language}',fill='#242424')
    if (kind,language,state) in [('goal','en','front'),('repair','ar','practice')]:retain(f'{side}-{kind}-{state}-{language}.png',title,data)
   buf=io.BytesIO();pair.save(buf,format='PNG',icc_profile=ImageCms.ImageCmsProfile(ImageCms.createProfile('sRGB')).tobytes());retain(f'{kind}-{state}-{language}-pair.png',f'Original source left, native right: {kind} {state} {language}',buf.getvalue())
  for typ,title in [('input',f'Public fresh offline phonics {kind} {language} input'),('cache-trace',f'Source fresh offline phonics {kind} {language} cache trace')]:
   row=find(title);retain(f'{kind}-{language}-{typ}.json',title,(a.attachments/row['exportedFileName']).read_bytes())
manifest={'reference_revision':'b269524ddc578027c549616fc47f5954991d9f6f','native_base':'83e09632f47e5b7e7a092c5385f29e675fd4a582','qa_device':'CE8248B6-7171-4FD4-97DE-89E499107F82','comparison_bundle':a.result,'scope':'Unmodified original focused Phonics component and complete cache/factory functions, with remote reads/transactions explicitly failing against public stores. Native fresh preparation and Practice use an injected failing progress service. English/light and Arabic/dark content frames at 402x874; no full browser authentication/routing, physical speech or whole-shell design claim.','original_captures':originals,'artifacts':records}
(dst/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n');print(len(records),'artifacts;',len(originals),'original hashes; eight paired states.')
