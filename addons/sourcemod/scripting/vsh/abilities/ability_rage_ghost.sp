#define GHOST_MODEL	"models/props_halloween/ghost.mdl"

#define PARTICLE_BEAM	"passtime_beam"

static float g_flGhostHealStartTime[MAXPLAYERS][2048];
static int g_iGhostHealStealCount[MAXPLAYERS][2048];

static float g_flGhostHealGainBuffer[MAXPLAYERS];
static float g_flGhostLastSpookTime[MAXPLAYERS];

static bool g_bGhostEnable[MAXPLAYERS];

static int g_iGhostParticleBeam[MAXPLAYERS][2048];
static int g_iGhostParticleCentre[MAXPLAYERS];

public void RageGhost_GetModel(SaxtonHaleBase boss, char[] sModel, int iLength)
{
	//Override boss's model during GetModel function
	if (g_bGhostEnable[boss.iClient])
		strcopy(sModel, iLength, GHOST_MODEL);
}

public void RageGhost_Create(SaxtonHaleBase boss)
{
	//Default values, these can be changed if needed
	boss.SetPropFloat("RageGhost", "Radius", 400.0);
	boss.SetPropFloat("RageGhost", "Duration", 8.0);
	boss.SetPropFloat("RageGhost", "HealSteal", 25.0);	//Steals hp per second
	boss.SetPropFloat("RageGhost", "HealGainMultiplier", 2.0);	//Gains hp multiplied by amount of health stolen
	boss.SetPropFloat("RageGhost", "BuildingDrain", 3.0);	//Building health drain multiplier based on flHealSteal, 0.0 or lower disables it
	boss.SetPropFloat("RageGhost", "PullStrength", 10.0);	//Scale of pull strength, negative values push enemies away instead. Note that making it too weak will only pull players if they're airborne
	
	g_bGhostEnable[boss.iClient] = false;
	g_flGhostLastSpookTime[boss.iClient] = 0.0;
	
	for (int iVictim = 1; iVictim <= MAXPLAYERS; iVictim++)
		g_iGhostParticleBeam[boss.iClient][iVictim] = 0;
}

public void RageGhost_OnRage(SaxtonHaleBase boss)
{
	int iClient = boss.iClient;
	
	g_bGhostEnable[iClient] = true;
	g_flGhostHealGainBuffer[iClient] = 0.0;
	
	SetEntProp(iClient, Prop_Data, "m_takedamage", DAMAGE_NO);
	
	//Update model
	ApplyBossModel(iClient);
	
	float vecOrigin[3], vecAngles[3];
	GetClientAbsOrigin(iClient, vecOrigin);
	GetClientEyeAngles(iClient, vecAngles);
	
	//Create poof particle
	CreateTimer(3.0, Timer_EntityCleanup, TF2_SpawnParticle(PARTICLE_GHOST, vecOrigin, vecAngles));
	
	//Create "centre" particle dummy for beams to connect it
	vecOrigin[2] += 42.0;
	g_iGhostParticleCentre[iClient] = TF2_SpawnParticle("", vecOrigin, vecAngles, false, iClient);
	
	//Stun and Fly
	float flDuration = boss.GetPropFloat("RageGhost", "Duration");
	TF2_StunPlayer(iClient, flDuration, 0.0, TF_STUNFLAG_GHOSTEFFECT|TF_STUNFLAG_NOSOUNDOREFFECT, 0)
	TF2_AddCondition(iClient, TFCond_SwimmingNoEffects, flDuration);
	TF2_AddCondition(iClient, TFCond_ImmuneToPushback, flDuration);
	
	//Get active weapon and dont render
	int iWeapon = GetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon");
	if (IsValidEdict(iWeapon))
	{
		SetEntityRenderMode(iWeapon, RENDER_TRANSCOLOR);
		SetEntityRenderColor(iWeapon, _, _, _, 0);
	}
	
	//Thirdperson
	SetVariantInt(1);
	AcceptEntityInput(iClient, "SetForcedTauntCam");
}

public void RageGhost_OnThink(SaxtonHaleBase boss)
{
	int iClient = boss.iClient;
	if (!g_bGhostEnable[iClient]) return;
	
	if (boss.GetPropFloat("RageGhost", "Duration") > GetGameTime() - boss.flRageLastTime)
	{
		float vecOrigin[3];
		GetClientAbsOrigin(iClient, vecOrigin);
		vecOrigin[2] += 42.0;
		
		//Arrays of spooked clients
		int[] iSpooked = new int[MaxClients];
		int iLength = 0;
		
		float flRadius = (boss.bSuperRage) ? boss.GetPropFloat("RageGhost", "Radius") * 1.25 : boss.GetPropFloat("RageGhost", "Radius");
		float flHealSteal = (boss.bSuperRage) ? boss.GetPropFloat("RageGhost", "HealSteal") * 2.0 : boss.GetPropFloat("RageGhost", "HealSteal");
		
		//Player interaction
		for (int iVictim = 1; iVictim <= MaxClients; iVictim++)
		{
			bool bSpook = false;
			
			if (IsClientInGame(iVictim) && IsPlayerAlive(iVictim) && TF2_GetClientTeam(iVictim) != TF2_GetClientTeam(iClient))
			{
				float vecTargetOrigin[3];
				GetClientAbsOrigin(iVictim, vecTargetOrigin);
				vecTargetOrigin[2] += 42.0;
				if (GetVectorDistance(vecOrigin, vecTargetOrigin) <= flRadius && IsPointsClear(vecOrigin, vecTargetOrigin))
				{
					//Victim got spooked
					bSpook = true;
					iSpooked[iLength] = iVictim;
					iLength++;
						
					//Pull victim towards boss
					if (boss.GetPropFloat("RageGhost", "PullStrength") != 0.0)
					{
						float vecPullVelocity[3];
						MakeVectorFromPoints(vecTargetOrigin, vecOrigin, vecPullVelocity);
						
						//We don't want players to helplessly hover slightly above ground if the boss is above them, so we don't modify their vertical velocity
						vecPullVelocity[2] = 0.0;
						
						NormalizeVector(vecPullVelocity, vecPullVelocity);
						ScaleVector(vecPullVelocity, boss.GetPropFloat("RageGhost", "PullStrength"));
						
						//Consider their current velocity
						float vecTargetVelocity[3];
						GetEntPropVector(iVictim, Prop_Data, "m_vecVelocity", vecTargetVelocity);
						AddVectors(vecTargetVelocity, vecPullVelocity, vecPullVelocity);
						
						TeleportEntity(iVictim, NULL_VECTOR, NULL_VECTOR, vecPullVelocity);
					}

					//Set time when victim entered
					if (g_flGhostHealStartTime[iClient][iVictim] == 0.0)
					{
						g_flGhostHealStartTime[iClient][iVictim] = GetGameTime();
						
						float vecTargetAngles[3];
						GetClientAbsAngles(iClient, vecTargetAngles);
						g_iGhostParticleBeam[iClient][iVictim] = TF2_SpawnParticle(PARTICLE_BEAM, vecTargetOrigin, vecTargetAngles, true, iVictim, EntRefToEntIndex(g_iGhostParticleCentre[iClient]));
					}
					
					//Calculate on heal steal
					float flTimeGap = GetGameTime() - g_flGhostHealStartTime[iClient][iVictim];
					
					float flExpectedSteal = flTimeGap * flHealSteal;
					if (flExpectedSteal > g_iGhostHealStealCount[iClient][iVictim] + 1.0)
					{
						float flDamage = flExpectedSteal - float(g_iGhostHealStealCount[iClient][iVictim]);
						
						int iHealth = GetEntProp(iVictim, Prop_Send, "m_iHealth");
						SDKHooks_TakeDamage(iVictim, iClient, iClient, flDamage, DMG_PREVENT_PHYSICS_FORCE);
						int iHealthLost = iHealth - GetEntProp(iVictim, Prop_Send, "m_iHealth");
						
						if (iHealthLost > 0)	//Health is lost
						{
							g_iGhostHealStealCount[iClient][iVictim] += iHealthLost;
							
							//Only heal the boss if we're connected to attackers
							if (SaxtonHale_IsValidAttack(iVictim))
							{
								g_flGhostHealGainBuffer[iClient] += float(iHealthLost) * boss.GetPropFloat("RageGhost", "HealGainMultiplier");
								int iExpectedGain = RoundToFloor(g_flGhostHealGainBuffer[iClient]);
								if (iExpectedGain > 0)
								{
									Client_AddHealth(iClient, iExpectedGain);
									g_flGhostHealGainBuffer[iClient] -= iExpectedGain;
								}
							}
						}
						else if (flDamage > 3.0)	//Player is invincible, just update steal count without giving boss health
						{
							g_iGhostHealStealCount[iClient][iVictim]++;
						}
					}
				}
			}
			
			//Check if beam ent need to be killed, from out of range or client death/disconnect
			if (!bSpook && g_flGhostHealStartTime[iClient][iVictim] != 0.0)
			{
				g_flGhostHealStartTime[iClient][iVictim] = 0.0;
				g_iGhostHealStealCount[iClient][iVictim] = 0;
				Timer_EntityCleanup(null, g_iGhostParticleBeam[iClient][iVictim]);
			}
		}
		
		//Building interaction -- you basically just damage them
		if (boss.GetPropFloat("RageGhost", "BuildingDrain") > 0.0)
		{
			int iBuilding = MaxClients+1;
			
			while ((iBuilding = FindEntityByClassname(iBuilding, "obj_*")) > MaxClients)
			{
				bool bLinked = false;
				if (GetEntProp(iBuilding, Prop_Send, "m_iTeamNum") != GetClientTeam(iClient))
				{
					float vecTargetOrigin[3];
					GetEntPropVector(iBuilding, Prop_Send, "m_vecOrigin", vecTargetOrigin);
					
					//Teleporters are tiny, so the beam must be down low
					char sClassname[32];
					GetEntityClassname(iBuilding, sClassname, sizeof(sClassname));
					if (StrEqual(sClassname, "obj_teleporter"))
						vecTargetOrigin[2] += 5.0;
					else
						vecTargetOrigin[2] += 42.0;
					
					if (GetVectorDistance(vecOrigin, vecTargetOrigin) <= flRadius && IsPointsClear(vecOrigin, vecTargetOrigin))
					{
						bLinked = true;
						if (g_flGhostHealStartTime[iClient][iBuilding] == 0.0)
						{
							g_flGhostHealStartTime[iClient][iBuilding] = GetGameTime();
							
							float vecTargetAngles[3];
							GetClientAbsAngles(iClient, vecTargetAngles);
							g_iGhostParticleBeam[iClient][iBuilding] = TF2_SpawnParticle(PARTICLE_BEAM, vecTargetOrigin, vecTargetAngles, true, iBuilding, EntRefToEntIndex(g_iGhostParticleCentre[iClient]));
						}
							
						float flTimeGap = GetGameTime() - g_flGhostHealStartTime[iClient][iBuilding];
							
						int iExpectedSteal = RoundToCeil(flTimeGap * flHealSteal * boss.GetPropFloat("RageGhost", "BuildingDrain"));
						if (iExpectedSteal > g_iGhostHealStealCount[iClient][iBuilding])
						{
							float flDamage = (float(iExpectedSteal - g_iGhostHealStealCount[iClient][iBuilding]));
							SDKHooks_TakeDamage(iBuilding, iClient, iClient, flDamage);
							g_iGhostHealStealCount[iClient][iBuilding] = iExpectedSteal;
						}
					}
						
					if (!bLinked && g_flGhostHealStartTime[iClient][iBuilding] != 0.0)
					{
						g_flGhostHealStartTime[iClient][iBuilding] = 0.0;
						g_iGhostHealStealCount[iClient][iBuilding] = 0;
						Timer_EntityCleanup(null, g_iGhostParticleBeam[iClient][iBuilding]);
					}
				}
			}
		}
		
		//Random Spook effects, 2.5 sec cooldown
		if (g_flGhostLastSpookTime[iClient] < GetGameTime() - 2.5)
		{
			g_flGhostLastSpookTime[iClient] = GetGameTime();
			
			if (iLength == 0)
				return;
			
			SortIntegers(iSpooked, iLength, Sort_Random);
			
			//Visual/Sound effects
			for (int i = 0; i < iLength; i++)
			{
				CreateFade(iSpooked[i], 1000, 160, 56, 204, 160);
				
				char sSound[PLATFORM_MAX_PATH];
				boss.CallFunction("GetSoundAbility", sSound, sizeof(sSound), "RageGhost");
				if (!StrEmpty(sSound))
					EmitSoundToClient(iSpooked[i], sSound);
			}
			
			//Random teleports
			if (iLength >= 2 && !GetRandomInt(0, 2))
			{
				int iTeleport[2];
				iTeleport[0] = iSpooked[iLength-2];
				iTeleport[1] = iSpooked[iLength-1];
				TF2_TeleportSwap(iTeleport);
				iLength -= 2;
			}
			
			//Attempt to change to a random weapon slot
			for (int i = 0; i < iLength; i++)
			{
				ArrayList aWeapons = new ArrayList();
				int iActiveWeapon = GetEntPropEnt(iSpooked[i], Prop_Send, "m_hActiveWeapon");
				
				//We don't want to count PDA2 due to invis watch
				for (int iSlot = 0; iSlot <= WeaponSlot_PDADisguise; iSlot++)
				{
					int iWeapon = GetPlayerWeaponSlot(iSpooked[i], iSlot);
					if (IsValidEdict(iWeapon) && iWeapon != iActiveWeapon)
						aWeapons.Push(iWeapon);
				}
				
				if (aWeapons.Length > 0)
				{
					//Get random weapon/slot to change
					aWeapons.Sort(Sort_Random, Sort_Integer);
					TF2_SwitchToWeapon(iSpooked[i], aWeapons.Get(0));
				}
				
				delete aWeapons;
			}
		}
	}
	else
	{
		//Rage ended
		g_bGhostEnable[iClient] = false;
		SetEntProp(iClient, Prop_Data, "m_takedamage", DAMAGE_YES);
		
		Timer_EntityCleanup(null, g_iGhostParticleCentre[iClient]);
		for (int iEntity = 1; iEntity < 2048; iEntity++)
		{	
			if (g_flGhostHealStartTime[iClient][iEntity] > 0.0)
			{
				g_iGhostHealStealCount[iClient][iEntity] = 0;
				g_flGhostHealStartTime[iClient][iEntity] = 0.0;
				Timer_EntityCleanup(null, g_iGhostParticleBeam[iClient][iEntity]);
			}
		}
		
		//Update model
		ApplyBossModel(boss.iClient);
		
		//Create poof particle
		float vecOrigin[3];
		GetClientAbsOrigin(iClient, vecOrigin);
		CreateTimer(3.0, Timer_EntityCleanup, TF2_SpawnParticle(PARTICLE_GHOST, vecOrigin));
		
		//Get active weapon and make it visible again
		int iWeapon = GetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon");
		if (IsValidEdict(iWeapon))
		{
			SetEntityRenderMode(iWeapon, RENDER_NORMAL);
			SetEntityRenderColor(iWeapon, _, _, _, 255);
		}
		
		//Firstperson
		SetVariantInt(0);
		AcceptEntityInput(iClient, "SetForcedTauntCam");
	}
}

public void RageGhost_OnButton(SaxtonHaleBase boss, int &buttons)
{
	//Don't allow him to attack during rage
	if (g_bGhostEnable[boss.iClient] && buttons & IN_ATTACK)
		buttons &= ~IN_ATTACK;
}

public void RageGhost_OnPlayerKilled(SaxtonHaleBase boss, Event event)
{
	//Purely cosmetic effect, but let's add a cool little icon for killing with the rage
	int iInflictor = event.GetInt("inflictor_entindex");
	
	if (g_bGhostEnable[boss.iClient] && iInflictor == boss.iClient)
	{
		event.SetString("weapon_logclassname", "purgatory");
		event.SetString("weapon", "purgatory");
	}
}

public void RageGhost_OnDestroyObject(SaxtonHaleBase boss, Event event)
{
	// "attacker" does not give the value we're looking for, so check for "weaponid" instead
	int iWeaponId = event.GetInt("weaponid");

	if (g_bGhostEnable[boss.iClient] && iWeaponId == TF_WEAPON_SWORD)
	{
		event.SetString("weapon", "purgatory"); 
	}
}

public void RageGhost_Destroy(SaxtonHaleBase boss)
{
	SetEntProp(boss.iClient, Prop_Data, "m_takedamage", DAMAGE_YES);
}

public void RageGhost_Precache(SaxtonHaleBase boss)
{
	PrecacheModel(GHOST_MODEL);
	PrecacheParticleSystem(PARTICLE_BEAM);
}

