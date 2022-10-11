static ArrayList g_aConditions[TF_MAXPLAYERS + 1];

public void AddCond_Create(SaxtonHaleBase boss)
{
	if (g_aConditions[boss.iClient] == null)
		g_aConditions[boss.iClient] = new ArrayList();
	g_aConditions[boss.iClient].Clear();
	
	boss.SetPropFloat("AddCond", "CondDuration", 30.0);
	boss.SetPropFloat("AddCond", "CondCooldownWait", 0.0);
	boss.SetPropFloat("AddCond", "CondDuration", 8.0);
	boss.SetPropFloat("AddCond", "CondMaxCharge", 1.0);
}

public void AddCond_AddCond(SaxtonHaleBase boss, TFCond cond)
{
	g_aConditions[boss.iClient].Push(cond);
}

public void AddCond_GetHudInfo(SaxtonHaleBase boss, char[] sMessage, int iLength, int iColor[4])
{
	int iCharge;
	
	float flCondCooldownWait = boss.GetPropFloat("AddCond", "CondCooldownWait");
	if (flCondCooldownWait < GetGameTime())
	{
		iCharge = RoundToFloor(boss.GetPropFloat("AddCond", "CondMaxCharge") * 100.0);
	}
	else
	{
		float flPercentage = (flCondCooldownWait - GetGameTime()) / boss.GetPropFloat("AddCond", "CondCooldown");
		iCharge = RoundToFloor((boss.GetPropFloat("AddCond", "CondMaxCharge") - flPercentage) * 100.0);
	}
	
	if (iCharge >= 100)
		Format(sMessage, iLength, "Ability Charge: %d%%%% - Press MOUSE2 to use!", iCharge);
	else
		Format(sMessage, iLength, "Ability Charge: %d%%%%", iCharge);
}

public void AddCond_OnButtonPress(SaxtonHaleBase boss, int iButton)
{
	if (iButton == IN_ATTACK2 && GameRules_GetRoundState() != RoundState_Preround && !TF2_IsPlayerInCondition(boss.iClient, TFCond_Dazed))
	{
		float flCondCooldownWait = boss.GetPropFloat("AddCond", "CondCooldownWait");
		if (flCondCooldownWait < GetGameTime())
		{
			flCondCooldownWait = GetGameTime();
			boss.SetPropFloat("AddCond", "CondCooldownWait", flCondCooldownWait);
		}
		
		float flPercentage = (flCondCooldownWait - GetGameTime()) / boss.GetPropFloat("AddCond", "CondCooldown");
		float flCharge = boss.GetPropFloat("AddCond", "CondMaxCharge") - flPercentage;
		
		if (flCharge < 1.0)
			return;
		
		for (int i = 0; i < g_aConditions[boss.iClient].Length; i++)
		{
			TF2_AddCondition(boss.iClient, g_aConditions[boss.iClient].Get(i), boss.GetPropFloat("AddCond", "CondDuration"));
		}
		
		flCondCooldownWait += boss.GetPropFloat("AddCond", "CondCooldown");
		boss.SetPropFloat("AddCond", "CondCooldownWait", flCondCooldownWait);
		
		char sSound[PLATFORM_MAX_PATH];
		boss.CallFunction("GetSoundAbility", sSound, sizeof(sSound), "AddCond");
		if (!StrEmpty(sSound))
			EmitSoundToAll(sSound, boss.iClient, SNDCHAN_VOICE, SNDLEVEL_SCREAMING);
	}
}

public void AddCond_OnRage(SaxtonHaleBase boss)
{
	if (boss.GetPropInt("AddCond", "RemoveOnRage"))
	{
		for (int i = 0; i < g_aConditions[boss.iClient].Length; i++)
		{
			TF2_RemoveCondition(boss.iClient, g_aConditions[boss.iClient].Get(i));
		}
		
		//If conditions are removed due to rage, refund remaining duration as cooldown reduction
		float flCondCooldownWait = boss.GetPropFloat("AddCond", "CondCooldownWait");
		float flDurationRemaining = flCondCooldownWait - GetGameTime() - boss.GetPropFloat("AddCond", "CondCooldown") + boss.GetPropFloat("AddCond", "CondDuration");
		if (0 < flDurationRemaining < boss.GetPropFloat("AddCond", "CondDuration"))
			boss.SetPropFloat("AddCond", "CondCooldownWait", flCondCooldownWait - flDurationRemaining);
	}
}