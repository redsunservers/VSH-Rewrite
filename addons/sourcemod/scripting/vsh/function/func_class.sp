static StringMap g_mFuncClassPlugin;
static StringMap g_mFuncClassType;

void FuncClass_Init()
{
	g_mFuncClassPlugin = new StringMap();
	g_mFuncClassType = new StringMap();
}

bool FuncClass_Register(const char[] sClass, Handle hPlugin, SaxtonHaleClassType nClassType)
{
	if (!g_mFuncClassPlugin.SetValue(sClass, hPlugin, false))
		return false;
	
	if (!g_mFuncClassType.SetValue(sClass, nClassType, false))
		return false;
	
	return true;
}

void FuncClass_Unregister(const char[] sClass)
{
	g_mFuncClassPlugin.Remove(sClass);
	g_mFuncClassType.Remove(sClass);
}

bool FuncClass_Exists(const char[] sClass)
{
	SaxtonHaleClassType nBuffer;
	return g_mFuncClassType.GetValue(sClass, nBuffer);
}

Handle FuncClass_GetPlugin(const char[] sClass)
{
	Handle hPlugin = null;
	g_mFuncClassPlugin.GetValue(sClass, hPlugin);
	return hPlugin;
}

SaxtonHaleClassType FuncClass_GetType(const char[] sClass)
{
	SaxtonHaleClassType nClassType;
	g_mFuncClassType.GetValue(sClass, nClassType);
	return nClassType;
}

ArrayList FuncClass_GetAll()
{
	ArrayList aClass = new ArrayList(MAX_TYPE_CHAR);
	StringMapSnapshot snapshot = g_mFuncClassType.Snapshot();
	
	int iLength = snapshot.Length;
	for (int i = 0; i < iLength; i++)
	{
		char sClass[MAX_TYPE_CHAR];
		snapshot.GetKey(i, sClass, sizeof(sClass));
		aClass.PushString(sClass);
	}
	
	delete snapshot;
	return aClass;
}

ArrayList FuncClass_GetAllType(SaxtonHaleClassType nClassType)
{
	ArrayList aClass = new ArrayList(MAX_TYPE_CHAR);
	StringMapSnapshot snapshot = g_mFuncClassType.Snapshot();
	
	int iLength = snapshot.Length;
	for (int i = 0; i < iLength; i++)
	{
		char sClass[MAX_TYPE_CHAR];
		snapshot.GetKey(i, sClass, sizeof(sClass));
		
		SaxtonHaleClassType nBuffer;
		if (g_mFuncClassType.GetValue(sClass, nBuffer) && nBuffer == nClassType)
			aClass.PushString(sClass);
	}
	
	delete snapshot;
	return aClass;
}