static float g_flDashJumpCooldownWait[MAXPLAYERS];

public void DashJump_Create(SaxtonHaleBase boss)
{
	g_flDashJumpCooldownWait[boss.iClient] = 0.0;
	
	//Default values, these can be changed if needed
	boss.SetPropFloat("DashJump", "Cooldown", 4.0);
	boss.SetPropFloat("DashJump", "MaxCharge", 2.0);
	boss.SetPropFloat("DashJump", "MaxForce", 700.0);
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
		
		SetEntProp(boss.iClient, Prop_Send, "m_bJumping", true);
		
		TeleportEntity(boss.iClient, NULL_VECTOR, NULL_VECTOR, vecVel);
		
		g_flDashJumpCooldownWait[boss.iClient] += boss.GetPropFloat("DashJump", "Cooldown");
		boss.CallFunction("UpdateHudInfo", 0.0, boss.GetPropFloat("DashJump", "Cooldown") * 2);	//Update every frame for cooldown * 2
		
		char sSound[PLATFORM_MAX_PATH];
		boss.CallFunction("GetSoundAbility", sSound, sizeof(sSound), "DashJump");
		if (!StrEmpty(sSound))
			EmitSoundToAll(sSound, boss.iClient, SNDCHAN_VOICE, SNDLEVEL_SCREAMING);
	}
}
