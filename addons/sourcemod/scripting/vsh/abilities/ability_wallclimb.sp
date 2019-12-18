static float g_flWallClimbMaxHeight[TF_MAXPLAYERS+1];
static float g_flWallClimbMaxDistance[TF_MAXPLAYERS+1];

methodmap CWallClimb < SaxtonHaleBase
{
	property float flMaxHeight
	{
		public get()
		{
			return g_flWallClimbMaxHeight[this.iClient];
		}
		public set(float val)
		{
			g_flWallClimbMaxHeight[this.iClient] = val;
		}
	}
	property float flMaxDistance
	{
		public get()
		{
			return g_flWallClimbMaxDistance[this.iClient];
		}
		public set(float val)
		{
			g_flWallClimbMaxDistance[this.iClient] = val;
		}
	}
	
	public CWallClimb(CWallClimb ability)
	{
		//Default values, these can be changed if needed
		ability.flMaxHeight = 750.0;
		ability.flMaxDistance = 100.0;
	}
	
	public Action OnAttackCritical(int iWeapon, bool &bResult)
	{
		int iClient = this.iClient;
		
		char sClassname[64];
		float vecClientEyePos[3], vecClientEyeAng[3];
		GetClientEyePosition(iClient, vecClientEyePos);
		GetClientEyeAngles(iClient, vecClientEyeAng);
		
		//Check for colliding entities
		TR_TraceRayFilter(vecClientEyePos, vecClientEyeAng, MASK_PLAYERSOLID, RayType_Infinite, TraceRay_DontHitEntity, iClient);
		
		if (!TR_DidHit(INVALID_HANDLE)) return;
		
		int iEntity = TR_GetEntityIndex(INVALID_HANDLE);
		GetEdictClassname(iEntity, sClassname, sizeof(sClassname));
		
		if (strcmp(sClassname, "worldspawn") != 0 && strncmp(sClassname, "prop_", 5) != 0)
			return;
		
		float vecNormal[3];
		TR_GetPlaneNormal(INVALID_HANDLE, vecNormal);
		GetVectorAngles(vecNormal, vecNormal);
		
		if (vecNormal[0] >= 30.0 && vecNormal[0] <= 330.0) return;
		if (vecNormal[0] <= -30.0) return;
		
		float vecPos[3];
		TR_GetEndPosition(vecPos);
		float flDistance = GetVectorDistance(vecClientEyePos, vecPos);
		
		if (flDistance >= this.flMaxDistance) return;
		
		float fVelocity[3];
		GetEntPropVector(iClient, Prop_Data, "m_vecVelocity", fVelocity);
		fVelocity[2] = this.flMaxHeight;
		TeleportEntity(iClient, NULL_VECTOR, NULL_VECTOR, fVelocity);
	}
	
	public void OnThink()
	{
		Hud_AddText(this.iClient, "Climb walls by hitting them with your melee weapon!");
	}
};