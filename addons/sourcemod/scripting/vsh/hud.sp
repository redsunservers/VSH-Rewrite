static char g_sHudText[TF_MAXPLAYERS+1][256];
static int g_iHudColor[TF_MAXPLAYERS+1][4];
static bool g_bHudRage[TF_MAXPLAYERS+1] = true;

void Hud_SetRageView(int iClient, bool bEnable)
{
	g_bHudRage[iClient] = bEnable;
}

void Hud_AddText(int iClient, char[] sText)
{
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
	
	if (!SaxtonHale_IsValidBoss(iClient, false))
	{
		char sMessage[255];

		//Display Boss's health
		Format(sMessage, sizeof(sMessage), "Boss Health: %i/%i", g_iHealthBarHealth, g_iHealthBarMaxHealth);
		
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
		
		Hud_AddText(iClient, sMessage);

		//Display Client's damage
		if (g_iPlayerAssistDamage[iClient] <= 0)
			Format(sMessage, sizeof(sMessage), "Damage: %i", g_iPlayerDamage[iClient]);
		else
			Format(sMessage, sizeof(sMessage), "Damage: %i Assist: %i", g_iPlayerDamage[iClient], g_iPlayerAssistDamage[iClient]);

		Hud_AddText(iClient, sMessage);

		if (!IsPlayerAlive(iClient))
		{
			//If dead, display whoever client is spectating and damage
			int iOberserTarget = GetEntPropEnt(iClient, Prop_Send, "m_hObserverTarget");
			if (iOberserTarget != iClient && 0 < iOberserTarget <= MaxClients && IsClientInGame(iOberserTarget) && !SaxtonHaleBase(iOberserTarget).bValid)
			{
				if (g_iPlayerAssistDamage[iOberserTarget] <= 0)
					Format(sMessage, sizeof(sMessage), "%N's Damage: %i", iOberserTarget, g_iPlayerDamage[iOberserTarget]);
				else
					Format(sMessage, sizeof(sMessage), "%N's Damage: %i Assist: %i", iOberserTarget, g_iPlayerDamage[iOberserTarget], g_iPlayerAssistDamage[iOberserTarget]);
				
				Hud_AddText(iClient, sMessage);
			}
		}
		else
		{
			//Display airblast percentage
			float flPercentage = Tags_GetAirblastPercentage(iClient);
			if (flPercentage >= 0.0)
			{
				Format(sMessage, sizeof(sMessage), "Airblast: %i%%", RoundToFloor(flPercentage * 100.0));
				Hud_AddText(iClient, sMessage);
			}
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