static float g_flDashJumpCooldownWait[MAXPLAYERS];
static float g_flDashJumpRageEnd[MAXPLAYERS];
static float g_flDashJumpLastThink[MAXPLAYERS];

public void DashJump_Create(SaxtonHaleBase boss)
{
	g_flDashJumpCooldownWait[boss.iClient] = 0.0;
	g_flDashJumpRageEnd[boss.iClient] = 0.0;
	g_flDashJumpLastThink[boss.iClient] = 0.0;
	
	//Default values, these can be changed if needed
	boss.SetPropFloat("DashJump", "Cooldown", 4.0);
	boss.SetPropFloat("DashJump", "MaxCharge", 2.0);
	boss.SetPropFloat("DashJump", "MaxForce", 700.0);
	boss.SetPropFloat("DashJump", "RageRegenMultiplier", 1.0);
	boss.SetPropFloat("DashJump", "RageDuration", 5.0);
}

public void DashJump_OnRage(SaxtonHaleBase boss)
{
	if (boss.GetPropFloat("DashJump", "RageRegenMultiplier") <= 1.0)
		return;

	float flDuration = boss.GetPropFloat("DashJump", "RageDuration");
	if (boss.bSuperRage)
		flDuration *= 2.0;

	g_flDashJumpRageEnd[boss.iClient] = GetGameTime() + flDuration;
	boss.CallFunction("UpdateHudInfo", 0.0, flDuration);
}

public void DashJump_OnThink(SaxtonHaleBase boss)
{
	int iClient = boss.iClient;
	float flNow = GetGameTime();
	float flDelta = flNow - g_flDashJumpLastThink[iClient];
	g_flDashJumpLastThink[iClient] = flNow;

	if (g_flDashJumpRageEnd[iClient] <= flNow || flDelta <= 0.0 || flDelta > 0.5)
		return;

	if (g_flDashJumpCooldownWait[iClient] > flNow)
		g_flDashJumpCooldownWait[iClient] -= flDelta * (boss.GetPropFloat("DashJump", "RageRegenMultiplier") - 1.0);
}

public void DashJump_GetHudInfo(SaxtonHaleBase boss, char[] sMessage, int iLength, int iColor[4])
{
	int iCharge;
	
	if (g_flDashJumpCooldownWait[boss.iClient] < GetGameTime())
	{
		iCharge = RoundToFloor(boss.GetPropFloat("DashJump", "MaxCharge") * 100.0);
	}
	else
	{
		float flPercentage = (g_flDashJumpCooldownWait[boss.iClient]-GetGameTime()) / boss.GetPropFloat("DashJump", "Cooldown");
		iCharge = RoundToFloor((boss.GetPropFloat("DashJump", "MaxCharge") - flPercentage) * 100.0);
	}
	
	if (iCharge >= 100)
		Format(sMessage, iLength, "%s\nDash charge: %d%%%%%%%% - Press reload to use your dash!", sMessage, iCharge);
	else
		Format(sMessage, iLength, "%s\nDash charge: %d%%%%", sMessage, iCharge);
}

public void DashJump_OnArenaRoundStart(SaxtonHaleBase boss)
{
	float flTimeUntilMaxCharge = boss.GetPropFloat("DashJump", "Cooldown") * boss.GetPropFloat("DashJump", "MaxCharge");
	g_flDashJumpCooldownWait[boss.iClient] = GetGameTime() + flTimeUntilMaxCharge;
	boss.CallFunction("UpdateHudInfo", 0.0, flTimeUntilMaxCharge);	// Update every frame until dash charge maxes out
}

public void DashJump_OnButtonPress(SaxtonHaleBase boss, int iButton)
{
	if (iButton == IN_RELOAD && GameRules_GetRoundState() != RoundState_Preround && !TF2_IsPlayerInCondition(boss.iClient, TFCond_Dazed))
	{
		if (g_flDashJumpCooldownWait[boss.iClient] < GetGameTime())
			g_flDashJumpCooldownWait[boss.iClient] = GetGameTime();
		
		float flPercentage = (g_flDashJumpCooldownWait[boss.iClient]-GetGameTime()) / boss.GetPropFloat("DashJump", "Cooldown");
		float flCharge = boss.GetPropFloat("DashJump", "MaxCharge") - flPercentage;
		
		if (flCharge < 1.0)
			return;
		
		float vecAng[3], vecVel[3];
		GetClientEyeAngles(boss.iClient, vecAng);
		
		vecVel[0] = Cosine(DegToRad(vecAng[0])) * Cosine(DegToRad(vecAng[1])) * boss.GetPropFloat("DashJump", "MaxForce");
		vecVel[1] = Cosine(DegToRad(vecAng[0])) * Sine(DegToRad(vecAng[1])) * boss.GetPropFloat("DashJump", "MaxForce");
		vecVel[2] = (((-vecAng[0]) * 1.5) + 90.0) * 3.0;
		
		TeleportEntity(boss.iClient, NULL_VECTOR, NULL_VECTOR, vecVel);
		
		SetEntProp(boss.iClient, Prop_Send, "m_bJumping", true);
		SetEntityFlags(boss.iClient, GetEntityFlags(boss.iClient) & ~FL_ONGROUND);
		TF2_AddCondition(boss.iClient, TFCond_BlastJumping);
		
		g_flDashJumpCooldownWait[boss.iClient] += boss.GetPropFloat("DashJump", "Cooldown");
		boss.CallFunction("UpdateHudInfo", 0.0, boss.GetPropFloat("DashJump", "Cooldown") * 2);	//Update every frame for cooldown * 2
		
		char sSound[PLATFORM_MAX_PATH];
		boss.CallFunction("GetSoundAbility", sSound, sizeof(sSound), "DashJump");
		if (!StrEmpty(sSound))
			EmitSoundToAll(sSound, boss.iClient, SNDCHAN_VOICE, SNDLEVEL_SCREAMING);
	}
}
