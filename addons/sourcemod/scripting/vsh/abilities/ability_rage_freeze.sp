#define FREEZE_BEGIN_SOUND "player/taunt_yeti_appear_snow.wav"
#define FREEZE_SOUND "weapons/icicle_freeze_victim_01.wav"
#define UNFREEZE_SOUND "weapons/bottle_break.wav"
#define FREEZE_PARTICLE_01 "xms_snowburst"
#define FREEZE_PARTICLE_02 "xms_icicle_impact_dryice"
#define FREEZE_PARTICLE_03 "xmas_ornament_glitter_alt"

static float g_flAbilityRadius[TF_MAXPLAYERS + 1];
static float g_flSlowDuration[TF_MAXPLAYERS + 1];
static float g_flSlowPercentage[TF_MAXPLAYERS + 1];
static float g_flFreezeDuration[TF_MAXPLAYERS + 1];
static bool g_bFreezeAffected[TF_MAXPLAYERS + 1];

methodmap CRageFreeze < SaxtonHaleBase
{
	property float flRadius
	{
		public get()
		{
			return g_flAbilityRadius[this.iClient];
		}
		public set(float flVal)
		{
			g_flAbilityRadius[this.iClient] = flVal;
		}
	}
	
	property float flSlowDuration
	{
		public get()
		{
			return g_flSlowDuration[this.iClient];
		}
		public set(float flVal)
		{
			g_flSlowDuration[this.iClient] = flVal;
		}
	}
	
	property float flSlowPercentage
	{
		public get()
		{
			return g_flSlowPercentage[this.iClient];
		}
		public set(float flVal)
		{
			g_flSlowPercentage[this.iClient] = flVal;
		}
	}
	
	property float flFreezeDuration
	{
		public get()
		{
			return g_flFreezeDuration[this.iClient];
		}
		public set(float flVal)
		{
			g_flFreezeDuration[this.iClient] = flVal;
		}
	}
	
	public CRageFreeze(CRageFreeze ability)
	{
		ability.flRadius = 800.0;
		ability.flSlowDuration = 3.0;
		ability.flSlowPercentage = 0.5;
		ability.flFreezeDuration = 4.0;
	}
	
	public void OnRage()
	{
		float vecBossOrigin[3];
		GetClientAbsOrigin(this.iClient, vecBossOrigin);
		
		float flRadius = this.flRadius;
		if (this.bSuperRage)flRadius *= 1.5;
		float flFreezeDuration = this.flFreezeDuration;
		if (this.bSuperRage)flFreezeDuration *= 1.5;
		
		for (int iClient = 1; iClient <= MaxClients; iClient++)
		{
			if (IsClientInGame(iClient) && IsPlayerAlive(iClient) && GetClientTeam(iClient) != GetClientTeam(this.iClient) && IsClientInRange(iClient, vecBossOrigin, flRadius) && !TF2_IsUbercharged(iClient))
			{
				g_bFreezeAffected[iClient] = true;
				
				float vecClientOrigin[3];
				GetClientAbsOrigin(iClient, vecClientOrigin);
				
				TF2_SpawnParticle(FREEZE_PARTICLE_01, vecClientOrigin);
				TF2_SpawnParticle(FREEZE_PARTICLE_02, vecClientOrigin);
				TF2_SpawnParticle(FREEZE_PARTICLE_03, vecClientOrigin);
				EmitAmbientSound(FREEZE_BEGIN_SOUND, vecClientOrigin);
				TF2_Shake(vecBossOrigin, 10.0, this.flRadius, 1.0, 0.5);
				TF2_StunPlayer(iClient, this.flSlowDuration, this.flSlowPercentage, TF_STUNFLAG_SLOWDOWN, this.iClient);
				
				CreateTimer(this.flSlowDuration, FreezeClient, GetClientUserId(iClient));
				CreateTimer(this.flSlowDuration + flFreezeDuration, UnfreezeClient, GetClientUserId(iClient));
			}
		}
	}
	
	public void OnThink()
	{
		for (int iClient = 1; iClient <= MaxClients; iClient++)
		{
			if (IsClientInGame(iClient) && !IsPlayerAlive(iClient))
				g_bFreezeAffected[iClient] = false;
		}
	}
	
	public void Precache()
	{
		PrecacheSound(FREEZE_BEGIN_SOUND);
		PrecacheSound(FREEZE_SOUND);
		PrecacheSound(UNFREEZE_SOUND);
		PrecacheParticleSystem(FREEZE_PARTICLE_01);
		PrecacheParticleSystem(FREEZE_PARTICLE_02);
		PrecacheParticleSystem(FREEZE_PARTICLE_03);
	}
};

public Action FreezeClient(Handle hTimer, int iUserId)
{
	int iClient = GetClientOfUserId(iUserId);
	if (0 < iClient <= MaxClients && IsClientInGame(iClient) && g_bFreezeAffected[iClient])
	{
		SetEntityMoveType(iClient, MOVETYPE_NONE);
		SetEntityRenderColor(iClient, 128, 176, 255, 255);
		float vecOrigin[3];
		GetClientAbsOrigin(iClient, vecOrigin);
		EmitAmbientSound(FREEZE_SOUND, vecOrigin);
	}
}

public Action UnfreezeClient(Handle hTimer, int iUserId)
{
	int iClient = GetClientOfUserId(iUserId);
	if (0 < iClient <= MaxClients && IsClientInGame(iClient))
	{
		SetEntityMoveType(iClient, MOVETYPE_WALK);
		SetEntityRenderColor(iClient, 255, 255, 255, 255);
		
		if (IsPlayerAlive(iClient))
		{
			float vecOrigin[3];
			GetClientAbsOrigin(iClient, vecOrigin);
			EmitAmbientSound(UNFREEZE_SOUND, vecOrigin);
		}
	}
}
