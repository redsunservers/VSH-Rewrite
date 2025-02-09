// Inspired by ff2_sarysamods4's Meteor Shower ability

static const char g_sRocketModels[][] =
{
	"models/props_wasteland/rockgranite03a.mdl",
	"models/props_wasteland/rockgranite03b.mdl",
	"models/props_wasteland/rockgranite03c.mdl"
};

static Handle g_hFreezeTimer[MAXPLAYERS];
static int g_iRocketCount[MAXPLAYERS];
static float g_flNextRocketIn[MAXPLAYERS];
static int g_iRocketModels[3];

public void RageMeteor_Precache(SaxtonHaleBase boss)
{
	PrecacheSound(FREEZE_SOUND);

	for (int i = 0; i < sizeof(g_sRocketModels); i++)
	{
		g_iRocketModels[i] = PrecacheModel(g_sRocketModels[i]);
	}
}

public void RageMeteor_Create(SaxtonHaleBase boss)
{
	g_iRocketCount[boss.iClient] = 0;
	g_flNextRocketIn[boss.iClient] = 0.0;

	boss.SetPropFloat("RageMeteor", "Damage", 50.0);
	boss.SetPropFloat("RageMeteor", "Speed", 300.0);
	boss.SetPropFloat("RageMeteor", "SpawnRadius", 250.0);
	boss.SetPropFloat("RageMeteor", "MinAngle", 45.0);
	boss.SetPropFloat("RageMeteor", "FreezeTime", 1.5);
	boss.SetPropFloat("RageMeteor", "SpawnDelay", 0.094);
	boss.SetPropFloat("RageMeteor", "SpawnDelaySuper", 0.077);
	boss.SetPropInt("RageMeteor", "SpawnCount", 70);
	boss.SetPropInt("RageMeteor", "SpawnCountSuper", 130);
}

public void RageMeteor_OnRage(SaxtonHaleBase boss)
{
	g_iRocketCount[boss.iClient] = boss.GetPropInt("RageMeteor", boss.bSuperRage ? "SpawnCountSuper" : "SpawnCount");
	g_flNextRocketIn[boss.iClient] = GetGameTime();
}

public void RageMeteor_OnThink(SaxtonHaleBase boss)
{
	if (g_iRocketCount[boss.iClient] == 0)
		return;
	
	float flGameTime = GetGameTime();
	if (g_flNextRocketIn[boss.iClient] < flGameTime)
	{
		g_flNextRocketIn[boss.iClient] += boss.GetPropFloat("RageMeteor", boss.bSuperRage ? "SpawnDelaySuper" : "SpawnDelay");
		g_iRocketCount[boss.iClient]--;
		SpawnRocket(boss);
	}
}

public Action RageMeteor_OnTakeDamage(SaxtonHaleBase boss, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if (boss.iClient == attacker && IsValidEntity(inflictor))
	{
		char sClassname[36];
		GetEntityClassname(inflictor, sClassname, sizeof(sClassname));

		if (strcmp(sClassname, "tf_projectile_rocket") == 0)
		{
			return Plugin_Handled;
		}
	}

	return Plugin_Continue;

}

public Action RageMeteor_OnAttackDamage(SaxtonHaleBase boss, int victim, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if (IsValidEntity(inflictor))
	{
		char sClassname[36];
		GetEntityClassname(inflictor, sClassname, sizeof(sClassname));

		if (strcmp(sClassname, "tf_projectile_rocket") == 0)
		{
			float flDuration = boss.GetPropFloat("RageMeteor", "FreezeTime");
			if (flDuration > 0.0)
			{
				if (!g_hFreezeTimer[victim])
				{
					float vecOrigin[3];
					GetClientAbsOrigin(victim, vecOrigin);
					TF2_SpawnParticle(FREEZE_PARTICLE_01, vecOrigin);
					TF2_SpawnParticle(FREEZE_PARTICLE_02, vecOrigin);
					TF2_SpawnParticle(FREEZE_PARTICLE_03, vecOrigin);
					EmitAmbientSound(FREEZE_SOUND, vecOrigin);
					
					SetEntityRenderColor(victim, 128, 176, 255, 255);
					SetEntityMoveType(victim, MOVETYPE_NONE);
				}

				TF2_StunPlayer(victim, flDuration, 1.0, TF_STUNFLAG_SLOWDOWN);
				
				delete g_hFreezeTimer[victim];

				DataPack pack;
				g_hFreezeTimer[victim] = CreateDataTimer(flDuration, Timer_UnfreezeVictim, pack);
				pack.WriteCell(victim);
				pack.WriteCell(GetClientUserId(victim));
			}
		}
	}
	
	return Plugin_Continue;
}

public void RageMeteor_OnPlayerKilled(SaxtonHaleBase boss, Event event, int iVictim)
{
	if(g_hFreezeTimer[iVictim])
		TriggerTimer(g_hFreezeTimer[iVictim]);
}

static Action Timer_UnfreezeVictim(Handle hTimer, DataPack pack)
{
	pack.Reset();
	int iClient = pack.ReadCell();
	if (iClient == GetClientOfUserId(pack.ReadCell()))
	{
		SetEntityMoveType(iClient, MOVETYPE_WALK);
		SetEntityRenderColor(iClient, 255, 255, 255, 255);

		float vecOrigin[3];
		GetClientAbsOrigin(iClient, vecOrigin);
		EmitAmbientSound(UNFREEZE_SOUND, vecOrigin);
	}

	g_hFreezeTimer[iClient] = null;
	return Plugin_Continue;
}

static void SpawnRocket(SaxtonHaleBase boss)
{
	float vecBossOrigin[3];
	GetEntPropVector(boss.iClient, Prop_Send, "m_vecOrigin", vecBossOrigin);
	vecBossOrigin[2] += 41.5;

	float vecTargetOrigin[3], vecAngles[3];
	GetClientEyePosition(boss.iClient, vecTargetOrigin);
	GetClientEyeAngles(boss.iClient, vecAngles);
	
	// Take crosshair location
	TR_TraceRayFilter(vecTargetOrigin, vecAngles, MASK_PLAYERSOLID, RayType_Infinite, TraceRay_DontHitEntity, boss.iClient);
	if(TR_DidHit())
	{
		TR_GetEndPosition(vecTargetOrigin);
		vecTargetOrigin[2] += 20.0;
	}
	else
	{
		vecTargetOrigin = vecBossOrigin;
	}

	// Stay close to the boss
	float flDistance = GetVectorDistance(vecTargetOrigin, vecBossOrigin);
	if (flDistance > 500.0)
		ConstrainDistance(vecBossOrigin, vecTargetOrigin, flDistance, 500.0);
	
	// Find any valid spots
	float vecSpawnPos[3];
	float radius = boss.GetPropFloat("RageMeteor", "SpawnRadius");
	bool foundValidPoint = false;
	for (int a = 0; a < 5; a++)
	{
		vecAngles[1] = GetRandomFloat(-179.9, 179.9);
		float minDistance = GetRandomFloat(0.0, radius);
		for (int b = 0; b < 3; b++)
		{
			static const float Angles[] = { 0.0, 25.0, -25.0 };
			vecAngles[0] = Angles[b];
			
			Handle trace = TR_TraceRayFilterEx(vecTargetOrigin, vecAngles, (CONTENTS_SOLID|CONTENTS_WINDOW|CONTENTS_GRATE), RayType_Infinite, TraceRay_HitWallOnly);
			TR_GetEndPosition(vecSpawnPos, trace);
			delete trace;

			flDistance = GetVectorDistance(vecTargetOrigin, vecSpawnPos);
			if (flDistance >= minDistance)
			{
				foundValidPoint = true;
				ConstrainDistance(vecTargetOrigin, vecSpawnPos, flDistance, minDistance);
				break;
			}
		}
		
		if (foundValidPoint)
			break;
	}
	
	// Failed to spawn, close quarters area (usually would get nuked anyways)
	if (!foundValidPoint)
		return;
	
	// Spawn close to the ceiling
	vecAngles[0] = -89.9;
	Handle trace = TR_TraceRayFilterEx(vecSpawnPos, vecAngles, (CONTENTS_SOLID|CONTENTS_WINDOW|CONTENTS_GRATE), RayType_Infinite, TraceRay_HitWallOnly);
	TR_GetEndPosition(vecSpawnPos, trace);
	delete trace;
	vecSpawnPos[2] -= 20.0;
	
	// TOO high up
	if(vecSpawnPos[2] > (vecTargetOrigin[2] + 1500.0))
		vecSpawnPos[2] = vecTargetOrigin[2] + 1500.0;
	
	vecAngles[0] = GetRandomFloat(boss.GetPropFloat("RageMeteor", "MinAngle"), 89.9);
	vecAngles[1] = GetRandomFloat(-179.9, 179.9);
	vecAngles[2] = 0.0;
	
	float vecVelocity[3];
	GetAngleVectors(vecAngles, vecVelocity, NULL_VECTOR, NULL_VECTOR);
	ScaleVector(vecVelocity, boss.GetPropFloat("RageMeteor", "Speed"));
	
	int rocket = CreateEntityByName("tf_projectile_rocket");
	TeleportEntity(rocket, vecSpawnPos, vecAngles, vecVelocity);
	SetEntDataFloat(rocket, FindSendPropInfo("CTFProjectile_Rocket", "m_iDeflected") + 4, boss.GetPropFloat("RageMeteor", "Damage"), true);
	SetEntProp(rocket, Prop_Send, "m_nSkin", GetClientTeam(boss.iClient) - 2);
	SetEntPropEnt(rocket, Prop_Send, "m_hOwnerEntity", boss.iClient);
	SetEntProp(rocket, Prop_Send, "m_iTeamNum", GetClientTeam(boss.iClient));
	DispatchSpawn(rocket);
	
	// Use any weapon attributes
	SetEntPropEnt(rocket, Prop_Send, "m_hOriginalLauncher", GetPlayerWeaponSlot(boss.iClient, TFWeaponSlot_Melee));
	SetEntPropEnt(rocket, Prop_Send, "m_hLauncher", GetPlayerWeaponSlot(boss.iClient, TFWeaponSlot_Melee));

	// Set the model without hitbox changing
	SetEntProp(rocket, Prop_Send, "m_nModelIndex", g_iRocketModels[GetURandomInt() % sizeof(g_iRocketModels)]);
	SetEntityRenderMode(rocket, RENDER_TRANSCOLOR);
	SetEntityRenderColor(rocket, 200, 255, 255, 200);
	
	// Dies when the rocket dies
	TF2_SpawnParticle("coin_large_blue", vecSpawnPos, .iEntity = rocket);
}
