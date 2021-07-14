float BPMOffset(float bpm, float note)
{
    float step = 60 / (bpm * (1 / note));
    float curr = _Time.y % step;
    curr /= step;
    return curr;
}

float4 PostLightingHook(float4 col, HookData data)
{
    #if defined(UNITY_PASS_FORWARDBASE)
        if (!_ALFallback)
        {
            return col;
        }
        FragmentData i = data.i;
        TextureUV t = data.t;
        float4 emission = 0;
        if(_EmissionAudioLinkChannel == 0)
        {
            emission = lerp(i.emissionMap, i.emissionMap * i.diffuseColor.xyzz, _EmissionToDiffuse) * _EmissionColor;
        }
        else
        {
            float offset = BPMOffset(_ALFallbackBPM,1);
            if(_EmissionAudioLinkChannel != 5)
            {
                int2 aluv;
                if (_EmissionAudioLinkChannel == 6)
                {
                    aluv = int2(t.emissionMapUV.x * _ALUVWidth, t.emissionMapUV.y);
                } else
                {
                    aluv = int2(0, (_EmissionAudioLinkChannel-1));
                }
                aluv.x -= offset;
                float alink = lerp(1, UNITY_SAMPLE_TEX2D_SAMPLER(_ALFallbackTexture, _MainTex, aluv).x , saturate(_EmissionAudioLinkChannel));
                emission = lerp(i.emissionMap, i.emissionMap * i.diffuseColor.xyzz, _EmissionToDiffuse) * _EmissionColor * alink;
            }
            else
            {
                float audioDataBass = UNITY_SAMPLE_TEX2D_SAMPLER(_ALFallbackTexture, _MainTex, float2(offset, 0)).x;
                float audioDataMids = UNITY_SAMPLE_TEX2D_SAMPLER(_ALFallbackTexture, _MainTex, float2(offset, 1)).x;
                float audioDataHighs = (UNITY_SAMPLE_TEX2D_SAMPLER(_ALFallbackTexture, _MainTex, float2(offset, 2)).x + UNITY_SAMPLE_TEX2D_SAMPLER(_ALFallbackTexture, _MainTex, float2(0, 3)).x) * 0.5;

                float tLow = smoothstep((1-audioDataBass), (1-audioDataBass) + 0.01, i.emissionMap.r) * i.emissionMap.a;
                float tMid = smoothstep((1-audioDataMids), (1-audioDataMids) + 0.01, i.emissionMap.g) * i.emissionMap.a;
                float tHigh = smoothstep((1-audioDataHighs), (1-audioDataHighs) + 0.01, i.emissionMap.b) * i.emissionMap.a;

                float4 emissionChannelRed = lerp(i.emissionMap.r, tLow, _ALGradientOnRed) * _EmissionColor * audioDataBass;
                float4 emissionChannelGreen = lerp(i.emissionMap.g, tMid, _ALGradientOnGreen) * _EmissionColor0 * audioDataMids;
                float4 emissionChannelBlue = lerp(i.emissionMap.b, tHigh, _ALGradientOnBlue) * _EmissionColor1 * audioDataHighs;
                emission = (emissionChannelRed + emissionChannelGreen + emissionChannelBlue) * lerp(1, i.diffuseColor.rgbb, _EmissionToDiffuse);
            }

            emission.rgb = rgb2hsv(emission.rgb);
            emission.x += fmod(_Hue, 360);
            emission.y = saturate(emission.y * _Saturation);
            emission.z *= _Value;
            emission.rgb = hsv2rgb(emission.rgb);
        }

        col += emission;

        return col;
    #else
        return col;
    #endif
}
