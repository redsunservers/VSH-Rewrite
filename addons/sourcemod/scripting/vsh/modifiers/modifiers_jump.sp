methodmap CModifiersJump < SaxtonHaleBase
{
	public CModifiersJump(CModifiersJump boss)
	{
		CBraveJump bravejump = boss.CallFunction("CreateAbility", "CBraveJump");
		
		if (bravejump != INVALID_ABILITY)
		{
			bravejump.flCooldown *= 0.50;
			bravejump.flMaxHeight *= 0.75;
			bravejump.flMaxDistance *= 0.60;
		}
	}
	
	public bool IsModifiersHidden()
	{
		return true;
	}
	
	public void GetModifiersName(char[] sName, int length)
	{
		strcopy(sName, length, "Jumper");
	}
	
	public void GetModifiersInfo(char[] sInfo, int length)
	{
		StrCat(sInfo, length, "\nColor: Purple");
		StrCat(sInfo, length, "\n ");
		StrCat(sInfo, length, "\n- Brave Jump cooldown is halved");
		StrCat(sInfo, length, "\n- Less brave jump height");
	}
	
	public int GetRenderColor(int iColor[4])
	{
		iColor[0] = 160;
		iColor[1] = 144;
		iColor[2] = 255;
		iColor[3] = 255;
	}
};