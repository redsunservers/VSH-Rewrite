static float g_flDashJumpCooldownWait[TF_MAXPLAYERS+1];
static float g_flDashJumpCooldown[TF_MAXPLAYERS+1];
static float g_flDashJumpMaxCharge[TF_MAXPLAYERS+1];
static float g_flDashJumpMaxForce[TF_MAXPLAYERS+1];

methodmap CDashJump < SaxtonHaleBase
{
	property float flCooldown
	{
		public get()
		{
			return g_flDashJumpCooldown[this.iClient];
		}
		public set(float val)
		{
			g_flDashJumpCooldown[this.iClient] = val;
		}
	}
	
	property float flMaxCharge
	{
		public get()
		{
			return g_flDashJumpMaxCharge[this.iClient];
		}
		public set(float val)
		{
			g_flDashJumpMaxCharge[this.iClient] = val;
		}
	}
	
	property float flMaxForce
	{
		public get()
		{
			return g_flDashJumpMaxForce[this.iClient];
		}
		public set(float val)
		{
			g_flDashJumpMaxForce[this.iClient] = val;
		}
	}
	
	public CDashJump(CDashJump ability)
	{
		g_flDashJumpCooldownWait[ability.iClient] = 0.0;
		
		//Default values, these can be changed if needed
		ability.flCooldown = 4.0;
		ability.flMaxCharge = 2.0;
		ability.flMaxForce = 700.0;
	}
	
	public void OnThink()
	{
		if (GameRules_GetRoundState() == RoundState_Preround) return;
		
		char sMessage[255];
		int iCharge;
		
		if (g_flDashJumpCooldownWait[this.iClient] < GetGameTime())
		{
			iCharge = RoundToFloor(this.flMaxCharge * 100.0);
		}
		else
		{
			float flPercentage = (g_flDashJumpCooldownWait[this.iClient]-GetGameTime()) / this.flCooldown;
			iCharge = RoundToFloor((this.flMaxCharge - flPercentage) * 100.0);
		}
		
		if (iCharge >= 100)
			Format(sMessage, sizeof(sMessage), "Dash charge: %d%%, Press reload to use your dash!", iCharge);
		else
			Format(sMessage, sizeof(sMessage), "Dash charge: %d%%", iCharge);
		
		Hud_AddText(this.iClient, sMessage);
	}
	
	public void OnButtonPress(int iButton)
	{
		if (iButton == IN_RELOAD)
		{
			if (TF2_IsPlayerInCondition(this.iClient, TFCond_Dazed))	//Can't dash if stunned
				return;
			
			if (g_flDashJumpCooldownWait[this.iClient] < GetGameTime())
				g_flDashJumpCooldownWait[this.iClient] = GetGameTime();
			
			float flPercentage = (g_flDashJumpCooldownWait[this.iClient]-GetGameTime()) / this.flCooldown;
			float flCharge = this.flMaxCharge - flPercentage;
			
			if (flCharge < 1.0)
				return;
			
			float vecAng[3];
			GetClientEyeAngles(this.iClient, vecAng);
			
			float vecVel[3];
			GetEntPropVector(this.iClient, Prop_Data, "m_vecVelocity", vecVel);
			
			vecVel[0] = Cosine(DegToRad(vecAng[0])) * Cosine(DegToRad(vecAng[1])) * this.flMaxForce;
			vecVel[1] = Cosine(DegToRad(vecAng[0])) * Sine(DegToRad(vecAng[1])) * this.flMaxForce;
			vecVel[2] = (((-vecAng[0]) * 1.5) + 90.0) * 3.0;
			
			SetEntProp(this.iClient, Prop_Send, "m_bJumping", true);
			
			TeleportEntity(this.iClient, NULL_VECTOR, NULL_VECTOR, vecVel);
			
			g_flDashJumpCooldownWait[this.iClient] += this.flCooldown;
			
			char sSound[PLATFORM_MAX_PATH];
			this.CallFunction("GetSoundAbility", sSound, sizeof(sSound), "CDashJump");
			if (!StrEmpty(sSound))
				EmitSoundToAll(sSound, this.iClient, SNDCHAN_VOICE, SNDLEVEL_SCREAMING);
		}
	}
};