void FuncCall_Start(SaxtonHaleBase boss, FuncStack funcStack)
{
	char sBuffer[MAX_TYPE_CHAR];
	
	//Start pre hooks
	if (!FuncHook_Call(boss, funcStack, VSHHookMode_Pre))
		return;
	
	//Calculate dynamic array max size
	int iArrayCount;
	int iArraySize;
	for (int iParam = 0; iParam < funcStack.iParamLength; iParam++)
	{
		if (funcStack.nParamType[iParam] == Param_StringByRef || funcStack.nParamType[iParam] == Param_Array)
		{
			iArrayCount++;
			int iBuffer = funcStack.GetArrayLength(iParam);
			if (iBuffer > iArraySize)
				iArraySize = iBuffer;
		}
	}
	
	//Create dynamic and static arrays by reference
	any[][] arrayDynamic = new any[iArrayCount][iArraySize];
	any arrayStatic[SP_MAX_EXEC_PARAMS][4];
	
	//Get dynamic and static array values
	int iDynamicCount = 0;
	for (int iParam = 0; iParam < funcStack.iParamLength; iParam++)
	{
		switch (funcStack.nParamType[iParam])
		{
			case Param_StringByRef, Param_Array:
			{
				funcStack.GetArray(iParam+1, arrayDynamic[iDynamicCount++]);
			}
			case Param_Vector:
			{
				arrayStatic[iParam][0] = funcStack.array0[iParam];
				arrayStatic[iParam][1] = funcStack.array1[iParam];
				arrayStatic[iParam][2] = funcStack.array2[iParam];
			}
			case Param_Color:
			{
				arrayStatic[iParam][0] = funcStack.array0[iParam];
				arrayStatic[iParam][1] = funcStack.array1[iParam];
				arrayStatic[iParam][2] = funcStack.array2[iParam];
				arrayStatic[iParam][3] = funcStack.array3[iParam];
			}
		}
	}
	
	//Call base_boss
	if (!FuncCall_Call(boss, "SaxtonHaleBoss", funcStack, arrayDynamic, iArraySize, arrayStatic))
		return;
	
	//Call boss specific
	SaxtonHaleBoss saxtonBoss = view_as<SaxtonHaleBoss>(boss);
	saxtonBoss.GetBossType(sBuffer, sizeof(sBuffer));
	if (!FuncCall_Call(boss, sBuffer, funcStack, arrayDynamic, iArraySize, arrayStatic))
		return;
	
	//Call base_ability
	if (!FuncCall_Call(boss, "SaxtonHaleAbility", funcStack, arrayDynamic, iArraySize, arrayStatic))
		return;
	
	//Call every abilites from boss
	for (int i = 0; i < MAX_BOSS_ABILITY; i++)
	{
		SaxtonHaleAbility saxtonAbility = view_as<SaxtonHaleAbility>(boss);
		saxtonAbility.GetAbilityType(sBuffer, sizeof(sBuffer), i);
		if (!StrEmpty(sBuffer))
			if (!FuncCall_Call(boss, sBuffer, funcStack, arrayDynamic, iArraySize, arrayStatic))
				return;
	}
	
	if (boss.bModifiers)
	{
		//Call base_modifiers
		if (!FuncCall_Call(boss, "SaxtonHaleModifiers", funcStack, arrayDynamic, iArraySize, arrayStatic))
			return;
		
		//Call modifier specific
		SaxtonHaleModifiers saxtonModifiers = view_as<SaxtonHaleModifiers>(boss);
		saxtonModifiers.GetModifiersType(sBuffer, sizeof(sBuffer));
		if (!FuncCall_Call(boss, sBuffer, funcStack, arrayDynamic, iArraySize, arrayStatic))
			return;
	}
	
	//Set dynamic and static arrays back
	iDynamicCount = 0;
	for (int iParam = 0; iParam < funcStack.iParamLength; iParam++)
	{
		switch (funcStack.nParamType[iParam])
		{
			case Param_StringByRef, Param_Array:
			{
				funcStack.SetArray(iParam+1, arrayDynamic[iDynamicCount++]);
			}
			case Param_Vector:
			{
				funcStack.array0[iParam] = arrayStatic[iParam][0];
				funcStack.array1[iParam] = arrayStatic[iParam][1];
				funcStack.array2[iParam] = arrayStatic[iParam][2];
			}
			case Param_Color:
			{
				funcStack.array0[iParam] = arrayStatic[iParam][0];
				funcStack.array1[iParam] = arrayStatic[iParam][1];
				funcStack.array2[iParam] = arrayStatic[iParam][2];
				funcStack.array3[iParam] = arrayStatic[iParam][3];
			}
		}
	}
	
	//Start post hooks
	FuncHook_Call(boss, funcStack, VSHHookMode_Post);
}

bool FuncCall_Call(SaxtonHaleBase boss, const char[] sClass, FuncStack funcStack, any[][] arrayDynamic, int iArraySize, any arrayStatic[SP_MAX_EXEC_PARAMS][4])
{
	//Start function if valid
	if (!boss.StartFunction(sClass, funcStack.sFunction))
		return true;
	
	int iCopyback = (funcStack.action <= Plugin_Changed) ? SM_PARAM_COPYBACK : 0;
	int iDynamicCount = 0;
	
	//Push params
	for (int iParam = 0; iParam < funcStack.iParamLength; iParam++)
	{
		switch (funcStack.nParamType[iParam])
		{
			case Param_Cell:
			{
				Call_PushCell(funcStack.cell[iParam]);
			}
			case Param_CellByRef:
			{
				if (iCopyback)
				{
					Call_PushCellRef(funcStack.cell[iParam]);
				}
				else
				{
					any buffer = funcStack.cell[iParam];
					Call_PushCellRef(buffer);
				}
			}
			case Param_Float:
			{
				Call_PushFloat(funcStack.cell[iParam]);
			}
			case Param_FloatByRef:
			{
				if (iCopyback)
				{
					Call_PushFloatRef(funcStack.cell[iParam]);
				}
				else
				{
					any buffer = funcStack.cell[iParam];
					Call_PushFloatRef(buffer);
				}
			}
			case Param_String:
			{
				int iLength = funcStack.GetArrayLength(iParam);
				char[] sBuffer = new char[iLength];
				funcStack.GetArray(iParam, view_as<any>(sBuffer));
				Call_PushString(sBuffer);
			}
			case Param_StringByRef:
			{
				Call_PushStringEx(view_as<char>(arrayDynamic[iDynamicCount++]), iArraySize, SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, iCopyback);
			}
			case Param_Array:
			{
				Call_PushArrayEx(arrayDynamic[iDynamicCount++], iArraySize, iCopyback);
			}
			case Param_Vector:
			{
				Call_PushArrayEx(arrayStatic[iParam], 3, iCopyback);
			}
			case Param_Color:
			{
				Call_PushArrayEx(arrayStatic[iParam], 4, iCopyback);
			}
		}
	}
	
	//Call function
	any returnTemp;
	int iError = Call_Finish(returnTemp);
	if (iError != SP_ERROR_NONE)
		ThrowError("Unable to call function (%s.%s, error code %d)", sClass, funcStack.sFunction, iError);
	
	//If current action is handled, dont override return
	if (funcStack.action >= Plugin_Handled)
		return true;
	
	//Determe what to do with return from ExecType
	switch (funcStack.nExecType)
	{
		case ET_Ignore:
		{
			funcStack.returnValue = 0;
		}
		case ET_Single:
		{
			funcStack.returnValue = returnTemp;
		}
		case ET_Event:
		{
			if (returnTemp > funcStack.returnValue)
				funcStack.returnValue = returnTemp;
		}
		case ET_Hook:
		{
			if (returnTemp > funcStack.returnValue)
				funcStack.returnValue = returnTemp;
			
			if (funcStack.returnValue == Plugin_Stop)
				return false;	//Stop any further forwards
		}
	}
	
	return true;
}