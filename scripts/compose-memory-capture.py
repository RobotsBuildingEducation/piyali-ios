#!/usr/bin/env python3
"""Pair finalized source/native crystal captures; normalize tagged P3 into sRGB."""
import argparse, hashlib, io, json, shutil
from pathlib import Path
from PIL import Image, ImageCms, ImageDraw
p=argparse.ArgumentParser(description=__doc__)
p.add_argument('components',type=Path);p.add_argument('journey',type=Path)
p.add_argument('--output',type=Path,default=Path('docs/native/exercise-notes-memory-capture-b269524d'))
a=p.parse_args();a.output.mkdir(parents=True,exist_ok=True);records=[]
def attachments(folder):return [i for t in json.loads((folder/'manifest.json').read_text())for i in t['attachments']]
def record(file,bundle,**kwargs):records.append(dict(file=file,sha256=hashlib.sha256((a.output/file).read_bytes()).hexdigest(),resultBundle=bundle,**kwargs))
rows=attachments(a.components);srgb=ImageCms.createProfile('sRGB')
for theme in ['light','dark']:
 for ms,reduced in [(500,False),(1600,False),(2300,False),(1600,True)]:
  state=f'{theme} {ms} '+('reduced'if reduced else'motion');name=state.replace(' ','-');pair=Image.new('RGB',(640,350),'white')
  for index,prefix in enumerate(['Source','Native']):
   item=next(i for i in rows if i['suggestedHumanReadableName'].startswith(prefix+' Memory capture '+state+'_'));image=Image.open(a.components/item['exportedFileName'])
   profile=image.info.get('icc_profile');image=ImageCms.profileToProfile(image,ImageCms.ImageCmsProfile(io.BytesIO(profile)),srgb,outputMode='RGB')if profile else image.convert('RGB')
   pair.paste(image.resize((402,400)).crop((121,142,281,302)).resize((320,320)),(320*index,30))
  draw=ImageDraw.Draw(pair);draw.text((8,8),'Web source '+state,fill='black');draw.text((328,8),'Native Swift',fill='black');file='capture-'+name+'.png';pair.save(a.output/file,optimize=True,icc_profile=ImageCms.ImageCmsProfile(srgb).tobytes());record(file,'/tmp/PiyaliMemoryCaptureFinalPaint20261105.xcresult')
  item=next(i for i in rows if i['suggestedHumanReadableName'].startswith('Source Memory metrics '+state+'_'));file='capture-'+name+'.json';shutil.copyfile(a.components/item['exportedFileName'],a.output/file);record(file,'/tmp/PiyaliMemoryCaptureFinalPaint20261105.xcresult')
rows=attachments(a.journey)
for prefix,file in [('Native pending exercise note captured','pending-note-after-next.png'),('Native advanced exercise note retained','note-in-memory.png')]:
 item=next(i for i in rows if i['suggestedHumanReadableName'].startswith(prefix));shutil.copyfile(a.journey/item['exportedFileName'],a.output/file);record(file,'/tmp/PiyaliMemoryCaptureStable20261105.xcresult',scope='Passing full isolated product journey, before final paint-only shadow clipping calibration.')
(a.output/'manifest.json').write_text(json.dumps(dict(referenceCommit='b269524ddc578027c549616fc47f5954991d9f6f',scope='Eight original source/native crystal/menu component pairs at 402x400; 160x160 center crops enlarged 2x. Native tagged Display P3 PNGs are converted to sRGB before composition; source untagged PNGs use source CSS sRGB. Original product PNGs retain their profiles. Source animation clocks are paused at the recorded milliseconds. Reduced source mode applies its original CSS equivalent inline; native uses a rendering override, not a physical accessibility setting. Source menu trigger is transparent; native product captures retain the existing shell. This does not certify whole navigation viewport parity.',captures=records),indent=2)+'\n')
