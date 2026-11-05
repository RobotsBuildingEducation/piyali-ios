#!/usr/bin/env python3
"""Read only the two scoped simulator profiles from a durable-finish UI run."""
import argparse,hashlib,json,subprocess
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('--since',type=Path,required=True);p.add_argument('--output',type=Path,required=True);a=p.parse_args();run=json.loads(a.since.read_text());device=run['device'];assert device=='CE8248B6-7171-4FD4-97DE-89E499107F82','Only the named isolated QA device is supported'
container=Path(subprocess.check_output(['xcrun','simctl','get_app_container',device,'app.piyali.ios','data'],text=True).strip());profiles={}
for file in (container/'Library/Application Support/Piyali').glob('*.json'):
 if file.stat().st_mtime<run['startedAt']:continue
 raw=file.read_bytes();state=json.loads(raw);adjust=state.get('subscriptionXPAdjustment');kind={297:'goal',295:'repair'}.get(adjust)
 if not kind or state.get('target')!='es':continue
 bucket=(state.get('goalIntelligence')or{}).get('es',{});daily=bucket.get('dailyGoal')or{};xp=sum((state.get('xpByLanguage')or{}).values());day=state.get('dailyKey','');quest=state.get('questProgress')or{}
 report={'snapshotSHA256':hashlib.sha256(raw).hexdigest(),'totalXP':xp,'subscriptionXP':xp+adjust,'gradedAttempts':(state.get('gradedByLanguage')or{}).get('es',0),'pendingFinishes':len(state.get('pendingPhonicsFinishes')or{}),'pendingPracticeReceipts':len(state.get('pendingChanges')or[]),'pendingGoalReceipts':len(state.get('pendingGoalChanges')or[]),'pendingRepairEvidence':len(state.get('pendingRepairEvidence')or[]),'phonicsModeProgress':(daily.get('modeProgress')or{}).get('phonics',0),'goalModeEventCount':len(daily.get('modeEventIds')or[]),'repairCompletedCount':((quest.get('repairDailyActivity')or{}).get('es')or{}).get(day,0),'repairEvidenceEventCount':len((bucket.get('repairSummary')or{}).get('eventIds')or[])}
 profiles[kind]=(file.stat().st_mtime,report)
assert set(profiles)=={'goal','repair'},'Both scoped UI profiles must exist'
for kind,(_,r) in profiles.items():
 assert r['totalXP']==(4 if kind=='goal' else 6),(kind,r)
 assert r['subscriptionXP']==301 and r['gradedAttempts']==(3 if kind=='goal' else 4),(kind,r)
 assert all(r[k]==0 for k in ['pendingFinishes','pendingPracticeReceipts','pendingGoalReceipts','pendingRepairEvidence']),(kind,r)
 if kind=='goal':assert r['phonicsModeProgress']==2 and r['goalModeEventCount']==1,(kind,r)
 else:assert r['repairCompletedCount']==1 and r['repairEvidenceEventCount']==1,(kind,r)
result={'qaDevice':device,'startedAt':run['startedAt'],'scope':'Read-only final account-private QA snapshots after real UI termination, an offline gated relaunch and online gated relaunch. No keys, names, notes or full profiles are exported. Subscription presentation is verified by the UI test, not inferred from these counts.','profiles':{k:v[1] for k,v in profiles.items()}};a.output.parent.mkdir(parents=True,exist_ok=True);a.output.write_text(json.dumps(result,indent=2)+'\n');print('Verified Goal/repair UI outcomes, reward/assessment counts and retired continuations at 301 subscription XP.')
