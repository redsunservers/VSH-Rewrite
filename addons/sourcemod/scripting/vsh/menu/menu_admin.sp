static Menu g_hMenuAdminMain;
static Menu g_hMenuAdminSpecial;
static Menu g_hMenuAdminSpecialClass;
static Menu g_hMenuAdminRage;

//replaced with a dynamic menu
static int g_iAdminQueueTarget[MAXPLAYERS];

void MenuAdmin_Init()
{
	// Main Admin menu
	g_hMenuAdminMain = new Menu(MenuAdmin_SelectMain);
	g_hMenuAdminMain.SetTitle("Admin Menu");
	g_hMenuAdminMain.AddItem("config", "Refresh VSH Config (!vshrefresh)");
	g_hMenuAdminMain.AddItem("queue", "Add Queue (!vshqueue)");
	g_hMenuAdminMain.AddItem("special", "Force Special Round (!vshspecial)");
	g_hMenuAdminMain.AddItem("dome", "Force Start Dome (!vshdome)");
	g_hMenuAdminMain.AddItem("boss", "Set Next Boss & Modifiers (!vshsetboss)");
	g_hMenuAdminMain.AddItem("rage", "Set Rage (!vshrage)");
	
	// Special round menu
	g_hMenuAdminSpecial = new Menu(MenuAdmin_SelectSpecial);
	g_hMenuAdminSpecial.SetTitle("Force set special round");
	g_hMenuAdminSpecial.AddItem("random", "Random Class");
	g_hMenuAdminSpecial.AddItem("class", "Select Class");
	g_hMenuAdminSpecial.AddItem("back", "<- Back");
	
	// Special round, slecting specific class menu
	g_hMenuAdminSpecialClass = new Menu(MenuAdmin_SelectSpecialClass);
	g_hMenuAdminSpecialClass.SetTitle("Force set specific class for special round");
	for (int iClass = 1; iClass < sizeof(g_strClassName); iClass++)
	{
		TFClassType nClass = g_nClassDisplay[iClass];
		char sClass[4];
		IntToString(view_as<int>(nClass), sClass, sizeof(sClass));
		g_hMenuAdminSpecialClass.AddItem(sClass, g_strClassName[nClass]);
	}
	
	g_hMenuAdminSpecialClass.AddItem("back", "<- Back");
	g_hMenuAdminSpecialClass.Pagination = MENU_NO_PAGINATION;
	
	// Set rage menu
	g_hMenuAdminRage = new Menu(MenuAdmin_SelectRage);
	g_hMenuAdminRage.SetTitle("Set all alive boss rage");
	g_hMenuAdminRage.AddItem("0", "0%");
	g_hMenuAdminRage.AddItem("50", "50%");
	g_hMenuAdminRage.AddItem("100", "100%");
	g_hMenuAdminRage.AddItem("150", "150%");
	g_hMenuAdminRage.AddItem("200", "200%");
}

void MenuAdmin_DisplayMain(int iClient)
{
	g_hMenuAdminMain.Display(iClient, MENU_TIME_FOREVER);
}

public int MenuAdmin_SelectMain(Menu hMenu, MenuAction action, int iClient, int iSelect)
{
	if (action != MenuAction_Select) return 0;
	
	char sSelect[32];
	hMenu.GetItem(iSelect, sSelect, sizeof(sSelect));
	
	if (StrEqual(sSelect, "config"))
		ClientCommand(iClient, "vsh_refresh");
	else if (StrEqual(sSelect, "queue"))
		MenuAdmin_DisplayQueue(iClient);
	else if (StrEqual(sSelect, "special"))
		MenuAdmin_DisplaySpecial(iClient);
	else if (StrEqual(sSelect, "dome"))
		ClientCommand(iClient, "vsh_dome");
	else if (StrEqual(sSelect, "boss"))
		MenuBoss_DisplayNextList(iClient);
	else if (StrEqual(sSelect, "rage"))
		MenuAdmin_DisplayRage(iClient);
	else
		Menu_DisplayError(iClient);
	
	return 0;
}

void MenuAdmin_DisplayQueue(int iClient)
{
	//show a dynamic player list
	Menu hMenuTarget = new Menu(MenuAdmin_SelectQueueTarget);
	hMenuTarget.SetTitle("Select player to give queue points to\n---");
	hMenuTarget.AddItem("back", "<- Back");
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			char sIndex[4], sName[MAX_NAME_LENGTH];
			IntToString(i, sIndex, sizeof(sIndex));
			GetClientName(i, sName, sizeof(sName));
			
			hMenuTarget.AddItem(sIndex, sName);
		}
	}
	
	hMenuTarget.Display(iClient, MENU_TIME_FOREVER);
}

public int MenuAdmin_SelectQueueTarget(Menu hMenu, MenuAction action, int iClient, int iSelect)
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
		MenuAdmin_DisplayMain(iClient);
		return 0;
	}
	
	int iPlayer = StringToInt(sSelect);
	if (iPlayer != 0 && (iPlayer < 1 || iPlayer > MaxClients || !IsClientInGame(iPlayer)))
	{
		//Target disconnected between opening the menu and selecting
		PrintToChat(iClient, "%s%s That player is no longer available.", TEXT_TAG, TEXT_ERROR);
		MenuAdmin_DisplayQueue(iClient);
		return 0;
	}
	
	g_iAdminQueueTarget[iClient] = iPlayer;
	MenuAdmin_DisplayQueueAmount(iClient);
	return 0;
}

void MenuAdmin_DisplayQueueAmount(int iClient)
{
	//rebuild the menu
	Menu hMenuAmount = new Menu(MenuAdmin_SelectQueue);
	
	int iTarget = g_iAdminQueueTarget[iClient];
	char sTitle[128];
	if (iTarget > 0)
	{
		char sName[MAX_NAME_LENGTH];
		GetClientName(iTarget, sName, sizeof(sName));
		Format(sTitle, sizeof(sTitle), "Add queue points to %s", sName);
	}
	else
	{
		Format(sTitle, sizeof(sTitle), "Add queue points (no player selected)");
	}
	
	hMenuAmount.SetTitle(sTitle);
	hMenuAmount.AddItem("1", "1");
	hMenuAmount.AddItem("5", "5");
	hMenuAmount.AddItem("10", "10");
	hMenuAmount.AddItem("50", "50");
	hMenuAmount.AddItem("100", "100");
	hMenuAmount.AddItem("500", "500");
	hMenuAmount.AddItem("back", "<- Back");
	
	hMenuAmount.Display(iClient, MENU_TIME_FOREVER);
}

public int MenuAdmin_SelectQueue(Menu hMenu, MenuAction action, int iClient, int iSelect)
{
	if (action == MenuAction_End)
	{
		delete hMenu;
		return 0;
	}
	
	if (action != MenuAction_Select) return 0;
	
	char sSelect[32];
	hMenu.GetItem(iSelect, sSelect, sizeof(sSelect));
	
	int iValue;
	if (StringToIntEx(sSelect, iValue) != 0)
	{
		int iTarget = g_iAdminQueueTarget[iClient];
		if (iTarget <= 0 || !IsClientInGame(iTarget))
		{
			PrintToChat(iClient, "%s%s No player selected. Pick a player first.", TEXT_TAG, TEXT_ERROR);
			MenuAdmin_DisplayQueue(iClient);
			return 0;
		}
		
		//grab the target by #userid so it stays valid even if the client index shifts
		int iUserId = GetClientUserId(iTarget);
		ClientCommand(iClient, "vsh_queue #%d %d", iUserId, iValue);
	}
	else if (StrEqual(sSelect, "back"))
	{
		MenuAdmin_DisplayQueue(iClient);
	}
	else
	{
		Menu_DisplayError(iClient);
	}
	
	return 0;
}

void MenuAdmin_DisplaySpecial(int iClient)
{
	g_hMenuAdminSpecial.Display(iClient, MENU_TIME_FOREVER);
}

public int MenuAdmin_SelectSpecial(Menu hMenu, MenuAction action, int iClient, int iSelect)
{
	if (action != MenuAction_Select) return 0;
	
	char sSelect[32];
	hMenu.GetItem(iSelect, sSelect, sizeof(sSelect));
	
	if (StrEqual(sSelect, "random"))
		ClientCommand(iClient, "vsh_special");
	else if (StrEqual(sSelect, "class"))
		MenuAdmin_DisplaySpecialClass(iClient);
	else if (StrEqual(sSelect, "back"))
		MenuAdmin_DisplayMain(iClient);
	else
		Menu_DisplayError(iClient);
	
	return 0;
}

void MenuAdmin_DisplaySpecialClass(int iClient)
{
	g_hMenuAdminSpecialClass.Display(iClient, MENU_TIME_FOREVER);
}

public int MenuAdmin_SelectSpecialClass(Menu hMenu, MenuAction action, int iClient, int iSelect)
{
	if (action != MenuAction_Select) return 0;
	
	char sSelect[32];
	hMenu.GetItem(iSelect, sSelect, sizeof(sSelect));
	
	if (StrEqual(sSelect, "back"))
	{
		MenuAdmin_DisplaySpecial(iClient);
		return 0;
	}
	
	TFClassType nClass = view_as<TFClassType>(StringToInt(sSelect));
	if (nClass == TFClass_Unknown)
	{
		Menu_DisplayError(iClient);
		return 0;
	}
	
	ClientCommand(iClient, "vsh_special %s", g_strClassName[nClass]);
	return 0;
}

void MenuAdmin_DisplayRage(int iClient)
{
	g_hMenuAdminRage.Display(iClient, MENU_TIME_FOREVER);
}

public int MenuAdmin_SelectRage(Menu hMenu, MenuAction action, int iClient, int iSelect)
{
	if (action != MenuAction_Select) return 0;
	
	char sSelect[32];
	hMenu.GetItem(iSelect, sSelect, sizeof(sSelect));
	
	int iValue;
	if (StringToIntEx(sSelect, iValue) != 0)
		ClientCommand(iClient, "vsh_rage %d", iValue);
	else if (StrEqual(sSelect, "back"))
		MenuAdmin_DisplayMain(iClient);
	else
		Menu_DisplayError(iClient);
	
	return 0;
}