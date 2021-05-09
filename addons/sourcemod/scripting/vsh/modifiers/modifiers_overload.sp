methodmap CModifiersOverload < SaxtonHaleBase
{
	public CModifiersOverload(CModifiersOverload boss)
	{
		//Basically 165% required for super rage
		boss.iMaxRageDamage = RoundToNearest(float(boss.iMaxRageDamage) * 1.65);
		boss.flMaxRagePercentage = 1.0;	//Hard set 100% cap
	}
	
	public void GetModifiersName(char[] sName, int length)
	{
		strcopy(sName, length, "Overload");
	}
	
	public void GetModifiersInfo(char[] sInfo, int length)
	{
		StrCat(sInfo, length, "\nColor: Orange");
		StrCat(sInfo, length, "\n ");
		StrCat(sInfo, length, "\n- Normal Rage becomes Super Rage");
		StrCat(sInfo, length, "\n- 65%% less rage gain");
		StrCat(sInfo, length, "\n- Rage percentage can't go above 100%%");
	}
	
	public int GetRenderColor(int iColor[4])
	{
		iColor[0] = 255;
		iColor[1] = 144;
		iColor[2] = 0;
		iColor[3] = 255;
	}
};