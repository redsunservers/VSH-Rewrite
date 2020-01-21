static int g_iRageHopMaxCharge[TF_MAXPLAYERS+1];
static float g_flRageHopMaxHeight[TF_MAXPLAYERS+1];
static float g_flRageHopMaxDistance[TF_MAXPLAYERS+1];
static float g_flBombDamage[TF_MAXPLAYERS+1];
static float g_flBombRadius[TF_MAXPLAYERS+1];
static float g_flFloatEndTime[TF_MAXPLAYERS+1];
static bool g_bStompEnabled[TF_MAXPLAYERS+1];
static float g_flDuration[TF_MAXPLAYERS+1];
static float g_flDurationSuper[TF_MAXPLAYERS+1];

methodmap CRageHop < SaxtonHaleBase
{
	property float flDuration
	{
		public get()
		{
			return g_flDuration[this.iClient];
		}
		public set(float val)
		{
			g_flDuration[this.iClient] = val;
		}
	}
	
	property float flDurationSuper
	{
		public get()
		{
			return g_flDurationSuper[this.iClient];
		}
		public set(float val)
		{
			g_flDurationSuper[this.iClient] = val;
		}
	}
	
	property int iMaxJumpCharge
	{
		public get()
		{
			return g_iRageHopMaxCharge[this.iClient];
		}
		public set(int val)
		{
			g_iRageHopMaxCharge[this.iClient] = val;
		}
	}
	
	property float flMaxHeight
	{
		public get()
		{
			return g_flRageHopMaxHeight[this.iClient];
		}
		public set(float val)
		{
			g_flRageHopMaxHeight[this.iClient] = val;
		}
	}
	
	property float flMaxDistance
	{
		public get()
		{
			return g_flRageHopMaxDistance[this.iClient];
		}
		public set(float val)
		{
			g_flRageHopMaxDistance[this.iClient] = val;
		}
	}
	
	property float flBombDamage
	{
		public get()
		{
			return g_flBombDamage[this.iClient];
		}
		public set(float val)
		{
			g_flBombDamage[this.iClient] = val;
		}
	}
	
		property float flBombRadius
	{
		public get()
		{
			return g_flBombRadius[this.iClient];
		}
		public set(float val)
		{
			g_flBombRadius[this.iClient] = val;
		}
	}
	
	public CRageHop(CRageHop ability)
	{
		//Default values, these can be changed if needed
		ability.iMaxJumpCharge = 1200;
		ability.flMaxHeight = 600.0;
		ability.flMaxDistance = 4.5;
		
		ability.flBombDamage = 10.0;
		ability.flBombRadius = 200.0;
		
		ability.flDuration = 45.0;
		ability.flDurationSuper = 16.0;
		
	}
	
	public void OnThink()
	{
		if (GameRules_GetRoundState() == RoundState_Preround) return;
		if (!IsPlayerAlive(this.iClient)) return;
		
		int iTeam = GetClientTeam(this.iClient);
		
		if(g_bStompEnabled[this.iClient])
		{
			float vecExplosionPos[3], vecExplosionOrigin[3];
			GetClientAbsOrigin(this.iClient, vecExplosionOrigin);
			
			vecExplosionPos = vecExplosionOrigin;
			
			char sSound[255];
			Format(sSound, sizeof(sSound), "weapons/airstrike_small_explosion_0%i.wav", GetRandomInt(1,3));
			TF2_Explode(this.iClient, vecExplosionPos, this.flBombDamage, this.flBombRadius, "heavy_ring_of_fire", sSound);
			
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) > 1 && GetClientTeam(i) != iTeam)
				{
					float vecTargetPos[3];
					GetClientAbsOrigin(i, vecTargetPos);
					
					if (GetVectorDistance(vecExplosionOrigin, vecTargetPos) < 200.0)
					{
						TF2_IgnitePlayer(i, this.iClient);
						TF2_AddCondition(i, TFCond_Gas, 10.0, this.iClient);
					}
				}
				
			}
			
			g_bStompEnabled[this.iClient] = false;
		}
		if (g_flFloatEndTime[this.iClient] > GetGameTime() && (GetEntityFlags(this.iClient) & FL_ONGROUND) && !g_bStompEnabled[this.iClient])
		{
			float vecVel[3];
			GetEntPropVector(this.iClient, Prop_Data, "m_vecVelocity", vecVel);
			
			vecVel[2] = 500.0;
			vecVel[0] *= (1.0+Sine((float(600)/float(this.iMaxJumpCharge)) * FLOAT_PI * this.flMaxDistance));
			vecVel[1] *= (1.0+Sine((float(600)/float(this.iMaxJumpCharge)) * FLOAT_PI * this.flMaxDistance));
			SetEntProp(this.iClient, Prop_Send, "m_bJumping", true);
			
			TeleportEntity(this.iClient, NULL_VECTOR, NULL_VECTOR, vecVel);
			
			g_bStompEnabled[this.iClient] = true;
		}
		else
		{
		int iWeapon = GetPlayerWeaponSlot(this.iClient, WeaponSlot_Primary);
		TF2Attrib_SetByName(iWeapon, "damage force reduction", 0.5);
		}
	}
	
	public void OnRage()
	{
		if(this.bSuperRage)
			g_flFloatEndTime[this.iClient] = GetGameTime() + g_flDurationSuper[this.iClient];
		else
			g_flFloatEndTime[this.iClient] = GetGameTime() + g_flDuration[this.iClient];
		
		char sSound[PLATFORM_MAX_PATH];
		this.CallFunction("GetSoundAbility", sSound, sizeof(sSound), "CRageHop");
		if (!StrEmpty(sSound))
		EmitSoundToAll(sSound, this.iClient, SNDCHAN_VOICE, SNDLEVEL_SCREAMING);
		
		int iWeapon = GetPlayerWeaponSlot(this.iClient, WeaponSlot_Primary);
		TF2Attrib_SetByName(iWeapon, "damage force reduction", 0.0);
	}
};
