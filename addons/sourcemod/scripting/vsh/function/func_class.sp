enum struct FuncClass
{
	char sName[MAX_TYPE_CHAR];
	Handle hPlugin;
	SaxtonHaleClassType nClassType;
}

methodmap FuncClassList < ArrayList
{
	public FuncClassList()
	{
		return view_as<FuncClassList>(new ArrayList(sizeof(FuncClass)));
	}
	
	public void Add(const char[] sName, Handle hPlugin, SaxtonHaleClassType nClassType)
	{
		FuncClass funcClass;
		strcopy(funcClass.sName, sizeof(funcClass.sName), sName);
		funcClass.hPlugin = hPlugin;
		funcClass.nClassType = nClassType;
		this.PushArray(funcClass);
	}
	
	public bool Remove(const char[] sName)
	{
		int iLength = this.Length;
		for (int i = 0; i < iLength; i++)
		{
			FuncClass funcClass;
			this.GetArray(i, funcClass);
			if (StrEqual(funcClass.sName, sName))
			{
				this.Erase(i);
				return true;
			}
		}
		
		return false;
	}
	
	public bool Exists(const char[] sName)
	{
		int iLength = this.Length;
		for (int i = 0; i < iLength; i++)
		{
			FuncClass funcClass;
			this.GetArray(i, funcClass);
			if (StrEqual(funcClass.sName, sName))
				return true;
		}
		
		return false;
	}
	
	public Handle GetPlugin(const char[] sName)
	{
		int iLength = this.Length;
		for (int i = 0; i < iLength; i++)
		{
			FuncClass funcClass;
			this.GetArray(i, funcClass);
			if (StrEqual(funcClass.sName, sName))
				return funcClass.hPlugin;
		}
		
		return null;
	}
	
	public SaxtonHaleClassType GetType(const char[] sName)
	{
		int iLength = this.Length;
		for (int i = 0; i < iLength; i++)
		{
			FuncClass funcClass;
			this.GetArray(i, funcClass);
			if (StrEqual(funcClass.sName, sName))
				return funcClass.nClassType;
		}
		
		return VSHClassType_Core;	//Why do we not have invalid version of this enum...
	}
	
	public ArrayList GetAll()
	{
		ArrayList aClass = new ArrayList(MAX_TYPE_CHAR);
		
		int iLength = this.Length;
		for (int i = 0; i < iLength; i++)
		{
			FuncClass funcClass;
			this.GetArray(i, funcClass);
			aClass.PushString(funcClass.sName);
		}
		
		return aClass;
	}
	
	public ArrayList GetAllType(SaxtonHaleClassType nClassType)
	{
		ArrayList aClass = new ArrayList(MAX_TYPE_CHAR);
		
		int iLength = this.Length;
		for (int i = 0; i < iLength; i++)
		{
			FuncClass funcClass;
			this.GetArray(i, funcClass);
			if (funcClass.nClassType == nClassType)
				aClass.PushString(funcClass.sName);
		}
		
		return aClass;
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
		while ((iPos = this.FindValue(hPlugin, FuncClass::hPlugin)) != -1)
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
				Handle hPlugin = this.Get(i, FuncClass::hPlugin);
				if (!this.IsPluginLoaded(hPlugin))
				{
					this.ClearPlugin(hPlugin);
					bCleared = true;
					break;
				}
			}
		}
		while (bCleared);
	}
}