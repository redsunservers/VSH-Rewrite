#pragma semicolon 1
#pragma newdecls required

void MenuBlacklist_DisplayMain(int iClient)
{
	int iMax = g_ConfigConvar.LookupInt("vsh_blacklist_amount");
	if (iMax <= 0)
	{
		PrintToChat(iClient, "%s%s The blacklist is currently disabled.", TEXT_TAG, TEXT_COLOR);
		return;
	}
	
	Menu hMenu = new Menu(MenuBlacklist_SelectMain);
	ArrayList aBlacklist = Blacklist_Get(iClient);
	
	char sTitle[512];
	FormatEx(sTitle, sizeof(sTitle), "Blacklist Menu\n \nYou can blacklist up to %d bosses to avoid being selected as them.\n ", iMax);
	
	int iLength = aBlacklist.Length;
	if (iLength)
	{
		StrCat(sTitle, sizeof(sTitle), "\nCurrent blacklist:");
		for (int i = 0; i < iLength; i++)
		{
			char sType[64], sName[64];
			aBlacklist.GetString(i, sType, sizeof(sType));
			SaxtonHale_CallFunction(sType, "GetBossName", sName, sizeof(sName));
			
			Format(sTitle, sizeof(sTitle), "%s\n- %s", sTitle, sName);
		}
		
		StrCat(sTitle, sizeof(sTitle), "\n ");
	}
	
	hMenu.SetTitle(sTitle);
	hMenu.AddItem("back", "<- Back");
	hMenu.AddItem("list", "Select which bosses to blacklist");
	hMenu.AddItem("clear", "Clear blacklist");
	hMenu.Display(iClient, MENU_TIME_FOREVER);
}

public int MenuBlacklist_SelectMain(Menu hMenu, MenuAction action, int iClient, int iSelect)
{
	if (action != MenuAction_Select) return 0;
	
	char sSelect[32];
	hMenu.GetItem(iSelect, sSelect, sizeof(sSelect));
	
	if (StrEqual(sSelect, "back"))
	{
		Menu_DisplayMain(iClient);
	}
	else if (StrEqual(sSelect, "list"))
	{
		// Just offload this shit to the vshboss menu man
		PrintToChat(iClient, "%s%s You can blacklist bosses in their respective pages.", TEXT_TAG, TEXT_COLOR);
		MenuBoss_DisplayList(iClient, VSHClassType_Boss, MenuBoss_CallbackInfo);
	}
	else if (StrEqual(sSelect, "clear"))
	{
		MenuBlacklist_DisplayClear(iClient);
	}
	
	return 0;
}

void MenuBlacklist_DisplayClear(int iClient)
{
	Menu hMenu = new Menu(MenuBlacklist_SelectClear);
	
	hMenu.SetTitle("Blacklist Menu\n \nAre you sure you want to clear your blacklist?\n ");
	hMenu.AddItem("yes", "Yes");
	hMenu.AddItem("no", "No");
	
	hMenu.Display(iClient, MENU_TIME_FOREVER);
}

public int MenuBlacklist_SelectClear(Menu hMenu, MenuAction action, int iClient, int iSelect)
{
	if (action != MenuAction_Select) return 0;
	
	char sSelect[32];
	hMenu.GetItem(iSelect, sSelect, sizeof(sSelect));
	
	if (StrEqual(sSelect, "yes"))
	{
		Blacklist_Clear(iClient);
		PrintToChat(iClient, "%s%s Your blacklist has been cleared.", TEXT_TAG, TEXT_COLOR);
	}
	
	MenuBlacklist_DisplayMain(iClient);
	return 0;
}