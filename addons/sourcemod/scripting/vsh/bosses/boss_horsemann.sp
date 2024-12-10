#define HORSEMANN_MODEL "models/player/saxton_hale/hhh_jr_mk3.mdl"
#define HORSEMANN_THEME "ui/holiday/gamestartup_halloween.mp3"

static char g_strHorsemannRoundStart[][] = {
	"ui/halloween_boss_summoned_fx.wav",
};

static char g_strHorsemannWin[][] = {
	"vo/halloween_boss/knight_laugh01.mp3",
	"vo/halloween_boss/knight_laugh02.mp3",
	"vo/halloween_boss/knight_laugh03.mp3",
	"vo/halloween_boss/knight_laugh04.mp3",
};

static char g_strHorsemannLose[][] = {
	"vo/halloween_boss/knight_death01.mp3",
	"vo/halloween_boss/knight_death02.mp3",
	"vo/halloween_boss/knight_dying.mp3",
};

static char g_strHorsemannGhost[][] = {
	"ambient/halloween/thunder_02.wav",
	"ambient/halloween/thunder_04.wav",
	"ambient/halloween/thunder_07.wav",
	"ambient/halloween/thunder_08.wav",
	"ambient/halloween/mysterious_perc_02.wav",
	"ambient/halloween/mysterious_perc_03.wav",
	"ambient/halloween/mysterious_perc_07.wav",
	"ambient/halloween/mysterious_perc_10.wav",
	"ambient/halloween/windgust_02.wav",
	"ambient/halloween/windgust_05.wav",
	"ambient/halloween/windgust_07.wav",
};

static char g_strHorsemannKill[][] = {
	"vo/halloween_boss/knight_attack01.mp3",
	"vo/halloween_boss/knight_attack02.mp3",
	"vo/halloween_boss/knight_attack03.mp3",
	"vo/halloween_boss/knight_attack04.mp3",
	"vo/halloween_boss/knight_laugh01.mp3",
	"vo/halloween_boss/knight_laugh02.mp3",
	"vo/halloween_boss/knight_laugh03.mp3",
	"vo/halloween_boss/knight_laugh04.mp3",
};

static char g_strHorsemannLastMan[][] = {
	"ui/halloween_boss_player_becomes_it.wav",
};

static char g_strHorsemannBackStabbed[][] = {
	"vo/halloween_boss/knight_pain01.mp3",
	"vo/halloween_boss/knight_pain02.mp3",
	"vo/halloween_boss/knight_pain03.mp3",
};

static char g_strHorsemannTeleport[][] = {
	"vo/halloween_boss/knight_alert.mp3",
};

static char g_strHorsemannVoice[][] = {
	"vo/halloween_boss/knight_alert01.mp3",
	"vo/halloween_boss/knight_alert02.mp3",
	"vo/halloween_boss/knight_attack02.mp3",
};

static char g_strHorsemannFootsteps[][] = {
	"player/footsteps/giant2.wav",
};

public void Horsemann_Create(SaxtonHaleBase boss)
{
	boss.CreateClass("WallClimb");
	boss.CreateClass("TeleportSwap");
	boss.CreateClass("RageGhost");
	
	boss.iHealthPerPlayer = 500;
	boss.flHealthExponential = 1.05;
	boss.nClass = TFClass_DemoMan;
	boss.iMaxRageDamage = 3000;
}

public void Horsemann_GetBossName(SaxtonHaleBase boss, char[] sName, int length)
{
	strcopy(sName, length, "Horseless Headless Horsemann Jr.");
}

public void Horsemann_GetBossInfo(SaxtonHaleBase boss, char[] sInfo, int length)
{
	StrCat(sInfo, length, "\nHealth: Low");
	StrCat(sInfo, length, "\n ");
	StrCat(sInfo, length, "\nAbilities");
	StrCat(sInfo, length, "\n- Wall Climb");
	StrCat(sInfo, length, "\n- Teleport Swap");
	StrCat(sInfo, length, "\n ");
	StrCat(sInfo, length, "\nRage");
	StrCat(sInfo, length, "\n- Damage requirement: 3000");
	StrCat(sInfo, length, "\n- Become a flying ghost that is immune to damage, cannot attack for 8 seconds");
	StrCat(sInfo, length, "\n- Pulls in and drains health from nearby players with random spooky effects");
	StrCat(sInfo, length, "\n- 200%% Rage: Larger range and health drain is doubled");
}

public void Horsemann_OnSpawn(SaxtonHaleBase boss)
{
	char attribs[128];
	Format(attribs, sizeof(attribs), "2 ; 2.80 ; 252 ; 0.5 ; 259 ; 1.0 ; 264 ; 0.73 ; 551 ; 1");
	int iWeapon = boss.CallFunction("CreateWeapon", 266, "tf_weapon_sword", 100, TFQual_Unusual, attribs);

	if (iWeapon > MaxClients)
	{
		SetEntPropEnt(boss.iClient, Prop_Send, "m_hActiveWeapon", iWeapon);
		SetEntPropFloat(iWeapon, Prop_Send, "m_flModelScale", 0.0); //The boss model already has a Headtaker, so it doesn't need the original one. There's like no other way that doesn't also disable the viewmodel
	}
	/*
	Horseless Headless Horsemann's Headtaker attributes:
	
	2: damage bonus
	252: reduction in push force taken from damage
	259: Deals 3x falling damage to the player you land on
	436: ragdolls_plasma_effect
	264: melee range multiplier (tf_weapon_sword have 37% extra range)
	551: special taunt
	*/

	Horsemann_CreateEyeGlow(boss);
}

public void Horsemann_GetModel(SaxtonHaleBase boss, char[] sModel, int length)
{
	strcopy(sModel, length, HORSEMANN_MODEL);
}

public void Horsemann_GetSound(SaxtonHaleBase boss, char[] sSound, int length, SaxtonHaleSound iSoundType)
{
	switch (iSoundType)
	{
		case VSHSound_RoundStart: strcopy(sSound, length, g_strHorsemannRoundStart[GetRandomInt(0,sizeof(g_strHorsemannRoundStart)-1)]);
		case VSHSound_Win: strcopy(sSound, length, g_strHorsemannWin[GetRandomInt(0,sizeof(g_strHorsemannWin)-1)]);
		case VSHSound_Lose: strcopy(sSound, length, g_strHorsemannLose[GetRandomInt(0,sizeof(g_strHorsemannLose)-1)]);
		case VSHSound_Lastman: strcopy(sSound, length, g_strHorsemannLastMan[GetRandomInt(0,sizeof(g_strHorsemannLastMan)-1)]);
		case VSHSound_Backstab: strcopy(sSound, length, g_strHorsemannBackStabbed[GetRandomInt(0,sizeof(g_strHorsemannBackStabbed)-1)]);
	}
}

public void Horsemann_GetSoundAbility(SaxtonHaleBase boss, char[] sSound, int length, const char[] sType)
{
	if (strcmp(sType, "RageGhost") == 0)
		strcopy(sSound, length, g_strHorsemannGhost[GetRandomInt(0,sizeof(g_strHorsemannGhost)-1)]);
		
	if (strcmp(sType, "TeleportSwap") == 0)
		strcopy(sSound, length, g_strHorsemannTeleport[GetRandomInt(0,sizeof(g_strHorsemannTeleport)-1)]);
}

public void Horsemann_GetSoundKill(SaxtonHaleBase boss, char[] sSound, int length, TFClassType nClass)
{
	strcopy(sSound, length, g_strHorsemannKill[GetRandomInt(0,sizeof(g_strHorsemannKill)-1)]);
}

public Action Horsemann_OnSoundPlayed(SaxtonHaleBase boss, int clients[MAXPLAYERS], int &numClients, char sample[PLATFORM_MAX_PATH], int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
	if (strncmp(sample, "vo/", 3) == 0)
	{
		if (StrContains(sample, "vo/halloween_boss/", false) == 0)
			return Plugin_Continue;
		
		Format(sample, sizeof(sample), g_strHorsemannVoice[GetRandomInt(0, sizeof(g_strHorsemannVoice)-1)]);
		return Plugin_Changed;
	}
		
	if (StrContains(sample, "player/footsteps/", false) == 0)
	{
		if (!TF2_IsPlayerInCondition(boss.iClient, TFCond_SwimmingNoEffects))
			EmitSoundToAll(g_strHorsemannFootsteps[GetRandomInt(0, sizeof(g_strHorsemannFootsteps)-1)], boss.iClient, _, _, _, 0.4, GetRandomInt(90, 100));
		
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public void Horsemann_GetMusicInfo(SaxtonHaleBase boss, char[] sSound, int length, float &time)
{
	strcopy(sSound, length, HORSEMANN_THEME);
	time = 83.0;
}

public void Horsemann_Precache(SaxtonHaleBase boss)
{
	PrecacheModel(HORSEMANN_MODEL);
	
	PrepareMusic(HORSEMANN_THEME, false);
	
	for (int i = 0; i < sizeof(g_strHorsemannRoundStart); i++) PrecacheSound(g_strHorsemannRoundStart[i]);
	for (int i = 0; i < sizeof(g_strHorsemannWin); i++) PrecacheSound(g_strHorsemannWin[i]);
	for (int i = 0; i < sizeof(g_strHorsemannLose); i++) PrecacheSound(g_strHorsemannLose[i]);
	for (int i = 0; i < sizeof(g_strHorsemannGhost); i++) PrecacheSound(g_strHorsemannGhost[i]);
	for (int i = 0; i < sizeof(g_strHorsemannKill); i++) PrecacheSound(g_strHorsemannKill[i]);
	for (int i = 0; i < sizeof(g_strHorsemannLastMan); i++) PrecacheSound(g_strHorsemannLastMan[i]);
	for (int i = 0; i < sizeof(g_strHorsemannBackStabbed); i++) PrecacheSound(g_strHorsemannBackStabbed[i]);
	for (int i = 0; i < sizeof(g_strHorsemannTeleport); i++) PrecacheSound(g_strHorsemannTeleport[i]);
	for (int i = 0; i < sizeof(g_strHorsemannVoice); i++) PrecacheSound(g_strHorsemannVoice[i]);
	for (int i = 0; i < sizeof(g_strHorsemannFootsteps); i++) PrecacheSound(g_strHorsemannFootsteps[i]);
	
	AddFileToDownloadsTable("models/player/saxton_hale/hhh_jr_mk3.mdl");
	AddFileToDownloadsTable("models/player/saxton_hale/hhh_jr_mk3.vvd");
	AddFileToDownloadsTable("models/player/saxton_hale/hhh_jr_mk3.dx80.vtx");
	AddFileToDownloadsTable("models/player/saxton_hale/hhh_jr_mk3.dx90.vtx");
}

public void Horsemann_CreateEyeGlow(SaxtonHaleBase boss)
{
	char sEffectName[64];
	int iParticle = MaxClients + 1;
	while ((iParticle = FindEntityByClassname(iParticle, "info_particle_system")) > MaxClients)
	{
		if (GetEntPropEnt(iParticle, Prop_Send, "m_hOwnerEntity") != boss.iClient)
			continue;

		GetEntPropString(iParticle, Prop_Data, "m_iszEffectName", sEffectName, sizeof(sEffectName));
		if (strcmp(sEffectName, "halloween_boss_eye_glow") != 0)
			continue;

		RemoveEntity(iParticle);
	}

	char sAttachment[64];
	for (int i = 0; i <= 1; i++)
	{
		strcopy(sAttachment, sizeof(sAttachment), (i == 0) ? "lefteye" : "righteye");

		iParticle = TF2_SpawnParticle("halloween_boss_eye_glow", .iEntity = boss.iClient, .sAttachment = sAttachment);
		SetEntPropEnt(iParticle, Prop_Send, "m_hOwnerEntity", boss.iClient);

		if (GetEdictFlags(iParticle) & FL_EDICT_ALWAYS)
	 		SetEdictFlags(iParticle, GetEdictFlags(iParticle) & ~FL_EDICT_ALWAYS);

		SDKHook(iParticle, SDKHook_SetTransmit, Horsemann_EyeGlowTransmit);
	}
}

public Action Horsemann_EyeGlowTransmit(int iEntity, int iClient)
{
	if (GetEdictFlags(iEntity) & FL_EDICT_ALWAYS)
	 	SetEdictFlags(iEntity, GetEdictFlags(iEntity) & ~FL_EDICT_ALWAYS);

	int iBossOwner = GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity");
	if (!SaxtonHale_IsValidBoss(iBossOwner) || !SaxtonHaleBase(iBossOwner).HasClass("Horsemann"))
	{
		RemoveEntity(iEntity);
		return Plugin_Handled;
	}

	if (iClient == iBossOwner && GetEntProp(iClient, Prop_Send, "m_nForceTauntCam") == 0)
		return Plugin_Handled;

	if (!IsPlayerAlive(iClient) && GetEntPropEnt(iClient, Prop_Send, "m_hObserverTarget") == iBossOwner)
	{
		if (GetEntProp(iClient, Prop_Send, "m_iObserverMode") == 4)	//SPEC_MODE_FIRSTPERSON
			return Plugin_Handled;
	}

	return Plugin_Continue;
}