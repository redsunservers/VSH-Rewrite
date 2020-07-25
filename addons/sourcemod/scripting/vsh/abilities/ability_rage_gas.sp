static float g_flRageGasNext[TF_MAXPLAYERS+1];
static float g_flRageGasEnd[TF_MAXPLAYERS+1];
static float g_flRageGasRate[TF_MAXPLAYERS+1];
static float g_flRageGasDuration[TF_MAXPLAYERS+1];
static float g_flRageGasDistance[TF_MAXPLAYERS+1];
static float g_flRageGasHeight[TF_MAXPLAYERS+1];
static float g_flPreviousSpeed[TF_MAXPLAYERS+1];
static float g_flNewSpeed[TF_MAXPLAYERS+1];

methodmap CRageGas < SaxtonHaleBase
{
	property float flRate
	{
		public set(float flVal)
		{
			g_flRageGasRate[this.iClient] = flVal;
		}
		public get()
		{
			return g_flRageGasRate[this.iClient];
		}
	}
	
	property float flDuration
	{
		public set (float flVal)
		{
			g_flRageGasDuration[this.iClient] = flVal;
		}
		public get()
		{
			return g_flRageGasDuration[this.iClient];
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
	
	property float flDistance
	{
		public set (float flVal)
		{
			g_flRageGasDistance[this.iClient] = flVal;
		}
		public get()
		{
			return g_flRageGasDistance[this.iClient];
		}
	}
	
	property float flHeight
	{
		public set (float flVal)
		{
			g_flRageGasHeight[this.iClient] = flVal;
		}
		public get()
		{
			return g_flRageGasHeight[this.iClient];
		}
	}
		
	public CRageGas(CRageGas ability)
	{
		g_flRageGasNext[ability.iClient] = 0.0;
		g_flRageGasEnd[ability.iClient] = 0.0;
		
		ability.flRate = 2.5;
		ability.flDuration = 8.0;
		ability.flDistance = 600.0;
		ability.flHeight = 700.0;
	}

	public void OnRage()
	{
		g_flRageGasNext[this.iClient] = GetGameTime();
		g_flRageGasEnd[this.iClient] = GetGameTime() + this.flDuration;
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
		if (g_flRageGasEnd[this.iClient] == 0.0)
			return;
		
		float flGameTime = GetGameTime();
		if (flGameTime <= g_flRageGasEnd[this.iClient])
		{
			if (g_flRageGasNext[this.iClient] > flGameTime) return;
		
			if (this.bSuperRage)
				g_flRageGasNext[this.iClient] = flGameTime + (this.flRate / 1.5);
			else
				g_flRageGasNext[this.iClient] = flGameTime + this.flRate;
			
			float vecOrigin[3], vecVelocity[3], vecAngleVelocity[3];
			GetClientAbsOrigin(this.iClient, vecOrigin);
			vecOrigin[2] += 42.0;
			
			for (int i = 0; i < 8; i++)
			{
				int iBomb = CreateEntityByName("tf_projectile_jar_gas");
				if (iBomb > MaxClients)
				{
					vecAngleVelocity[1] = float(45 * i);
					
					GetAngleVectors(vecAngleVelocity, vecVelocity, vecVelocity, NULL_VECTOR);
					
					ScaleVector(vecVelocity, this.flDistance);
					vecVelocity[2] = this.flHeight;
						
					SetEntProp(iBomb, Prop_Send, "m_iTeamNum", GetClientTeam(this.iClient));
					SetEntPropEnt(iBomb, Prop_Send, "m_hOwnerEntity", this.iClient);
					
					DispatchSpawn(iBomb);
					
					TeleportEntity(iBomb, vecOrigin, NULL_VECTOR, vecVelocity);
					
					SetEntProp(iBomb, Prop_Send, "m_CollisionGroup", 24);
				}
			}
		}
		else
		{
			g_flRageGasEnd[this.iClient] = 0.0;
			this.flSpeed = g_flPreviousSpeed[this.iClient];
		}
	}
};