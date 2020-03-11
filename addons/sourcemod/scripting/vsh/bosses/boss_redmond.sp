#define REDMOND_MODEL		"models/player/kirillian/boss/boss_redmond_v2.mdl"

static char g_strRedmondRoundStart[][] = {
	"vo/halloween_mann_brothers/sf13_mannbros_argue09.mp3",
	"vo/halloween_mann_brothers/sf13_mannbros_argue13.mp3",
};

static char g_strRedmondWin[][] = {
	"vo/halloween_mann_brothers/sf13_redmond_win05.mp3",
	"vo/halloween_mann_brothers/sf13_redmond_win08.mp3",
	"vo/halloween_mann_brothers/sf13_redmond_winning17.mp3",
	"vo/halloween_mann_brothers/sf13_redmond_winning18.mp3",
};

static char g_strRedmondDeath[][] = {
	"vo/halloween_mann_brothers/sf13_redmond_almost_lost01.mp3",
	"vo/halloween_mann_brothers/sf13_redmond_losing02.mp3",
	"vo/halloween_mann_brothers/sf13_redmond_lose07.mp3",
};

static char g_strRedmondLose[][] = {
	"vo/halloween_mann_brothers/sf13_redmond_lose02.mp3",
	"vo/halloween_mann_brothers/sf13_redmond_lose07.mp3",
	"vo/halloween_mann_brothers/sf13_redmond_lose08.mp3",
};
/*
static char g_strRedmondSpell[][] = {
	"vo/halloween_mann_brothers/sf13_redmond_spells02.mp3",
	"vo/halloween_mann_brothers/sf13_redmond_spells06.mp3",
};
*/
static char g_strRedmondRage[][] = {
	"vo/halloween_mann_brothers/sf13_redmond_spells02.mp3",
	"vo/halloween_mann_brothers/sf13_redmond_spells06.mp3",
	"vo/halloween_mann_brothers/sf13_redmond_midnight01.mp3",
};

static char g_strRedmondLastMan[][] = {
	"vo/halloween_mann_brothers/sf13_redmond_almost_won01.mp3",
	"vo/halloween_mann_brothers/sf13_redmond_winning07.mp3",
	"vo/halloween_mann_brothers/sf13_redmond_winning17.mp3",
};

static char g_strRedmondBackstabbed[][] = {
	"vo/halloween_mann_brothers/sf13_redmond_losing01.mp3",
	"vo/halloween_mann_brothers/sf13_redmond_losing19.mp3",
};

methodmap CRedmond < SaxtonHaleBase
{
	public CRedmond(CRedmond boss)
	{
		CWeaponSpells weaponSpells = boss.CallFunction("CreateAbility", "CWeaponSpells");
		weaponSpells.AddSpells(haleSpells_Teleport);
		weaponSpells.RageSpells(haleSpells_Monoculus);
		weaponSpells.flRageRequirement = 0.20;
		
		boss.iBaseHealth = 500;
		boss.iHealthPerPlayer = 700;
		boss.nClass = TFClass_Spy;
		boss.iMaxRageDamage = 2500;
	}
	
	public void GetBossName(char[] sName, int length)
	{
		strcopy(sName, length, "Redmond");
	}
	
	public void GetBossInfo(char[] sInfo, int length)
	{
		StrCat(sInfo, length, "\nDuo Boss with Blutarch");
		StrCat(sInfo, length, "\nMelee deals 124 damage");
		StrCat(sInfo, length, "\nHealth: Low");
		StrCat(sInfo, length, "\n ");
		StrCat(sInfo, length, "\nAbilities");
		StrCat(sInfo, length, "\n- Spells: alt-attack to use Teleport spell for 20%% of rage");
		StrCat(sInfo, length, "\n  - Teleport");
		StrCat(sInfo, length, "\n ");
		StrCat(sInfo, length, "\nRage");
		StrCat(sInfo, length, "\n- Summons a MONOCULUS! spell");
		StrCat(sInfo, length, "\n- 200%% Rage: Summons 3 MONOCULUS! spells");
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
				if (StrEqual(sType, "CBlutarch"))
				{
					char sSound[PLATFORM_MAX_PATH];
					strcopy(sSound, sizeof(sSound), g_strRedmondDeath[GetRandomInt(0,sizeof(g_strRedmondDeath)-1)]);
					BroadcastSoundToTeam(TFTeam_Spectator, sSound);
					return;
				}
			}
		}
	}
	
	public Action OnAttackDamage(int victim, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
	{
		//Monos spell damage sucks, buff it
		if (weapon > MaxClients)
		{
			char sClassname[256];
			GetEntityClassname(weapon, sClassname, sizeof(sClassname));
			if (StrEqual(sClassname, "eyeball_boss"))
			{
				damage *= 1.5;
				return Plugin_Changed;
			}
		}
		
		return Plugin_Continue;
		
	}
	
	public void GetModel(char[] sModel, int length)
	{
		strcopy(sModel, length, REDMOND_MODEL);
	}
	
	public void GetSound(char[] sSound, int length, SaxtonHaleSound iSoundType)
	{
		switch (iSoundType)
		{
			case VSHSound_RoundStart: strcopy(sSound, length, g_strRedmondRoundStart[GetRandomInt(0,sizeof(g_strRedmondRoundStart)-1)]);
			case VSHSound_Win: strcopy(sSound, length, g_strRedmondWin[GetRandomInt(0,sizeof(g_strRedmondWin)-1)]);
			case VSHSound_Lose: strcopy(sSound, length, g_strRedmondLose[GetRandomInt(0,sizeof(g_strRedmondLose)-1)]);
			case VSHSound_Rage: strcopy(sSound, length, g_strRedmondRage[GetRandomInt(0,sizeof(g_strRedmondRage)-1)]);
			case VSHSound_Lastman: strcopy(sSound, length, g_strRedmondLastMan[GetRandomInt(0,sizeof(g_strRedmondLastMan)-1)]);
			case VSHSound_Backstab: strcopy(sSound, length, g_strRedmondBackstabbed[GetRandomInt(0,sizeof(g_strRedmondBackstabbed)-1)]);
		}
	}
	/*
	public void GetSoundAbility(char[] sSound, int length, const char[] sType)
	{
		if (strcmp(sType, "CWeaponSpells") == 0 && GetRandomInt(0, 1))
			strcopy(sSound, length, g_strRedmondSpell[GetRandomInt(0,sizeof(g_strRedmondSpell)-1)]);
	}
	*/
	public Action OnSoundPlayed(int clients[MAXPLAYERS], int &numClients, char sample[PLATFORM_MAX_PATH], int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
	{
		if (strncmp(sample, "vo/", 3) == 0)//Block voicelines
			return Plugin_Handled;
		return Plugin_Continue;
	}
	
	public void Precache()
	{
		PrecacheModel(REDMOND_MODEL);
		
		for (int i = 0; i < sizeof(g_strRedmondRoundStart); i++) PrecacheSound(g_strRedmondRoundStart[i]);
		for (int i = 0; i < sizeof(g_strRedmondWin); i++) PrecacheSound(g_strRedmondWin[i]);
		for (int i = 0; i < sizeof(g_strRedmondDeath); i++) PrecacheSound(g_strRedmondDeath[i]);
		for (int i = 0; i < sizeof(g_strRedmondLose); i++) PrecacheSound(g_strRedmondLose[i]);
		//for (int i = 0; i < sizeof(g_strRedmondSpell); i++) PrecacheSound(g_strRedmondSpell[i]);
		for (int i = 0; i < sizeof(g_strRedmondRage); i++) PrecacheSound(g_strRedmondRage[i]);
		for (int i = 0; i < sizeof(g_strRedmondLastMan); i++) PrecacheSound(g_strRedmondLastMan[i]);
		for (int i = 0; i < sizeof(g_strRedmondBackstabbed); i++) PrecacheSound(g_strRedmondBackstabbed[i]);
		
		AddFileToDownloadsTable("models/player/kirillian/boss/boss_redmond_v2.mdl");
		AddFileToDownloadsTable("models/player/kirillian/boss/boss_redmond_v2.sw.vtx");
		AddFileToDownloadsTable("models/player/kirillian/boss/boss_redmond_v2.vvd");
		AddFileToDownloadsTable("models/player/kirillian/boss/boss_redmond_v2.dx80.vtx");
		AddFileToDownloadsTable("models/player/kirillian/boss/boss_redmond_v2.dx90.vtx");
		AddFileToDownloadsTable("models/player/kirillian/boss/boss_redmond_v2.phy");
	}
};