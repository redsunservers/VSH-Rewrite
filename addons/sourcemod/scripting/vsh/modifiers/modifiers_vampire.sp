#define VAMPIRE_GAIN	300.0
#define VAMPIRE_LOSS	30.0

static int g_iVampireCount = 0;
static int g_iVampireStartHealth[TF_MAXPLAYERS+1];
static float g_flVampireStartTime[TF_MAXPLAYERS+1];

methodmap CModifiersVampire < SaxtonHaleBase
{
	public CModifiersVampire(CModifiersVampire boss)
	{
		if (g_iVampireCount == 0)
		{
			SaxtonHale_HookFunction("CalculateMaxHealth", Vampire_CalculateMaxHealth, VSHHookMode_Pre);
			HookEvent("player_death", Vampire_PlayerDeath);
		}
		
		g_iVampireCount++;
		g_iVampireStartHealth[boss.iClient] = 1;
		g_flVampireStartTime[boss.iClient] = 0.0;
	}
	
	public void GetModifiersName(char[] sName, int length)
	{
		strcopy(sName, length, "Vampire");
	}
	
	public void GetModifiersInfo(char[] sInfo, int length)
	{
		StrCat(sInfo, length, "\nColor: Purple");
		StrCat(sInfo, length, "\n ");
		StrCat(sInfo, length, "\n- Gain 300 health on player death");
		StrCat(sInfo, length, "\n- Max health decays 30 per second");
	}
	
	public int GetRenderColor(int iColor[4])
	{
		iColor[0] = 160;
		iColor[1] = 144;
		iColor[2] = 255;
		iColor[3] = 255;
	}
	
	public void OnThink()
	{
		if (GameRules_GetRoundState() != RoundState_Preround && IsPlayerAlive(this.iClient))
		{
			if (g_flVampireStartTime[this.iClient] == 0.0)
			{
				g_iVampireStartHealth[this.iClient] = this.iMaxHealth;
				g_flVampireStartTime[this.iClient] = GetGameTime();
			}
			
			int iHealth = this.CallFunction("CalculateMaxHealth");
			this.iMaxHealth = iHealth;
			if (this.iHealth > iHealth)
				this.iHealth = iHealth;
		}
	}
	
	public void Destroy()
	{
		if (g_iVampireCount > 0)	//This should never fail but just in case...
			g_iVampireCount--;
		
		if (g_iVampireCount == 0)
		{
			SaxtonHale_UnhookFunction("CalculateMaxHealth", Vampire_CalculateMaxHealth);
			UnhookEvent("player_death", Vampire_PlayerDeath);
		}
	}
};

public Action Vampire_CalculateMaxHealth(SaxtonHaleBase boss, int &iHealth)
{
	if (Vampire_IsVampire(boss.iClient) && g_flVampireStartTime[boss.iClient] != 0.0)
	{
		//Remove health by starting hp and time
		iHealth = g_iVampireStartHealth[boss.iClient] - RoundToFloor((GetGameTime() - g_flVampireStartTime[boss.iClient]) * VAMPIRE_LOSS);
		
		if (iHealth < 1)
			iHealth = 1;
		
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

public Action Vampire_PlayerDeath(Event event, const char[] sName, bool bDontBroadcast)
{
	int iVictim = GetClientOfUserId(event.GetInt("userid"));
	if (!SaxtonHale_IsValidAttack(iVictim))
		return;
	
	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if (Vampire_IsVampire(iClient) && IsPlayerAlive(iClient))
		{
			SaxtonHaleBase boss = SaxtonHaleBase(iClient);
			boss.iHealth += VAMPIRE_GAIN;
			
			if (boss.iHealth > boss.iMaxHealth)
				boss.iHealth = boss.iMaxHealth;
		}
	}
}

stock bool Vampire_IsVampire(int iClient)
{
	SaxtonHaleBase boss = SaxtonHaleBase(iClient);
	if (!boss.bValid || !boss.bModifiers)
		return false;
	
	char sBossType[MAX_TYPE_CHAR];
	boss.CallFunction("GetModifiersType", sBossType, sizeof(sBossType));
	return StrEqual(sBossType, "CModifiersVampire");
}