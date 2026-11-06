#!/usr/bin/env python3
"""Read counters only from the newly created, disposable Tutor Memory UI profile."""
import argparse,hashlib,json,subprocess
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('--since',type=Path,required=True);p.add_argument('--output',type=Path,required=True);a=p.parse_args();run=json.loads(a.since.read_text());device=run['device'];assert device=='CE8248B6-7171-4FD4-97DE-89E499107F82'
container=Path(subprocess.check_output(['xcrun','simctl','get_app_container',device,'app.piyali.ios','data'],text=True).strip());profiles=[]
for file in (container/'Library/Application Support/Piyali').glob('*.json'):
 if file.stat().st_mtime < run['startedAt']:continue
 raw=file.read_bytes();state=json.loads(raw)
 if state.get('name')!='Tutor Learner' or state.get('target')!='es':continue
 memories=(state.get('companionMemory')or{}).get('es')or[]
 changes=state.get('pendingChanges')or[];memoryChanges=state.get('pendingMemoryChanges')or[]
 record=next(v for k,v in (state.get('tutorLessons')or{}).items() if k.endswith('lesson-tutorial-1'))
 result={'snapshotSHA256':hashlib.sha256(raw).hexdigest(),'totalXP':sum((state.get('xpByLanguage')or{}).values()),'dailyXP':state.get('dailyXP',0),'gradedAttempts':(state.get('gradedByLanguage')or{}).get('es',0),'earnedTutorXP':record.get('earnedXP',0),'agenda':sorted(record.get('items')or[]),'pendingTutorOutcomes':len(state.get('pendingTutorOutcomes')or[]),'tutorTurnReceipts':sum(c.get('source')=='tutorTurn' for c in changes),'assessmentReceipts':sum(c.get('source')=='assessment' for c in changes),'completionReceipts':sum(c.get('source')=='speak' for c in changes),'memoryNotes':len(memories),'captureReceipts':sum(c.get('action')=='capture' for c in memoryChanges),'enrichmentReceipts':sum(c.get('action')=='localize' for c in memoryChanges),'studyNotes':len(state.get('notes')or[])}
 assert all(result[k]==0 for k in ['totalXP','dailyXP','gradedAttempts','earnedTutorXP','pendingTutorOutcomes','tutorTurnReceipts','assessmentReceipts','completionReceipts','studyNotes']),result
 assert result['agenda']==[] and result['memoryNotes']==result['captureReceipts']==result['enrichmentReceipts']==1,result
 note=memories[0].get("fields",memories[0])
 assert note.get('sourceMode')==note.get('sourceContext')=='tutor' and note.get('enriched') is True and note.get('severity')==1
 assert note.get('concept')=='A greeting' and note.get('expectedAnswer')=='Hola' and note.get('mistake')=='The greeting was missing.' and note.get('tip')=='Start with hola.'
 assert note.get('cefrLevel')=='Pre-A1' and note.get('supportLang')=='en'
 profiles.append(result)
assert len(profiles)==1,('Exactly one newly scoped Tutor Memory UI profile required',len(profiles))
a.output.parent.mkdir(parents=True,exist_ok=True);a.output.write_text(json.dumps({'qaDevice':device,'startedAt':run['startedAt'],'scope':'Read-only counters from final signup → Tutor Gemini low-confidence semantic slip → End → enriched Memory → process relaunch. Public I/O fixture, no seeded progress or notes. No private identity, keys or profile contents exported.','profiles':profiles},indent=2)+'\n');print('Verified one captured/enriched Memory after relaunch, no XP, assessments or duplicate receipt.')
