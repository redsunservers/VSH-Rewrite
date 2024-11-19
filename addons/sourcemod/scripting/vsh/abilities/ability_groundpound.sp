#define IMPACT_SOUND "player/taunt_yeti_land.wav"
#define IMPACT_PARTICLE "hammer_impact_button"

static bool g_bClientBossWeighDownForce[MAXPLAYERS];

static float g_flClientBossWeighDownTimer[MAXPLAYERS];

public void GroundPound_Create(SaxtonHaleBase boss)
{
	g_bClientBossWeighDownForce[boss.iClient] = false;
	g_flClientBossWeighDownTimer[boss.iClient] = 0.0;
	
	boss.SetPropFloat("GroundPound", "StartTimer", 2.8);
	boss.SetPropFloat("GroundPound", "GravityMultiplier", 8.0);
	boss.SetPropFloat("GroundPound", "JumpCooldown", 5.0);
	
	boss.SetPropFloat("GroundPound", "ImpactPush", 500.0);
	boss.SetPropFloat("GroundPound", "ImpactVelocity", 750.0);
	boss.SetPropFloat("GroundPound", "ImpactRadius", 400.0);
	boss.SetPropFloat("GroundPound", "ImpactDamage", 25.0);
	boss.SetPropFloat("GroundPound", "ImpactLaunchVelocity", 400.0);
}

public void GroundPound_OnThink(SaxtonHaleBase boss)
{
	if (GetEntityFlags(boss.iClient) & FL_ONGROUND)
	{
		if (g_bClientBossWeighDownForce[boss.iClient])
		{
			SetEntityGravity(boss.iClient, GetEntityGravity(boss.iClient) / boss.GetPropFloat("GroundPound", "GravityMultiplier"));
			TF2_RemoveCondition(boss.iClient, TFCond_SpeedBuffAlly);
		}
		
		//Reset weighdown timer
		g_bClientBossWeighDownForce[boss.iClient] = false;
		g_flClientBossWeighDownTimer[boss.iClient] = 0.0;
	}
	else if (g_flClientBossWeighDownTimer[boss.iClient] == 0.0 && !g_bClientBossWeighDownForce[boss.iClient])
	{
		//Start weighdown timer
		g_flClientBossWeighDownTimer[boss.iClient] = GetGameTime();
	}
}

public Action GroundPound_OnTakeDamage(SaxtonHaleBase boss, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if (!(damagetype & DMG_FALL) || !g_bClientBossWeighDownForce[boss.iClient])
		return Plugin_Continue;
	
	float vecVel[3];
	GetEntPropVector(boss.iClient, Prop_Data, "m_vecVelocity", vecVel);
	if (vecVel[2] > -boss.GetPropFloat("GroundPound", "ImpactVelocity"))
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
			float vecClientOrigin[3], vecClientVelocity[3];
			GetClientAbsOrigin(iClient, vecClientOrigin);
			GetEntPropVector(iClient, Prop_Data, "m_vecVelocity", vecClientVelocity);
			vecClientVelocity[2] += boss.GetPropFloat("GroundPound", "ImpactLaunchVelocity");
			
			float vecVelocity[3];
			SubtractVectors(vecClientOrigin, vecBossOrigin, vecVelocity);
			vecVelocity[2] = 0.0;
			NormalizeVector(vecVelocity, vecVelocity);
			ScaleVector(vecVelocity, boss.GetPropFloat("GroundPound", "ImpactPush"));
			AddVectors(vecClientVelocity, vecVelocity, vecClientVelocity);
			
			SDKHooks_TakeDamage(iClient, boss.iClient, boss.iClient, boss.GetPropFloat("GroundPound", "ImpactDamage"));
			TeleportEntity(iClient, NULL_VECTOR, NULL_VECTOR, vecClientVelocity);
		}
	}
	
	return Plugin_Continue;
}

public void GroundPound_OnButton(SaxtonHaleBase boss, int &buttons)
{
	//Is boss crouching, allowed to use weighdown if passed timer
	if (buttons & IN_DUCK
		&& !g_bClientBossWeighDownForce[boss.iClient]
		&& g_flClientBossWeighDownTimer[boss.iClient] != 0.0
		&& g_flClientBossWeighDownTimer[boss.iClient] < GetGameTime() - boss.GetPropFloat("GroundPound", "StartTimer"))
	{
		//Check if boss is looking down
		float vecAngles[3];
		GetClientEyeAngles(boss.iClient, vecAngles);
		if (vecAngles[0] > 60.0)
		{
			//Enable weighdown
			g_bClientBossWeighDownForce[boss.iClient] = true;
			g_flClientBossWeighDownTimer[boss.iClient] = 0.0;
			SetEntityGravity(boss.iClient, GetEntityGravity(boss.iClient) * boss.GetPropFloat("GroundPound", "GravityMultiplier"));
			TF2_AddCondition(boss.iClient, TFCond_SpeedBuffAlly, TFCondDuration_Infinite);

			float flJumpCooldown = boss.GetPropFloat("GroundPound", "JumpCooldown");
			
			// Add brave jump cooldown to it
			if (flJumpCooldown > 0.0 && boss.HasClass("BraveJump"))
			{
				float flCooldownWait = boss.GetPropFloat("BraveJump", "CooldownWait");
				if (flCooldownWait)
				{
					boss.SetPropFloat("BraveJump", "CooldownWait", flCooldownWait + flJumpCooldown);
					boss.CallFunction("UpdateHudInfo", 1.0, flCooldownWait + flJumpCooldown);	//Update every second for cooldown duration
				}
			}
		}
	}
}

public void GroundPound_GetSoundAbility(SaxtonHaleBase boss, char[] sSound, int iLength, const char[] sAbility)
{
	// Allow ground pound immediately on brave jump
	if (StrEqual(sAbility, "BraveJump"))
		g_flClientBossWeighDownTimer[boss.iClient] = 1.0;
}

public void GroundPound_Destroy(SaxtonHaleBase boss)
{
	if (g_bClientBossWeighDownForce[boss.iClient])
	{
		SetEntityGravity(boss.iClient, GetEntityGravity(boss.iClient) / boss.GetPropFloat("GroundPound", "GravityMultiplier"));
		TF2_RemoveCondition(boss.iClient, TFCond_SpeedBuffAlly);
	}
}

public void GroundPound_Precache(SaxtonHaleBase boss)
{
	PrecacheSound(IMPACT_SOUND);
	PrecacheParticleSystem(IMPACT_PARTICLE);
}

