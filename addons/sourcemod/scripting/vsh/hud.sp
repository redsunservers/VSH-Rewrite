static char g_sHudText[TF_MAXPLAYERS+1][256];
static int g_iHudColor[TF_MAXPLAYERS+1][4];
static bool g_bHudRage[TF_MAXPLAYERS+1] = true;

void Hud_SetRageView(int iClient, bool bEnable)
{
	g_bHudRage[iClient] = bEnable;
}

void Hud_AddText(int iClient, char[] sText, bool bShowWhenDead = false)
{
	if (!bShowWhenDead && !IsPlayerAlive(iClient))
		return;
		
	if (!StrEmpty(g_sHudText[iClient])) StrCat(g_sHudText[iClient], sizeof(g_sHudText[]), "\n");
	StrCat(g_sHudText[iClient], sizeof(g_sHudText[]), sText);
}

void Hud_SetColor(int iClient, int iColor[4])
{
	for (int i = 0; i < sizeof(iColor); i++)
		g_iHudColor[iClient][i] = iColor[i];
}

void Hud_Think(int iClient)
{
	if (!g_bRoundStarted) return;
	
	char sMessage[255];
	
	if (!SaxtonHale_IsValidBoss(iClient, false))
	{
		//Display Boss's health to non-bosses regardless if dead or alive
		Format(sMessage, sizeof(sMessage), "Boss HP: %i/%i", g_iHealthBarHealth, g_iHealthBarMaxHealth);
		
		//Display boss's rage
		if (g_bHudRage[iClient])
		{
			for (int iBoss = 1; iBoss <= MaxClients; iBoss++)
			{
				SaxtonHaleBase boss = SaxtonHaleBase(iBoss);
				if (IsClientInGame(iBoss) && IsPlayerAlive(iBoss) && boss.bValid && !boss.bMinion)
				{
					int iRage = RoundToFloor(float(boss.iRageDamage) / float(boss.iMaxRageDamage) * 100.0);
					Format(sMessage, sizeof(sMessage), "%s | Boss Rage: %i%%%%", sMessage, iRage);
					break;
				}
			}
		}
		
		Hud_AddText(iClient, sMessage, true);

		//Display Client's damage
		if (g_iPlayerAssistDamage[iClient] <= 0)
			Format(sMessage, sizeof(sMessage), "Damage: %i", g_iPlayerDamage[iClient]);
		else
			Format(sMessage, sizeof(sMessage), "Damage: %i Assist: %i", g_iPlayerDamage[iClient], g_iPlayerAssistDamage[iClient]);

		Hud_AddText(iClient, sMessage, true);
		
		//Display airblast percentage
		float flPercentage = Tags_GetAirblastPercentage(iClient);
		if (flPercentage >= 0.0)
		{
			Format(sMessage, sizeof(sMessage), "Airblast: %i%%", RoundToFloor(flPercentage * 100.0));
			Hud_AddText(iClient, sMessage);
		}
	}
	else
	{
		//Display Boss's health to other bosses if they're dead
		if (!IsPlayerAlive(iClient))
		{
			Format(sMessage, sizeof(sMessage), "Boss HP: %i/%i", g_iHealthBarHealth, g_iHealthBarMaxHealth);
			Hud_AddText(iClient, sMessage, true);
		}
	}

	if (!IsPlayerAlive(iClient))
	{
		//If dead, display whoever client is spectating and damage
		int iObserverTarget = GetEntPropEnt(iClient, Prop_Send, "m_hObserverTarget");
		if (iObserverTarget != iClient && 0 < iObserverTarget <= MaxClients && IsClientInGame(iObserverTarget) && !SaxtonHale_IsValidBoss(iObserverTarget, false))
		{
			if (g_iPlayerAssistDamage[iObserverTarget] <= 0)
				Format(sMessage, sizeof(sMessage), "%N's Damage: %i", iObserverTarget, g_iPlayerDamage[iObserverTarget]);
			else
				Format(sMessage, sizeof(sMessage), "%N's Damage: %i (Assist: %i)", iObserverTarget, g_iPlayerDamage[iObserverTarget], g_iPlayerAssistDamage[iObserverTarget]);
			
			Hud_AddText(iClient, sMessage, true);
		}

		int iColor[4];
		iColor[0] = 90; iColor[1] = 255; iColor[2] = 90; iColor[3] = 255;
		Hud_SetColor(iClient, iColor);
	}
	
	//Display
	float flHUD[2];
	flHUD[0] = -1.0;
	flHUD[1] = 0.88;
	
	Hud_Display(iClient, CHANNEL_HELP, g_sHudText[iClient], flHUD, 0.2, g_iHudColor[iClient]);
	
	//Reset string
	Format(g_sHudText[iClient], sizeof(g_sHudText[]), "");
}

void Hud_Display(int iClient, int iChannel, char[] sText, float flHUD[2], float flDuration = 0.0, int iColor[4] = -1, int iEffect = 0, float flTime = 0.0, float flFade[2] = 0.0)
{
	if (iColor[0] == -1)
	{
		iColor[0] = 255;
		iColor[1] = 255;
		iColor[2] = 255;
		iColor[3] = 255;
	}
	
	SetHudTextParams(flHUD[0], flHUD[1], flDuration, iColor[0], iColor[1], iColor[2], iColor[3], iEffect, flTime, flFade[0], flFade[1]);
	ShowHudText(iClient, iChannel, sText);
}