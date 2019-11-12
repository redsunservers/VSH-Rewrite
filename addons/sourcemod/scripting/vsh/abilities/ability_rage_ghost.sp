#define GHOST_MODEL	"models/props_halloween/ghost.mdl"

#define PARTICLE_BEAM_BLU	"medicgun_beam_blue"
#define PARTICLE_BEAM_RED	"medicgun_beam_red"

static float g_flGhostRadius[TF_MAXPLAYERS+1];
static float g_flGhostDuration[TF_MAXPLAYERS+1];
static float g_flGhostHealSteal[TF_MAXPLAYERS+1];
static float g_flGhostHealGain[TF_MAXPLAYERS+1];
static float g_flGhostPullStrength[TF_MAXPLAYERS+1];
static float g_flGhostBuildingDrain[TF_MAXPLAYERS+1];

static float g_flGhostHealStartTime[TF_MAXPLAYERS+1][2048];
static int g_iGhostHealStealCount[TF_MAXPLAYERS+1][2048];
static int g_iGhostHealGainCount[TF_MAXPLAYERS+1][TF_MAXPLAYERS+1];

static float g_flGhostLastSpookTime[TF_MAXPLAYERS+1];

static bool g_bGhostEnable[TF_MAXPLAYERS+1];

static int g_iGhostParticleBeam[TF_MAXPLAYERS+1][2048];
static int g_iGhostParticleCentre[TF_MAXPLAYERS+1];

methodmap CRageGhost < SaxtonHaleBase
{
	property float flRadius
	{
		public get()
		{
			return g_flGhostRadius[this.iClient];
		}
		public set(float val)
		{
			g_flGhostRadius[this.iClient] = val;
		}
	}
	
	property float flDuration
	{
		public get()
		{
			return g_flGhostDuration[this.iClient];
		}
		public set(float val)
		{
			g_flGhostDuration[this.iClient] = val;
		}
	}
	
	property float flHealSteal
	{
		public get()
		{
			return g_flGhostHealSteal[this.iClient];
		}
		public set(float val)
		{
			g_flGhostHealSteal[this.iClient] = val;
		}
	}
	
	property float flHealGain
	{
		public get()
		{
			return g_flGhostHealGain[this.iClient];
		}
		public set(float val)
		{
			g_flGhostHealGain[this.iClient] = val;
		}
	}
	
	property float flBuildingDrain
	{
		public get()
		{
			return g_flGhostBuildingDrain[this.iClient];
		}
		public set(float val)
		{
			g_flGhostBuildingDrain[this.iClient] = val;
		}
	}
	
	property float flPullStrength
	{
		public get()
		{
			return g_flGhostPullStrength[this.iClient];
		}
		public set(float val)
		{
			g_flGhostPullStrength[this.iClient] = val;
		}
	}
	
	public void GetModel(char[] sModel, int iLength)
	{
		//Override boss's model during GetModel function
		if (g_bGhostEnable[this.iClient])
			strcopy(sModel, iLength, GHOST_MODEL);
	}
	
	public CRageGhost(CRageGhost ability)
	{
		//Default values, these can be changed if needed
		ability.flRadius = 400.0;
		ability.flDuration = 8.0;
		ability.flHealSteal = 20.0;	//Steals hp per second
		ability.flHealGain = 40.0;	//Gains hp per second
		ability.flBuildingDrain = 1.0;	//Building health drain multiplier, 0.0 or lower disables it
		ability.flPullStrength = 1.0;	//Pull strength multiplier, negative values push enemies away instead. Note that making it too weak will only pull players if they're airborne
		
		g_bGhostEnable[ability.iClient] = false;
		g_flGhostLastSpookTime[ability.iClient] = 0.0;
		
		for (int iVictim = 1; iVictim <= TF_MAXPLAYERS; iVictim++)
			g_iGhostParticleBeam[ability.iClient][iVictim] = 0;
	}
	
	public void OnRage()
	{
		int iClient = this.iClient;
		
		g_bGhostEnable[iClient] = true;
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
		TF2_StunPlayer(iClient, this.flDuration, 0.0, TF_STUNFLAG_GHOSTEFFECT|TF_STUNFLAG_NOSOUNDOREFFECT, 0);
		TF2_AddCondition(iClient, TFCond_SwimmingNoEffects, this.flDuration);
		
		//Get active weapon and dont render
		int iWeapon = GetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon");
		if (IsValidEdict(iWeapon))
		{
			SetEntityRenderMode(iWeapon, RENDER_TRANSCOLOR);
			SetEntityRenderColor(iWeapon, _, _, _, 0);
		}
		
		//Thirdperson
		SetVariantInt(1);
		AcceptEntityInput(this.iClient, "SetForcedTauntCam");
	}
	
	public void OnThink()
	{
		int iClient = this.iClient;
		if (!g_bGhostEnable[iClient]) return;
		
		if (this.flDuration > GetGameTime() - this.flRageLastTime)
		{
			float vecOrigin[3];
			GetClientAbsOrigin(iClient, vecOrigin);
			
			int iTeam = GetClientTeam(iClient);
			static char sParticle[][] = {
				"",
				"",
				PARTICLE_BEAM_RED,
				PARTICLE_BEAM_BLU,
			};
			
			//Arrays of spooked clients
			int[] iSpooked = new int[MaxClients];
			int iLength = 0;
			
			float flRadius = (this.bSuperRage) ? this.flRadius * 1.5 : this.flRadius;
			float flHealSteal = (this.bSuperRage) ? this.flHealSteal * 2 : this.flHealSteal;
			
			//Player interaction
			for (int iVictim = 1; iVictim <= MaxClients; iVictim++)
			{
				bool bSpook = false;
				
				if (SaxtonHale_IsValidAttack(iVictim) && IsPlayerAlive(iVictim))
				{
					float vecTargetOrigin[3];
					GetClientAbsOrigin(iVictim, vecTargetOrigin);
					if (GetVectorDistance(vecOrigin, vecTargetOrigin) <= flRadius)
					{
						//Victim got spooked
						bSpook = true;
						iSpooked[iLength] = iVictim;
						iLength++;
							
						//Pull victim towards boss
						if (this.flPullStrength != 0.0)
						{
							float vecPullVelocity[3];
							MakeVectorFromPoints(vecTargetOrigin, vecOrigin, vecPullVelocity);
							
							//We don't want players to helplessly hover slightly above ground if the boss is above them, so we don't modify their vertical velocity
							vecPullVelocity[2] = 0.0;
							
							NormalizeVector(vecPullVelocity, vecPullVelocity);
							ScaleVector(vecPullVelocity, (10.0 * this.flPullStrength));
							
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
							
							vecTargetOrigin[2] += 42.0;
							float vecTargetAngles[3];
							GetClientAbsAngles(iClient, vecTargetAngles);
							g_iGhostParticleBeam[iClient][iVictim] = TF2_SpawnParticle(sParticle[iTeam], vecTargetOrigin, vecTargetAngles, true, iVictim, EntRefToEntIndex(g_iGhostParticleCentre[iClient]));
						}
						
						//Calculate on heal steal
						float flTimeGap = GetGameTime() - g_flGhostHealStartTime[iClient][iVictim];
						
						int iExpectedSteal = RoundToCeil(flTimeGap * flHealSteal);
						if (iExpectedSteal > g_iGhostHealStealCount[iClient][iVictim])
						{
							float flDamage = float(iExpectedSteal - g_iGhostHealStealCount[iClient][iVictim]);
							SDKHooks_TakeDamage(iVictim, iClient, iClient, flDamage, DMG_PREVENT_PHYSICS_FORCE);
							g_iGhostHealStealCount[iClient][iVictim] = iExpectedSteal;
						}
						
						float flHealGain = (this.bSuperRage) ? this.flHealGain * 2 : this.flHealGain; //Health gain is only applied from other players, so it's down here rather than with the other super rage checks
						int iExpectedGain = RoundToCeil(flTimeGap * flHealGain);
						if (iExpectedGain > g_iGhostHealGainCount[iClient][iVictim])
						{
							Client_AddHealth(iClient, iExpectedGain - g_iGhostHealGainCount[iClient][iVictim]);
							g_iGhostHealGainCount[iClient][iVictim] = iExpectedGain;
						}
					}
				}
				
				//Check if beam ent need to be killed, from out of range or client death/disconnect
				if (!bSpook && g_flGhostHealStartTime[iClient][iVictim] != 0.0)
				{
					g_flGhostHealStartTime[iClient][iVictim] = 0.0;
					g_iGhostHealStealCount[iClient][iVictim] = 0;
					g_iGhostHealGainCount[iClient][iVictim] = 0;
					Timer_EntityCleanup(null, g_iGhostParticleBeam[iClient][iVictim]);
				}
			}
			
			//Building interaction -- you basically just damage them
			if (this.flBuildingDrain > 0.0)
			{
				int iBuilding = MaxClients+1;
				
				while ((iBuilding = FindEntityByClassname(iBuilding, "obj_*")) > MaxClients)
				{
					bool bLinked = false;
					if (GetEntProp(iBuilding, Prop_Send, "m_iTeamNum") != iTeam)
					{
						float vecTargetOrigin[3];
						GetEntPropVector(iBuilding, Prop_Send, "m_vecOrigin", vecTargetOrigin);
						if (GetVectorDistance(vecOrigin, vecTargetOrigin) <= flRadius)
						{
							bLinked = true;
							if (g_flGhostHealStartTime[iClient][iBuilding] == 0.0)
							{
								g_flGhostHealStartTime[iClient][iBuilding] = GetGameTime();
								
								char sClassname[32];
								GetEntityClassname(iBuilding, sClassname, sizeof(sClassname));
								
								//Teleporters are tiny, so the beam must be down low
								if (StrEqual(sClassname, "obj_teleporter"))
									vecTargetOrigin[2] += 5.0;
								else
									vecTargetOrigin[2] += 42.0;
									
								float vecTargetAngles[3];
								GetClientAbsAngles(iClient, vecTargetAngles);
								g_iGhostParticleBeam[iClient][iBuilding] = TF2_SpawnParticle(sParticle[iTeam], vecTargetOrigin, vecTargetAngles, true, iBuilding, EntRefToEntIndex(g_iGhostParticleCentre[iClient]));
							}
								
							float flTimeGap = GetGameTime() - g_flGhostHealStartTime[iClient][iBuilding];
								
							int iExpectedSteal = RoundToCeil(flTimeGap * flHealSteal);
							if (iExpectedSteal > g_iGhostHealStealCount[iClient][iBuilding])
							{
								float flDamage = (float(iExpectedSteal - g_iGhostHealStealCount[iClient][iBuilding]) * this.flBuildingDrain);
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
			
			//Random Spook effects, 1.5 sec cooldown
			if (g_flGhostLastSpookTime[iClient] < GetGameTime() - 1.5)
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
					this.CallFunction("GetSoundAbility", sSound, sizeof(sSound), "CRageGhost");
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
				
				//Other random effects
				for (int i = 0; i < iLength; i++)
				{
					bool bEffectDone = false;
					
					//Attempt use random slot
					if (GetRandomInt(0, 1))
					{
						ArrayList aWeapons = new ArrayList();
						int iActiveWepon = GetEntPropEnt(iSpooked[i], Prop_Send, "m_hActiveWeapon");
						
						//We don't want to count PDA2 due to invis watch
						for (int iSlot = 0; iSlot <= WeaponSlot_PDADisguise; iSlot++)
						{
							int iWeapon = GetPlayerWeaponSlot(iSpooked[i], iSlot);
							if (IsValidEdict(iWeapon) && iWeapon != iActiveWepon)
								aWeapons.Push(iWeapon);
						}
						
						if (aWeapons.Length > 0)
						{
							//Get random weapon/slot to change
							aWeapons.Sort(Sort_Random, Sort_Integer);
							char sClassname[256];
							GetEntityClassname(aWeapons.Get(0), sClassname, sizeof(sClassname));
							FakeClientCommand(iSpooked[i], "use %s", sClassname);
							bEffectDone = true;
						}
						
						delete aWeapons;
					}
					
					//Random angles
					if (!bEffectDone)
					{
						float vecAngles[3];
						vecAngles[0] = GetRandomFloat(-90.0, 90.0);
						vecAngles[1] = GetRandomFloat(0.0, 360.0);
						
						TeleportEntity(iSpooked[i], NULL_VECTOR, vecAngles, NULL_VECTOR);
					}
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
					if (iEntity <= MaxClients)
						g_iGhostHealGainCount[iClient][iEntity] = 0;
						
					g_iGhostHealStealCount[iClient][iEntity] = 0;
					g_flGhostHealStartTime[iClient][iEntity] = 0.0;
					Timer_EntityCleanup(null, g_iGhostParticleBeam[iClient][iEntity]);
				}
			}
			
			//Update model
			ApplyBossModel(this.iClient);
			
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
			AcceptEntityInput(this.iClient, "SetForcedTauntCam");
		}
	}
	
	public void OnButton(int &buttons)
	{
		//Don't allow him to attack during rage
		if (g_bGhostEnable[this.iClient] && buttons & IN_ATTACK)
			buttons &= ~IN_ATTACK;
	}
	
	public void OnPlayerKilled(Event event)
	{
		//Purely cosmetic effect, but let's add a cool little icon for killing with the rage
		if (g_bGhostEnable[this.iClient])
		{
			event.SetString("weapon_logclassname", "purgatory");
			event.SetString("weapon", "purgatory");
		}
	}
	
	public void Destroy()
	{
		SetEntProp(this.iClient, Prop_Data, "m_takedamage", DAMAGE_YES);
	}
	
	public void Precache()
	{
		PrecacheModel(GHOST_MODEL);
		PrecacheParticleSystem(PARTICLE_BEAM_RED);
		PrecacheParticleSystem(PARTICLE_BEAM_BLU);
	}
};
