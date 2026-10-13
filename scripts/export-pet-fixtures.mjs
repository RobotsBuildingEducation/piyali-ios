// Executes only the pure reference helpers; writes fixtures in the iOS repository.
import fs from 'node:fs/promises';
import path from 'node:path';
import {pathToFileURL} from 'node:url';
const reference=path.resolve(process.argv[2] || '../nosabos/nosabos');
const web=await import(pathToFileURL(path.join(reference,'src/utils/dailyGoalPet.js')));
const base={dailyGoalXp:50,dailyGoalPetHealth:100,dailyGoalPetLastAccountedDay:'2026-10-01',dailyResetAt:'2026-10-04T20:00:00.000Z',dailyXp:12};
const cases=[
 {},base,{...base,dailyGoalXp:0}, {...base,dailyGoalXp:undefined,progress:{dailyGoalXp:50}},
 {...base,dailyGoalXp:undefined,stats:{dailyGoalXp:'50'}},
 {...base,dailyGoalPetHealth:0},{...base,dailyGoalPetHealth:5},{...base,dailyGoalPetHealth:55.5},
 {...base,dailyGoalPetHealth:'90.4'},{...base,dailyGoalPetHealth:'bad'},{...base,dailyGoalPetHealth:null},
 {...base,dailyGoalPetLastAccountedDay:undefined},
 {...base,dailyGoalPetLastAccountedDay:undefined,createdAt:'2026-10-01T23:00:00.000Z'},
 {...base,dailyGoalPetLastAccountedDay:'bad',createdAt:Date.parse('2026-10-01T23:00:00.000Z')},
 {...base,dailyGoalPetLastAccountedDay:'2020-01-01'},
 {...base,dailyGoalPetLastAccountedDay:'2027-01-01'},
 {...base,completedGoalDates:['2026-10-02','2026-10-03']},
 {...base,dailyGoalPetReachedDates:['2026-10-02'],lastGoalDayKey:'2026-10-03'},
 {...base,dailyGoalPetTrackedDay:'2026-10-02',dailyGoalPetStartedFull:true,completedGoalDates:['2026-10-02','2026-10-03']},
 {...base,dailyGoalPetTrackedDay:'2026-10-02',dailyGoalPetStartedFull:false,completedGoalDates:['2026-10-02','2026-10-03']},
 {...base,dailyGoalPetTrackedDay:'2026-10-04',dailyGoalPetStartedFull:false},
 {...base,dailyGoalPetTrackedDay:'2026-10-04',dailyGoalPetStartedFull:true,dailyGoalPetHealth:90},
 {...base,dailyGoalPetTrackedDay:'2026-10-01',dailyGoalPetStartedFull:true,dailyGoalPetHealthyDates:['2026-09-28'],completedGoalDates:['2026-10-01','2026-10-03']},
 {...base,dailyGoalPetLastAccountedDay:'2026-02-30'}
];
const fixtures=[];
for(const timezone of ['UTC','America/Los_Angeles','America/Mexico_City']) {
 process.env.TZ=timezone;
 for(const [i,data] of cases.entries()) for(const resetWindow of [true,false]) {
  const now=new Date(2026,9,4,12);
  fixtures.push({name:`${timezone}-${i}-${resetWindow}`,timezone,data,now:now.toISOString(),resetWindow,missed:web.countMissedDailyGoalWindows(data,now),expected:web.buildDailyGoalResetFields(data,now,{resetWindow})});
 }
 // DST starts and ends: each date is one whole local day despite the hour change.
 for(const now of [new Date(2026,2,10,12),new Date(2026,10,3,12)]) {
  const yesterday=new Date(now);yesterday.setDate(yesterday.getDate()-3);
  const marker=`${yesterday.getFullYear()}-${String(yesterday.getMonth()+1).padStart(2,'0')}-${String(yesterday.getDate()).padStart(2,'0')}`;
  const data={...base,dailyGoalPetLastAccountedDay:marker};
  fixtures.push({name:`${timezone}-dst-${marker}`,timezone,data,now:now.toISOString(),resetWindow:false,missed:web.countMissedDailyGoalWindows(data,now),expected:web.buildDailyGoalResetFields(data,now,{resetWindow:false})});
 }
}
await fs.writeFile(new URL('../Tests/PiyaliCoreTests/Fixtures/companion-health.json',import.meta.url),JSON.stringify(fixtures,null,2)+'\n');
console.log(`Exported ${fixtures.length} companion health cases from the reference.`);
