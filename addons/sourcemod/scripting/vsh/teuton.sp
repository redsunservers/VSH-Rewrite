void Teuton_Init()
{
	g_ConfigConvar.Create("vsh_teuton_enable", "1", "Enable Teuton Knights?", _, true, 0.0, true, 1.0);
}

void Teuton_RoundArenaStart()
{
	if (!g_ConfigConvar.LookupBool("vsh_teuton_enable") || g_ConfigConvar.LookupBool("vsh_dome_enable"))
		return;
	
	// If we have Dome disabled and Teutons enabled, block the cap overall
	GameRules_SetPropFloat("m_flCapturePointEnableTime", GetGameTime() + 999.9);
}

void Teuton_PlayerDeath(int iVictim)
{
	if (!g_ConfigConvar.LookupBool("vsh_teuton_enable") || SaxtonHale_IsValidBoss(iVictim, false))
		return;
	
	CreateTimer(4.0, Teuton_SpawnTimer, GetClientUserId(iVictim), TIMER_FLAG_NO_MAPCHANGE);
}

static Action Teuton_SpawnTimer(Handle timer, int iUserID)
{
	int iClient = GetClientOfUserId(iUserID);
	if (iClient && !IsPlayerAlive(iClient) && TF2_GetClientTeam(iClient) > TFTeam_Spectator)
	{
		SaxtonHaleBase boss = SaxtonHaleBase(iClient);
		if (boss.bValid)
			boss.DestroyAllClass();
		
		TF2_ChangeClientTeam(iClient, TFTeam_Attack);
		
		boss.CreateClass("Teuton");
		TF2_RespawnPlayer(iClient);
		
		int iCount;
		int[] iTargets = new int[MaxClients];
		for (int iTarget = 1; iTarget <= MaxClients; iTarget++)
		{
			if(iTarget != iClient && IsClientInGame(iTarget) && IsPlayerAlive(iTarget) && TF2_GetClientTeam(iTarget) == TFTeam_Attack)
			{
				iTargets[iCount++] = iTarget;
			}
		}

		if (iCount != 0)
			TF2_TeleportToClient(iClient, iTargets[GetURandomInt() % iCount]);
	}

	return Plugin_Continue;
}
