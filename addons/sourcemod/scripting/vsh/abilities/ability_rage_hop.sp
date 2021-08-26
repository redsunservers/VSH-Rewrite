#define ATTRIB_PUSHRESISTANCE	252
#define ATTRIB_AIRCONTROL 		610

static float g_flJumpPower[TF_MAXPLAYERS];
static float g_flRageHopMaxHeight[TF_MAXPLAYERS];
static float g_flRageHopMaxDistance[TF_MAXPLAYERS];
static float g_flBombDamage[TF_MAXPLAYERS];
static float g_flBombRadius[TF_MAXPLAYERS];
static float g_flHopEndTime[TF_MAXPLAYERS];
static bool g_bStompEnabled[TF_MAXPLAYERS];
static float g_flDuration[TF_MAXPLAYERS];
static float g_vecPeakVel[TF_MAXPLAYERS];

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
		ability.flRageHopMaxHeight = 500.0;
		ability.flRageHopMaxDistance = 1.2;
		
		ability.flBombDamage = 23.0;
		ability.flBombRadius = 275.0;
		
		ability.flDuration = 8.0;
	}
	
	public void OnThink()
	{
		if (GameRules_GetRoundState() == RoundState_Preround) return;
		if (!IsPlayerAlive(this.iClient)) return;
		
		float vecPeakVel[3];
		GetEntPropVector(this.iClient, Prop_Data, "m_vecVelocity", vecPeakVel);
		
		if(vecPeakVel[2] < g_vecPeakVel[this.iClient])
			g_vecPeakVel[this.iClient] = vecPeakVel[2];
		
		if (g_bStompEnabled[this.iClient])
		{
			
			float vecExplosionOrigin[3];
			GetClientAbsOrigin(this.iClient, vecExplosionOrigin);
			
			char sSound[PLATFORM_MAX_PATH];
			Format(sSound, sizeof(sSound), "weapons/airstrike_small_explosion_0%i.wav", GetRandomInt(1,3));
			
			float flBombRadiusValue = this.flBombRadius;
			//Calculate velocity and apply damage multiplier
			float flFinalBombDamage = (g_vecPeakVel[this.iClient] + 110.0) / 100.0 * -this.flBombDamage;
			if (flFinalBombDamage < 30.0) flFinalBombDamage = 30.0;
			if (flFinalBombDamage > 140.0) flFinalBombDamage = 140.0;
			
			if (this.bSuperRage)
			{
				flBombRadiusValue *= 1.25;
				flFinalBombDamage *= 1.25;
			}
			
			TF2_Explode(this.iClient, vecExplosionOrigin, flFinalBombDamage, flBombRadiusValue, "heavy_ring_of_fire", sSound);
			
			g_vecPeakVel[this.iClient] = 0.0;
			g_bStompEnabled[this.iClient] = false;
		}
		
		if (g_flHopEndTime[this.iClient] > GetGameTime() && (GetEntityFlags(this.iClient) & FL_ONGROUND) && !g_bStompEnabled[this.iClient])
		{
			float vecVel[3];
			GetEntPropVector(this.iClient, Prop_Data, "m_vecVelocity", vecVel);
			
			vecVel[0] *= this.flRageHopMaxDistance;
			vecVel[1] *= this.flRageHopMaxDistance;
			vecVel[2] = this.flRageHopMaxHeight;
			SetEntProp(this.iClient, Prop_Send, "m_bJumping", true);
			
			TeleportEntity(this.iClient, NULL_VECTOR, NULL_VECTOR, vecVel);
			
			g_bStompEnabled[this.iClient] = true;
		}
		else if (g_flHopEndTime[this.iClient] < GetGameTime())
		{
			TF2Attrib_RemoveByDefIndex(this.iClient, ATTRIB_AIRCONTROL);
		}
	}
	
	public void OnRage()
	{
		if (this.bSuperRage)
		{
			g_flHopEndTime[this.iClient] = GetGameTime() + g_flDuration[this.iClient] * 1.5;
			//Give defense buff (no crits block) and knockback immunity
			TF2_AddCondition(this.iClient, TFCond_DefenseBuffNoCritBlock, g_flDuration[this.iClient] * 1.5);
			TF2_AddCondition(this.iClient, TFCond_MegaHeal, g_flDuration[this.iClient] * 1.5);
		}
		else
		{
			g_flHopEndTime[this.iClient] = GetGameTime() + g_flDuration[this.iClient];
			TF2_AddCondition(this.iClient, TFCond_DefenseBuffNoCritBlock, g_flDuration[this.iClient]);
			TF2_AddCondition(this.iClient, TFCond_MegaHeal, g_flDuration[this.iClient]);
		}
		
		TF2Attrib_SetByDefIndex(this.iClient, ATTRIB_AIRCONTROL, 8.0);
		g_vecPeakVel[this.iClient] = 0.0;
		
		char sSound[PLATFORM_MAX_PATH];
		this.CallFunction("GetSoundAbility", sSound, sizeof(sSound), "CRageHop");
		if (!StrEmpty(sSound))
			EmitSoundToAll(sSound, this.iClient, SNDCHAN_VOICE, SNDLEVEL_SCREAMING);
	}
};
