static ArrayList g_aNextBossMulti;
static bool g_bNextBossSpecialClass;
static TFClassType g_nNextBossSpecialClass;

void NextBoss_Init()
{
	g_aNextBoss = new ArrayList(sizeof(NextBoss));
	g_aNextBossMulti = new ArrayList();
	
	g_ConfigConvar.Create("vsh_boss_chance_saxton", "0.25", "% chance for next boss to be Saxton Hale from normal bosses pool (0.0 - 1.0)", _, true, 0.0, true, 1.0);
	g_ConfigConvar.Create("vsh_boss_chance_multi", "0.20", "% chance for next boss to be multiple bosses (0.0 - 1.0)", _, true, 0.0, true, 1.0);
	g_ConfigConvar.Create("vsh_boss_chance_modifiers", "0.15", "% chance for next boss to have random modifiers (0.0 - 1.0)", _, true, 0.0, true, 1.0);
}

int NextBoss_CreateStruct(int iClient)
{
	//Don't want to create another NextBoss if client specified already have one, return existing one instead
	if (0 < iClient <= MaxClients)
	{
		int iIndex = g_aNextBoss.FindValue(iClient, 1);	//assuming iClient is at 1 pos of struct
		if (iIndex >= 0)
		{
			NextBoss nextBoss;
			g_aNextBoss.GetArray(iIndex, nextBoss);
			return nextBoss.iId;
		}
	}
	
	g_iNextBossId++;
	
	NextBoss nextBoss;
	nextBoss.iId = g_iNextBossId;
	nextBoss.iClient = iClient;
	nextBoss.sBossType = NULL_STRING;
	nextBoss.sModifierType = NULL_STRING;
	
	g_aNextBoss.PushArray(nextBoss);
	return g_iNextBossId;
}

bool NextBoss_GetStruct(int iId, NextBoss nextBoss)
{
	int iIndex = g_aNextBoss.FindValue(iId, 0);	//assuming iId is at 0 pos of struct
	if (iIndex < 0)
		return false;
	
	g_aNextBoss.GetArray(iIndex, nextBoss);
	return true;
}

void NextBoss_SetStruct(NextBoss nextBoss)
{
	int iIndex = g_aNextBoss.FindValue(nextBoss.iId, 0);	//assuming iId is at 0 pos of struct
	if (iIndex >= 0)
		g_aNextBoss.SetArray(iIndex, nextBoss);
}

void NextBoss_Delete(SaxtonHaleNextBoss nextBoss)
{
	int iIndex = g_aNextBoss.FindValue(nextBoss, 0);	//assuming iId is at 0 pos of struct
	if (iIndex >= 0)
		g_aNextBoss.Erase(iIndex);
}

void NextBoss_DeleteClient(int iClient)
{
	int iIndex = g_aNextBoss.FindValue(iClient, 1);	//assuming iClient is at 1 pos of struct
	if (iIndex >= 0)
		g_aNextBoss.Erase(iIndex);
}

void NextBoss_SetSpecialClass(TFClassType nClass)
{
	g_bNextBossSpecialClass = true;
	g_nNextBossSpecialClass = nClass;
}

void NextBoss_SetNextBoss()
{
	//Get every non-specs, clients who has not been selected as boss yet
	ArrayList aNonBosses = new ArrayList();
	for (int iClient = 1; iClient <= MaxClients; iClient++)
		if (IsClientInGame(iClient) && TF2_GetClientTeam(iClient) > TFTeam_Spectator)
			aNonBosses.Push(iClient);
	
	aNonBosses.Sort(Sort_Random, Sort_Integer);
	
	bool bForceSet;
	int iMainBoss;
	
	//Check if there any client bosses force set for this round
	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if (IsClientInGame(iClient))
		{
			SaxtonHaleNextBoss nextBoss = SaxtonHaleNextBoss(iClient);
			if (nextBoss.bForceNext)
			{
				NextBoss_SetBoss(nextBoss, aNonBosses);
				bForceSet = true;
			}
		}
	}
	
	//Check if there any other bosses force set, but with missing client
	bool bBossSet;
	do
	{
		bBossSet = false;
		int iLength = g_aNextBoss.Length;
		for (int i = 0; i < iLength; i++)
		{
			NextBoss nextStruct;
			g_aNextBoss.GetArray(i, nextStruct);
			
			if (!nextStruct.bForceNext)
				continue;
			
			//We want to make sure same client can only have 1 NextBoss in array,
			//delete client's existing NextBoss and assign client to new NextBoss
			
			nextStruct.iClient = NextBoss_GetNextClient(aNonBosses);	//Get client in queue
			SaxtonHaleNextBoss nextBoss = SaxtonHaleNextBoss(nextStruct.iClient);	//Get existing client in NextBoss
			
			g_aNextBoss.SetArray(i, nextStruct);	//Set new client and infos to array
			NextBoss_Delete(nextBoss);	//Delete previous NextBoss after setting new client, otherwise array indexs get changed
			
			//Set boss
			nextBoss = SaxtonHaleNextBoss(nextStruct.iClient);
			NextBoss_SetBoss(nextBoss, aNonBosses);
			bForceSet = true;
			bBossSet = true;
			break;	//Break 'for' loop to start 'while' loop again, with updated NextBoss array
		}
	}
	while (bBossSet);
	
	//If there no force set, pick one from highest queue
	if (!bForceSet)
	{
		iMainBoss = NextBoss_GetNextClient(aNonBosses);
		
		//Roll for multi boss
		char sMultiBoss[MAX_TYPE_CHAR];
		if (Preferences_Get(iMainBoss, VSHPreferences_MultiBoss)
			&& GetRandomFloat(0.0, 1.0) <= g_ConfigConvar.LookupFloat("vsh_boss_chance_multi")
			&& NextBoss_GetRandomMulti(sMultiBoss, sizeof(sMultiBoss)))
		{
			ArrayList aList = new ArrayList(ByteCountToCells(MAX_TYPE_CHAR));
			SaxtonHale_CallFunction(sMultiBoss, "GetBossMultiList", aList);
			
			int iLength = aList.Length;
			for (int i = 0; i < iLength; i++)
			{
				int iClient = NextBoss_GetNextClient(aNonBosses, true);
				
				//Set client to play as multi boss
				SaxtonHaleNextBoss nextBoss = SaxtonHaleNextBoss(iClient);
				
				char sBossType[MAX_TYPE_CHAR];
				aList.GetString(i, sBossType, sizeof(sBossType));
				
				nextBoss.SetBoss(sBossType);
				nextBoss.SetBossMulti(sMultiBoss);
				NextBoss_SetBoss(nextBoss, aNonBosses);
			}

			delete aList;
		}
		else
		{
			//Set client to play as normal boss
			SaxtonHaleNextBoss nextBoss = SaxtonHaleNextBoss(iMainBoss);
			NextBoss_SetBoss(nextBoss, aNonBosses);
		}
	}
	
	delete aNonBosses;
	
	//Get amount of valid bosses after set
	int iBosses = 0;
	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if (SaxtonHale_IsValidBoss(iClient, false))
		{
			iBosses++;
			
			if (!iMainBoss)
				iMainBoss = iClient;
		}
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
	
	if (g_bNextBossSpecialClass || g_nNextBossSpecialClass != TFClass_Unknown)
	{
		if (g_nNextBossSpecialClass == TFClass_Unknown)
			g_nNextBossSpecialClass = view_as<TFClassType>(GetRandomInt(1, sizeof(g_strClassName)-1));
		
		ClassLimit_SetSpecialRound(g_nNextBossSpecialClass);
		PrintToChatAll("%s%s SPECIAL ROUND: %N versus %s", TEXT_TAG, TEXT_COLOR, iMainBoss, g_strClassName[g_nNextBossSpecialClass]);
		
		g_bNextBossSpecialClass = false;
		g_nNextBossSpecialClass = TFClass_Unknown;
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

int NextBoss_GetNextClient(ArrayList aNonBosses, bool bMultiBoss = false)
{
	if (aNonBosses.Length <= 0)
	{
		PluginStop(true, "[VSH] NO MORE AVAILABLE CLIENTS TO SET AS BOSS!!!!");
		return 0;
	}
	
	int iRank = 1;
	while (iRank > 0)	//Forever loop
	{
		int iClient = Queue_GetPlayerFromRank(iRank);
		
		if (iClient <= 0 || iClient > MaxClients || !IsClientInGame(iClient))
		{
			//No more available clients from queue, pick one random
			return aNonBosses.Get(0);
		}
		else if (aNonBosses.FindValue(iClient) < 0)
		{
			//If client not in aNonBosses, client should already be boss, skip
			iRank++;
		}
		else if (bMultiBoss && !Preferences_Get(iClient, VSHPreferences_MultiBoss))
		{
			//We want to skip players not wanting to play as multi boss
			iRank++;
		}
		else
		{
			//Should be safe to use client from queue
			return iClient;
		}
	}
	
	//We should never reach this line
	PluginStop(true, "[VSH] ESCAPED FOREVER LOOP!!!!");
	return 0;
}

void NextBoss_SetBoss(SaxtonHaleNextBoss nextBoss, ArrayList aNonBosses)
{
	//Fill random boss and not modifier if not set
	char sBossType[MAX_TYPE_CHAR], sBossMultiType[MAX_TYPE_CHAR], sModifierType[MAX_TYPE_CHAR];
	nextBoss.GetBoss(sBossType, sizeof(sBossType));
	nextBoss.GetBossMulti(sBossMultiType, sizeof(sBossMultiType));
	bool bModifierSet = nextBoss.GetModifier(sModifierType, sizeof(sModifierType));
	
	if (StrEmpty(sBossType))
		NextBoss_GetRandomNormal(sBossType, sizeof(sBossType));
	
	if (!bModifierSet)
		NextBoss_GetRandomModifiers(sModifierType, sizeof(sModifierType));
	
	SaxtonHaleBase boss = SaxtonHaleBase(nextBoss.iClient);
	if (boss.bValid)
	{
		//We should never get valid boss here
		PluginStop(true, "[VSH] CLIENT SELECTED TO BE BOSS IS ALREADY BOSS!!!!");
		return;
	}
	
	boss.CreateClass(sBossType);
	if (sBossMultiType[0])
		boss.CreateClass(sBossMultiType);
	
	//Select Modifiers
	if (!StrEmpty(sModifierType))
		boss.CreateClass(sModifierType);
	
	TF2_ForceTeamJoin(nextBoss.iClient, TFTeam_Boss);
	
	//Display to client what boss you are for 10 seconds
	MenuBoss_DisplayInfo(nextBoss.iClient, VSHClassType_Boss, sBossType, 10);
	
	//Enable special round if triggered
	if (nextBoss.bSpecialClassRound)
	{
		if (nextBoss.nSpecialClassType == TFClass_Unknown && g_nNextBossSpecialClass == TFClass_Unknown)
			g_nNextBossSpecialClass = view_as<TFClassType>(GetRandomInt(1, sizeof(g_strClassName)-1));
		else if (nextBoss.nSpecialClassType != TFClass_Unknown)
			g_nNextBossSpecialClass = nextBoss.nSpecialClassType;
	}

	//Reset player queue
	Queue_ResetPlayer(nextBoss.iClient);
	int iIndex = aNonBosses.FindValue(nextBoss.iClient);
	if (iIndex >= 0)
		aNonBosses.Erase(iIndex);
	
	//Clear next boss data
	NextBoss_Delete(nextBoss);
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
		for (int j = iMultiLength-1; j >= 0; j--)
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
	//Saxton Hale get higher chance to appear
	if (GetRandomFloat(0.0, 1.0) <= g_ConfigConvar.LookupFloat("vsh_boss_chance_saxton"))
	{
		Format(sBoss, iLength, "SaxtonHale");
		return;
	}
	
	//Get list of all bosses
	ArrayList aBosses = SaxtonHale_GetAllClassType(VSHClassType_Boss);
	
	//Delet saxton hale
	int iIndex = aBosses.FindString("SaxtonHale");
	if (iIndex >= 0)
		aBosses.Erase(iIndex);
	
	//Delet hidden bosses
	int iBossLength = aBosses.Length;
	for (int i = iBossLength-1; i >= 0; i--)
	{
		char sBuffer[MAX_TYPE_CHAR];
		aBosses.GetString(i, sBuffer, sizeof(sBuffer));
		if (SaxtonHale_CallFunction(sBuffer, "IsBossHidden"))
			aBosses.Erase(i);
	}
	
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

stock bool NextBoss_GetRandomMulti(char[] sBossMulti, int iLength)
{
	//Count players with duo prefs
	int iPlayersDuo = 0;
	for (int iClient = 1; iClient <= MaxClients; iClient++)
		if (IsClientInGame(iClient) && TF2_GetClientTeam(iClient) > TFTeam_Spectator && Preferences_Get(iClient, VSHPreferences_PickAsBoss) && Preferences_Get(iClient, VSHPreferences_MultiBoss))
			iPlayersDuo++;
	
	//Get list of all multi bosses
	ArrayList aBossesMulti = SaxtonHale_GetAllClassType(VSHClassType_BossMulti);
	
	int iBossLength = aBossesMulti.Length;
	for (int i = iBossLength-1; i >= 0; i--)
	{
		char sBuffer[MAX_TYPE_CHAR];
		aBossesMulti.GetString(i, sBuffer, sizeof(sBuffer));
		if (SaxtonHale_CallFunction(sBuffer, "IsBossMultiHidden"))
		{
			//Delet hidden multi bosses
			aBossesMulti.Erase(i);
			continue;
		}
		
		//Delet multi boss if too few players for it
		ArrayList aList = new ArrayList(ByteCountToCells(MAX_TYPE_CHAR));
		SaxtonHale_CallFunction(sBuffer, "GetBossMultiList", aList);
		if (aList.Length > iPlayersDuo)
			aBossesMulti.Erase(i);
		
		delete aList;
	}
	
	//No valid multi-boss to pick
	iBossLength = aBossesMulti.Length;
	if (iBossLength == 0)
	{
		delete aBossesMulti;
		return false;
	}
	
	aBossesMulti.GetString(GetRandomInt(0, iBossLength-1), sBossMulti, iLength);
	delete aBossesMulti;
	return true;
}

void NextBoss_GetRandomModifiers(char[] sModifiers, int iLength, bool bForce = false)
{
	if (bForce || GetRandomFloat(0.0, 1.0) <= g_ConfigConvar.LookupFloat("vsh_boss_chance_modifiers"))
	{
		//Get list of every non-hidden modifiers to select random
		ArrayList aModifiers = SaxtonHale_GetAllClassType(VSHClassType_Modifier);
		int iArrayLength = aModifiers.Length;
		for (int iModifiers = iArrayLength-1; iModifiers >= 0; iModifiers--)
		{
			char sModifiersType[MAX_TYPE_CHAR];
			aModifiers.GetString(iModifiers, sModifiersType, sizeof(sModifiersType));
			
			if (SaxtonHale_CallFunction(sModifiersType, "IsModifiersHidden"))
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
		Format(sModifiers, iLength, "");
	}
}