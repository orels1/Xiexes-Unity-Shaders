half4 XSLighting_BRDF_Toon(XSLighting i)
{   
    calcNormal(i);
    
    int lightEnv = int(any(_WorldSpaceLightPos0.xyz));
    half3 lightDir = calcLightDir(i);
    half3 viewDir = calcViewDir(i.worldPos);
    half3 stereoViewDir = calcStereoViewDir(i.worldPos);
    half4 metallicSmoothnessMask = calcMetallicSmoothness(i);
    half3 halfVector = normalize(lightDir + viewDir);

    half3 reflView = reflect(-viewDir, i.normal);
    half3 reflLight = reflect(lightDir, i.normal);

    DotProducts d = (DotProducts)0;
    d.ndl = dot(i.normal, lightDir);
    d.vdn = abs(dot(viewDir, i.normal));
    d.vdh = DotClamped(viewDir, halfVector);
    d.tdh = dot(i.tangent, halfVector);
    d.bdh = dot(i.bitangent, halfVector);
    d.ndh = DotClamped(i.normal, halfVector);
    d.rdv = saturate( dot( reflLight, float4(-viewDir, 0) ));
    d.ldh = DotClamped(lightDir, halfVector);
    d.svdn = abs(dot(stereoViewDir, i.normal));

    i.albedo.rgb *= (1-metallicSmoothnessMask.x); 

#if SPLIT_TERM_DIFFUSE
    half3 indirectDiffuse = ShadeSH9(float4(0,0,0,1));
#if defined(DIRECTIONAL)
    half3 indirectDiffuseDirect = calcIndirectDiffuse(i, lightDir);
#endif
#else
    half3 indirectDiffuse = calcIndirectDiffuse();
#endif

    half4 lightCol = calcLightCol(lightEnv, indirectDiffuse);
    half4 diffuse = calcDiffuse(i, d, indirectDiffuse, lightCol);

    half3 indirectSpecular = calcIndirectSpecular(i, d, metallicSmoothnessMask, reflView, indirectDiffuse, viewDir);
 
    half4 rimLight = calcRimLight(i, d, lightCol, indirectDiffuse);
    half4 shadowRim = calcShadowRim(i, d, indirectDiffuse);
    half3 directSpecular = calcDirectSpecular(i, d, lightCol, indirectDiffuse, metallicSmoothnessMask, _AnisotropicAX * 0.1, _AnisotropicAY * 0.1);
    half4 subsurface = calcSubsurfaceScattering(i, d, lightDir, viewDir, i.normal, lightCol, indirectDiffuse);
    half4 outlineColor = calcOutlineColor(i, d, indirectDiffuse, lightCol);
    half4 occlusion = lerp(1, _OcclusionColor, 1-i.occlusion);

	half4 col;
    col = diffuse * shadowRim * (1-metallicSmoothnessMask.x);
    col += indirectSpecular.xyzz;
    col += directSpecular.xyzz;
    col += rimLight;
    col += subsurface;
#if defined(DIRECTIONAL) && SPLIT_TERM_DIFFUSE
    col += float4(indirectDiffuseDirect, 0);
#endif
    //col *= occlusion;

    float4 finalColor = lerp(col, outlineColor, i.isOutline);

#if UNITY_PASS_FORWARDBASE
	//finalColor = tex2D(_ShadowMapTexture, i.uv0);
#endif

	return finalColor;
}