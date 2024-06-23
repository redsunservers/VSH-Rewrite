#define HALE_MODEL "models/player/saxton_hale_jungle_inferno/saxton_hale_3.mdl"

static bool g_bHaleSpeedRage[MAXPLAYERS];

static char g_strHaleRoundStart[][] = {
	"vsh_rewrite/saxton_hale/saxton_hale_responce_start1.mp3",
	"vsh_rewrite/saxton_hale/saxton_hale_responce_start2.mp3",
	"vsh_rewrite/saxton_hale/saxton_hale_responce_start3.mp3",
	"vsh_rewrite/saxton_hale/saxton_hale_responce_start4.mp3",
	"vsh_rewrite/saxton_hale/saxton_hale_responce_start5.mp3",
	"vsh_rewrite/saxton_hale/saxton_hale_132_start_1.mp3",
	"vsh_rewrite/saxton_hale/saxton_hale_132_start_2.mp3",
	"vsh_rewrite/saxton_hale/saxton_hale_132_start_3.mp3",
	"vsh_rewrite/saxton_hale/saxton_hale_132_start_4.mp3",
	"vsh_rewrite/saxton_hale/saxton_hale_132_start_5.mp3"
};

static char g_strHaleWin[][] = {
	"vsh_rewrite/saxton_hale/saxton_hale_responce_win1.mp3",
	"vsh_rewrite/saxton_hale/saxton_hale_responce_win2.mp3"
};

static char g_strHaleLose[][] = {
	"vsh_rewrite/saxton_hale/saxton_hale_responce_fail1.mp3",
	"vsh_rewrite/saxton_hale/saxton_hale_responce_fail2.mp3",
	"vsh_rewrite/saxton_hale/saxton_hale_responce_fail3.mp3"
};

static char g_strHaleRage[][] = {
	"vsh_rewrite/saxton_hale/saxton_hale_responce_rage1.mp3",
	"vsh_rewrite/saxton_hale/saxton_hale_responce_rage3.mp3",
	"vsh_rewrite/saxton_hale/saxton_hale_responce_rage4.mp3"
};

static char g_strHaleLunge[][] = {
	"vsh_rewrite/saxton_hale/saxton_hale_responce_rage2.mp3",
};

static char g_strHaleJump[][] = {
	"vsh_rewrite/saxton_hale/saxton_hale_responce_jump1.mp3",
	"vsh_rewrite/saxton_hale/saxton_hale_responce_jump2.mp3",
	"vsh_rewrite/saxton_hale/saxton_hale_132_jump_1.mp3",
	"vsh_rewrite/saxton_hale/saxton_hale_132_jump_2.mp3"
};

static char g_strHaleKill[][] = {
	"vsh_rewrite/saxton_hale/saxton_hale_responce_spree1.mp3",
	"vsh_rewrite/saxton_hale/saxton_hale_responce_spree2.mp3",
	"vsh_rewrite/saxton_hale/saxton_hale_responce_spree3.mp3",
	"vsh_rewrite/saxton_hale/saxton_hale_responce_spree4.mp3",
	"vsh_rewrite/saxton_hale/saxton_hale_responce_spree5.mp3",
	"vsh_rewrite/saxton_hale/saxton_hale_132_kspree_1.mp3",
	"vsh_rewrite/saxton_hale/saxton_hale_132_kspree_2.mp3"
};

static char g_strHaleKillScout[][] = {
	"vsh_rewrite/saxton_hale/saxton_hale_132_kill_scout.mp3"
};
/*	//No soldier voicelines
static char g_strHaleKillSoldier[][] = {
	
};
*/
static char g_strHaleKillPyro[][] = {
	"vsh_rewrite/saxton_hale/saxton_hale_132_kill_w_and_m1.mp3"
};

static char g_strHaleKillDemoman[][] = {
	"vsh_rewrite/saxton_hale/saxton_hale_132_kill_demo.mp3"
};

static char g_strHaleKillHeavy[][] = {
	"vsh_rewrite/saxton_hale/saxton_hale_132_kill_heavy.mp3"
};

static char g_strHaleKillEngineer[][] = {
	"vsh_rewrite/saxton_hale/saxton_hale_132_kill_engie_1.mp3",
	"vsh_rewrite/saxton_hale/saxton_hale_132_kill_engie_2.mp3",
	"vsh_rewrite/saxton_hale/saxton_hale_responce_kill_eggineer1.mp3",
	"vsh_rewrite/saxton_hale/saxton_hale_responce_kill_eggineer2.mp3"
};

static char g_strHaleKillMedic[][] = {
	"vsh_rewrite/saxton_hale/saxton_hale_responce_kill_medic.mp3"
};

static char g_strHaleKillSniper[][] = {
	"vsh_rewrite/saxton_hale/saxton_hale_responce_kill_sniper1.mp3",
	"vsh_rewrite/saxton_hale/saxton_hale_responce_kill_sniper2.mp3"
};

static char g_strHaleKillSpy[][] = {
	"vsh_rewrite/saxton_hale/saxton_hale_responce_kill_spy1.mp3",
	"vsh_rewrite/saxton_hale/saxton_hale_responce_kill_spy2.mp3",
	"vsh_rewrite/saxton_hale/saxton_hale_132_kill_spie.mp3"
};

static char g_strHaleKillBuilding[][] = {
	"vsh_rewrite/saxton_hale/saxton_hale_132_kill_toy.mp3"
};

static char g_strHaleLastMan[][] = {
	"vsh_rewrite/saxton_hale/saxton_hale_responce_2.mp3",
	"vsh_rewrite/saxton_hale/saxton_hale_132_last.mp3",
	"vsh_rewrite/saxton_hale/saxton_hale_responce_lastman1.mp3",
	"vsh_rewrite/saxton_hale/saxton_hale_responce_lastman2.mp3",
	"vsh_rewrite/saxton_hale/saxton_hale_responce_lastman3.mp3",
	"vsh_rewrite/saxton_hale/saxton_hale_responce_lastman4.mp3",
	"vsh_rewrite/saxton_hale/saxton_hale_responce_lastman5.mp3"
};

static char g_strHaleBackStabbed[][] = {
	"vsh_rewrite/saxton_hale/saxton_hale_132_stub_1.mp3",
	"vsh_rewrite/saxton_hale/saxton_hale_132_stub_2.mp3",
	"vsh_rewrite/saxton_hale/saxton_hale_132_stub_3.mp3",
	"vsh_rewrite/saxton_hale/saxton_hale_132_stub_4.mp3"
};

public void SaxtonHale_Create(SaxtonHaleBase boss)
{
	boss.CreateClass("BraveJump");

	boss.CreateClass("RageAttributes");
	boss.SetPropFloat("RageAttributes", "RageAttribDuration", 5.0);
	boss.SetPropFloat("RageAttributes", "RageAttribSuperRageMultiplier", 2.0);
	RageAttributes_AddAttrib(boss, 6, 0.3, 0.3, false);		// Increased attack speed (+70%)

	boss.CreateClass("RageAddCond");
	boss.SetPropFloat("RageAddCond", "RageCondDuration", 5.0);
	boss.SetPropFloat("RageAddCond", "RageCondSuperRageMultiplier", 2.0);
	RageAddCond_AddCond(boss, TFCond_SpeedBuffAlly);	// Speed boost effect
	RageAddCond_AddCond(boss, TFCond_MegaHeal);			// Knockback & stun immunity
	RageAddCond_AddCond(boss, TFCond_DefenseBuffed);	// Battalion's Resistance

	boss.CreateClass("Lunge");
	
	boss.iHealthPerPlayer = 600;
	boss.flHealthExponential = 1.05;
	boss.nClass = TFClass_Soldier;
	boss.iMaxRageDamage = 2500;
}

public void SaxtonHale_GetBossName(SaxtonHaleBase boss, char[] sName, int length)
{
	strcopy(sName, length, "Saxton Hale");
}

public void SaxtonHale_GetBossInfo(SaxtonHaleBase boss, char[] sInfo, int length)
{
	StrCat(sInfo, length, "\nHealth: Medium");
	StrCat(sInfo, length, "\n ");
	StrCat(sInfo, length, "\nAbilities");
	StrCat(sInfo, length, "\n- Brave Jump");
	StrCat(sInfo, length, "\n- Lunge, reload to use");
	StrCat(sInfo, length, "\n ");
	StrCat(sInfo, length, "\nRage");
	StrCat(sInfo, length, "\n- Damage requirement: 2500");
	StrCat(sInfo, length, "\n- Faster attack and movement speed");
	StrCat(sInfo, length, "\n- Knockback and stun immunity");
	StrCat(sInfo, length, "\n- Damage resistance and crits immunity");
	StrCat(sInfo, length, "\n- 200%% Rage: Extends duration from 5 to 10 seconds");
}

public void SaxtonHale_OnSpawn(SaxtonHaleBase boss)
{
	char attribs[128];
	Format(attribs, sizeof(attribs), "2 ; 2.80 ; 252 ; 0.5 ; 259 ; 1.0 ; 214 ; %d", GetRandomInt(9999, 99999));
	int iWeapon = boss.CallFunction("CreateWeapon", 195, "tf_weapon_shovel", 100, TFQual_Strange, attribs);
	if (iWeapon > MaxClients)
		SetEntPropEnt(boss.iClient, Prop_Send, "m_hActiveWeapon", iWeapon);
	/*
	Fist attributes:
	
	2: damage bonus
	252: reduction in push force taken from damage
	259: Deals 3x falling damage to the player you land on
	214: kill_eater
	*/
}

public void SaxtonHale_OnRage(SaxtonHaleBase boss)
{
	if (!g_bHaleSpeedRage[boss.iClient])
	{
		boss.flSpeed *= 1.3;
		g_bHaleSpeedRage[boss.iClient] = true;
	}
}

public void SaxtonHale_OnThink(SaxtonHaleBase boss)
{
	if (g_bHaleSpeedRage[boss.iClient] && boss.flRageLastTime < GetGameTime() - (boss.bSuperRage ? 8.0 : 5.0))
	{
		g_bHaleSpeedRage[boss.iClient] = false;
		boss.flSpeed /= 1.3;
	}
}

public void SaxtonHale_OnPlayerKilled(SaxtonHaleBase boss, Event event, int iVictim)
{
	KillIconShared(boss, event, true);
}

public void SaxtonHale_OnDestroyObject(SaxtonHaleBase boss, Event event)
{
	KillIconShared(boss, event, false);
}

static void KillIconShared(SaxtonHaleBase boss, Event event, bool bLog)
{
	int iWeaponId = event.GetInt("weaponid");
	
	if (iWeaponId == TF_WEAPON_SHOVEL || iWeaponId == TF_WEAPON_BOTTLE)
	{
		if (bLog)
			event.SetString("weapon_logclassname", g_bHaleSpeedRage[boss.iClient] ? "berserk" : "fists");
		
		event.SetString("weapon", g_bHaleSpeedRage[boss.iClient] ? "vehicle" : "fists");
		event.SetInt("weaponid", TF_WEAPON_FISTS);
	}
}

public void SaxtonHale_GetModel(SaxtonHaleBase boss, char[] sModel, int length)
{
	strcopy(sModel, length, HALE_MODEL);
}

public void SaxtonHale_GetSound(SaxtonHaleBase boss, char[] sSound, int length, SaxtonHaleSound iSoundType)
{
	switch (iSoundType)
	{
		case VSHSound_RoundStart: strcopy(sSound, length, g_strHaleRoundStart[GetRandomInt(0,sizeof(g_strHaleRoundStart)-1)]);
		case VSHSound_Win: strcopy(sSound, length, g_strHaleWin[GetRandomInt(0,sizeof(g_strHaleWin)-1)]);
		case VSHSound_Lose: strcopy(sSound, length, g_strHaleLose[GetRandomInt(0,sizeof(g_strHaleLose)-1)]);
		case VSHSound_Rage: strcopy(sSound, length, g_strHaleRage[GetRandomInt(0,sizeof(g_strHaleRage)-1)]);
		case VSHSound_KillBuilding: strcopy(sSound, length, g_strHaleKillBuilding[GetRandomInt(0,sizeof(g_strHaleKillBuilding)-1)]);
		case VSHSound_Lastman: strcopy(sSound, length, g_strHaleLastMan[GetRandomInt(0,sizeof(g_strHaleLastMan)-1)]);
		case VSHSound_Backstab: strcopy(sSound, length, g_strHaleBackStabbed[GetRandomInt(0,sizeof(g_strHaleBackStabbed)-1)]);
	}
}

public void SaxtonHale_GetSoundAbility(SaxtonHaleBase boss, char[] sSound, int length, const char[] sType)
{
	if (strcmp(sType, "BraveJump") == 0)
		strcopy(sSound, length, g_strHaleJump[GetRandomInt(0,sizeof(g_strHaleJump)-1)]);
	
	if (strcmp(sType, "Lunge") == 0)
		strcopy(sSound, length, g_strHaleLunge[GetRandomInt(0,sizeof(g_strHaleLunge)-1)]);
}

public void SaxtonHale_GetSoundKill(SaxtonHaleBase boss, char[] sSound, int length, TFClassType nClass)
{
	if (!GetRandomInt(0, 1) || nClass == TFClass_Soldier)
	{
		strcopy(sSound, length, g_strHaleKill[GetRandomInt(0,sizeof(g_strHaleKill)-1)]);
	}
	else
	{
		switch (nClass)
		{
			case TFClass_Scout: strcopy(sSound, length, g_strHaleKillScout[GetRandomInt(0,sizeof(g_strHaleKillScout)-1)]);
			case TFClass_Pyro: strcopy(sSound, length, g_strHaleKillPyro[GetRandomInt(0,sizeof(g_strHaleKillPyro)-1)]);
			case TFClass_DemoMan: strcopy(sSound, length, g_strHaleKillDemoman[GetRandomInt(0,sizeof(g_strHaleKillDemoman)-1)]);
			case TFClass_Heavy: strcopy(sSound, length, g_strHaleKillHeavy[GetRandomInt(0,sizeof(g_strHaleKillHeavy)-1)]);
			case TFClass_Engineer: strcopy(sSound, length, g_strHaleKillEngineer[GetRandomInt(0,sizeof(g_strHaleKillEngineer)-1)]);
			case TFClass_Medic: strcopy(sSound, length, g_strHaleKillMedic[GetRandomInt(0,sizeof(g_strHaleKillMedic)-1)]);
			case TFClass_Sniper: strcopy(sSound, length, g_strHaleKillSniper[GetRandomInt(0,sizeof(g_strHaleKillSniper)-1)]);
			case TFClass_Spy: strcopy(sSound, length, g_strHaleKillSpy[GetRandomInt(0,sizeof(g_strHaleKillSpy)-1)]);
		}
	}
}

public Action SaxtonHale_OnSoundPlayed(SaxtonHaleBase boss, int clients[MAXPLAYERS], int &numClients, char sample[PLATFORM_MAX_PATH], int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
	if (strncmp(sample, "vo/", 3) == 0)//Block voicelines
		return Plugin_Handled;
	return Plugin_Continue;
}

public void SaxtonHale_Precache(SaxtonHaleBase boss)
{
	PrecacheModel(HALE_MODEL);
	for (int i = 0; i < sizeof(g_strHaleRoundStart); i++) PrepareSound(g_strHaleRoundStart[i]);
	for (int i = 0; i < sizeof(g_strHaleWin); i++) PrepareSound(g_strHaleWin[i]);
	for (int i = 0; i < sizeof(g_strHaleLose); i++) PrepareSound(g_strHaleLose[i]);
	for (int i = 0; i < sizeof(g_strHaleRage); i++) PrepareSound(g_strHaleRage[i]);
	for (int i = 0; i < sizeof(g_strHaleLunge); i++) PrepareSound(g_strHaleLunge[i]);
	for (int i = 0; i < sizeof(g_strHaleJump); i++) PrepareSound(g_strHaleJump[i]);
	for (int i = 0; i < sizeof(g_strHaleKill); i++) PrepareSound(g_strHaleKill[i]);
	for (int i = 0; i < sizeof(g_strHaleKillScout); i++) PrepareSound(g_strHaleKillScout[i]);
	//for (int i = 0; i < sizeof(g_strHaleKillSoldier); i++) PrepareSound(g_strHaleKillSoldier[i]);
	for (int i = 0; i < sizeof(g_strHaleKillPyro); i++) PrepareSound(g_strHaleKillPyro[i]);
	for (int i = 0; i < sizeof(g_strHaleKillDemoman); i++) PrepareSound(g_strHaleKillDemoman[i]);
	for (int i = 0; i < sizeof(g_strHaleKillHeavy); i++) PrepareSound(g_strHaleKillHeavy[i]);
	for (int i = 0; i < sizeof(g_strHaleKillEngineer); i++) PrepareSound(g_strHaleKillEngineer[i]);
	for (int i = 0; i < sizeof(g_strHaleKillMedic); i++) PrepareSound(g_strHaleKillMedic[i]);
	for (int i = 0; i < sizeof(g_strHaleKillSniper); i++) PrepareSound(g_strHaleKillSniper[i]);
	for (int i = 0; i < sizeof(g_strHaleKillSpy); i++) PrepareSound(g_strHaleKillSpy[i]);
	for (int i = 0; i < sizeof(g_strHaleKillBuilding); i++) PrepareSound(g_strHaleKillBuilding[i]);
	for (int i = 0; i < sizeof(g_strHaleLastMan); i++) PrepareSound(g_strHaleLastMan[i]);
	for (int i = 0; i < sizeof(g_strHaleBackStabbed); i++) PrepareSound(g_strHaleBackStabbed[i]);
	
	AddFileToDownloadsTable("materials/models/player/hwm_saxton_hale/tongue_saxxy.vmt");
	AddFileToDownloadsTable("materials/models/player/hwm_saxton_hale/saxton_hat_saxxy.vmt");
	AddFileToDownloadsTable("materials/models/player/hwm_saxton_hale/saxton_hat_saxxy.vtf");
	AddFileToDownloadsTable("materials/models/player/hwm_saxton_hale/saxton_hat_color.vmt");
	AddFileToDownloadsTable("materials/models/player/hwm_saxton_hale/saxton_hat_color.vtf");
	AddFileToDownloadsTable("materials/models/player/hwm_saxton_hale/saxton_body_saxxy.vmt");
	AddFileToDownloadsTable("materials/models/player/hwm_saxton_hale/saxton_body_saxxy.vtf");
	AddFileToDownloadsTable("materials/models/player/hwm_saxton_hale/saxton_body_normal.vtf");
	AddFileToDownloadsTable("materials/models/player/hwm_saxton_hale/saxton_body_exp.vtf");
	AddFileToDownloadsTable("materials/models/player/hwm_saxton_hale/saxton_body_alt.vmt");
	AddFileToDownloadsTable("materials/models/player/hwm_saxton_hale/saxton_body.vmt");
	AddFileToDownloadsTable("materials/models/player/hwm_saxton_hale/saxton_body.vtf");
	AddFileToDownloadsTable("materials/models/player/hwm_saxton_hale/saxton_belt_high_normal.vtf");
	AddFileToDownloadsTable("materials/models/player/hwm_saxton_hale/saxton_belt_high.vtf");
	AddFileToDownloadsTable("materials/models/player/hwm_saxton_hale/saxton_belt_high.vmt");
	AddFileToDownloadsTable("materials/models/player/hwm_saxton_hale/saxton_belt.vmt");
	AddFileToDownloadsTable("materials/models/player/hwm_saxton_hale/hwm/saxton_head.vmt");
	AddFileToDownloadsTable("materials/models/player/hwm_saxton_hale/hwm/saxton_head.vtf");
	AddFileToDownloadsTable("materials/models/player/hwm_saxton_hale/hwm/saxton_head_exponent.vtf");
	AddFileToDownloadsTable("materials/models/player/hwm_saxton_hale/hwm/saxton_head_normal.vtf");
	AddFileToDownloadsTable("materials/models/player/hwm_saxton_hale/hwm/saxton_head_saxxy.vmt");
	AddFileToDownloadsTable("materials/models/player/hwm_saxton_hale/hwm/saxton_head_saxxy.vtf");
	AddFileToDownloadsTable("materials/models/player/hwm_saxton_hale/hwm/tongue.vtf");
	AddFileToDownloadsTable("materials/models/player/hwm_saxton_hale/hwm/tongue.vmt");
	AddFileToDownloadsTable("materials/models/player/hwm_saxton_hale/shades/eye.vtf");
	AddFileToDownloadsTable("materials/models/player/hwm_saxton_hale/shades/eyeball_r.vmt");
	AddFileToDownloadsTable("materials/models/player/hwm_saxton_hale/shades/eyeball_l.vmt");
	AddFileToDownloadsTable("materials/models/player/hwm_saxton_hale/shades/eyeball_saxxy.vmt");
	AddFileToDownloadsTable("materials/models/player/hwm_saxton_hale/shades/eye-extra.vtf");
	AddFileToDownloadsTable("materials/models/player/hwm_saxton_hale/shades/eye-saxxy.vtf");
	AddFileToDownloadsTable("materials/models/player/hwm_saxton_hale/shades/inv.vmt");
	AddFileToDownloadsTable("materials/models/player/hwm_saxton_hale/shades/null.vtf");
	
	AddFileToDownloadsTable("models/player/saxton_hale_jungle_inferno/saxton_hale_3.mdl");
	AddFileToDownloadsTable("models/player/saxton_hale_jungle_inferno/saxton_hale_3.phy");
	AddFileToDownloadsTable("models/player/saxton_hale_jungle_inferno/saxton_hale_3.vvd");
	AddFileToDownloadsTable("models/player/saxton_hale_jungle_inferno/saxton_hale_3.dx80.vtx");
	AddFileToDownloadsTable("models/player/saxton_hale_jungle_inferno/saxton_hale_3.dx90.vtx");
}

