#define ATTRIB_MINICRIT_BECOMES_CRIT	179

static float g_flRageGasEnd[MAXPLAYERS];
static float g_flPreviousSpeed[MAXPLAYERS];

	
public void RageGas_Create(SaxtonHaleBase boss)
{
	g_flRageGasEnd[boss.iClient] = 0.0;
	
	boss.SetPropFloat("RageGas", "Duration", 8.0);
	boss.SetPropFloat("RageGas", "RageSpeedMult", 1.15);
	boss.SetPropFloat("RageGas", "Radius", 800.0);
}

public void RageGas_OnRage(SaxtonHaleBase boss)
{
	int bossTeam = GetClientTeam(boss.iClient);
	float vecPos[3], vecTargetPos[3];
	float flRageDuration = boss.GetPropFloat("RageGas", "Duration");
	GetClientAbsOrigin(boss.iClient, vecPos);
	
	float flRadius = boss.GetPropFloat("RageGas", "Radius");
	if (boss.bSuperRage) flRadius *= 1.5;
	if (boss.bSuperRage) flRageDuration *= 1.5;
	
	for (int iVictim = 1; iVictim <= MaxClients; iVictim++)
	{
		if (IsClientInGame(iVictim) && IsPlayerAlive(iVictim) && GetClientTeam(iVictim) != bossTeam && !TF2_IsUbercharged(iVictim))
		{
			GetClientAbsOrigin(iVictim, vecTargetPos);
			
			float flDistance = GetVectorDistance(vecTargetPos, vecPos);
			
			if (flDistance <= flRadius)
			{
				TF2_AddCondition(iVictim, TFCond_Gas, flRageDuration, boss.iClient);
			}
		}
	}
	
	if (g_flRageGasEnd[boss.iClient] == 0.0)
	{
		g_flPreviousSpeed[boss.iClient] = boss.flSpeed;
		boss.flSpeed *= boss.GetPropFloat("RageGas", "RageSpeedMult");
		
		if (boss.bSuperRage)
		{
		TF2_AddCondition(boss.iClient, TFCond_TeleportedGlow, flRageDuration, boss.iClient);
		boss.flSpeed *= boss.GetPropFloat("RageGas", "RageSpeedMult");
		}
	}
	
	g_flRageGasEnd[boss.iClient] = GetGameTime() + flRageDuration;
	
	TF2_AddCondition(boss.iClient, TFCond_SpeedBuffAlly, flRageDuration, boss.iClient);
	
	int iWeapon = TF2_GetItemInSlot(boss.iClient, WeaponSlot_Primary);
	if (iWeapon != INVALID_ENT_REFERENCE)
	{
		TF2Attrib_SetByDefIndex(iWeapon, ATTRIB_MINICRIT_BECOMES_CRIT, 1.0);
		TF2Attrib_ClearCache(iWeapon);
	}
}

public void RageGas_OnThink(SaxtonHaleBase boss)
{
	if (g_flRageGasEnd[boss.iClient] == 0.0)
		return;
	
	float flGameTime = GetGameTime();
	if (flGameTime > g_flRageGasEnd[boss.iClient])
	{
		g_flRageGasEnd[boss.iClient] = 0.0;
		boss.flSpeed = g_flPreviousSpeed[boss.iClient];
		
		int iWeapon = TF2_GetItemInSlot(boss.iClient, WeaponSlot_Primary);
		if (iWeapon != INVALID_ENT_REFERENCE)
		{
			TF2Attrib_RemoveByDefIndex(iWeapon, ATTRIB_MINICRIT_BECOMES_CRIT);
			TF2Attrib_ClearCache(iWeapon);
		}
	}
}
