enum struct HookEntityCreated
{
	char sClassname[256];			//Entity Classname to hook
	char sType[MAX_TYPE_CHAR];		//Class type
	char sFunction[MAX_TYPE_CHAR];	//Callback to call
}

static ArrayList g_aHelpersHookEntityCreated;
static ArrayList g_aHelpersTimers[TF_MAXPLAYERS+1];

void Helpers_Init()
{
	SaxtonHale_HookFunction("HookEntityCreated", Helpers_HookEntityCreatedPre, VSHHookMode_Pre);
	SaxtonHale_HookFunction("CreateTimer", Helpers_CreateTimerPre, VSHHookMode_Pre);
	SaxtonHale_HookFunction("KillTimer", Helpers_KillTimerPre, VSHHookMode_Pre);
	SaxtonHale_HookFunction("Destroy", Helpers_DestroyPost, VSHHookMode_Post);
}

void Helpers_MapEnd()
{
	//Clear everything to rehook from Precache 
	delete g_aHelpersHookEntityCreated;
}

void Helpers_Unregister(const char[] sClass)
{
	//Unregister all hooks from said class
	int iLength = g_aHelpersHookEntityCreated.Length;
	for (int i = iLength - 1; i >= 0; i--)
	{
		HookEntityCreated hook;
		g_aHelpersHookEntityCreated.GetArray(i, hook);
		if (StrEqual(hook.sType, sClass))
			g_aHelpersHookEntityCreated.Erase(i);
	}
}

public Action Helpers_HookEntityCreatedPre(SaxtonHaleBase boss)
{
	//Add given classname, class type and function to hook
	HookEntityCreated hook;
	SaxtonHale_GetParamString(1, hook.sClassname, sizeof(hook.sClassname));
	SaxtonHale_GetParamString(2, hook.sType, sizeof(hook.sType));
	SaxtonHale_GetParamString(3, hook.sFunction, sizeof(hook.sFunction));
	
	if (!g_aHelpersHookEntityCreated)
		g_aHelpersHookEntityCreated = new ArrayList(sizeof(HookEntityCreated));
	
	g_aHelpersHookEntityCreated.PushArray(hook);
	return Plugin_Stop;
}

void Helpers_OnEntityCreated(int iEntity, const char[] sClassname)
{
	if (!g_aHelpersTimers)
		return;
	
	//Loop though each hooks and call if equal to classname
	
	int iLength = g_aHelpersHookEntityCreated.Length;
	for (int i = iLength - 1; i >= 0; i--)
	{
		HookEntityCreated hook;
		g_aHelpersHookEntityCreated.GetArray(i, hook);
		if (StrEqual(hook.sClassname, sClassname))
		{
			SaxtonHaleBase boss = SaxtonHaleBase(0);
			if (boss.StartFunction(hook.sType, hook.sFunction))
			{
				Call_PushCell(iEntity);
				Call_Finish();
			}
			else
			{
				//Class not valid anymore, may well then remove hook
				g_aHelpersHookEntityCreated.Erase(i);
			}
		}
	}
}

public Action Helpers_CreateTimerPre(SaxtonHaleBase boss, Handle &hTimer)
{
	char sType[MAX_TYPE_CHAR], sFunction[MAX_TYPE_CHAR];
	float flDuration = SaxtonHale_GetParam(1);
	SaxtonHale_GetParamString(2, sType, sizeof(sType));
	SaxtonHale_GetParamString(3, sFunction, sizeof(sFunction));
	
	Handle hPlugin = SaxtonHale_GetPlugin(sType);
	if (!hPlugin)
	{
		hTimer = null;
		return Plugin_Stop;
	}
	
	char sBuffer[64];
	Format(sBuffer, sizeof(sBuffer), "%s.%s", sType, sFunction);
	Function func = GetFunctionByName(hPlugin, sBuffer);
	if (func == INVALID_FUNCTION)
	{
		hTimer = null;
		return Plugin_Stop;
	}
	
	DataPack data;
	hTimer = CreateDataTimer(flDuration, Timer_BossTimer, data);
	data.WriteCell(boss.iClient);
	data.WriteString(sType);
	data.WriteFunction(func);
	
	if (!g_aHelpersTimers[boss.iClient])
		g_aHelpersTimers[boss.iClient] = new ArrayList();
	
	g_aHelpersTimers[boss.iClient].Push(hTimer);
	
	return Plugin_Stop;
}

public Action Helpers_KillTimerPre(SaxtonHaleBase boss)
{
	if (!g_aHelpersTimers[boss.iClient])
		return Plugin_Stop;
	
	Handle hTimer = SaxtonHale_GetParam(1);
	int iPos = g_aHelpersTimers[boss.iClient].FindValue(hTimer);
	if (iPos < 0)
		return Plugin_Stop;
	
	g_aHelpersTimers[boss.iClient].Erase(iPos);
	KillTimer(hTimer);
	
	return Plugin_Stop;
}

public void Helpers_DestroyPost(SaxtonHaleBase boss)
{
	delete g_aHelpersTimers[boss.iClient];
}

public Action Timer_BossTimer(Handle hTimer, DataPack data)
{
	char sType[MAX_TYPE_CHAR];
	
	int iClient = data.ReadCell();
	data.ReadString(sType, sizeof(sType));
	Function func = data.ReadFunction();
	
	if (!g_aHelpersTimers[iClient])
		return;
	
	int iPos = g_aHelpersTimers[iClient].FindValue(hTimer);
	if (iPos < 0)
		return;
	
	g_aHelpersTimers[iClient].Erase(iPos);
	
	Handle hPlugin = SaxtonHale_GetPlugin(sType);
	if (!hPlugin)
		return;
	
	Call_StartFunction(hPlugin, func);
	Call_PushCell(iClient);
	Call_Finish();
	
	return;
}