static int g_iFloatJumpCharge[TF_MAXPLAYERS+1];
static int g_iFloatJumpMaxCharge[TF_MAXPLAYERS+1];
static int g_iFloatJumpChargeBuild[TF_MAXPLAYERS+1];
static float g_flFloatJumpHeightMultiplier[TF_MAXPLAYERS+1];
static float g_flJumpCooldown[TF_MAXPLAYERS+1];
static float g_flJumpCooldownWait[TF_MAXPLAYERS+1];
static float g_flFloatEndTime[TF_MAXPLAYERS+1];
static float g_flFlightTime[TF_MAXPLAYERS+1];
static bool g_bFloatJumpHoldingChargeButton[TF_MAXPLAYERS+1];

methodmap CFloatJump < SaxtonHaleBase
{
	property int iMaxJumpCharge
	{
		public get()
		{
			return g_iFloatJumpMaxCharge[this.iClient];
		}
		public set(int val)
		{
			g_iFloatJumpMaxCharge[this.iClient] = val;
		}
	}
	
	property int iJumpCharge
	{
		public get()
		{
			return g_iFloatJumpCharge[this.iClient];
		}
		public set(int val)
		{
			g_iFloatJumpCharge[this.iClient] = val;
			if (g_iFloatJumpCharge[this.iClient] > this.iMaxJumpCharge) g_iFloatJumpCharge[this.iClient] = this.iMaxJumpCharge;
			if (g_iFloatJumpCharge[this.iClient] < 0) g_iFloatJumpCharge[this.iClient] = 0;
		}
	}
	
	property int iJumpChargeBuild
	{
		public get()
		{
			return g_iFloatJumpChargeBuild[this.iClient];
		}
		public set(int val)
		{
			g_iFloatJumpChargeBuild[this.iClient] = val;
		}
	}
	
	property float flCooldown
	{
		public get()
		{
			return g_flJumpCooldown[this.iClient];
		}
		public set(float val)
		{
			g_flJumpCooldown[this.iClient] = val;
		}
	}
	
	property float flHeightMultiplier
	{
		public get()
		{
			return g_flFloatJumpHeightMultiplier[this.iClient];
		}
		public set(float val)
		{
			g_flFloatJumpHeightMultiplier[this.iClient] = val;
		}
	}
	
	property float flFlightTime
	{
		public get()
		{
			return g_flFlightTime[this.iClient];
		}
		public set(float val)
		{
			g_flFlightTime[this.iClient] = val;
		}
	}
	
	public CFloatJump(CFloatJump ability)
	{
		g_iFloatJumpCharge[ability.iClient] = 0;
		g_flJumpCooldownWait[ability.iClient] = 0.0;
		g_bFloatJumpHoldingChargeButton[ability.iClient] = false;
		g_flFloatEndTime[ability.iClient] = 0.0;
		
		//Default values, these can be changed if needed
		ability.iMaxJumpCharge = 200;
		ability.iJumpChargeBuild = 4;
		ability.flHeightMultiplier = 8.5;
		ability.flCooldown = 7.5;
		ability.flFlightTime = 1.5;
	}
	
	public void OnThink()
	{
		if (GameRules_GetRoundState() == RoundState_Preround) return;
		
		char sMessage[255];
		if (this.iJumpCharge > 0)
			Format(sMessage, sizeof(sMessage), "Float charge: %0.2f%%.", (float(this.iJumpCharge)/float(this.iMaxJumpCharge))*100.0);
		else
			Format(sMessage, sizeof(sMessage), "Hold right click to use your float jump!");
		
		if (g_flFloatEndTime[this.iClient] > GetGameTime())
		{
			float vecAng[3];
			GetClientEyeAngles(this.iClient, vecAng);
			
			float vecVel[3];
			
			vecVel[0] = Cosine(DegToRad(vecAng[0])) * Cosine(DegToRad(vecAng[1])) * 600.0;
			vecVel[1] = Cosine(DegToRad(vecAng[0])) * Sine(DegToRad(vecAng[1])) * 600.0;
			vecVel[2] = 90.0 * this.flHeightMultiplier;
			
			SetEntProp(this.iClient, Prop_Send, "m_bJumping", true);
			
			TeleportEntity(this.iClient, NULL_VECTOR, NULL_VECTOR, vecVel);
		}
		
		if (g_flJumpCooldownWait[this.iClient] != 0.0 && g_flJumpCooldownWait[this.iClient] > GetGameTime())
		{
			float flRemainingTime = g_flJumpCooldownWait[this.iClient]-GetGameTime();
			int iSec = RoundToNearest(flRemainingTime);
			Format(sMessage, sizeof(sMessage), "Float cooldown %i second%s remaining!", iSec, (iSec > 1) ? "s" : "");
			Hud_AddText(this.iClient, sMessage);
			return;
		}
		
		Hud_AddText(this.iClient, sMessage);
		
		g_flJumpCooldownWait[this.iClient] = 0.0;
		
		if (g_bFloatJumpHoldingChargeButton[this.iClient])
			this.iJumpCharge += this.iJumpChargeBuild;
		else
			this.iJumpCharge -= this.iJumpChargeBuild*2;
	}
	
	public void OnButtonPress(int button)
	{
		if (button == IN_ATTACK2)
			g_bFloatJumpHoldingChargeButton[this.iClient] = true;
	}
	
	public void OnButtonRelease(int button)
	{
		if (GameRules_GetRoundState() == RoundState_Preround) return;
		
		if (button == IN_ATTACK2)
		{
			if (TF2_IsPlayerInCondition(this.iClient, TFCond_Dazed))//Can't jump if stunned
				return;
			
			g_bFloatJumpHoldingChargeButton[this.iClient] = false;
			
			if ((g_flJumpCooldownWait[this.iClient] != 0.0 && g_flJumpCooldownWait[this.iClient] > GetGameTime()) || this.iJumpCharge < 1) return;
			
			float flCooldownTime = (this.flCooldown*(float(this.iJumpCharge)/float(this.iMaxJumpCharge)));
			if (flCooldownTime < 3.5) flCooldownTime = 3.5;
			g_flJumpCooldownWait[this.iClient] = GetGameTime()+flCooldownTime;
			
			g_flFloatEndTime[this.iClient] = GetGameTime() + this.flFlightTime * (float(this.iJumpCharge)/float(this.iMaxJumpCharge));
			this.iJumpCharge = 0;
			
			TF2_AddCondition(this.iClient, TFCond_SwimmingNoEffects, this.flFlightTime);
			TF2_AddCondition(this.iClient, TFCond_TeleportedGlow, this.flFlightTime * 1.7);
			
			char sSound[PLATFORM_MAX_PATH];
			this.CallFunction("GetSoundAbility", sSound, sizeof(sSound), "CFloatJump");
			if (!StrEmpty(sSound))
				EmitSoundToAll(sSound, this.iClient, SNDCHAN_VOICE, SNDLEVEL_SCREAMING);
		}
	}
};
