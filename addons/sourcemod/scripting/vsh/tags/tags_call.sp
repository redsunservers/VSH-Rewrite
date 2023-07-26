enum TagsCall	//List of possible ways to call tags
{
	TagsCall_Invalid = -1,
	
	TagsCall_Banner,
	TagsCall_Uber,
	TagsCall_Jarate,
	TagsCall_Spawn,
	TagsCall_Lunchbox,
	TagsCall_Think,
	TagsCall_Projectile,
	TagsCall_AttackDamage,
	TagsCall_TakeDamage,
	TagsCall_Attack,
	TagsCall_Heal,
	
	TagsCall_MAX,
};

TagsCall TagsCall_GetType(const char[] sCall)
{
	static StringMap mCall;
	
	if (mCall == null)
	{
		mCall = new StringMap();
		mCall.SetValue("banner", TagsCall_Banner);
		mCall.SetValue("uber", TagsCall_Uber);
		mCall.SetValue("jarate", TagsCall_Jarate);
		mCall.SetValue("spawn", TagsCall_Spawn);
		mCall.SetValue("lunchbox", TagsCall_Lunchbox);
		mCall.SetValue("think", TagsCall_Think);
		mCall.SetValue("projectile", TagsCall_Projectile);
		mCall.SetValue("attackdamage", TagsCall_AttackDamage);
		mCall.SetValue("takedamage", TagsCall_TakeDamage);
		mCall.SetValue("attack", TagsCall_Attack);
		mCall.SetValue("heal", TagsCall_Heal);
	}
	
	TagsCall nCall = TagsCall_Invalid;
	mCall.GetValue(sCall, nCall);
	return nCall;
}

static ArrayList g_aTagsCallTimer[MAXPLAYERS];	//Arrays of pending function timers to be called

void TagsCall_Init()
{
	for (int iClient = 1; iClient <= MaxClients; iClient++)
		g_aTagsCallTimer[iClient] = new ArrayList();
}

void TagsCall_ClearTimer(int iClient)
{
	g_aTagsCallTimer[iClient].Clear();
}

void TagsCall_CallDelay(Function func, int iClient, TagsParams tParams, int iCall, float flDuration)
{
	//Create delay timer
	DataPack data;
	Handle hTimer = CreateDataTimer(flDuration, TagsCall_TimerDelay, data);
	data.WriteFunction(func);
	data.WriteCell(EntIndexToEntRef(iClient));
	data.WriteCell(tParams);
	data.WriteCell(iCall);
	
	//Push timer to array
	g_aTagsCallTimer[iClient].Push(hTimer);
}

public Action TagsCall_TimerDelay(Handle hTimer, DataPack data)
{
	data.Reset();
	Function func = data.ReadFunction();
	int iClient = EntRefToEntIndex(data.ReadCell());
	TagsParams tParams = data.ReadCell();
	int iCall = data.ReadCell();
	
	//Valid client check
	if (iClient <= 0 || iClient > MaxClients || !IsClientInGame(iClient))
	{
		delete tParams;
		return Plugin_Continue;
	}
	
	//Check if timer still valid to be called
	int iIndex = g_aTagsCallTimer[iClient].FindValue(hTimer);
	if (iIndex == -1)
	{
		delete tParams;
		return Plugin_Continue;
	}
	
	//Remove pending timer from array as it done.
	g_aTagsCallTimer[iClient].Erase(iIndex);
	
	//Player alive check
	if (!IsPlayerAlive(iClient))
	{
		delete tParams;
		return Plugin_Continue;
	}
	
	//Call function
	TagsCall_Call(func, iClient, tParams, iCall);
	return Plugin_Continue;
}

void TagsCall_Call(Function func, int iClient, TagsParams tParams, int iCall)
{
	int iTarget = tParams.GetTarget(iClient);
	
	Call_StartFunction(null, func);
	Call_PushCell(iClient);
	Call_PushCell(iTarget);
	Call_PushCell(tParams);
	Call_Finish();
	
	//Reduce call count remaining
	iCall--;
	
	//If there still any remaining calls, create timer to call again
	if (iCall > 0)
	{
		if (tParams.flRate > 0.0)
			TagsCall_CallDelay(func, iClient, tParams, iCall, tParams.flRate);
		else	//0.0 delay, no need to create delay timer
			TagsCall_Call(func, iClient, tParams, iCall);
	}
	else
	{
		//Free the cloned param
		delete tParams;
	}
}