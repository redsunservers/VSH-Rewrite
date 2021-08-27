#define ATTRIB_NO_JUMP	819

static float g_flJumpCooldown[TF_MAXPLAYERS];

methodmap CModifiersJumper < SaxtonHaleBase
{
	public CModifiersJumper(CModifiersJumper boss)
	{
		TF2Attrib_SetByDefIndex(boss.iClient, ATTRIB_NO_JUMP, 1.0);
	}
	
	public void GetModifiersName(char[] sName, int length)
	{
		strcopy(sName, length, "Jumper");
	}
	
	public void GetModifiersInfo(char[] sInfo, int length)
	{
		StrCat(sInfo, length, "\nColor: Blue");
		StrCat(sInfo, length, "\n ");
		StrCat(sInfo, length, "\n- Normal jump is replaced with leap");
		StrCat(sInfo, length, "\n- 3 seconds cooldown");
	}
	
	public int GetRenderColor(int iColor[4])
	{
		iColor[0] = 64;
		iColor[1] = 144;
		iColor[2] = 255;
		iColor[3] = 255;
	}
	
	public void OnButtonPress(int iButton)
	{
		if (GameRules_GetRoundState() == RoundState_Preround)
			return;
		
		if (iButton == IN_JUMP && g_flJumpCooldown[this.iClient] == 0.0)
		{
			g_flJumpCooldown[this.iClient] = GetGameTime() + 3.0;
			
			float vecAng[3], vecVel[3];
			GetEntPropVector(this.iClient, Prop_Data, "m_vecVelocity", vecVel);
			
			float flCharge = GetVectorLength(vecVel) / this.flSpeed;	//flSpeedMulti? meh
			if (flCharge > 1.0)
				flCharge = 1.0;
			
			GetVectorAngles(vecVel, vecAng);
			
			vecVel[0] = Cosine(DegToRad(vecAng[0])) * Cosine(DegToRad(vecAng[1])) * 700.0 * flCharge;
			vecVel[1] = Cosine(DegToRad(vecAng[0])) * Sine(DegToRad(vecAng[1])) * 700.0 * flCharge;
			vecVel[2] = 360.0;
			
			SetEntProp(this.iClient, Prop_Send, "m_bJumping", true);
			
			TeleportEntity(this.iClient, NULL_VECTOR, NULL_VECTOR, vecVel);
		}
	}
	
	public void OnThink()
	{
		if (g_flJumpCooldown[this.iClient] != 0.0 && GetGameTime() > g_flJumpCooldown[this.iClient])
			g_flJumpCooldown[this.iClient] = 0.0;
	}
	
	public void GetHudText(char[] sMessage, int iLength)
	{
		if (g_flJumpCooldown[this.iClient] == 0.0)
		{
			StrCat(sMessage, iLength, "\nPress spacebar to leap!");
		}
		else
		{
			int iSec = RoundToNearest(g_flJumpCooldown[this.iClient]-GetGameTime());
			Format(sMessage, iLength, "%s\nLeap cooldown %i second%s remaining!", sMessage, iSec, (iSec > 1) ? "s" : "");
		}
	}
	
	public void Destroy()
	{
		TF2Attrib_RemoveByDefIndex(this.iClient, ATTRIB_NO_JUMP);
		g_flJumpCooldown[this.iClient] = 0.0;
	}
};