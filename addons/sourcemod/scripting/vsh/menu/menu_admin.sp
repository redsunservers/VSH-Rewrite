static Menu g_hMenuAdminMain;
static Menu g_hMenuAdminQueue;
static Menu g_hMenuAdminSpecial;
static Menu g_hMenuAdminSpecialClass;
static Menu g_hMenuAdminRage;

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
	
	// Queue menu
	g_hMenuAdminQueue = new Menu(MenuAdmin_SelectQueue);
	g_hMenuAdminQueue.SetTitle("Add queue points to self");
	g_hMenuAdminQueue.AddItem("1", "1");
	g_hMenuAdminQueue.AddItem("5", "5");
	g_hMenuAdminQueue.AddItem("10", "10");
	g_hMenuAdminQueue.AddItem("50", "50");
	g_hMenuAdminQueue.AddItem("100", "100");
	g_hMenuAdminQueue.AddItem("500", "500");
	g_hMenuAdminQueue.AddItem("back", "<- Back");
	
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
	g_hMenuAdminQueue.Display(iClient, MENU_TIME_FOREVER);
}

public int MenuAdmin_SelectQueue(Menu hMenu, MenuAction action, int iClient, int iSelect)
{
	if (action != MenuAction_Select) return 0;
	
	char sSelect[32];
	hMenu.GetItem(iSelect, sSelect, sizeof(sSelect));
	
	int iValue;
	if (StringToIntEx(sSelect, iValue) != 0)
		ClientCommand(iClient, "vsh_queue @me %d", iValue);
	else if (StrEqual(sSelect, "back"))
		MenuAdmin_DisplayMain(iClient);
	else
		Menu_DisplayError(iClient);
	
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