static float g_flWallClimbMaxHeight[TF_MAXPLAYERS];
static float g_flWallClimbMaxDistance[TF_MAXPLAYERS];
static float g_flWallClimbHorizontalSpeedMult[TF_MAXPLAYERS];
static float g_flWallClimbMaxHorizontalVelocity[TF_MAXPLAYERS];

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
	property float flHorizontalSpeedMult
	{
		public get()
		{
			return g_flWallClimbHorizontalSpeedMult[this.iClient];
		}
		public set(float val)
		{
			g_flWallClimbHorizontalSpeedMult[this.iClient] = val;
		}
	}
	property float flMaxHorizontalVelocity
	{
		public get()
		{
			return g_flWallClimbMaxHorizontalVelocity[this.iClient];
		}
		public set(float val)
		{
			g_flWallClimbMaxHorizontalVelocity[this.iClient] = val;
		}
	}
	
	public CWallClimb(CWallClimb ability)
	{
		//Default values, these can be changed if needed
		ability.flMaxHeight = 750.0;
		ability.flMaxDistance = 100.0;
		ability.flHorizontalSpeedMult = 1.2;  //Horizontal speed multiplier, for better mobility if the boss is trying to go anywhere besides straight up
		ability.flMaxHorizontalVelocity = 600.0;  //Horizontal speed limit because we don't want the boss to fly around the map at light speed
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
		
		float vecVelocity[3];
		GetEntPropVector(iClient, Prop_Data, "m_vecVelocity", vecVelocity);
		
		//Increase horizontal velocity
		vecVelocity[0] *= this.flHorizontalSpeedMult;
		vecVelocity[1] *= this.flHorizontalSpeedMult;
		
		//Limit max speed
		float flSpeed = SquareRoot(vecVelocity[0] * vecVelocity[0] + vecVelocity[1] * vecVelocity[1]);
		if (flSpeed > this.flMaxHorizontalVelocity)
		{
			vecVelocity[0] *= this.flMaxHorizontalVelocity / flSpeed;
			vecVelocity[1] *= this.flMaxHorizontalVelocity / flSpeed;
		}
		
		//Set vertical velocity, the main part of this ability
		vecVelocity[2] = this.flMaxHeight;
		
		TeleportEntity(iClient, NULL_VECTOR, NULL_VECTOR, vecVelocity);
	}
	
	public void GetHudText(char[] sMessage, int iLength)
	{
		StrCat(sMessage, iLength, "\nClimb walls by hitting them with your melee weapon!");
	}
};
