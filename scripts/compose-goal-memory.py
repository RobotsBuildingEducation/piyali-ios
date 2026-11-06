#!/usr/bin/env python3
"""Compose source/native Goal captures and preserve full product journey evidence."""
import argparse,hashlib,io,json,shutil
from pathlib import Path
from PIL import Image,ImageCms,ImageDraw
p=argparse.ArgumentParser();p.add_argument('attachments',type=Path);p.add_argument('--bundle',required=True);p.add_argument('--journey',type=Path);p.add_argument('--journey-bundle');p.add_argument('--output',type=Path,default=Path('docs/native/goal-memory-capture-b269524d'));a=p.parse_args();a.output.mkdir(parents=True,exist_ok=True)
rows=[r for t in json.loads((a.attachments/'manifest.json').read_text()) for r in t['attachments']]
def find(prefix,folder=None):
 values=rows if folder is None else [r for t in json.loads((folder/'manifest.json').read_text()) for r in t['attachments']]
 matches=[r for r in values if r.get('suggestedHumanReadableName','').startswith(prefix+'_')];assert len(matches)==1,(prefix,len(matches));return (folder or a.attachments)/matches[0]['exportedFileName']
def load(path):
 im=Image.open(path);profile=im.info.get('icc_profile');im=im.convert('RGB')
 return ImageCms.profileToProfile(im,ImageCms.ImageCmsProfile(io.BytesIO(profile)),ImageCms.createProfile('sRGB'),outputMode='RGB') if profile else im
for theme in ['light','dark']:
 pair=Image.new('RGB',(804,902),'white');draw=ImageDraw.Draw(pair)
 for index,prefix in enumerate(['Source','Native']):
  im=load(find(f'{prefix} Goal slip Memory {theme}')).resize((402,874),Image.Resampling.LANCZOS);pair.paste(im,(index*402,28));draw.text((index*402+12,8),'Web reference' if index==0 else 'Native Swift',fill='black')
 pair.save(a.output/f'goals-{theme}.png',optimize=True)
 shutil.copyfile(find('Source actual Goal capture '+theme),a.output/f'source-capture-{theme}.json')
 shutil.copyfile(find('Goal Memory surface '+theme),a.output/f'surface-{theme}.json')
for prefix,name in [('Native focused Goal wrong answer','goal-wrong-answer'),('Native Goal slip saved as open capability without a repair','goal-evidence'),('Native cached Goal reopens with pending evidence','cached-goal-reentry'),('Native ordinary practice miss stays in Repairs','ordinary-repair'),('Native Goal evidence and ordinary repair restore without active focus','restored-without-focus')]:shutil.copyfile(find(prefix,a.journey),a.output/f'{name}.png')
shutil.copyfile(find('Native actual Goal slip bucket'),a.output/'native-goal-bucket.json')
manifest={'sourceRevision':'b269524ddc578027c549616fc47f5954991d9f6f','nativeBase':'a1ef93fe42cdd4c546747b5252dd9404678ca163','resultBundle':a.bundle,'journeyResultBundle':a.journey_bundle or a.bundle,'scope':'Original full captureCompanionMemory executes with an explicit valid focus, public missed-answer inputs, fixed clock and recording learning-evidence boundary. Original mergeEvidence/compactSummary then feeds the original NotesDrawer Goals. Native actual grader captures independently; tests compare fields and summaries except opaque event IDs. Source/native pairs use 402x874 canvases in light/dark with sRGB-normalized profiles; their component backgrounds differ and omit surrounding product navigation. Five original native screenshots retain actual onboarding/Start tasks/Goal miss/Memory/retry/cached reentry/ordinary miss/relaunch UI. This is not a complete browser question UI, real provider/cloud, physical speech, RTL or whole-product design approval.','files':[]}
for file in sorted(a.output.iterdir()):
 if file.name!='manifest.json':manifest['files'].append({'file':file.name,'sha256':hashlib.sha256(file.read_bytes()).hexdigest(),'bytes':file.stat().st_size})
(a.output/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n');print(a.output)
