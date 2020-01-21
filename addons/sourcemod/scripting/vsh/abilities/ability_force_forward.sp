static float g_flBonusEndTime[TF_MAXPLAYERS+1];
static float g_flSpeedBonusMultiplier[TF_MAXPLAYERS+1];

methodmap CForceForward < SaxtonHaleBase
{
	
	public CForceForward(CForceForward ability)
	{
	
	}
	
	public void OnThink()
	{
		if (GameRules_GetRoundState() == RoundState_Preround) return;
		
		float vecAng[3];
		float vecVel[3];
		GetClientAbsAngles(this.iClient, vecAng);
		
		GetEntPropVector(this.iClient, Prop_Data, "m_vecAbsVelocity", vecVel);
		
		if (g_flBonusEndTime[this.iClient] < GetGameTime())
		{
			g_flSpeedBonusMultiplier[this.iClient] = 1.0;
		}
		
		
		float flMaxSpeed = GetEntPropFloat(this.iClient, Prop_Data, "m_flMaxspeed");
		
		vecVel[0] = Cosine(DegToRad(vecAng[0])) * Cosine(DegToRad(vecAng[1])) * flMaxSpeed * g_flSpeedBonusMultiplier[this.iClient];
		vecVel[1] = Cosine(DegToRad(vecAng[0])) * Sine(DegToRad(vecAng[1])) * flMaxSpeed * g_flSpeedBonusMultiplier[this.iClient];
		
		SetEntPropVector(this.iClient, Prop_Data, "m_vecAbsVelocity", vecVel);
		
	}
	
	public void OnRage()
	{
		if (this.bSuperRage)
		{
			g_flBonusEndTime[this.iClient] = GetGameTime() + 16.0;
			g_flSpeedBonusMultiplier[this.iClient] = 1.4;
		}
		else
		{
			g_flBonusEndTime[this.iClient] = GetGameTime() + 10.0;
			g_flSpeedBonusMultiplier[this.iClient] = 1.3;
		}
	}
};