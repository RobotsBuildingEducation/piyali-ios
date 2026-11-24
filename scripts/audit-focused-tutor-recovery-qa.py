#!/usr/bin/env python3
"""Read public-fixture counters from isolated Goal/Repair Tutor restore journeys."""
import argparse,hashlib,json,subprocess,time
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('--since',type=Path,required=True);p.add_argument('--output',type=Path,required=True);p.add_argument('--kind',choices=['goal','repair'],required=True);p.add_argument('--phase',choices=['worth','save','settled'],required=True);p.add_argument('--timeout',type=int,default=2);a=p.parse_args();run=json.loads(a.since.read_text());device=run['device'];assert device=='CE8248B6-7171-4FD4-97DE-89E499107F82';deadline=time.monotonic()+a.timeout;root=None;found=[]
while time.monotonic()<deadline:
 try:
  if root is None or not root.exists():root=Path(subprocess.check_output(['xcrun','simctl','get_app_container',device,'app.piyali.ios','data'],text=True,stderr=subprocess.DEVNULL).strip())/'Library/Application Support/Piyali'
 except subprocess.CalledProcessError:time.sleep(.2);continue
 found=[]
 for f in root.glob('*.json'):
  if f.stat().st_mtime<run['startedAt']:continue
  try:raw=f.read_bytes();s=json.loads(raw)
  except (OSError,json.JSONDecodeError):continue
  if s.get('name')!=('Goal Tutor Recovery Learner' if a.kind=='goal' else 'Repair Tutor Recovery Learner') or s.get('target')!='es':continue
  changes=s.get('pendingChanges')or[];goals=s.get('pendingGoalChanges')or[];jobs=s.get('focusedTutorRuns')or{};worth=s.get('pendingTutorOutcomes')or[];bucket=(s.get('goalIntelligence')or{}).get('es',{});daily=bucket.get('dailyGoal')or{};bp=daily.get('blueprint')or{};day=bp.get('dayKey') if a.kind=='goal' else next((v.get('dayKey') for v in (s.get('companionQuestDays')or{}).values() if v.get('repair')),None)
  progress=s.get('questProgress')or{};notes=(s.get('companionMemory')or{}).get('es')or[];attempts=[c for c in goals if c.get('action')=='attempt'];repair=[c for c in changes if c.get('source')=='repair'];job=next(iter(jobs.values()),None)
  r={'snapshotSHA256':hashlib.sha256(raw).hexdigest(),'totalXP':sum((s.get('xpByLanguage')or{}).values()),'dailyXP':s.get('dailyXP',0),'gradedAttempts':(s.get('gradedByLanguage')or{}).get('es',0),'subscriptionXP':sum((s.get('xpByLanguage')or{}).values())+s.get('subscriptionXPAdjustment',0),'pendingWorth':len(worth),'focusedRuns':len(jobs),'pendingGoalAttempts':len(attempts),'pendingRepairCompletions':len(repair),'goalPhonicsProgress':(daily.get('modeProgress')or{}).get('phonics',0),'repairCount':((progress.get('repairDailyActivity')or{}).get('es')or{}).get(day,0),'speakCount':((progress.get('speakDailyActivity')or{}).get('es')or{}).get(day,0),'ordinaryTutorRecords':len(s.get('tutorLessons')or{}),'ordinaryPhonicsRecords':len(s.get('phonicsRecords')or{}),'repairMemoryReinforced':any(n.get('fields',n).get('id')=='pronunciation' and n.get('fields',n).get('status')=='reinforced' for n in notes)}
  if a.phase in ['worth','save']:
   if job is None or not job.get('ready'):continue
   if a.phase=='worth' and (len(worth)!=1 or job.get('completionID') is not None):continue
   if a.phase=='save' and (worth or job.get('completionID') is None):continue
   r.update({'earnedFocusedXP':job['earnedXP'],'requiredFocusedXP':job['required'],'runHash':hashlib.sha256(job['id'].encode()).hexdigest(),'completionReceiptHash':hashlib.sha256(job['completionID'].encode()).hexdigest() if job.get('completionID') else None})
  elif job is not None or worth:continue
  expectedXP=(20 if a.kind=='goal' else 0) if a.phase=='worth' else (25 if a.kind=='goal' else 17);expectedGrades=(4 if a.kind=='goal' else 0) if a.phase=='worth' else (5 if a.kind=='goal' else 1)
  if r['totalXP']!=expectedXP or r['gradedAttempts']!=expectedGrades:continue
  assert r['dailyXP']==(25 if a.kind=='goal' else 5) if a.phase=='worth' else r['dailyXP']==expectedXP,r
  assert r['ordinaryTutorRecords']==r['ordinaryPhonicsRecords']==r['speakCount']==0,r
  if a.phase=='worth':assert r['subscriptionXP']==299 and r['pendingGoalAttempts']==r['pendingRepairCompletions']==r['goalPhonicsProgress']==r['repairCount']==0,r
  else:
   assert r['subscriptionXP']==(304 if a.kind=='goal' else 316),r
   if a.kind=='goal':
    assert r['goalPhonicsProgress']==2 and r['repairCount']==0,r
    assert r['pendingGoalAttempts']==(1 if a.phase=='save' else 0) and r['pendingRepairCompletions']==0,r
    if attempts:assert attempts[0]['payload']['sourceEvidenceID']=='tutor:'+bp['goalId']+':'+day
   else:assert r['repairCount']==1 and r['repairMemoryReinforced'] and r['pendingRepairCompletions']==(1 if a.phase=='save' else 0) and r['pendingGoalAttempts']==0,r
  found.append(r)
 if len(found)==1:break
 time.sleep(.2)
assert len(found)==1,('One fresh profile with expected phase required',a.kind,a.phase,len(found))
a.output.parent.mkdir(parents=True,exist_ok=True);a.output.write_text(json.dumps({'qaDevice':device,'startedAt':run['startedAt'],'kind':a.kind,'phase':a.phase,'scope':'Read-only counters of normal signup/setup → acknowledged public Phonics plan/cache failure → real focused Tutor inputs → held worth → actual termination → save Retry at trial → acknowledged completion. Source prerequisites and external I/O are public fixtures; no earned progress, answers or completion were seeded. No account key, private identity or full profile exported.','profile':found[0]},indent=2)+'\n');print(a.kind,a.phase,'audit passed')
