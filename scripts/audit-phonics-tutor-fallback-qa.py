#!/usr/bin/env python3
"""Read only the two scoped fallback UI snapshots; export counts and hashes."""
import argparse,hashlib,json,subprocess
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('--since',type=Path,required=True);p.add_argument('--output',type=Path,required=True);a=p.parse_args();run=json.loads(a.since.read_text());device=run['device'];assert device=='CE8248B6-7171-4FD4-97DE-89E499107F82','Only the isolated QA device is supported'
container=Path(subprocess.check_output(['xcrun','simctl','get_app_container',device,'app.piyali.ios','data'],text=True).strip());profiles={}
for file in (container/'Library/Application Support/Piyali').glob('*.json'):
 if file.stat().st_mtime<run['startedAt']:continue
 raw=file.read_bytes();s=json.loads(raw)
 if s.get('name')!='Focused Phonics Learner' or s.get('target')!='es':continue
 daily=((s.get('goalIntelligence')or{}).get('es')or{}).get('dailyGoal')or{};kind='goal' if (daily.get('blueprint')or{}).get('objective')=='Pronounce casa and mesa' else 'repair'
 artifacts=list((s.get('goalArtifacts')or{}).values())+[v for d in (s.get('companionQuestDays')or{}).values() for k,v in d.items() if k.startswith('practice_phonics_')]
 if not any(isinstance(v,dict) and v.get('cards')==[None] for v in artifacts):continue
 r={'snapshotSHA256':hashlib.sha256(raw).hexdigest(),'totalXP':sum((s.get('xpByLanguage')or{}).values()),'gradedAttempts':(s.get('gradedByLanguage')or{}).get('es',0),'goalPhonicsModeProgress':(daily.get('modeProgress')or{}).get('phonics',0),'repairCompletedCount':(((s.get('questProgress')or{}).get('repairDailyActivity')or{}).get('es')or{}).get(s.get('dailyKey',''),0),'ordinaryTutorLessonCount':len(s.get('tutorLessons')or{}),'pendingPracticeReceipts':len(s.get('pendingChanges')or[]),'pendingGoalReceipts':len(s.get('pendingGoalChanges')or[]),'pendingRepairEvidence':len(s.get('pendingRepairEvidence')or[]),'malformedArtifactPreserved':True}
 assert kind not in profiles,('Expected one scoped snapshot per flow',kind);profiles[kind]=r
assert set(profiles)=={'goal','repair'},'Both UI fallback snapshots must exist'
for kind,r in profiles.items():assert all(r[k]==0 for k in ['totalXP','gradedAttempts','goalPhonicsModeProgress','repairCompletedCount','ordinaryTutorLessonCount','pendingPracticeReceipts','pendingGoalReceipts','pendingRepairEvidence']),(kind,r)
result={'qaDevice':device,'startedAt':run['startedAt'],'scope':'Read-only final QA snapshots after actual signup/setup, failed Phonics load, explicit Tutor connect/pause/end and private relaunch. UI verifies disconnected controls/objective; counts verify navigation did not award or advance learning. No names, keys, notes or full profiles are exported.','profiles':profiles};a.output.parent.mkdir(parents=True,exist_ok=True);a.output.write_text(json.dumps(result,indent=2)+'\n');print('Verified both fallback journeys preserve artifacts and award no XP, assessment, completion or ordinary Tutor progress.')
