static int g_iFloatJumpCharge[TF_MAXPLAYERS];
static int g_iFloatJumpMaxCharge[TF_MAXPLAYERS];
static int g_iFloatJumpChargeBuild[TF_MAXPLAYERS];
static float g_flFloatJumpMaxDistance[TF_MAXPLAYERS];
static float g_flFloatJumpMaxHeight[TF_MAXPLAYERS];
static float g_flFloatJumpCooldown[TF_MAXPLAYERS];
static float g_flFloatJumpCooldownWait[TF_MAXPLAYERS];
static float g_flFloatJumpEndTime[TF_MAXPLAYERS];
static float g_flFloatJumpDuration[TF_MAXPLAYERS];
static float g_flFloatJumpGravity[TF_MAXPLAYERS];
static bool g_bFloatJumpHoldingChargeButton[TF_MAXPLAYERS];

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
			return g_flFloatJumpCooldown[this.iClient];
		}
		public set(float val)
		{
			g_flFloatJumpCooldown[this.iClient] = val;
		}
	}
	
	property float flMaxDistance
	{
		public get()
		{
			return g_flFloatJumpMaxDistance[this.iClient];
		}
		public set(float val)
		{
			g_flFloatJumpMaxDistance[this.iClient] = val;
		}
	}
	
	property float flMaxHeight
	{
		public get()
		{
			return g_flFloatJumpMaxHeight[this.iClient];
		}
		public set(float val)
		{
			g_flFloatJumpMaxHeight[this.iClient] = val;
		}
	}
	
	property float flDuration
	{
		public get()
		{
			return g_flFloatJumpDuration[this.iClient];
		}
		public set(float val)
		{
			g_flFloatJumpDuration[this.iClient] = val;
		}
	}
	
	property float flGravity
	{
		public get()
		{
			return g_flFloatJumpGravity[this.iClient];
		}
		public set(float val)
		{
			g_flFloatJumpGravity[this.iClient] = val;
		}
	}
	
	public CFloatJump(CFloatJump ability)
	{
		g_iFloatJumpCharge[ability.iClient] = 0;
		g_flFloatJumpCooldownWait[ability.iClient] = 0.0;
		g_bFloatJumpHoldingChargeButton[ability.iClient] = false;
		g_flFloatJumpEndTime[ability.iClient] = 0.0;
		
		//Default values, these can be changed if needed
		ability.iMaxJumpCharge = 200;
		ability.iJumpChargeBuild = 4;
		ability.flMaxDistance = 750.0;
		ability.flMaxHeight = 500.0;
		ability.flCooldown = 8.0;
		ability.flDuration = 1.0;
		ability.flGravity = 0.3;
	}
	
	public void OnThink()
	{
		if (GameRules_GetRoundState() == RoundState_Preround) return;
		
		if (g_flFloatJumpEndTime[this.iClient] < GetGameTime() && GetEntityGravity(this.iClient) != 1.0 && GetEntityFlags(this.iClient) & FL_ONGROUND)
		{
			//Ability ended and pyrocar landed on ground
			SetEntityGravity(this.iClient, 1.0);
		}
		else if (g_flFloatJumpEndTime[this.iClient] > GetGameTime() || GetEntityGravity(this.iClient) != 1.0)
		{
			//Still in air floating
			float vecAng[3], vecVel[3];
			GetClientEyeAngles(this.iClient, vecAng);
			GetEntPropVector(this.iClient, Prop_Data, "m_vecVelocity", vecVel);
			
			vecVel[0] = Cosine(DegToRad(vecAng[0])) * Cosine(DegToRad(vecAng[1])) * this.flMaxDistance;
			vecVel[1] = Cosine(DegToRad(vecAng[0])) * Sine(DegToRad(vecAng[1])) * this.flMaxDistance;
			
			if (g_flFloatJumpEndTime[this.iClient] > GetGameTime())
				vecVel[2] = this.flMaxHeight;	//Only give extra height if still floating up
			
			SetEntProp(this.iClient, Prop_Send, "m_bJumping", true);
			TeleportEntity(this.iClient, NULL_VECTOR, NULL_VECTOR, vecVel);
		}
		
		if (g_flFloatJumpCooldownWait[this.iClient] <= GetGameTime())
		{
			g_flFloatJumpCooldownWait[this.iClient] = 0.0;
			
			if (g_bFloatJumpHoldingChargeButton[this.iClient])
				this.iJumpCharge += this.iJumpChargeBuild;
			else
				this.iJumpCharge -= this.iJumpChargeBuild*2;
		}
	}
	
	public void GetHudText(char[] sMessage, int iLength)
	{
		if (g_flFloatJumpCooldownWait[this.iClient] != 0.0 && g_flFloatJumpCooldownWait[this.iClient] > GetGameTime())
		{
			int iSec = RoundToNearest(g_flFloatJumpCooldownWait[this.iClient]-GetGameTime());
			Format(sMessage, iLength, "%s\nFloat cooldown %i second%s remaining!", sMessage, iSec, (iSec > 1) ? "s" : "");
		}
		else if (this.iJumpCharge > 0)
		{
			Format(sMessage, iLength, "%s\nFloat charge: %0.2f%%.", sMessage, (float(this.iJumpCharge)/float(this.iMaxJumpCharge))*100.0);
		}
		else
		{
			Format(sMessage, iLength, "%s\nHold right click to use your float jump!", sMessage);
		}
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
			
			if ((g_flFloatJumpCooldownWait[this.iClient] != 0.0 && g_flFloatJumpCooldownWait[this.iClient] > GetGameTime()) || this.iJumpCharge < 1)
				return;
			
			float flCooldownTime = (this.flCooldown*(float(this.iJumpCharge)/float(this.iMaxJumpCharge)));
			if (flCooldownTime < 5.0)
				flCooldownTime = 5.0;
			
			g_flFloatJumpCooldownWait[this.iClient] = GetGameTime()+flCooldownTime;
			
			g_flFloatJumpEndTime[this.iClient] = GetGameTime() + this.flDuration * (float(this.iJumpCharge)/float(this.iMaxJumpCharge));
			this.iJumpCharge = 0;
			
			TF2_AddCondition(this.iClient, TFCond_SwimmingNoEffects, this.flDuration);
			TF2_AddCondition(this.iClient, TFCond_TeleportedGlow, this.flDuration * 1.7);
			SetEntityGravity(this.iClient, this.flGravity);
			
			char sSound[PLATFORM_MAX_PATH];
			this.CallFunction("GetSoundAbility", sSound, sizeof(sSound), "CFloatJump");
			if (!StrEmpty(sSound))
				EmitSoundToAll(sSound, this.iClient, SNDCHAN_VOICE, SNDLEVEL_SCREAMING);
		}
	}
};
