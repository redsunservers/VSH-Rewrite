enum TagsCall	//List of possible ways to call tags
{
	TagsCall_Invalid = -1,
	
	TagsCall_Banner,
	TagsCall_Uber,
	TagsCall_Jarate,
	TagsCall_Spawn,
	TagsCall_Think,
	TagsCall_AttackDamage,
	TagsCall_TakeDamage,
	TagsCall_Attack,
	TagsCall_Heal,
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
		mCall.SetValue("think", TagsCall_Think);
		mCall.SetValue("attackdamage", TagsCall_AttackDamage);
		mCall.SetValue("takedamage", TagsCall_TakeDamage);
		mCall.SetValue("attack", TagsCall_Attack);
		mCall.SetValue("heal", TagsCall_Heal);
	}
	
	TagsCall nCall = TagsCall_Invalid;
	mCall.GetValue(sCall, nCall);
	return nCall;
}

public Action TagsCall_TimerDelay(Handle hTimer, DataPack data)
{
	data.Reset();
	Function func = data.ReadFunction();
	int iClient = EntRefToEntIndex(data.ReadCell());
	TagsParams tParams = data.ReadCell();
	int iCall = data.ReadCell();
	
	if (iClient <= 0 || iClient > MaxClients || !IsClientInGame(iClient) || !IsPlayerAlive(iClient))
	{
		delete tParams;
		return;
	}
	
	TagsCall_Call(func, iClient, tParams, iCall);
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
		{
			DataPack data;
			CreateDataTimer(tParams.flRate, TagsCall_TimerDelay, data);
			data.WriteFunction(func);
			data.WriteCell(EntIndexToEntRef(iClient));
			data.WriteCell(tParams);
			data.WriteCell(iCall);
		}
		else
		{
			//0.0 delay, no need to create timer
			TagsCall_Call(func, iClient, tParams, iCall);
		}
	}
	else
	{
		//Free the cloned param
		delete tParams;
	}
}