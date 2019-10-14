ArrayList g_aTags;	//Arrays of every tags
ArrayList g_aTagsClient[TF_MAXPLAYERS+1][view_as<int>(TagsCall)][WeaponSlot_BuilderEngie+1];	//List of tags id from g_aTags builted to call from each clients

TagsFunction g_tFunctions;	//List of all functions and overrides

enum struct Tags	//Mental
{
	TFClassType nClass;			//Class assigned to this tag
	int iSlot;					//Slot assigned to this tag
	int iIndex;					//Weapon index assigned to this tag
	TagsCall nCall;				//Type of call on when to call this tag
	
	TagsFilter tFilters;		//Filters to check before doing anything below
	ArrayList aFunctions;		//Arrays of function id in g_tFunctions to call
	
	ArrayStack aBlockBuffer;	//Buffer list of blocked function name
	
	//Values only used for "takedamage" and "attackdamage", -1 if undefined
	float flSet;
	float flPerPlayer;
	float flMultiply;
	float flMin;
	float flMax;
	int iKnockback;
	
	//Values only used for "attack", -1 if undefined
	int iAttackCrit;
	
	//Values only used for "heal", -1 if undefined
	int iHealBuilding;
	
	void Load(KeyValues kv)
	{
		//Load filters
		this.tFilters = new TagsFilter(kv);
		
		//Load every functions and blocked function as a buffer for TagsName later
		if (kv.GotoFirstSubKey(false))
		{
			do	//Loop through every filter
			{
				char sKeyName[MAXLEN_CONFIG_VALUE];
				kv.GetSectionName(sKeyName, sizeof(sKeyName));
				if (StrEqual(sKeyName, "block"))
				{
					char sValue[MAXLEN_CONFIG_VALUE];
					kv.GetString(NULL_STRING, sValue, sizeof(sValue));
					
					if (this.aBlockBuffer == null)
						this.aBlockBuffer = new ArrayStack(sizeof(sValue));
					
					this.aBlockBuffer.PushString(sValue);
				}
				else if (StrContains(sKeyName, "Tags_") == 0)
				{
					if (g_tFunctions.AddFunction(kv, g_aTags.Length))	//Returns true on success
					{
						if (!g_tFunctions.IsOverride(g_tFunctions.Length-1))	//If not override, add to list
						{
							if (this.aFunctions == null)
								this.aFunctions = new ArrayList();
							
							//Push g_tFunctions id to array
							this.aFunctions.Push(g_tFunctions.Length-1);
						}
					}
				}
			}
			while (kv.GotoNextKey(false));
			kv.GoBack();
		}
		
		//Load slot to force set if given
		this.iSlot = kv.GetNum("slot", this.iSlot);	//TODO do we still need this?
		
		//Load whatever other values
		this.flSet = kv.GetFloat("set", -1.0);
		this.flPerPlayer = kv.GetFloat("perplayer", -1.0);
		this.flMultiply = kv.GetFloat("multiply", -1.0);
		this.flMin = kv.GetFloat("min", -1.0);
		this.flMax = kv.GetFloat("max", -1.0);
		this.iKnockback = kv.GetNum("knockback", -1);
		this.iAttackCrit = kv.GetNum("attackcrit", -1);
		this.iHealBuilding = kv.GetNum("healbuilding", -1);
		
		//Push this into array
		g_aTags.PushArray(this);
	}
}

void TagsCore_Init()
{
	g_aTags = new ArrayList(sizeof(Tags));
	g_tFunctions = new TagsFunction();
}

void TagsCore_Clear()
{
	int iCoreLength = g_aTags.Length;
	for (int iCoreId = 0; iCoreId < iCoreLength; iCoreId++)
	{
		Tags tagsStruct;
		g_aTags.GetArray(iCoreId, tagsStruct);
		delete tagsStruct.tFilters;
		delete tagsStruct.aFunctions;
		//aBlockBuffer is deleted in tags_name.sp
	}
	
	int iFunctionLength = g_tFunctions.Length;
	for (int iFunctionId = 0; iFunctionId < iFunctionLength; iFunctionId++)
		g_tFunctions.Delete(iFunctionId);
	
	g_aTags.Clear();
	g_tFunctions.Clear();
}

void TagsCore_RefreshClient(int iClient)
{
	//Delet existing arrays before creating new ones
	for (TagsCall nCall; nCall < TagsCall; nCall++)
		for (int iSlot = 0; iSlot <= WeaponSlot_BuilderEngie; iSlot++)
			delete g_aTagsClient[iClient][nCall][iSlot];
	
	if (!SaxtonHale_IsValidAttack(iClient))
		return;
	
	//Get class to search
	TFClassType nClass = TF2_GetPlayerClass(iClient);
	
	//Get every weapon indexs to search
	int iIndex[WeaponSlot_BuilderEngie+1];
	for (int iSlot = 0; iSlot <= WeaponSlot_BuilderEngie; iSlot++)
	{
		int iWeapon = TF2_GetItemInSlot(iClient, iSlot);
		if (IsValidEdict(iWeapon))
			iIndex[iSlot] = GetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex");
		else
			iIndex[iSlot] = -1;
	}
	
	//Loop through every tags to search what we want
	int iLength = g_aTags.Length;
	for (int iCoreId = 0; iCoreId < iLength; iCoreId++)
	{
		Tags tagsStruct;
		g_aTags.GetArray(iCoreId, tagsStruct);
		
		//Same class and valid slot
		if (tagsStruct.nClass == nClass && tagsStruct.iSlot > -1)
		{
			if (g_aTagsClient[iClient][tagsStruct.nCall][tagsStruct.iSlot] == null)
				g_aTagsClient[iClient][tagsStruct.nCall][tagsStruct.iSlot] = new ArrayList();
			
			g_aTagsClient[iClient][tagsStruct.nCall][tagsStruct.iSlot].Push(iCoreId);
		}
		else if (tagsStruct.iIndex > -1)
		{
			for (int iSlot = 0; iSlot <= WeaponSlot_BuilderEngie; iSlot++)
			{
				//Same index
				if (tagsStruct.iIndex == iIndex[iSlot])
				{
					if (g_aTagsClient[iClient][tagsStruct.nCall][iSlot] == null)
						g_aTagsClient[iClient][tagsStruct.nCall][iSlot] = new ArrayList();
					
					g_aTagsClient[iClient][tagsStruct.nCall][iSlot].Push(iCoreId);
					break;
				}
			}
		}
	}
}

void TagsCore_CallAll(int iClient, TagsCall nCall)
{
	for (int iSlot = 0; iSlot <= WeaponSlot_BuilderEngie; iSlot++)
		TagsCore_CallSlot(iClient, nCall, iSlot);
}

void TagsCore_CallSlot(int iClient, TagsCall nCall, int iSlot)
{
	ArrayList aArray = g_aTagsClient[iClient][nCall][iSlot];
	if (aArray == null) return;	//No tags to call
	
	int iLength = aArray.Length;
	for (int i = 0; i < iLength; i++)
	{
		int iCoreId = aArray.Get(i);
		Tags tagsStruct;
		g_aTags.GetArray(iCoreId, tagsStruct);
		
		//Check if there any functions to call
		if (tagsStruct.aFunctions == null)
			continue;
		
		//Filter check
		if (!tagsStruct.tFilters.IsAllowed(iClient))
			continue;
		
		//Call function
		int iFunctionLength = tagsStruct.aFunctions.Length;
		for (int iPos = 0; iPos < iFunctionLength; iPos++)
		{
			int iFunctionId = tagsStruct.aFunctions.Get(iPos);
			
			g_tFunctions.Call(iFunctionId, iClient);
		}
	}
}

stock bool TagsCore_IsAttackCrit(int iClient, TagsCall nCall, int iSlot)
{
	int iPos = -1;
	Tags tagsStruct;
	while (TagsCore_GetStruct(iPos, iClient, nCall, iSlot, tagsStruct))	//Loop though every active structs
	{
		if (tagsStruct.iAttackCrit == 1)
			return true;
		else if (tagsStruct.iAttackCrit == 0)
			return false;
	}
	
	return false;
}

stock bool TagsCore_CanHealBuilding(int iClient, TagsCall nCall, int iSlot)
{
	int iPos = -1;
	Tags tagsStruct;
	while (TagsCore_GetStruct(iPos, iClient, nCall, iSlot, tagsStruct))	//Loop though every active structs
	{
		if (tagsStruct.iHealBuilding == 1)
			return true;
		else if (tagsStruct.iHealBuilding == 0)
			return false;
	}
	
	return false;
}

//Stock to get every valid structs, returns false if no more structs to search
stock bool TagsCore_GetStruct(int &iPos, int iClient, TagsCall nCall, int iSlot, Tags tagsStruct)
{
	ArrayList aArray = g_aTagsClient[iClient][nCall][iSlot];
	if (aArray == null) return false;
	
	iPos++;
	int iLength = aArray.Length;
	while (iPos < iLength)
	{
		int iCoreId = aArray.Get(iPos);
		Tags bufferStruct;
		g_aTags.GetArray(iCoreId, bufferStruct);
		
		//Filter check
		if (!bufferStruct.tFilters.IsAllowed(iClient))
		{
			iPos++;
			continue;
		}
		
		tagsStruct = bufferStruct;
		return true;
	}
	
	return false;
}

stock bool TagsCore_IsAllowed(int iClient, int iId)
{
	//Check if client have given id first
	for (TagsCall nCall; nCall < TagsCall; nCall++)
	{
		for (int iSlot = 0; iSlot <= WeaponSlot_BuilderEngie; iSlot++)
		{
			if (g_aTagsClient[iClient][nCall][iSlot] != null)
			{
				if (g_aTagsClient[iClient][nCall][iSlot].FindValue(iId) > -1)
				{
					//Found, check filters
					Tags tagsStruct;
					g_aTags.GetArray(iId, tagsStruct);
					return tagsStruct.tFilters.IsAllowed(iClient);
				}
			}
		}
	}
	
	return false;
}