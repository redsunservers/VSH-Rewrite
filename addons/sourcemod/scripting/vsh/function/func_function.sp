enum struct FuncFunction
{
	ExecType nExecType;
	ParamType nParamType[SP_MAX_EXEC_PARAMS];
	int iParamLength;
}

static StringMap g_mFuncFunction;

void FuncFunction_Init()
{
	g_mFuncFunction = new StringMap();
	
	//Boss functions
	SaxtonHale_InitFunction("CreateBoss", ET_Single, Param_String);
	SaxtonHale_InitFunction("SetBossType", ET_Ignore, Param_String);
	SaxtonHale_InitFunction("GetBossType", ET_Ignore, Param_StringByRef, Param_Cell);
	SaxtonHale_InitFunction("GetBossName", ET_Ignore, Param_StringByRef, Param_Cell);
	SaxtonHale_InitFunction("GetBossInfo", ET_Ignore, Param_StringByRef, Param_Cell);
	SaxtonHale_InitFunction("IsBossHidden", ET_Single);
	
	//Modifiers functions
	SaxtonHale_InitFunction("CreateModifiers", ET_Single, Param_String);
	SaxtonHale_InitFunction("SetModifiersType", ET_Ignore, Param_String);
	SaxtonHale_InitFunction("GetModifiersType", ET_Ignore, Param_StringByRef, Param_Cell);
	SaxtonHale_InitFunction("GetModifiersName", ET_Ignore, Param_StringByRef, Param_Cell);
	SaxtonHale_InitFunction("GetModifiersInfo", ET_Ignore, Param_StringByRef, Param_Cell);
	SaxtonHale_InitFunction("IsModifiersHidden", ET_Single);
	
	//Ability functions
	SaxtonHale_InitFunction("CreateAbility", ET_Single, Param_String);
	SaxtonHale_InitFunction("FindAbility", ET_Single, Param_String);
	SaxtonHale_InitFunction("DestroyAbility", ET_Ignore, Param_String);
	
	//General functions
	SaxtonHale_InitFunction("OnThink", ET_Ignore);
	SaxtonHale_InitFunction("OnSpawn", ET_Ignore);
	SaxtonHale_InitFunction("OnRage", ET_Ignore);
	SaxtonHale_InitFunction("OnCommandKeyValues", ET_Hook, Param_String);
	SaxtonHale_InitFunction("OnAttackCritical", ET_Hook, Param_Cell, Param_CellByRef);
	SaxtonHale_InitFunction("OnVoiceCommand", ET_Hook, Param_String, Param_String);
	SaxtonHale_InitFunction("OnSoundPlayed", ET_Hook, Param_Array, Param_CellByRef, Param_StringByRef, Param_CellByRef, Param_FloatByRef, Param_CellByRef, Param_CellByRef, Param_CellByRef, Param_String, Param_CellByRef);
	
	//Damage/Death functions
	SaxtonHale_InitFunction("OnAttackDamage", ET_Hook, Param_CellByRef, Param_CellByRef, Param_FloatByRef, Param_CellByRef, Param_CellByRef, Param_Vector, Param_Vector, Param_Cell);
	SaxtonHale_InitFunction("OnTakeDamage", ET_Hook, Param_CellByRef, Param_CellByRef, Param_FloatByRef, Param_CellByRef, Param_CellByRef, Param_Vector, Param_Vector, Param_Cell);
	SaxtonHale_InitFunction("OnPlayerKilled", ET_Ignore, Param_Cell, Param_Cell);
	SaxtonHale_InitFunction("OnDeath", ET_Ignore, Param_Cell);
	
	//Button functions
	SaxtonHale_InitFunction("OnButton", ET_Ignore, Param_CellByRef);
	SaxtonHale_InitFunction("OnButtonPress", ET_Ignore, Param_Cell);
	SaxtonHale_InitFunction("OnButtonHold", ET_Ignore, Param_Cell);
	SaxtonHale_InitFunction("OnButtonRelease", ET_Ignore, Param_Cell);
	
	//Building functions
	SaxtonHale_InitFunction("OnBuild", ET_Single, Param_Cell, Param_Cell);
	SaxtonHale_InitFunction("OnBuildObject", ET_Event, Param_Cell);
	SaxtonHale_InitFunction("OnDestroyObject", ET_Event, Param_Cell);
	SaxtonHale_InitFunction("OnObjectSapped", ET_Event, Param_Cell);
	
	//Retrieve array/strings
	SaxtonHale_InitFunction("GetModel", ET_Ignore, Param_StringByRef, Param_Cell);
	SaxtonHale_InitFunction("GetSound", ET_Ignore, Param_StringByRef, Param_Cell, Param_Cell);
	SaxtonHale_InitFunction("GetSoundKill", ET_Ignore, Param_StringByRef, Param_Cell, Param_Cell);
	SaxtonHale_InitFunction("GetSoundAbility", ET_Ignore, Param_StringByRef, Param_Cell, Param_String);
	SaxtonHale_InitFunction("GetRenderColor", ET_Ignore, Param_Color);
	SaxtonHale_InitFunction("GetMusicInfo", ET_Ignore, Param_StringByRef, Param_Cell, Param_FloatByRef);
	SaxtonHale_InitFunction("GetRageMusicInfo", ET_Ignore, Param_StringByRef, Param_Cell, Param_FloatByRef);
	
	//Misc functions
	SaxtonHale_InitFunction("Precache", ET_Ignore);
	SaxtonHale_InitFunction("CalculateMaxHealth", ET_Single);
	SaxtonHale_InitFunction("AddRage", ET_Ignore, Param_Cell);
	SaxtonHale_InitFunction("CreateWeapon", ET_Single, Param_Cell, Param_String, Param_Cell, Param_Cell, Param_String);
	SaxtonHale_InitFunction("Destroy", ET_Ignore);
}

stock bool FuncFunction_Register(const char[] sFunction, ExecType nExecType, ParamType nParamType[SP_MAX_EXEC_PARAMS], int iParamLength)
{
	FuncFunction funcFunction;
	funcFunction.nExecType = nExecType;
	funcFunction.iParamLength = iParamLength;
	funcFunction.nParamType = nParamType;
	
	if (!g_mFuncFunction.SetArray(sFunction, funcFunction, sizeof(funcFunction), false))
		return false;
	
	return true;
}

stock void FuncFunction_Unregister(const char[] sFunction)
{
	g_mFuncFunction.Remove(sFunction);
}

stock bool FuncFunction_Exists(const char[] sFunction)
{
	FuncFunction buffer;
	return g_mFuncFunction.GetArray(sFunction, buffer, sizeof(buffer));
}

stock ExecType FuncFunction_GetExecType(const char[] sFunction)
{
	FuncFunction funcFunction;
	g_mFuncFunction.GetArray(sFunction, funcFunction, sizeof(funcFunction));
	return funcFunction.nExecType;
}

stock int FuncFunction_GetParamType(const char[] sFunction, ParamType nParamType[SP_MAX_EXEC_PARAMS])
{
	FuncFunction funcFunction;
	if (!g_mFuncFunction.GetArray(sFunction, funcFunction, sizeof(funcFunction)))
		return -1;
	
	for (int i = 0; i < funcFunction.iParamLength; i++)
		nParamType[i] = funcFunction.nParamType[i];
	
	//Return amount of params
	return funcFunction.iParamLength;
}

stock bool FuncFunction_GetParamTypeName(ParamType nParamType, char[] sBuffer, int iLength)
{
	switch (nParamType)
	{
		case Param_Any: Format(sBuffer, iLength, "Param_Any");
		case Param_Cell: Format(sBuffer, iLength, "Param_Cell");
		case Param_CellByRef: Format(sBuffer, iLength, "Param_CellByRef");
		case Param_Float: Format(sBuffer, iLength, "Param_Float");
		case Param_FloatByRef: Format(sBuffer, iLength, "Param_FloatByRef");
		case Param_String: Format(sBuffer, iLength, "Param_String");
		case Param_StringByRef: Format(sBuffer, iLength, "Param_StringByRef");
		case Param_Array: Format(sBuffer, iLength, "Param_Array");
		case Param_Vector: Format(sBuffer, iLength, "Param_Vector");
		case Param_Color: Format(sBuffer, iLength, "Param_Color");
		case Param_VarArgs: Format(sBuffer, iLength, "Param_VarArgs");
		default: return false;
	}
	
	return true;
}