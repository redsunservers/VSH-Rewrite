enum struct TagsFunctionStruct
{
	int iCoreId;			//Id pos in g_aTags
	Function func;			//Function tag to call
	TagsParams tParams;		//Params to pass tag function
	TagsBlock tBlock;		//List of ids in g_aTags blocking this function
	ArrayList aOverride;	//List of overrides from Id pos in g_tFunctions
}

methodmap TagsFunction < ArrayList
{
	public TagsFunction()
	{
		return view_as<TagsFunction>(new ArrayList(sizeof(TagsFunctionStruct)));
	}
	
	public bool AddFunction(KeyValues kv, int iCoreId)
	{
		TagsFunctionStruct functionStruct;
		functionStruct.iCoreId = iCoreId;
		
		//Get and check if function exists
		char sFunctionName[MAXLEN_CONFIG_VALUE];
		kv.GetSectionName(sFunctionName, sizeof(sFunctionName));
		
		functionStruct.func = GetFunctionByName(null, sFunctionName);
		if (functionStruct.func == INVALID_FUNCTION)
		{
			LogMessage("WARNING: Unable to find function name '%s'", sFunctionName);
			return false;
		}
		
		if (kv.GotoFirstSubKey(false))
		{
			functionStruct.tParams = new TagsParams();
			
			do	//Loop through every params
			{
				char sParamName[MAXLEN_CONFIG_VALUE], sParamValue[MAXLEN_CONFIG_VALUE];
				kv.GetSectionName(sParamName, sizeof(sParamName));
				kv.GetString(NULL_STRING, sParamValue, sizeof(sParamValue));
				functionStruct.tParams.SetString(sParamName, sParamValue);
				
				if (StrEqual(sParamName, "name"))
					TagsName_Add(sParamValue, this.Length);
			}
			while (kv.GotoNextKey(false));
			kv.GoBack();
		}
		
		//Push into array
		this.PushArray(functionStruct);
		return true;
	}
	
	public void AddBlock(int iPos, int iCoreId)
	{
		TagsFunctionStruct functionStruct;
		this.GetArray(iPos, functionStruct);
		
		if (functionStruct.tBlock == null)
		{
			functionStruct.tBlock = new TagsBlock();
			this.SetArray(iPos, functionStruct);	//Set new handle to array
		}
		
		functionStruct.tBlock.Push(iCoreId);
	}
	
	public bool IsOverride(int iPos)
	{
		TagsFunctionStruct functionStruct;
		this.GetArray(iPos, functionStruct);
		return functionStruct.tParams.bOverride;
	}
	
	public bool GetOverrideName(int iPos, char[] sName, int iLength)
	{
		TagsFunctionStruct functionStruct;
		this.GetArray(iPos, functionStruct);
		return functionStruct.tParams.GetOverride(sName, iLength);
	}
	
	public void AddOverride(int iPos, int iFunctionId)
	{
		TagsFunctionStruct functionStruct;
		this.GetArray(iPos, functionStruct);
		
		if (functionStruct.aOverride == null)
		{
			functionStruct.aOverride = new ArrayList();
			this.SetArray(iPos, functionStruct);	//Set new handle to array
		}
		
		functionStruct.aOverride.Push(iFunctionId);
	}
	
	public void GetParams(int iPos, int iClient, TagsParams tParams)
	{
		TagsFunctionStruct functionStruct;
		this.GetArray(iPos, functionStruct);
		
		//Does client have this id, and not filtered
		if (!TagsCore_IsAllowed(iClient, functionStruct.iCoreId))
			return;
		
		//Block check
		if (functionStruct.tBlock.IsBlocked(iClient))
			return;
		
		functionStruct.tParams.CopyData(tParams);
		
		//Check for overrides to copy data
		if (functionStruct.aOverride != null)
		{
			int iLength = functionStruct.aOverride.Length;
			for (int i = 0; i < iLength; i++)
			{
				int iFunctionId = functionStruct.aOverride.Get(i);
				TagsFunction_GetParams(this, iFunctionId, iClient, tParams);	//Recursion
			}
		}
	}
	
	public void Call(int iPos, int iClient)
	{
		TagsFunctionStruct functionStruct;
		this.GetArray(iPos, functionStruct);
		
		//Block check
		if (functionStruct.tBlock.IsBlocked(iClient))
			return;
		
		TagsParams tParams = new TagsParams();	//Create new params
		this.GetParams(iPos, iClient, tParams);	//Get params, including override params if possible
		
		float flDelay = tParams.flDelay;
		if (flDelay >= 0.0)
		{
			//Create delay timer
			DataPack data;
			CreateDataTimer(flDelay, TagsCall_TimerDelay, data);
			data.WriteFunction(functionStruct.func);
			data.WriteCell(EntIndexToEntRef(iClient));
			data.WriteCell(tParams);
		}
		else
		{
			TagsCall_Call(functionStruct.func, iClient, tParams, tParams.iCall);
		}
	}
	
	public void Delete(int iPos)
	{
		TagsFunctionStruct functionStruct;
		this.GetArray(iPos, functionStruct);
		
		//tFilters get deleted in core, as it uses same handle
		delete functionStruct.tParams;
		delete functionStruct.tBlock;
		delete functionStruct.aOverride;
	}
}

void TagsFunction_GetParams(TagsFunction tFunctions, int iPos, int iClient, TagsParams tParams)
{
	tFunctions.GetParams(iPos, iClient, tParams);
}