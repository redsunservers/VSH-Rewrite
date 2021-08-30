#define IMPACT_SOUND "player/taunt_yeti_land.wav"
#define IMPACT_PARTICLE "hammer_impact_button"

static float g_flImpactRadius[TF_MAXPLAYERS];
static float g_flImpactDamage[TF_MAXPLAYERS];
static float flImpactLaunchVelocity[TF_MAXPLAYERS];

methodmap CGroundPound < SaxtonHaleBase
{
	property float flImpactRadius
	{
		public set(float flVal)
		{
			g_flImpactRadius[this.iClient] = flVal;
		}
		public get()
		{
			return g_flImpactRadius[this.iClient];
		}
	}
	
	property float flImpactDamage
	{
		public set(float flVal)
		{
			g_flImpactDamage[this.iClient] = flVal;
		}
		public get()
		{
			return g_flImpactDamage[this.iClient];
		}
	}
	
	property float flImpactLaunchVelocity
	{
		public set(float flVal)
		{
			flImpactLaunchVelocity[this.iClient] = flVal;
		}
		public get()
		{
			return flImpactLaunchVelocity[this.iClient];
		}
	}
	
	public CGroundPound(CGroundPound ability)
	{
		ability.flImpactRadius = 500.0;
		ability.flImpactDamage = 50.0;
		ability.flImpactLaunchVelocity = 650.0;
	}
	
	public Action OnTakeDamage(int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
	{
		if (!(damagetype & DMG_FALL))
			return Plugin_Continue;
		
		float vecBossOrigin[3];
		GetClientAbsOrigin(this.iClient, vecBossOrigin);
		
		EmitAmbientSound(IMPACT_SOUND, vecBossOrigin, _, SNDLEVEL_SCREAMING);
		TF2_Shake(vecBossOrigin, 10.0, this.flImpactRadius, 1.0, 0.5);
		TF2_SpawnParticle(IMPACT_PARTICLE, vecBossOrigin);
		
		for (int iClient = 1; iClient <= MaxClients; iClient++)
		{
			if (IsClientInGame(iClient) && GetClientTeam(iClient) != GetClientTeam(this.iClient) && IsClientInRange(iClient, vecBossOrigin, this.flImpactRadius) && GetEntityFlags(iClient) & FL_ONGROUND)
			{
				float vecClientVelocity[3];
				GetEntPropVector(iClient, Prop_Data, "m_vecVelocity", vecClientVelocity);
				vecClientVelocity[2] += this.flImpactLaunchVelocity;
				
				TeleportEntity(iClient, NULL_VECTOR, NULL_VECTOR, vecClientVelocity);
				SDKHooks_TakeDamage(iClient, this.iClient, this.iClient, this.flImpactDamage);
			}
		}
		
		return Plugin_Continue;
	}
	
	public void Precache()
	{
		PrecacheSound(IMPACT_SOUND);
		PrecacheParticleSystem(IMPACT_PARTICLE);
	}
};
