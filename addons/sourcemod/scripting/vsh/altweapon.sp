static ArrayList g_aAltWeaponEnabled[MAXPLAYERS];
static Cookie g_hCookiesAltWeapon;

void AltWeapon_Init()
{
	g_hCookiesAltWeapon = new Cookie("vsh_altweapons", "VSH alternate weapon toggles", CookieAccess_Private);
}

static ArrayList AltWeapon_GetList(int iClient)
{
	if (g_aAltWeaponEnabled[iClient] == null)
		g_aAltWeaponEnabled[iClient] = new ArrayList();
	
	return g_aAltWeaponEnabled[iClient];
}

void AltWeapon_Clear(int iClient)
{
	if (g_aAltWeaponEnabled[iClient] != null)
		g_aAltWeaponEnabled[iClient].Clear();
}

static bool AltWeapon_UseCookies(int iClient)
{
	return (!IsFakeClient(iClient) && AreClientCookiesCached(iClient) && g_ConfigConvar.LookupBool("vsh_cookies_preferences"));
}

void AltWeapon_Load(int iClient)
{
	ArrayList aList = AltWeapon_GetList(iClient);
	aList.Clear();
	
	if (!AltWeapon_UseCookies(iClient))
		return;
	
	char sValue[100];
	g_hCookiesAltWeapon.Get(iClient, sValue, sizeof(sValue));
	
	char sExplode[16][12];
	int iCount = ExplodeString(sValue, ";", sExplode, sizeof(sExplode), sizeof(sExplode[]));
	for (int i = 0; i < iCount; i++)
	{
		int iIndex;
		if (StringToIntEx(sExplode[i], iIndex) > 0 && iIndex >= 0 && aList.FindValue(iIndex) == -1)
			aList.Push(iIndex);
	}
}

static void AltWeapon_Save(int iClient)
{
	if (!AltWeapon_UseCookies(iClient))
		return;
	
	ArrayList aList = AltWeapon_GetList(iClient);
	char sValue[100], sIndex[12];
	int iLength = aList.Length;
	for (int i = 0; i < iLength; i++)
	{
		int iIndex = aList.Get(i);
		if (Config_GetStringMap(iIndex + CONFIG_ALT_INDEX_OFFSET) == null)
			continue;

		IntToString(iIndex, sIndex, sizeof(sIndex));
		if (sValue[0] != '\0')
			StrCat(sValue, sizeof(sValue), ";");

		StrCat(sValue, sizeof(sValue), sIndex);
	}
	
	g_hCookiesAltWeapon.Set(iClient, sValue);
}

bool AltWeapon_IsEnabled(int iClient, int iIndex)
{
	if (iClient <= 0 || iClient > MaxClients || g_aAltWeaponEnabled[iClient] == null)
		return false;
	
	return (g_aAltWeaponEnabled[iClient].FindValue(iIndex) != -1);
}

bool AltWeapon_Toggle(int iClient, int iIndex)
{
	ArrayList aList = AltWeapon_GetList(iClient);
	int iPos = aList.FindValue(iIndex);
	bool bEnabled = (iPos == -1);
	
	if (bEnabled)
		aList.Push(iIndex);
	else
		aList.Erase(iPos);
	
	AltWeapon_Save(iClient);
	AltWeapon_ApplyNow(iClient, iIndex);
	return bEnabled;
}

int AltWeapon_GetConfigIndex(int iClient, int iIndex)
{
	if (iIndex < 0 || iIndex >= CONFIG_ALT_INDEX_OFFSET)
		return iIndex;
	
	if (iClient <= 0 || iClient > MaxClients || g_aAltWeaponEnabled[iClient] == null || g_aAltWeaponEnabled[iClient].Length == 0)
		return iIndex;
	
	int iBase = Config_GetPrefab(iIndex);
	if (!AltWeapon_IsEnabled(iClient, iBase) || Config_GetStringMap(iBase + CONFIG_ALT_INDEX_OFFSET) == null)
		return iIndex;
	
	return iBase + CONFIG_ALT_INDEX_OFFSET;
}

bool AltWeapon_GetString(int iIndex, const char[] sKey, char[] sValue, int iLength)
{
	StringMap sMap = Config_GetStringMap(iIndex + CONFIG_ALT_INDEX_OFFSET);
	if (sMap == null)
		return false;
	
	return sMap.GetString(sKey, sValue, iLength);
}

void AltWeapon_PrintDesp(int iClient, int iIndex)
{
	char sDesp[255];
	if (!AltWeapon_GetString(iIndex, "desp", sDesp, sizeof(sDesp)) || StrEmpty(sDesp))
		return;
	
	for (int iColor = 0; iColor < sizeof(g_strColorTag); iColor++)
		ReplaceString(sDesp, sizeof(sDesp), g_strColorTag[iColor], g_strColorCode[iColor]);
	
	ReplaceString(sDesp, sizeof(sDesp), "%", "%%");
	Format(sDesp, sizeof(sDesp), "%s%s", TEXT_COLOR, sDesp);
	PrintToChat(iClient, sDesp);
}

static void AltWeapon_ApplyNow(int iClient, int iIndex)
{
	if (g_iTotalRoundPlayed <= 0 || GameRules_GetRoundState() != RoundState_Preround)
		return;
	
	if (!IsClientInGame(iClient) || !IsPlayerAlive(iClient) || !SaxtonHale_IsValidAttack(iClient))
		return;
	
	for (int iSlot = 0; iSlot <= WeaponSlot_BuilderEngie; iSlot++)
	{
		int iWeapon = TF2_GetItemInSlot(iClient, iSlot);
		if (iWeapon > MaxClients && Config_GetPrefab(GetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex")) == iIndex)
		{
			TF2_RemoveItemInSlot(iClient, iSlot);
			TF2_RegeneratePlayer(iClient);
			return;
		}
	}
}
