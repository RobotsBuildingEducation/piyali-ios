#pragma declaration
float3 RRTAndODTFit( float3 v ) {

	float3 a = v * ( v + 0.0245786 ) - 0.000090537;
	float3 b = v * ( 0.983729 * v + 0.4329510 ) + 0.238081;
	return a / b;

}
float3 ACESFilmicToneMapping( float3 color ) {

	// sRGB => XYZ => D65_2_D60 => AP1 => RRT_SAT
	const float3x3 ACESInputMat = float3x3(
		float3( 0.59719, 0.07600, 0.02840 ), // transposed from source
		float3( 0.35458, 0.90834, 0.13383 ),
		float3( 0.04823, 0.01566, 0.83777 )
	);

	// ODT_SAT => XYZ => D60_2_D65 => sRGB
	const float3x3 ACESOutputMat = float3x3(
		float3(  1.60475, -0.10208, -0.00327 ), // transposed from source
		float3( -0.53108,  1.10813, -0.07276 ),
		float3( -0.07367, -0.00605,  1.07602 )
	);

	color *= 1.2 / 0.6;

	color = ACESInputMat * color;

	// Apply RRT and ODT
	color = RRTAndODTFit( color );

	color = ACESOutputMat * color;

	// Clamp to [0, 1]
	return saturate( color );

}
#pragma body
_output.color.rgb = ACESFilmicToneMapping(_output.color.rgb);
