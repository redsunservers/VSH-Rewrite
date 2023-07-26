static bool g_bHudRage[MAXPLAYERS] = {true, ...};
static char g_sBossHudText[MAXPLAYERS][256];
static int g_iBossHudColor[MAXPLAYERS][4];

void Hud_SetRageView(int iClient, bool bEnable)
{
	g_bHudRage[iClient] = bEnable;
}

void Hud_UpdateBossInfo(int iClient, float flinterval, float flDuration)
{
	//Update now
	g_sBossHudText[iClient] = "";
	g_iBossHudColor[iClient] = {255, 255, 255, 255};
	SaxtonHaleBase(iClient).CallFunction("GetHudInfo", g_sBossHudText[iClient], sizeof(g_sBossHudText[]), g_iBossHudColor[iClient]);
	
	if (flDuration > 0.0)
	{
		//Create timer to update hud on every interval
		DataPack hPack;
		CreateDataTimer(flinterval, Hud_TimerUpdateBossInfo, hPack, TIMER_REPEAT);
		hPack.WriteCell(GetClientSerial(iClient));
		hPack.WriteFloat(GetGameTime() + flDuration);
	}
}

Action Hud_TimerUpdateBossInfo(Handle hTimer, DataPack hPack)
{
	hPack.Reset();
	int iClient = GetClientFromSerial(hPack.ReadCell());
	float flEnd = hPack.ReadFloat();
	
	if (!SaxtonHale_IsValidBoss(iClient))
		return Plugin_Stop;
	
	g_sBossHudText[iClient] = "";
	g_iBossHudColor[iClient] = {255, 255, 255, 255};
	SaxtonHaleBase(iClient).CallFunction("GetHudInfo", g_sBossHudText[iClient], sizeof(g_sBossHudText[]), g_iBossHudColor[iClient]);
	
	if (flEnd <= GetGameTime())	//We've reached duration, stop updating
		return Plugin_Stop;
	
	return Plugin_Continue;
}

void Hud_Think(int iClient)
{
	if (!g_bRoundStarted)
		return;
	
	char sMessage[256];
	int iColor[4] = {255, 255, 255, 255};
	
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
		
		//Display Client's damage
		if (g_iPlayerAssistDamage[iClient] <= 0)
			Format(sMessage, sizeof(sMessage), "%s\nDamage: %i", sMessage, g_iPlayerDamage[iClient]);
		else
			Format(sMessage, sizeof(sMessage), "%s\nDamage: %i Assist: %i", sMessage, g_iPlayerDamage[iClient], g_iPlayerAssistDamage[iClient]);
		
		//Display airblast percentage
		float flCooldown = Tags_GetAirblastCooldown(iClient);
		if (flCooldown > 0.0)
			Format(sMessage, sizeof(sMessage), "%s\nAirblast Cooldown: %d sec", sMessage, RoundToCeil(flCooldown));
	}
	else if (!IsPlayerAlive(iClient))
	{
		//Display Boss's health to other bosses if they're dead
		Format(sMessage, sizeof(sMessage), "Boss HP: %i/%i", g_iHealthBarHealth, g_iHealthBarMaxHealth);
	}
	
	if (!IsPlayerAlive(iClient))
	{
		//If dead, display whoever client is spectating and damage
		int iObserverTarget = GetEntPropEnt(iClient, Prop_Send, "m_hObserverTarget");
		if (iObserverTarget != iClient && 0 < iObserverTarget <= MaxClients && IsClientInGame(iObserverTarget) && !SaxtonHale_IsValidBoss(iObserverTarget, false))
		{
			if (g_iPlayerAssistDamage[iObserverTarget] <= 0)
				Format(sMessage, sizeof(sMessage), "%s\n%N's Damage: %i", sMessage, iObserverTarget, g_iPlayerDamage[iObserverTarget]);
			else
				Format(sMessage, sizeof(sMessage), "%s\n%N's Damage: %i (Assist: %i)", sMessage, iObserverTarget, g_iPlayerDamage[iObserverTarget], g_iPlayerAssistDamage[iObserverTarget]);
		}
	}
	else if (SaxtonHale_IsValidBoss(iClient))
	{
		StrCat(sMessage, sizeof(sMessage), g_sBossHudText[iClient]);
		iColor = g_iBossHudColor[iClient];
	}
	
	if (StrContains(sMessage, "\n") == 0)	//Delete newline from start
		Format(sMessage, sizeof(sMessage), sMessage[1]);
	
	//Display
	Hud_Display(iClient, CHANNEL_HELP, sMessage, view_as<float>({-1.0, 0.88}), 0.2, iColor);
}

void Hud_Display(int iClient, int iChannel, char[] sText, float flHUD[2], float flDuration = 0.0, int iColor[4] = {255, 255, 255, 255}, int iEffect = 0, float flTime = 0.0, float flFade[2] = {0.0, 0.0})
{
	SetHudTextParams(flHUD[0], flHUD[1], flDuration, iColor[0], iColor[1], iColor[2], iColor[3], iEffect, flTime, flFade[0], flFade[1]);
	ShowHudText(iClient, iChannel, sText);
}