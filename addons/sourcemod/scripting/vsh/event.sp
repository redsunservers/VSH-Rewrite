static bool g_bSpawnTeamSwitch;

void Event_Init()
{
	HookEvent("teamplay_round_start", Event_RoundStart, EventHookMode_Pre);
	HookEvent("arena_round_start", Event_RoundArenaStart);
	HookEvent("teamplay_round_win", Event_RoundEnd);
	HookEvent("teamplay_point_captured", Event_PointCaptured);
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
	HookEvent("post_inventory_application", Event_PlayerInventoryUpdate);
	HookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Pre);
	HookEvent("deploy_buff_banner", Event_BuffBannerDeployed);
	HookEvent("player_chargedeployed", Event_UberDeployed);
	HookEvent("teamplay_broadcast_audio", Event_BroadcastAudio, EventHookMode_Pre);
	HookEvent("player_builtobject", Event_BuiltObject, EventHookMode_Pre);
	HookEvent("object_destroyed", Event_DestroyObject, EventHookMode_Pre);
	HookEvent("player_sapped_object", Event_SappedObject, EventHookMode_Pre);

	HookUserMessage(GetUserMessageId("PlayerJarated"), Event_Jarated);
}

public Action Event_RoundStart(Event event, const char[] sName, bool bDontBroadcast)
{
	g_bSpawnTeamSwitch = false;
	
	if (!g_bEnabled || GameRules_GetProp("m_bInWaitingForPlayers"))
		return;
	
	// Start dome stuffs regardless if first round
	Dome_RoundStart();

	// Play one round of arena
	if (g_iTotalRoundPlayed <= 0)
		return;
	
	// Arena has a very dumb logic, if all players from a team leave the round will end and then restart without reseting the game state...
	// Catch that issue and don't run our logic!
	int iRed = 0, iBlu = 0;
	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if (IsClientInGame(iClient))
		{
			switch (TF2_GetClientTeam(iClient))
			{
				case TFTeam_Red: iRed++;
				case TFTeam_Blue: iBlu++;
			}
		}
	}
	// Both team must have at least one player!
	if (iRed == 0 || iBlu == 0)
	{
		if (iRed + iBlu >= 2) //If we have atleast 2 players in red or blue, force one person to other team and try again
		{
			for (int iClient = 1; iClient <= MaxClients; iClient++)
			{
				if (IsClientInGame(iClient))
				{
					//Once we found someone whos in red or blue, swap his team
					TFTeam nTeam = TF2_GetClientTeam(iClient);
					if (nTeam == TFTeam_Red)
					{
						g_bSpawnTeamSwitch = true;
						TF2_ForceTeamJoin(iClient, TFTeam_Blue);
						return;
					}
					else if (nTeam == TFTeam_Blue)
					{
						g_bSpawnTeamSwitch = true;
						TF2_ForceTeamJoin(iClient, TFTeam_Red);
						return;
					}
				}
			}
		}
		//If we reach that part, either nobody is in server or people in spectator
		return;
	}
	
	g_hTimerBossMusic = null;
	g_bRoundStarted = false;

	// New round started
	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		//Clean up any boss(es) that is/are still active
		SaxtonHaleBase boss = SaxtonHaleBase(iClient);
		if (boss.bValid)
			boss.CallFunction("Destroy");
		
		g_iPlayerDamage[iClient] = 0;
		g_iPlayerAssistDamage[iClient] = 0;
		g_iClientOwner[iClient] = 0;
		
		int iColor[4];
		iColor[0] = 255; iColor[1] = 255; iColor[2] = 255; iColor[3] = 255;
		Hud_SetColor(iClient, iColor);
		
		if (!IsClientInGame(iClient)) continue;
		if (GetClientTeam(iClient) <= 1) continue;
		
		// Put every players in same team & pick the boss later
		TF2_ForceTeamJoin(iClient, TFTeam_Attack);
	}
	
	g_iTotalAttackCount = SaxtonHale_GetAliveAttackPlayers();
	
	NextBoss_SetNextBoss();	//Set boss

	g_iTotalAttackCount = SaxtonHale_GetAliveAttackPlayers();	//Update amount of attack players

	Rank_RoundStart();

	RequestFrame(Frame_InitVshPreRoundTimer, tf_arena_preround_time.IntValue);
}

public Action Event_RoundArenaStart(Event event, const char[] sName, bool bDontBroadcast)
{
	if (!g_bEnabled || GameRules_GetProp("m_bInWaitingForPlayers")) return;

	//Play one round of arena, and force unlock/enable dome
	if (g_iTotalRoundPlayed <= 0)
	{
		GameRules_SetPropFloat("m_flCapturePointEnableTime", 0.0);
		return;
	}

	g_bRoundStarted = true;
	g_iTotalAttackCount = SaxtonHale_GetAliveAttackPlayers();

	//New round started
	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if (!IsClientInGame(iClient)) continue;

		g_iPlayerDamage[iClient] = 0;
		g_iPlayerAssistDamage[iClient] = 0;
		ClassLimit_SetMainClass(iClient, TFClass_Unknown);
		
		if (!SaxtonHale_IsValidAttack(iClient)) continue;

		//Display weapon balances in chat
		TFClassType nClass = TF2_GetPlayerClass(iClient);

		ClassLimit_SetMainClass(iClient, nClass);

		for (int iSlot = 0; iSlot <= WeaponSlot_InvisWatch; iSlot++)
		{
			int iWeapon = TF2_GetItemInSlot(iClient, iSlot);
			
			if (IsValidEdict(iWeapon))
			{
				int iIndex = GetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex");
				for (int i = 0; i <= 1; i++)
				{					
					char sDesp[255];
					
					// Desp for all weapon in class slot
					if (i == 0)
						g_ConfigClass[nClass][iSlot].GetDesp(sDesp, sizeof(sDesp));
					// Desp for specific index
					else if (i == 1)
						g_ConfigIndex.GetDesp(iIndex, sDesp, sizeof(sDesp));

					if (!StrEmpty(sDesp))
					{
						//Color tags
						for (int iColor = 0; iColor < sizeof(g_strColorTag); iColor++)
							ReplaceString(sDesp, sizeof(sDesp), g_strColorTag[iColor], g_strColorCode[iColor]);
	
						//Bug with single % not showing, use %% to have % appeared once
						ReplaceString(sDesp, sizeof(sDesp), "%", "%%");
	
						//Add VSH color at start
						Format(sDesp, sizeof(sDesp), "%s%s", TEXT_COLOR, sDesp);
						PrintToChat(iClient, sDesp);
					}
				}
			}
		}
	}
	
	//Play boss music if there is one
	if (g_ConfigConvar.LookupInt("vsh_music_enable"))
	{
		for (int iBoss = 1; iBoss <= MaxClients; iBoss++)
		{
			if (SaxtonHale_IsValidBoss(iBoss, false))
			{
				SaxtonHaleBase boss = SaxtonHaleBase(iBoss);
				
				float flMusicTime;
				boss.CallFunction("GetMusicInfo", g_sBossMusic, sizeof(g_sBossMusic), flMusicTime);
				if (!StrEmpty(g_sBossMusic))
				{
					for (int i = 1; i <= MaxClients; i++)
						if (IsClientInGame(i) && Preferences_Get(i, VSHPreferences_Music))
							EmitSoundToClient(i, g_sBossMusic);
					
					if (flMusicTime > 0.0)
						g_hTimerBossMusic = CreateTimer(flMusicTime, Timer_Music, boss, TIMER_REPEAT);
					
					break;
				}
			}
		}
	}
	
	//Check if there still enough players while rank is on, otherwise quick snipe disable it
	int iClientRank = Rank_GetClient();
	if (iClientRank != 0 && g_iTotalAttackCount < Rank_GetPlayerRequirement(iClientRank))
		Rank_SetEnable(false);
	
	//Refresh boss health from rank disable & player count
	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		SaxtonHaleBase boss = SaxtonHaleBase(iClient);
		if (boss.bValid)
		{
			int iHealth = boss.CallFunction("CalculateMaxHealth");
			boss.iMaxHealth = iHealth;
			boss.iHealth = iHealth;
		}
	}
	
	char sMessage[2048], sBuffer[256], sPreviousModifiers[256];
	int iColor[4] = {255, 255, 255, 255};
	bool bAllowModifiersColor = true;
	
	//Loop through each bosses to display
	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		SaxtonHaleBase boss = SaxtonHaleBase(iClient);
		if (!IsClientInGame(iClient) || !boss.bValid || boss.bMinion) continue;
		
		if (!StrEmpty(sMessage)) StrCat(sMessage, sizeof(sMessage), "\n");
		
		//Get client name
		Format(sMessage, sizeof(sMessage), "%s%N became", sMessage, iClient);
		
		//Display text who is what boss and modifiers with health
		if (boss.bModifiers)
		{
			boss.CallFunction("GetModifiersName", sBuffer, sizeof(sBuffer));
			Format(sMessage, sizeof(sMessage), "%s %s", sMessage, sBuffer);
			
			if (!StrEmpty(sPreviousModifiers) && !StrEqual(sPreviousModifiers, sBuffer))
			{
				//More than 1 different modifiers, dont allow colors
				bAllowModifiersColor = false;
			}
			else
			{
				boss.CallFunction("GetRenderColor", iColor);
			}
			
			Format(sPreviousModifiers, sizeof(sPreviousModifiers), sBuffer);
		}
		
		//Get Boss name and health
		boss.CallFunction("GetBossName", sBuffer, sizeof(sBuffer));
		Format(sMessage, sizeof(sMessage), "%s %s with %d HP!", sMessage, sBuffer, boss.iMaxHealth);
	
		//Get rank
		if (Rank_IsHealthEnabled() && Rank_GetCurrent(iClient) > 0)
			Format(sMessage, sizeof(sMessage), "%s\nRank %d (-%.0f%%%% health)", sMessage, Rank_GetCurrent(iClient), Rank_GetPrecentageLoss(iClient) * 100.0);
	}
	
	if (!bAllowModifiersColor)
		for (int iRGB = 0; iRGB < sizeof(iColor); iRGB++)
			iColor[iRGB] = 255;
	
	float flHUD[2];
	flHUD[0] = -1.0;
	flHUD[1] = 0.3;
	
	float flFade[2];
	flFade[0] = 0.4;
	flFade[1] = 0.4;

	for (int i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i))
			Hud_Display(i, CHANNEL_INTRO, sMessage, flHUD, 5.0, iColor, 0, 0.0, flFade);

	Dome_RoundArenaStart();

	//Display chat on who is next boss
	int iNextPlayer = Queue_GetPlayerFromRank(1);
	if (0 < iNextPlayer <= MaxClients && IsClientInGame(iNextPlayer))
	{
		PrintToChat(iNextPlayer, "%s================%s\nYou are about to be the next boss!", TEXT_DARK, TEXT_COLOR);
		Rank_DisplayClient(iNextPlayer);
		PrintToChat(iNextPlayer, "%s================", TEXT_DARK);
	}
}

public Action Event_RoundEnd(Event event, const char[] sName, bool bDontBroadcast)
{
	if (!g_bEnabled) return;

	g_hTimerBossMusic = null;
	g_bRoundStarted = false;

	TFTeam iWinningTeam = view_as<TFTeam>(event.GetInt("team"));

	g_iTotalRoundPlayed++;
	if (g_iTotalRoundPlayed <= 1)
	{
		if (g_iTotalRoundPlayed == 1)//Arena round ended disable arena logic!
			Plugin_Cvars(true);
		return;
	}

	int iMainBoss = GetMainBoss();
	int iClientRank = Rank_GetClient();
	
	if (iWinningTeam == TFTeam_Boss)
	{
		if (0 < iMainBoss <= MaxClients && IsClientInGame(iMainBoss))//Play our win line
		{
			SaxtonHaleBase boss = SaxtonHaleBase(iMainBoss);
			if (boss.bValid)
			{
				char sSound[255];
				boss.CallFunction("GetSound", sSound, sizeof(sSound), VSHSound_Win);
				if (!StrEmpty(sSound))
					BroadcastSoundToTeam(TFTeam_Spectator, sSound);

				Forward_BossWin(TFTeam_Boss);
			}
		}
		
		if (iClientRank != 0 && Rank_IsEnabled())
		{
			int iRank = Rank_GetCurrent(iClientRank) + 1;
			PrintToChatAll("%s %s%N%s's rank has %sincreased%s to %s%d%s!", TEXT_TAG, TEXT_DARK, iClientRank, TEXT_COLOR, TEXT_POSITIVE, TEXT_COLOR, TEXT_DARK, iRank, TEXT_COLOR);
			Rank_SetCurrent(iClientRank, iRank, true);
		}
	}
	else
	{
		if (0 < iMainBoss <= MaxClients && IsClientInGame(iMainBoss))//Play our lose line
		{
			SaxtonHaleBase boss = SaxtonHaleBase(iMainBoss);
			if (boss.bValid)
			{
				char sSound[255];
				boss.CallFunction("GetSound", sSound, sizeof(sSound), VSHSound_Lose);
				if (!StrEmpty(sSound))
					BroadcastSoundToTeam(TFTeam_Spectator, sSound);

				Forward_BossLose(TFTeam_Boss);
			}
		}
		
		if (iClientRank != 0 && Rank_IsEnabled())
		{
			int iRank = Rank_GetCurrent(iClientRank) - 1;
			if (iRank >= 0)
			{
				PrintToChatAll("%s %s%N%s's rank has %sdecreased%s to %s%d%s!", TEXT_TAG, TEXT_DARK, iClientRank, TEXT_COLOR, TEXT_NEGATIVE, TEXT_COLOR, TEXT_DARK, iRank, TEXT_COLOR);
				Rank_SetCurrent(iClientRank, iRank, true);
			}
		}
	}

	Rank_SetEnable(false);
	Rank_ClearClient();

	ArrayList aPlayersList = new ArrayList();
	
	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if (IsClientInGame(iClient))
		{
			//End music
			if (!StrEmpty(g_sBossMusic))
				StopSound(iClient, SNDCHAN_AUTO, g_sBossMusic);
			
			if (GetClientTeam(iClient) > 1 && (!SaxtonHale_IsValidBoss(iClient, false)))
			{				
				aPlayersList.Push(iClient);
				
				if (!Client_HasFlag(iClient, ClientFlags_Punishment))
				{
					int iAddQueue = 10 + RoundToFloor(float(SaxtonHale_GetScore(iClient)) / 300.0);
					if (iAddQueue > 20)
						iAddQueue = 20;
					Queue_AddPlayerPoints(iClient, iAddQueue);
				}
			}
		}
	}
	
	g_sBossMusic = "";

	char sPlayerNames[3][70];
	sPlayerNames[0] = "----";
	sPlayerNames[1] = "----";
	sPlayerNames[2] = "----";

	for (int iRank = 0; iRank < 3; iRank++)
	{
		int iBestPlayerIndex = -1;
		int iLength = aPlayersList.Length;
		int iBestScore = 0;

		for (int i = 0; i < iLength; i++)
		{
			int iPlayer = aPlayersList.Get(i);
			int iPlayerScore = SaxtonHale_GetScore(iPlayer);
			if (iPlayerScore > iBestScore)
			{
				iBestScore = iPlayerScore;
				iBestPlayerIndex = i;
			}
		}

		if (iBestPlayerIndex != -1)
		{
			char sBufferName[59];
			int iPlayer = aPlayersList.Get(iBestPlayerIndex);

			GetClientName(iPlayer, sBufferName, sizeof(sBufferName));
			Format(sPlayerNames[iRank], sizeof(sPlayerNames[]), "%s - %i", sBufferName, SaxtonHale_GetScore(iPlayer));
			aPlayersList.Erase(iBestPlayerIndex);
		}
	}

	delete aPlayersList;

	float flHUD[2];
	flHUD[0] = -1.0;
	flHUD[1] = 0.3;

	char sMessage[2048], sBuffer[256];
	
	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		SaxtonHaleBase boss = SaxtonHaleBase(iClient);
		if (boss.bValid && !boss.bMinion)
		{
			if (!StrEmpty(sMessage)) StrCat(sMessage, sizeof(sMessage), "\n");
			Format(sMessage, sizeof(sMessage), "%s%N as", sMessage, iClient);
			
			//Get Modifiers name
			if (boss.bModifiers)
			{
				boss.CallFunction("GetModifiersName", sBuffer, sizeof(sBuffer));
				Format(sMessage, sizeof(sMessage), "%s %s", sMessage, sBuffer);
			}
			
			//Get Boss name
			boss.CallFunction("GetBossName", sBuffer, sizeof(sBuffer));
			
			//Format with health
			if (IsPlayerAlive(iClient))
				Format(sMessage, sizeof(sMessage), "%s %s had %d of %d HP left", sMessage, sBuffer, boss.iHealth, boss.iMaxHealth);
			else
				Format(sMessage, sizeof(sMessage), "%s %s died with %d max HP", sMessage, sBuffer, boss.iMaxHealth);
		}
	}

	Format(sMessage, sizeof(sMessage), "%s\n1) %s \n2) %s \n3) %s ", sMessage, sPlayerNames[0], sPlayerNames[1], sPlayerNames[2]);

	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if (IsClientInGame(iClient))
		{
			Format(sBuffer, sizeof(sBuffer), sMessage);

			if (!SaxtonHale_IsValidBoss(iClient, false))
				Format(sBuffer, sizeof(sBuffer), "%s\nYour damage: %d | Your assist: %d", sBuffer, g_iPlayerDamage[iClient], g_iPlayerAssistDamage[iClient]);

			Hud_Display(iClient, CHANNEL_INTRO, sBuffer, flHUD, 10.0);
		}
	}	
}

public void Event_PointCaptured(Event event, const char[] sName, bool bDontBroadcast)
{
	if (!g_bEnabled) return;
	
	TFTeam nTeam = view_as<TFTeam>(event.GetInt("team"));
	Dome_SetTeam(nTeam);
}

public void Event_BroadcastAudio(Event event, const char[] sName, bool bDontBroadcast)
{
	if (!g_bEnabled) return;
	if (g_iTotalRoundPlayed <= 0) return;

	char strSound[50];
	event.GetString("sound", strSound, sizeof(strSound));

	if (strcmp(strSound, "Game.TeamWin3") == 0
	|| strcmp(strSound, "Game.YourTeamLost") == 0
	|| strcmp(strSound, "Game.YourTeamWon") == 0
	|| strcmp(strSound, "Announcer.AM_RoundStartRandom") == 0
	|| strcmp(strSound, "Game.Stalemate") == 0)
		SetEventBroadcast(event, true);
}

public Action Event_PlayerSpawn(Event event, const char[] sName, bool bDontBroadcast)
{
	if (!g_bEnabled) return;
	if (g_iTotalRoundPlayed <= 0) return;
	
	if (g_bSpawnTeamSwitch)
		return;
	
	int iClient = GetClientOfUserId(event.GetInt("userid"));
	if (TF2_GetClientTeam(iClient) <= TFTeam_Spectator)
		return;
	
	if (g_bRoundStarted && SaxtonHale_IsValidAttack(iClient))
	{
		//Latespawn... get outa here
		ForcePlayerSuicide(iClient);
		return;
	}
	
	bool bRespawn;
	TFClassType iOldClass = view_as<TFClassType>(event.GetInt("class"));
	TFClassType iNewClass = ClassLimit_GetNewClass(iClient);
	
	if (iOldClass != iNewClass && iNewClass != TFClass_Unknown)
	{
		TF2_SetPlayerClass(iClient, iNewClass);
		bRespawn = true;
	}
	
	SaxtonHaleBase boss = SaxtonHaleBase(iClient);
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (SaxtonHale_IsValidBoss(i, false))
		{
			if (!boss.bValid && TF2_GetClientTeam(iClient) != TFTeam_Attack)
			{
				TF2_ChangeClientTeam(iClient, TFTeam_Attack);
				bRespawn = true;
			}
			
			break;
		}
	}
	
	if (bRespawn)
	{
		TF2_RespawnPlayer(iClient);
		return;
	}
	
	// Player spawned, if they are a boss, call their spawn function
	if (boss.bValid)
		boss.CallFunction("OnSpawn");
}

public Action Event_BuiltObject(Event event, const char[] sName, bool bDontBroadcast)
{	
	if (!g_bEnabled) return Plugin_Continue;
	if (g_iTotalRoundPlayed <= 0) return Plugin_Continue;

	int iClient = GetClientOfUserId(event.GetInt("userid"));

	SaxtonHaleBase boss = SaxtonHaleBase(iClient);
	if (boss.bValid)
		return boss.CallFunction("OnBuildObject", event);
	
	return Plugin_Continue;
}

public Action Event_DestroyObject(Event event, const char[] sName, bool bDontBroadcast)
{
	if (!g_bEnabled) return Plugin_Continue;
	if (g_iTotalRoundPlayed <= 0) return Plugin_Continue;

	int iClient = GetClientOfUserId(event.GetInt("attacker"));

	SaxtonHaleBase boss = SaxtonHaleBase(iClient);
	if (boss.bValid)
	{
		char sSound[255];
		boss.CallFunction("GetSound", sSound, sizeof(sSound), VSHSound_KillBuilding);
		if (!StrEmpty(sSound))
			EmitSoundToAll(sSound, iClient, SNDCHAN_VOICE, SNDLEVEL_SCREAMING);
		
		return boss.CallFunction("OnDestroyObject", event);
	}
	
	return Plugin_Continue;
}

public Action Event_SappedObject(Event event, const char[] sName, bool bDontBroadcast)
{
	if (!g_bEnabled) return Plugin_Continue;
	if (g_iTotalRoundPlayed <= 0) return Plugin_Continue;

	int iVictim = GetClientOfUserId(event.GetInt("ownerid"));

	SaxtonHaleBase boss = SaxtonHaleBase(iVictim);
	if (boss.bValid)
		return boss.CallFunction("OnObjectSapped", event);
	
	return Plugin_Continue;
}

public Action Event_PlayerDeath(Event event, const char[] sName, bool bDontBroadcast)
{
	if (!g_bEnabled) return Plugin_Continue;
	if (g_iTotalRoundPlayed <= 0) return Plugin_Continue;

	int iVictim = GetClientOfUserId(event.GetInt("userid"));
	int iAttacker = GetClientOfUserId(event.GetInt("attacker"));

	int iVictimTeam = GetClientTeam(iVictim);
	if (iVictimTeam <= 1) return Plugin_Continue;

	SaxtonHaleBase bossVictim = SaxtonHaleBase(iVictim);
	SaxtonHaleBase bossAttacker = SaxtonHaleBase(iAttacker);

	bool bDeadRinger = (event.GetInt("death_flags") & TF_DEATHFLAG_DEADRINGER) != 0;

	int iSentry = TF2_GetBuilding(iVictim, TFObject_Sentry);
	if (iSentry > MaxClients)
	{
		SetVariantInt(999999);
		AcceptEntityInput(iSentry, "RemoveHealth");
	}
	
	if (bossVictim.bValid)
	{
		//Call boss death
		bossVictim.CallFunction("OnDeath", event);
		CheckForceAttackWin(iVictim);
	}
	
	if (0 < iAttacker <= MaxClients && iVictim != iAttacker && IsClientInGame(iAttacker))
	{	
		//Call boss kill
		if (bossAttacker.bValid)
			bossAttacker.CallFunction("OnPlayerKilled", event, iVictim);
	}
	
	if (g_bRoundStarted && !bDeadRinger && SaxtonHale_IsValidAttack(iVictim))
	{
		//Victim who died is still "alive" during this event, so we subtract by 1 to not count victim
		int iLastAlive = SaxtonHale_GetAliveAttackPlayers() - 1;
		
		if (iLastAlive >= 2)
		{
			//Play boss kill voiceline
			if ((GetRandomInt(0, 1)) && 0 < iAttacker <= MaxClients && bossAttacker.bValid)
			{
				char sSound[255];
				bossAttacker.CallFunction("GetSoundKill", sSound, sizeof(sSound), TF2_GetPlayerClass(iVictim));
				if (!StrEmpty(sSound))
					EmitSoundToAll(sSound, iAttacker, SNDCHAN_VOICE, SNDLEVEL_SCREAMING);
			}
		}
		
		if (iLastAlive == 1)
		{
			//Play last man voiceline
			int iBoss = 0;
			if (0 < iAttacker <= MaxClients && IsClientInGame(iAttacker))
			{
				iBoss = iAttacker;
			}
			else
			{
				for (int iClient = 1; iClient <= MaxClients; iClient++)
				{
					if (SaxtonHale_IsValidBoss(iClient, false) && IsPlayerAlive(iClient))
					{
						iBoss = iClient;
						break;
					}
				}
			}
			
			SaxtonHaleBase boss = SaxtonHaleBase(iBoss);
			if (iBoss != 0 && boss.bValid)
			{
				char sSound[255];
				boss.CallFunction("GetSound", sSound, sizeof(sSound), VSHSound_Lastman);
				if (!StrEmpty(sSound))
					BroadcastSoundToTeam(TFTeam_Spectator, sSound);
			}
		}

		if (iLastAlive == 0)
		{
			//Kill any minions that are still alive
			for (int i = 1; i <= MaxClients; i++)
				if (IsClientInGame(i) && IsPlayerAlive(i) && i != iVictim && GetClientTeam(i) == iVictimTeam)
					SDKHooks_TakeDamage(i, 0, i, 99999.0);
		}
	}
	
	if (g_bRoundStarted && !bDeadRinger)
		g_iClientOwner[iVictim] = 0;
	
	return Plugin_Changed;
}

public Action Event_PlayerInventoryUpdate(Event event, const char[] sName, bool bDontBroadcast)
{
	if (!g_bEnabled) return;

	int iClient = GetClientOfUserId(event.GetInt("userid"));
	if (GetClientTeam(iClient) <= 1) return;
	
	TF2_CheckClientWeapons(iClient);
	
	if (SaxtonHale_IsValidAttack(iClient))
	{
		/*Balance specific weapons*/
		TFClassType nClass = TF2_GetPlayerClass(iClient);
		for (int iSlot = 0; iSlot <= WeaponSlot_InvisWatch; iSlot++)
		{
			int iWeapon = TF2_GetItemInSlot(iClient, iSlot);
			
			if (iWeapon <= MaxClients)
			{
				//No weapon in this slot, may be removed from GiveNamedItem hook
				//Generate default weapon index for class and slot
				int iIndex = g_iDefaultWeaponIndex[view_as<int>(nClass)][iSlot];
				if (iIndex >= 0)
					iWeapon = TF2_CreateAndEquipWeapon(iClient, iIndex, .bAttrib = true);
			}
			
			if (iWeapon > MaxClients)
			{
				// Balance weapons, not including 1st round
				if (g_iTotalRoundPlayed > 0)
				{
					int iIndex = GetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex");
					
					for (int i = 0; i <= 1; i++)
					{
						char sAttrib[255], atts[32][32];
						
						// Give attribs in class slot and specific index
						switch (i)
						{
							case 0: g_ConfigClass[nClass][iSlot].GetAttrib(sAttrib, sizeof(sAttrib));
							case 1: g_ConfigIndex.GetAttrib(iIndex, sAttrib, sizeof(sAttrib));
						}
						
						int count = ExplodeString(sAttrib, " ; ", atts, 32, 32);
						if (count > 1)
						{
							for (int j = 0; j < count; j+= 2)
								TF2Attrib_SetByDefIndex(iWeapon, StringToInt(atts[j]), StringToFloat(atts[j+1]));

							TF2Attrib_ClearCache(iWeapon);
						}
						
						// Set clip size to weapon in both class slot and specific index
						int iClip = -1;
						switch (i)
						{
							case 0: iClip = g_ConfigClass[nClass][iSlot].GetClip();
							case 1: iClip = g_ConfigIndex.GetClip(iIndex);
						}
						
						if (iClip > -1)
							SetEntProp(iWeapon, Prop_Send, "m_iClip1", iClip);
					}
				}
			}
		}
	}

	if (g_iTotalRoundPlayed <= 0) return;
	
	Tags_ResetClient(iClient);
	TagsCore_RefreshClient(iClient);
	
	if (SaxtonHale_IsValidAttack(iClient))
		TagsCore_CallAll(iClient, TagsCall_Spawn);
}

public Action Event_PlayerHurt(Event event, const char[] sName, bool bDontBroadcast)
{
	if (!g_bEnabled) return;
	if (g_iTotalRoundPlayed <= 0) return;

	int iClient = GetClientOfUserId(event.GetInt("userid"));
	if (GetClientTeam(iClient) <= 1) return;
	
	SaxtonHaleBase boss = SaxtonHaleBase(iClient);
	if (boss.bValid)
	{
		int iAttacker = GetClientOfUserId(event.GetInt("attacker"));
		int iDamageAmount = event.GetInt("damageamount");
		Tags_PlayerHurt(iClient, iAttacker, iDamageAmount);
		
		if (0 < iAttacker <= MaxClients && IsClientInGame(iAttacker) && iClient != iAttacker)
		{
			boss.CallFunction("AddRage", iDamageAmount);
			
			if (boss.bMinion)
				return;
			
			g_iPlayerDamage[iAttacker] += iDamageAmount;
			int iAttackTeam = GetClientTeam(iAttacker);

			//Award assist damage if Client has a owner
			int iOwner = g_iClientOwner[iAttacker];
			if (0 < iOwner <= MaxClients && IsClientInGame(iOwner))
				g_iPlayerAssistDamage[iOwner] += iDamageAmount;

			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && GetClientTeam(i) == iAttackTeam && i != iAttacker)
				{
					int iSecondaryWep = GetPlayerWeaponSlot(i, WeaponSlot_Secondary);
					char weaponSecondaryClass[32];
					if (iSecondaryWep >= 0) GetEdictClassname(iSecondaryWep, weaponSecondaryClass, sizeof(weaponSecondaryClass));

					//Award damage assit to healers
					if (strcmp(weaponSecondaryClass, "tf_weapon_medigun") == 0)
					{
						int iHealTarget = GetEntPropEnt(iSecondaryWep, Prop_Send, "m_hHealingTarget");
						if (iHealTarget == iAttacker)
						{
							g_iPlayerAssistDamage[i] += iDamageAmount;
						}
						else if (iHealTarget > MaxClients)	//Buildings
						{
							char sClassname[64];
							GetEdictClassname(iHealTarget, sClassname, sizeof(sClassname));
							//Check if healer is healing sentry gun, with attacker as builder
							if (strcmp(sClassname, "obj_sentrygun") == 0 && GetEntPropEnt(iHealTarget, Prop_Send, "m_hBuilder") == iAttacker)
							{
								g_iPlayerAssistDamage[i] += iDamageAmount;
							}
						}
					}
				}
			}
		}
	}
}

public Action Event_BuffBannerDeployed(Event event, const char[] sName, bool bDontBroadcast)
{
	if (!g_bEnabled) return;
	if (g_iTotalRoundPlayed <= 0) return;

	int iClient = GetClientOfUserId(event.GetInt("buff_owner"));
	if (GetClientTeam(iClient) <= 1 || SaxtonHale_IsValidBoss(iClient)) return;

	TagsCore_CallAll(iClient, TagsCall_Banner);
}

public Action Event_UberDeployed(Event event, const char[] sName, bool bDontBroadcast)
{
	if (!g_bEnabled) return;
	if (g_iTotalRoundPlayed <= 0) return;

	int iClient = GetClientOfUserId(GetEventInt(event, "userid"));
	if (GetClientTeam(iClient) <= 1 || SaxtonHale_IsValidBoss(iClient)) return;

	TagsCore_CallAll(iClient, TagsCall_Uber);
}

public Action Event_Jarated(UserMsg msg_id, Handle msg, const int[] players, int playersNum, bool reliable, bool init)
{
	if (!g_bEnabled) return;
	if (g_iTotalRoundPlayed <= 0) return;

	int iThrower = BfReadByte(msg);
	int iVictim = BfReadByte(msg);
	
	if (GetClientTeam(iThrower) <= 1 || SaxtonHale_IsValidBoss(iThrower)) return;
	
	SaxtonHaleBase bossVictim = SaxtonHaleBase(iVictim);
	if (GetClientTeam(iVictim) <= 1 || !bossVictim.bValid) return;
	
	TagsParams tParams = new TagsParams();
	tParams.SetInt("victim", iVictim);
	
	//Possible crash if called in same frame
	DataPack data = new DataPack();
	data.WriteCell(GetClientUserId(iThrower));
	data.WriteCell(tParams);
	RequestFrame(Frame_CallJarate, data);
}