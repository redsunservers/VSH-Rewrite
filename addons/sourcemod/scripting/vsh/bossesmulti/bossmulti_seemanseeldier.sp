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
		strcopy(sName, length, "SeeMan and Seeldier");
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
