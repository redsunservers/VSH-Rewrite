static bool g_bClassLimit = false;		//Whenever if Class limit is enabled
static TFClassType g_nSpecialRoundClass = TFClass_Unknown;	//Class for current special round, TFClass_Unknown if not on

static TFClassType g_classMain[MAXPLAYERS];
static TFClassType g_classDesired[MAXPLAYERS];

static ConVar g_cvClassLimit[view_as<int>(TFClass_Engineer) + 1];

public void ClassLimit_Init()
{
	g_ConfigConvar.Create("vsh_class_limit", "0", "Enable or Disable Class Limit", _, true, 0.0, true, 1.0);
	g_cvClassLimit[1] = g_ConfigConvar.Create("vsh_class_limit_scout", "-1", "Limit how many players can be Scout, -1 for no limit", _, true, -1.0);
	g_cvClassLimit[2] = g_ConfigConvar.Create("vsh_class_limit_sniper", "-1", "Limit how many players can be Sniper, -1 for no limit", _, true, -1.0);
	g_cvClassLimit[3] = g_ConfigConvar.Create("vsh_class_limit_soldier", "-1", "Limit how many players can be Soldier, -1 for no limit", _, true, -1.0);
	g_cvClassLimit[4] = g_ConfigConvar.Create("vsh_class_limit_demoman", "-1", "Limit how many players can be Demoman, -1 for no limit", _, true, -1.0);
	g_cvClassLimit[5] = g_ConfigConvar.Create("vsh_class_limit_medic", "-1", "Limit how many players can be Medic, -1 for no limit", _, true, -1.0);
	g_cvClassLimit[6] = g_ConfigConvar.Create("vsh_class_limit_heavy", "-1", "Limit how many players can be Heavy, -1 for no limit", _, true, -1.0);
	g_cvClassLimit[7] = g_ConfigConvar.Create("vsh_class_limit_pyro", "-1", "Limit how many players can be Pyro, -1 for no limit", _, true, -1.0);
	g_cvClassLimit[8] = g_ConfigConvar.Create("vsh_class_limit_spy", "-1", "Limit how many players can be Spy, -1 for no limit", _, true, -1.0);
	g_cvClassLimit[9] = g_ConfigConvar.Create("vsh_class_limit_engineer", "-1", "Limit how many players can be Engineer, -1 for no limit", _, true, -1.0);
}

public void ClassLimit_Refresh()
{
	if (!g_ConfigConvar.LookupBool("vsh_class_limit"))
	{
		g_bClassLimit = false;
	}
	else	//If class limit config is enabled, check to see if config total number is enough for 32 players
	{
		int iMaxLimit = 0;
		for (int iClass = 1; iClass < sizeof(g_cvClassLimit); iClass++) //Goes through each class limit and count
		{
			char sName[MAXLEN_CONFIG_VALUE];
			g_cvClassLimit[iClass].GetName(sName, sizeof(sName));
			int iClassLimit = g_ConfigConvar.LookupInt(sName);
			
			if (iClassLimit == -1)	//If unlimited class found, stop counting
			{
				iMaxLimit = -1;
				break;
			}
			else
			{
				iMaxLimit += iClassLimit;
			}
		}
		
		if (iMaxLimit < MaxClients && iMaxLimit != -1)	//If total count is smaller than max players and not unlimited...
		{
			g_bClassLimit = false;				//...disable class limit
			PrintToChatAll("%s%s Class Limit config total number is too small! (min %d out of %d)", TEXT_TAG, TEXT_ERROR, iMaxLimit, MaxClients);
			LogMessage("Class Limit config total number is too small! (min %d out of %d)", iMaxLimit, MaxClients);
		}
		else
		{
			g_bClassLimit = true;				//Otherwise enable class limit
		}
	}
}

public TFClassType ClassLimit_GetNewClass(int iClient)
{
	SaxtonHaleBase boss = SaxtonHaleBase(iClient);
	if (boss.bValid)
	{
		return boss.nClass;
	}
	else if (g_nSpecialRoundClass != TFClass_Unknown)
	{
		//Special round
		return g_nSpecialRoundClass;
	}
	else if (g_bClassLimit)
	{
		TFClassType nClass = TF2_GetPlayerClass(iClient);
		
		//Try set class to his desired class if not already one
		TFClassType nDesiredClass = ClassLimit_GetDesiredClass(iClient);
		if (nDesiredClass != TFClass_Unknown && nClass != nDesiredClass)
		{
			if (ClassLimit_GetMaxNum(nDesiredClass) == -1 || ClassLimit_GetCurrentNum(nDesiredClass) < ClassLimit_GetMaxNum(nDesiredClass))
				return nDesiredClass;
		}
		
		//Otherwise, use current class and check if it breaks class limit
		if (ClassLimit_GetMaxNum(nClass) != -1 && ClassLimit_GetCurrentNum(nClass) > ClassLimit_GetMaxNum(nClass))
		{
			PrintToChat(iClient, "%s%s %s slot is already full! (max %d)", TEXT_TAG, TEXT_ERROR, g_strClassName[nClass], ClassLimit_GetMaxNum(nClass));
			return ClassLimit_GetRandomValidClass();
		}
		else
		{
			//Not breaking classlimit
			return nClass;
		}
	}
	else
	{
		//Class limit disabled, just use desired class
		if (ClassLimit_GetDesiredClass(iClient) != TFClass_Unknown)
			return ClassLimit_GetDesiredClass(iClient);
		else
			return TF2_GetPlayerClass(iClient);
	}
}

public Action ClassLimit_JoinClass(int iClient, TFClassType nClass)
{
	if (!SaxtonHale_IsValidAttack(iClient))
	{
		return Plugin_Handled;
	}
	else if (g_nSpecialRoundClass != TFClass_Unknown && g_nSpecialRoundClass != nClass)
	{
		//Special round check
		return Plugin_Handled;
	}
	else if (!g_bClassLimit)
	{
		return Plugin_Continue;
	}
	else if (ClassLimit_GetCurrentNum(nClass) >= ClassLimit_GetMaxNum(nClass))
	{
		PrintToChat(iClient, "%s%s %s slot is already full! (max %d)", TEXT_TAG, TEXT_ERROR, g_strClassName[nClass], ClassLimit_GetMaxNum(nClass));
		
		if (!IsPlayerAlive(iClient))	//Set valid class, otherwise may get bug to be "alive" while actually dead
			TF2_SetPlayerClass(iClient, ClassLimit_GetRandomValidClass());
		
		return Plugin_Handled;
	}
	else
	{
		//If player is dead, set current class as that class for real
		if (!IsPlayerAlive(iClient))
			TF2_SetPlayerClass(iClient, nClass);
		
		return Plugin_Continue;
	}
}

stock void ClassLimit_SetMainClass(int iClient, TFClassType class)
{
	g_classMain[iClient] = class;
}

stock TFClassType ClassLimit_GetMainClass(int iClient)
{
	return g_classMain[iClient];
}

stock void ClassLimit_SetDesiredClass(int iClient, TFClassType class)
{
	g_classDesired[iClient] = class;
}

stock TFClassType ClassLimit_GetDesiredClass(int iClient)
{
	return g_classDesired[iClient];
}

stock int ClassLimit_GetCurrentNum(TFClassType class)	//Input TFClassType, return number of clients playing as that class
{
	int iCurrentClassNum = 0;
	for (int iClient = 1; iClient <= MaxClients; iClient++)
		if (SaxtonHale_IsValidAttack(iClient) && TF2_GetPlayerClass(iClient) == class)
			iCurrentClassNum++;

	return iCurrentClassNum;
}

stock int ClassLimit_GetMaxNum(TFClassType nClass)	//Input TFClassType, return max allowed for that class
{
	char sName[MAXLEN_CONFIG_VALUE];
	g_cvClassLimit[nClass].GetName(sName, sizeof(sName));
	return g_ConfigConvar.LookupInt(sName);
}

stock void ClassLimit_SetSpecialRound(TFClassType nClass)
{
	g_nSpecialRoundClass = nClass;
	
	//Check every clients with new special round
	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if (!IsClientInGame(iClient) || GetClientTeam(iClient) <= 1) continue;
		
		TFClassType iOldClass = TF2_GetPlayerClass(iClient);
		TFClassType iNewClass = ClassLimit_GetNewClass(iClient);
		
		if (iOldClass != iNewClass)
		{
			TF2_SetPlayerClass(iClient, iNewClass);
			TF2_RespawnPlayer(iClient);
		}
	}
}

stock bool ClassLimit_IsSpecialRoundOn()
{
	if (g_nSpecialRoundClass != TFClass_Unknown)
		return true;
	
	return false;
}

stock TFClassType ClassLimit_GetRandomValidClass()
{
	//Create a list of all classes to randomize and select one
	TFClassType nClassList[sizeof(g_strClassName)-1];	//Don't want to count unknown class at 0
	for (int i = 0; i < sizeof(nClassList); i++)
		nClassList[i] = view_as<TFClassType>(i+1);
	
	//Randomize
	SortIntegers(view_as<int>(nClassList), sizeof(nClassList), Sort_Random);
	
	//Go through each class in the list, and find the class not already in limit
	for (int i = 0; i < sizeof(nClassList); i++)
	{
		if (ClassLimit_GetMaxNum(nClassList[i]) == -1 || ClassLimit_GetCurrentNum(nClassList[i]) < ClassLimit_GetMaxNum(nClassList[i]))
		{
			//We found the new class, return as that class
			return nClassList[i];
		}
	}
	
	//We somehow reach here with no other class to find... that should never happen
	PluginStop(true, "[VSH] FAILED TO FIND NEW CLASS IN CLASSLIMIT!!!!");
	return TFClass_Unknown;
}