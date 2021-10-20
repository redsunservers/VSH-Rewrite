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
	
	public void ClearUnloadedPlugin()
	{
		//TODO use OnNotifyPluginUnloaded when SM 1.11 is stable
		ArrayList aPlugins = new ArrayList();
		Handle hIterator = GetPluginIterator();
		while (MorePlugins(hIterator))
			aPlugins.Push(ReadPlugin(hIterator));
		
		delete hIterator;
		aPlugins.Push(GetMyHandle());	//My handle is not in iterator during OnPluginEnd
		
		int iLength = this.Length;
		for (int iPos = iLength - 1; iPos >= 0; iPos--)
			if (aPlugins.FindValue(this.Get(iPos, FuncClass::hPlugin)) == -1)
				this.Erase(iPos);
		
		delete aPlugins;
	}
}