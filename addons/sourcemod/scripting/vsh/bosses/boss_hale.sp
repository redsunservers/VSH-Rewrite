#define HALE_MODEL "models/player/saxton_hale_jungle_inferno/saxton_hale.mdl"

static char g_strHaleRoundStart[][] = {
	"vsh_rewrite/saxton_hale/saxton_hale_responce_start1.mp3",
	"vsh_rewrite/saxton_hale/saxton_hale_responce_start2.mp3",
	"vsh_rewrite/saxton_hale/saxton_hale_responce_start3.mp3",
	"vsh_rewrite/saxton_hale/saxton_hale_responce_start4.mp3",
	"vsh_rewrite/saxton_hale/saxton_hale_responce_start5.mp3"
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
	"vsh_rewrite/saxton_hale/saxton_hale_responce_rage2.mp3",
	"vsh_rewrite/saxton_hale/saxton_hale_responce_rage3.mp3",
	"vsh_rewrite/saxton_hale/saxton_hale_responce_rage4.mp3"
};

static char g_strHaleJump[][] = {
	"vsh_rewrite/saxton_hale/saxton_hale_responce_jump1.mp3",
	"vsh_rewrite/saxton_hale/saxton_hale_responce_jump2.mp3",
	"vsh_rewrite/saxton_hale/saxton_hale_132_jump_1.mp3",
	"vsh_rewrite/saxton_hale/saxton_hale_132_jump_2.mp3"
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

methodmap CSaxtonHale < SaxtonHaleBase
{
	public CSaxtonHale(CSaxtonHale boss)
	{
		boss.CallFunction("CreateAbility", "CWeaponFists");
		boss.CallFunction("CreateAbility", "CBraveJump");
		CScareRage scareAbility = boss.CallFunction("CreateAbility", "CScareRage");
		scareAbility.flRadius = 800.0;
		
		boss.iHealthPerPlayer = 600;
		boss.flHealthExponential = 1.05;
		boss.nClass = TFClass_Soldier;
		boss.iMaxRageDamage = 2500;
	}
	
	public void GetBossName(char[] sName, int length)
	{
		strcopy(sName, length, "Saxton Hale");
	}
	
	public void GetBossInfo(char[] sInfo, int length)
	{
		StrCat(sInfo, length, "\nHealth: Medium");
		StrCat(sInfo, length, "\n ");
		StrCat(sInfo, length, "\nAbilities");
		StrCat(sInfo, length, "\n- Brave Jump");
		StrCat(sInfo, length, "\n ");
		StrCat(sInfo, length, "\nRage");
		StrCat(sInfo, length, "\n- Scares players at medium range for 5 seconds");
		StrCat(sInfo, length, "\n- 200%% Rage: Longer range and extends duration to 7.5 seconds");
	}
	
	public void OnSpawn()
	{
		char attribs[128];
		Format(attribs, sizeof(attribs), "2 ; 2.80 ; 252 ; 0.5 ; 259 ; 1.0 ; 214 ; %d", GetRandomInt(9999, 99999));
		int iWeapon = this.CallFunction("CreateWeapon", 195, "tf_weapon_shovel", 100, TFQual_Strange, attribs);
		if (iWeapon > MaxClients)
			SetEntPropEnt(this.iClient, Prop_Send, "m_hActiveWeapon", iWeapon);
		/*
		Fist attributes:
		
		2: damage bonus
		252: reduction in push force taken from damage
		259: Deals 3x falling damage to the player you land on
		214: kill_eater
		*/
	}
	
	public void GetModel(char[] sModel, int length)
	{
		strcopy(sModel, length, HALE_MODEL);
	}
	
	public void GetSound(char[] sSound, int length, SaxtonHaleSound iSoundType)
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
	
	public void GetSoundAbility(char[] sSound, int length, const char[] sType)
	{
		if (strcmp(sType, "CBraveJump") == 0)
			strcopy(sSound, length, g_strHaleJump[GetRandomInt(0,sizeof(g_strHaleJump)-1)]);
	}
	
	public void GetSoundKill(char[] sSound, int length, TFClassType nClass)
	{
		switch (nClass)
		{
			case TFClass_Scout: strcopy(sSound, length, g_strHaleKillScout[GetRandomInt(0,sizeof(g_strHaleKillScout)-1)]);
			//case TFClass_Soldier: strcopy(sSound, length, g_strHaleKillSoldier[GetRandomInt(0,sizeof(g_strHaleKillSoldier)-1)]);
			case TFClass_Pyro: strcopy(sSound, length, g_strHaleKillPyro[GetRandomInt(0,sizeof(g_strHaleKillPyro)-1)]);
			case TFClass_DemoMan: strcopy(sSound, length, g_strHaleKillDemoman[GetRandomInt(0,sizeof(g_strHaleKillDemoman)-1)]);
			case TFClass_Heavy: strcopy(sSound, length, g_strHaleKillHeavy[GetRandomInt(0,sizeof(g_strHaleKillHeavy)-1)]);
			case TFClass_Engineer: strcopy(sSound, length, g_strHaleKillEngineer[GetRandomInt(0,sizeof(g_strHaleKillEngineer)-1)]);
			case TFClass_Medic: strcopy(sSound, length, g_strHaleKillMedic[GetRandomInt(0,sizeof(g_strHaleKillMedic)-1)]);
			case TFClass_Sniper: strcopy(sSound, length, g_strHaleKillSniper[GetRandomInt(0,sizeof(g_strHaleKillSniper)-1)]);
			case TFClass_Spy: strcopy(sSound, length, g_strHaleKillSpy[GetRandomInt(0,sizeof(g_strHaleKillSpy)-1)]);
		}
	}
	
	public Action OnSoundPlayed(int clients[MAXPLAYERS], int &numClients, char sample[PLATFORM_MAX_PATH], int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
	{
		if (strncmp(sample, "vo/", 3) == 0)//Block voicelines
			return Plugin_Handled;
		return Plugin_Continue;
	}
	
	public void Precache()
	{
		PrecacheModel(HALE_MODEL);
		for (int i = 0; i < sizeof(g_strHaleRoundStart); i++) PrepareSound(g_strHaleRoundStart[i]);
		for (int i = 0; i < sizeof(g_strHaleWin); i++) PrepareSound(g_strHaleWin[i]);
		for (int i = 0; i < sizeof(g_strHaleLose); i++) PrepareSound(g_strHaleLose[i]);
		for (int i = 0; i < sizeof(g_strHaleRage); i++) PrepareSound(g_strHaleRage[i]);
		for (int i = 0; i < sizeof(g_strHaleJump); i++) PrepareSound(g_strHaleJump[i]);
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
		
		AddFileToDownloadsTable("models/player/saxton_hale_jungle_inferno/saxton_hale.mdl");
		AddFileToDownloadsTable("models/player/saxton_hale_jungle_inferno/saxton_hale.phy");
		AddFileToDownloadsTable("models/player/saxton_hale_jungle_inferno/saxton_hale.sw.vtx");
		AddFileToDownloadsTable("models/player/saxton_hale_jungle_inferno/saxton_hale.vvd");
		AddFileToDownloadsTable("models/player/saxton_hale_jungle_inferno/saxton_hale.dx80.vtx");
		AddFileToDownloadsTable("models/player/saxton_hale_jungle_inferno/saxton_hale.dx90.vtx");
	}
};
