public void ModifiersSpeed_Create(SaxtonHaleBase boss)
{
	boss.flSpeed *= 1.08;
	boss.flSpeedMult *= 3.0;
	boss.iMaxRageDamage = RoundToNearest(float(boss.iMaxRageDamage) * 1.2);
}

public void ModifiersSpeed_GetModifiersName(SaxtonHaleBase boss, char[] sName, int length)
{
	strcopy(sName, length, "Speedy");
}

public void ModifiersSpeed_GetModifiersInfo(SaxtonHaleBase boss, char[] sInfo, int length)
{
	StrCat(sInfo, length, "\nColor: Green");
	StrCat(sInfo, length, "\n ");
	StrCat(sInfo, length, "\n- Faster movement speed");
	StrCat(sInfo, length, "\n- 20%% less rage gain");
}

public void ModifiersSpeed_GetRenderColor(SaxtonHaleBase boss, int iColor[4])
{
	iColor[0] = 176;
	iColor[1] = 255;
	iColor[2] = 144;
	iColor[3] = 255;
}

public void ModifiersSpeed_GetParticleEffect(SaxtonHaleBase boss, int index, char[] sEffect, int length)
{
	if (index == 0)
		strcopy(sEffect, length, "utaunt_auroraglow_green_parent");
}
