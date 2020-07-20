void FuncCall_Start(SaxtonHaleBase boss, FuncStack funcStack)
{
	char sBuffer[MAX_TYPE_CHAR];
	
	//Start pre hooks
	if (!FuncHook_Call(boss, funcStack, VSHHookMode_Pre))
		return;
	
	//Calculate array max size
	int iParamLength = (funcStack.iParamLength > 0) ? funcStack.iParamLength : 1;
	int iArraySize = 1;
	for (int iParam = 0; iParam < funcStack.iParamLength; iParam++)
		if (iArraySize < funcStack.iArrayLength[iParam])
			iArraySize = funcStack.iArrayLength[iParam];
	
	//Create arrays by reference
	any[][] array = new any[iParamLength][iArraySize];
	
	//Get array values
	for (int iParam = 0; iParam < funcStack.iParamLength; iParam++)
		if (funcStack.nParamType[iParam] == Param_String || funcStack.nParamType[iParam] == Param_Array)
			funcStack.GetArray(iParam+1, array[iParam]);
	
	//Call base_bossmulti
	if (!FuncCall_Call(boss, "SaxtonHaleBossMulti", funcStack, array, iArraySize))
		return;
	
	//Call multi boss specifc
	SaxtonHaleBossMulti saxtonBossMulti = view_as<SaxtonHaleBossMulti>(boss);
	saxtonBossMulti.GetBossMultiType(sBuffer, sizeof(sBuffer));
	if (!StrEmpty(sBuffer))
		if (!FuncCall_Call(boss, sBuffer, funcStack, array, iArraySize))
			return;
	
	//Call base_boss
	if (!FuncCall_Call(boss, "SaxtonHaleBoss", funcStack, array, iArraySize))
		return;
	
	//Call boss specific
	SaxtonHaleBoss saxtonBoss = view_as<SaxtonHaleBoss>(boss);
	saxtonBoss.GetBossType(sBuffer, sizeof(sBuffer));
	if (!FuncCall_Call(boss, sBuffer, funcStack, array, iArraySize))
		return;
	
	//Call base_ability
	if (!FuncCall_Call(boss, "SaxtonHaleAbility", funcStack, array, iArraySize))
		return;
	
	//Call every abilites from boss
	for (int i = 0; i < MAX_BOSS_ABILITY; i++)
	{
		SaxtonHaleAbility saxtonAbility = view_as<SaxtonHaleAbility>(boss);
		saxtonAbility.GetAbilityType(sBuffer, sizeof(sBuffer), i);
		if (!StrEmpty(sBuffer))
			if (!FuncCall_Call(boss, sBuffer, funcStack, array, iArraySize))
				return;
	}
	
	if (boss.bModifiers)
	{
		//Call base_modifiers
		if (!FuncCall_Call(boss, "SaxtonHaleModifiers", funcStack, array, iArraySize))
			return;
		
		//Call modifier specific
		SaxtonHaleModifiers saxtonModifiers = view_as<SaxtonHaleModifiers>(boss);
		saxtonModifiers.GetModifiersType(sBuffer, sizeof(sBuffer));
		if (!FuncCall_Call(boss, sBuffer, funcStack, array, iArraySize))
			return;
	}
	
	//Set arrays back
	for (int iParam = 0; iParam < funcStack.iParamLength; iParam++)
		if (funcStack.nParamType[iParam] == Param_String || funcStack.nParamType[iParam] == Param_Array)
			funcStack.SetArray(iParam+1, array[iParam]);
	
	//Start post hooks
	FuncHook_Call(boss, funcStack, VSHHookMode_Post);
}

bool FuncCall_Call(SaxtonHaleBase boss, const char[] sClass, FuncStack funcStack, any[][] array, int iArraySize)
{
	//Start function if valid
	if (!boss.StartFunction(sClass, funcStack.sFunction))
		return true;
	
	int iCopyback = (funcStack.action <= Plugin_Changed) ? SM_PARAM_COPYBACK : 0;
	
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
				Call_PushStringEx(view_as<char>(array[iParam]), iArraySize, SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, iCopyback);
			}
			case Param_Array:
			{
				Call_PushArrayEx(array[iParam], iArraySize, iCopyback);
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