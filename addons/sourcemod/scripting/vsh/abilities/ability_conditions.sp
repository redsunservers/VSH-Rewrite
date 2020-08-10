static float g_flCondCooldownWait[TF_MAXPLAYERS + 1];
static float g_flCondCooldown[TF_MAXPLAYERS + 1];
static float g_flCondDuration[TF_MAXPLAYERS + 1];
static float g_flCondMaxCharge[TF_MAXPLAYERS + 1];
static bool g_bRemoveOnRage[TF_MAXPLAYERS + 1];
static ArrayList g_aConditions[TF_MAXPLAYERS + 1];

methodmap CAddCond < SaxtonHaleBase
{
	property float flCondCooldown
	{
		public get()
		{
			return g_flCondCooldown[this.iClient];
		}
		public set(float flVal)
		{
			g_flCondCooldown[this.iClient] = flVal;
		}
	}
	
	property float flCondDuration
	{
		public get()
		{
			return g_flCondDuration[this.iClient];
		}
		public set(float flVal)
		{
			g_flCondDuration[this.iClient] = flVal;
		}
	}
	
	property float flCondMaxCharge
	{
		public get()
		{
			return g_flCondMaxCharge[this.iClient];
		}
		public set(float flVal)
		{
			g_flCondMaxCharge[this.iClient] = flVal;
		}
	}
	
	property bool bRemoveOnRage
	{
		public get()
		{
			return g_bRemoveOnRage[this.iClient];
		}
		public set(bool bVal)
		{
			g_bRemoveOnRage[this.iClient] = bVal;
		}
	}
	
	public CAddCond(CAddCond ability)
	{
		g_flCondCooldownWait[ability.iClient] = 0.0;
		
		if (g_aConditions[ability.iClient] == null)
			g_aConditions[ability.iClient] = new ArrayList();
		g_aConditions[ability.iClient].Clear();
		
		ability.flCondCooldown = 30.0;
		ability.flCondDuration = 8.0;
		ability.flCondMaxCharge = 1.0;
	}
	
	public void AddCond(TFCond cond)
	{
		g_aConditions[this.iClient].Push(cond);
	}
	
	public void OnThink()
	{
		if (GameRules_GetRoundState() == RoundState_Preround)
			return;
		
		char sMessage[255];
		int iCharge;
		
		if (g_flCondCooldownWait[this.iClient] < GetGameTime())
		{
			iCharge = RoundToFloor(this.flCondMaxCharge * 100.0);
		}
		else
		{
			float flPercentage = (g_flCondCooldownWait[this.iClient] - GetGameTime()) / this.flCondCooldown;
			iCharge = RoundToFloor((this.flCondMaxCharge - flPercentage) * 100.0);
		}
		
		if (iCharge >= 100)
			Format(sMessage, sizeof(sMessage), "Ability Charge: %d%%%% - Press MOUSE2 to use!", iCharge);
		else
			Format(sMessage, sizeof(sMessage), "Ability Charge: %d%%%%", iCharge);
		
		Hud_AddText(this.iClient, sMessage);
	}
	
	public void OnButtonPress(int iButton)
	{
		if (iButton == IN_ATTACK2 && GameRules_GetRoundState() != RoundState_Preround && !TF2_IsPlayerInCondition(this.iClient, TFCond_Dazed))
		{
			if (g_flCondCooldownWait[this.iClient] < GetGameTime())
				g_flCondCooldownWait[this.iClient] = GetGameTime();
			
			float flPercentage = (g_flCondCooldownWait[this.iClient] - GetGameTime()) / this.flCondCooldown;
			float flCharge = this.flCondMaxCharge - flPercentage;
			
			if (flCharge < 1.0)
				return;
			
			for (int i = 0; i < g_aConditions[this.iClient].Length; i++)
			{
				TF2_AddCondition(this.iClient, g_aConditions[this.iClient].Get(i), this.flCondDuration);
			}
			
			g_flCondCooldownWait[this.iClient] += this.flCondCooldown;
			
			char sSound[PLATFORM_MAX_PATH];
			this.CallFunction("GetSoundAbility", sSound, sizeof(sSound), "CAddCond");
			if (!StrEmpty(sSound))
				EmitSoundToAll(sSound, this.iClient, SNDCHAN_VOICE, SNDLEVEL_SCREAMING);
		}
	}
	
	public void OnRage()
	{
		if (this.bRemoveOnRage)
		{
			for (int i = 0; i < g_aConditions[this.iClient].Length; i++)
			{
				TF2_RemoveCondition(this.iClient, g_aConditions[this.iClient].Get(i));
			}
		}
	}
};
