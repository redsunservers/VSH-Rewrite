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
	char sBossMultiType[MAX_TYPE_CHAR];
}

enum struct MenuBossListInfo
{
	char sTitle[32];
	char sSetType[MAX_TYPE_CHAR];
	char sIsHidden[MAX_TYPE_CHAR];
	char sGetName[MAX_TYPE_CHAR];
	char sGetInfo[512];
}

//Callback when selecting boss/modifiers list
typedef MenuBossListCallback = function void (int iClient, const char[] sType);

static SaxtonHaleClassType g_nMenuBossClassType[TF_MAXPLAYERS+1];	//Current class type using
static MenuBossListCallback g_fMenuBossCallback[TF_MAXPLAYERS+1];	//Callback function to use once client selected boss/modifiers

static MenuBossSelect g_menuBossSelect[TF_MAXPLAYERS+1];
static MenuBossListInfo g_menuBossListInfo[view_as<int>(SaxtonHaleClassType)];

void MenuBoss_Init()
{
	g_menuBossListInfo[VSHClassType_Boss].sTitle = "Boss Menu";
	g_menuBossListInfo[VSHClassType_Boss].sSetType = "SetBossType";
	g_menuBossListInfo[VSHClassType_Boss].sIsHidden = "IsBossHidden";
	g_menuBossListInfo[VSHClassType_Boss].sGetName = "GetBossName";
	g_menuBossListInfo[VSHClassType_Boss].sGetInfo = "GetBossInfo";
	
	g_menuBossListInfo[VSHClassType_Modifier].sTitle = "Modifiers Menu";
	g_menuBossListInfo[VSHClassType_Modifier].sSetType = "SetModifiersType";
	g_menuBossListInfo[VSHClassType_Modifier].sIsHidden = "IsModifiersHidden";
	g_menuBossListInfo[VSHClassType_Modifier].sGetName = "GetModifiersName";
	g_menuBossListInfo[VSHClassType_Modifier].sGetInfo = "GetModifiersInfo";
	
	g_menuBossListInfo[VSHClassType_BossMulti].sTitle = "Multi Boss Menu";
	g_menuBossListInfo[VSHClassType_BossMulti].sSetType = "SetBossMultiType";
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
	hMenuList.AddItem("back", "<- back");
	
	if (iFlags & MenuBossFlags_Random)
		hMenuList.AddItem("random", "Random");
	
	if (iFlags & MenuBossFlags_None)
		hMenuList.AddItem("none", "None");
	
	//Loop through every classes by type
	ArrayList aClasses = FuncClass_GetAllType(nClassType);
	aClasses.Sort(Sort_Ascending, Sort_String);
	int iLength = aClasses.Length;
	for (int i = 0; i < iLength; i++)
	{
		//Get boss type
		char sBossType[MAX_TYPE_CHAR];
		aClasses.GetString(i, sBossType, sizeof(sBossType));
		
		SaxtonHaleBase boss = SaxtonHaleBase(0);
		boss.CallFunction(g_menuBossListInfo[nClassType].sSetType, sBossType);
		
		//If disallow hidden class, check that
		if (!(iFlags & MenuBossFlags_Hidden) && boss.CallFunction(g_menuBossListInfo[nClassType].sIsHidden))
			continue;
		
		//Get boss name
		char sName[512];
		boss.CallFunction(g_menuBossListInfo[nClassType].sGetName, sName, sizeof(sName));
		
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
		
		Call_StartFunction(null, g_fMenuBossCallback[iClient]);
		g_fMenuBossCallback[iClient] = INVALID_FUNCTION;
		
		Call_PushCell(iClient);
		Call_PushString(sSelect);
		Call_Finish();
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
		MenuBoss_DisplayInfo(iClient, g_nMenuBossClassType[iClient], sType);
}

void MenuBoss_DisplayInfo(int iClient, SaxtonHaleClassType nClassType, const char[] sType, int iTime = MENU_TIME_FOREVER)
{
	g_nMenuBossClassType[iClient] = nClassType;
	
	char sName[512], sInfo[512];
	
	SaxtonHaleBase boss = SaxtonHaleBase(0);
	boss.CallFunction(g_menuBossListInfo[nClassType].sSetType, sType);
	boss.CallFunction(g_menuBossListInfo[nClassType].sGetName, sName, sizeof(sName));
	
	//Create menu info for boss
	Menu hMenuBossInfo = new Menu(MenuBoss_SelectInfo);
	
	//Get Boss info to set title
	boss.CallFunction(g_menuBossListInfo[nClassType].sGetInfo, sInfo, sizeof(sInfo));
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
	hAdminBossList.AddItem("bossmulti", "Add New Multi Boss");
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
		
		MenuBoss_DisplayList(iClient, VSHClassType_Boss, MenuBoss_CallbackNextBoss, MenuBossFlags_Hidden|MenuBossFlags_Random);
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
	
	MenuBoss_DisplayList(iClient, VSHClassType_Modifier, MenuBoss_CallbackNextModifiers, MenuBossFlags_Hidden|MenuBossFlags_Random|MenuBossFlags_None);
}

public void MenuBoss_CallbackNextModifiers(int iClient, const char[] sType)
{
	if (StrEqual(sType, "back"))
	{
		MenuBoss_DisplayList(iClient, VSHClassType_Boss, MenuBoss_CallbackNextBoss, MenuBossFlags_Hidden|MenuBossFlags_Random);
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
	
	if (!StrEmpty(g_menuBossSelect[iClient].sBossType))
	{
		//Add to list
		SaxtonHaleNextBoss nextBoss = SaxtonHaleNextBoss(g_menuBossSelect[iClient].iClient);
		nextBoss.SetBoss(g_menuBossSelect[iClient].sBossType);
		nextBoss.SetModifier(g_menuBossSelect[iClient].sModifierType);
		nextBoss.bForceNext = true;
		
		//Print chat boss been set
		char sBuffer[256];
		nextBoss.GetName(sBuffer, sizeof(sBuffer));
		PrintToChatAll("%s%s %N added next boss %s", TEXT_TAG, TEXT_COLOR, iClient, sBuffer);
	}
	else if (!StrEmpty(g_menuBossSelect[iClient].sBossMultiType))
	{
		//Add all bosses from multi to list
		SaxtonHaleBase boss = SaxtonHaleBase(0);
		boss.CallFunction("SetBossMultiType", g_menuBossSelect[iClient].sBossMultiType);
		boss.CallFunction("SetModifiersType", g_menuBossSelect[iClient].sModifierType);
		
		ArrayList aList = new ArrayList(ByteCountToCells(MAX_TYPE_CHAR));
		boss.CallFunction("GetBossMultiList", aList);
		
		int iLength = aList.Length;
		for (int i = 0; i < iLength; i++)
		{
			char sBossType[MAX_TYPE_CHAR];
			aList.GetString(i, sBossType, sizeof(sBossType));
			
			SaxtonHaleNextBoss nextBoss = SaxtonHaleNextBoss();
			nextBoss.SetBoss(sBossType);
			nextBoss.SetBossMulti(g_menuBossSelect[iClient].sBossMultiType);
			nextBoss.SetModifier(g_menuBossSelect[iClient].sModifierType);
			nextBoss.bForceNext = true;
		}
		
		delete aList;
		
		char sModifiersName[256], sBossMultiName[256];
		boss.CallFunction("GetModifiersName", sModifiersName, sizeof(sModifiersName));
		boss.CallFunction("GetBossMultiName", sBossMultiName, sizeof(sBossMultiName));
		
		if (StrEmpty(sModifiersName))
			PrintToChatAll("%s%s %N added next multi boss %s", TEXT_TAG, TEXT_COLOR, iClient, sBossMultiName);
		else
			PrintToChatAll("%s%s %N added next multi boss %s %s", TEXT_TAG, TEXT_COLOR, iClient, sModifiersName, sBossMultiName);
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

public void MenuBoss_CallbackNextBossMulti(int iClient, const char[] sType)
{
	if (StrEqual(sType, "back"))
	{
		MenuBoss_DisplayNextList(iClient);
		return;
	}
	else
	{
		Format(g_menuBossSelect[iClient].sBossMultiType, sizeof(g_menuBossSelect[].sBossMultiType), sType);
	}
	
	MenuBoss_DisplayList(iClient, VSHClassType_Modifier, MenuBoss_CallbackNextModifiers, MenuBossFlags_Hidden|MenuBossFlags_Random|MenuBossFlags_None);
}