void FuncCall_Start(SaxtonHaleBase boss, FuncStack funcStack)
{
	char sBuffer[MAX_TYPE_CHAR];
	
	//Start pre hooks
	if (!FuncHook_Call(boss, funcStack, VSHHookMode_Pre))
		return;
	
	//Calculate dynamic array size
	int iArrayPos[4] = {-1, ...};
	int iArraySize[4];
	int iCount = 0;
	for (int iParam = 0; iParam < funcStack.iParamLength; iParam++)
	{
		if (FuncFunction_IsParamTypeDynamic(funcStack.nParamType[iParam]))
		{
			iArrayPos[iCount] = iParam;
			iArraySize[iCount++] = funcStack.GetArrayLength(iParam);
		}
	}
	
	//Create dynamic arrays by reference
	any[] array0 = new any[iArraySize[0]];
	any[] array1 = new any[iArraySize[1]];
	any[] array2 = new any[iArraySize[2]];
	any[] array3 = new any[iArraySize[3]];
	
	//Set value
	funcStack.GetArray(iArrayPos[0], array0);
	funcStack.GetArray(iArrayPos[1], array1);
	funcStack.GetArray(iArrayPos[2], array2);
	funcStack.GetArray(iArrayPos[3], array3);
	
	//Call base_boss
	if (!FuncCall_Call(boss, "SaxtonHaleBoss", funcStack, iArraySize, array0, array1, array2, array3))
		return;
	
	//Call boss specific
	SaxtonHaleBoss saxtonBoss = view_as<SaxtonHaleBoss>(boss);
	saxtonBoss.GetBossType(sBuffer, sizeof(sBuffer));
	if (!FuncCall_Call(boss, sBuffer, funcStack, iArraySize, array0, array1, array2, array3))
		return;
	
	//Call base_ability
	if (!FuncCall_Call(boss, "SaxtonHaleAbility", funcStack, iArraySize, array0, array1, array2, array3))
		return;
	
	//Call every abilites from boss
	for (int i = 0; i < MAX_BOSS_ABILITY; i++)
	{
		SaxtonHaleAbility saxtonAbility = view_as<SaxtonHaleAbility>(boss);
		saxtonAbility.GetAbilityType(sBuffer, sizeof(sBuffer), i);
		if (!StrEmpty(sBuffer))
			if (!FuncCall_Call(boss, sBuffer, funcStack, iArraySize, array0, array1, array2, array3))
				return;
	}
	
	if (boss.bModifiers)
	{
		//Call base_modifiers
		if (!FuncCall_Call(boss, "SaxtonHaleModifiers", funcStack, iArraySize, array0, array1, array2, array3))
			return;
		
		//Call modifier specific
		SaxtonHaleModifiers saxtonModifiers = view_as<SaxtonHaleModifiers>(boss);
		saxtonModifiers.GetModifiersType(sBuffer, sizeof(sBuffer));
		if (!FuncCall_Call(boss, sBuffer, funcStack, iArraySize, array0, array1, array2, array3))
			return;
	}
	
	//Set dynamic array back
	funcStack.SetArray(iArrayPos[0], array0);
	funcStack.SetArray(iArrayPos[1], array1);
	funcStack.SetArray(iArrayPos[2], array2);
	funcStack.SetArray(iArrayPos[3], array3);
	
	//Start post hooks
	FuncHook_Call(boss, funcStack, VSHHookMode_Post);
}

bool FuncCall_Call(SaxtonHaleBase boss, const char[] sClass, FuncStack funcStack, int iArraySize[4], any[] array0, any[] array1, any[] array2, any[] array3)
{
	//Start function if valid
	if (!boss.StartFunction(sClass, funcStack.sFunction))
		return true;
	
	int iCopyback = (funcStack.action <= Plugin_Changed) ? SM_PARAM_COPYBACK : 0;
	
	int iDynamicCount = 0;
	any array[SP_MAX_EXEC_PARAMS][4];	//Param_Vector and Param_Color to pass by ref
	funcStack.GetArrayAll(array);
	
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
				switch (iDynamicCount)
				{
					case 0: Call_PushStringEx(view_as<char>(array0), iArraySize[0], SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, iCopyback);
					case 1: Call_PushStringEx(view_as<char>(array1), iArraySize[1], SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, iCopyback);
					case 2: Call_PushStringEx(view_as<char>(array2), iArraySize[2], SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, iCopyback);
					case 3: Call_PushStringEx(view_as<char>(array3), iArraySize[3], SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, iCopyback);
				}
				
				iDynamicCount++;
			}
			case Param_Array:
			{
				switch (iDynamicCount)
				{
					case 0: Call_PushArrayEx(array0, iArraySize[0], iCopyback);
					case 1: Call_PushArrayEx(array1, iArraySize[1], iCopyback);
					case 2: Call_PushArrayEx(array2, iArraySize[2], iCopyback);
					case 3: Call_PushArrayEx(array3, iArraySize[3], iCopyback);
				}
				
				iDynamicCount++;
			}
			case Param_Vector:
			{
				Call_PushArrayEx(array[iParam], 3, iCopyback);
			}
			case Param_Color:
			{
				Call_PushArrayEx(array[iParam], 4, iCopyback);
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
	
	//Set arrays back
	funcStack.SetArrayAll(array);
	
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