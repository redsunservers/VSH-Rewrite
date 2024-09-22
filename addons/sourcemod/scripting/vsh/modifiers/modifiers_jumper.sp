#define ATTRIB_NO_JUMP	819

static float g_flJumpCooldown[MAXPLAYERS];

public void ModifiersJumper_Create(SaxtonHaleBase boss)
{
	TF2Attrib_SetByDefIndex(boss.iClient, ATTRIB_NO_JUMP, 1.0);
}

public void ModifiersJumper_GetModifiersName(SaxtonHaleBase boss, char[] sName, int length)
{
	strcopy(sName, length, "Jumper");
}

public void ModifiersJumper_GetModifiersInfo(SaxtonHaleBase boss, char[] sInfo, int length)
{
	StrCat(sInfo, length, "\nColor: Blue");
	StrCat(sInfo, length, "\n ");
	StrCat(sInfo, length, "\n- Normal jump is replaced with leap");
	StrCat(sInfo, length, "\n- 3 seconds cooldown");
}

public void ModifiersJumper_GetRenderColor(SaxtonHaleBase boss, int iColor[4])
{
	iColor[0] = 64;
	iColor[1] = 144;
	iColor[2] = 255;
	iColor[3] = 255;
}

public void ModifiersJumper_GetParticleEffect(SaxtonHaleBase boss, int index, char[] sEffect, int length)
{
	switch (index)
	{
		case 0:
			strcopy(sEffect, length, "utaunt_pedalfly_blue_pedals2");
		
		case 1:
			strcopy(sEffect, length, "player_intel_trail_blue");
	}
}

public void ModifiersJumper_OnButtonPress(SaxtonHaleBase boss, int iButton)
{
	if (GameRules_GetRoundState() == RoundState_Preround)
		return;
	
	if (iButton == IN_JUMP && g_flJumpCooldown[boss.iClient] == 0.0)
	{
		g_flJumpCooldown[boss.iClient] = GetGameTime() + 3.0;
		boss.CallFunction("UpdateHudInfo", 1.0, 3.0);	//Update every second for 3 seconds
		
		float vecAng[3], vecVel[3];
		GetEntPropVector(boss.iClient, Prop_Data, "m_vecVelocity", vecVel);
		
		float flCharge = GetVectorLength(vecVel) / boss.flSpeed;	//flSpeedMulti? meh
		if (flCharge > 1.0)
			flCharge = 1.0;
		
		GetVectorAngles(vecVel, vecAng);
		
		vecVel[0] = Cosine(DegToRad(vecAng[0])) * Cosine(DegToRad(vecAng[1])) * 700.0 * flCharge;
		vecVel[1] = Cosine(DegToRad(vecAng[0])) * Sine(DegToRad(vecAng[1])) * 700.0 * flCharge;
		vecVel[2] = 360.0;
		
		SetEntProp(boss.iClient, Prop_Send, "m_bJumping", true);
		
		TeleportEntity(boss.iClient, NULL_VECTOR, NULL_VECTOR, vecVel);
	}
}

public void ModifiersJumper_OnThink(SaxtonHaleBase boss)
{
	if (g_flJumpCooldown[boss.iClient] == 0.0)
		return;
	
	if (g_flJumpCooldown[boss.iClient] < GetGameTime())
		g_flJumpCooldown[boss.iClient] = 0.0;
}

public void ModifiersJumper_GetHudInfo(SaxtonHaleBase boss, char[] sMessage, int iLength, int iColor[4])
{
	if (g_flJumpCooldown[boss.iClient] == 0.0)
	{
		StrCat(sMessage, iLength, "\nPress spacebar to leap!");
	}
	else
	{
		int iSec = RoundToCeil(g_flJumpCooldown[boss.iClient]-GetGameTime());
		Format(sMessage, iLength, "%s\nLeap cooldown %i second%s remaining!", sMessage, iSec, (iSec > 1) ? "s" : "");
	}
}

public void ModifiersJumper_Destroy(SaxtonHaleBase boss)
{
	TF2Attrib_RemoveByDefIndex(boss.iClient, ATTRIB_NO_JUMP);
	g_flJumpCooldown[boss.iClient] = 0.0;
}
