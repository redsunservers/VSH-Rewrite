static bool g_bWinstreakMode = false;
static int g_iWinstreak[TF_MAXPLAYERS+1];

void Winstreak_Init()
{
	g_ConfigConvar.Create("vsh_boss_winstreak_health", "0.06", "How much precentage boss should lose health on every winstreak", _, true, 0.0, true, 1.0);

	SaxtonHale_HookFunction("CalculateMaxHealth", Winstreak_CalculateMaxHealth);
}

void Winstreak_RoundStart()
{
	Winstreak_SetEnable(false);
	
	//Get main boss
	int iBoss = GetMainBoss();
	if (iBoss <= 0 || iBoss > MaxClients || !IsClientInGame(iBoss))
		return;
	
	// Enable winstreak if allows to
	if (Winstreak_IsAllowed(iBoss))
	{
		Winstreak_SetEnable(true);
		SaxtonHaleBase boss = SaxtonHaleBase(iBoss);
		int iHealth = boss.CallFunction("CalculateMaxHealth");
		boss.iMaxHealth = iHealth;
		boss.iHealth = iHealth;
	}
}

public Action Winstreak_CalculateMaxHealth(SaxtonHaleBase boss, int &iHealth)
{
	//Cut down health if enabled
	if (!boss.bMinion && Winstreak_IsEnabled())
	{
		iHealth = RoundToNearest(float(iHealth) * (1.0 - Winstreak_GetPrecentageLoss(boss.iClient)));
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}

stock int Winstreak_GetCurrent(int iClient)
{
	return g_iWinstreak[iClient];
}

stock void Winstreak_SetCurrent(int iClient, int iWinstreak, bool bUpdate = false)
{
	g_iWinstreak[iClient] = iWinstreak;
	
	if (bUpdate) Cookies_SaveWinstreak(iClient, iWinstreak);
}

stock bool Winstreak_IsEnabled()
{
	return g_bWinstreakMode;
}

stock void Winstreak_SetEnable(bool bValue)
{
	g_bWinstreakMode = bValue;
}

stock bool Winstreak_IsAllowed(int iClient)
{
	if (Winstreak_GetCurrent(iClient) != -1	//Is his current winstreak loaded
		&& Preferences_Get(iClient, Preferences_Winstreak)		//Is winstreak pref on
		&& (GetMainBoss() != iClient || !ClassLimit_IsSpecialRoundOn())	//If boss, is special round not on
		&& g_iTotalAttackCount >= Winstreak_GetPlayerRequirement(iClient))		//Is there enough attack players
	{
		return true;
	}
	
	return false;
}

stock int Winstreak_GetPlayerRequirement(int iClient)
{
	int iPlayerRequirement = 10 + Winstreak_GetCurrent(iClient);
	if (iPlayerRequirement > 24) iPlayerRequirement = 24;
	
	return iPlayerRequirement;
}

stock float Winstreak_GetPrecentageLoss(int iClient)
{
	return float(Winstreak_GetCurrent(iClient)) * g_ConfigConvar.LookupFloat("vsh_boss_winstreak_health");
}