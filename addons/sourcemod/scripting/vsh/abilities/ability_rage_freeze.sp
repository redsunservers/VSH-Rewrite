#define FREEZE_BEGIN_SOUND "player/taunt_yeti_appear_snow.wav"
#define FREEZE_SOUND "weapons/icicle_freeze_victim_01.wav"
#define UNFREEZE_SOUND "weapons/bottle_break.wav"
#define FREEZE_PARTICLE_01 "xms_snowburst"
#define FREEZE_PARTICLE_02 "xms_icicle_impact_dryice"
#define FREEZE_PARTICLE_03 "xmas_ornament_glitter_alt"

static bool g_bFreezeAffected[MAXPLAYERS];

public void RageFreeze_Create(SaxtonHaleBase boss)
{
	boss.SetPropFloat("RageFreeze", "Radius", 800.0);
	boss.SetPropFloat("RageFreeze", "SlowDuration", 2.0);
	boss.SetPropFloat("RageFreeze", "SlowPercentage", 0.5);
	boss.SetPropFloat("RageFreeze", "FreezeDuration", 4.0);
	boss.SetPropFloat("RageFreeze", "RageFreezeSuperRageMultiplier", 1.5);
}

public void RageFreeze_OnRage(SaxtonHaleBase boss)
{
	float vecBossOrigin[3];
	GetClientAbsOrigin(boss.iClient, vecBossOrigin);
	
	float flRadius = boss.GetPropFloat("RageFreeze", "Radius");
	if (boss.bSuperRage)flRadius *= boss.GetPropFloat("RageFreeze", "RageFreezeSuperRageMultiplier");
	float flFreezeDuration = boss.GetPropFloat("RageFreeze", "FreezeDuration");
	if (boss.bSuperRage)flFreezeDuration *= boss.GetPropFloat("RageFreeze", "RageFreezeSuperRageMultiplier");
	
	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if (IsClientInGame(iClient) && IsPlayerAlive(iClient) && GetClientTeam(iClient) != GetClientTeam(boss.iClient) && IsClientInRange(iClient, vecBossOrigin, flRadius) && !TF2_IsUbercharged(iClient))
		{
			g_bFreezeAffected[iClient] = true;
			
			float vecClientOrigin[3];
			GetClientAbsOrigin(iClient, vecClientOrigin);
			
			TF2_SpawnParticle(FREEZE_PARTICLE_01, vecClientOrigin);
			TF2_SpawnParticle(FREEZE_PARTICLE_02, vecClientOrigin);
			TF2_SpawnParticle(FREEZE_PARTICLE_03, vecClientOrigin);
			EmitAmbientSound(FREEZE_BEGIN_SOUND, vecClientOrigin);
			TF2_Shake(vecBossOrigin, 10.0, boss.GetPropFloat("RageFreeze", "Radius"), 1.0, 0.5);
			TF2_StunPlayer(iClient, boss.GetPropFloat("RageFreeze", "SlowDuration"), boss.GetPropFloat("RageFreeze", "SlowPercentage"), TF_STUNFLAG_SLOWDOWN, boss.iClient);
			
			CreateTimer(boss.GetPropFloat("RageFreeze", "SlowDuration"), FreezeClient, GetClientUserId(iClient));
			CreateTimer(boss.GetPropFloat("RageFreeze", "SlowDuration") + flFreezeDuration, UnfreezeClient, GetClientUserId(iClient));
		}
	}
}

public void RageFreeze_OnThink(SaxtonHaleBase boss)
{
	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if (IsClientInGame(iClient) && !IsPlayerAlive(iClient))
			g_bFreezeAffected[iClient] = false;
	}
}

public void RageFreeze_Precache(SaxtonHaleBase boss)
{
	PrecacheSound(FREEZE_BEGIN_SOUND);
	PrecacheSound(FREEZE_SOUND);
	PrecacheSound(UNFREEZE_SOUND);
	PrecacheParticleSystem(FREEZE_PARTICLE_01);
	PrecacheParticleSystem(FREEZE_PARTICLE_02);
	PrecacheParticleSystem(FREEZE_PARTICLE_03);
}

public Action FreezeClient(Handle hTimer, int iUserId)
{
	int iClient = GetClientOfUserId(iUserId);
	if (0 < iClient <= MaxClients && IsClientInGame(iClient) && g_bFreezeAffected[iClient])
	{
		TF2_AddCondition(iClient, TFCond_FreezeInput, TFCondDuration_Infinite);
		SetEntityRenderColor(iClient, 128, 176, 255, 255);
		float vecOrigin[3];
		GetClientAbsOrigin(iClient, vecOrigin);
		EmitAmbientSound(FREEZE_SOUND, vecOrigin);
	}
	
	return Plugin_Continue;
}

public Action UnfreezeClient(Handle hTimer, int iUserId)
{
	int iClient = GetClientOfUserId(iUserId);
	if (0 < iClient <= MaxClients && IsClientInGame(iClient))
	{
		if (IsPlayerAlive(iClient))
		{
			TF2_RemoveCondition(iClient, TFCond_FreezeInput);
			SetEntityRenderColor(iClient, 255, 255, 255, 255);
			float vecOrigin[3];
			GetClientAbsOrigin(iClient, vecOrigin);
			EmitAmbientSound(UNFREEZE_SOUND, vecOrigin);
		}
	}
	
	return Plugin_Continue;
}

