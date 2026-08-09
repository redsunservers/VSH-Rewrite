#define SEEMAN_MODEL						"models/player/kirillian/boss/seeman_fix.mdl"
#define SEEMAN_RAGE_SND						"vsh_rewrite/seeman/rage.mp3"
#define SEEMAN_SEE_SND						"vsh_rewrite/seeman/see.mp3"

public void SeeMan_Create(SaxtonHaleBase boss)
{
	boss.CreateClass("WeaponFists");
	boss.CreateClass("BraveJump");
	boss.CreateClass("Bomb");
	boss.SetPropFloat("Bomb", "BombSpawnInterval", 0.1);
	boss.SetPropFloat("Bomb", "BombSpawnDuration", 3.0);
	boss.SetPropFloat("Bomb", "BombSpawnRadius", 500.0);
	boss.SetPropFloat("Bomb", "BombRadius", 200.0);
	boss.SetPropFloat("Bomb", "BombDamage", 75.0);
	boss.SetPropFloat("Bomb", "NukeRadius", 650.0);
	
	boss.iHealthPerPlayer = 550;
	boss.flHealthExponential = 1.05;
	boss.nClass = TFClass_DemoMan;
	boss.iMaxRageDamage = 2000;
	
	boss.CreateClass("RageAddCond");
	boss.SetPropFloat("RageAddCond", "RageCondDuration", 3.0);
	boss.SetPropFloat("RageAddCond", "RageCondSuperRageMultiplier", 1.0);
	RageAddCond_AddCond(boss, TFCond_UberchargedCanteen);
}

public void SeeMan_GetBossMultiType(SaxtonHaleBase boss, char[] sType, int length)
{
	strcopy(sType, length, "SeeManSeeldier");
}

public bool SeeMan_IsBossHidden(SaxtonHaleBase boss)
{
	return true;
}

public void SeeMan_GetBossName(SaxtonHaleBase boss, char[] sName, int length)
{
	strcopy(sName, length, "Seeman");
}

public void SeeMan_GetBossInfo(SaxtonHaleBase boss, char[] sInfo, int length)
{
	StrCat(sInfo, length, "\nDuo Boss with Seeldier");
	StrCat(sInfo, length, "\nMelee deals 124 damage");
	StrCat(sInfo, length, "\nHealth: Low");
	StrCat(sInfo, length, "\n ");
	StrCat(sInfo, length, "\nAbilities");
	StrCat(sInfo, length, "\n- Brave Jump");
	StrCat(sInfo, length, "\n ");
	StrCat(sInfo, length, "\nRage");
	StrCat(sInfo, length, "\n- Damage requirement: 2000");
	StrCat(sInfo, length, "\n- Frozen with Übercharge for 3 seconds");
	StrCat(sInfo, length, "\n- Lots of small explosions around boss");
	StrCat(sInfo, length, "\n- 200%% Rage: instakill nuke at end of rage");
}

public Action SeeMan_OnTakeDamage(SaxtonHaleBase boss, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	char sWeaponClassName[32];
	if (inflictor >= 0) GetEdictClassname(inflictor, sWeaponClassName, sizeof(sWeaponClassName));
	
	//Disable self-damage from bomb rage ability
	if (boss.iClient == attacker && strcmp(sWeaponClassName, "tf_generic_bomb") == 0) return Plugin_Stop;

	EmitSoundToAll(SEEMAN_SEE_SND, boss.iClient, SNDCHAN_VOICE, SNDLEVEL_SCREAMING);
	return Plugin_Continue;
}

public void SeeMan_OnSpawn(SaxtonHaleBase boss)
{
	char attribs[128];
	Format(attribs, sizeof(attribs), "2 ; 1.9 ; 252 ; 0.5 ; 259 ; 1.0");
	int iWeapon = boss.CallFunction("CreateWeapon", 195, "tf_weapon_bottle", 100, TFQual_Collectors, attribs);
	if (iWeapon > MaxClients)
		SetEntPropEnt(boss.iClient, Prop_Send, "m_hActiveWeapon", iWeapon);
	/*
	Fist attributes:
	
	2: damage bonus
	252: reduction in push force taken from damage
	259: Deals 3x falling damage to the player you land on
	*/
}

public void SeeMan_GetModel(SaxtonHaleBase boss, char[] sModel, int length)
{
	strcopy(sModel, length, SEEMAN_MODEL);
}

public void SeeMan_GetSound(SaxtonHaleBase boss, char[] sSound, int length, SaxtonHaleSound iSoundType)
{
	if (iSoundType != VSHSound_RoundStart)
		strcopy(sSound, length, SEEMAN_SEE_SND);
}

public void SeeMan_GetSoundAbility(SaxtonHaleBase boss, char[] sSound, int length, const char[] sType)
{
	if (strcmp(sType, "BraveJump") == 0)
		strcopy(sSound, length, SEEMAN_SEE_SND);
}

public void SeeMan_GetSoundKill(SaxtonHaleBase boss, char[] sSound, int length, TFClassType nClass)
{
	strcopy(sSound, length, SEEMAN_SEE_SND);
}

public Action SeeMan_OnSoundPlayed(SaxtonHaleBase boss, int clients[MAXPLAYERS], int &numClients, char sample[PLATFORM_MAX_PATH], int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
	if (strncmp(sample, "vo/", 3) == 0)
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public void SeeMan_GetRageMusicInfo(SaxtonHaleBase boss, char[] sSound, int length, float &time)
{
	strcopy(sSound, length, SEEMAN_RAGE_SND);
	time = 6.0;
}

public void SeeMan_Precache(SaxtonHaleBase boss)
{
	PrepareSound(SEEMAN_SEE_SND);
	PrepareSound(SEEMAN_RAGE_SND);
	PrecacheModel(SEEMAN_MODEL);
	
	AddFileToDownloadsTable("models/player/kirillian/boss/seeman_fix.mdl");
	AddFileToDownloadsTable("models/player/kirillian/boss/seeman_fix.vvd");
	AddFileToDownloadsTable("models/player/kirillian/boss/seeman_fix.dx80.vtx");
	AddFileToDownloadsTable("models/player/kirillian/boss/seeman_fix.dx90.vtx");
	AddFileToDownloadsTable("models/player/kirillian/boss/seeman_fix.phy");
}

