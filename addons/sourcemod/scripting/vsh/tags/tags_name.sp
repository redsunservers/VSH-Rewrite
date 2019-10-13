static StringMap g_mFunctionName;	//Buffer list of every function names, with value as g_tFunctions id

void TagsName_Init()
{
	g_mFunctionName = new StringMap();
}

void TagsName_Clear()
{
	g_mFunctionName.Clear();
}

void TagsName_Add(const char[] sName, int iFunctionId)
{
	g_mFunctionName.SetValue(sName, iFunctionId);
}

void TagsName_Load()
{
	//Load blocked functions
	int iCoreLength = g_aTags.Length;
	for (int iCoreId = 0; iCoreId < iCoreLength; iCoreId++)
	{
		Tags tagsStruct;
		g_aTags.GetArray(iCoreId, tagsStruct);
		
		//Load blocked functions
		if (tagsStruct.aBlockBuffer != null)
		{
			int iBlockSize = tagsStruct.aBlockBuffer.BlockSize;
			
			while (!tagsStruct.aBlockBuffer.Empty)
			{
				char[] sBlockName = new char[iBlockSize];
				tagsStruct.aBlockBuffer.PopString(sBlockName, iBlockSize);
				
				int iFunctionId;
				if (!g_mFunctionName.GetValue(sBlockName, iFunctionId))
				{
					LogMessage("WARNING: Unable to find name from block '%s'", sBlockName);
					continue;
				}
				
				g_tFunctions.AddBlock(iFunctionId, iCoreId);
			}
			
			delete tagsStruct.aBlockBuffer;
		}
	}
	
	//Load override functions
	int iFunctionLength = g_tFunctions.Length;
	for (int iFunctionId = 0; iFunctionId < iFunctionLength; iFunctionId++)
	{
		char sOverrideName[MAXLEN_CONFIG_VALUE];
		if (g_tFunctions.GetOverrideName(iFunctionId, sOverrideName, sizeof(sOverrideName)))
		{
			//Found name of override, find function id
			int iPos;
			if (!g_mFunctionName.GetValue(sOverrideName, iPos))
			{
				LogMessage("WARNING: Unable to find name from override '%s'", sOverrideName);
				continue;
			}
			
			g_tFunctions.AddOverride(iPos, iFunctionId);
		}
	}
}