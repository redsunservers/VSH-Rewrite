#define GRAYMANN_THEME 					"ui/gamestartup16.mp3"
#define GRAYMANN_RAGE 					"mvm/mvm_tele_deliver.wav"
#define GRAYMANN_MODEL 					"models/player/vsh_rewrite/graymann/graymann.mdl"

#define GRAYMANN_SOLDIERMINION 			"models/bots/soldier_boss/bot_soldier_boss.mdl"
#define GRAYMANN_DEMOMINION 			"models/bots/demo_boss/bot_demo_boss.mdl"
#define GRAYMANN_PYROMINION				"models/bots/pyro_boss/bot_pyro_boss.mdl"

#define GRAYMANN_GIANTROCKETSOUND		"mvm/giant_soldier/giant_soldier_rocket_shoot.wav"
#define GRAYMANN_GIANTCRITROCKETSOUND 	"mvm/giant_soldier/giant_soldier_rocket_shoot_crit.wav"
#define GRAYMANN_GIANTGRENADESOUND		"mvm/giant_demoman/giant_demoman_grenade_shoot.wav"

#define GRAYMANN_GIANTDESTROYEDSOUND	"MVM.GiantCommonExplodes"

#define GRAYMANN_MAX_GIANT_GIBS			4
#define GRAYMANN_GIANT_ROBOT_SCALE		1.5

enum
{
	GRAYMANN_QUEUE_CAN_SPAWN,
	GRAYMANN_QUEUE_NO_CANDIDATES,
	GRAYMANN_QUEUE_NO_SPACE
}

static int g_iGrayMannQueuedMinions[MAXPLAYERS + 1];
static int g_iGrayMannQueueReason[MAXPLAYERS + 1];

static Handle g_hGrayMannSpawnQueuedMinionTimer[MAXPLAYERS + 1];

static int g_iGrayMannMinionAFKTimeLeft[MAXPLAYERS + 1];
static Handle g_hGrayMannMinionAFKTimer[MAXPLAYERS + 1];
static bool g_bGrayMannPlayerWasSummoned[MAXPLAYERS + 1];
static bool g_bGrayMannMinionHasMoved[MAXPLAYERS + 1];
static bool g_bGrayMannMinionIsPlayingSoundLoop[MAXPLAYERS + 1];

static bool g_bGrayMannMinionBlockRagdoll;

static char g_strGrayMannRoundStart[][] = {
	"vsh_rewrite/graymann/intro1.mp3",
	"vsh_rewrite/graymann/intro2.mp3",
	"vsh_rewrite/graymann/intro3.mp3"
};

static char g_strGrayMannWin[][] = {
	"vsh_rewrite/graymann/win.mp3"
};

static char g_strGrayMannLose[][] = {
	"vsh_rewrite/graymann/lose.mp3"
};

static char g_strGrayMannRage[][] = {
	"vsh_rewrite/graymann/rage1.mp3",
	"vsh_rewrite/graymann/rage2.mp3",
	"vsh_rewrite/graymann/rage3.mp3"
};

static char g_strGrayMannKill[][] = {
	"vsh_rewrite/graymann/laugh1.mp3",
	"vsh_rewrite/graymann/laugh2.mp3",
	"vsh_rewrite/graymann/laugh3.mp3"
};

static char g_strGrayMannLastMan[][] = {
	"vsh_rewrite/graymann/lastman1.mp3",
	"vsh_rewrite/graymann/lastman2.mp3"
};

static char g_strGrayMannBackStabbed[][] = {
	"weapons/fx/rics/arrow_impact_metal.wav",
	"weapons/fx/rics/arrow_impact_metal2.wav",
	"weapons/fx/rics/arrow_impact_metal4.wav"
};

static char g_strGrayMannSoundGiantLoop[][] = {
	"", // Unknown
	"", // Scout
	"", // Sniper
	"MVM.GiantSoldierLoop",
	"MVM.GiantDemomanLoop",
	"", // Medic
	"", // Heavy
	"MVM.GiantPyroLoop",
	"", // Spy
	""  // Engineer
};


// Gibs: heads are always the first item in the arrays

static char g_strGrayMannSoldierGibs[][] = {
	"models/bots/gibs/soldierbot_gib_boss_head.mdl",
	"models/bots/gibs/soldierbot_gib_boss_arm1.mdl",
	"models/bots/gibs/soldierbot_gib_boss_arm2.mdl",
	"models/bots/gibs/soldierbot_gib_boss_chest.mdl",
	"models/bots/gibs/soldierbot_gib_boss_leg1.mdl",
	"models/bots/gibs/soldierbot_gib_boss_leg2.mdl",
	"models/bots/gibs/soldierbot_gib_boss_pelvis.mdl"
};

static char g_strGrayMannPyroGibs[][] = {
	"models/bots/gibs/pyrobot_gib_boss_head.mdl",
	"models/bots/gibs/pyrobot_gib_boss_arm1.mdl",
	"models/bots/gibs/pyrobot_gib_boss_arm2.mdl",
	"models/bots/gibs/pyrobot_gib_boss_arm3.mdl",
	"models/bots/gibs/pyrobot_gib_boss_chest.mdl",
	"models/bots/gibs/pyrobot_gib_boss_chest2.mdl",
	"models/bots/gibs/pyrobot_gib_boss_leg.mdl",
	"models/bots/gibs/pyrobot_gib_boss_pelvis.mdl"
};

static char g_strGrayMannDemomanGibs[][] = {
	"models/bots/gibs/demobot_gib_boss_head.mdl",
	"models/bots/gibs/demobot_gib_boss_arm1.mdl",
	"models/bots/gibs/demobot_gib_boss_arm2.mdl",
	"models/bots/gibs/demobot_gib_boss_leg1.mdl",
	"models/bots/gibs/demobot_gib_boss_leg2.mdl",
	"models/bots/gibs/demobot_gib_boss_leg3.mdl",
	"models/bots/gibs/demobot_gib_boss_pelvis.mdl"
};

////////////////////////////////////////////////////////
//
// GRAY MANN
//
////////////////////////////////////////////////////////

public void GrayMann_Create(SaxtonHaleBase boss)
{	
	boss.CreateClass("BraveJump");
	boss.SetPropFloat("BraveJump", "MaxHeight", boss.GetPropFloat("BraveJump", "MaxHeight") * 0.50);
	boss.CreateClass("RageAddCond");
	boss.SetPropFloat("RageAddCond", "RageCondDuration", 8.0);
	RageAddCond_AddCond(boss, TFCond_DefenseBuffed);
	RageAddCond_AddCond(boss, TFCond_SpeedBuffAlly);
	
	boss.flSpeed = 350.0;
	boss.iHealthPerPlayer = 400;
	boss.flHealthExponential = 1.05;
	boss.nClass = TFClass_Engineer;
	boss.iMaxRageDamage = 3000;
	
	for (int iClient = 1; iClient <= MaxClients; iClient++)
		g_bGrayMannPlayerWasSummoned[iClient] = false;
	
	g_iGrayMannQueuedMinions[boss.iClient] = 0;
	g_iGrayMannQueueReason[boss.iClient] = GRAYMANN_QUEUE_CAN_SPAWN;
	g_bGrayMannMinionBlockRagdoll = false;
}

public void GrayMann_GetBossName(SaxtonHaleBase boss, char[] sName, int length)
{
	strcopy(sName, length, "Gray Mann");
}

public void GrayMann_GetBossInfo(SaxtonHaleBase boss, char[] sInfo, int length)
{
	StrCat(sInfo, length, "\nHealth: Low");
	StrCat(sInfo, length, "\n ");
	StrCat(sInfo, length, "\nAbilities");
	StrCat(sInfo, length, "\n- Killing people turns them into gold, and you siphon their power to heal yourself for 250 HP flat");
	StrCat(sInfo, length, "\n ");
	StrCat(sInfo, length, "\nRage");
	StrCat(sInfo, length, "\n- Damage requirement: 3000");
	StrCat(sInfo, length, "\n- Spawn a random giant robot");
	StrCat(sInfo, length, "\n- 200%% Rage: Spawn 2 random giant robots");
}

public void GrayMann_GetModel(SaxtonHaleBase boss, char[] sModel, int length)
{
	strcopy(sModel, length, GRAYMANN_MODEL);
}

public void GrayMann_OnRage(SaxtonHaleBase boss)
{
	int iTotalSummons = 1;
	if (boss.bSuperRage) iTotalSummons = 2;
	
	if (g_iGrayMannQueuedMinions[boss.iClient] == 0)
		g_hGrayMannSpawnQueuedMinionTimer[boss.iClient] = CreateTimer(1.0, GrayMann_Timer_TryToSpawnQueuedMinion, GetClientUserId(boss.iClient), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	
	g_iGrayMannQueuedMinions[boss.iClient] += iTotalSummons;
	
	boss.CallFunction("UpdateHudInfo", 0.0, 0.0);	// Update once
}

public void GrayMann_OnSpawn(SaxtonHaleBase boss)
{
	int iWeapon;
	char attribs[128];
	Format(attribs, sizeof(attribs), "2 ; 2.80 ; 252 ; 0.5 ; 259 ; 1.0 ; 150 ; 1.0 ; 180 ; 250");
	iWeapon = boss.CallFunction("CreateWeapon", 169, "tf_weapon_wrench", 100, TFQual_Unusual, attribs);
	if (iWeapon > MaxClients)
	{
		SetEntPropEnt(boss.iClient, Prop_Send, "m_hActiveWeapon", iWeapon);
	}
	/*
	wrench attributes:
	
	2: damage bonus
	252: reduction in push force taken from damage
	259: Deals 3x falling damage to the player you land on
	150: turn to gold
	180: heal on kill
	*/
}

public void GrayMann_OnEntityCreated(SaxtonHaleBase boss, int iEntity, const char[] sClassname)
{
	if (g_bGrayMannMinionBlockRagdoll && StrEqual(sClassname, "tf_ragdoll"))
	{
		RemoveEntity(iEntity);
		g_bGrayMannMinionBlockRagdoll = false;
	}
}

public void GrayMann_GetSound(SaxtonHaleBase boss, char[] sSound, int length, SaxtonHaleSound iSoundType)
{
	switch (iSoundType)
	{
		case VSHSound_RoundStart: strcopy(sSound, length, g_strGrayMannRoundStart[GetRandomInt(0,sizeof(g_strGrayMannRoundStart)-1)]);
		case VSHSound_Win: strcopy(sSound, length, g_strGrayMannWin[GetRandomInt(0,sizeof(g_strGrayMannWin)-1)]);
		case VSHSound_Lose: strcopy(sSound, length, g_strGrayMannLose[GetRandomInt(0,sizeof(g_strGrayMannLose)-1)]);
		case VSHSound_Rage: strcopy(sSound, length, g_strGrayMannRage[GetRandomInt(0,sizeof(g_strGrayMannRage)-1)]);
		case VSHSound_Lastman: strcopy(sSound, length, g_strGrayMannLastMan[GetRandomInt(0,sizeof(g_strGrayMannLastMan)-1)]);
		case VSHSound_Backstab: strcopy(sSound, length, g_strGrayMannBackStabbed[GetRandomInt(0,sizeof(g_strGrayMannBackStabbed)-1)]);
	}
}

public void GrayMann_GetSoundKill(SaxtonHaleBase boss, char[] sSound, int length, TFClassType nClass)
{
	strcopy(sSound, length, g_strGrayMannKill[GetRandomInt(0, sizeof(g_strGrayMannKill) - 1)]);
}

public Action GrayMann_OnSoundPlayed(SaxtonHaleBase boss, int clients[MAXPLAYERS], int &numClients, char sample[PLATFORM_MAX_PATH], int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
	if (strncmp(sample, "vo/", 3) == 0)//Block voicelines
		return Plugin_Handled;
	
	return Plugin_Continue;
}

public void GrayMann_GetMusicInfo(SaxtonHaleBase boss, char[] sSound, int length, float &time)
{
	strcopy(sSound, length, GRAYMANN_THEME);
	time = 214.0;
}

public void GrayMann_GetHudInfo(SaxtonHaleBase boss, char[] sMessage, int iLength, int iColor[4])
{
	int iQueue = g_iGrayMannQueuedMinions[boss.iClient];
	if (iQueue > 0)
	{
		Format(sMessage, iLength, "%s\nYou have %d giant robot%s queued.", sMessage, iQueue, (iQueue > 1) ? "s" : "");
		
		switch (g_iGrayMannQueueReason[boss.iClient])
		{
			case GRAYMANN_QUEUE_NO_CANDIDATES: Format(sMessage, iLength, "%s\nThere are no players available to summon.", sMessage);
			case GRAYMANN_QUEUE_NO_SPACE: Format(sMessage, iLength, "%s\nThere is not enough space around you to fit a giant robot.", sMessage);
		}
	}
}

public void GrayMann_Precache(SaxtonHaleBase boss) //not sure if custom sounds have to be in the downloadstable but I added them anyway
{
	PrecacheModel(GRAYMANN_MODEL);
	PrepareMusic(GRAYMANN_THEME, false);
	PrecacheSound(GRAYMANN_RAGE);
	
	for (int i = 0; i < sizeof(g_strGrayMannRoundStart); i++) PrepareSound(g_strGrayMannRoundStart[i]);
	for (int i = 0; i < sizeof(g_strGrayMannWin); i++) PrepareSound(g_strGrayMannWin[i]);
	for (int i = 0; i < sizeof(g_strGrayMannLose); i++) PrepareSound(g_strGrayMannLose[i]);
	for (int i = 0; i < sizeof(g_strGrayMannRage); i++) PrepareSound(g_strGrayMannRage[i]);
	for (int i = 0; i < sizeof(g_strGrayMannKill); i++) PrepareSound(g_strGrayMannKill[i]);
	
	for (int i = 0; i < sizeof(g_strGrayMannSoldierGibs); i++) PrecacheModel(g_strGrayMannSoldierGibs[i]);
	for (int i = 0; i < sizeof(g_strGrayMannPyroGibs); i++) PrecacheModel(g_strGrayMannPyroGibs[i]);
	for (int i = 0; i < sizeof(g_strGrayMannDemomanGibs); i++) PrecacheModel(g_strGrayMannDemomanGibs[i]);
	
	PrecacheSound(GRAYMANN_GIANTROCKETSOUND);
	PrecacheSound(GRAYMANN_GIANTCRITROCKETSOUND);
	PrecacheSound(GRAYMANN_GIANTGRENADESOUND);

	//Materials
	AddFileToDownloadsTable("materials/models/player/graymann/eyeball_l.vmt");
	AddFileToDownloadsTable("materials/models/player/graymann/eyeball_r.vmt");
	AddFileToDownloadsTable("materials/models/player/graymann/graymann.vmt");
	AddFileToDownloadsTable("materials/models/player/graymann/graymann_alpha.vtf");
	AddFileToDownloadsTable("materials/models/player/graymann/graymann_apron_normal.vtf");
	AddFileToDownloadsTable("materials/models/player/graymann/graymann_lifepack.vmt");
	AddFileToDownloadsTable("materials/models/player/graymann/graymann_lifepack.vtf");
	AddFileToDownloadsTable("materials/models/player/graymann/graymann_normal.vtf");
	AddFileToDownloadsTable("materials/models/player/graymann/hands.vmt");
	AddFileToDownloadsTable("materials/models/player/graymann/hands.vtf");
	AddFileToDownloadsTable("materials/models/player/graymann/hands_normal.vtf");
	AddFileToDownloadsTable("materials/models/player/graymann/intro.vmt");
	AddFileToDownloadsTable("materials/models/player/graymann/intro.vtf");
	AddFileToDownloadsTable("materials/models/player/graymann/hwm/graymann_head.vmt");
	AddFileToDownloadsTable("materials/models/player/graymann/hwm/graymann_head_alpha.vtf");
	AddFileToDownloadsTable("materials/models/player/graymann/hwm/graymann_head_compress.vtf");
	AddFileToDownloadsTable("materials/models/player/graymann/hwm/graymann_head_exponent.vtf");
	AddFileToDownloadsTable("materials/models/player/graymann/hwm/graymann_head_stretch.vtf");
	
	//Models
	AddFileToDownloadsTable("models/player/vsh_rewrite/graymann/graymann.mdl");
	AddFileToDownloadsTable("models/player/vsh_rewrite/graymann/graymann.vvd");
	AddFileToDownloadsTable("models/player/vsh_rewrite/graymann/graymann.phy");
	AddFileToDownloadsTable("models/player/vsh_rewrite/graymann/graymann.dx80.vtx");
	AddFileToDownloadsTable("models/player/vsh_rewrite/graymann/graymann.dx90.vtx");
}

public void GrayMann_Destroy(SaxtonHaleBase boss)
{
	g_hGrayMannSpawnQueuedMinionTimer[boss.iClient] = null;
}

////////////////////////////////////////////////////////
//
// GIANT ROBOT MINIONS
//
////////////////////////////////////////////////////////

public void GrayMannSoldierMinion_Create(SaxtonHaleBase boss) //Giant Soldier Stats
{
	boss.iBaseHealth = 2500;
	boss.iHealthPerPlayer = 25;
	boss.flSpeed = 150.0;
	boss.nClass = TFClass_Soldier;
	boss.iMaxRageDamage = -1;
	boss.bMinion = true;
	boss.bHealthPerPlayerAlive = true;
	
	GrayMann_GiantCommon_Create(boss);
}

public void GrayMannDemomanMinion_Create(SaxtonHaleBase boss) //Giant Demoman Stats
{
	boss.iBaseHealth = 2500;
	boss.iHealthPerPlayer = 25;
	boss.flSpeed = 150.0;
	boss.nClass = TFClass_DemoMan;
	boss.iMaxRageDamage = -1;
	boss.bMinion = true;
	boss.bHealthPerPlayerAlive = true;
	
	GrayMann_GiantCommon_Create(boss);
}

public void GrayMannPyroMinion_Create(SaxtonHaleBase boss) //Giant Pyro Stats
{
	boss.iBaseHealth = 1500;
	boss.iHealthPerPlayer = 30;
	boss.flSpeed = 200.0;
	boss.nClass = TFClass_Pyro;
	boss.iMaxRageDamage = -1;
	boss.bMinion = true;
	boss.bHealthPerPlayerAlive = true;
	
	GrayMann_GiantCommon_Create(boss);
}

public void GrayMannSoldierMinion_GetModel(SaxtonHaleBase boss, char[] sModel, int length)
{
	strcopy(sModel, length, GRAYMANN_SOLDIERMINION);
}

public void GrayMannDemomanMinion_GetModel(SaxtonHaleBase boss, char[] sModel, int length)
{
	strcopy(sModel, length, GRAYMANN_DEMOMINION);
}

public void GrayMannPyroMinion_GetModel(SaxtonHaleBase boss, char[] sModel, int length)
{
	strcopy(sModel, length, GRAYMANN_PYROMINION);
}

public bool GrayMannSoldierMinion_IsBossHidden(SaxtonHaleBase boss)
{
	return true;
}

public bool GrayMannDemomanMinion_IsBossHidden(SaxtonHaleBase boss)
{
	return true;
}

public bool GrayMannPyroMinion_IsBossHidden(SaxtonHaleBase boss)
{
	return true;
}

public void GrayMannSoldierMinion_OnSpawn(SaxtonHaleBase boss) //Soldier's Attributes
{
	char sAttribs[256];
	strcopy(sAttribs, sizeof(sAttribs), "4 ; 2.0 ; 6 ; 0.75 ; 97 ; 0.5 ; 252 ; 0.5 ; 259 ; 1.0 ; 330 ; 3.0");
	int iWeapon = boss.CallFunction("CreateWeapon", 205, "tf_weapon_rocketlauncher", 10, TFQual_Collectors, sAttribs);
	
	/*
	Rocket Launcher attributes:
	
	4: clip size bonus
	6: fire rate bonus
	97: reload time decreased
	252: reduction in push force taken from damage
	259: Deals 3x falling damage to the player you land on
	330: override footstep sound set
	*/
	
	GrayMann_GiantCommon_OnSpawn(boss, iWeapon);
}

public void GrayMannDemomanMinion_OnSpawn(SaxtonHaleBase boss) //Demo's Attributes
{
	char sAttribs[256];
	strcopy(sAttribs, sizeof(sAttribs), "4 ; 2.0 ; 6 ; 0.50 ; 252 ; 0.5 ; 259 ; 1.0 ; 330 ; 4.0");
	int iWeapon = boss.CallFunction("CreateWeapon", 206, "tf_weapon_grenadelauncher", 100, TFQual_Collectors, sAttribs);
	
	/*
	Grenade Launcher attributes:
	
	4: clip size bonus
	6: fire rate bonus
	252: reduction in push force taken from damage
	259: Deals 3x falling damage to the player you land on
	330: override footstep sound set
	*/
	
	GrayMann_GiantCommon_OnSpawn(boss, iWeapon);
}

public void GrayMannPyroMinion_OnSpawn(SaxtonHaleBase boss) //Pyro's Attributes. Don't touch it. Don't even blink. Don't do fucking ANYTHING.
{
	char sAttribs[256];
	strcopy(sAttribs, sizeof(sAttribs), "844 ; 1850.0 ; 841 ; 0.0 ; 843 ; 10.0 ; 862 ; 0.50 ; 4 ; 2.0 ; 356 ; 1.0 ; 252 ; 0.5 ; 259 ; 1.0 ; 330 ; 6.0 ; 164 ; 2.0");
	int iWeapon = boss.CallFunction("CreateWeapon", 208, "tf_weapon_flamethrower", 100, TFQual_Collectors, sAttribs);
	
	/*
	Flammenwerfer attributes:
	// DO NOT USE FLAME_SPEED UNDER ANY CIRCUMSTANCES, FOR SOME REASON IT COMPLETELY FUCKS WITH AIRBLAST DISABLED, FUCK YOU!!!!
	// https://www.youtube.com/watch?v=_4qEz5ONk5c&ab_channel=1995Berserk this is me after working with pyro attributes btw
	// its ok it works now!!!!!!!!!!!!!!!!!!!!! steamhappy
	
	844: flame speed UNFORTUFUCKINGNATELY
	841: flame gravity
	843: flame drag
	862: flame lifetime
	4: clip size bonus
	164: flame life bonus
	356: airblast disabled
	252: reduction in push force taken from damage
	259: Deals 3x falling damage to the player you land on
	330: override footstep sound set
	*/
	
	GrayMann_GiantCommon_OnSpawn(boss, iWeapon);
}

public void GrayMannSoldierMinion_OnThink(SaxtonHaleBase boss)
{
	GrayMann_GiantCommon_OnThink(boss);
}

public void GrayMannDemomanMinion_OnThink(SaxtonHaleBase boss)
{
	GrayMann_GiantCommon_OnThink(boss);
}

public void GrayMannPyroMinion_OnThink(SaxtonHaleBase boss)
{
	GrayMann_GiantCommon_OnThink(boss);
}

public void GrayMannSoldierMinion_OnButtonPress(SaxtonHaleBase boss, int button)
{
	GrayMann_GiantCommon_OnButtonPress(boss);
}

public void GrayMannDemomanMinion_OnButtonPress(SaxtonHaleBase boss, int button)
{
	GrayMann_GiantCommon_OnButtonPress(boss);
}

public void GrayMannPyroMinion_OnButtonPress(SaxtonHaleBase boss, int button)
{
	GrayMann_GiantCommon_OnButtonPress(boss);
}

public Action GrayMannSoldierMinion_OnSoundPlayed(SaxtonHaleBase boss, int clients[MAXPLAYERS], int &numClients, char sample[PLATFORM_MAX_PATH], int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
	if (strncmp(sample, "vo/", 3) == 0)
	{
		if (strncmp(sample, "vo/mvm/", 7) == 0)
			return Plugin_Continue;
		
		char file[PLATFORM_MAX_PATH];
		strcopy(file, PLATFORM_MAX_PATH, sample);
		ReplaceString(file, sizeof(file), "vo/soldier_", "vo/mvm/mght/soldier_mvm_m_", false);
		Format(file, sizeof(file), "sound/%s", file);
		
		if (FileExists(file, true))
		{
			ReplaceString(sample, sizeof(sample), "vo/soldier_", "vo/mvm/mght/soldier_mvm_m_", false);
			PrecacheSound(sample);
			return Plugin_Changed;
		}
		
		return Plugin_Handled;
	}
	else if (strcmp(sample, ")weapons/rocket_shoot.wav") == 0)
	{
		strcopy(sample, sizeof(sample), GRAYMANN_GIANTROCKETSOUND);
		EmitSoundToClient(boss.iClient, sample, _, SNDCHAN_WEAPON);
		return Plugin_Changed;
	}
	else if (strcmp(sample, ")weapons/rocket_shoot_crit.wav") == 0)
	{
		strcopy(sample, sizeof(sample), GRAYMANN_GIANTCRITROCKETSOUND);
		EmitSoundToClient(boss.iClient, sample, _, SNDCHAN_WEAPON);
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}

public Action GrayMannDemomanMinion_OnSoundPlayed(SaxtonHaleBase boss, int clients[MAXPLAYERS], int &numClients, char sample[PLATFORM_MAX_PATH], int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
	if (strncmp(sample, "vo/", 3) == 0)
	{
		if (strncmp(sample, "vo/mvm/", 7) == 0)
			return Plugin_Continue;
		
		char file[PLATFORM_MAX_PATH];
		strcopy(file, PLATFORM_MAX_PATH, sample);
		ReplaceString(file, sizeof(file), "vo/demoman_", "vo/mvm/mght/demoman_mvm_m_", false);
		Format(file, sizeof(file), "sound/%s", file);
		
		if (FileExists(file, true))
		{
			ReplaceString(sample, sizeof(sample), "vo/demoman_", "vo/mvm/mght/demoman_mvm_m_", false);
			PrecacheSound(sample);
			return Plugin_Changed;
		}
		
		return Plugin_Handled;
	}
	else if (strcmp(sample, ")weapons/grenade_launcher_shoot.wav") == 0 || strcmp(sample, ")weapons/grenade_launcher_shoot_crit.wav") == 0)
	{
		strcopy(sample, sizeof(sample), GRAYMANN_GIANTGRENADESOUND);
		EmitSoundToClient(boss.iClient, sample, _, SNDCHAN_WEAPON);
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}

public Action GrayMannPyroMinion_OnSoundPlayed(SaxtonHaleBase boss, int clients[MAXPLAYERS], int &numClients, char sample[PLATFORM_MAX_PATH], int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
	if (strncmp(sample, "vo/", 3) == 0)
	{
		if (strncmp(sample, "vo/mvm/", 7) == 0)
			return Plugin_Continue;
		
		char file[PLATFORM_MAX_PATH];
		strcopy(file, PLATFORM_MAX_PATH, sample);
		ReplaceString(file, sizeof(file), "vo/pyro_", "vo/mvm/mght/pyro_mvm_m_", false);
		Format(file, sizeof(file), "sound/%s", file);
		
		if (FileExists(file, true))
		{
			ReplaceString(sample, sizeof(sample), "vo/pyro_", "vo/mvm/mght/pyro_mvm_m_", false);
			PrecacheSound(sample);
			return Plugin_Changed;
		}
		
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public void GrayMannSoldierMinion_OnDeath(SaxtonHaleBase boss)
{
	GrayMann_GiantCommon_OnDeath(boss);
}

public void GrayMannDemomanMinion_OnDeath(SaxtonHaleBase boss)
{
	GrayMann_GiantCommon_OnDeath(boss);
}

public void GrayMannPyroMinion_OnDeath(SaxtonHaleBase boss)
{
	GrayMann_GiantCommon_OnDeath(boss);
}

public void GrayMannSoldierMinion_Destroy(SaxtonHaleBase boss)
{
	GrayMann_GiantCommon_Destroy(boss);
}

public void GrayMannDemomanMinion_Destroy(SaxtonHaleBase boss)
{
	GrayMann_GiantCommon_Destroy(boss);
}

public void GrayMannPyroMinion_Destroy(SaxtonHaleBase boss)
{
	GrayMann_GiantCommon_Destroy(boss);
}

////////////////////////////////////////////////////////
//
// COMMON GIANT ROBOT FUNCTIONS
//
////////////////////////////////////////////////////////

void GrayMann_GiantCommon_Create(SaxtonHaleBase boss)
{
	g_bGrayMannMinionHasMoved[boss.iClient] = false;	// Will check if the player has moved to determine if they're AFK or not
	g_iGrayMannMinionAFKTimeLeft[boss.iClient] = 6;		// The player has 6 seconds to move after being summoned, else they'll be taken as AFK and replaced by someone else
	
	EmitSoundToClient(boss.iClient, SOUND_ALERT);		// Alert player as they (re)spawned
}

void GrayMann_GiantCommon_OnSpawn(SaxtonHaleBase boss, int iWeapon)
{
	SetEntityModelScale(boss.iClient, GRAYMANN_GIANT_ROBOT_SCALE);
	
	SetEntProp(boss.iClient, Prop_Data, "m_bloodColor", DONT_BLEED);
	
	if (iWeapon > MaxClients)
	{
		TF2_SwitchToWeapon(boss.iClient, iWeapon);
		SetEntProp(iWeapon, Prop_Send, "m_iClip1", SDK_GetMaxClip(iWeapon));
		TF2_SetAmmo(boss.iClient, TF_AMMO_PRIMARY, 99999);
	}
	
	// To ensure the looping sounds stop
	SetEdictFlags(boss.iClient, GetEdictFlags(boss.iClient) | FL_EDICT_ALWAYS);
	
	// Looping sounds persist if they're stopped on round change, so we stop/don't play them after the round ends
	if (GameRules_GetRoundState() != RoundState_TeamWin && GameRules_GetRoundState() != RoundState_Preround)
	{
		char sSoundLoop[PLATFORM_MAX_PATH];
		strcopy(sSoundLoop, sizeof(sSoundLoop), g_strGrayMannSoundGiantLoop[boss.nClass]);
		if (sSoundLoop[0])
		{
			EmitGameSoundToAll(sSoundLoop, boss.iClient);
			g_bGrayMannMinionIsPlayingSoundLoop[boss.iClient] = true;
		}
	}
	
	g_hGrayMannMinionAFKTimer[boss.iClient] = CreateTimer(0.0, Timer_GrayMann_ReplaceMinion, boss.iClient);
}

void GrayMann_GiantCommon_OnThink(SaxtonHaleBase boss)
{
	if (GameRules_GetRoundState() == RoundState_TeamWin && g_bGrayMannMinionIsPlayingSoundLoop[boss.iClient])
		GrayMann_GiantCommon_StopLoopingSound(boss);
}

void GrayMann_GiantCommon_OnButtonPress(SaxtonHaleBase boss)
{
	//Check if the player presses anything, thus isn't AFK
	if (!g_bGrayMannMinionHasMoved[boss.iClient])
	{	
		//Reset their über spawn protection
		TF2_RemoveCondition(boss.iClient, TFCond_UberchargedCanteen);
		TF2_AddCondition(boss.iClient, TFCond_UberchargedCanteen, 3.0);
			
		g_bGrayMannMinionHasMoved[boss.iClient] = true;
	}
}

void GrayMann_GiantCommon_OnDeath(SaxtonHaleBase boss)
{
	g_bGrayMannMinionBlockRagdoll = true;
	GrayMann_CreateRobotGibs(boss.iClient);
	EmitGameSoundToAll(GRAYMANN_GIANTDESTROYEDSOUND, boss.iClient);
	GrayMann_GiantCommon_StopLoopingSound(boss);
	
	//This is called on death in case people suicide after getting summoned instead of disabling respawn
	if (!g_bGrayMannMinionHasMoved[boss.iClient])
	{
		ArrayList aValidMinions = GetValidSummonableClients();
		
		//Spawn and teleport the replacement to where this AFK minion is, if valid
		int iBestClient = GrayMann_SelectBestPlayer(aValidMinions);
		if (iBestClient > 0)
		{
			GrayMann_SpawnMinion(iBestClient, boss.nClass);
			TF2_TeleportToClient(iBestClient, boss.iClient);
		}
			
		delete aValidMinions;
	}
}

void GrayMann_GiantCommon_Destroy(SaxtonHaleBase boss)
{
	// It errors out when using a float instead of a string, so it looks odd
	SetVariantString("1.0");
	AcceptEntityInput(boss.iClient, "SetModelScale");
	
	g_hGrayMannMinionAFKTimer[boss.iClient] = null;
	
	GrayMann_GiantCommon_StopLoopingSound(boss);
	
	SetEdictFlags(boss.iClient, GetEdictFlags(boss.iClient) & ~FL_EDICT_ALWAYS);
	SetEntProp(boss.iClient, Prop_Send, "m_bIsMiniBoss", false);
}

void GrayMann_GiantCommon_StopLoopingSound(SaxtonHaleBase boss)
{
	char sSoundLoop[PLATFORM_MAX_PATH];
	strcopy(sSoundLoop, sizeof(sSoundLoop), g_strGrayMannSoundGiantLoop[boss.nClass]);
	if (sSoundLoop[0])
		EmitGameSoundToAll(sSoundLoop, boss.iClient, (SND_STOP | SND_STOPLOOPING));
	
	g_bGrayMannMinionIsPlayingSoundLoop[boss.iClient] = false;
}

////////////////////////////////////////////////////////
//
// MISC GRAY MANN-MINION INTERACTION FUNCTIONS
//
////////////////////////////////////////////////////////

int GrayMann_SelectBestPlayer(ArrayList aClients)
{
	int iBestClientIndex = -1;
	int iLength = aClients.Length;
	int iBestScore = -1;
	
	for (int i = 0; i < iLength; i++)
	{
		int iClient = aClients.Get(i);
		
		if (!g_bGrayMannPlayerWasSummoned[iClient])
		{
			int iClientScore = SaxtonHale_GetScore(iClient);
			
			if (iClientScore > iBestScore)
			{
				iBestScore = iClientScore;
				iBestClientIndex = iClient;
			}
		}
	}
	
	// Returns index of client who tried to spawn, or -1 if it finds nobody suitable
	return iBestClientIndex;
}

void GrayMann_SpawnMinion(int iClient, TFClassType nClass = TFClass_Unknown)
{
	SaxtonHaleBase boss = SaxtonHaleBase(iClient);
	if (boss.bValid)
		boss.DestroyAllClass();
	
	g_bGrayMannPlayerWasSummoned[iClient] = true;
	
	// If there's a class specified, choose the boss made for that class
	switch (nClass)
	{
		case TFClass_Soldier: boss.CreateClass("GrayMannSoldierMinion");
		case TFClass_Pyro: boss.CreateClass("GrayMannPyroMinion");
		case TFClass_DemoMan: boss.CreateClass("GrayMannDemomanMinion");
		default:
		{
			// ...and if not, choose at random
			switch (GetURandomInt() % 3)
			{
				case 0: boss.CreateClass("GrayMannSoldierMinion");
				case 1: boss.CreateClass("GrayMannPyroMinion");
				case 2: boss.CreateClass("GrayMannDemomanMinion");
			}
		}
	}
	
	TF2_ForceTeamJoin(iClient, TFTeam_Boss);
	
	//Duration of this condition will reset when they move
	TF2_AddCondition(iClient, TFCond_UberchargedCanteen, 7.0);
}

Action Timer_GrayMann_ReplaceMinion(Handle hTimer, int iClient)
{
	if (hTimer != g_hGrayMannMinionAFKTimer[iClient])
		return Plugin_Continue;
	
	if (TF2_GetClientTeam(iClient) <= TFTeam_Spectator || !IsPlayerAlive(iClient) || g_bGrayMannMinionHasMoved[iClient])
		return Plugin_Continue;
	
	//Adjust the countdown on screen
	if (g_iGrayMannMinionAFKTimeLeft[iClient] > 0)
	{
		g_iGrayMannMinionAFKTimeLeft[iClient]--;
		SaxtonHaleBase(iClient).CallFunction("UpdateHudInfo", 0.0, 0.0);	//Update once
		g_hGrayMannMinionAFKTimer[iClient] = CreateTimer(1.0, Timer_GrayMann_ReplaceMinion, iClient);
		return Plugin_Continue;
	}
	
	//Snap the AFK player. Note that there's no point in killing them if they're the only acceptable client available
	ArrayList aValidMinions = GetValidSummonableClients();
	int iLength = aValidMinions.Length;
	
	for (int i = 0; i < iLength; i++)
	{
		int iCandidate = aValidMinions.Get(i);
		if (!g_bGrayMannPlayerWasSummoned[iCandidate])
		{
			ForcePlayerSuicide(iClient);
			break;
		}
	}	
	
	delete aValidMinions;
	
	//Set them as moving again, in case the AFK player wasn't killed
	g_bGrayMannMinionHasMoved[iClient] = true;
	return Plugin_Continue;
}

Action GrayMann_Timer_TryToSpawnQueuedMinion(Handle hTimer, int iUserID)
{
	int iClient = GetClientOfUserId(iUserID);
	if (iClient == 0)
		return Plugin_Stop;
	
	if (hTimer != g_hGrayMannSpawnQueuedMinionTimer[iClient])
		return Plugin_Stop;
	
	if (!IsPlayerAlive(iClient) || !SaxtonHale_IsValidBoss(iClient))
		return Plugin_Stop;
	
	SaxtonHaleBase boss = SaxtonHaleBase(iClient);
	
	// Try to find a player to spawn in
	ArrayList aValidMinions = GetValidSummonableClients();
	int iCandidate = GrayMann_SelectBestPlayer(aValidMinions);
	delete aValidMinions;
	
	// No player found? Stop here and try again in a couple of seconds
	if (iCandidate <= 0)
	{
		g_iGrayMannQueueReason[iClient] = GRAYMANN_QUEUE_NO_CANDIDATES;
		boss.CallFunction("UpdateHudInfo", 0.0, 0.0);	// Update once
		
		return Plugin_Continue;
	}
	
	// Check if there's enough space for the boss to spawn a giant
	float vecPos[3], vecMaxs[3], vecMins[3], vecNewPos[3];
	int iTries;
	GetClientAbsOrigin(iClient, vecPos);
	
	// We don't want to get the client's bounding box, what if they're not at default scale? Use the known defaults instead
	vecMins = { -24.0, -24.0, 0.0 };
	vecMaxs = { 24.0, 24.0, 82.0 };
	
	ScaleVector(vecMins, GRAYMANN_GIANT_ROBOT_SCALE);
	ScaleVector(vecMaxs, GRAYMANN_GIANT_ROBOT_SCALE);
	
	TR_TraceHullFilter(vecPos, vecPos, vecMins, vecMaxs, MASK_PLAYERSOLID, TraceRay_HitEnemyPlayersAndObjects, iClient);
	
	// We hit something, there's no space...
	if (TR_DidHit())
	{
		// Let's try again slightly higher up, in case we're on top of a displacement in a perfectly open area
		iTries++;
		vecNewPos[0] = vecPos[0];
		vecNewPos[1] = vecPos[1];
		vecNewPos[2] = vecPos[2] + 15.0;
		
		TR_TraceHullFilter(vecNewPos, vecNewPos, vecMins, vecMaxs, MASK_PLAYERSOLID, TraceRay_HitEnemyPlayersAndObjects, iClient);
		if (TR_DidHit())
		{
			// If we hit something, then there's no hope, try again later
			g_iGrayMannQueueReason[iClient] = GRAYMANN_QUEUE_NO_SPACE;
			boss.CallFunction("UpdateHudInfo", 0.0, 0.0);	// Update once
			return Plugin_Continue;
		}
	}
		
	// From now on, we've confirmed we can spawn someone
	GrayMann_SpawnMinion(iCandidate);
	TF2_TeleportToClient(iCandidate, iClient);
	
	// Teleport them again. It's necessary to teleport them twice because TF2_TeleportToClient does a few extra things
	if (iTries > 0)
		TeleportEntity(iCandidate, vecNewPos, NULL_VECTOR, NULL_VECTOR);
	
	// Create a lil effect
	CreateTimer(2.0, Timer_EntityCleanup, TF2_SpawnParticle(TF2_GetClientTeam(iClient) == TFTeam_Blue ? "teleportedin_blue" : "teleportedin_red", vecPos));
	EmitSoundToAll(GRAYMANN_RAGE, iClient);
	
	g_iGrayMannQueuedMinions[iClient]--;
	
	g_iGrayMannQueueReason[iClient] = GRAYMANN_QUEUE_CAN_SPAWN;
	boss.CallFunction("UpdateHudInfo", 0.0, 0.0);	// Update once
	
	if (g_iGrayMannQueuedMinions[iClient] == 0)
		return Plugin_Stop;
	
	return Plugin_Continue;
}

void GrayMann_CreateRobotGibs(int iClient)
{
	char sModel[PLATFORM_MAX_PATH];
	
	// Always spawn heads first
	TFClassType nClass = TF2_GetPlayerClass(iClient);
	switch (nClass)
	{
		case TFClass_Soldier: strcopy(sModel, sizeof(sModel), g_strGrayMannSoldierGibs[0]);
		case TFClass_Pyro: strcopy(sModel, sizeof(sModel), g_strGrayMannPyroGibs[0]);
		case TFClass_DemoMan: strcopy(sModel, sizeof(sModel), g_strGrayMannDemomanGibs[0]);
		default: return;
	}
	
	int iSkin = GetClientTeam(iClient) - 2;
	
	float vecPos[3], vecAng[3], vecVel[3];
	
	GetClientAbsOrigin(iClient, vecPos);
	GetClientEyeAngles(iClient, vecAng);
	
	// Shoot heads more straight up than other gibs
	vecVel[0] = GetRandomFloat(-25.0, 25.0);
	vecVel[1] = GetRandomFloat(-25.0, 25.0);
	vecVel[2] = GetRandomFloat(300.0, 400.0);
	
	if (sModel[0])
		GrayMann_InitRobotGib(sModel, vecPos, vecAng, vecVel, iSkin, true);
	
	// Spawn other random gibs
	for (int i = 1; i < GRAYMANN_MAX_GIANT_GIBS; i++)
	{
		switch (nClass)
		{
			case TFClass_Soldier: strcopy(sModel, sizeof(sModel), g_strGrayMannSoldierGibs[GetRandomInt(1, sizeof(g_strGrayMannSoldierGibs) - 1)]);
			case TFClass_Pyro: strcopy(sModel, sizeof(sModel), g_strGrayMannPyroGibs[GetRandomInt(1, sizeof(g_strGrayMannPyroGibs) - 1)]);
			case TFClass_DemoMan: strcopy(sModel, sizeof(sModel), g_strGrayMannDemomanGibs[GetRandomInt(1, sizeof(g_strGrayMannDemomanGibs) - 1)]);
		}
		
		vecVel[0] = GetRandomFloat(-100.0, 100.0);
		vecVel[1] = GetRandomFloat(-100.0, 100.0);
		vecVel[2] = GetRandomFloat(200.0, 350.0);
		
		if (sModel[0])
			GrayMann_InitRobotGib(sModel, vecPos, vecAng, vecVel, iSkin, false);
	}
}

void GrayMann_InitRobotGib(const char[] sModel, float vecPos[3], float vecAng[3], float vecVel[3], int iSkin, bool bHead)
{
	int iEntity = CreateEntityByName("prop_physics_multiplayer");
	if (iEntity <= MaxClients)
		return;
	
	DispatchKeyValue(iEntity, "model", sModel);
	DispatchKeyValue(iEntity, "physicsmode", "2");
	
	TeleportEntity(iEntity, vecPos, vecAng, vecVel);

	DispatchSpawn(iEntity);

	SetEntityCollisionGroup(iEntity, COLLISION_GROUP_DEBRIS);
	SetEntProp(iEntity, Prop_Send, "m_usSolidFlags", 0);
	SetEntProp(iEntity, Prop_Send, "m_nSolidType", 2);
	SetEntProp(iEntity, Prop_Send, "m_nSkin", iSkin);

	int iEffects = (EF_NOSHADOW | EF_NORECEIVESHADOW);
	if (bHead)
		iEffects |= EF_ITEM_BLINK;
	
	SetEntProp(iEntity, Prop_Send, "m_fEffects", iEffects);

	CreateTimer(10.0, Timer_EntityCleanup, EntIndexToEntRef(iEntity), TIMER_FLAG_NO_MAPCHANGE);
}