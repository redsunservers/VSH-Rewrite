public void WallClimb_Create(SaxtonHaleBase boss)
{
	//Default values, these can be changed if needed
	boss.SetPropFloat("WallClimb", "MaxHeight", 750.0);
	boss.SetPropFloat("WallClimb", "MaxDistance", 100.0);
	boss.SetPropFloat("WallClimb", "HorizontalSpeedMult", 1.2);  //Horizontal speed multiplier, for better mobility if the boss is trying to go anywhere besides straight up
	boss.SetPropFloat("WallClimb", "MaxHorizontalVelocity", 600.0);  //Horizontal speed limit because we don't want the boss to fly around the map at light speed
}

public Action WallClimb_OnAttackCritical(SaxtonHaleBase boss, int iWeapon, bool &bResult)
{
	int iClient = boss.iClient;
	
	char sClassname[64];
	float vecClientEyePos[3], vecClientEyeAng[3];
	GetClientEyePosition(iClient, vecClientEyePos);
	GetClientEyeAngles(iClient, vecClientEyeAng);
	
	//Check for colliding entities
	TR_TraceRayFilter(vecClientEyePos, vecClientEyeAng, MASK_PLAYERSOLID, RayType_Infinite, TraceRay_DontHitEntity, iClient);
	
	if (!TR_DidHit(INVALID_HANDLE)) return Plugin_Continue;
	
	int iEntity = TR_GetEntityIndex(INVALID_HANDLE);
	GetEdictClassname(iEntity, sClassname, sizeof(sClassname));
	
	if (strcmp(sClassname, "worldspawn") != 0 && strncmp(sClassname, "prop_", 5) != 0)
		return Plugin_Continue;
	
	float vecNormal[3];
	TR_GetPlaneNormal(INVALID_HANDLE, vecNormal);
	GetVectorAngles(vecNormal, vecNormal);
	
	if (vecNormal[0] >= 30.0 && vecNormal[0] <= 330.0) return Plugin_Continue;
	if (vecNormal[0] <= -30.0) return Plugin_Continue;
	
	float vecPos[3];
	TR_GetEndPosition(vecPos);
	float flDistance = GetVectorDistance(vecClientEyePos, vecPos);
	
	if (flDistance >= boss.GetPropFloat("WallClimb", "MaxDistance")) return Plugin_Continue;
	
	float vecVelocity[3];
	GetEntPropVector(iClient, Prop_Data, "m_vecVelocity", vecVelocity);
	
	//Increase horizontal velocity
	vecVelocity[0] *= boss.GetPropFloat("WallClimb", "HorizontalSpeedMult");
	vecVelocity[1] *= boss.GetPropFloat("WallClimb", "HorizontalSpeedMult");
	
	//Limit max speed
	float flSpeed = SquareRoot(vecVelocity[0] * vecVelocity[0] + vecVelocity[1] * vecVelocity[1]);
	if (flSpeed > boss.GetPropFloat("WallClimb", "MaxHorizontalVelocity"))
	{
		vecVelocity[0] *= boss.GetPropFloat("WallClimb", "MaxHorizontalVelocity") / flSpeed;
		vecVelocity[1] *= boss.GetPropFloat("WallClimb", "MaxHorizontalVelocity") / flSpeed;
	}
	
	//Set vertical velocity, the main part of this ability
	vecVelocity[2] = boss.GetPropFloat("WallClimb", "MaxHeight");
	
	TeleportEntity(iClient, NULL_VECTOR, NULL_VECTOR, vecVelocity);
	return Plugin_Continue;
}

public void WallClimb_GetHudInfo(SaxtonHaleBase boss, char[] sMessage, int iLength, int iColor[4])
{
	StrCat(sMessage, iLength, "\nClimb walls by hitting them with your melee weapon!");
}

