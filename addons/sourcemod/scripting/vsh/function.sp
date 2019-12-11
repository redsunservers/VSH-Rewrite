#define FUNCTION_CALLSTACK_MAX	16		//Max allowed callstacks
#define FUNCTION_PARAM_MAX		16		//Max allowed ParamType
#define FUNCTION_ARRAY_MAX		512		//Max string/array to store

static int g_iFunctionStack = -1;	//Current callstack
static char g_sFunctionStackName[FUNCTION_CALLSTACK_MAX][FUNCTION_ARRAY_MAX];	//Function name of stack
static any g_FunctionStackFinal[FUNCTION_CALLSTACK_MAX][FUNCTION_PARAM_MAX+1][FUNCTION_ARRAY_MAX];	//0 at param for size of param
static any g_FunctionStackTemp[FUNCTION_CALLSTACK_MAX][FUNCTION_PARAM_MAX+1][FUNCTION_ARRAY_MAX];	//Temporary values on whenever to override or not

static StringMap g_mFunctionExecType;	//ExecType of the forward
static StringMap g_mFunctionParamType;	//Array of ParamType of the forward from 1 to FUNCTION_PARAM_MAX, 0 for size of param
static StringMap g_mFunctionPlugin;		//Plugin handle connected to methodmap, for calling function
static StringMap g_mFunctionHook[view_as<int>(SaxtonHaleHookMode)];	//PrivateForward of hooks

void Function_Init()
{
	g_iFunctionStack = -1;
	
	g_mFunctionExecType = new StringMap();
	g_mFunctionParamType = new StringMap();
	g_mFunctionPlugin = new StringMap();
	
	for (int i = 0; i < sizeof(g_mFunctionHook); i++)
		g_mFunctionHook[i] = new StringMap();
	
	//Boss functions
	SaxtonHale_InitFunction("CreateBoss", ET_Single, Param_String);
	SaxtonHale_InitFunction("SetBossType", ET_Ignore, Param_String);
	SaxtonHale_InitFunction("GetBossType", ET_Ignore, Param_String, Param_Cell);
	SaxtonHale_InitFunction("GetBossName", ET_Ignore, Param_String, Param_Cell);
	SaxtonHale_InitFunction("GetBossInfo", ET_Ignore, Param_String, Param_Cell);
	SaxtonHale_InitFunction("IsBossHidden", ET_Single);
	
	//Modifiers functions
	SaxtonHale_InitFunction("CreateModifiers", ET_Single, Param_String);
	SaxtonHale_InitFunction("SetModifiersType", ET_Ignore, Param_String);
	SaxtonHale_InitFunction("GetModifiersType", ET_Ignore, Param_String, Param_Cell);
	SaxtonHale_InitFunction("GetModifiersName", ET_Ignore, Param_String, Param_Cell);
	SaxtonHale_InitFunction("GetModifiersInfo", ET_Ignore, Param_String, Param_Cell);
	SaxtonHale_InitFunction("IsModifiersHidden", ET_Single);
	
	//Ability functions
	SaxtonHale_InitFunction("CreateAbility", ET_Single, Param_String);
	SaxtonHale_InitFunction("FindAbility", ET_Single, Param_String);
	SaxtonHale_InitFunction("DestroyAbility", ET_Ignore, Param_String);
	
	//General functions
	SaxtonHale_InitFunction("OnThink", ET_Ignore);
	SaxtonHale_InitFunction("OnSpawn", ET_Ignore);
	SaxtonHale_InitFunction("OnRage", ET_Ignore);
	SaxtonHale_InitFunction("OnEntityCreated", ET_Ignore, Param_Cell, Param_String);
	SaxtonHale_InitFunction("OnCommandKeyValues", ET_Hook, Param_String);
	SaxtonHale_InitFunction("OnAttackCritical", ET_Hook, Param_Cell, Param_CellByRef);
	SaxtonHale_InitFunction("OnVoiceCommand", ET_Hook, Param_String, Param_String);
	SaxtonHale_InitFunction("OnSoundPlayed", ET_Hook, Param_Array, Param_CellByRef, Param_String, Param_CellByRef, Param_FloatByRef, Param_CellByRef, Param_CellByRef, Param_CellByRef, Param_String, Param_CellByRef);
	
	//Damage/Death functions
	SaxtonHale_InitFunction("OnAttackDamage", ET_Hook, Param_CellByRef, Param_CellByRef, Param_FloatByRef, Param_CellByRef, Param_CellByRef, Param_Array, Param_Array, Param_Cell);
	SaxtonHale_InitFunction("OnTakeDamage", ET_Hook, Param_CellByRef, Param_CellByRef, Param_FloatByRef, Param_CellByRef, Param_CellByRef, Param_Array, Param_Array, Param_Cell);
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
	SaxtonHale_InitFunction("GetModel", ET_Ignore, Param_String, Param_Cell);
	SaxtonHale_InitFunction("GetSound", ET_Ignore, Param_String, Param_Cell, Param_Cell);
	SaxtonHale_InitFunction("GetSoundKill", ET_Ignore, Param_String, Param_Cell, Param_Cell);
	SaxtonHale_InitFunction("GetSoundAbility", ET_Ignore, Param_String, Param_Cell, Param_String);
	SaxtonHale_InitFunction("GetRenderColor", ET_Ignore, Param_Array);
	SaxtonHale_InitFunction("GetMusicInfo", ET_Ignore, Param_String, Param_Cell, Param_FloatByRef);
	SaxtonHale_InitFunction("GetRageMusicInfo", ET_Ignore, Param_String, Param_Cell, Param_FloatByRef);
	
	//Misc functions
	SaxtonHale_InitFunction("Precache", ET_Ignore);
	SaxtonHale_InitFunction("CalculateMaxHealth", ET_Single);
	SaxtonHale_InitFunction("AddRage", ET_Ignore, Param_Cell);
	SaxtonHale_InitFunction("CreateWeapon", ET_Single, Param_Cell, Param_String, Param_Cell, Param_Cell, Param_String);
	SaxtonHale_InitFunction("Destroy", ET_Ignore);
}

bool Function_Create(const char[] sName, ExecType execType, ParamType[FUNCTION_PARAM_MAX+1] paramType, int iSize)
{
	if (!g_mFunctionExecType.SetValue(sName, execType, false))
		return false;
	
	paramType[0] = view_as<ParamType>(iSize);	//Store size of ParamType at 0
	if (!g_mFunctionParamType.SetArray(sName, paramType, FUNCTION_PARAM_MAX+1, false))
		return false;
	
	return true;
}

bool Function_StartStack(const char[] sName, any[][] value, int iSize)
{
	if (g_iFunctionStack >= FUNCTION_CALLSTACK_MAX-1)
		return false;
	
	//Store values to stack
	g_iFunctionStack++;
	g_FunctionStackFinal[g_iFunctionStack][0][0] = iSize;
	
	Format(g_sFunctionStackName[g_iFunctionStack], sizeof(g_sFunctionStackName[]), sName);
	
	for (int iParam = 1; iParam <= iSize; iParam++)
		for (int iArray = 0; iArray < FUNCTION_ARRAY_MAX; iArray++)
			g_FunctionStackFinal[g_iFunctionStack][iParam][iArray] = value[iParam][iArray];
	
	return true;
}

any Function_Start(SaxtonHaleBase boss)
{
	Action action = Plugin_Continue;
	any returnValue = 0;
	PrivateForward hPrivateForward;
	char sBuffer[64];
	
	//Start pre hooks
	int hookType = view_as<int>(VSHHookMode_Pre);	//I hate this
	if (g_mFunctionHook[hookType].GetValue(g_sFunctionStackName[g_iFunctionStack], hPrivateForward))
	{
		if (hPrivateForward.FunctionCount == 0)
		{
			//One of plugin unloaded, caused function count 0. Don't need to keep handle now
			delete hPrivateForward;
			g_mFunctionHook[hookType].Remove(g_sFunctionStackName[g_iFunctionStack]);
		}
		else if (!Function_CallHook(boss, hPrivateForward, action, returnValue)) return returnValue;
	}
	
	//Call base_boss
	if (!Function_Call(boss, "SaxtonHaleBoss", action, returnValue)) return returnValue;
	
	//Call boss specific
	SaxtonHaleBoss saxtonBoss = view_as<SaxtonHaleBoss>(boss);
	saxtonBoss.GetBossType(sBuffer, sizeof(sBuffer));
	if (!Function_Call(boss, sBuffer, action, returnValue)) return returnValue;
	
	//Call base_ability
	if (!Function_Call(boss, "SaxtonHaleAbility", action, returnValue)) return returnValue;
	
	//Call every abilites from boss
	for (int i = 0; i < MAX_BOSS_ABILITY; i++)
	{
		SaxtonHaleAbility saxtonAbility = view_as<SaxtonHaleAbility>(boss);
		saxtonAbility.GetAbilityType(sBuffer, sizeof(sBuffer), i);
		if (!StrEmpty(sBuffer))
			if (!Function_Call(boss, sBuffer, action, returnValue)) return returnValue;
	}
	
	if (boss.bModifiers)
	{
		//Call base_modifiers
		if (!Function_Call(boss, "SaxtonHaleModifiers", action, returnValue)) return returnValue;
		
		//Call modifier specific
		SaxtonHaleModifiers saxtonModifiers = view_as<SaxtonHaleModifiers>(boss);
		saxtonModifiers.GetModifiersType(sBuffer, sizeof(sBuffer));
		if (!Function_Call(boss, sBuffer, action, returnValue)) return returnValue;
	}
	
	//Start post hooks
	hookType = view_as<int>(VSHHookMode_Post);
	if (g_mFunctionHook[hookType].GetValue(g_sFunctionStackName[g_iFunctionStack], hPrivateForward))
	{
		if (hPrivateForward.FunctionCount == 0)
		{
			//One of plugin unloaded, caused function count 0. Don't need to keep handle now
			delete hPrivateForward;
			g_mFunctionHook[hookType].Remove(g_sFunctionStackName[g_iFunctionStack]);
		}
		else if (!Function_CallHook(boss, hPrivateForward, action, returnValue)) return returnValue;
	}
	
	return returnValue;
}

void Function_FinishStack(int[][] value)
{
	//Copy and "delete" stack
	int iSize = g_FunctionStackFinal[g_iFunctionStack][0][0];
	for (int iParam = 0; iParam <= iSize; iParam++)
	{
		for (int iArray = 0; iArray < FUNCTION_ARRAY_MAX; iArray++)
		{
			value[iParam][iArray] = g_FunctionStackFinal[g_iFunctionStack][iParam][iArray];
			g_FunctionStackFinal[g_iFunctionStack][iParam][iArray] = 0;
		}
	}
	
	Format(g_sFunctionStackName[g_iFunctionStack], sizeof(g_sFunctionStackName[]), "");
	
	g_iFunctionStack--;
}

bool Function_Call(SaxtonHaleBase boss, const char[] sClass, Action action, any &returnValue)
{
	//Start function if valid
	if (boss.StartFunction(sClass, g_sFunctionStackName[g_iFunctionStack]))
	{
		//Push params
		ParamType paramType[FUNCTION_PARAM_MAX+1];
		int iSize = Function_GetParamType(g_sFunctionStackName[g_iFunctionStack], paramType);
		for (int iParam = 1; iParam <= iSize; iParam++)
		{
			//if current action is handled, dont copyback params
			if (action < Plugin_Handled)
			{
				switch (paramType[iParam])
				{
					case Param_Cell: Call_PushCell(g_FunctionStackFinal[g_iFunctionStack][iParam][0]);
					case Param_CellByRef: Call_PushCellRef(g_FunctionStackFinal[g_iFunctionStack][iParam][0]);
					case Param_Float: Call_PushFloat(g_FunctionStackFinal[g_iFunctionStack][iParam][0]);
					case Param_FloatByRef: Call_PushFloatRef(g_FunctionStackFinal[g_iFunctionStack][iParam][0]);
					case Param_String: Call_PushStringEx(view_as<char>(g_FunctionStackFinal[g_iFunctionStack][iParam]), FUNCTION_ARRAY_MAX, SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
					case Param_Array: Call_PushArrayEx(g_FunctionStackFinal[g_iFunctionStack][iParam], FUNCTION_ARRAY_MAX, SM_PARAM_COPYBACK);
				}
			}
			else
			{
				switch (paramType[iParam])
				{
					case Param_Cell, Param_CellByRef: Call_PushCell(g_FunctionStackFinal[g_iFunctionStack][iParam][0]);
					case Param_Float, Param_FloatByRef: Call_PushFloat(g_FunctionStackFinal[g_iFunctionStack][iParam][0]);
					case Param_String: Call_PushString(view_as<char>(g_FunctionStackFinal[g_iFunctionStack][iParam]));
					case Param_Array: Call_PushArray(g_FunctionStackFinal[g_iFunctionStack][iParam], FUNCTION_ARRAY_MAX);
				}
			}
		}
		
		//Call function
		any returnTemp;
		int iError = Call_Finish(returnTemp);
		if (iError != SP_ERROR_NONE)
			ThrowError("Unable to call function (Function %s.%s, error code %d)", sClass, g_sFunctionStackName[g_iFunctionStack], iError);
		
		//If current action is handled, dont override return
		if (action >= Plugin_Handled)
			return true;
		
		//Determe what to do with return from ExecType
		ExecType execType;
		g_mFunctionExecType.GetValue(g_sFunctionStackName[g_iFunctionStack], execType);
		
		switch (execType)
		{
			case ET_Ignore:
			{
				returnValue = 0;
			}
			case ET_Single:
			{
				returnValue = returnTemp;
			}
			case ET_Event:
			{
				if (returnTemp > returnValue)
					returnValue = returnTemp;
			}
			case ET_Hook:
			{
				if (returnTemp > returnValue)
					returnValue = returnTemp;
				
				if (returnValue == Plugin_Stop)
					return false;	//Stop any further forwards
			}
		}
	}
	
	return true;
}

void Function_Hook(const char[] sName, Handle hPlugin, SaxtonHaleHookCallback callback, SaxtonHaleHookMode hookType)
{
	PrivateForward hPrivateForward;
	if (!g_mFunctionHook[hookType].GetValue(sName, hPrivateForward))	//Get existing private forward
	{
		//If does not exist, create new private forward
		hPrivateForward = new PrivateForward(ET_Hook, Param_Cell, Param_CellByRef);
		g_mFunctionHook[hookType].SetValue(sName, hPrivateForward);
	}
	
	hPrivateForward.AddFunction(hPlugin, callback);
}

void Function_Unhook(const char[] sName, Handle hPlugin, SaxtonHaleHookCallback callback, SaxtonHaleHookMode hookType)
{
	PrivateForward hPrivateForward;
	if (!g_mFunctionHook[hookType].GetValue(sName, hPrivateForward))	//Get private forward to remove
		return;	//No hook functions to unhook
	
	hPrivateForward.RemoveFunction(hPlugin, callback);
	
	if (hPrivateForward.FunctionCount == 0)
	{
		//No more hooks in forward
		delete hPrivateForward;
		g_mFunctionHook[hookType].Remove(sName);
	}
}

bool Function_CallHook(SaxtonHaleBase boss, PrivateForward hPrivateForward, Action &action, any &returnValue)
{
	//Copy final to temps for hook to use temp params
	int iSize = g_FunctionStackFinal[g_iFunctionStack][0][0];
	for (int iParam = 0; iParam <= iSize; iParam++)
		for (int iArray = 0; iArray < FUNCTION_ARRAY_MAX; iArray++)
			g_FunctionStackTemp[g_iFunctionStack][iParam][iArray] = g_FunctionStackFinal[g_iFunctionStack][iParam][iArray];
	
	//Start call
	Call_StartForward(hPrivateForward);
	Call_PushCell(boss);
	
	any returnTemp = returnValue;
	Call_PushCellRef(returnTemp);
	
	Action actionTemp;
	int iError = Call_Finish(actionTemp);
	if (iError != SP_ERROR_NONE)
		ThrowError("Unable to call hook forward (Function %s, error code %d)", g_sFunctionStackName[g_iFunctionStack], iError);
	
	//If stop, set return and params, stop any further functions called
	if (actionTemp == Plugin_Stop)
	{
		for (int iParam = 1; iParam <= iSize; iParam++)
			for (int iArray = 0; iArray < FUNCTION_ARRAY_MAX; iArray++)
				g_FunctionStackFinal[g_iFunctionStack][iParam][iArray] = g_FunctionStackTemp[g_iFunctionStack][iParam][iArray];
		
		returnValue = returnTemp;
		action = Plugin_Stop;
		return false;
	}
	
	//If changed or handled and function action not already handled, set return and params
	if (actionTemp >= Plugin_Changed && action < Plugin_Handled)
	{
		for (int iParam = 1; iParam <= iSize; iParam++)
			for (int iArray = 0; iArray < FUNCTION_ARRAY_MAX; iArray++)
				g_FunctionStackFinal[g_iFunctionStack][iParam][iArray] = g_FunctionStackTemp[g_iFunctionStack][iParam][iArray];
		
		returnValue = returnTemp;
		action = actionTemp;
		return true;
	}
	
	return true;
}

bool Function_GetNameStack(char[] sName, int iLength)
{
	if (g_iFunctionStack < 0)
		return false;
	
	Format(sName, iLength, g_sFunctionStackName[g_iFunctionStack]);
	return true;
}

int Function_GetParamValue(int iParam, any[] value)
{
	if (g_iFunctionStack < 0)
		return -1;
	
	for (int iArray = 0; iArray < FUNCTION_ARRAY_MAX; iArray++)
		value[iArray] = g_FunctionStackTemp[g_iFunctionStack][iParam][iArray];
	
	return g_iFunctionStack;
}

int Function_SetParamValue(int iParam, any[] value)
{
	if (g_iFunctionStack < 0)
		return -1;
	
	for (int iArray = 0; iArray < FUNCTION_ARRAY_MAX; iArray++)
		g_FunctionStackTemp[g_iFunctionStack][iParam][iArray] = value[iArray];
	
	return g_iFunctionStack;
}

int Function_GetParamType(const char[] sName, ParamType[FUNCTION_PARAM_MAX+1] paramType)
{
	if (!g_mFunctionParamType.GetArray(sName, paramType, FUNCTION_PARAM_MAX+1))
		return -1;
	
	return view_as<int>(paramType[0]);	//Return size of ParamType
}

void Function_GetParamTypeName(ParamType paramType, char[] sName, int iLength)
{
	switch (paramType)
	{
		case Param_Any: Format(sName, iLength, "Param_Any");
		case Param_Cell: Format(sName, iLength, "Param_Cell");
		case Param_CellByRef: Format(sName, iLength, "Param_CellByRef");
		case Param_Float: Format(sName, iLength, "Param_Float");
		case Param_FloatByRef: Format(sName, iLength, "Param_FloatByRef");
		case Param_String: Format(sName, iLength, "Param_String");
		case Param_Array: Format(sName, iLength, "Param_Array");
		case Param_VarArgs: Format(sName, iLength, "Param_VarArgs");
		default: Format(sName, iLength, "Unknown Param");
	}
}

bool Function_AddPlugin(const char[] sClass, Handle hPlugin)
{
	if (!g_mFunctionPlugin.SetValue(sClass, hPlugin, false))
		return false;
	
	return true;
}

Handle Function_GetPlugin(const char[] sClass)
{
	Handle hPlugin = null;
	g_mFunctionPlugin.GetValue(sClass, hPlugin);
	return hPlugin;
}

void Function_RemovePlugin(const char[] sClass)
{
	g_mFunctionPlugin.Remove(sClass);
}

StringMapSnapshot Function_GetPluginSnapshot()
{
	return g_mFunctionPlugin.Snapshot();
}