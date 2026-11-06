#!/usr/bin/env python3
"""Read only the current late-speech UI profile and export counters/hashes."""
import argparse,hashlib,json,subprocess
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('--since',type=Path,required=True);p.add_argument('--output',type=Path,required=True);a=p.parse_args();run=json.loads(a.since.read_text());device=run['device'];assert device=='CE8248B6-7171-4FD4-97DE-89E499107F82'
container=Path(subprocess.check_output(['xcrun','simctl','get_app_container',device,'app.piyali.ios','data'],text=True).strip());profiles=[]
for f in (container/'Library/Application Support/Piyali').glob('*.json'):
 if f.stat().st_mtime<run['startedAt']:continue
 raw=f.read_bytes();s=json.loads(raw)
 if s.get('name')!='Late Speech Learner' or s.get('target')!='es':continue
 records=s.get('tutorLessons')or{};record=next(v for k,v in records.items() if k.endswith('lesson-tutorial-1'));source=record.get('sourceState')or{};draft=(source.get('conversationDraft')or{}).get('messages')or[]
 turns=[v for v in s.get('pendingChanges')or[] if v.get('source')=='tutorTurn'];assessments=[v for v in s.get('pendingChanges')or[] if v.get('source')=='assessment'];xp=sum((s.get('xpByLanguage')or{}).values())
 result={'snapshotSHA256':hashlib.sha256(raw).hexdigest(),'totalXP':xp,'dailyXP':s.get('dailyXP',0),'pendingTutorOutcomes':len(s.get('pendingTutorOutcomes')or[]),'gradedAttempts':(s.get('gradedByLanguage')or{}).get('es',0),'earnedTutorXP':record.get('earnedXP',0),'agenda':sorted(record.get('items')or[]),'tutorTurnReceipts':len(turns),'assessmentReceipts':len(assessments),'completionReceipts':sum(v.get('source')=='speak' for v in s.get('pendingChanges')or[]),'lateMessagesInPrivateDraft':sum(v.get('role')=='user' and v.get('text') in ['hola','me llamo'] for v in draft),'notes':len(s.get('notes')or[]),'memoryNotes':sum(len(v) for v in (s.get('companionMemory')or{}).values()),'historyEntries':len(s.get('history')or[]),'tutorDailyActivity':((((s.get('questProgress')or{}).get('speakDailyActivity')or{}).get('es')or{}).get(s.get('dailyKey',''),0))}
 assert 3<=xp<=7 and result['gradedAttempts']==1 and result['earnedTutorXP']==xp and result['dailyXP']==xp and result['pendingTutorOutcomes']==0,result
 assert result['agenda']==['hello','myNameIs'],result
 assert result['tutorTurnReceipts']==result['assessmentReceipts']==1 and turns[0]['amount']==xp,result
 assert all(result[k]==0 for k in ['completionReceipts','lateMessagesInPrivateDraft','notes','memoryNotes','historyEntries','tutorDailyActivity']),result
 profiles.append(result)
assert len(profiles)==1,'Exactly one newly scoped late-speech UI profile required'
a.output.parent.mkdir(parents=True,exist_ok=True);a.output.write_text(json.dumps({'qaDevice':device,'startedAt':run['startedAt'],'scope':'Read-only final public late-speech UI journey counters. No private profile, identity, key or note contents exported. One 3–7 XP turn, two starter items, one assessment, no late chat, bonus or Memory.','profiles':profiles},indent=2)+'\n');print('Verified one earned turn and assessment, two agenda items, no late chat, duplicate XP, bonus, history or Memory.')
