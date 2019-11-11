#define BOMBPROJECTILE_MODEL	"models/props_lakeside_event/bomb_temp.mdl"

static float g_flBombProjectileNext[TF_MAXPLAYERS+1];
static float g_flBombProjectileEnd[TF_MAXPLAYERS+1];
static float g_flBombProjectileRate[TF_MAXPLAYERS+1];
static float g_flBombProjectileDuration[TF_MAXPLAYERS+1];
static float g_flBombProjectileRadius[TF_MAXPLAYERS+1];
static float g_flBombProjectileDamage[TF_MAXPLAYERS+1];

methodmap CBombProjectile < SaxtonHaleBase
{
	property float flRate
	{
		public set(float flVal)
		{
			g_flBombProjectileRate[this.iClient] = flVal;
		}
		public get()
		{
			return g_flBombProjectileRate[this.iClient];
		}
	}
	
	property float flDuration
	{
		public set (float flVal)
		{
			g_flBombProjectileDuration[this.iClient] = flVal;
		}
		public get()
		{
			return g_flBombProjectileDuration[this.iClient];
		}
	}
	
	property float flRadius
	{
		public set (float flVal)
		{
			g_flBombProjectileRadius[this.iClient] = flVal;
		}
		public get()
		{
			return g_flBombProjectileRadius[this.iClient];
		}
	}
	
	property float flDamage
	{
		public set (float flVal)
		{
			g_flBombProjectileDamage[this.iClient] = flVal;
		}
		public get()
		{
			return g_flBombProjectileDamage[this.iClient];
		}
	}
	
	property float flMaxDistance
	{
		public set (float flVal)
		{
			g_flBombProjectileDamage[this.iClient] = flVal;
		}
		public get()
		{
			return g_flBombProjectileDamage[this.iClient];
		}
	}
	
	property float flMinHeight
	{
		public set (float flVal)
		{
			g_flBombProjectileDamage[this.iClient] = flVal;
		}
		public get()
		{
			return g_flBombProjectileDamage[this.iClient];
		}
	}
	
	property float flMaxHeight
	{
		public set (float flVal)
		{
			g_flBombProjectileDamage[this.iClient] = flVal;
		}
		public get()
		{
			return g_flBombProjectileDamage[this.iClient];
		}
	}
	
	public CBombProjectile(CBombProjectile ability)
	{
		g_flBombProjectileNext[ability.iClient] = 0.0;
		g_flBombProjectileEnd[ability.iClient] = 0.0;
		
		ability.flRate = 0.2;
		ability.flDuration = 6.0;
		ability.flRadius = 100.0;
		ability.flDamage = 50.0;
		
		PrecacheModel(BOMBPROJECTILE_MODEL);
	}

	public void OnRage()
	{
		g_flBombProjectileNext[this.iClient] = GetGameTime();
		g_flBombProjectileEnd[this.iClient] = GetGameTime() + this.flDuration;
	}
	
	public void OnThink()
	{
		if (g_iOffsetFuseTime <= 0 || g_flBombProjectileEnd[this.iClient] == 0.0) return;
		
		float flGameTime = GetGameTime();
		if (flGameTime <= g_flBombProjectileEnd[this.iClient])
		{
			if (g_flBombProjectileNext[this.iClient] > flGameTime) return;
			
			g_flBombProjectileNext[this.iClient] = flGameTime + this.flRate;
			
			float vecOrigin[3], vecVelocity[3], vecAngleVelocity[3];
			GetClientAbsOrigin(this.iClient, vecOrigin);
			vecOrigin[2] += 42.0;
			
			int iBomb = CreateEntityByName("tf_weaponbase_merasmus_grenade");
			if (iBomb > MaxClients)
			{
				//Create random velocity, but keep it upwards
				for (int i = 0; i < 2; i++)
					vecVelocity[i] = GetRandomFloat(-600.0, 600.0);
				
				vecVelocity[2] = GetRandomFloat(500.0, 1000.0);
				
				//Create random angle velocity
				for (int i = 0; i < 3; i++)
					vecAngleVelocity[i] = GetRandomFloat(-500.0, 500.0);
				
				DispatchKeyValueVector(iBomb, "origin", vecOrigin);
				SetEntityModel(iBomb, BOMBPROJECTILE_MODEL);
				SetEntProp(iBomb, Prop_Send, "m_iTeamNum", GetClientTeam(this.iClient));
				SetEntPropEnt(iBomb, Prop_Send, "m_hThrower", this.iClient);
				SetEntPropEnt(iBomb, Prop_Send, "m_hOwnerEntity", this.iClient);
				
				DispatchSpawn(iBomb);
				
				SDK_AddVelocity(iBomb, vecVelocity, vecAngleVelocity);
				
				SetEntPropFloat(iBomb, Prop_Data, "m_flDamage", this.flDamage);
				SetEntDataFloat(iBomb, g_iOffsetFuseTime, GetGameTime() + 2.0);	//Fuse time
				SetEntProp(iBomb, Prop_Send, "m_CollisionGroup", 24);
			}
		}
		else
		{
			g_flBombProjectileEnd[this.iClient] = 0.0;
		}
	}
	
	public void Precache()
	{
		PrecacheModel(BOMBPROJECTILE_MODEL);
	}
};