static float g_flRageGasEnd[TF_MAXPLAYERS+1];
static float g_flRageGasRate[TF_MAXPLAYERS+1];
static float g_flRageGasDuration[TF_MAXPLAYERS+1];
static float g_flRageSpeedMult[TF_MAXPLAYERS+1];
static float g_flPreviousSpeed[TF_MAXPLAYERS+1];
static float g_flNewSpeed[TF_MAXPLAYERS+1];
static float g_flGasRadius[TF_MAXPLAYERS+1];

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
	
	property float flRadius
	{
		public get()
		{
			return g_flGasRadius[this.iClient];
		}
		public set(float val)
		{
			g_flGasRadius[this.iClient] = val;
		}
	}
	
	property float flRageSpeedMult
	{
		public set (float flVal)
		{
			g_flRageSpeedMult[this.iClient] = flVal;
		}
		public get()
		{
			return g_flRageSpeedMult[this.iClient];
		}
	}
		
	public CRageGas(CRageGas ability)
	{
		g_flRageGasEnd[ability.iClient] = 0.0;
		
		ability.flDuration = 8.0;
		ability.flRageSpeedMult = 1.15;
		ability.flRadius = 800.0;
	}

	public void OnRage()
	{
		int bossTeam = GetClientTeam(this.iClient);
		float vecPos[3], vecTargetPos[3];
		float flRageDuration = this.flDuration;
		GetClientAbsOrigin(this.iClient, vecPos);
		
		float flRadius = this.flRadius;
		if (this.bSuperRage) flRadius *= 1.5;
		if (this.bSuperRage) flRageDuration *= 1.5;
		
		for (int iVictim = 1; iVictim <= MaxClients; iVictim++)
		{
			if (IsClientInGame(iVictim) && IsPlayerAlive(iVictim) && GetClientTeam(iVictim) != bossTeam && !TF2_IsUbercharged(iVictim))
			{
				GetClientAbsOrigin(iVictim, vecTargetPos);
				
				float flDistance = GetVectorDistance(vecTargetPos, vecPos);
				
				if (flDistance <= flRadius)
				{
					TF2_AddCondition(iVictim, TFCond_Gas, flRageDuration, this.iClient);
				}
			}
		}
		
		if (g_flRageGasEnd[this.iClient] == 0.0)
		{
			g_flPreviousSpeed[this.iClient] = this.flSpeed;
			this.flSpeed *= this.flRageSpeedMult;
			
			if (this.bSuperRage)
			{
			TF2_AddCondition(this.iClient, TFCond_TeleportedGlow, flRageDuration, this.iClient);
			this.flSpeed *= this.flRageSpeedMult;
			}
		}
		
		g_flRageGasEnd[this.iClient] = GetGameTime() + flRageDuration;
		
		TF2_AddCondition(this.iClient, TFCond_SpeedBuffAlly, flRageDuration, this.iClient);
	}
	
	public void OnThink()
	{
		if (g_flRageGasEnd[this.iClient] == 0.0)
			return;
		
		float flGameTime = GetGameTime();
		if (flGameTime > g_flRageGasEnd[this.iClient])
		{
			g_flRageGasEnd[this.iClient] = 0.0;
			this.flSpeed = g_flPreviousSpeed[this.iClient];
		}
	}
};