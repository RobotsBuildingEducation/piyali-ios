#pragma arguments
float orbTime;
float orbVoice;
float orbRipple;
float orbSpiral;
float orbWarp;
float orbTurbulence;
float3 orbDeep;
float3 orbMid;
float3 orbLight;
#pragma varyings
float3 orbPosition;
#pragma declaration
float orbNoise(float2 p) {
        float2 cell = floor(p);
        float2 f = fract(p);
        f = f * f * (3.0 - 2.0 * f);
        float4 n = float4(dot(cell, float2(12.9898, 4.1414)),
          dot(cell + float2(1.0, 0.0), float2(12.9898, 4.1414)),
          dot(cell + float2(0.0, 1.0), float2(12.9898, 4.1414)),
          dot(cell + float2(1.0), float2(12.9898, 4.1414)));
        n = fract(sin(n) * 43758.5453);
        return mix(mix(n.x, n.y, f.x), mix(n.z, n.w, f.x), f.y);
      }
#pragma body
float orbWaveScale=1.0;float orbWashAlpha=0.83;float orbVoiceMod=1.0;float3 pigment;float3 p=in.orbPosition;

        float drift = orbTime;
        float radius = length(p.xy);
        // VoiceOrb's listening ripples and speaking spiral, wrapped around the toy.
        float ripple = (sin(radius * (12.0 * orbWaveScale) - drift * 8.0) * 0.18
          + sin(radius * (20.0 * orbWaveScale) - drift * 13.0 + 1.2) * 0.08) * orbRipple;
        p.xy += p.xy / max(radius, 0.001) * ripple * (0.5 + orbVoice * orbVoiceMod);
        // Match VoiceOrb's speaking twist & inward thinking warp
        float spiral = radius * 6.0 * orbSpiral
          - sin(p.y * 2.0 + drift) * orbWarp * 1.1;
        float spiralCos = cos(spiral);
        float spiralSin = sin(spiral);
        p.xy = float2(p.x * spiralCos - p.y * spiralSin,
                    p.x * spiralSin + p.y * spiralCos);
        float2 watercolor = float2(orbNoise(p.xy * (2.2 * orbWaveScale) + drift),
          orbNoise(p.yz * 2.0 - drift + 74.85)) - 0.5;
        p.xy += watercolor * orbTurbulence * 0.5;
        float wave = sin((p.x * 3.4 + p.y * 2.8) * orbWaveScale + sin(p.z * 3.0 + drift) * 1.6 - drift);
        float ribbon = sin((p.y * 4.0 - p.x * 2.4) * orbWaveScale + sin(p.z * 2.5 - drift) + drift * 0.7);
        // Active states expose more of the saturated pigment beneath the pale wash.
        wave -= orbWarp * 0.22 + orbSpiral * orbVoice * 0.28 * orbVoiceMod;
        pigment = mix(orbDeep, orbMid, smoothstep(-0.9, 0.65, wave));
        float wash = orbWashAlpha - orbWarp * 0.2 - orbSpiral * (0.14 + orbVoice * 0.25 * orbVoiceMod);
        pigment = mix(pigment, orbLight, smoothstep(0.08, 0.95, ribbon) * wash);
_surface.diffuse.rgb *= pigment;
