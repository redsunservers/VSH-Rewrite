#define ATTRIB_MAX_MISC_AMMO	279
#define ATTRIB_EFFECTBAR_RECHARGE_RATE	278
#define WEAPONBALL_RECHARGE_TIME	10.0
#define WEAPONBALL_STOCK_DAMAGE	15.0

static int g_iWeaponBallStunType;

static float g_flWeaponBallRageEnd[MAXPLAYERS];
static float g_flWeaponBallStunTime[MAXPLAYERS];
static int g_iWeaponBallThrower[MAXPLAYERS];

#define WEAPONBALL_SOUND_STUN		"player/pl_impact_stun.wav"
#define WEAPONBALL_SOUND_STUN_RANGE	"player/pl_impact_stun_range.wav"

static float g_flWeaponBallSlowdown[MAXPLAYERS];
static int g_iWeaponBallBoss[MAXPLAYERS];
static bool g_bWeaponBallRage[MAXPLAYERS];
static float g_flWeaponBallRechargeRate[MAXPLAYERS];
static float g_flWeaponBallMarkEnd[MAXPLAYERS][MAXPLAYERS];
static int g_iWeaponBallMarkGlow[MAXPLAYERS];
static bool g_bWeaponBallWasDazed[MAXPLAYERS];
static bool g_bWeaponBallHomeRun[MAXPLAYERS];

public void WeaponBall_Create(SaxtonHaleBase boss)
{
	//Default values
	boss.SetPropInt("WeaponBall", "MaxBall", 3);
	boss.SetPropFloat("WeaponBall", "Duration", 5.0);
	boss.SetPropFloat("WeaponBall", "Slowdown", 0.8);
	boss.SetPropFloat("WeaponBall", "DamageScale", 3.75);
	boss.SetPropFloat("WeaponBall", "RageDamageScale", 4.5);
	boss.SetPropFloat("WeaponBall", "BaseDamage", 40.0);
	boss.SetPropFloat("WeaponBall", "RageBaseDamage", 80.0);
	boss.SetPropFloat("WeaponBall", "BuildingDamage", 150.0);
	boss.SetPropInt("WeaponBall", "RageBall", 5);
	boss.SetPropInt("WeaponBall", "RageMaxBall", 7);
	boss.SetPropFloat("WeaponBall", "RageRegenMultiplier", 3.0);
	boss.SetPropFloat("WeaponBall", "MarkDuration", 10.0);

	g_flWeaponBallRageEnd[boss.iClient] = 0.0;
	g_bWeaponBallRage[boss.iClient] = false;
	for (int iVictim = 0; iVictim < MAXPLAYERS; iVictim++)
		g_flWeaponBallMarkEnd[boss.iClient][iVictim] = 0.0;
}

public void WeaponBall_OnSpawn(SaxtonHaleBase boss)
{
	int iMelee = TF2_GetItemInSlot(boss.iClient, WeaponSlot_Melee);
	if (iMelee > MaxClients)
	{
		TF2Attrib_SetByDefIndex(iMelee, ATTRIB_MAX_MISC_AMMO, float(boss.GetPropInt("WeaponBall", "MaxBall")));
		TF2Attrib_ClearCache(iMelee);
		
		//Correctly set ammo
		TF2_SetAmmo(boss.iClient, TF_AMMO_GRENADES1, boss.GetPropInt("WeaponBall", "MaxBall"));
	}
}

public void WeaponBall_OnRage(SaxtonHaleBase boss)
{
	g_flWeaponBallRageEnd[boss.iClient] = GetGameTime() + (boss.bSuperRage ? boss.GetPropFloat("WeaponBall", "Duration") * 2 : boss.GetPropFloat("WeaponBall", "Duration"));

	int iClient = boss.iClient;
	int iMelee = TF2_GetItemInSlot(iClient, WeaponSlot_Melee);
	if (iMelee <= MaxClients)
		return;

	float flMultiplier = boss.GetPropFloat("WeaponBall", "RageRegenMultiplier");
	if (flMultiplier <= 0.0)
		flMultiplier = 1.0;

	int iRageMaxBall = boss.GetPropInt("WeaponBall", "RageMaxBall");

	if (!g_bWeaponBallRage[iClient])
	{
		g_bWeaponBallRage[iClient] = true;

		float flRate = 1.0;
		TF2_FindAttribute(iMelee, ATTRIB_EFFECTBAR_RECHARGE_RATE, flRate);
		g_flWeaponBallRechargeRate[iClient] = flRate;

		TF2Attrib_SetByDefIndex(iMelee, ATTRIB_MAX_MISC_AMMO, float(iRageMaxBall));
		TF2Attrib_SetByDefIndex(iMelee, ATTRIB_EFFECTBAR_RECHARGE_RATE, flRate / flMultiplier);
		TF2Attrib_ClearCache(iMelee);

		WeaponBall_ScaleRecharge(iMelee, 1.0 / flMultiplier);
	}

	int iRageBall = boss.GetPropInt("WeaponBall", "RageBall");
	if (TF2_GetAmmo(iClient, TF_AMMO_GRENADES1) < iRageBall)
		TF2_SetAmmo(iClient, TF_AMMO_GRENADES1, iRageBall);

	if (TF2_GetAmmo(iClient, TF_AMMO_GRENADES1) < iRageMaxBall && HasEntProp(iMelee, Prop_Send, "m_flEffectBarRegenTime")
		&& GetEntPropFloat(iMelee, Prop_Send, "m_flEffectBarRegenTime") <= GetGameTime())
	{
		SetEntPropFloat(iMelee, Prop_Send, "m_flEffectBarRegenTime", GetGameTime() + WEAPONBALL_RECHARGE_TIME * g_flWeaponBallRechargeRate[iClient] / flMultiplier);
	}
}

static void WeaponBall_ScaleRecharge(int iMelee, float flScale)
{
	if (!HasEntProp(iMelee, Prop_Send, "m_flEffectBarRegenTime"))
		return;

	float flNow = GetGameTime();
	float flRegenTime = GetEntPropFloat(iMelee, Prop_Send, "m_flEffectBarRegenTime");
	if (flRegenTime > flNow)
		SetEntPropFloat(iMelee, Prop_Send, "m_flEffectBarRegenTime", flNow + (flRegenTime - flNow) * flScale);
}

public void WeaponBall_OnThink(SaxtonHaleBase boss)
{
	//Unlimited ball during rage
	int iClient = boss.iClient;
	if (!g_bWeaponBallRage[iClient] || g_flWeaponBallRageEnd[iClient] > GetGameTime())
		return;

	g_bWeaponBallRage[iClient] = false;

	int iMaxBall = boss.GetPropInt("WeaponBall", "MaxBall");
	int iMelee = TF2_GetItemInSlot(iClient, WeaponSlot_Melee);
	if (iMelee > MaxClients)
	{
		float flMultiplier = boss.GetPropFloat("WeaponBall", "RageRegenMultiplier");
		if (flMultiplier <= 0.0)
			flMultiplier = 1.0;

		TF2Attrib_SetByDefIndex(iMelee, ATTRIB_MAX_MISC_AMMO, float(iMaxBall));
		TF2Attrib_SetByDefIndex(iMelee, ATTRIB_EFFECTBAR_RECHARGE_RATE, g_flWeaponBallRechargeRate[iClient]);
		TF2Attrib_ClearCache(iMelee);

		WeaponBall_ScaleRecharge(iMelee, flMultiplier);
	}

	if (TF2_GetAmmo(iClient, TF_AMMO_GRENADES1) > iMaxBall)
		TF2_SetAmmo(iClient, TF_AMMO_GRENADES1, iMaxBall);
}

public void WeaponBall_OnEntityCreated(SaxtonHaleBase boss, int iEntity, const char[] sClassname)
{
	if (strcmp(sClassname, "tf_projectile_stun_ball") == 0)
	{
		SDK_HookBallImpact(iEntity, WeaponBall_BallImpact);	//To hook when ball impacts player
		SDK_HookBallTouch(iEntity, WeaponBall_BallTouch);	//To hook when ball impacts building
	}
}

public void WeaponBall_Precache(SaxtonHaleBase boss)
{
	g_iWeaponBallStunType = FindSendPropInfo("CTFStunBall", "m_iType");
	
	PrecacheSound(WEAPONBALL_SOUND_STUN);
	PrecacheSound(WEAPONBALL_SOUND_STUN_RANGE);
}

void WeaponBall_SlowPlayer(int iVictim, float flSlowdown, float flDuration, bool bRange)
{
	if (flDuration <= 0.0)
		return;
	
	AddTemporarySlowdownToClient(iVictim, flSlowdown, flDuration);
	EmitSoundToAll(bRange ? WEAPONBALL_SOUND_STUN_RANGE : WEAPONBALL_SOUND_STUN, iVictim);
}

bool WeaponBall_IsMarked(int iBoss, int iVictim)
{
	if (iBoss <= 0 || iBoss > MaxClients || iVictim <= 0 || iVictim > MaxClients)
		return false;

	return (IsClientInGame(iVictim) && IsPlayerAlive(iVictim) && g_flWeaponBallMarkEnd[iBoss][iVictim] > GetGameTime());
}

static void WeaponBall_MarkPlayer(int iBoss, int iVictim)
{
	if (!SaxtonHale_IsValidBoss(iBoss) || iBoss == iVictim || GetClientTeam(iBoss) == GetClientTeam(iVictim))
		return;

	SaxtonHaleBase boss = SaxtonHaleBase(iBoss);
	if (!boss.HasClass("WeaponBall"))
		return;

	float flDuration = boss.GetPropFloat("WeaponBall", "MarkDuration");
	if (flDuration <= 0.0)
		return;

	g_flWeaponBallMarkEnd[iBoss][iVictim] = GetGameTime() + flDuration;
	TF2_AddCondition(iVictim, TFCond_MarkedForDeath, flDuration, iBoss);

	char sModel[PLATFORM_MAX_PATH];
	GetEntPropString(iVictim, Prop_Data, "m_ModelName", sModel, sizeof(sModel));
	if (g_iWeaponBallMarkGlow[iVictim] == 0 || !IsValidEntity(g_iWeaponBallMarkGlow[iVictim]))
	{
		g_iWeaponBallMarkGlow[iVictim] = TF2_CreateTransmitGlow(iVictim, sModel, WeaponBall_MarkGlowTransmit);
		return;
	}

	char sGlowModel[PLATFORM_MAX_PATH];
	GetEntPropString(g_iWeaponBallMarkGlow[iVictim], Prop_Data, "m_ModelName", sGlowModel, sizeof(sGlowModel));
	if (!StrEqual(sModel, sGlowModel))
		SetEntityModel(g_iWeaponBallMarkGlow[iVictim], sModel);
}

public Action WeaponBall_MarkGlowTransmit(int iEntity, int iTarget)
{
	int iVictim = GetEntPropEnt(iEntity, Prop_Data, "m_hParent");
	if (iVictim <= 0 || iVictim > MaxClients || iTarget <= 0 || iTarget > MaxClients)
		return Plugin_Stop;

	if (!WeaponBall_IsMarked(iTarget, iVictim) || !SaxtonHale_IsValidBoss(iTarget) || !IsPlayerAlive(iTarget) || GetClientTeam(iTarget) == GetClientTeam(iVictim))
		return Plugin_Stop;

	if (TF2_IsPlayerInCondition(iVictim, TFCond_Cloaked) || TF2_IsPlayerInCondition(iVictim, TFCond_Disguised) || TF2_IsPlayerInCondition(iVictim, TFCond_Stealthed))
		return Plugin_Stop;

	return Plugin_Continue;
}

static float WeaponBall_GetDamageScale(int iBoss)
{
	if (!SaxtonHale_IsValidBoss(iBoss) || !SaxtonHaleBase(iBoss).HasClass("WeaponBall"))
		return 3.0;

	if (g_flWeaponBallRageEnd[iBoss] > GetGameTime())
		return SaxtonHaleBase(iBoss).GetPropFloat("WeaponBall", "RageDamageScale");

	return SaxtonHaleBase(iBoss).GetPropFloat("WeaponBall", "DamageScale");
}

static float WeaponBall_GetBaseScale(int iBoss)
{
	if (!SaxtonHale_IsValidBoss(iBoss) || !SaxtonHaleBase(iBoss).HasClass("WeaponBall"))
		return 1.0;

	float flBase;
	if (g_flWeaponBallRageEnd[iBoss] > GetGameTime())
		flBase = SaxtonHaleBase(iBoss).GetPropFloat("WeaponBall", "RageBaseDamage");
	else
		flBase = SaxtonHaleBase(iBoss).GetPropFloat("WeaponBall", "BaseDamage");

	if (flBase <= 0.0)
		return 1.0;

	float flStock = WEAPONBALL_STOCK_DAMAGE;
	ConVar cvStock = FindConVar("sv_proj_stunball_damage");
	if (cvStock != null && cvStock.FloatValue > 0.0)
		flStock = cvStock.FloatValue;

	return flBase / flStock;
}

public MRESReturn WeaponBall_BallImpact(int iEntity, Handle hParams)
{
	//Get victim whos stunned from ball
	int iVictim = DHookGetParam(hParams, 1);
	if (iVictim <= 0 || iVictim > MaxClients || !IsClientInGame(iVictim))
		return MRES_Ignored;
	
	//Check if valid ball from Bonk Boy
	int iThrower;
	float flTime;
	if (!WeaponBall_IsValidBall(iEntity, iThrower, flTime))
		return MRES_Ignored;
	
	g_flWeaponBallStunTime[iVictim] = flTime;
	g_iWeaponBallThrower[iVictim] = iThrower;
	
	g_bWeaponBallWasDazed[iVictim] = TF2_IsPlayerInCondition(iVictim, TFCond_Dazed);
	g_bWeaponBallHomeRun[iVictim] = false;
	g_flWeaponBallSlowdown[iVictim] = SaxtonHaleBase(GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity")).GetPropFloat("WeaponBall", "Slowdown");
	g_iWeaponBallBoss[iVictim] = GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity");
	
	SDKHook(iVictim, SDKHook_OnTakeDamageAlive, WeaponBall_OnTakeDamage);
	HookEvent("player_death", WeaponBall_PlayerDeath, EventHookMode_Pre);
	RequestFrame(WeaponBall_UnhookBallDamage, GetClientUserId(iVictim));
	return MRES_Ignored;
}

public MRESReturn WeaponBall_BallTouch(int iEntity, Handle hReturn, Handle hParams)
{
	if (GetEntProp(iEntity, Prop_Send, "m_bTouched"))
		return MRES_Ignored;
	
	//Check if toucher is building
	int iBuilding = DHookGetParam(hParams, 1);
	if (iBuilding <= MaxClients)
		return MRES_Ignored;
	
	char sClassname[256];
	GetEntityClassname(iBuilding, sClassname, sizeof(sClassname));
	if (StrContains(sClassname, "obj_") != 0)
		return MRES_Ignored;
	
	//Check if valid ball from Bonk Boy
	int iThrower;
	float flTime;
	if (!WeaponBall_IsValidBall(iEntity, iThrower, flTime))
		return MRES_Ignored;
	
	//Team check
	if (GetEntProp(iBuilding, Prop_Send, "m_iTeamNum") == GetClientTeam(iThrower))
		return MRES_Ignored;
	
	//Deal damage
	SDKHooks_TakeDamage(iBuilding, iThrower, iThrower, SaxtonHaleBase(GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity")).GetPropFloat("WeaponBall", "BuildingDamage"), DMG_CRIT);
	
	//Stun building
	TF2_StunBuilding(iBuilding, flTime * 8.0);
	
	//Mark ball as touched
	SetEntProp(iEntity, Prop_Send, "m_bTouched", true);
	return MRES_Ignored;
}

bool WeaponBall_IsValidBall(int iEntity, int &iThrower = 0, float &flTime = 0.0)
{
	//Check if ball came from owner with ability
	int iOwner = GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity");
	if (!SaxtonHale_IsValidBoss(iOwner))
		return false;
	
	SaxtonHaleBase boss = SaxtonHaleBase(iOwner);
	if (!boss.HasClass("WeaponBall"))
		return false;
	
	//Get whoever threw the ball, either from bonk boy, or from deflected pyro
	iThrower = GetEntPropEnt(iEntity, Prop_Send, "m_hThrower");
	if (iThrower <= 0 || iThrower > MaxClients || !IsClientInGame(iThrower))
		return false;
	
	//Sandman init time is stored in m_iType + 4 offset
	flTime = GetGameTime() - GetEntDataFloat(iEntity, g_iWeaponBallStunType + 0x04);
	return true;
}

public Action WeaponBall_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	Action action = Plugin_Continue;
	
	if (damagecustom == TF_CUSTOM_BASEBALL && g_flWeaponBallStunTime[victim] > 0.0)
	{
		attacker = g_iWeaponBallThrower[victim];
		g_iWeaponBallThrower[victim] = 0;
		action = Plugin_Changed;
		
		if (g_flWeaponBallStunTime[victim] > 0.85)
		{
			//Home run baby
			damage = 1337.0;
			g_bWeaponBallHomeRun[victim] = true;
			WeaponBall_SlowPlayer(victim, g_flWeaponBallSlowdown[victim], 10.0, true);
		}
		else if (g_flWeaponBallStunTime[victim] > 0.10)
		{
			//Not so home run
			damage *= g_flWeaponBallStunTime[victim] * WeaponBall_GetDamageScale(g_iWeaponBallBoss[victim]);
			damage *= WeaponBall_GetBaseScale(g_iWeaponBallBoss[victim]);
			WeaponBall_SlowPlayer(victim, g_flWeaponBallSlowdown[victim], g_flWeaponBallStunTime[victim] * 8.0, false);
		}
		else
		{
			damage *= WeaponBall_GetBaseScale(g_iWeaponBallBoss[victim]);
		}
		
		g_flWeaponBallStunTime[victim] = 0.0;

		WeaponBall_MarkPlayer(g_iWeaponBallBoss[victim], victim);
	}

	return action;
}

public void WeaponBall_PlayerDeath(Event event, const char[] sName, bool bDontBroadcast)
{
	int iVictim = GetClientOfUserId(event.GetInt("userid"));
	bool bHomeRun = (0 < iVictim <= MaxClients && g_bWeaponBallHomeRun[iVictim]);
	if (event.GetInt("customkill") == TF_CUSTOM_BASEBALL && (bHomeRun || event.GetInt("stun_flags") == TF_STUNFLAGS_BIGBONK))
	{
		event.SetInt("customkill", TF_CUSTOM_TAUNT_GRAND_SLAM);
		event.SetString("weapon", "taunt_scout");
		event.SetString("weapon_logclassname", "taunt_scout");
	}
}

public void WeaponBall_UnhookBallDamage(int iUserId)
{
	int iClient = GetClientOfUserId(iUserId);
	if (0 < iClient <= MaxClients && IsClientInGame(iClient))
	{
		SDKUnhook(iClient, SDKHook_OnTakeDamageAlive, WeaponBall_OnTakeDamage);
		
		if (!g_bWeaponBallWasDazed[iClient] && TF2_IsPlayerInCondition(iClient, TFCond_Dazed))
			TF2_RemoveCondition(iClient, TFCond_Dazed);
		
		g_bWeaponBallHomeRun[iClient] = false;
	}
	
	UnhookEvent("player_death", WeaponBall_PlayerDeath, EventHookMode_Pre);
}
