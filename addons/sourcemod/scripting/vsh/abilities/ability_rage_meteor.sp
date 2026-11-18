// Inspired by ff2_sarysamods4's Meteor Shower ability

#define RAGEMETEOR_MAX_CIRCLES	8
#define RAGEMETEOR_MAX_ROCKS	8
#define RAGEMETEOR_REDRAW	0.1
#define RAGEMETEOR_RING_HEIGHT	8.0
#define RAGEMETEOR_BLAST_HEIGHT	24.0
#define RAGEMETEOR_ROCK_HEIGHT	1500.0
#define RAGEMETEOR_NOT_SOLID	0x0004
#define RAGEMETEOR_IMPACT_SOUND	"player/taunt_yeti_land.wav"

static const char g_sRocketModels[][] =
{
	"models/props_wasteland/rockgranite03a.mdl",
	"models/props_wasteland/rockgranite03b.mdl",
	"models/props_wasteland/rockgranite03c.mdl"
};

static const char g_sRageMeteorBuildings[][] =
{
	"obj_sentrygun",
	"obj_dispenser",
	"obj_teleporter"
};

static Handle g_hFreezeTimer[MAXPLAYERS];
static int g_iRocketModels[3];

static float g_flRageMeteorPos[MAXPLAYERS][RAGEMETEOR_MAX_CIRCLES * 3];
static float g_flRageMeteorRadius[MAXPLAYERS][RAGEMETEOR_MAX_CIRCLES];
static float g_flRageMeteorExplode[MAXPLAYERS][RAGEMETEOR_MAX_CIRCLES];
static float g_flRageMeteorNextDraw[MAXPLAYERS][RAGEMETEOR_MAX_CIRCLES];
static int g_iRageMeteorRocks[MAXPLAYERS][RAGEMETEOR_MAX_CIRCLES * RAGEMETEOR_MAX_ROCKS];
static bool g_bRageMeteorDamaging;
static int g_iRageMeteorWavesLeft[MAXPLAYERS];
static float g_flRageMeteorNextWave[MAXPLAYERS];
static bool g_bRageMeteorWaveSuper[MAXPLAYERS];

public void RageMeteor_Precache(SaxtonHaleBase boss)
{
	PrecacheSound(FREEZE_SOUND);
	PrecacheSound(RAGEMETEOR_IMPACT_SOUND);

	for (int i = 0; i < sizeof(g_sRocketModels); i++)
	{
		g_iRocketModels[i] = PrecacheModel(g_sRocketModels[i]);
	}
}

public void RageMeteor_Create(SaxtonHaleBase boss)
{
	RageMeteor_ClearCircles(boss.iClient);

	boss.SetPropFloat("RageMeteor", "Damage", 100.0);
	boss.SetPropFloat("RageMeteor", "FreezeTime", 3.0);
	boss.SetPropInt("RageMeteor", "PlayersPerCircle", 8);
	boss.SetPropFloat("RageMeteor", "TargetRadius", 500.0);
	boss.SetPropFloat("RageMeteor", "TargetRadiusSuper", 800.0);
	boss.SetPropFloat("RageMeteor", "TargetRadiusFar", 1000.0);
	boss.SetPropFloat("RageMeteor", "TargetRadiusFarSuper", 1200.0);
	boss.SetPropFloat("RageMeteor", "CircleRadius", 75.0);
	boss.SetPropFloat("RageMeteor", "CircleRadiusSuper", 100.0);
	boss.SetPropFloat("RageMeteor", "Fuse", 3.0);
	boss.SetPropFloat("RageMeteor", "FuseSuper", 2.0);
	boss.SetPropInt("RageMeteor", "Waves", 3);
	boss.SetPropInt("RageMeteor", "WavesSuper", 5);
	boss.SetPropInt("RageMeteor", "RockCount", 6);
}

public void RageMeteor_Destroy(SaxtonHaleBase boss)
{
	RageMeteor_ClearCircles(boss.iClient);
}

bool RageMeteor_IsDamaging()
{
	return g_bRageMeteorDamaging;
}

static float RageMeteor_GetRageProp(SaxtonHaleBase boss, bool bSuper, const char[] sProp, const char[] sPropSuper)
{
	if (bSuper)
		return boss.GetPropFloat("RageMeteor", sPropSuper);

	return boss.GetPropFloat("RageMeteor", sProp);
}

public void RageMeteor_OnRage(SaxtonHaleBase boss)
{
	int iClient = boss.iClient;

	g_bRageMeteorWaveSuper[iClient] = boss.bSuperRage;
	if (boss.bSuperRage)
		g_iRageMeteorWavesLeft[iClient] = boss.GetPropInt("RageMeteor", "WavesSuper");
	else
		g_iRageMeteorWavesLeft[iClient] = boss.GetPropInt("RageMeteor", "Waves");

	if (g_iRageMeteorWavesLeft[iClient] > 0)
		RageMeteor_StartWave(boss);
}

static void RageMeteor_StartWave(SaxtonHaleBase boss)
{
	int iClient = boss.iClient;
	bool bSuper = g_bRageMeteorWaveSuper[iClient];
	float flTargetRadius = RageMeteor_GetRageProp(boss, bSuper, "TargetRadius", "TargetRadiusSuper");
	float flTargetRadiusFar = RageMeteor_GetRageProp(boss, bSuper, "TargetRadiusFar", "TargetRadiusFarSuper");
	float flCircleRadius = RageMeteor_GetRageProp(boss, bSuper, "CircleRadius", "CircleRadiusSuper");
	float flFuse = RageMeteor_GetRageProp(boss, bSuper, "Fuse", "FuseSuper");

	g_iRageMeteorWavesLeft[iClient]--;
	g_flRageMeteorNextWave[iClient] = GetGameTime() + flFuse;

	int iPlayers = g_iTotalAttackCount - Afk_GetCount();
	if (iPlayers < 1)
		iPlayers = 1;

	int iPerCircle = boss.GetPropInt("RageMeteor", "PlayersPerCircle");
	if (iPerCircle < 1)
		iPerCircle = 1;

	int iCircles = RoundToCeil(float(iPlayers) / float(iPerCircle));
	if (iCircles > RAGEMETEOR_MAX_CIRCLES)
		iCircles = RAGEMETEOR_MAX_CIRCLES;

	static float vecCandidate[MAXPLAYERS][3];
	int iNear = 0;
	int iFar = 0;

	float vecBoss[3];
	GetClientAbsOrigin(iClient, vecBoss);
	int iTeam = GetClientTeam(iClient);

	for (int iPass = 0; iPass < 2; iPass++)
	{
		for (int iVictim = 1; iVictim <= MaxClients; iVictim++)
		{
			if (!IsClientInGame(iVictim) || !IsPlayerAlive(iVictim) || GetClientTeam(iVictim) <= 1 || GetClientTeam(iVictim) == iTeam)
				continue;

			if (TF2_IsPlayerInCondition(iVictim, TFCond_Cloaked) || TF2_IsPlayerInCondition(iVictim, TFCond_Stealthed))
				continue;

			bool bNear = IsClientInRange(iVictim, vecBoss, flTargetRadius);
			if (iPass == 0)
			{
				if (!bNear)
					continue;
			}
			else if (bNear || !IsClientInRange(iVictim, vecBoss, flTargetRadiusFar))
			{
				continue;
			}

			RageMeteor_GetGroundPos(iVictim, vecCandidate[iNear + iFar]);
			if (iPass == 0)
				iNear++;
			else
				iFar++;
		}
	}

	float vecChosen[RAGEMETEOR_MAX_CIRCLES][3];
	int iChosen = 0;
	int iNearLeft = iNear;
	int iFarLeft = iFar;

	while (iChosen < iCircles)
	{
		bool bFromNear = (iNearLeft > 0);
		int iFirst = 0;
		int iEnd = iNearLeft;
		if (!bFromNear)
		{
			iFirst = iNear;
			iEnd = iNear + iFarLeft;
		}

		if (iEnd <= iFirst)
			break;

		int iPick = -1;
		if (iChosen == 0)
		{
			iPick = GetRandomInt(iFirst, iEnd - 1);
		}
		else
		{
			static int iClear[MAXPLAYERS];
			int iClearCount = 0;
			int iFurthest = -1;
			float flFurthest = -1.0;

			for (int i = iFirst; i < iEnd; i++)
			{
				float flNearest = -1.0;
				for (int j = 0; j < iChosen; j++)
				{
					float flDistance = GetVectorDistance(vecCandidate[i], vecChosen[j]);
					if (flNearest < 0.0 || flDistance < flNearest)
						flNearest = flDistance;
				}

				if (flNearest >= flCircleRadius * 2.0)
					iClear[iClearCount++] = i;

				if (flNearest > flFurthest)
				{
					flFurthest = flNearest;
					iFurthest = i;
				}
			}

			if (iClearCount > 0)
				iPick = iClear[GetRandomInt(0, iClearCount - 1)];
			else
				iPick = iFurthest;
		}

		if (iPick < 0)
			break;

		vecChosen[iChosen][0] = vecCandidate[iPick][0];
		vecChosen[iChosen][1] = vecCandidate[iPick][1];
		vecChosen[iChosen][2] = vecCandidate[iPick][2];
		RageMeteor_PlaceCircle(boss, vecChosen[iChosen], flCircleRadius, flFuse);
		iChosen++;

		vecCandidate[iPick][0] = vecCandidate[iEnd - 1][0];
		vecCandidate[iPick][1] = vecCandidate[iEnd - 1][1];
		vecCandidate[iPick][2] = vecCandidate[iEnd - 1][2];
		if (bFromNear)
			iNearLeft--;
		else
			iFarLeft--;
	}
}

static void RageMeteor_GetGroundPos(int iClient, float vecPos[3])
{
	GetClientAbsOrigin(iClient, vecPos);
	if (GetEntityFlags(iClient) & FL_ONGROUND)
		return;

	float vecEnd[3];
	vecEnd[0] = vecPos[0];
	vecEnd[1] = vecPos[1];
	vecEnd[2] = vecPos[2] - 2000.0;

	TR_TraceRayFilter(vecPos, vecEnd, MASK_PLAYERSOLID, RayType_EndPoint, TraceRay_DontHitPlayersAndObjects);
	if (TR_DidHit())
		TR_GetEndPosition(vecPos);
}

static void RageMeteor_PlaceCircle(SaxtonHaleBase boss, const float vecGround[3], float flRadius, float flFuse)
{
	int iClient = boss.iClient;

	int iSlot = -1;
	for (int i = 0; i < RAGEMETEOR_MAX_CIRCLES; i++)
	{
		if (g_flRageMeteorExplode[iClient][i] <= 0.0)
		{
			iSlot = i;
			break;
		}
	}

	if (iSlot == -1)
		return;

	float flNow = GetGameTime();
	float vecPos[3];
	vecPos[0] = vecGround[0];
	vecPos[1] = vecGround[1];
	vecPos[2] = vecGround[2] + RAGEMETEOR_RING_HEIGHT;

	g_flRageMeteorPos[iClient][iSlot * 3] = vecPos[0];
	g_flRageMeteorPos[iClient][iSlot * 3 + 1] = vecPos[1];
	g_flRageMeteorPos[iClient][iSlot * 3 + 2] = vecPos[2];
	g_flRageMeteorRadius[iClient][iSlot] = flRadius;
	g_flRageMeteorExplode[iClient][iSlot] = flNow + flFuse;
	g_flRageMeteorNextDraw[iClient][iSlot] = flNow + RAGEMETEOR_REDRAW;

	TE_SetupBeamRingPoint(vecPos, flRadius * 2.0, 1.0, g_iSpritesLaserbeam, g_iSpritesGlow, 0, 10, flFuse, 6.0, 0.0, {255, 255, 255, 255}, 10, 0);
	TE_SendToAll();
	RageMeteor_DrawCircle(vecPos, flRadius);

	RageMeteor_SpawnRocks(boss, iSlot, vecPos, flRadius, flFuse);
}

static void RageMeteor_DrawCircle(const float vecPos[3], float flRadius)
{
	TE_SetupBeamRingPoint(vecPos, flRadius * 2.0, flRadius * 2.0 + 1.0, g_iSpritesLaserbeam, g_iSpritesGlow, 0, 10, RAGEMETEOR_REDRAW + 0.1, 10.0, 0.0, {120, 200, 255, 255}, 10, 0);
	TE_SendToAll();
}

public void RageMeteor_OnThink(SaxtonHaleBase boss)
{
	int iClient = boss.iClient;
	float flNow = GetGameTime();

	for (int i = 0; i < RAGEMETEOR_MAX_CIRCLES; i++)
	{
		if (g_flRageMeteorExplode[iClient][i] <= 0.0)
			continue;

		float vecPos[3];
		vecPos[0] = g_flRageMeteorPos[iClient][i * 3];
		vecPos[1] = g_flRageMeteorPos[iClient][i * 3 + 1];
		vecPos[2] = g_flRageMeteorPos[iClient][i * 3 + 2];

		if (flNow >= g_flRageMeteorExplode[iClient][i])
		{
			g_flRageMeteorExplode[iClient][i] = 0.0;
			RageMeteor_RemoveRocks(iClient, i);

			if (IsPlayerAlive(iClient))
				RageMeteor_Detonate(boss, vecPos, g_flRageMeteorRadius[iClient][i]);
		}
		else if (flNow >= g_flRageMeteorNextDraw[iClient][i])
		{
			g_flRageMeteorNextDraw[iClient][i] = flNow + RAGEMETEOR_REDRAW;
			RageMeteor_DrawCircle(vecPos, g_flRageMeteorRadius[iClient][i]);
		}
	}

	if (g_iRageMeteorWavesLeft[iClient] > 0 && flNow >= g_flRageMeteorNextWave[iClient])
	{
		if (IsPlayerAlive(iClient))
			RageMeteor_StartWave(boss);
		else
			g_iRageMeteorWavesLeft[iClient] = 0;
	}
}

static void RageMeteor_Detonate(SaxtonHaleBase boss, float vecPos[3], float flRadius)
{
	int iClient = boss.iClient;
	vecPos[2] += RAGEMETEOR_BLAST_HEIGHT;

	char sParticle[64];
	strcopy(sParticle, sizeof(sParticle), FREEZE_PARTICLE_01);
	CreateTimer(3.0, Timer_EntityCleanup, TF2_SpawnParticle(sParticle, vecPos));
	strcopy(sParticle, sizeof(sParticle), FREEZE_PARTICLE_02);
	CreateTimer(3.0, Timer_EntityCleanup, TF2_SpawnParticle(sParticle, vecPos));
	EmitAmbientSound(RAGEMETEOR_IMPACT_SOUND, vecPos, _, SNDLEVEL_SCREAMING);
	TF2_Shake(vecPos, 10.0, flRadius, 1.0, 0.5);

	float flDamage = boss.GetPropFloat("RageMeteor", "Damage");
	int iTeam = GetClientTeam(iClient);

	g_bRageMeteorDamaging = true;

	for (int iVictim = 1; iVictim <= MaxClients; iVictim++)
	{
		if (!IsClientInGame(iVictim) || !IsPlayerAlive(iVictim) || GetClientTeam(iVictim) <= 1 || GetClientTeam(iVictim) == iTeam)
			continue;

		if (RageMeteor_GetBoxDistance(iVictim, vecPos) > flRadius || !RageMeteor_IsInSight(vecPos, iVictim))
			continue;

		SDKHooks_TakeDamage(iVictim, iClient, iClient, flDamage, DMG_BLAST, -1, NULL_VECTOR, vecPos, false);

		if (IsClientInGame(iVictim) && IsPlayerAlive(iVictim))
			RageMeteor_FreezeVictim(boss, iVictim);
	}

	for (int i = 0; i < sizeof(g_sRageMeteorBuildings); i++)
	{
		int iBuilding = INVALID_ENT_REFERENCE;
		while ((iBuilding = FindEntityByClassname(iBuilding, g_sRageMeteorBuildings[i])) > MaxClients)
		{
			if (GetEntProp(iBuilding, Prop_Send, "m_iTeamNum") == iTeam)
				continue;

			if (GetEntProp(iBuilding, Prop_Send, "m_bCarried") || GetEntProp(iBuilding, Prop_Send, "m_bPlacing"))
				continue;

			if (RageMeteor_GetBoxDistance(iBuilding, vecPos) > flRadius || !RageMeteor_IsInSight(vecPos, iBuilding))
				continue;

			SDKHooks_TakeDamage(iBuilding, iClient, iClient, flDamage, DMG_BLAST, -1, NULL_VECTOR, vecPos, false);
		}
	}

	g_bRageMeteorDamaging = false;
}

void RageMeteor_FreezeVictim(SaxtonHaleBase boss, int iVictim)
{
	float flDuration = boss.GetPropFloat("RageMeteor", "FreezeTime");
	if (flDuration <= 0.0)
		return;

	if (!g_hFreezeTimer[iVictim])
	{
		float vecOrigin[3];
		GetClientAbsOrigin(iVictim, vecOrigin);

		char sParticle[64];
		strcopy(sParticle, sizeof(sParticle), FREEZE_PARTICLE_01);
		CreateTimer(3.0, Timer_EntityCleanup, TF2_SpawnParticle(sParticle, vecOrigin));
		strcopy(sParticle, sizeof(sParticle), FREEZE_PARTICLE_02);
		CreateTimer(3.0, Timer_EntityCleanup, TF2_SpawnParticle(sParticle, vecOrigin));
		strcopy(sParticle, sizeof(sParticle), FREEZE_PARTICLE_03);
		CreateTimer(3.0, Timer_EntityCleanup, TF2_SpawnParticle(sParticle, vecOrigin));
		EmitAmbientSound(FREEZE_SOUND, vecOrigin);

		SetEntityRenderColor(iVictim, 128, 176, 255, 255);
	}

	AddTemporarySlowdownToClient(iVictim, 0.5, flDuration);

	delete g_hFreezeTimer[iVictim];

	DataPack pack;
	g_hFreezeTimer[iVictim] = CreateDataTimer(flDuration, Timer_UnfreezeVictim, pack);
	pack.WriteCell(iVictim);
	pack.WriteCell(GetClientUserId(iVictim));
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

		SetEntityRenderColor(iClient, 255, 255, 255, 255);

		float vecOrigin[3];
		GetClientAbsOrigin(iClient, vecOrigin);
		EmitAmbientSound(UNFREEZE_SOUND, vecOrigin);
	}

	g_hFreezeTimer[iClient] = null;
	return Plugin_Continue;
}

static void RageMeteor_SpawnRocks(SaxtonHaleBase boss, int iSlot, const float vecCentre[3], float flRadius, float flFuse)
{
	int iClient = boss.iClient;
	int iRocks = boss.GetPropInt("RageMeteor", "RockCount");
	if (iRocks > RAGEMETEOR_MAX_ROCKS)
		iRocks = RAGEMETEOR_MAX_ROCKS;

	for (int i = 0; i < iRocks; i++)
	{
		g_iRageMeteorRocks[iClient][iSlot * RAGEMETEOR_MAX_ROCKS + i] = INVALID_ENT_REFERENCE;
		if (flFuse <= 0.0)
			continue;

		float flAngle = GetRandomFloat(0.0, 2.0 * FLOAT_PI);
		float flDistance = flRadius * 0.9 * SquareRoot(GetRandomFloat(0.0, 1.0));

		float vecLand[3];
		vecLand[0] = vecCentre[0] + Cosine(flAngle) * flDistance;
		vecLand[1] = vecCentre[1] + Sine(flAngle) * flDistance;
		vecLand[2] = vecCentre[2];

		// Spawn close to the ceiling
		float vecSpawnPos[3], vecAngles[3];
		vecAngles[0] = -89.9;
		Handle trace = TR_TraceRayFilterEx(vecLand, vecAngles, (CONTENTS_SOLID|CONTENTS_WINDOW|CONTENTS_GRATE), RayType_Infinite, TraceRay_HitWallOnly);
		TR_GetEndPosition(vecSpawnPos, trace);
		delete trace;
		vecSpawnPos[2] -= 20.0;

		// TOO high up
		if(vecSpawnPos[2] > (vecLand[2] + RAGEMETEOR_ROCK_HEIGHT))
			vecSpawnPos[2] = vecLand[2] + RAGEMETEOR_ROCK_HEIGHT;

		if (vecSpawnPos[2] < vecLand[2] + 40.0)
			continue;

		float vecVelocity[3];
		vecVelocity[0] = (vecLand[0] - vecSpawnPos[0]) / flFuse;
		vecVelocity[1] = (vecLand[1] - vecSpawnPos[1]) / flFuse;
		vecVelocity[2] = (vecLand[2] - vecSpawnPos[2]) / flFuse;
		GetVectorAngles(vecVelocity, vecAngles);

		int rocket = CreateEntityByName("tf_projectile_rocket");
		if (rocket <= MaxClients)
			continue;

		TeleportEntity(rocket, vecSpawnPos, vecAngles, vecVelocity);
		SetEntDataFloat(rocket, FindSendPropInfo("CTFProjectile_Rocket", "m_iDeflected") + 4, 0.0, true);
		SetEntProp(rocket, Prop_Send, "m_nSkin", GetClientTeam(iClient) - 2);
		SetEntPropEnt(rocket, Prop_Send, "m_hOwnerEntity", iClient);
		SetEntProp(rocket, Prop_Send, "m_iTeamNum", GetClientTeam(iClient));
		DispatchSpawn(rocket);

		// Use any weapon attributes
		SetEntPropEnt(rocket, Prop_Send, "m_hOriginalLauncher", GetPlayerWeaponSlot(iClient, TFWeaponSlot_Melee));
		SetEntPropEnt(rocket, Prop_Send, "m_hLauncher", GetPlayerWeaponSlot(iClient, TFWeaponSlot_Melee));

		// Set the model without hitbox changing
		SetEntProp(rocket, Prop_Send, "m_nModelIndex", g_iRocketModels[GetURandomInt() % sizeof(g_iRocketModels)]);
		SetEntityRenderMode(rocket, RENDER_TRANSCOLOR);
		SetEntityRenderColor(rocket, 200, 255, 255, 200);

		SetEntProp(rocket, Prop_Send, "m_usSolidFlags", GetEntProp(rocket, Prop_Send, "m_usSolidFlags") | RAGEMETEOR_NOT_SOLID);
		SetEntityMoveType(rocket, MOVETYPE_NOCLIP);
		TeleportEntity(rocket, NULL_VECTOR, NULL_VECTOR, vecVelocity);

		// Dies when the rocket dies
		TF2_SpawnParticle("coin_large_blue", vecSpawnPos, .iEntity = rocket);

		g_iRageMeteorRocks[iClient][iSlot * RAGEMETEOR_MAX_ROCKS + i] = EntIndexToEntRef(rocket);
	}
}

static void RageMeteor_RemoveRocks(int iClient, int iSlot)
{
	for (int i = 0; i < RAGEMETEOR_MAX_ROCKS; i++)
	{
		int iRef = g_iRageMeteorRocks[iClient][iSlot * RAGEMETEOR_MAX_ROCKS + i];
		g_iRageMeteorRocks[iClient][iSlot * RAGEMETEOR_MAX_ROCKS + i] = INVALID_ENT_REFERENCE;

		if (iRef == 0 || iRef == INVALID_ENT_REFERENCE)
			continue;

		int iRock = EntRefToEntIndex(iRef);
		if (iRock > MaxClients)
			RemoveEntity(iRock);
	}
}

static void RageMeteor_ClearCircles(int iClient)
{
	g_iRageMeteorWavesLeft[iClient] = 0;
	for (int i = 0; i < RAGEMETEOR_MAX_CIRCLES; i++)
	{
		g_flRageMeteorExplode[iClient][i] = 0.0;
		RageMeteor_RemoveRocks(iClient, i);
	}
}

float RageMeteor_GetBoxDistance(int iEntity, const float vecPos[3])
{
	float vecOrigin[3], vecMins[3], vecMaxs[3];
	GetEntPropVector(iEntity, Prop_Data, "m_vecAbsOrigin", vecOrigin);
	GetEntPropVector(iEntity, Prop_Send, "m_vecMins", vecMins);
	GetEntPropVector(iEntity, Prop_Send, "m_vecMaxs", vecMaxs);

	float flDistSq = 0.0;
	for (int i = 0; i < 3; i++)
	{
		float flDelta = 0.0;
		if (vecPos[i] < vecOrigin[i] + vecMins[i])
			flDelta = vecOrigin[i] + vecMins[i] - vecPos[i];
		else if (vecPos[i] > vecOrigin[i] + vecMaxs[i])
			flDelta = vecPos[i] - vecOrigin[i] - vecMaxs[i];

		flDistSq += flDelta * flDelta;
	}

	return SquareRoot(flDistSq);
}

bool RageMeteor_IsInSight(const float vecFrom[3], int iEntity)
{
	float vecTo[3], vecMins[3], vecMaxs[3];
	GetEntPropVector(iEntity, Prop_Data, "m_vecAbsOrigin", vecTo);
	GetEntPropVector(iEntity, Prop_Send, "m_vecMins", vecMins);
	GetEntPropVector(iEntity, Prop_Send, "m_vecMaxs", vecMaxs);
	for (int i = 0; i < 3; i++)
		vecTo[i] += (vecMins[i] + vecMaxs[i]) * 0.5;

	TR_TraceRayFilter(vecFrom, vecTo, MASK_SOLID, RayType_EndPoint, RageMeteor_TraceGeometry);
	return !TR_DidHit();
}

bool RageMeteor_TraceGeometry(int iEntity, int iMask, any data)
{
	if (iEntity == 0)
		return true;

	if (iEntity <= MaxClients)
		return false;

	char sClassname[32];
	GetEntityClassname(iEntity, sClassname, sizeof(sClassname));
	if (StrEqual(sClassname, "prop_ragdoll"))
		return false;

	return strncmp(sClassname, "func_", 5) == 0 || strncmp(sClassname, "prop_", 5) == 0;
}
