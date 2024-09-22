public void ModifiersOverload_Create(SaxtonHaleBase boss)
{
	//Basically 165% required for super rage
	boss.iMaxRageDamage = RoundToNearest(float(boss.iMaxRageDamage) * 1.65);
	boss.flMaxRagePercentage = 1.0;	//Hard set 100% cap
}

public void ModifiersOverload_GetModifiersName(SaxtonHaleBase boss, char[] sName, int length)
{
	strcopy(sName, length, "Overload");
}

public void ModifiersOverload_GetModifiersInfo(SaxtonHaleBase boss, char[] sInfo, int length)
{
	StrCat(sInfo, length, "\nColor: Orange");
	StrCat(sInfo, length, "\n ");
	StrCat(sInfo, length, "\n- Normal Rage becomes Super Rage");
	StrCat(sInfo, length, "\n- 65%% less rage gain");
	StrCat(sInfo, length, "\n- Rage percentage can't go above 100%%");
}

public void ModifiersOverload_GetRenderColor(SaxtonHaleBase boss, int iColor[4])
{
	iColor[0] = 255;
	iColor[1] = 144;
	iColor[2] = 0;
	iColor[3] = 255;
}

public void ModifiersOverload_GetParticleEffect(SaxtonHaleBase boss, int index, char[] sEffect, int length)
{
	switch (index)
	{
		case 0:
			strcopy(sEffect, length, "utaunt_god_gold_beam_cp");
		
		case 1:
			strcopy(sEffect, length, "utaunt_twinkling_goldsilver_glow01");
	}
}
