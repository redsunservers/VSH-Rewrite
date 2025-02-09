#define YETI_MODEL "models/player/kirillian/boss/yeti_modded.mdl"
#define YETI_THEME "ui/gamestartup29.mp3"

static char g_strYetiRoundStart[][] =  {
	"ambient_mp3/lair/animal_call_yeti1.mp3", 
	"ambient_mp3/lair/animal_call_yeti2.mp3", 
	"ambient_mp3/lair/animal_call_yeti3.mp3", 
	"ambient_mp3/lair/animal_call_yeti4.mp3", 
	"ambient_mp3/lair/animal_call_yeti5.mp3", 
	"ambient_mp3/lair/animal_call_yeti6.mp3", 
	"ambient_mp3/lair/animal_call_yeti7.mp3"
};

static char g_strYetiWin[][] =  {
	"player/taunt_yeti_roar_first.wav"
};

static char g_strYetiLose[][] =  {
	"player/taunt_yeti_roar_second.wav"
};

static char g_strYetiKill[][] =  {
	"player/taunt_yeti_roar_beginning.wav"
};

static char g_strYetiRage[] = "ambient/atmosphere/terrain_rumble1.wav";

static char g_strYetiLastMan[][] =  {
	"ambient_mp3/lair/animal_call_yeti2.mp3", 
};

static char g_strYetiBackStabbed[][] =  {
	"player/taunt_yeti_roar_second.wav"
};

static char g_strYetiVoice[][] =  {
	"player/taunt_yeti_roar_beginning.wav", 
	"player/taunt_yeti_roar_first.wav", 
	"player/taunt_yeti_roar_second.wav"
};

static char g_strYetiFootsteps[][] =  {
	"player/footsteps/giant1.wav", 
	"player/footsteps/giant2.wav"
};

public void Yeti_Create(SaxtonHaleBase boss)
{
	boss.CreateClass("BraveJump");
	boss.CreateClass("GroundPound");
	boss.CreateClass("RageMeteor");

	boss.SetPropFloat("GroundPound", "JumpCooldown", 0.0);
	
	boss.iHealthPerPlayer = 650;
	boss.flHealthExponential = 1.05;
	boss.nClass = TFClass_Heavy;
	boss.iMaxRageDamage = 3000;
}

public void Yeti_GetBossName(SaxtonHaleBase boss, char[] sName, int length)
{
	strcopy(sName, length, "Last Yeti");
}

public void Yeti_GetBossInfo(SaxtonHaleBase boss, char[] sInfo, int length)
{
	StrCat(sInfo, length, "\nHealth: Medium");
	StrCat(sInfo, length, "\n ");
	StrCat(sInfo, length, "\nAbilities");
	StrCat(sInfo, length, "\n- Brave Jump (Not Reduced by Ground Pound)");
	StrCat(sInfo, length, "\n ");
	StrCat(sInfo, length, "\nRage");
	StrCat(sInfo, length, "\n- Damage requirement: 3000");
	StrCat(sInfo, length, "\n- Rains hail down on to players in front of you");
	StrCat(sInfo, length, "\n- Players hit will get frozen for 1 second");
	StrCat(sInfo, length, "\n- 200%% Rage: Increased projectile count and spawn rate");
}

public void Yeti_OnSpawn(SaxtonHaleBase boss)
{
	int iWeapon = boss.CallFunction("CreateWeapon", 195, NULL_STRING, 100, TFQual_Strange, "2 ; 2.80 ; 252 ; 0.5 ; 259 ; 1.0");
	if (iWeapon > MaxClients)
	{
		TF2Attrib_SetByDefIndex(iWeapon, 214, view_as<float>(GetRandomInt(7500, 7615)));
		SetEntPropEnt(boss.iClient, Prop_Send, "m_hActiveWeapon", iWeapon);
	}
	/*
	Fist attributes:
	
	2: damage bonus
	252: reduction in push force taken from damage
	259: Deals 3x falling damage to the player you land on
	214: kill_eater (7500-7615 for Legendary strange rank)
	*/
}

public void Yeti_OnThink(SaxtonHaleBase boss)
{
	int iWeapon = GetPlayerWeaponSlot(boss.iClient, WeaponSlot_Melee);
	if (iWeapon > MaxClients)
		SetEntPropFloat(iWeapon, Prop_Send, "m_flNextSecondaryAttack", GetGameTime() + 60.0);
}

public void Yeti_OnRage(SaxtonHaleBase boss)
{
	FakeClientCommand(boss.iClient, "voicemenu 2 1");
	
	EmitSoundToAll(g_strYetiRage);
	EmitSoundToAll(g_strYetiRage);
}

public void Yeti_OnPlayerKilled(SaxtonHaleBase boss, Event event, int iVictim)
{
	KillIconShared(event, true);
}

public void Yeti_OnDestroyObject(SaxtonHaleBase boss, Event event)
{
	KillIconShared(event, false);
}

static void KillIconShared(Event event, bool bLog)
{
	int iWeaponId = event.GetInt("weaponid");
	
	if (iWeaponId == TF_WEAPON_ROCKETLAUNCHER)
	{
		if (bLog)
			event.SetString("weapon_logclassname", "meteor");
		
		event.SetString("weapon", "krampus_ranged");
	}
}

public void Yeti_GetModel(SaxtonHaleBase boss, char[] sModel, int length)
{
	strcopy(sModel, length, YETI_MODEL);
}

public void Yeti_GetSound(SaxtonHaleBase boss, char[] sSound, int length, SaxtonHaleSound iSoundType)
{
	switch (iSoundType)
	{
		case VSHSound_RoundStart:strcopy(sSound, length, g_strYetiRoundStart[GetRandomInt(0, sizeof(g_strYetiRoundStart) - 1)]);
		case VSHSound_Win:strcopy(sSound, length, g_strYetiWin[GetRandomInt(0, sizeof(g_strYetiWin) - 1)]);
		case VSHSound_Lose:strcopy(sSound, length, g_strYetiLose[GetRandomInt(0, sizeof(g_strYetiLose) - 1)]);
		case VSHSound_Lastman:strcopy(sSound, length, g_strYetiLastMan[GetRandomInt(0, sizeof(g_strYetiLastMan) - 1)]);
		case VSHSound_Backstab:strcopy(sSound, length, g_strYetiBackStabbed[GetRandomInt(0, sizeof(g_strYetiBackStabbed) - 1)]);
	}
}

public void Yeti_GetSoundKill(SaxtonHaleBase boss, char[] sSound, int length, TFClassType nClass)
{
	strcopy(sSound, length, g_strYetiKill[GetRandomInt(0, sizeof(g_strYetiKill) - 1)]);
}

public Action Yeti_OnSoundPlayed(SaxtonHaleBase boss, int clients[MAXPLAYERS], int &numClients, char sample[PLATFORM_MAX_PATH], int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
	if (strncmp(sample, "vo/", 3) == 0)
	{
		// Prevent kill taunt voice lines
		if (strcmp(sample, "vo/heavy_NiceShot02.mp3") == 0 || strcmp(sample, "vo/puff.mp3") == 0)
			return Plugin_Stop;
		
		Format(sample, sizeof(sample), g_strYetiVoice[GetRandomInt(0, sizeof(g_strYetiVoice) - 1)]);
		return Plugin_Changed;
	}
	else if (strncmp(sample, "player/footsteps/", 17) == 0)
	{
		EmitSoundToAll(g_strYetiFootsteps[GetRandomInt(0, sizeof(g_strYetiFootsteps) - 1)], boss.iClient, _, _, _, 0.4, GetRandomInt(90, 100));
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public Action Yeti_OnAttackDamage(SaxtonHaleBase boss, int victim, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	// Prevent kill taunt
	if (victim != boss.iClient && damagecustom == TF_CUSTOM_TAUNT_HIGH_NOON)
	{
		damage = 0.0;
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}

public void Yeti_GetMusicInfo(SaxtonHaleBase boss, char[] sSound, int length, float &time)
{
	strcopy(sSound, length, YETI_THEME);
	time = 105.0;
}

public void Yeti_Precache(SaxtonHaleBase boss)
{
	PrecacheModel(YETI_MODEL);
	
	PrepareMusic(YETI_THEME, false);
	PrecacheSound(g_strYetiRage);
	
	for (int i = 0; i < sizeof(g_strYetiRoundStart); i++)PrecacheSound(g_strYetiRoundStart[i]);
	for (int i = 0; i < sizeof(g_strYetiWin); i++)PrecacheSound(g_strYetiWin[i]);
	for (int i = 0; i < sizeof(g_strYetiLose); i++)PrecacheSound(g_strYetiLose[i]);
	for (int i = 0; i < sizeof(g_strYetiKill); i++)PrecacheSound(g_strYetiKill[i]);
	for (int i = 0; i < sizeof(g_strYetiLastMan); i++)PrecacheSound(g_strYetiLastMan[i]);
	for (int i = 0; i < sizeof(g_strYetiBackStabbed); i++)PrecacheSound(g_strYetiBackStabbed[i]);
	for (int i = 0; i < sizeof(g_strYetiVoice); i++)PrecacheSound(g_strYetiVoice[i]);
	for (int i = 0; i < sizeof(g_strYetiFootsteps); i++)PrecacheSound(g_strYetiFootsteps[i]);
	
	AddFileToDownloadsTable("materials/models/player/boss/yeti/invun_grey.vtf");
	AddFileToDownloadsTable("materials/models/player/boss/yeti/yeti_face_invun.vmt");
	AddFileToDownloadsTable("materials/models/player/boss/yeti/yeti_face_invun.vtf");
	AddFileToDownloadsTable("materials/models/player/boss/yeti/yeti_invun.vmt");
	AddFileToDownloadsTable("materials/models/player/boss/yeti/yeti_invun.vtf");
	
	AddFileToDownloadsTable("models/player/kirillian/boss/yeti_modded.dx80.vtx");
	AddFileToDownloadsTable("models/player/kirillian/boss/yeti_modded.dx90.vtx");
	AddFileToDownloadsTable("models/player/kirillian/boss/yeti_modded.mdl");
	AddFileToDownloadsTable("models/player/kirillian/boss/yeti_modded.phy");
	AddFileToDownloadsTable("models/player/kirillian/boss/yeti_modded.vvd");
}
