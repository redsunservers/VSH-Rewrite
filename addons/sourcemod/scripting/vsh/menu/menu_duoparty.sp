void MenuDuoParty_Display(int iClient)
{
	if (DuoParty_IsInParty(iClient))
		MenuDuoParty_DisplayParty(iClient);
	else
		MenuDuoParty_DisplayList(iClient);
}

void MenuDuoParty_DisplayList(int iClient)
{
	Menu hMenu = new Menu(MenuDuoParty_SelectList);
	hMenu.AddItem("", "select a player to invite to play with you as duo boss", ITEMDRAW_DISABLED);

	for (int i = 1; i <= MaxClients; i++)
	{
		if (i == iClient || !IsClientInGame(i) || IsFakeClient(i))
			continue;

		char sInfo[16], sName[MAX_NAME_LENGTH];
		IntToString(GetClientUserId(i), sInfo, sizeof(sInfo));
		GetClientName(i, sName, sizeof(sName));
		if (DuoParty_IsInParty(i))
			hMenu.AddItem(sInfo, sName, ITEMDRAW_DISABLED);
		else
			hMenu.AddItem(sInfo, sName);
	}

	hMenu.ExitBackButton = true;
	hMenu.Display(iClient, MENU_TIME_FOREVER);
}

public int MenuDuoParty_SelectList(Menu hMenu, MenuAction action, int iClient, int iSelect)
{
	if (action == MenuAction_End)
	{
		delete hMenu;
		return 0;
	}

	if (action == MenuAction_Cancel)
	{
		if (iSelect == MenuCancel_ExitBack)
			Menu_DisplayMain(iClient);

		return 0;
	}

	if (action != MenuAction_Select) return 0;

	char sSelect[16];
	hMenu.GetItem(iSelect, sSelect, sizeof(sSelect));

	int iTarget = GetClientOfUserId(StringToInt(sSelect));
	if (iTarget <= 0 || !IsClientInGame(iTarget))
		MenuDuoParty_Display(iClient);
	else
		MenuDuoParty_DisplayPlayer(iClient, iTarget);

	return 0;
}

void MenuDuoParty_DisplayPlayer(int iClient, int iTarget)
{
	Menu hMenu = new Menu(MenuDuoParty_SelectPlayer);
	hMenu.SetTitle("%N", iTarget);

	char sInfo[16];
	IntToString(GetClientUserId(iTarget), sInfo, sizeof(sInfo));
	hMenu.AddItem(sInfo, "Invite to be duo boss partner");

	hMenu.ExitBackButton = true;
	hMenu.Display(iClient, MENU_TIME_FOREVER);
}

public int MenuDuoParty_SelectPlayer(Menu hMenu, MenuAction action, int iClient, int iSelect)
{
	if (action == MenuAction_End)
	{
		delete hMenu;
		return 0;
	}

	if (action == MenuAction_Cancel)
	{
		if (iSelect == MenuCancel_ExitBack)
			MenuDuoParty_Display(iClient);

		return 0;
	}

	if (action != MenuAction_Select) return 0;

	char sSelect[16];
	hMenu.GetItem(iSelect, sSelect, sizeof(sSelect));
	DuoParty_Invite(iClient, GetClientOfUserId(StringToInt(sSelect)));
	return 0;
}

void MenuDuoParty_DisplayParty(int iClient)
{
	Menu hMenu = new Menu(MenuDuoParty_SelectParty);
	char sDisplay[256], sName[MAX_NAME_LENGTH];

	DuoParty_GetPartnerName(iClient, sName, sizeof(sName));
	Format(sDisplay, sizeof(sDisplay), "You are currently in a party with %s", sName);
	hMenu.AddItem("", sDisplay, ITEMDRAW_DISABLED);

	for (int iMember = 0; iMember < 2; iMember++)
	{
		int iMemberClient = DuoParty_GetMember(iClient, iMember, sName, sizeof(sName));
		if (iMemberClient > 0)
			Format(sDisplay, sizeof(sDisplay), "%s (%i)", sName, Queue_PlayerGetPoints(iMemberClient));
		else
			strcopy(sDisplay, sizeof(sDisplay), sName);

		hMenu.AddItem("", sDisplay, ITEMDRAW_DISABLED);
	}

	if (DuoParty_IsOptedIn(iClient))
		hMenu.AddItem("optin", "Opt in to only play as duo boss | [ON]");
	else
		hMenu.AddItem("optin", "Opt in to only play as duo boss | [OFF]");

	hMenu.AddItem("disband", "Disband party");

	if (DuoParty_IsOptedInPair(iClient))
		hMenu.AddItem("name", "Change name of party (!partyname)");

	hMenu.ExitBackButton = true;
	hMenu.Display(iClient, MENU_TIME_FOREVER);
}

public int MenuDuoParty_SelectParty(Menu hMenu, MenuAction action, int iClient, int iSelect)
{
	if (action == MenuAction_End)
	{
		delete hMenu;
		return 0;
	}

	if (action == MenuAction_Cancel)
	{
		if (iSelect == MenuCancel_ExitBack)
			Menu_DisplayMain(iClient);

		return 0;
	}

	if (action != MenuAction_Select) return 0;

	char sSelect[16];
	hMenu.GetItem(iSelect, sSelect, sizeof(sSelect));

	if (StrEqual(sSelect, "optin"))
	{
		DuoParty_ToggleOptIn(iClient);
		MenuDuoParty_Display(iClient);
	}
	else if (StrEqual(sSelect, "disband"))
	{
		DuoParty_Disband(iClient);
	}
	else if (StrEqual(sSelect, "name"))
	{
		DuoParty_StartNaming(iClient);
	}

	return 0;
}
