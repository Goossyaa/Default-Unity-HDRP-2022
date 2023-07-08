// Amplify Shader Pack
// Copyright (c) Amplify Creations, Lda <info@amplify.pt>

using UnityEditor;
using UnityEngine;
using System;
using System.Collections;
using UnityEngine.Networking;

namespace AmplifyShaderPack
{
	[InitializeOnLoad]
	public class ASPStartup
	{
		static ASPStartup()
		{
			EditorApplication.update += Update;
		}

		static void Update()
		{
			EditorApplication.update -= Update;

			if( !EditorApplication.isPlayingOrWillChangePlaymode )
			{
				ASPPreferences.ShowOption show = ASPPreferences.ShowOption.Never;
				if( !EditorPrefs.HasKey( ASPPreferences.PrefStartUp ) )
				{
					show = ASPPreferences.ShowOption.Always;
					EditorPrefs.SetInt( ASPPreferences.PrefStartUp , 0 );
				}
				else
				{
					if( Time.realtimeSinceStartup < 10 )
					{
						show = (ASPPreferences.ShowOption)EditorPrefs.GetInt( ASPPreferences.PrefStartUp , 0 );
						// check version here
						if( show == ASPPreferences.ShowOption.OnNewVersion )
						{
							ASPStartScreen.StartBackgroundTask( StartRequest( ASPStartScreen.ChangelogURL , () =>
							{
								var changeLog = ChangeLogInfo.CreateFromJSON( www.downloadHandler.text );
								if( changeLog != null )
								{
									if( changeLog.Version > VersionInfo.FullNumber )
										ASPStartScreen.Init();
								}
							} ) );
						}
					}
				}

				if( show == ASPPreferences.ShowOption.Always )
					ASPStartScreen.Init();
			}
		}

		static UnityWebRequest www;

		static IEnumerator StartRequest( string url , Action success = null )
		{
			using( www = UnityWebRequest.Get( url ) )
			{
#if UNITY_2017_2_OR_NEWER
				yield return www.SendWebRequest();
#else
				yield return www.Send();
#endif

				while( www.isDone == false )
					yield return null;

				if( success != null )
					success();
			}
		}

	}
}
