static float g_flClientAngryLastTime[TF_MAXPLAYERS+1];

methodmap CModifiersAngry < SaxtonHaleBase
{
	public CModifiersAngry(CModifiersAngry boss)
	{
		boss.iMaxRageDamage = RoundToNearest(float(boss.iMaxRageDamage) * 0.5);
		boss.flMaxRagePercentage *= 1.25;	//2.0 -> 2.5
	}
	
	public void GetModifiersName(char[] sName, int length)
	{
		strcopy(sName, length, "Angry");
	}
	
	public void GetModifiersInfo(char[] sInfo, int length)
	{
		StrCat(sInfo, length, "\nColor: Brown");
		StrCat(sInfo, length, "\n ");
		StrCat(sInfo, length, "\n- Gains twice as much rage");
		StrCat(sInfo, length, "\n- Increase max rage percentage cap to 250%%");
		StrCat(sInfo, length, "\n- Loses rage over time");
	}
	
	public int GetRenderColor(int iColor[4])
	{
		iColor[0] = 192;
		iColor[1] = 128;
		iColor[2] = 56;
		iColor[3] = 255;
	}
	
	public void OnThink()
	{
		if (g_flClientAngryLastTime[this.iClient] <= GetGameTime() - 0.02)	//50 dmg per second
		{
			this.CallFunction("AddRage", -1);
			g_flClientAngryLastTime[this.iClient] = GetGameTime();
		}
	}
};