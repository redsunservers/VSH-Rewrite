static ArrayList g_aNextBossMulti;

void NextBoss_Init()
{
	g_aNextBossMulti = new ArrayList();
	
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
	aClients.Sort(Sort_Random, Sort_Integer);
	
	//Find main boss
	int iMainBoss = 0;
	int iArray = 0;
	while (g_aNextBoss.Length > iArray && iMainBoss == 0)
	{
		//Get "main" boss
		NextBoss nextStruct;
		g_aNextBoss.GetArray(iArray, nextStruct);
		iMainBoss = GetClientOfUserId(nextStruct.iUserId);	//Should return 0 if invalid userid
		
		iArray++;
	}
	
	//If next player not force set as boss, get one from queue
	if (iMainBoss <= 0 || iMainBoss > MaxClients || !IsClientInGame(iMainBoss))
	{
		iMainBoss = Queue_GetPlayerFromRank(1);
		if (iMainBoss <= 0 || iMainBoss > MaxClients || !IsClientInGame(iMainBoss))
		{
			PrintToChatAll("%s%s Unable to find player in queue to become boss! %sPicking random player...", TEXT_TAG, TEXT_ERROR, TEXT_COLOR);
			iMainBoss = aClients.Get(0);
		}
	}
	
	//Check if next boss is not force set
	if (g_aNextBoss.Length == 0)
	{
		char sBoss[MAX_TYPE_CHAR];
		ArrayList aMultiBoss;
		
		if (GetRandomFloat(0.0, 1.0) <= g_ConfigConvar.LookupFloat("vsh_boss_chance_saxton"))
		{
			//Saxton Hale
			NextBoss nextStruct;
			Format(nextStruct.sBoss, sizeof(nextStruct.sBoss), "CSaxtonHale");
			g_aNextBoss.PushArray(nextStruct);
		}
		else if (Preferences_Get(iMainBoss, Preferences_MultiBoss)
			&& GetRandomFloat(0.0, 1.0) <= g_ConfigConvar.LookupFloat("vsh_boss_chance_multi")
			&& (aMultiBoss = NextBoss_GetRandomMulti()))
		{
			//Random multiple bosses
			int iLength = aMultiBoss.Length;
			for (int i = 0; i < iLength; i++)
			{
				aMultiBoss.GetString(i, sBoss, sizeof(sBoss));
				
				NextBoss nextStruct;
				Format(nextStruct.sBoss, sizeof(nextStruct.sBoss), sBoss);
				g_aNextBoss.PushArray(nextStruct);
			}
		}
		else
		{
			NextBoss_GetRandomNormal(sBoss, sizeof(sBoss));
			
			NextBoss nextStruct;
			Format(nextStruct.sBoss, sizeof(nextStruct.sBoss), sBoss);
			g_aNextBoss.PushArray(nextStruct);
		}
	}
	
	int iRank = 1;
	int iBossCount = g_aNextBoss.Length;
	//Loop though and check if all client, boss and modifiers has been set
	for (int i = 0; i < iBossCount; i++)
	{
		NextBoss nextStruct;
		g_aNextBoss.GetArray(i, nextStruct);
		
		//Check if client has been selected yet, and still in game
		int iClient = GetClientOfUserId(nextStruct.iUserId);
		if (iClient <= 0 || iClient > MaxClients || !IsClientInGame(iClient))
		{
			iClient = -1;
			while (iClient == -1 && aClients.Length > 0)
			{
				iClient = Queue_GetPlayerFromRank(iRank);
				
				//If cant find in list, get player from array sorted at random
				if (iClient <= 0 || iClient > MaxClients || !IsClientInGame(iClient))
					iClient = aClients.Get(0);
				
				//If were not at first boss to set, we assume there duo boss going on, dont select one with pref disabled
				else if (i > 0 && !Preferences_Get(iClient, Preferences_MultiBoss))
					iClient = -1;
				
				if (0 < iClient <= MaxClients && IsClientInGame(iClient))
				{
					nextStruct.iUserId = GetClientUserId(iClient);
					
					//Erase client in list
					int iIndex = aClients.FindValue(iClient);
					if (iIndex >= 0) aClients.Erase(iIndex);
				}
				
				iRank++;
			}
		}
		
		//Get random non-duo boss
		if (StrEmpty(nextStruct.sBoss))
			NextBoss_GetRandomNormal(nextStruct.sBoss, sizeof(nextStruct.sBoss));
		
		//Get random modifiers
		if (StrEmpty(nextStruct.sModifiers))
			NextBoss_GetRandomModifiers(nextStruct.sModifiers, sizeof(nextStruct.sModifiers));
		
		g_aNextBoss.SetArray(i, nextStruct);
	}
	
	//Loop again to actually set boss
	for (int i = 0; i < iBossCount; i++)
	{
		NextBoss nextStruct;
		g_aNextBoss.GetArray(i, nextStruct);
		
		int iClient = GetClientOfUserId(nextStruct.iUserId);
		if (iClient <= 0 || iClient > MaxClients || !IsClientInGame(iClient))
		{
			char sError[256];
			Format(sError, sizeof(sError), "[VSH] INVALID NEXT BOSS CLIENT %d, USERID %d", iClient, nextStruct.iUserId);
			PluginStop(true, sError);
			return;
		}
		
		//Set boss
		SetBoss(iClient, nextStruct.sBoss, nextStruct.sModifiers);
		
		// Reset their points
		Queue_ResetPlayer(iClient);
		
		// Enable special round if triggered
		if (g_bPlayerTriggerSpecialRound[iClient])
		{
			g_bSpecialRound = true;
			g_bPlayerTriggerSpecialRound[iClient] = false;
		}
	}
	
	//Whipe all next boss data
	g_aNextBoss.Clear();
	delete aClients;
	
	//Get amount of valid bosses after set
	int iBosses = 0;
	for (int iClient = 1; iClient <= MaxClients; iClient++)
		if (SaxtonHale_IsValidBoss(iClient, false))
			iBosses++;
	
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
		PrintToChatAll("%s%s SPECIAL ROUND: %N versus %s", TEXT_TAG, TEXT_COLOR, iMainBoss, g_strClassName[nSpecialRoundClass]);
		
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
		Client_AddFlag(iClient, ClientFlags_BossTeam);
		TF2_ForceTeamJoin(iClient, TFTeam_Boss);

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
		MenuBoss_DisplayInfo(iClient, sBossType, 10);
	}
}

stock void GetNextBossName(NextBoss nextStruct, char[] sBuffer, int iLength)
{
	char sBossName[256], sModifiersName[256];
	
	int iClient = GetClientOfUserId(nextStruct.iUserId);
	if (0 < iClient <= MaxClients && IsClientInGame(iClient))
		Format(sBuffer, iLength, "%s%N as ", sBuffer, iClient);
	
	//If boss not set, display as "random (modifiers) boss"
	if (StrEmpty(nextStruct.sBoss))
	{
		Format(sBuffer, iLength, "%sRandom ", sBuffer);
		Format(sBossName, sizeof(sBossName), "Boss");
	}
	else
	{
		SaxtonHaleBase boss = SaxtonHaleBase(0);
		boss.CallFunction("SetBossType", nextStruct.sBoss);
		boss.CallFunction("GetBossName", sBossName, sizeof(sBossName));
	}
	
	if (!StrEmpty(nextStruct.sModifiers) && !StrEqual(nextStruct.sModifiers, "CModifiersNone"))
	{
		SaxtonHaleBase boss = SaxtonHaleBase(0);
		boss.CallFunction("SetModifiersType", nextStruct.sModifiers);
		boss.CallFunction("GetModifiersName", sModifiersName, sizeof(sModifiersName));
		
		Format(sBuffer, iLength, "%s%s ", sBuffer, sModifiersName);
	}
	
	Format(sBuffer, iLength, "%s%s", sBuffer, sBossName);
}

stock void NextBoss_AddMulti(ArrayList aBosses)
{
	g_aNextBossMulti.Push(aBosses);
}

stock void NextBoss_RemoveMulti(const char[] sBoss)
{
	int iLength = g_aNextBossMulti.Length;
	for (int i = 0; i < iLength; i++)
	{
		ArrayList aMultiBoss = g_aNextBossMulti.Get(i);
		
		int iMultiLength = aMultiBoss.Length;
		for (int j = iMultiLength; j >= 0; j--)
		{
			char sMultiBoss[MAX_TYPE_CHAR];
			aMultiBoss.GetString(j, sMultiBoss, sizeof(sMultiBoss));
			
			if (StrEqual(sMultiBoss, sBoss))
			{
				aMultiBoss.Erase(j);
				
				//Check if 1 or less bosses in list, if so delet
				if (aMultiBoss.Length <= 1)
				{
					delete aMultiBoss;
					g_aNextBossMulti.Erase(i);
				}
				
				return;
			}
		}
	}
}

stock void NextBoss_GetRandomNormal(char[] sBoss, int iLength)
{
	//Get list of all bosses
	ArrayList aBosses = FuncClass_GetAllType(VSHClassType_Boss);
	
	//Delet multi boss
	int iBossLength = g_aNextBossMulti.Length;
	for (int i = 0; i < iBossLength; i++)
	{
		ArrayList aMultiBoss = g_aNextBossMulti.Get(i);
		
		int iMultiLength = aMultiBoss.Length;
		for (int j = 0; j < iMultiLength; j++)
		{
			char sMultiBoss[MAX_TYPE_CHAR];
			aMultiBoss.GetString(j, sMultiBoss, sizeof(sMultiBoss));
			
			int iIndex = aBosses.FindString(sMultiBoss);
			if (iIndex >= 0)
				aBosses.Erase(iIndex);
		}
	}
	
	//Delet saxton hale
	int iIndex = aBosses.FindString("CSaxtonHale");
	if (iIndex >= 0)
		aBosses.Erase(iIndex);
	
	//Delet hidden bosses
	iBossLength = aBosses.Length;
	for (int i = iBossLength-1; i >= 0; i--)
		if (NextBoss_IsBossHidden(aBosses, i))
			aBosses.Erase(i);
	
	iBossLength = aBosses.Length;
	if (iBossLength == 0)
	{
		delete aBosses;
		PluginStop(true, "[VSH] NO BOSS IN LIST TO SELECT RANDOM!!!!");
		return;
	}
	
	aBosses.GetString(GetRandomInt(0, iBossLength-1), sBoss, iLength);
	delete aBosses;
}

stock ArrayList NextBoss_GetRandomMulti()
{
	//Count players with duo prefs
	int iPlayersDuo = 0;
	for (int iClient = 1; iClient <= MaxClients; iClient++)
		if (IsClientInGame(iClient) && TF2_GetClientTeam(iClient) > TFTeam_Spectator && Preferences_Get(iClient, Preferences_PickAsBoss) && Preferences_Get(iClient, Preferences_MultiBoss))
			iPlayersDuo++;
	
	ArrayList aClone = g_aNextBossMulti.Clone();
	aClone.Sort(Sort_Random, Sort_Integer);
	
	while (aClone.Length)
	{
		ArrayList aMultiBoss = aClone.Get(0);
		
		int iLength = aMultiBoss.Length;
		if (iPlayersDuo >= iLength)
		{
			// Check if hidden boss
			bool bHidden = false;
			for (int i = 0; i < iLength; i++)
			{
				if (NextBoss_IsBossHidden(aMultiBoss, i))
				{
					bHidden = true;
					aClone.Erase(0);
					break;
				}
			}
			
			if (!bHidden)
			{
				delete aClone;
				return aMultiBoss;
			}
		}
		else
		{
			//Not enough players for this multi
			aClone.Erase(0);
		}
	}
	
	//No valid multi-boss to pick
	delete aClone;
	return null;
}

stock bool NextBoss_IsBossHidden(ArrayList aList, int iIndex)
{
	char sBuffer[MAX_TYPE_CHAR];
	aList.GetString(iIndex, sBuffer, sizeof(sBuffer));
	
	SaxtonHaleBase boss = SaxtonHaleBase(0);
	boss.CallFunction("SetBossType", sBuffer);
	return boss.CallFunction("IsBossHidden");
}

stock int NextBoss_GetRandomModifiers(char[] sModifiers, int iLength, bool bForce = false)
{
	if (bForce || GetRandomFloat(0.0, 1.0) <= g_ConfigConvar.LookupFloat("vsh_boss_chance_modifiers"))
	{
		//Get list of every non-hidden modifiers to select random
		ArrayList aModifiers = FuncClass_GetAllType(VSHClassType_Modifier);
		int iArrayLength = aModifiers.Length;
		for (int iModifiers = iArrayLength-1; iModifiers >= 0; iModifiers--)
		{
			char sModifiersType[MAX_TYPE_CHAR];
			aModifiers.GetString(iModifiers, sModifiersType, sizeof(sModifiersType));
			
			SaxtonHaleBase boss = SaxtonHaleBase(0);
			boss.CallFunction("SetModifiersType", sModifiersType);
			if (boss.CallFunction("IsModifiersHidden"))
				aModifiers.Erase(iModifiers);
		}
		
		iArrayLength = aModifiers.Length;
		if (iArrayLength == 0)
		{
			delete aModifiers;
			PluginStop(true, "[VSH] NO MODIFIERS IN LIST TO SELECT RANDOM!!!!");
			return;
		}
		
		//Randomizer and set modifiers
		aModifiers.GetString(GetRandomInt(0, iArrayLength-1), sModifiers, iLength);
		delete aModifiers;
	}
	else
	{
		Format(sModifiers, iLength, "CModifiersNone");
	}
}