void Native_AskLoad()
{
	CreateNative("SaxtonHaleNextBoss.SaxtonHaleNextBoss", Native_NextBoss);
	CreateNative("SaxtonHaleNextBoss.GetBoss", Native_NextBoss_GetBoss);
	CreateNative("SaxtonHaleNextBoss.SetBoss", Native_NextBoss_SetBoss);
	CreateNative("SaxtonHaleNextBoss.GetModifier", Native_NextBoss_GetModifier);
	CreateNative("SaxtonHaleNextBoss.SetModifier", Native_NextBoss_SetModifier);
	CreateNative("SaxtonHaleNextBoss.GetName", Native_NextBoss_GetName);
	CreateNative("SaxtonHaleNextBoss.iClient.get", Native_NextBoss_GetClient);
	CreateNative("SaxtonHaleNextBoss.bForceNext.get", Native_NextBoss_GetForceNext);
	CreateNative("SaxtonHaleNextBoss.bForceNext.set", Native_NextBoss_SetForceNext);
	CreateNative("SaxtonHaleNextBoss.bSpecialClass.get", Native_NextBoss_GetSpecialClass);
	CreateNative("SaxtonHaleNextBoss.bSpecialClass.set", Native_NextBoss_SetSpecialClass);
	CreateNative("SaxtonHaleNextBoss.nSpecialClass.get", Native_NextBoss_GetClass);
	CreateNative("SaxtonHaleNextBoss.nSpecialClass.set", Native_NextBoss_SetClass);
	
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

//SaxtonHaleNextBoss SaxtonHaleNextBoss.SaxtonHaleNextBoss(int iClient = 0);
public any Native_NextBoss(Handle hPlugin, int iNumParams)
{
	return NextBoss_CreateStruct(GetNativeCell(1));
}

//void SaxtonHaleNextBoss.GetBoss(char[] sBossType, int iLength);
public any Native_NextBoss_GetBoss(Handle hPlugin, int iNumParams)
{
	NextBoss nextBoss;
	if (!NextBoss_GetStruct(GetNativeCell(1), nextBoss))
		ThrowNativeError(SP_ERROR_NATIVE, "Invalid id passed, id may be already used");
	
	SetNativeString(2, nextBoss.sBossType, GetNativeCell(3));
}

//void SaxtonHaleNextBoss.SetBoss(const char[] sBossType);
public any Native_NextBoss_SetBoss(Handle hPlugin, int iNumParams)
{
	NextBoss nextBoss;
	if (!NextBoss_GetStruct(GetNativeCell(1), nextBoss))
		ThrowNativeError(SP_ERROR_NATIVE, "Invalid id passed, id may be already used");
	
	GetNativeString(2, nextBoss.sBossType, sizeof(nextBoss.sBossType));
	NextBoss_SetStruct(nextBoss);
}

//void SaxtonHaleNextBoss.GetModifier(char[] sModifierType, int iLength);
public any Native_NextBoss_GetModifier(Handle hPlugin, int iNumParams)
{
	NextBoss nextBoss;
	if (!NextBoss_GetStruct(GetNativeCell(1), nextBoss))
		ThrowNativeError(SP_ERROR_NATIVE, "Invalid id passed, id may be already used");
	
	SetNativeString(2, nextBoss.sModifierType, GetNativeCell(3));
}

//void SaxtonHaleNextBoss.SetModifier(const char[] sModifierType);
public any Native_NextBoss_SetModifier(Handle hPlugin, int iNumParams)
{
	NextBoss nextBoss;
	if (!NextBoss_GetStruct(GetNativeCell(1), nextBoss))
		ThrowNativeError(SP_ERROR_NATIVE, "Invalid id passed, id may be already used");
	
	GetNativeString(2, nextBoss.sModifierType, sizeof(nextBoss.sModifierType));
	NextBoss_SetStruct(nextBoss);
}

//void SaxtonHaleNextBoss.GetName(char[] sBuffer, int iLength);
public any Native_NextBoss_GetName(Handle hPlugin, int iNumParams)
{
	NextBoss nextBoss;
	if (!NextBoss_GetStruct(GetNativeCell(1), nextBoss))
		ThrowNativeError(SP_ERROR_NATIVE, "Invalid id passed, id may be already used");
	
	int iLength = GetNativeCell(3);
	char[] sBuffer = new char[iLength];
	char[] sBossName = new char[iLength];
	char[] sModifiersName = new char[iLength];
	
	if (0 < nextBoss.iClient <= MaxClients && IsClientInGame(nextBoss.iClient))
		Format(sBuffer, iLength, "%s%N as ", sBuffer, nextBoss.iClient);
	
	//If boss not set, display as "random (modifiers) boss"
	if (StrEmpty(nextBoss.sBossType))
	{
		Format(sBuffer, iLength, "%sRandom ", sBuffer);
		Format(sBossName, iLength, "Boss");
	}
	else
	{
		SaxtonHaleBase boss = SaxtonHaleBase(0);
		boss.CallFunction("SetBossType", nextBoss.sBossType);
		boss.CallFunction("GetBossName", sBossName, iLength);
	}
	
	if (!StrEmpty(nextBoss.sModifierType) && !StrEqual(nextBoss.sModifierType, "CModifiersNone"))
	{
		SaxtonHaleBase boss = SaxtonHaleBase(0);
		boss.CallFunction("SetModifiersType", nextBoss.sModifierType);
		boss.CallFunction("GetModifiersName", sModifiersName, iLength);
		
		Format(sBuffer, iLength, "%s%s ", sBuffer, sModifiersName);
	}
	
	Format(sBuffer, iLength, "%s%s", sBuffer, sBossName);
	SetNativeString(2, sBuffer, iLength);
}

//int SaxtonHaleNextBoss.iClient.get();
public any Native_NextBoss_GetClient(Handle hPlugin, int iNumParams)
{
	NextBoss nextBoss;
	if (!NextBoss_GetStruct(GetNativeCell(1), nextBoss))
		ThrowNativeError(SP_ERROR_NATIVE, "Invalid id passed, id may be already used");
	
	return nextBoss.iClient;
}

//bool SaxtonHaleNextBoss.bForceNext.get();
public any Native_NextBoss_GetForceNext(Handle hPlugin, int iNumParams)
{
	NextBoss nextBoss;
	if (!NextBoss_GetStruct(GetNativeCell(1), nextBoss))
		ThrowNativeError(SP_ERROR_NATIVE, "Invalid id passed, id may be already used");
	
	return nextBoss.bForceNext;
}

//void SaxtonHaleNextBoss.bForceNext.set(bool val);
public any Native_NextBoss_SetForceNext(Handle hPlugin, int iNumParams)
{
	NextBoss nextBoss;
	if (!NextBoss_GetStruct(GetNativeCell(1), nextBoss))
		ThrowNativeError(SP_ERROR_NATIVE, "Invalid id passed, id may be already used");
	
	nextBoss.bForceNext = GetNativeCell(2);
	NextBoss_SetStruct(nextBoss);
}

//bool SaxtonHaleNextBoss.bSpecialClass.get();
public any Native_NextBoss_GetSpecialClass(Handle hPlugin, int iNumParams)
{
	NextBoss nextBoss;
	if (!NextBoss_GetStruct(GetNativeCell(1), nextBoss))
		ThrowNativeError(SP_ERROR_NATIVE, "Invalid id passed, id may be already used");
	
	return nextBoss.bSpecialClass;
}

//void SaxtonHaleNextBoss.bSpecialClass.set(bool val);
public any Native_NextBoss_SetSpecialClass(Handle hPlugin, int iNumParams)
{
	NextBoss nextBoss;
	if (!NextBoss_GetStruct(GetNativeCell(1), nextBoss))
		ThrowNativeError(SP_ERROR_NATIVE, "Invalid id passed, id may be already used");
	
	nextBoss.bSpecialClass = GetNativeCell(2);
	NextBoss_SetStruct(nextBoss);
}

//TFClassType SaxtonHaleNextBoss.nSpecialClass.get();
public any Native_NextBoss_GetClass(Handle hPlugin, int iNumParams)
{
	NextBoss nextBoss;
	if (!NextBoss_GetStruct(GetNativeCell(1), nextBoss))
		ThrowNativeError(SP_ERROR_NATIVE, "Invalid id passed, id may be already used");
	
	return nextBoss.nSpecialClass;
}

//void SaxtonHaleNextBoss.nSpecialClass.set(bool val);
public any Native_NextBoss_SetClass(Handle hPlugin, int iNumParams)
{
	NextBoss nextBoss;
	if (!NextBoss_GetStruct(GetNativeCell(1), nextBoss))
		ThrowNativeError(SP_ERROR_NATIVE, "Invalid id passed, id may be already used");
	
	nextBoss.nSpecialClass = GetNativeCell(2);
	NextBoss_SetStruct(nextBoss);
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

//bool SaxtonHale_ForceSpecialRound(int iClient=0, TFClassType nClass=TFClass_Unknown);
public any Native_ForceSpecialRound(Handle hPlugin, int iNumParams)
{
	int iClient = GetNativeCell(1);
	TFClassType nClass = GetNativeCell(2);
	
	if (iClient == 0)
	{
		NextBoss_SetSpecialClass(nClass);
		return true;
	}
	
	if (0 < iClient <= MaxClients && IsClientInGame(iClient))
	{
		SaxtonHaleNextBoss nextBoss = SaxtonHaleNextBoss(iClient);
		if (nextBoss.bSpecialClass)
			return false;
		
		nextBoss.bSpecialClass = true;
		nextBoss.nSpecialClass = nClass;
		return true;
	}
	
	return false;
}