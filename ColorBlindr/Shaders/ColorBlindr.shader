Shader "Hidden/ColorBlindr"
{
	Properties
	{
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_Strength ("Blindness Strength (Float)", Float) = 1.0
	}

	CGINCLUDE

		#include "UnityCG.cginc"

		sampler2D _MainTex;
		float _Strength;

		// Adapted from http://colororacle.org/ algorithms
		// Highly unoptimized shaders but they're intended to be used in the editor only so who cares

		float3 rgb2lin(float3 c) { return (0.992052 * pow(c, 2.2) + 0.003974) * 128.498039; }
		float3 lin2rgb(float3 c) { return pow(c, 0.45454545); }

		float3 rgFilter(float3 color, float k1, float k2, float k3)
		{
			color = saturate(color);
			float3 c_lin = rgb2lin(color);
					
			float r_blind = (k1 * c_lin.r + k2 * c_lin.g) / 16448.25098;
			float b_blind = (k3 * c_lin.r - k3 * c_lin.g + 128.498039 * c_lin.b) / 16448.25098;
			r_blind = saturate(r_blind);
			b_blind = saturate(b_blind);

			return lerp(color, lin2rgb(float3(r_blind, r_blind, b_blind)), _Strength);
		}

		float3 tritanFilter(float3 color)
		{
			color = saturate(color);

			float anchor_e0 = 0.05059983 + 0.08585369 + 0.00952420;
			float anchor_e1 = 0.01893033 + 0.08925308 + 0.01370054;
			float anchor_e2 = 0.00292202 + 0.00975732 + 0.07145979;
			float inflection = anchor_e1 / anchor_e0;

			float a1 = -anchor_e2 * 0.007009;
			float b1 = anchor_e2 * 0.0914;
			float c1 = anchor_e0 * 0.007009 - anchor_e1 * 0.0914;
			float a2 = anchor_e1 * 0.3636 - anchor_e2 * 0.2237;
			float b2 = anchor_e2 * 0.1284 - anchor_e0 * 0.3636;
			float c2 = anchor_e0 * 0.2237 - anchor_e1 * 0.1284;

			float3 c_lin = rgb2lin(color);

			float L = (c_lin.r * 0.05059983 + c_lin.g * 0.08585369 + c_lin.b * 0.00952420) / 128.498039;
			float M = (c_lin.r * 0.01893033 + c_lin.g * 0.08925308 + c_lin.b * 0.01370054) / 128.498039;
			float S = (c_lin.r * 0.00292202 + c_lin.g * 0.00975732 + c_lin.b * 0.07145979) / 128.498039;

			float tmp = M / L;

			if (tmp < inflection) S = -(a1 * L + b1 * M) / c1;
			else S = -(a2 * L + b2 * M) / c2;

			float r = L * 30.830854 - M * 29.832659 + S * 1.610474;
			float g = -L * 6.481468 + M * 17.715578 - S * 2.532642;
			float b = -L * 0.375690 - M * 1.199062 + S * 14.273846;

			return lerp(color, lin2rgb(saturate(float3(r, g, b))), _Strength);
		}

	ENDCG

	SubShader
	{
		ZTest Always Cull Off ZWrite Off
		Fog { Mode off }

		// (0) Deuteranopia
		Pass
		{
			CGPROGRAM

				#pragma vertex vert_img
				#pragma fragment frag
				#pragma fragmentoption ARB_precision_hint_fastest

				float4 frag(v2f_img i) : SV_Target
				{
					float3 result = rgFilter(tex2D(_MainTex, i.uv).rgb, 37.611765, 90.87451, -2.862745);
					return float4(result, 1.0);
				}
			ENDCG
		}

		// (1) Protanopia
		Pass
		{
			CGPROGRAM

				#pragma vertex vert_img
				#pragma fragment frag
				#pragma fragmentoption ARB_precision_hint_fastest

				float4 frag(v2f_img i) : SV_Target
				{
					float3 result = rgFilter(tex2D(_MainTex, i.uv).rgb, 14.443137, 114.054902, 0.513725);
					return float4(result, 1.0);
				}
			ENDCG
		}

		// (2) Tritanopia
		Pass
		{
			CGPROGRAM
				#pragma vertex vert_img
				#pragma fragment frag
				#pragma fragmentoption ARB_precision_hint_fastest

				float4 frag(v2f_img i) : SV_Target
				{
					float3 result = tritanFilter(tex2D(_MainTex, i.uv).rgb);
					return float4(result, 1.0);
				}

			ENDCG
		}

		// (3) Deuteranopia - Linear
		Pass
		{
			CGPROGRAM

				#pragma vertex vert_img
				#pragma fragment frag
				#pragma fragmentoption ARB_precision_hint_fastest

				float4 frag(v2f_img i) : SV_Target
				{
					float3 color = LinearToGammaSpace(tex2D(_MainTex, i.uv).rgb);
					float3 result = rgFilter(color, 37.611765, 90.87451, -2.862745);
					return float4(GammaToLinearSpace(result), 1.0);
				}
			ENDCG
		}

		// (4) Protanopia - Linear
		Pass
		{
			CGPROGRAM

				#pragma vertex vert_img
				#pragma fragment frag
				#pragma fragmentoption ARB_precision_hint_fastest

				float4 frag(v2f_img i) : SV_Target
				{
					float3 color = LinearToGammaSpace(tex2D(_MainTex, i.uv).rgb);
					float3 result = rgFilter(color, 14.443137, 114.054902, 0.513725);
					return float4(GammaToLinearSpace(result), 1.0);
				}
			ENDCG
		}

		// (5) Tritanopia - Linear
		Pass
		{
			CGPROGRAM
				#pragma vertex vert_img
				#pragma fragment frag
				#pragma fragmentoption ARB_precision_hint_fastest

				float4 frag(v2f_img i) : SV_Target
				{
					float3 color = LinearToGammaSpace(tex2D(_MainTex, i.uv).rgb);
					float3 result = tritanFilter(color);
					return float4(GammaToLinearSpace(result), 1.0);
				}

			ENDCG
		}
	}

	FallBack off
}
