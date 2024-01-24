static float g_flZombieLastDamage[MAXPLAYERS];

public void Zombie_Create(SaxtonHaleBase boss)
{
	boss.nClass = TFClass_Scout;
	boss.flSpeed = -1.0;
	boss.iMaxRageDamage = -1;
	boss.bMinion = true;
	boss.bModel = false;
	
	EmitSoundToClient(boss.iClient, SOUND_ALERT);	//Alert player as he spawned
}

public bool Zombie_IsBossHidden(SaxtonHaleBase boss)
{
	return true;
}

public void Zombie_OnSpawn(SaxtonHaleBase boss)
{
	int iWeapon = boss.CallFunction("CreateWeapon", 0, "tf_weapon_bat", 0, TFQual_Normal, "");
	if (iWeapon > MaxClients)
		SetEntPropEnt(boss.iClient, Prop_Send, "m_hActiveWeapon", iWeapon);
	
	TF2_AddCondition(boss.iClient, TFCond_CritOnDamage, TFCondDuration_Infinite);
	
	SetVariantString("TLK_RESURRECTED");
	AcceptEntityInput(boss.iClient, "SpeakResponseConcept");
	
	SetEntityRenderColor(boss.iClient, 206, 100, 100, _);
}

public void Zombie_OnThink(SaxtonHaleBase boss)
{
	int iClient = boss.iClient;
	
	if (!IsPlayerAlive(iClient)) return;
	
	if (g_flZombieLastDamage[iClient] == 0.0 || g_flZombieLastDamage[iClient] <= GetGameTime()-1.0)
	{
		SDKHooks_TakeDamage(iClient, 0, iClient, float(RoundToCeil(SDK_GetMaxHealth(iClient)*0.04)), DMG_PREVENT_PHYSICS_FORCE);
		g_flZombieLastDamage[iClient] = GetGameTime();
	}
	
	if (!TF2_IsPlayerInCondition(iClient, TFCond_Bleeding))
		TF2_MakeBleed(iClient, iClient, 99999.0);
}

public Action Zombie_OnAttackDamage(SaxtonHaleBase boss, int victim, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	int iClient = boss.iClient;
	
	//Reset the last-hurt timer on hit
	if (iClient != victim && GetClientTeam(iClient) != GetClientTeam(victim))
		g_flZombieLastDamage[iClient] = GetGameTime();
	
	return Plugin_Continue;
}

public Action Zombie_OnVoiceCommand(SaxtonHaleBase boss, char sCmd1[8], char sCmd2[8])
{
	if (sCmd1[0] == '0' && sCmd2[0] == '0')
	{
		//Since zombie scout cant get healed from medic, dont allow him to call medic
		PrintHintText(boss.iClient, "You can't heal as zombie!");
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public Action Zombie_CanHealTarget(SaxtonHaleBase boss, int iTarget, bool &bResult)
{
	//Don't heal other bosses
	if (SaxtonHale_IsValidBoss(iTarget))
	{
		bResult = false;
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}

public void Zombie_Destroy(SaxtonHaleBase boss)
{
	SetEntityRenderColor(boss.iClient, 255, 255, 255, _);
	
	if (TF2_IsPlayerInCondition(boss.iClient, TFCond_CritOnDamage))
		TF2_RemoveCondition(boss.iClient, TFCond_CritOnDamage);
}
