#define WEAPONKEYS_DONK_WINDOW	0.5
#define WEAPONKEYS_DMG_USEDISTANCEMOD	(1 << 21)
#define WEAPONKEYS_FALLOFF_DISTANCE	512.0
#define WEAPONKEYS_JAR_RECHARGE_TIME	20.1
#define WEAPONKEYS_SHOVE_CLASSNAME	"tf_weapon_handgun_scout_primary"
#define WEAPONKEYS_SCATTERGUN_PUSH	300.0
#define WEAPONKEYS_SCATTERGUN_PUSH_UP	50.0
#define WEAPONKEYS_SCATTERGUN_PUSH_TOLERANCE	2.0

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

static ConVar g_cvWeaponKeysDamageRange;
static ConVar g_cvWeaponKeysCritFalloff;
static ConVar g_cvWeaponKeysMiniCritFalloff;

static int g_iWeaponKeysFireWeapon[MAXPLAYERS];
static float g_flWeaponKeysFireTime[MAXPLAYERS];

void WeaponKeys_Init()
{
	int iOffset = FindSendPropInfo("CTFGrenadePipebombProjectile", "m_hOriginalLauncher");
	if (iOffset > 4)
		g_iWeaponKeysCollideOffset = iOffset - 4;
	else
		LogMessage("Could not locate offset for CTFGrenadePipebombProjectile::m_hOriginalLauncher, \"passteammates\" is disabled");
	
	g_cvWeaponKeysDonkWindow = FindConVar("tf_double_donk_window");
	g_cvWeaponKeysDamageRange = FindConVar("tf_damage_range");
	g_cvWeaponKeysCritFalloff = FindConVar("tf_weapon_criticals_distance_falloff");
	g_cvWeaponKeysMiniCritFalloff = FindConVar("tf_weapon_minicrits_distance_falloff");
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
		g_iWeaponKeysPipeState[iPipe] = (SaxtonHale_IsValidAttack(iOwner) && Config_GetWeaponKeyInt(iOwner, iLauncher, "passteammates") == 1) ? 1 : -1;
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
	
	bool bChanged = false;
	
	if (iVictim != iAttacker && SaxtonHale_IsValidAttack(iAttacker) && GetClientTeam(iVictim) != GetClientTeam(iAttacker)
		&& Config_GetWeaponKeyInt(iAttacker, iWeapon, "noknockback") == 1)
	{
		iDamageType |= DMG_PREVENT_PHYSICS_FORCE;
		WeaponKeys_BlockPushback(iVictim);
		bChanged = true;
	}
	
	if (iVictim == iAttacker || !SaxtonHale_IsValidBoss(iVictim, false) || !SaxtonHale_IsValidAttack(iAttacker))
		return bChanged;
	
	if (Config_GetWeaponKeyInt(iAttacker, iWeapon, "nobosspush") == 1)
	{
		iDamageType |= DMG_PREVENT_PHYSICS_FORCE;
		bChanged = true;
		
		if (iDamageCustom == TF_CUSTOM_CANNONBALL_PUSH)
			WeaponKeys_BlockImpactPush(iVictim);
	}
	
	float flBonus = Config_GetWeaponKeyFloat(iAttacker, iWeapon, "doubledonk");
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

static void WeaponKeys_BlockPushback(int iVictim)
{
	if (TF2_IsPlayerInCondition(iVictim, TFCond_ImmuneToPushback))
		return;
	
	TF2_AddCondition(iVictim, TFCond_ImmuneToPushback, TFCondDuration_Infinite);
	g_bWeaponKeysPushImmune[iVictim] = true;
	g_iWeaponKeysPushUserId[iVictim] = GetClientUserId(iVictim);
	RequestFrame(WeaponKeys_RemovePushConds, iVictim);
}

void WeaponKeys_OnThink(int iClient)
{
	if (!IsPlayerAlive(iClient) || TF2_GetPlayerClass(iClient) != TFClass_Scout)
		return;
	
	int iWeapon = GetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon");
	if (iWeapon <= MaxClients || !IsValidEntity(iWeapon))
		return;
	
	char sClassname[64];
	GetEntityClassname(iWeapon, sClassname, sizeof(sClassname));
	if (strcmp(sClassname, WEAPONKEYS_SHOVE_CLASSNAME) != 0 || Config_GetWeaponKeyInt(iClient, iWeapon, "noknockback") != 1)
		return;
	
	float flBlock = GetGameTime() + 1.0;
	if (GetEntPropFloat(iWeapon, Prop_Send, "m_flNextSecondaryAttack") < flBlock)
		SetEntPropFloat(iWeapon, Prop_Send, "m_flNextSecondaryAttack", flBlock + 1.0);
}

bool WeaponKeys_OnTakeDamageAliveFalloff(int iVictim, int iAttacker, float &flDamage, int iDamageType, int iWeapon)
{
	if (flDamage <= 0.0 || iVictim == iAttacker || !SaxtonHale_IsValidAttack(iAttacker))
		return false;
	
	if ((iDamageType & DMG_BLAST) || !(iDamageType & WEAPONKEYS_DMG_USEDISTANCEMOD))
		return false;
	
	float flScale = Config_GetWeaponKeyFloat(iAttacker, iWeapon, "falloffscale");
	if (flScale <= 0.0 || flScale == 1.0)
		return false;
	
	if (iDamageType & DMG_CRIT)
	{
		if (g_cvWeaponKeysCritFalloff == null || !g_cvWeaponKeysCritFalloff.BoolValue)
			return false;
	}
	else if (WeaponKeys_IsMiniCrit(iVictim, iAttacker, iWeapon))
	{
		if (g_cvWeaponKeysMiniCritFalloff == null || !g_cvWeaponKeysMiniCritFalloff.BoolValue)
			return false;
	}
	
	if (TF2_IsPlayerInCondition(iAttacker, TFCond_RunePrecision) || TF2_IsPlayerInCondition(iAttacker, TFCond_RuneStrength))
		return false;
	
	float vecAttacker[3], vecVictim[3];
	WeaponKeys_GetWorldSpaceCenter(iAttacker, vecAttacker);
	WeaponKeys_GetWorldSpaceCenter(iVictim, vecVictim);
	float flDistance = GetVectorDistance(vecAttacker, vecVictim);
	
	float flCenter = 1.0 - flDistance / (WEAPONKEYS_FALLOFF_DISTANCE * 2.0);
	if (flCenter >= 0.5)
		return false;
	
	float flValue = (flCenter > 0.1) ? flCenter : 0.1;
	float flSpline = flValue * flValue * (3.0 - 2.0 * flValue);
	float flRange = (g_cvWeaponKeysDamageRange != null) ? g_cvWeaponKeysDamageRange.FloatValue : 0.5;
	float flLoss = flRange * (2.0 * flSpline - 1.0);
	if (flLoss >= 0.0 || 1.0 + flLoss <= 0.0)
		return false;
	
	flDamage *= (1.0 + flLoss * flScale) / (1.0 + flLoss);
	return true;
}

static bool WeaponKeys_IsMiniCrit(int iVictim, int iAttacker, int iWeapon)
{
	if (TF2_IsPlayerInCondition(iVictim, TFCond_Jarated) || TF2_IsPlayerInCondition(iVictim, TFCond_MarkedForDeath)
		|| TF2_IsPlayerInCondition(iVictim, TFCond_MarkedForDeathSilent) || TF2_IsPlayerInCondition(iVictim, TFCond_PasstimePenaltyDebuff))
		return true;
	
	if (TF2_IsPlayerInCondition(iAttacker, TFCond_Buffed) || TF2_IsPlayerInCondition(iAttacker, TFCond_NoHealingDamageBuff)
		|| TF2_IsPlayerInCondition(iAttacker, TFCond_CritCola))
		return true;
	
	if (iWeapon <= MaxClients || !IsValidEntity(iWeapon))
		return false;
	
	if (TF2_GetPlayerClass(iAttacker) == TFClass_Scout && !(GetEntityFlags(iAttacker) & FL_ONGROUND)
		&& iWeapon == GetEntPropEnt(iAttacker, Prop_Send, "m_hActiveWeapon") && TF2Attrib_HookValueInt(0, "air_dash_count", iWeapon) != 0)
		return true;
	
	if (TF2Attrib_HookValueInt(0, "closerange_backattack_minicrits", iWeapon) == 1)
	{
		float vecAttacker[3], vecVictim[3], vecToVictim[3], vecAngles[3], vecForward[3];
		GetClientAbsOrigin(iAttacker, vecAttacker);
		GetClientAbsOrigin(iVictim, vecVictim);
		SubtractVectors(vecVictim, vecAttacker, vecToVictim);
		if (GetVectorLength(vecToVictim, true) < 512.0 * 512.0)
		{
			GetClientEyeAngles(iVictim, vecAngles);
			GetAngleVectors(vecAngles, vecForward, NULL_VECTOR, NULL_VECTOR);
			vecToVictim[2] = 0.0;
			NormalizeVector(vecToVictim, vecToVictim);
			if (GetVectorDotProduct(vecToVictim, vecForward) > 0.259)
				return true;
		}
	}
	
	return false;
}

static void WeaponKeys_GetWorldSpaceCenter(int iClient, float vecCenter[3])
{
	float vecMins[3], vecMaxs[3];
	GetClientAbsOrigin(iClient, vecCenter);
	GetClientMins(iClient, vecMins);
	GetClientMaxs(iClient, vecMaxs);
	for (int i = 0; i < 3; i++)
		vecCenter[i] += (vecMins[i] + vecMaxs[i]) * 0.5;
}

void WeaponKeys_OnTakeDamagePost(int iVictim, int iAttacker, float flDamage)
{
	if (flDamage <= 0.0 || iVictim == iAttacker || !SaxtonHale_IsValidAttack(iAttacker) || !IsPlayerAlive(iAttacker))
		return;
	
	if (iVictim <= 0 || iVictim > MaxClients || !IsClientInGame(iVictim) || GetClientTeam(iVictim) == GetClientTeam(iAttacker))
		return;
	
	float flNow = GetGameTime();
	for (int iSlot = WeaponSlot_Primary; iSlot <= WeaponSlot_Melee; iSlot++)
	{
		int iWeapon = TF2_GetItemInSlot(iAttacker, iSlot);
		if (iWeapon <= MaxClients || !HasEntProp(iWeapon, Prop_Send, "m_flEffectBarRegenTime"))
			continue;
		
		float flDamageFull = Config_GetWeaponKeyFloat(iAttacker, iWeapon, "rechargedamage");
		if (flDamageFull <= 0.0)
			continue;
		
		float flRegenTime = GetEntPropFloat(iWeapon, Prop_Send, "m_flEffectBarRegenTime");
		if (flRegenTime <= flNow)
			continue;
		
		float flFullTime = TF2Attrib_HookValueFloat(WEAPONKEYS_JAR_RECHARGE_TIME, "effectbar_recharge_rate", iWeapon);
		flRegenTime -= flFullTime * flDamage / flDamageFull;
		SetEntPropFloat(iWeapon, Prop_Send, "m_flEffectBarRegenTime", (flRegenTime > flNow) ? flRegenTime : flNow);
	}
}

void WeaponKeys_OnPlayerRunCmdPost(int iClient)
{
	int iWeapon = GetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon");
	if (iWeapon <= MaxClients || !HasEntProp(iWeapon, Prop_Send, "m_flLastFireTime"))
	{
		g_iWeaponKeysFireWeapon[iClient] = 0;
		return;
	}
	
	int iRef = EntIndexToEntRef(iWeapon);
	float flFireTime = GetEntPropFloat(iWeapon, Prop_Send, "m_flLastFireTime");
	bool bFired = (iRef == g_iWeaponKeysFireWeapon[iClient] && flFireTime > g_flWeaponKeysFireTime[iClient]);
	g_iWeaponKeysFireWeapon[iClient] = iRef;
	g_flWeaponKeysFireTime[iClient] = flFireTime;
	
	if (!bFired)
		return;
	
	char sSound[PLATFORM_MAX_PATH];
	if (Config_GetWeaponKey(iClient, iWeapon, "extrafiresound", sSound, sizeof(sSound)) && sSound[0] != '\0')
		WeaponKeys_PlayFireSound(iClient, sSound);
	
	float flScale = Config_GetWeaponKeyFloat(iClient, iWeapon, "selfpushscale");
	if (flScale > 0.0 && flScale != 1.0)
		WeaponKeys_ScaleScattergunPush(iClient, flScale);
}

static void WeaponKeys_PlayFireSound(int iClient, const char[] sGameSound)
{
	if (!PrecacheScriptSound(sGameSound))
		return;
	
	int iChannel, iLevel, iPitch;
	float flVolume;
	char sSample[PLATFORM_MAX_PATH];
	if (!GetGameSoundParams(sGameSound, iChannel, iLevel, flVolume, iPitch, sSample, sizeof(sSample), iClient))
		return;
	
	EmitSoundToAll(sSample, iClient, SNDCHAN_AUTO, iLevel, SND_NOFLAGS, flVolume, iPitch);
}

static void WeaponKeys_ScaleScattergunPush(int iClient, float flScale)
{
	if (GetEntityFlags(iClient) & FL_ONGROUND)
		return;
	
	float vecAngles[3], vecForward[3], vecVelocity[3];
	GetClientEyeAngles(iClient, vecAngles);
	GetAngleVectors(vecAngles, vecForward, NULL_VECTOR, NULL_VECTOR);
	GetEntPropVector(iClient, Prop_Data, "m_vecVelocity", vecVelocity);
	
	float flPushed = -WEAPONKEYS_SCATTERGUN_PUSH + WEAPONKEYS_SCATTERGUN_PUSH_UP * vecForward[2];
	if (FloatAbs(GetVectorDotProduct(vecVelocity, vecForward) - flPushed) > WEAPONKEYS_SCATTERGUN_PUSH_TOLERANCE)
		return;
	
	float flExtra = flScale - 1.0;
	for (int i = 0; i < 3; i++)
		vecVelocity[i] -= vecForward[i] * WEAPONKEYS_SCATTERGUN_PUSH * flExtra;
	
	vecVelocity[2] += WEAPONKEYS_SCATTERGUN_PUSH_UP * flExtra;
	TeleportEntity(iClient, NULL_VECTOR, NULL_VECTOR, vecVelocity);
}
