any FuncCall_Setup(SaxtonHaleBase boss, FuncFunction funcFunction)
{
	//Create stack
	FuncStack funcStack;
	Format(funcStack.sFunction, sizeof(funcStack.sFunction), funcFunction.sName);
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

void FuncCall_Start(SaxtonHaleBase boss, FuncStack funcStack)
{
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
	
	//Call each classes
	int iPos;
	char sClass[MAX_TYPE_CHAR];
	while (FuncClass_ClientGetClass(boss.iClient, iPos, sClass, sizeof(sClass)))
		if (!FuncCall_Call(boss, sClass, funcStack, array, iArraySize))
			return;
	
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