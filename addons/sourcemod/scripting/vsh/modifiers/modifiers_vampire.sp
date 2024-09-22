//Values by % of max health
#define VAMPIRE_GAIN	0.0175
#define VAMPIRE_LOSS	0.002	//Per second

static int g_iVampireCount = 0;
static float g_flVampireHealthDrainBuffer[MAXPLAYERS];

public void ModifiersVampire_Create(SaxtonHaleBase boss)
{
	if (g_iVampireCount == 0)
		HookEvent("player_death", Vampire_PlayerDeath);
	
	g_iVampireCount++;
	g_flVampireHealthDrainBuffer[boss.iClient] = 0.0;
}

public void ModifiersVampire_GetModifiersName(SaxtonHaleBase boss, char[] sName, int length)
{
	strcopy(sName, length, "Vampire");
}

public void ModifiersVampire_GetModifiersInfo(SaxtonHaleBase boss, char[] sInfo, int length)
{
	StrCat(sInfo, length, "\nColor: Purple");
	StrCat(sInfo, length, "\n ");
	StrCat(sInfo, length, "\n- Gain health on player death");
	StrCat(sInfo, length, "\n- Health decays over time");
}

public void ModifiersVampire_GetRenderColor(SaxtonHaleBase boss, int iColor[4])
{
	iColor[0] = 192;
	iColor[1] = 96;
	iColor[2] = 255;
	iColor[3] = 255;
}

public void ModifiersVampire_GetParticleEffect(SaxtonHaleBase boss, int index, char[] sEffect, int length)
{
	switch (index)
	{
		case 0:
			strcopy(sEffect, length, "utaunt_hellpit_bats");
		
		case 1:
			strcopy(sEffect, length, "player_intel_trail_red");
	}
}

public void ModifiersVampire_OnThink(SaxtonHaleBase boss)
{
	if (GameRules_GetRoundState() != RoundState_Preround && IsPlayerAlive(boss.iClient))
	{
		g_flVampireHealthDrainBuffer[boss.iClient] += GetGameFrameTime() * float(boss.iMaxHealth) * VAMPIRE_LOSS;
		
		if (g_flVampireHealthDrainBuffer[boss.iClient] >= 1.0)
		{
			int iHealthDrain = RoundToFloor(g_flVampireHealthDrainBuffer[boss.iClient]);
			boss.iHealth -= iHealthDrain;
			g_flVampireHealthDrainBuffer[boss.iClient] -= float(iHealthDrain);
			
			if (boss.iHealth <= 0)	//die
				ForcePlayerSuicide(boss.iClient);
		}
	}
}

public void ModifiersVampire_Destroy(SaxtonHaleBase boss)
{
	if (g_iVampireCount > 0)	//This should never fail but just in case...
		g_iVampireCount--;
	
	if (g_iVampireCount == 0)
		UnhookEvent("player_death", Vampire_PlayerDeath);
}

public void Vampire_PlayerDeath(Event event, const char[] sName, bool bDontBroadcast)
{
	int iVictim = GetClientOfUserId(event.GetInt("userid"));
	if (!SaxtonHale_IsValidAttack(iVictim))
		return;
	
	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		SaxtonHaleBase boss = SaxtonHaleBase(iClient);
		if (boss.HasClass("ModifiersVampire") && IsPlayerAlive(iClient))
		{
			boss.iHealth += RoundToNearest(float(boss.iMaxHealth) * VAMPIRE_GAIN);
			
			if (boss.iHealth > boss.iMaxHealth)
				boss.iHealth = boss.iMaxHealth;
		}
	}
}