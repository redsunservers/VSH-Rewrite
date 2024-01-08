#define SEELDIER_MODEL						"models/player/kirillian/boss/seeldier_fix.mdl"
#define SEELDIER_SEE_SND					"vsh_rewrite/seeldier/see.mp3"

public void Seeldier_Create(SaxtonHaleBase boss)
{
	boss.CreateClass("WeaponFists");
	boss.CreateClass("BraveJump");
	
	boss.iHealthPerPlayer = 550;
	boss.flHealthExponential = 1.05;
	boss.nClass = TFClass_Soldier;
	boss.iMaxRageDamage = 2000;
}

public void Seeldier_GetBossMultiType(SaxtonHaleBase boss, char[] sType, int length)
{
	strcopy(sType, length, "SeeManSeeldier");
}

public bool Seeldier_IsBossHidden(SaxtonHaleBase boss)
{
	return true;
}

public void Seeldier_GetBossName(SaxtonHaleBase boss, char[] sName, int length)
{
	strcopy(sName, length, "Seeldier");
}

public void Seeldier_GetBossInfo(SaxtonHaleBase boss, char[] sInfo, int length)
{
	StrCat(sInfo, length, "\nDuo Boss with Seeman");
	StrCat(sInfo, length, "\nMelee deals 124 damage");
	StrCat(sInfo, length, "\nHealth: Low");
	StrCat(sInfo, length, "\n ");
	StrCat(sInfo, length, "\nAbilities");
	StrCat(sInfo, length, "\n- Brave Jump");
	StrCat(sInfo, length, "\n ");
	StrCat(sInfo, length, "\nRage");
	StrCat(sInfo, length, "\n- Damage requirement: 2000");
	StrCat(sInfo, length, "\n- Summons 3 mini-Seeldiers");
	StrCat(sInfo, length, "\n- 200%% Rage: Summons 6 mini-Seeldiers");
}

public void Seeldier_OnSpawn(SaxtonHaleBase boss)
{
	char attribs[128];
	Format(attribs, sizeof(attribs), "2 ; 1.9 ; 252 ; 0.5 ; 259 ; 1.0");
	int iWeapon = boss.CallFunction("CreateWeapon", 195, "tf_weapon_shovel", 100, TFQual_Collectors, attribs);
	if (iWeapon > MaxClients)
		SetEntPropEnt(boss.iClient, Prop_Send, "m_hActiveWeapon", iWeapon);
	/*
	Fist attributes:
	
	2: damage bonus
	252: reduction in push force taken from damage
	259: Deals 3x falling damage to the player you land on
	*/
}

public void Seeldier_GetModel(SaxtonHaleBase boss, char[] sModel, int length)
{
	strcopy(sModel, length, SEELDIER_MODEL);
}

public void Seeldier_OnRage(SaxtonHaleBase boss)
{
	int iTotalMinions = 3;
	if (boss.bSuperRage) iTotalMinions *= 2;
	
	ArrayList aValidMinions = GetValidSummonableClients();
	
	int iLength = aValidMinions.Length;
	if (iLength < iTotalMinions)
		iTotalMinions = iLength;
	else
		iLength = iTotalMinions;
	
	for (int i = 0; i < iLength; i++)
	{
		int iClient = aValidMinions.Get(i);
		
		SaxtonHaleBase bossMinion = SaxtonHaleBase(iClient);
		if (bossMinion.bValid)
			bossMinion.DestroyAllClass();
		
		bossMinion.CreateClass("SeeldierMinion");
		TF2_ForceTeamJoin(iClient, TFTeam_Boss);
		
		TF2_TeleportToClient(iClient, boss.iClient);
		TF2_AddCondition(iClient, TFCond_Ubercharged, 2.0);
	}
	
	delete aValidMinions;
}

public Action Seeldier_OnTakeDamage(SaxtonHaleBase boss, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	EmitSoundToAll(SEELDIER_SEE_SND, boss.iClient, SNDCHAN_VOICE, SNDLEVEL_SCREAMING);
	return Plugin_Continue;
}

public void Seeldier_GetSound(SaxtonHaleBase boss, char[] sSound, int length, SaxtonHaleSound iSoundType)
{
	//C on every sounds
	if (iSoundType != VSHSound_RoundStart)
		strcopy(sSound, length, SEELDIER_SEE_SND);
}

public void Seeldier_GetSoundAbility(SaxtonHaleBase boss, char[] sSound, int length, const char[] sType)
{
	if (strcmp(sType, "BraveJump") == 0)
		strcopy(sSound, length, SEELDIER_SEE_SND);
}

public void Seeldier_GetSoundKill(SaxtonHaleBase boss, char[] sSound, int length, TFClassType nClass)
{
	strcopy(sSound, length, SEELDIER_SEE_SND);
}

public Action Seeldier_OnSoundPlayed(SaxtonHaleBase boss, int clients[MAXPLAYERS], int &numClients, char sample[PLATFORM_MAX_PATH], int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
	if (strncmp(sample, "vo/", 3) == 0)
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public void Seeldier_Precache(SaxtonHaleBase boss)
{
	PrecacheModel(SEELDIER_MODEL);
	PrepareSound(SEELDIER_SEE_SND);
	
	AddFileToDownloadsTable("models/player/kirillian/boss/seeldier_fix.mdl");
	AddFileToDownloadsTable("models/player/kirillian/boss/seeldier_fix.vvd");
	AddFileToDownloadsTable("models/player/kirillian/boss/seeldier_fix.dx80.vtx");
	AddFileToDownloadsTable("models/player/kirillian/boss/seeldier_fix.dx90.vtx");
	AddFileToDownloadsTable("models/player/kirillian/boss/seeldier_fix.phy");
}

public void SeeldierMinion_Create(SaxtonHaleBase boss)
{
	boss.CreateClass("WeaponFists");
	
	boss.iBaseHealth = 300;
	boss.iHealthPerPlayer = 0;
	boss.nClass = TFClass_Soldier;
	boss.iMaxRageDamage = -1;
	boss.bMinion = true;
	
	EmitSoundToClient(boss.iClient, SOUND_ALERT);	//Alert player as he spawned
}

public bool SeeldierMinion_IsBossHidden(SaxtonHaleBase boss)
{
	return true;
}

public void SeeldierMinion_OnSpawn(SaxtonHaleBase boss)
{
	char attribs[128];
	Format(attribs, sizeof(attribs), "2 ; 1.25 ; 252 ; 0.5 ; 259 ; 1.0");
	int iWeapon = boss.CallFunction("CreateWeapon", 195, "tf_weapon_shovel", 100, TFQual_Collectors, attribs);
	if (iWeapon > MaxClients)
		SetEntPropEnt(boss.iClient, Prop_Send, "m_hActiveWeapon", iWeapon);
	
	SetEntPropFloat(boss.iClient, Prop_Send, "m_flModelScale", 0.75);
}

public void SeeldierMinion_GetModel(SaxtonHaleBase boss, char[] sModel, int length)
{
	strcopy(sModel, length, SEELDIER_MODEL);
}

public void SeeldierMinion_GetSound(SaxtonHaleBase boss, char[] sSound, int length, SaxtonHaleSound iSoundType)
{
	strcopy(sSound, length, SEELDIER_SEE_SND);
}

public void SeeldierMinion_GetSoundKill(SaxtonHaleBase boss, TFClassType playerClass, char[] sSound, int length)
{
	strcopy(sSound, length, SEELDIER_SEE_SND);
}

public Action SeeldierMinion_OnSoundPlayed(SaxtonHaleBase boss, int clients[MAXPLAYERS], int &numClients, char sample[PLATFORM_MAX_PATH], int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
	if (strncmp(sample, "vo/", 3) == 0)
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public void SeeldierMinion_Destroy(SaxtonHaleBase boss)
{
	SetEntPropFloat(boss.iClient, Prop_Send, "m_flModelScale", 1.0);
}
