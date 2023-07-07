//Amplify Shader Pack
//Copyright( c) Amplify Creations, Lda <info @amplify.pt>

using System;
using UnityEngine;
using UnityEditor;
using UnityEditor.PackageManager.Requests;
using System.Collections.Generic;
using System.Reflection;
namespace AmplifyShaderPack
{
	public enum ASPSRPVersions
	{
		ASP_SRP_7_0_1 = 070001,
		ASP_SRP_7_1_1 = 070101,
		ASP_SRP_7_1_2 = 070102,
		ASP_SRP_7_1_5 = 070105,
		ASP_SRP_7_1_6 = 070106,
		ASP_SRP_7_1_7 = 070107,
		ASP_SRP_7_1_8 = 070108,
		ASP_SRP_7_2_0 = 070200,
		ASP_SRP_7_2_1 = 070201,
		ASP_SRP_7_3_1 = 070301,
		ASP_SRP_7_4_1 = 070401,
		ASP_SRP_7_4_2 = 070402,
		ASP_SRP_7_4_3 = 070403,
		ASP_SRP_7_5_1 = 070501,
		ASP_SRP_7_5_2 = 070502,
		ASP_SRP_7_5_3 = 070503,
		ASP_SRP_7_6_0 = 070600,
		ASP_SRP_7_7_1 = 070701,
		ASP_SRP_8_2_0 = 080200,
		ASP_SRP_8_3_1 = 080301,
		ASP_SRP_9_0_0 = 090000,
		ASP_SRP_10_0_0 = 100000,
		ASP_SRP_10_1_0 = 100100,
		ASP_SRP_10_2_2 = 100202,
		ASP_SRP_10_3_1 = 100301,
		ASP_SRP_10_3_2 = 100302,
		ASP_SRP_10_4_0 = 100400,
		ASP_SRP_10_5_0 = 100500,
		ASP_SRP_10_5_1 = 100501,
		ASP_SRP_10_6_0 = 100600,
		ASP_SRP_11_0_0 = 110000,
		ASP_SRP_12_0_0 = 120000,
		ASP_SRP_12_1_0 = 120100,
		ASP_SRP_12_1_1 = 120101,
		ASP_SRP_12_1_2 = 120102,
		ASP_SRP_RECENT = 999999
	}

	public enum ASPImportType
	{
		None,
		URP,
		HDRP,
		BiRP
	}

	public enum ASPRequestStatus
	{
		Success,
		Failed_Import_Running,
		Failed_Editor_Is_Playing
	}

	public static class AssetDatabaseEX
	{
		private static System.Type type = null;
		public static System.Type Type { get { return ( type == null ) ? type = System.Type.GetType( "UnityEditor.AssetDatabase, UnityEditor" ) : type; } }

		public static void ImportPackageImmediately( string packagePath )
		{
			AssetDatabaseEX.Type.InvokeMember( "ImportPackageImmediately" , BindingFlags.Static | BindingFlags.NonPublic | BindingFlags.InvokeMethod , null , null , new object[] { packagePath } );
		}
	}

	[Serializable]
	public static class ASPPackageManagerHelper
	{
		private static ASPImportType m_importingPackage = ASPImportType.None;
		private static int m_importPackageIndex = 0;
		private static ASPSRPVersions m_importVersion = ASPSRPVersions.ASP_SRP_RECENT;

		private static readonly string BiRPSamplesGUID = "cc34b441a892177478d7932a061167f7";

		private static Dictionary<string , ASPSRPVersions> m_srpVersionConverter = new Dictionary<string , ASPSRPVersions>()
		{
			{"7.0.1",               ASPSRPVersions.ASP_SRP_7_0_1},
			{"7.0.1-preview",       ASPSRPVersions.ASP_SRP_7_0_1},
			{"7.1.1",               ASPSRPVersions.ASP_SRP_7_1_1},
			{"7.1.1-preview",       ASPSRPVersions.ASP_SRP_7_1_1},
			{"7.1.2",               ASPSRPVersions.ASP_SRP_7_1_2},
			{"7.1.2-preview",       ASPSRPVersions.ASP_SRP_7_1_2},
			{"7.1.5",               ASPSRPVersions.ASP_SRP_7_1_5},
			{"7.1.5-preview",       ASPSRPVersions.ASP_SRP_7_1_5},
			{"7.1.6",               ASPSRPVersions.ASP_SRP_7_1_6},
			{"7.1.6-preview",       ASPSRPVersions.ASP_SRP_7_1_6},
			{"7.1.7",               ASPSRPVersions.ASP_SRP_7_1_7},
			{"7.1.7-preview",       ASPSRPVersions.ASP_SRP_7_1_7},
			{"7.1.8",               ASPSRPVersions.ASP_SRP_7_1_8},
			{"7.1.8-preview",       ASPSRPVersions.ASP_SRP_7_1_8},
			{"7.2.0",               ASPSRPVersions.ASP_SRP_7_2_0},
			{"7.2.0-preview",       ASPSRPVersions.ASP_SRP_7_2_0},
			{"7.2.1",               ASPSRPVersions.ASP_SRP_7_2_1},
			{"7.2.1-preview",       ASPSRPVersions.ASP_SRP_7_2_1},
			{"7.3.1",               ASPSRPVersions.ASP_SRP_7_3_1},
			{"7.3.1-preview",       ASPSRPVersions.ASP_SRP_7_3_1},
			{"7.4.1",               ASPSRPVersions.ASP_SRP_7_4_1},
			{"7.4.1-preview",       ASPSRPVersions.ASP_SRP_7_4_1},
			{"7.4.2",               ASPSRPVersions.ASP_SRP_7_4_2},
			{"7.4.2-preview",       ASPSRPVersions.ASP_SRP_7_4_2},
			{"7.4.3",               ASPSRPVersions.ASP_SRP_7_4_3},
			{"7.4.3-preview",       ASPSRPVersions.ASP_SRP_7_4_3},
			{"7.5.1",               ASPSRPVersions.ASP_SRP_7_5_1},
			{"7.5.1-preview",       ASPSRPVersions.ASP_SRP_7_5_1},
			{"7.5.2",               ASPSRPVersions.ASP_SRP_7_5_2},
			{"7.5.2-preview",       ASPSRPVersions.ASP_SRP_7_5_2},
			{"7.5.3",               ASPSRPVersions.ASP_SRP_7_5_3},
			{"7.5.3-preview",       ASPSRPVersions.ASP_SRP_7_5_3},
			{"7.6.0",               ASPSRPVersions.ASP_SRP_7_6_0},
			{"7.6.0-preview",       ASPSRPVersions.ASP_SRP_7_6_0},
			{"7.7.1",               ASPSRPVersions.ASP_SRP_7_7_1},
			{"7.7.1-preview",       ASPSRPVersions.ASP_SRP_7_7_1},
			{"8.2.0",               ASPSRPVersions.ASP_SRP_8_2_0},
			{"8.2.0-preview",       ASPSRPVersions.ASP_SRP_8_2_0},
			{"8.3.1",               ASPSRPVersions.ASP_SRP_8_3_1},
			{"8.3.1-preview",       ASPSRPVersions.ASP_SRP_8_3_1},
			{"9.0.0",               ASPSRPVersions.ASP_SRP_9_0_0},
			{"9.0.0-preview.13",    ASPSRPVersions.ASP_SRP_9_0_0},
			{"9.0.0-preview.14",    ASPSRPVersions.ASP_SRP_9_0_0},
			{"9.0.0-preview.33",    ASPSRPVersions.ASP_SRP_9_0_0},
			{"9.0.0-preview.35",    ASPSRPVersions.ASP_SRP_9_0_0},
			{"9.0.0-preview.54",    ASPSRPVersions.ASP_SRP_9_0_0},
			{"9.0.0-preview.55",    ASPSRPVersions.ASP_SRP_9_0_0},
			{"9.0.0-preview.71",    ASPSRPVersions.ASP_SRP_9_0_0},
			{"9.0.0-preview.72",    ASPSRPVersions.ASP_SRP_9_0_0},
			{"10.0.0-preview.26",   ASPSRPVersions.ASP_SRP_10_0_0},
			{"10.0.0-preview.27",   ASPSRPVersions.ASP_SRP_10_0_0},
			{"10.1.0",              ASPSRPVersions.ASP_SRP_10_1_0},
			{"10.2.2",              ASPSRPVersions.ASP_SRP_10_2_2},
			{"10.3.1",              ASPSRPVersions.ASP_SRP_10_3_1},
			{"10.3.2",              ASPSRPVersions.ASP_SRP_10_3_2},
			{"10.4.0",              ASPSRPVersions.ASP_SRP_10_4_0},
			{"10.5.0",              ASPSRPVersions.ASP_SRP_10_5_0},
			{"10.5.1",              ASPSRPVersions.ASP_SRP_10_5_1},
			{"10.6.0",              ASPSRPVersions.ASP_SRP_10_6_0},
			{"11.0.0",              ASPSRPVersions.ASP_SRP_11_0_0},
			{"12.0.0",              ASPSRPVersions.ASP_SRP_12_0_0},
			{"12.1.0",              ASPSRPVersions.ASP_SRP_12_1_0},
			{"12.1.1",              ASPSRPVersions.ASP_SRP_12_1_1},
			{"12.1.2",              ASPSRPVersions.ASP_SRP_12_1_2}
		};

		private static Dictionary<ASPSRPVersions , string[]> m_srpToASEPackageURP = new Dictionary<ASPSRPVersions , string[]>()
		{
			{ASPSRPVersions.ASP_SRP_7_0_1,  new string[]{"a4ba258cacd903245bb6a04777c45689"}},
			{ASPSRPVersions.ASP_SRP_7_1_1,  new string[]{"a4ba258cacd903245bb6a04777c45689"}},
			{ASPSRPVersions.ASP_SRP_7_1_2,  new string[]{"a4ba258cacd903245bb6a04777c45689"}},
			{ASPSRPVersions.ASP_SRP_7_1_5,  new string[]{"a4ba258cacd903245bb6a04777c45689"}},
			{ASPSRPVersions.ASP_SRP_7_1_6,  new string[]{"a4ba258cacd903245bb6a04777c45689"}},
			{ASPSRPVersions.ASP_SRP_7_1_7,  new string[]{"a4ba258cacd903245bb6a04777c45689"}},
			{ASPSRPVersions.ASP_SRP_7_1_8,  new string[]{"a4ba258cacd903245bb6a04777c45689"}},
			{ASPSRPVersions.ASP_SRP_7_2_0,  new string[]{"a4ba258cacd903245bb6a04777c45689"}},
			{ASPSRPVersions.ASP_SRP_7_2_1,  new string[]{"a4ba258cacd903245bb6a04777c45689"}},
			{ASPSRPVersions.ASP_SRP_7_3_1,  new string[]{"a4ba258cacd903245bb6a04777c45689"}},
			{ASPSRPVersions.ASP_SRP_7_4_1,  new string[]{"a4ba258cacd903245bb6a04777c45689"}},
			{ASPSRPVersions.ASP_SRP_7_4_2,  new string[]{"a4ba258cacd903245bb6a04777c45689"}},
			{ASPSRPVersions.ASP_SRP_7_4_3,  new string[]{"a4ba258cacd903245bb6a04777c45689"}},
			{ASPSRPVersions.ASP_SRP_7_5_1,  new string[]{"a4ba258cacd903245bb6a04777c45689"}},
			{ASPSRPVersions.ASP_SRP_7_5_2,  new string[]{"a4ba258cacd903245bb6a04777c45689"}},
			{ASPSRPVersions.ASP_SRP_7_5_3,  new string[]{"a4ba258cacd903245bb6a04777c45689"}},
			{ASPSRPVersions.ASP_SRP_7_6_0,  new string[]{"a4ba258cacd903245bb6a04777c45689"}},
			{ASPSRPVersions.ASP_SRP_7_7_1,  new string[]{"a4ba258cacd903245bb6a04777c45689"}},
			{ASPSRPVersions.ASP_SRP_8_2_0,  new string[]{"a4ba258cacd903245bb6a04777c45689"}},
			{ASPSRPVersions.ASP_SRP_8_3_1,  new string[]{"a4ba258cacd903245bb6a04777c45689"}},
			{ASPSRPVersions.ASP_SRP_9_0_0,  new string[]{"a4ba258cacd903245bb6a04777c45689"}},
			{ASPSRPVersions.ASP_SRP_10_0_0, new string[]{"47222e91b38f7f943a2c717aca57ed58"}},
			{ASPSRPVersions.ASP_SRP_10_1_0, new string[]{"47222e91b38f7f943a2c717aca57ed58"}},
			{ASPSRPVersions.ASP_SRP_10_2_2, new string[]{"47222e91b38f7f943a2c717aca57ed58"}},
			{ASPSRPVersions.ASP_SRP_10_3_1, new string[]{"47222e91b38f7f943a2c717aca57ed58"}},
			{ASPSRPVersions.ASP_SRP_10_3_2, new string[]{"47222e91b38f7f943a2c717aca57ed58"}},
			{ASPSRPVersions.ASP_SRP_10_4_0, new string[]{"47222e91b38f7f943a2c717aca57ed58"}},
			{ASPSRPVersions.ASP_SRP_10_5_0, new string[]{"47222e91b38f7f943a2c717aca57ed58"}},
			{ASPSRPVersions.ASP_SRP_10_5_1, new string[]{"47222e91b38f7f943a2c717aca57ed58"}},
			{ASPSRPVersions.ASP_SRP_10_6_0, new string[]{"47222e91b38f7f943a2c717aca57ed58"}},
			{ASPSRPVersions.ASP_SRP_11_0_0, new string[]{"47222e91b38f7f943a2c717aca57ed58","b8bc3077e81f22247b45a2869df74191"}},
			{ASPSRPVersions.ASP_SRP_12_0_0, new string[]{"47222e91b38f7f943a2c717aca57ed58","b8bc3077e81f22247b45a2869df74191"}},
			{ASPSRPVersions.ASP_SRP_12_1_0, new string[]{"47222e91b38f7f943a2c717aca57ed58","b8bc3077e81f22247b45a2869df74191"}},
			{ASPSRPVersions.ASP_SRP_12_1_1, new string[]{"47222e91b38f7f943a2c717aca57ed58","b8bc3077e81f22247b45a2869df74191"}},
			{ASPSRPVersions.ASP_SRP_12_1_2, new string[]{"47222e91b38f7f943a2c717aca57ed58","b8bc3077e81f22247b45a2869df74191"}},
			{ASPSRPVersions.ASP_SRP_RECENT, new string[]{"47222e91b38f7f943a2c717aca57ed58","b8bc3077e81f22247b45a2869df74191"}}
		};

		private static Dictionary<ASPSRPVersions , string[]> m_srpToASEPackageHDRP = new Dictionary<ASPSRPVersions , string[]>()
		{
			{ASPSRPVersions.ASP_SRP_7_0_1,  new string[]{"abf8c3e18e883894aa7a5cf7dc6a5408"}},
			{ASPSRPVersions.ASP_SRP_7_1_1,  new string[]{"abf8c3e18e883894aa7a5cf7dc6a5408"}},
			{ASPSRPVersions.ASP_SRP_7_1_2,  new string[]{"abf8c3e18e883894aa7a5cf7dc6a5408"}},
			{ASPSRPVersions.ASP_SRP_7_1_5,  new string[]{"abf8c3e18e883894aa7a5cf7dc6a5408"}},
			{ASPSRPVersions.ASP_SRP_7_1_6,  new string[]{"abf8c3e18e883894aa7a5cf7dc6a5408"}},
			{ASPSRPVersions.ASP_SRP_7_1_7,  new string[]{"abf8c3e18e883894aa7a5cf7dc6a5408"}},
			{ASPSRPVersions.ASP_SRP_7_1_8,  new string[]{"abf8c3e18e883894aa7a5cf7dc6a5408"}},
			{ASPSRPVersions.ASP_SRP_7_2_0,  new string[]{"abf8c3e18e883894aa7a5cf7dc6a5408"}},
			{ASPSRPVersions.ASP_SRP_7_2_1,  new string[]{"abf8c3e18e883894aa7a5cf7dc6a5408"}},
			{ASPSRPVersions.ASP_SRP_7_3_1,  new string[]{"abf8c3e18e883894aa7a5cf7dc6a5408"}},
			{ASPSRPVersions.ASP_SRP_7_4_1,  new string[]{"abf8c3e18e883894aa7a5cf7dc6a5408"}},
			{ASPSRPVersions.ASP_SRP_7_4_2,  new string[]{"abf8c3e18e883894aa7a5cf7dc6a5408"}},
			{ASPSRPVersions.ASP_SRP_7_4_3,  new string[]{"abf8c3e18e883894aa7a5cf7dc6a5408"}},
			{ASPSRPVersions.ASP_SRP_7_5_1,  new string[]{"abf8c3e18e883894aa7a5cf7dc6a5408"}},
			{ASPSRPVersions.ASP_SRP_7_5_2,  new string[]{"abf8c3e18e883894aa7a5cf7dc6a5408"}},
			{ASPSRPVersions.ASP_SRP_7_5_3,  new string[]{"abf8c3e18e883894aa7a5cf7dc6a5408"}},
			{ASPSRPVersions.ASP_SRP_7_6_0,  new string[]{"abf8c3e18e883894aa7a5cf7dc6a5408"}},
			{ASPSRPVersions.ASP_SRP_7_7_1,  new string[]{"abf8c3e18e883894aa7a5cf7dc6a5408"}},
			{ASPSRPVersions.ASP_SRP_8_2_0,  new string[]{"abf8c3e18e883894aa7a5cf7dc6a5408"}},
			{ASPSRPVersions.ASP_SRP_8_3_1,  new string[]{"abf8c3e18e883894aa7a5cf7dc6a5408"}},
			{ASPSRPVersions.ASP_SRP_9_0_0,  new string[]{"abf8c3e18e883894aa7a5cf7dc6a5408"}},
			{ASPSRPVersions.ASP_SRP_10_0_0, new string[]{"312b55e12eefb9b4aba6ebeb4ad6f35a"}},
			{ASPSRPVersions.ASP_SRP_10_1_0, new string[]{"312b55e12eefb9b4aba6ebeb4ad6f35a"}},
			{ASPSRPVersions.ASP_SRP_10_2_2, new string[]{"312b55e12eefb9b4aba6ebeb4ad6f35a"}},
			{ASPSRPVersions.ASP_SRP_10_3_1, new string[]{"312b55e12eefb9b4aba6ebeb4ad6f35a"}},
			{ASPSRPVersions.ASP_SRP_10_3_2, new string[]{"312b55e12eefb9b4aba6ebeb4ad6f35a"}},
			{ASPSRPVersions.ASP_SRP_10_4_0, new string[]{"312b55e12eefb9b4aba6ebeb4ad6f35a"}},
			{ASPSRPVersions.ASP_SRP_10_5_0, new string[]{"312b55e12eefb9b4aba6ebeb4ad6f35a"}},
			{ASPSRPVersions.ASP_SRP_10_5_1, new string[]{"312b55e12eefb9b4aba6ebeb4ad6f35a"}},
			{ASPSRPVersions.ASP_SRP_10_6_0, new string[]{"312b55e12eefb9b4aba6ebeb4ad6f35a"}},
			{ASPSRPVersions.ASP_SRP_11_0_0, new string[]{"312b55e12eefb9b4aba6ebeb4ad6f35a"}},
			{ASPSRPVersions.ASP_SRP_12_0_0, new string[]{"312b55e12eefb9b4aba6ebeb4ad6f35a"}},
			{ASPSRPVersions.ASP_SRP_12_1_0, new string[]{"312b55e12eefb9b4aba6ebeb4ad6f35a"}},
			{ASPSRPVersions.ASP_SRP_12_1_1, new string[]{"312b55e12eefb9b4aba6ebeb4ad6f35a"}},
			{ASPSRPVersions.ASP_SRP_12_1_2, new string[]{"312b55e12eefb9b4aba6ebeb4ad6f35a"}},
			{ASPSRPVersions.ASP_SRP_RECENT, new string[]{"312b55e12eefb9b4aba6ebeb4ad6f35a"}}

		};


		static void FailedPackageImport( string packageName , string errorMessage )
		{
			FinishImporter();
		}

		static void CancelledPackageImport( string packageName )
		{
			FinishImporter();
		}

		static void CompletedPackageImport( string packageName )
		{
			FinishImporter();
		}

		public static ASPRequestStatus ImportPackage( ASPSRPVersions version, ASPImportType rpType )
		{
			if( Application.isPlaying )
				return ASPRequestStatus.Failed_Editor_Is_Playing;

			if( m_importingPackage != ASPImportType.None )
				return ASPRequestStatus.Failed_Import_Running;

			if( rpType == ASPImportType.BiRP )
			{
				AssetDatabase.ImportPackage( AssetDatabase.GUIDToAssetPath( BiRPSamplesGUID ) , false );
			}
			else
			{
				m_importingPackage = rpType;
				m_importPackageIndex = 0;
				m_importVersion = version;
				string packagePath =	(rpType == ASPImportType.URP) ?
										AssetDatabase.GUIDToAssetPath( m_srpToASEPackageURP[ m_importVersion ][ m_importPackageIndex ] ):
										AssetDatabase.GUIDToAssetPath( m_srpToASEPackageHDRP[ m_importVersion ][ m_importPackageIndex ] );
				StartImporting( packagePath );
			}

			return ASPRequestStatus.Success;
		}

		private static void StartImporting( string packagePath )
		{
			AssetDatabase.importPackageCancelled += CancelledPackageImport;
			AssetDatabase.importPackageCompleted += CompletedPackageImport;
			AssetDatabase.importPackageFailed += FailedPackageImport;
			AssetDatabase.ImportPackage( packagePath , false );
		}

		public static void FinishImporter()
		{
			m_importPackageIndex += 1;
			string[] srpPackageList = ( m_importingPackage == ASPImportType.URP ) ?
										m_srpToASEPackageURP[ m_importVersion ]:
										m_srpToASEPackageHDRP[ m_importVersion ];

			if( m_importPackageIndex < srpPackageList.Length )
			{
				string packagePath = AssetDatabase.GUIDToAssetPath( srpPackageList[ m_importPackageIndex ] );
				AssetDatabase.ImportPackage( packagePath , false );
			}
			else
			{
				m_importingPackage = ASPImportType.None;
				AssetDatabase.importPackageCancelled -= CancelledPackageImport;
				AssetDatabase.importPackageCompleted -= CompletedPackageImport;
				AssetDatabase.importPackageFailed -= FailedPackageImport;
			}
		}

		public static ASPSRPVersions GetVersionFromString( string key )
		{
			ASPSRPVersions value = ASPSRPVersions.ASP_SRP_RECENT;
			if( m_srpVersionConverter.ContainsKey( key ) )
				value = m_srpVersionConverter[ key ];

			return value;
		}
	}
}
