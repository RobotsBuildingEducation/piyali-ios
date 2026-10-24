import fs from 'node:fs/promises';
import path from 'node:path';
import {gzipSync} from 'node:zlib';
import {createHash} from 'node:crypto';
import {storyReferenceFixture} from './story-reference-fixture.mjs';
const reference=path.resolve(process.argv[2]||'../nosabos/nosabos'),output=new URL('../Piyali/Resources/',import.meta.url);
const files=['src/features/stories/storyCopy.js','src/features/stories/storyCharacters.js','src/components/rpgCompanionSprites.js','src/components/RandomCharacter.jsx'];
const sources=await Promise.all(files.map(file=>fs.readFile(path.join(reference,file),'utf8')));
for(const source of sources.slice(0,3)) if(/^import\s/m.test(source)) throw Error('Story UI export gained an import; review dependency.');
const [copy,characters,sprites]=await Promise.all(sources.slice(0,3).map(source=>import('data:text/javascript;base64,'+Buffer.from(source).toString('base64'))));
const translations=Object.fromEntries(['en','es','pt','fr','it','de','ja','hi','ar','zh'].map(language=>[language,copy.storyCopy(language)]));
const imports=new Map([...sources[3].matchAll(/import (character\d+) from "([^"]+)";/g)].map(match=>[match[1],match[2]]));
const map=sources[3].match(/export const characterImagesMap = \{([\s\S]*?)\};/)?.[1];if(!map) throw Error('Portrait map moved');
const portraitFiles={},portraitSources=[];
for(const [,key,binding] of map.matchAll(/(\d+):\s*(character\d+)/g)) {
 const file=path.resolve(reference,'src/components',imports.get(binding)),name=`story-portrait-${key}.webp`;
 await fs.copyFile(file,new URL('Brand/'+name,output));portraitFiles[key]=name;
 portraitSources.push({file:path.relative(reference,file),sha256:createHash('sha256').update(await fs.readFile(file)).digest('hex')});
}
if(Object.keys(portraitFiles).length!==40) throw Error('Portrait map changed; review export');
const pets={};
for(const type of ['ghost','alien','robot','slime','dog','axolotl']) {
 pets[type]=[];
 for(let frame=0;frame<12;frame++) {
  const commands=[],stack=[];let offset=[0,0],fill='#000000',ellipse=null;
  const ctx={set fillStyle(value){fill=value},save(){stack.push([...offset])},restore(){if(!stack.length) throw Error('Unbalanced sprite');offset=stack.pop()},translate(x,y){offset=[offset[0]+x,offset[1]+y]},fillRect(x,y,w,h){commands.push({shape:'rect',x:x+offset[0],y:y+offset[1],w,h,fill})},beginPath(){ellipse=null},ellipse(x,y,rx,ry,rotation,start,end){if(rotation!==0||start!==0||Math.abs(end-Math.PI*2)>1e-8) throw Error('Unsupported sprite path');ellipse={shape:'ellipse',x:x-rx+offset[0],y:y-ry+offset[1],w:rx*2,h:ry*2,fill}},fill(){if(!ellipse) throw Error('Unsupported sprite fill');commands.push(ellipse)}};
  sprites.drawRpgCompanionFrame(ctx,type,'down',frame);if(stack.length) throw Error('Unbalanced sprite');
  const minX=Math.max(0,Math.min(...commands.map(c=>c.x))),minY=Math.max(0,Math.min(...commands.map(c=>c.y))),maxX=Math.min(sprites.RPG_COMPANION_SPRITE.width,Math.max(...commands.map(c=>c.x+c.w))),maxY=Math.min(sprites.RPG_COMPANION_SPRITE.height,Math.max(...commands.map(c=>c.y+c.h)));
  pets[type].push({bounds:{x:minX,y:minY,w:maxX-minX,h:maxY-minY},commands});
 }
}
const metadata={translations,characters:characters.RPG_STORY_CHARACTERS,pools:characters.RPG_CHARACTER_PORTRAIT_POOLS,portraitFiles,pets};
await fs.writeFile(new URL('story-ui.json.gz',output),gzipSync(JSON.stringify(metadata),{level:9}));
await fs.writeFile(new URL('story-ui.manifest.json',output),JSON.stringify([...files.map((file,index)=>({file,sha256:createHash('sha256').update(sources[index]).digest('hex')})),...portraitSources],null,2)+'\n');
console.log('Exported original story copy, exact 40-entry portrait mapping and 72 companion sprite frames.');

const identityFixtures=['', 'Sheilfer','HAMSTER','Jiraiya','Yoruichi','Neko','Yachiru','You','Tú','Toi','Du','Alicia','Ana','Luis','光','🌱','ليلى',' André '].map(name=>({name,user:{name:'Alicia'},isUser:characters.isUserCharacter(name,{name:'Alicia'}),pool:characters.getStoryCharacterPortraitPool(name,{name:'Alicia'})}));
await fs.writeFile(new URL('../Tests/PiyaliCoreTests/Fixtures/story-appearance.json.gz',import.meta.url),gzipSync(JSON.stringify(identityFixtures),{level:9}));

const parser=await import(path.join(reference,'node_modules/@babel/parser/lib/index.js'));
const browserFixture=storyReferenceFixture(await fs.readFile(path.join(reference,'tests/browser/stories.jsx'),'utf8'),parser);
await fs.writeFile(new URL('story-test-episode.json.gz',output),gzipSync(JSON.stringify(browserFixture),{level:9}));
