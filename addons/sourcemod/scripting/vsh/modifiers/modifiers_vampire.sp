//Values by % of max health
#define VAMPIRE_GAIN	0.0175
#define VAMPIRE_LOSS	0.002	//Per second

static int g_iVampireCount = 0;
static float g_flVampireHealthDrainBuffer[TF_MAXPLAYERS+1];

methodmap CModifiersVampire < SaxtonHaleBase
{
	public CModifiersVampire(CModifiersVampire boss)
	{
		if (g_iVampireCount == 0)
			HookEvent("player_death", Vampire_PlayerDeath);
		
		g_iVampireCount++;
		g_flVampireHealthDrainBuffer[boss.iClient] = 0.0;
	}
	
	public bool IsModifiersHidden()
	{
		return true;
	}
	
	public void GetModifiersName(char[] sName, int length)
	{
		strcopy(sName, length, "Vampire");
	}
	
	public void GetModifiersInfo(char[] sInfo, int length)
	{
		StrCat(sInfo, length, "\nColor: Purple");
		StrCat(sInfo, length, "\n ");
		StrCat(sInfo, length, "\n- Gain health on player death");
		StrCat(sInfo, length, "\n- Health decays over time");
	}
	
	public int GetRenderColor(int iColor[4])
	{
		iColor[0] = 192;
		iColor[1] = 96;
		iColor[2] = 255;
		iColor[3] = 255;
	}
	
	public void OnThink()
	{
		if (GameRules_GetRoundState() != RoundState_Preround && IsPlayerAlive(this.iClient))
		{
			g_flVampireHealthDrainBuffer[this.iClient] += GetGameFrameTime() * float(this.iMaxHealth) * VAMPIRE_LOSS;
			
			if (g_flVampireHealthDrainBuffer[this.iClient] >= 1.0)
			{
				int iHealthDrain = RoundToFloor(g_flVampireHealthDrainBuffer[this.iClient]);
				this.iHealth -= iHealthDrain;
				g_flVampireHealthDrainBuffer[this.iClient] -= float(iHealthDrain);
				
				if (this.iHealth <= 0)	//die
					ForcePlayerSuicide(this.iClient);
			}
		}
	}
	
	public void Destroy()
	{
		if (g_iVampireCount > 0)	//This should never fail but just in case...
			g_iVampireCount--;
		
		if (g_iVampireCount == 0)
			UnhookEvent("player_death", Vampire_PlayerDeath);
	}
};

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
			boss.iHealth += RoundToNearest(float(boss.iMaxHealth) * VAMPIRE_GAIN);
			
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