#!/usr/bin/env python3
"""Read scoped QA counters before or after actual pending-operation termination."""
import argparse,hashlib,json,subprocess,time
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('--since',type=Path,required=True);p.add_argument('--output',type=Path,required=True);p.add_argument('--kind',choices=['memory','tutor-memory','worth'],required=True);p.add_argument('--phase',choices=['pending','settled'],required=True);p.add_argument('--require-intent',action='store_true');p.add_argument('--timeout',type=int,default=1);a=p.parse_args();run=json.loads(a.since.read_text());device=run['device'];assert device=='CE8248B6-7171-4FD4-97DE-89E499107F82';deadline=time.monotonic()+a.timeout;found=[];root=None
while time.monotonic()<deadline:
 try:
  if root is None or not root.exists():root=Path(subprocess.check_output(['xcrun','simctl','get_app_container',device,'app.piyali.ios','data'],text=True,stderr=subprocess.DEVNULL).strip())/'Library/Application Support/Piyali'
 except subprocess.CalledProcessError:time.sleep(.2);continue
 found=[]
 for f in root.glob('*.json'):
  if f.stat().st_mtime<run['startedAt']:continue
  try:raw=f.read_bytes();s=json.loads(raw)
  except (OSError,json.JSONDecodeError):continue
  if s.get('name')!=({'memory':'Interrupted Memory Learner','tutor-memory':'Interrupted Tutor Memory Learner','worth':'Interrupted Worth Learner'}[a.kind]) or s.get('target')!='es':continue
  changes=s.get('pendingChanges')or[];memory=s.get('pendingMemoryChanges')or[];notes=(s.get('companionMemory')or{}).get('es')or[];intents=s.get('pendingMemoryEnrichments')or[];worth=s.get('pendingTutorOutcomes')or[]
  lesson=next((v for k,v in (s.get('tutorLessons')or{}).items() if k.endswith('lesson-tutorial-1')),{})
  r={'snapshotSHA256':hashlib.sha256(raw).hexdigest(),'totalXP':sum((s.get('xpByLanguage')or{}).values()),'dailyXP':s.get('dailyXP',0),'gradedAttempts':(s.get('gradedByLanguage')or{}).get('es',0),'assessments':sum(c.get('source')=='assessment' for c in changes),'turnReceipts':sum(c.get('source')=='tutorTurn' for c in changes),'completionReceipts':sum(c.get('source')=='speak' for c in changes),'lessonXP':lesson.get('earnedXP',0),'pendingWorth':len(worth),'memoryNotes':len(notes),'memoryCaptures':sum(c.get('action')=='capture' for c in memory),'memoryEnrichments':sum(c.get('action')=='localize' for c in memory),'pendingEnrichments':len(intents),'repairEvidence':len(s.get('pendingRepairEvidence')or[])}
  if a.kind in ['memory','tutor-memory']:
   if len(notes)!=1:continue
   note=notes[0].get('fields',notes[0]);r['enriched']=note.get('enriched',False);r['noteID']=note['id']
   if r['enriched']!=(a.phase=='settled'):continue
   assert r['totalXP']==r['dailyXP']==r['turnReceipts']==r['completionReceipts']==r['pendingWorth']==0,r
   assert r['memoryCaptures']==1,r
   if not r['gradedAttempts']==r['assessments']==r['repairEvidence']==(1 if a.kind=='memory' else 0):continue
   if a.kind=='memory':assert note['concept']=='Match the items:' and note['userAnswer']=='hola → goodbye, adiós → hello, gracias → thank you'
   else:assert note['concept']=='A greeting' and note['expectedAnswer']=='Hola' and note['userAnswer']=='a public complete attempt'
   if a.phase=='pending':
    assert r['memoryEnrichments']==0,r
    if a.require_intent and r['pendingEnrichments']!=1:continue
   else:assert r['memoryEnrichments']==1 and r['pendingEnrichments']==0 and note['tip']==('Match each word to its partner.' if a.kind=='memory' else 'Start with hola.'),r
  else:
   if a.phase=='pending':
    if not worth:continue
    if r['pendingWorth']!=1:continue # The distinct late phrases and duplicate belong to one source question turn.
    assert r['totalXP']==r['gradedAttempts']==r['assessments']==r['turnReceipts']==0,r
    assert 3<=r['dailyXP']==r['lessonXP']<=7,r
   else:
    if worth or r['totalXP']==0:continue
    assert 3<=r['totalXP']==r['dailyXP']==r['lessonXP']<=7,r
    assert r['gradedAttempts']==r['assessments']==r['turnReceipts']==1,r
   assert r['memoryNotes']==r['completionReceipts']==0,r
  found.append(r)
 if len(found)==1:break
 time.sleep(.2)
assert len(found)==1,('One fresh scoped profile with expected phase required',a.kind,a.phase,len(found))
a.output.parent.mkdir(parents=True,exist_ok=True);a.output.write_text(json.dumps({'qaDevice':device,'startedAt':run['startedAt'],'kind':a.kind,'phase':a.phase,'scope':'Read-only counters of a fresh public-fixture signup and real process termination; no private identity, keys, audio, provider tokens or full profile exported.','profile':found[0]},indent=2)+'\n');print(a.kind,a.phase,'counter audit passed')
