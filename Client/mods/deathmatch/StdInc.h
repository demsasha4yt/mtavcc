#pragma message("Compiling precompiled header.\n")

#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#define MTA_CLIENT
#define SHARED_UTIL_WITH_FAST_HASH_MAP
#include "SharedUtil.h"

#include <string.h>
#include <stdio.h>
#include <mmsystem.h>
#include <winsock.h>

#include <algorithm>
#include <list>
#include <map>
#include <set>
#include <string>
#include <sstream>
#include <vector>
#include <cstdio>
#include <cstring>

#include <zlib.h>

// SDK includes
#include <core/CLocalizationInterface.h>
#include <core/CTrayIconInterface.h>
#include <core/CCoreInterface.h>
#include <core/CExceptionInformation.h>
#include <xml/CXML.h>
#include <xml/CXMLNode.h>
#include <xml/CXMLFile.h>
#include <xml/CXMLAttributes.h>
#include <xml/CXMLAttribute.h>
#include <net/CNet.h>
#include <net/packetenums.h>
#include <game/CGame.h>
#include <CVector.h>
#include <CVector4D.h>
#include <CMatrix4.h>
#include <CSphere.h>
#include <CBox.h>
#include <ijsify.h>
#include <Common.h>
#include "net/Packets.h"
#include "Enums.h"
#include "net/SyncStructures.h"
#include "CIdArray.h"
#include "pcrecpp.h"

// Shared logic includes
#include <Utils.h>
#include <CClientCommon.h>
#include <CClientManager.h>
#include <CClient3DMarker.h>
#include <CClientCheckpoint.h>
#include <CClientColShape.h>
#include <CClientColCircle.h>
#include <CClientColCuboid.h>
#include <CClientColSphere.h>
#include <CClientColRectangle.h>
#include <CClientColPolygon.h>
#include <CClientColTube.h>
#include <CClientCorona.h>
#include <CClientDFF.h>
#include <CClientDummy.h>
#include <CClientEntity.h>
#include <CClientSpatialDatabase.h>
#include <CClientExplosionManager.h>
#include <CClientPed.h>
#include <CClientPlayerClothes.h>
#include <CClientPlayerVoice.h>
#include <CClientPointLights.h>
#include <CClientProjectileManager.h>
#include <CClientStreamSector.h>
#include <CClientStreamSectorRow.h>
#include <CClientTask.h>
#include <CClientTXD.h>
#include <CClientIFP.h>
#include <CClientWater.h>
#include <CClientWeapon.h>
#include <CClientRenderElement.h>
#include <CClientDxFont.h>
#include <CClientGuiFont.h>
#include <CClientMaterial.h>
#include <CClientTexture.h>
#include <CClientShader.h>
#include <CClientWebBrowser.h>
#include <CClientSearchLight.h>
#include <CClientEffect.h>
#include <CCustomData.h>
#include <CElementArray.h>
#include <CLogger.h>
#include <CMapEventManager.h>
#include <CModelNames.h>
#include <CIFPEngine.h>
#include <CFileReader.h>
#include <CIFPAnimations.h>
#include <CScriptFile.h>
#include <CWeaponNames.h>
#include <CVehicleNames.h>
#include <lua/CLuaCFunctions.h>
#include <lua/CLuaArguments.h>
#include <lua/CLuaMain.h>
#include "CEasingCurve.h"
#include <lua/CLuaFunctionParseHelpers.h>
#include <CScriptArgReader.h>
#include <luadefs/CLuaDefs.h>
#include <luadefs/CLuaAudioDefs.h>
#include <luadefs/CLuaBitDefs.h>
#include <luadefs/CLuaBlipDefs.h>
#include <luadefs/CLuaBrowserDefs.h>
#include <luadefs/CLuaClassDefs.h>
#include <luadefs/CLuaCameraDefs.h>
#include <luadefs/CLuaColShapeDefs.h>
#include <luadefs/CLuaDrawingDefs.h>
#include <luadefs/CLuaEffectDefs.h>
#include <luadefs/CLuaElementDefs.h>
#include <luadefs/CLuaEngineDefs.h>
#include <luadefs/CLuaGUIDefs.h>
#include <luadefs/CLuaMarkerDefs.h>
#include <luadefs/CLuaObjectDefs.h>
#include <luadefs/CLuaPointLightDefs.h>
#include <luadefs/CLuaPedDefs.h>
#include <luadefs/CLuaPickupDefs.h>
#include <luadefs/CLuaPlayerDefs.h>
#include <luadefs/CLuaProjectileDefs.h>
#include <luadefs/CLuaRadarAreaDefs.h>
#include <luadefs/CLuaResourceDefs.h>
#include <luadefs/CLuaSearchLightDefs.h>
#include <luadefs/CLuaTaskDefs.h>
#include <luadefs/CLuaTeamDefs.h>
#include <luadefs/CLuaTimerDefs.h>
#include <luadefs/CLuaVehicleDefs.h>
#include <luadefs/CLuaWaterDefs.h>
#include <luadefs/CLuaWeaponDefs.h>
#include <CRemoteCalls.h>

// Shared includes
#include "TInterpolation.h"
#include "CPositionRotationAnimation.h"
#include "CLatentTransferManager.h"
#include "CDebugHookManager.h"
#include "lua/CLuaShared.h"

// Deathmatch includes
#include "ClientCommands.h"
#include "CClient.h"
#include "CEvents.h"
#include "HeapTrace.h"
#include "logic/CClientGame.h"
#include "logic/CClientModelCacheManager.h"
#include "logic/CClientPerfStatManager.h"
#include "logic/CDeathmatchVehicle.h"
#include "logic/CResource.h"
#include "logic/CStaticFunctionDefinitions.h"
#include "logic/CResourceFileDownloadManager.h"
#include "../../version.h"

// Bharrold deathmatch includes

