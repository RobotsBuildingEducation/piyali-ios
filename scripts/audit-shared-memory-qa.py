#!/usr/bin/env python3
"""Inspect counters from this run's disposable ordinary-exercise Memory profile."""
import argparse, hashlib, json, subprocess
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('--since',type=Path,required=True);p.add_argument('--output',type=Path,required=True);a=p.parse_args()
run=json.loads(a.since.read_text());device=run['device'];assert device=='CE8248B6-7171-4FD4-97DE-89E499107F82'
container=Path(subprocess.check_output(['xcrun','simctl','get_app_container',device,'app.piyali.ios','data'],text=True).strip());profiles=[]
for file in (container/'Library/Application Support/Piyali').glob('*.json'):
 if file.stat().st_mtime<run['startedAt']:continue
 raw=file.read_bytes();state=json.loads(raw)
 if state.get('name')!='Shared Memory Learner' or state.get('target')!='es':continue
 notes=(state.get('companionMemory')or{}).get('es')or[];changes=state.get('pendingChanges')or[];memory=state.get('pendingMemoryChanges')or[];evidence=state.get('pendingRepairEvidence')or[]
 result={'snapshotSHA256':hashlib.sha256(raw).hexdigest(),'totalXP':sum((state.get('xpByLanguage')or{}).values()),'dailyXP':state.get('dailyXP',0),'gradedAttempts':(state.get('gradedByLanguage')or{}).get('es',0),'assessmentReceipts':sum(c.get('source')=='assessment' for c in changes),'memoryNotes':len(notes),'captureReceipts':sum(c.get('action')=='capture' for c in memory),'enrichmentReceipts':sum(c.get('action')=='localize' for c in memory),'repairEvidenceReceipts':len(evidence),'studyNotes':len(state.get('notes')or[])}
 assert result['totalXP']==result['dailyXP']==result['studyNotes']==0,result
 assert all(result[k]==1 for k in ['gradedAttempts','assessmentReceipts','memoryNotes','captureReceipts','enrichmentReceipts','repairEvidenceReceipts']),result
 note=notes[0].get('fields',notes[0]);assert note['enriched'] is True and note['severity']==1
 assert note['concept']=='Match the items:' and note['userAnswer']=='hola → goodbye, adiós → hello, gracias → thank you'
 assert note['correction']=='Check the correct pairings' and note['mistake']=='The pairings did not match.' and note['tip']=='Match each word to its partner.'
 assert evidence[0]['event']['id']==note['id']+':1' and evidence[0]['sourceCaptureID']==next(c['id'] for c in memory if c['action']=='capture')
 summary=(state.get('goalIntelligence')or{}).get('es',{}).get('repairSummary',{});assert len(summary.get('eventIds',[]))==len(summary.get('openPatterns',[]))==1
 assert summary['openPatterns'][0]['recurrence']==1
 result['sourceMode']=note['sourceMode'];result['openPatternRecurrence']=summary['openPatterns'][0]['recurrence'];profiles.append(result)
assert len(profiles)==1,('Exactly one newly scoped ordinary-exercise Memory profile required',len(profiles))
a.output.parent.mkdir(parents=True,exist_ok=True);a.output.write_text(json.dumps({'qaDevice':device,'startedAt':run['startedAt'],'scope':'Read-only counters after signup → ordinary matching miss → Skip → enriched Memory → actual process relaunch. Public provider I/O fixture; no seeded notes or progress. No private identity or full profile exported.','profiles':profiles},indent=2)+'\n');print('Verified one capture, enrichment, assessment and repair evidence; zero XP after relaunch.')
