methodmap TagsParams < StringMap
{
	public TagsParams(KeyValues kv = null, int iFunctionId = -1)
	{
		if (kv == null)
			return view_as<TagsParams>(new StringMap());
		
		if (!kv.GotoFirstSubKey(false))
			return null;
		
		TagsParams tParams = view_as<TagsParams>(new StringMap());
		
		do	//Loop through every params
		{
			char sParamName[MAXLEN_CONFIG_VALUE], sParamValue[MAXLEN_CONFIG_VALUEARRAY], sBuffer[MAXLEN_CONFIG_VALUEARRAY];
			kv.GetSectionName(sParamName, sizeof(sParamName));
			kv.GetString(NULL_STRING, sParamValue, sizeof(sParamValue));
			StrToLower(sParamName);	//Convert string to lowercase, KeyValues rarely read 1st letter as uppercase...
			
			//If same param name found, add to an "array"
			if (tParams.GetString(sParamName, sBuffer, sizeof(sBuffer)))
				Format(sParamValue, sizeof(sParamValue), "%s ; %s", sParamValue, sBuffer);
			
			tParams.SetString(sParamName, sParamValue);
			
			if (StrEqual(sParamName, "name") && iFunctionId >= 0)
				TagsName_Add(sParamValue, iFunctionId);
		}
		while (kv.GotoNextKey(false));
		kv.GoBack();
		
		return tParams;
	}
	
	public void SetInt(const char[] sKey, any iValue)
	{
		char sValue[12];
		IntToString(iValue, sValue, sizeof(sValue));
		this.SetString(sKey, sValue);
	}
	
	public void SetFloat(const char[] sKey, float flValue)
	{
		char sValue[12];
		FloatToString(flValue, sValue, sizeof(sValue));
		this.SetString(sKey, sValue);
	}
	
	public bool GetStringSingle(const char[] sKey, char[] sBuffer, int iLength)
	{
		if (this == null) return false;
		
		char sValue[MAXLEN_CONFIG_VALUEARRAY];
		if (!this.GetString(sKey, sValue, sizeof(sValue)))
			return false;
		
		char sValues[MAX_CONFIG_ARRAY][MAXLEN_CONFIG_VALUE];
		int iCount = ExplodeString(sValue, " ; ", sValues, sizeof(sValues), sizeof(sValues[]));
		if (iCount == 0) return false;
		
		//Copy last value in array
		Format(sBuffer, iLength, sValues[iCount-1]);
		return true;
	}
	
	public ArrayList GetStringArray(const char[] sKey)
	{
		if (this == null) return null;
		
		char sValue[MAXLEN_CONFIG_VALUEARRAY];
		if (!this.GetString(sKey, sValue, sizeof(sValue)))
			return null;
		
		char sValues[MAX_CONFIG_ARRAY][MAXLEN_CONFIG_VALUE];
		int iCount = ExplodeString(sValue, " ; ", sValues, sizeof(sValues), sizeof(sValues[]));
		if (iCount == 0) return null;
		
		//Push all into array
		ArrayList aBuffer = new ArrayList(MAXLEN_CONFIG_VALUE);
		for (int i = 0; i < iCount; i++)
			aBuffer.PushString(sValues[i]);
		
		return aBuffer;
	}
	
	public bool GetStringRandom(const char[] sKey, char[] sBuffer, int iLength)
	{
		if (this == null) return false;
		
		char sValue[MAXLEN_CONFIG_VALUEARRAY];
		if (!this.GetString(sKey, sValue, sizeof(sValue)))
			return false;
		
		char sValues[MAX_CONFIG_ARRAY][MAXLEN_CONFIG_VALUE];
		int iCount = ExplodeString(sValue, " ; ", sValues, sizeof(sValues), sizeof(sValues[]));
		if (iCount == 0) return false;
		
		//Copy a random value in the array
		Format(sBuffer, iLength, sValues[GetRandomInt(0, iCount-1)]);
		return true;
	}
	
	public any GetInt(const char[] sKey, any iValue = 0)
	{
		if (this == null) return iValue;
		
		char sValue[MAXLEN_CONFIG_VALUE];
		if (!this.GetStringSingle(sKey, sValue, sizeof(sValue)))
			return iValue;
		
		return StringToInt(sValue);
	}
	
	public bool GetIntEx(const char[] sKey, any &iValue)
	{
		if (this == null) return false;
		
		char sValue[MAXLEN_CONFIG_VALUE];
		if (!this.GetStringSingle(sKey, sValue, sizeof(sValue)))
			return false;
		
		return !!StringToIntEx(sValue, iValue);
	}
	
	public ArrayList GetIntArray(const char[] sKey)
	{
		if (this == null) return null;
		
		char sValue[MAXLEN_CONFIG_VALUEARRAY];
		if (!this.GetString(sKey, sValue, sizeof(sValue)))
			return null;
		
		char sValues[MAX_CONFIG_ARRAY][12];
		int iCount = ExplodeString(sValue, " ; ", sValues, sizeof(sValues), sizeof(sValues[]));
		if (iCount == 0) return null;
		
		//Push all into array
		ArrayList aBuffer = new ArrayList();
		for (int i = 0; i < iCount; i++)
			aBuffer.Push(StringToInt(sValues[i]));
		
		return aBuffer;
	}
	
	public float GetFloat(const char[] sKey, float flValue = 0.0)
	{
		if (this == null) return flValue;
		
		char sValue[MAXLEN_CONFIG_VALUE];
		if (!this.GetStringSingle(sKey, sValue, sizeof(sValue)))
			return flValue;
		
		return StringToFloat(sValue);
	}
	
	public bool GetFloatEx(const char[] sKey, float &flValue)
	{
		if (this == null) return false;
		
		char sValue[MAXLEN_CONFIG_VALUE];
		if (!this.GetStringSingle(sKey, sValue, sizeof(sValue)))
			return false;
		
		return !!StringToFloatEx(sValue, flValue);
	}
	
	public ArrayList GetFloatArray(const char[] sKey)
	{
		if (this == null) return null;
		
		char sValue[MAXLEN_CONFIG_VALUEARRAY];
		if (!this.GetString(sKey, sValue, sizeof(sValue)))
			return null;
		
		char sValues[MAX_CONFIG_ARRAY][12];
		int iCount = ExplodeString(sValue, " ; ", sValues, sizeof(sValues), sizeof(sValues[]));
		if (iCount == 0) return null;
		
		//Push all into array
		ArrayList aBuffer = new ArrayList();
		for (int i = 0; i < iCount; i++)
			aBuffer.Push(StringToFloat(sValues[i]));
		
		return aBuffer;
	}
	
	public int GetTarget(int iClient)
	{
		if (this == null) return iClient;
		
		char sTarget[MAXLEN_CONFIG_VALUE];
		if (!this.GetStringSingle("target", sTarget, sizeof(sTarget)))
			return iClient;	//If not found, return client as default
		
		TagsTarget nTarget = TagsTarget_GetType(sTarget);
		return TagsTarget_GetTarget(iClient, nTarget, this);
	}
	
	public bool GetOverride(char[] sName, int iLength)
	{
		if (this == null) return false;
		
		return this.GetStringSingle("override", sName, iLength);
	}
	
	public bool CopyData(TagsParams tParams)
	{
		if (this == null || tParams == null) return false;
		
		StringMapSnapshot snapshot = this.Snapshot();
		int iLength = snapshot.Length;
		for (int i = 0; i < iLength; i++)
		{
			//Get key name
			int ikeyLength = snapshot.KeyBufferSize(i);
			char[] sKey = new char[ikeyLength];
			snapshot.GetKey(i, sKey, ikeyLength);
			
			//Get key value
			char sValue[MAXLEN_CONFIG_VALUEARRAY];
			this.GetString(sKey, sValue, sizeof(sValue));
			
			//If already exists, add as an "array"
			char sBuffer[MAXLEN_CONFIG_VALUEARRAY];
			if (tParams.GetString(sKey, sBuffer, sizeof(sBuffer)))
				Format(sValue, sizeof(sValue), "%s ; %s", sBuffer, sValue);
			
			//Add to StringMap
			tParams.SetString(sKey, sValue);
		}
		
		delete snapshot;
		return true;
	}
	
	property bool bOverride
	{
		public get()
		{
			if (this == null) return false;
			
			char sBuffer[1];
			if (this.GetString("override", sBuffer, sizeof(sBuffer)))
				return true;
			
			return false;
		}
	}
	
	property float flDelay
	{
		public get()
		{
			if (this == null) return -1.0;
			
			char sBuffer[12];
			if (this.GetStringSingle("delay", sBuffer, sizeof(sBuffer)))
				return StringToFloat(sBuffer);
			
			return -1.0;
		}
	}
	
	property int iCall
	{
		public get()
		{
			if (this == null) return 1;
			
			char sBuffer[12];
			if (this.GetStringSingle("call", sBuffer, sizeof(sBuffer)))
				return StringToInt(sBuffer);
			
			return 1;
		}
	}
	
	property float flRate
	{
		public get()
		{
			if (this == null) return 0.0;
			
			char sBuffer[12];
			if (this.GetStringSingle("rate", sBuffer, sizeof(sBuffer)))
				return StringToFloat(sBuffer);
			
			return 0.0;
		}
	}
}