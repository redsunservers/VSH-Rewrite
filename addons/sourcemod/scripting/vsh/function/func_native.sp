//Macro to register every properties to set and get
#define NATIVE_PROPERTY_REGISTER(%1,%2)\
Format(sBuffer, sizeof(sBuffer), "SaxtonHaleBase.%s.set", %1); \
CreateNative(sBuffer, FuncNative_Property_%2_Set); \
Format(sBuffer, sizeof(sBuffer), "SaxtonHaleBase.%s.get", %1); \
CreateNative(sBuffer, FuncNative_Property_%2_Get);

void FuncNative_AskLoad()
{
	CreateNative("SaxtonHale_InitFunction", FuncNative_InitFunction);
	CreateNative("SaxtonHale_RegisterClass", FuncNative_RegisterClass);
	CreateNative("SaxtonHale_UnregisterClass", FuncNative_UnregisterClass);
	CreateNative("SaxtonHale_GetPlugin", FuncNative_GetPlugin);
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

//void SaxtonHale_InitFunction(const char[] sName, ExecType type, ParamType ...);
public any FuncNative_InitFunction(Handle hPlugin, int iNumParams)
{
	iNumParams -= 2;
	
	if (iNumParams > SP_MAX_EXEC_PARAMS)
		ThrowNativeError(SP_ERROR_NATIVE, "Too many ParamType passed (Found %d, max %d)", iNumParams, SP_MAX_EXEC_PARAMS);
	
	char sFunction[MAX_TYPE_CHAR];
	GetNativeString(1, sFunction, sizeof(sFunction));
	ExecType nExecType = GetNativeCell(2);
	
	//Check for dumb plugins passing unsupported ExecType
	if (nExecType < ET_Ignore || nExecType > ET_Hook)
		ThrowNativeError(SP_ERROR_NATIVE, "Unknown ExecType passed (%d)", nExecType);
	
	//Push all ParamType to array
	ParamType nParamType[SP_MAX_EXEC_PARAMS];
	bool bDynamicArray = false;
	
	for (int iParam = 0; iParam < iNumParams; iParam++)
	{
		nParamType[iParam] = GetNativeCellRef(iParam + 3);
		
		//Check for any unsupported params
		static const ParamType nAllowedType[] = {
			Param_Cell,
			Param_CellByRef,
			Param_Float,
			Param_FloatByRef,
			Param_String,
			Param_StringByRef,
			Param_Array,
			Param_Vector,
			Param_Color
		};
		
		bool bFound = false;
		for (int i = 0; i < sizeof(nAllowedType); i++)
		{
			if (nParamType[iParam] == nAllowedType[i])
			{
				bFound = true;
				break;
			}
		}
		
		if (!bFound)
		{
			char sParamTypeName[32];
			if (FuncFunction_GetParamTypeName(nParamType[iParam], sParamTypeName, sizeof(sParamTypeName)))
				ThrowNativeError(SP_ERROR_NATIVE, "Unsupported %s passed (Param %d)", sParamTypeName, iParam+1);
			else
				ThrowNativeError(SP_ERROR_NATIVE, "Unknown ParamType passed (Param %d)", sParamTypeName, iParam+1);
		}
		
		//If previous type is dynamic array, check if this is cell
		if (bDynamicArray && nParamType[iParam] != Param_Cell && nParamType[iParam] != Param_CellByRef)
		{
			char sParamTypeName1[32], sParamTypeName2[32];
			FuncFunction_GetParamTypeName(nParamType[iParam], sParamTypeName1, sizeof(sParamTypeName1));
			FuncFunction_GetParamTypeName(nParamType[iParam-1], sParamTypeName2, sizeof(sParamTypeName2));
			ThrowNativeError(SP_ERROR_NATIVE, "Expected Param_Cell or Param_CellByRef, but found %s (Param %d) for %s (Param %d)", sParamTypeName1, iParam+1, sParamTypeName2, iParam-1);
		}
		
		bDynamicArray = nParamType[iParam] == Param_StringByRef || nParamType[iParam] == Param_Array;
	}
	
	//Check for dynamic array length but at end of params
	if (bDynamicArray)
	{
		char sParamTypeName[32];
		FuncFunction_GetParamTypeName(nParamType[iNumParams-1], sParamTypeName, sizeof(sParamTypeName));
		ThrowNativeError(SP_ERROR_NATIVE, "Expected Param_Cell or Param_CellByRef at end of param for %s (Param %d)", sParamTypeName, iNumParams-1);
	}
	
	if (!FuncFunction_Register(sFunction, nExecType, nParamType, iNumParams))
		ThrowNativeError(SP_ERROR_NATIVE, "Function (%s) already exists", sFunction);
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

//void SaxtonHale_RegisterMultiBoss(const char[] ...);
public any FuncNative_RegisterMultiBoss(Handle hPlugin, int iNumParams)
{
	//TODO
}

//any SaxtonHaleBase.CallFunction(const char[] sName, any...);
public any FuncNative_CallFunction(Handle hPlugin, int iNumParams)
{
	SaxtonHaleBase boss = GetNativeCell(1);
	
	char sFunction[MAX_TYPE_CHAR];
	GetNativeString(2, sFunction, sizeof(sFunction));
	
	ParamType nParamType[SP_MAX_EXEC_PARAMS];
	int iSize = FuncFunction_GetParamType(sFunction, nParamType);
	if (iSize == -1)
		ThrowNativeError(SP_ERROR_NATIVE, "Invalid function name passed (%s)", sFunction);
	
	if (iSize > iNumParams-2)
		ThrowNativeError(SP_ERROR_NATIVE, "Too few param passed (Found %d params, expected %d)", iNumParams-2, iSize);
	
	//Create stack
	FuncStack funcStack;
	Format(funcStack.sFunction, sizeof(funcStack.sFunction), sFunction);
	funcStack.nExecType = FuncFunction_GetExecType(sFunction);
	
	//Fill params
	for (int iParam = 1; iParam <= iSize; iParam++)
	{
		switch (nParamType[iParam-1])
		{
			case Param_Cell, Param_CellByRef, Param_Float, Param_FloatByRef:	// ... (Param_VarArgs) is always ByRef
			{
				funcStack.PushCell(GetNativeCellRef(iParam+2), nParamType[iParam-1]);
			}
			case Param_String:
			{
				int iLength;
				int iError = GetNativeStringLength(iParam+2, iLength);
				if (iError != SP_ERROR_NONE)
					ThrowNativeError(SP_ERROR_NATIVE, "Unable to get string value (param %d, error code %d)", iParam, iError);
				
				char[] sBuffer = new char[iLength];
				GetNativeString(iParam+2, sBuffer, iLength);
				funcStack.PushArray(view_as<any>(sBuffer), iLength, Param_String);
			}
			case Param_StringByRef:
			{
				int iLength = GetNativeCellRef(iParam+3);	//Get length of array from next param
				
				char[] sBuffer = new char[iLength];
				int iError = GetNativeString(iParam+2, sBuffer, iLength);
				if (iError != SP_ERROR_NONE)
					ThrowNativeError(SP_ERROR_NATIVE, "Unable to get string value (param %d, error code %d)", iParam, iError);
				
				funcStack.PushArray(view_as<any>(sBuffer), iLength, Param_StringByRef);
			}
			case Param_Array:	//Dynamic array
			{
				int iLength = GetNativeCellRef(iParam+3);	//Get length of array from next param
				if (iLength <= 0)
					ThrowNativeError(SP_ERROR_NATIVE, "Dynamic array size must be more than 0 (array param %d, length param %d)", iParam+3, iParam+4);
				
				any[] buffer = new any[iLength];
				int iError = GetNativeArray(iParam+2, buffer, iLength);
				if (iError != SP_ERROR_NONE)
					ThrowNativeError(SP_ERROR_NATIVE, "Unable to get dynamic array value (param %d, error code %d)", iParam, iError);
				
				funcStack.PushArray(buffer, iLength, Param_Array);
			}
			case Param_Vector:	//Static array with size 3
			{
				any buffer[3];
				int iError = GetNativeArray(iParam+2, buffer, sizeof(buffer));
				if (iError != SP_ERROR_NONE)
					ThrowNativeError(SP_ERROR_NATIVE, "Unable to get vector array value (param %d, error code %d)", iParam, iError);
				
				funcStack.PushVector(buffer);
			}
			case Param_Color:	//Static array with size 4
			{
				any buffer[4];
				int iError = GetNativeArray(iParam+2, buffer, sizeof(buffer));
				if (iError != SP_ERROR_NONE)
					ThrowNativeError(SP_ERROR_NATIVE, "Unable to get color array value (param %d, error code %d)", iParam, iError);
				
				funcStack.PushColor(buffer);
			}
		}
	}
	
	//Start stack, call functions, then erase stack
	FuncStack_Push(funcStack);
	FuncCall_Start(boss, funcStack);
	FuncStack_Erase();
	
	//Set ref native values
	for (int iParam = 1; iParam <= iSize; iParam++)
	{
		switch (nParamType[iParam-1])
		{
			case Param_CellByRef, Param_FloatByRef:
			{
				SetNativeCellRef(iParam+2, funcStack.GetCell(iParam));
			}
			case Param_StringByRef:
			{
				int iLength = funcStack.GetArrayLength(iParam);
				char[] sBuffer = new char[iLength];
				funcStack.GetArray(iParam, view_as<any>(sBuffer));
				
				int iError = SetNativeString(iParam+2, sBuffer, iLength);
				if (iError != SP_ERROR_NONE)
					ThrowNativeError(SP_ERROR_NATIVE, "Unable to return string value (param %d, error code %d)", iParam, iError);
			}
			case Param_Array:	//Dynamic array
			{
				int iLength = funcStack.GetArrayLength(iParam);
				any[] buffer = new any[iLength];
				funcStack.GetArray(iParam, buffer);
				
				int iError = SetNativeArray(iParam+2, buffer, iLength);
				if (iError != SP_ERROR_NONE)
					ThrowNativeError(SP_ERROR_NATIVE, "Unable to return dynamic array value (param %d, error code %d)", iParam, iError);
			}
			case Param_Vector:	//Static array with size 3
			{
				any buffer[3];
				funcStack.GetVector(iParam, buffer);
				
				int iError = SetNativeArray(iParam+2, buffer, sizeof(buffer));
				if (iError != SP_ERROR_NONE)
					ThrowNativeError(SP_ERROR_NATIVE, "Unable to return vector array value (param %d, error code %d)", iParam, iError);
			}
			case Param_Color:	//Static array with size 4
			{
				any buffer[4];
				funcStack.GetColor(iParam, buffer);
				
				int iError = SetNativeArray(iParam+2, buffer, sizeof(buffer));
				if (iError != SP_ERROR_NONE)
					ThrowNativeError(SP_ERROR_NATIVE, "Unable to return color array value (param %d, error code %d)", iParam, iError);
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
	if (nParamType != Param_String && nParamType != Param_StringByRef)
	{
		char sParamTypeName[32];
		FuncFunction_GetParamTypeName(nParamType, sParamTypeName, sizeof(sParamTypeName));
		ThrowNativeError(SP_ERROR_NATIVE, "Unable to get string from %s (Function %s, param %d)", sParamTypeName, funcStack.sFunction, iParam);
	}
	
	//return string length
	return funcStack.GetArrayLength(iParam);
}

//void SaxtonHale_GetParamString(int iParam, char[] value);
public any FuncNative_GetParamString(Handle hPlugin, int iNumParams)
{
	//Get param + checks
	FuncStack funcStack;
	ParamType nParamType;
	int iParam = FuncNative_GetFuncStack(funcStack, nParamType);
	
	//Check for non-string ParamType
	if (nParamType != Param_String && nParamType != Param_StringByRef)
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
	if (nParamType != Param_StringByRef)
	{
		char sParamTypeName[32];
		FuncFunction_GetParamTypeName(nParamType, sParamTypeName, sizeof(sParamTypeName));
		ThrowNativeError(SP_ERROR_NATIVE, "Unable to set string from %s (Function %s, param %d)", sParamTypeName, funcStack.sFunction, iParam);
	}
	
	//Get and set string
	int iLength;
	GetNativeStringLength(2, iLength);
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
	
	//Get and set array
	switch (nParamType)
	{
		case Param_Array:
		{
			int iLength = GetNativeCell(3);
			any[] buffer = new any[iLength];
			funcStack.GetArray(iParam, buffer);
			SetNativeArray(2, buffer, iLength);
		}
		case Param_Vector:
		{
			any buffer[3];
			funcStack.GetVector(iParam, buffer);
			SetNativeArray(2, buffer, GetNativeCell(3));
		}
		case Param_Color:
		{
			any buffer[4];
			funcStack.GetColor(iParam, buffer);
			SetNativeArray(2, buffer, GetNativeCell(3));
		}
		default:
		{
			char sParamTypeName[32];
			FuncFunction_GetParamTypeName(nParamType, sParamTypeName, sizeof(sParamTypeName));
			ThrowNativeError(SP_ERROR_NATIVE, "Unable to get array from %s (Function %s, param %d)", sParamTypeName, funcStack.sFunction, iParam);
		}
	}
}

//void SaxtonHale_SetParamArray(int iParam, any[] value);
public any FuncNative_SetParamArray(Handle hPlugin, int iNumParams)
{
	//Get param + checks
	FuncStack funcStack;
	ParamType nParamType;
	int iParam = FuncNative_GetFuncStack(funcStack, nParamType);
	
	//Get and set array
	switch (nParamType)
	{
		case Param_Array:
		{
			int iLength = GetNativeCell(3);
			any[] buffer = new any[iLength];
			GetNativeArray(2, buffer, iLength);
			funcStack.SetArray(iParam, buffer);
		}
		case Param_Vector:
		{
			any buffer[3];
			GetNativeArray(2, buffer, sizeof(buffer));
			funcStack.SetVector(iParam, buffer);
		}
		case Param_Color:
		{
			any buffer[4];
			GetNativeArray(2, buffer, sizeof(buffer));
			funcStack.SetColor(iParam, buffer);
		}
		default:
		{
			char sParamTypeName[32];
			FuncFunction_GetParamTypeName(nParamType, sParamTypeName, sizeof(sParamTypeName));
			ThrowNativeError(SP_ERROR_NATIVE, "Unable to set array from %s (Function %s, param %d)", sParamTypeName, funcStack.sFunction, iParam);
		}
	}
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