static float g_flRageBonusEndTime[TF_MAXPLAYERS+1];
static float g_flSpeedRageBonusMultiplier[TF_MAXPLAYERS+1];
static float g_flRageBonusDuration[TF_MAXPLAYERS+1];
static float g_flSpeedRageBonusMultValue[TF_MAXPLAYERS+1];
static float g_flRageBonusDurationSuper[TF_MAXPLAYERS+1];
static float g_flSpeedRageBonusMultValueSuper[TF_MAXPLAYERS+1];

methodmap CForceForward < SaxtonHaleBase
{
	
	property float flRageBonusDuration
	{
		public get()
		{
			return g_flRageBonusDuration[this.iClient];
		}
		public set(float val)
		{
			g_flRageBonusDuration[this.iClient] = val;
		}
	}
	
	property float flSpeedRageBonusMultValue
	{
		public get()
		{
			return g_flSpeedRageBonusMultValue[this.iClient];
		}
		public set(float val)
		{
			g_flSpeedRageBonusMultValue[this.iClient] = val;
		}
	}
	
	property float flRageBonusDurationSuper
	{
		public get()
		{
			return g_flRageBonusDurationSuper[this.iClient];
		}
		public set(float val)
		{
			g_flRageBonusDurationSuper[this.iClient] = val;
		}
	}
	
	property float flSpeedRageBonusMultValueSuper
	{
		public get()
		{
			return g_flSpeedRageBonusMultValueSuper[this.iClient];
		}
		public set(float val)
		{
			g_flSpeedRageBonusMultValueSuper[this.iClient] = val;
		}
	}
	
	public CForceForward(CForceForward ability)
	{
	
		ability.flRageBonusDuration = 10.0;
		ability.flRageBonusDurationSuper = 15.0;
		
		ability.flSpeedRageBonusMultValue = 1.3;
		ability.flSpeedRageBonusMultValue = 1.45;
	
	}
	
	public void OnThink()
	{
		if (GameRules_GetRoundState() == RoundState_Preround) return;
		
		float vecAng[3];
		float vecVel[3];
		GetClientAbsAngles(this.iClient, vecAng);
		
		GetEntPropVector(this.iClient, Prop_Data, "m_vecAbsVelocity", vecVel);
		
		if (g_flRageBonusEndTime[this.iClient] < GetGameTime())
		{
			g_flSpeedRageBonusMultiplier[this.iClient] = 1.0;
		}
		
		
		float flMaxSpeed = GetEntPropFloat(this.iClient, Prop_Data, "m_flMaxspeed");
		
		vecVel[0] = Cosine(DegToRad(vecAng[0])) * Cosine(DegToRad(vecAng[1])) * flMaxSpeed * g_flSpeedRageBonusMultiplier[this.iClient];
		vecVel[1] = Cosine(DegToRad(vecAng[0])) * Sine(DegToRad(vecAng[1])) * flMaxSpeed * g_flSpeedRageBonusMultiplier[this.iClient];
		
		SetEntPropVector(this.iClient, Prop_Data, "m_vecAbsVelocity", vecVel);
		
	}
	
	public void OnRage()
	{
		if (this.bSuperRage)
		{
			g_flRageBonusEndTime[this.iClient] = GetGameTime() + this.flRageBonusDurationSuper;
			g_flSpeedRageBonusMultiplier[this.iClient] = this.flSpeedRageBonusMultValueSuper;
		}
		else
		{
			g_flRageBonusEndTime[this.iClient] = GetGameTime() + this.flRageBonusDuration;
			g_flSpeedRageBonusMultiplier[this.iClient] = this.flSpeedRageBonusMultValue;
		}
	}
};