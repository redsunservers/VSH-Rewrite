#define GHOST_MODEL	"models/props_halloween/ghost.mdl"

#define PARTICLE_BEAM_BLU	"medicgun_beam_blue"
#define PARTICLE_BEAM_RED	"medicgun_beam_red"

static float g_flGhostRadius[TF_MAXPLAYERS+1];
static float g_flGhostDuration[TF_MAXPLAYERS+1];
static float g_flGhostHealSteal[TF_MAXPLAYERS+1];
static float g_flGhostHealGain[TF_MAXPLAYERS+1];

static float g_flGhostHealStartTime[TF_MAXPLAYERS+1][TF_MAXPLAYERS+1];
static int g_iGhostHealStealCount[TF_MAXPLAYERS+1][TF_MAXPLAYERS+1];
static int g_iGhostHealGainCount[TF_MAXPLAYERS+1][TF_MAXPLAYERS+1];

static float g_flGhostLastSpookTime[TF_MAXPLAYERS+1];

static bool g_bGhostEnable[TF_MAXPLAYERS+1];

static int g_iGhostParticleBeam[TF_MAXPLAYERS+1][TF_MAXPLAYERS+1];
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
		ability.flDuration = 5.0;
		ability.flHealSteal = 20.0;	//Steals hp per second
		ability.flHealGain = 40.0;	//Gains hp per second
		
		g_bGhostEnable[ability.iClient] = false;
		g_flGhostLastSpookTime[ability.iClient] = 0.0;
		
		for (int iVictim = 1; iVictim <= TF_MAXPLAYERS; iVictim++)
			g_iGhostParticleBeam[ability.iClient][iVictim] = 0;
		
		//TODO precache on map start instead of when boss spawns
		PrecacheModel(GHOST_MODEL);
		PrecacheParticleSystem(PARTICLE_BEAM_RED);
		PrecacheParticleSystem(PARTICLE_BEAM_BLU);
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
		
		//Stun
		float flDuration = this.flDuration * (this.bSuperRage ? 2 : 1);
		TF2_StunPlayer(iClient, flDuration, 0.0, TF_STUNFLAGS_GHOSTSCARE|TF_STUNFLAG_NOSOUNDOREFFECT, 0);
		/*
		//Thirdperson
		int iFlags = GetCommandFlags("thirdperson");
		SetCommandFlags("thirdperson", iFlags & (~FCVAR_CHEAT));
		ClientCommand(this.iClient, "thirdperson");
		SetCommandFlags("thirdperson", iFlags);
		*/
	}
	
	public void OnThink()
	{
		int iClient = this.iClient;
		if (!g_bGhostEnable[iClient]) return;
		
		float flDuration = this.flDuration * (this.bSuperRage ? 2 : 1);
		if (flDuration > GetGameTime() - this.flRageLastTime)
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
			
			for (int iVictim = 1; iVictim <= MaxClients; iVictim++)
			{
				bool bSpook = false;
				
				if (SaxtonHale_IsValidAttack(iVictim) && IsPlayerAlive(iVictim))
				{
					float vecTargetOrigin[3];
					GetClientAbsOrigin(iVictim, vecTargetOrigin);
					if (GetVectorDistance(vecOrigin, vecTargetOrigin) <= this.flRadius)
					{
						//Victim got spooked
						bSpook = true;
						iSpooked[iLength] = iVictim;
						iLength++;
						
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
						
						int iExpectedSteal = RoundToCeil(flTimeGap * this.flHealSteal);
						if (iExpectedSteal > g_iGhostHealStealCount[iClient][iVictim])
						{
							float flDamage = float(iExpectedSteal - g_iGhostHealStealCount[iClient][iVictim]);
							SDKHooks_TakeDamage(iVictim, iClient, iClient, flDamage, DMG_PREVENT_PHYSICS_FORCE);
							g_iGhostHealStealCount[iClient][iVictim] = iExpectedSteal;
						}
						
						int iExpectedGain = RoundToCeil(flTimeGap * this.flHealGain);
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
					BfWrite bf = UserMessageToBfWrite(StartMessageOne("Fade", iSpooked[i]));
					bf.WriteShort(2000);	//Fade duration
					bf.WriteShort(0);
					bf.WriteShort(0x0001);
					bf.WriteByte(255);		//Red
					bf.WriteByte(0);		//Green
					bf.WriteByte(255);		//Blue
					bf.WriteByte(160);		//Alpha
					EndMessage();
					
					char sSound[PLATFORM_MAX_PATH];
					this.CallFunction("GetSoundAbility", "CRageGhost", sSound, sizeof(sSound));
					if (!StrEmpty(sSound))
						EmitSoundToClient(iClient, sSound, _, SNDCHAN_VOICE, SNDLEVEL_SCREAMING);
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
							SortADTArray(aWeapons, Sort_Random, Sort_Integer);
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
			for (int iVictim = 1; iVictim <= MaxClients; iVictim++)
			{
				g_flGhostHealStartTime[iClient][iVictim] = 0.0;
				g_iGhostHealStealCount[iClient][iVictim] = 0;
				g_iGhostHealGainCount[iClient][iVictim] = 0;
				Timer_EntityCleanup(null, g_iGhostParticleBeam[iClient][iVictim]);
			}
			
			//Update model
			ApplyBossModel(this.iClient);
			
			//Create poof particle
			float vecOrigin[3];
			GetClientAbsOrigin(iClient, vecOrigin);
			CreateTimer(3.0, Timer_EntityCleanup, TF2_SpawnParticle(PARTICLE_GHOST, vecOrigin));
			/*
			//Firstperson
			int iFlags = GetCommandFlags("firstperson");
			SetCommandFlags("firstperson", iFlags & (~FCVAR_CHEAT));
			ClientCommand(iClient, "firstperson");
			SetCommandFlags("firstperson", iFlags);
			*/
		}
	}
	
	public void Destroy()
	{
		SetEntProp(this.iClient, Prop_Data, "m_takedamage", DAMAGE_YES);
	}
};