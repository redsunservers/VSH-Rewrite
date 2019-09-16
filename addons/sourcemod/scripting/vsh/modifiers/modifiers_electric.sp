methodmap CModifiersElectric < SaxtonHaleBase
{
	public CModifiersElectric(CModifiersElectric boss)
	{
		PrecacheGeneric("sprites/laserbeam.vmt");
	}
	
	public void GetModifiersName(char[] sName, int length)
	{
		strcopy(sName, length, "Electric");
	}
	
	public void GetModifiersInfo(char[] sInfo, int length)
	{
		StrCat(sInfo, length, "\nColor: Yellow");
		StrCat(sInfo, length, "\n ");
		StrCat(sInfo, length, "\n- Every attack damages nearby players");
		StrCat(sInfo, length, "\n- Every attack deals 15%% less damage");
	}
	
	public int GetRenderColor(int iColor[4])
	{
		iColor[0] = 255;
		iColor[1] = 192;
		iColor[2] = 0;
		iColor[3] = 255;
	}
	
	public Action OnAttackDamage(int &victim, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
	{		
		if (TF2_IsUbercharged(victim)) return Plugin_Continue;
		
		int iTeam = GetClientTeam(victim);
		
		float vecVictimPos[3];
		GetClientAbsOrigin(victim, vecVictimPos);
		vecVictimPos[2] += 40.0;
		
		damage *= 0.85;
		
		int iTarget = CreateEntityByName("info_target");
		if (iTarget > MaxClients)
		{
			TeleportEntity(iTarget, vecVictimPos, NULL_VECTOR, NULL_VECTOR);
			DispatchSpawn(iTarget);
			
			CreateTimer(0.3, Timer_EntityCleanup, EntIndexToEntRef(iTarget));
		}
		
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == iTeam && i != victim)
			{
				float vecTargetPos[3];
				GetClientAbsOrigin(i, vecTargetPos);
				vecTargetPos[2] += 40.0;
				
				if (GetVectorDistance(vecVictimPos, vecTargetPos) < 215.0)
				{
					SDKHooks_TakeDamage(i, 0, this.iClient, (damage * 0.40), DMG_SHOCK, _, _, vecVictimPos);
					
					int iLaser = CreateEntityByName("env_laser");
					if (iLaser > MaxClients)
					{
						SetEntityModel(iLaser, "sprites/laserbeam.vmt");
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
		
		return Plugin_Changed;
	}
};