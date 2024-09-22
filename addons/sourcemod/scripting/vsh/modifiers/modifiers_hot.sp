public void ModifiersHot_Create(SaxtonHaleBase boss)
{
}

public void ModifiersHot_GetModifiersName(SaxtonHaleBase boss, char[] sName, int length)
{
	strcopy(sName, length, "Hot");
}

public void ModifiersHot_GetModifiersInfo(SaxtonHaleBase boss, char[] sInfo, int length)
{
	StrCat(sInfo, length, "\nColor: Red");
	StrCat(sInfo, length, "\n ");
	StrCat(sInfo, length, "\n- Ignites nearby players for 10 seconds, dealing 3 damage");
	StrCat(sInfo, length, "\n- Boss ignites when taking any damage");
}

public void ModifiersHot_GetRenderColor(SaxtonHaleBase boss, int iColor[4])
{
	iColor[0] = 255;
	iColor[1] = 64;
	iColor[2] = 64;
	iColor[3] = 255;
}

public void ModifiersHot_GetParticleEffect(SaxtonHaleBase boss, int index, char[] sEffect, int length)
{
	if (index == 0)
		strcopy(sEffect, length, "utaunt_glowyplayer_orange_parent");
}

public void ModifiersHot_OnThink(SaxtonHaleBase boss)
{
	int iTeam = GetClientTeam(boss.iClient);
	
	if (!IsPlayerAlive(boss.iClient)) return;
	
	float vecClientPos[3];
	GetClientAbsOrigin(boss.iClient, vecClientPos);
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) > 1 && GetClientTeam(i) != iTeam)
		{
			float vecTargetPos[3];
			GetClientAbsOrigin(i, vecTargetPos);
			
			if (GetVectorDistance(vecClientPos, vecTargetPos) < 200.0)
				TF2_IgnitePlayer(i, boss.iClient);
		}
	}
}

public Action ModifiersHot_OnAttackDamage(SaxtonHaleBase boss, int victim, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if (damagetype & DMG_BURN)
	{
		damage *= 0.75;
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}

public Action ModifiersHot_OnTakeDamage(SaxtonHaleBase boss, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if (TF2_IsUbercharged(boss.iClient))
		return Plugin_Continue;
	
	if (damagetype & DMG_BURN)
	{
		damage *= 3.0;
		if (damage > 12.0) damage = 12.0;
		return Plugin_Continue;
	}
	
	if (0 < attacker <= MaxClients && IsClientInGame(attacker))
		TF2_IgnitePlayer(boss.iClient, attacker);
	
	return Plugin_Continue;
}
