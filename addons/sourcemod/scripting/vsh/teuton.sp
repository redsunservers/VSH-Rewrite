void Teuton_Init()
{
	g_ConfigConvar.Create("vsh_teuton_enable", "1", "Enable Teuton Knights?", _, true, 0.0, true, 1.0);
}

void Teuton_MapStart()
{
	int iEntity = FindEntityByClassname(-1, "tf_player_manager");
	if(iEntity != -1)
		SDKHook(iEntity, SDKHook_ThinkPost, Teuton_PlayerManagerThink);
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
	
	CreateTimer(6.0, Teuton_SpawnTimer, GetClientUserId(iVictim), TIMER_FLAG_NO_MAPCHANGE);
}

static Action Teuton_SpawnTimer(Handle timer, int iUserID)
{
	int iClient = GetClientOfUserId(iUserID);
	if (iClient && g_bRoundStarted && !IsPlayerAlive(iClient) && TF2_GetClientTeam(iClient) > TFTeam_Spectator)
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

static void Teuton_PlayerManagerThink(int iEntity)
{
	static int iOffset = -1;
	if (iOffset == -1) 
		iOffset = FindSendPropInfo("CTFPlayerResource", "m_bAlive");
	
	bool[] bAlive = new bool[MaxClients+1];

	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if (IsClientInGame(iClient))
		{
			// Alive and not a minion boss
			bAlive[iClient] = (IsPlayerAlive(iClient) && (!SaxtonHaleBase(iClient).bValid || !SaxtonHaleBase(iClient).bMinion));
		}
	}

	SetEntDataArray(iEntity, iOffset, bAlive, MaxClients + 1);
}
