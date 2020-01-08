static int g_iBraveJumpCharge[TF_MAXPLAYERS+1];
static int g_iBraveJumpMaxCharge[TF_MAXPLAYERS+1];
static int g_iBraveJumpChargeBuild[TF_MAXPLAYERS+1];
static float g_flBraveJumpMaxHeight[TF_MAXPLAYERS+1];
static float g_flBraveJumpMaxDistance[TF_MAXPLAYERS+1];
static float g_flJumpCooldown[TF_MAXPLAYERS+1];
static float g_flJumpCooldownWait[TF_MAXPLAYERS+1];
static float g_flBraveJumpEyeAngleRequirement[TF_MAXPLAYERS+1];
static bool g_bBraveJumpHoldingChargeButton[TF_MAXPLAYERS+1];

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
		ability.flCooldown = 7.0;
		ability.flEyeAngleRequirement = -25.0;	//How far up should the boss look for the ability to trigger? Ranges from -90.0 to 90.0
	}
	
	public void OnThink()
	{
		if (GameRules_GetRoundState() == RoundState_Preround) return;
		
		char sMessage[255];
		if (this.iJumpCharge > 0)
			Format(sMessage, sizeof(sMessage), "Jump charge: %0.2f%%. Look up and stand up to use super-jump.", (float(this.iJumpCharge)/float(this.iMaxJumpCharge))*100.0);
		else
			Format(sMessage, sizeof(sMessage), "Hold right click to use your super-jump!");
		
		if (g_flJumpCooldownWait[this.iClient] != 0.0 && g_flJumpCooldownWait[this.iClient] > GetGameTime())
		{
			float flRemainingTime = g_flJumpCooldownWait[this.iClient]-GetGameTime();
			int iSec = RoundToNearest(flRemainingTime);
			Format(sMessage, sizeof(sMessage), "Super-jump cooldown %i second%s remaining!", iSec, (iSec > 1) ? "s" : "");
			Hud_AddText(this.iClient, sMessage);
			return;
		}
		
		Hud_AddText(this.iClient, sMessage);
		
		g_flJumpCooldownWait[this.iClient] = 0.0;
		
		if (g_bBraveJumpHoldingChargeButton[this.iClient])
			this.iJumpCharge += this.iJumpChargeBuild;
		else
			this.iJumpCharge -= this.iJumpChargeBuild*2;
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
			
			//Cap value to prevent impossible angle
			float flAngleRequirement = this.flEyeAngleRequirement;
			if (flAngleRequirement > 90.0)
				flAngleRequirement = 90.0;
				
			else if (flAngleRequirement < -90.0)
				flAngleRequirement = -90.0;
			
			if ((vecAng[0] <= flAngleRequirement) && (this.iJumpCharge > 1))
			{
				float vecVel[3];
				GetEntPropVector(this.iClient, Prop_Data, "m_vecVelocity", vecVel);
				
				vecVel[2] = this.flMaxHeight*((float(this.iJumpCharge)/float(this.iMaxJumpCharge)));
				vecVel[0] *= (1.0+Sine((float(this.iJumpCharge)/float(this.iMaxJumpCharge)) * FLOAT_PI * this.flMaxDistance));
				vecVel[1] *= (1.0+Sine((float(this.iJumpCharge)/float(this.iMaxJumpCharge)) * FLOAT_PI * this.flMaxDistance));
				SetEntProp(this.iClient, Prop_Send, "m_bJumping", true);
				
				TeleportEntity(this.iClient, NULL_VECTOR, NULL_VECTOR, vecVel);
				
				float flCooldownTime = (this.flCooldown*(float(this.iJumpCharge)/float(this.iMaxJumpCharge)));
				if (flCooldownTime < 2.5) flCooldownTime = 2.5;
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
