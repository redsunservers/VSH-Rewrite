//Macro to register every properties to set and get
#define NATIVE_PROPERTY_REGISTER(%1,%2)\
Format(sBuffer, sizeof(sBuffer), "SaxtonHaleBase.%s.set", %1); \
CreateNative(sBuffer, FuncNative_Property_%2_Set); \
Format(sBuffer, sizeof(sBuffer), "SaxtonHaleBase.%s.get", %1); \
CreateNative(sBuffer, FuncNative_Property_%2_Get);

static FuncFunctionId g_mFuncFunctionId;

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
	CreateNative("SaxtonHale_RegisterMultiBoss", FuncNative_RegisterMultiBoss);
	
	CreateNative("SaxtonHaleBase.CallFunction", FuncNative_CallFunction);
	
	CreateNative("SaxtonHale_HookFunction", FuncNative_HookFunction);
	CreateNative("SaxtonHale_UnhookFunction", FuncNative_UnhookFunction);
	
	CreateNative("SaxtonHale_GetParam", FuncNative_GetParam);
	CreateNative("SaxtonHale_SetParam", FuncNative_SetParam);
	CreateNative("SaxtonHale_GetParamStringLength", FuncNative_GetParamStringLength);
	CreateNative("SaxtonHale_GetParamString", FuncNative_GetParamString);
	CreateNative("SaxtonHale_SetParamString", FuncNative_SetParamString);
	CreateNative("SaxtonHale_GetParamArray", FuncNative_GetParamArray);
	CreateNative("SaxtonHale_SetParamArray", FuncNative_SetParamArray);
	
	// Deprecated functions
	CreateNative("SaxtonHale_InitFunction", FuncNative_InitFunction);
	CreateNative("SaxtonHale_RegisterBoss", FuncNative_RegisterBoss);
	CreateNative("SaxtonHale_UnregisterBoss", FuncNative_UnregisterBoss);
	CreateNative("SaxtonHale_RegisterModifiers", FuncNative_RegisterModifiers);
	CreateNative("SaxtonHale_UnregisterModifiers", FuncNative_UnregisterModifiers);
	CreateNative("SaxtonHale_RegisterAbility", FuncNative_RegisterAbility);
	CreateNative("SaxtonHale_UnregisterAbility", FuncNative_UnregisterAbility);
	
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
	NATIVE_PROPERTY_REGISTER("flWeighDownTimer",flWeighDownTimer)
	NATIVE_PROPERTY_REGISTER("flWeighDownForce",flWeighDownForce)
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

void FuncNative_Init()
{
	g_mFuncFunctionId = new FuncFunctionId();
}

//SaxtonHaleFunction.SaxtonHaleFunction(const char[] sName, ExecType type, ParamType ...);
public any FuncNative_InitFunction(Handle hPlugin, int iNumParams)
{
	iNumParams -= 2;
	
	if (iNumParams > SP_MAX_EXEC_PARAMS)
		ThrowNativeError(SP_ERROR_NATIVE, "Too many ParamType passed (Found %d, max %d)", iNumParams, SP_MAX_EXEC_PARAMS);
	
	char sFunction[MAX_TYPE_CHAR];
	GetNativeString(1, sFunction, sizeof(sFunction));
	
	FuncFunction funcFunction;
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
	
	SaxtonHaleFunction nId = g_mFuncFunctionId.AddStruct(sFunction, funcFunction);
	if (nId == view_as<SaxtonHaleFunction>(-1))
		ThrowNativeError(SP_ERROR_NATIVE, "Function (%s) already exists", sFunction);
	
	return nId;
}

//void SaxtonHaleFunction.AddParam(ParamType nParamType, SaxtonHaleArrayType nArrayType = VSHArrayType_None, int iArrayData = 0);
public any FuncNative_FunctionAddParam(Handle hPlugin, int iNumParams)
{
	SaxtonHaleFunction nId = GetNativeCell(1);
	
	FuncFunction funcFunction;
	if (!g_mFuncFunctionId.GetStruct(nId, funcFunction))
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
	g_mFuncFunctionId.SetStruct(nId, funcFunction);
}

//void SaxtonHaleFunction.SetParam(int iParam, ParamType nParamType, SaxtonHaleArrayType nArrayType = VSHArrayType_None, int iArrayData = 0);
public any FuncNative_FunctionSetParam(Handle hPlugin, int iNumParams)
{
	SaxtonHaleFunction nId = GetNativeCell(1);
	
	FuncFunction funcFunction;
	if (!g_mFuncFunctionId.GetStruct(nId, funcFunction))
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
	
	g_mFuncFunctionId.SetStruct(nId, funcFunction);
}

//void SaxtonHale_RegisterClass(const char[] sClass, SaxtonHaleClassType nClassType);
public any FuncNative_RegisterClass(Handle hPlugin, int iNumParams)
{
	char sClass[MAX_TYPE_CHAR];
	GetNativeString(1, sClass, sizeof(sClass));
	
	SaxtonHaleClassType nClassType = GetNativeCell(2);
	if (nClassType == VSHClassType_Core && hPlugin != GetMyHandle())
		ThrowNativeError(SP_ERROR_NATIVE, "VSHClassType_Core passed from non-main plugin");
	
	if (!FuncClass_Register(sClass, hPlugin, nClassType))
		ThrowNativeError(SP_ERROR_NATIVE, "Methodmap Class (%s) already registered", sClass);
	
	switch (nClassType)
	{
		case VSHClassType_Boss: MenuBoss_AddInfoBoss(sClass);
		case VSHClassType_Modifier: MenuBoss_AddInfoModifiers(sClass);
	}
}

//void SaxtonHale_UnregisterClass(const char[] sClass);
public any FuncNative_UnregisterClass(Handle hPlugin, int iNumParams)
{
	char sClass[MAX_TYPE_CHAR];
	GetNativeString(1, sClass, sizeof(sClass));
	
	if (!FuncClass_Exists(sClass))
		return;
	
	SaxtonHaleClassType nClassType = FuncClass_GetType(sClass);
	if (nClassType == VSHClassType_Core)
		ThrowNativeError(SP_ERROR_NATIVE, "Unregister core class (%s) is not allowed", sClass);
	
	FuncClass_Unregister(sClass);
	MenuBoss_RemoveInfo(sClass);
	NextBoss_RemoveMulti(sClass);
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

//void SaxtonHale_RegisterMultiBoss(const char[] ...);
public any FuncNative_RegisterMultiBoss(Handle hPlugin, int iNumParams)
{
	if (iNumParams < 2)
		ThrowNativeError(SP_ERROR_NATIVE, "There must be atleast 2 bosses for multiboss");
	
	ArrayList aBosses = new ArrayList(MAX_TYPE_CHAR);
	for (int i = 1; i <= iNumParams; i++)
	{
		char sClass[MAX_TYPE_CHAR];
		GetNativeString(i, sClass, sizeof(sClass));
		aBosses.PushString(sClass);
	}
	
	NextBoss_AddMulti(aBosses);
}

//any SaxtonHaleBase.CallFunction(const char[] sName, any...);
public any FuncNative_CallFunction(Handle hPlugin, int iNumParams)
{
	SaxtonHaleBase boss = GetNativeCell(1);
	
	char sFunction[MAX_TYPE_CHAR];
	GetNativeString(2, sFunction, sizeof(sFunction));
	
	//Get function to call
	FuncFunction funcFunction;
	if (!FuncFunction_Get(sFunction, funcFunction))
		ThrowNativeError(SP_ERROR_NATIVE, "Invalid function name passed (%s)", sFunction);
	else if (funcFunction.iParamLength >  iNumParams-2)
		ThrowNativeError(SP_ERROR_NATIVE, "Too few param passed (found %d params, expected %d)", iNumParams-2, funcFunction.iParamLength);
	
	//Create stack
	FuncStack funcStack;
	Format(funcStack.sFunction, sizeof(funcStack.sFunction), sFunction);
	funcStack.nExecType = funcFunction.nExecType;
	funcStack.nParamType = funcFunction.nParamType;
	
	//Fill params
	for (int iParam = 1; iParam <= funcFunction.iParamLength; iParam++)
	{
		switch (funcStack.nParamType[iParam-1])
		{
			case Param_Cell, Param_CellByRef, Param_Float, Param_FloatByRef:	// ... (Param_VarArgs) is always ByRef
			{
				funcStack.PushCell(GetNativeCellRef(iParam+2), funcStack.nParamType[iParam-1]);
			}
			case Param_String, Param_Array:
			{
				int iLength;
				
				switch (funcFunction.nArrayType[iParam-1])
				{
					case VSHArrayType_Const:
					{
						GetNativeStringLength(iParam+2, iLength);
						iLength++;
					}
					case VSHArrayType_Static:
					{
						iLength = funcFunction.iArrayData[iParam-1];
					}
					case VSHArrayType_Dynamic:
					{
						iLength = GetNativeCellRef(funcFunction.iArrayData[iParam-1]+2);
						if (iLength <= 0)
							ThrowNativeError(SP_ERROR_NATIVE, "Array size must be greater than 0 (param %d, found %d)", iParam, iLength);
					}
				}
				
				if (funcStack.nParamType[iParam-1] == Param_String)
				{
					char[] sBuffer = new char[iLength];
					int iError = GetNativeString(iParam+2, sBuffer, iLength);
					if (iError != SP_ERROR_NONE)
						ThrowNativeError(SP_ERROR_NATIVE, "Unable to get string value (param %d, error %d)", iParam, iError);
					
					funcStack.PushArray(view_as<any>(sBuffer), iLength, Param_String);
				}
				else if (funcStack.nParamType[iParam-1] == Param_Array)
				{
					any[] buffer = new any[iLength];
					int iError = GetNativeArray(iParam+2, buffer, iLength);
					if (iError != SP_ERROR_NONE)
						ThrowNativeError(SP_ERROR_NATIVE, "Unable to get array value (param %d, error %d)", iParam, iError);
					
					funcStack.PushArray(buffer, iLength, Param_Array);
				}
			}
		}
	}
	
	//Start stack, call functions, then erase stack
	FuncStack_Push(funcStack);
	FuncCall_Start(boss, funcStack);
	FuncStack_Erase();
	
	//Set ref native values
	for (int iParam = 1; iParam <= funcFunction.iParamLength; iParam++)
	{
		switch (funcStack.nParamType[iParam-1])
		{
			case Param_CellByRef, Param_FloatByRef:
			{
				SetNativeCellRef(iParam+2, funcStack.GetCell(iParam));
			}
			case Param_String:
			{
				if (funcFunction.nArrayType[iParam-1] == VSHArrayType_Const)
					continue;
				
				int iLength = funcStack.iArrayLength[iParam-1];
				char[] sBuffer = new char[iLength];
				funcStack.GetArray(iParam, view_as<any>(sBuffer));
				
				int iError = SetNativeString(iParam+2, sBuffer, iLength);
				if (iError != SP_ERROR_NONE)
					ThrowNativeError(SP_ERROR_NATIVE, "Unable to return string value (param %d, error code %d)", iParam, iError);
			}
			case Param_Array:
			{
				int iLength = funcStack.iArrayLength[iParam-1];
				any[] buffer = new any[iLength];
				funcStack.GetArray(iParam, buffer);
				
				int iError = SetNativeArray(iParam+2, buffer, iLength);
				if (iError != SP_ERROR_NONE)
					ThrowNativeError(SP_ERROR_NATIVE, "Unable to return array value (param %d, error code %d)", iParam, iError);
			}
		}
	}
	
	//Free the handle memory and return value
	funcStack.Delete();
	return funcStack.returnValue;
}

//void SaxtonHale_HookFunction(const char[] sName, SaxtonHaleHookCallback callback, SaxtonHaleHookType = VSHHookType_Post);
public any FuncNative_HookFunction(Handle hPlugin, int iNumParams)
{
	char sFunction[MAX_TYPE_CHAR];
	GetNativeString(1, sFunction, sizeof(sFunction));
	SaxtonHaleHookCallback callback = view_as<SaxtonHaleHookCallback>(GetNativeFunction(2));
	SaxtonHaleHookMode nHookMode = GetNativeCell(3);
	
	FuncHook_Add(sFunction, hPlugin, callback, nHookMode);
}

//void SaxtonHale_UnhookFunction(const char[] sName, SaxtonHaleHookCallback callback, SaxtonHaleHookType = VSHHookType_Post);
public any FuncNative_UnhookFunction(Handle hPlugin, int iNumParams)
{
	char sFunction[MAX_TYPE_CHAR];
	GetNativeString(1, sFunction, sizeof(sFunction));
	SaxtonHaleHookCallback callback = view_as<SaxtonHaleHookCallback>(GetNativeFunction(2));
	SaxtonHaleHookMode nHookMode = GetNativeCell(3);
	
	FuncHook_Remove(sFunction, hPlugin, callback, nHookMode);
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
}

/**
 * Deprecated functions
 */

//void SaxtonHale_RegisterBoss(const char[] ...);
public any FuncNative_RegisterBoss(Handle hPlugin, int iNumParams)
{
	//TODO multiboss support
	char sClass[MAX_TYPE_CHAR];
	GetNativeString(1, sClass, sizeof(sClass));
	SaxtonHale_RegisterClass(sClass, VSHClassType_Boss);
}

//void SaxtonHale_UnregisterBoss(const char[] sBossType);
public any FuncNative_UnregisterBoss(Handle hPlugin, int iNumParams)
{
	//TODO multiboss support
	char sClass[MAX_TYPE_CHAR];
	GetNativeString(1, sClass, sizeof(sClass));
	SaxtonHale_UnregisterClass(sClass);
}
 
//void SaxtonHale_RegisterModifiers(const char[] sModifiersType);
public any FuncNative_RegisterModifiers(Handle hPlugin, int iNumParams)
{
	char sClass[MAX_TYPE_CHAR];
	GetNativeString(1, sClass, sizeof(sClass));
	SaxtonHale_RegisterClass(sClass, VSHClassType_Modifier);
}

//void SaxtonHale_UnregisterModifiers(const char[] sModifiersType);
public any FuncNative_UnregisterModifiers(Handle hPlugin, int iNumParams)
{
	char sClass[MAX_TYPE_CHAR];
	GetNativeString(1, sClass, sizeof(sClass));
	SaxtonHale_UnregisterClass(sClass);
}

//void SaxtonHale_RegisterAbility(const char[] sAbilityType);
public any FuncNative_RegisterAbility(Handle hPlugin, int iNumParams)
{
	char sClass[MAX_TYPE_CHAR];
	GetNativeString(1, sClass, sizeof(sClass));
	SaxtonHale_RegisterClass(sClass, VSHClassType_Ability);
}

//void SaxtonHale_UnregisterAbility(const char[] sAbilityType);
public any FuncNative_UnregisterAbility(Handle hPlugin, int iNumParams)
{
	char sClass[MAX_TYPE_CHAR];
	GetNativeString(1, sClass, sizeof(sClass));
	SaxtonHale_UnregisterClass(sClass);
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

//Macro to setup natives for every properties
#define NATIVE_PROPERTY(%1) \
static any g_clientBoss%1[TF_MAXPLAYERS+1]; \
public any FuncNative_Property_%1_Set(Handle hPlugin, int iNumParams) \
{ \
	g_clientBoss%1[GetNativeCell(1)] = GetNativeCell(2); \
} \
public any FuncNative_Property_%1_Get(Handle hPlugin, int iNumParams) \
{ \
	return g_clientBoss%1[GetNativeCell(1)]; \
}

NATIVE_PROPERTY(bValid)
NATIVE_PROPERTY(bModifiers)
NATIVE_PROPERTY(bMinion)
NATIVE_PROPERTY(bSuperRage)
NATIVE_PROPERTY(bModel)
NATIVE_PROPERTY(bCanBeHealed)
NATIVE_PROPERTY(flSpeed)
NATIVE_PROPERTY(flSpeedMult)
NATIVE_PROPERTY(flEnvDamageCap)
NATIVE_PROPERTY(flWeighDownTimer)
NATIVE_PROPERTY(flWeighDownForce)
NATIVE_PROPERTY(flGlowTime)
NATIVE_PROPERTY(flRageLastTime)
NATIVE_PROPERTY(flMaxRagePercentage)
NATIVE_PROPERTY(flHealthMultiplier)
NATIVE_PROPERTY(iMaxHealth)
NATIVE_PROPERTY(iBaseHealth)
NATIVE_PROPERTY(iHealthPerPlayer)
NATIVE_PROPERTY(iRageDamage)
NATIVE_PROPERTY(iMaxRageDamage)
NATIVE_PROPERTY(nClass)