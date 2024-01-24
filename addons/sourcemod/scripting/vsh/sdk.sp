static Handle g_hHookGetCaptureValueForPlayer;
static Handle g_hHookGetMaxHealth;
static Handle g_hHookShouldTransmit;
static Handle g_hHookGiveNamedItem;
static Handle g_hHookBallImpact;
static Handle g_hHookShouldBallTouch;
static Handle g_hSDKGetMaxHealth;
static Handle g_hSDKSendWeaponAnim;
static Handle g_hSDKPlaySpecificSequence;
static Handle g_hSDKGetMaxClip;
static Handle g_hSDKRemoveWearable;
static Handle g_hSDKGetEquippedWearable;
static Handle g_hSDKEquipWearable;
static Handle g_hSDKAddObject;
static Handle g_hSDKRemoveObject;
static Handle g_hSDKTossJarThink;

int g_iOffsetFuseTime = -1;

static int g_iHookIdGiveNamedItem[MAXPLAYERS];

void SDK_Init()
{
	GameData hGameData = new GameData("sdkhooks.games");
	if (hGameData == null)
		SetFailState("Could not find sdkhooks.games gamedata!");

	//This function is used to control player's max health
	int iOffset = hGameData.GetOffset("GetMaxHealth");
	g_hHookGetMaxHealth = DHookCreate(iOffset, HookType_Entity, ReturnType_Int, ThisPointer_CBaseEntity, Hook_GetMaxHealth);
	if (g_hHookGetMaxHealth == null)
		LogMessage("Failed to create hook: CTFPlayer::GetMaxHealth!");

	//This function is used to retreive player's max health
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGameData, SDKConf_Virtual, "GetMaxHealth");
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	g_hSDKGetMaxHealth = EndPrepSDKCall();
	if (g_hSDKGetMaxHealth == null)
		LogMessage("Failed to create call: CTFPlayer::GetMaxHealth!");

	delete hGameData;

	hGameData = new GameData("sm-tf2.games");
	if (hGameData == null)
		SetFailState("Could not find sm-tf2.games gamedata!");

	int iRemoveWearableOffset = hGameData.GetOffset("RemoveWearable");

	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetVirtual(iRemoveWearableOffset);
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	g_hSDKRemoveWearable = EndPrepSDKCall();
	if (g_hSDKRemoveWearable == null)
		LogMessage("Failed to create call: CBasePlayer::RemoveWearable!");

	// This call allows us to equip a wearable
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetVirtual(iRemoveWearableOffset-1);//In theory the virtual function for EquipWearable is rigth before RemoveWearable,
													//if it's always true (valve don't put a new function between these two), then we can use SM auto update offset for RemoveWearable and find EquipWearable from it
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	g_hSDKEquipWearable = EndPrepSDKCall();
	if(g_hSDKEquipWearable == null)
		LogMessage("Failed to create call: CBasePlayer::EquipWearable!");

	delete hGameData;

	hGameData = new GameData("vsh");
	if (hGameData == null) SetFailState("Could not find vsh gamedata!");
	
	// This hook allows to change capture rate
	iOffset = hGameData.GetOffset("CTFGameRules::GetCaptureValueForPlayer");
	g_hHookGetCaptureValueForPlayer = DHookCreate(iOffset, HookType_GameRules, ReturnType_Int, ThisPointer_Ignore);
	if (g_hHookGetCaptureValueForPlayer == null)
		LogMessage("Failed to create hook: CTFGameRules::GetCaptureValueForPlayer");
	else
		DHookAddParam(g_hHookGetCaptureValueForPlayer, HookParamType_CBaseEntity);

	// This call gets wearable equipped in loadout slots
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTFPlayer::GetEquippedWearableForLoadoutSlot");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
	g_hSDKGetEquippedWearable = EndPrepSDKCall();
	if (g_hSDKGetEquippedWearable == null)
		LogMessage("Failed to create call: CTFPlayer::GetEquippedWearableForLoadoutSlot!");
	
	//This function is used to play the blocked knife animation
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(hGameData, SDKConf_Virtual, "CTFWeaponBase::SendWeaponAnim");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	g_hSDKSendWeaponAnim = EndPrepSDKCall();
	if (g_hSDKSendWeaponAnim == null)
		LogMessage("Failed to create call: CTFWeaponBase::SendWeaponAnim!");
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTFPlayer::PlaySpecificSequence");
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
	g_hSDKPlaySpecificSequence = EndPrepSDKCall();
	if (g_hSDKPlaySpecificSequence == null)
		LogMessage("Failed to create call: CTFPlayer::PlaySpecificSequence!");
	
	// This call gets the maximum clip 1 for a given weapon
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(hGameData, SDKConf_Virtual, "CTFWeaponBase::GetMaxClip1");
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	g_hSDKGetMaxClip = EndPrepSDKCall();
	if (g_hSDKGetMaxClip == null)
		LogMessage("Failed to create call: CTFWeaponBase::GetMaxClip1!");
	
	//This call is used to give an owner to a building
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTFPlayer::AddObject");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	g_hSDKAddObject = EndPrepSDKCall();
	if (g_hSDKAddObject == null)
		LogMessage("Failed to create call: CTFPlayer::AddObject!");

	//This call is used to remove a building's owner
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTFPlayer::RemoveObject");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	g_hSDKRemoveObject = EndPrepSDKCall();
	if (g_hSDKRemoveObject == null)
		LogMessage("Failed to create call: CTFPlayer::RemoveObject!");
	
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(hGameData, SDKConf_Virtual, "CTFJar::TossJarThink");
	g_hSDKTossJarThink = EndPrepSDKCall();
	if (!g_hSDKTossJarThink)
		LogError("Failed to create call: CTFJar::TossJarThink!");
	
	// This hook allows entity to always transmit
	iOffset = hGameData.GetOffset("CBaseEntity::ShouldTransmit");
	g_hHookShouldTransmit = DHookCreate(iOffset, HookType_Entity, ReturnType_Int, ThisPointer_CBaseEntity, Hook_EntityShouldTransmit);
	if (g_hHookShouldTransmit == null)
		LogMessage("Failed to create hook: CBaseEntity::ShouldTransmit!");
	else
		DHookAddParam(g_hHookShouldTransmit, HookParamType_ObjectPtr);
	
	iOffset = hGameData.GetOffset("CTFPlayer::GiveNamedItem");
	g_hHookGiveNamedItem = DHookCreate(iOffset, HookType_Entity, ReturnType_CBaseEntity, ThisPointer_CBaseEntity);
	if (g_hHookGiveNamedItem == null)
	{
		LogMessage("Failed to create hook: CTFPlayer::GiveNamedItem!");
	}
	else
	{
		DHookAddParam(g_hHookGiveNamedItem, HookParamType_CharPtr);
		DHookAddParam(g_hHookGiveNamedItem, HookParamType_Int);
		DHookAddParam(g_hHookGiveNamedItem, HookParamType_ObjectPtr);
		DHookAddParam(g_hHookGiveNamedItem, HookParamType_Bool);
	}
	
	// This hook calls when Sandman Ball stuns a player
	iOffset = hGameData.GetOffset("CTFStunBall::ApplyBallImpactEffectOnVictim");
	g_hHookBallImpact = DHookCreate(iOffset, HookType_Entity, ReturnType_Void, ThisPointer_CBaseEntity);
	if (g_hHookBallImpact == null)
		LogMessage("Failed to create hook: CTFStunBall::ApplyBallImpactEffectOnVictim!");
	else
		DHookAddParam(g_hHookBallImpact, HookParamType_CBaseEntity);
	
	// This hook calls when Sandman Ball want to touch
	iOffset = hGameData.GetOffset("CTFStunBall::ShouldBallTouch");
	g_hHookShouldBallTouch = DHookCreate(iOffset, HookType_Entity, ReturnType_Bool, ThisPointer_CBaseEntity);
	if (g_hHookShouldBallTouch == null)
		LogMessage("Failed to create hook: CTFStunBall::ApplyBallImpactEffectOnVictim!");
	else
		DHookAddParam(g_hHookShouldBallTouch, HookParamType_CBaseEntity);
	
	// This hook allows to allow/block medigun heals
	Handle hHook = DHookCreateFromConf(hGameData, "CWeaponMedigun::AllowedToHealTarget");
	if (hHook == null)
		LogMessage("Failed to create hook: CWeaponMedigun::AllowedToHealTarget!");
	else
		DHookEnableDetour(hHook, true, Hook_AllowedToHealTarget);
	
	delete hHook;
	
	// This hook allows to allow/block dispenser heals
	hHook = DHookCreateFromConf(hGameData, "CObjectDispenser::CouldHealTarget");
	if (hHook == null)
		LogMessage("Failed to create hook: CObjectDispenser::CouldHealTarget!");
	else
		DHookEnableDetour(hHook, true, Hook_CouldHealTarget);
	
	delete hHook;
	delete hGameData;
	
	if (LookupOffset(g_iOffsetFuseTime, "CTFWeaponBaseMerasmusGrenade", "m_hThrower"))
		g_iOffsetFuseTime += 48;
}

static bool LookupOffset(int &iOffset, const char[] sClass, const char[] sProp)
{
	iOffset = FindSendPropInfo(sClass, sProp);
	if (iOffset <= 0)
	{
		LogMessage("Could not locate offset for %s::%s!", sClass, sProp);
		return false;
	}
	return true;
}

void SDK_HookGiveNamedItem(int iClient)
{
	if (g_hHookGiveNamedItem && !g_bTF2Items)
		g_iHookIdGiveNamedItem[iClient] = DHookEntity(g_hHookGiveNamedItem, false, iClient, Hook_GiveNamedItemRemoved, Hook_GiveNamedItem);
}

void SDK_UnhookGiveNamedItem(int iClient)
{
	if (g_iHookIdGiveNamedItem[iClient])
	{
		DHookRemoveHookID(g_iHookIdGiveNamedItem[iClient]);
		g_iHookIdGiveNamedItem[iClient] = 0;	
	}
}

bool SDK_IsGiveNamedItemActive()
{
	for (int iClient = 1; iClient <= MaxClients; iClient++)
		if (g_iHookIdGiveNamedItem[iClient])
			return true;
	
	return false;
}

void SDK_HookGetCaptureValueForPlayer(DHookCallback callback)
{
	if (g_hHookGetCaptureValueForPlayer)
		DHookGamerules(g_hHookGetCaptureValueForPlayer, true, _, callback);
}

void SDK_HookGetMaxHealth(int iClient)
{
	if (g_hHookGetMaxHealth)
		DHookEntity(g_hHookGetMaxHealth, false, iClient);
}

void SDK_AlwaysTransmitEntity(int iEntity)
{
	if (g_hHookShouldTransmit)
		DHookEntity(g_hHookShouldTransmit, true, iEntity);
}

void SDK_HookBallImpact(int iEntity, DHookCallback callback)
{
	if (g_hHookBallImpact)
		DHookEntity(g_hHookBallImpact, false, iEntity, _, callback);
}

void SDK_HookBallTouch(int iEntity, DHookCallback callback)
{
	if (g_hHookShouldBallTouch)
		DHookEntity(g_hHookShouldBallTouch, false, iEntity, _, callback);
}

public MRESReturn Hook_GetMaxHealth(int iClient, Handle hReturn)
{
	SaxtonHaleBase boss = SaxtonHaleBase(iClient);
	if (boss.bValid && boss.iMaxHealth > 0)
	{
		DHookSetReturn(hReturn, boss.iMaxHealth);
		return MRES_Supercede;
	}
	return MRES_Ignored;
}

public MRESReturn Hook_EntityShouldTransmit(int iEntity, Handle hReturn, Handle hParams)
{
	DHookSetReturn(hReturn, FL_EDICT_ALWAYS);
	return MRES_Supercede;
}

public MRESReturn Hook_GiveNamedItem(int iClient, Handle hReturn, Handle hParams)
{
	if (DHookIsNullParam(hParams, 1) || DHookIsNullParam(hParams, 3))
		return MRES_Ignored;
	
	char sClassname[256];
	DHookGetParamString(hParams, 1, sClassname, sizeof(sClassname));
	int iIndex = DHookGetParamObjectPtrVar(hParams, 3, 4, ObjectValueType_Int) & 0xFFFF;
	
	Action action = GiveNamedItem(iClient, sClassname, iIndex);
	if (action >= Plugin_Handled)
	{
		DHookSetReturn(hReturn, 0);
		return MRES_Supercede;
	}
	
	return MRES_Ignored;
}

public void Hook_GiveNamedItemRemoved(int iHookId)
{
	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if (g_iHookIdGiveNamedItem[iClient] == iHookId)
		{
			g_iHookIdGiveNamedItem[iClient] = 0;
			return;
		}
	}
}

public MRESReturn Hook_AllowedToHealTarget(int iMedigun, Handle hReturn, Handle hParams)
{
	if (!g_bEnabled) return MRES_Ignored;
	if (g_iTotalRoundPlayed <= 0) return MRES_Ignored;
	
	int iHealTarget = DHookGetParam(hParams, 1);
	int iClient = GetEntPropEnt(iMedigun, Prop_Send, "m_hOwnerEntity");
	
	if (0 < iClient <= MaxClients && IsClientInGame(iClient))
	{
		SaxtonHaleBase boss = SaxtonHaleBase(iClient);
		if (boss.bValid)
		{
			bool bReturn = DHookGetReturn(hReturn);
			Action action = boss.CallFunction("CanHealTarget", iHealTarget, bReturn);
			if (action >= Plugin_Changed)
			{
				DHookSetReturn(hReturn, bReturn);
				return MRES_Supercede;
			}
			
			return MRES_Ignored;
		}
		
		if (SaxtonHale_IsValidBoss(iHealTarget))
		{
			//Never allow heal boss from any other sources
			DHookSetReturn(hReturn, false);
			return MRES_Supercede;
		}
		
		TagsParams tParams = new TagsParams();
		TagsCore_CallSlot(iClient, TagsCall_Heal, WeaponSlot_Secondary, tParams);
		
		if (iHealTarget > MaxClients)
		{
			char sClassname[256];
			GetEntityClassname(iHealTarget, sClassname, sizeof(sClassname));
			
			//Override heal result
			int iResult;
			if (StrContains(sClassname, "obj_") == 0
				&& GetEntProp(iHealTarget, Prop_Send, "m_iTeamNum") == GetClientTeam(iClient)
				&& !GetEntProp(iHealTarget, Prop_Send, "m_bCarried")
				&& tParams.GetIntEx("healbuilding", iResult))
			{
				bool bResult = !!iResult;
				DHookSetReturn(hReturn, bResult);
				delete tParams;
				return MRES_Supercede;
			}
		}
		
		delete tParams;
	}
	
	return MRES_Ignored;
}

public MRESReturn Hook_CouldHealTarget(int iDispenser, Handle hReturn, Handle hParams)
{
	int iClient = GetEntPropEnt(iDispenser, Prop_Send, "m_hBuilder");
	int iHealTarget = DHookGetParam(hParams, 1);
	
	if (0 < iClient <= MaxClients)
	{
		SaxtonHaleBase boss = SaxtonHaleBase(iClient);
		if (boss.bValid)
		{
			bool bReturn = DHookGetReturn(hReturn);
			Action action = boss.CallFunction("CanHealTarget", iHealTarget, bReturn);
			if (action >= Plugin_Changed)
			{
				DHookSetReturn(hReturn, bReturn);
				return MRES_Supercede;
			}
			
			return MRES_Ignored;
		}
	}
	
	if (SaxtonHale_IsValidBoss(iHealTarget))
	{
		//Never allow heal boss from any other sources
		DHookSetReturn(hReturn, false);
		return MRES_Supercede;
	}
	
	return MRES_Ignored;
}

void SDK_SendWeaponAnim(int weapon, int anim)
{
	if (g_hSDKSendWeaponAnim != null)
		SDKCall(g_hSDKSendWeaponAnim, weapon, anim);
}

bool SDKCall_PlaySpecificSequence(int iClient, const char[] sAnimationName)
{
	return SDKCall(g_hSDKPlaySpecificSequence, iClient, sAnimationName);
}

int SDK_GetMaxClip(int iWeapon)
{
	if (g_hSDKGetMaxClip != null)
		return SDKCall(g_hSDKGetMaxClip, iWeapon);
	return -1;
}

int SDK_GetMaxHealth(int iClient)
{
	if (g_hSDKGetMaxHealth != null)
		return SDKCall(g_hSDKGetMaxHealth, iClient);
	return 0;
}

void SDK_RemoveWearable(int client, int iWearable)
{
	if(g_hSDKRemoveWearable != null)
		SDKCall(g_hSDKRemoveWearable, client, iWearable);
}

int SDK_GetEquippedWearable(int client, int iSlot)
{
	if(g_hSDKGetEquippedWearable != null)
		return SDKCall(g_hSDKGetEquippedWearable, client, iSlot);
	return -1;
}

void SDK_EquipWearable(int client, int iWearable)
{
	if(g_hSDKEquipWearable != null)
		SDKCall(g_hSDKEquipWearable, client, iWearable);
}

void SDK_AddObject(int iClient, int iEntity)
{
	if(g_hSDKAddObject != null)
		SDKCall(g_hSDKAddObject, iClient, iEntity);
}

void SDK_RemoveObject(int iClient, int iEntity)
{
	if(g_hSDKRemoveObject != null)
		SDKCall(g_hSDKRemoveObject, iClient, iEntity);
}

void SDK_TossJarThink(int iEntity)
{
	SDKCall(g_hSDKTossJarThink, iEntity);
}

void SDK_SetFuseTime(int iEntity, float flTime)
{
	if (g_iOffsetFuseTime <= 0)
		return;
	
	SetEntDataFloat(iEntity, g_iOffsetFuseTime, flTime);
}