static Menu g_hMenuBossMain;			//Main menu of boss info
static ArrayList g_aMenuBossName;		//Array of bosses ordered from g_aMenuBossInfo
static ArrayList g_aMenuBossInfo;		//Menus of each boss info

static Menu g_hMenuModifiersMain;		//Main menu of modifiers info
static ArrayList g_aMenuModifiersName;	//Array of modifiers ordered from g_aMenuModifiersInfo
static ArrayList g_aMenuModifiersInfo;	//Menus of each modifiers info

static Menu g_hMenuNextBoss;
static Menu g_hMenuNextModifiers;

static NextBoss g_nextMenuSelectBoss[TF_MAXPLAYERS+1];

void MenuBoss_Init()
{
	//Boss/modifiers types
	g_aMenuBossName = new ArrayList(MAX_TYPE_CHAR);
	g_aMenuModifiersName = new ArrayList(MAX_TYPE_CHAR);
	
	//Menu handles
	g_aMenuBossInfo = new ArrayList();
	g_aMenuModifiersInfo = new ArrayList();
	
	//Create boss info menu
	g_hMenuBossMain = new Menu(MenuBoss_SelectBossMain);
	g_hMenuBossMain.SetTitle("Boss Menu");
	g_hMenuBossMain.AddItem("back", "<- Back");

	//Create boss selection menu for admins
	g_hMenuNextBoss = new Menu(MenuBoss_SelectNextBoss);
	g_hMenuNextBoss.SetTitle("Select next boss\n---");
	g_hMenuNextBoss.AddItem("back", "<- back");
	g_hMenuNextBoss.AddItem("random", "Random");
	g_hMenuNextBoss.AddItem("", "---", ITEMDRAW_DISABLED);
	
	//Create modifiers info menu
	g_hMenuModifiersMain = new Menu(MenuBoss_SelectModifiersMain);
	g_hMenuModifiersMain.SetTitle("Modifiers Menu");
	g_hMenuModifiersMain.AddItem("back", "<- Back");
	
	//Create modifiers selection menu for admins
	g_hMenuNextModifiers = new Menu(MenuBoss_SelectNextModifiers);
	g_hMenuNextModifiers.SetTitle("Select next modifiers");
	g_hMenuNextModifiers.AddItem("back", "<- back");
	g_hMenuNextModifiers.AddItem("random", "Random");
	g_hMenuNextModifiers.AddItem("CModifiersNone", "None");
	g_hMenuNextModifiers.AddItem("", "---", ITEMDRAW_DISABLED);
}

void MenuBoss_AddBoss(const char[] sBossType)
{
	char sName[512], sInfo[512];
	
	SaxtonHaleBase boss = SaxtonHaleBase(0);
	boss.CallFunction("SetBossType", sBossType);
	boss.CallFunction("GetBossName", sName, sizeof(sName));
	bool bIsHidden = boss.CallFunction("IsBossHidden");
	
	g_hMenuNextBoss.AddItem(sBossType, sName);
	
	if (bIsHidden) return;
	
	g_hMenuBossMain.AddItem(sBossType, sName);
	
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
	
	g_aMenuBossName.PushString(sBossType);
	g_aMenuBossInfo.Push(hMenuBossInfo);
}

void MenuBoss_RemoveBoss(const char[] sBossType)
{
	//Remove from boss info
	int iLength = g_hMenuBossMain.ItemCount;
	for (int i = 0; i < iLength; i++)
	{
		char sBuffer[MAX_TYPE_CHAR];
		g_hMenuBossMain.GetItem(i, sBuffer, sizeof(sBuffer));
		if (StrEqual(sBossType, sBuffer))
		{
			//Found boss in menu, erase from list
			g_hMenuBossMain.RemoveItem(i);
			break;
		}
	}
	
	//Delete boss info menu
	int iIndex = g_aMenuBossName.FindString(sBossType);
	if (iIndex >= 0)
	{
		Menu hMenu = g_aMenuBossInfo.Get(iIndex);
		delete hMenu;
		
		g_aMenuBossName.Erase(iIndex);
		g_aMenuBossInfo.Erase(iIndex);
	}
	
	//Remove from boss selection
	iLength = g_hMenuNextBoss.ItemCount;
	for (int i = 0; i < iLength; i++)
	{
		char sBuffer[MAX_TYPE_CHAR];
		g_hMenuNextBoss.GetItem(i, sBuffer, sizeof(sBuffer));
		if (StrEqual(sBossType, sBuffer))
		{
			//Found boss in menu, erase from list
			g_hMenuBossMain.RemoveItem(i);
			break;
		}
	}
}

void MenuBoss_AddModifiers(const char[] sModifiersType)
{
	char sName[512], sInfo[512];
	
	SaxtonHaleBase boss = SaxtonHaleBase(0);
	boss.CallFunction("SetModifiersType", sModifiersType);
	boss.CallFunction("GetModifiersName", sName, sizeof(sName));
	bool bIsHidden = boss.CallFunction("IsModifiersHidden");
	
	g_hMenuNextModifiers.AddItem(sModifiersType, sName);
	
	if (bIsHidden) return;
	
	g_hMenuModifiersMain.AddItem(sModifiersType, sName);
	
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
	
	g_aMenuModifiersName.PushString(sModifiersType);
	g_aMenuModifiersInfo.Push(hMenuModifiersInfo);
}

void MenuBoss_RemoveModifiers(const char[] sModifiersType)
{
	//Remove from boss info
	int iLength = g_hMenuModifiersMain.ItemCount;
	for (int i = 0; i < iLength; i++)
	{
		char sBuffer[MAX_TYPE_CHAR];
		g_hMenuModifiersMain.GetItem(i, sBuffer, sizeof(sBuffer));
		if (StrEqual(sModifiersType, sBuffer))
		{
			//Found boss in menu, erase from list
			g_hMenuModifiersMain.RemoveItem(i);
			break;
		}
	}
	
	//Delete modifiers info menu
	int iIndex = g_aMenuModifiersName.FindString(sModifiersType);
	if (iIndex >= 0)
	{
		Menu hMenu = g_aMenuModifiersInfo.Get(iIndex);
		delete hMenu;
		
		g_aMenuModifiersName.Erase(iIndex);
		g_aMenuModifiersInfo.Erase(iIndex);
	}
	
	//Remove from boss selection
	iLength = g_hMenuNextModifiers.ItemCount;
	for (int i = 0; i < iLength; i++)
	{
		char sBuffer[MAX_TYPE_CHAR];
		g_hMenuNextModifiers.GetItem(i, sBuffer, sizeof(sBuffer));
		if (StrEqual(sModifiersType, sBuffer))
		{
			//Found boss in menu, erase from list
			g_hMenuNextModifiers.RemoveItem(i);
			break;
		}
	}
}

void MenuBoss_DisplayBossMain(int iClient)
{
	g_hMenuBossMain.Display(iClient, MENU_TIME_FOREVER);
}

public int MenuBoss_SelectBossMain(Menu hMenu, MenuAction action, int iClient, int iSelect)
{
	if (action != MenuAction_Select) return;
	
	char sSelect[MAX_TYPE_CHAR];
	hMenu.GetItem(iSelect, sSelect, sizeof(sSelect));
	
	if (StrEqual(sSelect, "back"))
		Menu_DisplayMain(iClient);
	else
		MenuBoss_DisplayBossInfo(iClient, sSelect);
}

void MenuBoss_DisplayBossInfo(int iClient, char[] sBossType, int iTime = MENU_TIME_FOREVER)
{
	int iIndex = g_aMenuBossName.FindString(sBossType);
	if (iIndex < 0)
	{
		Menu_DisplayError(iClient);
		return;
	}
	
	Menu hMenuBossInfo = g_aMenuBossInfo.Get(iIndex);
	hMenuBossInfo.Display(iClient, iTime);
}

public int MenuBoss_SelectBossInfo(Menu hMenu, MenuAction action, int iClient, int iSelect)
{
	if (action != MenuAction_Select) return;
	
	//Only back button in menu
	MenuBoss_DisplayBossMain(iClient);
}

void MenuBoss_DisplayModifiersMain(int iClient)
{
	g_hMenuModifiersMain.Display(iClient, MENU_TIME_FOREVER);
}

public int MenuBoss_SelectModifiersMain(Menu hMenu, MenuAction action, int iClient, int iSelect)
{
	if (action != MenuAction_Select) return;
	
	char sSelect[MAX_TYPE_CHAR];
	hMenu.GetItem(iSelect, sSelect, sizeof(sSelect));
	
	if (StrEqual(sSelect, "back"))
		Menu_DisplayMain(iClient);
	else
		MenuBoss_DisplayModifiersInfo(iClient, sSelect);
}

void MenuBoss_DisplayModifiersInfo(int iClient, char[] sModifiersType)
{
	int iIndex = g_aMenuModifiersName.FindString(sModifiersType);
	if (iIndex < 0)
	{
		Menu_DisplayError(iClient);
		return;
	}
	
	Menu hMenuModifiersInfo = g_aMenuModifiersInfo.Get(iIndex);
	hMenuModifiersInfo.Display(iClient, MENU_TIME_FOREVER);
}

public int MenuBoss_SelectModifiersInfo(Menu hMenu, MenuAction action, int iClient, int iSelect)
{
	if (action != MenuAction_Select) return;
	
	//Only back button in menu
	MenuBoss_DisplayModifiersMain(iClient);
}

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
		PrintToChatAll("%s%s %N cleared all next boss", VSH_TAG, VSH_TEXT_COLOR, iClient);
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
	hAdminNextBoss_Client.AddItem("", "---", ITEMDRAW_DISABLED);
	
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
		
		MenuBoss_DisplayNextBoss(iClient);
	}
}

void MenuBoss_DisplayNextBoss(int iClient)
{
	g_hMenuNextBoss.Display(iClient, MENU_TIME_FOREVER);
}

public int MenuBoss_SelectNextBoss(Menu hMenu, MenuAction action, int iClient, int iSelect)
{
	if (action != MenuAction_Select) return;
	
	char sSelect[MAX_TYPE_CHAR];
	hMenu.GetItem(iSelect, sSelect, sizeof(sSelect));
	
	if (StrEqual(sSelect, "back"))
	{
		MenuBoss_DisplayNextClient(iClient);
		return;
	}
	else if (StrEqual(sSelect, "random"))
	{
		Format(g_nextMenuSelectBoss[iClient].sBoss, sizeof(g_nextMenuSelectBoss[].sBoss), "");
	}
	else
	{
		Format(g_nextMenuSelectBoss[iClient].sBoss, sizeof(g_nextMenuSelectBoss[].sBoss), sSelect);
	}
	
	MenuBoss_DisplayNextModifiers(iClient);
}

void MenuBoss_DisplayNextModifiers(int iClient)
{
	g_hMenuNextModifiers.Display(iClient, MENU_TIME_FOREVER);
}

public int MenuBoss_SelectNextModifiers(Menu hMenu, MenuAction action, int iClient, int iSelect)
{
	if (action != MenuAction_Select) return;
	
	char sSelect[MAX_TYPE_CHAR];
	hMenu.GetItem(iSelect, sSelect, sizeof(sSelect));
	
	if (StrEqual(sSelect, "back"))
	{
		MenuBoss_DisplayNextBoss(iClient);
		return;
	}
	else if (StrEqual(sSelect, "random"))
	{
		Format(g_nextMenuSelectBoss[iClient].sModifiers, sizeof(g_nextMenuSelectBoss[].sModifiers), "");
	}
	else
	{
		Format(g_nextMenuSelectBoss[iClient].sModifiers, sizeof(g_nextMenuSelectBoss[].sModifiers), sSelect);
	}
	
	//Push NextBoss to ArrayList
	g_aNextBoss.PushArray(g_nextMenuSelectBoss[iClient]);
	
	//Print chat boss been set
	char sBuffer[256];
	GetNextBossName(g_nextMenuSelectBoss[iClient], sBuffer, sizeof(sBuffer));
	PrintToChatAll("%s%s %N added next boss %s", VSH_TAG, VSH_TEXT_COLOR, iClient, sBuffer);
	
	//Clear stuffs
	g_nextMenuSelectBoss[iClient].iUserId = 0;
	g_nextMenuSelectBoss[iClient].sBoss = "";
	g_nextMenuSelectBoss[iClient].sModifiers = "";
	
	MenuBoss_DisplayNextList(iClient);
}