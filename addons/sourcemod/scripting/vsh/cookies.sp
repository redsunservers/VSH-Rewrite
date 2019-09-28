static Handle g_hCookiesPreferences;
static Handle g_hCookiesQueue;
static Handle g_hCookiesWinstreak;

void Cookies_Init()
{
	g_ConfigConvar.Create("vsh_cookies_preferences", "1", "Should preferences use cookies to store? (Disable if you want to store preferences somewhere else)", _, true, 0.0, true, 1.0);
	g_ConfigConvar.Create("vsh_cookies_queue", "1", "Should queue use cookies to store? (Disable if you want to store queue somewhere else)", _, true, 0.0, true, 1.0);
	g_ConfigConvar.Create("vsh_cookies_winstreak", "1", "Should winstreak use cookies to store? (Disable if you want to store winstreak somewhere else)", _, true, 0.0, true, 1.0);
	
	g_hCookiesPreferences = RegClientCookie("vsh_preferences", "VSH Player preferences", CookieAccess_Protected);
	g_hCookiesQueue = RegClientCookie("vsh_queue", "Amount of VSH Queue points player has", CookieAccess_Protected);
	g_hCookiesWinstreak = RegClientCookie("vsh_winstreak", "Amount of VSH Winstreaks player has", CookieAccess_Protected);
}

void Cookies_Refresh()
{
	bool bPreferences = g_ConfigConvar.LookupBool("vsh_cookies_preferences");
	bool bQueue = g_ConfigConvar.LookupBool("vsh_cookies_queue");
	bool bWinstreak = g_ConfigConvar.LookupBool("vsh_cookies_winstreak");
	
	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if (!IsClientInGame(iClient) || IsFakeClient(iClient)) continue;
		
		if (bPreferences) Cookies_RefreshPreferences(iClient);
		if (bQueue) Cookies_RefreshQueue(iClient);
		if (bWinstreak) Cookies_RefreshWinstreak(iClient);
	}
}

void Cookies_OnClientJoin(int iClient)
{
	if (IsFakeClient(iClient))
	{
		//Bots dont use cookies
		Preferences_SetAll(iClient, 0);
		Queue_SetPlayerPoints(iClient, 0);
		Winstreak_SetCurrent(iClient, 0);
		return;
	}
	
	if (g_ConfigConvar.LookupBool("vsh_cookies_preferences"))
		Cookies_RefreshPreferences(iClient);
	
	if (g_ConfigConvar.LookupBool("vsh_cookies_queue"))
		Cookies_RefreshQueue(iClient);
	
	if (g_ConfigConvar.LookupBool("vsh_cookies_winstreak"))
		Cookies_RefreshWinstreak(iClient);
}

void Cookies_RefreshPreferences(int iClient)
{
	int iVal;
	char sVal[16];
	GetClientCookie(iClient, g_hCookiesPreferences, sVal, sizeof(sVal));
	
	if (StringToIntEx(sVal, iVal) > 0)
		Preferences_SetAll(iClient, iVal);
	else
		Preferences_SetAll(iClient, 0);
}

void Cookies_RefreshQueue(int iClient)
{
	int iVal;
	char sVal[16];
	GetClientCookie(iClient, g_hCookiesQueue, sVal, sizeof(sVal));
	
	if (StringToIntEx(sVal, iVal) > 0)
		Queue_SetPlayerPoints(iClient, iVal);
	else
		Queue_SetPlayerPoints(iClient, 0);
}

void Cookies_RefreshWinstreak(int iClient)
{
	int iVal;
	char sVal[16];
	GetClientCookie(iClient, g_hCookiesWinstreak, sVal, sizeof(sVal));
	
	if (StringToIntEx(sVal, iVal) > 0)
		Winstreak_SetCurrent(iClient, iVal);
	else
		Winstreak_SetCurrent(iClient, 0);
}

void Cookies_SavePreferences(int iClient, int iValue)
{
	if (iClient <= 0 || iClient > MaxClients || !IsClientInGame(iClient) || IsFakeClient(iClient))
		return;
	
	if (g_ConfigConvar.LookupBool("vsh_cookies_preferences"))
	{
		char sVal[16];
		IntToString(iValue, sVal, sizeof(sVal));
		SetClientCookie(iClient, g_hCookiesPreferences, sVal);
	}
	
	Forward_UpdatePreferences(iClient, iValue);
}

void Cookies_SaveQueue(int iClient, int iValue)
{
	if (iClient <= 0 || iClient > MaxClients || !IsClientInGame(iClient) || IsFakeClient(iClient))
		return;
	
	if (g_ConfigConvar.LookupBool("vsh_cookies_queue"))
	{
		char sVal[16];
		IntToString(iValue, sVal, sizeof(sVal));
		SetClientCookie(iClient, g_hCookiesQueue, sVal);
	}
	
	Forward_UpdateQueue(iClient, iValue);
}

void Cookies_SaveWinstreak(int iClient, int iValue)
{
	if (iClient <= 0 || iClient > MaxClients || !IsClientInGame(iClient) || IsFakeClient(iClient))
		return;
	
	if (g_ConfigConvar.LookupBool("vsh_cookies_winstreak"))
	{
		char sVal[16];
		IntToString(iValue, sVal, sizeof(sVal));
		SetClientCookie(iClient, g_hCookiesWinstreak, sVal);
	}
	
	Forward_UpdateWinstreak(iClient, iValue);
}