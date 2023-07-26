enum struct FuncClass
{
	char sName[MAX_TYPE_CHAR];
	Handle hPlugin;
	SaxtonHaleClassType nClassType;
}

static ArrayList g_aFuncClasses;
static ArrayList g_aClientClasses[MAXPLAYERS];
static StringMap g_mClientProps[MAXPLAYERS];	//StringMap inside a StringMap!

void FuncClass_Init()
{
	g_aFuncClasses = new ArrayList(sizeof(FuncClass));
}

void FuncClass_Add(const char[] sName, Handle hPlugin, SaxtonHaleClassType nClassType)
{
	FuncClass funcClass;
	strcopy(funcClass.sName, sizeof(funcClass.sName), sName);
	funcClass.hPlugin = hPlugin;
	funcClass.nClassType = nClassType;
	g_aFuncClasses.PushArray(funcClass);
}
	
bool FuncClass_Remove(const char[] sName)
{
	int iLength = g_aFuncClasses.Length;
	for (int i = 0; i < iLength; i++)
	{
		FuncClass funcClass;
		g_aFuncClasses.GetArray(i, funcClass);
		if (StrEqual(funcClass.sName, sName))
		{
			g_aFuncClasses.Erase(i);
			return true;
		}
	}
	
	return false;
}

bool FuncClass_Exists(const char[] sName)
{
	int iLength = g_aFuncClasses.Length;
	for (int i = 0; i < iLength; i++)
	{
		FuncClass funcClass;
		g_aFuncClasses.GetArray(i, funcClass);
		if (StrEqual(funcClass.sName, sName))
			return true;
	}
	
	return false;
}

Handle FuncClass_GetPlugin(const char[] sName)
{
	int iLength = g_aFuncClasses.Length;
	for (int i = 0; i < iLength; i++)
	{
		FuncClass funcClass;
		g_aFuncClasses.GetArray(i, funcClass);
		if (StrEqual(funcClass.sName, sName))
			return funcClass.hPlugin;
	}
	
	return null;
}
	
SaxtonHaleClassType FuncClass_GetType(const char[] sName)
{
	int iLength = g_aFuncClasses.Length;
	for (int i = 0; i < iLength; i++)
	{
		FuncClass funcClass;
		g_aFuncClasses.GetArray(i, funcClass);
		if (StrEqual(funcClass.sName, sName))
			return funcClass.nClassType;
	}
	
	return VSHClassType_Core;	//Why do we not have invalid version of this enum...
}

ArrayList FuncClass_GetAll()
{
	ArrayList aClass = new ArrayList(MAX_TYPE_CHAR);
	
	int iLength = g_aFuncClasses.Length;
	for (int i = 0; i < iLength; i++)
	{
		FuncClass funcClass;
		g_aFuncClasses.GetArray(i, funcClass);
		aClass.PushString(funcClass.sName);
	}
	
	return aClass;
}
	
ArrayList FuncClass_GetAllType(SaxtonHaleClassType nClassType)
{
	ArrayList aClass = new ArrayList(MAX_TYPE_CHAR);
	
	int iLength = g_aFuncClasses.Length;
	for (int i = 0; i < iLength; i++)
	{
		FuncClass funcClass;
		g_aFuncClasses.GetArray(i, funcClass);
		if (funcClass.nClassType == nClassType)
			aClass.PushString(funcClass.sName);
	}
	
	return aClass;
}

void FuncClass_ClearUnloadedPlugin(Handle hPlugin)
{
	int iPos = -1;
	while ((iPos = g_aFuncClasses.FindValue(hPlugin, FuncClass::hPlugin)) != -1)
		g_aFuncClasses.Erase(iPos);
}

void FuncClass_ClientCreate(SaxtonHaleBase boss, const char[] sClass, bool bCreate = true)
{
	if (FuncClass_GetType(sClass) == VSHClassType_Modifier)
		boss.bModifiers = true;
	
	if (!g_aClientClasses[boss.iClient])
	{
		g_mClientProps[boss.iClient] = new StringMap();
		g_aClientClasses[boss.iClient] = new ArrayList(ByteCountToCells(MAX_TYPE_CHAR));
		
		if (bCreate)
		{
			g_aClientClasses[boss.iClient].PushString("SaxtonHaleBoss");
			
			boss.bValid = true;
			if (boss.StartFunction("SaxtonHaleBoss", "Create"))
				Call_Finish();
		}
	}
	
	g_aClientClasses[boss.iClient].PushString(sClass);
	if (bCreate && boss.StartFunction(sClass, "Create"))
		Call_Finish();
	
	g_aClientClasses[boss.iClient].SortCustom(FuncClass_Sort);
}

public int FuncClass_Sort(int index1, int index2, Handle hArray, Handle hHandle)
{
	char sClass1[MAX_TYPE_CHAR], sClass2[MAX_TYPE_CHAR];
	GetArrayString(hArray, index1, sClass1, sizeof(sClass1));	//Callback using legacy handle reeee
	GetArrayString(hArray, index2, sClass2, sizeof(sClass2));
	SaxtonHaleClassType nType1 = FuncClass_GetType(sClass1);
	SaxtonHaleClassType nType2 = FuncClass_GetType(sClass2);
	
	if (nType1 > nType2)
		return 1;
	else if (nType1 == nType2)
		return 0;
	else
		return -1;
}

bool FuncClass_ClientGetClass(int iClient, int &iPos, char[] sClass, int iLength)
{
	if (!g_aClientClasses[iClient] || iPos < 0 || iPos >= g_aClientClasses[iClient].Length)
		return false;
	
	g_aClientClasses[iClient].GetString(iPos, sClass, iLength);
	iPos++;
	return true;
}

bool FuncClass_ClientHasClass(int iClient, const char[] sClass)
{
	if (!g_aClientClasses[iClient])
		return false;
	
	return g_aClientClasses[iClient].FindString(sClass) >= 0;
}

void FuncClass_ClientDestroyClass(SaxtonHaleBase boss, const char[] sClass)
{
	int iIndex = g_aClientClasses[boss.iClient].FindString(sClass);
	if (iIndex == -1)
		return;
	
	if (boss.StartFunction(sClass, "Destroy"))
		Call_Finish();
	
	StringMap mProps;
	if (g_mClientProps[boss.iClient].GetValue(sClass, mProps))
		delete mProps;
	
	g_aClientClasses[boss.iClient].Erase(iIndex);
}

void FuncClass_ClientDestroyAllClass(SaxtonHaleBase boss, bool bDestroy = true)
{
	boss.bValid = false;
	boss.bModifiers = false;
	
	int iLength = g_aClientClasses[boss.iClient].Length;
	for (int i = 0; i < iLength; i++)
	{
		char sClass[MAX_TYPE_CHAR];
		g_aClientClasses[boss.iClient].GetString(i, sClass, sizeof(sClass));
		
		if (bDestroy && boss.StartFunction(sClass, "Destroy"))
			Call_Finish();
		
		StringMap mProps;
		if (g_mClientProps[boss.iClient].GetValue(sClass, mProps))
			delete mProps;
	}
	
	delete g_aClientClasses[boss.iClient];
	delete g_mClientProps[boss.iClient];
}

bool FuncClass_GetProp(int iClient, const char[] sClass, const char[] sProp, any &val)
{
	StringMap mProps;
	if (!g_mClientProps[iClient].GetValue(sClass, mProps))
		return false;
	
	return mProps.GetValue(sProp, val);
}

void FuncClass_SetProp(int iClient, const char[] sClass, const char[] sProp, any val)
{
	StringMap mProps;
	if (!g_mClientProps[iClient].GetValue(sClass, mProps))
	{
		mProps = new StringMap();
		g_mClientProps[iClient].SetValue(sClass, mProps);
	}
	
	mProps.SetValue(sProp, val);
}