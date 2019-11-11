#define FREEZE_BEGIN_SOUND "player/taunt_yeti_appear_snow.wav"
#define FREEZE_SOUND "weapons/icicle_freeze_victim_01.wav"
#define UNFREEZE_SOUND "weapons/bottle_break.wav"
#define FREEZE_PARTICLE_01 "xms_snowburst"
#define FREEZE_PARTICLE_02 "xms_icicle_impact_dryice"
#define FREEZE_PARTICLE_03 "xmas_ornament_glitter_alt"

static float g_flAbilityRadius[TF_MAXPLAYERS + 1];
static float g_flSlowDuration[TF_MAXPLAYERS + 1];
static float g_flFreezeDuration[TF_MAXPLAYERS + 1];

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
		ability.flFreezeDuration = 5.0;
	}
	
	public void OnRage()
	{
		float flBossOrigin[3];
		GetClientAbsOrigin(this.iClient, flBossOrigin);
		
		FakeClientCommand(this.iClient, "voicemenu %d %d", 2, 1);
		
		for (int iClient = 1; iClient <= MaxClients; iClient++)
		{
			if (IsClientInGame(iClient) && GetClientTeam(iClient) != GetClientTeam(this.iClient) && IsClientInRange(iClient, flBossOrigin, this.flRadius))
			{
				float flClientOrigin[3];
				GetClientAbsOrigin(iClient, flClientOrigin);
				float flClientAngles[3];
				GetClientAbsAngles(iClient, flClientAngles);
				
				TF2_SpawnParticle(FREEZE_PARTICLE_01, flClientOrigin, flClientAngles, _, iClient);
				TF2_SpawnParticle(FREEZE_PARTICLE_02, flClientOrigin, flClientAngles, _, iClient);
				TF2_SpawnParticle(FREEZE_PARTICLE_03, flClientOrigin, flClientAngles, _, iClient);
				EmitAmbientSound(FREEZE_BEGIN_SOUND, flClientOrigin);
				TF2_Shake(flBossOrigin, 10.0, this.flRadius, 1.0, 0.5);
				TF2_StunPlayer(iClient, this.flSlowDuration, 0.75, TF_STUNFLAG_SLOWDOWN, this.iClient);
				
				CreateTimer(this.flSlowDuration, FreezeClient, GetClientUserId(iClient));
				CreateTimer(this.flSlowDuration + this.flFreezeDuration, UnfreezeClient, GetClientUserId(iClient));
			}
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
	SetEntityMoveType(iClient, MOVETYPE_NONE);
	float flOrigin[3];
	GetClientAbsOrigin(iClient, flOrigin);
	EmitAmbientSound(FREEZE_SOUND, flOrigin);
}

public Action UnfreezeClient(Handle hTimer, int iUserId)
{
	int iClient = GetClientOfUserId(iUserId);
	SetEntityMoveType(iClient, MOVETYPE_WALK);
	float flOrigin[3];
	GetClientAbsOrigin(iClient, flOrigin);
	EmitAmbientSound(UNFREEZE_SOUND, flOrigin);
} 