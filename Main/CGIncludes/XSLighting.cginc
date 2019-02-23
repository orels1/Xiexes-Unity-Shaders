half4 XSLighting_BRDF_Toon(XSLighting i)
{   
    calcNormal(i);
    

    int lightEnv = int(any(_WorldSpaceLightPos0.xyz));
    half3 lightDir = calcLightDir(i);
    half3 viewDir = calcViewDir(i.worldPos);
    half2 metallicSmoothness = calcMetallicSmoothness(i);
    half3 stereoViewDir = calcStereoViewDir(i.worldPos);
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

    i.albedo.rgb *= 1-metallicSmoothness.x;

    half3 indirectDiffuse = calcIndirectDiffuse();
    half4 lightCol = calcLightCol(lightEnv, indirectDiffuse);
    half3 indirectSpecular = calcIndirectSpecular(i, metallicSmoothness, reflView);
    half4 rimLight = calcRimLight(i, d, lightCol, indirectDiffuse);
    half4 shadowRim = calcShadowRim(i, d, indirectDiffuse);
    half4 diffuse = calcDiffuse(i, d, indirectDiffuse, lightCol);
    half3 directSpecular = calcDirectSpecular(i, d, lightCol, indirectDiffuse, metallicSmoothness, _AnisotropicAX * 0.1, _AnisotropicAY * 0.1);
    half4 subsurface = calcSubsurfaceScattering(i, d, lightDir, viewDir, i.normal, lightCol, indirectDiffuse);
    half4 outlineColor = calcOutlineColor(i, d, indirectDiffuse, lightCol);

	half4 col;
    col = diffuse * shadowRim;
    col += indirectSpecular.xyzz;
    col += directSpecular.xyzz;
    col += rimLight;
    col += subsurface;
    col -= LineHalftone(i, smoothstep(0.1, 5, -d.ndl*0.5+0.5) );

    float4 finalColor = lerp(col, outlineColor, i.isOutline);

	return finalColor;
}