enum ( <<=1 )
{
	MenuBossFlags_Hidden = 1,
	MenuBossFlags_Random,
	MenuBossFlags_None
}

//Callback when selecting boss/modifiers list
typedef MenuBossListCallback = function void (int iClient, const char[] sType);

static MenuBossListCallback g_fMenuBossCallback[TF_MAXPLAYERS+1];	//Callback function to use once client selected boss/modifiers

static StringMap g_mMenuInfo; 		//Menu handles of boss/modifers info
static NextBoss g_nextMenuSelectBoss[TF_MAXPLAYERS+1];

void MenuBoss_Init()
{
	g_mMenuInfo = new StringMap();
}

/*
 * Display list of bosses/modifiers
 */
 
void MenuBoss_DisplayBossList(int iClient, MenuBossListCallback callback, int iFlags = 0)
{
	Menu hMenuList = new Menu(MenuBoss_SelectList);
	hMenuList.SetTitle("Boss Menu\n---");
	hMenuList.AddItem("back", "<- back");
	
	if (iFlags & MenuBossFlags_Random)
		hMenuList.AddItem("random", "Random");
	
	if (iFlags & MenuBossFlags_None)
		hMenuList.AddItem("none", "None");
	
	//Loop through every bosses
	int iLength = g_aAllBossesType.Length;
	for (int i = 0; i < iLength; i++)
	{
		//Get boss type
		char sBossType[MAX_TYPE_CHAR];
		g_aAllBossesType.GetString(i, sBossType, sizeof(sBossType));
		
		SaxtonHaleBase boss = SaxtonHaleBase(0);
		boss.CallFunction("SetBossType", sBossType);
		
		//If disallow hidden bosses, check that
		if (!(iFlags & MenuBossFlags_Hidden) && boss.CallFunction("IsBossHidden"))
			continue;
		
		//Get boss name
		char sName[512];
		boss.CallFunction("GetBossName", sName, sizeof(sName));
		
		//Add to menu
		hMenuList.AddItem(sBossType, sName);
	}
	
	g_fMenuBossCallback[iClient] = callback;
	hMenuList.Display(iClient, MENU_TIME_FOREVER);
}

void MenuBoss_DisplayModifiersList(int iClient, MenuBossListCallback callback, int iFlags = 0)
{
	Menu hMenuList = new Menu(MenuBoss_SelectList);
	hMenuList.SetTitle("Modifiers Menu\n---");
	hMenuList.AddItem("back", "<- back");
	
	if (iFlags & MenuBossFlags_Random)
		hMenuList.AddItem("random", "Random");
	
	if (iFlags & MenuBossFlags_None)
		hMenuList.AddItem("none", "None");
	
	//Loop through every bosses
	int iLength = g_aModifiersType.Length;
	for (int i = 0; i < iLength; i++)
	{
		//Get boss type
		char sModifiersType[MAX_TYPE_CHAR];
		g_aModifiersType.GetString(i, sModifiersType, sizeof(sModifiersType));
		
		SaxtonHaleBase boss = SaxtonHaleBase(0);
		boss.CallFunction("SetModifiersType", sModifiersType);
		
		//If disallow hidden modifiers, check that
		if (!(iFlags & MenuBossFlags_Hidden) && boss.CallFunction("IsModifiersHidden"))
			continue;
		
		//Get modifiers name
		char sName[512];
		boss.CallFunction("GetModifiersName", sName, sizeof(sName));
		
		//Add to menu
		hMenuList.AddItem(sModifiersType, sName);
	}
	
	g_fMenuBossCallback[iClient] = callback;
	hMenuList.Display(iClient, MENU_TIME_FOREVER);
}

public int MenuBoss_SelectList(Menu hMenu, MenuAction action, int iClient, int iSelect)
{
	if (action == MenuAction_End)
	{
		delete hMenu;
	}
	else if (action == MenuAction_Select)
	{
		char sSelect[MAX_TYPE_CHAR];
		hMenu.GetItem(iSelect, sSelect, sizeof(sSelect));
		
		Call_StartFunction(null, g_fMenuBossCallback[iClient]);
		g_fMenuBossCallback[iClient] = INVALID_FUNCTION;
		
		Call_PushCell(iClient);
		Call_PushString(sSelect);
		Call_Finish();
	}
}

/*
 * Add/Remove bosses/modifiers info menu
 */

void MenuBoss_AddInfoBoss(const char[] sBossType)
{
	char sName[512], sInfo[512];
	
	SaxtonHaleBase boss = SaxtonHaleBase(0);
	boss.CallFunction("SetBossType", sBossType);
	boss.CallFunction("GetBossName", sName, sizeof(sName));
	
	//Create menu info for boss
	Menu hMenuBossInfo = new Menu(MenuBoss_SelectBossInfo);
	
	//Get Boss info to set title
	boss.CallFunction("GetBossInfo", sInfo, sizeof(sInfo));
	if (StrEmpty(sInfo))
		Format(sInfo, sizeof(sInfo), "%s\n \nThere seems to be nothing here...", sName);
	else
		Format(sInfo, sizeof(sInfo), "%s\n \n%s", sName, sInfo);
	
	hMenuBossInfo.SetTitle(sInfo);
	hMenuBossInfo.AddItem("back", "<- Back");
	
	g_mMenuInfo.SetValue(sBossType, hMenuBossInfo);
}

void MenuBoss_AddInfoModifiers(const char[] sModifiersType)
{
	char sName[512], sInfo[512];
	
	SaxtonHaleBase boss = SaxtonHaleBase(0);
	boss.CallFunction("SetModifiersType", sModifiersType);
	boss.CallFunction("GetModifiersName", sName, sizeof(sName));
	
	//Create menu info for modifiers
	Menu hMenuModifiersInfo = new Menu(MenuBoss_SelectModifiersInfo);
	
	//Get Modifiers info to set title
	boss.CallFunction("GetModifiersInfo", sInfo, sizeof(sInfo));
	if (StrEmpty(sInfo))
		Format(sInfo, sizeof(sInfo), "%s\n \nThere seems to be nothing here...", sName);
	else
		Format(sInfo, sizeof(sInfo), "%s\n \n%s", sName, sInfo);
	
	hMenuModifiersInfo.SetTitle(sInfo);
	hMenuModifiersInfo.AddItem("back", "<- Back");
	
	g_mMenuInfo.SetValue(sModifiersType, hMenuModifiersInfo);
}

void MenuBoss_RemoveInfo(const char[] sType)
{
	Menu hMenuInfo;
	if (g_mMenuInfo.GetValue(sType, hMenuInfo))
	{
		delete hMenuInfo;
		g_mMenuInfo.Remove(sType);
	}
}

/*
 * Display bosses/modifiers info
 */

public void MenuBoss_CallbackInfo(int iClient, const char[] sType)
{
	if (StrEqual(sType, "back"))
		Menu_DisplayMain(iClient);
	else
		MenuBoss_DisplayInfo(iClient, sType);
}

void MenuBoss_DisplayInfo(int iClient, const char[] sType, int iTime = MENU_TIME_FOREVER)
{
	Menu hMenuInfo;
	if (!g_mMenuInfo.GetValue(sType, hMenuInfo))
	{
		Menu_DisplayError(iClient);
		return;
	}
	
	hMenuInfo.Display(iClient, iTime);
}

public int MenuBoss_SelectBossInfo(Menu hMenu, MenuAction action, int iClient, int iSelect)
{
	//Only back button in menu
	if (action == MenuAction_Select)
		MenuBoss_DisplayBossList(iClient, MenuBoss_CallbackInfo);
}

public int MenuBoss_SelectModifiersInfo(Menu hMenu, MenuAction action, int iClient, int iSelect)
{
	//Only back button in menu
	if (action == MenuAction_Select)
		MenuBoss_DisplayModifiersList(iClient, MenuBoss_CallbackInfo);
}

/*
 * Admin next boss menus
 */

void MenuBoss_DisplayNextList(int iClient)
{
	Menu hAdminBossList = new Menu(MenuBoss_SelectNextList);
	
	char sBuffer[512];
	Format(sBuffer, sizeof(sBuffer), "Next Boss List\n---");
	
	int iLength = g_aNextBoss.Length;
	if (iLength == 0)
	{
		Format(sBuffer, sizeof(sBuffer), "%s\nThe list is empty", sBuffer);
	}
	else
	{
		for (int iBossCount = 0; iBossCount < iLength; iBossCount++)
		{
			//Get struct
			NextBoss nextStruct;
			g_aNextBoss.GetArray(iBossCount, nextStruct);
			
			//Get boss name and add to list
			char sNextBoss[256];
			GetNextBossName(nextStruct, sNextBoss, sizeof(sNextBoss));
			Format(sBuffer, sizeof(sBuffer), "%s\n%s", sBuffer, sNextBoss);
		}
	}
	
	//Set title and display
	Format(sBuffer, sizeof(sBuffer), "%s\n---", sBuffer);
	hAdminBossList.SetTitle(sBuffer);
	hAdminBossList.AddItem("back", "<- back");
	hAdminBossList.AddItem("add", "Add New Boss");
	hAdminBossList.AddItem("clear", "Clear List");
	hAdminBossList.Display(iClient, MENU_TIME_FOREVER);
}

public int MenuBoss_SelectNextList(Menu hMenu, MenuAction action, int iClient, int iSelect)
{
	if (action == MenuAction_End)
	{
		delete hMenu;
		return;
	}
	
	if (action != MenuAction_Select) return;
	
	char sSelect[16];
	hMenu.GetItem(iSelect, sSelect, sizeof(sSelect));
	
	if (StrEqual(sSelect, "add"))
	{
		MenuBoss_DisplayNextClient(iClient);
	}
	else if (StrEqual(sSelect, "clear"))
	{
		g_aNextBoss.Clear();
		PrintToChatAll("%s%s %N cleared all next boss", TEXT_TAG, TEXT_COLOR, iClient);
		MenuBoss_DisplayNextList(iClient);
	}
	else if (StrEqual(sSelect, "back"))
	{
		MenuAdmin_DisplayMain(iClient);
	}
	else
	{
		Menu_DisplayError(iClient);
	}
}

void MenuBoss_DisplayNextClient(int iClient)
{
	Menu hAdminNextBoss_Client = new Menu(MenuBoss_SelectNextClient);
	
	hAdminNextBoss_Client.SetTitle("Select Player to be Boss\n---");
	hAdminNextBoss_Client.AddItem("back", "<- back");
	hAdminNextBoss_Client.AddItem("", "None");
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			//Check client not already in list
			int iUserId = GetClientUserId(i);
			int iLength = g_aNextBoss.Length;
			for (int iBossCount = 0; iBossCount < iLength; iBossCount++)
			{
				NextBoss nextStruct;
				g_aNextBoss.GetArray(iBossCount, nextStruct);
				if (iUserId == nextStruct.iUserId)
				{
					iUserId = -1;
					break;
				}
			}
			
			if (iUserId == -1)
				continue;
			
			char sUserId[4], sName[64];
			IntToString(iUserId, sUserId, sizeof(sUserId));
			GetClientName(i, sName, sizeof(sName));
			
			hAdminNextBoss_Client.AddItem(sUserId, sName);
		}
	}
	
	hAdminNextBoss_Client.Display(iClient, MENU_TIME_FOREVER);
}

public int MenuBoss_SelectNextClient(Menu hMenu, MenuAction action, int iClient, int iSelect)
{
	if (action == MenuAction_End)
	{
		delete hMenu;
		return;
	}
	
	if (action != MenuAction_Select) return;
	
	char sSelect[16];
	hMenu.GetItem(iSelect, sSelect, sizeof(sSelect));
	
	if (StrEqual(sSelect, "back"))
	{
		MenuBoss_DisplayNextList(iClient);
	}
	else
	{
		int iUserId = StringToInt(sSelect);
		int iPlayer = GetClientOfUserId(iUserId);
		if (0 < iPlayer <= MaxClients && IsClientInGame(iPlayer))
			g_nextMenuSelectBoss[iClient].iUserId = iUserId;
		else
			g_nextMenuSelectBoss[iClient].iUserId = 0;
		
		MenuBoss_DisplayBossList(iClient, MenuBoss_CallbackNextBoss, MenuBossFlags_Hidden|MenuBossFlags_Random);
	}
}

public void MenuBoss_CallbackNextBoss(int iClient, const char[] sType)
{
	if (StrEqual(sType, "back"))
	{
		MenuBoss_DisplayNextClient(iClient);
		return;
	}
	else if (StrEqual(sType, "random"))
	{
		Format(g_nextMenuSelectBoss[iClient].sBoss, sizeof(g_nextMenuSelectBoss[].sBoss), "");
	}
	else
	{
		Format(g_nextMenuSelectBoss[iClient].sBoss, sizeof(g_nextMenuSelectBoss[].sBoss), sType);
	}
	
	MenuBoss_DisplayModifiersList(iClient, MenuBoss_CallbackNextModifiers, MenuBossFlags_Hidden|MenuBossFlags_Random|MenuBossFlags_None);
}

public void MenuBoss_CallbackNextModifiers(int iClient, const char[] sType)
{
	if (StrEqual(sType, "back"))
	{
		MenuBoss_DisplayBossList(iClient, MenuBoss_CallbackNextBoss, MenuBossFlags_Hidden|MenuBossFlags_Random);
		return;
	}
	else if (StrEqual(sType, "random"))
	{
		Format(g_nextMenuSelectBoss[iClient].sModifiers, sizeof(g_nextMenuSelectBoss[].sModifiers), "");
	}
	else if (StrEqual(sType, "none"))
	{
		Format(g_nextMenuSelectBoss[iClient].sModifiers, sizeof(g_nextMenuSelectBoss[].sModifiers), "CModifiersNone");
	}
	else
	{
		Format(g_nextMenuSelectBoss[iClient].sModifiers, sizeof(g_nextMenuSelectBoss[].sModifiers), sType);
	}
	
	//Push NextBoss to ArrayList
	g_aNextBoss.PushArray(g_nextMenuSelectBoss[iClient]);
	
	//Print chat boss been set
	char sBuffer[256];
	GetNextBossName(g_nextMenuSelectBoss[iClient], sBuffer, sizeof(sBuffer));
	PrintToChatAll("%s%s %N added next boss %s", TEXT_TAG, TEXT_COLOR, iClient, sBuffer);
	
	//Clear stuffs
	g_nextMenuSelectBoss[iClient].iUserId = 0;
	g_nextMenuSelectBoss[iClient].sBoss = "";
	g_nextMenuSelectBoss[iClient].sModifiers = "";
	
	MenuBoss_DisplayNextList(iClient);
}