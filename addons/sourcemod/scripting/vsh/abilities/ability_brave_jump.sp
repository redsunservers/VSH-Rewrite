static bool g_bBraveJumpHoldingChargeButton[MAXPLAYERS];

public void BraveJump_Create(SaxtonHaleBase boss)
{
	//Default values, these can be changed if needed
	boss.SetPropInt("BraveJump", "JumpCharge", 0);
	boss.SetPropInt("BraveJump", "MaxJumpCharge", 200);
	boss.SetPropInt("BraveJump", "JumpChargeBuild", 4);
	boss.SetPropFloat("BraveJump", "MaxHeight", 1100.0);
	boss.SetPropFloat("BraveJump", "MaxDistance", 0.45);
	boss.SetPropFloat("BraveJump", "Cooldown", 7.0);
	boss.SetPropFloat("BraveJump", "MinCooldown", 5.5);
	boss.SetPropFloat("BraveJump", "CooldownWait", 0.0);
	boss.SetPropFloat("BraveJump", "EyeAngleRequirement", -25.0);	//How far up should the boss look for the ability to trigger? Minimum value is -89.0 (all the way up)
}

public void BraveJump_OnThink(SaxtonHaleBase boss)
{
	if (GameRules_GetRoundState() == RoundState_Preround)
		return;
	
	float flCooldownWait = boss.GetPropFloat("BraveJump", "CooldownWait");
	if (flCooldownWait == 0.0)	//Round started, start cooldown
	{
		flCooldownWait = GetGameTime()+boss.GetPropFloat("BraveJump", "Cooldown");
		boss.SetPropFloat("BraveJump", "CooldownWait", flCooldownWait);
		
		boss.CallFunction("UpdateHudInfo", 1.0, boss.GetPropFloat("BraveJump", "Cooldown"));	//Update every second for cooldown duration
	}
	
	int iJumpCharge = boss.GetPropInt("BraveJump", "JumpCharge");
	int iJumpChargeBuild = boss.GetPropInt("BraveJump", "JumpChargeBuild");
	int iMaxJumpCharge = boss.GetPropInt("BraveJump", "MaxJumpCharge");
	int iNewJumpCharge;
	
	if (flCooldownWait <= GetGameTime() && g_bBraveJumpHoldingChargeButton[boss.iClient])
		iNewJumpCharge = iJumpCharge + iJumpChargeBuild;
	else
		iNewJumpCharge = iJumpCharge - iJumpChargeBuild * 2;
	
	if (iNewJumpCharge > iMaxJumpCharge)
		iNewJumpCharge = iMaxJumpCharge;
	else if (iNewJumpCharge < 0)
		iNewJumpCharge = 0;
	
	if (iJumpCharge != iNewJumpCharge)
	{
		boss.SetPropInt("BraveJump", "JumpCharge", iNewJumpCharge);
		boss.CallFunction("UpdateHudInfo", 0.0, 0.0);	//Update once
	}
}

public void BraveJump_GetHudInfo(SaxtonHaleBase boss, char[] sMessage, int iLength, int iColor[4])
{
	float flCooldownWait = boss.GetPropFloat("BraveJump", "CooldownWait");
	if (flCooldownWait != 0.0 && flCooldownWait > GetGameTime())
	{
		int iSec = RoundToCeil(flCooldownWait-GetGameTime());
		Format(sMessage, iLength, "%s\nSuper-jump cooldown %i second%s remaining!", sMessage, iSec, (iSec > 1) ? "s" : "");
	}
	else if (boss.GetPropInt("BraveJump", "JumpCharge") > 0)
	{
		Format(sMessage, iLength, "%s\nJump charge: %0.2f%%. Look up and stand up to use super-jump.", sMessage, (float(boss.GetPropInt("BraveJump", "JumpCharge"))/float(boss.GetPropInt("BraveJump", "MaxJumpCharge")))*100.0);
	}
	else
	{
		Format(sMessage, iLength, "%s\nHold right click to use your super-jump!", sMessage);
	}
}

public void BraveJump_OnButton(SaxtonHaleBase boss, int &buttons)
{
	if (buttons & IN_ATTACK2)
		g_bBraveJumpHoldingChargeButton[boss.iClient] = true;
}

public void BraveJump_OnButtonRelease(SaxtonHaleBase boss, int button)
{
	if (button == IN_ATTACK2)
	{
		if (TF2_IsPlayerInCondition(boss.iClient, TFCond_Dazed))//Can't jump if stunned
			return;
		
		g_bBraveJumpHoldingChargeButton[boss.iClient] = false;
		float flCooldownWait = boss.GetPropFloat("BraveJump", "CooldownWait");
		if (flCooldownWait != 0.0 && flCooldownWait > GetGameTime()) return;
		
		float vecAng[3];
		GetClientEyeAngles(boss.iClient, vecAng);
		
		if ((vecAng[0] <= boss.GetPropFloat("BraveJump", "EyeAngleRequirement")) && (boss.GetPropInt("BraveJump", "JumpCharge") > 1))
		{
			float vecVel[3];
			GetEntPropVector(boss.iClient, Prop_Data, "m_vecVelocity", vecVel);
			
			vecVel[2] = boss.GetPropFloat("BraveJump", "MaxHeight")*((float(boss.GetPropInt("BraveJump", "JumpCharge"))/float(boss.GetPropInt("BraveJump", "MaxJumpCharge"))));
			vecVel[0] *= (1.0+Sine((float(boss.GetPropInt("BraveJump", "JumpCharge"))/float(boss.GetPropInt("BraveJump", "MaxJumpCharge"))) * FLOAT_PI * boss.GetPropFloat("BraveJump", "MaxDistance")));
			vecVel[1] *= (1.0+Sine((float(boss.GetPropInt("BraveJump", "JumpCharge"))/float(boss.GetPropInt("BraveJump", "MaxJumpCharge"))) * FLOAT_PI * boss.GetPropFloat("BraveJump", "MaxDistance")));
			
			TeleportEntity(boss.iClient, NULL_VECTOR, NULL_VECTOR, vecVel);
			
			SetEntProp(boss.iClient, Prop_Send, "m_bJumping", true);
			SetEntityFlags(boss.iClient, GetEntityFlags(boss.iClient) & ~FL_ONGROUND);
			
			float flCooldownTime = (boss.GetPropFloat("BraveJump", "Cooldown")*(float(boss.GetPropInt("BraveJump", "JumpCharge"))/float(boss.GetPropInt("BraveJump", "MaxJumpCharge"))));
			if (flCooldownTime < boss.GetPropFloat("BraveJump", "MinCooldown"))
				flCooldownTime = boss.GetPropFloat("BraveJump", "MinCooldown");
			
			boss.SetPropFloat("BraveJump", "CooldownWait", GetGameTime()+flCooldownTime);
			boss.CallFunction("UpdateHudInfo", 1.0, boss.GetPropFloat("BraveJump", "Cooldown"));	//Update every second for cooldown duration
			
			boss.SetPropInt("BraveJump", "JumpCharge", 0);
			
			char sSound[PLATFORM_MAX_PATH];
			boss.CallFunction("GetSoundAbility", sSound, sizeof(sSound), "BraveJump");
			if (!StrEmpty(sSound))
				EmitSoundToAll(sSound, boss.iClient, SNDCHAN_VOICE, SNDLEVEL_SCREAMING);
		}
	}
}

