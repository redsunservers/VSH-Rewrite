#define MAGNET_RANGE	500.0
#define MAGNET_STRENGTH	8.0

public void ModifiersMagnet_Create(SaxtonHaleBase boss)
{
	boss.flSpeed *= 0.9; //370 -> 333
}

public void ModifiersMagnet_GetModifiersName(SaxtonHaleBase boss, char[] sName, int length)
{
	strcopy(sName, length, "Magnet");
}

public void ModifiersMagnet_GetModifiersInfo(SaxtonHaleBase boss, char[] sInfo, int length)
{
	StrCat(sInfo, length, "\nColor: Pink");
	StrCat(sInfo, length, "\n ");
	StrCat(sInfo, length, "\n- Pulls itself and enemy player toward eachother");
	StrCat(sInfo, length, "\n- 10%% movement speed penalty");
}

public void ModifiersMagnet_GetRenderColor(SaxtonHaleBase boss, int iColor[4])
{
	iColor[0] = 255;
	iColor[1] = 128;
	iColor[2] = 255;
	iColor[3] = 255;
}

public void ModifiersMagnet_GetParticleEffect(SaxtonHaleBase boss, int index, char[] sEffect, int length)
{
	if (index == 0)
		strcopy(sEffect, length, "utaunt_electricity_purple_glow");
}

public void ModifiersMagnet_OnThink(SaxtonHaleBase boss)
{
	if (!IsPlayerAlive(boss.iClient))
		return;
	
	float vecOrigin[3], vecPullVelocity[3];
	GetClientAbsOrigin(boss.iClient, vecOrigin);
	TFTeam nTeam = TF2_GetClientTeam(boss.iClient);
	int iCount = 0;
	
	//Player interaction
	for (int iVictim = 1; iVictim <= MaxClients; iVictim++)
	{
		if (IsClientInGame(iVictim) && IsPlayerAlive(iVictim) && TF2_GetClientTeam(iVictim) != nTeam)
		{
			float vecTargetOrigin[3];
			GetClientAbsOrigin(iVictim, vecTargetOrigin);
			if (GetVectorDistance(vecOrigin, vecTargetOrigin) <= MAGNET_RANGE)
			{
				float vecTargetPullVelocity[3];
				MakeVectorFromPoints(vecOrigin, vecTargetOrigin, vecTargetPullVelocity);
				
				//We don't want players to helplessly hover slightly above ground if the boss is above them, so we don't modify their vertical velocity
				vecTargetPullVelocity[2] = 0.0;
				
				//Boss velocity
				NormalizeVector(vecTargetPullVelocity, vecTargetPullVelocity);
				AddVectors(vecPullVelocity, vecTargetPullVelocity, vecPullVelocity);
				iCount++;
				
				//Victim velocity
				NegateVector(vecTargetPullVelocity);
				ScaleVector(vecTargetPullVelocity, MAGNET_STRENGTH);
				
				//Consider their current velocity
				float vecTargetVelocity[3];
				GetEntPropVector(iVictim, Prop_Data, "m_vecVelocity", vecTargetVelocity);
				
				AddVectors(vecTargetVelocity, vecTargetPullVelocity, vecTargetVelocity);
				TeleportEntity(iVictim, NULL_VECTOR, NULL_VECTOR, vecTargetVelocity);
			}
		}
	}
	
	//Don't do anything to the boss if nobody is in range
	if (iCount <= 0)
		return;
	
	ScaleVector(vecPullVelocity, 1.0 / float(iCount));	//So vel won't go crazy with huge amount of players
	ScaleVector(vecPullVelocity, MAGNET_STRENGTH);
	
	//Consider boss current velocity
	float vecVelocity[3];
	GetEntPropVector(boss.iClient, Prop_Data, "m_vecVelocity", vecVelocity);
	
	AddVectors(vecVelocity, vecPullVelocity, vecVelocity);
	TeleportEntity(boss.iClient, NULL_VECTOR, NULL_VECTOR, vecVelocity);
}
