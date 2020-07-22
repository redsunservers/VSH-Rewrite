#define BOMBPROJECTILE_MODEL	"models/props_lakeside_event/bomb_temp.mdl"

static float g_flBombProjectileNext[TF_MAXPLAYERS+1];
static float g_flBombProjectileEnd[TF_MAXPLAYERS+1];
static float g_flBombProjectileRate[TF_MAXPLAYERS+1];
static float g_flBombProjectileDuration[TF_MAXPLAYERS+1];
static float g_flBombProjectileMaxDistance[TF_MAXPLAYERS+1];
static float g_flBombProjectileHeight[TF_MAXPLAYERS+1];
static float g_flPreviousSpeed[TF_MAXPLAYERS+1];
static float g_flNewSpeed[TF_MAXPLAYERS+1];

methodmap CRageGas < SaxtonHaleBase
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
	
	property float flNewSpeed
	{
		public set (float flVal)
		{
			g_flNewSpeed[this.iClient] = flVal;
		}
		public get()
		{
			return g_flNewSpeed[this.iClient];
		}
	}
	
	property float flMaxDistance
	{
		public set (float flVal)
		{
			g_flBombProjectileMaxDistance[this.iClient] = flVal;
		}
		public get()
		{
			return g_flBombProjectileMaxDistance[this.iClient];
		}
	}
	
	property float flHeight
	{
		public set (float flVal)
		{
			g_flBombProjectileHeight[this.iClient] = flVal;
		}
		public get()
		{
			return g_flBombProjectileHeight[this.iClient];
		}
	}
		
	public CRageGas(CRageGas ability)
	{
		g_flBombProjectileNext[ability.iClient] = 0.0;
		g_flBombProjectileEnd[ability.iClient] = 0.0;
		
		ability.flRate = 2.5;
		ability.flDuration = 8.0;
		ability.flMaxDistance = 600.0;
		ability.flHeight = 700.0;
	}

	public void OnRage()
	{
		g_flBombProjectileNext[this.iClient] = GetGameTime();
		g_flBombProjectileEnd[this.iClient] = GetGameTime() + this.flDuration;
		g_flPreviousSpeed[this.iClient] = this.flSpeed;
		TF2_AddCondition(this.iClient, TFCond_SpeedBuffAlly, this.flDuration, this.iClient);
		this.flSpeed *= 1.2;
		if(this.bSuperRage)
		{
			TF2_AddCondition(this.iClient, TFCond_TeleportedGlow, this.flDuration, this.iClient);
			this.flSpeed *= 1.2;
		}
	}
	
	public void OnThink()
	{
		if (g_flBombProjectileEnd[this.iClient] == 0.0)
			return;
		
		float flGameTime = GetGameTime();
		if (flGameTime <= g_flBombProjectileEnd[this.iClient])
		{
			if (g_flBombProjectileNext[this.iClient] > flGameTime) return;
		
			if (this.bSuperRage)
				g_flBombProjectileNext[this.iClient] = flGameTime + (this.flRate / 1.5);
			else
				g_flBombProjectileNext[this.iClient] = flGameTime + this.flRate;
			
			float vecOrigin[3], vecVelocity[3], vecAngleVelocity[3];
			GetClientAbsOrigin(this.iClient, vecOrigin);
			vecOrigin[2] += 42.0;
			
			for (int i = 0; i < 8; i++)
			{
				int iBomb = CreateEntityByName("tf_projectile_jar_gas");
				if (iBomb > MaxClients)
				{
					//Create random velocity, but keep it upwards
					switch (i)
					{
						case 0:
						{
							vecVelocity[0] = this.flMaxDistance;
							vecVelocity[1] = this.flMaxDistance;
						}
						case 1:
						{
							vecVelocity[0] = -this.flMaxDistance;
							vecVelocity[1] = this.flMaxDistance;
						}
						case 2:
						{
							vecVelocity[0] = this.flMaxDistance;
							vecVelocity[1] = -this.flMaxDistance;
						}
						case 3:
						{
							vecVelocity[0] = -this.flMaxDistance;
							vecVelocity[1] = -this.flMaxDistance;
						}
						case 4:
						{
							vecVelocity[0] = this.flMaxDistance;
							vecVelocity[1] = 0.0;
						}
						case 5:
						{
							vecVelocity[0] = -this.flMaxDistance;
							vecVelocity[1] = 0.0;
						}
						case 6:
						{
							vecVelocity[0] = 0.0;
							vecVelocity[1] = this.flMaxDistance;
						}
						case 7:
						{
							vecVelocity[0] = 0.0;
							vecVelocity[1] = -this.flMaxDistance;
						}
					}
					
					vecVelocity[2] = this.flHeight;
				
					//Create random angle velocity
					for (int j = 0; j < 3; j++)
						vecAngleVelocity[j] = GetRandomFloat(0.0, 360.0);
						
					SetEntProp(iBomb, Prop_Send, "m_iTeamNum", GetClientTeam(this.iClient));
					SetEntPropEnt(iBomb, Prop_Send, "m_hOwnerEntity", this.iClient);
					
					DispatchSpawn(iBomb);
					
					TeleportEntity(iBomb, vecOrigin, vecAngleVelocity, vecVelocity);
					
					SetEntProp(iBomb, Prop_Send, "m_CollisionGroup", 24);
				}
			}
		}
		else
		{
			g_flBombProjectileEnd[this.iClient] = 0.0;
			this.flSpeed = g_flPreviousSpeed[this.iClient];
		}
	}
};