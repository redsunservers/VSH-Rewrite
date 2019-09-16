methodmap CModifiersSpeed < SaxtonHaleBase
{
	public CModifiersSpeed(CModifiersSpeed boss)
	{
		boss.flSpeedMult *= 3.0;
		boss.iMaxRageDamage = RoundToNearest(float(boss.iMaxRageDamage) * 1.35);
	}
	
	public void GetModifiersName(char[] sName, int length)
	{
		strcopy(sName, length, "Speedy");
	}
	
	public void GetModifiersInfo(char[] sInfo, int length)
	{
		StrCat(sInfo, length, "\nColor: Green");
		StrCat(sInfo, length, "\n ");
		StrCat(sInfo, length, "\n- Much faster movement speed as the boss loses health");
		StrCat(sInfo, length, "\n- 35%% less rage gain");
	}
	
	public int GetRenderColor(int iColor[4])
	{
		iColor[0] = 176;
		iColor[1] = 255;
		iColor[2] = 144;
		iColor[3] = 255;
	}
};