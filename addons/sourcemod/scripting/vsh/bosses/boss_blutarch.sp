#define BLUTARCH_MODEL		"models/player/kirillian/boss/boss_blutarch_v2.mdl"

static char g_strBlutarchRoundStart[][] = {
	"vo/halloween_mann_brothers/sf13_mannbros_argue09.mp3",
	"vo/halloween_mann_brothers/sf13_mannbros_argue14.mp3",
};

static char g_strBlutarchWin[][] = {
	"vo/halloween_mann_brothers/sf13_blutarch_win04.mp3",
	"vo/halloween_mann_brothers/sf13_blutarch_win11.mp3",
	"vo/halloween_mann_brothers/sf13_blutarch_winning06.mp3",
};

static char g_strBlutarchDeath[][] = {
	"vo/halloween_mann_brothers/sf13_blutarch_almost_lost01.mp3",
	"vo/halloween_mann_brothers/sf13_blutarch_almost_lost03.mp3",
	"vo/halloween_mann_brothers/sf13_blutarch_almost_lost05.mp3",
};

static char g_strBlutarchLose[][] = {
	"vo/halloween_mann_brothers/sf13_blutarch_lose01.mp3",
	"vo/halloween_mann_brothers/sf13_blutarch_lose04.mp3",
	"vo/halloween_mann_brothers/sf13_blutarch_lose07.mp3",
};
/*
static char g_strBlutarchSpell[][] = {
	"vo/halloween_mann_brothers/sf13_blutarch_misc01.mp3",
	"vo/halloween_mann_brothers/sf13_blutarch_spells04.mp3",
	"vo/halloween_mann_brothers/sf13_blutarch_spells05.mp3",
};
*/
static char g_strBlutarchRage[][] = {
	"vo/halloween_mann_brothers/sf13_blutarch_spells04.mp3",
	"vo/halloween_mann_brothers/sf13_blutarch_spells05.mp3",
	"vo/halloween_mann_brothers/sf13_blutarch_midnight01.mp3",
};

static char g_strBlutarchLastMan[][] = {
	"vo/halloween_mann_brothers/sf13_blutarch_almost_won02.mp3",
	"vo/halloween_mann_brothers/sf13_blutarch_almost_won03.mp3",
	"vo/halloween_mann_brothers/sf13_blutarch_almost_won09.mp3",
};

static char g_strBlutarchBackstabbed[][] = {
	"vo/halloween_mann_brothers/sf13_blutarch_enemies01.mp3",
	"vo/halloween_mann_brothers/sf13_blutarch_enemies02.mp3",
	"vo/halloween_mann_brothers/sf13_blutarch_enemies03.mp3",
};

methodmap CBlutarch < SaxtonHaleBase
{
	public CBlutarch(CBlutarch boss)
	{
		CWeaponSpells weaponSpells = boss.CallFunction("CreateAbility", "CWeaponSpells");
		weaponSpells.AddSpells(haleSpells_Bats);
		weaponSpells.RageSpells(haleSpells_Meteor);
		weaponSpells.flRageRequirement = 0.20;
		
		boss.iBaseHealth = 500;
		boss.iHealthPerPlayer = 700;
		boss.nClass = TFClass_Spy;
		boss.iMaxRageDamage = 2500;
	}
	
	public void GetBossName(char[] sName, int length)
	{
		strcopy(sName, length, "Blutarch");
	}
	
	public void GetBossInfo(char[] sInfo, int length)
	{
		StrCat(sInfo, length, "\nDuo Boss with Redmond");
		StrCat(sInfo, length, "\nMelee deals 124 damage");
		StrCat(sInfo, length, "\nHealth: Low");
		StrCat(sInfo, length, "\n ");
		StrCat(sInfo, length, "\nAbilities");
		StrCat(sInfo, length, "\n- Spells: alt-attack to use Bats spell for 20%% of rage");
		StrCat(sInfo, length, "\n ");
		StrCat(sInfo, length, "\nRage");
		StrCat(sInfo, length, "\n- Summons a Meteor spell");
		StrCat(sInfo, length, "\n- 200%% Rage: Summons 3 Meteor spells");
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
	
	public void OnDeath(Event eventInfo)
	{
		if (!g_bRoundStarted) return;
		
		for (int iClient = 1; iClient <= MaxClients; iClient++)
		{
			SaxtonHaleBase boss = SaxtonHaleBase(iClient);
			if (boss.bValid && IsPlayerAlive(iClient))
			{
				char sType[128];
				boss.CallFunction("GetBossType", sType, sizeof(sType));
				if (StrEqual(sType, "CRedmond"))
				{
					char sSound[PLATFORM_MAX_PATH];
					strcopy(sSound, sizeof(sSound), g_strBlutarchDeath[GetRandomInt(0,sizeof(g_strBlutarchDeath)-1)]);
					BroadcastSoundToTeam(TFTeam_Spectator, sSound);
					return;
				}
			}
		}
	}
	
	public void GetModel(char[] sModel, int length)
	{
		strcopy(sModel, length, BLUTARCH_MODEL);
	}
	
	public void GetSound(char[] sSound, int length, SaxtonHaleSound iSoundType)
	{
		switch (iSoundType)
		{
			case VSHSound_RoundStart: strcopy(sSound, length, g_strBlutarchRoundStart[GetRandomInt(0,sizeof(g_strBlutarchRoundStart)-1)]);
			case VSHSound_Win: strcopy(sSound, length, g_strBlutarchWin[GetRandomInt(0,sizeof(g_strBlutarchWin)-1)]);
			case VSHSound_Lose: strcopy(sSound, length, g_strBlutarchLose[GetRandomInt(0,sizeof(g_strBlutarchLose)-1)]);
			case VSHSound_Rage: strcopy(sSound, length, g_strBlutarchRage[GetRandomInt(0,sizeof(g_strBlutarchRage)-1)]);
			case VSHSound_Lastman: strcopy(sSound, length, g_strBlutarchLastMan[GetRandomInt(0,sizeof(g_strBlutarchLastMan)-1)]);
			case VSHSound_Backstab: strcopy(sSound, length, g_strBlutarchBackstabbed[GetRandomInt(0,sizeof(g_strBlutarchBackstabbed)-1)]);
		}
	}
	
	/*
	public void GetSoundAbility(char[] sSound, int length, const char[] sType)
	{
		if (strcmp(sType, "CWeaponSpells") == 0 && GetRandomInt(0, 1))
			strcopy(sSound, length, g_strBlutarchSpell[GetRandomInt(0,sizeof(g_strBlutarchSpell)-1)]);
	}
	*/
	
	public Action OnSoundPlayed(int clients[MAXPLAYERS], int &numClients, char sample[PLATFORM_MAX_PATH], int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
	{
		if (strncmp(sample, "vo/", 3) == 0 && strncmp(sample, "vo/halloween_mann_brothers/", 27) != 0)
			return Plugin_Handled;
		return Plugin_Continue;
	}
	
	public void Precache()
	{
		PrecacheModel(BLUTARCH_MODEL);
		
		for (int i = 0; i < sizeof(g_strBlutarchRoundStart); i++) PrecacheSound(g_strBlutarchRoundStart[i]);
		for (int i = 0; i < sizeof(g_strBlutarchWin); i++) PrecacheSound(g_strBlutarchWin[i]);
		for (int i = 0; i < sizeof(g_strBlutarchDeath); i++) PrecacheSound(g_strBlutarchDeath[i]);
		for (int i = 0; i < sizeof(g_strBlutarchLose); i++) PrecacheSound(g_strBlutarchLose[i]);
		//for (int i = 0; i < sizeof(g_strBlutarchSpell); i++) PrecacheSound(g_strBlutarchSpell[i]);
		for (int i = 0; i < sizeof(g_strBlutarchRage); i++) PrecacheSound(g_strBlutarchRage[i]);
		for (int i = 0; i < sizeof(g_strBlutarchLastMan); i++) PrecacheSound(g_strBlutarchLastMan[i]);
		for (int i = 0; i < sizeof(g_strBlutarchBackstabbed); i++) PrecacheSound(g_strBlutarchBackstabbed[i]);
		
		AddFileToDownloadsTable("models/player/kirillian/boss/boss_blutarch_v2.mdl");
		AddFileToDownloadsTable("models/player/kirillian/boss/boss_blutarch_v2.sw.vtx");
		AddFileToDownloadsTable("models/player/kirillian/boss/boss_blutarch_v2.vvd");
		AddFileToDownloadsTable("models/player/kirillian/boss/boss_blutarch_v2.dx80.vtx");
		AddFileToDownloadsTable("models/player/kirillian/boss/boss_blutarch_v2.dx90.vtx");
		AddFileToDownloadsTable("models/player/kirillian/boss/boss_blutarch_v2.phy");
	}
};