// Metal port of the referenced tutorAtmosphereScene.js color field.
#include <metal_stdlib>
using namespace metal;

struct VoiceVertex {
  float4 position [[position]];
  float2 uv;
};

struct VoiceUniforms {
  float time, light, aspect, activity, speechOffset, speechTravel;
};

vertex VoiceVertex voiceAtmosphereVertex(uint index [[vertex_id]]) {
  const float2 coordinates[] = { float2(-1., -1.), float2(3., -1.), float2(-1., 3.) };
  float2 point = coordinates[index];
  VoiceVertex result;
  result.position = float4(point, 0., 1.);
  result.uv = float2((point.x + 1.) * .5, (1. - point.y) * .5);
  return result;
}

float hash(float3 p) {
  p = fract(p * 0.1031);
  p += dot(p, p.yzx + 33.33);
  return fract((p.x + p.y) * p.z);
}
// Smooth 3D noise gives the field an evolving shape, rather than translating
// a fixed chain of alternating peaks. Time is sampled continuously, never reseeded.
float softNoise(float3 p) {
  float3 cell = floor(p);
  float3 f = fract(p);
  f = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);
  float bottom = mix(
    mix(hash(cell), hash(cell + float3(1.0, 0.0, 0.0)), f.x),
    mix(hash(cell + float3(0.0, 1.0, 0.0)), hash(cell + float3(1.0, 1.0, 0.0)), f.x), f.y);
  float top = mix(
    mix(hash(cell + float3(0.0, 0.0, 1.0)), hash(cell + float3(1.0, 0.0, 1.0)), f.x),
    mix(hash(cell + float3(0.0, 1.0, 1.0)), hash(cell + float3(1.0, 1.0, 1.0)), f.x), f.y);
  return mix(bottom, top, f.z);
}
fragment half4 voiceAtmosphereFragment(VoiceVertex input [[stage_in]],
                                        constant VoiceUniforms &uniforms [[buffer(0)]]) {
  float uTime = uniforms.time;
  float uLight = uniforms.light;
  float uAspect = uniforms.aspect;
  float uActivity = uniforms.activity;
  float uSpeechOffset = uniforms.speechOffset;
  float uSpeechTravel = uniforms.speechTravel;
  float2 uv = float2(input.uv);
  float speechResponse = 1.0 - exp(-uActivity * 3.0);
  // Signed movement follows voice dynamics, independently of the wave shape.
  float speechSwell = uSpeechOffset;
  float span = mix(2.4, 3.6, smoothstep(0.6, 1.5, uAspect));
  // Left-to-right advection and independent slow evolution: patches can merge,
  // stretch or recede as they travel, without a repeated high/low pattern.
  float3 flow = float3(uv.x * span - uTime * 0.16, uv.y * 3.0, uTime * 0.075);
  float2 warp = float2(
    softNoise(flow * 0.63 + float3(4.7, 2.1, 8.3)),
    softNoise(flow * 0.57 + float3(9.2, 6.8, 3.4))) - 0.5;
  float3 shaped = flow + float3(warp * float2(1.35, 1.1), 0.0);
  float broad = softNoise(shaped + float3(2.1, 5.7, 1.3));
  float detail = softNoise(shaped * 1.7 + float3(7.4, 3.2, 6.9));
  float field = broad * 0.78 + detail * 0.22;
  float coolField = softNoise(float3(uv.x * 2.0 - uTime * 0.12, uv.y * 2.5, uTime * 0.065) + float3(warp, 0.0) + float3(5.6, 9.4, 2.8));
  float warmField = softNoise(float3(uv.x * 2.5 - uTime * 0.10, uv.y * 3.1, uTime * 0.09) + float3(warp.yx, 0.0) + float3(9.7, 4.2, 7.6));
  float3 colorFlow = float3(uv.x * 1.6 - uTime * 0.09, uv.y * 1.8, uTime * 0.10);
  float tone = softNoise(colorFlow + float3(3.2, 7.1, 4.8));
  float hue = softNoise(colorFlow * 0.8 + float3(8.6, 2.3, 6.1));

  // Three separate gradients retain their hues as they overlap: blue/mint
  // beneath a cooler accent and a violet/green accent, each with its own depth.
  float3 deep = mix(float3(0.075, 0.23, 0.56), float3(0.24, 0.68, 0.50), uLight);
  float3 bright = mix(float3(0.17, 0.41, 0.82), float3(0.39, 0.88, 0.68), uLight);
  float3 coolAccent = mix(float3(0.045, 0.51, 0.57), float3(0.28, 0.75, 0.98), uLight);
  float3 warmAccent = mix(float3(0.34, 0.29, 0.72), float3(0.48, 0.84, 0.36), uLight);
  float shade = smoothstep(0.20, 0.80, field * 0.55 + tone * 0.45);
  float3 baseColor = mix(deep, bright, shade);
  float3 coolColor = coolAccent * mix(mix(0.64, 0.94, uLight), 1.12, smoothstep(0.18, 0.82, coolField));
  float3 warmColor = warmAccent * mix(mix(0.62, 0.94, uLight), 1.14, smoothstep(0.18, 0.82, warmField));

  // Shape the density in two dimensions so dark pockets and asymmetric lobes
  // can develop inside the wash, instead of every column sharing one gradient.
  float density = smoothstep(0.24, 0.72, field);
  float reach = clamp(0.18 + 0.35 * density + speechSwell, 0.09, 0.60);
  float feather = mix(0.17, 0.27, detail);
  float fade = 1.0 - smoothstep(max(0.0, reach - feather), reach, uv.y);
  // All density contours feather out before 60%, including loud speech.
  fade *= 1.0 - smoothstep(0.55, 0.60, uv.y);

  // A warped seam separates the color regions instead of mixing every hue
  // everywhere. Different moving fade contours make their layering visible.
  float seam = 0.38 + hue * 0.26;
  float across = uv.x + warp.x * 0.23 + (uv.y - 0.2) * (tone - 0.5) * 0.5;
  float coolMask = 1.0 - smoothstep(seam - 0.18, seam + 0.08, across);
  float warmMask = smoothstep(seam - 0.04, seam + 0.22, across);
  float coolReach = clamp(0.20 + smoothstep(0.20, 0.78, coolField) * 0.28 + speechSwell, 0.08, 0.60);
  float warmReach = clamp(0.21 + smoothstep(0.20, 0.78, warmField) * 0.28 + speechSwell, 0.08, 0.60);
  float coolFade = 1.0 - smoothstep(max(0.0, coolReach - 0.19), coolReach, uv.y);
  float warmFade = 1.0 - smoothstep(max(0.0, warmReach - 0.22), warmReach, uv.y);
  float baseWeight = fade * 0.40;
  float coolWeight = coolMask * coolFade * 0.80;
  float warmWeight = warmMask * warmFade * 0.80;

  // A separate, translucent wave travels right-to-left through all color
  // regions. Speech swells this layer; it does not shove or reverse the wash.
  float3 speechFlow = float3(uv.x * span * 0.85 + uSpeechTravel, uv.y * 2.7, uTime * 0.04);
  float2 speechWarp = float2(
    softNoise(speechFlow * 0.60 + float3(3.8, 6.2, 9.1)),
    softNoise(speechFlow * 0.54 + float3(7.3, 1.6, 5.4))) - 0.5;
  float speechField = softNoise(speechFlow + float3(speechWarp * 1.1, 0.0) + float3(6.1, 8.3, 2.7));
  // Ordinary playback is often only 0.2–0.4 on the shared envelope. Give those
  // levels a visible swell, following syllables rather than the slow turn fade.
  float speechReach = clamp(0.22 + smoothstep(0.20, 0.78, speechField) * 0.22
    + speechSwell, 0.08, 0.60);
  float speechFade = 1.0 - smoothstep(max(0.0, speechReach - 0.22), speechReach, uv.y);
  float speechWeight = speechFade * speechResponse * 0.90;
  float3 speechColor = mix(coolAccent, warmAccent, smoothstep(0.22, 0.78, speechField))
    * mix(0.85, 1.12, speechField);
  float coverage = baseWeight + coolWeight + warmWeight + speechWeight;
  float3 color = (baseColor * baseWeight + coolColor * coolWeight + warmColor * warmWeight
    + speechColor * speechWeight) / max(coverage, 0.0001);
  color *= mix(mix(0.88, 1.02, uLight), 1.10, tone);

  // Fine, stationary grain: texture without flickering pixels.
  float grain = hash(float3(input.position.xy, 7.0)) - 0.5;
  color += grain * mix(0.028, 0.018, uLight);
  float opacity = min(1.0, mix(0.63, 0.44, uLight) * min(coverage, 1.0) * (0.82 + tone * 0.18) * (1.0 + uActivity * 0.08));
  return half4(half3(saturate(color) * opacity), half(opacity));
}
