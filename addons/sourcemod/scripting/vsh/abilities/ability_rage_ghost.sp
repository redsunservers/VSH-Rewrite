#define GHOST_MODEL	"models/props_halloween/ghost.mdl"
#define GHOST_BEAM_BLU	"medicgun_beam_blue_muzzle"
#define GHOST_BEAM_RED	"medicgun_beam_red_muzzle"

static float g_flGhostRadius[TF_MAXPLAYERS+1];
static float g_flGhostDuration[TF_MAXPLAYERS+1];
static float g_flGhostLastSpookTime[TF_MAXPLAYERS+1];
static bool g_bGhostEnable[TF_MAXPLAYERS+1];
static int g_iGhostBeamEffect[TF_MAXPLAYERS+1][TF_MAXPLAYERS+1];

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
		
		g_bGhostEnable[ability.iClient] = false;
		g_flGhostLastSpookTime[ability.iClient] = 0.0;
		
		for (int iVictim = 1; iVictim <= TF_MAXPLAYERS; iVictim++)
			g_iGhostBeamEffect[ability.iClient][iVictim] = 0;
		
		//TODO precache on map start instead of when boss spawns
		PrecacheModel(GHOST_MODEL);
		PrecacheParticleSystem(GHOST_BEAM_BLU);
		PrecacheParticleSystem(GHOST_BEAM_RED);
	}
	
	public void OnRage()
	{
		int iClient = this.iClient;
		
		g_bGhostEnable[iClient] = true;
		SetEntProp(iClient, Prop_Data, "m_takedamage", DAMAGE_NO);
		
		//Update model
		ApplyBossModel(this.iClient);
		
		//Create particle
		int iParticle = TF2_SpawnParticle(iClient, PARTICLE_GHOST);
		CreateTimer(3.0, Timer_EntityCleanup, EntIndexToEntRef(iParticle));
		
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
			float vecPos[3], vecTargetPos[3];
			GetClientAbsOrigin(iClient, vecPos);
			int iTeam = GetClientTeam(iClient);
			
			for (int iVictim = 1; iVictim <= MaxClients; iVictim++)
			{
				if (SaxtonHale_IsValidAttack(iVictim) && IsPlayerAlive(iVictim))
				{
					GetClientAbsOrigin(iVictim, vecTargetPos);
					if (GetVectorDistance(vecPos, vecTargetPos) <= this.flRadius)
					{
						int iParticle = EntRefToEntIndex(g_iGhostBeamEffect[iClient][iVictim]);
						
						if (!IsValidEdict(iParticle))
						{
							//Victim just got spooked
							iParticle = TF2_SpawnParticle(iVictim, (iTeam == TFTeam_Blue) ? GHOST_BEAM_BLU : GHOST_BEAM_RED);
							g_iGhostBeamEffect[iClient][iVictim] = EntIndexToEntRef(iParticle);
						}
					}
				}
			}
			
			//Random Spook effects, 1.5 sec cooldown
			if (g_flGhostLastSpookTime[iClient] < GetGameTime() - 1.5)
			{
				g_flGhostLastSpookTime[iClient] = GetGameTime();
				
				ArrayList aVictims = new ArrayList();
				
				for (int iVictim = 1; iVictim <= MaxClients; iVictim++)
				{
					if (SaxtonHale_IsValidAttack(iVictim) && IsPlayerAlive(iVictim))
					{
						GetClientAbsOrigin(iVictim, vecTargetPos);
						if (GetVectorDistance(vecPos, vecTargetPos) <= this.flRadius)
							aVictims.Push(iVictim);
					}
				}
				
				if (aVictims.Length == 0)
				{
					delete aVictims;
					return;
				}
				
				SortADTArray(aVictims, Sort_Random, Sort_Integer);
				
				//Visual/Sound effects
				for (int i = 0; i < aVictims.Length; i++)
				{
					Handle hFade = StartMessageOne("Fade", aVictims.Get(i));
					BfWriteShort(hFade, 2000);	//Fade duration
					BfWriteShort(hFade, 0);
					BfWriteShort(hFade, 0x0001);
					BfWriteByte(hFade, 255);	//Red
					BfWriteByte(hFade, 0);		//Green
					BfWriteByte(hFade, 255);	//Blue
					BfWriteByte(hFade, 160);	//Alpha
					EndMessage();
					
					char sSound[PLATFORM_MAX_PATH];
					this.CallFunction("GetSoundAbility", "CRageGhost", sSound, sizeof(sSound));
					if (!StrEmpty(sSound))
						EmitSoundToClient(iClient, sSound, _, SNDCHAN_VOICE, SNDLEVEL_SCREAMING);
				}
				
				//Random teleports
				if (aVictims.Length >= 2 && !GetRandomInt(0, 2))
				{
					int iTeleport[2];
					iTeleport[0] = aVictims.Get(0);
					iTeleport[1] = aVictims.Get(1);
					TF2_TeleportSwap(iTeleport);
					aVictims.Erase(1);
					aVictims.Erase(0);
				}
				
				//Other random effects
				for (int i = 0; i < aVictims.Length; i++)
				{
					int iVictim = aVictims.Get(i);
					bool bEffectDone = false;
					
					//Attempt use random slot
					if (GetRandomInt(0, 1))
					{
						ArrayList aWeapons = new ArrayList();
						int iActiveWepon = GetEntPropEnt(iVictim, Prop_Send, "m_hActiveWeapon");
						
						//We don't want to count PDA2 due to invis watch
						for (int iSlot = 0; iSlot <= WeaponSlot_PDADisguise; iSlot++)
						{
							int iWeapon = GetPlayerWeaponSlot(iVictim, iSlot);
							if (IsValidEdict(iWeapon) && iWeapon != iActiveWepon)
								aWeapons.Push(iWeapon);
						}
						
						if (aWeapons.Length > 0)
						{
							//Get random weapon/slot to change
							SortADTArray(aWeapons, Sort_Random, Sort_Integer);
							char sClassname[256];
							GetEntityClassname(aWeapons.Get(0), sClassname, sizeof(sClassname));
							FakeClientCommand(iVictim, "use %s", sClassname);
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
						
						TeleportEntity(iVictim, NULL_VECTOR, vecAngles, NULL_VECTOR);
					}
				}
				
				delete aVictims;
			}
		}
		else
		{
			//Rage ended
			g_bGhostEnable[iClient] = false;
			SetEntProp(iClient, Prop_Data, "m_takedamage", DAMAGE_YES);
			
			for (int iVictim = 1; iVictim <= MaxClients; iVictim++)
			{
				int iParticle = EntRefToEntIndex(g_iGhostBeamEffect[iClient][iVictim]);
				if (IsValidEdict(iParticle))
					CreateTimer(0.0, Timer_EntityCleanup, g_iGhostBeamEffect[iClient][iVictim]);
				
				g_iGhostBeamEffect[iClient][iVictim] = 0;
			}
			
			//Update model
			ApplyBossModel(this.iClient);
			
			//Create particle
			int iParticle = TF2_SpawnParticle(iClient, PARTICLE_GHOST);
			CreateTimer(3.0, Timer_EntityCleanup, EntIndexToEntRef(iParticle));
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