// Runs only inside the local reference fixture. Export the original RoomEnvironment
// as linear RGBE, before display tone mapping, for native image-based lighting.
export function exportRoomEnvironment(THREE,RoomEnvironment) {
  const renderer=new THREE.WebGLRenderer({antialias:false});renderer.outputColorSpace=THREE.LinearSRGBColorSpace;renderer.toneMapping=THREE.NoToneMapping;
  const room=new RoomEnvironment(),cube=new THREE.WebGLCubeRenderTarget(256,{type:THREE.HalfFloatType}),capture=new THREE.CubeCamera(0.1,100,cube);capture.update(renderer,room);
  const width=512,height=256,target=new THREE.WebGLRenderTarget(width,height,{type:THREE.HalfFloatType});
  const material=new THREE.ShaderMaterial({uniforms:{room:{value:cube.texture}},vertexShader:'varying vec2 texcoord;void main(){texcoord=uv;gl_Position=vec4(position.xy,0.0,1.0);}',fragmentShader:'uniform samplerCube room;varying vec2 texcoord;void main(){float phi=(1.0-texcoord.y)*3.14159265359;float theta=(texcoord.x-0.5)*6.28318530718;vec3 direction=vec3(-sin(phi)*cos(theta),cos(phi),sin(phi)*sin(theta));gl_FragColor=vec4(textureCube(room,direction).rgb,1.0);}'});
  const plane=new THREE.Mesh(new THREE.PlaneGeometry(2,2),material),scene=new THREE.Scene();scene.add(plane);renderer.setRenderTarget(target);renderer.render(scene,new THREE.Camera());
  const half=new Uint16Array(width*height*4);renderer.readRenderTargetPixels(target,0,0,width,height,half);
  const header=new TextEncoder().encode(`#?RADIANCE\nFORMAT=32-bit_rle_rgbe\n\n-Y ${height} +X ${width}\n`),bytes=new Uint8Array(header.length+width*height*4);bytes.set(header);
  for(let y=0;y<height;y++)for(let x=0;x<width;x++){const i=((height-1-y)*width+x)*4,j=header.length+(y*width+x)*4,rgb=[0,1,2].map(c=>THREE.DataUtils.fromHalfFloat(half[i+c])),max=Math.max(...rgb);if(max<1e-32)continue;const e=Math.ceil(Math.log2(max)),scale=256/2**e;for(let c=0;c<3;c++)bytes[j+c]=Math.min(255,Math.round(rgb[c]*scale));bytes[j+3]=e+128;}
  let binary='';for(let i=0;i<bytes.length;i+=8192)binary+=String.fromCharCode(...bytes.subarray(i,i+8192));const link=document.createElement('a');link.id='original-room-environment';link.href='data:application/octet-stream;base64,'+btoa(binary);link.download='orb-room.hdr';link.textContent='Save original room lighting for native orb';document.getElementById('root').replaceChildren(link);
  material.dispose();plane.geometry.dispose();target.dispose();cube.dispose();room.dispose();renderer.dispose();renderer.forceContextLoss();
}
