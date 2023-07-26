#define DEMO_ROBOT_GIANT_SCALE					1.75
#define DEMO_ROBOT_TURN_INTO_GIANT  			"mvm/giant_heavy/giant_heavy_entrance.wav"
#define DEMO_ROBOT_THEME						"vsh_rewrite/demorobot/demorobot_music.mp3"
#define DEMO_ROBOT_DEATH						"mvm/sentrybuster/mvm_sentrybuster_explode.wav"
#define DEMO_ROBOT_MODEL						"models/bots/demo/bot_demo.mdl"
#define DEMO_ROBOT_GRENADE_LAUNCHER_SHOOT		"mvm/giant_demoman/giant_demoman_grenade_shoot.wav"

static float g_flGrenadeLauncherRemoveTime[MAXPLAYERS];

static char g_strSoundRobotFootsteps[][] =
{
	"mvm/player/footsteps/robostep_01.wav",
	"mvm/player/footsteps/robostep_02.wav",
	"mvm/player/footsteps/robostep_03.wav",
	"mvm/player/footsteps/robostep_04.wav",
	"mvm/player/footsteps/robostep_05.wav",
	"mvm/player/footsteps/robostep_06.wav",
	"mvm/player/footsteps/robostep_07.wav",
	"mvm/player/footsteps/robostep_08.wav",
	"mvm/player/footsteps/robostep_09.wav",
	"mvm/player/footsteps/robostep_10.wav",
	"mvm/player/footsteps/robostep_11.wav",
	"mvm/player/footsteps/robostep_12.wav",
	"mvm/player/footsteps/robostep_13.wav",
	"mvm/player/footsteps/robostep_14.wav",
	"mvm/player/footsteps/robostep_15.wav",
	"mvm/player/footsteps/robostep_16.wav",
	"mvm/player/footsteps/robostep_17.wav",
	"mvm/player/footsteps/robostep_18.wav"
};

static char g_strSoundGiantFootsteps[][] =
{
	"^mvm/giant_common/giant_common_step_01.wav",
	"^mvm/giant_common/giant_common_step_02.wav",
	"^mvm/giant_common/giant_common_step_03.wav",
	"^mvm/giant_common/giant_common_step_04.wav",
	"^mvm/giant_common/giant_common_step_05.wav",
	"^mvm/giant_common/giant_common_step_06.wav",
	"^mvm/giant_common/giant_common_step_07.wav",
	"^mvm/giant_common/giant_common_step_08.wav"
};

static char g_strDemoRobotSpawn[][] = {
	"vo/mvm/mght/demoman_mvm_m_eyelandertaunt01.mp3",
	"vo/mvm/mght/demoman_mvm_m_eyelandertaunt02.mp3",
	"vo/mvm/mght/demoman_mvm_m_dominationdemoman01.mp3",
	"vo/mvm/mght/demoman_mvm_m_specialcompleted08.mp3",
	"vo/mvm/mght/demoman_mvm_m_laughevil03.mp3"
};

static char g_strDemoRobotWin[][] = {
	"vo/mvm/mght/demoman_mvm_m_laughevil01.mp3",
	"vo/mvm/mght/demoman_mvm_m_laughevil02.mp3",
	"vo/mvm/mght/demoman_mvm_m_laughevil03.mp3",
	"vo/mvm/mght/demoman_mvm_m_laughevil04.mp3",
	"vo/mvm/mght/demoman_mvm_m_laughevil05.mp3"
};

static char g_strDemoRobotLastMan[][] = {
	"vo/mvm/mght/demoman_mvm_m_cheers03.mp3",
	"vo/mvm/mght/demoman_mvm_m_cheers05.mp3",
	"vo/mvm/mght/demoman_mvm_m_cheers06.mp3"
};

static char g_strDemoRobotJump[][] = {
	"vo/mvm/mght/demoman_mvm_m_battlecry01.mp3",
	"vo/mvm/mght/demoman_mvm_m_battlecry02.mp3",
	"vo/mvm/mght/demoman_mvm_m_battlecry03.mp3",
	"vo/mvm/mght/demoman_mvm_m_battlecry04.mp3",
	"vo/mvm/mght/demoman_mvm_m_battlecry05.mp3",
	"vo/mvm/mght/demoman_mvm_m_battlecry06.mp3",
	"vo/mvm/mght/demoman_mvm_m_battlecry07.mp3"
};

static char g_strDemoRobotBackStab[][] = {
	"vo/mvm/mght/demoman_mvm_m_autodejectedtie01.mp3",
	"vo/mvm/mght/demoman_mvm_m_autodejectedtie02.mp3"
};

public void DemoRobot_Create(SaxtonHaleBase boss)
{
	boss.CreateClass("BraveJump");
	
	boss.iHealthPerPlayer = 600;
	boss.flHealthExponential = 1.05;
	boss.nClass = TFClass_DemoMan;
	boss.iMaxRageDamage = 2500;
	g_flGrenadeLauncherRemoveTime[boss.iClient] = 0.0;
}

public void DemoRobot_GetBossName(SaxtonHaleBase boss, char[] sName, int length)
{
	strcopy(sName, length, "Glitched Robot");
}

public void DemoRobot_GetBossInfo(SaxtonHaleBase boss, char[] sInfo, int length)
{
	StrCat(sInfo, length, "\nHealth: Medium");
	StrCat(sInfo, length, "\n ");
	StrCat(sInfo, length, "\nAbilities");
	StrCat(sInfo, length, "\n- Brave Jump");
	StrCat(sInfo, length, "\n ");
	StrCat(sInfo, length, "\nRage");
	StrCat(sInfo, length, "\n- Damage requirement: 2500");
	StrCat(sInfo, length, "\n- Get an upgraded Grenade Launcher for 8 seconds");
	StrCat(sInfo, length, "\n- It has faster firing speed, unlimited ammo and clip size");
	StrCat(sInfo, length, "\n- 200%% Rage: Grenade Launcher faster firing speed is doubled");
}

public void DemoRobot_OnSpawn(SaxtonHaleBase boss)
{
	char attribs[128];
	Format(attribs, sizeof(attribs), "2 ; 2.80 ; 252 ; 0.5 ; 259 ; 1.0 ; 436 ; 1.0 ; 264 ; 0.73");
	int iWeapon = boss.CallFunction("CreateWeapon", 132, "tf_weapon_sword", 100, TFQual_Collectors, attribs);
	if (iWeapon > MaxClients)
		SetEntPropEnt(boss.iClient, Prop_Send, "m_hActiveWeapon", iWeapon);
	/*
	Eyelander attributes:
	
	2: damage bonus
	252: reduction in push force taken from damage
	259: Deals 3x falling damage to the player you land on
	
	436: ragdolls_plasma_effect
	264: melee range multiplier (tf_weapon_sword have 37% extra range)
	*/
}

public void DemoRobot_GetModel(SaxtonHaleBase boss, char[] sModel, int length)
{
	strcopy(sModel, length, DEMO_ROBOT_MODEL);
}

public void DemoRobot_GetSound(SaxtonHaleBase boss, char[] sSound, int length, SaxtonHaleSound iSoundType)
{
	switch (iSoundType)
	{
		case VSHSound_RoundStart: strcopy(sSound, length, g_strDemoRobotSpawn[GetRandomInt(0,sizeof(g_strDemoRobotSpawn)-1)]);
		case VSHSound_Win: strcopy(sSound, length, g_strDemoRobotWin[GetRandomInt(0,sizeof(g_strDemoRobotWin)-1)]);
		case VSHSound_Lose: strcopy(sSound, length, DEMO_ROBOT_DEATH);
		case VSHSound_Rage: strcopy(sSound, length, DEMO_ROBOT_TURN_INTO_GIANT);
		case VSHSound_Lastman: strcopy(sSound, length, g_strDemoRobotLastMan[GetRandomInt(0,sizeof(g_strDemoRobotLastMan)-1)]);
		case VSHSound_Backstab: strcopy(sSound, length, g_strDemoRobotBackStab[GetRandomInt(0,sizeof(g_strDemoRobotBackStab)-1)]);
	}
}

public void DemoRobot_GetSoundAbility(SaxtonHaleBase boss, char[] sSound, int length, const char[] sType)
{
	if (strcmp(sType, "BraveJump") == 0)
		strcopy(sSound, length, g_strDemoRobotJump[GetRandomInt(0,sizeof(g_strDemoRobotJump)-1)]);
}

public Action DemoRobot_OnSoundPlayed(SaxtonHaleBase boss, int clients[MAXPLAYERS], int &numClients, char sample[PLATFORM_MAX_PATH], int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
	if (strncmp(sample, "vo/", 3) == 0)
	{
		if (StrContains(sample, "vo/mvm/", false) == 0)
			return Plugin_Continue;
		
		char file[PLATFORM_MAX_PATH];
		strcopy(file, PLATFORM_MAX_PATH, sample);
		ReplaceString(file, sizeof(file), "vo/demoman_", "vo/mvm/norm/demoman_mvm_", false);
		Format(file, sizeof(file), "sound/%s", file);
		
		if (FileExists(file, true))
		{
			ReplaceString(sample, sizeof(sample), "vo/demoman_", "vo/mvm/norm/demoman_mvm_", false);
			PrecacheSound(sample);
			return Plugin_Changed;
		}
		return Plugin_Handled;
	}
	
	if (StrContains(sample, "player/footsteps/", false) != -1)
	{
		EmitSoundToAll(g_strSoundRobotFootsteps[GetRandomInt(0, sizeof(g_strSoundRobotFootsteps)-1)], boss.iClient, _, _, _, 0.13, GetRandomInt(95, 100));
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public void DemoRobot_GetMusicInfo(SaxtonHaleBase boss, char[] sSound, int length, float &time)
{
	strcopy(sSound, length, DEMO_ROBOT_THEME);
	time = 144.0;
}

public void DemoRobot_OnRage(SaxtonHaleBase boss)
{
	int iClient = boss.iClient;
	
	TF2_RemoveItemInSlot(iClient, WeaponSlot_Primary);
	
	char attribs[256];
	Format(attribs, sizeof(attribs), "15 ; 1.0 ; 77 ; 0.0 ; 330 ; 4.0 ; 335 ; 996.0");
	
	if (!boss.bSuperRage)
		StrCat(attribs, sizeof(attribs), " ; 6 ; 0.3");
	else
		StrCat(attribs, sizeof(attribs), " ; 6 ; 0.15");
	
	int iWeapon = boss.CallFunction("CreateWeapon", 206, "tf_weapon_grenadelauncher", 100, TFQual_Unusual, attribs);
	if (iWeapon > MaxClients)
	{
		TF2_SwitchToWeapon(boss.iClient, iWeapon);
		SetEntProp(iWeapon, Prop_Send, "m_iClip1", 1000);
	}
	/*
	Gremade Launcher attributes:
	
	6: faster firing speed
	15: No random critical hits
	77: max primary ammo
	303: mod_max_primary_clip_override
	330: override_footstep_sound_set
	335: clip size
	*/
	
	int iMeleeWep = GetPlayerWeaponSlot(iClient, WeaponSlot_Melee);
	if (iMeleeWep > MaxClients)
	{
		float flVal;
		TF2_WeaponFindAttribute(iMeleeWep, ATTRIB_MELEE_RANGE_MULTIPLIER, flVal);
		flVal *= DEMO_ROBOT_GIANT_SCALE;
		TF2Attrib_SetByDefIndex(iMeleeWep, ATTRIB_MELEE_RANGE_MULTIPLIER, flVal);
	}
	
	g_flGrenadeLauncherRemoveTime[iClient] = GetGameTime()+8.0;
}

public void DemoRobot_OnThink(SaxtonHaleBase boss)
{
	int iClient = boss.iClient;
	
	if (g_flGrenadeLauncherRemoveTime[iClient] != 0.0 && g_flGrenadeLauncherRemoveTime[iClient] <= GetGameTime())
	{
		TF2_RemoveItemInSlot(iClient, WeaponSlot_Primary);
		g_flGrenadeLauncherRemoveTime[iClient] = 0.0;
		
		int iMeleeWep = GetPlayerWeaponSlot(iClient, WeaponSlot_Melee);
		if (iMeleeWep > MaxClients)
		{
			float flVal;
			TF2_WeaponFindAttribute(iMeleeWep, ATTRIB_MELEE_RANGE_MULTIPLIER, flVal);
			flVal /= DEMO_ROBOT_GIANT_SCALE;
			TF2Attrib_SetByDefIndex(iMeleeWep, ATTRIB_MELEE_RANGE_MULTIPLIER, flVal);
			
			TF2_SwitchToWeapon(boss.iClient, iMeleeWep);
		}
	}
}

public void DemoRobot_Precache(SaxtonHaleBase boss)
{
	for (int i = 0; i < sizeof(g_strSoundRobotFootsteps); i++) PrecacheSound(g_strSoundRobotFootsteps[i]);
	for (int i = 0; i < sizeof(g_strSoundGiantFootsteps); i++) PrecacheSound(g_strSoundGiantFootsteps[i]);
	for (int i = 0; i < sizeof(g_strDemoRobotWin); i++) PrecacheSound(g_strDemoRobotWin[i]);
	for (int i = 0; i < sizeof(g_strDemoRobotSpawn); i++) PrecacheSound(g_strDemoRobotSpawn[i]);
	for (int i = 0; i < sizeof(g_strDemoRobotBackStab); i++) PrecacheSound(g_strDemoRobotBackStab[i]);
	for (int i = 0; i < sizeof(g_strDemoRobotLastMan); i++) PrecacheSound(g_strDemoRobotLastMan[i]);
	for (int i = 0; i < sizeof(g_strDemoRobotJump); i++) PrecacheSound(g_strDemoRobotJump[i]);
	
	PrecacheSound(DEMO_ROBOT_TURN_INTO_GIANT);
	PrecacheSound(DEMO_ROBOT_DEATH);
	PrecacheSound(DEMO_ROBOT_GRENADE_LAUNCHER_SHOOT);
	PrepareMusic(DEMO_ROBOT_THEME);
	
	PrecacheModel(DEMO_ROBOT_MODEL);
}

