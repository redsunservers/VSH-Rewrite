#define PARTICLE_TELEPORT	"merasmus_tp"

enum TeleportViewMode
{
	TeleportViewMode_None,
	TeleportViewMode_Teleporting,
	TeleportViewMode_Teleported
}

static TeleportViewMode g_nTeleportViewMode[TF_MAXPLAYERS];
static float g_vecTeleportViewPos[TF_MAXPLAYERS][3];
static float g_flTeleportViewCharge[TF_MAXPLAYERS];
static float g_flTeleportViewStartCharge[TF_MAXPLAYERS];
static float g_flTeleportViewCooldown[TF_MAXPLAYERS];
static float g_flTeleportViewCooldownWait[TF_MAXPLAYERS];

methodmap CTeleportView < SaxtonHaleBase
{
	property float flCharge
	{
		public get()
		{
			return g_flTeleportViewCharge[this.iClient];
		}
		public set(float val)
		{
			g_flTeleportViewCharge[this.iClient] = val;
		}
	}
	
	property float flCooldown
	{
		public get()
		{
			return g_flTeleportViewCooldown[this.iClient];
		}
		public set(float val)
		{
			g_flTeleportViewCooldown[this.iClient] = val;
		}
	}
	
	public CTeleportView(CTeleportView ability)
	{
		//Default values, these can be changed if needed
		ability.flCharge = 2.0;
		ability.flCooldown = 30.0;
		
		g_flTeleportViewStartCharge[ability.iClient] = 0.0;
		g_flTeleportViewCooldownWait[ability.iClient] = GetGameTime() + ability.flCooldown;
	}
	
	public void OnThink()
	{
		if (GameRules_GetRoundState() == RoundState_Preround)
			return;
		
		float flCharge = GetGameTime() - g_flTeleportViewStartCharge[this.iClient];
		
		if (g_nTeleportViewMode[this.iClient] == TeleportViewMode_Teleporting)
		{
			float vecOrigin[3];
			GetClientAbsOrigin(this.iClient, vecOrigin);
			
			if (flCharge > this.flCharge + 1.5)
			{
				//Do the actual teleport
				
				g_nTeleportViewMode[this.iClient] = TeleportViewMode_Teleported;
				
				//Create particle
				CreateTimer(3.0, Timer_EntityCleanup, TF2_SpawnParticle(PARTICLE_TELEPORT, vecOrigin));
				CreateTimer(3.0, Timer_EntityCleanup, TF2_SpawnParticle(PARTICLE_TELEPORT, g_vecTeleportViewPos[this.iClient]));
				
				//Teleport
				TeleportEntity(this.iClient, g_vecTeleportViewPos[this.iClient], NULL_VECTOR, NULL_VECTOR);
				
				SDKCall_PlaySpecificSequence(this.iClient, "teleport_in");
				
				Hud_AddText(this.iClient, "Teleport-view: TELEPORTED.");
				return;
			}
			
			//Progress in teleporting
			TeleportView_ShowPos(this.iClient, g_vecTeleportViewPos[this.iClient]);
			Hud_AddText(this.iClient, "Teleport-view: TELEPORTING.");
			return;
		}
		else if (g_nTeleportViewMode[this.iClient] == TeleportViewMode_Teleported)
		{
			if (flCharge > this.flCharge + 3.0)
			{
				//Fully done
				
				g_nTeleportViewMode[this.iClient] = TeleportViewMode_None;
				g_flTeleportViewCooldownWait[this.iClient] = GetGameTime() + this.flCooldown;
				g_flTeleportViewStartCharge[this.iClient] = 0.0;
				
				SetEntityMoveType(this.iClient, MOVETYPE_WALK);
			}
			
			//Progress into finishing
			Hud_AddText(this.iClient, "Teleport-view: TELEPORTED.");
			return;
		}
		else if (g_flTeleportViewCooldownWait[this.iClient] != 0.0 && g_flTeleportViewCooldownWait[this.iClient] > GetGameTime())
		{
			//Teleport in cooldown
			
			int iSec = RoundToNearest(g_flTeleportViewCooldownWait[this.iClient] - GetGameTime());
			
			char sMessage[255];
			Format(sMessage, sizeof(sMessage), "Teleport-view cooldown %i second%s remaining!", iSec, (iSec > 1) ? "s" : "");
			Hud_AddText(this.iClient, sMessage);
			return;
		}
		else if (g_flTeleportViewStartCharge[this.iClient] == 0.0)
		{
			//Can use teleport, but not charging
			
			Hud_AddText(this.iClient, "Hold reload to use your teleport-view!");
			return;
		}
		
		float vecEyePos[3], vecAng[3];
		GetClientEyePosition(this.iClient, vecEyePos);
		GetClientEyeAngles(this.iClient, vecAng);
		
		TR_TraceRayFilter(vecEyePos, vecAng, MASK_PLAYERSOLID, RayType_Infinite, TraceRay_DontHitEntity, this.iClient);
		if (!TR_DidHit())
			return;
		
		float vecEndPos[3];
		TR_GetEndPosition(vecEndPos);
		
		float vecOrigin[3], vecMins[3], vecMaxs[3];
		GetClientAbsOrigin(this.iClient, vecOrigin);
		GetClientMins(this.iClient, vecMins);
		GetClientMaxs(this.iClient, vecMaxs);
		
		if (vecEndPos[2] < vecOrigin[2])	//If trace heading downward, prevent that because mins/maxs hitbox
			vecEndPos[2] = vecOrigin[2];
		
		//Find spot from player's eye
		TR_TraceHullFilter(vecOrigin, vecEndPos, vecMins, vecMaxs, MASK_PLAYERSOLID, TraceRay_DontHitEntity, this.iClient);
		TR_GetEndPosition(vecEndPos);
		
		//Find the floor
		TR_TraceRayFilter(vecEndPos, view_as<float>({ 90.0, 0.0, 0.0 }), MASK_PLAYERSOLID, RayType_Infinite, TraceRay_DontHitEntity, this.iClient);
		if (!TR_DidHit())
			return;
		
		float vecFloorPos[3];
		TR_GetEndPosition(vecFloorPos);
		TR_TraceHullFilter(vecEndPos, vecFloorPos, vecMins, vecMaxs, MASK_PLAYERSOLID, TraceRay_DontHitEntity, this.iClient);
		TR_GetEndPosition(vecEndPos);
		
		if (flCharge < this.flCharge)
		{
			//Charging to teleport
			
			float flPercentage = (GetGameTime() - g_flTeleportViewStartCharge[this.iClient]) / this.flCharge;
			
			char sMessage[255];
			Format(sMessage, sizeof(sMessage), "Teleport-view: %0.2f%%.", flPercentage * 100.0);
			Hud_AddText(this.iClient, sMessage);
		}
		else
		{
			//Start teleport anim
			
			g_nTeleportViewMode[this.iClient] = TeleportViewMode_Teleporting;
			g_vecTeleportViewPos[this.iClient] = vecEndPos;
			
			SetEntityMoveType(this.iClient, MOVETYPE_NONE);
			SDKCall_PlaySpecificSequence(this.iClient, "teleport_out");
			
			TF2_AddCondition(this.iClient, TFCond_FreezeInput, 3.0);
			TF2_AddCondition(this.iClient, TFCond_UberchargedCanteen, 3.0);
			
			Hud_AddText(this.iClient, "Teleport-view: TELEPORTING.");
		}
		
		//Show where to teleport
		TeleportView_ShowPos(this.iClient, vecEndPos);
	}
	
	public void OnButtonHold(int button)
	{
		if (GameRules_GetRoundState() == RoundState_Preround)
			return;
		
		if (button == IN_RELOAD && g_flTeleportViewStartCharge[this.iClient] == 0.0 && g_flTeleportViewCooldownWait[this.iClient] != 0.0 && g_flTeleportViewCooldownWait[this.iClient] < GetGameTime())
			g_flTeleportViewStartCharge[this.iClient] = GetGameTime();
	}
	
	public void OnButtonRelease(int button)
	{
		if (button == IN_RELOAD && g_nTeleportViewMode[this.iClient] == TeleportViewMode_None)
			g_flTeleportViewStartCharge[this.iClient] = 0.0;
	}
	
	public void Precache()
	{
		PrecacheParticleSystem(PARTICLE_TELEPORT);
	}
};

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