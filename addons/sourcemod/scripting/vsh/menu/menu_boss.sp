enum ( <<=1 )
{
	MenuBossFlags_Hidden = 1,
	MenuBossFlags_Random,
	MenuBossFlags_None
}

enum struct MenuBossSelect
{
	int iClient;
	char sBossType[MAX_TYPE_CHAR];
	char sModifierType[MAX_TYPE_CHAR];
}

//Callback when selecting boss/modifiers list
typedef MenuBossListCallback = function void (int iClient, const char[] sType);

static MenuBossListCallback g_fMenuBossCallback[TF_MAXPLAYERS+1];	//Callback function to use once client selected boss/modifiers

static StringMap g_mMenuInfo; 		//Menu handles of boss/modifers info
static MenuBossSelect g_menuBossSelect[TF_MAXPLAYERS+1];

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
	ArrayList aBosses = FuncClass_GetAllType(VSHClassType_Boss);
	aBosses.Sort(Sort_Ascending, Sort_String);
	int iLength = aBosses.Length;
	for (int i = 0; i < iLength; i++)
	{
		//Get boss type
		char sBossType[MAX_TYPE_CHAR];
		aBosses.GetString(i, sBossType, sizeof(sBossType));
		
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
	
	delete aBosses;
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
	
	//Loop through every modifiers
	ArrayList aModifiers = FuncClass_GetAllType(VSHClassType_Modifier);
	aModifiers.Sort(Sort_Ascending, Sort_String);
	int iLength = aModifiers.Length;
	for (int i = 0; i < iLength; i++)
	{
		//Get boss type
		char sModifiersType[MAX_TYPE_CHAR];
		aModifiers.GetString(i, sModifiersType, sizeof(sModifiersType));
		
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
	
	delete aModifiers;
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
	
	bool bEmpty = true;
	int iLength = g_aNextBoss.Length;	
	for (int iBossCount = 0; iBossCount < iLength; iBossCount++)
	{
		//Get struct
		NextBoss nextStruct;
		g_aNextBoss.GetArray(iBossCount, nextStruct);
		if (!nextStruct.bForceNext)
			continue;
		
		//Get boss name and add to list
		char sNextBoss[256];
		SaxtonHaleNextBoss nextBoss = view_as<SaxtonHaleNextBoss>(nextStruct.iId);
		nextBoss.GetName(sNextBoss, sizeof(sNextBoss));
		Format(sBuffer, sizeof(sBuffer), "%s\n%s", sBuffer, sNextBoss);
		
		bEmpty = false;
	}
	
	if (bEmpty)
		Format(sBuffer, sizeof(sBuffer), "%s\nThe list is empty", sBuffer);
	
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
			bool bSkip;
			int iLength = g_aNextBoss.Length;
			for (int iBossCount = 0; iBossCount < iLength; iBossCount++)
			{
				NextBoss nextBoss;
				g_aNextBoss.GetArray(iBossCount, nextBoss);
				if (i == nextBoss.iClient && nextBoss.bForceNext)
				{
					bSkip = true;
					break;
				}
			}
			
			if (!bSkip)
			{
				char sClient[4], sName[64];
				IntToString(i, sClient, sizeof(sClient));
				GetClientName(i, sName, sizeof(sName));
				
				hAdminNextBoss_Client.AddItem(sClient, sName);
			}
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
		int iPlayer = StringToInt(sSelect);
		if (0 < iPlayer <= MaxClients && IsClientInGame(iPlayer))
			g_menuBossSelect[iClient].iClient = iPlayer;
		else
			g_menuBossSelect[iClient].iClient = 0;
		
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
		g_menuBossSelect[iClient].sBossType = NULL_STRING;
	}
	else
	{
		Format(g_menuBossSelect[iClient].sBossType, sizeof(g_menuBossSelect[].sBossType), sType);
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
		g_menuBossSelect[iClient].sModifierType = NULL_STRING;
	}
	else if (StrEqual(sType, "none"))
	{
		g_menuBossSelect[iClient].sModifierType = "CModifiersNone";
	}
	else
	{
		Format(g_menuBossSelect[iClient].sModifierType, sizeof(g_menuBossSelect[].sModifierType), sType);
	}
	
	//Add to list
	SaxtonHaleNextBoss nextBoss = SaxtonHaleNextBoss(g_menuBossSelect[iClient].iClient);
	nextBoss.SetBoss(g_menuBossSelect[iClient].sBossType);
	nextBoss.SetModifier(g_menuBossSelect[iClient].sModifierType);
	nextBoss.bForceNext = true;
	
	//Print chat boss been set
	char sBuffer[256];
	nextBoss.GetName(sBuffer, sizeof(sBuffer));
	PrintToChatAll("%s%s %N added next boss %s", TEXT_TAG, TEXT_COLOR, iClient, sBuffer);
	
	//Clear stuffs
	g_menuBossSelect[iClient].iClient = 0;
	g_menuBossSelect[iClient].sBossType = NULL_STRING;
	g_menuBossSelect[iClient].sModifierType = NULL_STRING;
	
	MenuBoss_DisplayNextList(iClient);
}