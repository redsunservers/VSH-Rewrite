void MenuAltWeapon_DisplayList(int iClient)
{
	Menu hMenu = new Menu(MenuAltWeapon_SelectList);
	hMenu.SetTitle("Alternate Weapon Behaviour");
	hMenu.AddItem("back", "<- Back");
	
	int iLength = g_ConfigIndex.Length;
	for (int i = 0; i < iLength; i++)
	{
		int iIndex = g_ConfigIndex.Get(i, 0);
		if (iIndex < CONFIG_ALT_INDEX_OFFSET)
			continue;
		
		iIndex -= CONFIG_ALT_INDEX_OFFSET;
		
		char sName[128];
		if (!AltWeapon_GetString(iIndex, "name", sName, sizeof(sName)) || StrEmpty(sName))
			continue;
		
		char sInfo[16];
		IntToString(iIndex, sInfo, sizeof(sInfo));
		hMenu.AddItem(sInfo, sName);
	}
	
	hMenu.Display(iClient, MENU_TIME_FOREVER);
}

public int MenuAltWeapon_SelectList(Menu hMenu, MenuAction action, int iClient, int iSelect)
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
		Menu_DisplayMain(iClient);
	else
		MenuAltWeapon_DisplayWeapon(iClient, StringToInt(sSelect));
	
	return 0;
}

void MenuAltWeapon_DisplayWeapon(int iClient, int iIndex)
{
	char sName[128];
	if (!AltWeapon_GetString(iIndex, "name", sName, sizeof(sName)))
	{
		MenuAltWeapon_DisplayList(iClient);
		return;
	}
	
	Menu hMenu = new Menu(MenuAltWeapon_SelectWeapon);
	hMenu.SetTitle("%s", sName);
	hMenu.AddItem("back", "<- Back");
	
	char sInfo[16], sDisplay[128];
	Format(sInfo, sizeof(sInfo), "t%d", iIndex);
	Format(sDisplay, sizeof(sDisplay), "Toggle Alternate Weapon Behaviour | %s", AltWeapon_IsEnabled(iClient, iIndex) ? "[ON]" : "[OFF]");
	hMenu.AddItem(sInfo, sDisplay);
	
	Format(sInfo, sizeof(sInfo), "s%d", iIndex);
	hMenu.AddItem(sInfo, "Show Alternate Weapon Behaviour");
	
	hMenu.Display(iClient, MENU_TIME_FOREVER);
}

public int MenuAltWeapon_SelectWeapon(Menu hMenu, MenuAction action, int iClient, int iSelect)
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
		MenuAltWeapon_DisplayList(iClient);
		return 0;
	}
	
	int iIndex = StringToInt(sSelect[1]);
	if (sSelect[0] == 't')
		AltWeapon_Toggle(iClient, iIndex);
	else if (sSelect[0] == 's')
		AltWeapon_PrintDesp(iClient, iIndex);
	
	MenuAltWeapon_DisplayWeapon(iClient, iIndex);
	return 0;
}
