#!/usr/bin/env python3
"""Publish normal Tutor replay journey captures without altering their contents."""
import argparse,hashlib,io,json
from pathlib import Path
from PIL import Image,ImageCms
p=argparse.ArgumentParser();p.add_argument('attachments',type=Path);p.add_argument('--result',required=True);a=p.parse_args()
rows=[r for t in json.loads((a.attachments/'manifest.json').read_text()) for r in t['attachments']]
states={'active':'Native Tutor recorded reply replay active','paused':'Native Tutor replay interrupted by pause','history':'Native Tutor history replay keeps other reply available','relaunch':'Native Tutor recording cache does not expose private replies on relaunch'};records=[]
for key,label in states.items():
 matches=[r for r in rows if r['suggestedHumanReadableName'].startswith(label+'_')];assert len(matches)==1,(label,len(matches));row=matches[0];src=a.attachments/row['exportedFileName'];image=Image.open(src);profile=image.info.get('icc_profile');image=image.convert('RGB')
 if profile:image=ImageCms.profileToProfile(image,ImageCms.ImageCmsProfile(io.BytesIO(profile)),ImageCms.createProfile('sRGB'),outputMode='RGB')
 image=image.resize((402,round(image.height*402/image.width)),Image.Resampling.LANCZOS);dest=Path(f'docs/native/tutor-replay-{key}-en-product.png');image.save(dest,optimize=True)
 records.append({'file':str(dest),'sha256':hashlib.sha256(dest.read_bytes()).hexdigest(),'attachment':row['suggestedHumanReadableName']})
Path('docs/reference/tutor-replay-product-captures.json').write_text(json.dumps({'result':a.result,'scope':'Normal entry, Start learning, product menu, Tutor start, actual saved-clip AVAudioPlayer, pause/resume/end, per-response history replay, private fresh relaunch. Explicit isolated offline provider fixture supplies a public synthetic six-second tone; real provider PCM and physical audio are separate checks. Existing source reply component comparisons retain their own scope.','records':records},indent=2)+'\n')
print('Published',len(records),'normal Tutor replay captures.')
