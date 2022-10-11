static Cookie g_hCookiesPreferences;
static Cookie g_hCookiesQueue;

void Cookies_Init()
{
	g_ConfigConvar.Create("vsh_cookies_preferences", "1", "Should preferences use cookies to store? (Disable if you want to store preferences somewhere else)", _, true, 0.0, true, 1.0);
	g_ConfigConvar.Create("vsh_cookies_queue", "1", "Should queue use cookies to store? (Disable if you want to store queue somewhere else)", _, true, 0.0, true, 1.0);
	
	g_hCookiesPreferences = new Cookie("vsh_preferences", "VSH Player preferences", CookieAccess_Protected);
	g_hCookiesQueue = new Cookie("vsh_queue", "Amount of VSH Queue points player has", CookieAccess_Protected);
}

void Cookies_Refresh()
{
	bool bPreferences = g_ConfigConvar.LookupBool("vsh_cookies_preferences");
	bool bQueue = g_ConfigConvar.LookupBool("vsh_cookies_queue");
	
	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if (!IsClientInGame(iClient) || IsFakeClient(iClient))
			continue;
		
		if (bPreferences) Cookies_RefreshPreferences(iClient);
		if (bQueue) Cookies_RefreshQueue(iClient);
	}
}

void Cookies_OnClientJoin(int iClient)
{
	if (IsFakeClient(iClient))
	{
		//Bots dont use cookies
		Preferences_SetAll(iClient, 0);
		Queue_SetPlayerPoints(iClient, 0);
		return;
	}
	
	if (g_ConfigConvar.LookupBool("vsh_cookies_preferences"))
		Cookies_RefreshPreferences(iClient);
	
	if (g_ConfigConvar.LookupBool("vsh_cookies_queue"))
		Cookies_RefreshQueue(iClient);
}

void Cookies_RefreshPreferences(int iClient)
{
	int iVal;
	char sVal[16];
	g_hCookiesPreferences.Get(iClient, sVal, sizeof(sVal));
	
	if (StringToIntEx(sVal, iVal) > 0)
		Preferences_SetAll(iClient, iVal);
	else
		Preferences_SetAll(iClient, 0);
}

void Cookies_RefreshQueue(int iClient)
{
	int iVal;
	char sVal[16];
	g_hCookiesQueue.Get(iClient, sVal, sizeof(sVal));
	
	if (StringToIntEx(sVal, iVal) > 0)
		Queue_SetPlayerPoints(iClient, iVal);
	else
		Queue_SetPlayerPoints(iClient, 0);
}

void Cookies_SavePreferences(int iClient, int iValue)
{
	if (iClient <= 0 || iClient > MaxClients || !IsClientInGame(iClient) || IsFakeClient(iClient))
		return;
	
	if (g_ConfigConvar.LookupBool("vsh_cookies_preferences"))
	{
		char sVal[16];
		IntToString(iValue, sVal, sizeof(sVal));
		g_hCookiesPreferences.Set(iClient, sVal);
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
		g_hCookiesQueue.Set(iClient, sVal);
	}
	
	Forward_UpdateQueue(iClient, iValue);
}