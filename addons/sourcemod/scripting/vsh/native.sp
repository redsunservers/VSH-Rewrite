//Macro to register every properties to set and get
#define NATIVE_PROPERTY_REGISTER(%1,%2)\
Format(sBuffer, sizeof(sBuffer), "SaxtonHaleBase.%s.set", %1); \
CreateNative(sBuffer, Native_Property_%2_Set); \
Format(sBuffer, sizeof(sBuffer), "SaxtonHaleBase.%s.get", %1); \
CreateNative(sBuffer, Native_Property_%2_Get);

void Native_AskLoad()
{
	CreateNative("SaxtonHaleBase.CallFunction", Native_CallFunction);
	
	CreateNative("SaxtonHale_InitFunction", Native_InitFunction);
	
	CreateNative("SaxtonHale_HookFunction", Native_HookFunction);
	CreateNative("SaxtonHale_UnhookFunction", Native_UnhookFunction);
	
	CreateNative("SaxtonHale_GetParam", Native_GetParam);
	CreateNative("SaxtonHale_SetParam", Native_SetParam);
	CreateNative("SaxtonHale_GetParamArray", Native_GetParamArray);
	CreateNative("SaxtonHale_SetParamArray", Native_SetParamArray);
	CreateNative("SaxtonHale_GetParamString", Native_GetParamString);
	CreateNative("SaxtonHale_SetParamString", Native_SetParamString);
	
	CreateNative("SaxtonHale_RegisterBoss", Native_RegisterBoss);
	CreateNative("SaxtonHale_UnregisterBoss", Native_UnregisterBoss);
	CreateNative("SaxtonHale_RegisterModifiers", Native_RegisterModifiers);
	CreateNative("SaxtonHale_UnregisterModifiers", Native_UnregisterModifiers);
	CreateNative("SaxtonHale_RegisterAbility", Native_RegisterAbility);
	CreateNative("SaxtonHale_UnregisterAbility", Native_UnregisterAbility);
	
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
	
	char sBuffer[256];
	
	NATIVE_PROPERTY_REGISTER("bValid",bValid)
	NATIVE_PROPERTY_REGISTER("bModifiers",bModifiers)
	NATIVE_PROPERTY_REGISTER("bMinion",bMinion)
	NATIVE_PROPERTY_REGISTER("bSuperRage",bSuperRage)
	NATIVE_PROPERTY_REGISTER("bModel",bModel)
	NATIVE_PROPERTY_REGISTER("bCanBeHealed",bCanBeHealed)
	NATIVE_PROPERTY_REGISTER("flSpeed",flSpeed)
	NATIVE_PROPERTY_REGISTER("flSpeedMult",flSpeedMult)
	NATIVE_PROPERTY_REGISTER("flEnvDamageCap",flEnvDamageCap)
	NATIVE_PROPERTY_REGISTER("flGlowTime",flGlowTime)
	NATIVE_PROPERTY_REGISTER("flRageLastTime",flRageLastTime)
	NATIVE_PROPERTY_REGISTER("flMaxRagePercentage",flMaxRagePercentage)
	NATIVE_PROPERTY_REGISTER("flHealthMultiplier",flHealthMultiplier)
	NATIVE_PROPERTY_REGISTER("iMaxHealth",iMaxHealth)
	NATIVE_PROPERTY_REGISTER("iBaseHealth",iBaseHealth)
	NATIVE_PROPERTY_REGISTER("iHealthPerPlayer",iHealthPerPlayer)
	NATIVE_PROPERTY_REGISTER("iRageDamage",iRageDamage)
	NATIVE_PROPERTY_REGISTER("iMaxRageDamage",iMaxRageDamage)
	NATIVE_PROPERTY_REGISTER("nClass",nClass)
}

//any SaxtonHaleBase.CallFunction(const char[] sName, any...);
public int Native_CallFunction(Handle hPlugin, int iNumParams)
{
	SaxtonHaleBase boss = view_as<SaxtonHaleBase>(GetNativeCell(1));
	
	char sName[FUNCTION_ARRAY_MAX];
	GetNativeString(2, sName, sizeof(sName));
	
	ParamType paramType[FUNCTION_PARAM_MAX+1];
	int iSize = Function_GetParamType(sName, paramType);
	if (iSize == -1)
		ThrowNativeError(SP_ERROR_NATIVE, "Invalid function name passed (%s)", sName);
	
	if (iSize > iNumParams-2)
		ThrowNativeError(SP_ERROR_NATIVE, "Too few param passed (Found %d params, expected %d)", iNumParams-2, iSize);
	
	//Create array of every params to pass
	any value[FUNCTION_PARAM_MAX+1][FUNCTION_ARRAY_MAX];
	
	for (int iParam = 1; iParam <= iSize; iParam++)
	{
		switch (paramType[iParam])
		{
			case Param_Cell, Param_CellByRef, Param_Float, Param_FloatByRef:
			{
				value[iParam][0] = GetNativeCellRef(iParam + 2);
			}
			case Param_String:
			{
				int iError = GetNativeString(iParam + 2, view_as<char>(value[iParam]), sizeof(value[]));
				if (iError != SP_ERROR_NONE)
					ThrowNativeError(SP_ERROR_NATIVE, "Unable to get string value (param %d, error code %d)", iParam, iError);
			}
			case Param_Array:
			{
				int iError = GetNativeArray(iParam + 2, value[iParam], sizeof(value[]));
				if (iError != SP_ERROR_NONE)
					ThrowNativeError(SP_ERROR_NATIVE, "Unable to get array value (param %d, error code %d)", iParam, iError);
			}
		}
	}
	
	//Start stack
	if (!Function_StartStack(sName, value, iSize))
		ThrowNativeError(SP_ERROR_NATIVE, "Reached max allowed callstack! (max %d)", FUNCTION_CALLSTACK_MAX);
	
	//Start function
	any returnValue = Function_Start(boss);
	
	//Finish stack and get result
	Function_FinishStack(value);
	
	//Set ref native values
	for (int iParam = 1; iParam <= iSize; iParam++)
	{
		switch (paramType[iParam])
		{
			case Param_CellByRef, Param_FloatByRef:
			{
				SetNativeCellRef(iParam + 2, value[iParam][0]);
			}
			case Param_String:
			{
				int iError = SetNativeString(iParam + 2, view_as<char>(value[iParam]), sizeof(value[]));
				if (iError != SP_ERROR_NONE)
					ThrowNativeError(SP_ERROR_NATIVE, "Unable to return string value (param %d, error code %d)", iParam, iError);
			}
			case Param_Array:
			{
				int iError = SetNativeArray(iParam + 2, value[iParam], sizeof(value[]));
				if (iError != SP_ERROR_NONE)
					ThrowNativeError(SP_ERROR_NATIVE, "Unable to return array value (param %d, error code %d)", iParam, iError);
			}
		}
	}
	
	return returnValue;
}

//void SaxtonHale_InitFunction(const char[] sName, ExecType type, ParamType ...);
public int Native_InitFunction(Handle hPlugin, int iNumParams)
{
	iNumParams -= 2;
	
	if (iNumParams > FUNCTION_PARAM_MAX)
		ThrowNativeError(SP_ERROR_NATIVE, "Too many ExecType params passed (Found %d, max %d)", iNumParams, FUNCTION_PARAM_MAX);
	
	char sName[FUNCTION_ARRAY_MAX];
	GetNativeString(1, sName, sizeof(sName));
	ExecType execType = GetNativeCell(2);
	
	//Check for dumb plugins passing unsupported ExecType
	if (execType < ET_Ignore || execType > ET_Hook)
		ThrowNativeError(SP_ERROR_NATIVE, "ExecType %d is unsupported", execType);
	
	//Push all ParamType to array
	ParamType paramType[FUNCTION_PARAM_MAX+1];
	for (int iParam = 1; iParam <= iNumParams; iParam++)
	{
		paramType[iParam] = GetNativeCellRef(iParam + 2);
		
		//Check for any unsupported params
		if (paramType[iParam] != Param_Cell
			&& paramType[iParam] != Param_CellByRef
			&& paramType[iParam] != Param_Float
			&& paramType[iParam] != Param_FloatByRef
			&& paramType[iParam] != Param_String
			&& paramType[iParam] != Param_Array)
		{
			char sParamTypeName[32];
			Function_GetParamTypeName(paramType[iParam], sParamTypeName, sizeof(sParamTypeName));
			ThrowNativeError(SP_ERROR_NATIVE, "%s is unsupported (Param %d)", sParamTypeName, iParam);
		}
	}
	
	if (!Function_Create(sName, execType, paramType, iNumParams))
		ThrowNativeError(SP_ERROR_NATIVE, "Function (%s) already exists", sName);
}

//void SaxtonHale_HookFunction(const char[] sName, SaxtonHaleHookCallback callback, SaxtonHaleHookType = VSHHookType_Post);
public int Native_HookFunction(Handle hPlugin, int iNumParams)
{
	char sName[FUNCTION_ARRAY_MAX];
	GetNativeString(1, sName, sizeof(sName));
	SaxtonHaleHookCallback callback = view_as<SaxtonHaleHookCallback>(GetNativeFunction(2));
	SaxtonHaleHookMode hookType = GetNativeCell(3);
	
	Function_Hook(sName, hPlugin, callback, hookType);
}

//void SaxtonHale_UnhookFunction(const char[] sName, SaxtonHaleHookCallback callback, SaxtonHaleHookType = VSHHookType_Post);
public int Native_UnhookFunction(Handle hPlugin, int iNumParams)
{
	char sName[FUNCTION_ARRAY_MAX];
	GetNativeString(1, sName, sizeof(sName));
	SaxtonHaleHookCallback callback = view_as<SaxtonHaleHookCallback>(GetNativeFunction(2));
	SaxtonHaleHookMode hookType = GetNativeCell(3);
	
	Function_Unhook(sName, hPlugin, callback, hookType);
}

int Native_GetParamEx(char[] sName, int iLength, ParamType &buffer)
{
	//Just to save clutter from not copypasting from other natives
	
	int iParam = GetNativeCell(1);
	if (iParam <= 0)
		ThrowNativeError(SP_ERROR_NATIVE, "Param entered must be greater than 0 (Found %d)", iParam);
	
	if (!Function_GetNameStack(sName, iLength))
		ThrowNativeError(SP_ERROR_NATIVE, "Native called while outside of hook");
	
	ParamType paramType[FUNCTION_PARAM_MAX+1];
	int iSize = Function_GetParamType(sName, paramType);
	if (iParam > iSize)
		ThrowNativeError(SP_ERROR_NATIVE, "Param entered outside of function bounds (Found %d, max %d)", iParam, iSize);
	
	buffer = paramType[iParam];
	return iParam;
}

//any SaxtonHale_GetParam(int iParam);
public int Native_GetParam(Handle hPlugin, int iNumParams)
{
	//Get param + checks
	char sName[FUNCTION_ARRAY_MAX];
	ParamType paramType;
	int iParam = Native_GetParamEx(sName, sizeof(sName), paramType);
	
	//Check for non-cell ParamType
	if (paramType != Param_Cell
		&& paramType != Param_CellByRef
		&& paramType != Param_Float
		&& paramType != Param_FloatByRef)
	{
		char sParamTypeName[32];
		Function_GetParamTypeName(paramType, sParamTypeName, sizeof(sParamTypeName));
		ThrowNativeError(SP_ERROR_NATIVE, "Unable to get cell from %s (Function %s, param %d)", sParamTypeName, sName, iParam);
	}
	
	//Get and return value
	any value[FUNCTION_ARRAY_MAX];
	Function_GetParamValue(iParam, value);
	return value[0];
}

//void SaxtonHale_SetParam(int iParam, any value);
public int Native_SetParam(Handle hPlugin, int iNumParams)
{
	//Get param + checks
	char sName[FUNCTION_ARRAY_MAX];
	ParamType paramType;
	int iParam = Native_GetParamEx(sName, sizeof(sName), paramType);
	
	//Check for non-cell ref ParamType
	if (paramType != Param_CellByRef && paramType != Param_FloatByRef)
	{
		char sParamTypeName[32];
		Function_GetParamTypeName(paramType, sParamTypeName, sizeof(sParamTypeName));
		ThrowNativeError(SP_ERROR_NATIVE, "Unable to set cell from %s (Function %s, param %d)", sParamTypeName, sName, iParam);
	}
	
	//Get and set value
	any value[FUNCTION_ARRAY_MAX];
	value[0] = GetNativeCell(2);
	Function_SetParamValue(iParam, value);
}

//void SaxtonHale_GetParamArray(int iParam, any[] value);
public int Native_GetParamArray(Handle hPlugin, int iNumParams)
{
	//Get param + checks
	char sName[FUNCTION_ARRAY_MAX];
	ParamType paramType;
	int iParam = Native_GetParamEx(sName, sizeof(sName), paramType);
	
	//Check for non-array ParamType
	if (paramType != Param_Array)
	{
		char sParamTypeName[32];
		Function_GetParamTypeName(paramType, sParamTypeName, sizeof(sParamTypeName));
		ThrowNativeError(SP_ERROR_NATIVE, "Unable to get array from %s (Function %s, param %d)", sParamTypeName, sName, iParam);
	}
	
	//Get and set array
	any value[FUNCTION_ARRAY_MAX];
	Function_GetParamValue(iParam, value);
	SetNativeArray(2, value, sizeof(value));
}

//void SaxtonHale_SetParamArray(int iParam, any[] value);
public int Native_SetParamArray(Handle hPlugin, int iNumParams)
{
	//Get param + checks
	char sName[FUNCTION_ARRAY_MAX];
	ParamType paramType;
	int iParam = Native_GetParamEx(sName, sizeof(sName), paramType);
	
	//Check for non-array ParamType
	if (paramType != Param_Array)
	{
		char sParamTypeName[32];
		Function_GetParamTypeName(paramType, sParamTypeName, sizeof(sParamTypeName));
		ThrowNativeError(SP_ERROR_NATIVE, "Unable to set array from %s (Function %s, param %d)", sParamTypeName, sName, iParam);
	}
	
	//Get and set array
	any value[FUNCTION_ARRAY_MAX];
	GetNativeArray(2, value, sizeof(value));
	Function_SetParamValue(iParam, value);
}

//void SaxtonHale_GetParamString(int iParam, char[] value);
public int Native_GetParamString(Handle hPlugin, int iNumParams)
{
	//Get param + checks
	char sName[FUNCTION_ARRAY_MAX];
	ParamType paramType;
	int iParam = Native_GetParamEx(sName, sizeof(sName), paramType);
	
	//Check for non-string ParamType
	if (paramType != Param_String)
	{
		char sParamTypeName[32];
		Function_GetParamTypeName(paramType, sParamTypeName, sizeof(sParamTypeName));
		ThrowNativeError(SP_ERROR_NATIVE, "Unable to get string from %s (Function %s, param %d)", sParamTypeName, sName, iParam);
	}
	
	//Get and set string
	any value[FUNCTION_ARRAY_MAX];
	Function_GetParamValue(iParam, value);
	int iLength = GetNativeCell(3);
	SetNativeString(2, view_as<char>(value), iLength);
}

//void SaxtonHale_SetParamString(int iParam, char[] value);
public int Native_SetParamString(Handle hPlugin, int iNumParams)
{
	//Get param + checks
	char sName[FUNCTION_ARRAY_MAX];
	ParamType paramType;
	int iParam = Native_GetParamEx(sName, sizeof(sName), paramType);
	
	//Check for non-string ParamType
	if (paramType != Param_String)
	{
		char sParamTypeName[32];
		Function_GetParamTypeName(paramType, sParamTypeName, sizeof(sParamTypeName));
		ThrowNativeError(SP_ERROR_NATIVE, "Unable to set string from %s (Function %s, param %d)", sParamTypeName, sName, iParam);
	}
	
	//Get and set string
	char value[FUNCTION_ARRAY_MAX];
	GetNativeString(2, value, sizeof(value));
	Function_SetParamValue(iParam, view_as<any>(value));
}

//void SaxtonHale_RegisterBoss(const char[] ...);
public int Native_RegisterBoss(Handle hPlugin, int iNumParams)
{
	if (iNumParams == 0)
		ThrowNativeError(SP_ERROR_NATIVE, "No params passed");
	
	ArrayList aArray;
	if (iNumParams > 1)
		aArray = new ArrayList(MAX_TYPE_CHAR);
	
	for (int i = 1; i <= iNumParams; i++)
	{
		char sBossType[MAX_TYPE_CHAR];
		GetNativeString(i, sBossType, sizeof(sBossType));
		
		if (!Function_AddPlugin(sBossType, hPlugin))
		{
			delete aArray;
			ThrowNativeError(SP_ERROR_NATIVE, "Constructor (%s) already registered", sBossType);
		}
		
		if (iNumParams == 1)
			g_aBossesType.PushString(sBossType);
		else
			aArray.PushString(sBossType);
		
		g_aAllBossesType.PushString(sBossType);
		MenuBoss_AddBoss(sBossType);	//Add boss to menu
	}
	
	if (iNumParams > 1)
		g_aMiscBossesType.Push(aArray);
}

//void SaxtonHale_UnregisterBoss(const char[] sBossType);
public int Native_UnregisterBoss(Handle hPlugin, int iNumParams)
{
	char sBossType[MAX_TYPE_CHAR];
	GetNativeString(1, sBossType, sizeof(sBossType));
	
	Function_RemovePlugin(sBossType);
	
	//Remove from normal boss array
	int iIndex = g_aBossesType.FindString(sBossType);
	if (iIndex >= 0) g_aBossesType.Erase(iIndex);
	
	//Remove from all boss array
	iIndex = g_aAllBossesType.FindString(sBossType);
	if (iIndex >= 0) g_aAllBossesType.Erase(iIndex);
	
	//Remove from menu
	MenuBoss_RemoveBoss(sBossType);
	
	//Remove from misc boss array
	int iLength = g_aMiscBossesType.Length;
	for (int i = 0; i < iLength; i++)
	{
		ArrayList aArray = g_aMiscBossesType.Get(i);
		
		iIndex = aArray.PushString(sBossType);
		if (iIndex >= 0) aArray.Erase(iIndex);
		
		//If only 1 exists, move to normal pick
		if (aArray.Length == 1)
		{
			aArray.GetString(0, sBossType, sizeof(sBossType));
			g_aBossesType.PushString(sBossType);
			delete aArray;
			g_aMiscBossesType.Erase(i);
		}
	}
}

//void SaxtonHale_RegisterModifiers(const char[] sModifiersType);
public int Native_RegisterModifiers(Handle hPlugin, int iNumParams)
{
	char sModifiersType[MAX_TYPE_CHAR];
	GetNativeString(1, sModifiersType, sizeof(sModifiersType));
	
	if (!Function_AddPlugin(sModifiersType, hPlugin))
		ThrowNativeError(SP_ERROR_NATIVE, "Constructor (%s) already registered", sModifiersType);
	
	g_aModifiersType.PushString(sModifiersType);
	MenuBoss_AddModifiers(sModifiersType);	//Add modifiers to menu
}

//void SaxtonHale_UnregisterModifiers(const char[] sModifiersType);
public int Native_UnregisterModifiers(Handle hPlugin, int iNumParams)
{
	char sModifiersType[MAX_TYPE_CHAR];
	GetNativeString(1, sModifiersType, sizeof(sModifiersType));
	
	Function_RemovePlugin(sModifiersType);
	
	//Remove from modifiers array
	int iIndex = g_aModifiersType.FindString(sModifiersType);
	if (iIndex >= 0) g_aModifiersType.Erase(iIndex);
	
	//Remove from menu
	MenuBoss_RemoveModifiers(sModifiersType);
}

//void SaxtonHale_RegisterAbility(const char[] sAbilityType);
public int Native_RegisterAbility(Handle hPlugin, int iNumParams)
{
	char sAbilityType[MAX_TYPE_CHAR];
	GetNativeString(1, sAbilityType, sizeof(sAbilityType));
	
	if (!Function_AddPlugin(sAbilityType, hPlugin))
		ThrowNativeError(SP_ERROR_NATIVE, "Constructor (%s) already registered", sAbilityType);
}

//void SaxtonHale_UnregisterAbility(const char[] sAbilityType);
public int Native_UnregisterAbility(Handle hPlugin, int iNumParams)
{
	char sAbilityType[MAX_TYPE_CHAR];
	GetNativeString(1, sAbilityType, sizeof(sAbilityType));
	
	Function_RemovePlugin(sAbilityType);
}

//TFTeam SaxtonHale_GetBossTeam();
public int Native_GetBossTeam(Handle hPlugin, int iNumParams)
{
	return BOSS_TEAM;
}

//TFTeam SaxtonHale_GetAttackTeam();
public int Native_GetAttackTeam(Handle hPlugin, int iNumParams)
{
	return ATTACK_TEAM;
}

//TFClassType SaxtonHale_GetMainClass(int iClient);
public int Native_GetMainClass(Handle hPlugin, int iNumParams)
{
	int iClient = GetNativeCell(1);
	if (iClient <= 0 || iClient > MaxClients)
		ThrowNativeError(SP_ERROR_NATIVE, "Client index %d is invalid", iClient);
	if (!IsClientInGame(iClient))
		ThrowNativeError(SP_ERROR_NATIVE, "Client %d is not in game", iClient);
	
	return view_as<int>(ClassLimit_GetMainClass(iClient));
}

//int SaxtonHale_GetDamage(int iClient);
public int Native_GetDamage(Handle hPlugin, int iNumParams)
{
	int iClient = GetNativeCell(1);
	if (iClient <= 0 || iClient > MaxClients)
		ThrowNativeError(SP_ERROR_NATIVE, "Client index %d is invalid", iClient);
	if (!IsClientInGame(iClient))
		ThrowNativeError(SP_ERROR_NATIVE, "Client %d is not in game", iClient);
	
	return g_iPlayerDamage[iClient];
}

//int SaxtonHale_GetAssistDamage(int iClient);
public int Native_GetAssistDamage(Handle hPlugin, int iNumParams)
{
	int iClient = GetNativeCell(1);
	if (iClient <= 0 || iClient > MaxClients)
		ThrowNativeError(SP_ERROR_NATIVE, "Client index %d is invalid", iClient);
	if (!IsClientInGame(iClient))
		ThrowNativeError(SP_ERROR_NATIVE, "Client %d is not in game", iClient);
	
	return g_iPlayerAssistDamage[iClient];
}

//bool SaxtonHale_ForceSpecialRound(int iClient=0, TFClassType nClass=TFClass_Unknown);
public int Native_ForceSpecialRound(Handle hPlugin, int iNumParams)
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
public int Native_SetPreferences(Handle hPlugin, int iNumParams)
{
	int iClient = GetNativeCell(1);
	int iPreferences = GetNativeCell(2);
	
	if (iClient <= 0 || iClient > MaxClients)
		ThrowNativeError(SP_ERROR_NATIVE, "Client index %d is invalid", iClient);
	if (!IsClientInGame(iClient))
		ThrowNativeError(SP_ERROR_NATIVE, "Client %d is not in game", iClient);

	Preferences_SetAll(iClient, iPreferences);
}

//SaxtonHale_SetQueue(int iClient, int iQueue);
public int Native_SetQueue(Handle hPlugin, int iNumParams)
{
	int iClient = GetNativeCell(1);
	int iQueue = GetNativeCell(2);
	
	if (iClient <= 0 || iClient > MaxClients)
		ThrowNativeError(SP_ERROR_NATIVE, "Client index %d is invalid", iClient);
	if (!IsClientInGame(iClient))
		ThrowNativeError(SP_ERROR_NATIVE, "Client %d is not in game", iClient);

	Queue_SetPlayerPoints(iClient, iQueue);
}

//SaxtonHale_SetWinstreak(int iClient, int iWinstreak);
public int Native_SetWinstreak(Handle hPlugin, int iNumParams)
{
	int iClient = GetNativeCell(1);
	int iWinstreak = GetNativeCell(2);
	
	if (iClient <= 0 || iClient > MaxClients)
		ThrowNativeError(SP_ERROR_NATIVE, "Client index %d is invalid", iClient);
	if (!IsClientInGame(iClient))
		ThrowNativeError(SP_ERROR_NATIVE, "Client %d is not in game", iClient);

	Winstreak_SetCurrent(iClient, iWinstreak);
}

//bool SaxtonHale_IsWinstreakEnable();
public int Native_IsWinstreakEnable(Handle hPlugin, int iNumParams)
{
	return Winstreak_IsEnabled();
}

//SaxtonHale_SetAdmin(int iClient, bool bEnable);
public int Native_SetAdmin(Handle hPlugin, int iNumParams)
{
	int iClient = GetNativeCell(1);
	bool bEnable = GetNativeCell(2);
	
	if (iClient <= 0 || iClient > MaxClients)
		ThrowNativeError(SP_ERROR_NATIVE, "Client index %d is invalid", iClient);
	if (!IsClientInGame(iClient))
		ThrowNativeError(SP_ERROR_NATIVE, "Client %d is not in game", iClient);

	if (bEnable)
		Client_AddFlag(iClient, haleClientFlags_Admin);
	else
		Client_RemoveFlag(iClient, haleClientFlags_Admin);
}

//SaxtonHale_SetPunishment(int iClient, bool bEnable);
public int Native_SetPunishment(Handle hPlugin, int iNumParams)
{
	int iClient = GetNativeCell(1);
	bool bEnable = GetNativeCell(2);
	
	if (iClient <= 0 || iClient > MaxClients)
		ThrowNativeError(SP_ERROR_NATIVE, "Client index %d is invalid", iClient);
	if (!IsClientInGame(iClient))
		ThrowNativeError(SP_ERROR_NATIVE, "Client %d is not in game", iClient);

	if (bEnable)
		Client_AddFlag(iClient, haleClientFlags_Punishment);
	else
		Client_RemoveFlag(iClient, haleClientFlags_Punishment);
}

//Macro to setup natives for every properties
#define NATIVE_PROPERTY(%1,%2) \
static %2 g_clientBoss%1[TF_MAXPLAYERS+1]; \
public int Native_Property_%1_Set(Handle hPlugin, int iNumParams) \
{ \
	g_clientBoss%1[GetNativeCell(1)] = GetNativeCell(2); \
} \
public int Native_Property_%1_Get(Handle hPlugin, int iNumParams) \
{ \
	return view_as<int>(g_clientBoss%1[GetNativeCell(1)]); \
}

NATIVE_PROPERTY(bValid, bool)
NATIVE_PROPERTY(bModifiers, bool)
NATIVE_PROPERTY(bMinion, bool)
NATIVE_PROPERTY(bSuperRage, bool)
NATIVE_PROPERTY(bModel, bool)
NATIVE_PROPERTY(bCanBeHealed, bool)
NATIVE_PROPERTY(flSpeed, float)
NATIVE_PROPERTY(flSpeedMult, float)
NATIVE_PROPERTY(flEnvDamageCap, float)
NATIVE_PROPERTY(flGlowTime, float)
NATIVE_PROPERTY(flRageLastTime, float)
NATIVE_PROPERTY(flMaxRagePercentage, float)
NATIVE_PROPERTY(flHealthMultiplier, float)
NATIVE_PROPERTY(iMaxHealth, int)
NATIVE_PROPERTY(iBaseHealth, int)
NATIVE_PROPERTY(iHealthPerPlayer, int)
NATIVE_PROPERTY(iRageDamage, int)
NATIVE_PROPERTY(iMaxRageDamage, int)
NATIVE_PROPERTY(nClass, TFClassType)