#define PARTICLE_TELEPORT	"merasmus_tp"

enum TeleportViewMode
{
	TeleportViewMode_None,
	TeleportViewMode_Teleporting,
	TeleportViewMode_Teleported
}

static TeleportViewMode g_nTeleportViewMode[MAXPLAYERS];
static float g_vecTeleportViewPos[MAXPLAYERS][3];
static float g_flTeleportViewStartCharge[MAXPLAYERS];
static float g_flTeleportViewCooldownWait[MAXPLAYERS];

public void TeleportView_Create(SaxtonHaleBase boss)
{
	//Default values, these can be changed if needed
	boss.SetPropFloat("TeleportView", "Charge", 2.0);
	boss.SetPropFloat("TeleportView", "Cooldown", 30.0);
	
	g_flTeleportViewStartCharge[boss.iClient] = 0.0;
	g_flTeleportViewCooldownWait[boss.iClient] = GetGameTime() + boss.GetPropFloat("TeleportView", "Cooldown");
	boss.CallFunction("UpdateHudInfo", 1.0, boss.GetPropFloat("TeleportView", "Cooldown"));	//Update every second for cooldown duration
}

public void TeleportView_OnThink(SaxtonHaleBase boss)
{
	if (GameRules_GetRoundState() == RoundState_Preround)
		return;
	
	float flCharge = GetGameTime() - g_flTeleportViewStartCharge[boss.iClient];
	
	if (g_nTeleportViewMode[boss.iClient] == TeleportViewMode_Teleporting)
	{
		float vecOrigin[3];
		GetClientAbsOrigin(boss.iClient, vecOrigin);
		
		if (flCharge > boss.GetPropFloat("TeleportView", "Charge") + 1.5)
		{
			//Do the actual teleport
			
			g_nTeleportViewMode[boss.iClient] = TeleportViewMode_Teleported;
			boss.CallFunction("UpdateHudInfo", 0.0, 0.0);	//Update once
			
			//Create particle
			CreateTimer(3.0, Timer_EntityCleanup, TF2_SpawnParticle(PARTICLE_TELEPORT, vecOrigin));
			CreateTimer(3.0, Timer_EntityCleanup, TF2_SpawnParticle(PARTICLE_TELEPORT, g_vecTeleportViewPos[boss.iClient]));
			
			//Teleport
			TeleportEntity(boss.iClient, g_vecTeleportViewPos[boss.iClient], NULL_VECTOR, NULL_VECTOR);
			
			SDKCall_PlaySpecificSequence(boss.iClient, "teleport_in");
			return;
		}
		
		//Progress in teleporting
		TeleportView_ShowPos(boss.iClient, g_vecTeleportViewPos[boss.iClient]);
		return;
	}
	else if (g_nTeleportViewMode[boss.iClient] == TeleportViewMode_Teleported)
	{
		if (flCharge > boss.GetPropFloat("TeleportView", "Charge") + 3.0)
		{
			//Fully done
			
			g_nTeleportViewMode[boss.iClient] = TeleportViewMode_None;
			g_flTeleportViewCooldownWait[boss.iClient] = GetGameTime() + boss.GetPropFloat("TeleportView", "Cooldown");
			boss.CallFunction("UpdateHudInfo", 1.0, boss.GetPropFloat("TeleportView", "Cooldown"));	//Update every second for cooldown duration
			
			g_flTeleportViewStartCharge[boss.iClient] = 0.0;
			
			SetEntityMoveType(boss.iClient, MOVETYPE_WALK);
		}
		
		//Progress into finishing
		return;
	}
	else if (g_flTeleportViewCooldownWait[boss.iClient] != 0.0 && g_flTeleportViewCooldownWait[boss.iClient] > GetGameTime())
	{
		//Teleport in cooldown
		return;
	}
	else if (g_flTeleportViewStartCharge[boss.iClient] == 0.0)
	{
		//Can use teleport, but not charging
		return;
	}
	
	float vecEyePos[3], vecAng[3];
	GetClientEyePosition(boss.iClient, vecEyePos);
	GetClientEyeAngles(boss.iClient, vecAng);
	
	TR_TraceRayFilter(vecEyePos, vecAng, MASK_PLAYERSOLID, RayType_Infinite, TraceRay_DontHitEntity, boss.iClient);
	if (!TR_DidHit())
		return;
	
	float vecEndPos[3];
	TR_GetEndPosition(vecEndPos);
	
	float vecOrigin[3], vecMins[3], vecMaxs[3];
	GetClientAbsOrigin(boss.iClient, vecOrigin);
	GetClientMins(boss.iClient, vecMins);
	GetClientMaxs(boss.iClient, vecMaxs);
	
	if (vecEndPos[2] < vecOrigin[2])	//If trace heading downward, prevent that because mins/maxs hitbox
		vecEndPos[2] = vecOrigin[2];
	
	//Find spot from player's eye
	TR_TraceHullFilter(vecOrigin, vecEndPos, vecMins, vecMaxs, MASK_PLAYERSOLID, TraceRay_DontHitEntity, boss.iClient);
	TR_GetEndPosition(vecEndPos);
	
	//Find the floor
	TR_TraceRayFilter(vecEndPos, view_as<float>({ 90.0, 0.0, 0.0 }), MASK_PLAYERSOLID, RayType_Infinite, TraceRay_DontHitEntity, boss.iClient);
	if (!TR_DidHit())
		return;
	
	float vecFloorPos[3];
	TR_GetEndPosition(vecFloorPos);
	TR_TraceHullFilter(vecEndPos, vecFloorPos, vecMins, vecMaxs, MASK_PLAYERSOLID, TraceRay_DontHitEntity, boss.iClient);
	TR_GetEndPosition(vecEndPos);
	
	if (flCharge >= boss.GetPropFloat("TeleportView", "Charge"))
	{
		//Start teleport anim
		
		g_nTeleportViewMode[boss.iClient] = TeleportViewMode_Teleporting;
		
		g_vecTeleportViewPos[boss.iClient] = vecEndPos;
		
		SetEntityMoveType(boss.iClient, MOVETYPE_NONE);
		SDKCall_PlaySpecificSequence(boss.iClient, "teleport_out");
		
		TF2_AddCondition(boss.iClient, TFCond_FreezeInput, 3.0);
		TF2_AddCondition(boss.iClient, TFCond_UberchargedCanteen, 3.0);
	}
	
	//Show where to teleport
	TeleportView_ShowPos(boss.iClient, vecEndPos);
	boss.CallFunction("UpdateHudInfo", 0.0, 0.0);	//Update once
}

public void TeleportView_GetHudInfo(SaxtonHaleBase boss, char[] sMessage, int iLength, int iColor[4])
{
	if (g_nTeleportViewMode[boss.iClient] == TeleportViewMode_Teleporting)
	{
		//Progress in teleporting
		StrCat(sMessage, iLength, "\nTeleport-view: TELEPORTING.");
	}
	else if (g_nTeleportViewMode[boss.iClient] == TeleportViewMode_Teleported)
	{
		//Progress into finishing
		StrCat(sMessage, iLength, "\nTeleport-view: TELEPORTED.");
	}
	else if (g_flTeleportViewCooldownWait[boss.iClient] != 0.0 && g_flTeleportViewCooldownWait[boss.iClient] > GetGameTime())
	{
		//Teleport in cooldown
		int iSec = RoundToCeil(g_flTeleportViewCooldownWait[boss.iClient] - GetGameTime());
		Format(sMessage, iLength, "%s\nTeleport-view cooldown %i second%s remaining!", sMessage, iSec, (iSec > 1) ? "s" : "");
	}
	else if (g_flTeleportViewStartCharge[boss.iClient] == 0.0)
	{
		//Can use teleport, but not charging
		StrCat(sMessage, iLength, "\nHold reload to use your teleport-view!");
	}
	else
	{
		//Charging to teleport
		float flPercentage = (GetGameTime() - g_flTeleportViewStartCharge[boss.iClient]) / boss.GetPropFloat("TeleportView", "Charge");
		Format(sMessage, iLength, "%s\nTeleport-view: %0.2f%%.", sMessage, flPercentage * 100.0);
	}
}

public void TeleportView_OnButton(SaxtonHaleBase boss, int &buttons)
{
	if (GameRules_GetRoundState() == RoundState_Preround)
		return;
	
	if (buttons & IN_RELOAD && g_flTeleportViewStartCharge[boss.iClient] == 0.0 && g_flTeleportViewCooldownWait[boss.iClient] != 0.0 && g_flTeleportViewCooldownWait[boss.iClient] < GetGameTime())
		g_flTeleportViewStartCharge[boss.iClient] = GetGameTime();
}

public void TeleportView_OnButtonRelease(SaxtonHaleBase boss, int button)
{
	if (button == IN_RELOAD && g_nTeleportViewMode[boss.iClient] == TeleportViewMode_None)
	{
		g_flTeleportViewStartCharge[boss.iClient] = 0.0;
		boss.CallFunction("UpdateHudInfo", 0.0, 0.0);	//Update once
	}
}

public void TeleportView_Precache(SaxtonHaleBase boss)
{
	PrecacheParticleSystem(PARTICLE_TELEPORT);
}

void TeleportView_ShowPos(int iClient, const float vecPos[3])
{
	//Show where boss will be teleported
	float vecStart[3], vecEnd[3], vecMins[3], vecMaxs[3];
	GetClientAbsOrigin(iClient, vecStart);
	GetClientMins(iClient, vecMins);
	GetClientMaxs(iClient, vecMaxs);
	vecEnd = vecPos;
	
	vecStart[2] += 8.0;
	vecEnd[2] += 8.0;
	float flDiameter = vecMaxs[0] - vecMins[0];
	
	//Line effect
	TE_SetupBeamPoints(vecStart, vecEnd, g_iSpritesLaserbeam, g_iSpritesGlow, 0, 10, 0.1, 3.0, 3.0, 10, 0.0, {0, 255, 0, 255}, 10);
	TE_SendToClient(iClient);
	
	//Ring effect
	TE_SetupBeamRingPoint(vecEnd, flDiameter, flDiameter + 1.0, g_iSpritesLaserbeam, g_iSpritesGlow, 0, 10, 0.1, 3.0, 0.0, {0, 255, 0, 255}, 10, 0);
	TE_SendToClient(iClient);
}
