static bool g_bRankEnabled = false;
static bool g_bRankHealth = false;
static int g_iRank[TF_MAXPLAYERS+1];

void Rank_Init()
{
	g_ConfigConvar.Create("vsh_boss_rank_health", "0.05", "How much precentage boss should lose health on every Rank", _, true, 0.0, true, 1.0);

	SaxtonHale_HookFunction("CalculateMaxHealth", Rank_CalculateMaxHealth);
}

void Rank_RoundStart()
{
	g_bRankEnabled = false;
	g_bRankHealth = false;
	
	// Enable health if main boss, rank is loaded and pref enabled
	int iClient = GetMainBoss();
	if (0 < iClient <= MaxClients && Rank_GetCurrent(iClient) >= 0 && Preferences_Get(iClient, Preferences_Rank))
	{
		g_bRankHealth = true;
		
		// Allow rank increase/decrease if not special round and enough players
		if (!ClassLimit_IsSpecialRoundOn() && g_iTotalAttackCount >= Rank_GetPlayerRequirement(iClient))
			g_bRankEnabled = true;
	}
	
	//Refresh max health
	for (int i = 1; i <= MaxClients; i++)
	{
		SaxtonHaleBase boss = SaxtonHaleBase(i);
		if (boss.bValid)
		{
			int iHealth = boss.CallFunction("CalculateMaxHealth");
			boss.iMaxHealth = iHealth;
			boss.iHealth = iHealth;
		}
	}
}

public void Rank_DisplayNextClient(int iClient)
{
	char sFormat[512];
	Format(sFormat, sizeof(sFormat), "%s================%s\nYou are about to be the next boss!\n", TEXT_DARK, TEXT_COLOR);
	
	SaxtonHaleNextBoss nextBoss = SaxtonHaleNextBoss(iClient);
	
	if (nextBoss.bSpecialClassRound)
		Format(sFormat, sizeof(sFormat), "%sYour round will be a special class round, your rank %s%d%s will not change.", sFormat, TEXT_DARK, Rank_GetCurrent(iClient), TEXT_COLOR);
	else if (!Preferences_Get(iClient, Preferences_Rank))
		Format(sFormat, sizeof(sFormat), "%sYour rank preference is disabled, your rank %s%d%s will not change.", sFormat, TEXT_DARK, Rank_GetCurrent(iClient), TEXT_COLOR);
	else if (g_iTotalAttackCount < Rank_GetPlayerRequirement(iClient))
		Format(sFormat, sizeof(sFormat), "%sYou need %s%d%s enemy players to have your rank %s%d%s changed.", sFormat, TEXT_DARK, Rank_GetPlayerRequirement(iClient), TEXT_COLOR, TEXT_DARK, Rank_GetCurrent(iClient), TEXT_COLOR);
	else
		Format(sFormat, sizeof(sFormat), "%sYou are currently at rank %s%d%s.", sFormat, TEXT_DARK, Rank_GetCurrent(iClient), TEXT_COLOR);
	
	Format(sFormat, sizeof(sFormat), "%s%s\n================", sFormat, TEXT_DARK);
	PrintToChat(iClient, sFormat);
}

public Action Rank_CalculateMaxHealth(SaxtonHaleBase boss, int &iHealth)
{
	//Cut down health if enabled
	if (!boss.bMinion && g_bRankHealth)
	{
		iHealth = RoundToNearest(float(iHealth) * (1.0 - Rank_GetPrecentageLoss(boss.iClient)));
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}

int Rank_GetCurrent(int iClient)
{
	return g_iRank[iClient];
}

void Rank_SetCurrent(int iClient, int iRank, bool bUpdate = false)
{
	g_iRank[iClient] = iRank;
	
	if (bUpdate)
		Cookies_SaveRank(iClient, iRank);
}

bool Rank_IsEnabled()
{
	return g_bRankEnabled;
}

void Rank_SetEnable(bool bValue)
{
	g_bRankEnabled = bValue;
}

bool Rank_IsHealthEnabled()
{
	return g_bRankHealth;
}

int Rank_GetPlayerRequirement(int iClient)
{
	int iPlayerRequirement = 5 + Rank_GetCurrent(iClient);
	if (iPlayerRequirement > 20) iPlayerRequirement = 20;
	
	return iPlayerRequirement;
}

float Rank_GetPrecentageLoss(int iClient)
{
	float flPrecentage = float(Rank_GetCurrent(iClient)) * g_ConfigConvar.LookupFloat("vsh_boss_rank_health");
	if (flPrecentage > 0.99)
		return 0.99;
	
	return flPrecentage;
}
