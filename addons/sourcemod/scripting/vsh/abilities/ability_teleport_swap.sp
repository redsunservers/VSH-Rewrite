static int g_iTeleportSwapCharge[TF_MAXPLAYERS+1];
static int g_iTeleportSwapMaxCharge[TF_MAXPLAYERS+1];
static int g_iTeleportSwapChargeBuild[TF_MAXPLAYERS+1];
static float g_flTeleportSwapCooldown[TF_MAXPLAYERS+1];
static float g_flTeleportSwapStunDuration[TF_MAXPLAYERS+1];
static float g_flTeleportSwapCooldownWait[TF_MAXPLAYERS+1];
static bool g_bTeleportSwapHoldingChargeButton[TF_MAXPLAYERS+1];

methodmap CTeleportSwap < SaxtonHaleBase
{
	property int iMaxCharge
	{
		public get()
		{
			return g_iTeleportSwapMaxCharge[this.iClient];
		}
		public set(int val)
		{
			g_iTeleportSwapMaxCharge[this.iClient] = val;
		}
	}
	
	property int iCharge
	{
		public get()
		{
			return g_iTeleportSwapCharge[this.iClient];
		}
		public set(int val)
		{
			g_iTeleportSwapCharge[this.iClient] = val;
			if (g_iTeleportSwapCharge[this.iClient] > this.iMaxCharge) g_iTeleportSwapCharge[this.iClient] = this.iMaxCharge;
			if (g_iTeleportSwapCharge[this.iClient] < 0) g_iTeleportSwapCharge[this.iClient] = 0;
		}
	}
	
	property int iChargeBuild
	{
		public get()
		{
			return g_iTeleportSwapChargeBuild[this.iClient];
		}
		public set(int val)
		{
			g_iTeleportSwapChargeBuild[this.iClient] = val;
		}
	}
	
	property float flCooldown
	{
		public get()
		{
			return g_flTeleportSwapCooldown[this.iClient];
		}
		public set(float val)
		{
			g_flTeleportSwapCooldown[this.iClient] = val;
		}
	}
	
	property float flStunDuration
	{
		public get()
		{
			return g_flTeleportSwapStunDuration[this.iClient];
		}
		public set(float val)
		{
			g_flTeleportSwapStunDuration[this.iClient] = val;
		}
	}
	
	public CTeleportSwap(CTeleportSwap ability)
	{
		//Default values, these can be changed if needed
		ability.iMaxCharge = 200;
		ability.iChargeBuild = 4;
		ability.flCooldown = 40.0;
		ability.flStunDuration = 3.0;
		
		g_iTeleportSwapCharge[ability.iClient] = 0;
		g_flTeleportSwapCooldownWait[ability.iClient] = GetGameTime() + ability.flCooldown;
	}
	
	public void OnThink()
	{
		if (GameRules_GetRoundState() == RoundState_Preround) return;
		
		char sMessage[255];
		if (this.iCharge > 0)
			Format(sMessage, sizeof(sMessage), "Teleport-swap: %0.2f%%. Look up and stand up to use teleport-swap.", (float(this.iCharge)/float(this.iMaxCharge))*100.0);
		else
			Format(sMessage, sizeof(sMessage), "Hold right click to use your teleport-swap!");
		
		if (g_flTeleportSwapCooldownWait[this.iClient] != 0.0 && g_flTeleportSwapCooldownWait[this.iClient] > GetGameTime())
		{
			float flRemainingTime = g_flTeleportSwapCooldownWait[this.iClient]-GetGameTime();
			int iSec = RoundToNearest(flRemainingTime);
			Format(sMessage, sizeof(sMessage), "Teleport-swap cooldown %i second%s remaining!", iSec, (iSec > 1) ? "s" : "");
			Hud_AddText(this.iClient, sMessage);
			return;
		}
		
		Hud_AddText(this.iClient, sMessage);
		
		g_flTeleportSwapCooldownWait[this.iClient] = 0.0;
		
		if (g_bTeleportSwapHoldingChargeButton[this.iClient])
			this.iCharge += this.iChargeBuild;
		else
			this.iCharge -= this.iChargeBuild*2;
	}
	
	public void OnButtonHold(int button)
	{
		if (button == IN_ATTACK2)
			g_bTeleportSwapHoldingChargeButton[this.iClient] = true;
	}
	
	public void OnButtonRelease(int button)
	{
		if (button == IN_ATTACK2)
		{
			if (TF2_IsPlayerInCondition(this.iClient, TFCond_Dazed))//Can't teleport-swap if stunned
				return;
			
			if (!(GetEntityFlags(this.iClient) & FL_ONGROUND))
				return;
			
			g_bTeleportSwapHoldingChargeButton[this.iClient] = false;
			if (g_flTeleportSwapCooldownWait[this.iClient] != 0.0 && g_flTeleportSwapCooldownWait[this.iClient] > GetGameTime()) return;
			
			float vecAng[3];
			GetClientEyeAngles(this.iClient, vecAng);
			if ((vecAng[0] < -60.0) && (this.iCharge >= this.iMaxCharge))
			{
				//get random valid attack player
				ArrayList aClients = new ArrayList();
				for (int i = 1; i <= MaxClients; i++)
					if (SaxtonHale_IsValidAttack(i) && IsPlayerAlive(i))
						aClients.Push(i);
				
				if (aClients.Length == 0)
				{
					//Nobody in list? okay...
					delete aClients;
					return;
				}
				
				aClients.Sort(Sort_Random, Sort_Integer);
				
				int iClient[2];
				
				iClient[0] = this.iClient;
				iClient[1] = aClients.Get(0);
				delete aClients;
				
				TF2_TeleportSwap(iClient);
				
				TF2_StunPlayer(iClient[0], this.flStunDuration, 0.0, TF_STUNFLAGS_GHOSTSCARE|TF_STUNFLAG_NOSOUNDOREFFECT, iClient[1]);
				TF2_AddCondition(iClient[0], TFCond_DefenseBuffMmmph, this.flStunDuration);
				
				g_flTeleportSwapCooldownWait[this.iClient] = GetGameTime()+this.flCooldown;
				this.iCharge = 0;
				
				char sSound[PLATFORM_MAX_PATH];
				this.CallFunction("GetSoundAbility", sSound, sizeof(sSound), "CTeleportSwap");
				if (!StrEmpty(sSound))
					EmitSoundToAll(sSound, this.iClient, SNDCHAN_VOICE, SNDLEVEL_SCREAMING);
			}
		}
	}
};
