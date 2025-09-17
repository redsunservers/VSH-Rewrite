#pragma semicolon 1
#pragma newdecls required

static ArrayList g_aBlacklistedBosses[MAXPLAYERS];
static Cookie g_hCookiesBlacklist;

enum BlacklistResult
{
	BLACKLIST_ADDED,
	BLACKLIST_REMOVED,
	BLACKLIST_FAILED_TO_CHANGE
}

void Blacklist_Init()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		g_aBlacklistedBosses[i] = new ArrayList(32);
	}
	
	g_hCookiesBlacklist = new Cookie("vsh_blacklist", "Which bosses this player has blacklisted", CookieAccess_Protected);
}

BlacklistResult Blacklist_Toggle(int iClient, const char[] sBoss)
{
	BlacklistResult result;
	int iIndex = g_aBlacklistedBosses[iClient].FindString(sBoss);
	if (iIndex == -1)
	{
		int iMax = g_ConfigConvar.LookupInt("vsh_blacklist_amount");
		if (Blacklist_GetAmount(iClient) >= iMax)
			return BLACKLIST_FAILED_TO_CHANGE;
		
		g_aBlacklistedBosses[iClient].PushString(sBoss);
		result = BLACKLIST_ADDED;
	}
	else
	{
		g_aBlacklistedBosses[iClient].Erase(iIndex);
		result = BLACKLIST_REMOVED;
	}
	
	Blacklist_Save(iClient);
	return result;
}

void Blacklist_Load(int iClient)
{
	g_aBlacklistedBosses[iClient].Clear();
	
	int iMax = g_ConfigConvar.LookupInt("vsh_blacklist_amount");
	if (iMax <= 0)
		return;
	
	if (IsFakeClient(iClient))
		return;
	
	// Get list of all bosses
	ArrayList aBosses = SaxtonHale_GetAllClassType(VSHClassType_Boss);
	
	// Cookies can only be 99 chars long
	char sValue[100];
	g_hCookiesBlacklist.Get(iClient, sValue, sizeof(sValue));
	
	char sExplode[100][16];
	int iCookieAmount = ExplodeString(sValue, ";", sExplode, sizeof(sExplode[]), sizeof(sExplode));
	int iPluginAmount;
	
	for (int i = 0; i < iMax; i++)
	{
		if (sExplode[i][0] == '\0')
		{
			if (i == 0)
				iCookieAmount = 0;
			
			break;
		}
		
		// This boss doesn't exist. Maybe it was recently removed?
		if (aBosses.FindString(sExplode[i]) == -1)
			continue;
		
		// This boss is hidden. Maybe it was set this way recently?
		if (SaxtonHale_CallFunction(sExplode[i], "IsBossHidden"))
			continue;
		
		g_aBlacklistedBosses[iClient].PushString(sExplode[i]);
		iPluginAmount++;
	}
	
	// Something changed since last time? Save the new data
	if (iCookieAmount != iPluginAmount)
		Blacklist_Save(iClient);
	
	delete aBosses;
}

void Blacklist_Save(int iClient)
{
	// Cookies can only be 99 chars long
	char sValue[100];
	for (int i = 0; i < Blacklist_GetAmount(iClient); i++)
	{
		if (i > 0)
			StrCat(sValue, sizeof(sValue), ";");
		
		char sBuffer[100];
		g_aBlacklistedBosses[iClient].GetString(i, sBuffer, sizeof(sBuffer));
		StrCat(sValue, sizeof(sValue), sBuffer);
	}
	
	g_hCookiesBlacklist.Set(iClient, sValue);
}

ArrayList Blacklist_Get(int iClient)
{
	// If we somehow have more blacklisted bosses than allowed (ie convar recently changed), only use as many as we can
	int iLength = g_aBlacklistedBosses[iClient].Length;
	int iMax = g_ConfigConvar.LookupInt("vsh_blacklist_amount");
	
	for (int i = iLength - 1; i >= iMax; i--)
		g_aBlacklistedBosses[iClient].Erase(i);
	
	return g_aBlacklistedBosses[iClient].Clone();
}

int Blacklist_GetAmount(int iClient)
{
	return g_aBlacklistedBosses[iClient].Length;
}

bool Blacklist_IsBossBlacklisted(int iClient, const char[] sBoss)
{
	return g_aBlacklistedBosses[iClient].FindString(sBoss) != -1;
}

void Blacklist_Clear(int iClient)
{
	g_aBlacklistedBosses[iClient].Clear();
	Blacklist_Save(iClient);
}