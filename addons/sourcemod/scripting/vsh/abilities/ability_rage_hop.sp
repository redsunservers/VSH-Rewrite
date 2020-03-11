#define ATTRIB_PUSHRESISTANCE	252

static float g_flJumpPower[TF_MAXPLAYERS+1];
static float g_flRageHopMaxHeight[TF_MAXPLAYERS+1];
static float g_flRageHopMaxDistance[TF_MAXPLAYERS+1];
static float g_flBombDamage[TF_MAXPLAYERS+1];
static float g_flBombRadius[TF_MAXPLAYERS+1];
static float g_flHopEndTime[TF_MAXPLAYERS+1];
static bool g_bStompEnabled[TF_MAXPLAYERS+1];
static float g_flDuration[TF_MAXPLAYERS+1];

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
	
	property float flJumpPower
	{
		public get()
		{
			return g_flJumpPower[this.iClient];
		}
		public set(float val)
		{
			g_flJumpPower[this.iClient] = val;
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
	
	property float flRageHopMaxDistance
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
	
	property float flRageHopMaxHeight
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
	
	public CRageHop(CRageHop ability)
	{
		
		g_flHopEndTime[ability.iClient] = 0.0;
		g_bStompEnabled[ability.iClient] = false;
		
		//Default values, these can be changed if needed
		ability.flJumpPower = 0.5;
		
		ability.flRageHopMaxHeight = 500.0;
		ability.flRageHopMaxDistance = 4.5;
		
		ability.flBombDamage = 50.0;
		ability.flBombRadius = 225.0;
		
		ability.flDuration = 10.0;
	}
	
	public void OnThink()
	{
		if (GameRules_GetRoundState() == RoundState_Preround) return;
		if (!IsPlayerAlive(this.iClient)) return;
		
		int iTeam = GetClientTeam(this.iClient);
		
		if (g_bStompEnabled[this.iClient])
		{
			float vecExplosionOrigin[3];
			GetClientAbsOrigin(this.iClient, vecExplosionOrigin);
			
			char sSound[PLATFORM_MAX_PATH];
			Format(sSound, sizeof(sSound), "weapons/airstrike_small_explosion_0%i.wav", GetRandomInt(1,3));
			
			float flBombRadiusValue = this.flBombRadius;
			if(this.bSuperRage)
			{
				flBombRadiusValue *= 1.25;
				TF2_Explode(this.iClient, vecExplosionOrigin, this.flBombDamage * 1.5, flBombRadiusValue, "heavy_ring_of_fire", sSound);
			}
			else
			{
				TF2_Explode(this.iClient, vecExplosionOrigin, this.flBombDamage, flBombRadiusValue, "heavy_ring_of_fire", sSound);
			}
			
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) > 1 && GetClientTeam(i) != iTeam)
				{
					if (IsClientInRange(i, vecExplosionOrigin, flBombRadiusValue))
					{
						TF2_IgnitePlayer(i, this.iClient);
						TF2_AddCondition(i, TFCond_Gas, 10.0, this.iClient);
					}
				}
				
			}
			
			g_bStompEnabled[this.iClient] = false;
		}
		
		if (g_flHopEndTime[this.iClient] > GetGameTime() && (GetEntityFlags(this.iClient) & FL_ONGROUND) && !g_bStompEnabled[this.iClient])
		{
			float vecVel[3];
			GetEntPropVector(this.iClient, Prop_Data, "m_vecVelocity", vecVel);
			
			vecVel[2] = this.flRageHopMaxHeight;
			vecVel[0] *= (1.0+Sine(this.flJumpPower) * FLOAT_PI * this.flRageHopMaxDistance);
			vecVel[1] *= (1.0+Sine(this.flJumpPower) * FLOAT_PI * this.flRageHopMaxDistance);
			SetEntProp(this.iClient, Prop_Send, "m_bJumping", true);
			
			TeleportEntity(this.iClient, NULL_VECTOR, NULL_VECTOR, vecVel);
			
			g_bStompEnabled[this.iClient] = true;
		}
		else
		{
			int iWeapon = GetPlayerWeaponSlot(this.iClient, WeaponSlot_Primary);
			if (iWeapon > MaxClients)
				TF2Attrib_SetByDefIndex(iWeapon, ATTRIB_PUSHRESISTANCE, 0.5);
		}
	}
	
	public void OnRage()
	{
		if (this.bSuperRage)
			g_flHopEndTime[this.iClient] = GetGameTime() + g_flDuration[this.iClient] * 1.5;
		else
			g_flHopEndTime[this.iClient] = GetGameTime() + g_flDuration[this.iClient];
		
		char sSound[PLATFORM_MAX_PATH];
		this.CallFunction("GetSoundAbility", sSound, sizeof(sSound), "CRageHop");
		if (!StrEmpty(sSound))
			EmitSoundToAll(sSound, this.iClient, SNDCHAN_VOICE, SNDLEVEL_SCREAMING);
		
		int iWeapon = GetPlayerWeaponSlot(this.iClient, WeaponSlot_Primary);
		if (iWeapon > MaxClients)
			TF2Attrib_SetByDefIndex(iWeapon, ATTRIB_PUSHRESISTANCE, 1.0);
	}
};
