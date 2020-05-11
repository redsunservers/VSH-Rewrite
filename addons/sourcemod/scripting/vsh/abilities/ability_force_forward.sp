static float g_flRageBonusEndTime[TF_MAXPLAYERS+1];
static float g_flSpeedRageBonusMultiplier[TF_MAXPLAYERS+1];
static float g_flRageBonusDuration[TF_MAXPLAYERS+1];
static float g_flSpeedRageBonusMultValue[TF_MAXPLAYERS+1];
static float g_flSpeedAbilityBonusMultValue[TF_MAXPLAYERS+1];
static bool g_bInCatapult[TF_MAXPLAYERS+1];

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
	
	property float flSpeedAbilityMultValue
	{
		public get()
		{
			return g_flSpeedAbilityBonusMultValue[this.iClient];
		}
		public set(float val)
		{
			g_flSpeedAbilityBonusMultValue[this.iClient] = val;
		}
	}
	
	public CForceForward(CForceForward ability)
	{
		ability.flRageDuration = 10.0;
		ability.flSpeedRageMultValue = 1.25;
		ability.flSpeedAbilityMultValue = 1.5;
		
		int iEntity = 0;
		while ((iEntity = FindEntityByClassname(iEntity, "trigger_push")) > MaxClients)
		{
			SDKHook(iEntity, SDKHook_StartTouch, OnCatapultStart);
			SDKHook(iEntity, SDKHook_EndTouch, OnCatapultEnd);
		}
		iEntity = 0;
		while ((iEntity = FindEntityByClassname(iEntity, "trigger_catapult")) > MaxClients)
		{
			SDKHook(iEntity, SDKHook_StartTouch, OnCatapultStart);
			SDKHook(iEntity, SDKHook_EndTouch, OnCatapultEnd);
		}
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
		
		
		float flSpeedAbilityBonusMultiplier = 1.0;
		//Ability speedboost
		if (TF2_IsPlayerInCondition(this.iClient, TFCond_TeleportedGlow))
		{
			flSpeedAbilityBonusMultiplier = g_flSpeedAbilityBonusMultValue[this.iClient];
		}
		
		
		float flMaxSpeed = GetEntPropFloat(this.iClient, Prop_Data, "m_flMaxspeed");
		
		float vecCompareVel[3];
		
		if (!g_bInCatapult[this.iClient])
		{
			vecCompareVel[0] = Cosine(DegToRad(vecAng[0])) * Cosine(DegToRad(vecAng[1])) * flMaxSpeed * g_flSpeedRageBonusMultiplier[this.iClient] * flSpeedAbilityBonusMultiplier;
			vecCompareVel[1] = Cosine(DegToRad(vecAng[0])) * Sine(DegToRad(vecAng[1])) * flMaxSpeed * g_flSpeedRageBonusMultiplier[this.iClient] * flSpeedAbilityBonusMultiplier;
			
			if (FloatAbs(vecVel[0]) < FloatAbs(vecCompareVel[0]))
				vecVel[0] = vecCompareVel[0];
			
			if (FloatAbs(vecVel[1]) < FloatAbs(vecCompareVel[1]))
				vecVel[1] = vecCompareVel[1];
			
			TeleportEntity(this.iClient, NULL_VECTOR, NULL_VECTOR, vecVel);
		}
		
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
	
	public void OnEntityCreated(int iEntity, const char[] sClassname)
	{
		if (StrEqual(sClassname, "trigger_catapult") || StrEqual(sClassname, "trigger_push"))
		{
			SDKHook(iEntity, SDKHook_StartTouch, OnCatapultStart);
			SDKHook(iEntity, SDKHook_EndTouch, OnCatapultEnd);
		}
	}
};

public Action OnCatapultStart(int iEntity, int iClient)
{
	if (iClient <= MaxClients)
		g_bInCatapult[iClient] = true;
	
	return Plugin_Continue;
}

public Action OnCatapultEnd(int iEntity, int iClient)
{
	if (iClient <= MaxClients)
		g_bInCatapult[iClient] = false;
	
	return Plugin_Continue;
}