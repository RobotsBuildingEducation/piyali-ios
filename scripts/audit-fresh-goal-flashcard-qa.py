#!/usr/bin/env python3
"""Read only the scoped fresh Goal flashcard UI profile; export counts and a hash."""
import argparse,hashlib,json,subprocess
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('--since',type=Path,required=True);p.add_argument('--output',type=Path,required=True);a=p.parse_args();run=json.loads(a.since.read_text());device=run['device'];assert device=='CE8248B6-7171-4FD4-97DE-89E499107F82','Only the named isolated QA device is supported'
container=Path(subprocess.check_output(['xcrun','simctl','get_app_container',device,'app.piyali.ios','data'],text=True).strip());matches=[]
for file in (container/'Library/Application Support/Piyali').glob('*.json'):
 if file.stat().st_mtime<run['startedAt']:continue
 raw=file.read_bytes();state=json.loads(raw);bucket=(state.get('goalIntelligence')or{}).get('es',{});daily=bucket.get('dailyGoal')or{};blueprint=daily.get('blueprint')or{}
 if state.get('target')!='es' or blueprint.get('objective')!='Name your family members' or (daily.get('modeProgress')or{}).get('flashcards')!=3:continue
 report={'snapshotSHA256':hashlib.sha256(raw).hexdigest(),'totalXP':sum((state.get('xpByLanguage')or{}).values()),'gradedAttempts':(state.get('gradedByLanguage')or{}).get('es',0),'flashcardModeProgress':(daily.get('modeProgress')or{}).get('flashcards',0),'lessonModeProgress':(daily.get('modeProgress')or{}).get('lesson',0),'goalModeEventCount':len(daily.get('modeEventIds')or[]),'pendingGoalReceipts':len(state.get('pendingGoalChanges')or[]),'pendingPracticeReceipts':len(state.get('pendingChanges')or[]),'ordinaryReviewCount':len(state.get('cardReviews')or{})}
 matches.append(report)
assert len(matches)==1,('Exactly one scoped fresh Goal UI snapshot is required',len(matches));r=matches[0]
assert r['totalXP']==6 and r['gradedAttempts']==3,r
assert r['goalModeEventCount']==1 and r['flashcardModeProgress']==3 and r['lessonModeProgress']==0,r
assert r['pendingGoalReceipts']==0 and r['pendingPracticeReceipts']==0 and r['ordinaryReviewCount']==0,r
result={'qaDevice':device,'startedAt':run['startedAt'],'scope':'Read-only final private QA snapshot after fresh provider/artifact failure, actual first recall/save failure, offline process restoration, reconnect acknowledgment, remaining recalls, next-lesson handoff and relaunch. UI tests verify controls; this audit verifies persisted counts. No keys, names, notes or full profiles are exported.','profile':r};a.output.parent.mkdir(parents=True,exist_ok=True);a.output.write_text(json.dumps(result,indent=2)+'\n');print('Verified fresh Goal UI reward/assessment/completion counts, empty outboxes and unchanged ordinary review schedule.')
