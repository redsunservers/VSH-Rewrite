#define MENU_MAX_SLOT 3 //Only Display Primary, Secondary and Melee

static Menu g_hMenuWeaponMain;
static Menu g_hMenuWeaponClass[sizeof(g_strClassName)];
static Menu g_hMenuWeaponSlot[sizeof(g_strClassName)][MENU_MAX_SLOT];

void MenuWeapon_Refresh()
{
	char buffer[1024];
	
	delete g_hMenuWeaponMain;
	for (int iClass = 1; iClass < sizeof(g_strClassName); iClass++)
	{
		delete g_hMenuWeaponClass[iClass];
		
		for (int iSlot = 0; iSlot < MENU_MAX_SLOT; iSlot++)
			delete g_hMenuWeaponSlot[iClass][iSlot];
	}
	
	// Create menus loaded from config
	
	char sClassDesp[sizeof(g_strClassName)][MENU_MAX_SLOT][1024];
	
	//Get list of every weapons in config to add desp
	int iLength = g_ConfigIndex.Length;
	for (int i = 0; i < iLength; i++)
	{
		char sDesp[256];
		int iIndex = g_ConfigIndex.Get(i, 0);
		
		//Don't use prefab weapons
		if (g_ConfigIndex.IsPrefab(iIndex))
			continue;
		
		if (g_ConfigIndex.GetDesp(iIndex, sDesp, sizeof(sDesp)))
		{
			//Loop through all classes to get slot to add desp if found
			for (int iClass = 1; iClass < sizeof(g_strClassName); iClass++)
			{
				int iSlot = TF2_GetItemSlot(iIndex, view_as<TFClassType>(iClass));
				
				if (iSlot >= MENU_MAX_SLOT) iSlot = WeaponSlot_Secondary;
				if (iSlot >= 0) Format(sClassDesp[iClass][iSlot], sizeof(sClassDesp[][]), "%s \n%s", sClassDesp[iClass][iSlot], sDesp);
			}
		}
	}
	
	// Weapon Menu
	g_hMenuWeaponMain = new Menu(MenuWeapon_SelectMain);
	g_hMenuWeaponMain.SetTitle("Class Menu");
	
	//Loop through each class
	for (int iClass = 1; iClass < sizeof(g_strClassName); iClass++)
	{
		//Display in order of g_nClassDisplay
		TFClassType nClass = g_nClassDisplay[iClass];
		char sClass[4];
		IntToString(view_as<int>(nClass), sClass, sizeof(sClass));
		
		//Add class name button to WeaponMain
		g_hMenuWeaponMain.AddItem(sClass, g_strClassName[nClass]);
	}
	
	//Create each class menu
	for (int iClass = 1; iClass < sizeof(g_strClassName); iClass++)
	{
		//Title for Weapon Class
		g_hMenuWeaponClass[iClass] = new Menu(MenuWeapon_SelectClass);
		g_hMenuWeaponClass[iClass].SetTitle(g_strClassName[iClass]);
		
		//Loop through each slots, Primary Secondary and Melee
		for (int iSlot = 0; iSlot < MENU_MAX_SLOT; iSlot++)
		{
			//Add slot name button to WeaponClass
			char sSlot[4];
			IntToString(iSlot, sSlot, sizeof(sSlot));
			g_hMenuWeaponClass[iClass].AddItem(sSlot, g_strSlotName[iSlot]);
			
			//Title for Weapon Slot
			g_hMenuWeaponSlot[iClass][iSlot] = new Menu(MenuWeapon_SelectSlot);
			Format(buffer, sizeof(buffer), "%s - %s", g_strClassName[iClass], g_strSlotName[iSlot]);
			
			//Get Desp for specific class and slot to add
			char sDesp[256];
			if (g_ConfigClass[iClass][iSlot].GetDesp(sDesp, sizeof(sDesp)))
				Format(buffer, sizeof(buffer), "%s \n%s", buffer, sDesp);
			
			if (!StrEmpty(sDesp) || !StrEmpty(sClassDesp[iClass][iSlot]))
			{
				//Add all indexs from class slot
				if (!StrEmpty(sClassDesp[iClass][iSlot]))
					Format(buffer, sizeof(buffer), "%s \n%s", buffer, sClassDesp[iClass][iSlot]);
				
				//Remove all color tags
				for (int iColorTag = 0; iColorTag < sizeof(g_strColorTag); iColorTag++)
					ReplaceString(buffer, sizeof(buffer), g_strColorTag[iColorTag], "");
				
				//Bug with single % not showing, use %% to have % appeared once
				ReplaceString(buffer, sizeof(buffer), "%", "%%");
			}
			else
			{
				//If there nothing in both class slot and index...
				Format(buffer, sizeof(buffer), "%s\n\nThere seems to be nothing here...", buffer);
			}
			
			//Set everything above as title
			g_hMenuWeaponSlot[iClass][iSlot].SetTitle(buffer);

			//Add exit button to WeaponSlot
			g_hMenuWeaponSlot[iClass][iSlot].AddItem("back", "<- Back");
		}
		
		//Add exit button to WeaponClass
		g_hMenuWeaponClass[iClass].AddItem("back", "<- Back");
	}
	
	//Add exit button to WeaponMain
	g_hMenuWeaponMain.AddItem("back", "<- Back");
	g_hMenuWeaponMain.Pagination = MENU_NO_PAGINATION;
}

void MenuWeapon_DisplayMain(int iClient)
{
	g_hMenuWeaponMain.Display(iClient, MENU_TIME_FOREVER);
}

public int MenuWeapon_SelectMain(Menu hMenu, MenuAction action, int iClient, int iSelect)
{
	if (action != MenuAction_Select) return 0;
	
	char sSelect[32];
	hMenu.GetItem(iSelect, sSelect, sizeof(sSelect));
	
	if (StrEqual(sSelect, "back"))
	{
		Menu_DisplayMain(iClient);
		return 0;
	}
	
	TFClassType nClass = view_as<TFClassType>(StringToInt(sSelect));
	MenuWeapon_DisplayClass(iClient, nClass);
	return 0;
}

void MenuWeapon_DisplayClass(int iClient, TFClassType nClass)
{
	//If unknown class passed, display main list instead
	if (nClass == TFClass_Unknown)
	{
		MenuWeapon_DisplayMain(iClient);
		return;
	}
	
	g_hMenuWeaponClass[nClass].Display(iClient, MENU_TIME_FOREVER);
}

public int MenuWeapon_SelectClass(Menu hMenu, MenuAction action, int iClient, int iSelect)
{
	if (action != MenuAction_Select) return 0;
	
	char sSelect[32];
	hMenu.GetItem(iSelect, sSelect, sizeof(sSelect));
	if (StrEqual(sSelect, "back"))
	{
		MenuWeapon_DisplayMain(iClient);
		return 0;
	}
	
	//Find class by matching menu
	for (int iClass = 1; iClass < sizeof(g_strClassName); iClass++)
	{
		if (g_hMenuWeaponClass[iClass] == hMenu)
		{
			int iSlot = StringToInt(sSelect);
			MenuWeapon_DisplaySlot(iClient, view_as<TFClassType>(iClass), iSlot);
			return 0;
		}
	}
	
	Menu_DisplayError(iClient);
	return 0;
}

void MenuWeapon_DisplaySlot(int iClient, TFClassType nClass, int iSlot)
{
	//If unknown class passed, display main list instead
	if (nClass == TFClass_Unknown)
	{
		MenuWeapon_DisplayMain(iClient);
		return;
	}
	
	g_hMenuWeaponSlot[nClass][iSlot].Display(iClient, MENU_TIME_FOREVER);
}

public int MenuWeapon_SelectSlot(Menu hMenu, MenuAction action, int iClient, int iSelect)
{
	if (action != MenuAction_Select) return 0;
	
	//Since slot display only have back button, we only need to find which class to go back
	for (int iClass = 1; iClass < sizeof(g_strClassName); iClass++)
	{
		for (int iSlot = 0; iSlot < MENU_MAX_SLOT; iSlot++)
		{
			if (hMenu == g_hMenuWeaponSlot[iClass][iSlot])
			{
				g_hMenuWeaponClass[iClass].Display(iClient, MENU_TIME_FOREVER);
				return 0;
			}
		}
	}
	
	Menu_DisplayError(iClient);
	return 0;
}
