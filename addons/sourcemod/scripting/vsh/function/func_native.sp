static FuncFunctionList g_aFuncFunctionList;

void FuncNative_AskLoad()
{
	CreateNative("SaxtonHaleFunction.SaxtonHaleFunction", FuncNative_InitFunction);
	CreateNative("SaxtonHaleFunction.AddParam", FuncNative_FunctionAddParam);
	CreateNative("SaxtonHaleFunction.SetParam", FuncNative_FunctionSetParam);
	
	CreateNative("SaxtonHale_RegisterClass", FuncNative_RegisterClass);
	CreateNative("SaxtonHale_UnregisterClass", FuncNative_UnregisterClass);
	CreateNative("SaxtonHale_GetPlugin", FuncNative_GetPlugin);
	CreateNative("SaxtonHale_GetAllClass", FuncNative_GetAllClass);
	CreateNative("SaxtonHale_GetAllClassType", FuncNative_GetAllClassType);
	CreateNative("SaxtonHale_CallFunction", FuncNative_CallFunctionClass);
	
	CreateNative("SaxtonHaleBase.CallFunction", FuncNative_CallFunctionClient);
	CreateNative("SaxtonHaleBase.CreateClass", FuncNative_CreateClass);
	CreateNative("SaxtonHaleBase.HasClass", FuncNative_HasClass);
	CreateNative("SaxtonHaleBase.DestroyClass", FuncNative_DestroyClass);
	CreateNative("SaxtonHaleBase.DestroyAllClass", FuncNative_DestroyAllClass);
	CreateNative("SaxtonHaleBase.GetPropInt", FuncNative_GetPropInt);
	CreateNative("SaxtonHaleBase.GetPropFloat", FuncNative_GetPropFloat);
	CreateNative("SaxtonHaleBase.SetPropInt", FuncNative_SetProp);	//Exact same as SetPropFloat
	CreateNative("SaxtonHaleBase.SetPropFloat", FuncNative_SetProp);	//Exact same as SetPropInt
	
	CreateNative("SaxtonHale_HookFunction", FuncNative_HookFunction);
	CreateNative("SaxtonHale_UnhookFunction", FuncNative_UnhookFunction);
	
	CreateNative("SaxtonHale_GetParam", FuncNative_GetParam);
	CreateNative("SaxtonHale_SetParam", FuncNative_SetParam);
	CreateNative("SaxtonHale_GetParamStringLength", FuncNative_GetParamStringLength);
	CreateNative("SaxtonHale_GetParamString", FuncNative_GetParamString);
	CreateNative("SaxtonHale_SetParamString", FuncNative_SetParamString);
	CreateNative("SaxtonHale_GetParamArray", FuncNative_GetParamArray);
	CreateNative("SaxtonHale_SetParamArray", FuncNative_SetParamArray);
}

void FuncNative_Init()
{
	g_aFuncFunctionList = new FuncFunctionList();
}

//SaxtonHaleFunction.SaxtonHaleFunction(const char[] sName, ExecType type, ParamType ...);
public any FuncNative_InitFunction(Handle hPlugin, int iNumParams)
{
	iNumParams -= 2;
	
	if (iNumParams > SP_MAX_EXEC_PARAMS)
		ThrowNativeError(SP_ERROR_NATIVE, "Too many ParamType passed (Found %d, max %d)", iNumParams, SP_MAX_EXEC_PARAMS);
	
	FuncFunction funcFunction;
	GetNativeString(1, funcFunction.sName, sizeof(funcFunction.sName));
	if (g_aFuncFunctionList.GetByName(funcFunction.sName, funcFunction))
		ThrowNativeError(SP_ERROR_NATIVE, "Function (%s) already exists", funcFunction.sName);
	
	funcFunction.hPlugin = hPlugin;
	funcFunction.nExecType = GetNativeCell(2);
	funcFunction.iParamLength = iNumParams;
	
	//Check for dumb plugins passing unsupported ExecType
	if (funcFunction.nExecType < ET_Ignore || funcFunction.nExecType > ET_Hook)
		ThrowNativeError(SP_ERROR_NATIVE, "Unknown ExecType passed (%d)", funcFunction.nExecType);
	
	//Push all ParamType to array
	for (int iParam = 0; iParam < funcFunction.iParamLength; iParam++)
	{
		funcFunction.nParamType[iParam] = GetNativeCellRef(iParam + 3);
		
		//Check for any unsupported params
		switch (funcFunction.nParamType[iParam])
		{
			case Param_Cell, Param_CellByRef, Param_Float, Param_FloatByRef:
			{
			}
			case Param_String:
			{
				funcFunction.nArrayType[iParam] = VSHArrayType_Const;
			}
			case Param_Array:
			{
				funcFunction.nArrayType[iParam] = VSHArrayType_Static;
				funcFunction.iArrayData[iParam] = 1;
			}
			default:
			{
				//Unsupported ParamType
				char sParamTypeName[32];
				if (FuncFunction_GetParamTypeName(funcFunction.nParamType[iParam], sParamTypeName, sizeof(sParamTypeName)))
					ThrowNativeError(SP_ERROR_NATIVE, "Unsupported %s passed (Param %d)", sParamTypeName, iParam+1);
				else
					ThrowNativeError(SP_ERROR_NATIVE, "Unknown ParamType passed (Param %d)", sParamTypeName, iParam+1);
			}
		}
	}
	
	return g_aFuncFunctionList.Add(funcFunction);
}

//void SaxtonHaleFunction.AddParam(ParamType nParamType, SaxtonHaleArrayType nArrayType = VSHArrayType_None, int iArrayData = 0);
public any FuncNative_FunctionAddParam(Handle hPlugin, int iNumParams)
{
	SaxtonHaleFunction nId = GetNativeCell(1);
	
	FuncFunction funcFunction;
	if (!g_aFuncFunctionList.GetById(nId, funcFunction))
		ThrowNativeError(SP_ERROR_NATIVE, "Invalid function id passed (%d)", nId);
	
	int iParam = funcFunction.iParamLength;
	if (iParam >= SP_MAX_EXEC_PARAMS)
		ThrowNativeError(SP_ERROR_NATIVE, "Function reached max params (%d)", SP_MAX_EXEC_PARAMS);
	
	funcFunction.nParamType[iParam] = GetNativeCell(2);
	funcFunction.nArrayType[iParam] = GetNativeCell(3);
	funcFunction.iArrayData[iParam] = GetNativeCell(4);
	
	switch (funcFunction.nParamType[iParam])
	{
		case Param_Cell, Param_CellByRef, Param_Float, Param_FloatByRef:
		{
			if (funcFunction.nArrayType[iParam] != VSHArrayType_None)
			{
				char sParamTypeName[32];
				FuncFunction_GetParamTypeName(funcFunction.nParamType[iParam], sParamTypeName, sizeof(sParamTypeName));
				ThrowNativeError(SP_ERROR_NATIVE, "%s must use VSHArrayType_None", sParamTypeName);
			}
		}
		case Param_String, Param_Array:
		{
			char sParamTypeName[32];
			FuncFunction_GetParamTypeName(funcFunction.nParamType[iParam], sParamTypeName, sizeof(sParamTypeName));
			
			if (funcFunction.nArrayType[iParam] == VSHArrayType_None)
				ThrowNativeError(SP_ERROR_NATIVE, "%s must not use VSHArrayType_None", sParamTypeName);
			else if (funcFunction.nArrayType[iParam] == VSHArrayType_Const && funcFunction.nParamType[iParam] == Param_Array)
				ThrowNativeError(SP_ERROR_NATIVE, "Param_Array must not use VSHArrayType_Const");
			else if (funcFunction.nArrayType[iParam] == VSHArrayType_Static && funcFunction.iArrayData[iParam] <= 0)
				ThrowNativeError(SP_ERROR_NATIVE, "%s must have VSHArrayType_Static size greater than 0 (found %d)", sParamTypeName, funcFunction.iArrayData[iParam]);
			else if (funcFunction.nArrayType[iParam] == VSHArrayType_Dynamic)
			{
				if (funcFunction.iArrayData[iParam] <= 0)
					ThrowNativeError(SP_ERROR_NATIVE, "%s must have VSHArrayType_Dynamic param greater than 0 (found %d)", sParamTypeName, funcFunction.iArrayData[iParam]);
				else if (funcFunction.iArrayData[iParam] > funcFunction.iParamLength)
					ThrowNativeError(SP_ERROR_NATIVE, "%s must have VSHArrayType_Dynamic param less than param count (found %d, max %d)", sParamTypeName, funcFunction.iArrayData[iParam], funcFunction.iParamLength);
				else if (funcFunction.nParamType[funcFunction.iArrayData[iParam]-1] != Param_Cell)
					ThrowNativeError(SP_ERROR_NATIVE, "%s must have VSHArrayType_Dynamic param Param_Cell (param %d)", sParamTypeName, funcFunction.iArrayData[iParam]);
			}
		}
		default:
		{
			//Unsupported ParamType
			char sParamTypeName[32];
			if (FuncFunction_GetParamTypeName(funcFunction.nParamType[iParam], sParamTypeName, sizeof(sParamTypeName)))
				ThrowNativeError(SP_ERROR_NATIVE, "%s is unsupported (Param %d)", sParamTypeName, iParam+1);
			else
				ThrowNativeError(SP_ERROR_NATIVE, "Unknown ParamType passed (Param %d)", sParamTypeName, iParam+1);
		}
	}
	
	funcFunction.iParamLength++;
	g_aFuncFunctionList.SetById(nId, funcFunction);
	return 0;
}

//void SaxtonHaleFunction.SetParam(int iParam, ParamType nParamType, SaxtonHaleArrayType nArrayType = VSHArrayType_None, int iArrayData = 0);
public any FuncNative_FunctionSetParam(Handle hPlugin, int iNumParams)
{
	SaxtonHaleFunction nId = GetNativeCell(1);
	
	FuncFunction funcFunction;
	if (!g_aFuncFunctionList.GetById(nId, funcFunction))
		ThrowNativeError(SP_ERROR_NATIVE, "Invalid function id passed (%d)", nId);
	
	int iParam = GetNativeCell(2);
	if (iParam <= 0)
		ThrowNativeError(SP_ERROR_NATIVE, "Param must be greater than 0 (found %d)", iParam);
	else if (iParam > funcFunction.iParamLength)
		ThrowNativeError(SP_ERROR_NATIVE, "Param must be less than param count (found %d, max %d)", iParam, funcFunction.iParamLength);
	
	iParam--;
	funcFunction.nParamType[iParam] = GetNativeCell(3);
	funcFunction.nArrayType[iParam] = GetNativeCell(4);
	funcFunction.iArrayData[iParam] = GetNativeCell(5);
	
	switch (funcFunction.nParamType[iParam])
	{
		case Param_Cell, Param_CellByRef, Param_Float, Param_FloatByRef:
		{
			if (funcFunction.nArrayType[iParam] != VSHArrayType_None)
			{
				char sParamTypeName[32];
				FuncFunction_GetParamTypeName(funcFunction.nParamType[iParam], sParamTypeName, sizeof(sParamTypeName));
				ThrowNativeError(SP_ERROR_NATIVE, "%s must use VSHArrayType_None", sParamTypeName);
			}
		}
		case Param_String, Param_Array:
		{
			char sParamTypeName[32];
			FuncFunction_GetParamTypeName(funcFunction.nParamType[iParam], sParamTypeName, sizeof(sParamTypeName));
			
			if (funcFunction.nArrayType[iParam] == VSHArrayType_None)
				ThrowNativeError(SP_ERROR_NATIVE, "%s must not use VSHArrayType_None", sParamTypeName);
			else if (funcFunction.nArrayType[iParam] == VSHArrayType_Const && funcFunction.nParamType[iParam] == Param_Array)
				ThrowNativeError(SP_ERROR_NATIVE, "Param_Array must not use VSHArrayType_Const");
			else if (funcFunction.nArrayType[iParam] == VSHArrayType_Static && funcFunction.iArrayData[iParam] <= 0)
				ThrowNativeError(SP_ERROR_NATIVE, "%s must have VSHArrayType_Static size greater than 0 (found %d)", sParamTypeName, funcFunction.iArrayData[iParam]);
			else if (funcFunction.nArrayType[iParam] == VSHArrayType_Dynamic)
			{
				if (funcFunction.iArrayData[iParam] <= 0)
					ThrowNativeError(SP_ERROR_NATIVE, "%s must have VSHArrayType_Dynamic param greater than 0 (found %d)", sParamTypeName, funcFunction.iArrayData[iParam]);
				else if (funcFunction.iArrayData[iParam] > funcFunction.iParamLength)
					ThrowNativeError(SP_ERROR_NATIVE, "%s must have VSHArrayType_Dynamic param less than param count (found %d, max %d)", sParamTypeName, funcFunction.iArrayData[iParam], funcFunction.iParamLength);
				else if (funcFunction.nParamType[funcFunction.iArrayData[iParam]-1] != Param_Cell)
					ThrowNativeError(SP_ERROR_NATIVE, "%s must have VSHArrayType_Dynamic param Param_Cell (param %d)", sParamTypeName, funcFunction.iArrayData[iParam]);
			}
		}
		default:
		{
			//Unsupported ParamType
			char sParamTypeName[32];
			if (FuncFunction_GetParamTypeName(funcFunction.nParamType[iParam], sParamTypeName, sizeof(sParamTypeName)))
				ThrowNativeError(SP_ERROR_NATIVE, "%s is unsupported (Param %d)", sParamTypeName, iParam+1);
			else
				ThrowNativeError(SP_ERROR_NATIVE, "Unknown ParamType passed (Param %d)", sParamTypeName, iParam+1);
		}
	}
	
	g_aFuncFunctionList.SetById(nId, funcFunction);
	return 0;
}

//void SaxtonHale_RegisterClass(const char[] sClass, SaxtonHaleClassType nClassType);
public any FuncNative_RegisterClass(Handle hPlugin, int iNumParams)
{
	char sClass[MAX_TYPE_CHAR];
	GetNativeString(1, sClass, sizeof(sClass));
	
	SaxtonHaleClassType nClassType = GetNativeCell(2);
	if (nClassType == VSHClassType_Core && hPlugin != GetMyHandle())
		ThrowNativeError(SP_ERROR_NATIVE, "VSHClassType_Core passed from non-main plugin");
	
	if (FuncClass_Exists(sClass))
		ThrowNativeError(SP_ERROR_NATIVE, "Methodmap Class (%s) already registered", sClass);
	
	FuncClass_Add(sClass, hPlugin, nClassType);
	return 0;
}

//void SaxtonHale_UnregisterClass(const char[] sClass);
public any FuncNative_UnregisterClass(Handle hPlugin, int iNumParams)
{
	char sClass[MAX_TYPE_CHAR];
	GetNativeString(1, sClass, sizeof(sClass));
	
	if (!FuncClass_Exists(sClass))
		return 0;
	
	SaxtonHaleClassType nClassType = FuncClass_GetType(sClass);
	if (nClassType == VSHClassType_Core)
		ThrowNativeError(SP_ERROR_NATIVE, "Unregister core class (%s) is not allowed", sClass);
	
	FuncClass_Remove(sClass);
	NextBoss_RemoveMulti(sClass);
	return 0;
}

//Handle SaxtonHale_GetPlugin(const char[] sClass);
public any FuncNative_GetPlugin(Handle hPlugin, int iNumParams)
{
	char sType[MAX_TYPE_CHAR];
	GetNativeString(1, sType, sizeof(sType));
	
	return FuncClass_GetPlugin(sType);
}

//ArrayList SaxtonHale_GetAllClass();
public any FuncNative_GetAllClass(Handle hPlugin, int iNumParams)
{
	ArrayList aClass = FuncClass_GetAll();
	
	ArrayList aClone = view_as<ArrayList>(CloneHandle(aClass, hPlugin));
	delete aClass;
	
	return aClone;
}

//ArrayList SaxtonHale_GetAllClassType(SaxtonHaleClassType nClassType);
public any FuncNative_GetAllClassType(Handle hPlugin, int iNumParams)
{
	ArrayList aClass = FuncClass_GetAllType(GetNativeCell(1));
	
	ArrayList aClone = view_as<ArrayList>(CloneHandle(aClass, hPlugin));
	delete aClass;
	
	return aClone;
}

//any SaxtonHale_CallFunction(const char[] sClass, const char[] sFunction, any...);
public any FuncNative_CallFunctionClass(Handle hPlugin, int iNumParams)
{
	char sClass[MAX_TYPE_CHAR];
	GetNativeString(1, sClass, sizeof(sClass));
	if (!FuncClass_Exists(sClass))
		ThrowNativeError(SP_ERROR_NATIVE, "Invalid class name passed (%s)", sClass);
	
	//Get function to call
	FuncFunction funcFunction;
	GetNativeString(2, funcFunction.sName, sizeof(funcFunction.sName));
	if (!g_aFuncFunctionList.GetByName(funcFunction.sName, funcFunction))
		ThrowNativeError(SP_ERROR_NATIVE, "Invalid function name passed (%s)", funcFunction.sName);
	else if (funcFunction.iParamLength >  iNumParams-2)
		ThrowNativeError(SP_ERROR_NATIVE, "Too few param passed (found %d params, expected %d)", iNumParams-2, funcFunction.iParamLength);
	
	SaxtonHaleBase boss = SaxtonHaleBase(0);
	FuncClass_ClientCreate(boss, sClass, false);
	any returnVal = FuncCall_Setup(boss, funcFunction);
	FuncClass_ClientDestroyAllClass(boss, false);
	return returnVal;
}

//any SaxtonHaleBase.CallFunction(const char[] sName, any...);
public any FuncNative_CallFunctionClient(Handle hPlugin, int iNumParams)
{	
	//Get function to call
	FuncFunction funcFunction;
	GetNativeString(2, funcFunction.sName, sizeof(funcFunction.sName));
	if (!g_aFuncFunctionList.GetByName(funcFunction.sName, funcFunction))
		ThrowNativeError(SP_ERROR_NATIVE, "Invalid function name passed (%s)", funcFunction.sName);
	else if (funcFunction.iParamLength >  iNumParams-2)
		ThrowNativeError(SP_ERROR_NATIVE, "Too few param passed (found %d params, expected %d)", iNumParams-2, funcFunction.iParamLength);
	
	return FuncCall_Setup(GetNativeCell(1), funcFunction);
}

//void SaxtonHaleBase.CreateClass(const char[] sClass);
public any FuncNative_CreateClass(Handle hPlugin, int iNumParams)
{
	SaxtonHaleBase boss = GetNativeCell(1);
	
	char sClass[MAX_TYPE_CHAR];
	GetNativeString(2, sClass, sizeof(sClass));
	if (!FuncClass_Exists(sClass))
		ThrowNativeError(SP_ERROR_NATIVE, "Invalid class name passed (%s)", sClass);
	
	FuncClass_ClientCreate(boss, sClass);
	return 0;
}

//void SaxtonHaleBase.HasClass(const char[] sClass);
public any FuncNative_HasClass(Handle hPlugin, int iNumParams)
{
	SaxtonHaleBase boss = GetNativeCell(1);
	
	char sClass[MAX_TYPE_CHAR];
	GetNativeString(2, sClass, sizeof(sClass));
	return FuncClass_ClientHasClass(boss.iClient, sClass);
}

//void SaxtonHaleBase.DestroyClass(const char[] sClass);
public any FuncNative_DestroyClass(Handle hPlugin, int iNumParams)
{
	SaxtonHaleBase boss = GetNativeCell(1);
	
	char sClass[MAX_TYPE_CHAR];
	GetNativeString(2, sClass, sizeof(sClass));
	if (!FuncClass_Exists(sClass))
		ThrowNativeError(SP_ERROR_NATIVE, "Invalid class name passed (%s)", sClass);
	
	FuncClass_ClientDestroyClass(boss, sClass);
	return 0;
}

//void SaxtonHaleBase.DestroyAllClass();
public any FuncNative_DestroyAllClass(Handle hPlugin, int iNumParams)
{
	FuncClass_ClientDestroyAllClass(GetNativeCell(1));
	return 0;
}

//void SaxtonHaleBase.GetPropInt(const char[] sClass, const char[] sProp);
public any FuncNative_GetPropInt(Handle hPlugin, int iNumParams)
{
	int iClient = GetNativeCell(1);
	if (iClient <= 0 || iClient > MaxClients)
		ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index %d", iClient);
	else if (!IsClientInGame(iClient))
		ThrowNativeError(SP_ERROR_NATIVE, "Client index %d is not in game", iClient);
	
	char sClass[MAX_TYPE_CHAR];
	GetNativeString(2, sClass, sizeof(sClass));
	if (!FuncClass_ClientHasClass(iClient, sClass))
		ThrowNativeError(SP_ERROR_NATIVE, "Client index %d does not have class name '%s'", iClient, sClass);
	
	char sProp[MAX_TYPE_CHAR];
	GetNativeString(3, sProp, sizeof(sProp));
	int iValue = 0;
	FuncClass_GetProp(iClient, sClass, sProp, iValue);
	return iValue;
}

//void SaxtonHaleBase.GetPropFloat(const char[] sClass, const char[] sProp);
public any FuncNative_GetPropFloat(Handle hPlugin, int iNumParams)
{
	int iClient = GetNativeCell(1);
	if (iClient <= 0 || iClient > MaxClients)
		ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index %d", iClient);
	else if (!IsClientInGame(iClient))
		ThrowNativeError(SP_ERROR_NATIVE, "Client index %d is not in game", iClient);
	
	char sClass[MAX_TYPE_CHAR];
	GetNativeString(2, sClass, sizeof(sClass));
	if (!FuncClass_ClientHasClass(iClient, sClass))
		ThrowNativeError(SP_ERROR_NATIVE, "Client index %d does not have class name '%s'", iClient, sClass);
	
	char sProp[MAX_TYPE_CHAR];
	GetNativeString(3, sProp, sizeof(sProp));
	float flValue = 0.0;
	FuncClass_GetProp(iClient, sClass, sProp, flValue);
	return flValue;
}

//void SaxtonHaleBase.SetPropInt(const char[] sClass, const char[] sProp, int iVal);
//void SaxtonHaleBase.SetPropFloat(const char[] sClass, const char[] sProp, float flVal);
public any FuncNative_SetProp(Handle hPlugin, int iNumParams)
{
	int iClient = GetNativeCell(1);
	if (iClient <= 0 || iClient > MaxClients)
		ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index %d", iClient);
	else if (!IsClientInGame(iClient))
		ThrowNativeError(SP_ERROR_NATIVE, "Client index %d is not in game", iClient);
	
	char sClass[MAX_TYPE_CHAR];
	GetNativeString(2, sClass, sizeof(sClass));
	if (!FuncClass_ClientHasClass(iClient, sClass))
		ThrowNativeError(SP_ERROR_NATIVE, "Client index %d does not have class name '%s'", iClient, sClass);
	
	char sProp[MAX_TYPE_CHAR];
	GetNativeString(3, sProp, sizeof(sProp));
	FuncClass_SetProp(iClient, sClass, sProp, GetNativeCell(4));
	return 0;
}

//void SaxtonHale_HookFunction(const char[] sName, SaxtonHaleHookCallback callback, SaxtonHaleHookType = VSHHookType_Post);
public any FuncNative_HookFunction(Handle hPlugin, int iNumParams)
{
	char sFunction[MAX_TYPE_CHAR];
	GetNativeString(1, sFunction, sizeof(sFunction));
	FuncHook_Add(sFunction, hPlugin, GetNativeFunction(2), GetNativeCell(3));
	return 0;
}

//void SaxtonHale_UnhookFunction(const char[] sName, SaxtonHaleHookCallback callback, SaxtonHaleHookType = VSHHookType_Post);
public any FuncNative_UnhookFunction(Handle hPlugin, int iNumParams)
{
	char sFunction[MAX_TYPE_CHAR];
	GetNativeString(1, sFunction, sizeof(sFunction));
	FuncHook_Remove(sFunction, hPlugin, GetNativeFunction(2), GetNativeCell(3));
	return 0;
}

//any SaxtonHale_GetParam(int iParam);
public any FuncNative_GetParam(Handle hPlugin, int iNumParams)
{
	//Get param + checks
	FuncStack funcStack;
	ParamType nParamType;
	int iParam = FuncNative_GetFuncStack(funcStack, nParamType);
	
	//Check for non-cell ParamType
	if (nParamType != Param_Cell
		&& nParamType != Param_CellByRef
		&& nParamType != Param_Float
		&& nParamType != Param_FloatByRef)
	{
		char sParamTypeName[32];
		FuncFunction_GetParamTypeName(nParamType, sParamTypeName, sizeof(sParamTypeName));
		ThrowNativeError(SP_ERROR_NATIVE, "Unable to get cell from %s (Function %s, param %d)", sParamTypeName, funcStack.sFunction, iParam);
	}
	
	//Return value
	return funcStack.cell[iParam-1];
}

//void SaxtonHale_SetParam(int iParam, any value);
public any FuncNative_SetParam(Handle hPlugin, int iNumParams)
{
	//Get param + checks
	FuncStack funcStack;
	ParamType nParamType;
	int iParam = FuncNative_GetFuncStack(funcStack, nParamType);
	
	//Check for non-cell ref ParamType
	if (nParamType != Param_CellByRef && nParamType != Param_FloatByRef)
	{
		char sParamTypeName[32];
		FuncFunction_GetParamTypeName(nParamType, sParamTypeName, sizeof(sParamTypeName));
		ThrowNativeError(SP_ERROR_NATIVE, "Unable to set cell from %s (Function %s, param %d)", sParamTypeName, funcStack.sFunction, iParam);
	}
	
	//Get and set value
	funcStack.cell[iParam-1] = GetNativeCell(2);
	FuncStack_Set(funcStack);
	return 0;
}

//int SaxtonHale_GetParamStringLength(int iParam);
public any FuncNative_GetParamStringLength(Handle hPlugin, int iNumParams)
{
	//Get param + checks
	FuncStack funcStack;
	ParamType nParamType;
	int iParam = FuncNative_GetFuncStack(funcStack, nParamType);
	
	//Check for non-string ParamType
	if (nParamType != Param_String)
	{
		char sParamTypeName[32];
		FuncFunction_GetParamTypeName(nParamType, sParamTypeName, sizeof(sParamTypeName));
		ThrowNativeError(SP_ERROR_NATIVE, "Unable to get string length from %s (Function %s, param %d)", sParamTypeName, funcStack.sFunction, iParam);
	}
	
	//return string length
	return funcStack.iArrayLength[iParam-1];
}

//void SaxtonHale_GetParamString(int iParam, char[] value);
public any FuncNative_GetParamString(Handle hPlugin, int iNumParams)
{
	//Get param + checks
	FuncStack funcStack;
	ParamType nParamType;
	int iParam = FuncNative_GetFuncStack(funcStack, nParamType);
	
	//Check for non-string ParamType
	if (nParamType != Param_String)
	{
		char sParamTypeName[32];
		FuncFunction_GetParamTypeName(nParamType, sParamTypeName, sizeof(sParamTypeName));
		ThrowNativeError(SP_ERROR_NATIVE, "Unable to get string from %s (Function %s, param %d)", sParamTypeName, funcStack.sFunction, iParam);
	}
	
	//Get and set string
	int iLength = GetNativeCell(3);
	char[] sBuffer = new char[iLength];
	funcStack.GetArray(iParam, view_as<any>(sBuffer));
	SetNativeString(2, sBuffer, iLength);
	return 0;
}

//void SaxtonHale_SetParamString(int iParam, char[] value);
public any FuncNative_SetParamString(Handle hPlugin, int iNumParams)
{
	//Get param + checks
	FuncStack funcStack;
	ParamType nParamType;
	int iParam = FuncNative_GetFuncStack(funcStack, nParamType);
	
	//Check for non-string ParamType
	if (nParamType != Param_String)
	{
		char sParamTypeName[32];
		FuncFunction_GetParamTypeName(nParamType, sParamTypeName, sizeof(sParamTypeName));
		ThrowNativeError(SP_ERROR_NATIVE, "Unable to set string from %s (Function %s, param %d)", sParamTypeName, funcStack.sFunction, iParam);
	}
	
	//Get and set string
	int iLength;
	GetNativeStringLength(2, iLength);
	
	iLength++;
	char[] sBuffer = new char[iLength];
	GetNativeString(2, sBuffer, iLength);
	funcStack.SetArray(iParam, view_as<any>(sBuffer));
	return 0;
}

//void SaxtonHale_GetParamArray(int iParam, any[] value);
public any FuncNative_GetParamArray(Handle hPlugin, int iNumParams)
{
	//Get param + checks
	FuncStack funcStack;
	ParamType nParamType;
	int iParam = FuncNative_GetFuncStack(funcStack, nParamType);
	
	//Check for non-array ParamType
	if (nParamType != Param_Array)
	{
		char sParamTypeName[32];
		FuncFunction_GetParamTypeName(nParamType, sParamTypeName, sizeof(sParamTypeName));
		ThrowNativeError(SP_ERROR_NATIVE, "Unable to get array from %s (Function %s, param %d)", sParamTypeName, funcStack.sFunction, iParam);
	}
	
	//Get and set array
	int iLength = GetNativeCell(3);
	any[] buffer = new any[iLength];
	funcStack.GetArray(iParam, buffer);
	SetNativeArray(2, buffer, iLength);
	return 0;
}

//void SaxtonHale_SetParamArray(int iParam, any[] value);
public any FuncNative_SetParamArray(Handle hPlugin, int iNumParams)
{
	//Get param + checks
	FuncStack funcStack;
	ParamType nParamType;
	int iParam = FuncNative_GetFuncStack(funcStack, nParamType);
	
	//Check for non-array ParamType
	if (nParamType != Param_Array)
	{
		char sParamTypeName[32];
		FuncFunction_GetParamTypeName(nParamType, sParamTypeName, sizeof(sParamTypeName));
		ThrowNativeError(SP_ERROR_NATIVE, "Unable to set array from %s (Function %s, param %d)", sParamTypeName, funcStack.sFunction, iParam);
	}
	
	//Get and set array
	int iLength = funcStack.iArrayLength[iParam-1];
	any[] buffer = new any[iLength];
	GetNativeArray(2, buffer, iLength);
	funcStack.SetArray(iParam, buffer);
	return 0;
}

//----------

int FuncNative_GetFuncStack(FuncStack funcStack, ParamType &nParamType)
{
	//Just to save clutter from not copypasting from other natives
	
	if (!FuncStack_Get(funcStack))
		ThrowNativeError(SP_ERROR_NATIVE, "Native called while outside of hook");
	
	int iParam = GetNativeCell(1);
	if (iParam <= 0)
		ThrowNativeError(SP_ERROR_NATIVE, "Param entered must be greater than 0 (Found %d)", iParam);
	
	if (iParam > funcStack.iParamLength)
		ThrowNativeError(SP_ERROR_NATIVE, "Param entered outside of bounds (Found %d, max %d)", iParam, funcStack.iParamLength);
	
	nParamType = funcStack.nParamType[iParam - 1];
	return iParam;
}

void FuncNative_ClearUnloadedPlugin(Handle hPlugin)
{
	g_aFuncFunctionList.ClearUnloadedPlugin(hPlugin);
}