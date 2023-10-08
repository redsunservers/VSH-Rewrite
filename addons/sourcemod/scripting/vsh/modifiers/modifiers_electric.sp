#define ELECTRIC_BEAM	"sprites/laserbeam.spr"

static bool g_bElectricDamage[MAXPLAYERS];	//Whenever if client is currently being damaged or not

public void ModifiersElectric_Create(SaxtonHaleBase boss)
{
}

public void ModifiersElectric_GetModifiersName(SaxtonHaleBase boss, char[] sName, int length)
{
	strcopy(sName, length, "Electric");
}

public void ModifiersElectric_GetModifiersInfo(SaxtonHaleBase boss, char[] sInfo, int length)
{
	StrCat(sInfo, length, "\nColor: Yellow");
	StrCat(sInfo, length, "\n ");
	StrCat(sInfo, length, "\n- Every attack damages nearby players");
	StrCat(sInfo, length, "\n- Every attack deals 15%% less damage");
}

public void ModifiersElectric_GetRenderColor(SaxtonHaleBase boss, int iColor[4])
{
	iColor[0] = 255;
	iColor[1] = 255;
	iColor[2] = 0;
	iColor[3] = 255;
}

public Action ModifiersElectric_OnAttackDamage(SaxtonHaleBase boss, int iVictim, CTakeDamageInfo info)
{		
	if (info.m_flDamage < 3.0 || g_bElectricDamage[iVictim] || TF2_IsUbercharged(iVictim))
		return Plugin_Continue;
	
	TFTeam nTeam = TF2_GetClientTeam(iVictim);
	
	float vecVictimPos[3];
	GetClientAbsOrigin(iVictim, vecVictimPos);
	vecVictimPos[2] += 40.0;
	
	info.m_flDamage *= 0.85;
	
	//Mark victim as currently taking damage to avoid endless loop
	g_bElectricDamage[iVictim] = true;
	
	//Create entity at centre so lasers can connect
	int iTarget = CreateEntityByName("info_target");
	if (iTarget > MaxClients)
	{
		TeleportEntity(iTarget, vecVictimPos, NULL_VECTOR, NULL_VECTOR);
		DispatchSpawn(iTarget);
		
		CreateTimer(0.3, Timer_EntityCleanup, EntIndexToEntRef(iTarget));
	}
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i) && TF2_GetClientTeam(i) == nTeam && i != iVictim)
		{
			float vecTargetPos[3];
			GetClientAbsOrigin(i, vecTargetPos);
			vecTargetPos[2] += 40.0;
			
			if (GetVectorDistance(vecVictimPos, vecTargetPos) < 215.0)
			{
				//Mark victim as currently taking damage to avoid endless loop
				g_bElectricDamage[i] = true;
				SDKHooks_TakeDamage(i, 0, boss.iClient, (info.m_flDamage * 0.40), DMG_SHOCK, _, _, vecVictimPos);
				g_bElectricDamage[i] = false;
				
				int iLaser = CreateEntityByName("env_laser");
				if (iLaser > MaxClients)
				{
					DispatchKeyValue(iLaser, "texture", ELECTRIC_BEAM);
					DispatchKeyValue(iLaser, "renderamt", "100");		//Brightness
					DispatchKeyValue(iLaser, "rendermode", "0");
					DispatchKeyValue(iLaser, "rendercolor", "255 192 0");	//Color
					DispatchKeyValue(iLaser, "life", "0");				//How long should beam stay (0 = inf)
					DispatchKeyValue(iLaser, "width", "1.5");			//Width of beam
					DispatchKeyValue(iLaser, "NoiseAmplitude", "15");	//Noise shake
					DispatchKeyValue(iLaser, "damage", "0");			//SDKHooks deals damage instead
					
					TeleportEntity(iLaser, vecTargetPos, NULL_VECTOR, NULL_VECTOR );
					DispatchSpawn(iLaser);
					
					SetEntPropEnt(iLaser, Prop_Send, "m_hAttachEntity", EntIndexToEntRef(iLaser), 0);
					SetEntPropEnt(iLaser, Prop_Send, "m_hAttachEntity", EntIndexToEntRef(iTarget), 1);
					SetEntProp(iLaser, Prop_Send, "m_nNumBeamEnts", BEAM_ENTS);
					SetEntProp(iLaser, Prop_Send, "m_nBeamType", BEAM_ENTS);
					
					AcceptEntityInput(iLaser, "TurnOn");
					
					CreateTimer(0.3, Timer_EntityCleanup, EntIndexToEntRef(iLaser));
				}
			}
		}
	}
	
	g_bElectricDamage[iVictim] = false;
	return Plugin_Changed;
}