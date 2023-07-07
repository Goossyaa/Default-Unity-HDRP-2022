# Default Unity URP 2021
Unity 2021.3.25f1
  
# Assets list
## Unity
2D Animations - 7.0.10  
2D Sprite - 1.0.0  
Animation Rigging - 1.1.1  
Burst - 1.8.2  
Localization - 1.3.2  
Mathematics - 1.2.6  
Cinemachine - 2.8.9  
Post Processing - 3.2.2  
Recorder - 3.0.3  
Shader Graph - 12.1.10  
TextMesh Pro - 3.0.6  
Timeline - 1.6.4  
Universal RP - 12.1.10  
Visual Effect Graph - 12.1.10  
Visual Scripting - 1.8.0  
  
## Third-party
### Plugins
Amplify Shader Editor - 1.9.1  
Amplify Shader Pack - 1.0.3  
Beautify 3 - 15.5  
DOTween Pro - 1.0.310  
Feel - 3.5  
FMOD  
Rewired - 1.1.41.5 
All Settings Pro - 1.0.5  
Fast script reload - 1.5

### Editor
Build Report - 3.4.14  
ConsolePro  
Grabbit - 2021.0.8  
Hierarchy 2  
Hierarchy Pro - Extended 2022.1.4  
Shader Control - 6.2.1  
SuperPivot  
  
# Project structure
```
Assets
|---Art
|	|---Animations
|	|---Animators
|	|---Fonts		Fonts converted by TextMesh Pro 
|	|---Materials
|	|---Models		FBX and BLEND files
|	|---Textures		All images 
|
|---Audio
|	|---Music
|	|---Sounds
|
|---Code
| 	|---Scripts		C# scripts
| 	|---Shaders 		Shader files and shader graphs
|	|---VFX			VFX graph files
|
|---Level 			Anything related to game design in Unity
| 	|---Prefabs
| 	|---Scenes
|
|---Resource			Some Assets store their settings here. For example DOTween
|
|---Settings			User settings and configuration files
| 	|---PostProcessing
| 	|---Presets
| 	|---Quality
| 	|---Renderer
| 	|---ShaderVariants
|
|---Third-party			Third-party content from the Asset Store
| 	|---Content		Any art-related asset with its own structure that does not bring additional functionality
| 	|---Editor		Any editor extensions that should not affect the build
| 	|---Plugins		Other third-party assets that bring new functionality to the build
|
|---zzzTrash			Files to be assigned or deleted

```


# Changelog
## [0.1.2] — 2023-07-07

### Added
Fast script reload

### Changed
#### Unity
Updated project version to 2021.03.25f1

#### README.md
Remove "v" prefix from versions, in third-party assets list



## [0.1.1] — 2023-03-18

### Added
New high quality **HDRIs**  
**Animators** folder


### Changed
#### Unity
Updated the project version from 2021.3.19f1 to **2021.3.21f1**  
Moved **VFX** folder from /Art to **/Code**

#### README.md
Tweaked **Project structure**  
Updated **Changelog**


### Removed
Delete old **HDRIs**  
UModeler


## [0.1.0] — 2023-02-20

### Added
#### Unity
Amplify Shader Editor - v1.9.1  
Amplify Shader Pack - v1.0.3  
UModeler - v2.9.20  
Rewired - v1.1.41.5  
All Settings Pro - v1.0.5  
Fullscreen Editor - v2.2.7
#### README.md
Assets list block  
Project structure block  

### Changed
Updated the project version from 2020.3.43f1 to **2021.3.19f1**  
Updated Horizon Based Ambient Occlusion  
Input System settings to Old  

### Removed
RainbowFolders  
I2 Localization  
Lux URP Essentials  
Bolt  

### Fixed 
Renamed folder «zzz Trash zzz» to «zzzTrash» to get rid of the spaces  
  
## [0.0.1] — 2023-02-18

Created a repository using the template https://github.com/Goossyaa/Default-Unity-URP  