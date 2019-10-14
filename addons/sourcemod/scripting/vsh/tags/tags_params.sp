methodmap TagsParams < StringMap
{
	public TagsParams()
	{
		return view_as<TagsParams>(new StringMap());
	}
	
	public any GetInt(const char[] sKey, any iValue = 0)
	{
		if (this == null)
			return iValue;
		
		char sValue[MAXLEN_CONFIG_VALUE];
		if (!this.GetString(sKey, sValue, sizeof(sValue)))
			return iValue;
		
		return StringToInt(sValue);
	}
	
	public bool GetIntEx(const char[] sKey, any &iValue)
	{
		if (this == null)
			return false;
		
		char sValue[MAXLEN_CONFIG_VALUE];
		if (!this.GetString(sKey, sValue, sizeof(sValue)))
			return false;
		
		return !!StringToIntEx(sValue, iValue);
	}
	
	public float GetFloat(const char[] sKey, float flValue = 0.0)
	{
		if (this == null)
			return flValue;
		
		char sValue[MAXLEN_CONFIG_VALUE];
		if (!this.GetString(sKey, sValue, sizeof(sValue)))
			return flValue;
		
		return StringToFloat(sValue);
	}
	
	public bool GetFloatEx(const char[] sKey, float &flValue)
	{
		if (this == null)
			return false;
		
		char sValue[MAXLEN_CONFIG_VALUE];
		if (!this.GetString(sKey, sValue, sizeof(sValue)))
			return false;
		
		return !!StringToFloatEx(sValue, flValue);
	}
	
	public int GetTarget(int iClient)
	{
		if (this == null)
			return iClient;
		
		char sTarget[MAXLEN_CONFIG_VALUE];
		if (!this.GetString("target", sTarget, sizeof(sTarget)))
			return iClient;	//If not found, return client as default
		
		TagsTarget nTarget = TagsTarget_GetType(sTarget);
		return TagsTarget_GetTarget(iClient, nTarget);
	}
	
	public bool GetOverride(char[] sName, int iLength)
	{
		if (this == null)
			return false;
		
		return this.GetString("override", sName, iLength);
	}
	
	public bool CopyData(TagsParams tParams)
	{
		if (this == null)
			return false;
		
		StringMapSnapshot snapshot = this.Snapshot();
		int iLength = snapshot.Length;
		for (int i = 0; i < iLength; i++)
		{
			//Get key name
			int ikeyLength = snapshot.KeyBufferSize(i);
			char[] sKey = new char[ikeyLength];
			snapshot.GetKey(i, sKey, ikeyLength);
			
			//Get key value
			char sValue[MAXLEN_CONFIG_VALUE];
			this.GetString(sKey, sValue, sizeof(sValue));
			
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
			if (this == null)
				return false;
			
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
			if (this == null)
				return -1.0;
			
			char sBuffer[8];
			if (this.GetString("delay", sBuffer, sizeof(sBuffer)))
				return StringToFloat(sBuffer);
			
			return -1.0;
		}
	}
	
	property int iCall
	{
		public get()
		{
			if (this == null)
				return 1;
			
			char sBuffer[8];
			if (this.GetString("call", sBuffer, sizeof(sBuffer)))
				return StringToInt(sBuffer);
			
			return 1;
		}
	}
	
	property float flRate
	{
		public get()
		{
			if (this == null)
				return 0.0;
			
			char sBuffer[8];
			if (this.GetString("rate", sBuffer, sizeof(sBuffer)))
				return StringToFloat(sBuffer);
			
			return 0.0;
		}
	}
}