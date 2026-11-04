#define ATTRIB_MAX_MISC_AMMO	279

static int g_iWeaponBallStunType;

static float g_flWeaponBallRageEnd[MAXPLAYERS];
static float g_flWeaponBallStunTime[MAXPLAYERS];
static int g_iWeaponBallThrower[MAXPLAYERS];

#define WEAPONBALL_SOUND_STUN		"player/pl_impact_stun.wav"
#define WEAPONBALL_SOUND_STUN_RANGE	"player/pl_impact_stun_range.wav"

static float g_flWeaponBallSlowdown[MAXPLAYERS];
static float g_flWeaponBallSlowEnd[MAXPLAYERS];
static bool g_bWeaponBallWasDazed[MAXPLAYERS];
static bool g_bWeaponBallHomeRun[MAXPLAYERS];

public void WeaponBall_Create(SaxtonHaleBase boss)
{
	//Default values
	boss.SetPropInt("WeaponBall", "MaxBall", 3);
	boss.SetPropFloat("WeaponBall", "Duration", 5.0);
	boss.SetPropFloat("WeaponBall", "Slowdown", 0.8);
	
	g_flWeaponBallRageEnd[boss.iClient] = 0.0;
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
}

public void WeaponBall_OnThink(SaxtonHaleBase boss)
{
	//Unlimited ball during rage
	if (g_flWeaponBallRageEnd[boss.iClient] > GetGameTime())
		TF2_SetAmmo(boss.iClient, TF_AMMO_GRENADES1, boss.GetPropInt("WeaponBall", "MaxBall"));
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
	
	float flEnd = GetGameTime() + flDuration;
	if (flEnd > g_flWeaponBallSlowEnd[iVictim])
		g_flWeaponBallSlowEnd[iVictim] = flEnd;
}

bool WeaponBall_IsSlowed(int iVictim)
{
	return (0 < iVictim <= MaxClients && IsClientInGame(iVictim) && IsPlayerAlive(iVictim) && g_flWeaponBallSlowEnd[iVictim] > GetGameTime());
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
	SDKHooks_TakeDamage(iBuilding, iThrower, iThrower, flTime * 120.0, DMG_CRIT);
	
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
			damage *= g_flWeaponBallStunTime[victim] * 3.0;
			WeaponBall_SlowPlayer(victim, g_flWeaponBallSlowdown[victim], g_flWeaponBallStunTime[victim] * 8.0, false);
		}
		
		g_flWeaponBallStunTime[victim] = 0.0;
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
