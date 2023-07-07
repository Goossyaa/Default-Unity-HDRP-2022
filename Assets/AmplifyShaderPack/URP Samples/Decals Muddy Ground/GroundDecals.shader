// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader  "AmplifyShaderPack/URP/GroundDecals"
{
    Properties
    {
        [HideInInspector] _AlphaCutoff("Alpha Cutoff ", Range(0, 1)) = 0.5
        [HideInInspector] _EmissionColor("Emission Color", Color) = (1,1,1,1)
        [ASEBegin]_BaseColor("Base Color", 2D) = "white" {}
        _Mask("Mask", 2D) = "white" {}
        _Normal("Normal", 2D) = "bump" {}
        _SmoothnessMultiplier("Smoothness Multiplier", Range( 0 , 1)) = 0
        _NormalIntensity("Normal Intensity", Float) = 1
        _DecalQuantity("Decal Quantity", Float) = 2
        [ASEEnd][IntRange]_DecalType("Decal Type", Range( 0 , 3)) = 3

        [HideInInspector]_DrawOrder("Draw Order", Range(-50, 50)) = 0
        [HideInInspector][Enum(Depth Bias, 0, View Bias, 1)]_DecalMeshBiasType("DecalMesh BiasType", Float) = 0
        [HideInInspector]_DecalMeshDepthBias("DecalMesh DepthBias", Float) = 0
        [HideInInspector]_DecalMeshViewBias("DecalMesh ViewBias", Float) = 0
        [HideInInspector][NoScaleOffset]unity_Lightmaps("unity_Lightmaps", 2DArray) = "" {}
        [HideInInspector][NoScaleOffset]unity_LightmapsInd("unity_LightmapsInd", 2DArray) = "" {}
        [HideInInspector][NoScaleOffset]unity_ShadowMasks("unity_ShadowMasks", 2DArray) = "" {}
        [HideInInspector] _DecalAngleFadeSupported("Decal Angle Fade Supported", Float) = 1
    }

    SubShader
    {
		LOD 0

			


        Tags { "RenderPipeline"="UniversalPipeline" "PreviewType"="Plane" "ShaderGraphShader"="true" }

		HLSLINCLUDE
		#pragma target 3.5
		ENDHLSL
		
        Pass
        { 
			
            Name "DBufferProjector"
            Tags { "LightMode"="DBufferProjector" }
        
            Cull Front
			Blend 0 SrcAlpha OneMinusSrcAlpha, Zero OneMinusSrcAlpha
			Blend 1 SrcAlpha OneMinusSrcAlpha, Zero OneMinusSrcAlpha
			Blend 2 SrcAlpha OneMinusSrcAlpha, Zero OneMinusSrcAlpha
			ZTest Greater
			ZWrite Off
			ColorMask RGBA
			ColorMask RGBA 1
			ColorMask RGBA 2
        
        
            HLSLPROGRAM

			#define _MATERIAL_AFFECTS_ALBEDO 1
			#define _MATERIAL_AFFECTS_NORMAL 1
			#define _MATERIAL_AFFECTS_NORMAL_BLEND 1
			#define  _MATERIAL_AFFECTS_MAOS 1
			#define DECAL_ANGLE_FADE 1
			#define ASE_SRP_VERSION 120101


			#pragma vertex Vert
			#pragma fragment Frag
			#pragma multi_compile_instancing
        
            #pragma multi_compile _ _DBUFFER_MRT1 _DBUFFER_MRT2 _DBUFFER_MRT3
        
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        
            
            #define HAVE_MESH_MODIFICATION
        
        
            #define SHADERPASS SHADERPASS_DBUFFER_PROJECTOR
        
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DecalInput.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderVariablesDecal.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DBuffer.hlsl"
        
			#define ASE_NEEDS_FRAG_TEXTURE_COORDINATES0


			struct SurfaceDescription
			{
				float3 BaseColor;
				float Alpha;
				float3 NormalTS;
				float NormalAlpha;
				float Metallic;
				float Occlusion;
				float Smoothness;
				float MAOSAlpha;
			};

			struct Attributes
			{
				float3 positionOS : POSITION;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID	
			};

			struct PackedVaryings
			{
				float4 positionCS : SV_POSITION;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};
        

            CBUFFER_START(UnityPerMaterial)
			float _DecalQuantity;
			float _DecalType;
			float _NormalIntensity;
			float _SmoothnessMultiplier;
			float _DrawOrder;
			float _DecalMeshBiasType;
			float _DecalMeshDepthBias;
			float _DecalMeshViewBias;
			#if defined(DECAL_ANGLE_FADE)
			float _DecalAngleFadeSupported;
			#endif
			CBUFFER_END
       
			sampler2D _BaseColor;
			sampler2D _Normal;
			sampler2D _Mask;


			
            void GetSurfaceData(SurfaceDescription surfaceDescription, half3 viewDirectioWS, uint2 positionSS, float angleFadeFactor, out DecalSurfaceData surfaceData)
            {
                half4x4 normalToWorld = UNITY_ACCESS_INSTANCED_PROP(Decal, _NormalToWorld);
                half fadeFactor = clamp(normalToWorld[0][3], 0.0f, 1.0f) * angleFadeFactor;
                float2 scale = float2(normalToWorld[3][0], normalToWorld[3][1]);
                float2 offset = float2(normalToWorld[3][2], normalToWorld[3][3]);
        
                ZERO_INITIALIZE(DecalSurfaceData, surfaceData);
                surfaceData.occlusion = half(1.0);
                surfaceData.smoothness = half(0);
        
                #ifdef _MATERIAL_AFFECTS_NORMAL
                    surfaceData.normalWS.w = half(1.0);
                #else
                    surfaceData.normalWS.w = half(0.0);
                #endif
        
        
                surfaceData.baseColor.xyz = half3(surfaceDescription.BaseColor);
                surfaceData.baseColor.w = half(surfaceDescription.Alpha * fadeFactor);
        
                #if defined(_MATERIAL_AFFECTS_NORMAL)
                    surfaceData.normalWS.xyz = mul((half3x3)normalToWorld, surfaceDescription.NormalTS.xyz);
                #else
                    surfaceData.normalWS.xyz = normalToWorld[2].xyz;
                #endif

        
                surfaceData.normalWS.w = surfaceDescription.NormalAlpha * fadeFactor;
				#if defined( _MATERIAL_AFFECTS_MAOS )
                surfaceData.metallic = half(surfaceDescription.Metallic);
                surfaceData.occlusion = half(surfaceDescription.Occlusion);
                surfaceData.smoothness = half(surfaceDescription.Smoothness);
                surfaceData.MAOSAlpha = half(surfaceDescription.MAOSAlpha * fadeFactor);
				#endif
            }
        
			#define DECAL_PROJECTOR
			#define DECAL_DBUFFER

			#if ((!defined(_MATERIAL_AFFECTS_NORMAL) && defined(_MATERIAL_AFFECTS_ALBEDO)) || (defined(_MATERIAL_AFFECTS_NORMAL) && defined(_MATERIAL_AFFECTS_NORMAL_BLEND))) && (defined(DECAL_SCREEN_SPACE) || defined(DECAL_GBUFFER))
			#define DECAL_RECONSTRUCT_NORMAL
			#elif defined(DECAL_ANGLE_FADE)
			#define DECAL_LOAD_NORMAL
			#endif

			#if defined(DECAL_LOAD_NORMAL)
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareNormalsTexture.hlsl"
			#endif

			#if defined(DECAL_PROJECTOR) || defined(DECAL_RECONSTRUCT_NORMAL)
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
			#endif

			#ifdef DECAL_MESH
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/DecalMeshBiasTypeEnum.cs.hlsl"
			#endif
			#ifdef DECAL_RECONSTRUCT_NORMAL
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/NormalReconstruction.hlsl"
			#endif


			PackedVaryings Vert(Attributes inputMesh  )
			{
				PackedVaryings packedOutput;
				ZERO_INITIALIZE(PackedVaryings, packedOutput);

				UNITY_SETUP_INSTANCE_ID(inputMesh);
				UNITY_TRANSFER_INSTANCE_ID(inputMesh, packedOutput);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(packedOutput);

				
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = inputMesh.positionOS.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif
				float3 vertexValue = defaultVertexValue;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					inputMesh.positionOS.xyz = vertexValue;
				#else
					inputMesh.positionOS.xyz += vertexValue;
				#endif

				VertexPositionInputs vertexInput = GetVertexPositionInputs(inputMesh.positionOS.xyz);
    
				float3 positionWS = TransformObjectToWorld(inputMesh.positionOS);			
				packedOutput.positionCS = TransformWorldToHClip(positionWS);

				return packedOutput;
			}

			void Frag(PackedVaryings packedInput,
				OUTPUT_DBUFFER(outDBuffer)
				 
			)
			{
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(packedInput);
				UNITY_SETUP_INSTANCE_ID(packedInput);
				
				half angleFadeFactor = 1.0;

				#if UNITY_REVERSED_Z
					float depth = LoadSceneDepth(packedInput.positionCS.xy);
				#else
					float depth = lerp(UNITY_NEAR_CLIP_VALUE, 1, LoadSceneDepth(packedInput.positionCS.xy));
				#endif
			

			#if defined(DECAL_RECONSTRUCT_NORMAL)
				#if defined(_DECAL_NORMAL_BLEND_HIGH)
					half3 normalWS = half3(ReconstructNormalTap9(packedInput.positionCS.xy));
				#elif defined(_DECAL_NORMAL_BLEND_MEDIUM)
					half3 normalWS = half3(ReconstructNormalTap5(packedInput.positionCS.xy));
				#else
					half3 normalWS = half3(ReconstructNormalDerivative(packedInput.positionCS.xy));
				#endif
			#elif defined(DECAL_LOAD_NORMAL)
				half3 normalWS = half3(LoadSceneNormals(packedInput.positionCS.xy));
			#endif

			float2 positionSS = packedInput.positionCS.xy * _ScreenSize.zw;
			float3 positionWS = ComputeWorldSpacePosition(positionSS, depth, UNITY_MATRIX_I_VP);


			float3 positionDS = TransformWorldToObject(positionWS);
			positionDS = positionDS * float3(1.0, -1.0, 1.0);

			float clipValue = 0.5 - Max3(abs(positionDS).x, abs(positionDS).y, abs(positionDS).z);
			clip(clipValue);

			float2 texCoord = positionDS.xz + float2(0.5, 0.5);

			#ifdef DECAL_ANGLE_FADE
				half4x4 normalToWorld = UNITY_ACCESS_INSTANCED_PROP(Decal, _NormalToWorld);
				half2 angleFade = half2(normalToWorld[1][3], normalToWorld[2][3]);

				if (angleFade.y < 0.0f)
				{
					half3 decalNormal = half3(normalToWorld[0].z, normalToWorld[1].z, normalToWorld[2].z);
					half dotAngle = dot(normalWS, decalNormal);
					angleFadeFactor = saturate(angleFade.x + angleFade.y * (dotAngle * (dotAngle - 2.0)));
				}
			#endif


				half3 viewDirectionWS = half3(1.0, 1.0, 1.0); 
				DecalSurfaceData surfaceData;

				SurfaceDescription surfaceDescription = (SurfaceDescription)0;

				float2 texCoord15 = texCoord * float2( 1,1 ) + float2( 0,0 );
				// *** BEGIN Flipbook UV Animation vars ***
				// Total tiles of Flipbook Texture
				float fbtotaltiles17 = _DecalQuantity * _DecalQuantity;
				// Offsets for cols and rows of Flipbook Texture
				float fbcolsoffset17 = 1.0f / _DecalQuantity;
				float fbrowsoffset17 = 1.0f / _DecalQuantity;
				// Speed of animation
				float fbspeed17 = _Time[ 1 ] * 0.0;
				// UV Tiling (col and row offset)
				float2 fbtiling17 = float2(fbcolsoffset17, fbrowsoffset17);
				// UV Offset - calculate current tile linear index, and convert it to (X * coloffset, Y * rowoffset)
				// Calculate current tile linear index
				float fbcurrenttileindex17 = round( fmod( fbspeed17 + _DecalType, fbtotaltiles17) );
				fbcurrenttileindex17 += ( fbcurrenttileindex17 < 0) ? fbtotaltiles17 : 0;
				// Obtain Offset X coordinate from current tile linear index
				float fblinearindextox17 = round ( fmod ( fbcurrenttileindex17, _DecalQuantity ) );
				// Multiply Offset X by coloffset
				float fboffsetx17 = fblinearindextox17 * fbcolsoffset17;
				// Obtain Offset Y coordinate from current tile linear index
				float fblinearindextoy17 = round( fmod( ( fbcurrenttileindex17 - fblinearindextox17 ) / _DecalQuantity, _DecalQuantity ) );
				// Reverse Y to get tiles from Top to Bottom
				fblinearindextoy17 = (int)(_DecalQuantity-1) - fblinearindextoy17;
				// Multiply Offset Y by rowoffset
				float fboffsety17 = fblinearindextoy17 * fbrowsoffset17;
				// UV Offset
				float2 fboffset17 = float2(fboffsetx17, fboffsety17);
				// Flipbook UV
				half2 fbuv17 = texCoord15 * fbtiling17 + fboffset17;
				// *** END Flipbook UV Animation vars ***
				float2 FlipUVs20 = fbuv17;
				float4 tex2DNode9 = tex2D( _BaseColor, FlipUVs20 );
				
				float3 unpack10 = UnpackNormalScale( tex2D( _Normal, FlipUVs20 ), _NormalIntensity );
				unpack10.z = lerp( 1, unpack10.z, saturate(_NormalIntensity) );
				
				float4 tex2DNode11 = tex2D( _Mask, FlipUVs20 );
				
				surfaceDescription.BaseColor = tex2DNode9.rgb;
				surfaceDescription.Alpha = tex2DNode9.a;
				surfaceDescription.NormalTS = unpack10;
				surfaceDescription.NormalAlpha = tex2DNode9.a;
				
				#if defined( _MATERIAL_AFFECTS_MAOS )
				surfaceDescription.Metallic = tex2DNode11.r;
				surfaceDescription.Occlusion = tex2DNode11.g;
				surfaceDescription.Smoothness =( tex2DNode11.a * _SmoothnessMultiplier );
				surfaceDescription.MAOSAlpha = tex2DNode9.a;
				#endif

				GetSurfaceData(surfaceDescription, viewDirectionWS, (uint2)positionSS, angleFadeFactor, surfaceData);
				ENCODE_INTO_DBUFFER(surfaceData, outDBuffer);
			
			}

        
            ENDHLSL
        }

		
        Pass
        { 
			
            Name "DecalScreenSpaceProjector"
            Tags { "LightMode"="DecalScreenSpaceProjector" }
        
            Cull Front
			Blend SrcAlpha OneMinusSrcAlpha
			ZTest Greater
			ZWrite Off
        
            HLSLPROGRAM
        
			#define _MATERIAL_AFFECTS_ALBEDO 1
			#define _MATERIAL_AFFECTS_NORMAL 1
			#define _MATERIAL_AFFECTS_NORMAL_BLEND 1
			#define  _MATERIAL_AFFECTS_MAOS 1
			#define DECAL_ANGLE_FADE 1
			#define ASE_SRP_VERSION 120101

        
			#pragma vertex Vert
			#pragma fragment Frag
			#pragma multi_compile_instancing
			#pragma multi_compile_fog
        
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
			#pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
			#pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
			#pragma multi_compile _ _SHADOWS_SOFT
			#pragma multi_compile _ _CLUSTERED_RENDERING
			#pragma multi_compile _DECAL_NORMAL_BLEND_LOW _DECAL_NORMAL_BLEND_MEDIUM _DECAL_NORMAL_BLEND_HIGH
        
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        
            #define ATTRIBUTES_NEED_NORMAL
            #define VARYINGS_NEED_NORMAL_WS
            #define VARYINGS_NEED_VIEWDIRECTION_WS
            #define VARYINGS_NEED_FOG_AND_VERTEX_LIGHT
            #define VARYINGS_NEED_SH
            #define VARYINGS_NEED_STATIC_LIGHTMAP_UV
            #define VARYINGS_NEED_DYNAMIC_LIGHTMAP_UV
            
            #define HAVE_MESH_MODIFICATION
        
        
            #define SHADERPASS SHADERPASS_DECAL_SCREEN_SPACE_PROJECTOR
        
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DecalInput.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderVariablesDecal.hlsl"
        
			#define ASE_NEEDS_FRAG_TEXTURE_COORDINATES0


			struct SurfaceDescription
			{
				float3 BaseColor;
				float Alpha;
				float3 NormalTS;
				float NormalAlpha;
				float Metallic;
				float Occlusion;
				float Smoothness;
				float MAOSAlpha;
				float3 Emission;
			};

			struct Attributes
			{
				float3 positionOS : POSITION;
				float3 normalOS : NORMAL;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct PackedVaryings
			{
				float4 positionCS : SV_POSITION;
				float3 normalWS : TEXCOORD0;
				float3 viewDirectionWS : TEXCOORD1;
				float2 staticLightmapUV : TEXCOORD2;
				float2 dynamicLightmapUV : TEXCOORD3;
				float3 sh : TEXCOORD4;
				float4 fogFactorAndVertexLight : TEXCOORD5;
				
				UNITY_VERTEX_OUTPUT_STEREO
			};
        
        
            CBUFFER_START(UnityPerMaterial)
			float _DecalQuantity;
			float _DecalType;
			float _NormalIntensity;
			float _SmoothnessMultiplier;
			float _DrawOrder;
			float _DecalMeshBiasType;
			float _DecalMeshDepthBias;
			float _DecalMeshViewBias;
			#if defined(DECAL_ANGLE_FADE)
			float _DecalAngleFadeSupported;
			#endif
			CBUFFER_END
			sampler2D _BaseColor;
			sampler2D _Normal;
			sampler2D _Mask;


			
            void GetSurfaceData( SurfaceDescription surfaceDescription, half3 viewDirectioWS, uint2 positionSS, float angleFadeFactor, out DecalSurfaceData surfaceData)
            {
                
                half4x4 normalToWorld = UNITY_ACCESS_INSTANCED_PROP(Decal, _NormalToWorld);
                half fadeFactor = clamp(normalToWorld[0][3], 0.0f, 1.0f) * angleFadeFactor;
                float2 scale = float2(normalToWorld[3][0], normalToWorld[3][1]);
                float2 offset = float2(normalToWorld[3][2], normalToWorld[3][3]);

        
                ZERO_INITIALIZE(DecalSurfaceData, surfaceData);
                surfaceData.occlusion = half(1.0);
                surfaceData.smoothness = half(0);
        
                #ifdef _MATERIAL_AFFECTS_NORMAL
                    surfaceData.normalWS.w = half(1.0);
                #else
                    surfaceData.normalWS.w = half(0.0);
                #endif
        
				#if defined( _MATERIAL_AFFECTS_EMISSION )
                surfaceData.emissive.rgb = half3(surfaceDescription.Emission.rgb * fadeFactor);
				#endif

                surfaceData.baseColor.xyz = half3(surfaceDescription.BaseColor);
                surfaceData.baseColor.w = half(surfaceDescription.Alpha * fadeFactor);
        
                #if defined(_MATERIAL_AFFECTS_NORMAL)
                    surfaceData.normalWS.xyz = mul((half3x3)normalToWorld, surfaceDescription.NormalTS.xyz);
                #else
                    surfaceData.normalWS.xyz = normalToWorld[2].xyz;
                #endif

                surfaceData.normalWS.w = surfaceDescription.NormalAlpha * fadeFactor;
				
				#if defined( _MATERIAL_AFFECTS_MAOS )
                surfaceData.metallic = half(surfaceDescription.Metallic);
                surfaceData.occlusion = half(surfaceDescription.Occlusion);
                surfaceData.smoothness = half(surfaceDescription.Smoothness);
                surfaceData.MAOSAlpha = half(surfaceDescription.MAOSAlpha * fadeFactor);
				#endif
            }
        

			#define DECAL_PROJECTOR
			#define DECAL_SCREEN_SPACE

			#if ((!defined(_MATERIAL_AFFECTS_NORMAL) && defined(_MATERIAL_AFFECTS_ALBEDO)) || (defined(_MATERIAL_AFFECTS_NORMAL) && defined(_MATERIAL_AFFECTS_NORMAL_BLEND))) && (defined(DECAL_SCREEN_SPACE) || defined(DECAL_GBUFFER))
			#define DECAL_RECONSTRUCT_NORMAL
			#elif defined(DECAL_ANGLE_FADE)
			#define DECAL_LOAD_NORMAL
			#endif

			#if defined(DECAL_LOAD_NORMAL)
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareNormalsTexture.hlsl"
			#endif

			#if defined(DECAL_PROJECTOR) || defined(DECAL_RECONSTRUCT_NORMAL)
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
			#endif

			#ifdef DECAL_MESH
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/DecalMeshBiasTypeEnum.cs.hlsl"
			#endif
			#ifdef DECAL_RECONSTRUCT_NORMAL
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/NormalReconstruction.hlsl"
			#endif

			void InitializeInputData( PackedVaryings input, float3 positionWS, half3 normalWS, half3 viewDirectionWS, out InputData inputData)
			{
				inputData = (InputData)0;

				inputData.positionWS = positionWS;
				inputData.normalWS = normalWS;
				inputData.viewDirectionWS = viewDirectionWS;
				inputData.shadowCoord = float4(0, 0, 0, 0);
			
				inputData.fogCoord = half(input.fogFactorAndVertexLight.x);
				inputData.vertexLighting = half3(input.fogFactorAndVertexLight.yzw);
			

			#if defined(VARYINGS_NEED_DYNAMIC_LIGHTMAP_UV) && defined(DYNAMICLIGHTMAP_ON)
				inputData.bakedGI = SAMPLE_GI(input.staticLightmapUV, input.dynamicLightmapUV.xy, half3(input.sh), normalWS);
			#elif defined(VARYINGS_NEED_STATIC_LIGHTMAP_UV)
				inputData.bakedGI = SAMPLE_GI(input.staticLightmapUV, half3(input.sh), normalWS);
			#endif

			#if defined(VARYINGS_NEED_STATIC_LIGHTMAP_UV)
				inputData.shadowMask = SAMPLE_SHADOWMASK(input.staticLightmapUV);
			#endif

				#if defined(DEBUG_DISPLAY)
				#if defined(VARYINGS_NEED_DYNAMIC_LIGHTMAP_UV) && defined(DYNAMICLIGHTMAP_ON)
				inputData.dynamicLightmapUV = input.dynamicLightmapUV.xy;
				#endif
				#if defined(VARYINGS_NEED_STATIC_LIGHTMAP_UV && LIGHTMAP_ON)
				inputData.staticLightmapUV = input.staticLightmapUV;
				#elif defined(VARYINGS_NEED_SH)
				inputData.vertexSH = input.sh;
				#endif
				#endif

				inputData.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(input.positionCS);
			}

			void GetSurface(DecalSurfaceData decalSurfaceData, inout SurfaceData surfaceData)
			{
				surfaceData.albedo = decalSurfaceData.baseColor.rgb;
				surfaceData.metallic = saturate(decalSurfaceData.metallic);
				surfaceData.specular = 0;
				surfaceData.smoothness = saturate(decalSurfaceData.smoothness);
				surfaceData.occlusion = decalSurfaceData.occlusion;
				surfaceData.emission = decalSurfaceData.emissive;
				surfaceData.alpha = saturate(decalSurfaceData.baseColor.w);
				surfaceData.clearCoatMask = 0;
				surfaceData.clearCoatSmoothness = 1;
			}

			PackedVaryings Vert(Attributes inputMesh  )
			{
				PackedVaryings packedOutput;
				ZERO_INITIALIZE(PackedVaryings, packedOutput);

				UNITY_SETUP_INSTANCE_ID(inputMesh);
				UNITY_TRANSFER_INSTANCE_ID(inputMesh, packedOutput);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(packedOutput);

				
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = inputMesh.positionOS.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif
				float3 vertexValue = defaultVertexValue;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					inputMesh.positionOS.xyz = vertexValue;
				#else
					inputMesh.positionOS.xyz += vertexValue;
				#endif

				VertexPositionInputs vertexInput = GetVertexPositionInputs(inputMesh.positionOS.xyz);
				float3 positionWS = TransformObjectToWorld(inputMesh.positionOS);

				float3 normalWS = TransformObjectToWorldNormal(inputMesh.normalOS);
				
				packedOutput.positionCS = TransformWorldToHClip(positionWS);
				half fogFactor = 0;
			#if !defined(_FOG_FRAGMENT)
					fogFactor = ComputeFogFactor(packedOutput.positionCS.z);
			#endif
				half3 vertexLight = VertexLighting(positionWS, normalWS);
				packedOutput.fogFactorAndVertexLight = half4(fogFactor, vertexLight);

				packedOutput.normalWS.xyz =  normalWS;
				packedOutput.viewDirectionWS.xyz =  GetWorldSpaceViewDir(positionWS);
				
				#if defined(LIGHTMAP_ON)
				OUTPUT_LIGHTMAP_UV(inputMesh.uv1, unity_LightmapST, packedOutput.staticLightmapUV);
				#endif
				
				#if defined(DYNAMICLIGHTMAP_ON)
				packedOutput.dynamicLightmapUV.xy = inputMesh.uv2.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
				#endif
				
				#if !defined(LIGHTMAP_ON)
				packedOutput.sh.xyz =  float3(SampleSHVertex(half3(normalWS)));
				#endif

				return packedOutput;
			}

			void Frag(PackedVaryings packedInput,
				out half4 outColor : SV_Target0
				 
			)
			{
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(packedInput);
				UNITY_SETUP_INSTANCE_ID(packedInput);

				half angleFadeFactor = 1.0;

				#if UNITY_REVERSED_Z
					float depth = LoadSceneDepth(packedInput.positionCS.xy);
				#else
					float depth = lerp(UNITY_NEAR_CLIP_VALUE, 1, LoadSceneDepth(packedInput.positionCS.xy));
				#endif

			#if defined(DECAL_RECONSTRUCT_NORMAL)
				#if defined(_DECAL_NORMAL_BLEND_HIGH)
					half3 normalWS = half3(ReconstructNormalTap9(packedInput.positionCS.xy));
				#elif defined(_DECAL_NORMAL_BLEND_MEDIUM)
					half3 normalWS = half3(ReconstructNormalTap5(packedInput.positionCS.xy));
				#else
					half3 normalWS = half3(ReconstructNormalDerivative(packedInput.positionCS.xy));
				#endif
			#elif defined(DECAL_LOAD_NORMAL)
				half3 normalWS = half3(LoadSceneNormals(packedInput.positionCS.xy));
			#endif

				float2 positionSS = packedInput.positionCS.xy * _ScreenSize.zw;

				float3 positionWS = ComputeWorldSpacePosition(positionSS, depth, UNITY_MATRIX_I_VP);


				float3 positionDS = TransformWorldToObject(positionWS);
				positionDS = positionDS * float3(1.0, -1.0, 1.0);

				float clipValue = 0.5 - Max3(abs(positionDS).x, abs(positionDS).y, abs(positionDS).z);
				clip(clipValue);

				float2 texCoord = positionDS.xz + float2(0.5, 0.5);


				#ifdef DECAL_ANGLE_FADE
					half4x4 normalToWorld = UNITY_ACCESS_INSTANCED_PROP(Decal, _NormalToWorld);
					half2 angleFade = half2(normalToWorld[1][3], normalToWorld[2][3]);

					if (angleFade.y < 0.0f)
					{
						half3 decalNormal = half3(normalToWorld[0].z, normalToWorld[1].z, normalToWorld[2].z);
						half dotAngle = dot(normalWS, decalNormal);
						angleFadeFactor = saturate(angleFade.x + angleFade.y * (dotAngle * (dotAngle - 2.0)));
					}
				#endif

			
				half3 viewDirectionWS = half3(packedInput.viewDirectionWS);
	
				DecalSurfaceData surfaceData;

				float2 texCoord15 = texCoord * float2( 1,1 ) + float2( 0,0 );
				// *** BEGIN Flipbook UV Animation vars ***
				// Total tiles of Flipbook Texture
				float fbtotaltiles17 = _DecalQuantity * _DecalQuantity;
				// Offsets for cols and rows of Flipbook Texture
				float fbcolsoffset17 = 1.0f / _DecalQuantity;
				float fbrowsoffset17 = 1.0f / _DecalQuantity;
				// Speed of animation
				float fbspeed17 = _Time[ 1 ] * 0.0;
				// UV Tiling (col and row offset)
				float2 fbtiling17 = float2(fbcolsoffset17, fbrowsoffset17);
				// UV Offset - calculate current tile linear index, and convert it to (X * coloffset, Y * rowoffset)
				// Calculate current tile linear index
				float fbcurrenttileindex17 = round( fmod( fbspeed17 + _DecalType, fbtotaltiles17) );
				fbcurrenttileindex17 += ( fbcurrenttileindex17 < 0) ? fbtotaltiles17 : 0;
				// Obtain Offset X coordinate from current tile linear index
				float fblinearindextox17 = round ( fmod ( fbcurrenttileindex17, _DecalQuantity ) );
				// Multiply Offset X by coloffset
				float fboffsetx17 = fblinearindextox17 * fbcolsoffset17;
				// Obtain Offset Y coordinate from current tile linear index
				float fblinearindextoy17 = round( fmod( ( fbcurrenttileindex17 - fblinearindextox17 ) / _DecalQuantity, _DecalQuantity ) );
				// Reverse Y to get tiles from Top to Bottom
				fblinearindextoy17 = (int)(_DecalQuantity-1) - fblinearindextoy17;
				// Multiply Offset Y by rowoffset
				float fboffsety17 = fblinearindextoy17 * fbrowsoffset17;
				// UV Offset
				float2 fboffset17 = float2(fboffsetx17, fboffsety17);
				// Flipbook UV
				half2 fbuv17 = texCoord15 * fbtiling17 + fboffset17;
				// *** END Flipbook UV Animation vars ***
				float2 FlipUVs20 = fbuv17;
				float4 tex2DNode9 = tex2D( _BaseColor, FlipUVs20 );
				
				float3 unpack10 = UnpackNormalScale( tex2D( _Normal, FlipUVs20 ), _NormalIntensity );
				unpack10.z = lerp( 1, unpack10.z, saturate(_NormalIntensity) );
				
				float4 tex2DNode11 = tex2D( _Mask, FlipUVs20 );
				
				SurfaceDescription surfaceDescription = (SurfaceDescription)0;

				surfaceDescription.BaseColor = tex2DNode9.rgb;
				surfaceDescription.Alpha = tex2DNode9.a;
				surfaceDescription.NormalTS = unpack10;
				surfaceDescription.NormalAlpha = tex2DNode9.a;
				#if defined( _MATERIAL_AFFECTS_MAOS )
				surfaceDescription.Metallic = tex2DNode11.r;
				surfaceDescription.Occlusion = tex2DNode11.g;
				surfaceDescription.Smoothness = ( tex2DNode11.a * _SmoothnessMultiplier );
				surfaceDescription.MAOSAlpha = tex2DNode9.a;
				#endif
				
				#if defined( _MATERIAL_AFFECTS_EMISSION )
				surfaceDescription.Emission = float3(0, 0, 0);
				#endif

				GetSurfaceData( surfaceDescription, viewDirectionWS, (uint2)positionSS, angleFadeFactor, surfaceData);

				#ifdef DECAL_RECONSTRUCT_NORMAL
					surfaceData.normalWS.xyz = normalize(lerp(normalWS.xyz, surfaceData.normalWS.xyz, surfaceData.normalWS.w));
				#endif

				InputData inputData;
				InitializeInputData( packedInput, positionWS, surfaceData.normalWS.xyz, viewDirectionWS, inputData);

				SurfaceData surface = (SurfaceData)0;
				GetSurface(surfaceData, surface);

				half4 color = UniversalFragmentPBR(inputData, surface);
				color.rgb = MixFog(color.rgb, inputData.fogCoord);
				outColor = color;

			}

            ENDHLSL
        }

		
        Pass
        { 
            
			Name "DecalGBufferProjector"
            Tags { "LightMode"="DecalGBufferProjector" }
        
            Cull Front
			Blend 0 SrcAlpha OneMinusSrcAlpha
			Blend 1 SrcAlpha OneMinusSrcAlpha
			Blend 2 SrcAlpha OneMinusSrcAlpha
			Blend 3 SrcAlpha OneMinusSrcAlpha
			ZTest Greater
			ZWrite Off
			ColorMask RGB
			ColorMask 0 1
			ColorMask RGB 2
			ColorMask RGB 3
        
            HLSLPROGRAM
        
			#define _MATERIAL_AFFECTS_ALBEDO 1
			#define _MATERIAL_AFFECTS_NORMAL 1
			#define _MATERIAL_AFFECTS_NORMAL_BLEND 1
			#define  _MATERIAL_AFFECTS_MAOS 1
			#define DECAL_ANGLE_FADE 1
			#define ASE_SRP_VERSION 120101

        
			#pragma vertex Vert
			#pragma fragment Frag
			#pragma multi_compile_instancing
			#pragma multi_compile_fog
        
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
			#pragma multi_compile _ _SHADOWS_SOFT
			#pragma multi_compile _DECAL_NORMAL_BLEND_LOW _DECAL_NORMAL_BLEND_MEDIUM _DECAL_NORMAL_BLEND_HIGH
			#pragma multi_compile _ _GBUFFER_NORMALS_OCT
        
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        
            #define ATTRIBUTES_NEED_NORMAL
            #define VARYINGS_NEED_NORMAL_WS
            #define VARYINGS_NEED_VIEWDIRECTION_WS
            #define VARYINGS_NEED_SH
            #define VARYINGS_NEED_STATIC_LIGHTMAP_UV
            #define VARYINGS_NEED_DYNAMIC_LIGHTMAP_UV
            
            #define HAVE_MESH_MODIFICATION
        
        
            #define SHADERPASS SHADERPASS_DECAL_GBUFFER_PROJECTOR
        
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/UnityGBuffer.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DecalInput.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderVariablesDecal.hlsl"
        
			#define ASE_NEEDS_FRAG_TEXTURE_COORDINATES0

        
			struct SurfaceDescription
			{
				float3 BaseColor;
				float Alpha;
				float3 NormalTS;
				float NormalAlpha;
				float Metallic;
				float Occlusion;
				float Smoothness;
				float MAOSAlpha;
				float3 Emission;
			};
        
            struct Attributes
			{
				float3 positionOS : POSITION;
				float3 normalOS : NORMAL;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct PackedVaryings
			{
				float4 positionCS : SV_POSITION;
				float3 normalWS : TEXCOORD0;
				float3 viewDirectionWS : TEXCOORD1;
				float2 staticLightmapUV : TEXCOORD2;
				float2 dynamicLightmapUV : TEXCOORD3;
				float3 sh : TEXCOORD4;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};
        
            CBUFFER_START(UnityPerMaterial)
			float _DecalQuantity;
			float _DecalType;
			float _NormalIntensity;
			float _SmoothnessMultiplier;
			float _DrawOrder;
			float _DecalMeshBiasType;
			float _DecalMeshDepthBias;
			float _DecalMeshViewBias;
			#if defined(DECAL_ANGLE_FADE)
			float _DecalAngleFadeSupported;
			#endif
			CBUFFER_END
			sampler2D _BaseColor;
			sampler2D _Normal;
			sampler2D _Mask;


			/*ase_funcs*/            

            void GetSurfaceData(SurfaceDescription surfaceDescription, half3 viewDirectioWS, uint2 positionSS, float angleFadeFactor, out DecalSurfaceData surfaceData)
            {
                
                half4x4 normalToWorld = UNITY_ACCESS_INSTANCED_PROP(Decal, _NormalToWorld);
                half fadeFactor = clamp(normalToWorld[0][3], 0.0f, 1.0f) * angleFadeFactor;
                float2 scale = float2(normalToWorld[3][0], normalToWorld[3][1]);
                float2 offset = float2(normalToWorld[3][2], normalToWorld[3][3]);

                ZERO_INITIALIZE(DecalSurfaceData, surfaceData);
                surfaceData.occlusion = half(1.0);
                surfaceData.smoothness = half(0);
        
                #ifdef _MATERIAL_AFFECTS_NORMAL
                    surfaceData.normalWS.w = half(1.0);
                #else
                    surfaceData.normalWS.w = half(0.0);
                #endif
        
				#if defined( _MATERIAL_AFFECTS_EMISSION )
                surfaceData.emissive.rgb = half3(surfaceDescription.Emission.rgb * fadeFactor);
				#endif

                surfaceData.baseColor.xyz = half3(surfaceDescription.BaseColor);
                surfaceData.baseColor.w = half(surfaceDescription.Alpha * fadeFactor);
        
                #if defined(_MATERIAL_AFFECTS_NORMAL)
                    surfaceData.normalWS.xyz = mul((half3x3)normalToWorld, surfaceDescription.NormalTS.xyz);
                #else
                    surfaceData.normalWS.xyz = normalToWorld[2].xyz;
                #endif

                surfaceData.normalWS.w = surfaceDescription.NormalAlpha * fadeFactor;
				#if defined( _MATERIAL_AFFECTS_MAOS )
                surfaceData.metallic = half(surfaceDescription.Metallic);
                surfaceData.occlusion = half(surfaceDescription.Occlusion);
                surfaceData.smoothness = half(surfaceDescription.Smoothness);
                surfaceData.MAOSAlpha = half(surfaceDescription.MAOSAlpha * fadeFactor);
				#endif
            }
        
			#define DECAL_PROJECTOR
			#define DECAL_GBUFFER
			

			#if ((!defined(_MATERIAL_AFFECTS_NORMAL) && defined(_MATERIAL_AFFECTS_ALBEDO)) || (defined(_MATERIAL_AFFECTS_NORMAL) && defined(_MATERIAL_AFFECTS_NORMAL_BLEND))) && (defined(DECAL_SCREEN_SPACE) || defined(DECAL_GBUFFER))
			#define DECAL_RECONSTRUCT_NORMAL
			#elif defined(DECAL_ANGLE_FADE)
			#define DECAL_LOAD_NORMAL
			#endif

			#if defined(DECAL_LOAD_NORMAL)
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareNormalsTexture.hlsl"
			#endif

			#if defined(DECAL_PROJECTOR) || defined(DECAL_RECONSTRUCT_NORMAL)
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
			#endif

			#ifdef DECAL_MESH
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/DecalMeshBiasTypeEnum.cs.hlsl"
			#endif
			#ifdef DECAL_RECONSTRUCT_NORMAL
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/NormalReconstruction.hlsl"
			#endif


			void InitializeInputData(PackedVaryings input, float3 positionWS, half3 normalWS, half3 viewDirectionWS, out InputData inputData)
			{
				inputData = (InputData)0;

				inputData.positionWS = positionWS;
				inputData.normalWS = normalWS;
				inputData.viewDirectionWS = viewDirectionWS;

				inputData.shadowCoord = float4(0, 0, 0, 0);
			
			#ifdef VARYINGS_NEED_FOG_AND_VERTEX_LIGHT
				inputData.fogCoord = half(input.fogFactorAndVertexLight.x);
				inputData.vertexLighting = half3(input.fogFactorAndVertexLight.yzw);
			#endif

			#if defined(VARYINGS_NEED_DYNAMIC_LIGHTMAP_UV) && defined(DYNAMICLIGHTMAP_ON)
				inputData.bakedGI = SAMPLE_GI(input.staticLightmapUV, input.dynamicLightmapUV.xy, half3(input.sh), normalWS);
			#elif defined(VARYINGS_NEED_STATIC_LIGHTMAP_UV)
				inputData.bakedGI = SAMPLE_GI(input.staticLightmapUV, half3(input.sh), normalWS);
			#endif

			#if defined(VARYINGS_NEED_STATIC_LIGHTMAP_UV)
				inputData.shadowMask = SAMPLE_SHADOWMASK(input.staticLightmapUV);
			#endif

				#if defined(DEBUG_DISPLAY)
				#if defined(VARYINGS_NEED_DYNAMIC_LIGHTMAP_UV) && defined(DYNAMICLIGHTMAP_ON)
				inputData.dynamicLightmapUV = input.dynamicLightmapUV.xy;
				#endif
				#if defined(VARYINGS_NEED_STATIC_LIGHTMAP_UV && LIGHTMAP_ON)
				inputData.staticLightmapUV = input.staticLightmapUV;
				#elif defined(VARYINGS_NEED_SH)
				inputData.vertexSH = input.sh;
				#endif
				#endif

				inputData.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(input.positionCS);
			}

			void GetSurface(DecalSurfaceData decalSurfaceData, inout SurfaceData surfaceData)
			{
				surfaceData.albedo = decalSurfaceData.baseColor.rgb;
				surfaceData.metallic = saturate(decalSurfaceData.metallic);
				surfaceData.specular = 0;
				surfaceData.smoothness = saturate(decalSurfaceData.smoothness);
				surfaceData.occlusion = decalSurfaceData.occlusion;
				surfaceData.emission = decalSurfaceData.emissive;
				surfaceData.alpha = saturate(decalSurfaceData.baseColor.w);
				surfaceData.clearCoatMask = 0;
				surfaceData.clearCoatSmoothness = 1;
			}

			PackedVaryings Vert(Attributes inputMesh  )
			{
				PackedVaryings packedOutput;
				ZERO_INITIALIZE(PackedVaryings, packedOutput);

				UNITY_SETUP_INSTANCE_ID(inputMesh);
				UNITY_TRANSFER_INSTANCE_ID(inputMesh, packedOutput);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(packedOutput);

				
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = inputMesh.positionOS.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif
				float3 vertexValue = defaultVertexValue;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					inputMesh.positionOS.xyz = vertexValue;
				#else
					inputMesh.positionOS.xyz += vertexValue;
				#endif

				float3 positionWS = TransformObjectToWorld(inputMesh.positionOS);
				float3 normalWS = TransformObjectToWorldNormal(inputMesh.normalOS);

				packedOutput.positionCS = TransformWorldToHClip(positionWS);
				packedOutput.normalWS.xyz =  normalWS;
				packedOutput.viewDirectionWS.xyz =  GetWorldSpaceViewDir(positionWS);
				#if defined(LIGHTMAP_ON)
				OUTPUT_LIGHTMAP_UV(inputMesh.uv1, unity_LightmapST, packedOutput.staticLightmapUV);
				#endif
				#if defined(DYNAMICLIGHTMAP_ON)
				packedOutput.dynamicLightmapUV.xy = inputMesh.uv2.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
				#endif
				#if !defined(LIGHTMAP_ON)
				packedOutput.sh = float3(SampleSHVertex(half3(normalWS)));
				#endif

				return packedOutput;
			}

			void Frag(PackedVaryings packedInput,
				out FragmentOutput fragmentOutput
				 
			)
			{
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(packedInput);
				UNITY_SETUP_INSTANCE_ID(packedInput);	

				half angleFadeFactor = 1.0;

			#if UNITY_REVERSED_Z
				float depth = LoadSceneDepth(packedInput.positionCS.xy);
			#else
				float depth = lerp(UNITY_NEAR_CLIP_VALUE, 1, LoadSceneDepth(packedInput.positionCS.xy));
			#endif
			

			#if defined(DECAL_RECONSTRUCT_NORMAL)
				#if defined(_DECAL_NORMAL_BLEND_HIGH)
					half3 normalWS = half3(ReconstructNormalTap9(packedInput.positionCS.xy));
				#elif defined(_DECAL_NORMAL_BLEND_MEDIUM)
					half3 normalWS = half3(ReconstructNormalTap5(packedInput.positionCS.xy));
				#else
					half3 normalWS = half3(ReconstructNormalDerivative(packedInput.positionCS.xy));
				#endif
			#elif defined(DECAL_LOAD_NORMAL)
				half3 normalWS = half3(LoadSceneNormals(packedInput.positionCS.xy));
			#endif

				float2 positionSS = packedInput.positionCS.xy * _ScreenSize.zw;

				float3 positionWS = ComputeWorldSpacePosition(positionSS, depth, UNITY_MATRIX_I_VP);

				float3 positionDS = TransformWorldToObject(positionWS);
				positionDS = positionDS * float3(1.0, -1.0, 1.0);

				float clipValue = 0.5 - Max3(abs(positionDS).x, abs(positionDS).y, abs(positionDS).z);
				clip(clipValue);

				float2 texCoord = positionDS.xz + float2(0.5, 0.5);

				#ifdef DECAL_ANGLE_FADE
					half4x4 normalToWorld = UNITY_ACCESS_INSTANCED_PROP(Decal, _NormalToWorld);
					half2 angleFade = half2(normalToWorld[1][3], normalToWorld[2][3]);

					if (angleFade.y < 0.0f)
					{
						half3 decalNormal = half3(normalToWorld[0].z, normalToWorld[1].z, normalToWorld[2].z);
						half dotAngle = dot(normalWS, decalNormal);
						angleFadeFactor = saturate(angleFade.x + angleFade.y * (dotAngle * (dotAngle - 2.0)));
					}
				#endif


				half3 viewDirectionWS = half3(packedInput.viewDirectionWS);
				DecalSurfaceData surfaceData;

				SurfaceDescription surfaceDescription = (SurfaceDescription)0;
				float2 texCoord15 = texCoord * float2( 1,1 ) + float2( 0,0 );
				// *** BEGIN Flipbook UV Animation vars ***
				// Total tiles of Flipbook Texture
				float fbtotaltiles17 = _DecalQuantity * _DecalQuantity;
				// Offsets for cols and rows of Flipbook Texture
				float fbcolsoffset17 = 1.0f / _DecalQuantity;
				float fbrowsoffset17 = 1.0f / _DecalQuantity;
				// Speed of animation
				float fbspeed17 = _Time[ 1 ] * 0.0;
				// UV Tiling (col and row offset)
				float2 fbtiling17 = float2(fbcolsoffset17, fbrowsoffset17);
				// UV Offset - calculate current tile linear index, and convert it to (X * coloffset, Y * rowoffset)
				// Calculate current tile linear index
				float fbcurrenttileindex17 = round( fmod( fbspeed17 + _DecalType, fbtotaltiles17) );
				fbcurrenttileindex17 += ( fbcurrenttileindex17 < 0) ? fbtotaltiles17 : 0;
				// Obtain Offset X coordinate from current tile linear index
				float fblinearindextox17 = round ( fmod ( fbcurrenttileindex17, _DecalQuantity ) );
				// Multiply Offset X by coloffset
				float fboffsetx17 = fblinearindextox17 * fbcolsoffset17;
				// Obtain Offset Y coordinate from current tile linear index
				float fblinearindextoy17 = round( fmod( ( fbcurrenttileindex17 - fblinearindextox17 ) / _DecalQuantity, _DecalQuantity ) );
				// Reverse Y to get tiles from Top to Bottom
				fblinearindextoy17 = (int)(_DecalQuantity-1) - fblinearindextoy17;
				// Multiply Offset Y by rowoffset
				float fboffsety17 = fblinearindextoy17 * fbrowsoffset17;
				// UV Offset
				float2 fboffset17 = float2(fboffsetx17, fboffsety17);
				// Flipbook UV
				half2 fbuv17 = texCoord15 * fbtiling17 + fboffset17;
				// *** END Flipbook UV Animation vars ***
				float2 FlipUVs20 = fbuv17;
				float4 tex2DNode9 = tex2D( _BaseColor, FlipUVs20 );
				
				float3 unpack10 = UnpackNormalScale( tex2D( _Normal, FlipUVs20 ), _NormalIntensity );
				unpack10.z = lerp( 1, unpack10.z, saturate(_NormalIntensity) );
				
				float4 tex2DNode11 = tex2D( _Mask, FlipUVs20 );
				
				surfaceDescription.BaseColor = tex2DNode9.rgb;
				surfaceDescription.Alpha = tex2DNode9.a;
				surfaceDescription.NormalTS = unpack10;
				surfaceDescription.NormalAlpha = tex2DNode9.a;
				#if defined( _MATERIAL_AFFECTS_MAOS )
				surfaceDescription.Metallic = tex2DNode11.r;
				surfaceDescription.Occlusion =tex2DNode11.g;
				surfaceDescription.Smoothness = ( tex2DNode11.a * _SmoothnessMultiplier );
				surfaceDescription.MAOSAlpha = tex2DNode9.a;
				#endif
				
				#if defined( _MATERIAL_AFFECTS_EMISSION )
				surfaceDescription.Emission = float3(0, 0, 0);
				#endif

				GetSurfaceData(surfaceDescription, viewDirectionWS, (uint2)positionSS, angleFadeFactor, surfaceData);

				InputData inputData;
				InitializeInputData(packedInput, positionWS, surfaceData.normalWS.xyz, viewDirectionWS, inputData);

				SurfaceData surface = (SurfaceData)0;
				GetSurface(surfaceData, surface);

				BRDFData brdfData;
				InitializeBRDFData(surface.albedo, surface.metallic, 0, surface.smoothness, surface.alpha, brdfData);

				#ifdef _MATERIAL_AFFECTS_ALBEDO

					#ifdef DECAL_RECONSTRUCT_NORMAL
						half3 normalGI = normalize(lerp(normalWS.xyz, surfaceData.normalWS.xyz, surfaceData.normalWS.w));
					#endif

					Light mainLight = GetMainLight(inputData.shadowCoord, inputData.positionWS, inputData.shadowMask);
					MixRealtimeAndBakedGI(mainLight, normalGI, inputData.bakedGI, inputData.shadowMask);
					half3 color = GlobalIllumination(brdfData, inputData.bakedGI, surface.occlusion, normalGI, inputData.viewDirectionWS);
				#else
					half3 color = 0;
				#endif

				half3 packedNormalWS = PackNormal(surfaceData.normalWS.xyz);
				fragmentOutput.GBuffer0 = half4(surfaceData.baseColor.rgb, surfaceData.baseColor.a);
				fragmentOutput.GBuffer1 = 0;
				fragmentOutput.GBuffer2 = half4(packedNormalWS, surfaceData.normalWS.a);
				fragmentOutput.GBuffer3 = half4(surfaceData.emissive + color, surfaceData.baseColor.a);
				#if OUTPUT_SHADOWMASK
					fragmentOutput.GBuffer4 = inputData.shadowMask;
				#endif

			}

            ENDHLSL
        }

		
        Pass
        { 
            
			Name "DBufferMesh"
            Tags { "LightMode"="DBufferMesh" }
        
            Blend 0 SrcAlpha OneMinusSrcAlpha, Zero OneMinusSrcAlpha
			Blend 1 SrcAlpha OneMinusSrcAlpha, Zero OneMinusSrcAlpha
			Blend 2 SrcAlpha OneMinusSrcAlpha, Zero OneMinusSrcAlpha
			ZTest LEqual
			ZWrite Off
			ColorMask RGBA
			ColorMask RGBA 1
			ColorMask RGBA 2
        
            HLSLPROGRAM
        
			#define _MATERIAL_AFFECTS_ALBEDO 1
			#define _MATERIAL_AFFECTS_NORMAL 1
			#define _MATERIAL_AFFECTS_NORMAL_BLEND 1
			#define  _MATERIAL_AFFECTS_MAOS 1
			#define DECAL_ANGLE_FADE 1
			#define ASE_SRP_VERSION 120101

        
			#pragma vertex Vert
			#pragma fragment Frag
			#pragma multi_compile_instancing
        
            #pragma multi_compile _ _DBUFFER_MRT1 _DBUFFER_MRT2 _DBUFFER_MRT3
        
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        
            #define ATTRIBUTES_NEED_NORMAL
            #define ATTRIBUTES_NEED_TANGENT
            #define ATTRIBUTES_NEED_TEXCOORD0
            #define ATTRIBUTES_NEED_TEXCOORD1
            #define ATTRIBUTES_NEED_TEXCOORD2
            #define VARYINGS_NEED_POSITION_WS
            #define VARYINGS_NEED_NORMAL_WS
            #define VARYINGS_NEED_TANGENT_WS
            #define VARYINGS_NEED_TEXCOORD0
            
            #define HAVE_MESH_MODIFICATION
        
        
            #define SHADERPASS SHADERPASS_DBUFFER_MESH
        
        
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DecalInput.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderVariablesDecal.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DBuffer.hlsl"
        
            
            
			struct SurfaceDescription
			{
				float3 BaseColor;
				float Alpha;
				float3 NormalTS;
				float NormalAlpha;
				float Metallic;
				float Occlusion;
				float Smoothness;
				float MAOSAlpha;
			};

			struct Attributes
			{
				float3 positionOS : POSITION;
				float3 normalOS : NORMAL;
				float4 tangentOS : TANGENT;
				float4 uv0 : TEXCOORD0;
				float4 uv1 : TEXCOORD1;
				float4 uv2 : TEXCOORD2;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct PackedVaryings
			{
				float4 positionCS : SV_POSITION;
				float3 positionWS : TEXCOORD0;
				float3 normalWS : TEXCOORD1;
				float4 tangentWS : TEXCOORD2;
				float4 texCoord0 : TEXCOORD3;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};
        
            CBUFFER_START(UnityPerMaterial)
			float _DecalQuantity;
			float _DecalType;
			float _NormalIntensity;
			float _SmoothnessMultiplier;
			float _DrawOrder;
			float _DecalMeshBiasType;
			float _DecalMeshDepthBias;
			float _DecalMeshViewBias;
			#if defined(DECAL_ANGLE_FADE)
			float _DecalAngleFadeSupported;
			#endif
			CBUFFER_END
 			sampler2D _BaseColor;
 			sampler2D _Normal;
 			sampler2D _Mask;


			/*ase_funcs*/       

        
            uint2 ComputeFadeMaskSeed(uint2 positionSS)
            {
                uint2 fadeMaskSeed;
                fadeMaskSeed = positionSS;
                return fadeMaskSeed;
            }
        
            void GetSurfaceData(PackedVaryings input, SurfaceDescription surfaceDescription, half3 viewDirectioWS, uint2 positionSS, float angleFadeFactor, out DecalSurfaceData surfaceData)
            {
                #ifdef LOD_FADE_CROSSFADE
                    LODDitheringTransition(ComputeFadeMaskSeed(positionSS), unity_LODFade.x);
                #endif
        
                half fadeFactor = half(1.0);
        
                ZERO_INITIALIZE(DecalSurfaceData, surfaceData);
                surfaceData.occlusion = half(1.0);
                surfaceData.smoothness = half(0);
        
                #ifdef _MATERIAL_AFFECTS_NORMAL
                    surfaceData.normalWS.w = half(1.0);
                #else
                    surfaceData.normalWS.w = half(0.0);
                #endif
        
                surfaceData.baseColor.xyz = half3(surfaceDescription.BaseColor);
                surfaceData.baseColor.w = half(surfaceDescription.Alpha * fadeFactor);
        
                #if defined(_MATERIAL_AFFECTS_NORMAL)
                    float sgn = input.tangentWS.w;
                    float3 bitangent = sgn * cross(input.normalWS.xyz, input.tangentWS.xyz);
                    half3x3 tangentToWorld = half3x3(input.tangentWS.xyz, bitangent.xyz, input.normalWS.xyz);
        
                    surfaceData.normalWS.xyz = normalize(TransformTangentToWorld(surfaceDescription.NormalTS, tangentToWorld));
                #else
                    surfaceData.normalWS.xyz = half3(input.normalWS);
                #endif
                
        
                surfaceData.normalWS.w = surfaceDescription.NormalAlpha * fadeFactor;
				#if defined( _MATERIAL_AFFECTS_MAOS )
                surfaceData.metallic = half(surfaceDescription.Metallic);
                surfaceData.occlusion = half(surfaceDescription.Occlusion);
                surfaceData.smoothness = half(surfaceDescription.Smoothness);
                surfaceData.MAOSAlpha = half(surfaceDescription.MAOSAlpha * fadeFactor);
				#endif
            }
       
			#define DECAL_MESH
			#define DECAL_DBUFFER
			

			#if ((!defined(_MATERIAL_AFFECTS_NORMAL) && defined(_MATERIAL_AFFECTS_ALBEDO)) || (defined(_MATERIAL_AFFECTS_NORMAL) && defined(_MATERIAL_AFFECTS_NORMAL_BLEND))) && (defined(DECAL_SCREEN_SPACE) || defined(DECAL_GBUFFER))
			#define DECAL_RECONSTRUCT_NORMAL
			#elif defined(DECAL_ANGLE_FADE)
			#define DECAL_LOAD_NORMAL
			#endif

			#if defined(DECAL_LOAD_NORMAL)
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareNormalsTexture.hlsl"
			#endif

			#if defined(DECAL_PROJECTOR) || defined(DECAL_RECONSTRUCT_NORMAL)
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
			#endif

			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/DecalMeshBiasTypeEnum.cs.hlsl"


			#ifdef DECAL_RECONSTRUCT_NORMAL
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/NormalReconstruction.hlsl"
			#endif

			void MeshDecalsPositionZBias(inout PackedVaryings input)
			{
			#if UNITY_REVERSED_Z
				input.positionCS.z -= _DecalMeshDepthBias;
			#else
				input.positionCS.z += _DecalMeshDepthBias;
			#endif
			}

			PackedVaryings Vert(Attributes inputMesh  )
			{
				if (_DecalMeshBiasType == DECALMESHDEPTHBIASTYPE_VIEW_BIAS)
				{
					float3 viewDirectionOS = GetObjectSpaceNormalizeViewDir(inputMesh.positionOS);
					inputMesh.positionOS += viewDirectionOS * (_DecalMeshViewBias);
				}

				PackedVaryings packedOutput;
				ZERO_INITIALIZE(PackedVaryings, packedOutput);

				UNITY_SETUP_INSTANCE_ID(inputMesh);
				UNITY_TRANSFER_INSTANCE_ID(inputMesh, packedOutput);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(packedOutput);

				
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = inputMesh.positionOS.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif
				float3 vertexValue = defaultVertexValue;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					inputMesh.positionOS.xyz = vertexValue;
				#else
					inputMesh.positionOS.xyz += vertexValue;
				#endif

				VertexPositionInputs vertexInput = GetVertexPositionInputs(inputMesh.positionOS.xyz);

				float3 positionWS = TransformObjectToWorld(inputMesh.positionOS);

				float3 normalWS = TransformObjectToWorldNormal(inputMesh.normalOS);
				float4 tangentWS = float4(TransformObjectToWorldDir(inputMesh.tangentOS.xyz), inputMesh.tangentOS.w);
		
				packedOutput.positionWS.xyz =  positionWS;
				packedOutput.normalWS.xyz =  normalWS;
				packedOutput.tangentWS.xyzw =  tangentWS;
				packedOutput.texCoord0.xyzw =  inputMesh.uv0;
				packedOutput.positionCS = TransformWorldToHClip(positionWS);
				if (_DecalMeshBiasType == DECALMESHDEPTHBIASTYPE_DEPTH_BIAS)
				{
					MeshDecalsPositionZBias(packedOutput);
				}

				return packedOutput;
			}

			void Frag(PackedVaryings packedInput,
				OUTPUT_DBUFFER(outDBuffer)
				 
			)
			{
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(packedInput);
				UNITY_SETUP_INSTANCE_ID(packedInput);
				
				half angleFadeFactor = 1.0;
				#if defined(DECAL_RECONSTRUCT_NORMAL)
					#if defined(_DECAL_NORMAL_BLEND_HIGH)
						half3 normalWS = half3(ReconstructNormalTap9(packedInput.positionCS.xy));
					#elif defined(_DECAL_NORMAL_BLEND_MEDIUM)
						half3 normalWS = half3(ReconstructNormalTap5(packedInput.positionCS.xy));
					#else
						half3 normalWS = half3(ReconstructNormalDerivative(packedInput.positionCS.xy));
					#endif
				#elif defined(DECAL_LOAD_NORMAL)
					half3 normalWS = half3(LoadSceneNormals(packedInput.positionCS.xy));
				#endif

				float2 positionSS = packedInput.positionCS.xy * _ScreenSize.zw;
				float3 positionWS = packedInput.positionWS.xyz;
				half3 viewDirectionWS = half3(1.0, 1.0, 1.0); 
				DecalSurfaceData surfaceData;

				SurfaceDescription surfaceDescription;

				float2 texCoord15 = packedInput.texCoord0.xy * float2( 1,1 ) + float2( 0,0 );
				// *** BEGIN Flipbook UV Animation vars ***
				// Total tiles of Flipbook Texture
				float fbtotaltiles17 = _DecalQuantity * _DecalQuantity;
				// Offsets for cols and rows of Flipbook Texture
				float fbcolsoffset17 = 1.0f / _DecalQuantity;
				float fbrowsoffset17 = 1.0f / _DecalQuantity;
				// Speed of animation
				float fbspeed17 = _Time[ 1 ] * 0.0;
				// UV Tiling (col and row offset)
				float2 fbtiling17 = float2(fbcolsoffset17, fbrowsoffset17);
				// UV Offset - calculate current tile linear index, and convert it to (X * coloffset, Y * rowoffset)
				// Calculate current tile linear index
				float fbcurrenttileindex17 = round( fmod( fbspeed17 + _DecalType, fbtotaltiles17) );
				fbcurrenttileindex17 += ( fbcurrenttileindex17 < 0) ? fbtotaltiles17 : 0;
				// Obtain Offset X coordinate from current tile linear index
				float fblinearindextox17 = round ( fmod ( fbcurrenttileindex17, _DecalQuantity ) );
				// Multiply Offset X by coloffset
				float fboffsetx17 = fblinearindextox17 * fbcolsoffset17;
				// Obtain Offset Y coordinate from current tile linear index
				float fblinearindextoy17 = round( fmod( ( fbcurrenttileindex17 - fblinearindextox17 ) / _DecalQuantity, _DecalQuantity ) );
				// Reverse Y to get tiles from Top to Bottom
				fblinearindextoy17 = (int)(_DecalQuantity-1) - fblinearindextoy17;
				// Multiply Offset Y by rowoffset
				float fboffsety17 = fblinearindextoy17 * fbrowsoffset17;
				// UV Offset
				float2 fboffset17 = float2(fboffsetx17, fboffsety17);
				// Flipbook UV
				half2 fbuv17 = texCoord15 * fbtiling17 + fboffset17;
				// *** END Flipbook UV Animation vars ***
				float2 FlipUVs20 = fbuv17;
				float4 tex2DNode9 = tex2D( _BaseColor, FlipUVs20 );
				
				float3 unpack10 = UnpackNormalScale( tex2D( _Normal, FlipUVs20 ), _NormalIntensity );
				unpack10.z = lerp( 1, unpack10.z, saturate(_NormalIntensity) );
				
				float4 tex2DNode11 = tex2D( _Mask, FlipUVs20 );
				
				surfaceDescription.BaseColor = tex2DNode9.rgb;
				surfaceDescription.Alpha = tex2DNode9.a;
				surfaceDescription.NormalTS = unpack10;
				surfaceDescription.NormalAlpha = tex2DNode9.a;
				#if defined( _MATERIAL_AFFECTS_MAOS )
				surfaceDescription.Metallic = tex2DNode11.r;
				surfaceDescription.Occlusion = tex2DNode11.g;
				surfaceDescription.Smoothness = ( tex2DNode11.a * _SmoothnessMultiplier );
				surfaceDescription.MAOSAlpha = tex2DNode9.a;
				#endif
				GetSurfaceData(packedInput,surfaceDescription, viewDirectionWS, (uint2)positionSS, angleFadeFactor, surfaceData);
				ENCODE_INTO_DBUFFER(surfaceData, outDBuffer);
			}

            ENDHLSL
        }

		
        Pass
        { 
            
			Name "DecalScreenSpaceMesh"
            Tags { "LightMode"="DecalScreenSpaceMesh" }
        
            Blend SrcAlpha OneMinusSrcAlpha
			ZTest LEqual
			ZWrite Off
        
            HLSLPROGRAM
        
			#define _MATERIAL_AFFECTS_ALBEDO 1
			#define _MATERIAL_AFFECTS_NORMAL 1
			#define _MATERIAL_AFFECTS_NORMAL_BLEND 1
			#define  _MATERIAL_AFFECTS_MAOS 1
			#define DECAL_ANGLE_FADE 1
			#define ASE_SRP_VERSION 120101

        
			#pragma vertex Vert
			#pragma fragment Frag
			#pragma multi_compile_instancing
			#pragma multi_compile_fog
        
            #pragma multi_compile _ LIGHTMAP_ON
			#pragma multi_compile _ DYNAMICLIGHTMAP_ON
			#pragma multi_compile _ DIRLIGHTMAP_COMBINED
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
			#pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
			#pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
			#pragma multi_compile _ _SHADOWS_SOFT
			#pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
			#pragma multi_compile _ SHADOWS_SHADOWMASK
			#pragma multi_compile _ _CLUSTERED_RENDERING
			#pragma multi_compile _DECAL_NORMAL_BLEND_LOW _DECAL_NORMAL_BLEND_MEDIUM _DECAL_NORMAL_BLEND_HIGH
        
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        
            #define ATTRIBUTES_NEED_NORMAL
            #define ATTRIBUTES_NEED_TANGENT
            #define ATTRIBUTES_NEED_TEXCOORD0
            #define ATTRIBUTES_NEED_TEXCOORD1
            #define ATTRIBUTES_NEED_TEXCOORD2
            #define VARYINGS_NEED_POSITION_WS
            #define VARYINGS_NEED_NORMAL_WS
            #define VARYINGS_NEED_VIEWDIRECTION_WS
            #define VARYINGS_NEED_TANGENT_WS
            #define VARYINGS_NEED_TEXCOORD0
            #define VARYINGS_NEED_FOG_AND_VERTEX_LIGHT
            #define VARYINGS_NEED_SH
            #define VARYINGS_NEED_STATIC_LIGHTMAP_UV
            #define VARYINGS_NEED_DYNAMIC_LIGHTMAP_UV
            
            #define HAVE_MESH_MODIFICATION
        
        
            #define SHADERPASS SHADERPASS_DECAL_SCREEN_SPACE_MESH
        
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DecalInput.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderVariablesDecal.hlsl"
        
			

            struct SurfaceDescription
			{
				float3 BaseColor;
				float Alpha;
				float3 NormalTS;
				float NormalAlpha;
				float Metallic;
				float Occlusion;
				float Smoothness;
				float MAOSAlpha;
				float3 Emission;
			};

            struct Attributes
			{
				float3 positionOS : POSITION;
				float3 normalOS : NORMAL;
				float4 tangentOS : TANGENT;
				float4 uv0 : TEXCOORD0;
				float4 uv1 : TEXCOORD1;
				float4 uv2 : TEXCOORD2;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct PackedVaryings
			{
				float4 positionCS : SV_POSITION;
				float3 positionWS : TEXCOORD0;
				float3 normalWS : TEXCOORD1;
				float4 tangentWS : TEXCOORD2;
				float4 texCoord0 : TEXCOORD3;
				float3 viewDirectionWS : TEXCOORD4;
				float2 staticLightmapUV : TEXCOORD5;
				float2 dynamicLightmapUV : TEXCOORD6;
				float3 sh : TEXCOORD7;
				float4 fogFactorAndVertexLight : TEXCOORD8;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};
        
            CBUFFER_START(UnityPerMaterial)
			float _DecalQuantity;
			float _DecalType;
			float _NormalIntensity;
			float _SmoothnessMultiplier;
			float _DrawOrder;
			float _DecalMeshBiasType;
			float _DecalMeshDepthBias;
			float _DecalMeshViewBias;
			#if defined(DECAL_ANGLE_FADE)
			float _DecalAngleFadeSupported;
			#endif
			CBUFFER_END
			sampler2D _BaseColor;
			sampler2D _Normal;
			sampler2D _Mask;


						
            uint2 ComputeFadeMaskSeed(uint2 positionSS)
            {
                uint2 fadeMaskSeed;
                fadeMaskSeed = positionSS;
                return fadeMaskSeed;
            }
        
            void GetSurfaceData( PackedVaryings input, SurfaceDescription surfaceDescription, half3 viewDirectioWS, uint2 positionSS, float angleFadeFactor, out DecalSurfaceData surfaceData)
            {
                #ifdef LOD_FADE_CROSSFADE
                    LODDitheringTransition(ComputeFadeMaskSeed(positionSS), unity_LODFade.x);
                #endif
        
                half fadeFactor = half(1.0);
        
                ZERO_INITIALIZE(DecalSurfaceData, surfaceData);
                surfaceData.occlusion = half(1.0);
                surfaceData.smoothness = half(0);
        
                #ifdef _MATERIAL_AFFECTS_NORMAL
                    surfaceData.normalWS.w = half(1.0);
                #else
                    surfaceData.normalWS.w = half(0.0);
                #endif
        
				#if defined( _MATERIAL_AFFECTS_EMISSION )
                surfaceData.emissive.rgb = half3(surfaceDescription.Emission.rgb * fadeFactor);
				#endif

                surfaceData.baseColor.xyz = half3(surfaceDescription.BaseColor);
                surfaceData.baseColor.w = half(surfaceDescription.Alpha * fadeFactor);

                #if defined(_MATERIAL_AFFECTS_NORMAL)
                    float sgn = input.tangentWS.w;
                    float3 bitangent = sgn * cross(input.normalWS.xyz, input.tangentWS.xyz);
                    half3x3 tangentToWorld = half3x3(input.tangentWS.xyz, bitangent.xyz, input.normalWS.xyz);
        
                    surfaceData.normalWS.xyz = normalize(TransformTangentToWorld(surfaceDescription.NormalTS, tangentToWorld));
                #else
                    surfaceData.normalWS.xyz = half3(input.normalWS);
                #endif
                
        
                surfaceData.normalWS.w = surfaceDescription.NormalAlpha * fadeFactor;
				#if defined( _MATERIAL_AFFECTS_MAOS )
                surfaceData.metallic = half(surfaceDescription.Metallic);
                surfaceData.occlusion = half(surfaceDescription.Occlusion);
                surfaceData.smoothness = half(surfaceDescription.Smoothness);
                surfaceData.MAOSAlpha = half(surfaceDescription.MAOSAlpha * fadeFactor);
				#endif
            }
        

			#define DECAL_MESH
			#define DECAL_SCREEN_SPACE
			


			#if ((!defined(_MATERIAL_AFFECTS_NORMAL) && defined(_MATERIAL_AFFECTS_ALBEDO)) || (defined(_MATERIAL_AFFECTS_NORMAL) && defined(_MATERIAL_AFFECTS_NORMAL_BLEND))) && (defined(DECAL_SCREEN_SPACE) || defined(DECAL_GBUFFER))
			#define DECAL_RECONSTRUCT_NORMAL
			#elif defined(DECAL_ANGLE_FADE)
			#define DECAL_LOAD_NORMAL
			#endif

			#if defined(DECAL_LOAD_NORMAL)
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareNormalsTexture.hlsl"
			#endif

			#if defined(DECAL_PROJECTOR) || defined(DECAL_RECONSTRUCT_NORMAL)
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
			#endif

			#ifdef DECAL_MESH
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/DecalMeshBiasTypeEnum.cs.hlsl"
			#endif
			#ifdef DECAL_RECONSTRUCT_NORMAL
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/NormalReconstruction.hlsl"
			#endif

			void MeshDecalsPositionZBias(inout PackedVaryings input)
			{
			#if UNITY_REVERSED_Z
			input.positionCS.z -= _DecalMeshDepthBias;
			#else
			input.positionCS.z += _DecalMeshDepthBias;
			#endif
			}

			void InitializeInputData( PackedVaryings input, float3 positionWS, half3 normalWS, half3 viewDirectionWS, out InputData inputData)
			{
				inputData = (InputData)0;

				inputData.positionWS = positionWS;
				inputData.normalWS = normalWS;
				inputData.viewDirectionWS = viewDirectionWS;

				inputData.shadowCoord = float4(0, 0, 0, 0);
			

				#ifdef VARYINGS_NEED_FOG_AND_VERTEX_LIGHT
				inputData.fogCoord = half(input.fogFactorAndVertexLight.x);
				inputData.vertexLighting = half3(input.fogFactorAndVertexLight.yzw);
				#endif

				#if defined(VARYINGS_NEED_DYNAMIC_LIGHTMAP_UV) && defined(DYNAMICLIGHTMAP_ON)
				inputData.bakedGI = SAMPLE_GI(input.staticLightmapUV, input.dynamicLightmapUV.xy, half3(input.sh), normalWS);
				#elif defined(VARYINGS_NEED_STATIC_LIGHTMAP_UV)
				inputData.bakedGI = SAMPLE_GI(input.staticLightmapUV, half3(input.sh), normalWS);
				#endif

				#if defined(VARYINGS_NEED_STATIC_LIGHTMAP_UV)
				inputData.shadowMask = SAMPLE_SHADOWMASK(input.staticLightmapUV);
				#endif

				#if defined(DEBUG_DISPLAY)
				#if defined(VARYINGS_NEED_DYNAMIC_LIGHTMAP_UV) && defined(DYNAMICLIGHTMAP_ON)
				inputData.dynamicLightmapUV = input.dynamicLightmapUV.xy;
				#endif
				#if defined(VARYINGS_NEED_STATIC_LIGHTMAP_UV && LIGHTMAP_ON)
				inputData.staticLightmapUV = input.staticLightmapUV;
				#elif defined(VARYINGS_NEED_SH)
				inputData.vertexSH = input.sh;
				#endif
				#endif

				inputData.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(input.positionCS);
			}

			void GetSurface(DecalSurfaceData decalSurfaceData, inout SurfaceData surfaceData)
			{
				surfaceData.albedo = decalSurfaceData.baseColor.rgb;
				surfaceData.metallic = saturate(decalSurfaceData.metallic);
				surfaceData.specular = 0;
				surfaceData.smoothness = saturate(decalSurfaceData.smoothness);
				surfaceData.occlusion = decalSurfaceData.occlusion;
				surfaceData.emission = decalSurfaceData.emissive;
				surfaceData.alpha = saturate(decalSurfaceData.baseColor.w);
				surfaceData.clearCoatMask = 0;
				surfaceData.clearCoatSmoothness = 1;
			}

			PackedVaryings Vert(Attributes inputMesh  )
			{
				if (_DecalMeshBiasType == DECALMESHDEPTHBIASTYPE_VIEW_BIAS)
				{
					float3 viewDirectionOS = GetObjectSpaceNormalizeViewDir(inputMesh.positionOS);
					inputMesh.positionOS += viewDirectionOS * (_DecalMeshViewBias);
				}
				
				PackedVaryings packedOutput;
				ZERO_INITIALIZE(PackedVaryings, packedOutput);

				UNITY_SETUP_INSTANCE_ID(inputMesh);
				UNITY_TRANSFER_INSTANCE_ID(inputMesh, packedOutput);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(packedOutput);

				
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = inputMesh.positionOS.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif
				float3 vertexValue = defaultVertexValue;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					inputMesh.positionOS.xyz = vertexValue;
				#else
					inputMesh.positionOS.xyz += vertexValue;
				#endif

				VertexPositionInputs vertexInput = GetVertexPositionInputs(inputMesh.positionOS.xyz);
				float3 positionWS = TransformObjectToWorld(inputMesh.positionOS);
				float3 normalWS = TransformObjectToWorldNormal(inputMesh.normalOS);
				float4 tangentWS = float4(TransformObjectToWorldDir(inputMesh.tangentOS.xyz), inputMesh.tangentOS.w);

				packedOutput.positionCS = TransformWorldToHClip(positionWS);
				half fogFactor = 0;
			#if !defined(_FOG_FRAGMENT)
					fogFactor = ComputeFogFactor(packedOutput.positionCS.z);
			#endif

				half3 vertexLight = VertexLighting(positionWS, normalWS);
				packedOutput.fogFactorAndVertexLight = half4(fogFactor, vertexLight);

				if (_DecalMeshBiasType == DECALMESHDEPTHBIASTYPE_DEPTH_BIAS)
				{
					MeshDecalsPositionZBias(packedOutput);
				}


				packedOutput.positionWS.xyz = positionWS;
				packedOutput.normalWS.xyz =  normalWS;
				packedOutput.tangentWS.xyzw =  tangentWS;
				packedOutput.texCoord0.xyzw =  inputMesh.uv0;
				packedOutput.viewDirectionWS.xyz =  GetWorldSpaceViewDir(positionWS);

				#if defined(LIGHTMAP_ON)
				OUTPUT_LIGHTMAP_UV(inputMesh.uv1, unity_LightmapST, packedOutput.staticLightmapUV);
				#endif

				#if defined(DYNAMICLIGHTMAP_ON)
				packedOutput.dynamicLightmapUV.xy = inputMesh.uv2.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
				#endif

				#if !defined(LIGHTMAP_ON)
				packedOutput.sh = float3(SampleSHVertex(half3(normalWS)));
				#endif
				
				return packedOutput;
			}

			void Frag(PackedVaryings packedInput,
						out half4 outColor : SV_Target0
						 
					)
			{
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(packedInput);
				UNITY_SETUP_INSTANCE_ID(packedInput);
			
				half angleFadeFactor = 1.0;

				#if defined(DECAL_RECONSTRUCT_NORMAL)
				#if defined(_DECAL_NORMAL_BLEND_HIGH)
					half3 normalWS = half3(ReconstructNormalTap9(packedInput.positionCS.xy));
				#elif defined(_DECAL_NORMAL_BLEND_MEDIUM)
					half3 normalWS = half3(ReconstructNormalTap5(packedInput.positionCS.xy));
				#else
					half3 normalWS = half3(ReconstructNormalDerivative(packedInput.positionCS.xy));
				#endif
				#elif defined(DECAL_LOAD_NORMAL)
				half3 normalWS = half3(LoadSceneNormals(packedInput.positionCS.xy));
				#endif

				float2 positionSS = packedInput.positionCS.xy * _ScreenSize.zw;
				float3 positionWS = packedInput.positionWS.xyz;
				half3 viewDirectionWS = half3(packedInput.viewDirectionWS);

				DecalSurfaceData surfaceData;

				SurfaceDescription surfaceDescription = (SurfaceDescription)0;

				float2 texCoord15 = packedInput.texCoord0.xy * float2( 1,1 ) + float2( 0,0 );
				// *** BEGIN Flipbook UV Animation vars ***
				// Total tiles of Flipbook Texture
				float fbtotaltiles17 = _DecalQuantity * _DecalQuantity;
				// Offsets for cols and rows of Flipbook Texture
				float fbcolsoffset17 = 1.0f / _DecalQuantity;
				float fbrowsoffset17 = 1.0f / _DecalQuantity;
				// Speed of animation
				float fbspeed17 = _Time[ 1 ] * 0.0;
				// UV Tiling (col and row offset)
				float2 fbtiling17 = float2(fbcolsoffset17, fbrowsoffset17);
				// UV Offset - calculate current tile linear index, and convert it to (X * coloffset, Y * rowoffset)
				// Calculate current tile linear index
				float fbcurrenttileindex17 = round( fmod( fbspeed17 + _DecalType, fbtotaltiles17) );
				fbcurrenttileindex17 += ( fbcurrenttileindex17 < 0) ? fbtotaltiles17 : 0;
				// Obtain Offset X coordinate from current tile linear index
				float fblinearindextox17 = round ( fmod ( fbcurrenttileindex17, _DecalQuantity ) );
				// Multiply Offset X by coloffset
				float fboffsetx17 = fblinearindextox17 * fbcolsoffset17;
				// Obtain Offset Y coordinate from current tile linear index
				float fblinearindextoy17 = round( fmod( ( fbcurrenttileindex17 - fblinearindextox17 ) / _DecalQuantity, _DecalQuantity ) );
				// Reverse Y to get tiles from Top to Bottom
				fblinearindextoy17 = (int)(_DecalQuantity-1) - fblinearindextoy17;
				// Multiply Offset Y by rowoffset
				float fboffsety17 = fblinearindextoy17 * fbrowsoffset17;
				// UV Offset
				float2 fboffset17 = float2(fboffsetx17, fboffsety17);
				// Flipbook UV
				half2 fbuv17 = texCoord15 * fbtiling17 + fboffset17;
				// *** END Flipbook UV Animation vars ***
				float2 FlipUVs20 = fbuv17;
				float4 tex2DNode9 = tex2D( _BaseColor, FlipUVs20 );
				
				float3 unpack10 = UnpackNormalScale( tex2D( _Normal, FlipUVs20 ), _NormalIntensity );
				unpack10.z = lerp( 1, unpack10.z, saturate(_NormalIntensity) );
				
				float4 tex2DNode11 = tex2D( _Mask, FlipUVs20 );
				
				surfaceDescription.BaseColor = tex2DNode9.rgb;
				surfaceDescription.Alpha = tex2DNode9.a;
				surfaceDescription.NormalTS = unpack10;
				surfaceDescription.NormalAlpha = tex2DNode9.a;
				#if defined( _MATERIAL_AFFECTS_MAOS )
				surfaceDescription.Metallic = tex2DNode11.r;
				surfaceDescription.Occlusion = tex2DNode11.g;
				surfaceDescription.Smoothness = ( tex2DNode11.a * _SmoothnessMultiplier );
				surfaceDescription.MAOSAlpha = tex2DNode9.a;
				#endif

				#if defined( _MATERIAL_AFFECTS_EMISSION )
				surfaceDescription.Emission = float3(0, 0, 0);
				#endif

				GetSurfaceData(packedInput,surfaceDescription, viewDirectionWS, (uint2)positionSS, angleFadeFactor, surfaceData);

				#ifdef DECAL_RECONSTRUCT_NORMAL
				surfaceData.normalWS.xyz = normalize(lerp(normalWS.xyz, surfaceData.normalWS.xyz, surfaceData.normalWS.w));
				#endif

				InputData inputData;
				InitializeInputData(packedInput, positionWS, surfaceData.normalWS.xyz, viewDirectionWS, inputData);

				SurfaceData surface = (SurfaceData)0;
				GetSurface(surfaceData, surface);

				half4 color = UniversalFragmentPBR(inputData, surface);
				color.rgb = MixFog(color.rgb, inputData.fogCoord);
				outColor = color;
			}

        
            ENDHLSL
        }

		
        Pass
        { 
            
			Name "DecalGBufferMesh"
            Tags { "LightMode"="DecalGBufferMesh" }
        
            Blend 0 SrcAlpha OneMinusSrcAlpha
			Blend 1 SrcAlpha OneMinusSrcAlpha
			Blend 2 SrcAlpha OneMinusSrcAlpha
			Blend 3 SrcAlpha OneMinusSrcAlpha
			ZWrite Off
			ColorMask RGB
			ColorMask 0 1
			ColorMask RGB 2
			ColorMask RGB 3
        
        
            HLSLPROGRAM
        
			#define _MATERIAL_AFFECTS_ALBEDO 1
			#define _MATERIAL_AFFECTS_NORMAL 1
			#define _MATERIAL_AFFECTS_NORMAL_BLEND 1
			#define  _MATERIAL_AFFECTS_MAOS 1
			#define DECAL_ANGLE_FADE 1
			#define ASE_SRP_VERSION 120101

        
			#pragma vertex Vert
			#pragma fragment Frag
			#pragma multi_compile_instancing
			#pragma multi_compile_fog
        
            #pragma multi_compile _ LIGHTMAP_ON
			#pragma multi_compile _ DYNAMICLIGHTMAP_ON
			#pragma multi_compile _ DIRLIGHTMAP_COMBINED
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
			#pragma multi_compile _ _SHADOWS_SOFT
			#pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
			#pragma multi_compile _ _MIXED_LIGHTING_SUBTRACTIVE
			#pragma multi_compile _DECAL_NORMAL_BLEND_LOW _DECAL_NORMAL_BLEND_MEDIUM _DECAL_NORMAL_BLEND_HIGH
			#pragma multi_compile _ _GBUFFER_NORMALS_OCT
        
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        
            #define ATTRIBUTES_NEED_NORMAL
            #define ATTRIBUTES_NEED_TANGENT
            #define ATTRIBUTES_NEED_TEXCOORD0
            #define ATTRIBUTES_NEED_TEXCOORD1
            #define ATTRIBUTES_NEED_TEXCOORD2
            #define VARYINGS_NEED_POSITION_WS
            #define VARYINGS_NEED_NORMAL_WS
            #define VARYINGS_NEED_VIEWDIRECTION_WS
            #define VARYINGS_NEED_TANGENT_WS
            #define VARYINGS_NEED_TEXCOORD0
            #define VARYINGS_NEED_FOG_AND_VERTEX_LIGHT
            #define VARYINGS_NEED_SH
            #define VARYINGS_NEED_STATIC_LIGHTMAP_UV
            #define VARYINGS_NEED_DYNAMIC_LIGHTMAP_UV
            
            #define HAVE_MESH_MODIFICATION
        
            #define SHADERPASS SHADERPASS_DECAL_GBUFFER_MESH
        
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/UnityGBuffer.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DecalInput.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderVariablesDecal.hlsl"
        
			
            
			struct SurfaceDescription
			{
				float3 BaseColor;
				float Alpha;
				float3 NormalTS;
				float NormalAlpha;
				float Metallic;
				float Occlusion;
				float Smoothness;
				float MAOSAlpha;
				float3 Emission;
			};

            struct Attributes
			{
				float3 positionOS : POSITION;
				float3 normalOS : NORMAL;
				float4 tangentOS : TANGENT;
				float4 uv0 : TEXCOORD0;
				float4 uv1 : TEXCOORD1;
				float4 uv2 : TEXCOORD2;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct PackedVaryings
			{
				float4 positionCS : SV_POSITION;
				float3 positionWS : TEXCOORD0;
				float3 normalWS : TEXCOORD1;
				float4 tangentWS : TEXCOORD2;
				float4 texCoord0 : TEXCOORD3;
				float3 viewDirectionWS : TEXCOORD4;
				float2 staticLightmapUV : TEXCOORD5;
				float2 dynamicLightmapUV : TEXCOORD6;
				float3 sh : TEXCOORD7;
				float4 fogFactorAndVertexLight : TEXCOORD8;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};
        
            CBUFFER_START(UnityPerMaterial)
			float _DecalQuantity;
			float _DecalType;
			float _NormalIntensity;
			float _SmoothnessMultiplier;
			float _DrawOrder;
			float _DecalMeshBiasType;
			float _DecalMeshDepthBias;
			float _DecalMeshViewBias;
			#if defined(DECAL_ANGLE_FADE)
			float _DecalAngleFadeSupported;
			#endif
			CBUFFER_END
			sampler2D _BaseColor;
			sampler2D _Normal;
			sampler2D _Mask;


						
            uint2 ComputeFadeMaskSeed(uint2 positionSS)
            {
                uint2 fadeMaskSeed;
                fadeMaskSeed = positionSS;
                return fadeMaskSeed;
            }
        
            void GetSurfaceData(PackedVaryings input, SurfaceDescription surfaceDescription, half3 viewDirectioWS, uint2 positionSS, float angleFadeFactor, out DecalSurfaceData surfaceData)
            {
                
				#ifdef LOD_FADE_CROSSFADE
                    LODDitheringTransition(ComputeFadeMaskSeed(positionSS), unity_LODFade.x);
                #endif
        
                half fadeFactor = half(1.0);
        
                ZERO_INITIALIZE(DecalSurfaceData, surfaceData);
                surfaceData.occlusion = half(1.0);
                surfaceData.smoothness = half(0);
        
                #ifdef _MATERIAL_AFFECTS_NORMAL
                    surfaceData.normalWS.w = half(1.0);
                #else
                    surfaceData.normalWS.w = half(0.0);
                #endif
        
				#if defined( _MATERIAL_AFFECTS_EMISSION )
                surfaceData.emissive.rgb = half3(surfaceDescription.Emission.rgb * fadeFactor);
				#endif


                surfaceData.baseColor.xyz = half3(surfaceDescription.BaseColor);
                surfaceData.baseColor.w = half(surfaceDescription.Alpha * fadeFactor);
        
                #if defined(_MATERIAL_AFFECTS_NORMAL)
                    float sgn = input.tangentWS.w;
                    float3 bitangent = sgn * cross(input.normalWS.xyz, input.tangentWS.xyz);
                    half3x3 tangentToWorld = half3x3(input.tangentWS.xyz, bitangent.xyz, input.normalWS.xyz);
        
                    surfaceData.normalWS.xyz = normalize(TransformTangentToWorld(surfaceDescription.NormalTS, tangentToWorld));
                #else
                    surfaceData.normalWS.xyz = half3(input.normalWS);
                #endif
                
        
                surfaceData.normalWS.w = surfaceDescription.NormalAlpha * fadeFactor;
				#if defined( _MATERIAL_AFFECTS_MAOS )
                surfaceData.metallic = half(surfaceDescription.Metallic);
                surfaceData.occlusion = half(surfaceDescription.Occlusion);
                surfaceData.smoothness = half(surfaceDescription.Smoothness);
                surfaceData.MAOSAlpha = half(surfaceDescription.MAOSAlpha * fadeFactor);
				#endif
            }

			#define DECAL_MESH
			#define DECAL_GBUFFER
			
			#if ((!defined(_MATERIAL_AFFECTS_NORMAL) && defined(_MATERIAL_AFFECTS_ALBEDO)) || (defined(_MATERIAL_AFFECTS_NORMAL) && defined(_MATERIAL_AFFECTS_NORMAL_BLEND))) && (defined(DECAL_SCREEN_SPACE) || defined(DECAL_GBUFFER))
			#define DECAL_RECONSTRUCT_NORMAL
			#elif defined(DECAL_ANGLE_FADE)
			#define DECAL_LOAD_NORMAL
			#endif

			#if defined(DECAL_LOAD_NORMAL)
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareNormalsTexture.hlsl"
			#endif

			#if defined(DECAL_PROJECTOR) || defined(DECAL_RECONSTRUCT_NORMAL)
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
			#endif

			#ifdef DECAL_MESH
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/DecalMeshBiasTypeEnum.cs.hlsl"
			#endif
			#ifdef DECAL_RECONSTRUCT_NORMAL
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/NormalReconstruction.hlsl"
			#endif

			void MeshDecalsPositionZBias(inout PackedVaryings input)
			{
			#if UNITY_REVERSED_Z
				input.positionCS.z -= _DecalMeshDepthBias;
			#else
				input.positionCS.z += _DecalMeshDepthBias;
			#endif
			}

			void InitializeInputData(PackedVaryings input, float3 positionWS, half3 normalWS, half3 viewDirectionWS, out InputData inputData)
			{
				inputData = (InputData)0;

				inputData.positionWS = positionWS;
				inputData.normalWS = normalWS;
				inputData.viewDirectionWS = viewDirectionWS;


				inputData.shadowCoord = float4(0, 0, 0, 0);

				inputData.fogCoord = half(input.fogFactorAndVertexLight.x);
				inputData.vertexLighting = half3(input.fogFactorAndVertexLight.yzw);


			#if defined(VARYINGS_NEED_DYNAMIC_LIGHTMAP_UV) && defined(DYNAMICLIGHTMAP_ON)
				inputData.bakedGI = SAMPLE_GI(input.staticLightmapUV, input.dynamicLightmapUV.xy, half3(input.sh), normalWS);
			#elif defined(VARYINGS_NEED_STATIC_LIGHTMAP_UV)
				inputData.bakedGI = SAMPLE_GI(input.staticLightmapUV, half3(input.sh), normalWS);
			#endif

			#if defined(VARYINGS_NEED_STATIC_LIGHTMAP_UV)
				inputData.shadowMask = SAMPLE_SHADOWMASK(input.staticLightmapUV);
			#endif

				#if defined(DEBUG_DISPLAY)
				#if defined(VARYINGS_NEED_DYNAMIC_LIGHTMAP_UV) && defined(DYNAMICLIGHTMAP_ON)
				inputData.dynamicLightmapUV = input.dynamicLightmapUV.xy;
				#endif
				#if defined(VARYINGS_NEED_STATIC_LIGHTMAP_UV && LIGHTMAP_ON)
				inputData.staticLightmapUV = input.staticLightmapUV;
				#elif defined(VARYINGS_NEED_SH)
				inputData.vertexSH = input.sh;
				#endif
				#endif

				inputData.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(input.positionCS);
			}

			void GetSurface(DecalSurfaceData decalSurfaceData, inout SurfaceData surfaceData)
			{
				surfaceData.albedo = decalSurfaceData.baseColor.rgb;
				surfaceData.metallic = saturate(decalSurfaceData.metallic);
				surfaceData.specular = 0;
				surfaceData.smoothness = saturate(decalSurfaceData.smoothness);
				surfaceData.occlusion = decalSurfaceData.occlusion;
				surfaceData.emission = decalSurfaceData.emissive;
				surfaceData.alpha = saturate(decalSurfaceData.baseColor.w);
				surfaceData.clearCoatMask = 0;
				surfaceData.clearCoatSmoothness = 1;
			}

			PackedVaryings Vert(Attributes inputMesh  )
			{
				if (_DecalMeshBiasType == DECALMESHDEPTHBIASTYPE_VIEW_BIAS)
				{
					float3 viewDirectionOS = GetObjectSpaceNormalizeViewDir(inputMesh.positionOS);
					inputMesh.positionOS += viewDirectionOS * (_DecalMeshViewBias);
				}

				PackedVaryings packedOutput;
				ZERO_INITIALIZE(PackedVaryings, packedOutput);

				UNITY_SETUP_INSTANCE_ID(inputMesh);
				UNITY_TRANSFER_INSTANCE_ID(inputMesh, packedOutput);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(packedOutput);

				
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = inputMesh.positionOS.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif
				float3 vertexValue = defaultVertexValue;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					inputMesh.positionOS.xyz = vertexValue;
				#else
					inputMesh.positionOS.xyz += vertexValue;
				#endif

				VertexPositionInputs vertexInput = GetVertexPositionInputs(inputMesh.positionOS.xyz);

				float3 positionWS = TransformObjectToWorld(inputMesh.positionOS);
				float3 normalWS = TransformObjectToWorldNormal(inputMesh.normalOS);
				float4 tangentWS = float4(TransformObjectToWorldDir(inputMesh.tangentOS.xyz), inputMesh.tangentOS.w);

				packedOutput.positionCS = TransformWorldToHClip(positionWS);
				if (_DecalMeshBiasType == DECALMESHDEPTHBIASTYPE_DEPTH_BIAS)
				{
					MeshDecalsPositionZBias(packedOutput);
				}

				packedOutput.positionWS.xyz =  positionWS;
				packedOutput.normalWS.xyz =  normalWS;
				packedOutput.tangentWS.xyzw =  tangentWS;
				packedOutput.texCoord0.xyzw =  inputMesh.uv0;
				packedOutput.viewDirectionWS.xyz =  GetWorldSpaceViewDir(positionWS);
			#if defined(LIGHTMAP_ON)
				OUTPUT_LIGHTMAP_UV(inputMesh.uv1, unity_LightmapST, packedOutput.staticLightmapUV);
			#endif
			#if defined(DYNAMICLIGHTMAP_ON)
				packedOutput.dynamicLightmapUV.xy = inputMesh.uv2.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
			#endif
			#if !defined(LIGHTMAP_ON)
				packedOutput.sh.xyz =  float3(SampleSHVertex(half3(normalWS)));
			#endif

				half fogFactor = 0;
			#if !defined(_FOG_FRAGMENT)
					fogFactor = ComputeFogFactor(packedOutput.positionCS.z);
			#endif
				half3 vertexLight = VertexLighting(positionWS, normalWS);
				packedOutput.fogFactorAndVertexLight = half4(fogFactor, vertexLight);
				return packedOutput;
			}

			void Frag(PackedVaryings packedInput,
				out FragmentOutput fragmentOutput
				 
			)
			{
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(packedInput);
				UNITY_SETUP_INSTANCE_ID(packedInput);
				
				half angleFadeFactor = 1.0;


			#if defined(DECAL_RECONSTRUCT_NORMAL)
				#if defined(_DECAL_NORMAL_BLEND_HIGH)
					half3 normalWS = half3(ReconstructNormalTap9(packedInput.positionCS.xy));
				#elif defined(_DECAL_NORMAL_BLEND_MEDIUM)
					half3 normalWS = half3(ReconstructNormalTap5(packedInput.positionCS.xy));
				#else
					half3 normalWS = half3(ReconstructNormalDerivative(packedInput.positionCS.xy));
				#endif
			#elif defined(DECAL_LOAD_NORMAL)
				half3 normalWS = half3(LoadSceneNormals(packedInput.positionCS.xy));
			#endif

				float2 positionSS = packedInput.positionCS.xy * _ScreenSize.zw;
				float3 positionWS = packedInput.positionWS.xyz;
			
				half3 viewDirectionWS = half3(packedInput.viewDirectionWS);

				DecalSurfaceData surfaceData;
				
				SurfaceDescription surfaceDescription = (SurfaceDescription)0;

				float2 texCoord15 = packedInput.texCoord0.xy * float2( 1,1 ) + float2( 0,0 );
				// *** BEGIN Flipbook UV Animation vars ***
				// Total tiles of Flipbook Texture
				float fbtotaltiles17 = _DecalQuantity * _DecalQuantity;
				// Offsets for cols and rows of Flipbook Texture
				float fbcolsoffset17 = 1.0f / _DecalQuantity;
				float fbrowsoffset17 = 1.0f / _DecalQuantity;
				// Speed of animation
				float fbspeed17 = _Time[ 1 ] * 0.0;
				// UV Tiling (col and row offset)
				float2 fbtiling17 = float2(fbcolsoffset17, fbrowsoffset17);
				// UV Offset - calculate current tile linear index, and convert it to (X * coloffset, Y * rowoffset)
				// Calculate current tile linear index
				float fbcurrenttileindex17 = round( fmod( fbspeed17 + _DecalType, fbtotaltiles17) );
				fbcurrenttileindex17 += ( fbcurrenttileindex17 < 0) ? fbtotaltiles17 : 0;
				// Obtain Offset X coordinate from current tile linear index
				float fblinearindextox17 = round ( fmod ( fbcurrenttileindex17, _DecalQuantity ) );
				// Multiply Offset X by coloffset
				float fboffsetx17 = fblinearindextox17 * fbcolsoffset17;
				// Obtain Offset Y coordinate from current tile linear index
				float fblinearindextoy17 = round( fmod( ( fbcurrenttileindex17 - fblinearindextox17 ) / _DecalQuantity, _DecalQuantity ) );
				// Reverse Y to get tiles from Top to Bottom
				fblinearindextoy17 = (int)(_DecalQuantity-1) - fblinearindextoy17;
				// Multiply Offset Y by rowoffset
				float fboffsety17 = fblinearindextoy17 * fbrowsoffset17;
				// UV Offset
				float2 fboffset17 = float2(fboffsetx17, fboffsety17);
				// Flipbook UV
				half2 fbuv17 = texCoord15 * fbtiling17 + fboffset17;
				// *** END Flipbook UV Animation vars ***
				float2 FlipUVs20 = fbuv17;
				float4 tex2DNode9 = tex2D( _BaseColor, FlipUVs20 );
				
				float3 unpack10 = UnpackNormalScale( tex2D( _Normal, FlipUVs20 ), _NormalIntensity );
				unpack10.z = lerp( 1, unpack10.z, saturate(_NormalIntensity) );
				
				float4 tex2DNode11 = tex2D( _Mask, FlipUVs20 );
				
				surfaceDescription.BaseColor = tex2DNode9.rgb;
				surfaceDescription.Alpha = tex2DNode9.a;
				surfaceDescription.NormalTS = unpack10;
				surfaceDescription.NormalAlpha = tex2DNode9.a;
				#if defined( _MATERIAL_AFFECTS_MAOS )
				surfaceDescription.Metallic = tex2DNode11.r;
				surfaceDescription.Occlusion = tex2DNode11.g;
				surfaceDescription.Smoothness = ( tex2DNode11.a * _SmoothnessMultiplier );
				surfaceDescription.MAOSAlpha = 1;
				#endif
				
				#if defined( _MATERIAL_AFFECTS_EMISSION )
				surfaceDescription.Emission = float3(0, 0, 0);
				#endif

				GetSurfaceData(packedInput, surfaceDescription, viewDirectionWS, (uint2)positionSS, angleFadeFactor, surfaceData);

				InputData inputData;
				InitializeInputData(packedInput, positionWS, surfaceData.normalWS.xyz, viewDirectionWS, inputData);

				SurfaceData surface = (SurfaceData)0;
				GetSurface(surfaceData, surface);

				BRDFData brdfData;
				InitializeBRDFData(surface.albedo, surface.metallic, 0, surface.smoothness, surface.alpha, brdfData);

				
			#ifdef _MATERIAL_AFFECTS_ALBEDO

			#ifdef DECAL_RECONSTRUCT_NORMAL
				half3 normalGI = normalize(lerp(normalWS.xyz, surfaceData.normalWS.xyz, surfaceData.normalWS.w));
			#endif

				Light mainLight = GetMainLight(inputData.shadowCoord, inputData.positionWS, inputData.shadowMask);
				MixRealtimeAndBakedGI(mainLight, normalGI, inputData.bakedGI, inputData.shadowMask);
				half3 color = GlobalIllumination(brdfData, inputData.bakedGI, surface.occlusion, normalGI, inputData.viewDirectionWS);
			#else
				half3 color = 0;
			#endif

				half3 packedNormalWS = PackNormal(surfaceData.normalWS.xyz);
				fragmentOutput.GBuffer0 = half4(surfaceData.baseColor.rgb, surfaceData.baseColor.a);
				fragmentOutput.GBuffer1 = 0;
				fragmentOutput.GBuffer2 = half4(packedNormalWS, surfaceData.normalWS.a);
				fragmentOutput.GBuffer3 = half4(surfaceData.emissive + color, surfaceData.baseColor.a);
			#if OUTPUT_SHADOWMASK
				fragmentOutput.GBuffer4 = inputData.shadowMask;
			#endif
			
			}

            ENDHLSL
        }

		
        Pass
        { 
            
			Name "ScenePickingPass"
            Tags { "LightMode"="Picking" }
        
            Cull Back
            HLSLPROGRAM
        
			#define _MATERIAL_AFFECTS_ALBEDO 1
			#define _MATERIAL_AFFECTS_NORMAL 1
			#define _MATERIAL_AFFECTS_NORMAL_BLEND 1
			#define  _MATERIAL_AFFECTS_MAOS 1
			#define DECAL_ANGLE_FADE 1
			#define ASE_SRP_VERSION 120101

        
			#pragma vertex Vert
			#pragma fragment Frag
			#pragma multi_compile_instancing
        
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        
            
            #define HAVE_MESH_MODIFICATION
        
            #define SHADERPASS SHADERPASS_DEPTHONLY
			#define SCENEPICKINGPASS 1
        
            float4 _SelectionID;
            
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DecalInput.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderVariablesDecal.hlsl"
        
			

			struct Attributes
			{
				float3 positionOS : POSITION;
				float4 ase_texcoord : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct PackedVaryings
			{
				float4 positionCS : SV_POSITION;
				float4 ase_texcoord : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};
        
            CBUFFER_START(UnityPerMaterial)
			float _DecalQuantity;
			float _DecalType;
			float _NormalIntensity;
			float _SmoothnessMultiplier;
			float _DrawOrder;
			float _DecalMeshBiasType;
			float _DecalMeshDepthBias;
			float _DecalMeshViewBias;
			#if defined(DECAL_ANGLE_FADE)
			float _DecalAngleFadeSupported;
			#endif
			CBUFFER_END
        
			sampler2D _BaseColor;


			
			#if ((!defined(_MATERIAL_AFFECTS_NORMAL) && defined(_MATERIAL_AFFECTS_ALBEDO)) || (defined(_MATERIAL_AFFECTS_NORMAL) && defined(_MATERIAL_AFFECTS_NORMAL_BLEND))) && (defined(DECAL_SCREEN_SPACE) || defined(DECAL_GBUFFER))
			#define DECAL_RECONSTRUCT_NORMAL
			#elif defined(DECAL_ANGLE_FADE)
			#define DECAL_LOAD_NORMAL
			#endif

			#if defined(DECAL_LOAD_NORMAL)
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareNormalsTexture.hlsl"
			#endif

			#if defined(DECAL_PROJECTOR) || defined(DECAL_RECONSTRUCT_NORMAL)
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
			#endif

			#ifdef DECAL_MESH
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/DecalMeshBiasTypeEnum.cs.hlsl"
			#endif
			#ifdef DECAL_RECONSTRUCT_NORMAL
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/NormalReconstruction.hlsl"
			#endif

			PackedVaryings Vert(Attributes inputMesh  )
			{
				PackedVaryings packedOutput;
				ZERO_INITIALIZE(PackedVaryings, packedOutput);
				
				UNITY_SETUP_INSTANCE_ID(inputMesh);
				UNITY_TRANSFER_INSTANCE_ID(inputMesh, packedOutput);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(packedOutput);

				packedOutput.ase_texcoord.xy = inputMesh.ase_texcoord.xy;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				packedOutput.ase_texcoord.zw = 0;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = inputMesh.positionOS.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif
				float3 vertexValue = defaultVertexValue;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					inputMesh.positionOS.xyz = vertexValue;
				#else
					inputMesh.positionOS.xyz += vertexValue;
				#endif

				float3 positionWS = TransformObjectToWorld(inputMesh.positionOS);				
				packedOutput.positionCS = TransformWorldToHClip(positionWS);
				return packedOutput;
			}

			void Frag(PackedVaryings packedInput,
				out float4 outColor : SV_Target0
				 
			)
			{
				float2 texCoord15 = packedInput.ase_texcoord.xy * float2( 1,1 ) + float2( 0,0 );
				// *** BEGIN Flipbook UV Animation vars ***
				// Total tiles of Flipbook Texture
				float fbtotaltiles17 = _DecalQuantity * _DecalQuantity;
				// Offsets for cols and rows of Flipbook Texture
				float fbcolsoffset17 = 1.0f / _DecalQuantity;
				float fbrowsoffset17 = 1.0f / _DecalQuantity;
				// Speed of animation
				float fbspeed17 = _Time[ 1 ] * 0.0;
				// UV Tiling (col and row offset)
				float2 fbtiling17 = float2(fbcolsoffset17, fbrowsoffset17);
				// UV Offset - calculate current tile linear index, and convert it to (X * coloffset, Y * rowoffset)
				// Calculate current tile linear index
				float fbcurrenttileindex17 = round( fmod( fbspeed17 + _DecalType, fbtotaltiles17) );
				fbcurrenttileindex17 += ( fbcurrenttileindex17 < 0) ? fbtotaltiles17 : 0;
				// Obtain Offset X coordinate from current tile linear index
				float fblinearindextox17 = round ( fmod ( fbcurrenttileindex17, _DecalQuantity ) );
				// Multiply Offset X by coloffset
				float fboffsetx17 = fblinearindextox17 * fbcolsoffset17;
				// Obtain Offset Y coordinate from current tile linear index
				float fblinearindextoy17 = round( fmod( ( fbcurrenttileindex17 - fblinearindextox17 ) / _DecalQuantity, _DecalQuantity ) );
				// Reverse Y to get tiles from Top to Bottom
				fblinearindextoy17 = (int)(_DecalQuantity-1) - fblinearindextoy17;
				// Multiply Offset Y by rowoffset
				float fboffsety17 = fblinearindextoy17 * fbrowsoffset17;
				// UV Offset
				float2 fboffset17 = float2(fboffsetx17, fboffsety17);
				// Flipbook UV
				half2 fbuv17 = texCoord15 * fbtiling17 + fboffset17;
				// *** END Flipbook UV Animation vars ***
				float2 FlipUVs20 = fbuv17;
				float4 tex2DNode9 = tex2D( _BaseColor, FlipUVs20 );
				
				float3 BaseColor = tex2DNode9.rgb;
				outColor = _SelectionID;
			}

            ENDHLSL
        }
    }
    CustomEditor "UnityEditor.Rendering.Universal.DecalShaderGraphGUI"
    FallBack "Hidden/Shader Graph/FallbackError"
	
	
}
/*ASEBEGIN
Version=18926
789;73;678;976;541.717;182.5936;1;True;False
Node;AmplifyShaderEditor.CommentaryNode;24;-1393.936,-96.76087;Inherit;False;817;368;Decal flipbook, put all your decals in a single atlas to simplify their use.;5;15;18;19;17;20;;1,1,1,1;0;0
Node;AmplifyShaderEditor.RangedFloatNode;19;-1360.936,173.2391;Inherit;False;Property;_DecalType;Decal Type;6;1;[IntRange];Create;True;0;0;0;False;0;False;3;0;0;3;0;1;FLOAT;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;15;-1343.936,-46.76087;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;18;-1305.936,81.23914;Inherit;False;Property;_DecalQuantity;Decal Quantity;5;0;Create;True;0;0;0;False;0;False;2;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCFlipBookUVAnimation;17;-1082.936,-11.76087;Inherit;False;0;0;6;0;FLOAT2;0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.RegisterLocalVarNode;20;-800.9363,-4.760866;Inherit;False;FlipUVs;-1;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;21;-557,-69;Inherit;False;20;FlipUVs;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;14;-588,247;Inherit;False;Property;_NormalIntensity;Normal Intensity;4;0;Create;True;0;0;0;False;0;False;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;13;-407,623;Inherit;False;Property;_SmoothnessMultiplier;Smoothness Multiplier;3;0;Create;True;0;0;0;False;0;False;0;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;22;-565,169;Inherit;False;20;FlipUVs;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;23;-548,403;Inherit;False;20;FlipUVs;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;12;-18,563;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;11;-377,364;Inherit;True;Property;_Mask;Mask;1;0;Create;True;0;0;0;False;0;False;-1;7d02b70a11844539aa69f4dfdf8a5771;7d02b70a11844539aa69f4dfdf8a5771;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TextureCoordinatesNode;26;-224.7173,-436.5936;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;10;-373,148;Inherit;True;Property;_Normal;Normal;2;0;Create;True;0;0;0;False;0;False;-1;ba478537f03c452f82cf7e0c4a9587c2;ba478537f03c452f82cf7e0c4a9587c2;True;0;True;bump;Auto;True;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;9;-393,-94;Inherit;True;Property;_BaseColor;Base Color;0;0;Create;True;0;0;0;False;0;False;-1;3f19e5aabc6340ee9098748a5c075c67;3f19e5aabc6340ee9098748a5c075c67;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;0;0,0;Float;False;False;-1;2;UnityEditor.Rendering.Universal.DecalShaderGraphGUI;0;1;New Amplify Shader;c2a467ab6d5391a4ea692226d82ffefd;True;DBufferProjector;0;0;DBufferProjector;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;PreviewType=Plane;ShaderGraphShader=true;True;3;False;0;False;True;2;5;False;-1;10;False;-1;1;0;False;-1;10;False;-1;False;False;True;2;5;False;-1;10;False;-1;1;0;False;-1;10;False;-1;False;False;True;2;5;False;-1;10;False;-1;1;0;False;-1;10;False;-1;False;False;False;False;False;False;True;1;False;-1;False;False;False;True;True;True;True;True;0;False;-1;False;True;True;True;True;True;0;False;-1;False;False;False;False;False;True;2;False;-1;True;2;False;-1;False;True;1;LightMode=DBufferProjector;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;2;176,-85;Float;False;True;-1;2;UnityEditor.Rendering.Universal.DecalShaderGraphGUI;0;14;AmplifyShaderPack/URP/GroundDecals;c2a467ab6d5391a4ea692226d82ffefd;True;DecalScreenSpaceProjector;0;2;DecalScreenSpaceProjector;10;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;PreviewType=Plane;ShaderGraphShader=true;True;3;False;0;False;True;2;5;False;-1;10;False;-1;0;1;False;-1;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;True;1;False;-1;False;False;False;False;False;False;False;False;False;False;False;True;2;False;-1;True;2;False;-1;False;True;1;LightMode=DecalScreenSpaceProjector;False;False;0;;0;0;Standard;8;Affect BaseColor;1;Affect Normal;1;Blend;1;Affect MAOS;1;Affect Emission;0;Support LOD CrossFade;0;Angle Fade;1;Vertex Position,InvertActionOnDeselection;1;0;9;True;False;True;True;True;False;True;True;True;False;;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;1;0,0;Float;False;False;-1;2;UnityEditor.Rendering.Universal.DecalShaderGraphGUI;0;1;New Amplify Shader;c2a467ab6d5391a4ea692226d82ffefd;True;DecalProjectorForwardEmissive;0;1;DecalProjectorForwardEmissive;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;PreviewType=Plane;ShaderGraphShader=true;True;3;False;0;False;True;8;5;False;-1;1;False;-1;0;1;False;-1;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;True;1;False;-1;False;False;False;False;False;False;False;False;False;False;False;True;2;False;-1;True;2;False;-1;False;True;1;LightMode=DecalProjectorForwardEmissive;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;3;0,0;Float;False;False;-1;2;UnityEditor.Rendering.Universal.DecalShaderGraphGUI;0;1;New Amplify Shader;c2a467ab6d5391a4ea692226d82ffefd;True;DecalGBufferProjector;0;3;DecalGBufferProjector;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;PreviewType=Plane;ShaderGraphShader=true;True;3;False;0;False;True;2;5;False;-1;10;False;-1;0;1;False;-1;0;False;-1;False;False;True;2;5;False;-1;10;False;-1;0;1;False;-1;0;False;-1;False;False;True;2;5;False;-1;10;False;-1;0;1;False;-1;0;False;-1;False;False;True;2;5;False;-1;10;False;-1;0;1;False;-1;0;False;-1;False;False;False;True;1;False;-1;False;False;False;True;False;False;False;False;0;False;-1;False;True;True;True;True;False;0;False;-1;False;True;True;True;True;False;0;False;-1;False;False;False;True;2;False;-1;True;2;False;-1;False;True;1;LightMode=DecalGBufferProjector;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;6;0,0;Float;False;False;-1;2;UnityEditor.Rendering.Universal.DecalShaderGraphGUI;0;1;New Amplify Shader;c2a467ab6d5391a4ea692226d82ffefd;True;DecalScreenSpaceMesh;0;6;DecalScreenSpaceMesh;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;PreviewType=Plane;ShaderGraphShader=true;True;3;False;0;False;True;2;5;False;-1;10;False;-1;0;1;False;-1;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;2;False;-1;True;3;False;-1;False;True;1;LightMode=DecalScreenSpaceMesh;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;7;0,0;Float;False;False;-1;2;UnityEditor.Rendering.Universal.DecalShaderGraphGUI;0;1;New Amplify Shader;c2a467ab6d5391a4ea692226d82ffefd;True;DecalGBufferMesh;0;7;DecalGBufferMesh;1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;PreviewType=Plane;ShaderGraphShader=true;True;3;False;0;False;True;2;5;False;-1;10;False;-1;0;1;False;-1;0;False;-1;False;False;True;2;5;False;-1;10;False;-1;0;1;False;-1;0;False;-1;False;False;True;2;5;False;-1;10;False;-1;0;1;False;-1;0;False;-1;False;False;True;2;5;False;-1;10;False;-1;0;1;False;-1;0;False;-1;False;False;False;False;False;False;False;True;False;False;False;False;0;False;-1;False;True;True;True;True;False;0;False;-1;False;True;True;True;True;False;0;False;-1;False;False;False;True;2;False;-1;False;False;True;1;LightMode=DecalGBufferMesh;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;8;0,0;Float;False;False;-1;2;UnityEditor.Rendering.Universal.DecalShaderGraphGUI;0;1;New Amplify Shader;c2a467ab6d5391a4ea692226d82ffefd;True;ScenePickingPass;0;8;ScenePickingPass;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;PreviewType=Plane;ShaderGraphShader=true;True;3;False;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;LightMode=Picking;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;4;0,0;Float;False;False;-1;2;UnityEditor.Rendering.Universal.DecalShaderGraphGUI;0;1;New Amplify Shader;c2a467ab6d5391a4ea692226d82ffefd;True;DBufferMesh;0;4;DBufferMesh;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;PreviewType=Plane;ShaderGraphShader=true;True;3;False;0;False;True;2;5;False;-1;10;False;-1;1;0;False;-1;10;False;-1;False;False;True;2;5;False;-1;10;False;-1;1;0;False;-1;10;False;-1;False;False;True;2;5;False;-1;10;False;-1;1;0;False;-1;10;False;-1;False;False;False;False;False;False;False;False;False;False;True;True;True;True;True;0;False;-1;False;True;True;True;True;True;0;False;-1;False;False;False;False;False;True;2;False;-1;True;3;False;-1;False;True;1;LightMode=DBufferMesh;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;5;0,0;Float;False;False;-1;2;UnityEditor.Rendering.Universal.DecalShaderGraphGUI;0;1;New Amplify Shader;c2a467ab6d5391a4ea692226d82ffefd;True;DecalMeshForwardEmissive;0;5;DecalMeshForwardEmissive;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;PreviewType=Plane;ShaderGraphShader=true;True;3;False;0;False;True;8;5;False;-1;1;False;-1;0;1;False;-1;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;2;False;-1;True;3;False;-1;False;True;1;LightMode=DecalMeshForwardEmissive;False;False;0;;0;0;Standard;0;False;0
WireConnection;17;0;15;0
WireConnection;17;1;18;0
WireConnection;17;2;18;0
WireConnection;17;4;19;0
WireConnection;20;0;17;0
WireConnection;12;0;11;4
WireConnection;12;1;13;0
WireConnection;11;1;23;0
WireConnection;10;1;22;0
WireConnection;10;5;14;0
WireConnection;9;1;21;0
WireConnection;2;0;9;0
WireConnection;2;1;9;4
WireConnection;2;2;10;0
WireConnection;2;3;9;4
WireConnection;2;4;11;1
WireConnection;2;5;11;2
WireConnection;2;6;12;0
WireConnection;2;7;9;4
ASEEND*/
//CHKSM=81F55CCCFA3454BAD609CB0F1051C6BF29D36A40