#define DASHSTRIKE_SOUND	"weapons/draw_sword.wav"
#define DASHSTRIKE_PARTICLE	"wrenchmotron_teleport_flash"

enum DashStrikeMode
{
	DashStrikeMode_None,
	DashStrikeMode_Invisible,
	DashStrikeMode_Dash,
	DashStrikeMode_Rage
}

static DashStrikeMode g_nDashStrikeMode[TF_MAXPLAYERS];
static float g_flDashStrikeCooldownWait[TF_MAXPLAYERS];
static float g_flDashStrikeProgress[TF_MAXPLAYERS];
static bool g_bDashStrikeHitEntity[TF_MAXPLAYERS][2048];
static int g_iDashStrikeDamage[TF_MAXPLAYERS];

public DashStrike_Create(SaxtonHaleBase boss)
{
	boss.SetPropFloat("DashStrike", "Cooldown", 0.5);
	boss.SetPropFloat("DashStrike", "DashDistance", 1000.0);
	boss.SetPropFloat("DashStrike", "RageDistance", 10000.0);
	boss.SetPropInt("DashStrike", "DashDamage", 100);
	boss.SetPropInt("DashStrike", "RageDamage", 500);
	boss.SetPropFloat("DashStrike", "Speed", 10000.0);
	
	g_flDashStrikeCooldownWait[boss.iClient] = 0.0;
	g_flDashStrikeProgress[boss.iClient] = 0.0;
	g_nDashStrikeMode[boss.iClient] = DashStrikeMode_None;
}

public void DashStrike_StartDash(SaxtonHaleBase boss)
{
	SetEntityMoveType(boss.iClient, MOVETYPE_NONE);
	TF2_AddCondition(boss.iClient, TFCond_FreezeInput, TFCondDuration_Infinite);
	
	g_flDashStrikeProgress[boss.iClient] = 0.0;
	for (int i = 0; i < sizeof(g_bDashStrikeHitEntity[]); i++)
		g_bDashStrikeHitEntity[boss.iClient][i] = false;
}

public void DashStrike_EndDash(SaxtonHaleBase boss)
{
	SetEntityMoveType(boss.iClient, MOVETYPE_WALK);
	TF2_RemoveCondition(boss.iClient, TFCond_FreezeInput);
	
	g_nDashStrikeMode[boss.iClient] = DashStrikeMode_None;
}

public void DashStrike_OnRage(SaxtonHaleBase boss)
{
	g_nDashStrikeMode[boss.iClient] = DashStrikeMode_Invisible;
	SDKHook(boss.iClient, SDKHook_SetTransmit, DashStrike_SetTransmit);
	SDKHook(boss.iClient, SDKHook_ShouldCollide, DashStrike_ShouldCollide);
	
	int iColor[4] = {255, 255, 255, 255};
	boss.CallFunction("GetRenderColor", iColor);
	SetEntityRenderColor(boss.iClient, iColor[0], iColor[1], iColor[2], 32);
	SetEntityRenderMode(boss.iClient, RENDER_TRANSCOLOR);
	
	float vecOrigin[3], vecAngles[3];
	GetClientAbsOrigin(boss.iClient, vecOrigin);
	GetClientEyeAngles(boss.iClient, vecAngles);
	CreateTimer(3.0, Timer_EntityCleanup, TF2_SpawnParticle(DASHSTRIKE_PARTICLE, vecOrigin, vecAngles));
}

public void DashStrike_OnThink(SaxtonHaleBase boss)
{
	if (g_flDashStrikeCooldownWait[boss.iClient] <= GetGameTime())
		g_flDashStrikeCooldownWait[boss.iClient] = 0.0;
	
	if (g_nDashStrikeMode[boss.iClient] == DashStrikeMode_Invisible)
	{
		//Calculate where dest would be
		float flProgress;
		
		float vecOrigin[3], vecAngle[3], vecMins[3], vecMaxs[3];
		GetClientAbsOrigin(boss.iClient, vecOrigin);
		GetClientEyeAngles(boss.iClient, vecAngle);
		GetClientMins(boss.iClient, vecMins);
		GetClientMaxs(boss.iClient, vecMaxs);
		
		do
		{
			float flDistance = boss.GetPropFloat("DashStrike", "Speed") * GetGameFrameTime();
			if (flDistance > boss.GetPropFloat("DashStrike", "RageDistance") - flProgress)
				flDistance = boss.GetPropFloat("DashStrike", "RageDistance") - flProgress;
			
			flProgress += DashStrike_DoTrace(boss.iClient, vecOrigin, vecAngle, flDistance, vecOrigin);
		}
		while (flProgress < boss.GetPropFloat("DashStrike", "RageDistance") && !TR_DidHit());
		
		//Line effect
		float vecStart[3];
		GetClientAbsOrigin(boss.iClient, vecStart);
		vecStart[2] += 8.0;
		vecOrigin[2] += 8.0;
		
		TE_SetupBeamPoints(vecStart, vecOrigin, g_iSpritesLaserbeam, g_iSpritesGlow, 0, 10, 0.1, 3.0, 3.0, 10, 0.0, {0, 255, 0, 255}, 10);
		TE_SendToClient(boss.iClient);
		
		//Ring effect
		float flDiameter = vecMaxs[0] - vecMins[0];
		TE_SetupBeamRingPoint(vecOrigin, flDiameter, flDiameter + 1.0, g_iSpritesLaserbeam, g_iSpritesGlow, 0, 10, 0.1, 3.0, 0.0, {0, 255, 0, 255}, 10, 0);
		TE_SendToClient(boss.iClient);
	}
	else if (g_nDashStrikeMode[boss.iClient] == DashStrikeMode_Dash || g_nDashStrikeMode[boss.iClient] == DashStrikeMode_Rage)
	{
		//How far do we go
		float flDistance = boss.GetPropFloat("DashStrike", "Speed") * GetGameFrameTime();
		float flMaxDistance = g_nDashStrikeMode[boss.iClient] == DashStrikeMode_Dash ? boss.GetPropFloat("DashStrike", "DashDistance") : boss.GetPropFloat("DashStrike", "RageDistance");
		if (flDistance > flMaxDistance - g_flDashStrikeProgress[boss.iClient])
			flDistance = flMaxDistance - g_flDashStrikeProgress[boss.iClient];
		
		float vecOrigin[3], vecAngle[3], vecEnd[3], vecVelocity[3];
		GetClientAbsOrigin(boss.iClient, vecOrigin);
		GetClientEyeAngles(boss.iClient, vecAngle);
		
		switch (g_nDashStrikeMode[boss.iClient])
		{
			case DashStrikeMode_Dash: DashStrike_DoTrace(boss.iClient, vecOrigin, vecAngle, flDistance, vecEnd, vecVelocity, boss.GetPropInt("DashStrike", "DashDamage"));
			case DashStrikeMode_Rage: DashStrike_DoTrace(boss.iClient, vecOrigin, vecAngle, flDistance, vecEnd, vecVelocity, boss.GetPropInt("DashStrike", "RageDamage"));
		}
		
		ScaleVector(vecVelocity, boss.GetPropFloat("DashStrike", "Speed"));
		TeleportEntity(boss.iClient, vecEnd, NULL_VECTOR, vecVelocity);
		
		g_flDashStrikeProgress[boss.iClient] += flDistance;
		if (g_flDashStrikeProgress[boss.iClient] >= flMaxDistance || TR_DidHit())
			DashStrike_EndDash(boss);
	}
}

public void DashStrike_GetHudText(SaxtonHaleBase boss, char[] sMessage, int iLength)
{
	if (g_nDashStrikeMode[boss.iClient] == DashStrikeMode_Invisible)
	{
		Format(sMessage, iLength, "%s\nRight click to use Dash-Strike!", sMessage);
	}
	else if (g_flDashStrikeCooldownWait[boss.iClient] != 0.0)
	{
		int iSec = RoundToNearest(g_flDashStrikeCooldownWait[boss.iClient]-GetGameTime());
		Format(sMessage, iLength, "%s\nDash-Strike cooldown %i second%s remaining!", sMessage, iSec, (iSec > 1) ? "s" : "");
	}
	else
	{
		Format(sMessage, iLength, "%s\nRight click to use Dash-Strike!", sMessage);
	}
}

public void DashStrike_OnButtonPress(SaxtonHaleBase boss, int button)
{
	//Use dash-strike if not in cooldown and not during rage
	if (button == IN_ATTACK2)
	{
		if (g_nDashStrikeMode[boss.iClient] == DashStrikeMode_Invisible)
		{
			SDKUnhook(boss.iClient, SDKHook_SetTransmit, DashStrike_SetTransmit);
			SDKUnhook(boss.iClient, SDKHook_ShouldCollide, DashStrike_ShouldCollide);
			
			int iColor[4] = {255, 255, 255, 255};
			boss.CallFunction("GetRenderColor", iColor);
			SetEntityRenderColor(boss.iClient, iColor[0], iColor[1], iColor[2], iColor[3]);
			SetEntityRenderMode(boss.iClient, RENDER_NORMAL);
			
			float vecOrigin[3], vecAngles[3];
			GetClientAbsOrigin(boss.iClient, vecOrigin);
			GetClientEyeAngles(boss.iClient, vecAngles);
			CreateTimer(3.0, Timer_EntityCleanup, TF2_SpawnParticle(DASHSTRIKE_PARTICLE, vecOrigin, vecAngles));
			
			BroadcastSoundToTeam(TFTeam_Spectator, DASHSTRIKE_SOUND);
			g_nDashStrikeMode[boss.iClient] = DashStrikeMode_Rage;
			DashStrike_StartDash(boss);
		}
		else if (g_nDashStrikeMode[boss.iClient] == DashStrikeMode_None && g_flDashStrikeCooldownWait[boss.iClient] == 0.0)
		{
			EmitSoundToAll(DASHSTRIKE_SOUND, boss.iClient, SNDCHAN_VOICE, SNDLEVEL_SCREAMING);
			g_nDashStrikeMode[boss.iClient] = DashStrikeMode_Dash;
			DashStrike_StartDash(boss);
			
			g_flDashStrikeCooldownWait[boss.iClient] = GetGameTime() + boss.GetPropFloat("DashStrike", "Cooldown");
		}
	}
}

public Action DashStrike_OnTakeDamage(SaxtonHaleBase boss, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if (g_nDashStrikeMode[boss.iClient] == DashStrikeMode_Invisible)
		return Plugin_Stop;
	
	return Plugin_Continue;
}

public void DashStrike_OnPlayerKilled(SaxtonHaleBase boss, Event event)
{
	//Allow use dash now on kill
	g_flDashStrikeCooldownWait[boss.iClient] = 0.0;
}

public Action DashStrike_OnSoundPlayed(SaxtonHaleBase boss, int clients[MAXPLAYERS], int &numClients, char sample[PLATFORM_MAX_PATH], int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
	if (g_nDashStrikeMode[boss.iClient] != DashStrikeMode_None)
		return Plugin_Handled;	//Silent any sounds during dash
	
	return Plugin_Continue;
}

public void DashStrike_OnEntityCreated(SaxtonHaleBase boss, int iEntity, const char[] sClassname)
{
	if (strcmp(sClassname, "tf_ragdoll") == 0)
		RequestFrame(DashStrike_RagdollSpawn, EntIndexToEntRef(iEntity));
}

public void DashStrike_Destroy(SaxtonHaleBase boss)
{
	SDKUnhook(boss.iClient, SDKHook_SetTransmit, DashStrike_SetTransmit);
	SDKUnhook(boss.iClient, SDKHook_ShouldCollide, DashStrike_ShouldCollide);
	
	if (g_nDashStrikeMode[boss.iClient] != DashStrikeMode_None)
		DashStrike_EndDash(boss);
}

public void DashStrike_Precache(SaxtonHaleBase boss)
{
	PrecacheParticleSystem(DASHSTRIKE_PARTICLE);
}

float DashStrike_DoTrace(int iClient, const float vecStart[3], const float vecAngle[3], float flDistance, float vecEnd[3], float vecVelocity[3] = {0.0, 0.0, 0.0}, int iDamage = 0)
{
	g_iDashStrikeDamage[iClient] = iDamage;
	
	float vecMins[3], vecMaxs[3];
	GetClientMins(iClient, vecMins);
	GetClientMaxs(iClient, vecMaxs);
	
	GetAngleVectors(vecAngle, vecVelocity, NULL_VECTOR, NULL_VECTOR);
	ScaleVector(vecVelocity, flDistance);
	AddVectors(vecVelocity, vecStart, vecEnd);
	
	//Start hull to see how far we can go
	TR_TraceHullFilter(vecStart, vecEnd, vecMins, vecMaxs, MASK_PLAYERSOLID, TraceRay_DashStrike, iClient);
	TR_GetEndPosition(vecEnd);
	
	MakeVectorFromPoints(vecStart, vecEnd, vecVelocity);
	float flDistanceMade = GetVectorLength(vecVelocity);
	if (flDistanceMade < flDistance)
	{
		//There still distance left to use, try without taking into account with vertical
		float vecBuffer[3];
		vecBuffer = vecAngle;
		vecBuffer[0] = 0.0;
		GetAngleVectors(vecBuffer, vecVelocity, NULL_VECTOR, NULL_VECTOR);
		ScaleVector(vecVelocity, flDistance - flDistanceMade);
		
		vecBuffer = vecEnd;
		AddVectors(vecBuffer, vecVelocity, vecEnd);
		
		TR_TraceHullFilter(vecBuffer, vecEnd, vecMins, vecMaxs, MASK_PLAYERSOLID, TraceRay_DashStrike, iClient);
		TR_GetEndPosition(vecEnd);
		
		MakeVectorFromPoints(vecBuffer, vecEnd, vecVelocity);
		flDistanceMade += GetVectorLength(vecVelocity);
	}
	
	NormalizeVector(vecVelocity, vecVelocity);
	g_iDashStrikeDamage[iClient] = 0;
	return flDistanceMade;
}

bool TraceRay_DashStrike(int iEntity, int iMask, int iClient)
{
	if (g_bDashStrikeHitEntity[iClient][iEntity])
		return false;	//Already hit this entity, don't damage again
	
	g_bDashStrikeHitEntity[iClient][iEntity] = true;
	
	if (0 < iEntity <= MaxClients)
	{
		if (g_iDashStrikeDamage[iClient] > 0 && GetClientTeam(iEntity) != GetClientTeam(iClient))
			SDKHooks_TakeDamage(iEntity, iClient, iClient, float(g_iDashStrikeDamage[iClient]), DMG_CLUB|DMG_PREVENT_PHYSICS_FORCE, TF2_GetItemInSlot(iClient, WeaponSlot_Melee));
		
		return false;
	}
	else if (iEntity > MaxClients)
	{
		char sClassname[256];
		GetEntityClassname(iEntity, sClassname, sizeof(sClassname));
		if (StrContains(sClassname, "obj_") == 0)
		{
			if (g_iDashStrikeDamage[iClient] > 0 && GetEntProp(iEntity, Prop_Send, "m_iTeamNum") != GetClientTeam(iClient))
				SDKHooks_TakeDamage(iEntity, iClient, iClient, float(g_iDashStrikeDamage[iClient]), DMG_CLUB, TF2_GetItemInSlot(iClient, WeaponSlot_Melee));
			
			return false;
		}
	}
	
	//Dont want to collide dropped weapon and ammo pack
	return GetEntProp(iEntity, Prop_Send, "m_CollisionGroup") != COLLISION_GROUP_DEBRIS;
}

public void DashStrike_RagdollSpawn(int iRef)
{
	int iEntity = EntRefToEntIndex(iRef);
	if (iEntity <= 0 || !IsValidEntity(iEntity)) return;
	
	SetEntProp(iEntity, Prop_Send, "m_iDamageCustom", TF_CUSTOM_DECAPITATION);
}

public Action DashStrike_SetTransmit(int iEntity, int iClient)
{
	if (iEntity == iClient || !IsPlayerAlive(iClient) || TF2_GetClientTeam(iClient) == TF2_GetClientTeam(iEntity))
		return Plugin_Continue;
	
	return Plugin_Stop;
}

public bool DashStrike_ShouldCollide(int iClient, int iCollisionGroup, int iMask, bool bOriginal)
{
	if (iCollisionGroup == COLLISION_GROUP_PLAYER || iCollisionGroup == TFCOLLISION_GROUP_OBJECT_SOLIDTOPLAYERMOVEMENT)
		return false;
	
	return bOriginal;
}