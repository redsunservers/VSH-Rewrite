static int g_iRageLightColor[MAXPLAYERS][4];

public void LightRage_SetColor(SaxtonHaleBase boss, int iColor[4])
{
	g_iRageLightColor[boss.iClient] = iColor;
}

public void LightRage_Create(SaxtonHaleBase boss)
{
	int lightColor[4];
	for (int i = 0; i < 4; i++) lightColor[i] = 255;
	LightRage_SetColor(boss, lightColor);
	boss.SetPropFloat("LightRage", "LigthRageDuration", 10.0);
	boss.SetPropFloat("LightRage", "LightRageRadius", 450.0);
	boss.SetPropInt("LightRage", "RageLightBrigthness", 10);
}

public void LightRage_OnRage(SaxtonHaleBase boss)
{
	int iColor[4];
	iColor = g_iRageLightColor[boss.iClient];
	
	int iGlow = TF2_CreateLightEntity(boss.GetPropFloat("LightRage", "LightRageRadius"), iColor, boss.GetPropInt("LightRage", "RageLightBrigthness"));
	if (iGlow != -1)
	{			
		float vecEyepos[3];
		GetClientEyePosition(boss.iClient, vecEyepos);
		TeleportEntity(iGlow, vecEyepos, view_as<float>({ 90.0, 0.0, 0.0 }), NULL_VECTOR);

		SetVariantString("!activator");
		AcceptEntityInput(iGlow, "SetParent", boss.iClient);
		
		float flDuration = boss.GetPropFloat("LightRage", "LigthRageDuration");
		if (boss.bSuperRage)
			flDuration *= 2.0;
		CreateTimer(flDuration, Timer_DestroyLight, EntIndexToEntRef(iGlow));
	}
}
