void Native_AskLoad()
{
	CreateNative("SaxtonHale_GetBossTeam", Native_GetBossTeam);
	CreateNative("SaxtonHale_GetAttackTeam", Native_GetAttackTeam);
	CreateNative("SaxtonHale_GetMainClass", Native_GetMainClass);
	CreateNative("SaxtonHale_GetDamage", Native_GetDamage);
	CreateNative("SaxtonHale_GetAssistDamage", Native_GetAssistDamage);
	CreateNative("SaxtonHale_ForceSpecialRound", Native_ForceSpecialRound);
	CreateNative("SaxtonHale_SetPreferences", Native_SetPreferences);
	CreateNative("SaxtonHale_SetQueue", Native_SetQueue);
	CreateNative("SaxtonHale_SetWinstreak", Native_SetWinstreak);
	CreateNative("SaxtonHale_IsWinstreakEnable", Native_IsWinstreakEnable);
	CreateNative("SaxtonHale_SetAdmin", Native_SetAdmin);
	CreateNative("SaxtonHale_SetPunishment", Native_SetPunishment);
}

//TFTeam SaxtonHale_GetBossTeam();
public any Native_GetBossTeam(Handle hPlugin, int iNumParams)
{
	return TFTeam_Boss;
}

//TFTeam SaxtonHale_GetAttackTeam();
public any Native_GetAttackTeam(Handle hPlugin, int iNumParams)
{
	return TFTeam_Attack;
}

//TFClassType SaxtonHale_GetMainClass(int iClient);
public any Native_GetMainClass(Handle hPlugin, int iNumParams)
{
	int iClient = GetNativeCell(1);
	if (iClient <= 0 || iClient > MaxClients)
		ThrowNativeError(SP_ERROR_NATIVE, "Client index %d is invalid", iClient);
	if (!IsClientInGame(iClient))
		ThrowNativeError(SP_ERROR_NATIVE, "Client %d is not in game", iClient);
	
	return ClassLimit_GetMainClass(iClient);
}

//int SaxtonHale_GetDamage(int iClient);
public any Native_GetDamage(Handle hPlugin, int iNumParams)
{
	int iClient = GetNativeCell(1);
	if (iClient <= 0 || iClient > MaxClients)
		ThrowNativeError(SP_ERROR_NATIVE, "Client index %d is invalid", iClient);
	if (!IsClientInGame(iClient))
		ThrowNativeError(SP_ERROR_NATIVE, "Client %d is not in game", iClient);
	
	return g_iPlayerDamage[iClient];
}

//int SaxtonHale_GetAssistDamage(int iClient);
public any Native_GetAssistDamage(Handle hPlugin, int iNumParams)
{
	int iClient = GetNativeCell(1);
	if (iClient <= 0 || iClient > MaxClients)
		ThrowNativeError(SP_ERROR_NATIVE, "Client index %d is invalid", iClient);
	if (!IsClientInGame(iClient))
		ThrowNativeError(SP_ERROR_NATIVE, "Client %d is not in game", iClient);
	
	return g_iPlayerAssistDamage[iClient];
}

//bool SaxtonHale_ForceSpecialRound(int iClient=0, TFClassType nClass=TFClass_Unknown);
public any Native_ForceSpecialRound(Handle hPlugin, int iNumParams)
{
	int iClient = GetNativeCell(1);
	TFClassType nClass = GetNativeCell(2);

	if (iClient == 0)
	{
		g_bSpecialRound = true;
		g_nSpecialRoundNextClass = nClass;
		return true;
	}
	
	if (0 < iClient <= MaxClients && IsClientInGame(iClient) && !g_bPlayerTriggerSpecialRound[iClient])
	{
		g_bPlayerTriggerSpecialRound[iClient] = true;
		g_nSpecialRoundNextClass = nClass;
		return true;
	}

	return false;
}

//void SaxtonHale_SetPreferences(int iClient, int iPreferences);
public any Native_SetPreferences(Handle hPlugin, int iNumParams)
{
	int iClient = GetNativeCell(1);
	int iPreferences = GetNativeCell(2);
	
	if (iClient <= 0 || iClient > MaxClients)
		ThrowNativeError(SP_ERROR_NATIVE, "Client index %d is invalid", iClient);
	if (!IsClientConnected(iClient))
		ThrowNativeError(SP_ERROR_NATIVE, "Client %d is not connected", iClient);

	Preferences_SetAll(iClient, iPreferences);
}

//SaxtonHale_SetQueue(int iClient, int iQueue);
public any Native_SetQueue(Handle hPlugin, int iNumParams)
{
	int iClient = GetNativeCell(1);
	int iQueue = GetNativeCell(2);
	
	if (iClient <= 0 || iClient > MaxClients)
		ThrowNativeError(SP_ERROR_NATIVE, "Client index %d is invalid", iClient);
	if (!IsClientConnected(iClient))
		ThrowNativeError(SP_ERROR_NATIVE, "Client %d is not connected", iClient);

	Queue_SetPlayerPoints(iClient, iQueue);
}

//SaxtonHale_SetWinstreak(int iClient, int iWinstreak);
public any Native_SetWinstreak(Handle hPlugin, int iNumParams)
{
	int iClient = GetNativeCell(1);
	int iWinstreak = GetNativeCell(2);
	
	if (iClient <= 0 || iClient > MaxClients)
		ThrowNativeError(SP_ERROR_NATIVE, "Client index %d is invalid", iClient);
	if (!IsClientConnected(iClient))
		ThrowNativeError(SP_ERROR_NATIVE, "Client %d is not connected", iClient);

	Winstreak_SetCurrent(iClient, iWinstreak);
}

//bool SaxtonHale_IsWinstreakEnable();
public any Native_IsWinstreakEnable(Handle hPlugin, int iNumParams)
{
	return Winstreak_IsEnabled();
}

//SaxtonHale_SetAdmin(int iClient, bool bEnable);
public any Native_SetAdmin(Handle hPlugin, int iNumParams)
{
	int iClient = GetNativeCell(1);
	bool bEnable = GetNativeCell(2);
	
	if (iClient <= 0 || iClient > MaxClients)
		ThrowNativeError(SP_ERROR_NATIVE, "Client index %d is invalid", iClient);
	if (!IsClientConnected(iClient))
		ThrowNativeError(SP_ERROR_NATIVE, "Client %d is not connected", iClient);

	if (bEnable)
		Client_AddFlag(iClient, ClientFlags_Admin);
	else
		Client_RemoveFlag(iClient, ClientFlags_Admin);
}

//SaxtonHale_SetPunishment(int iClient, bool bEnable);
public any Native_SetPunishment(Handle hPlugin, int iNumParams)
{
	int iClient = GetNativeCell(1);
	bool bEnable = GetNativeCell(2);
	
	if (iClient <= 0 || iClient > MaxClients)
		ThrowNativeError(SP_ERROR_NATIVE, "Client index %d is invalid", iClient);
	if (!IsClientConnected(iClient))
		ThrowNativeError(SP_ERROR_NATIVE, "Client %d is not connected", iClient);

	if (bEnable)
		Client_AddFlag(iClient, ClientFlags_Punishment);
	else
		Client_RemoveFlag(iClient, ClientFlags_Punishment);
}