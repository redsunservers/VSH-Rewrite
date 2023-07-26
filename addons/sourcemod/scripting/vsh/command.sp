static char g_strCommandPrefix[][] = {
	"vsh",
	"vsh_",
	"hale",
	"hale_"
};

public void Command_Init()
{
	//Commands for everyone
	RegConsoleCmd("vsh", Command_MainMenu);
	RegConsoleCmd("hale", Command_MainMenu);
	
	Command_Create("menu", Command_MainMenu);
	Command_Create("class", Command_Weapon);
	Command_Create("weapon", Command_Weapon);
	Command_Create("boss", Command_Boss);
	Command_Create("multiboss", Command_MultiBoss);
	Command_Create("modifiers", Command_Modifiers);
	Command_Create("next", Command_HaleNext);
	Command_Create("credits", Command_Credits);
	
	Command_Create("settings", Command_Preferences);
	Command_Create("preferences", Command_Preferences);
	Command_Create("bosstoggle", Command_Preferences_Boss);
	Command_Create("duo", Command_Preferences_Multi);
	Command_Create("multi", Command_Preferences_Multi);
	Command_Create("music", Command_Preferences_Music);
	Command_Create("revival", Command_Preferences_Revival);
	Command_Create("zombie", Command_Preferences_Revival);
	
	//Commands for admin only
	Command_Create("admin", Command_AdminMenu);
	Command_Create("refresh", Command_ConfigRefresh);
	Command_Create("cfg", Command_ConfigRefresh);
	Command_Create("queue", Command_AddQueuePoints);
	Command_Create("point", Command_AddQueuePoints);
	Command_Create("special", Command_ForceSpecialRound);
	Command_Create("dome", Command_ForceDome);
	Command_Create("rage", Command_SetRage);
}

stock void Command_Create(const char[] sCommand, ConCmd callback)
{
	for (int i = 0; i < sizeof(g_strCommandPrefix); i++)
	{
		char sBuffer[256];
		Format(sBuffer, sizeof(sBuffer), "%s%s", g_strCommandPrefix[i], sCommand);
		RegConsoleCmd(sBuffer, callback);
	}
}

public Action Command_MainMenu(int iClient, int iArgs)
{
	if (!g_bEnabled) return Plugin_Continue;

	if (iClient == 0)
	{
		ReplyToCommand(iClient, "This command can only be used in-game.");
		return Plugin_Handled;
	}

	Menu_DisplayMain(iClient);
	return Plugin_Handled;
}

public Action Command_Weapon(int iClient, int iArgs)
{
	if (!g_bEnabled) return Plugin_Continue;

	if (iClient == 0)
	{
		ReplyToCommand(iClient, "This command can only be used in-game.");
		return Plugin_Handled;
	}

	if (iArgs == 0)
	{
		MenuWeapon_DisplayMain(iClient);
		return Plugin_Handled;
	}

	char sClass[10];
	GetCmdArg(1, sClass, sizeof(sClass));
	TFClassType nClass = TF2_GetClassType(sClass);

	if (iArgs == 1)
	{
		MenuWeapon_DisplayClass(iClient, nClass);
		return Plugin_Handled;
	}

	char sSlot[10];
	GetCmdArg(2, sSlot, sizeof(sSlot));
	for (int iSlot = 0; iSlot < sizeof(g_strSlotName); iSlot++)
	{
		if (StrContains(g_strSlotName[iSlot], sSlot, false) != -1)
		{
			MenuWeapon_DisplaySlot(iClient, nClass, iSlot);
			return Plugin_Handled;
		}
	}
	
	//Slot name not found
	MenuWeapon_DisplayClass(iClient, nClass);
	return Plugin_Handled;
}

public Action Command_Boss(int iClient, int iArgs)
{
	if (!g_bEnabled) return Plugin_Continue;

	if (iClient == 0)
	{
		ReplyToCommand(iClient, "This command can only be used in-game.");
		return Plugin_Handled;
	}

	MenuBoss_DisplayList(iClient, VSHClassType_Boss, MenuBoss_CallbackInfo);
	return Plugin_Handled;
}

public Action Command_MultiBoss(int iClient, int iArgs)
{
	if (!g_bEnabled) return Plugin_Continue;

	if (iClient == 0)
	{
		ReplyToCommand(iClient, "This command can only be used in-game.");
		return Plugin_Handled;
	}

	MenuBoss_DisplayList(iClient, VSHClassType_BossMulti, MenuBoss_CallbackInfo);
	return Plugin_Handled;
}

public Action Command_Modifiers(int iClient, int iArgs)
{
	if (!g_bEnabled) return Plugin_Continue;

	if (iClient == 0)
	{
		ReplyToCommand(iClient, "This command can only be used in-game.");
		return Plugin_Handled;
	}

	MenuBoss_DisplayList(iClient, VSHClassType_Modifier, MenuBoss_CallbackInfo);
	return Plugin_Handled;
}

public Action Command_HaleNext(int iClient, int iArgs)
{
	if (!g_bEnabled) return Plugin_Continue;

	if (iClient == 0)
	{
		ReplyToCommand(iClient, "This command can only be used in-game.");
		return Plugin_Handled;
	}

	Menu_DisplayQueue(iClient);
	return Plugin_Handled;
}


public Action Command_Preferences(int iClient, int iArgs)
{
	if (!g_bEnabled) return Plugin_Continue;

	if (iClient == 0)
	{
		ReplyToCommand(iClient, "This command can only be used in-game.");
		return Plugin_Handled;
	}

	if (iArgs == 0)
	{
		//No args, just display prefs	
		Menu_DisplayPreferences(iClient);
		return Plugin_Handled;
	}
	else
	{
		char sPreferences[64];
		GetCmdArg(1, sPreferences, sizeof(sPreferences));
		
		for (SaxtonHalePreferences nPreferences; nPreferences < view_as<SaxtonHalePreferences>(sizeof(g_strPreferencesName)); nPreferences++)
		{
			if (!StrEmpty(g_strPreferencesName[nPreferences]) && StrContains(g_strPreferencesName[nPreferences], sPreferences, false) == 0)
			{
				bool bValue = !Preferences_Get(iClient, nPreferences);
				if (Preferences_Set(iClient, nPreferences, bValue))
				{
					char buffer[512];
					
					if (bValue)
						Format(buffer, sizeof(buffer), "Enable");
					else
						Format(buffer, sizeof(buffer), "Disable");
					
					PrintToChat(iClient, "%s%s %s %s", TEXT_TAG, TEXT_COLOR, buffer, g_strPreferencesName[nPreferences]);
					return Plugin_Handled;
				}
				else
				{
					PrintToChat(iClient, "%s%s Your preferences are still loading, try again later.", TEXT_TAG, TEXT_ERROR);
					return Plugin_Handled;
				}
			}
		}
		
		PrintToChat(iClient, "%s%s Invalid preferences entered.", TEXT_TAG, TEXT_ERROR);
		return Plugin_Handled;
	}
}

public Action Command_Preferences_Boss(int iClient, int iArgs)
{
	if (!g_bEnabled) return Plugin_Continue;

	if (iClient == 0)
	{
		ReplyToCommand(iClient, "This command can only be used in-game.");
		return Plugin_Handled;
	}

	ClientCommand(iClient, "vsh_preferences boss");
	return Plugin_Handled;
}

public Action Command_Preferences_Multi(int iClient, int iArgs)
{
	if (!g_bEnabled) return Plugin_Continue;

	if (iClient == 0)
	{
		ReplyToCommand(iClient, "This command can only be used in-game.");
		return Plugin_Handled;
	}

	ClientCommand(iClient, "vsh_preferences multi");
	return Plugin_Handled;
}

public Action Command_Preferences_Music(int iClient, int iArgs)
{
	if (!g_bEnabled) return Plugin_Continue;

	if (iClient == 0)
	{
		ReplyToCommand(iClient, "This command can only be used in-game.");
		return Plugin_Handled;
	}

	ClientCommand(iClient, "vsh_preferences music");
	return Plugin_Handled;
}

public Action Command_Preferences_Revival(int iClient, int iArgs)
{
	if (!g_bEnabled) return Plugin_Continue;

	if (iClient == 0)
	{
		ReplyToCommand(iClient, "This command can only be used in-game.");
		return Plugin_Handled;
	}

	ClientCommand(iClient, "vsh_preferences revival");
	return Plugin_Handled;
}

public Action Command_Credits(int iClient, int iArgs)
{
	if (!g_bEnabled) return Plugin_Continue;

	if (iClient == 0)
	{
		ReplyToCommand(iClient, "This command can only be used in-game.");
		return Plugin_Handled;
	}

	Menu_DisplayCredits(iClient);
	return Plugin_Handled;
}

public Action Command_AdminMenu(int iClient, int iArgs)
{
	if (!g_bEnabled) return Plugin_Continue;

	if (iClient == 0)
	{
		ReplyToCommand(iClient, "This command can only be used in-game.");
		return Plugin_Handled;
	}

	if (Client_HasFlag(iClient, ClientFlags_Admin))
	{
		MenuAdmin_DisplayMain(iClient);
		return Plugin_Handled;
	}
	else
	{
		ReplyToCommand(iClient, "%s%s You do not have permission to use this command.", TEXT_TAG, TEXT_ERROR);
		return Plugin_Handled;
	}
}

public Action Command_ConfigRefresh(int iClient, int iArgs)
{
	if (!g_bEnabled) return Plugin_Continue;

	if (Client_HasFlag(iClient, ClientFlags_Admin))
	{
		Config_Refresh();
		
		PrintToChatAll("%s%s %N refreshed the VSH config.", TEXT_TAG, TEXT_COLOR, iClient);
		return Plugin_Handled;
	}

	ReplyToCommand(iClient, "%s%s You do not have permission to use this command.", TEXT_TAG, TEXT_ERROR);
	return Plugin_Handled;
}

public Action Command_AddQueuePoints(int iClient, int iArgs)
{
	if (!g_bEnabled) return Plugin_Continue;

	if (Client_HasFlag(iClient, ClientFlags_Admin))
	{
		int iAddQueue;
		if (iArgs < 2)
		{
			ReplyToCommand(iClient, "%s%s Usage: vshqueue [target] [amount]", TEXT_TAG, TEXT_ERROR);
			return Plugin_Handled;
		}
		
		char sArg1[10], sArg2[10];
		GetCmdArg(1, sArg1, sizeof(sArg1));
		GetCmdArg(2, sArg2, sizeof(sArg2));
		
		if (StringToIntEx(sArg2, iAddQueue) == 0)
		{
			ReplyToCommand(iClient, "%s%s Could not convert '%s' to int", TEXT_TAG, TEXT_ERROR, sArg2);
			return Plugin_Handled;
		}
		
		int iTargetList[MAXPLAYERS];
		char sTargetName[MAX_TARGET_LENGTH];
		bool bIsML;
		
		int iTargetCount = ProcessTargetString(sArg1, iClient, iTargetList, sizeof(iTargetList), COMMAND_FILTER_NO_IMMUNITY, sTargetName, sizeof(sTargetName), bIsML);
		if (iTargetCount <= 0)
		{
			ReplyToCommand(iClient, "%s%s Could not find anyone to give queue points to.", TEXT_TAG, TEXT_ERROR);
			return Plugin_Handled;
		}
		
		for (int i = 0; i < iTargetCount; i++)
			Queue_AddPlayerPoints(iTargetList[i], iAddQueue);
		
		ReplyToCommand(iClient, "%s%s Gave %s %d queue points.", TEXT_TAG, TEXT_COLOR, sTargetName, iAddQueue);
		return Plugin_Handled;
	}

	ReplyToCommand(iClient, "%s%s You do not have permission to use this command.", TEXT_TAG, TEXT_ERROR);
	return Plugin_Handled;
}

public Action Command_ForceSpecialRound(int iClient, int iArgs)
{
	if (!g_bEnabled) return Plugin_Continue;

	if (Client_HasFlag(iClient, ClientFlags_Admin))
	{
		char sClass[256];
		
		if (iArgs < 1)
		{
			Format(sClass, sizeof(sClass), "random");
			NextBoss_SetSpecialClass(TFClass_Unknown);
		}
		else
		{
			GetCmdArg(1, sClass, sizeof(sClass));
			TFClassType nClass = TF2_GetClassType(sClass);
			
			if (nClass == TFClass_Unknown)
			{
				ReplyToCommand(iClient, "%s%s Unable to find class '%s'", TEXT_TAG, TEXT_ERROR, sClass);
				return Plugin_Handled;
			}
			
			Format(sClass, sizeof(sClass), g_strClassName[nClass]);
			NextBoss_SetSpecialClass(nClass);
		}
		
		PrintToChatAll("%s%s %N set the next round as a %s special round!", TEXT_TAG, TEXT_COLOR, iClient, sClass);
		return Plugin_Handled;
	}

	ReplyToCommand(iClient, "%s%s You do not have permission to use this command.", TEXT_TAG, TEXT_ERROR);
	return Plugin_Handled;
}

public Action Command_ForceDome(int iClient, int iArgs)
{
	if (!g_bEnabled) return Plugin_Continue;

	if (Client_HasFlag(iClient, ClientFlags_Admin))
	{
		char sBuffer[32];
		GetCmdArgString(sBuffer, sizeof(sBuffer));
		
		TFTeam nTeam;
		if (StrContains(sBuffer, "red", false) == 0)
			nTeam = TFTeam_Red;
		else if (StrContains(sBuffer, "blu", false) == 0)
			nTeam = TFTeam_Blue;
		else if (StrContains(sBuffer, "attack", false) == 0)
			nTeam = TFTeam_Attack;
		else if (StrContains(sBuffer, "boss", false) == 0)
			nTeam = TFTeam_Boss;
		else
			nTeam = view_as<TFTeam>(StringToInt(sBuffer));
		
		char sTeam[32];
		
		switch (nTeam)
		{
			case TFTeam_Attack:
			{
				Dome_SetTeam(TFTeam_Attack);
				sTeam = "attack";
			}
			case TFTeam_Boss:
			{
				Dome_SetTeam(TFTeam_Boss);
				sTeam = "boss";
			}
			default:
			{
				Dome_SetTeam(TFTeam_Unassigned);
				sTeam = "neutral";
			}
		}
		
		if (Dome_Start())
			PrintToChatAll("%s%s %N forcibly started a %s dome.", TEXT_TAG, TEXT_COLOR, iClient, sTeam);
		else
			PrintToChatAll("%s%s %N changed the dome team to %s.", TEXT_TAG, TEXT_COLOR, iClient, sTeam);
		
		return Plugin_Handled;
	}

	ReplyToCommand(iClient, "%s%s You do not have permission to use this command.", TEXT_TAG, TEXT_ERROR);
	return Plugin_Handled;
}

public Action Command_SetRage(int iClient, int iArgs)
{
	if (!g_bEnabled) return Plugin_Continue;

	if (Client_HasFlag(iClient, ClientFlags_Admin))
	{
		int iRage;
		if (iArgs == 0)
		{
			iRage = 100;
		}
		else if (iArgs == 1)
		{
			char strBuf[4];
			GetCmdArg(1, strBuf, sizeof(strBuf));
			if (StringToIntEx(strBuf, iRage) == 0)
			{
				ReplyToCommand(iClient, "%s%s Could not convert '%s' to int", TEXT_TAG, TEXT_ERROR, strBuf);
				return Plugin_Handled;
			}
		}
		else
		{
			ReplyToCommand(iClient, "%s%s Usage: vsh_rage [amount=100]", TEXT_TAG, TEXT_ERROR);
			return Plugin_Handled;
		}

		for (int i = 1; i <= MaxClients; i++)
		{
			SaxtonHaleBase boss = SaxtonHaleBase(i);
			if (boss.bValid && boss.iMaxRageDamage != -1)
				boss.iRageDamage = RoundToNearest(float(boss.iMaxRageDamage) * (float(iRage)/100.0));
		}

		PrintToChatAll("%s%s %N has set boss rage to %i percent.", TEXT_TAG, TEXT_COLOR, iClient, iRage);
		return Plugin_Handled;
	}

	ReplyToCommand(iClient, "%s%s You do not have permission to use this command.", TEXT_TAG, TEXT_ERROR);
	return Plugin_Handled;
}