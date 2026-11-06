#!/usr/bin/env python3
"""Keep the actual quiz -> warmed review -> saved replay product journey."""
import argparse,hashlib,io,json
from pathlib import Path
from PIL import Image,ImageCms
p=argparse.ArgumentParser();p.add_argument('attachments',type=Path);p.add_argument('--result',required=True);a=p.parse_args();rows=[r for t in json.loads((a.attachments/'manifest.json').read_text()) for r in t['attachments']]
states={'quiz':'Native upcoming review quiz passed','completion':'Native upcoming review warms behind quiz acknowledgment','path':'Native upcoming review remains unstarted on path','preparation':'Native warmed review keeps source exploration window','game':'Native warmed review opens seven beats without provider','resume':'Native warmed review saved run resumes after relaunch'};records=[]
for key,label in states.items():
 matches=[r for r in rows if r['suggestedHumanReadableName'].startswith(label+'_') and r['exportedFileName'].endswith('.png')];assert len(matches)==1,(label,len(matches))
 raw=a.attachments/matches[0]['exportedFileName'];im=Image.open(raw);profile=im.info.get('icc_profile');im=im.convert('RGB')
 if profile:im=ImageCms.profileToProfile(im,ImageCms.ImageCmsProfile(io.BytesIO(profile)),ImageCms.createProfile('sRGB'),outputMode='RGB')
 dest=Path('docs/native')/f'upcoming-review-{key}.png';im.resize((402,874),Image.Resampling.LANCZOS).save(dest,optimize=True);records.append({'file':str(dest),'sha256':hashlib.sha256(dest.read_bytes()).hexdigest(),'attachment':matches[0]['suggestedHumanReadableName']})
Path('docs/reference/upcoming-review-product-captures.json').write_text(json.dumps({'result':a.result,'viewport':{'width':402,'height':874},'scope':'Actual native product entry/onboarding/self-reported A1 -> beginner quiz -> quiz acknowledgment -> unstarted review -> process relaunch with prepared provider disabled -> cached seven-beat review -> Back/relaunch/saved run. Public provider content only; no prefilled learner progress or alternate UI. Both game entries wait for their map frame to fill the complete phone display. No new UI surfaces are introduced by warming; source parity evidence is the original completion predicate/selector and all 8,750 source cases. Prior source/native loader/map comparisons retain their original scope.','records':records},indent=2)+'\n');print(f'Published {len(records)} product captures')
