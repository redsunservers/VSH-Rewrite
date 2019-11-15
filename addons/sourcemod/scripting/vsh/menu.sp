static Menu g_hMenuError;
static Menu g_hMenuMain;
static Menu g_hMenuCredits;

void Menu_Init()
{
	char buffer[512];
	
	// Create menus.
	// TODO add translations support.
	
	// Error Menu
	g_hMenuError = new Menu(Menu_SelectError);
	g_hMenuError.SetTitle("You found an error menu your not suppose to be here, oops!\nYou probably want to tell an admin about this...");
	g_hMenuError.AddItem("back", "<- Main Menu");
	
	// Main Menu
	g_hMenuMain = new Menu(Menu_SelectMain);
	g_hMenuMain.SetTitle("[VSH REWRITE] - %s.%s", PLUGIN_VERSION, PLUGIN_VERSION_REVISION);
	g_hMenuMain.AddItem("class", "Class & Weapon Menu (!vshclass)");
	g_hMenuMain.AddItem("boss", "Bosses Info (!vshboss)");
	g_hMenuMain.AddItem("modifiers", "Modifiers Info (!vshmodifiers)");
	g_hMenuMain.AddItem("queue", "Queue List (!vshnext)");
	g_hMenuMain.AddItem("preference", "Settings (!vshsettings)");
	g_hMenuMain.AddItem("credit", "Credits (!vshcredits)");
	
	// Credits
	g_hMenuCredits = new Menu(Menu_SelectCredits);
	Format(buffer, sizeof(buffer), "Credits");
	Format(buffer, sizeof(buffer), "%s \n", buffer);
	Format(buffer, sizeof(buffer), "%s \nCoder: 42", buffer);
	Format(buffer, sizeof(buffer), "%s \nOriginal Coder: Kenzzer", buffer);
	Format(buffer, sizeof(buffer), "%s \n", buffer);
	Format(buffer, sizeof(buffer), "%s \nEggman - The creator of the first VSH", buffer);
	Format(buffer, sizeof(buffer), "%s \nKirillian - Several boss model addition", buffer);
	Format(buffer, sizeof(buffer), "%s \nSediSocks - Announcer model", buffer);
	Format(buffer, sizeof(buffer), "%s \nAlex Turtle & Chillax - Original Rewrite test subjects", buffer);
	Format(buffer, sizeof(buffer), "%s \nwo - Test subject", buffer);
	Format(buffer, sizeof(buffer), "%s \nRedSun - Host community!", buffer);
	g_hMenuCredits.SetTitle(buffer);
	g_hMenuCredits.AddItem("back", "<- Back");
	
	MenuAdmin_Init();
	MenuBoss_Init();
}

void Menu_DisplayError(int iClient)
{
	g_hMenuError.Display(iClient, MENU_TIME_FOREVER);
	ThrowError("[VSH] Entered error menu!");
}

public int Menu_SelectError(Menu hMenu, MenuAction action, int iClient, int iSelect)
{
	if (action != MenuAction_Select) return;
	
	Menu_DisplayMain(iClient);
}

void Menu_DisplayMain(int iClient)
{
	g_hMenuMain.Display(iClient, MENU_TIME_FOREVER);
}

public int Menu_SelectMain(Menu hMenu, MenuAction action, int iClient, int iSelect)
{
	if (action != MenuAction_Select) return;
	
	char sSelect[32];
	hMenu.GetItem(iSelect, sSelect, sizeof(sSelect));
	
	if (StrEqual(sSelect, "class"))
		MenuWeapon_DisplayMain(iClient);
	else if (StrEqual(sSelect, "boss"))
		MenuBoss_DisplayBossMain(iClient);
	else if (StrEqual(sSelect, "modifiers"))
		MenuBoss_DisplayModifiersMain(iClient);
	else if (StrEqual(sSelect, "queue"))
		Menu_DisplayQueue(iClient);
	else if (StrEqual(sSelect, "preference"))
		Menu_DisplayPreferences(iClient);
	else if (StrEqual(sSelect, "credit"))
		Menu_DisplayCredits(iClient);
	else
		Menu_DisplayError(iClient);
}

void Menu_DisplayQueue(int iClient)
{
	Menu hMenuQueue = new Menu(Menu_SelectQueue);
	
	char buffer[512];
	Format(buffer, sizeof(buffer), "Queue List:");

	for (int i = 1; i <= 8; i++)
	{
		int iPlayer = Queue_GetPlayerFromRank(i);

		if (0 < iPlayer <= MaxClients)
			Format(buffer, sizeof(buffer), "%s\n%i) - %N (%i)", buffer, i, iPlayer, Queue_PlayerGetPoints(iPlayer));
		else
			Format(buffer, sizeof(buffer), "%s\n%i) - ", buffer, i);
	}
	
	int iPoints = Queue_PlayerGetPoints(iClient);
	if (iPoints >= 0)
		Format(buffer, sizeof(buffer), "%s\nYour queue points: %i", buffer, iPoints);
	else
		Format(buffer, sizeof(buffer), "%s\nYour queue points is still loading, try again later", buffer, iPoints);
	
	hMenuQueue.SetTitle(buffer);
	hMenuQueue.AddItem("back", "<- Back");
	hMenuQueue.Display(iClient, MENU_TIME_FOREVER);
}

public int Menu_SelectQueue(Menu hMenu, MenuAction action, int iClient, int iSelect)
{
	if (action == MenuAction_End)
	{
		delete hMenu;
		return;
	}
	
	if (action != MenuAction_Select) return;

	Menu_DisplayMain(iClient);
}

void Menu_DisplayPreferences(int iClient)
{
	//Create new menu, and display whenever if it enabled or not
	Menu hMenuPreferences = new Menu(Menu_SelectPreferences);
	hMenuPreferences.SetTitle("Toggle Preferences");
	
	for (int iPreferences = 0; iPreferences < sizeof(g_strPreferencesName); iPreferences++)
	{
		halePreferences preferences = view_as<halePreferences>(RoundToNearest(Pow(2.0, float(iPreferences))));
		
		char buffer[512];
		if (Preferences_Get(iClient, preferences))
			Format(buffer, sizeof(buffer), "%s (Enable)", g_strPreferencesName[iPreferences]);
		else
			Format(buffer, sizeof(buffer), "%s (Disable)", g_strPreferencesName[iPreferences]);
		
		hMenuPreferences.AddItem(g_strPreferencesName[iPreferences], buffer);
	}
	
	hMenuPreferences.AddItem("back", "<- Back");
	hMenuPreferences.Display(iClient, MENU_TIME_FOREVER);
}

public int Menu_SelectPreferences(Menu hMenu, MenuAction action, int iClient, int iSelect)
{
	if (action == MenuAction_End)
	{
		delete hMenu;
		return;
	}
	
	if (action != MenuAction_Select) return;
	
	char sSelect[32];
	hMenu.GetItem(iSelect, sSelect, sizeof(sSelect));
	
	//Find preferences thats selected
	for (int iPreferences = 0; iPreferences < sizeof(g_strPreferencesName); iPreferences++)
	{
		if (StrEqual(sSelect, g_strPreferencesName[iPreferences]))
		{
			ClientCommand(iClient, "vsh_preferences %s", g_strPreferencesName[iPreferences]);
			return;
		}
	}
	
	if (StrEqual(sSelect, "back"))
		Menu_DisplayMain(iClient);
	else
		Menu_DisplayError(iClient);
}

void Menu_DisplayCredits(int iClient)
{
	g_hMenuCredits.Display(iClient, MENU_TIME_FOREVER);
}

public int Menu_SelectCredits(Menu hMenu, MenuAction action, int iClient, int iSelect)
{
	if (action != MenuAction_Select) return;

	Menu_DisplayMain(iClient);
}