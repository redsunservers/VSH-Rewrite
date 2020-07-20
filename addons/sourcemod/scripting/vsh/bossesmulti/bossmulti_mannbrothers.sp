static char g_strMannBrothersRoundStart[][] = {
	"vo/halloween_mann_brothers/sf13_mannbros_argue09.mp3",
	"vo/halloween_mann_brothers/sf13_mannbros_argue13.mp3",
	"vo/halloween_mann_brothers/sf13_mannbros_argue14.mp3",
};

methodmap CMannBrothers < SaxtonHaleBase
{
	public CMannBrothers(CMannBrothers boss)
	{
	}
	
	public void GetBossMultiList(ArrayList aList)
	{
		aList.PushString("CBlutarch");
		aList.PushString("CRedmond");
	}
	
	public void GetBossMultiName(char[] sName, int length)
	{
		strcopy(sName, length, "Mann Brothers");
	}
	
	public void GetBossMultiInfo(char[] sInfo, int length)
	{
		StrCat(sInfo, length, "\nMelee deals 124 damage");
		StrCat(sInfo, length, "\nHealth: Low");
		StrCat(sInfo, length, "\n ");
		StrCat(sInfo, length, "\nAbilities");
		StrCat(sInfo, length, "\n- Spells: alt-attack to use spell for 20%% of rage");
		StrCat(sInfo, length, "\n- Redmond use Bats spell, Blutarch use Teleport spell");
		StrCat(sInfo, length, "\n ");
		StrCat(sInfo, length, "\nRage");
		StrCat(sInfo, length, "\n- Redmond summons a Meteor spell, Blutarch summons a MONOCULUS! spell");
		StrCat(sInfo, length, "\n- 200%% Rage: Summons 3 spells");
	}
	
	public void OnSpawn()
	{
		char attribs[128];
		Format(attribs, sizeof(attribs), "2 ; 3.1 ; 252 ; 0.5 ; 259 ; 1.0");
		int iWeapon = this.CallFunction("CreateWeapon", 574, "tf_weapon_knife", 100, TFQual_Haunted, attribs);
		if (iWeapon > MaxClients)
			SetEntPropEnt(this.iClient, Prop_Send, "m_hActiveWeapon", iWeapon);
		/*
		Wanga Prick attributes:
		
		2: damage bonus
		252: reduction in push force taken from damage
		259: Deals 3x falling damage to the player you land on
		*/
	}
	
	public void GetSound(char[] sSound, int length, SaxtonHaleSound iSoundType)
	{
		if (iSoundType == VSHSound_RoundStart)
			strcopy(sSound, length, g_strMannBrothersRoundStart[GetRandomInt(0,sizeof(g_strMannBrothersRoundStart)-1)]);
	}
	
	public Action OnSoundPlayed(int clients[MAXPLAYERS], int &numClients, char sample[PLATFORM_MAX_PATH], int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
	{
		if (strncmp(sample, "vo/", 3) == 0 && strncmp(sample, "vo/halloween_mann_brothers/", 27) != 0)
			return Plugin_Handled;
		return Plugin_Continue;
	}
	
	public void Precache()
	{
		for (int i = 0; i < sizeof(g_strMannBrothersRoundStart); i++) PrecacheSound(g_strMannBrothersRoundStart[i]);
	}
};