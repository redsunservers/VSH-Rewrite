#define IMPACT_SOUND "player/taunt_yeti_land.wav"
#define IMPACT_PARTICLE "hammer_impact_button"

public void GroundPound_Create(SaxtonHaleBase boss)
{
	boss.SetPropFloat("GroundPound", "ImpactRadius", 500.0);
	boss.SetPropFloat("GroundPound", "ImpactDamage", 50.0);
	boss.SetPropFloat("GroundPound", "ImpactLaunchVelocity", 650.0);
}

public Action GroundPound_OnTakeDamage(SaxtonHaleBase boss, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if (!(damagetype & DMG_FALL))
		return Plugin_Continue;
	
	float vecBossOrigin[3];
	GetClientAbsOrigin(boss.iClient, vecBossOrigin);
	
	EmitAmbientSound(IMPACT_SOUND, vecBossOrigin, _, SNDLEVEL_SCREAMING);
	TF2_Shake(vecBossOrigin, 10.0, boss.GetPropFloat("GroundPound", "ImpactRadius"), 1.0, 0.5);
	TF2_SpawnParticle(IMPACT_PARTICLE, vecBossOrigin);
	
	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if (IsClientInGame(iClient) && GetClientTeam(iClient) != GetClientTeam(boss.iClient) && IsClientInRange(iClient, vecBossOrigin, boss.GetPropFloat("GroundPound", "ImpactRadius")) && GetEntityFlags(iClient) & FL_ONGROUND)
		{
			float vecClientVelocity[3];
			GetEntPropVector(iClient, Prop_Data, "m_vecVelocity", vecClientVelocity);
			vecClientVelocity[2] += boss.GetPropFloat("GroundPound", "ImpactLaunchVelocity");
			
			TeleportEntity(iClient, NULL_VECTOR, NULL_VECTOR, vecClientVelocity);
			SDKHooks_TakeDamage(iClient, boss.iClient, boss.iClient, boss.GetPropFloat("GroundPound", "ImpactDamage"));
		}
	}
	
	return Plugin_Continue;
}

public void GroundPound_Precache(SaxtonHaleBase boss)
{
	PrecacheSound(IMPACT_SOUND);
	PrecacheParticleSystem(IMPACT_PARTICLE);
}

