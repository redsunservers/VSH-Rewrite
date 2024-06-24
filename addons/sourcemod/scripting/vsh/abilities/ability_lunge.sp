static float g_flLungeCooldownWait[MAXPLAYERS];
static bool g_bLungeActive[MAXPLAYERS];
static bool g_bAlreadyHit[MAXPLAYERS];
static Handle g_hCollisionTimer[MAXPLAYERS];
static float g_flLungeStartTime[MAXPLAYERS];
static float g_flLungeNextPushAt[MAXPLAYERS];
static float g_vecLungeInitialAngles[MAXPLAYERS][3];

public void Lunge_Create(SaxtonHaleBase boss)
{
	g_flLungeCooldownWait[boss.iClient] = 0.0;
	g_bLungeActive[boss.iClient] = false;
	
	boss.SetPropFloat("Lunge", "Cooldown", 10.0);
	boss.SetPropFloat("Lunge", "RageCost", 0.0);
	boss.SetPropFloat("Lunge", "MaxDamage", 100.0);
	boss.SetPropFloat("Lunge", "MaxForce", 1100.0);
	boss.SetPropFloat("Lunge", "JumpCooldown", 1.0);
}

public void Lunge_GetHudInfo(SaxtonHaleBase boss, char[] sMessage, int iLength, int iColor[4])
{
	float flPercentage = 1.0 - ((g_flLungeCooldownWait[boss.iClient]-GetGameTime()) / boss.GetPropFloat("Lunge", "Cooldown"));
	if (flPercentage > 1.0)
		flPercentage = 1.0;

	float flCost = boss.GetPropFloat("Lunge", "RageCost");
	
	if (flCost > 0.0)
	{
		if (flPercentage == 1.0 && CanLunge(boss))
			Format(sMessage, iLength, "%s\nLunge: %.0f%%%%%%%% - Press reload and consume %.0f%%%%%%%% of your rage!", sMessage, flPercentage * 100.0, flCost);
		else
			Format(sMessage, iLength, "%s\nLunge: %.0f%%%%", sMessage, flPercentage * 100.0);
	}
	else
	{
		if (flPercentage == 1.0 && CanLunge(boss))
			Format(sMessage, iLength, "%s\nLunge: %.0f%%%%%%%% - Press reload to use your lunge!", sMessage, flPercentage * 100.0);
		else
			Format(sMessage, iLength, "%s\nLunge: %.0f%%%%", sMessage, flPercentage * 100.0);
	}
}

static bool CanLunge(SaxtonHaleBase boss)
{
	return !TF2_IsPlayerInCondition(boss.iClient, TFCond_Dazed) &&
		!TF2_IsPlayerInCondition(boss.iClient, TFCond_Taunting) &&
		GetEntProp(boss.iClient, Prop_Send, "m_nWaterLevel") < 2 &&
		GetEntityGravity(boss.iClient) < 6.0
}

public void Lunge_OnPlayerKilled(SaxtonHaleBase boss, Event event, int iVictim)
{
	KillIconShared(boss, event, true);
}

public void Lunge_OnDestroyObject(SaxtonHaleBase boss, Event event)
{
	KillIconShared(boss, event, false);
}

static void KillIconShared(SaxtonHaleBase boss, Event event, bool bLog)
{
	if (g_bLungeActive[boss.iClient])
	{
		if (bLog)
			event.SetString("weapon_logclassname", "lunge");
		
		event.SetString("weapon", "apocofists");
	}
}

public void Lunge_OnButtonPress(SaxtonHaleBase boss, int iButton)
{
	if (iButton == IN_RELOAD && GameRules_GetRoundState() != RoundState_Preround && CanLunge(boss))
	{
		if (g_flLungeCooldownWait[boss.iClient] > GetGameTime())
			return;
		
		float flRage = (float(boss.iRageDamage) / float(boss.iMaxRageDamage)) * 100.0;
		if (flRage < boss.GetPropFloat("Lunge", "RageCost"))
			return;
		
		boss.iRageDamage -= RoundFloat(boss.GetPropFloat("Lunge", "RageCost") / 100.0 * float(boss.iMaxRageDamage));
		g_flLungeCooldownWait[boss.iClient] = GetGameTime() + boss.GetPropFloat("Lunge", "Cooldown");
		boss.CallFunction("UpdateHudInfo", 0.0, boss.GetPropFloat("Lunge", "Cooldown") * 2);
		
		char sSound[PLATFORM_MAX_PATH];
		boss.CallFunction("GetSoundAbility", sSound, sizeof(sSound), "Lunge");
		if (!StrEmpty(sSound))
			EmitSoundToAll(sSound, boss.iClient, SNDCHAN_VOICE, SNDLEVEL_SCREAMING);
		
		if (boss.HasClass("BraveJump"))
		{
			float flCooldownWait = boss.GetPropFloat("BraveJump", "CooldownWait");
			if (flCooldownWait)
			{
				if (flCooldownWait < GetGameTime())
					flCooldownWait = GetGameTime();
				
				boss.SetPropFloat("BraveJump", "CooldownWait", flCooldownWait + boss.GetPropFloat("Lunge", "JumpCooldown"));
			}
		}
		
		int iTeam = GetClientTeam(boss.iClient);
		for (int iVictim = 1; iVictim <= MaxClients; iVictim++)
		{
			g_bAlreadyHit[iVictim] = false;

			if (iVictim != boss.iClient)
			{
				if (!IsClientInGame(iVictim) || !IsPlayerAlive(iVictim) || GetClientTeam(iVictim) == iTeam)
					continue;
			}

			SetEntityCollisionGroup(iVictim, COLLISION_GROUP_DEBRIS_TRIGGER);
			
			if (g_hCollisionTimer[iVictim] == null)
				g_hCollisionTimer[iVictim] = CreateTimer(0.1, RevertCollisionGroup, GetClientUserId(iVictim), TIMER_REPEAT);
		}
		
		g_bLungeActive[boss.iClient] = true;
		g_flLungeStartTime[boss.iClient] = GetGameTime();
		g_flLungeNextPushAt[boss.iClient] = g_flLungeStartTime[boss.iClient] + 0.05;
		
		TF2_AddCondition(boss.iClient, TFCond_HalloweenKartDash, -1.0);	// For animation
		TF2_AddCondition(boss.iClient, TFCond_MegaHeal, -1.0);
		
		GetClientEyeAngles(boss.iClient, g_vecLungeInitialAngles[boss.iClient]);
		
		// Restrict going heavily upwards/downwards
		if(g_vecLungeInitialAngles[boss.iClient][0] > 45.0)
		{
			g_vecLungeInitialAngles[boss.iClient][0] = 45.0;
		}
		else if(g_vecLungeInitialAngles[boss.iClient][0] < -45.0)
		{
			g_vecLungeInitialAngles[boss.iClient][0] = -45.0;
		}

		float vecVelocity[3];
		GetAngleVectors(g_vecLungeInitialAngles[boss.iClient], vecVelocity, NULL_VECTOR, NULL_VECTOR);
		ScaleVector(vecVelocity, boss.GetPropFloat("Lunge", "MaxForce"));

		if ((GetEntityFlags(boss.iClient) & FL_ONGROUND) == 0)
			vecVelocity[2] += 50.0;
		else if (vecVelocity[2] < 310.0)
			vecVelocity[2] = 310.0;
		
		TeleportEntity(boss.iClient, NULL_VECTOR, NULL_VECTOR, vecVelocity);
	}
}

public void Lunge_OnThink(SaxtonHaleBase boss)
{
	if (g_bLungeActive[boss.iClient])
	{
		// Grace period before checking conditions
		if ((GetGameTime() - g_flLungeStartTime[boss.iClient]) > 0.1)
		{
			// End after 1 second or touching ground/water
			if ((GetGameTime() - g_flLungeStartTime[boss.iClient]) > 1.0 || (GetEntityFlags(boss.iClient) & FL_ONGROUND) != 0 || GetEntProp(boss.iClient, Prop_Send, "m_nWaterLevel") > 1)
			{
				g_bLungeActive[boss.iClient] = false;
				TF2_RemoveCondition(boss.iClient, TFCond_HalloweenKartDash);
				TF2_RemoveCondition(boss.iClient, TFCond_MegaHeal);
				return;
			}
		}

		float vecAngles[3], vecBoss[3], vecVelocity[3], vecVictim[3];
		vecAngles[1] = g_vecLungeInitialAngles[boss.iClient][1];

		GetClientAbsOrigin(boss.iClient, vecBoss);
		static float vecHitPos[3];
		TR_TraceRayFilter(vecBoss, vecAngles, MASK_PLAYERSOLID, RayType_Infinite, TraceRay_HitWallOnly);
		TR_GetEndPosition(vecHitPos);
		float flDistance = GetVectorDistance(vecBoss, vecHitPos);
		float flMaxDistance = flDistance;
		if (flMaxDistance > 30.0)
			flMaxDistance = 30.0;
		
		ConstrainDistance(vecBoss, vecHitPos, flDistance, flMaxDistance - 0.1);

		float flDamage = boss.GetPropFloat("Lunge", "MaxDamage");
		float flForce = boss.GetPropFloat("Lunge", "MaxForce") * 1.2;
		
		int iTeam = GetClientTeam(boss.iClient);
		for (int iVictim = 1; iVictim <= MaxClients; iVictim++)
		{
			if (g_bAlreadyHit[iVictim] || !IsClientInGame(iVictim) || !IsPlayerAlive(iVictim) || GetClientTeam(iVictim) == iTeam)
				continue;

			// cylinder collision check
			GetClientAbsOrigin(iVictim, vecVictim);
			if (!CylinderCollision(vecHitPos, vecVictim, 60.0, vecHitPos[2] - 103.0, vecHitPos[2] + 95.0))
				continue;

			if (HasLineOfSight(vecHitPos, vecVictim, 41.5))
			{
				g_bAlreadyHit[iVictim] = true;
				CreateTimer(1.0, Timer_EntityCleanup, TF2_SpawnParticle("taunt_headbutt_impact_stars", vecVictim, vecAngles));

				vecAngles[0] = vecVictim[0] - vecHitPos[0];
				vecAngles[1] = vecVictim[1] - vecHitPos[1];
				vecAngles[2] = vecVictim[2] - vecHitPos[2];
				GetVectorAngles(vecAngles, vecAngles);
				GetAngleVectors(vecAngles, vecVelocity, NULL_VECTOR, NULL_VECTOR);
				ScaleVector(vecVelocity, flForce);
				
				if ((GetEntityFlags(iVictim) & FL_ONGROUND) != 0 && vecVelocity[2] < 300.0)
					vecVelocity[2] = 300.0;
				else if (vecVelocity[2] < 50.0)
					vecVelocity[2] = 50.0;
				
				TeleportEntity(iVictim, NULL_VECTOR, NULL_VECTOR, vecVelocity);

				// damage is simple enough
				if (flDamage > 0.0)
					SDKHooks_TakeDamage(iVictim, boss.iClient, boss.iClient, flDamage, DMG_CLUB);
			}
		}

		int iVictim = MaxClients + 1;
		while ((iVictim = FindEntityByClassname(iVictim, "obj_*")) != -1)
		{
			if (GetEntProp(iVictim, Prop_Send, "m_bCarried") || GetEntProp(iVictim, Prop_Send, "m_bPlacing") || GetEntProp(iVictim, Prop_Send, "m_iTeamNum") == iTeam)
				continue;

			GetEntPropVector(iVictim, Prop_Send, "m_vecOrigin", vecVictim);
			if (!CylinderCollision(vecHitPos, vecVictim, 60.0, vecHitPos[2] - 103.0, vecHitPos[2] + 95.0))
				continue;

			if (HasLineOfSight(vecHitPos, vecVictim, 41.5))
			{
				CreateTimer(1.0, Timer_EntityCleanup, TF2_SpawnParticle("taunt_headbutt_impact_stars", vecVictim, vecAngles));
				SDKHooks_TakeDamage(iVictim, boss.iClient, boss.iClient, 9999.0, DMG_GENERIC, -1);
			}
		}

		if (GetGameTime() >= g_flLungeNextPushAt[boss.iClient])
		{
			GetEntPropVector(boss.iClient, Prop_Data, "m_vecVelocity", vecVelocity);
			float flZ = vecVelocity[2];
			vecVelocity[2] = 0.0;
			if (GetLinearVelocity(vecVelocity) < 100.0)
			{
				GetAngleVectors(g_vecLungeInitialAngles[boss.iClient], vecVelocity, NULL_VECTOR, NULL_VECTOR);
				ScaleVector(vecVelocity, flForce);
				
				vecVelocity[2] = flZ;
				TeleportEntity(boss.iClient, NULL_VECTOR, NULL_VECTOR, vecVelocity);
			}
			
			g_flLungeNextPushAt[boss.iClient] = GetGameTime() + 0.05;
		}
	}
}

static Action RevertCollisionGroup(Handle hTimer, int iUserId)
{
	// Revert collision when we don't get stuck in another player
	int iClient = GetClientOfUserId(iUserId);
	if (iClient)
	{
		if (g_bLungeActive[iClient])
			return Plugin_Continue;
		
		float vecOrigin[3], vecMins[3], vecMaxs[3];
		GetClientAbsOrigin(iClient, vecOrigin);
		vecMins[0] = vecOrigin[0] - 50.0;
		vecMins[1] = vecOrigin[1] - 50.0;
		vecMins[2] = vecOrigin[2] - 85.0;
		vecMaxs[0] = vecOrigin[0] + 50.0;
		vecMaxs[1] = vecOrigin[1] + 50.0;
		vecMaxs[2] = vecOrigin[2] + 85.0;
		
		int iTeam = GetClientTeam(iClient);
		for (int iVictim = 1; iVictim <= MaxClients; iVictim++)
		{
			if (iVictim == iClient || !IsClientInGame(iVictim) || !IsPlayerAlive(iVictim) || GetClientTeam(iVictim) == iTeam)
				continue;
			
			if (g_bLungeActive[iVictim])
				return Plugin_Continue;
			
			GetClientAbsOrigin(iVictim, vecOrigin);
			if (vecOrigin[0] >= vecMins[0] && vecOrigin[0] <= vecMaxs[0] &&
				vecOrigin[1] >= vecMins[1] && vecOrigin[1] <= vecMaxs[1] &&
				vecOrigin[2] >= vecMins[2] && vecOrigin[2] <= vecMaxs[2])
			{
				// Failed, try again later
				return Plugin_Continue;
			}
		}
		
		SetEntityCollisionGroup(iClient, COLLISION_GROUP_PLAYER);
	}

	for (int i = 0; i < sizeof(g_hCollisionTimer); i++)
	{
		if (g_hCollisionTimer[i] == hTimer)
		{
			g_hCollisionTimer[i] = null;
			break;
		}
	}

	return Plugin_Stop;
}

static float GetLinearVelocity(float vecVelocity[3])
{
	return SquareRoot((vecVelocity[0] * vecVelocity[0]) + (vecVelocity[1] * vecVelocity[1]) + (vecVelocity[2] * vecVelocity[2]));
}

static bool CylinderCollision(const float vecCylinder[3], const float vecCollider[3], float flMaxDistance, float flMin, float flMax)
{
	if (vecCollider[2] < flMin || vecCollider[2] > flMax)
		return false;

	float vecPos1[3], vecPos2[3];
	vecPos1[0] = vecCylinder[0];
	vecPos1[1] = vecCylinder[1];
	vecPos2[0] = vecCollider[0];
	vecPos2[1] = vecCollider[1];
	
	return GetVectorDistance(vecPos1, vecPos2, true) <= flMaxDistance * flMaxDistance;
}

static bool HasLineOfSight(float vecBoss[3], float vecVictim[3], float flOffset)
{
	static float vecPos[3];
	vecBoss[2] += flOffset;
	vecVictim[2] += flOffset;
	TR_TraceRayFilter(vecBoss, vecVictim, MASK_PLAYERSOLID, RayType_EndPoint, TraceRay_HitWallOnly);
	TR_GetEndPosition(vecPos);
	vecBoss[2] -= flOffset;
	vecVictim[2] -= flOffset;
	vecPos[2] -= flOffset;
	
	return vecPos[0] == vecVictim[0] && vecPos[1] == vecVictim[1] && vecPos[2] == vecVictim[2];
}