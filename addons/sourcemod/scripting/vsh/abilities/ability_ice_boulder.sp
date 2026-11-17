#define ICEBOULDER_MODEL	"models/props_wasteland/rockgranite03a.mdl"
#define ICEBOULDER_PARTICLE	"utaunt_snowring_icy_parent"
#define ICEBOULDER_BREAK_PARTICLE_01	"xms_snowburst"
#define ICEBOULDER_BREAK_PARTICLE_02	"xms_icicle_impact_dryice"
#define ICEBOULDER_BREAK_SOUND	"physics/concrete/boulder_impact_hard1.wav"
#define ICEBOULDER_NOT_SOLID	0x0004
#define ICEBOULDER_MAX_SLOPE	0.7
#define ICEBOULDER_CLEARANCE	0.6
#define ICEBOULDER_GROUND_REACH	64.0
#define ICEBOULDER_FALL_SPEED	600.0

static float g_flIceBoulderCooldownEnd[MAXPLAYERS];
static float g_flIceBoulderChargeStart[MAXPLAYERS];
static bool g_bIceBoulderHolding[MAXPLAYERS];
static bool g_bIceBoulderCharged[MAXPLAYERS];
static int g_iIceBoulderParticle[MAXPLAYERS];
static int g_iIceBoulderRock[MAXPLAYERS];
static float g_flIceBoulderDir[MAXPLAYERS][3];
static float g_flIceBoulderEnd[MAXPLAYERS];
static int g_iIceBoulderCaught[MAXPLAYERS];
static bool g_bIceBoulderHit[MAXPLAYERS][MAXPLAYERS];
static bool g_bIceBoulderDamaging;
static int g_iIceBoulderModel;

public void IceBoulder_Precache(SaxtonHaleBase boss)
{
	g_iIceBoulderModel = PrecacheModel(ICEBOULDER_MODEL);
	PrecacheSound(ICEBOULDER_BREAK_SOUND);
	PrecacheParticleSystem(ICEBOULDER_PARTICLE);
	PrecacheParticleSystem(ICEBOULDER_BREAK_PARTICLE_01);
	PrecacheParticleSystem(ICEBOULDER_BREAK_PARTICLE_02);
}

public void IceBoulder_Create(SaxtonHaleBase boss)
{
	int iClient = boss.iClient;
	g_flIceBoulderCooldownEnd[iClient] = 0.0;
	g_flIceBoulderChargeStart[iClient] = 0.0;
	g_bIceBoulderHolding[iClient] = false;
	g_bIceBoulderCharged[iClient] = false;
	g_iIceBoulderParticle[iClient] = INVALID_ENT_REFERENCE;
	g_iIceBoulderRock[iClient] = INVALID_ENT_REFERENCE;

	boss.SetPropFloat("IceBoulder", "Cooldown", 12.0);
	boss.SetPropFloat("IceBoulder", "ChargeTime", 2.0);
	boss.SetPropFloat("IceBoulder", "Speed", 200.0);
	boss.SetPropFloat("IceBoulder", "SpeedPerPlayer", 50.0);
	boss.SetPropFloat("IceBoulder", "Damage", 50.0);
	boss.SetPropFloat("IceBoulder", "Radius", 60.0);
	boss.SetPropFloat("IceBoulder", "ModelScale", 3.0);
	boss.SetPropFloat("IceBoulder", "LifeTime", 10.0);
}

public void IceBoulder_Destroy(SaxtonHaleBase boss)
{
	IceBoulder_StopCharge(boss.iClient);
	IceBoulder_RemoveRock(boss.iClient, false);
}

bool IceBoulder_IsDamaging()
{
	return g_bIceBoulderDamaging;
}

public void IceBoulder_OnArenaRoundStart(SaxtonHaleBase boss)
{
	float flCooldown = boss.GetPropFloat("IceBoulder", "Cooldown");
	g_flIceBoulderCooldownEnd[boss.iClient] = GetGameTime() + flCooldown;
	boss.CallFunction("UpdateHudInfo", 1.0, flCooldown + 1.0);
}

public void IceBoulder_GetHudInfo(SaxtonHaleBase boss, char[] sMessage, int iLength, int iColor[4])
{
	int iClient = boss.iClient;
	float flNow = GetGameTime();

	if (g_flIceBoulderChargeStart[iClient] > 0.0)
	{
		int iCharge = IceBoulder_GetChargePercent(boss);
		if (iCharge >= 100)
			Format(sMessage, iLength, "%s\nIce Meteor charge: 100%%%%%%%%. Release reload to use Ice Meteor.", sMessage);
		else
			Format(sMessage, iLength, "%s\nIce Meteor charge: %d%%%%%%%%.", sMessage, iCharge);
	}
	else if (g_flIceBoulderCooldownEnd[iClient] > flNow)
	{
		int iSec = RoundToCeil(g_flIceBoulderCooldownEnd[iClient] - flNow);
		char sPlural[2];
		if (iSec > 1)
			strcopy(sPlural, sizeof(sPlural), "s");

		Format(sMessage, iLength, "%s\nIce meteor cooldown %i second%s remaining!", sMessage, iSec, sPlural);
	}
	else
	{
		Format(sMessage, iLength, "%s\nHold reload to use your Ice Meteor!", sMessage);
	}
}

public void IceBoulder_OnButton(SaxtonHaleBase boss, int &buttons)
{
	g_bIceBoulderHolding[boss.iClient] = (buttons & IN_RELOAD) != 0;
}

public void IceBoulder_OnButtonPress(SaxtonHaleBase boss, int iButton)
{
	if (iButton != IN_RELOAD || GameRules_GetRoundState() == RoundState_Preround)
		return;

	int iClient = boss.iClient;
	if (g_flIceBoulderChargeStart[iClient] > 0.0 || g_flIceBoulderCooldownEnd[iClient] > GetGameTime())
		return;

	if (!IsPlayerAlive(iClient) || TF2_IsPlayerInCondition(iClient, TFCond_Dazed))
		return;

	g_flIceBoulderChargeStart[iClient] = GetGameTime();
	g_bIceBoulderHolding[iClient] = true;
	g_bIceBoulderCharged[iClient] = false;
	boss.CallFunction("UpdateHudInfo", 0.0, boss.GetPropFloat("IceBoulder", "ChargeTime") + 0.5);

	IceBoulder_RemoveParticle(iClient);
	char sEffect[64];
	strcopy(sEffect, sizeof(sEffect), ICEBOULDER_PARTICLE);
	g_iIceBoulderParticle[iClient] = TF2_AttachParticle(sEffect, iClient);
	int iProp = EntRefToEntIndex(g_iIceBoulderParticle[iClient]);
	if (iProp > MaxClients)
		SetEdictFlags(iProp, GetEdictFlags(iProp) | FL_EDICT_ALWAYS);

	char sSound[PLATFORM_MAX_PATH];
	boss.CallFunction("GetSoundAbility", sSound, sizeof(sSound), "IceBoulder");
	if (!StrEmpty(sSound))
		EmitSoundToAll(sSound, iClient, SNDCHAN_VOICE, SNDLEVEL_SCREAMING);
}

public void IceBoulder_OnThink(SaxtonHaleBase boss)
{
	int iClient = boss.iClient;

	if (g_flIceBoulderChargeStart[iClient] > 0.0)
	{
		if (!IsPlayerAlive(iClient))
		{
			IceBoulder_StopCharge(iClient);
		}
		else if (IceBoulder_GetChargePercent(boss) >= 100)
		{
			if (!g_bIceBoulderHolding[iClient])
			{
				IceBoulder_Throw(boss);
			}
			else if (!g_bIceBoulderCharged[iClient])
			{
				g_bIceBoulderCharged[iClient] = true;
				boss.CallFunction("UpdateHudInfo", 0.0, 0.0);
			}
		}
	}

	IceBoulder_RockThink(boss);
}

static int IceBoulder_GetChargePercent(SaxtonHaleBase boss)
{
	float flChargeTime = boss.GetPropFloat("IceBoulder", "ChargeTime");
	if (flChargeTime <= 0.0)
		return 100;

	int iCharge = RoundToFloor((GetGameTime() - g_flIceBoulderChargeStart[boss.iClient]) / flChargeTime * 100.0);
	if (iCharge > 100)
		iCharge = 100;

	return iCharge;
}

static void IceBoulder_StopCharge(int iClient)
{
	g_flIceBoulderChargeStart[iClient] = 0.0;
	g_bIceBoulderCharged[iClient] = false;
	IceBoulder_RemoveParticle(iClient);
}

static void IceBoulder_RemoveParticle(int iClient)
{
	int iEntity = EntRefToEntIndex(g_iIceBoulderParticle[iClient]);
	g_iIceBoulderParticle[iClient] = INVALID_ENT_REFERENCE;
	if (iEntity <= MaxClients)
		return;

	SetVariantString("ParticleEffectStop");
	AcceptEntityInput(iEntity, "DispatchEffect");
	AcceptEntityInput(iEntity, "ClearParent");

	float vecPos[3] = {8192.0, 8192.0, 8192.0};
	TeleportEntity(iEntity, vecPos, NULL_VECTOR, NULL_VECTOR);
	CreateTimer(0.5, Timer_EntityCleanup, EntIndexToEntRef(iEntity));
}

static void IceBoulder_Throw(SaxtonHaleBase boss)
{
	int iClient = boss.iClient;
	IceBoulder_StopCharge(iClient);

	float flCooldown = boss.GetPropFloat("IceBoulder", "Cooldown");
	g_flIceBoulderCooldownEnd[iClient] = GetGameTime() + flCooldown;
	boss.CallFunction("UpdateHudInfo", 1.0, flCooldown + 1.0);

	IceBoulder_RemoveRock(iClient, false);

	float flRadius = boss.GetPropFloat("IceBoulder", "Radius");
	float flSpeed = boss.GetPropFloat("IceBoulder", "Speed");

	float vecAngles[3], vecDir[3];
	GetClientEyeAngles(iClient, vecAngles);
	vecAngles[0] = 0.0;
	vecAngles[2] = 0.0;
	GetAngleVectors(vecAngles, vecDir, NULL_VECTOR, NULL_VECTOR);

	float vecStart[3], vecPos[3];
	GetClientAbsOrigin(iClient, vecStart);
	vecStart[2] += flRadius;
	vecPos[0] = vecStart[0] + vecDir[0] * (flRadius + 40.0);
	vecPos[1] = vecStart[1] + vecDir[1] * (flRadius + 40.0);
	vecPos[2] = vecStart[2];

	TR_TraceRayFilter(vecStart, vecPos, MASK_PLAYERSOLID, RayType_EndPoint, RageMeteor_TraceGeometry);
	if (TR_DidHit())
		vecPos = vecStart;

	float vecVelocity[3];
	vecVelocity[0] = vecDir[0] * flSpeed;
	vecVelocity[1] = vecDir[1] * flSpeed;
	vecVelocity[2] = 0.0;

	int iRock = CreateEntityByName("tf_projectile_rocket");
	if (iRock <= MaxClients)
		return;

	TeleportEntity(iRock, vecPos, vecAngles, vecVelocity);
	SetEntDataFloat(iRock, FindSendPropInfo("CTFProjectile_Rocket", "m_iDeflected") + 4, 0.0, true);
	SetEntProp(iRock, Prop_Send, "m_nSkin", GetClientTeam(iClient) - 2);
	SetEntPropEnt(iRock, Prop_Send, "m_hOwnerEntity", iClient);
	SetEntProp(iRock, Prop_Send, "m_iTeamNum", GetClientTeam(iClient));
	DispatchSpawn(iRock);

	SetEntPropEnt(iRock, Prop_Send, "m_hOriginalLauncher", GetPlayerWeaponSlot(iClient, TFWeaponSlot_Melee));
	SetEntPropEnt(iRock, Prop_Send, "m_hLauncher", GetPlayerWeaponSlot(iClient, TFWeaponSlot_Melee));

	SetEntProp(iRock, Prop_Send, "m_nModelIndex", g_iIceBoulderModel);
	SetEntPropFloat(iRock, Prop_Send, "m_flModelScale", boss.GetPropFloat("IceBoulder", "ModelScale"));
	SetEntityRenderMode(iRock, RENDER_TRANSCOLOR);
	SetEntityRenderColor(iRock, 200, 255, 255, 230);

	SetEntProp(iRock, Prop_Send, "m_usSolidFlags", GetEntProp(iRock, Prop_Send, "m_usSolidFlags") | ICEBOULDER_NOT_SOLID);
	SetEntityMoveType(iRock, MOVETYPE_NOCLIP);
	TeleportEntity(iRock, NULL_VECTOR, NULL_VECTOR, vecVelocity);

	if (HasEntProp(iRock, Prop_Data, "m_vecAngVelocity"))
	{
		float vecSpin[3] = {360.0, 0.0, 0.0};
		SetEntPropVector(iRock, Prop_Data, "m_vecAngVelocity", vecSpin);
	}

	TF2_SpawnParticle("coin_large_blue", vecPos, .iEntity = iRock);

	g_iIceBoulderRock[iClient] = EntIndexToEntRef(iRock);
	g_flIceBoulderDir[iClient][0] = vecDir[0];
	g_flIceBoulderDir[iClient][1] = vecDir[1];
	g_flIceBoulderDir[iClient][2] = 0.0;
	g_flIceBoulderEnd[iClient] = GetGameTime() + boss.GetPropFloat("IceBoulder", "LifeTime");
	g_iIceBoulderCaught[iClient] = 0;
	for (int iVictim = 0; iVictim < MAXPLAYERS; iVictim++)
		g_bIceBoulderHit[iClient][iVictim] = false;
}

static void IceBoulder_RockThink(SaxtonHaleBase boss)
{
	int iClient = boss.iClient;
	int iRock = EntRefToEntIndex(g_iIceBoulderRock[iClient]);
	if (iRock <= MaxClients)
		return;

	if (!IsPlayerAlive(iClient) || GetGameTime() >= g_flIceBoulderEnd[iClient])
	{
		IceBoulder_RemoveRock(iClient, true);
		return;
	}

	float flRadius = boss.GetPropFloat("IceBoulder", "Radius");
	float flSpeed = boss.GetPropFloat("IceBoulder", "Speed") + boss.GetPropFloat("IceBoulder", "SpeedPerPlayer") * float(g_iIceBoulderCaught[iClient]);

	float vecPos[3], vecDir[3];
	GetEntPropVector(iRock, Prop_Data, "m_vecAbsOrigin", vecPos);
	vecDir[0] = g_flIceBoulderDir[iClient][0];
	vecDir[1] = g_flIceBoulderDir[iClient][1];
	vecDir[2] = 0.0;

	float flHalf = flRadius * 0.5;
	float vecMins[3], vecMaxs[3], vecEnd[3];
	vecMins[0] = -flHalf;
	vecMins[1] = -flHalf;
	vecMins[2] = -flRadius * (1.0 - ICEBOULDER_CLEARANCE);
	vecMaxs[0] = flHalf;
	vecMaxs[1] = flHalf;
	vecMaxs[2] = flHalf;
	vecEnd[0] = vecPos[0] + vecDir[0] * (flHalf + flSpeed * 0.05);
	vecEnd[1] = vecPos[1] + vecDir[1] * (flHalf + flSpeed * 0.05);
	vecEnd[2] = vecPos[2];

	TR_TraceHullFilter(vecPos, vecEnd, vecMins, vecMaxs, MASK_PLAYERSOLID, RageMeteor_TraceGeometry);
	if (TR_DidHit())
	{
		float vecNormal[3];
		TR_GetPlaneNormal(null, vecNormal);
		if (TR_StartSolid() || vecNormal[2] < ICEBOULDER_MAX_SLOPE)
		{
			IceBoulder_RemoveRock(iClient, true);
			return;
		}
	}

	float vecDown[3], flRise;
	vecDown[0] = vecPos[0];
	vecDown[1] = vecPos[1];
	vecDown[2] = vecPos[2] - flRadius - ICEBOULDER_GROUND_REACH;

	TR_TraceRayFilter(vecPos, vecDown, MASK_PLAYERSOLID, RayType_EndPoint, RageMeteor_TraceGeometry);
	if (TR_DidHit())
	{
		float vecGround[3];
		TR_GetEndPosition(vecGround);
		flRise = (vecGround[2] + flRadius - vecPos[2]) * 10.0;
		if (flRise > ICEBOULDER_FALL_SPEED)
			flRise = ICEBOULDER_FALL_SPEED;
		else if (flRise < -ICEBOULDER_FALL_SPEED)
			flRise = -ICEBOULDER_FALL_SPEED;
	}
	else
	{
		flRise = -ICEBOULDER_FALL_SPEED;
	}

	float vecVelocity[3];
	vecVelocity[0] = vecDir[0] * flSpeed;
	vecVelocity[1] = vecDir[1] * flSpeed;
	vecVelocity[2] = flRise;
	TeleportEntity(iRock, NULL_VECTOR, NULL_VECTOR, vecVelocity);

	int iTeam = GetClientTeam(iClient);
	float flDamage = boss.GetPropFloat("IceBoulder", "Damage");
	bool bFreeze = boss.HasClass("RageMeteor");

	for (int iVictim = 1; iVictim <= MaxClients; iVictim++)
	{
		if (!IsClientInGame(iVictim) || !IsPlayerAlive(iVictim) || GetClientTeam(iVictim) <= 1 || GetClientTeam(iVictim) == iTeam)
			continue;

		if (RageMeteor_GetBoxDistance(iVictim, vecPos) > flRadius || !RageMeteor_IsInSight(vecPos, iVictim))
			continue;

		if (!g_bIceBoulderHit[iClient][iVictim])
		{
			g_bIceBoulderHit[iClient][iVictim] = true;
			g_iIceBoulderCaught[iClient]++;

			g_bIceBoulderDamaging = true;
			SDKHooks_TakeDamage(iVictim, iClient, iClient, flDamage, DMG_CLUB|DMG_PREVENT_PHYSICS_FORCE, -1, NULL_VECTOR, vecPos, false);
			g_bIceBoulderDamaging = false;

			if (!IsClientInGame(iVictim) || !IsPlayerAlive(iVictim))
				continue;

			if (bFreeze)
				RageMeteor_FreezeVictim(boss, iVictim);
		}

		float vecVictim[3];
		GetEntPropVector(iVictim, Prop_Data, "m_vecVelocity", vecVictim);
		vecVictim[0] = vecVelocity[0];
		vecVictim[1] = vecVelocity[1];
		TF2_AddCondition(iVictim, TFCond_LostFooting, 0.5);
		TeleportEntity(iVictim, NULL_VECTOR, NULL_VECTOR, vecVictim);
	}
}

static void IceBoulder_RemoveRock(int iClient, bool bEffects)
{
	int iRock = EntRefToEntIndex(g_iIceBoulderRock[iClient]);
	g_iIceBoulderRock[iClient] = INVALID_ENT_REFERENCE;
	if (iRock <= MaxClients)
		return;

	if (bEffects)
	{
		float vecPos[3];
		GetEntPropVector(iRock, Prop_Data, "m_vecAbsOrigin", vecPos);

		char sParticle[64];
		strcopy(sParticle, sizeof(sParticle), ICEBOULDER_BREAK_PARTICLE_01);
		CreateTimer(3.0, Timer_EntityCleanup, TF2_SpawnParticle(sParticle, vecPos));
		strcopy(sParticle, sizeof(sParticle), ICEBOULDER_BREAK_PARTICLE_02);
		CreateTimer(3.0, Timer_EntityCleanup, TF2_SpawnParticle(sParticle, vecPos));
		EmitAmbientSound(ICEBOULDER_BREAK_SOUND, vecPos, _, SNDLEVEL_SCREAMING);
	}

	RemoveEntity(iRock);
}
