// Execute the reference's actual invitation helpers against an in-memory Firestore adapter.
import fs from 'node:fs/promises';
import path from 'node:path';
const reference=path.resolve(process.argv[2] || '../nosabos/nosabos');
const source=await fs.readFile(path.join(reference,'src/utils/teams.js'),'utf8');
const start=source.indexOf('export const acceptTeamInvite ='),end=source.indexOf('export const getUserTeams =',start);
if(start<0 || end<0) throw Error('Reference invitation helpers changed');
const helpers=source.slice(start,end);
const module=await import('data:text/javascript;base64,'+Buffer.from(`
let records;const database={};const doc=(_db,...parts)=>parts.join('/');
const getDoc=async ref=>({exists:()=>records.has(ref),data:()=>structuredClone(records.get(ref))});
const updateDoc=async(ref,patch)=>records.set(ref,{...records.get(ref),...structuredClone(patch)});
const runTransaction=async(_db,fn)=>fn({get:getDoc,update:updateDoc});
${helpers}
export async function run(input){records=new Map(Object.entries(structuredClone(input.records)));await (input.accept?acceptTeamInvite:rejectTeamInvite)(input.member,'team_fixture');return Object.fromEntries(records);}
`).toString('base64'));
const creator='npub1'+'q'.repeat(58),member='npub1'+'p'.repeat(58),other='npub1'+'z'.repeat(58),cases=[];
for(const status of ['pending','accepted']) for(const accept of [true,false]) {
 const team={teamName:'Weekend',createdBy:creator,creatorName:'Ada',createdAt:'2026-10-20T12:00:00.000Z',legacyMarker:{keep:true},members:[{npub:other,status:'accepted',name:'Jo',addedAt:'original'},{npub:member,status,name:'Sam',addedAt:'original',legacy:'keep'}]};
 const records={[`users/${creator}/teams/fixture`]:team,[`users/${member}/teamInvites/team_fixture`]:{teamId:'fixture',teamName:team.teamName,creatorNpub:creator,status}};
 const result=await module.run({records,member,accept});cases.push({creator,member,accept,team,expected:result[`users/${creator}/teams/fixture`],inviteStatus:result[`users/${member}/teamInvites/team_fixture`].status});
}
await fs.writeFile(new URL('../Tests/PiyaliCoreTests/Fixtures/private-teams.json',import.meta.url),JSON.stringify(cases,null,2)+'\n');
console.log('Exported '+cases.length+' reference private invitation results.');
