//Oh lord, where do we even begin? TL:DR, setting sequences via sourcemod/server is inconsistent as hell, so we are just swapping to a model that has the animation file as sequence 0 (ref/idle, whatever.)
//Right now, this is likely only going to be used with server exclusive bosses that are not available in this public version, I think that ancient FF2 did it like that, too

#define TEMP_MODEL_ANIM_MAX_DURATION	15.0	//Timeout

static char g_sTempModel[MAXPLAYERS + 1][PLATFORM_MAX_PATH];		//Currently active temp model, empty if none
static char g_sTempModelReturn[MAXPLAYERS + 1][PLATFORM_MAX_PATH];	//Model to revert to once duration ends
static float g_flTempModelEndTime[MAXPLAYERS + 1];					//GetGameTime() when temp model ends, 0.0 for no duration

static bool g_bTempModelAnim[MAXPLAYERS + 1];
static bool g_bTempModelSelfAnimating[MAXPLAYERS + 1];	//Current temp model self animates
static bool g_bTempModelAnimFreeze[MAXPLAYERS + 1];		//The animation freezes the player
static bool g_bTempModelAnimAllowLook[MAXPLAYERS + 1];	//Frozen player can still move the camera 
static float g_flTempModelAnimEndTime[MAXPLAYERS + 1];

void TempModel_AskLoad()
{
	CreateNative("SaxtonHaleBase.SetTempModelName", TempModel_NativeSetTempModelName);
	CreateNative("SaxtonHaleBase.SetModelWithAnimation", TempModel_NativeSetModelWithAnimation);
	CreateNative("SaxtonHaleBase.bModelAnimationActive.get", TempModel_NativeGetAnimationActive);
}

public any TempModel_NativeGetAnimationActive(Handle hPlugin, int iNumParams)
{
	return g_bTempModelAnim[GetNativeCell(1)];
}

public any TempModel_NativeSetTempModelName(Handle hPlugin, int iNumParams)
{
	int iClient = GetNativeCell(1);
	if (iClient <= 0 || iClient > MaxClients)
		ThrowNativeError(SP_ERROR_NATIVE, "Client index %d is invalid", iClient);
	if (!IsClientInGame(iClient))
		ThrowNativeError(SP_ERROR_NATIVE, "Client %d is not in game", iClient);
	if (!IsPlayerAlive(iClient))
		ThrowNativeError(SP_ERROR_NATIVE, "Client %d is not alive", iClient);

	GetNativeString(2, g_sTempModel[iClient], sizeof(g_sTempModel[]));
	GetNativeString(3, g_sTempModelReturn[iClient], sizeof(g_sTempModelReturn[]));

	float flDurationSec = GetNativeCell(4);
	g_flTempModelEndTime[iClient] = (flDurationSec > 0.0) ? GetGameTime() + flDurationSec : 0.0;

	g_bTempModelSelfAnimating[iClient] = (iNumParams >= 5) ? view_as<bool>(GetNativeCell(5)) : false;

	//Apply it now, ApplyBossModel keeps reapplying it until it ends
	TempModel_ApplyModel(iClient, g_sTempModel[iClient], !g_bTempModelSelfAnimating[iClient]);
	return 0;
}

//Swap to a model with an animation as sequence 0, so it automatically plays on the swap, perfect sync yo
public any TempModel_NativeSetModelWithAnimation(Handle hPlugin, int iNumParams)
{
	int iClient = GetNativeCell(1);
	if (iClient <= 0 || iClient > MaxClients)
		ThrowNativeError(SP_ERROR_NATIVE, "Client index %d is invalid", iClient);
	if (!IsClientInGame(iClient))
		ThrowNativeError(SP_ERROR_NATIVE, "Client %d is not in game", iClient);
	if (!IsPlayerAlive(iClient))
		ThrowNativeError(SP_ERROR_NATIVE, "Client %d is not alive", iClient);

	char sModel[PLATFORM_MAX_PATH], sModelReturn[PLATFORM_MAX_PATH];
	GetNativeString(2, sModel, sizeof(sModel));
	GetNativeString(3, sModelReturn, sizeof(sModelReturn));

	float flDurationSec = GetNativeCell(4);
	if (flDurationSec <= 0.0 || flDurationSec > TEMP_MODEL_ANIM_MAX_DURATION)
		flDurationSec = TEMP_MODEL_ANIM_MAX_DURATION;

	//Apply first: on a missing model file nothing is stored, so any cutscene already
	//running (or the plain boss model) keeps running untouched
	if (!TempModel_ApplyModel(iClient, sModel, false))
		return false;

	strcopy(g_sTempModel[iClient], sizeof(g_sTempModel[]), sModel);
	strcopy(g_sTempModelReturn[iClient], sizeof(g_sTempModelReturn[]), sModelReturn);
	g_flTempModelEndTime[iClient] = GetGameTime() + flDurationSec;
	g_bTempModelSelfAnimating[iClient] = true;

	bool bFreeze = (iNumParams >= 5) ? view_as<bool>(GetNativeCell(5)) : true;
	bool bLockLook = (iNumParams >= 6) ? view_as<bool>(GetNativeCell(6)) : false;
	bool bWasFrozen = g_bTempModelAnimFreeze[iClient];
	bool bWasLookLocked = bWasFrozen && !g_bTempModelAnimAllowLook[iClient];
	g_bTempModelAnimFreeze[iClient] = bFreeze;
	g_bTempModelAnimAllowLook[iClient] = bFreeze && !bLockLook;

	if (bFreeze)
	{
		SetEntityMoveType(iClient, MOVETYPE_NONE);

		//Kill leftover velocity, so the boss dont drift while frozen
		float vecVelocity[3];
		vecVelocity[0] = 0.0;
		vecVelocity[1] = 0.0;
		vecVelocity[2] = 0.0;
		TeleportEntity(iClient, NULL_VECTOR, NULL_VECTOR, vecVelocity);

		//If looking is allowed, don't freeze
		if (bLockLook)
			TF2_AddCondition(iClient, TFCond_FreezeInput, flDurationSec);

		SetEntProp(iClient, Prop_Send, "m_nForceTauntCam", 1);
	}
	else if (bWasFrozen)
	{
		SetEntityMoveType(iClient, MOVETYPE_WALK);
		if (bWasLookLocked)
			TF2_RemoveCondition(iClient, TFCond_FreezeInput);
	}

	g_bTempModelAnim[iClient] = true;
	g_flTempModelAnimEndTime[iClient] = GetGameTime() + flDurationSec;

	return true;
}

void TempModel_OnThink(int iClient)
{
	// Initially, left it in there because the clearing of the models was being tested, but, now with it being reset on class spawn it should work just fine. Right? At least I didnt notice any issues.
	// if (!IsClientInGame(iClient) || !IsPlayerAlive(iClient))
	// {
	// 	TempModel_ForceClear(iClient);
	// 	return;
	// }

	//Temp model duration ended, revert it
	if (g_sTempModel[iClient][0] != '\0' && g_flTempModelEndTime[iClient] != 0.0 && g_flTempModelEndTime[iClient] <= GetGameTime())
		TempModel_EndModel(iClient);

	if (!g_bTempModelAnim[iClient])
		return;

	//Keep player frozen and in third person while the animation plays
	if (g_bTempModelAnimFreeze[iClient])
	{
		SetEntityMoveType(iClient, MOVETYPE_NONE);
		if (!g_bTempModelAnimAllowLook[iClient])
			TF2_AddCondition(iClient, TFCond_FreezeInput, 0.2);
		SetEntProp(iClient, Prop_Send, "m_nForceTauntCam", 1);
	}

	//Animation ends when its duration runs out
	if (GetGameTime() >= g_flTempModelAnimEndTime[iClient])
		TempModel_EndAnimation(iClient);
}

//Returns true while a SetModelWithAnimation animation is playing on client (input blocked,
//optionally frozen in third person)
bool TempModel_IsAnimationActive(int iClient)
{
	return g_bTempModelAnim[iClient];
}

//Returns true while the active temp model is a self animating model (class anims off,
//animation plays from the model swap itself)
bool TempModel_IsSelfAnimating(int iClient)
{
	return g_bTempModelSelfAnimating[iClient];
}

//Returns true if client currently have a temp model, and fills sModel with it
bool TempModel_GetActiveModel(int iClient, char[] sModel, int iLength)
{
	if (g_sTempModel[iClient][0] == '\0')
		return false;

	//Temp model expired, revert it now instead of returning the expired model
	if (g_flTempModelEndTime[iClient] != 0.0 && g_flTempModelEndTime[iClient] <= GetGameTime())
	{
		TempModel_EndModel(iClient);
		return false;
	}

	strcopy(sModel, iLength, g_sTempModel[iClient]);
	return true;
}

static bool TempModel_ApplyModel(int iClient, const char[] sModel, bool bClassAnimations)
{
	if (!FileExists(sModel, true))
	{
		LogError("TempModel: model \"%s\" not found on server, skipping the swap for client %d", sModel, iClient);
		return false;
	}

	//Only reset the model when it actually changed: re-setting the same model would restart
	//a self animating cutscene from its first frame on every reapply
	char sCurrentModel[PLATFORM_MAX_PATH];
	GetEntPropString(iClient, Prop_Data, "m_ModelName", sCurrentModel, sizeof(sCurrentModel));
	if (StrEqual(sCurrentModel, sModel))
	{
		SetEntProp(iClient, Prop_Send, "m_bUseClassAnimations", bClassAnimations);
		return true;
	}

	PrecacheModel(sModel);
	SetVariantString(sModel);
	AcceptEntityInput(iClient, "SetCustomModel");
	SetEntProp(iClient, Prop_Send, "m_bUseClassAnimations", bClassAnimations);

	if (!bClassAnimations)
	{
		//If the model is not a class model, i.e the model with sequence 0 as the animation, don't use class anims. No reason to.
		SetEntProp(iClient, Prop_Send, "m_nSequence", 0);
		SetEntPropFloat(iClient, Prop_Send, "m_flCycle", 0.0);
	}
	return true;
}

static void TempModel_EndModel(int iClient)
{
	if (IsClientInGame(iClient) && IsPlayerAlive(iClient))
	{
		if (StrEmpty(g_sTempModelReturn[iClient]))
		{
			//No return model given, remove custom model
			SetVariantString("");
			AcceptEntityInput(iClient, "SetCustomModel");
		}
			else
				TempModel_ApplyModel(iClient, g_sTempModelReturn[iClient], true);	//Return model is class anim driven again
	}

	TempModel_Clear(iClient);
}

void TempModel_Clear(int iClient)
{
	TempModel_EndAnimation(iClient);

	g_bTempModelSelfAnimating[iClient] = false;
	g_sTempModel[iClient][0] = '\0';
	g_sTempModelReturn[iClient][0] = '\0';
	g_flTempModelEndTime[iClient] = 0.0;
}

//Removes the temp model from client, reverting them to their default class model
static void TempModel_RemoveModel(int iClient)
{
	if (IsClientInGame(iClient))
	{
		SetVariantString("");
		AcceptEntityInput(iClient, "SetCustomModel");
		SetEntProp(iClient, Prop_Send, "m_bUseClassAnimations", false);
	}
}

//Remove the model, unfreeze and clear all state.
//Usually on round start so boss with a temporary model won't 'bleed' over into the red team the round start
void TempModel_ForceClear(int iClient)
{
	TempModel_RemoveModel(iClient);
	TempModel_Clear(iClient);
}

//Self explanatory
static void TempModel_EndAnimation(int iClient)
{
	if (!g_bTempModelAnim[iClient])
		return;

	g_bTempModelAnim[iClient] = false;

	if (IsClientInGame(iClient) && g_bTempModelAnimFreeze[iClient])
	{
		SetEntityMoveType(iClient, MOVETYPE_WALK);
		if (!g_bTempModelAnimAllowLook[iClient])
			TF2_RemoveCondition(iClient, TFCond_FreezeInput);
		SetEntProp(iClient, Prop_Send, "m_nForceTauntCam", 0);
	}

	g_bTempModelAnimFreeze[iClient] = false;
	g_bTempModelAnimAllowLook[iClient] = false;
}
