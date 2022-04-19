static char g_strMannBrothersRoundStart[][] = {
	"vo/halloween_mann_brothers/sf13_mannbros_argue09.mp3",
	"vo/halloween_mann_brothers/sf13_mannbros_argue13.mp3",
	"vo/halloween_mann_brothers/sf13_mannbros_argue14.mp3",
};

public void MannBrothers_Create(SaxtonHaleBase boss)
{
}

public void MannBrothers_GetBossMultiList(SaxtonHaleBase boss, ArrayList aList)
{
	aList.PushString("Blutarch");
	aList.PushString("Redmond");
}

public void MannBrothers_GetBossMultiName(SaxtonHaleBase boss, char[] sName, int length)
{
	strcopy(sName, length, "Mann Brothers");
}

public void MannBrothers_GetBossMultiInfo(SaxtonHaleBase boss, char[] sInfo, int length)
{
	StrCat(sInfo, length, "\nMelee deals 124 damage");
	StrCat(sInfo, length, "\nHealth: Low");
	StrCat(sInfo, length, "\n ");
	StrCat(sInfo, length, "\nAbilities");
	StrCat(sInfo, length, "\n- Spells: alt-attack to use spell for 20%% of rage");
	StrCat(sInfo, length, "\n- Redmond uses Bats spell, Blutarch uses Teleport spell");
	StrCat(sInfo, length, "\n ");
	StrCat(sInfo, length, "\nRage");
	StrCat(sInfo, length, "\n- Redmond gets a Meteor spell, Blutarch gets a MONOCULUS! spell");
	StrCat(sInfo, length, "\n- 200%% Rage: Grants 3 spells");
}

public void MannBrothers_OnSpawn(SaxtonHaleBase boss)
{
	char attribs[128];
	Format(attribs, sizeof(attribs), "2 ; 3.1 ; 252 ; 0.5 ; 259 ; 1.0");
	int iWeapon = boss.CallFunction("CreateWeapon", 574, "tf_weapon_knife", 100, TFQual_Haunted, attribs);
	if (iWeapon > MaxClients)
		SetEntPropEnt(boss.iClient, Prop_Send, "m_hActiveWeapon", iWeapon);
	/*
	Wanga Prick attributes:
	
	2: damage bonus
	252: reduction in push force taken from damage
	259: Deals 3x falling damage to the player you land on
	*/
}

public void MannBrothers_GetSound(SaxtonHaleBase boss, char[] sSound, int length, SaxtonHaleSound iSoundType)
{
	if (iSoundType == VSHSound_RoundStart)
		strcopy(sSound, length, g_strMannBrothersRoundStart[GetRandomInt(0,sizeof(g_strMannBrothersRoundStart)-1)]);
}

public Action MannBrothers_OnSoundPlayed(SaxtonHaleBase boss, int clients[MAXPLAYERS], int &numClients, char sample[PLATFORM_MAX_PATH], int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
	if (strncmp(sample, "vo/", 3) == 0 && strncmp(sample, "vo/halloween_mann_brothers/", 27) != 0)
		return Plugin_Handled;
	return Plugin_Continue;
}

public void MannBrothers_Precache(SaxtonHaleBase boss)
{
	for (int i = 0; i < sizeof(g_strMannBrothersRoundStart); i++) PrecacheSound(g_strMannBrothersRoundStart[i]);
}
