#define ALTWEAPON_PREF_BIT_FIRST	16
#define ALTWEAPON_PREF_SLOTS	15

static ArrayList g_aAltWeaponActive[MAXPLAYERS];

void AltWeapon_Clear(int iClient)
{
	if (g_aAltWeaponActive[iClient] != null)
		g_aAltWeaponActive[iClient].Clear();
}

static int AltWeapon_GetPrefBit(int iIndex)
{
	char sValue[16];
	int iSlot;
	if (!AltWeapon_GetString(iIndex, "prefslot", sValue, sizeof(sValue)) || StringToIntEx(sValue, iSlot) <= 0)
		return -1;

	if (iSlot < 0 || iSlot >= ALTWEAPON_PREF_SLOTS)
		return -1;

	return ALTWEAPON_PREF_BIT_FIRST + iSlot;
}

void AltWeapon_UpdateActive(int iClient)
{
	if (g_aAltWeaponActive[iClient] == null)
		g_aAltWeaponActive[iClient] = new ArrayList();

	g_aAltWeaponActive[iClient].Clear();
	if (g_iTotalRoundPlayed <= 0)
		return;

	int iLength = g_ConfigIndex.Length;
	for (int i = 0; i < iLength; i++)
	{
		int iIndex = g_ConfigIndex.Get(i, 0);
		if (iIndex < CONFIG_ALT_INDEX_OFFSET)
			continue;

		iIndex -= CONFIG_ALT_INDEX_OFFSET;
		if (AltWeapon_IsEnabled(iClient, iIndex))
			g_aAltWeaponActive[iClient].Push(iIndex);
	}
}

void AltWeapon_ResetAttribs(int iWeapon, int iIndex)
{
	int iAltIndex = Config_GetPrefab(iIndex) + CONFIG_ALT_INDEX_OFFSET;
	if (Config_GetStringMap(iAltIndex) == null)
		return;

	AltWeapon_RemoveConfigAttribs(iWeapon, iIndex);
	AltWeapon_RemoveConfigAttribs(iWeapon, iAltIndex);
	TF2Attrib_ClearCache(iWeapon);
}

static void AltWeapon_RemoveConfigAttribs(int iWeapon, int iConfigIndex)
{
	char sAttrib[255], atts[32][32];
	if (!g_ConfigIndex.GetAttrib(iConfigIndex, sAttrib, sizeof(sAttrib)))
		return;

	int iCount = ExplodeString(sAttrib, " ; ", atts, sizeof(atts), sizeof(atts[]));
	for (int i = 0; i + 1 < iCount; i += 2)
		TF2Attrib_RemoveByDefIndex(iWeapon, StringToInt(atts[i]));
}

bool AltWeapon_IsEnabled(int iClient, int iIndex)
{
	if (iClient <= 0 || iClient > MaxClients)
		return false;

	int iBit = AltWeapon_GetPrefBit(iIndex);
	return (iBit != -1 && Preferences_GetBit(iClient, iBit));
}

bool AltWeapon_Toggle(int iClient, int iIndex)
{
	int iBit = AltWeapon_GetPrefBit(iIndex);
	if (iBit == -1)
		return false;

	if (!Preferences_SetBit(iClient, iBit, !Preferences_GetBit(iClient, iBit)))
		return false;

	AltWeapon_ApplyNow(iClient, iIndex);
	return true;
}

int AltWeapon_GetConfigIndex(int iClient, int iIndex)
{
	if (iIndex < 0 || iIndex >= CONFIG_ALT_INDEX_OFFSET)
		return iIndex;

	if (iClient <= 0 || iClient > MaxClients || g_aAltWeaponActive[iClient] == null || g_aAltWeaponActive[iClient].Length == 0)
		return iIndex;

	int iBase = Config_GetPrefab(iIndex);
	if (g_aAltWeaponActive[iClient].FindValue(iBase) == -1 || Config_GetStringMap(iBase + CONFIG_ALT_INDEX_OFFSET) == null)
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

			int iMaxHealth = SDK_GetMaxHealth(iClient);
			if (GetClientHealth(iClient) > iMaxHealth)
				SetEntityHealth(iClient, iMaxHealth);

			return;
		}
	}
}
