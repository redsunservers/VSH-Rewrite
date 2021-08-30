#define ITEM_NEON_ANNIHILATOR			813

static float g_flRageEndTime[TF_MAXPLAYERS];
static float g_flSpeedRageBonusMult[TF_MAXPLAYERS];
static float g_flRageDuration[TF_MAXPLAYERS];
static float g_flSpeedAbilityBonusMult[TF_MAXPLAYERS];
static float g_flSpeedSwimmingBonusMult[TF_MAXPLAYERS];
static bool g_bInCatapult[TF_MAXPLAYERS];

methodmap CForceForward < SaxtonHaleBase
{
	
	property float flRageDuration
	{
		public get()
		{
			return g_flRageDuration[this.iClient];
		}
		public set(float val)
		{
			g_flRageDuration[this.iClient] = val;
		}
	}
	
	property float flSpeedRageBonusMult
	{
		public get()
		{
			return g_flSpeedRageBonusMult[this.iClient];
		}
		public set(float val)
		{
			g_flSpeedRageBonusMult[this.iClient] = val;
		}
	}
	
	property float flSpeedAbilityBonusMult
	{
		public get()
		{
			return g_flSpeedAbilityBonusMult[this.iClient];
		}
		public set(float val)
		{
			g_flSpeedAbilityBonusMult[this.iClient] = val;
		}
	}
	
	property float flSpeedSwimmingBonusMult
	{
		public get()
		{
			return g_flSpeedSwimmingBonusMult[this.iClient];
		}
		public set(float val)
		{
			g_flSpeedSwimmingBonusMult[this.iClient] = val;
		}
	}
	
	public CForceForward(CForceForward ability)
	{
		ability.flRageDuration = 8.0;
		ability.flSpeedSwimmingBonusMult = 1.05;
		ability.flSpeedRageBonusMult = 1.25;
		ability.flSpeedAbilityBonusMult = 1.5;
		
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
		GetClientEyeAngles(this.iClient, vecAng);
		
		GetEntPropVector(this.iClient, Prop_Data, "m_vecAbsVelocity", vecVel);
		
		
		float flSpeedBonusMultiplier = 1.0;
		//Ability speedboost
		if (TF2_IsPlayerInCondition(this.iClient, TFCond_TeleportedGlow))
		{
			flSpeedBonusMultiplier *= this.flSpeedAbilityBonusMult;
		}
		
		if (GetEntityFlags(this.iClient) & FL_INWATER)
		{
			flSpeedBonusMultiplier *= this.flSpeedSwimmingBonusMult;
		}
		
		if (g_flRageEndTime[this.iClient] >= GetGameTime())
		{
			flSpeedBonusMultiplier *= this.flSpeedRageBonusMult;
		}
		
		float flMaxSpeed = GetEntPropFloat(this.iClient, Prop_Data, "m_flMaxspeed");
		
		float vecCompareVel[3];
		
		if (!g_bInCatapult[this.iClient])
		{
			vecCompareVel[0] = Cosine(DegToRad(vecAng[1])) * flMaxSpeed * flSpeedBonusMultiplier;
			vecCompareVel[1] = Sine(DegToRad(vecAng[1])) * flMaxSpeed * flSpeedBonusMultiplier;
			
			if (FloatAbs(vecVel[0]) < FloatAbs(vecCompareVel[0]))
				vecVel[0] = vecCompareVel[0];
			
			if (FloatAbs(vecVel[1]) < FloatAbs(vecCompareVel[1]))
				vecVel[1] = vecCompareVel[1];
				
			int iWaterLevel = GetEntProp(this.iClient, Prop_Send, "m_nWaterLevel");
			//0 - not in water (WL_NotInWater)
			//1 - feet in water (WL_Feet)
			//2 - waist in water (WL_Waist)
			//3 - head in water (WL_Eyes) 
		
			//Give Pyrocar proper swimming
			if (iWaterLevel >= 3)
			{
				vecVel[2] = -Sine(DegToRad(vecAng[0])) * flMaxSpeed * flSpeedBonusMultiplier;
			}
			
			
			TeleportEntity(this.iClient, NULL_VECTOR, NULL_VECTOR, vecVel);
		}
	}
	
	public void OnRage()
	{
		if (this.bSuperRage)
		{
			g_flRageEndTime[this.iClient] = GetGameTime() + this.flRageDuration * 1.5;
		}
		else
		{
			g_flRageEndTime[this.iClient] = GetGameTime() + this.flRageDuration;
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