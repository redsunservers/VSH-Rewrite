static bool g_bRankEnabled = false;
static int g_iRank[TF_MAXPLAYERS+1];

void Rank_Init()
{
	g_ConfigConvar.Create("vsh_boss_rank_health", "0.05", "How much precentage boss should lose health on every Rank", _, true, 0.0, true, 1.0);

	SaxtonHale_HookFunction("CalculateMaxHealth", Rank_CalculateMaxHealth);
}

void Rank_RoundStart()
{
	Rank_SetEnable(false);
	
	//Get main boss
	int iBoss = GetMainBoss();
	if (iBoss <= 0 || iBoss > MaxClients || !IsClientInGame(iBoss))
		return;
	
	// Enable rank if allows to
	if (Rank_IsAllowed(iBoss))
	{
		Rank_SetEnable(true);
		SaxtonHaleBase boss = SaxtonHaleBase(iBoss);
		int iHealth = boss.CallFunction("CalculateMaxHealth");
		boss.iMaxHealth = iHealth;
		boss.iHealth = iHealth;
	}
}

public Action Rank_CalculateMaxHealth(SaxtonHaleBase boss, int &iHealth)
{
	//Cut down health if enabled
	if (!boss.bMinion && 0 < GetMainBoss())
	{
		iHealth = RoundToNearest(float(iHealth) * (1.0 - Rank_GetPrecentageLoss(boss.iClient)));
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}

stock int Rank_GetCurrent(int iClient)
{
	return g_iRank[iClient];
}

stock void Rank_SetCurrent(int iClient, int iRank, bool bUpdate = false)
{
	g_iRank[iClient] = iRank;
	
	if (bUpdate)
		Cookies_SaveRank(iClient, iRank);
}

stock bool Rank_IsEnabled()
{
	return g_bRankEnabled;
}

stock void Rank_SetEnable(bool bValue)
{
	g_bRankEnabled = bValue;
}

stock bool Rank_IsAllowed(int iClient)
{
	return Rank_GetCurrent(iClient) != -1								//Is his current rank loaded
		&& (GetMainBoss() != iClient || !ClassLimit_IsSpecialRoundOn())	//If boss, is special round not on
		&& g_iTotalAttackCount >= Rank_GetPlayerRequirement(iClient);	//Is there enough attack players
}

stock int Rank_GetPlayerRequirement(int iClient)
{
	int iPlayerRequirement = 5 + Rank_GetCurrent(iClient);
	if (iPlayerRequirement > 20) iPlayerRequirement = 20;
	
	return iPlayerRequirement;
}

stock float Rank_GetPrecentageLoss(int iClient)
{
	float flPrecentage = float(Rank_GetCurrent(iClient)) * g_ConfigConvar.LookupFloat("vsh_boss_rank_health");
	if (flPrecentage > 0.99)
		return 0.99;
	
	return flPrecentage;
}
