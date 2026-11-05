#define WEAPONKEYS_DONK_WINDOW	0.5

static int g_iWeaponKeysCollideOffset = -1;
static int g_iWeaponKeysCollideState;
static int g_iWeaponKeysCollideMisses;
static int g_iWeaponKeysPipeState[2048+1];
static float g_flWeaponKeysPipeCreated[2048+1];
static bool g_bWeaponKeysPipeMissed[2048+1];

static ConVar g_cvWeaponKeysDonkWindow;
static float g_flWeaponKeysDonkEnd[MAXPLAYERS][MAXPLAYERS];
static int g_iWeaponKeysDonkVictim;
static int g_iWeaponKeysDonkAttacker;
static float g_flWeaponKeysDonkBonus;
static float g_flWeaponKeysDonkTime = -1.0;

static int g_iWeaponKeysPushUserId[MAXPLAYERS];
static bool g_bWeaponKeysPushAir[MAXPLAYERS];
static bool g_bWeaponKeysPushImmune[MAXPLAYERS];

void WeaponKeys_Init()
{
	int iOffset = FindSendPropInfo("CTFGrenadePipebombProjectile", "m_hOriginalLauncher");
	if (iOffset > 4)
		g_iWeaponKeysCollideOffset = iOffset - 4;
	else
		LogMessage("Could not locate offset for CTFGrenadePipebombProjectile::m_hOriginalLauncher, \"passteammates\" is disabled");
	
	g_cvWeaponKeysDonkWindow = FindConVar("tf_double_donk_window");
}

void WeaponKeys_OnEntityCreated(int iEntity, const char[] sClassname)
{
	if (g_iWeaponKeysCollideOffset <= 0 || g_iWeaponKeysCollideState == -1 || iEntity <= MaxClients || iEntity >= sizeof(g_iWeaponKeysPipeState))
		return;
	
	if (strcmp(sClassname, "tf_projectile_pipe") != 0 && strcmp(sClassname, "tf_projectile_pipe_remote") != 0)
		return;
	
	g_iWeaponKeysPipeState[iEntity] = 0;
	g_flWeaponKeysPipeCreated[iEntity] = GetGameTime();
	g_bWeaponKeysPipeMissed[iEntity] = false;
	SDKHook(iEntity, SDKHook_VPhysicsUpdate, WeaponKeys_PipeVPhysicsUpdate);
}

public void WeaponKeys_PipeVPhysicsUpdate(int iPipe)
{
	if (g_iWeaponKeysCollideState == -1 || iPipe <= MaxClients || iPipe >= sizeof(g_iWeaponKeysPipeState))
		return;
	
	if (g_iWeaponKeysPipeState[iPipe] == 0)
	{
		int iLauncher = GetEntPropEnt(iPipe, Prop_Send, "m_hOriginalLauncher");
		if (iLauncher <= MaxClients)
			return;
		
		int iOwner = GetEntPropEnt(iLauncher, Prop_Send, "m_hOwnerEntity");
		g_iWeaponKeysPipeState[iPipe] = (SaxtonHale_IsValidAttack(iOwner) && WeaponKeys_GetInt(iOwner, iLauncher, "passteammates") == 1) ? 1 : -1;
	}
	
	if (g_iWeaponKeysPipeState[iPipe] != 1)
		return;
	
	int iValue = GetEntData(iPipe, g_iWeaponKeysCollideOffset, 1);
	if (g_iWeaponKeysCollideState == 1)
	{
		if (iValue == 1)
			SetEntData(iPipe, g_iWeaponKeysCollideOffset, 0, 1);
		
		return;
	}
	
	float flAge = GetGameTime() - g_flWeaponKeysPipeCreated[iPipe];
	if ((iValue != 0 && iValue != 1) || (iValue == 1 && flAge < 0.2))
	{
		WeaponKeys_CollideCheckFailed();
	}
	else if (iValue == 1)
	{
		g_iWeaponKeysCollideState = 1;
		SetEntData(iPipe, g_iWeaponKeysCollideOffset, 0, 1);
	}
	else if (flAge > 0.6 && !g_bWeaponKeysPipeMissed[iPipe])
	{
		g_bWeaponKeysPipeMissed[iPipe] = true;
		g_iWeaponKeysCollideMisses++;
		if (g_iWeaponKeysCollideMisses >= 3)
			WeaponKeys_CollideCheckFailed();
	}
}

static void WeaponKeys_CollideCheckFailed()
{
	g_iWeaponKeysCollideState = -1;
	LogMessage("Offset check failed for CBaseProjectile::m_bCanCollideWithTeammates (m_hOriginalLauncher - 4), \"passteammates\" is disabled until the plugin reloads");
}

bool WeaponKeys_OnTakeDamage(int iVictim, int iAttacker, int &iDamageType, int iWeapon, int iDamageCustom)
{
	g_flWeaponKeysDonkTime = -1.0;
	
	if (iVictim == iAttacker || !SaxtonHale_IsValidBoss(iVictim, false) || !SaxtonHale_IsValidAttack(iAttacker))
		return false;
	
	StringMap sIndexMap, sClassMap;
	if (!WeaponKeys_GetMaps(iAttacker, iWeapon, sIndexMap, sClassMap))
		return false;
	
	bool bChanged = false;
	if (WeaponKeys_ReadInt(sIndexMap, sClassMap, "nobosspush") == 1)
	{
		iDamageType |= DMG_PREVENT_PHYSICS_FORCE;
		bChanged = true;
		
		if (iDamageCustom == TF_CUSTOM_CANNONBALL_PUSH)
			WeaponKeys_BlockImpactPush(iVictim);
	}
	
	float flBonus = WeaponKeys_ReadFloat(sIndexMap, sClassMap, "doubledonk");
	if (flBonus != 0.0 && (iDamageType & DMG_BLAST))
	{
		char sClassname[64];
		GetEntityClassname(iWeapon, sClassname, sizeof(sClassname));
		if (strcmp(sClassname, "tf_weapon_cannon") == 0)
		{
			float flNow = GetGameTime();
			float flWindow = (g_cvWeaponKeysDonkWindow != null) ? g_cvWeaponKeysDonkWindow.FloatValue : WEAPONKEYS_DONK_WINDOW;
			
			float flLeft = g_flWeaponKeysDonkEnd[iVictim][iAttacker] - flNow;
			if (flLeft > 0.0 && flLeft <= flWindow)
			{
				g_iWeaponKeysDonkVictim = iVictim;
				g_iWeaponKeysDonkAttacker = iAttacker;
				g_flWeaponKeysDonkBonus = flBonus;
				g_flWeaponKeysDonkTime = flNow;
			}
			
			if (iDamageCustom == TF_CUSTOM_CANNONBALL_PUSH)
				g_flWeaponKeysDonkEnd[iVictim][iAttacker] = flNow + flWindow;
		}
	}
	
	return bChanged;
}

bool WeaponKeys_OnTakeDamageAlive(int iVictim, int iAttacker, float &flDamage)
{
	if (g_flWeaponKeysDonkTime != GetGameTime() || g_iWeaponKeysDonkVictim != iVictim || g_iWeaponKeysDonkAttacker != iAttacker)
		return false;
	
	g_flWeaponKeysDonkTime = -1.0;
	flDamage += g_flWeaponKeysDonkBonus;
	return true;
}

static void WeaponKeys_BlockImpactPush(int iBoss)
{
	bool bQueue = false;
	
	if (!TF2_IsPlayerInCondition(iBoss, TFCond_KnockedIntoAir))
	{
		TF2_AddCondition(iBoss, TFCond_KnockedIntoAir, TFCondDuration_Infinite);
		g_bWeaponKeysPushAir[iBoss] = true;
		bQueue = true;
	}
	
	if (!TF2_IsPlayerInCondition(iBoss, TFCond_ImmuneToPushback))
	{
		TF2_AddCondition(iBoss, TFCond_ImmuneToPushback, TFCondDuration_Infinite);
		g_bWeaponKeysPushImmune[iBoss] = true;
		bQueue = true;
	}
	
	if (bQueue)
	{
		g_iWeaponKeysPushUserId[iBoss] = GetClientUserId(iBoss);
		RequestFrame(WeaponKeys_RemovePushConds, iBoss);
	}
}

public void WeaponKeys_RemovePushConds(int iBoss)
{
	if (IsClientInGame(iBoss) && GetClientUserId(iBoss) == g_iWeaponKeysPushUserId[iBoss])
	{
		if (g_bWeaponKeysPushAir[iBoss])
			TF2_RemoveCondition(iBoss, TFCond_KnockedIntoAir);
		
		if (g_bWeaponKeysPushImmune[iBoss])
			TF2_RemoveCondition(iBoss, TFCond_ImmuneToPushback);
	}
	
	g_bWeaponKeysPushAir[iBoss] = false;
	g_bWeaponKeysPushImmune[iBoss] = false;
}

static bool WeaponKeys_GetMaps(int iClient, int iWeapon, StringMap &sIndexMap, StringMap &sClassMap)
{
	sIndexMap = null;
	sClassMap = null;
	
	if (iWeapon <= MaxClients || !IsValidEntity(iWeapon) || !HasEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex"))
		return false;
	
	int iIndex = GetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex");
	sIndexMap = g_ConfigIndex.GetStringMap(AltWeapon_GetConfigIndex(iClient, iIndex));
	
	TFClassType nClass = TF2_GetPlayerClass(iClient);
	int iSlot = TF2_GetItemSlot(iIndex, nClass);
	if (nClass != TFClass_Unknown && 0 <= iSlot < sizeof(g_ConfigClass[]))
		sClassMap = view_as<StringMap>(g_ConfigClass[nClass][iSlot]);
	
	return (sIndexMap != null || sClassMap != null);
}

static bool WeaponKeys_Read(StringMap sIndexMap, StringMap sClassMap, const char[] sKey, char[] sValue, int iLength)
{
	if (sIndexMap != null && sIndexMap.GetString(sKey, sValue, iLength))
		return true;
	
	return (sClassMap != null && sClassMap.GetString(sKey, sValue, iLength));
}

static int WeaponKeys_ReadInt(StringMap sIndexMap, StringMap sClassMap, const char[] sKey)
{
	char sValue[MAXLEN_CONFIG_VALUE];
	if (!WeaponKeys_Read(sIndexMap, sClassMap, sKey, sValue, sizeof(sValue)))
		return 0;
	
	return StringToInt(sValue);
}

static float WeaponKeys_ReadFloat(StringMap sIndexMap, StringMap sClassMap, const char[] sKey)
{
	char sValue[MAXLEN_CONFIG_VALUE];
	if (!WeaponKeys_Read(sIndexMap, sClassMap, sKey, sValue, sizeof(sValue)))
		return 0.0;
	
	return StringToFloat(sValue);
}

static int WeaponKeys_GetInt(int iClient, int iWeapon, const char[] sKey)
{
	StringMap sIndexMap, sClassMap;
	if (!WeaponKeys_GetMaps(iClient, iWeapon, sIndexMap, sClassMap))
		return 0;
	
	return WeaponKeys_ReadInt(sIndexMap, sClassMap, sKey);
}
