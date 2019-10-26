static float g_flDashJumpMaxForce[TF_MAXPLAYERS+1];
static float g_flDashJumpCooldown[TF_MAXPLAYERS+1];
static float g_flDashJumpCooldownWait[TF_MAXPLAYERS+1];

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
		ability.flMaxForce = 700.0;
		ability.flCooldown = 5.0;
	}
	
	public void OnThink()
	{
		if (GameRules_GetRoundState() == RoundState_Preround) return;
		
		char sMessage[255];
		
		if (g_flDashJumpCooldownWait[this.iClient] != 0.0 && g_flDashJumpCooldownWait[this.iClient] > GetGameTime())
		{
			float flRemainingTime = g_flDashJumpCooldownWait[this.iClient]-GetGameTime();
			int iSec = RoundToNearest(flRemainingTime);
			Format(sMessage, sizeof(sMessage), "Dash cooldown %i second%s remaining!", iSec, (iSec > 1) ? "s" : "");
			Hud_AddText(this.iClient, sMessage);
		}
		else
		{
			Format(sMessage, sizeof(sMessage), "Right click to use your dash!");
			Hud_AddText(this.iClient, sMessage);
			g_flDashJumpCooldownWait[this.iClient] = 0.0;
		}
	}
	
	public void OnButtonPress(int iButton)
	{
		if (iButton == IN_ATTACK2)
		{
			if (TF2_IsPlayerInCondition(this.iClient, TFCond_Dazed))	//Can't dash if stunned
				return;
			
			if (g_flDashJumpCooldownWait[this.iClient] != 0.0 && g_flDashJumpCooldownWait[this.iClient] > GetGameTime())
				return;
			
			float vecAng[3];
			GetClientEyeAngles(this.iClient, vecAng);
			
			float vecVel[3];
			GetEntPropVector(this.iClient, Prop_Data, "m_vecVelocity", vecVel);
			
			PrintToChatAll("client angle %.2f %.2f %.2f", vecAng[0], vecAng[1], vecAng[2]);
			PrintToChatAll("client old vel %.2f %.2f %.2f", vecVel[0], vecVel[1], vecVel[2]);
			
			vecVel[0] = Cosine(DegToRad(vecAng[0])) * Cosine(DegToRad(vecAng[1])) * this.flMaxForce;
			vecVel[1] = Cosine(DegToRad(vecAng[0])) * Sine(DegToRad(vecAng[1])) * this.flMaxForce;
			vecVel[2] = (((-vecAng[0]) * 1.5) + 90.0) * 3.0;
			
			PrintToChatAll("client new vel %.2f %.2f %.2f", vecVel[0], vecVel[1], vecVel[2]);
			
			SetEntProp(this.iClient, Prop_Send, "m_bJumping", true);
			
			TeleportEntity(this.iClient, NULL_VECTOR, NULL_VECTOR, vecVel);
			
			g_flDashJumpCooldownWait[this.iClient] = GetGameTime()+this.flCooldown;
			
			char sSound[PLATFORM_MAX_PATH];
			this.CallFunction("GetSoundAbility", sSound, sizeof(sSound), "CDashJump");
			if (!StrEmpty(sSound))
				EmitSoundToAll(sSound, this.iClient, SNDCHAN_VOICE, SNDLEVEL_SCREAMING);
		}
	}
};