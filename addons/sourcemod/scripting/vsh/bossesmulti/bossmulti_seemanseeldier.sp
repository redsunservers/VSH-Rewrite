#define SEE_BOSSES_INTRO_SND				"vsh_rewrite/seeman/intro.wav"

methodmap CSeeManSeeldier < SaxtonHaleBase
{
	public CSeeManSeeldier(CSeeManSeeldier bossmulti)
	{
	}
	
	public void GetBossMultiList(ArrayList aList)
	{
		aList.PushString("CSeeMan");
		aList.PushString("CSeeldier");
	}
	
	public void GetBossMultiName(char[] sName, int length)
	{
		strcopy(sName, length, "Seeman and Seeldier");
	}
	
	public void GetBossMultiInfo(char[] sInfo, int length)
	{
		StrCat(sInfo, length, "\nMelee deals 124 damage");
		StrCat(sInfo, length, "\nHealth: Low");
		StrCat(sInfo, length, "\n ");
		StrCat(sInfo, length, "\nAbilities");
		StrCat(sInfo, length, "\n- Brave Jump");
		StrCat(sInfo, length, "\n ");
		StrCat(sInfo, length, "\nRage");
		StrCat(sInfo, length, "\n- Seeman is frozen with Übercharge for 3 seconds with small explosions around him");
		StrCat(sInfo, length, "\n- 200%% Rage: Seeman gets an instakill nuke at end of rage");
		StrCat(sInfo, length, "\n- Seeldlier summons 3 mini-Seeldiers");
		StrCat(sInfo, length, "\n- 200%% Rage: Seeldlier summons 6 mini-Seeldiers");
	}
	
	public void GetSound(char[] sSound, int length, SaxtonHaleSound iSoundType)
	{
		if (iSoundType == VSHSound_RoundStart)
			strcopy(sSound, length, SEE_BOSSES_INTRO_SND);
	}
	
	public void Precache()
	{
		PrepareSound(SEE_BOSSES_INTRO_SND);
	}
};
