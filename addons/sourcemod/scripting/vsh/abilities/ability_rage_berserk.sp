static float g_flScareRadiusClass[MAXPLAYERS][10];
static float g_flBerserkDurationClass[MAXPLAYERS][10];
static int g_iScareStunFlagsClass[MAXPLAYERS][10];

public void RageBerserk_SetClass(SaxtonHaleBase boss, TFClassType nClass, float flRadius, float flDuration, int iStunFlags)
{
	g_flScareRadiusClass[boss.iClient][nClass] = flRadius;
	g_flBerserkDurationClass[boss.iClient][nClass] = flDuration;
	g_iScareStunFlagsClass[boss.iClient][nClass] = iStunFlags;
}

public void RageBerserk_Create(SaxtonHaleBase boss)
{
	boss.SetPropFloat("RageBerserk", "Radius", -1.0);
	boss.SetPropFloat("RageBerserk", "Duration", 5.0);
	boss.SetPropInt("RageBerserk", "StunFlags", TF_STUNFLAGS_GHOSTSCARE);
	
	for (TFClassType nClass = TFClass_Scout; nClass <= TFClass_Engineer; nClass++)
	{
		g_flScareRadiusClass[boss.iClient][nClass] = -1.0;
		g_flBerserkDurationClass[boss.iClient][nClass] = -1.0;
		g_iScareStunFlagsClass[boss.iClient][nClass] = -1;
	}
}

public void RageBerserk_OnRage(SaxtonHaleBase boss)
{
	int iClient = boss.iClient;
	int bossTeam = GetClientTeam(iClient);
	float vecPos[3], vecTargetPos[3];
	GetClientAbsOrigin(iClient, vecPos);
	
	for (int iVictim = 1; iVictim <= MaxClients; iVictim++)
	{
		if (IsClientInGame(iVictim) && IsPlayerAlive(iVictim) && GetClientTeam(iVictim) != bossTeam && !TF2_IsUbercharged(iVictim))
		{
			GetClientAbsOrigin(iVictim, vecTargetPos);
			TFClassType nClass = TF2_GetPlayerClass(iVictim);
			
			float flMultiplier = 1.0;
			if (boss.bSuperRage)
				flMultiplier = 1.5;
			
			float flDistance = GetVectorDistance(vecTargetPos, vecPos);
			float flMinDistance = 99999.0;
			
			// Use whichever radius is the smallest
			float flDuration = 0.0;
			int iStunFlags = 0;
			
			if (flDistance <= boss.GetPropFloat("RageBerserk", "Radius") * flMultiplier <= flMinDistance)
			{
				flMinDistance = boss.GetPropFloat("RageBerserk", "Radius") * flMultiplier;
				flDuration = boss.GetPropFloat("RageBerserk", "Duration");
				iStunFlags = boss.GetPropInt("RageBerserk", "StunFlags");
			}
			
			if (flDistance <= g_flScareRadiusClass[boss.iClient][nClass] * flMultiplier <= flMinDistance)
			{
				flMinDistance = g_flScareRadiusClass[boss.iClient][nClass] * flMultiplier;
				flDuration = g_flBerserkDurationClass[boss.iClient][nClass];
				iStunFlags = g_iScareStunFlagsClass[boss.iClient][nClass];
			}
			
			flDuration *= flMultiplier;
			
			if (iStunFlags)
			{
				if (TF2_IsPlayerInCondition(iVictim, TFCond_Dazed))
					TF2_RemoveCondition(iVictim, TFCond_Dazed);
				
				TF2_StunPlayer(iVictim, flDuration, 0.0, iStunFlags, 0);
			}
		}
	}
	
	int iEntity = MaxClients+1;
	while ((iEntity = FindEntityByClassname(iEntity, "obj_sentrygun")) > MaxClients)
	{
		if (GetEntProp(iEntity, Prop_Send, "m_iTeamNum") != bossTeam)
		{
			float flDuration = (boss.bSuperRage) ? boss.GetPropFloat("RageBerserk", "Duration")*1.5 : boss.GetPropFloat("RageBerserk", "Duration");
			float flRadius = (boss.bSuperRage) ? boss.GetPropFloat("RageBerserk", "Radius")*1.5 : boss.GetPropFloat("RageBerserk", "Radius");
			
			GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", vecTargetPos);
			if (GetVectorDistance(vecTargetPos, vecPos) <= flRadius)
				TF2_StunBuilding(iEntity, flDuration);
		}
	}
}
