#define WEAPONKEYS_DONK_WINDOW	0.5
#define WEAPONKEYS_DMG_USEDISTANCEMOD	(1 << 21)
#define WEAPONKEYS_FALLOFF_DISTANCE	512.0
#define WEAPONKEYS_JAR_RECHARGE_TIME	20.1
#define WEAPONKEYS_SHOVE_CLASSNAME	"tf_weapon_handgun_scout_primary"
#define WEAPONKEYS_SCATTERGUN_PUSH	300.0
#define WEAPONKEYS_SCATTERGUN_PUSH_UP	50.0
#define WEAPONKEYS_SCATTERGUN_PUSH_TOLERANCE	2.0
#define WEAPONKEYS_MISS_CHECK_TIME	0.3
#define WEAPONKEYS_MISS_GRACE	0.25
#define WEAPONKEYS_MISS_READY	0.05
#define WEAPONKEYS_MISS_SWING_MIN	0.25
#define WEAPONKEYS_CABER_DAMAGE	75.0
#define WEAPONKEYS_CABER_RADIUS	100.0
#define WEAPONKEYS_CABER_SELF_SCALE	0.75
#define WEAPONKEYS_DMG_MELEE	(1 << 27)
#define WEAPONKEYS_EXPLOSION_WEAPONID	23
#define WEAPONKEYS_EXPLOSION_SOUND	11
#define WEAPONKEYS_REQUIRED_HOLD	0.5

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
static int g_iWeaponKeysMilkAttacker;
static int g_iWeaponKeysMilkTick;
static float g_flWeaponKeysNextAttack[MAXPLAYERS];
static float g_flWeaponKeysSwingTime[MAXPLAYERS];
static int g_iWeaponKeysCaberHitTick[MAXPLAYERS];
static int g_iWeaponKeysBlastClient;
static int g_iWeaponKeysBlastWeapon;
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

	g_iWeaponKeysMilkAttacker = 0;
	if (iVictim != iAttacker && SaxtonHale_IsValidAttack(iAttacker) && TF2_IsPlayerInCondition(iVictim, TFCond_Milked))
	{
		g_iWeaponKeysMilkAttacker = iAttacker;
		g_iWeaponKeysMilkTick = GetGameTickCount();
	}
	
	bool bChanged = false;
	
	if (iVictim != iAttacker && 0 < iAttacker <= MaxClients && iDamageCustom != TF_CUSTOM_STICKBOMB_EXPLOSION && !(iDamageType & DMG_BLAST)
		&& iWeapon > MaxClients && IsValidEntity(iWeapon) && HasEntProp(iWeapon, Prop_Send, "m_iDetonated"))
		g_iWeaponKeysCaberHitTick[iAttacker] = GetGameTickCount();
	
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
	if (!IsPlayerAlive(iClient))
		return;
	
	int iWeapon = GetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon");
	if (iWeapon <= MaxClients || !IsValidEntity(iWeapon))
		return;
	
	if (Config_GetWeaponKeyInt(iClient, iWeapon, "damagerequired") > g_iPlayerDamage[iClient])
	{
		float flHold = GetGameTime() + WEAPONKEYS_REQUIRED_HOLD;
		if (GetEntPropFloat(iWeapon, Prop_Send, "m_flNextPrimaryAttack") < flHold)
			SetEntPropFloat(iWeapon, Prop_Send, "m_flNextPrimaryAttack", flHold + WEAPONKEYS_REQUIRED_HOLD);
	}
	
	if (TF2_GetPlayerClass(iClient) != TFClass_Scout)
		return;
	
	char sClassname[64];
	GetEntityClassname(iWeapon, sClassname, sizeof(sClassname));
	if (strcmp(sClassname, WEAPONKEYS_SHOVE_CLASSNAME) != 0 || Config_GetWeaponKeyInt(iClient, iWeapon, "noknockback") != 1)
		return;
	
	float flBlock = GetGameTime() + 1.0;
	if (GetEntPropFloat(iWeapon, Prop_Send, "m_flNextSecondaryAttack") < flBlock)
		SetEntPropFloat(iWeapon, Prop_Send, "m_flNextSecondaryAttack", flBlock + 1.0);
}

bool WeaponKeys_GetDamageRequired(int iClient, int &iRequired)
{
	iRequired = 0;
	if (g_iTotalRoundPlayed <= 0 || !SaxtonHale_IsValidAttack(iClient) || !IsPlayerAlive(iClient))
		return false;
	
	for (int iSlot = WeaponSlot_Primary; iSlot <= WeaponSlot_Melee; iSlot++)
	{
		int iWeapon = GetPlayerWeaponSlot(iClient, iSlot);
		if (iWeapon <= MaxClients)
			continue;
		
		int iValue = Config_GetWeaponKeyInt(iClient, iWeapon, "damagerequired");
		if (iValue > g_iPlayerDamage[iClient])
		{
			iRequired = iValue;
			return true;
		}
	}
	
	return false;
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
	g_iWeaponKeysMilkAttacker = 0;

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
		g_flWeaponKeysSwingTime[iClient] = 0.0;
		return;
	}
	
	int iRef = EntIndexToEntRef(iWeapon);
	bool bSameWeapon = (iRef == g_iWeaponKeysFireWeapon[iClient]);
	float flFireTime = GetEntPropFloat(iWeapon, Prop_Send, "m_flLastFireTime");
	bool bFired = (bSameWeapon && flFireTime > g_flWeaponKeysFireTime[iClient]);
	g_iWeaponKeysFireWeapon[iClient] = iRef;
	g_flWeaponKeysFireTime[iClient] = flFireTime;
	
	WeaponKeys_MissExplodeThink(iClient, iWeapon, bSameWeapon);
	
	if (!bFired)
		return;
	
	char sSound[PLATFORM_MAX_PATH];
	if (Config_GetWeaponKey(iClient, iWeapon, "extrafiresound", sSound, sizeof(sSound)) && sSound[0] != '\0')
		WeaponKeys_PlayFireSound(iClient, sSound);
	
	float flScale = Config_GetWeaponKeyFloat(iClient, iWeapon, "selfpushscale");
	if (flScale > 0.0 && flScale != 1.0)
		WeaponKeys_ScaleScattergunPush(iClient, flScale);
}

void WeaponKeys_OnPlayerHealed(int iPatient, int iHealer, int iAmount)
{
	if (iPatient <= 0 || iPatient != g_iWeaponKeysMilkAttacker || GetGameTickCount() != g_iWeaponKeysMilkTick)
		return;

	if (!IsClientInGame(iPatient) || !SaxtonHale_IsValidAttack(iHealer))
		return;

	int iMissing = SDK_GetMaxHealth(iPatient) - GetClientHealth(iPatient);
	if (iAmount > iMissing)
		iAmount = iMissing;

	if (iAmount > 0)
		g_iPlayerAssistDamage[iHealer] += iAmount;
}

static void WeaponKeys_MissExplodeThink(int iClient, int iWeapon, bool bSameWeapon)
{
	float flNextAttack = GetEntPropFloat(iWeapon, Prop_Send, "m_flNextPrimaryAttack");
	float flPrevAttack = g_flWeaponKeysNextAttack[iClient];
	g_flWeaponKeysNextAttack[iClient] = flNextAttack;
	
	if (!bSameWeapon)
	{
		g_flWeaponKeysSwingTime[iClient] = 0.0;
		return;
	}
	
	float flNow = float(GetEntProp(iClient, Prop_Send, "m_nTickBase") - 1) * GetTickInterval();
	
	if (g_flWeaponKeysSwingTime[iClient] > 0.0)
	{
		float flSince = flNow - g_flWeaponKeysSwingTime[iClient];
		if (flSince >= 0.0 && flSince < WEAPONKEYS_MISS_CHECK_TIME)
			return;
		
		g_flWeaponKeysSwingTime[iClient] = 0.0;
		if (flSince < 0.0 || flSince > WEAPONKEYS_MISS_CHECK_TIME + WEAPONKEYS_MISS_GRACE)
			return;
		
		if (Config_GetWeaponKeyFloat(iClient, iWeapon, "missexplode") > 0.0 && HasEntProp(iWeapon, Prop_Send, "m_iDetonated") && GetEntProp(iWeapon, Prop_Send, "m_iDetonated") == 0)
			WeaponKeys_MissExplode(iClient, iWeapon);
		
		return;
	}
	
	if (!(GetClientButtons(iClient) & IN_ATTACK) || flPrevAttack > flNow + WEAPONKEYS_MISS_READY || flNextAttack < flNow + WEAPONKEYS_MISS_SWING_MIN)
		return;
	
	if (!HasEntProp(iWeapon, Prop_Send, "m_iDetonated") || GetEntProp(iWeapon, Prop_Send, "m_iDetonated") != 0)
		return;
	
	if (Config_GetWeaponKeyInt(iClient, iWeapon, "damagerequired") > g_iPlayerDamage[iClient])
		return;
	
	if (Config_GetWeaponKeyFloat(iClient, iWeapon, "missexplode") > 0.0)
		g_flWeaponKeysSwingTime[iClient] = flNow;
}

static void WeaponKeys_MissExplode(int iClient, int iWeapon)
{
	SetEntProp(iWeapon, Prop_Send, "m_iDetonated", 1);
	if (HasEntProp(iWeapon, Prop_Send, "m_bBroken"))
		SetEntProp(iWeapon, Prop_Send, "m_bBroken", 1);
	
	float vecPos[3];
	GetClientEyePosition(iClient, vecPos);
	
	float flRadius = TF2Attrib_HookValueFloat(WEAPONKEYS_CABER_RADIUS, "mult_explosion_radius", iWeapon);
	int iDamageType = DMG_BLAST | WEAPONKEYS_DMG_USEDISTANCEMOD | WEAPONKEYS_DMG_MELEE;
	if (TF2_IsForceCrit(iClient) || TF2_IsPlayerInCondition(iClient, TFCond_Kritzkrieged))
		iDamageType |= DMG_CRIT;
	
	g_iWeaponKeysBlastClient = iClient;
	g_iWeaponKeysBlastWeapon = iWeapon;
	
	TFTeam nTeam = TF2_GetClientTeam(iClient);
	for (int iVictim = 1; iVictim <= MaxClients; iVictim++)
	{
		if (iVictim == iClient || !IsClientInGame(iVictim) || !IsPlayerAlive(iVictim) || TF2_GetClientTeam(iVictim) == nTeam)
			continue;
		
		if (RageMeteor_GetBoxDistance(iVictim, vecPos) > flRadius || !RageMeteor_IsInSight(vecPos, iVictim))
			continue;
		
		SDKHooks_TakeDamage(iVictim, iClient, iClient, WeaponKeys_GetBlastDamage(iVictim, vecPos, flRadius), iDamageType, iWeapon, NULL_VECTOR, vecPos, false);
	}
	
	if (IsClientInGame(iClient) && IsPlayerAlive(iClient))
		SDKHooks_TakeDamage(iClient, iClient, iClient, WeaponKeys_GetBlastDamage(iClient, vecPos, flRadius) * WEAPONKEYS_CABER_SELF_SCALE, iDamageType, iWeapon, NULL_VECTOR, vecPos, false);
	
	g_iWeaponKeysBlastClient = 0;
	g_iWeaponKeysBlastWeapon = 0;
	
	float vecNormal[3] = {0.0, 0.0, 1.0};
	TE_Start("TFExplosion");
	TE_WriteFloat("m_vecOrigin[0]", vecPos[0]);
	TE_WriteFloat("m_vecOrigin[1]", vecPos[1]);
	TE_WriteFloat("m_vecOrigin[2]", vecPos[2]);
	TE_WriteVector("m_vecNormal", vecNormal);
	TE_WriteNum("m_iWeaponID", WEAPONKEYS_EXPLOSION_WEAPONID);
	TE_WriteNum("entindex", iClient);
	TE_WriteNum("m_nDefID", -1);
	TE_WriteNum("m_nSound", WEAPONKEYS_EXPLOSION_SOUND);
	TE_WriteNum("m_iCustomParticleIndex", -1);
	TE_SendToAll();
}

static float WeaponKeys_GetBlastDamage(int iVictim, const float vecPos[3], float flRadius)
{
	float vecCenter[3], vecOrigin[3];
	WeaponKeys_GetWorldSpaceCenter(iVictim, vecCenter);
	GetClientAbsOrigin(iVictim, vecOrigin);
	
	float flDistance = GetVectorDistance(vecPos, vecCenter);
	float flToOrigin = GetVectorDistance(vecPos, vecOrigin);
	if (flToOrigin < flDistance)
		flDistance = flToOrigin;
	
	if (flDistance > flRadius)
		flDistance = flRadius;
	
	float flEdge = WEAPONKEYS_CABER_DAMAGE / flRadius;
	if (flEdge > 1.0)
		flEdge = 1.0;
	
	return WEAPONKEYS_CABER_DAMAGE * (1.0 - (1.0 - flEdge) * flDistance / flRadius);
}

int WeaponKeys_GetDamageCustom(int iVictim, int iAttacker, int iWeapon, int iDamageCustom)
{
	bool bCodeBlast = (g_iWeaponKeysBlastClient != 0 && iAttacker == g_iWeaponKeysBlastClient && iWeapon == g_iWeaponKeysBlastWeapon);
	if (!bCodeBlast && iDamageCustom != TF_CUSTOM_STICKBOMB_EXPLOSION)
		return iDamageCustom;
	
	if (iVictim == iAttacker)
		return TF_CUSTOM_STICKBOMB_EXPLOSION;
	
	if (bCodeBlast)
		return TAGS_DAMAGECUSTOM_CABERMISS;
	
	if (iAttacker <= 0 || iAttacker > MaxClients || g_iWeaponKeysCaberHitTick[iAttacker] == GetGameTickCount())
		return iDamageCustom;
	
	if (Config_GetWeaponKeyFloat(iAttacker, iWeapon, "missexplode") <= 0.0)
		return iDamageCustom;
	
	return TAGS_DAMAGECUSTOM_CABERMISS;
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
