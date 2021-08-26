static float g_flLightRageDuration[TF_MAXPLAYERS];
static float g_flLightRageRadius[TF_MAXPLAYERS];
static int g_iRageLightColor[TF_MAXPLAYERS][4];
static int g_iRageLightBrigthness[TF_MAXPLAYERS];

methodmap CLightRage < SaxtonHaleBase
{
	property float flLigthRageDuration
	{
		public set(float flVal)
		{
			g_flLightRageDuration[this.iClient] = flVal;
		}
		public get()
		{
			return g_flLightRageDuration[this.iClient];
		}
	}
	
	property float flLightRageRadius
	{
		public set(float flVal)
		{
			g_flLightRageRadius[this.iClient] = flVal;
		}
		public get()
		{
			return g_flLightRageRadius[this.iClient];
		}
	}
	
	property int iRageLightBrigthness
	{
		public set(int iVal)
		{
			g_iRageLightBrigthness[this.iClient] = iVal;
		}
		public get()
		{
			return g_iRageLightBrigthness[this.iClient];
		}
	}
	
	public void SetColor(int iColor[4])
	{
		g_iRageLightColor[this.iClient] = iColor;
	}
	
	public CLightRage(CLightRage ability)
	{
		int lightColor[4];
		for (int i = 0; i < 4; i++) lightColor[i] = 255;
		ability.SetColor(lightColor);
		ability.flLigthRageDuration = 10.0;
		ability.flLightRageRadius = 450.0;
		ability.iRageLightBrigthness = 10;
	}
	
	public void OnRage()
	{
		int iColor[4];
		iColor = g_iRageLightColor[this.iClient];
		
		int iGlow = TF2_CreateLightEntity(this.flLightRageRadius, iColor, this.iRageLightBrigthness);
		if (iGlow != -1)
		{			
			float vecEyepos[3];
			GetClientEyePosition(this.iClient, vecEyepos);
			TeleportEntity(iGlow, vecEyepos, view_as<float>({ 90.0, 0.0, 0.0 }), NULL_VECTOR);

			SetVariantString("!activator");
			AcceptEntityInput(iGlow, "SetParent", this.iClient);
			
			float flDuration = this.flLigthRageDuration;
			if (this.bSuperRage)
				flDuration *= 2.0;
			CreateTimer(flDuration, Timer_DestroyLight, EntIndexToEntRef(iGlow));
		}
	}
};