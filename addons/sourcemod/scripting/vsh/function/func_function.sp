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
	
	public bool IsPluginLoaded(Handle hPlugin)
	{
		Handle hIterator = GetPluginIterator();
		while (MorePlugins(hIterator))
		{
			if (ReadPlugin(hIterator) == hPlugin)
			{
				delete hIterator;
				return true;
			}
		}
		
		delete hIterator;
		return false;
	}
	
	public void ClearPlugin(Handle hPlugin)
	{
		int iPos;
		while ((iPos = this.FindValue(hPlugin, FuncFunction::hPlugin)) != -1)
			this.Erase(iPos);
	}
	
	public void ClearUnloadedPlugin()
	{
		//TODO use OnNotifyPluginUnloaded when SM 1.11 is stable
		
		bool bCleared;
		do
		{
			bCleared = false;
			
			int iLength = this.Length;
			for (int i = 0; i < iLength; i++)
			{
				Handle hPlugin = this.Get(i, FuncFunction::hPlugin);
				if (!this.IsPluginLoaded(hPlugin))
				{
					PrintToServer("FuncFunctionList Found unloaded plugin %x", hPlugin);
					this.ClearPlugin(hPlugin);
					bCleared = true;
					break;
				}
			}
		}
		while (bCleared);
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