enum struct FuncFunction
{
	SaxtonHaleFunction nId;
	char sName[MAX_TYPE_CHAR];
	Handle hPlugin;
	ExecType nExecType;
	ParamType nParamType[SP_MAX_EXEC_PARAMS];
	SaxtonHaleArrayType nArrayType[SP_MAX_EXEC_PARAMS];
	int iArrayData[SP_MAX_EXEC_PARAMS];
	int iParamLength;
}

static SaxtonHaleFunction g_nFuncFunctionId;

methodmap FuncFunctionList < ArrayList
{
	public FuncFunctionList()
	{
		return view_as<FuncFunctionList>(new ArrayList(sizeof(FuncFunction)));
	}
	
	public bool GetById(SaxtonHaleFunction nId, FuncFunction funcFunction)
	{
		int iPos = this.FindValue(nId, FuncFunction::nId);
		if (iPos == -1)
			return false;
		
		this.GetArray(iPos, funcFunction);
		return true;
	}
	
	public bool SetById(SaxtonHaleFunction nId, FuncFunction funcFunction)
	{
		int iPos = this.FindValue(nId, FuncFunction::nId);
		if (iPos == -1)
			return false;
		
		this.SetArray(iPos, funcFunction);
		return true;
	}
	
	public bool GetByName(const char[] sName, FuncFunction funcFunction)
	{
		int iLength = this.Length;
		for (int i = 0; i < iLength; i++)
		{
			FuncFunction buffer;
			this.GetArray(i, buffer);
			if (StrEqual(buffer.sName, sName))
			{
				funcFunction = buffer;
				return true;
			}
		}
		
		return false;
	}
	
	public SaxtonHaleFunction Add(FuncFunction funcFunction)
	{
		funcFunction.nId = g_nFuncFunctionId;
		this.PushArray(funcFunction);
		g_nFuncFunctionId++;
		return funcFunction.nId;
	}
	
	public void ClearUnloadedPlugin(Handle hPlugin)
	{
		int iPos = -1;
		while ((iPos = this.FindValue(hPlugin, FuncFunction::hPlugin)) != -1)
			this.Erase(iPos);
	}
}

bool FuncFunction_GetParamTypeName(ParamType nParamType, char[] sBuffer, int iLength)
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