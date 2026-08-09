#define SEE_BOSSES_INTRO_SND				"vsh_rewrite/seeman/intro.mp3"
#define SEEMAN_SEELDIER_THEME				"vsh_rewrite/seeman/theme.mp3"
#define SEEMAN_SEELDIER_THEME_TIME			178.0

public void SeeManSeeldier_Create(SaxtonHaleBase boss)
{
}

public void SeeManSeeldier_GetBossMultiList(SaxtonHaleBase boss, ArrayList aList)
{
	aList.PushString("SeeMan");
	aList.PushString("Seeldier");
}

public void SeeManSeeldier_GetBossMultiName(SaxtonHaleBase boss, char[] sName, int length)
{
	strcopy(sName, length, "Seeman and Seeldier");
}

public void SeeManSeeldier_GetBossMultiInfo(SaxtonHaleBase boss, char[] sInfo, int length)
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

public void SeeManSeeldier_GetSound(SaxtonHaleBase boss, char[] sSound, int length, SaxtonHaleSound iSoundType)
{
	if (iSoundType == VSHSound_RoundStart)
		strcopy(sSound, length, SEE_BOSSES_INTRO_SND);
}

public void SeeManSeeldier_GetMusicInfo(SaxtonHaleBase boss, char[] sSound, int length, float &time)
{
	if (StrEmpty(SEEMAN_SEELDIER_THEME))
		return;

	strcopy(sSound, length, SEEMAN_SEELDIER_THEME);
	time = SEEMAN_SEELDIER_THEME_TIME;
}

public void SeeManSeeldier_Precache(SaxtonHaleBase boss)
{
	PrepareSound(SEE_BOSSES_INTRO_SND);

	if (!StrEmpty(SEEMAN_SEELDIER_THEME))
		PrepareMusic(SEEMAN_SEELDIER_THEME);
}

