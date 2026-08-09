#define REDMOND_MODEL		"models/player/kirillian/boss/boss_redmond_v2.mdl"

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

public void Redmond_Create(SaxtonHaleBase boss)
{
	boss.CreateClass("WeaponSpells");
	WeaponSpells_AddSpells(boss, haleSpells_Teleport);
	WeaponSpells_RageSpells(boss, haleSpells_Monoculus);
	boss.SetPropFloat("WeaponSpells", "RageRequirement", 0.0);
	boss.SetPropFloat("WeaponSpells", "Cooldown", 5.0);
	
	boss.iHealthPerPlayer = 550;
	boss.flHealthExponential = 1.05;
	boss.nClass = TFClass_Spy;
	boss.iMaxRageDamage = 2500;
}

public void Redmond_GetBossMultiType(SaxtonHaleBase boss, char[] sType, int length)
{
	strcopy(sType, length, "MannBrothers");
}

public bool Redmond_IsBossHidden(SaxtonHaleBase boss)
{
	return true;
}

public void Redmond_GetBossName(SaxtonHaleBase boss, char[] sName, int length)
{
	strcopy(sName, length, "Redmond");
}

public void Redmond_GetBossInfo(SaxtonHaleBase boss, char[] sInfo, int length)
{
	StrCat(sInfo, length, "\nDuo Boss with Blutarch");
	StrCat(sInfo, length, "\nMelee deals 124 damage");
	StrCat(sInfo, length, "\nHealth: Low");
	StrCat(sInfo, length, "\n ");
	StrCat(sInfo, length, "\nAbilities");
	StrCat(sInfo, length, "\n- Alt-attack to use Teleport spell (5 second cooldown)");
	StrCat(sInfo, length, "\n ");
	StrCat(sInfo, length, "\nRage");
	StrCat(sInfo, length, "\n- Damage requirement: 2500");
	StrCat(sInfo, length, "\n- Grants a MONOCULUS! spell");
	StrCat(sInfo, length, "\n- 200%% Rage: Grants 3 MONOCULUS! spells");
}

public Action Redmond_OnAttackDamage(SaxtonHaleBase boss, int victim, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	//Monos spell damage sucks, buff it
	if (weapon > MaxClients)
	{
		char sClassname[256];
		GetEntityClassname(weapon, sClassname, sizeof(sClassname));
		if (StrEqual(sClassname, "eyeball_boss"))
		{
			damage *= 2.0;
			return Plugin_Changed;
		}
	}
	
	return Plugin_Continue;
	
}

public void Redmond_GetModel(SaxtonHaleBase boss, char[] sModel, int length)
{
	strcopy(sModel, length, REDMOND_MODEL);
}

public void Redmond_GetSound(SaxtonHaleBase boss, char[] sSound, int length, SaxtonHaleSound iSoundType)
{
	switch (iSoundType)
	{
		case VSHSound_Win: strcopy(sSound, length, g_strRedmondWin[GetRandomInt(0,sizeof(g_strRedmondWin)-1)]);
		case VSHSound_Lose: strcopy(sSound, length, g_strRedmondLose[GetRandomInt(0,sizeof(g_strRedmondLose)-1)]);
		case VSHSound_Rage: strcopy(sSound, length, g_strRedmondRage[GetRandomInt(0,sizeof(g_strRedmondRage)-1)]);
		case VSHSound_Lastman: strcopy(sSound, length, g_strRedmondLastMan[GetRandomInt(0,sizeof(g_strRedmondLastMan)-1)]);
		case VSHSound_Backstab: strcopy(sSound, length, g_strRedmondBackstabbed[GetRandomInt(0,sizeof(g_strRedmondBackstabbed)-1)]);
		case VSHSound_Death: strcopy(sSound, length, g_strRedmondDeath[GetRandomInt(0,sizeof(g_strRedmondDeath)-1)]);
	}
}
	
public void Redmond_Precache(SaxtonHaleBase boss)
{
	PrecacheModel(REDMOND_MODEL);
	
	for (int i = 0; i < sizeof(g_strRedmondWin); i++) PrecacheSound(g_strRedmondWin[i]);
	for (int i = 0; i < sizeof(g_strRedmondDeath); i++) PrecacheSound(g_strRedmondDeath[i]);
	for (int i = 0; i < sizeof(g_strRedmondLose); i++) PrecacheSound(g_strRedmondLose[i]);
	for (int i = 0; i < sizeof(g_strRedmondRage); i++) PrecacheSound(g_strRedmondRage[i]);
	for (int i = 0; i < sizeof(g_strRedmondLastMan); i++) PrecacheSound(g_strRedmondLastMan[i]);
	for (int i = 0; i < sizeof(g_strRedmondBackstabbed); i++) PrecacheSound(g_strRedmondBackstabbed[i]);
	
	AddFileToDownloadsTable("models/player/kirillian/boss/boss_redmond_v2.mdl");
	AddFileToDownloadsTable("models/player/kirillian/boss/boss_redmond_v2.vvd");
	AddFileToDownloadsTable("models/player/kirillian/boss/boss_redmond_v2.dx80.vtx");
	AddFileToDownloadsTable("models/player/kirillian/boss/boss_redmond_v2.dx90.vtx");
	AddFileToDownloadsTable("models/player/kirillian/boss/boss_redmond_v2.phy");
}
