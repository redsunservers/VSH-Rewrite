static float g_flRageBonusEndTime[TF_MAXPLAYERS+1];
static float g_flSpeedRageBonusMultiplier[TF_MAXPLAYERS+1];
static float g_flRageBonusDuration[TF_MAXPLAYERS+1];
static float g_flSpeedRageBonusMultValue[TF_MAXPLAYERS+1];

methodmap CForceForward < SaxtonHaleBase
{
	
	property float flRageDuration
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
	
	property float flSpeedRageMultValue
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
	
	public CForceForward(CForceForward ability)
	{
		ability.flRageDuration = 10.0;
		ability.flSpeedRageMultValue = 1.3;
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
		
		TeleportEntity(this.iClient, NULL_VECTOR, NULL_VECTOR, vecVel);
		
	}
	
	public void OnRage()
	{
		if (this.bSuperRage)
		{
			g_flRageBonusEndTime[this.iClient] = GetGameTime() + this.flRageDuration * 1.5;
			g_flSpeedRageBonusMultiplier[this.iClient] = 1 + (this.flSpeedRageMultValue-1) * 1.5;
		}
		else
		{
			g_flRageBonusEndTime[this.iClient] = GetGameTime() + this.flRageDuration;
			g_flSpeedRageBonusMultiplier[this.iClient] = this.flSpeedRageMultValue;
		}
	}
};