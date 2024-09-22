static float g_flClientAngryLastTime[MAXPLAYERS];

public void ModifiersAngry_Create(SaxtonHaleBase boss)
{
	boss.iMaxRageDamage = RoundToNearest(float(boss.iMaxRageDamage) * 0.5);
	boss.flMaxRagePercentage *= 1.25;	//2.0 -> 2.5
}

public void ModifiersAngry_GetModifiersName(SaxtonHaleBase boss, char[] sName, int length)
{
	strcopy(sName, length, "Angry");
}

public void ModifiersAngry_GetModifiersInfo(SaxtonHaleBase boss, char[] sInfo, int length)
{
	StrCat(sInfo, length, "\nColor: Brown");
	StrCat(sInfo, length, "\n ");
	StrCat(sInfo, length, "\n- Gains twice as much rage");
	StrCat(sInfo, length, "\n- Increase max rage percentage cap to 250%%");
	StrCat(sInfo, length, "\n- Loses rage over time");
}

public void ModifiersAngry_GetRenderColor(SaxtonHaleBase boss, int iColor[4])
{
	iColor[0] = 144;
	iColor[1] = 96;
	iColor[2] = 48;
	iColor[3] = 255;
}

public void ModifiersAngry_GetParticleEffect(SaxtonHaleBase boss, int index, char[] sEffect, int length)
{
	if (index == 0)
		strcopy(sEffect, length, "utaunt_storm_cloud_o");
}

public void ModifiersAngry_OnThink(SaxtonHaleBase boss)
{
	if (g_flClientAngryLastTime[boss.iClient] <= GetGameTime() - 0.02)	//50 dmg per second
	{
		boss.CallFunction("AddRage", -1);
		g_flClientAngryLastTime[boss.iClient] = GetGameTime();
	}
}
