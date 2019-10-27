#define SEEMAN_MODEL						"models/player/kirillian/boss/seeman_fix.mdl"
#define SEEMAN_RAGE_SND						"vsh_rewrite/seeman/rage.wav"
#define SEEMAN_SEE_SND						"vsh_rewrite/seeman/see.wav"
#define SEE_BOSSES_INTRO_SND				"vsh_rewrite/seeman/intro.wav"

methodmap CSeeMan < SaxtonHaleBase
{
	public CSeeMan(CSeeMan boss)
	{
		boss.CallFunction("CreateAbility", "CWeaponFists");
		boss.CallFunction("CreateAbility", "CBraveJump");
		CBomb bomb = boss.CallFunction("CreateAbility", "CBomb");
		bomb.flBombSpawnInterval = 0.1;
		bomb.flBombSpawnDuration = 3.0;
		bomb.flBombSpawnRadius = 500.0;
		bomb.flBombRadius = 200.0;
		bomb.flBombDamage = 75.0;
		bomb.flNukeRadius = 650.0;
		
		boss.iBaseHealth = 500;
		boss.iHealthPerPlayer = 700;
		boss.nClass = TFClass_DemoMan;
		boss.iMaxRageDamage = 2000;
		
		CRageAddCond rageCond = boss.CallFunction("CreateAbility", "CRageAddCond");
		rageCond.flRageCondDuration = 3.0;
		rageCond.flRageCondSuperRageMultiplier = 1.0;
		rageCond.AddCond(TFCond_UberchargedCanteen);
	}
	
	public void GetBossName(char[] sName, int length)
	{
		strcopy(sName, length, "SeeMan");
	}
	
	public void GetBossInfo(char[] sInfo, int length)
	{
		StrCat(sInfo, length, "\nDuo Boss with Seeldier");
		StrCat(sInfo, length, "\nMelee deals 124 damage");
		StrCat(sInfo, length, "\nHealth: Low");
		StrCat(sInfo, length, "\n ");
		StrCat(sInfo, length, "\nAbilities");
		StrCat(sInfo, length, "\n- Brave Jump");
		StrCat(sInfo, length, "\n ");
		StrCat(sInfo, length, "\nRage");
		StrCat(sInfo, length, "\n- Frozen with Übercharge for 3 seconds");
		StrCat(sInfo, length, "\n- Many small explosions around boss");
		StrCat(sInfo, length, "\n- 200%% Rage: instakill nuke at end of rage");
	}
	
	public Action OnTakeDamage(int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
	{
		char sWeaponClassName[32];
		if (weapon >= 0) GetEdictClassname(inflictor, sWeaponClassName, sizeof(sWeaponClassName));
		
		if (this.iClient == attacker && strcmp(sWeaponClassName, "tf_generic_bomb") == 0) return Plugin_Stop; // Don't let the bombs from the bomb ability damages us!

		EmitSoundToAll(SEEMAN_SEE_SND, this.iClient, SNDCHAN_VOICE, SNDLEVEL_SCREAMING);
		return Plugin_Continue;
	}
	
	public void OnSpawn()
	{
		char attribs[128];
		Format(attribs, sizeof(attribs), "2 ; 1.9 ; 252 ; 0.5 ; 259 ; 1.0");
		int iWeapon = this.CallFunction("CreateWeapon", 195, "tf_weapon_bottle", 100, TFQual_Collectors, attribs);
		if (iWeapon > MaxClients)
			SetEntPropEnt(this.iClient, Prop_Send, "m_hActiveWeapon", iWeapon);
		/*
		Fist attributes:
		
		2: damage bonus
		252: reduction in push force taken from damage
		259: Deals 3x falling damage to the player you land on
		*/
	}
	
	public void GetModel(char[] sModel, int length)
	{
		strcopy(sModel, length, SEEMAN_MODEL);
	}
	
	public void GetSound(char[] sSound, int length, SaxtonHaleSound iSoundType)
	{
		switch (iSoundType)
		{
			case VSHSound_RoundStart: strcopy(sSound, length, SEE_BOSSES_INTRO_SND);
			default: strcopy(sSound, length, SEEMAN_SEE_SND);
		}
	}
	
	public void GetSoundAbility(char[] sSound, int length, const char[] sType)
	{
		if (strcmp(sType, "CBraveJump") == 0)
			strcopy(sSound, length, SEEMAN_SEE_SND);
	}
	
	public void GetSoundKill(char[] sSound, int length, TFClassType nClass)
	{
		strcopy(sSound, length, SEEMAN_SEE_SND);
	}
	
	public Action OnSoundPlayed(int clients[MAXPLAYERS], int &numClients, char sample[PLATFORM_MAX_PATH], int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
	{
		if (strncmp(sample, "vo/", 3) == 0)
		{
			return Plugin_Handled;
		}
		return Plugin_Continue;
	}
	
	public void GetRageMusicInfo(char[] sSound, int length, float &time)
	{
		strcopy(sSound, length, SEEMAN_RAGE_SND);
		time = 6.0;
	}
	
	public void Precache()
	{
		CBomb.Precache();
		
		PrepareSound(SEEMAN_SEE_SND);
		PrepareSound(SEEMAN_RAGE_SND);
		PrepareSound(SEE_BOSSES_INTRO_SND);
		PrecacheModel(SEEMAN_MODEL);
		
		AddFileToDownloadsTable("models/player/kirillian/boss/seeman_fix.mdl");
		AddFileToDownloadsTable("models/player/kirillian/boss/seeman_fix.sw.vtx");
		AddFileToDownloadsTable("models/player/kirillian/boss/seeman_fix.vvd");
		AddFileToDownloadsTable("models/player/kirillian/boss/seeman_fix.dx80.vtx");
		AddFileToDownloadsTable("models/player/kirillian/boss/seeman_fix.dx90.vtx");
		AddFileToDownloadsTable("models/player/kirillian/boss/seeman_fix.phy");
	}
};