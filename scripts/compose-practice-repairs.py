#!/usr/bin/env python3
"""Compose source/native drawer captures, normalizing PNG profiles before comparison."""
import argparse,hashlib,io,json,shutil
from pathlib import Path
from PIL import Image,ImageCms,ImageDraw
p=argparse.ArgumentParser();p.add_argument('comparison',type=Path);p.add_argument('journey',type=Path);p.add_argument('--output',type=Path,default=Path('docs/native/practice-repair-capture-b269524d'));a=p.parse_args();a.output.mkdir(parents=True,exist_ok=True)
def rows(folder):return [r for t in json.loads((folder/'manifest.json').read_text()) for r in t['attachments']]
def find(folder,prefix):
 matches=[r for r in rows(folder) if r.get('suggestedHumanReadableName','').startswith(prefix+'_')];assert len(matches)==1,(prefix,len(matches));return folder/matches[0]['exportedFileName']
def load(path):
 im=Image.open(path);profile=im.info.get('icc_profile');im=im.convert('RGB')
 return ImageCms.profileToProfile(im,ImageCms.ImageCmsProfile(io.BytesIO(profile)),ImageCms.createProfile('sRGB'),outputMode='RGB') if profile else im
for theme in ['light','dark']:
 pair=Image.new('RGB',(804,902),'white');draw=ImageDraw.Draw(pair)
 for index,prefix in enumerate(['Source','Native']):
  im=load(find(a.comparison,f'{prefix} actual matching repair drawer {theme}')).resize((402,874),Image.Resampling.LANCZOS);pair.paste(im,(index*402,28));draw.text((index*402+12,8),'Web reference' if index==0 else 'Native Swift',fill='black')
 pair.save(a.output/f'drawers-{theme}.png',optimize=True)
for prefix,name in [('Native stemless matching wrong submission','wrong-submission'),('Native stemless matching captured repair','captured-repair'),('Native matching repair retains missed answer after correct retry','retained-after-retry'),('Native matching captured repair restored after relaunch','restored-after-relaunch')]:
 shutil.copyfile(find(a.journey,prefix),a.output/f'{name}.png')
shutil.copyfile(find(a.comparison,'Actual native stemless matching capture'),a.output/'captured-note.json')
manifest={'sourceRevision':'b269524ddc578027c549616fc47f5954991d9f6f','nativeBase':'dc7ac531badb8cbdb3aed8c20094e87dfefdb0ac','resultBundles':['/tmp/PiyaliPracticeRepairContext2_20261105.xcresult (native UI pass; source comparison fails)','/tmp/PiyaliPracticeRepairDrawersFinal20261105.xcresult (source/native comparison passes)'],'scope':'Original NotesDrawer and native drawer at 402x874 in light/dark receive the actual native matching capture whose inputs are separately checked against original source handlers. Source component state/provider boundaries are fixtures; this is not a complete browser question-to-capture-to-drawer journey. Full native images are from the actual onboarding/course/miss/Memory/retry/relaunch UI journey. No OS reduced motion, physical device or cloud/provider quality coverage. Backgrounds differ in component captures; original PNG profiles normalized only for side-by-side pairs.','files':[]}
for file in sorted(a.output.iterdir()):
 if file.name!='manifest.json':manifest['files'].append({'file':file.name,'sha256':hashlib.sha256(file.read_bytes()).hexdigest(),'bytes':file.stat().st_size})
(a.output/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n');print(a.output)
