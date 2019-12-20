enum struct FuncStack
{
	char sFunction[MAX_TYPE_CHAR];	// Function name
	ExecType nExecType;				// Exec type
	
	ParamType nParamType[SP_MAX_EXEC_PARAMS];
	any cell[SP_MAX_EXEC_PARAMS]; 			// Param_Cell, Param_CellByRef, Param_Float, Param_FloatByRef
	ArrayList array[SP_MAX_EXEC_PARAMS];	// Param_String, Param_Array
	int iArrayLength[SP_MAX_EXEC_PARAMS];
	
	int iParamLength;				// Number of params passed
	
	Action action;					// Current action
	any returnValue;				// Current return value
	
	void PushCell(any value, ParamType nParamType)
	{
		this.cell[this.iParamLength] = value;
		this.nParamType[this.iParamLength++] = nParamType;
	}
	
	void PushArray(const any[] value, int iLength, ParamType nParamType)
	{
		this.array[this.iParamLength] = new ArrayList(iLength);
		this.array[this.iParamLength].PushArray(value);
		this.iArrayLength[this.iParamLength] = iLength;
		this.nParamType[this.iParamLength++] = nParamType;
	}
	
	any GetCell(int iParam)
	{
		return this.cell[iParam-1];
	}
	
	void GetArray(int iParam, any[] buffer)
	{
		if (iParam >= 0)
			this.array[iParam-1].GetArray(0, buffer);
	}
	
	void SetCell(int iParam, any value)
	{
		this.cell[iParam-1] = value;
	}
	
	void SetArray(int iParam, const any[] value)
	{
		this.array[iParam-1].SetArray(0, value);
	}
	
	void Delete()
	{
		for (int i = 0; i < this.iParamLength; i++)
			delete this.array[i];
	}
}

static ArrayList g_aFuncStack;

void FuncStack_Init()
{
	g_aFuncStack = new ArrayList(sizeof(FuncStack));
}

void FuncStack_Push(FuncStack funcStack)
{
	g_aFuncStack.PushArray(funcStack);
}

bool FuncStack_Get(FuncStack funcStack)
{
	int iPos = g_aFuncStack.Length-1;
	if (iPos < 0)
		return false;
	
	g_aFuncStack.GetArray(iPos, funcStack);
	return true;
}

bool FuncStack_Set(FuncStack funcStack)
{
	int iPos = g_aFuncStack.Length-1;
	if (iPos < 0)
		return false;
	
	g_aFuncStack.SetArray(iPos, funcStack);
	return true;
}

bool FuncStack_Clone(FuncStack funcStack)
{
	int iPos = g_aFuncStack.Length-1;
	if (iPos < 0)
		return false;
	
	g_aFuncStack.GetArray(iPos, funcStack);
	
	//Clone arrays
	for (int i = 0; i < funcStack.iParamLength; i++)
		if (funcStack.array[i])
			funcStack.array[i] = funcStack.array[i].Clone();
	
	return true;
}

bool FuncStack_Erase()
{
	int iPos = g_aFuncStack.Length-1;
	if (iPos < 0)
		return false;
	
	g_aFuncStack.Erase(iPos);
	return true;
}