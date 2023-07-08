# Default Unity HDRP 2022
Unity 2022.3.4f1
  
# Assets list
## Unity
2D Animations - 9.0.3 
2D Sprite - 1.0.0  
Animation Rigging - 1.2.1  
Burst - 1.8.7  
Localization - 1.3.2  
Mathematics - 1.2.6  
Cinemachine - 2.9.7  
Post Processing - 3.2.2  
Recorder - 4.0.1  
Shader Graph - 14.0.8   
TextMesh Pro - 3.0.6  
Timeline - 1.7.5  
High Definition RP - 14.0.8   
Visual Effect Graph - 14.0.8  
Visual Scripting - 1.8.0  
  
## Third-party
### Plugins
Amplify Shader Editor - 1.9.1.5  
DOTween Pro - 1.0.310  
Feel - 3.5  
FMOD  
Rewired - 1.1.45.0 
All Settings Pro - 1.0.5  
Fast script reload - 1.5
UModeler - 2.9.20

### Editor
Build Report - 3.4.14  
ConsolePro  
Grabbit - 2021.0.8   
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
|	|---Musics
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
| 	|---Volume
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
## [0.1.3] — 2023-07-08
Created a repository using the template https://github.com/Goossyaa/Default-Unity-URP-2021

### Added
UModeler - 2.9.20

Folder /Art/Textures/RendererTextures

### Changed
#### Unity
Project version to 2022.03.4f1
Render pipeline to HDRP
Convert all materials to HDRP
Updated packages

Move Rewired to /Third-party/Plugins folder
Updated Rewired to 1.1.45.0 

AmplifyShaderEditor, HBAO to HDRP

#### README.md
Updated title, description, changelog, assets list, project structure

### Removed
Hierarchy 2, Beautify because of the unsupportability
URP quality profiles

---

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