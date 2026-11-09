#define ZOMBIE_SPAWN_UBER	7.0

static float g_flZombieLastDamage[MAXPLAYERS];
static bool g_bZombieSpawnProtect[MAXPLAYERS];
static bool g_bZombieProtected[MAXPLAYERS];
static bool g_bZombieRestoreCollision[MAXPLAYERS];

public void Zombie_Create(SaxtonHaleBase boss)
{
	boss.nClass = TFClass_Scout;
	boss.flSpeed = -1.0;
	boss.iMaxRageDamage = -1;
	boss.bMinion = true;
	boss.bModel = false;

	g_bZombieSpawnProtect[boss.iClient] = true;
	g_bZombieProtected[boss.iClient] = false;
	g_bZombieRestoreCollision[boss.iClient] = false;
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

	if (g_bZombieSpawnProtect[boss.iClient])
	{
		g_bZombieSpawnProtect[boss.iClient] = false;
		ZombieSpawn_StartProtection(boss.iClient);
	}
}

public void Zombie_OnButtonPress(SaxtonHaleBase boss, int button)
{
	ZombieSpawn_EndProtection(boss.iClient, true);
}

public void Zombie_OnThink(SaxtonHaleBase boss)
{
	int iClient = boss.iClient;

	if (g_bZombieProtected[iClient] && (!IsPlayerAlive(iClient) || !TF2_IsPlayerInCondition(iClient, TFCond_UberchargedCanteen)))
		ZombieSpawn_EndProtection(iClient, false);
	else if (g_bZombieRestoreCollision[iClient])
		ZombieSpawn_RestoreCollision(iClient, false);

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
	g_bZombieSpawnProtect[boss.iClient] = false;
	ZombieSpawn_EndProtection(boss.iClient, true);
	ZombieSpawn_RestoreCollision(boss.iClient, true);

	SetEntityRenderColor(boss.iClient, 255, 255, 255, _);
	
	if (TF2_IsPlayerInCondition(boss.iClient, TFCond_CritOnDamage))
		TF2_RemoveCondition(boss.iClient, TFCond_CritOnDamage);
}

static void ZombieSpawn_StartProtection(int iClient)
{
	TF2_AddCondition(iClient, TFCond_UberchargedCanteen, ZOMBIE_SPAWN_UBER);
	g_bZombieProtected[iClient] = true;
	g_bZombieRestoreCollision[iClient] = false;
	SetEntityCollisionGroup(iClient, view_as<int>(COLLISION_GROUP_DEBRIS));
}

static void ZombieSpawn_EndProtection(int iClient, bool bRemoveUber)
{
	if (!g_bZombieProtected[iClient])
		return;

	g_bZombieProtected[iClient] = false;

	if (!IsClientInGame(iClient))
		return;

	if (bRemoveUber && TF2_IsPlayerInCondition(iClient, TFCond_UberchargedCanteen))
		TF2_RemoveCondition(iClient, TFCond_UberchargedCanteen);

	g_bZombieRestoreCollision[iClient] = true;
	ZombieSpawn_RestoreCollision(iClient, false);
}

static void ZombieSpawn_RestoreCollision(int iClient, bool bForce)
{
	if (!g_bZombieRestoreCollision[iClient] || !IsClientInGame(iClient))
	{
		g_bZombieRestoreCollision[iClient] = false;
		return;
	}

	if (!bForce && IsPlayerAlive(iClient) && ZombieSpawn_IsInsideEnemy(iClient))
		return;

	g_bZombieRestoreCollision[iClient] = false;
	if (GetEntProp(iClient, Prop_Send, "m_CollisionGroup") == view_as<int>(COLLISION_GROUP_DEBRIS))
		SetEntityCollisionGroup(iClient, view_as<int>(COLLISION_GROUP_PLAYER));
}

static bool ZombieSpawn_IsInsideEnemy(int iClient)
{
	float vecPos[3], vecMins[3], vecMaxs[3];
	GetClientAbsOrigin(iClient, vecPos);
	GetClientMins(iClient, vecMins);
	GetClientMaxs(iClient, vecMaxs);

	int iTeam = GetClientTeam(iClient);
	for (int iOther = 1; iOther <= MaxClients; iOther++)
	{
		if (iOther == iClient || !IsClientInGame(iOther) || !IsPlayerAlive(iOther) || GetClientTeam(iOther) == iTeam)
			continue;

		float vecOther[3], vecOtherMins[3], vecOtherMaxs[3];
		GetClientAbsOrigin(iOther, vecOther);
		GetClientMins(iOther, vecOtherMins);
		GetClientMaxs(iOther, vecOtherMaxs);

		bool bOverlap = true;
		for (int i = 0; i < 3; i++)
		{
			if (vecPos[i] + vecMins[i] > vecOther[i] + vecOtherMaxs[i] || vecPos[i] + vecMaxs[i] < vecOther[i] + vecOtherMins[i])
			{
				bOverlap = false;
				break;
			}
		}

		if (bOverlap)
			return true;
	}

	return false;
}
