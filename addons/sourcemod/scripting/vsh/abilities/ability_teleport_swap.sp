static float g_flTeleportSwapCooldownWait[TF_MAXPLAYERS];
static bool g_bTeleportSwapHoldingChargeButton[TF_MAXPLAYERS];

public void TeleportSwap_Create(SaxtonHaleBase boss)
{
	//Default values, these can be changed if needed
	boss.SetPropInt("TeleportSwap", "Charge", 0);
	boss.SetPropInt("TeleportSwap", "MaxCharge", 200);
	boss.SetPropInt("TeleportSwap", "ChargeBuild", 4);
	boss.SetPropFloat("TeleportSwap", "Cooldown", 30.0);
	boss.SetPropFloat("TeleportSwap", "StunDuration", 1.0);
	boss.SetPropFloat("TeleportSwap", "EyeAngleRequirement", -60.0);	//How far up should the boss look for the ability to trigger? Minimum value is -89.0 (all the way up)
	
	g_flTeleportSwapCooldownWait[boss.iClient] = GetGameTime() + boss.GetPropFloat("TeleportSwap", "Cooldown");
	boss.CallFunction("UpdateHudInfo", 1.0, boss.GetPropFloat("TeleportSwap", "Cooldown"));	//Update every second for cooldown duration
}

public void TeleportSwap_OnThink(SaxtonHaleBase boss)
{
	if (g_flTeleportSwapCooldownWait[boss.iClient] <= GetGameTime())
	{
		g_flTeleportSwapCooldownWait[boss.iClient] = 0.0;
		
		int iCharge = boss.GetPropInt("TeleportSwap", "Charge");
		int iChargeBuild = boss.GetPropInt("TeleportSwap", "ChargeBuild");
		int iMaxCharge = boss.GetPropInt("TeleportSwap", "MaxCharge");
		int iNewCharge;
		
		if (g_bTeleportSwapHoldingChargeButton[boss.iClient])
			iNewCharge = iCharge + iChargeBuild;
		else
			iNewCharge = iCharge - iChargeBuild * 2;
		
		if (iNewCharge > iMaxCharge)
			iNewCharge = iMaxCharge;
		else if (iNewCharge < 0)
			iNewCharge = 0;
		
		if (iCharge != iNewCharge)
		{
			boss.SetPropInt("TeleportSwap", "Charge", iNewCharge);
			boss.CallFunction("UpdateHudInfo", 0.0, 0.0);	//Update once
		}
	}
}

public void TeleportSwap_GetHudInfo(SaxtonHaleBase boss, char[] sMessage, int iLength, int iColor[4])
{
	if (g_flTeleportSwapCooldownWait[boss.iClient] != 0.0 && g_flTeleportSwapCooldownWait[boss.iClient] > GetGameTime())
	{
		int iSec = RoundToCeil(g_flTeleportSwapCooldownWait[boss.iClient]-GetGameTime());
		Format(sMessage, iLength, "%s\nTeleport-swap is on cooldown for %d second%s!", sMessage, iSec, (iSec > 1) ? "s" : "");
	}
	else if (boss.GetPropInt("TeleportSwap", "Charge") > 0)
	{
		Format(sMessage, iLength, "%s\nTeleport-swap: %.0f％. Look up and release right click to teleport.", sMessage, (float(boss.GetPropInt("TeleportSwap", "Charge"))/float(boss.GetPropInt("TeleportSwap", "MaxCharge")))*100.0);
	}
	else
	{
		Format(sMessage, iLength, "%s\nHold right click to use your teleport-swap!", sMessage);
	}
}

public void TeleportSwap_OnButton(SaxtonHaleBase boss, int &buttons)
{
	if (buttons & IN_ATTACK2)
		g_bTeleportSwapHoldingChargeButton[boss.iClient] = true;
}

public void TeleportSwap_OnButtonRelease(SaxtonHaleBase boss, int button)
{
	if (button == IN_ATTACK2)
	{
		g_bTeleportSwapHoldingChargeButton[boss.iClient] = false;
		
		// Deny teleporting when stunned
		if (TF2_IsPlayerInCondition(boss.iClient, TFCond_Dazed))
		{
			PrintHintText(boss.iClient, "Can't teleport-swap when stunned.");
			return;
		}
		
		// Deny teleporting when airborne
		if (!(GetEntityFlags(boss.iClient) & FL_ONGROUND))
		{
			PrintHintText(boss.iClient, "Can't teleport-swap when airborne.");
			return;
		}
		
		if (g_flTeleportSwapCooldownWait[boss.iClient] > GetGameTime()) return;
		
		float vecAng[3];
		GetClientEyeAngles(boss.iClient, vecAng);
		
		if ((vecAng[0] <= boss.GetPropFloat("TeleportSwap", "EyeAngleRequirement")) && (boss.GetPropInt("TeleportSwap", "Charge") >= boss.GetPropInt("TeleportSwap", "MaxCharge")))
		{
			//get random valid attack player
			ArrayList aClients = new ArrayList();
			for (int i = 1; i <= MaxClients; i++)
				if (SaxtonHale_IsValidAttack(i) && IsPlayerAlive(i))
					aClients.Push(i);
			
			if (aClients.Length == 0)
			{
				//Nobody in list? okay...
				delete aClients;
				return;
			}
			
			aClients.Sort(Sort_Random, Sort_Integer);
			
			int iClient[2];
			
			iClient[0] = boss.iClient;
			iClient[1] = aClients.Get(0);
			delete aClients;
			
			TF2_TeleportSwap(iClient);
			
			TF2_StunPlayer(iClient[0], boss.GetPropFloat("TeleportSwap", "StunDuration"), 0.0, TF_STUNFLAGS_GHOSTSCARE|TF_STUNFLAG_NOSOUNDOREFFECT, iClient[1]);
			TF2_AddCondition(iClient[0], TFCond_DefenseBuffMmmph, boss.GetPropFloat("TeleportSwap", "StunDuration"));
			
			g_flTeleportSwapCooldownWait[boss.iClient] = GetGameTime()+boss.GetPropFloat("TeleportSwap", "Cooldown");
			boss.CallFunction("UpdateHudInfo", 1.0, boss.GetPropFloat("TeleportSwap", "Cooldown"));	//Update every second for cooldown duration
			boss.SetPropInt("TeleportSwap", "Charge", 0);
			
			char sSound[PLATFORM_MAX_PATH];
			boss.CallFunction("GetSoundAbility", sSound, sizeof(sSound), "TeleportSwap");
			if (!StrEmpty(sSound))
				EmitSoundToAll(sSound, boss.iClient, SNDCHAN_VOICE, SNDLEVEL_SCREAMING);
		}
	}
}

