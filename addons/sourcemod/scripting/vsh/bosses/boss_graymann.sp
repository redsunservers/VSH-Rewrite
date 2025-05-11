#define GRAYMANN_THEME 				"ui/gamestartup16.mp3"
#define GRAYMAN_RAGE 				"mvm/mvm_tele_deliver.wav"
#define GRAYMANN_MODEL 				"models/player/vsh_rewrite/graymann/graymann.mdl"
#define GRAYMANN_SOLDIERMINION 		"models/bots/soldier_boss/bot_soldier_boss.mdl"
#define GRAYMANN_DEMOMINION 		"models/bots/demo_boss/bot_demo_boss.mdl"
#define GRAYMANN_PYROMINION			"models/bots/pyro_boss/bot_pyro_boss.mdl"

static int g_iGrayMannMinionAFKTimeLeft[MAXPLAYERS];
static Handle g_hGrayMannMinionAFKTimer[MAXPLAYERS];
static bool g_bGrayMannPlayerWasSummoned[MAXPLAYERS];
static bool g_bGrayMannMinionHasMoved[MAXPLAYERS];

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

static char g_strGrayMannKillScout[][] = {
	"vsh_rewrite/graymann/laugh1.mp3",
	"vsh_rewrite/graymann/laugh2.mp3",
	"vsh_rewrite/graymann/laugh3.mp3"
};

static char g_strGrayMannKillSniper[][] = {
	"vsh_rewrite/graymann/laugh1.mp3",
	"vsh_rewrite/graymann/laugh2.mp3",
	"vsh_rewrite/graymann/laugh3.mp3"
};

static char g_strGrayMannKillDemoMan[][] = {
	"vsh_rewrite/graymann/laugh1.mp3",
	"vsh_rewrite/graymann/laugh2.mp3",
	"vsh_rewrite/graymann/laugh3.mp3"
};

static char g_strGrayMannKillMedic[][] = {
	"vsh_rewrite/graymann/laugh1.mp3",
	"vsh_rewrite/graymann/laugh2.mp3",
	"vsh_rewrite/graymann/laugh3.mp3"
};

static char g_strGrayMannKillSpy[][] = {
	"vsh_rewrite/graymann/laugh1.mp3",
	"vsh_rewrite/graymann/laugh2.mp3",
	"vsh_rewrite/graymann/laugh3.mp3"
};

static char g_strGrayMannKillEngie[][] = {
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

static char g_strSoldierFootsteps[][] = {
	"mvm/giant_soldier/giant_soldier_step01.wav",
	"mvm/giant_soldier/giant_soldier_step02.wav",
	"mvm/giant_soldier/giant_soldier_step03.wav",
	"mvm/giant_soldier/giant_soldier_step04.wav"
};

static char g_strDemomanFootsteps[][] = {
	"mvm/giant_demoman/giant_demoman_step_01.wav",
	"mvm/giant_demoman/giant_demoman_step_02.wav",
	"mvm/giant_demoman/giant_demoman_step_03.wav",
	"mvm/giant_demoman/giant_demoman_step_04.wav"
};

static char g_strPyroFootsteps[][] = {
	"mvm/giant_pyro/giant_pyro_step_01.wav",
	"mvm/giant_pyro/giant_pyro_step_02.wav",
	"mvm/giant_pyro/giant_pyro_step_03.wav",
	"mvm/giant_pyro/giant_pyro_step_04.wav"
};

static char g_strSoldierLoop[][] = {
	"mvm/giant_soldier/giant_soldier_loop.wav"
}

static char g_strDemomanLoop[][] = {
	"mvm/giant_demoman/giant_demoman_loop.wav"
}

static char g_strPyroLoop[][] = {
	"mvm/giant_pyro/giant_pyro_loop.wav"
}

//There's probably a better way to write this code but I'm dogshit at coding, what you see is what you get

public void GrayMann_Create(SaxtonHaleBase boss)
{	
	boss.CreateClass("RageAddCond");
	boss.SetPropFloat("RageAddCond", "RageCondDuration", 8.0);
	RageAddCond_AddCond(boss, TFCond_DefenseBuffed);
	RageAddCond_AddCond(boss, TFCond_SpeedBuffAlly);
	
	boss.flSpeed = 350.0;
	boss.iHealthPerPlayer = 400;
	boss.flHealthExponential = 1.05;
	boss.nClass = TFClass_Engineer;
	boss.iMaxRageDamage = 3000;
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
	StrCat(sInfo, length, "\n- Killing people turns them into gold, and you siphon their power to heal yourself for 100 HP flat");
	StrCat(sInfo, length, "\n ");
	StrCat(sInfo, length, "\nRage");
	StrCat(sInfo, length, "\n- Damage requirement: 3000");
	StrCat(sInfo, length, "\n- Spawn a random giant robot");
	StrCat(sInfo, length, "\n- 200%% Rage: Spawn 2 random giant robots");
}

public void GrayMann_OnRage(SaxtonHaleBase boss)
{
	int iTotalSummons = 1;
	if (boss.bSuperRage) iTotalSummons = 2;
	
	//Create a lil effect
	float vecBossPos[3];
	GetClientAbsOrigin(boss.iClient, vecBossPos);
	CreateTimer(3.0, Timer_EntityCleanup, TF2_SpawnParticle(TF2_GetClientTeam(boss.iClient) == TFTeam_Blue ? "teleportedin_blue" : "teleportedin_red", vecBossPos));
	EmitSoundToAll(GRAYMAN_RAGE, boss.iClient);
	
	ArrayList aValidMinions = GetValidSummonableClients();
	
	int iLength = aValidMinions.Length;
	if (iLength < iTotalSummons)
		iTotalSummons = iLength;
	else
		iLength = iTotalSummons;
		
	//Give priority to players who have the highest scores
	for (int iSelection = 0; iSelection < iLength; iSelection++)
	{	
		//Spawn and teleport the minion to the boss
		int iClient = GrayMann_SpawnBestPlayer(aValidMinions);
		
		if (iClient > 0)		
			TF2_TeleportToClient(iClient, boss.iClient);
	}
		
	delete aValidMinions;
}

public void GrayMann_OnSpawn(SaxtonHaleBase boss)
{
	int iWeapon;
	char attribs[128];
	Format(attribs, sizeof(attribs), "2 ; 2.80 ; 252 ; 0.5 ; 259 ; 1.0 ; 150 ; 1.0 ; 180 ; 100");
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
	switch (nClass)
	{
		case TFClass_Scout: strcopy(sSound, length, g_strGrayMannKillScout[GetRandomInt(0,sizeof(g_strGrayMannKillScout)-1)]);
		case TFClass_DemoMan: strcopy(sSound, length, g_strGrayMannKillDemoMan[GetRandomInt(0,sizeof(g_strGrayMannKillDemoMan)-1)]);
		case TFClass_Engineer: strcopy(sSound, length, g_strGrayMannKillEngie[GetRandomInt(0,sizeof(g_strGrayMannKillEngie)-1)]);
		case TFClass_Medic: strcopy(sSound, length, g_strGrayMannKillMedic[GetRandomInt(0,sizeof(g_strGrayMannKillMedic)-1)]);
		case TFClass_Sniper: strcopy(sSound, length, g_strGrayMannKillSniper[GetRandomInt(0,sizeof(g_strGrayMannKillSniper)-1)]);
		case TFClass_Spy: strcopy(sSound, length, g_strGrayMannKillSpy[GetRandomInt(0,sizeof(g_strGrayMannKillSpy)-1)]);
	}
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

public void GrayMann_Precache(SaxtonHaleBase boss) //not sure if custom sounds have to be in the downloadstable but I added them anyway
{
	PrecacheModel(GRAYMANN_MODEL);
	PrepareMusic(GRAYMANN_THEME, false);
	PrecacheSound(GRAYMAN_RAGE);
	for (int i = 0; i < sizeof(g_strGrayMannRoundStart); i++) PrepareSound(g_strGrayMannRoundStart[i]);
	for (int i = 0; i < sizeof(g_strGrayMannWin); i++) PrepareSound(g_strGrayMannWin[i]);
	for (int i = 0; i < sizeof(g_strGrayMannLose); i++) PrepareSound(g_strGrayMannLose[i]);
	for (int i = 0; i < sizeof(g_strGrayMannRage); i++) PrepareSound(g_strGrayMannRage[i]);
	for (int i = 0; i < sizeof(g_strGrayMannKillScout); i++) PrepareSound(g_strGrayMannKillScout[i]);
	for (int i = 0; i < sizeof(g_strGrayMannKillSniper); i++) PrepareSound(g_strGrayMannKillSniper[i]);
	for (int i = 0; i < sizeof(g_strGrayMannKillDemoMan); i++) PrepareSound(g_strGrayMannKillDemoMan[i]);
	for (int i = 0; i < sizeof(g_strGrayMannKillMedic); i++) PrepareSound(g_strGrayMannKillMedic[i]);
	for (int i = 0; i < sizeof(g_strGrayMannKillSpy); i++) PrepareSound(g_strGrayMannKillSpy[i]);
	for (int i = 0; i < sizeof(g_strGrayMannKillEngie); i++) PrepareSound(g_strGrayMannKillEngie[i]);
	for (int i = 0; i < sizeof(g_strGrayMannLastMan); i++) PrepareSound(g_strGrayMannLastMan[i]);
	for (int i = 0; i < sizeof(g_strGrayMannBackStabbed); i++) PrepareSound(g_strGrayMannBackStabbed[i]);
	for (int i = 0; i < sizeof(g_strSoldierLoop); i++) PrepareSound(g_strSoldierLoop[i]);
	for (int i = 0; i < sizeof(g_strDemomanLoop); i++) PrepareSound(g_strDemomanLoop[i]);
	for (int i = 0; i < sizeof(g_strPyroLoop); i++) PrepareSound(g_strPyroLoop[i]);
	for (int i = 0; i < sizeof(g_strSoldierFootsteps); i++) PrepareSound(g_strSoldierFootsteps[i]);
	for (int i = 0; i < sizeof(g_strDemomanFootsteps); i++) PrepareSound(g_strDemomanFootsteps[i]);
	for (int i = 0; i < sizeof(g_strPyroFootsteps); i++) PrepareSound(g_strPyroFootsteps[i]);

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

public void GrayMannSoldierMinion_Create(SaxtonHaleBase boss) //Giant Soldier Stats
{
	boss.iBaseHealth = 2500;
	boss.iHealthPerPlayer = 25;
	boss.flSpeed = 150.0;
	boss.nClass = TFClass_Soldier;
	boss.iMaxRageDamage = -1;
	boss.bMinion = true;
	boss.bHealthPerPlayerAlive = true;
	g_bGrayMannMinionHasMoved[boss.iClient] = false;		//Will check if the player has moved to determine if they're AFK or not
	g_iGrayMannMinionAFKTimeLeft[boss.iClient] = 6;		//The player has 6 seconds to move after being summoned, else they'll be taken as AFK and replaced by someone else
	
	EmitSoundToClient(boss.iClient, SOUND_ALERT);			//Alert player as they (re)spawned
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
	g_bGrayMannMinionHasMoved[boss.iClient] = false;
	g_iGrayMannMinionAFKTimeLeft[boss.iClient] = 6;	
	
	EmitSoundToClient(boss.iClient, SOUND_ALERT);
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
	g_bGrayMannMinionHasMoved[boss.iClient] = false;	
	g_iGrayMannMinionAFKTimeLeft[boss.iClient] = 6;	
	
	EmitSoundToClient(boss.iClient, SOUND_ALERT);
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
	char sAttribs[64];
	strcopy(sAttribs, sizeof(sAttribs), "1 ; 0.5 ; 4 ; 2.0 ; 5 ; 2.0 ; 97 ; 0.5 ; 252 ; 0.5 ; 259 ; 1.0");
	int iWeapon = boss.CallFunction("CreateWeapon", 205, "tf_weapon_rocketlauncher", 10, TFQual_Collectors, sAttribs);
	TF2_SetAmmo(boss.iClient, TF_AMMO_PRIMARY, 99999);
	if (iWeapon > MaxClients)
		SetEntPropEnt(boss.iClient, Prop_Send, "m_hActiveWeapon", iWeapon);
	
	/*
	Rocket Launcher attributes:
	
	1: damage penalty
	4: clip size bonus
	5: slower firing speed
	97: reload time decreased
	252: reduction in push force taken from damage
	259: Deals 3x falling damage to the player you land on
	*/

	//EmitSoundToAll(g_strSoldierLoop[GetRandomInt(0, sizeof(g_strSoldierLoop)-1)], boss.iClient, _, 140, _, 1.0, GetRandomInt(95, 100));
	SetEntPropFloat(boss.iClient, Prop_Send, "m_flModelScale", 1.50);
	
	//We have to check if the color of the boss hasn't already been altered (usually by a modifier) before applying his default color
	int iColor[4] = {255, 255, 255, 255};
	boss.CallFunction("GetRenderColor", iColor);
	
	//Add a colored outline so he's more easily recognizable as not the boss during spawn uber
	//Round started check is there so it doesn't show up when spawning on the next round as well
	if (GameRules_GetRoundState() != RoundState_Preround)
		CreateTimer(3.0, Timer_EntityCleanup, TF2_CreateGlow(boss.iClient, iColor));
	
	g_hGrayMannMinionAFKTimer[boss.iClient] = CreateTimer(0.0, Timer_GrayMann_ReplaceMinion, boss.iClient);
}

public void GrayMannDemomanMinion_OnSpawn(SaxtonHaleBase boss) //Demo's Attributes
{
	char sAttribs[64];
	strcopy(sAttribs, sizeof(sAttribs), "1 ; 0.5 ; 4 ; 2.0 ; 5 ; 2.0 ; 97 ; 3.0 ; 252 ; 0.5 ; 259 ; 1.0");
	int iWeapon = boss.CallFunction("CreateWeapon", 206, "tf_weapon_grenadelauncher", 10, TFQual_Collectors, sAttribs);
	TF2_SetAmmo(boss.iClient, TF_AMMO_PRIMARY, 99999);
	if (iWeapon > MaxClients)
		SetEntPropEnt(boss.iClient, Prop_Send, "m_hActiveWeapon", iWeapon);
	
	/*
	Grenade Launcher attributes:
	
	1: damage penalty
	4: clip size bonus
	5: slower firing speed
	97: reload time decreased
	252: reduction in push force taken from damage
	259: Deals 3x falling damage to the player you land on
	*/

	//EmitSoundToAll(g_strDemomanLoop[GetRandomInt(0, sizeof(g_strDemomanLoop)-1)], boss.iClient, _, 140, _, 1.0, GetRandomInt(95, 100));
	SetEntPropFloat(boss.iClient, Prop_Send, "m_flModelScale", 1.50);
	
	int iColor[4] = {255, 255, 255, 255};
	boss.CallFunction("GetRenderColor", iColor);
	
	if (GameRules_GetRoundState() != RoundState_Preround)
		CreateTimer(3.0, Timer_EntityCleanup, TF2_CreateGlow(boss.iClient, iColor));
	
	g_hGrayMannMinionAFKTimer[boss.iClient] = CreateTimer(0.0, Timer_GrayMann_ReplaceMinion, boss.iClient);
}

public void GrayMannPyroMinion_OnSpawn(SaxtonHaleBase boss) //Pyro's Attributes. Don't touch it. Don't even blink. Don't do fucking ANYTHING.
{
	char sAttribs[64];
	strcopy(sAttribs, sizeof(sAttribs), "823 ; 1 ; 844 ; 1850.0 ; 841 ; 0 ; 843 ; 10 ; 862 ; 0.50 ; 1 ; 0.5 ; 4 ; 2.0 ; 356 ; 1.0 ; 252 ; 0.5 ; 259 ; 1.0");
	int iWeapon = boss.CallFunction("CreateWeapon", 208, "tf_weapon_flamethrower", 100, TFQual_Collectors, sAttribs);
	TF2_SetAmmo(boss.iClient, TF_AMMO_PRIMARY, 99999);
	if (iWeapon > MaxClients)
		SetEntPropEnt(boss.iClient, Prop_Send, "m_hActiveWeapon", iWeapon);
	
	/*
	Flammenwerfer attributes:
	// DO NOT USE FLAME_SPEED UNDER ANY CIRCUMSTANCES, FOR SOME REASON IT COMPLETELY FUCKS WITH AIRBLAST DISABLED, FUCK YOU!!!!
	// https://www.youtube.com/watch?v=_4qEz5ONk5c&ab_channel=1995Berserk this is me after working with pyro attributes btw

	823: airblast_pushback_disabled
	844: flame speed UNFORTUFUCKINGNATELY
	841: flame gravity
	843: flame drag
	862: flame lifetime
	1: damage penalty
	4: clip size bonus
	164: flame life bonus
	162: flame size
	356: airblast disabled (doesn't work because flame speed is used, see 823 attribute)
	252: reduction in push force taken from damage
	259: Deals 3x falling damage to the player you land on
	*/

	//EmitSoundToAll(g_strPyroLoop[GetRandomInt(0, sizeof(g_strPyroLoop)-1)], boss.iClient, _, 140, _, 1.0, GetRandomInt(95, 100));
	SetEntPropFloat(boss.iClient, Prop_Send, "m_flModelScale", 1.50);
	
	//We have to check if the color of the boss hasn't already been altered (usually by a modifier) before applying his default color
	int iColor[4] = {255, 255, 255, 255};
	boss.CallFunction("GetRenderColor", iColor);
	

	if (GameRules_GetRoundState() != RoundState_Preround)
		CreateTimer(3.0, Timer_EntityCleanup, TF2_CreateGlow(boss.iClient, iColor));
	
	g_hGrayMannMinionAFKTimer[boss.iClient] = CreateTimer(0.0, Timer_GrayMann_ReplaceMinion, boss.iClient);
}

public void GrayMannSoldierMinion_OnButtonPress(SaxtonHaleBase boss, int button)
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

public void GrayMannDemomanMinion_OnButtonPress(SaxtonHaleBase boss, int button)
{
	if (!g_bGrayMannMinionHasMoved[boss.iClient])
	{	
		TF2_RemoveCondition(boss.iClient, TFCond_UberchargedCanteen);
		TF2_AddCondition(boss.iClient, TFCond_UberchargedCanteen, 3.0);
			
		g_bGrayMannMinionHasMoved[boss.iClient] = true;
	}
}

public void GrayMannPyroMinion_OnButtonPress(SaxtonHaleBase boss, int button)
{
	if (!g_bGrayMannMinionHasMoved[boss.iClient])
	{	
		TF2_RemoveCondition(boss.iClient, TFCond_UberchargedCanteen);
		TF2_AddCondition(boss.iClient, TFCond_UberchargedCanteen, 3.0);
			
		g_bGrayMannMinionHasMoved[boss.iClient] = true;
	}
}

public void GrayMann_GetModel(SaxtonHaleBase boss, char[] sModel, int length) //Models are grabbed here, duh
{
	strcopy(sModel, length, GRAYMANN_MODEL);
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

// Added footsteps for giants here and blocked their voicelines at the same time

public Action GrayMannSoldierMinion_OnSoundPlayed(SaxtonHaleBase boss, int clients[MAXPLAYERS], int &numClients, char sample[PLATFORM_MAX_PATH], int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
	if (strncmp(sample, "vo/", 3) == 0)//Block voicelines
		return Plugin_Handled;

	if(StrContains(sample, "player/footsteps/", false) != -1)
	{
		EmitSoundToAll(g_strSoldierFootsteps[GetRandomInt(0, sizeof(g_strSoldierFootsteps)-1)], boss.iClient, _, _, _, 1.0, GetRandomInt(95, 100));
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action GrayMannDemomanMinion_OnSoundPlayed(SaxtonHaleBase boss, int clients[MAXPLAYERS], int &numClients, char sample[PLATFORM_MAX_PATH], int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
	if (strncmp(sample, "vo/", 3) == 0)
		return Plugin_Handled;
	if(StrContains(sample, "player/footsteps/", false) != -1)
	{
		EmitSoundToAll(g_strDemomanFootsteps[GetRandomInt(0, sizeof(g_strDemomanFootsteps)-1)], boss.iClient, _, _, _, 1.0, GetRandomInt(95, 100));
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action GrayMannPyroMinion_OnSoundPlayed(SaxtonHaleBase boss, int clients[MAXPLAYERS], int &numClients, char sample[PLATFORM_MAX_PATH], int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
	if (strncmp(sample, "vo/", 3) == 0)
		return Plugin_Handled;
	if(StrContains(sample, "player/footsteps/", false) != -1)
	{
		EmitSoundToAll(g_strPyroFootsteps[GetRandomInt(0, sizeof(g_strPyroFootsteps)-1)], boss.iClient, _, _, _, 1.0, GetRandomInt(95, 100));
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public void GrayMannSoldierMinion_OnDeath(SaxtonHaleBase boss)
{
	StopSound(boss.iClient, 2, g_strSoldierLoop[GetRandomInt(0, sizeof(g_strSoldierLoop)-1)])
	//This is called on death in case people suicide after getting summoned instead of disabling respawn
	if (!g_bGrayMannMinionHasMoved[boss.iClient])
	{
		ArrayList aValidMinions = GetValidSummonableClients();
		
		//Spawn and teleport the replacement to where this AFK minion is, if valid
		int iBestClient = GrayMann_SpawnBestPlayer(aValidMinions);
		if (iBestClient > 0)
			TF2_TeleportToClient(iBestClient, boss.iClient);
			
		delete aValidMinions;
	}
}

public void GrayMannDemomanMinion_OnDeath(SaxtonHaleBase boss)
{
	StopSound(boss.iClient, 2, g_strDemomanLoop[GetRandomInt(0, sizeof(g_strDemomanLoop)-1)])
	if (!g_bGrayMannMinionHasMoved[boss.iClient])
	{
		ArrayList aValidMinions = GetValidSummonableClients();
		
		int iBestClient = GrayMann_SpawnBestPlayer(aValidMinions);
		if (iBestClient > 0)
			TF2_TeleportToClient(iBestClient, boss.iClient);
			
		delete aValidMinions;
	}
}

public void GrayMannPyroMinion_OnDeath(SaxtonHaleBase boss)
{
	StopSound(boss.iClient, 2, g_strPyroLoop[GetRandomInt(0, sizeof(g_strPyroLoop)-1)])
	if (!g_bGrayMannMinionHasMoved[boss.iClient])
	{
		ArrayList aValidMinions = GetValidSummonableClients();
		
		int iBestClient = GrayMann_SpawnBestPlayer(aValidMinions);
		if (iBestClient > 0)
			TF2_TeleportToClient(iBestClient, boss.iClient);
			
		delete aValidMinions;
	}
}

public void GrayMannSoldierMinion_Destroy(SaxtonHaleBase boss)
{
	SetEntityRenderColor(boss.iClient, 255, 255, 255, 255);
	g_hGrayMannMinionAFKTimer[boss.iClient] = null;
}

public void GrayMannDemomanMinion_Destroy(SaxtonHaleBase boss)
{
	SetEntityRenderColor(boss.iClient, 255, 255, 255, 255);
	g_hGrayMannMinionAFKTimer[boss.iClient] = null;
}

public void GrayMannPyroMinion_Destroy(SaxtonHaleBase boss)
{
	SetEntityRenderColor(boss.iClient, 255, 255, 255, 255);
	g_hGrayMannMinionAFKTimer[boss.iClient] = null;
}

public int GrayMann_SpawnBestPlayer(ArrayList aClients)
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

	if (iBestClientIndex > 0)
	{
		SaxtonHaleBase boss = SaxtonHaleBase(iBestClientIndex);
		if (boss.bValid)
			boss.DestroyAllClass();
		switch(GetRandomInt(0,2)) //Picks one of these Minions at random
		{
			case 0:
			{
				boss.CreateClass("GrayMannSoldierMinion");
			}
			case 1:
			{
				boss.CreateClass("GrayMannDemomanMinion");
			}
			case 2:
			{
				boss.CreateClass("GrayMannPyroMinion");
			}
		}
		TF2_ForceTeamJoin(iBestClientIndex, TFTeam_Boss);
		
		//Duration of this condition will reset when they move
		TF2_AddCondition(iBestClientIndex, TFCond_UberchargedCanteen, 7.0);
	}
	
	//Returns index of client who tried to spawn, or -1 if it finds nobody suitable
	return iBestClientIndex;
}

public Action Timer_GrayMann_ReplaceMinion(Handle hTimer, int iClient)
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
	//Some unused StopSounds here, the bots were meant to make a looping sound whilst alive akin to MvM, but it caused issues after the round would end and the sound wouldn't stop for some reason
	ArrayList aValidMinions = GetValidSummonableClients();
	int iLength = aValidMinions.Length;
	
	for (int i = 0; i < iLength; i++)
	{
		int iCandidate = aValidMinions.Get(i);
		if (!g_bGrayMannPlayerWasSummoned[iCandidate])
		{
			StopSound(iClient, SNDCHAN_STATIC, g_strSoldierLoop[GetRandomInt(0, sizeof(g_strSoldierLoop)-1)])
			StopSound(iClient, SNDCHAN_STATIC, g_strDemomanLoop[GetRandomInt(0, sizeof(g_strDemomanLoop)-1)])
			StopSound(iClient, SNDCHAN_STATIC, g_strPyroLoop[GetRandomInt(0, sizeof(g_strPyroLoop)-1)])
			ForcePlayerSuicide(iClient);
			break;
		}
	}

	delete aValidMinions;
	
	//Set them as moving again, in case the AFK player wasn't killed
	g_bGrayMannMinionHasMoved[iClient] = true;
	return Plugin_Continue;
}