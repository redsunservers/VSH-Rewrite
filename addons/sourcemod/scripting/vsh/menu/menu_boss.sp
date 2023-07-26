enum
{
	MenuBossFlags_Hidden = (1 << 0),
	MenuBossFlags_Random = (1 << 1),
	MenuBossFlags_None = (1 << 2),
}

enum MenuBossOption
{
	MenuBossOption_Unknown,	//Also used for "back" button
	MenuBossOption_Select,
	MenuBossOption_Random,
	MenuBossOption_None
}

enum struct MenuBossSelect
{
	int iClient;
	MenuBossOption nOption[view_as<int>(VSHClassType_Modifier) + 1];
	char sBossType[MAX_TYPE_CHAR];
	char sModifierType[MAX_TYPE_CHAR];
	char sBossMultiType[MAX_TYPE_CHAR];
	bool bModifierSet;
}

enum struct MenuBossListInfo
{
	char sTitle[32];
	char sIsHidden[MAX_TYPE_CHAR];
	char sGetName[MAX_TYPE_CHAR];
	char sGetInfo[512];
}

//Callback when selecting boss/modifiers list
typedef MenuBossListCallback = function void (int iClient, MenuBossOption nOption, const char[] sType);

static SaxtonHaleClassType g_nMenuBossClassType[MAXPLAYERS];	//Current class type using
static MenuBossListCallback g_fMenuBossCallback[MAXPLAYERS];	//Callback function to use once client selected boss/modifiers

static MenuBossSelect g_menuBossSelect[MAXPLAYERS];
static MenuBossListInfo g_menuBossListInfo[view_as<int>(VSHClassType_Modifier) + 1];

void MenuBoss_Init()
{
	g_menuBossListInfo[VSHClassType_Boss].sTitle = "Boss Menu";
	g_menuBossListInfo[VSHClassType_Boss].sIsHidden = "IsBossHidden";
	g_menuBossListInfo[VSHClassType_Boss].sGetName = "GetBossName";
	g_menuBossListInfo[VSHClassType_Boss].sGetInfo = "GetBossInfo";
	
	g_menuBossListInfo[VSHClassType_Modifier].sTitle = "Modifiers Menu";
	g_menuBossListInfo[VSHClassType_Modifier].sIsHidden = "IsModifiersHidden";
	g_menuBossListInfo[VSHClassType_Modifier].sGetName = "GetModifiersName";
	g_menuBossListInfo[VSHClassType_Modifier].sGetInfo = "GetModifiersInfo";
	
	g_menuBossListInfo[VSHClassType_BossMulti].sTitle = "Multi Boss Menu";
	g_menuBossListInfo[VSHClassType_BossMulti].sIsHidden = "IsBossMultiHidden";
	g_menuBossListInfo[VSHClassType_BossMulti].sGetName = "GetBossMultiName";
	g_menuBossListInfo[VSHClassType_BossMulti].sGetInfo = "GetBossMultiInfo";
}

// --------------------

/*
 * Display list of classes
 */

void MenuBoss_DisplayList(int iClient, SaxtonHaleClassType nClassType, MenuBossListCallback callback, int iFlags = 0)
{
	Menu hMenuList = new Menu(MenuBoss_SelectList);
	hMenuList.SetTitle("%s\n---", g_menuBossListInfo[nClassType].sTitle);
	hMenuList.AddItem("__back__", "<- back");
	
	if (iFlags & MenuBossFlags_Random)
		hMenuList.AddItem("__random__", "Random");
	
	if (iFlags & MenuBossFlags_None)
		hMenuList.AddItem("__none__", "None");
	
	//Loop through every classes by type
	ArrayList aClasses = SaxtonHale_GetAllClassType(nClassType);
	aClasses.Sort(Sort_Ascending, Sort_String);
	int iLength = aClasses.Length;
	for (int i = 0; i < iLength; i++)
	{
		//Get boss type
		char sBossType[MAX_TYPE_CHAR];
		aClasses.GetString(i, sBossType, sizeof(sBossType));
		
		//If disallow hidden class, check that
		if (!(iFlags & MenuBossFlags_Hidden) && SaxtonHale_CallFunction(sBossType, g_menuBossListInfo[nClassType].sIsHidden))
			continue;
		
		//Get boss name
		char sName[512];
		SaxtonHale_CallFunction(sBossType, g_menuBossListInfo[nClassType].sGetName, sName, sizeof(sName));
		if (!sName[0])
			strcopy(sName, sizeof(sName), sBossType);
		
		//Add to menu
		hMenuList.AddItem(sBossType, sName);
	}
	
	delete aClasses;
	g_nMenuBossClassType[iClient] = nClassType;
	g_fMenuBossCallback[iClient] = callback;
	hMenuList.Display(iClient, MENU_TIME_FOREVER);
}

// --------------------

/*
 * Display list of bosses/modifiers
 */

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
		
		SaxtonHaleClassType nClassType = g_nMenuBossClassType[iClient];
		
		if (StrEqual(sSelect, "__back__"))
			g_menuBossSelect[iClient].nOption[nClassType] = MenuBossOption_Unknown;
		else if (StrEqual(sSelect, "__random__"))
			g_menuBossSelect[iClient].nOption[nClassType] = MenuBossOption_Random;
		else if (StrEqual(sSelect, "__none__"))
			g_menuBossSelect[iClient].nOption[nClassType] = MenuBossOption_None;
		else
			g_menuBossSelect[iClient].nOption[nClassType] = MenuBossOption_Select;
		
		Call_StartFunction(null, g_fMenuBossCallback[iClient]);
		g_fMenuBossCallback[iClient] = INVALID_FUNCTION;
		
		Call_PushCell(iClient);
		Call_PushCell(g_menuBossSelect[iClient].nOption[nClassType]);
		Call_PushString(sSelect);
		Call_Finish();
	}
	
	return 0;
}

/*
 * Display bosses/modifiers info
 */

public void MenuBoss_CallbackInfo(int iClient, MenuBossOption nOption, const char[] sType)
{
	if (nOption == MenuBossOption_Unknown)
		Menu_DisplayMain(iClient);
	else
		MenuBoss_DisplayInfo(iClient, g_nMenuBossClassType[iClient], sType);
}

void MenuBoss_DisplayInfo(int iClient, SaxtonHaleClassType nClassType, const char[] sType, int iTime = MENU_TIME_FOREVER)
{
	g_nMenuBossClassType[iClient] = nClassType;
	
	char sName[512], sInfo[512];
	
	SaxtonHale_CallFunction(sType, g_menuBossListInfo[nClassType].sGetName, sName, sizeof(sName));
	if (!sName[0])
		strcopy(sName, sizeof(sName), sType);
	
	//Create menu info for boss
	Menu hMenuBossInfo = new Menu(MenuBoss_SelectInfo);
	
	//Get Boss info to set title
	SaxtonHale_CallFunction(sType, g_menuBossListInfo[nClassType].sGetInfo, sInfo, sizeof(sInfo));
	if (StrEmpty(sInfo))
		Format(sInfo, sizeof(sInfo), "%s\n \nThere seems to be nothing here...", sName);
	else
		Format(sInfo, sizeof(sInfo), "%s\n \n%s", sName, sInfo);
	
	hMenuBossInfo.SetTitle(sInfo);
	hMenuBossInfo.AddItem("back", "<- Back");
	hMenuBossInfo.Display(iClient, iTime);
}

public int MenuBoss_SelectInfo(Menu hMenu, MenuAction action, int iClient, int iSelect)
{
	//Only back button in menu
	if (action == MenuAction_Select)
		MenuBoss_DisplayList(iClient, g_nMenuBossClassType[iClient], MenuBoss_CallbackInfo);
	else if (action == MenuAction_End)
		delete hMenu;
	
	return 0;
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
	hAdminBossList.AddItem("boss", "Add New Boss");
	hAdminBossList.AddItem("bossmulti", "Add New Multi-Boss");
	hAdminBossList.AddItem("clear", "Clear List");
	hAdminBossList.Display(iClient, MENU_TIME_FOREVER);
}

public int MenuBoss_SelectNextList(Menu hMenu, MenuAction action, int iClient, int iSelect)
{
	if (action == MenuAction_End)
	{
		delete hMenu;
		return 0;
	}
	
	if (action != MenuAction_Select) return 0;
	
	char sSelect[16];
	hMenu.GetItem(iSelect, sSelect, sizeof(sSelect));
	
	if (StrEqual(sSelect, "boss"))
	{
		MenuBoss_DisplayNextClient(iClient);
	}
	else if (StrEqual(sSelect, "bossmulti"))
	{
		MenuBoss_DisplayList(iClient, VSHClassType_BossMulti, MenuBoss_CallbackNextBossMulti, MenuBossFlags_Hidden);
	}
	else if (StrEqual(sSelect, "clear"))
	{
		g_aNextBoss.Clear();
		PrintToChatAll("%s %s%N%s cleared all queued bosses.", TEXT_TAG, TEXT_DARK, iClient, TEXT_COLOR);
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
	
	return 0;
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
		return 0;
	}
	
	if (action != MenuAction_Select) return 0;
	
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
		
		MenuBoss_DisplayList(iClient, VSHClassType_Boss, MenuBoss_CallbackNextBoss, MenuBossFlags_Hidden|MenuBossFlags_Random);
	}
	
	return 0;
}

public void MenuBoss_CallbackNextBoss(int iClient, MenuBossOption nOption, const char[] sType)
{
	if (nOption == MenuBossOption_Unknown)
	{
		MenuBoss_DisplayNextClient(iClient);
		return;
	}
	else if (nOption == MenuBossOption_Select)
	{
		Format(g_menuBossSelect[iClient].sBossType, sizeof(g_menuBossSelect[].sBossType), sType);
	}
	
	MenuBoss_DisplayList(iClient, VSHClassType_Modifier, MenuBoss_CallbackNextModifiers, MenuBossFlags_Hidden|MenuBossFlags_Random|MenuBossFlags_None);
}

public void MenuBoss_CallbackNextModifiers(int iClient, MenuBossOption nOption, const char[] sType)
{
	if (nOption == MenuBossOption_Unknown)
	{
		MenuBoss_DisplayList(iClient, VSHClassType_Boss, MenuBoss_CallbackNextBoss, MenuBossFlags_Hidden|MenuBossFlags_Random);
		return;
	}
	else if (nOption == MenuBossOption_Select)
	{
		Format(g_menuBossSelect[iClient].sModifierType, sizeof(g_menuBossSelect[].sModifierType), sType);
		g_menuBossSelect[iClient].bModifierSet = true;
	}
	else	// Random and None
	{
		Format(g_menuBossSelect[iClient].sModifierType, sizeof(g_menuBossSelect[].sModifierType), "");
		
		if (nOption == MenuBossOption_Random)
			g_menuBossSelect[iClient].bModifierSet = false;
		else
			g_menuBossSelect[iClient].bModifierSet = true;
	}
	
	int iColor[4];
	char sColor[16];
	if (g_menuBossSelect[iClient].sModifierType[0])
		SaxtonHale_CallFunction(g_menuBossSelect[iClient].sModifierType, "GetRenderColor", iColor);
	
	if (iColor[3])
		ColorToTextStr(iColor, sColor, sizeof(sColor));
	else
		sColor = TEXT_DARK;
	
	if (view_as<MenuBossOption>(g_menuBossSelect[iClient].nOption[VSHClassType_Boss]) != MenuBossOption_Unknown)
	{
		//Add to list
		SaxtonHaleNextBoss nextBoss = SaxtonHaleNextBoss(g_menuBossSelect[iClient].iClient);
		nextBoss.SetBoss(g_menuBossSelect[iClient].sBossType);
		nextBoss.bForceNext = true;
		
		if (g_menuBossSelect[iClient].bModifierSet)
			nextBoss.SetModifier(g_menuBossSelect[iClient].sModifierType);
		else
			nextBoss.SetModifier(NULL_STRING);
		
		//Print chat boss been set
		char sBuffer[256];
		nextBoss.GetName(sBuffer, sizeof(sBuffer));
		PrintToChatAll("%s %s%N%s added next boss %s%s", TEXT_TAG, TEXT_DARK, iClient, TEXT_COLOR, sColor, sBuffer);
	}
	else if (view_as<MenuBossOption>(g_menuBossSelect[iClient].nOption[VSHClassType_BossMulti]) != MenuBossOption_Unknown)
	{
		//Add all bosses from multi to list
		ArrayList aList = new ArrayList(ByteCountToCells(MAX_TYPE_CHAR));
		SaxtonHale_CallFunction(g_menuBossSelect[iClient].sBossMultiType, "GetBossMultiList", aList);
		
		int iLength = aList.Length;
		for (int i = 0; i < iLength; i++)
		{
			char sBossType[MAX_TYPE_CHAR];
			aList.GetString(i, sBossType, sizeof(sBossType));
			
			SaxtonHaleNextBoss nextBoss = SaxtonHaleNextBoss();
			nextBoss.SetBoss(sBossType);
			nextBoss.SetBossMulti(g_menuBossSelect[iClient].sBossMultiType);
			nextBoss.bForceNext = true;
			
			if (g_menuBossSelect[iClient].bModifierSet)
				nextBoss.SetModifier(g_menuBossSelect[iClient].sModifierType);
			else
				nextBoss.SetModifier(NULL_STRING);
		}
		
		delete aList;
		
		char sBossMultiName[256];
		SaxtonHale_CallFunction(g_menuBossSelect[iClient].sBossMultiType, "GetBossMultiName", sBossMultiName, sizeof(sBossMultiName));
		
		if (view_as<MenuBossOption>(g_menuBossSelect[iClient].nOption[VSHClassType_Modifier]) == MenuBossOption_Select)
		{
			char sModifiersName[256];
			SaxtonHale_CallFunction(g_menuBossSelect[iClient].sModifierType, "GetModifiersName", sModifiersName, sizeof(sModifiersName));
			PrintToChatAll("%s %s%N%s added %s%s %s as the next multi-boss.", TEXT_TAG, TEXT_DARK, iClient, TEXT_COLOR, sColor, sModifiersName, sBossMultiName);
		}
		else
		{
			PrintToChatAll("%s %s%N%s added %s%s as the next multi-boss.", TEXT_TAG, TEXT_DARK, iClient, TEXT_COLOR, sColor, sBossMultiName);
		}
	}
	else
	{
		Menu_DisplayError(iClient);
		return;
	}
	
	//Clear stuffs
	MenuBossSelect nothing;
	g_menuBossSelect[iClient] = nothing;
	
	MenuBoss_DisplayNextList(iClient);
}

public void MenuBoss_CallbackNextBossMulti(int iClient, MenuBossOption nOption, const char[] sType)
{
	if (nOption == MenuBossOption_Unknown)
	{
		MenuBoss_DisplayNextList(iClient);
		return;
	}
	else if (nOption == MenuBossOption_Select)
	{
		Format(g_menuBossSelect[iClient].sBossMultiType, sizeof(g_menuBossSelect[].sBossMultiType), sType);
	}
	
	MenuBoss_DisplayList(iClient, VSHClassType_Modifier, MenuBoss_CallbackNextModifiers, MenuBossFlags_Hidden|MenuBossFlags_Random|MenuBossFlags_None);
}