// Original react-icons paths; writes only target-owned iOS assets.
import fs from 'node:fs/promises';
import path from 'node:path';
import {createRequire} from 'node:module';
const root=process.cwd(),reference=path.resolve(root,'../nosabos/nosabos'),require=createRequire(path.join(reference,'package.json')),React=require('react'),{renderToStaticMarkup}=require('react-dom/server');
const icons={volume:['fi','FiVolume2'],refresh:['ri','RiRefreshLine'],'star-filled':['ri','RiStarFill'],support:['md','MdOutlineSupportAgent'],microphone:['ri','RiMicLine'],keyboard:['ri','RiKeyboardLine'],listen:['ri','RiVolumeUpLine'],check:['ri','RiCheckLine'],close:['ri','RiCloseLine'],star:['ri','RiStarLine'],bookmark:['ri','RiBookmarkLine'],help:['fi','FiHelpCircle'],lock:['ri','RiLockLine'],down:['ri','RiArrowDownLine'],previous:['ri','RiArrowLeftLine'],next:['ri','RiArrowRightLine']};
for(const [name,[group,exported]] of Object.entries(icons)){
 const component=require('react-icons/'+group)[exported],svg=renderToStaticMarkup(React.createElement(component,{size:32})).replaceAll('currentColor','#000000'),folder=path.join(root,'Piyali/Resources/BrandAssets.xcassets/Flashcard-'+name+'.imageset');await fs.mkdir(folder,{recursive:true});await fs.writeFile(path.join(folder,'icon.svg'),svg);await fs.writeFile(path.join(folder,'Contents.json'),JSON.stringify({images:[{filename:'icon.svg',idiom:'universal'}],info:{author:'xcode',version:1},properties:{'preserves-vector-representation':true,'template-rendering-intent':'template'}}));
}
console.log('Exported '+Object.keys(icons).length+' original flashcard icon paths.');
