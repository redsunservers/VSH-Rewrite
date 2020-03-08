static char g_strPyrocarRoundStart[][] =  {
	"vsh_rewrite/pyrocar/pyrocar_intro.mp3", 
	"vsh_rewrite/pyrocar/pyrocar_theme.mp3"
};

static char g_strPyrocarWin[][] =  {
	"vsh_rewrite/pyrocar/pyrocar_theme.mp3"
};

static char g_strPyrocarLose[][] =  {
	"vsh_rewrite/pyrocar/pyrocar_fail.mp3"
};

static char g_strPyrocarRage[][] =  {
	"misc/halloween/spell_blast_jump.wav"
};

static char g_strPyrocarJump[][] =  {
	"weapons/bumper_car_speed_boost_start.wav"
};

static char g_strPyrocarKill[][] =  {
	"vsh_rewrite/pyrocar/pyrocar_w.mp3", 
	"vsh_rewrite/pyrocar/pyrocar_team.mp3",
	"vsh_rewrite/pyrocar/pyrocar_backlines.mp3",
	"vsh_rewrite/pyrocar/pyrocar_besthat.mp3",
	"vsh_rewrite/pyrocar/pyrocar_burning.mp3",
	"vsh_rewrite/pyrocar/pyrocar_theme.mp3",
	"vsh_rewrite/pyrocar/pyrocar_medic.mp3"
};

static char g_strPyrocarKillBuilding[][] =  {
	"vsh_rewrite/pyrocar/pyrocar_transport.mp3"
};

static char g_strPyrocarLastMan[][] =  {
	"vsh_rewrite/pyrocar/pyrocar_burning.mp3",
	"vsh_rewrite/pyrocar/pyrocar_goingdown.mp3"
};

static char g_strPrecacheCosmetics[][] =  {
	"models/player/items/pyro/pyro_hat.mdl",
	"models/player/items/pyro/fireman_helmet.mdl",
	"models/player/items/all_class/ghostly_gibus_pyro.mdl",
	"models/player/items/pyro/pyro_madame_dixie.mdl",
	"models/player/items/pyro/pyro_chef_hat.mdl"
};

static int g_iCosmetics[] =  {
	51, //Pyro's Beanie
	105, //Brigade Helm
	116, //Ghastly Gibus
	321, //Madame Dixie
	394 //Connoisseur's Cap
};

static int g_iPyrocarCosmetics[sizeof(g_iCosmetics)];

methodmap CPyroCar < SaxtonHaleBase
{
	public CPyroCar(CPyroCar boss)
	{
		boss.CallFunction("CreateAbility", "CFloatJump");
		boss.CallFunction("CreateAbility", "CRageHop");
		boss.CallFunction("CreateAbility", "CForceForward");
		
		boss.iBaseHealth = 750;
		boss.iHealthPerPlayer = 750;
		boss.nClass = TFClass_Pyro;
		boss.flSpeed = 350.0;
		boss.iMaxRageDamage = 2000;
	}
	
	public bool IsBossHidden()
	{
		return true;
	}
	
	public void GetBossName(char[] sName, int length)
	{
		strcopy(sName, length, "Pyrocar");
	}
	
	public void GetBossInfo(char[] sInfo, int length)
	{
		StrCat(sInfo, length, "\nHealth: Low");
		StrCat(sInfo, length, "\nYou are forced to go forward");
		StrCat(sInfo, length, "\nYou have the same speed as the medic");
		StrCat(sInfo, length, "\n ");
		StrCat(sInfo, length, "\nAbilities");
		StrCat(sInfo, length, "\n- Float Jump");
		StrCat(sInfo, length, "\n ");
		StrCat(sInfo, length, "\nRage");
		StrCat(sInfo, length, "\n- Hops repeatedly dealing explosive fire damage near the impact for 10 seconds");
		StrCat(sInfo, length, "\n- 200%% Rage: Increases explosion damage and extends the duration to 15 seconds");
	}
	
	public void OnSpawn()
	{
		char attribs[128];
		Format(attribs, sizeof(attribs), "3 ; 0.2 ; 24 ; 1.0 ; 59 ; 1.0 ; 112 ; 0.5 ; 181 ; 1.0 ; 252 ; 0.75 ; 356 ; 1.0 ; 839 ; 2.8 ; 841 ; 0 ; 843 ; 8.5 ; 844 ; 2450 ; 862 ; 0.6 ; 863 ; 0.1 ; 865 ; 50 ; 259 ; 1.0 ; 356 ; 1.0 ; 214 ; %d", GetRandomInt(9999, 99999));
		int iWeapon = this.CallFunction("CreateWeapon", 40, "tf_weapon_flamethrower", 100, TFQual_Strange, attribs);
		if (iWeapon > MaxClients)
			SetEntPropEnt(this.iClient, Prop_Send, "m_hActiveWeapon", iWeapon);
			
		/*
		Backburner attributes:
		
		3: clip size penalty
		24: allow crits from behind
		59: self dmg push force decreased
		112: ammo regen
		181: no self blast dmg
		214: kill_eater
		252: reduction in push force taken from damage
		259: Deals 3x falling damage to the player you land on
		356: No airblast
		839: flame spread degree
		841: flame gravity
		843: flame drag
		844: flame speed
		862: flame lifetime
		863: flame random life time offset
		865: flame up speed
		*/
		
		
		int iRandom = GetRandomInt(0, sizeof(g_iCosmetics)-1);
		int iWearable = this.CallFunction("CreateWeapon", g_iCosmetics[iRandom], "tf_wearable", 1, TFQual_Collectors, "");
		if (iWearable > MaxClients)
			SetEntProp(iWearable, Prop_Send, "m_nModelIndexOverrides", g_iPyrocarCosmetics[iRandom]);
	}
	
	public Action OnTakeDamage(int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
	{
		char sWeaponClassName[32];
		if (inflictor >= 0) GetEdictClassname(inflictor, sWeaponClassName, sizeof(sWeaponClassName));
		
		//Disable self-damage from bomb rage ability
		if (this.iClient == attacker && strcmp(sWeaponClassName, "tf_generic_bomb") == 0) return Plugin_Stop;
		
		return Plugin_Continue;
	}	
	
	public void GetSound(char[] sSound, int length, SaxtonHaleSound iSoundType)
	{
		switch (iSoundType)
		{
			case VSHSound_RoundStart: strcopy(sSound, length, g_strPyrocarRoundStart[GetRandomInt(0,sizeof(g_strPyrocarRoundStart)-1)]);
			case VSHSound_Win: strcopy(sSound, length, g_strPyrocarWin[GetRandomInt(0,sizeof(g_strPyrocarWin)-1)]);
			case VSHSound_Lose: strcopy(sSound, length, g_strPyrocarLose[GetRandomInt(0,sizeof(g_strPyrocarLose)-1)]);
			case VSHSound_Rage: strcopy(sSound, length, g_strPyrocarRage[GetRandomInt(0,sizeof(g_strPyrocarRage)-1)]);
			case VSHSound_KillBuilding: strcopy(sSound, length, g_strPyrocarKillBuilding[GetRandomInt(0,sizeof(g_strPyrocarKillBuilding)-1)]);
			case VSHSound_Lastman: strcopy(sSound, length, g_strPyrocarLastMan[GetRandomInt(0,sizeof(g_strPyrocarLastMan)-1)]);
		}
	}
	
	public void GetSoundAbility(char[] sSound, int length, const char[] sType)
	{
		if (strcmp(sType, "CFloatJump") == 0)
			strcopy(sSound, length, g_strPyrocarJump[GetRandomInt(0,sizeof(g_strPyrocarJump)-1)]);
	}
	
	public void GetSoundKill(char[] sSound, int length, TFClassType nClass)
	{
		strcopy(sSound, length, g_strPyrocarKill[GetRandomInt(0, sizeof(g_strPyrocarKill) - 1)]);
	}
	
	public Action OnSoundPlayed(int clients[MAXPLAYERS], int &numClients, char sample[PLATFORM_MAX_PATH], int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
	{
		if (strncmp(sample, "vo/", 3) == 0)//Block voicelines
			return Plugin_Handled;
		return Plugin_Continue;
	}
	
	public void Precache()
	{
		for (int i = 0; i < sizeof(g_iCosmetics); i++)
			g_iPyrocarCosmetics[i] = PrecacheModel(g_strPrecacheCosmetics[i]);
			
		for (int i = 0; i < sizeof(g_strPyrocarRoundStart); i++) PrepareSound(g_strPyrocarRoundStart[i]);
		for (int i = 0; i < sizeof(g_strPyrocarWin); i++) PrepareSound(g_strPyrocarWin[i]);
		for (int i = 0; i < sizeof(g_strPyrocarLose); i++) PrepareSound(g_strPyrocarLose[i]);
		for (int i = 0; i < sizeof(g_strPyrocarRage); i++) PrecacheSound(g_strPyrocarRage[i]);
		for (int i = 0; i < sizeof(g_strPyrocarJump); i++) PrecacheSound(g_strPyrocarJump[i]);
		for (int i = 0; i < sizeof(g_strPyrocarKill); i++) PrepareSound(g_strPyrocarKill[i]);
		for (int i = 0; i < sizeof(g_strPyrocarKillBuilding); i++) PrepareSound(g_strPyrocarKillBuilding[i]);
		for (int i = 0; i < sizeof(g_strPyrocarLastMan); i++) PrepareSound(g_strPyrocarLastMan[i]);
	}
	
};