static int g_iBraveJumpCharge[TF_MAXPLAYERS];
static int g_iBraveJumpMaxCharge[TF_MAXPLAYERS];
static int g_iBraveJumpChargeBuild[TF_MAXPLAYERS];
static float g_flBraveJumpMaxHeight[TF_MAXPLAYERS];
static float g_flBraveJumpMaxDistance[TF_MAXPLAYERS];
static float g_flJumpCooldown[TF_MAXPLAYERS];
static float g_flJumpMinCooldown[TF_MAXPLAYERS];
static float g_flJumpCooldownWait[TF_MAXPLAYERS];
static float g_flBraveJumpEyeAngleRequirement[TF_MAXPLAYERS];
static bool g_bBraveJumpHoldingChargeButton[TF_MAXPLAYERS];

methodmap CBraveJump < SaxtonHaleBase
{
	property int iMaxJumpCharge
	{
		public get()
		{
			return g_iBraveJumpMaxCharge[this.iClient];
		}
		public set(int val)
		{
			g_iBraveJumpMaxCharge[this.iClient] = val;
		}
	}
	
	property int iJumpCharge
	{
		public get()
		{
			return g_iBraveJumpCharge[this.iClient];
		}
		public set(int val)
		{
			g_iBraveJumpCharge[this.iClient] = val;
			if (g_iBraveJumpCharge[this.iClient] > this.iMaxJumpCharge) g_iBraveJumpCharge[this.iClient] = this.iMaxJumpCharge;
			if (g_iBraveJumpCharge[this.iClient] < 0) g_iBraveJumpCharge[this.iClient] = 0;
		}
	}
	
	property int iJumpChargeBuild
	{
		public get()
		{
			return g_iBraveJumpChargeBuild[this.iClient];
		}
		public set(int val)
		{
			g_iBraveJumpChargeBuild[this.iClient] = val;
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
	
	property float flMinCooldown
	{
		public get()
		{
			return g_flJumpMinCooldown[this.iClient];
		}
		public set(float val)
		{
			g_flJumpMinCooldown[this.iClient] = val;
		}
	}
	
	property float flMaxHeight
	{
		public get()
		{
			return g_flBraveJumpMaxHeight[this.iClient];
		}
		public set(float val)
		{
			g_flBraveJumpMaxHeight[this.iClient] = val;
		}
	}
	
	property float flMaxDistance
	{
		public get()
		{
			return g_flBraveJumpMaxDistance[this.iClient];
		}
		public set(float val)
		{
			g_flBraveJumpMaxDistance[this.iClient] = val;
		}
	}
	
	property float flEyeAngleRequirement
	{
		public get()
		{
			return g_flBraveJumpEyeAngleRequirement[this.iClient];
		}
		public set(float val)
		{
			//Cap value to prevent impossible angle
			if (val < -89.0)
				val = -89.0;
			
			g_flBraveJumpEyeAngleRequirement[this.iClient] = val;
		}
	}
	
	public CBraveJump(CBraveJump ability)
	{
		g_iBraveJumpCharge[ability.iClient] = 0;
		g_flJumpCooldownWait[ability.iClient] = 0.0;
		
		//Default values, these can be changed if needed
		ability.iMaxJumpCharge = 200;
		ability.iJumpChargeBuild = 4;
		ability.flMaxHeight = 1100.0;
		ability.flMaxDistance = 0.45;
		ability.flCooldown = 9.0;
		ability.flMinCooldown = 5.5;
		ability.flEyeAngleRequirement = -25.0;	//How far up should the boss look for the ability to trigger? Minimum value is -89.0 (all the way up)
	}
	
	public void OnThink()
	{
		if (GameRules_GetRoundState() == RoundState_Preround)
			return;
		
		if (g_flJumpCooldownWait[this.iClient] == 0.0)	//Round started, start cooldown
			g_flJumpCooldownWait[this.iClient] = GetGameTime()+this.flCooldown;
		
		if (g_flJumpCooldownWait[this.iClient] <= GetGameTime() && g_bBraveJumpHoldingChargeButton[this.iClient])
			this.iJumpCharge += this.iJumpChargeBuild;
		else
			this.iJumpCharge -= this.iJumpChargeBuild*2;
	}
	
	public void GetHudText(char[] sMessage, int iLength)
	{
		if (g_flJumpCooldownWait[this.iClient] != 0.0 && g_flJumpCooldownWait[this.iClient] > GetGameTime())
		{
			int iSec = RoundToNearest(g_flJumpCooldownWait[this.iClient]-GetGameTime());
			Format(sMessage, iLength, "%s\nSuper-jump cooldown %i second%s remaining!", sMessage, iSec, (iSec > 1) ? "s" : "");
		}
		else if (this.iJumpCharge > 0)
		{
			Format(sMessage, iLength, "%s\nJump charge: %0.2f%%. Look up and stand up to use super-jump.", sMessage, (float(this.iJumpCharge)/float(this.iMaxJumpCharge))*100.0);
		}
		else
		{
			Format(sMessage, iLength, "%s\nHold right click to use your super-jump!", sMessage);
		}
	}
	
	public void OnButtonHold(int button)
	{
		if (button == IN_ATTACK2)
			g_bBraveJumpHoldingChargeButton[this.iClient] = true;
	}
	
	public void OnButtonRelease(int button)
	{
		if (button == IN_ATTACK2)
		{
			if (TF2_IsPlayerInCondition(this.iClient, TFCond_Dazed))//Can't jump if stunned
				return;
			
			g_bBraveJumpHoldingChargeButton[this.iClient] = false;
			if (g_flJumpCooldownWait[this.iClient] != 0.0 && g_flJumpCooldownWait[this.iClient] > GetGameTime()) return;
			
			float vecAng[3];
			GetClientEyeAngles(this.iClient, vecAng);
			
			if ((vecAng[0] <= this.flEyeAngleRequirement) && (this.iJumpCharge > 1))
			{
				float vecVel[3];
				GetEntPropVector(this.iClient, Prop_Data, "m_vecVelocity", vecVel);
				
				vecVel[2] = this.flMaxHeight*((float(this.iJumpCharge)/float(this.iMaxJumpCharge)));
				vecVel[0] *= (1.0+Sine((float(this.iJumpCharge)/float(this.iMaxJumpCharge)) * FLOAT_PI * this.flMaxDistance));
				vecVel[1] *= (1.0+Sine((float(this.iJumpCharge)/float(this.iMaxJumpCharge)) * FLOAT_PI * this.flMaxDistance));
				SetEntProp(this.iClient, Prop_Send, "m_bJumping", true);
				
				TeleportEntity(this.iClient, NULL_VECTOR, NULL_VECTOR, vecVel);
				
				float flCooldownTime = (this.flCooldown*(float(this.iJumpCharge)/float(this.iMaxJumpCharge)));
				if (flCooldownTime < this.flMinCooldown)
					flCooldownTime = this.flMinCooldown;
				
				g_flJumpCooldownWait[this.iClient] = GetGameTime()+flCooldownTime;
				
				this.iJumpCharge = 0;
				
				char sSound[PLATFORM_MAX_PATH];
				this.CallFunction("GetSoundAbility", sSound, sizeof(sSound), "CBraveJump");
				if (!StrEmpty(sSound))
					EmitSoundToAll(sSound, this.iClient, SNDCHAN_VOICE, SNDLEVEL_SCREAMING);
			}
		}
	}
};
