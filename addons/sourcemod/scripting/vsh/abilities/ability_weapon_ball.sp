#define ATTRIB_MAX_MISC_AMMO	279

static int g_iWeaponBallStunType;

static int g_iWeaponBallMax[TF_MAXPLAYERS+1];
static float g_flWeaponBallDuration[TF_MAXPLAYERS+1];
static float g_flWeaponBallRageEnd[TF_MAXPLAYERS+1];
static float g_flWeaponBallStunTime[TF_MAXPLAYERS+1];
static int g_iWeaponBallThrower[TF_MAXPLAYERS+1];

methodmap CWeaponBall < SaxtonHaleBase
{
	property int iMaxBall
	{
		public get()
		{
			return g_iWeaponBallMax[this.iClient];
		}
		
		public set(int iVal)
		{
			g_iWeaponBallMax[this.iClient] = iVal;
		}
	}
	
	property float flDuration
	{
		public get()
		{
			return g_flWeaponBallDuration[this.iClient];
		}
		
		public set(float flVal)
		{
			g_flWeaponBallDuration[this.iClient] = flVal;
		}
	}
	
	public CWeaponBall(CWeaponBall ability)
	{
		//Default values
		ability.iMaxBall = 3;
		ability.flDuration = 5.0;
		
		g_flWeaponBallRageEnd[ability.iClient] = 0.0;
	}
	
	public void OnSpawn()
	{
		int iMelee = TF2_GetItemInSlot(this.iClient, WeaponSlot_Melee);
		if (iMelee > MaxClients)
		{
			TF2Attrib_SetByDefIndex(iMelee, ATTRIB_MAX_MISC_AMMO, float(this.iMaxBall));
			TF2Attrib_ClearCache(iMelee);
			
			//Correctly set ammo
			TF2_SetAmmo(this.iClient, WeaponSlot_Melee, this.iMaxBall);
		}
	}
	
	public void OnRage()
	{
		g_flWeaponBallRageEnd[this.iClient] = GetGameTime() + (this.bSuperRage ? this.flDuration * 2 : this.flDuration);
	}
	
	public void OnThink()
	{
		//Unlimited ball during rage
		if (g_flWeaponBallRageEnd[this.iClient] > GetGameTime())
			TF2_SetAmmo(this.iClient, WeaponSlot_Melee, this.iMaxBall);
	}
	
	public void OnBallCreated(int iEntity)
	{
		SDK_HookBallImpact(iEntity, WeaponBall_BallImpact);	//To hook when ball impacts player
		SDK_HookBallTouch(iEntity, WeaponBall_BallTouch);	//To hook when ball impacts building
	}
	
	public void Precache()
	{
		g_iWeaponBallStunType = FindSendPropInfo("CTFStunBall", "m_iType");
		
		this.CallFunction("HookEntityCreated", "tf_projectile_stun_ball", "CWeaponBall", "OnBallCreated");
	}
};

public MRESReturn WeaponBall_BallImpact(int iEntity, Handle hParams)
{
	//Get victim whos stunned from ball
	int iVictim = DHookGetParam(hParams, 1);
	if (iVictim <= 0 || iVictim > MaxClients || !IsClientInGame(iVictim))
		return;
	
	//Check if valid ball from Bonk Boy
	int iThrower;
	float flTime;
	if (!WeaponBall_IsValidBall(iEntity, iThrower, flTime))
		return;
	
	g_flWeaponBallStunTime[iVictim] = flTime;
	g_iWeaponBallThrower[iVictim] = iThrower;
	
	SDKHook(iVictim, SDKHook_OnTakeDamageAlive, WeaponBall_OnTakeDamage);
	HookEvent("player_death", WeaponBall_PlayerDeath, EventHookMode_Pre);
	RequestFrame(WeaponBall_UnhookBallDamage, GetClientUserId(iVictim));
}

public MRESReturn WeaponBall_BallTouch(int iEntity, Handle hReturn, Handle hParams)
{
	if (GetEntProp(iEntity, Prop_Send, "m_bTouched"))
		return;
	
	//Check if toucher is building
	int iBuilding = DHookGetParam(hParams, 1);
	if (iBuilding <= MaxClients)
		return;
	
	char sClassname[256];
	GetEntityClassname(iBuilding, sClassname, sizeof(sClassname));
	if (StrContains(sClassname, "obj_") != 0)
		return;
	
	//Check if valid ball from Bonk Boy
	int iThrower;
	float flTime;
	if (!WeaponBall_IsValidBall(iEntity, iThrower, flTime))
		return;
	
	//Team check
	if (GetEntProp(iBuilding, Prop_Send, "m_iTeamNum") == GetClientTeam(iThrower))
		return;
	
	//Deal damage
	SDKHooks_TakeDamage(iBuilding, iThrower, iThrower, flTime * 120.0, DMG_CRIT);
	
	//Stun building
	TF2_StunBuilding(iBuilding, flTime * 8.0);
	
	//Mark ball as touched
	SetEntProp(iEntity, Prop_Send, "m_bTouched", true);
}

bool WeaponBall_IsValidBall(int iEntity, int &iThrower = 0, float &flTime = 0.0)
{
	//Check if ball came from owner with ability
	int iOwner = GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity");
	if (!SaxtonHale_IsValidBoss(iOwner))
		return false;
	
	SaxtonHaleBase boss = SaxtonHaleBase(iOwner);
	if (boss.CallFunction("FindAbility", "CWeaponBall") == INVALID_ABILITY)
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
			TF2_StunPlayer(victim, 10.0, _, TF_STUNFLAGS_BIGBONK, attacker);
		}
		else if (g_flWeaponBallStunTime[victim] > 0.10)
		{
			//Not so home run
			damage *= g_flWeaponBallStunTime[victim] * 8.0;
			TF2_StunPlayer(victim, g_flWeaponBallStunTime[victim] * 8.0, _, TF_STUNFLAGS_SMALLBONK, attacker);
		}
		
		g_flWeaponBallStunTime[victim] = 0.0;
	}
	
	return action;
}

public Action WeaponBall_PlayerDeath(Event event, const char[] sName, bool bDontBroadcast)
{
	if (event.GetInt("customkill") == TF_CUSTOM_BASEBALL && event.GetInt("stun_flags") == TF_STUNFLAGS_BIGBONK)
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
		SDKUnhook(iClient, SDKHook_OnTakeDamageAlive, WeaponBall_OnTakeDamage);
	
	UnhookEvent("player_death", WeaponBall_PlayerDeath, EventHookMode_Pre);
}