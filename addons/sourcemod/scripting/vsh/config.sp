#define CONFIG_FILE "configs/vsh/vsh.cfg"
#define CONFIG_MAPS "configs/vsh/maps.cfg"

methodmap ConfigClass < StringMap
{
	public ConfigClass()
	{
		return view_as<ConfigClass>(new StringMap());
	}
	
	public void LoadSection(KeyValues kv, TFClassType nClass, int iSlot)
	{
		if (kv.JumpToKey("class", false))	//Jump to "class"
		{
			if (kv.JumpToKey(g_strClassName[nClass], false))	//Jump to TF2 class name
			{
				if (kv.JumpToKey(g_strSlotName[iSlot], false))	//Jump to slot name
				{
					if (kv.GotoFirstSubKey(false))		//Go to first subkeys (attrib, desp etc)
					{
						do								//Loop through each subkeys from that slot
						{
							char sSubkey[MAXLEN_CONFIG_VALUE];
							kv.GetSectionName(sSubkey, sizeof(sSubkey));	//Subkey (attrib, desp etc)
							StrToLower(sSubkey);	//Convert string to lowercase, KeyValues rarely read 1st letter as uppercase...
							
							TagsCall nCall = TagsCall_GetType(sSubkey);
							if (nCall != TagsCall_Invalid)
							{
								//Tags stuff
								Tags tagsStruct;
								tagsStruct.nClass = nClass;
								tagsStruct.iSlot = iSlot;
								tagsStruct.iIndex = -1;
								tagsStruct.nCall = nCall;
								tagsStruct.Load(kv);
							}
							else
							{
								char sValue[MAXLEN_CONFIG_VALUE];
								kv.GetString(NULL_STRING, sValue, sizeof(sValue), "");	//Value of that subkey
								this.SetString(sSubkey, sValue);
							}
						}
						while (kv.GotoNextKey(false));
						kv.GoBack();
					}
					kv.GoBack();
				}
				kv.GoBack();
			}
			kv.GoBack();
		}
	}
	
	//Return string list of changed attributes weapon slot from class should have, false if doesnt exist
	public bool GetAttrib(char[] sValue, int iLength)
	{
		return this.GetString("attrib", sValue, iLength);
	}
	
	//Return string desp of weapon slot changes, false if doesnt exist
	public bool GetDesp(char[] sValue, int iLength)
	{
		return this.GetString("desp", sValue, iLength);
	}
	
	//Return 1 if class slot should have minicrit, 0 if should not have one, -1 if not specified
	public int IsMinicrit()
	{
		char sValue[MAXLEN_CONFIG_VALUE];
		if (this.GetString("minicrit", sValue, sizeof(sValue)))
			return StringToInt(sValue);
		
		else return -1;
	}
	
	//Return 1 if class slot should have crit, 0 if should not have one, -1 if not specified
	public int IsCrit()
	{
		char sValue[MAXLEN_CONFIG_VALUE];
		if (this.GetString("crit", sValue, sizeof(sValue)))
			return StringToInt(sValue);
		
		else return -1;
	}
	
	//Return clip size class slot should have on spawn, -1 if not specified
	public int GetClip()
	{
		char sValue[MAXLEN_CONFIG_VALUE];
		if (this.GetString("clip", sValue, sizeof(sValue)))
			return StringToInt(sValue);
		
		else return -1;
	}
	
	//Return whenever to ignore damage falloff
	public int IgnoreFalloff()
	{
		char sValue[MAXLEN_CONFIG_VALUE];
		if (this.GetString("ignorefalloff", sValue, sizeof(sValue)))
			return StringToInt(sValue);
		
		else return -1;
	}
};

methodmap ConfigIndex < ArrayList
{
	public ConfigIndex()
	{
		return view_as<ConfigIndex>(new ArrayList(2));	//0 for int index, 1 for StringMap handle
	}
	
	public void LoadSection(KeyValues kv)
	{
		if (kv.JumpToKey("weapons", false))	//Jump to "weapons"
		{
			if (kv.GotoFirstSubKey(false))	//Go to the first key of weapon index
			{
				do							//Loop through each weapon index
				{
					char sIndex[MAXLEN_CONFIG_VALUE];
					kv.GetSectionName(sIndex, sizeof(sIndex));	//Index of the weapon
					int iIndex = StringToInt(sIndex);
					StringMap sMap = new StringMap();
					
					if (kv.GotoFirstSubKey(false))		//Go to first subkeys from that index (attrib, desp etc)
					{
						do								//Loop through each subkeys from that index
						{
							char sSubkey[MAXLEN_CONFIG_VALUE];
							kv.GetSectionName(sSubkey, sizeof(sSubkey));	//Subkey (attrib, desp etc)
							StrToLower(sSubkey);	//Convert string to lowercase, KeyValues rarely read 1st letter as uppercase...
							
							TagsCall nCall = TagsCall_GetType(sSubkey);
							if (nCall != TagsCall_Invalid)
							{
								//Tags stuff
								Tags tagsStruct;
								tagsStruct.nClass = TFClass_Unknown;
								tagsStruct.iSlot = -1;
								tagsStruct.iIndex = iIndex;
								tagsStruct.nCall = nCall;
								tagsStruct.Load(kv);
							}
							else
							{
								char sValue[MAXLEN_CONFIG_VALUE];
								kv.GetString(NULL_STRING, sValue, sizeof(sValue), "");	//Value of that subkey
								sMap.SetString(sSubkey, sValue);
							}
						}
						while(kv.GotoNextKey(false));
						kv.GoBack();
					}
					
					int iSize = this.Length;
					this.Resize(iSize+1);
					this.Set(iSize, iIndex, 0);
					this.Set(iSize, sMap, 1);
				}
				while(kv.GotoNextKey(false));
				kv.GoBack();
			}
			kv.GoBack();
		}
	}
	
	//Return StringMap of specified item index while also taking into account with prefabs, null if not found
	public StringMap GetStringMap(int iIndex)
	{
		int iValue = this.FindValue(iIndex, 0);
		if (iValue >= 0)
		{
			StringMap sMap = this.Get(iValue, 1);
			
			//Check for prefabs
			char sValue[MAXLEN_CONFIG_VALUE];
			if (sMap.GetString("prefab", sValue, sizeof(sValue)))
				return Config_GetStringMap(StringToInt(sValue));	//Recursion
			
			return sMap;
		}
		
		return null;
	}
	
	//Return whenever if index is a prefab or not
	public bool IsPrefab(int iIndex)
	{
		int iValue = this.FindValue(iIndex, 0);
		if (iValue >= 0)
		{
			StringMap sMap = this.Get(iValue, 1);
			
			char sValue[MAXLEN_CONFIG_VALUE];
			if (sMap.GetString("prefab", sValue, sizeof(sValue)))
				return true;
		}
		
		return false;
	}
	
	//Return index's prefab. Returns same index if not found
	public int GetPrefab(int iIndex)
	{
		int iValue = this.FindValue(iIndex, 0);
		if (iValue >= 0)
		{
			StringMap sMap = this.Get(iValue, 1);
			
			char sValue[MAXLEN_CONFIG_VALUE];
			if (sMap.GetString("prefab", sValue, sizeof(sValue)))
				return Config_GetPrefab(StringToInt(sValue));	//Recursion
		}
		
		return iIndex;
	}
	
	//Return true if weapon index should be banned, false otherwise
	public bool IsRestricted(int iIndex)
	{
		StringMap sMap = this.GetStringMap(iIndex);
		if (sMap == null) return false;
		
		char sValue[MAXLEN_CONFIG_VALUE];
		sMap.GetString("restricted", sValue, sizeof(sValue));
		return view_as<bool>(StringToInt(sValue));
	}
	
	//Return string list of changed attributes weapon index should have, false if doesnt exist
	public bool GetAttrib(int iIndex, char[] sValue, int iLength)
	{
		StringMap sMap = this.GetStringMap(iIndex);
		if (sMap == null) return false;
		
		return sMap.GetString("attrib", sValue, iLength);
	}
	
	//Return string desp of weapon index changes, false if doesnt exist
	public bool GetDesp(int iIndex, char[] sValue, int iLength)
	{
		StringMap sMap = this.GetStringMap(iIndex);
		if (sMap == null) return false;
		
		return sMap.GetString("desp", sValue, iLength);
	}
	
	//Return 1 if weapon index should have minicrit, 0 if should not have one, -1 if not specified
	public int IsMinicrit(int iIndex)
	{
		StringMap sMap = this.GetStringMap(iIndex);
		if (sMap == null) return -1;
		
		char sValue[MAXLEN_CONFIG_VALUE];
		if (sMap.GetString("minicrit", sValue, sizeof(sValue)))
			return StringToInt(sValue);
		
		return -1;
	}
	
	//Return 1 if weapon index should have crit, 0 if should not have one, -1 if not specified
	public int IsCrit(int iIndex)
	{
		StringMap sMap = this.GetStringMap(iIndex);
		if (sMap == null) return -1;
		
		char sValue[MAXLEN_CONFIG_VALUE];
		if (sMap.GetString("crit", sValue, sizeof(sValue)))
			return StringToInt(sValue);
		
		return -1;
	}
	
	//Return clip size weapon index should have on spawn, -1 if not specified
	public int GetClip(int iIndex)
	{
		StringMap sMap = this.GetStringMap(iIndex);
		if (sMap == null) return -1;
		
		char sValue[MAXLEN_CONFIG_VALUE];
		if (sMap.GetString("clip", sValue, sizeof(sValue)))
			return StringToInt(sValue);
		
		else return -1;
	}
	
	//Return whenever to ignore damage falloff
	public int IgnoreFalloff(int iIndex)
	{
		StringMap sMap = this.GetStringMap(iIndex);
		if (sMap == null) return -1;
		
		char sValue[MAXLEN_CONFIG_VALUE];
		if (sMap.GetString("ignorefalloff", sValue, sizeof(sValue)))
			return StringToInt(sValue);
		
		else return -1;
	}
};

methodmap ConfigConvar < StringMap
{
	public ConfigConvar()
	{
		return view_as<ConfigConvar>(new StringMap());
	}
	
	public void LoadSection(KeyValues kv, const char[] sSection)
	{
		if(kv.JumpToKey(sSection, false))
		{
			if(kv.GotoFirstSubKey(false))
			{
				do
				{
					char sName[MAXLEN_CONFIG_VALUE];
					char sValue[MAXLEN_CONFIG_VALUE];
					
					kv.GetSectionName(sName, sizeof(sName));
					kv.GetString(NULL_STRING, sValue, sizeof(sValue), "");
					
					//Set value to StringMap and convar
					this.SetString(sName, sValue);
					ConVar convar = FindConVar(sName);
					if (convar != null)
						convar.SetString(sValue);
				}
				while(kv.GotoNextKey(false));
				kv.GoBack();
			}
			kv.GoBack();
		}
	}
	
	public ConVar Create(const char[] sName, const char[] sValue, const char[] sDesp, int iFlags=0, bool bMin=false, float flMin=0.0, bool bMax=false, float flMax=0.0)
	{
		ConVar convar = CreateConVar(sName, sValue, sDesp, iFlags, bMin, flMin, bMax, flMax);
		this.SetString(sName, sValue);
		convar.AddChangeHook(Config_ConvarChanged);
		return convar;
	}
	
	public void Changed(ConVar convar, const char[] sValue)
	{
		char sName[MAXLEN_CONFIG_VALUE];
		convar.GetName(sName, sizeof(sName));
		this.SetString(sName, sValue);
	}
	
	public int LookupInt(const char[] sName)
	{
		char sValue[MAXLEN_CONFIG_VALUE];
		this.GetString(sName, sValue, sizeof(sValue));
		return StringToInt(sValue);
	}
	
	public float LookupFloat(const char[] sName)
	{
		char sValue[MAXLEN_CONFIG_VALUE];
		this.GetString(sName, sValue, sizeof(sValue));
		return StringToFloat(sValue);
	}
	
	public bool LookupBool(const char[] sName)
	{
		char sValue[MAXLEN_CONFIG_VALUE];
		this.GetString(sName, sValue, sizeof(sValue));
		return (!!StringToInt(sValue));
	}
	
	public void LookupString(const char[] sName, char sValue[MAXLEN_CONFIG_VALUE])
	{
		this.GetString(sName, sValue, sizeof(sValue));
	}
	
	public bool LookupIntArray(const char[] sName, int[] iArray, int iLength)
	{
		char sValue[MAXLEN_CONFIG_VALUE];
		this.GetString(sName, sValue, sizeof(sValue));
		
		char[][] sArray = new char[iLength][12];
		if (ExplodeString(sValue, " ", sArray, iLength, 12) != iLength)
			return false;
		
		for (int i = 0; i < iLength; i++)
			iArray[i] = StringToInt(sArray[i]);
		
		return true;
	}
	
	public bool LookupFloatArray(const char[] sName, float[] flArray, int iLength)
	{
		char sValue[MAXLEN_CONFIG_VALUE];
		this.GetString(sName, sValue, sizeof(sValue));
		
		char[][] sArray = new char[iLength][12];
		if (ExplodeString(sValue, " ", sArray, iLength, 12) != iLength)
			return false;
		
		for (int i = 0; i < iLength; i++)
			flArray[i] = StringToFloat(sArray[i]);
		
		return true;
	}
};

ConfigClass g_ConfigClass[10][WeaponSlot_BuilderEngie+1];	//Double array of StringMap
ConfigIndex g_ConfigIndex;		//ArrayList of StringMap, should use enum struct once 1.10 reaches stable
ConfigConvar g_ConfigConvar;	//StringMap

void Config_Init()
{
	for (int iClass = 1; iClass < sizeof(g_ConfigClass); iClass++)
		for (int iSlot = 0; iSlot < sizeof(g_ConfigClass[]); iSlot++)
			g_ConfigClass[iClass][iSlot] = new ConfigClass();
	
	g_ConfigIndex = new ConfigIndex();
	g_ConfigConvar = new ConfigConvar();
}

void Config_Refresh()
{
	for (int iClass = 1; iClass < sizeof(g_ConfigClass); iClass++)
		for (int iSlot = 0; iSlot < sizeof(g_ConfigClass[]); iSlot++)
			g_ConfigClass[iClass][iSlot].Clear();
	
	int iLength = g_ConfigIndex.Length;
	if (iLength > 0)
	{
		for (int i = 0; i < iLength; i++)
		{
			ConfigIndex configIndex = g_ConfigIndex.Get(i, 1);
			delete configIndex;
		}
	}
	
	g_ConfigIndex.Clear();
	TagsCore_Clear();
	TagsName_Clear();
	
	KeyValues kv = Config_LoadFile(CONFIG_FILE);
	if (kv == null) return;
	
	//Load each class and slots
	for (int iClass = 1; iClass < sizeof(g_ConfigClass); iClass++)
		for (int iSlot = 0; iSlot < sizeof(g_ConfigClass[]); iSlot++)
			g_ConfigClass[iClass][iSlot].LoadSection(kv, view_as<TFClassType>(iClass), iSlot);
	
	//Load every indexs
	g_ConfigIndex.LoadSection(kv);
	
	//Load convars
	g_ConfigConvar.LoadSection(kv, "cvars");
	
	//Load map specific convars to override default
	delete kv;
	kv = Config_LoadFile(CONFIG_MAPS);
	if (kv == null) return;
	
	if (kv.JumpToKey("maps", false))
	{
		//Get map name
		char sMapName[64];
		GetCurrentMap(sMapName, sizeof(sMapName));
		GetMapDisplayName(sMapName, sMapName, sizeof(sMapName));
		
		if (kv.GotoFirstSubKey(false))		//Go to the first key of maps
		{
			do								//Loop through each maps
			{
				char bufferMaps[MAXLEN_CONFIG_VALUE];
				kv.GetSectionName(bufferMaps, sizeof(bufferMaps));	//Get map name
				
				//Check if the buffer is what we wanted
				if (StrContains(sMapName, bufferMaps, false) == 0)
				{
					//We found it, load that section
					kv.GoBack();
					g_ConfigConvar.LoadSection(kv, bufferMaps);
					break;
				}
			}
			
			while(kv.GotoNextKey(false));
			kv.GoBack();
		}
	}
	
	delete kv;
	
	TagsName_Load();
	for (int iClient = 1; iClient <= MaxClients; iClient++)
		TagsCore_RefreshClient(iClient);
	
	ClassLimit_Refresh();
	Cookies_Refresh();
	MenuWeapon_Refresh();
}

KeyValues Config_LoadFile(const char[] configFile)
{
	char configPath[PLATFORM_MAX_PATH];
	
	BuildPath(Path_SM, configPath, sizeof(configPath), configFile);
	if (!FileExists(configPath))
	{
		LogMessage("Failed to load vsh config file (file missing): %s!", configPath);
		return null;
	}
	
	KeyValues kv = new KeyValues("Config");
	kv.SetEscapeSequences(true);

	if(!kv.ImportFromFile(configPath))
	{
		LogMessage("Failed to parse vsh config file: %s!", configPath);
		delete kv;
		return null;
	}
	
	return kv;
}

stock StringMap Config_GetStringMap(int iIndex)
{
	return g_ConfigIndex.GetStringMap(iIndex);
}

stock int Config_GetPrefab(int iIndex)
{
	return g_ConfigIndex.GetPrefab(iIndex);
}

public void Config_ConvarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_ConfigConvar.Changed(convar, newValue);
}