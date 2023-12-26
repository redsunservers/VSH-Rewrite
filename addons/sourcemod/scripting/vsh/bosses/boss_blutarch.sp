#define BLUTARCH_MODEL		"models/player/kirillian/boss/boss_blutarch_v2.mdl"

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

public void Blutarch_Create(SaxtonHaleBase boss)
{
	boss.CreateClass("WeaponSpells");
	WeaponSpells_AddSpells(boss, haleSpells_Bats);
	WeaponSpells_RageSpells(boss, haleSpells_Meteor);
	boss.SetPropFloat("WeaponSpells", "RageRequirement", 0.0);
	boss.SetPropFloat("WeaponSpells", "Cooldown", 15.0);
	
	boss.iHealthPerPlayer = 550;
	boss.flHealthExponential = 1.05;
	boss.nClass = TFClass_Spy;
	boss.iMaxRageDamage = 2500;
}

public void Blutarch_GetBossMultiType(SaxtonHaleBase boss, char[] sType, int length)
{
	strcopy(sType, length, "MannBrothers");
}

public bool Blutarch_IsBossHidden(SaxtonHaleBase boss)
{
	return true;
}

public void Blutarch_GetBossName(SaxtonHaleBase boss, char[] sName, int length)
{
	strcopy(sName, length, "Blutarch");
}

public void Blutarch_GetBossInfo(SaxtonHaleBase boss, char[] sInfo, int length)
{
	StrCat(sInfo, length, "\nDuo Boss with Redmond");
	StrCat(sInfo, length, "\nMelee deals 124 damage");
	StrCat(sInfo, length, "\nHealth: Low");
	StrCat(sInfo, length, "\n ");
	StrCat(sInfo, length, "\nAbilities");
	StrCat(sInfo, length, "\n- Alt-attack to use Bats spell for 15 seconds cooldown");
	StrCat(sInfo, length, "\n ");
	StrCat(sInfo, length, "\nRage");
	StrCat(sInfo, length, "\n- Damage requirement: 2500");
	StrCat(sInfo, length, "\n- Summons a Meteor spell");
	StrCat(sInfo, length, "\n- 200%% Rage: Summons 3 Meteor spells");
}

public void Blutarch_GetModel(SaxtonHaleBase boss, char[] sModel, int length)
{
	strcopy(sModel, length, BLUTARCH_MODEL);
}

public void Blutarch_GetSound(SaxtonHaleBase boss, char[] sSound, int length, SaxtonHaleSound iSoundType)
{
	switch (iSoundType)
	{
		case VSHSound_Win: strcopy(sSound, length, g_strBlutarchWin[GetRandomInt(0,sizeof(g_strBlutarchWin)-1)]);
		case VSHSound_Lose: strcopy(sSound, length, g_strBlutarchLose[GetRandomInt(0,sizeof(g_strBlutarchLose)-1)]);
		case VSHSound_Rage: strcopy(sSound, length, g_strBlutarchRage[GetRandomInt(0,sizeof(g_strBlutarchRage)-1)]);
		case VSHSound_Lastman: strcopy(sSound, length, g_strBlutarchLastMan[GetRandomInt(0,sizeof(g_strBlutarchLastMan)-1)]);
		case VSHSound_Backstab: strcopy(sSound, length, g_strBlutarchBackstabbed[GetRandomInt(0,sizeof(g_strBlutarchBackstabbed)-1)]);
		case VSHSound_Death: strcopy(sSound, length, g_strBlutarchDeath[GetRandomInt(0,sizeof(g_strBlutarchDeath)-1)]);
	}
}

public void Blutarch_Precache(SaxtonHaleBase boss)
{
	PrecacheModel(BLUTARCH_MODEL);
	
	for (int i = 0; i < sizeof(g_strBlutarchWin); i++) PrecacheSound(g_strBlutarchWin[i]);
	for (int i = 0; i < sizeof(g_strBlutarchDeath); i++) PrecacheSound(g_strBlutarchDeath[i]);
	for (int i = 0; i < sizeof(g_strBlutarchLose); i++) PrecacheSound(g_strBlutarchLose[i]);
	for (int i = 0; i < sizeof(g_strBlutarchRage); i++) PrecacheSound(g_strBlutarchRage[i]);
	for (int i = 0; i < sizeof(g_strBlutarchLastMan); i++) PrecacheSound(g_strBlutarchLastMan[i]);
	for (int i = 0; i < sizeof(g_strBlutarchBackstabbed); i++) PrecacheSound(g_strBlutarchBackstabbed[i]);
	
	AddFileToDownloadsTable("models/player/kirillian/boss/boss_blutarch_v2.mdl");
	AddFileToDownloadsTable("models/player/kirillian/boss/boss_blutarch_v2.vvd");
	AddFileToDownloadsTable("models/player/kirillian/boss/boss_blutarch_v2.dx80.vtx");
	AddFileToDownloadsTable("models/player/kirillian/boss/boss_blutarch_v2.dx90.vtx");
	AddFileToDownloadsTable("models/player/kirillian/boss/boss_blutarch_v2.phy");
}
