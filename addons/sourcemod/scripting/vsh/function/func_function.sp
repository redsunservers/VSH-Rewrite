enum struct FuncFunction
{
	SaxtonHaleFunction nId;
	ExecType nExecType;
	ParamType nParamType[SP_MAX_EXEC_PARAMS];
	SaxtonHaleArrayType nArrayType[SP_MAX_EXEC_PARAMS];
	int iArrayData[SP_MAX_EXEC_PARAMS];
	int iParamLength;
}

static StringMap g_mFuncFunction;	//Stores FuncFunction
static SaxtonHaleFunction g_nFuncFunctionId;

methodmap FuncFunctionId < StringMap
{
	public FuncFunctionId()
	{
		return view_as<FuncFunctionId>(new StringMap());
	}
	
	public SaxtonHaleFunction AddStruct(const char[] sFunction, FuncFunction funcFunction)
	{
		funcFunction.nId = g_nFuncFunctionId;
		if (!g_mFuncFunction.SetArray(sFunction, funcFunction, sizeof(funcFunction), false))
			return view_as<SaxtonHaleFunction>(-1);
		
		char sBuffer[1];
		sBuffer[0] = view_as<char>(g_nFuncFunctionId);
		this.SetString(sBuffer, sFunction);
		
		g_nFuncFunctionId++;
		return g_nFuncFunctionId - view_as<SaxtonHaleFunction>(1);
	}
	
	public bool GetStruct(SaxtonHaleFunction nId, FuncFunction funcFunction)
	{
		char sBuffer[1];
		sBuffer[0] = view_as<char>(nId);
		
		char sFunction[MAX_TYPE_CHAR];
		if (!this.GetString(sBuffer, sFunction, sizeof(sFunction)))
			return false;
		
		g_mFuncFunction.GetArray(sFunction, funcFunction, sizeof(funcFunction));
		return true;
	}
	
	public bool SetStruct(SaxtonHaleFunction nId, FuncFunction funcFunction)
	{
		char sBuffer[1];
		sBuffer[0] = view_as<char>(nId);
		
		char sFunction[MAX_TYPE_CHAR];
		if (!this.GetString(sBuffer, sFunction, sizeof(sFunction)))
			return false;
		
		g_mFuncFunction.SetArray(sFunction, funcFunction, sizeof(funcFunction));
		return true;
	}
	
	public void RemoveStruct(const char[] sFunction)
	{
		FuncFunction funcFunction;
		if (g_mFuncFunction.GetArray(sFunction, funcFunction, sizeof(funcFunction)))
		{
			g_mFuncFunction.Remove(sFunction);
			
			char sBuffer[1];
			sBuffer[0] = view_as<char>(funcFunction.nId);
			this.Remove(sBuffer);
		}
	}
}

void FuncFunction_Init()
{
	g_mFuncFunction = new StringMap();
}

stock bool FuncFunction_Get(const char[] sFunction, FuncFunction funcFunction)
{
	return g_mFuncFunction.GetArray(sFunction, funcFunction, sizeof(funcFunction));
}

stock bool FuncFunction_GetParamTypeName(ParamType nParamType, char[] sBuffer, int iLength)
{
	switch (nParamType)
	{
		case Param_Any: Format(sBuffer, iLength, "Param_Any");
		case Param_Cell: Format(sBuffer, iLength, "Param_Cell");
		case Param_CellByRef: Format(sBuffer, iLength, "Param_CellByRef");
		case Param_Float: Format(sBuffer, iLength, "Param_Float");
		case Param_FloatByRef: Format(sBuffer, iLength, "Param_FloatByRef");
		case Param_String: Format(sBuffer, iLength, "Param_String");
		case Param_Array: Format(sBuffer, iLength, "Param_Array");
		case Param_VarArgs: Format(sBuffer, iLength, "Param_VarArgs");
		default: return false;
	}
	
	return true;
}