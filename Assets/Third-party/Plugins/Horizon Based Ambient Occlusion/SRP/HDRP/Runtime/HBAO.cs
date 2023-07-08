using System;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Experimental.Rendering;
using UnityEngine.Rendering;
using UnityEngine.Rendering.HighDefinition;

namespace HorizonBasedAmbientOcclusion.HighDefinition
{
    [ExecuteInEditMode, VolumeComponentMenu("Lighting/HBAO")]
    public class HBAO : CustomPostProcessVolumeComponent, IPostProcessComponent
    {
        public enum Preset
        {
            FastestPerformance,
            FastPerformance,
            Normal,
            HighQuality,
            HighestQuality,
            Custom
        }

        public enum Quality
        {
            Lowest,
            Low,
            Medium,
            High,
            Highest
        }

        public enum Resolution
        {
            Full,
            Half
        }

        public enum NoiseType
        {
            Dither,
            InterleavedGradientNoise,
            SpatialDistribution
        }

        public enum Deinterleaving
        {
            Disabled,
            x4
        }

        public enum DebugMode
        {
            Disabled,
            AOOnly,
            ColorBleedingOnly,
            SplitWithoutAOAndWithAO,
            SplitWithAOAndAOOnly,
            SplitWithoutAOAndAOOnly,
            ViewNormals
        }

        public enum BlurType
        {
            None,
            Narrow,
            Medium,
            Wide,
            ExtraWide
        }

        public enum PerPixelNormals
        {
            GBuffer,
            Reconstruct
        }

        public enum VarianceClipping
        {
            Disabled,
            _4Tap,
            _8Tap
        }

        public Shader shader;

        [Serializable]
        public sealed class PresetParameter : VolumeParameter<Preset>
        {
            public PresetParameter(Preset value, bool overrideState = false)
                : base(value, overrideState) { }
        }

        [Serializable]
        public sealed class QualityParameter : VolumeParameter<Quality>
        {
            public QualityParameter(Quality value, bool overrideState = false)
                : base(value, overrideState) { }
        }

        [Serializable]
        public sealed class DeinterleavingParameter : VolumeParameter<Deinterleaving>
        {
            public DeinterleavingParameter(Deinterleaving value, bool overrideState = false)
                : base(value, overrideState) { }
        }

        [Serializable]
        public sealed class ResolutionParameter : VolumeParameter<Resolution>
        {
            public ResolutionParameter(Resolution value, bool overrideState = false)
                : base(value, overrideState) { }
        }

        [Serializable]
        public sealed class NoiseTypeParameter : VolumeParameter<NoiseType>
        {
            public NoiseTypeParameter(NoiseType value, bool overrideState = false)
                : base(value, overrideState) { }
        }

        [Serializable]
        public sealed class DebugModeParameter : VolumeParameter<DebugMode>
        {
            public DebugModeParameter(DebugMode value, bool overrideState = false)
                : base(value, overrideState) { }
        }

        [Serializable]
        public sealed class PerPixelNormalsParameter : VolumeParameter<PerPixelNormals>
        {
            public PerPixelNormalsParameter(PerPixelNormals value, bool overrideState = false)
                : base(value, overrideState) { }
        }

        [Serializable]
        public sealed class VarianceClippingParameter : VolumeParameter<VarianceClipping>
        {
            public VarianceClippingParameter(VarianceClipping value, bool overrideState = false)
                : base(value, overrideState) { }
        }

        [Serializable]
        public sealed class BlurTypeParameter : VolumeParameter<BlurType>
        {
            public BlurTypeParameter(BlurType value, bool overrideState = false)
                : base(value, overrideState) { }
        }

        [Serializable]
        public sealed class MinMaxFloatParameter : VolumeParameter<Vector2>
        {
            public float min;
            public float max;

            public MinMaxFloatParameter(Vector2 value, float min, float max, bool overrideState = false)
                : base(value, overrideState)
            {
                this.min = min;
                this.max = max;
            }
        }

        [AttributeUsage(AttributeTargets.Field)]
        public class SettingsGroup : Attribute
        {
            public bool isExpanded = true;
        }

        [AttributeUsage(AttributeTargets.Field)]
        public class ParameterDisplayName : Attribute
        {
            public string name;

            public ParameterDisplayName(string name)
            {
                this.name = name;
            }
        }

        public class Presets : SettingsGroup { }
        public class GeneralSettings : SettingsGroup { }
        public class AOSettings : SettingsGroup { }
        public class TemporalFilterSettings : SettingsGroup { }
        public class BlurSettings : SettingsGroup { }
        public class ColorBleedingSettings : SettingsGroup { }

        [Presets]
        public PresetParameter preset = new PresetParameter(Preset.Normal);

        [Tooltip("The quality of the AO.")]
        [GeneralSettings, Space(6)]
        public QualityParameter quality = new QualityParameter(Quality.Medium);
        /*
        [Tooltip("The deinterleaving factor.")]
        [GeneralSettings]
        public DeinterleavingParameter deinterleaving = new DeinterleavingParameter(Deinterleaving.Disabled);
        */
        [Tooltip("The resolution at which the AO is calculated.")]
        [GeneralSettings]
        public ResolutionParameter resolution = new ResolutionParameter(Resolution.Full);
        [Tooltip("The type of noise to use.")]
        [GeneralSettings, Space(10)]
        public NoiseTypeParameter noiseType = new NoiseTypeParameter(NoiseType.Dither);
        [Tooltip("The debug mode actually displayed on screen.")]
        [GeneralSettings, Space(10)]
        public DebugModeParameter debugMode = new DebugModeParameter(DebugMode.Disabled);

        [Tooltip("AO radius: this is the distance outside which occluders are ignored.")]
        [AOSettings, Space(6)]
        public ClampedFloatParameter radius = new ClampedFloatParameter(0.8f, 0.25f, 5f);
        [Tooltip("Maximum radius in pixels: this prevents the radius to grow too much with close-up " +
                  "object and impact on performances.")]
        [AOSettings]
        public ClampedFloatParameter maxRadiusPixels = new ClampedFloatParameter(128f, 16f, 256f);
        [Tooltip("For low-tessellated geometry, occlusion variations tend to appear at creases and " +
                 "ridges, which betray the underlying tessellation. To remove these artifacts, we use " +
                 "an angle bias parameter which restricts the hemisphere.")]
        [AOSettings]
        public ClampedFloatParameter bias = new ClampedFloatParameter(0.05f, 0f, 0.5f);
        [Tooltip("This value allows to scale up the ambient occlusion values.")]
        [AOSettings]
        public ClampedFloatParameter intensity = new ClampedFloatParameter(0f, 0, 4f);
        [Tooltip("Enable/disable MultiBounce approximation.")]
        [AOSettings]
        public BoolParameter useMultiBounce = new BoolParameter(false);
        [Tooltip("MultiBounce approximation influence.")]
        [AOSettings]
        public ClampedFloatParameter multiBounceInfluence = new ClampedFloatParameter(1f, 0f, 1f);
        [Tooltip("The amount of AO offscreen samples are contributing.")]
        [AOSettings]
        public MinMaxFloatParameter multiBounceMaskRange = new MinMaxFloatParameter(new Vector2(0f, 2f), 0f, 2f);
        [AOSettings]
        public ClampedFloatParameter offscreenSamplesContribution = new ClampedFloatParameter(0f, 0f, 1f);
        [Tooltip("The max distance to display AO.")]
        [AOSettings, Space(10)]
        public FloatParameter maxDistance = new FloatParameter(150f);
        [Tooltip("The distance before max distance at which AO start to decrease.")]
        [AOSettings]
        public FloatParameter distanceFalloff = new FloatParameter(50f);
        [Tooltip("The type of per pixel normals to use.")]
        [AOSettings, Space(10)]
        public PerPixelNormalsParameter perPixelNormals = new PerPixelNormalsParameter(PerPixelNormals.GBuffer);
        [Tooltip("This setting allow you to set the base color if the AO, the alpha channel value is unused.")]
        [AOSettings, Space(10)]
        public ColorParameter baseColor = new ColorParameter(Color.black);

        [TemporalFilterSettings, ParameterDisplayName("Enabled"), Space(6)]
        public BoolParameter temporalFilterEnabled = new BoolParameter(false);
        [Tooltip("The type of variance clipping to use.")]
        [TemporalFilterSettings]
        public VarianceClippingParameter varianceClipping = new VarianceClippingParameter(VarianceClipping._4Tap);

        [Tooltip("The type of blur to use.")]
        [BlurSettings, ParameterDisplayName("Type"), Space(6)]
        public BlurTypeParameter blurType = new BlurTypeParameter(BlurType.Medium);

        [Tooltip("This parameter controls the depth-dependent weight of the bilateral filter, to " +
                 "avoid bleeding across edges. A zero sharpness is a pure Gaussian blur. Increasing " +
                 "the blur sharpness removes bleeding by using lower weights for samples with large " +
                 "depth delta from the current pixel.")]
        [BlurSettings, Space(10)]
        public ClampedFloatParameter sharpness = new ClampedFloatParameter(8f, 0f, 16f);

        [ColorBleedingSettings, ParameterDisplayName("Enabled"), Space(6)]
        public BoolParameter colorBleedingEnabled = new BoolParameter(false);
        [Tooltip("This value allows to control the saturation of the color bleeding.")]
        [ColorBleedingSettings, Space(10)]
        public ClampedFloatParameter saturation = new ClampedFloatParameter(1f, 0f, 4f);
        [Tooltip("This value allows to scale the contribution of the color bleeding samples.")]
        [ColorBleedingSettings]
        public ClampedFloatParameter albedoMultiplier = new ClampedFloatParameter(4f, 0f, 32f);
        [Tooltip("Use masking on emissive pixels")]
        [ColorBleedingSettings]
        public ClampedFloatParameter brightnessMask = new ClampedFloatParameter(1f, 0f, 1f);
        [Tooltip("Brightness level where masking starts/ends")]
        [ColorBleedingSettings]
        public MinMaxFloatParameter brightnessMaskRange = new MinMaxFloatParameter(new Vector2(0f, 0.5f), 0f, 2f);

        public void EnableHBAO(bool enable)
        {
            intensity.overrideState = enable;
        }

        public Preset GetCurrentPreset()
        {
            return preset.value;
        }

        public void ApplyPreset(Preset preset)
        {
            if (preset == Preset.Custom)
            {
                this.preset.Override(preset);
                return;
            }

            var actualDebugMode = debugMode.value;
            var actualDebugModeOverride = debugMode.overrideState;
            SetAllOverridesTo(false);
            debugMode.overrideState = actualDebugModeOverride;
            debugMode.value = actualDebugMode;

            switch (preset)
            {
                case Preset.FastestPerformance:
                    SetQuality(Quality.Lowest);
                    SetAoRadius(0.5f);
                    SetAoMaxRadiusPixels(64.0f);
                    SetBlurType(BlurType.ExtraWide);
                    break;
                case Preset.FastPerformance:
                    SetQuality(Quality.Low);
                    SetAoRadius(0.5f);
                    SetAoMaxRadiusPixels(64.0f);
                    SetBlurType(BlurType.Wide);
                    break;
                case Preset.HighQuality:
                    SetQuality(Quality.High);
                    SetAoRadius(1.0f);
                    break;
                case Preset.HighestQuality:
                    SetQuality(Quality.Highest);
                    SetAoRadius(1.2f);
                    SetAoMaxRadiusPixels(256.0f);
                    SetBlurType(BlurType.Narrow);
                    break;
                case Preset.Normal:
                default:
                    break;
            }

            this.preset.Override(preset);
        }

        public Quality GetQuality()
        {
            return quality.value;
        }

        public void SetQuality(Quality quality)
        {
            this.quality.Override(quality);
        }

        /*
        public Deinterleaving GetDeinterleaving()
        {
            return deinterleaving.value;
        }

        public void SetDeinterleaving(Deinterleaving deinterleaving)
        {
            this.deinterleaving.Override(deinterleaving);
        }
        */

        public Resolution GetResolution()
        {
            return resolution.value;
        }

        public void SetResolution(Resolution resolution)
        {
            this.resolution.Override(resolution);
        }

        public NoiseType GetNoiseType()
        {
            return noiseType.value;
        }

        public void SetNoiseType(NoiseType noiseType)
        {
            this.noiseType.Override(noiseType);
        }

        public DebugMode GetDebugMode()
        {
            return debugMode.value;
        }

        public void SetDebugMode(DebugMode debugMode)
        {
            this.debugMode.Override(debugMode);
        }

        public float GetAoRadius()
        {
            return radius.value;
        }

        public void SetAoRadius(float radius)
        {
            this.radius.Override(Mathf.Clamp(radius, this.radius.min, this.radius.max));
        }

        public float GetAoMaxRadiusPixels()
        {
            return maxRadiusPixels.value;
        }

        public void SetAoMaxRadiusPixels(float maxRadiusPixels)
        {
            this.maxRadiusPixels.Override(Mathf.Clamp(maxRadiusPixels, this.maxRadiusPixels.min, this.maxRadiusPixels.max));
        }

        public float GetAoBias()
        {
            return bias.value;
        }

        public void SetAoBias(float bias)
        {
            this.bias.Override(Mathf.Clamp(bias, this.bias.min, this.bias.max));
        }

        public float GetAoOffscreenSamplesContribution()
        {
            return offscreenSamplesContribution.value;
        }

        public void SetAoOffscreenSamplesContribution(float offscreenSamplesContribution)
        {
            this.offscreenSamplesContribution.Override(Mathf.Clamp(offscreenSamplesContribution, this.offscreenSamplesContribution.min, this.offscreenSamplesContribution.max));
        }

        public float GetAoMaxDistance()
        {
            return maxDistance.value;
        }

        public void SetAoMaxDistance(float maxDistance)
        {
            this.maxDistance.Override(maxDistance);
        }

        public float GetAoDistanceFalloff()
        {
            return distanceFalloff.value;
        }

        public void SetAoDistanceFalloff(float distanceFalloff)
        {
            this.distanceFalloff.Override(distanceFalloff);
        }

        public PerPixelNormals GetAoPerPixelNormals()
        {
            return perPixelNormals.value;
        }

        public void SetAoPerPixelNormals(PerPixelNormals perPixelNormals)
        {
            this.perPixelNormals.Override(perPixelNormals);
        }

        public Color GetAoColor()
        {
            return baseColor.value;
        }

        public void SetAoColor(Color baseColor)
        {
            this.baseColor.Override(baseColor);
        }

        public float GetAoIntensity()
        {
            return intensity.value;
        }

        public void SetAoIntensity(float intensity)
        {
            this.intensity.Override(Mathf.Clamp(intensity, this.intensity.min, this.intensity.max));
        }

        public bool UseMultiBounce()
        {
            return useMultiBounce.value;
        }

        public void EnableMultiBounce(bool enabled = true)
        {
            useMultiBounce.Override(enabled);
        }

        public float GetAoMultiBounceInfluence()
        {
            return multiBounceInfluence.value;
        }

        public void SetAoMultiBounceInfluence(float multiBounceInfluence)
        {
            this.multiBounceInfluence.Override(Mathf.Clamp(multiBounceInfluence, this.multiBounceInfluence.min, this.multiBounceInfluence.max));
        }

        public Vector2 GetAoMultiBounceMaskRange()
        {
            return multiBounceMaskRange.value;
        }

        public void SetAoMultiBounceMaskRange(Vector2 multiBounceMaskRange)
        {
            multiBounceMaskRange.x = Mathf.Clamp(multiBounceMaskRange.x, this.brightnessMaskRange.min, this.brightnessMaskRange.max);
            multiBounceMaskRange.y = Mathf.Clamp(multiBounceMaskRange.y, this.brightnessMaskRange.min, this.brightnessMaskRange.max);
            multiBounceMaskRange.x = Mathf.Min(multiBounceMaskRange.x, multiBounceMaskRange.y);
            this.multiBounceMaskRange.Override(multiBounceMaskRange);
        }

        public bool IsTemporalFilterEnabled()
        {
            return temporalFilterEnabled.value;
        }

        public void EnableTemporalFilter(bool enabled = true)
        {
            temporalFilterEnabled.Override(enabled);
        }

        public VarianceClipping GetTemporalFilterVarianceClipping()
        {
            return varianceClipping.value;
        }

        public void SetTemporalFilterVarianceClipping(VarianceClipping varianceClipping)
        {
            this.varianceClipping.Override(varianceClipping);
        }

        public BlurType GetBlurType()
        {
            return blurType.value;
        }

        public void SetBlurType(BlurType blurType)
        {
            this.blurType.Override(blurType);
        }

        public float GetBlurSharpness()
        {
            return sharpness.value;
        }

        public void SetBlurSharpness(float sharpness)
        {
            this.sharpness.Override(Mathf.Clamp(sharpness, this.sharpness.min, this.sharpness.max));
        }

        public bool IsColorBleedingEnabled()
        {
            return colorBleedingEnabled.value;
        }

        public void EnableColorBleeding(bool enabled = true)
        {
            colorBleedingEnabled.Override(enabled);
        }

        public float GetColorBleedingSaturation()
        {
            return saturation.value;
        }

        public void SetColorBleedingSaturation(float saturation)
        {
            this.saturation.Override(Mathf.Clamp(saturation, this.saturation.min, this.saturation.max));
        }

        public float GetColorBleedingAlbedoMultiplier()
        {
            return albedoMultiplier.value;
        }

        public void SetColorBleedingAlbedoMultiplier(float albedoMultiplier)
        {
            this.albedoMultiplier.Override(Mathf.Clamp(albedoMultiplier, this.albedoMultiplier.min, this.albedoMultiplier.max));
        }

        public float GetColorBleedingBrightnessMask()
        {
            return brightnessMask.value;
        }

        public void SetColorBleedingBrightnessMask(float brightnessMask)
        {
            this.brightnessMask.Override(Mathf.Clamp(brightnessMask, this.brightnessMask.min, this.brightnessMask.max));
        }

        public Vector2 GetColorBleedingBrightnessMaskRange()
        {
            return brightnessMaskRange.value;
        }

        public void SetColorBleedingBrightnessMaskRange(Vector2 brightnessMaskRange)
        {
            brightnessMaskRange.x = Mathf.Clamp(brightnessMaskRange.x, this.brightnessMaskRange.min, this.brightnessMaskRange.max);
            brightnessMaskRange.y = Mathf.Clamp(brightnessMaskRange.y, this.brightnessMaskRange.min, this.brightnessMaskRange.max);
            brightnessMaskRange.x = Mathf.Min(brightnessMaskRange.x, brightnessMaskRange.y);
            this.brightnessMaskRange.Override(brightnessMaskRange);
        }

        public bool IsActive() => intensity.overrideState && intensity.value > 0;

        public override CustomPostProcessInjectionPoint injectionPoint => CustomPostProcessInjectionPoint.AfterOpaqueAndSky;

        //public override bool visibleInSceneView => true;

        private static class Pass
        {
            public const int AO = 0;
            public const int AO_Deinterleaved = 1;

            public const int Deinterleave_Depth = 2;
            public const int Deinterleave_Normals = 3;
            public const int Atlas_AO_Deinterleaved = 4;
            public const int Reinterleave_AO = 5;

            public const int Blur = 6;

            public const int Temporal_Filter = 7;

            public const int Copy = 8;

            public const int Composite = 9;

            public const int Debug_ViewNormals = 10;
        }

        private static class ShaderProperties
        {
            public static int mainTex;
            public static int inputTex;
            public static int hbaoTex;
            public static int tempTex;
            public static int tempTex2;
            public static int noiseTex;
            public static int depthTex;
            public static int normalsTex;
            public static int[] depthSliceTex;
            public static int[] normalsSliceTex;
            public static int[] aoSliceTex;
            public static int[] deinterleaveOffset;
            public static int atlasOffset;
            public static int jitter;
            public static int uvTransform;
            public static int inputTexelSize;
            public static int aoTexelSize;
            public static int deinterleavedAOTexelSize;
            public static int reinterleavedAOTexelSize;
            public static int uvToView;
            //public static int worldToCameraMatrix;
            public static int targetScale;
            public static int radius;
            public static int maxRadiusPixels;
            public static int negInvRadius2;
            public static int angleBias;
            public static int aoMultiplier;
            public static int intensity;
            public static int multiBounceInfluence;
            public static int multiBounceMaskRange;
            public static int offscreenSamplesContrib;
            public static int maxDistance;
            public static int distanceFalloff;
            public static int baseColor;
            public static int colorBleedSaturation;
            public static int albedoMultiplier;
            public static int colorBleedBrightnessMask;
            public static int colorBleedBrightnessMaskRange;
            public static int blurDeltaUV;
            public static int blurSharpness;
            public static int temporalParams;

            static ShaderProperties()
            {
                mainTex = Shader.PropertyToID("_MainTex");
                inputTex = Shader.PropertyToID("_InputTex");
                hbaoTex = Shader.PropertyToID("_HBAOTex");
                tempTex = Shader.PropertyToID("_TempTex");
                tempTex2 = Shader.PropertyToID("_TempTex2");
                noiseTex = Shader.PropertyToID("_NoiseTex");
                depthTex = Shader.PropertyToID("_DepthTex");
                normalsTex = Shader.PropertyToID("_NormalsTex");
                depthSliceTex = new int[4 * 4];
                normalsSliceTex = new int[4 * 4];
                aoSliceTex = new int[4 * 4];
                for (int i = 0; i < 4 * 4; i++)
                {
                    depthSliceTex[i] = Shader.PropertyToID("_DepthSliceTex" + i);
                    normalsSliceTex[i] = Shader.PropertyToID("_NormalsSliceTex" + i);
                    aoSliceTex[i] = Shader.PropertyToID("_AOSliceTex" + i);
                }
                deinterleaveOffset = new int[] {
                    Shader.PropertyToID("_Deinterleave_Offset00"),
                    Shader.PropertyToID("_Deinterleave_Offset10"),
                    Shader.PropertyToID("_Deinterleave_Offset01"),
                    Shader.PropertyToID("_Deinterleave_Offset11")
                };
                atlasOffset = Shader.PropertyToID("_AtlasOffset");
                jitter = Shader.PropertyToID("_Jitter");
                uvTransform = Shader.PropertyToID("_UVTransform");
                inputTexelSize = Shader.PropertyToID("_Input_TexelSize");
                aoTexelSize = Shader.PropertyToID("_AO_TexelSize");
                deinterleavedAOTexelSize = Shader.PropertyToID("_DeinterleavedAO_TexelSize");
                reinterleavedAOTexelSize = Shader.PropertyToID("_ReinterleavedAO_TexelSize");
                uvToView = Shader.PropertyToID("_UVToView");
                //worldToCameraMatrix = Shader.PropertyToID("_WorldToCameraMatrix");
                targetScale = Shader.PropertyToID("_TargetScale");
                radius = Shader.PropertyToID("_Radius");
                maxRadiusPixels = Shader.PropertyToID("_MaxRadiusPixels");
                negInvRadius2 = Shader.PropertyToID("_NegInvRadius2");
                angleBias = Shader.PropertyToID("_AngleBias");
                aoMultiplier = Shader.PropertyToID("_AOmultiplier");
                intensity = Shader.PropertyToID("_Intensity");
                multiBounceInfluence = Shader.PropertyToID("_MultiBounceInfluence");
                multiBounceMaskRange = Shader.PropertyToID("_MultiBounceMaskRange");
                offscreenSamplesContrib = Shader.PropertyToID("_OffscreenSamplesContrib");
                maxDistance = Shader.PropertyToID("_MaxDistance");
                distanceFalloff = Shader.PropertyToID("_DistanceFalloff");
                baseColor = Shader.PropertyToID("_BaseColor");
                colorBleedSaturation = Shader.PropertyToID("_ColorBleedSaturation");
                albedoMultiplier = Shader.PropertyToID("_AlbedoMultiplier");
                colorBleedBrightnessMask = Shader.PropertyToID("_ColorBleedBrightnessMask");
                colorBleedBrightnessMaskRange = Shader.PropertyToID("_ColorBleedBrightnessMaskRange");
                blurDeltaUV = Shader.PropertyToID("_BlurDeltaUV");
                blurSharpness = Shader.PropertyToID("_BlurSharpness");
                temporalParams = Shader.PropertyToID("_TemporalParams");
            }

            public static string GetOrthographicProjectionKeyword(bool orthographic)
            {
                return orthographic ? "ORTHOGRAPHIC_PROJECTION" : "__";
            }

            public static string GetQualityKeyword(HBAO.Quality quality)
            {
                switch (quality)
                {
                    case HBAO.Quality.Lowest:
                        return "QUALITY_LOWEST";
                    case HBAO.Quality.Low:
                        return "QUALITY_LOW";
                    case HBAO.Quality.Medium:
                        return "QUALITY_MEDIUM";
                    case HBAO.Quality.High:
                        return "QUALITY_HIGH";
                    case HBAO.Quality.Highest:
                        return "QUALITY_HIGHEST";
                    default:
                        return "QUALITY_MEDIUM";
                }
            }

            public static string GetNoiseKeyword(NoiseType noiseType)
            {
                switch (noiseType)
                {
                    case NoiseType.InterleavedGradientNoise:
                        return "INTERLEAVED_GRADIENT_NOISE";
                    case NoiseType.Dither:
                    case NoiseType.SpatialDistribution:
                    default:
                        return "__";
                }
            }

            public static string GetDeinterleavingKeyword(Deinterleaving deinterleaving)
            {
                switch (deinterleaving)
                {
                    case Deinterleaving.x4:
                        return "DEINTERLEAVED";
                    case Deinterleaving.Disabled:
                    default:
                        return "__";
                }
            }

            public static string GetDebugKeyword(DebugMode debugMode)
            {
                switch (debugMode)
                {
                    case DebugMode.AOOnly:
                        return "DEBUG_AO";
                    case DebugMode.ColorBleedingOnly:
                        return "DEBUG_COLORBLEEDING";
                    case DebugMode.SplitWithoutAOAndWithAO:
                        return "DEBUG_NOAO_AO";
                    case DebugMode.SplitWithAOAndAOOnly:
                        return "DEBUG_AO_AOONLY";
                    case DebugMode.SplitWithoutAOAndAOOnly:
                        return "DEBUG_NOAO_AOONLY";
                    case DebugMode.Disabled:
                    default:
                        return "__";
                }
            }

            public static string GetMultibounceKeyword(bool useMultiBounce)
            {
                return useMultiBounce ? "MULTIBOUNCE" : "__";
            }

            public static string GetOffscreenSamplesContributionKeyword(float offscreenSamplesContribution)
            {
                return offscreenSamplesContribution > 0 ? "OFFSCREEN_SAMPLES_CONTRIBUTION" : "__";
            }

            public static string GetPerPixelNormalsKeyword(PerPixelNormals perPixelNormals)
            {
                switch (perPixelNormals)
                {
                    case PerPixelNormals.Reconstruct:
                        return "NORMALS_RECONSTRUCT";
                    default:
                        return "__";
                }
            }

            public static string GetBlurRadiusKeyword(BlurType blurType)
            {
                switch (blurType)
                {
                    case BlurType.Narrow:
                        return "BLUR_RADIUS_2";
                    case BlurType.Medium:
                        return "BLUR_RADIUS_3";
                    case BlurType.Wide:
                        return "BLUR_RADIUS_4";
                    case BlurType.ExtraWide:
                        return "BLUR_RADIUS_5";
                    case BlurType.None:
                    default:
                        return "BLUR_RADIUS_3";
                }
            }

            public static string GetVarianceClippingKeyword(VarianceClipping varianceClipping)
            {
                switch (varianceClipping)
                {
                    case VarianceClipping._4Tap:
                        return "VARIANCE_CLIPPING_4TAP";
                    case VarianceClipping._8Tap:
                        return "VARIANCE_CLIPPING_8TAP";
                    case VarianceClipping.Disabled:
                    default:
                        return "__";
                }
            }

            public static string GetColorBleedingKeyword(bool colorBleedingEnabled)
            {
                return colorBleedingEnabled ? "COLOR_BLEEDING" : "__";
            }
        }

        private static class MersenneTwister
        {
            // Mersenne-Twister random numbers in [0,1).
            public static float[] Numbers = new float[] {
                //0.463937f,0.340042f,0.223035f,0.468465f,0.322224f,0.979269f,0.031798f,0.973392f,0.778313f,0.456168f,0.258593f,0.330083f,0.387332f,0.380117f,0.179842f,0.910755f,
                //0.511623f,0.092933f,0.180794f,0.620153f,0.101348f,0.556342f,0.642479f,0.442008f,0.215115f,0.475218f,0.157357f,0.568868f,0.501241f,0.629229f,0.699218f,0.707733f
                0.556725f,0.005520f,0.708315f,0.583199f,0.236644f,0.992380f,0.981091f,0.119804f,0.510866f,0.560499f,0.961497f,0.557862f,0.539955f,0.332871f,0.417807f,0.920779f,
                0.730747f,0.076690f,0.008562f,0.660104f,0.428921f,0.511342f,0.587871f,0.906406f,0.437980f,0.620309f,0.062196f,0.119485f,0.235646f,0.795892f,0.044437f,0.617311f
            };
        }

        private static class ProfilingSample
        {
            public static string Ao = "HBAO - AO";
            public static string Blur = "HBAO - Blur";
            public static string TemporalFilter = "HBAO - Temporal Filter";
            public static string Composite = "HBAO - Composite";
        }

        private class AoKernelParameter
        {
            public int directions { get; set; }
            public int steps { get; set; }
        }

        private static readonly Dictionary<Quality, AoKernelParameter> s_AoKernelParameters = new Dictionary<Quality, AoKernelParameter>
        {
            { Quality.Lowest, new AoKernelParameter { directions = 3, steps = 2 } },
            { Quality.Low, new AoKernelParameter { directions = 4, steps = 3 } },
            { Quality.Medium, new AoKernelParameter { directions = 6, steps = 4 } },
            { Quality.High, new AoKernelParameter { directions = 8, steps = 4 } },
            { Quality.Highest, new AoKernelParameter { directions = 8, steps = 6 } }
        };

        private static readonly Vector2[] s_jitter = new Vector2[4 * 4];
        private static readonly float[] s_temporalRotations = { 60.0f, 300.0f, 180.0f, 240.0f, 120.0f, 0.0f };
        private static readonly float[] s_temporalOffsets = { 0.0f, 0.5f, 0.25f, 0.75f };

        private Material material { get; set; }
        private HDCamera cameraData { get; set; }
        private int width { get; set; }
        private int height { get; set; }
        private int screenWidth { get; set; }
        private int screenHeight { get; set; }
        private int aoWidth { get; set; }
        private int aoHeight { get; set; }
        private Vector2 aoScale { get; set; }
        private int reinterleavedWidth { get; set; }
        private int reinterleavedHeight { get; set; }
        private int deinterleavedWidth { get; set; }
        private int deinterleavedHeight { get; set; }
        private int frameCount { get; set; }
        private bool motionVectorsSupported { get; set; }
        private RTHandle sourceRT { get; set; }
        private RTHandle destinationRT { get; set; }
        private RTHandle aoRT { get; set; }
        private RTHandle tempRT { get; set; }
        private RTHandle temp2RT { get; set; }
        private RTHandle aoHistoryBufferRT { get; set; }
        private RTHandle colorBleedingHistoryBufferRT { get; set; }
        private Texture2D noiseTex { get; set; }

        private bool isRenderTextureSetDirty
        {
            get
            {
                if (aoRT == null || tempRT == null || temp2RT == null ||
                    aoRT.rt == null || tempRT.rt == null || temp2RT.rt == null ||
                    aoScale.x != aoRT.scaleFactor.x || aoScale.y != aoRT.scaleFactor.y ||
                    aoScale.x != tempRT.scaleFactor.x || aoScale.y != tempRT.scaleFactor.y ||
                    aoScale.x != temp2RT.scaleFactor.x || aoScale.y != temp2RT.scaleFactor.y)
                {
                    return true;
                }

                return false;
            }
        }

        private bool isHistoryBufferDirty
        {
            get
            {
                if (aoHistoryBufferRT == null || (colorBleedingEnabled.value && colorBleedingHistoryBufferRT == null) ||
                    aoHistoryBufferRT.rt == null || (colorBleedingEnabled.value && colorBleedingHistoryBufferRT.rt == null) ||
                    aoScale.x != aoHistoryBufferRT.scaleFactor.x || aoScale.y != aoHistoryBufferRT.scaleFactor.y ||
                    (colorBleedingEnabled.value && aoScale.x != colorBleedingHistoryBufferRT.scaleFactor.x) ||
                    (colorBleedingEnabled.value && aoScale.y != colorBleedingHistoryBufferRT.scaleFactor.y) ||
                    m_PreviousTemporalFilterEnabled != temporalFilterEnabled.value ||
                    m_PreviousResolution != resolution.value ||
                    m_PreviousColorBleedingEnabled != colorBleedingEnabled.value ||
                    m_PrevStereoRenderingMode != XRGraphics.stereoRenderingMode)
                {
                    m_PreviousTemporalFilterEnabled = temporalFilterEnabled.value;
                    m_PreviousResolution = resolution.value;
                    m_PreviousColorBleedingEnabled = colorBleedingEnabled.value;
                    m_PrevStereoRenderingMode = XRGraphics.stereoRenderingMode;

                    return true;
                }

                return false;
            }
        }

        private static GraphicsFormat colorFormat { get { return SystemInfo.SupportsRenderTextureFormat(RenderTextureFormat.ARGBHalf) ? GraphicsFormat.R16G16B16A16_SFloat : GraphicsFormat.R8G8B8A8_SRGB; } }
        private static bool isLinearColorSpace { get { return QualitySettings.activeColorSpace == ColorSpace.Linear; } }
        private bool renderingInSceneView { get { return cameraData.camera.cameraType == CameraType.SceneView; } }

        private Resolution? m_PreviousResolution;
        private NoiseType? m_PreviousNoiseType;
        private bool m_PreviousTemporalFilterEnabled;
        private bool m_PreviousColorBleedingEnabled;
        private XRGraphics.StereoRenderingMode m_PrevStereoRenderingMode;
        private string[] m_ShaderKeywords;
        private Vector4[] m_UVToViewPerEye = new Vector4[2];
        private float[] m_RadiusPerEye = new float[2];


        public override void Setup()
        {
            if (!FindShader())
                return;

            var renderpipelineAsset = GraphicsSettings.currentRenderPipeline as HDRenderPipelineAsset;

            // For platforms not supporting motion vectors texture
            // https://docs.unity3d.com/ScriptReference/DepthTextureMode.MotionVectors.html
            motionVectorsSupported = SystemInfo.SupportsRenderTextureFormat(RenderTextureFormat.RGHalf) && renderpipelineAsset.currentPlatformRenderPipelineSettings.supportMotionVectors;
        }

        public override void Render(CommandBuffer cmd, HDCamera hdCamera, RTHandle source, RTHandle destination)
        {
            if (material == null) material = CoreUtils.CreateEngineMaterial(shader);
            if (material == null)
            {
                Debug.LogError("HBAO material has not been correctly initialized...");
                return;
            }

            FetchRenderParameters(hdCamera, source, destination);
            CheckParameters();
            UpdateMaterialProperties();
            UpdateShaderKeywords();

            // AO
            AO(cmd);

            // Blur
            Blur(cmd);

            // Temporal Filter
            TemporalFilter(cmd);

            // Composite
            Composite(cmd);

            frameCount++;
        }

        public override void Cleanup()
        {
            ReleaseHistoryBuffers();

            RTHandles.Release(aoRT);
            RTHandles.Release(tempRT);
            RTHandles.Release(temp2RT);
            CoreUtils.Destroy(noiseTex);
            CoreUtils.Destroy(material);
        }

        private bool FindShader()
        {
            if (!SystemInfo.SupportsRenderTextureFormat(RenderTextureFormat.Depth))
            {
                Debug.LogWarning("HBAO shader is not supported on this platform.");
                return false;
            }

            if (shader == null) shader = Shader.Find("Hidden/High Definition Render Pipeline/HBAO");
            if (shader == null)
            {
                Debug.LogError("HBAO shader was not found...");
                return false;
            }

            return true;
        }

        private void FetchRenderParameters(HDCamera hdCamera, RTHandle source, RTHandle destination)
        {
            sourceRT = source;
            destinationRT = destination;
            width = hdCamera.actualWidth;
            height = hdCamera.actualHeight;
            screenWidth = (int)hdCamera.screenSize.x;
            screenHeight = (int)hdCamera.screenSize.y;
            aoWidth = width;
            aoHeight = height;
            aoScale = Vector2.one;

            var downsamplingFactor = resolution.value == Resolution.Full ? 1 : 2/*deinterleaving.value == Deinterleaving.Disabled ? 2 : 1*/;
            if (downsamplingFactor > 1)
            {
                aoWidth = (width + width % 2) / downsamplingFactor;
                aoHeight = (height + height % 2) / downsamplingFactor;
                aoScale = new Vector2(aoWidth / (float)width, aoHeight / (float)height);
            }

            /*
            if (deinterleaving.value != Deinterleaving.Disabled)
            {
                reinterleavedWidth = width + (width % 4 == 0 ? 0 : 4 - (width % 4));
                reinterleavedHeight = height + (height % 4 == 0 ? 0 : 4 - (height % 4));
                deinterleavedWidth = reinterleavedWidth / 4;
                deinterleavedHeight = reinterleavedHeight / 4;
            }*/

            cameraData = hdCamera;
        }

        private void AllocateHistoryBuffers()
        {
            ReleaseHistoryBuffers();

            aoHistoryBufferRT = RTHandles.Alloc(scaleFactor: aoScale, slices: TextureXR.slices, colorFormat: colorFormat, dimension: TextureXR.dimension, useDynamicScale: true, name: "HBAO_AO_HistoryBuffer");
            if (colorBleedingEnabled.value)
                colorBleedingHistoryBufferRT = RTHandles.Alloc(scaleFactor: aoScale, slices: TextureXR.slices, colorFormat: colorFormat, dimension: TextureXR.dimension, useDynamicScale: true, name: "HBAO_ColorBleeding_HistoryBuffer");

            // Clear history buffers to default
            var lastActive = RenderTexture.active;
            RenderTexture.active = aoHistoryBufferRT;
            GL.Clear(false, true, Color.white);
            if (colorBleedingEnabled.value)
            {
                RenderTexture.active = colorBleedingHistoryBufferRT;
                GL.Clear(false, true, new Color(0, 0, 0, 1));
            }
            RenderTexture.active = lastActive;

            frameCount = 0;
            //Debug.Log("History Buffers allocated and cleared");
        }

        private void ReleaseHistoryBuffers()
        {
            if (aoHistoryBufferRT != null)
                RTHandles.Release(aoHistoryBufferRT);

            if (colorBleedingHistoryBufferRT != null)
                RTHandles.Release(colorBleedingHistoryBufferRT);
        }

        private void AO(CommandBuffer cmd)
        {
            cmd.BeginSample(ProfilingSample.Ao);
            CoreUtils.SetRenderTarget(cmd, aoRT);
            CoreUtils.ClearRenderTarget(cmd, ClearFlag.Color, new Color(0, 0, 0, 1));
            DrawFullScreen(cmd, sourceRT, aoRT, material, Pass.AO);
            cmd.SetGlobalTexture(ShaderProperties.hbaoTex, aoRT);
            cmd.EndSample(ProfilingSample.Ao);
        }

        /*
        private void DeinterleavedAO(CommandBuffer cmd)
        {
            // Deinterleave depth & normals (4x4)
            for (int i = 0; i < 4; i++)
            {
                var rtsDepth = new RenderTargetIdentifier[] {
                    ShaderProperties.depthSliceTex[(i << 2) + 0],
                    ShaderProperties.depthSliceTex[(i << 2) + 1],
                    ShaderProperties.depthSliceTex[(i << 2) + 2],
                    ShaderProperties.depthSliceTex[(i << 2) + 3]
                };
                var rtsNormals = new RenderTargetIdentifier[] {
                    ShaderProperties.normalsSliceTex[(i << 2) + 0],
                    ShaderProperties.normalsSliceTex[(i << 2) + 1],
                    ShaderProperties.normalsSliceTex[(i << 2) + 2],
                    ShaderProperties.normalsSliceTex[(i << 2) + 3]
                };

                int offsetX = (i & 1) << 1; int offsetY = (i >> 1) << 1;
                cmd.SetGlobalVector(ShaderProperties.deinterleaveOffset[0], new Vector2(offsetX + 0, offsetY + 0));
                cmd.SetGlobalVector(ShaderProperties.deinterleaveOffset[1], new Vector2(offsetX + 1, offsetY + 0));
                cmd.SetGlobalVector(ShaderProperties.deinterleaveOffset[2], new Vector2(offsetX + 0, offsetY + 1));
                cmd.SetGlobalVector(ShaderProperties.deinterleaveOffset[3], new Vector2(offsetX + 1, offsetY + 1));
                for (int j = 0; j < 4; j++)
                {
                    cmd.GetTemporaryRT(ShaderProperties.depthSliceTex[j + 4 * i], deinterleavedDepthDesc, FilterMode.Point);
                    cmd.GetTemporaryRT(ShaderProperties.normalsSliceTex[j + 4 * i], deinterleavedNormalsDesc, FilterMode.Point);
                }
                cmd.SetRenderTarget(rtsDepth, rtsDepth[0]);
                cmd.DrawMesh(RenderingUtils.fullscreenMesh, Matrix4x4.identity, material, 0, Pass.Deinterleave_Depth); // outputs 4 render textures
                cmd.SetRenderTarget(rtsNormals, rtsNormals[0]);
                cmd.DrawMesh(RenderingUtils.fullscreenMesh, Matrix4x4.identity, material, 0, Pass.Deinterleave_Normals); // outputs 4 render textures
            }

            // AO on each layer
            for (int i = 0; i < 4 * 4; i++)
            {
                cmd.SetGlobalTexture(ShaderProperties.depthTex, ShaderProperties.depthSliceTex[i]);
                cmd.SetGlobalTexture(ShaderProperties.normalsTex, ShaderProperties.normalsSliceTex[i]);
                cmd.SetGlobalVector(ShaderProperties.jitter, s_jitter[i]);
                cmd.GetTemporaryRT(ShaderProperties.aoSliceTex[i], deinterleavedAoDesc, FilterMode.Point);
                CoreUtils.SetRenderTarget(cmd, ShaderProperties.aoSliceTex[i]);
                CoreUtils.ClearRenderTarget(cmd, ClearFlag.Color, new Color(0, 0, 0, 1));
                Blit(cmd, ShaderProperties.inputTex, ShaderProperties.aoSliceTex[i], material, Pass.AO_Deinterleaved); // ao
                cmd.ReleaseTemporaryRT(ShaderProperties.depthSliceTex[i]);
                cmd.ReleaseTemporaryRT(ShaderProperties.normalsSliceTex[i]);
            }

            // Atlas Deinterleaved AO, 4x4
            cmd.GetTemporaryRT(ShaderProperties.tempTex, reinterleavedAoDesc, FilterMode.Point);
            for (int i = 0; i < 4 * 4; i++)
            {
                cmd.SetGlobalVector(ShaderProperties.atlasOffset, new Vector2(((i & 1) + (((i & 7) >> 2) << 1)) * deinterleavedAoDesc.width, (((i & 3) >> 1) + ((i >> 3) << 1)) * deinterleavedAoDesc.height));
                Blit(cmd, ShaderProperties.aoSliceTex[i], ShaderProperties.tempTex, material, Pass.Atlas_AO_Deinterleaved); // atlassing
                cmd.ReleaseTemporaryRT(ShaderProperties.aoSliceTex[i]);
            }

            // Reinterleave AO
            Blit(cmd, ShaderProperties.tempTex, ShaderProperties.hbaoTex, material, Pass.Reinterleave_AO); // reinterleave
            cmd.ReleaseTemporaryRT(ShaderProperties.tempTex);
        }
        */

        private void Blur(CommandBuffer cmd)
        {
            if (blurType.value != BlurType.None)
            {
                cmd.BeginSample(ProfilingSample.Blur);
                cmd.SetGlobalVector(ShaderProperties.blurDeltaUV, new Vector2(1f / width, 0));
                DrawFullScreen(cmd, aoRT, tempRT, material, Pass.Blur); // blur X
                cmd.SetGlobalVector(ShaderProperties.blurDeltaUV, new Vector2(0, 1f / height));
                DrawFullScreen(cmd, tempRT, aoRT, material, Pass.Blur); // blur Y
                cmd.SetGlobalTexture(ShaderProperties.hbaoTex, aoRT);
                cmd.EndSample(ProfilingSample.Blur);
            }
        }

        private void TemporalFilter(CommandBuffer cmd)
        {
            if (isHistoryBufferDirty && temporalFilterEnabled.value)
                AllocateHistoryBuffers();

            if (temporalFilterEnabled.value && !renderingInSceneView)
            {
                cmd.BeginSample(ProfilingSample.TemporalFilter);
                if (colorBleedingEnabled.value)
                {
                    // For Color Bleeding we have 2 history buffers to fill so there are 2 render targets.
                    // AO is still contained in Color Bleeding history buffer (alpha channel) so that we
                    // can use it as a render texture for the composite pass.
                    var rts = new RenderTargetIdentifier[] {
                        aoHistoryBufferRT,
                        colorBleedingHistoryBufferRT
                    };
                    DrawFullScreen(cmd, aoHistoryBufferRT, temp2RT, material, Pass.Copy);
                    DrawFullScreen(cmd, colorBleedingHistoryBufferRT, tempRT, material, Pass.Copy);
                    cmd.SetGlobalTexture(ShaderProperties.tempTex, tempRT);
                    DrawFullScreen(cmd, temp2RT, rts, aoHistoryBufferRT, material, Pass.Temporal_Filter);
                    cmd.SetGlobalTexture(ShaderProperties.hbaoTex, colorBleedingHistoryBufferRT);
                }
                else
                {
                    // AO history buffer contains ao in aplha channel so we can just use history as
                    // a render texture for the composite pass.
                    DrawFullScreen(cmd, aoHistoryBufferRT, tempRT, material, Pass.Copy);
                    DrawFullScreen(cmd, tempRT, aoHistoryBufferRT, material, Pass.Temporal_Filter);
                    cmd.SetGlobalTexture(ShaderProperties.hbaoTex, aoHistoryBufferRT);
                }
                cmd.EndSample(ProfilingSample.TemporalFilter);
            }
        }

        private void Composite(CommandBuffer cmd)
        {
            cmd.BeginSample(ProfilingSample.Composite);
            DrawFullScreen(cmd, sourceRT, destinationRT, material, debugMode.value == DebugMode.ViewNormals ? Pass.Debug_ViewNormals : Pass.Composite);
            cmd.EndSample(ProfilingSample.Composite);
        }

        private void UpdateMaterialProperties()
        {
            var projMatrix = cameraData.mainViewConstants.projMatrix;
            float invTanHalfFOVxAR =  projMatrix.m00; // m00 => 1.0f / (tanHalfFOV * aspectRatio)
            float invTanHalfFOV    = -projMatrix.m11; // m11 => 1.0f / tanHalfFOV
            m_UVToViewPerEye[0] = new Vector4(2.0f / invTanHalfFOVxAR, -2.0f / invTanHalfFOV, -1.0f / invTanHalfFOVxAR, 1.0f / invTanHalfFOV);
            m_RadiusPerEye[0] = radius.value * 0.5f * (screenHeight /*/ (deinterleaving.value == HBAO.Deinterleaving.x4 ? 4 : 1)*/ / (2.0f / invTanHalfFOV));

            if (XRGraphics.enabled && XRGraphics.stereoRenderingMode == XRGraphics.StereoRenderingMode.SinglePassInstanced && !renderingInSceneView)
            {
                // TODO: sorry for GC... no other way actually
                var additionalCameraData = typeof(HDCamera).GetField("m_AdditionalCameraData", System.Reflection.BindingFlags.NonPublic | System.Reflection.BindingFlags.Instance).GetValue(cameraData) as HDAdditionalCameraData;
                if (additionalCameraData.xrRendering)
                {
                    var xrViewConstants = typeof(HDCamera).GetField("m_XRViewConstants", System.Reflection.BindingFlags.NonPublic | System.Reflection.BindingFlags.Instance).GetValue(cameraData) as HDCamera.ViewConstants[];
                    for (int viewIndex = 0; viewIndex < 2; viewIndex++)
                    {
                        projMatrix = xrViewConstants[viewIndex].projMatrix;
                        invTanHalfFOVxAR =  projMatrix.m00; // m00 => 1.0f / (tanHalfFOV * aspectRatio)
                        invTanHalfFOV    = -projMatrix.m11; // m11 => 1.0f / tanHalfFOV
                        m_UVToViewPerEye[viewIndex] = new Vector4(2.0f / invTanHalfFOVxAR, -2.0f / invTanHalfFOV, -1.0f / invTanHalfFOVxAR, 1.0f / invTanHalfFOV);
                        m_RadiusPerEye[viewIndex] = radius.value * 0.5f * (screenHeight /*/ (deinterleaving.value == HBAO.Deinterleaving.x4 ? 4 : 1)*/ / (2.0f / invTanHalfFOV));
                    }
                }
            }

            //float tanHalfFovY = Mathf.Tan(0.5f * cameraData.camera.fieldOfView * Mathf.Deg2Rad);
            //float invFocalLenX = 1.0f / (1.0f / tanHalfFovY * (screenHeight / (float)screenWidth));
            //float invFocalLenY = 1.0f / (1.0f / tanHalfFovY);
            float maxRadInPixels = Mathf.Max(16, maxRadiusPixels.value * Mathf.Sqrt(screenWidth * screenHeight / (1080.0f * 1920.0f)));
            //maxRadInPixels /= (deinterleaving.value == Deinterleaving.x4 ? 4 : 1);

            var targetScale = /*deinterleaving.value == Deinterleaving.x4 ?
                                  new Vector4(reinterleavedWidth / (float)width, reinterleavedHeight / (float)height, 1.0f / (reinterleavedWidth / (float)width), 1.0f / (reinterleavedHeight / (float)height)) :*/
                                      resolution.value == Resolution.Half /*&& perPixelNormals.value == PerPixelNormals.Reconstruct*/ ?
                                          new Vector4((width + 0.5f) / width, (height + 0.5f) / height, 1f, 1f) :
                                          Vector4.one;

            material.SetTexture(ShaderProperties.noiseTex, noiseTex);
            material.SetVector(ShaderProperties.inputTexelSize, new Vector4(1f / width, 1f / height, width, height));
            material.SetVector(ShaderProperties.aoTexelSize, new Vector4(1f / aoWidth, 1f / aoHeight, aoWidth, aoHeight));
            material.SetVector(ShaderProperties.deinterleavedAOTexelSize, new Vector4(1f / deinterleavedWidth, 1f / deinterleavedHeight, deinterleavedWidth, deinterleavedHeight));
            material.SetVector(ShaderProperties.reinterleavedAOTexelSize, new Vector4(1f / reinterleavedWidth, 1f / reinterleavedHeight, reinterleavedWidth, reinterleavedHeight));
            material.SetVector(ShaderProperties.targetScale, targetScale);
            //material.SetVector(ShaderProperties.uvToView, new Vector4(2.0f * invFocalLenX, -2.0f * invFocalLenY, -1.0f * invFocalLenX, 1.0f * invFocalLenY));
            material.SetVectorArray(ShaderProperties.uvToView, m_UVToViewPerEye);
            //material.SetMatrix(ShaderProperties.worldToCameraMatrix, cameraData.camera.worldToCameraMatrix);
            //material.SetFloat(ShaderProperties.radius, radius.value * 0.5f * ((screenHeight /*/ (deinterleaving.value == Deinterleaving.x4 ? 4 : 1)*/) / (tanHalfFovY * 2.0f)));
            //material.SetFloat(ShaderProperties.radius, radius.value * 0.5f * ((screenHeight /*/ (deinterleaving.value == Deinterleaving.x4 ? 4 : 1)*/) / (invFocalLenY * 2.0f)));
            material.SetFloatArray(ShaderProperties.radius, m_RadiusPerEye);
            material.SetFloat(ShaderProperties.maxRadiusPixels, maxRadInPixels);
            material.SetFloat(ShaderProperties.negInvRadius2, -1.0f / (radius.value * radius.value));
            material.SetFloat(ShaderProperties.angleBias, bias.value);
            material.SetFloat(ShaderProperties.aoMultiplier, 2.0f * (1.0f / (1.0f - bias.value)));
            material.SetFloat(ShaderProperties.intensity, isLinearColorSpace ? intensity.value : intensity.value * 0.454545454545455f);
            material.SetFloat(ShaderProperties.multiBounceInfluence, multiBounceInfluence.value);
            material.SetVector(ShaderProperties.multiBounceMaskRange, AdjustBrightnessMaskToGammaSpace(new Vector2(Mathf.Pow(multiBounceMaskRange.value.x, 3), Mathf.Pow(multiBounceMaskRange.value.y, 3))));
            material.SetFloat(ShaderProperties.offscreenSamplesContrib, offscreenSamplesContribution.value);
            material.SetFloat(ShaderProperties.maxDistance, maxDistance.value);
            material.SetFloat(ShaderProperties.distanceFalloff, distanceFalloff.value);
            material.SetColor(ShaderProperties.baseColor, baseColor.value);
            material.SetFloat(ShaderProperties.blurSharpness, sharpness.value);
            material.SetFloat(ShaderProperties.colorBleedSaturation, saturation.value);
            material.SetFloat(ShaderProperties.albedoMultiplier, albedoMultiplier.value);
            material.SetFloat(ShaderProperties.colorBleedBrightnessMask, brightnessMask.value);
            material.SetVector(ShaderProperties.colorBleedBrightnessMaskRange, AdjustBrightnessMaskToGammaSpace(new Vector2(Mathf.Pow(brightnessMaskRange.value.x, 3), Mathf.Pow(brightnessMaskRange.value.y, 3))));
            material.SetVector(ShaderProperties.temporalParams, temporalFilterEnabled.value && !renderingInSceneView ? new Vector2(s_temporalRotations[frameCount % 6] / 360.0f, s_temporalOffsets[frameCount % 4]) : Vector2.zero);
        }

        private void UpdateShaderKeywords()
        {
            if (m_ShaderKeywords == null || m_ShaderKeywords.Length != 11) m_ShaderKeywords = new string[11];

            m_ShaderKeywords[0] = ShaderProperties.GetOrthographicProjectionKeyword(cameraData.camera.orthographic);
            m_ShaderKeywords[1] = ShaderProperties.GetQualityKeyword(quality.value);
            m_ShaderKeywords[2] = ShaderProperties.GetNoiseKeyword(noiseType.value);
            //m_ShaderKeywords[3] = ShaderProperties.GetDeinterleavingKeyword(deinterleaving.value);
            m_ShaderKeywords[3] = ShaderProperties.GetDeinterleavingKeyword(Deinterleaving.Disabled);
            m_ShaderKeywords[4] = ShaderProperties.GetDebugKeyword(debugMode.value);
            m_ShaderKeywords[5] = ShaderProperties.GetMultibounceKeyword(useMultiBounce.value);
            m_ShaderKeywords[6] = ShaderProperties.GetOffscreenSamplesContributionKeyword(offscreenSamplesContribution.value);
            m_ShaderKeywords[7] = ShaderProperties.GetPerPixelNormalsKeyword(perPixelNormals.value);
            m_ShaderKeywords[8] = ShaderProperties.GetBlurRadiusKeyword(blurType.value);
            m_ShaderKeywords[9] = ShaderProperties.GetVarianceClippingKeyword(varianceClipping.value);
            m_ShaderKeywords[10] = ShaderProperties.GetColorBleedingKeyword(colorBleedingEnabled.value);

            material.shaderKeywords = m_ShaderKeywords;
        }

        private void CheckParameters()
        {
            // Settings to force
            //if (deinterleaving.value != Deinterleaving.Disabled && SystemInfo.supportedRenderTargetCount < 4)
            //    SetDeinterleaving(Deinterleaving.Disabled);

            if (temporalFilterEnabled.value && !motionVectorsSupported)
                EnableTemporalFilter(false);

            if (colorBleedingEnabled.value && temporalFilterEnabled.value && SystemInfo.supportedRenderTargetCount < 2)
                EnableTemporalFilter(false);

            // Noise texture
            if (noiseTex == null || m_PreviousNoiseType != noiseType.value)
            {
                if (noiseTex != null) CoreUtils.Destroy(noiseTex);

                CreateNoiseTexture();

                m_PreviousNoiseType = noiseType.value;
            }

            if (isRenderTextureSetDirty)
            {
                //Debug.Log("RenderTextureSet is dirty");

                RTHandles.Release(aoRT);
                RTHandles.Release(tempRT);
                RTHandles.Release(temp2RT);

                aoRT = RTHandles.Alloc(scaleFactor: aoScale, slices: TextureXR.slices, colorFormat: colorFormat, dimension: TextureXR.dimension, useDynamicScale: true, name: "HBAO_AO");
                tempRT = RTHandles.Alloc(scaleFactor: aoScale, slices: TextureXR.slices, colorFormat: colorFormat, dimension: TextureXR.dimension, useDynamicScale: true, name: "HBAO_Temp");
                temp2RT = RTHandles.Alloc(scaleFactor: aoScale, slices: TextureXR.slices, colorFormat: colorFormat, dimension: TextureXR.dimension, useDynamicScale: true, name: "HBAO_Temp2");
            }
        }

        private void DrawFullScreen(CommandBuffer cmd, RTHandle source, RTHandle destination, Material material, int pass = 0)
        {
            cmd.SetGlobalTexture(ShaderProperties.mainTex, source);
            HDUtils.DrawFullScreen(cmd, material, destination, shaderPassId: pass);
        }

        private void DrawFullScreen(CommandBuffer cmd, RTHandle source, RenderTargetIdentifier[] colorBuffers, RTHandle depthStencilBuffer, Material material, int pass = 0)
        {
            cmd.SetGlobalTexture(ShaderProperties.mainTex, source);
            HDUtils.DrawFullScreen(cmd, material, colorBuffers, depthStencilBuffer, shaderPassId: pass);
        }

        private static Vector2 AdjustBrightnessMaskToGammaSpace(Vector2 v)
        {
            return isLinearColorSpace ? v : ToGammaSpace(v);
        }

        private static float ToGammaSpace(float v)
        {
            return Mathf.Pow(v, 0.454545454545455f);
        }

        private static Vector2 ToGammaSpace(Vector2 v)
        {
            return new Vector2(ToGammaSpace(v.x), ToGammaSpace(v.y));
        }

        private void CreateNoiseTexture()
        {
            noiseTex = new Texture2D(4, 4, SystemInfo.SupportsTextureFormat(TextureFormat.RGHalf) ? TextureFormat.RGHalf : TextureFormat.RGB24, false, true);
            noiseTex.filterMode = FilterMode.Point;
            noiseTex.wrapMode = TextureWrapMode.Repeat;
            int z = 0;
            for (int x = 0; x < 4; ++x)
            {
                for (int y = 0; y < 4; ++y)
                {
                    float r1 = noiseType != NoiseType.Dither ? 0.25f * (0.0625f * ((x + y & 3) << 2) + (x & 3)) : MersenneTwister.Numbers[z++];
                    float r2 = noiseType != NoiseType.Dither ? 0.25f * ((y - x) & 3) : MersenneTwister.Numbers[z++];
                    Color color = new Color(r1, r2, 0);
                    noiseTex.SetPixel(x, y, color);
                }
            }
            noiseTex.Apply();

            for (int i = 0, j = 0; i < s_jitter.Length; ++i)
            {
                float r1 = MersenneTwister.Numbers[j++];
                float r2 = MersenneTwister.Numbers[j++];
                s_jitter[i] = new Vector2(r1, r2);
            }
        }
    }
}
