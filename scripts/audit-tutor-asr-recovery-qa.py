#!/usr/bin/env python3
"""Read only the new ASR journey's QA snapshot; export counters and hashes."""
import argparse, hashlib, json, subprocess
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('--since',type=Path,required=True);p.add_argument('--output',type=Path,required=True);a=p.parse_args();run=json.loads(a.since.read_text());device=run['device'];assert device=='CE8248B6-7171-4FD4-97DE-89E499107F82'
container=Path(subprocess.check_output(['xcrun','simctl','get_app_container',device,'app.piyali.ios','data'],text=True).strip());profiles=[]
for file in (container/'Library/Application Support/Piyali').glob('*.json'):
 if file.stat().st_mtime<run['startedAt']:continue
 raw=file.read_bytes();s=json.loads(raw)
 if s.get('name')!='ASR Recovery Learner' or s.get('target')!='es':continue
 records=list((s.get('tutorLessons') or {}).values());encoded=json.dumps(records,ensure_ascii=False)
 r={'snapshotSHA256':hashlib.sha256(raw).hexdigest(),'totalXP':sum((s.get('xpByLanguage')or{}).values()),'gradedAttempts':(s.get('gradedByLanguage')or{}).get('es',0),'notes':len(s.get('notes')or[]),'companionMemoryNotes':sum(len(v) for v in (s.get('companionMemory')or{}).values()),'pendingMemoryChanges':len(s.get('pendingMemoryChanges')or[]),'earnedTutorXP':sum(v.get('earnedXP',0) for v in records),'tutorTurnOrCompletionReceipts':sum(v.get('source') in ['tutorTurn','speak'] for v in s.get('pendingChanges')or[]),'rejectedTranscriptInTutorRecords':'नमस्ते' in encoded,'recoveryCueInPrivateDraft':'Please try hola once more.' in encoded}
 assert all(r[k]==0 for k in ['totalXP','gradedAttempts','notes','companionMemoryNotes','pendingMemoryChanges','earnedTutorXP','tutorTurnOrCompletionReceipts']),r
 assert not r['rejectedTranscriptInTutorRecords'] and r['recoveryCueInPrivateDraft'],r
 profiles.append(r)
assert len(profiles)==1,'Exactly one newly scoped ASR profile is required'
a.output.parent.mkdir(parents=True,exist_ok=True);a.output.write_text(json.dumps({'qaDevice':device,'startedAt':run['startedAt'],'scope':'Read-only counters from the new ASR Recovery Learner UI journey. Public scripted transcript; no profile, keys, names, private note bodies or identity identifiers exported.','profiles':profiles},indent=2)+'\n');print('Verified zero XP/grading/Tutor completion and rejected transcript absent from the retained recovery draft.')
