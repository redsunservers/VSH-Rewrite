enum struct FuncStack
{
	char sFunction[MAX_TYPE_CHAR];	// Function name
	ExecType nExecType;				// Exec type
	ParamType nParamType[SP_MAX_EXEC_PARAMS];
	
	any cell[SP_MAX_EXEC_PARAMS]; 			// Param_Cell, Param_CellByRef, Param_Float, Param_FloatByRef
	ArrayList array[SP_MAX_EXEC_PARAMS];	// Param_String, Param_StringByRef, Param_Array
	
	//Because enum struct cant have more than 1 dimension
	any array0[SP_MAX_EXEC_PARAMS]; 		// Param_Vector, Param_Color
	any array1[SP_MAX_EXEC_PARAMS];			// Param_Vector, Param_Color
	any array2[SP_MAX_EXEC_PARAMS];			// Param_Vector, Param_Color
	any array3[SP_MAX_EXEC_PARAMS];			// Param_Color
	
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
		this.nParamType[this.iParamLength++] = nParamType;
	}
	
	void PushVector(const any value[3])
	{
		this.array0[this.iParamLength] = value[0];
		this.array1[this.iParamLength] = value[1];
		this.array2[this.iParamLength] = value[2];
		this.nParamType[this.iParamLength++] = Param_Vector;
	}
	
	void PushColor(const any value[4])
	{
		this.array0[this.iParamLength] = value[0];
		this.array1[this.iParamLength] = value[1];
		this.array2[this.iParamLength] = value[2];
		this.array3[this.iParamLength] = value[3];
		this.nParamType[this.iParamLength++] = Param_Color;
	}
	
	any GetCell(int iParam)
	{
		return this.cell[iParam-1];
	}
	
	int GetArrayLength(int iParam)
	{
		return this.array[iParam-1].BlockSize;
	}
	
	void GetArray(int iParam, any[] buffer)
	{
		if (iParam >= 0)
			this.array[iParam-1].GetArray(0, buffer);
	}
	
	void GetVector(int iParam, any buffer[3])
	{
		buffer[0] = this.array0[iParam-1];
		buffer[1] = this.array1[iParam-1];
		buffer[2] = this.array2[iParam-1];
	}
	
	void GetColor(int iParam, any buffer[4])
	{
		buffer[0] = this.array0[iParam-1];
		buffer[1] = this.array1[iParam-1];
		buffer[2] = this.array2[iParam-1];
		buffer[3] = this.array3[iParam-1];
	}
	
	void SetCell(int iParam, any value)
	{
		this.cell[iParam-1] = value;
	}
	
	void SetArray(int iParam, const any[] value)
	{
		this.array[iParam-1].SetArray(0, value);
	}
	
	void SetVector(int iParam, const any value[3])
	{
		this.array0[iParam-1] = value[0];
		this.array1[iParam-1] = value[1];
		this.array2[iParam-1] = value[2];
	}
	
	void SetColor(int iParam, const any value[4])
	{
		this.array0[iParam-1] = value[0];
		this.array1[iParam-1] = value[1];
		this.array2[iParam-1] = value[2];
		this.array3[iParam-1] = value[3];
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

bool FuncStack_Erase()
{
	int iPos = g_aFuncStack.Length-1;
	if (iPos < 0)
		return false;
	
	g_aFuncStack.Erase(iPos);
	return true;
}