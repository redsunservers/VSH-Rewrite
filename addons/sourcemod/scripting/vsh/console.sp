void Console_Init()
{
	AddCommandListener(Console_VoiceCommand, "voicemenu");
	AddCommandListener(Console_KillCommand, "kill");
	AddCommandListener(Console_KillCommand, "explode");
	AddCommandListener(Console_JoinTeamCommand, "jointeam");
	AddCommandListener(Console_JoinTeamCommand, "autoteam");
	AddCommandListener(Console_JoinTeamCommand, "spectate");
	AddCommandListener(Console_JoinClass, "joinclass");
	AddCommandListener(Console_BuildCommand, "build");
}

public Action Console_VoiceCommand(int iClient, const char[] sCommand, int iArgs)
{
	if (!g_bEnabled) return Plugin_Continue;
	if (g_iTotalRoundPlayed <= 0) return Plugin_Continue;
	if (iArgs < 2) return Plugin_Handled;

	char sCmd1[8], sCmd2[8];

	GetCmdArg(1, sCmd1, sizeof(sCmd1));
	GetCmdArg(2, sCmd2, sizeof(sCmd2));

	Action action = Plugin_Continue;
	SaxtonHaleBase boss = SaxtonHaleBase(iClient);
	if (boss.bValid && IsPlayerAlive(iClient))
	{
		action = boss.CallFunction("OnVoiceCommand", sCmd1, sCmd2);
		
		if (sCmd1[0] == '0' && sCmd2[0] == '0' && boss.iMaxRageDamage != -1 && (boss.iRageDamage >= boss.iMaxRageDamage))
		{
			boss.CallFunction("OnRage");
			action = Plugin_Handled;
		}
	}
	
	return action;
}

public Action Console_KillCommand(int iClient, const char[] sCommand, int iArgs)
{
	if (!g_bEnabled) return Plugin_Continue;
	if (g_iTotalRoundPlayed <= 0) return Plugin_Continue;
	
	SaxtonHaleBase boss = SaxtonHaleBase(iClient);
	if (boss.bValid && g_bRoundStarted)
	{
		if (!boss.bMinion)
			PrintToChat(iClient, "%s%s Do not suicide and waste round as Boss. Use !vshbosstoggle instead.", TEXT_TAG, TEXT_ERROR);
		else
			PrintToChat(iClient, "%s%s Do not suicide and play abnormally as Minion. Use !vshrevival instead if possible.", TEXT_TAG, TEXT_ERROR);
		
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

public Action Console_JoinTeamCommand(int iClient, const char[] sCommand, int iArgs)
{
	if (!g_bEnabled) return Plugin_Continue;
	if (g_iTotalRoundPlayed <= 0) return Plugin_Continue;

	char sTeam[64];
	if (strcmp(sCommand, "spectate") == 0)
		Format(sTeam, sizeof(sTeam), sCommand);
	
	if (strcmp(sCommand, "jointeam") == 0 && iArgs > 0)
		GetCmdArg(1, sTeam, sizeof(sTeam));
	
	if (strcmp(sTeam, "spectate") == 0)
	{
		SaxtonHaleBase boss = SaxtonHaleBase(iClient);
		if (boss.bValid && IsPlayerAlive(iClient) && (g_bRoundStarted || GameRules_GetRoundState() == RoundState_Preround))
		{
			if (!boss.bMinion)
				PrintToChat(iClient, "%s%s Please do not suicide and waste the round as Boss. Use !vshbosstoggle instead.", TEXT_TAG, TEXT_ERROR);
			else
				PrintToChat(iClient, "%s%s Please do not suicide and play abnormally as a Minion. Use !vshrevival instead if possible.", TEXT_TAG, TEXT_ERROR);
			
			return Plugin_Handled;
		}
		
		return Plugin_Continue;
	}
	
	//Check if we have active boss, otherwise we assume a VSH round is not on
	bool bBoss = false;
	for (int iBoss = 1; iBoss <= MaxClients; iBoss++)
	{
		if (SaxtonHale_IsValidBoss(iBoss))
		{
			bBoss = true;
			break;
		}
	}
	
	if (!bBoss)
		return Plugin_Continue;

	if (SaxtonHaleBase(iClient).bValid)
		return Plugin_Handled;
	
	TF2_ChangeClientTeam(iClient, TFTeam_Attack);
	
	TFTeam nTeam = TF2_GetClientTeam(iClient);
	ShowVGUIPanel(iClient, nTeam == TFTeam_Blue ? "class_blue" : "class_red");

	return Plugin_Handled;
}

public Action Console_JoinClass(int iClient, const char[] sCommand, int iArgs)
{
	if (!g_bEnabled) return Plugin_Continue;
	if (iArgs < 1) return Plugin_Continue;
	
	char sClass[64];
	GetCmdArg(1, sClass, sizeof(sClass));
	TFClassType nClass = TF2_GetClassType(sClass);
	
	if (nClass == TFClass_Unknown)
		return Plugin_Continue;
	
	//Since player want to play as that class, set desired class
	ClassLimit_SetDesiredClass(iClient, nClass);
	
	if (g_iTotalRoundPlayed <= 0)
		return Plugin_Continue;
	
	//Check whenever if allow change to that class
	return ClassLimit_JoinClass(iClient, nClass);
}

public Action Console_BuildCommand(int iClient, const char[] sCommand, int iArgs)
{
	if (!g_bEnabled) return Plugin_Continue;
	if (g_iTotalRoundPlayed <= 0) return Plugin_Continue;

	SaxtonHaleBase boss = SaxtonHaleBase(iClient);
	if (!boss.bValid)
		return Plugin_Continue;

	if (iArgs == 0)
		return Plugin_Handled;

	// https://wiki.teamfortress.com/wiki/Scripting#Buildings

	char sType[2], sMode[2];
	GetCmdArg(1, sType, sizeof(sType));

	TFObjectType nType = view_as<TFObjectType>(StringToInt(sType));
	TFObjectMode nMode = TFObjectMode_None;

	if (iArgs >= 2)
	{
		GetCmdArg(2, sMode, sizeof(sMode));
		nMode = view_as<TFObjectMode>(StringToInt(sMode));
	}
	else if (nType == view_as<TFObjectType>(3))	//Possible to use 3 as Teleporter Exit with only 1 arg
	{
		nType = TFObject_Teleporter;
		nMode = TFObjectMode_Exit;
	}
	
	return boss.CallFunction("OnBuild", nType, nMode);
}