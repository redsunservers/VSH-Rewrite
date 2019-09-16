void NextBoss_Init()
{
	g_ConfigConvar.Create("vsh_boss_chance_saxton", "0.25", "% chance for next boss to be Saxton Hale (0.0 - 1.0)", _, true, 0.0, true, 1.0);
	g_ConfigConvar.Create("vsh_boss_chance_multi", "0.20", "% chance for next boss to be multiple bosses (after Saxton Hale roll) (0.0 - 1.0)", _, true, 0.0, true, 1.0);
	g_ConfigConvar.Create("vsh_boss_chance_modifiers", "0.15", "% chance for next boss to have random modifiers (0.0 - 1.0)", _, true, 0.0, true, 1.0);
}

void PickNextBoss()
{
	//Get every non-specs
	ArrayList aClients = new ArrayList();
	for (int iClient = 1; iClient <= MaxClients; iClient++)
		if (IsClientInGame(iClient) && GetClientTeam(iClient) > 1)
			aClients.Push(iClient);
	
	//Randomize incase we have to pick random player
	SortADTArray(aClients, Sort_Random, Sort_Integer);
	
	//Find main boss
	int iMainBoss = 0;
	int iArray = 0;
	while (g_aNextBoss.Length > iArray && iMainBoss == 0)
	{
		//Get "main" boss
		int iUserId = 0;
		StringMap mNextBoss = g_aNextBoss.Get(iArray);
		if (mNextBoss.GetValue("userid", iUserId))
			iMainBoss = GetClientOfUserId(iUserId);	//Should return 0 if invalid userid
		
		iArray++;
	}
	
	//If next player not force set as boss, get one from queue
	if (iMainBoss <= 0 || iMainBoss > MaxClients || !IsClientInGame(iMainBoss))
	{
		iMainBoss = Queue_GetPlayerFromRank(1);
		if (iMainBoss <= 0 || iMainBoss > MaxClients || !IsClientInGame(iMainBoss))
		{
			PrintToChatAll("%s%s Unable to find player in queue to become boss! %sPicking random player...", VSH_TAG, VSH_ERROR_COLOR, VSH_TEXT_COLOR);
			iMainBoss = aClients.Get(0);
		}
	}
	
	//Check if next boss is not force set
	if (g_aNextBoss.Length == 0)
	{
		char sBosses[256];
		GetRandomBosses(sBosses, sizeof(sBosses), Preferences_Get(iMainBoss, halePreferences_MultiBoss));
		
		//Loop though all bosses selected to set modifiers
		char sBoss[32][32];
		int iCount = ExplodeString(sBosses, " ; ", sBoss, 32, 32);
		for (int i = 0; i < iCount; i++)
		{
			//Create StringMap to set boss
			StringMap mNextBoss = new StringMap();
			mNextBoss.SetString("boss", sBoss[i]);
			g_aNextBoss.Push(mNextBoss);
		}
	}
	
	int iBossCount = g_aNextBoss.Length;
	if (iBossCount == 0)
	{
		//Still dont have anything in list somehow... that should never happen
		PluginStop(true, "[VSH] NEXT BOSS IN ARRAY LIST IS EMPTY!!!!");
		return;
	}
	
	int iRank = 1;
	//Loop though and check if all client, boss and modifiers has been set
	for (int i = 0; i < iBossCount; i++)
	{
		StringMap mNextBoss = g_aNextBoss.Get(i);
		
		//Check if client has been selected yet, and still in game
		int iUserId = -1;
		if (mNextBoss.GetValue("userid", iUserId))
		{
			int iClient = GetClientOfUserId(iUserId);
			if (iClient <= 0 || iClient > MaxClients || !IsClientInGame(iClient))
				iUserId = -1;
		}
		
		if (iUserId == -1)
		{
			int iClient = -1;
			while (iClient == -1 && aClients.Length > 0)
			{
				iClient = Queue_GetPlayerFromRank(iRank);
				
				//If cant find in list, get player from array sorted at random
				if (iClient <= 0 || iClient > MaxClients || !IsClientInGame(iClient))
					iClient = aClients.Get(0);
				
				//If were not at first boss to set, we assume there duo boss going on, dont select one with pref disabled
				else if (i > 0 && !Preferences_Get(iClient, halePreferences_MultiBoss))
					iClient = -1;
				
				if (0 < iClient <= MaxClients && IsClientInGame(iClient))
				{
					iUserId = GetClientUserId(iClient);
					mNextBoss.SetValue("userid", iUserId);
					
					//Erase client in list
					int iIndex = aClients.FindValue(iClient);
					if (iIndex >= 0) aClients.Erase(iIndex);
				}
				
				iRank++;
			}
		}
		
		char sBuffer[256];
		
		if (!mNextBoss.GetString("boss", sBuffer, sizeof(sBuffer)))
		{
			//Get random non-duo boss
			GetRandomBosses(sBuffer, sizeof(sBuffer), false);
			mNextBoss.SetString("boss", sBuffer);
		}
		
		if (!mNextBoss.GetString("modifiers", sBuffer, sizeof(sBuffer)))
		{
			//Get random modifiers
			GetRandomModifiers(sBuffer, sizeof(sBuffer));
			mNextBoss.SetString("modifiers", sBuffer);
		}
	}
	
	//Loop again to actually set boss
	for (int i = 0; i < iBossCount; i++)
	{
		StringMap mNextBoss = g_aNextBoss.Get(i);
		
		int iUserId = -1;
		mNextBoss.GetValue("userid", iUserId);
		int iClient = GetClientOfUserId(iUserId);
		if (iClient <= 0 || iClient > MaxClients || !IsClientInGame(iClient))
		{
			char sError[256];
			Format(sError, sizeof(sError), "[VSH] INVALID NEXT BOSS CLIENT %d, USERID %d", iClient, iUserId);
			PluginStop(true, sError);
			return;
		}
		
		char sBossType[256], sModifiersType[256];
		mNextBoss.GetString("boss", sBossType, sizeof(sBossType));
		mNextBoss.GetString("modifiers", sModifiersType, sizeof(sModifiersType));
		
		//Set boss
		SetBoss(iClient, sBossType, sModifiersType);
		
		// Reset their points
		Queue_ResetPlayer(iClient);
		
		// Enable special round if triggered
		if (g_bPlayerTriggerSpecialRound[iClient])
		{
			g_bSpecialRound = true;
			g_bPlayerTriggerSpecialRound[iClient] = false;
		}
	}
	
	//Whipe all next boss & modifiers data
	ClearAllNextBoss();
	delete aClients;
	
	//Get amount of valid bosses after set
	int iBosses = 0;
	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if (SaxtonHale_IsValidBoss(iClient, false))
			iBosses++;
	}
	
	if (iBosses == 0)
	{
		//Still empty after setting boss...
		PluginStop(true, "[VSH] NO BOSSES AFTER ATTEMPTED TO SET ONE!!!!");
		return;
	}
	
	//Cut down health, incase there more than 1 bosses
	float flHealthMulti = 1.0 / float(iBosses);
	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		SaxtonHaleBase boss = SaxtonHaleBase(iClient);
		if (IsClientInGame(iClient) && boss.bValid && !boss.bMinion)
		{
			boss.flHealthMultiplier *= flHealthMulti;
			int iHealth = boss.CallFunction("CalculateMaxHealth");
			boss.iMaxHealth = iHealth;
			boss.iHealth = iHealth;
		}
	}
	
	// Check if special round is set after setting boss
	if (g_bSpecialRound || g_nSpecialRoundNextClass != TFClass_Unknown)
	{
		
		TFClassType nSpecialRoundClass;
		if (g_nSpecialRoundNextClass != TFClass_Unknown)
			nSpecialRoundClass = g_nSpecialRoundNextClass;
		else
			nSpecialRoundClass = view_as<TFClassType>(GetRandomInt(1, sizeof(g_strClassName)-1));
		
		ClassLimit_SetSpecialRound(nSpecialRoundClass);
		PrintToChatAll("%s%s SPECIAL ROUND: %N versus %s", VSH_TAG, VSH_TEXT_COLOR, iMainBoss, g_strClassName[nSpecialRoundClass]);
		
		g_bSpecialRound = false;
		g_nSpecialRoundNextClass = TFClass_Unknown;
	}
	else	//If not, disable special round
	{
		ClassLimit_SetSpecialRound(TFClass_Unknown);
	}

	//Create timer to play round start sound
	int iRoundTime = tf_arena_preround_time.IntValue;
	float flPickBossTime = float(iRoundTime)-7.0;
	CreateTimer(flPickBossTime, Timer_RoundStartSound, iMainBoss);
}

void SetBoss(int iClient, char[] sBossType, char[] sModifiersType)
{
	if (0 < iClient <= MaxClients && IsClientInGame(iClient))
	{
		SaxtonHaleBase boss = SaxtonHaleBase(iClient);
		
		// Allow them to join the boss team
		Client_AddFlag(iClient, haleClientFlags_BossTeam);
		TF2_ForceTeamJoin(iClient, BOSS_TEAM);

		boss.CallFunction("CreateBoss", sBossType);
		
		//Give every bosses able to scare scout by default
		CScareRage scareAbility = boss.CallFunction("FindAbility", "CScareRage");
		if (scareAbility == INVALID_ABILITY) //If boss don't have scare rage ability, give him one
			scareAbility = boss.CallFunction("CreateAbility", "CScareRage");
		scareAbility.nSetClass = TFClass_Scout;
		scareAbility.flRadiusClass = 800.0;
		scareAbility.iStunFlagsClass = TF_STUNFLAGS_SMALLBONK;
		
		//Select Modifiers
		if (!StrEqual(sModifiersType, "CModifiersNone") && !StrEmpty(sModifiersType))
			boss.CallFunction("CreateModifiers", sModifiersType);
		
		TF2_RespawnPlayer(iClient);
		
		//Display to client what boss you are for 10 seconds
		MenuBoss_DisplayBossInfo(iClient, sBossType, 10);
	}
}

stock int GetRandomBosses(char[] sBosses, int iLength, bool bDuo = false)
{
	//Saxton Hale should always be 0 in ArrayList
	if (GetRandomFloat(0.0, 1.0) <= g_ConfigConvar.LookupFloat("vsh_boss_chance_saxton"))
	{
		char sBossType[MAX_TYPE_CHAR];
		g_aBossesType.GetString(0, sBossType, sizeof(sBossType));
		Format(sBosses, iLength, sBossType);
		return;
	}
	
	//Random multiple bosses
	if (bDuo && GetRandomFloat(0.0, 1.0) <= g_ConfigConvar.LookupFloat("vsh_boss_chance_multi"))
	{
		ArrayList aBosses = new ArrayList(MAX_TYPE_CHAR);
		
		//Count players with duo prefs
		int iPlayersDuo = 0;
		for (int iClient = 1; iClient <= MaxClients; iClient++)
			if (IsClientInGame(iClient) && GetClientTeam(iClient) > 1 && Preferences_Get(iClient, halePreferences_PickAsBoss) && Preferences_Get(iClient, halePreferences_MultiBoss))
				iPlayersDuo++;
		
		//Create list of every possible multi boss to select
		int iArrayLength = g_aMiscBossesType.Length;
		for (int i = 0; i < iArrayLength; i++)
		{
			ArrayList aArray = g_aMiscBossesType.Get(i);
			int iArrayArrayLength = aArray.Length;
			
			//If not enough players with duo pref for boss, dont add
			if (iPlayersDuo < iArrayArrayLength) continue;
			
			//Push all bosses in one to list
			char sBuffer[256];
			for (int j = 0; j < iArrayArrayLength; j++)
			{
				char sBossType[MAX_TYPE_CHAR];
				aArray.GetString(j, sBossType, sizeof(sBossType));
				
				SaxtonHaleBase boss = SaxtonHaleBase(0);
				boss.CallFunction("SetBossType", sBossType);
				if (!boss.CallFunction("IsBossHidden"))
				{
					if (!StrEmpty(sBuffer)) StrCat(sBuffer, sizeof(sBuffer), " ; ");
					StrCat(sBuffer, sizeof(sBuffer), sBossType);
				}
			}
					
			aBosses.PushString(sBuffer);
		}
		
		int iBossesLength = aBosses.Length;
		
		//If no duo boss found, just use non-multi boss underneath instead
		if (iBossesLength > 0)
		{
			//Randomize and set bosses
			aBosses.GetString(GetRandomInt(0, iBossesLength - 1), sBosses, iLength);
			delete aBosses;
			return;
		}
		
		delete aBosses;
	}
	
	//Random non-multiple boss
	ArrayList aBosses = new ArrayList(MAX_TYPE_CHAR);
	int iArrayLength = g_aBossesType.Length;
	for (int i = 1; i < iArrayLength; i++) //Don't loop Saxton Hale from 0
	{
		char sBossType[MAX_TYPE_CHAR];
		g_aBossesType.GetString(i, sBossType, sizeof(sBossType));
		
		SaxtonHaleBase boss = SaxtonHaleBase(0);
		boss.CallFunction("SetBossType", sBossType);
		if (!boss.CallFunction("IsBossHidden"))
			aBosses.PushString(sBossType);
	}
	
	int iBossLength = aBosses.Length;
	if (iBossLength == 0)
	{
		delete aBosses;
		PluginStop(true, "[VSH] NO BOSS IN LIST TO SELECT RANDOM!!!!");
		return;
	}
	
	//Randomize and set bosses
	aBosses.GetString(GetRandomInt(0, iBossLength - 1), sBosses, iLength);
	delete aBosses;
}

stock int GetRandomModifiers(char[] sModifiers, int iLength, bool bForce = false)
{
	if (bForce || GetRandomFloat(0.0, 1.0) <= g_ConfigConvar.LookupFloat("vsh_boss_chance_modifiers"))
	{
		//Get list of every non-hidden modifiers to select random
		ArrayList aModifiers = new ArrayList(MAX_TYPE_CHAR);
		int iArrayLength = g_aModifiersType.Length;
		for (int iModifiers = 0; iModifiers < iArrayLength; iModifiers++)
		{
			char sModifiersType[MAX_TYPE_CHAR];
			g_aModifiersType.GetString(iModifiers, sModifiersType, sizeof(sModifiersType));
			
			SaxtonHaleBase boss = SaxtonHaleBase(0);
			boss.CallFunction("SetModifiersType", sModifiersType);
			if (!boss.CallFunction("IsModifiersHidden"))
				aModifiers.PushString(sModifiersType);
		}
		
		int iModifiersLength = aModifiers.Length;
		if (iModifiersLength == 0)
		{
			delete aModifiers;
			PluginStop(true, "[VSH] NO MODIFIERS IN LIST TO SELECT RANDOM!!!!");
			return;
		}
		
		//Randomizer and set modifiers
		aModifiers.GetString(GetRandomInt(0, iModifiersLength - 1), sModifiers, iLength);
		delete aModifiers;
	}
	else
	{
		Format(sModifiers, iLength, "CModifiersNone");
	}
}

stock void GetNextBossName(StringMap mNextBoss, char[] sBuffer, int iLength)
{
	if (mNextBoss == null) return;
	
	int iUserId;
	char sBoss[256], sModifiers[256];
	
	if (mNextBoss.GetValue("userid", iUserId))
		Format(sBuffer, iLength, "%s%N as ", sBuffer, GetClientOfUserId(iUserId));
	
	//If boss not set, display as "random (modifiers) boss"
	if (!mNextBoss.GetString("boss", sBoss, sizeof(sBoss)))
	{
		Format(sBuffer, iLength, "%sRandom ", sBuffer);
		Format(sBoss, sizeof(sBoss), "Boss", sBoss);
	}
	else
	{
		SaxtonHaleBase boss = SaxtonHaleBase(0);
		boss.CallFunction("SetBossType", sBoss);
		boss.CallFunction("GetBossName", sBoss, sizeof(sBoss));
	}
	
	if (mNextBoss.GetString("modifiers", sModifiers, sizeof(sModifiers)) && !StrEqual(sModifiers, "CModifiersNone"))
	{
		SaxtonHaleBase boss = SaxtonHaleBase(0);
		boss.CallFunction("SetModifiersType", sModifiers);
		boss.CallFunction("GetModifiersName", sModifiers, sizeof(sModifiers));
		
		Format(sBuffer, iLength, "%s%s ", sBuffer, sModifiers);
	}
	
	Format(sBuffer, iLength, "%s%s", sBuffer, sBoss);
}

stock void ClearAllNextBoss()
{
	int iLength = g_aNextBoss.Length;
	for (int i = 0; i < iLength; i++)
		delete view_as<StringMap>(g_aNextBoss.Get(i));	//Delete all StringMap in ArrayList
	
	g_aNextBoss.Clear();
}
