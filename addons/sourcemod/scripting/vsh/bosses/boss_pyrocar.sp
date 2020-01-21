static int g_iPyrocarMinionAFKTimeLeft[TF_MAXPLAYERS+1];
static Handle g_hPyrocarMinionAFKTimer[TF_MAXPLAYERS+1];
static bool g_bPyrocarPlayerWasSummoned[TF_MAXPLAYERS+1];
static bool g_bPyrocarMinionHasMoved[TF_MAXPLAYERS+1];

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

static char g_strPyrocarKill[][] =  {
	"vsh_rewrite/pyrocar/pyrocar_w.mp3", 
	"vsh_rewrite/pyrocar/pyrocar_team.mp3",
	"vsh_rewrite/pyrocar/pyrocar_backlines.mp3",
	"vsh_rewrite/pyrocar/pyrocar_besthat.mp3",
	"vsh_rewrite/pyrocar/pyrocar_burning.mp3",
	"vsh_rewrite/pyrocar/pyrocar_theme.mp3"
};

static char g_strPyrocarLastMan[][] =  {
	"vsh_rewrite/pyrocar/pyrocar_transport.mp3"
};

static char g_strPyrocarKillBuilding[][] =  {
	"vsh_rewrite/pyrocar/pyrocar_burning.mp3",
	"vsh_rewrite/pyrocar/pyrocar_goingdown.mp3"
};

static char g_strPrecacheCosmetics[][] =
{
	"models/player/items/pyro/pyro_hat.mdl",
	"models/player/items/pyro/fireman_helmet.mdl",
	"models/player/items/pyro/pyro_chef_hat.mdl",
	"models/player/items/all_class/ghostly_gibus_pyro.mdl",
	"models/player/items/pyro/pyro_madame_dixie.mdl"
	
};

static int g_iCosmetics[] =
{
	51,
	105,
	394,
	116,
	321
};

static int g_iPrecacheCosmetics[5];

methodmap CPyroCar < SaxtonHaleBase
{
	public CPyroCar(CPyroCar boss)
	{
		boss.CallFunction("CreateAbility", "CFloatJump");
		boss.CallFunction("CreateAbility", "CRageHop");
		boss.CallFunction("CreateAbility", "CForceForward");
		
		boss.iBaseHealth = 800;
		boss.iHealthPerPlayer = 800;
		boss.nClass = TFClass_Pyro;
		boss.flSpeed = 320.0;
		boss.iMaxRageDamage = 2500;
	}
	
	public void GetBossName(char[] sName, int length)
	{
		strcopy(sName, length, "Pyrocar");
	}
	
	public void GetBossInfo(char[] sInfo, int length)
	{
		StrCat(sInfo, length, "\nHealth: Medium");
		StrCat(sInfo, length, "\nYou are forced to go forward");
		StrCat(sInfo, length, "\n ");
		StrCat(sInfo, length, "\nAbilities");
		StrCat(sInfo, length, "\n- Floating");
		StrCat(sInfo, length, "\n ");
		StrCat(sInfo, length, "\nRage");
		StrCat(sInfo, length, "\n- Hops repeatedly dealing fire damage near the impact for 10 seconds");
		StrCat(sInfo, length, "\n- 200%% Rage: Spawns a Kritzkrieg medic and extends duration to 16 seconds");
	}
	
	public void OnSpawn()
	{
		char attribs[128];
		Format(attribs, sizeof(attribs), "24 ; 1.0 ; 59 ; 1.0 ; 112 ; 1.0 ; 181 ; 1.0 ; 252 ; 0.5 ; 356 ; 1.0 ; 839 ; 2.8 ; 841 ; 0 ; 843 ; 8.5 ; 844 ; 2450 ; 862 ; 0.6 ; 863 ; 0.1 ; 865 ; 50 ; 259 ; 1.0 ; 356 ; 1.0 ; 214 ; %d", GetRandomInt(9999, 99999));
		int iWeapon = this.CallFunction("CreateWeapon", 40, "tf_weapon_flamethrower", 100, TFQual_Strange, attribs);
		if (iWeapon > MaxClients)
			SetEntPropEnt(this.iClient, Prop_Send, "m_hActiveWeapon", iWeapon);
			
		/*
		Backburner attributes:
		
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
		
		
		int rnd = GetRandomInt(0, sizeof(g_iPrecacheCosmetics)-1);
		int iWearable = this.CallFunction("CreateWeapon", g_iCosmetics[rnd], "tf_wearable", 1, TFQual_Collectors, "");
		if (iWearable > MaxClients)
			SetEntProp(iWearable, Prop_Send, "m_nModelIndexOverrides", g_iPrecacheCosmetics[rnd]);
	}
	
	public Action OnTakeDamage(int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
	{
		char sWeaponClassName[32];
		if (inflictor >= 0) GetEdictClassname(inflictor, sWeaponClassName, sizeof(sWeaponClassName));
		
		//Disable self-damage from bomb rage ability
		if (this.iClient == attacker && strcmp(sWeaponClassName, "tf_generic_bomb") == 0) return Plugin_Stop;
		
		return Plugin_Continue;
	}
	
	public void OnRage()
	{
		if (!this.bSuperRage) return;
		
		//Create a lil effect
		float vecBossPos[3];
		GetClientAbsOrigin(this.iClient, vecBossPos);
		CreateTimer(3.0, Timer_EntityCleanup, TF2_SpawnParticle(TF2_GetClientTeam(this.iClient) == TFTeam_Blue ? "teleportedin_blue" : "teleportedin_red", vecBossPos));
		EmitSoundToAll(RANGER_RAGESOUND, this.iClient);
		
		ArrayList aValidMinions = GetValidSummonableClients();
		
		//Give priority to players who have the highest scores
		for (int iSelection = 0; iSelection < aValidMinions.Length; iSelection++)
		{
			//Spawn and teleport the replacement to the boss
			int iClient = Pyrocar_SpawnBestPlayer(aValidMinions);
			
			if (iClient > 0)		
				TF2_TeleportToClient(iClient, this.iClient);
		}
		delete aValidMinions;
	}
	
	
	public void GetSound(char[] sSound, int length, SaxtonHaleSound iSoundType)
	{
		switch (iSoundType)
		{
			case VSHSound_RoundStart: strcopy(sSound, length, g_strPyrocarRoundStart[GetRandomInt(0,sizeof(g_strPyrocarRoundStart)-1)]);
			case VSHSound_Win: strcopy(sSound, length, g_strPyrocarWin[GetRandomInt(0,sizeof(g_strPyrocarWin)-1)]);
			case VSHSound_Lose: strcopy(sSound, length, g_strPyrocarLose[GetRandomInt(0,sizeof(g_strPyrocarLose)-1)]);
			//case VSHSound_Rage: strcopy(sSound, length, g_strPyrocarRage[GetRandomInt(0,sizeof(g_strPyrocarRage)-1)]);
			case VSHSound_KillBuilding: strcopy(sSound, length, g_strPyrocarKillBuilding[GetRandomInt(0,sizeof(g_strPyrocarKillBuilding)-1)]);
			case VSHSound_Lastman: strcopy(sSound, length, g_strPyrocarLastMan[GetRandomInt(0,sizeof(g_strPyrocarLastMan)-1)]);
		}
	}
	
	public void GetSoundAbility(char[] sSound, int length, const char[] sType)
	{
	//	if (strcmp(sType, "CBraveJump") == 0)
	//		strcopy(sSound, length, g_strHaleJump[GetRandomInt(0,sizeof(g_strHaleJump)-1)]);
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
			g_iPrecacheCosmetics[i] = PrecacheModel(g_strPrecacheCosmetics[i]);
			
		for (int i = 0; i < sizeof(g_strPyrocarRoundStart); i++) PrepareSound(g_strPyrocarRoundStart[i]);
		for (int i = 0; i < sizeof(g_strPyrocarWin); i++) PrepareSound(g_strPyrocarWin[i]);
		for (int i = 0; i < sizeof(g_strPyrocarLose); i++) PrepareSound(g_strPyrocarLose[i]);
		//for (int i = 0; i < sizeof(g_strPyrocarRage); i++) PrepareSound(g_strPyrocarRage[i]);
		//for (int i = 0; i < sizeof(g_strPyrocarJump); i++) PrepareSound(g_strPyrocarJump[i]);
		for (int i = 0; i < sizeof(g_strPyrocarKill); i++) PrepareSound(g_strPyrocarKill[i]);
		for (int i = 0; i < sizeof(g_strPyrocarKillBuilding); i++) PrepareSound(g_strPyrocarKillBuilding[i]);
		for (int i = 0; i < sizeof(g_strPyrocarLastMan); i++) PrepareSound(g_strPyrocarLastMan[i]);
	}
	
	
};

methodmap CPyrocarMinion < SaxtonHaleBase
{
	public CPyrocarMinion(CPyrocarMinion boss)
	{
		boss.nClass = TFClass_Medic;
		boss.flSpeed = -1.0;
		boss.iMaxRageDamage = -1;
		boss.flWeighDownTimer = -1.0;
		boss.bMinion = true;
		boss.bCanBeHealed = true;
		boss.bModel = false;
	}
	
	public bool IsBossHidden()
	{
		return true;
	}
	
	public Action OnAttackDamage(int &victim, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
	{
		//Don't allow minion attack boss team
		if (this.iClient != victim && TF2_GetClientTeam(victim) == TFTeam_Boss)
		{
			damage = 0.0;
			return Plugin_Stop;
		}
		
		return Plugin_Continue;
	}
	
	public Action OnTakeDamage(int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
	{
		if (attacker <= 0 || attacker > MaxClients)
			return Plugin_Continue;
		
		//Don't allow minion take damage from boss team
		if (this.iClient != attacker && TF2_GetClientTeam(attacker) == TFTeam_Boss)
		{
			damage = 0.0;
			return Plugin_Stop;
		}
		
		//Because minions have defense buff to block crits, prevent the 35% resist from happening
		damage *= (1.0 / 0.65);
		return Plugin_Changed;
	}
	
	
	public void OnSpawn()
	{
		char attribs[128];
		Format(attribs, sizeof(attribs), "24 ; 1.0 ; 59 ; 1.0 ; 112 ; 1.0 ; 181 ; 1.0 ; 252 ; 0.5 ; 356 ; 1.0 ; 839 ; 2.8 ; 841 ; 0 ; 843 ; 8.5 ; 844 ; 2450 ; 862 ; 0.6 ; 863 ; 0.1 ; 865 ; 50 ; 259 ; 1.0 ; 356 ; 1.0 ; 214 ; %d", GetRandomInt(9999, 99999));
		int iWeapon = this.CallFunction("CreateWeapon", 35, "tf_weapon_medigun", 100, TFQual_Strange, attribs);
		if (iWeapon > MaxClients)
			SetEntPropEnt(this.iClient, Prop_Send, "m_hActiveWeapon", iWeapon);
			
		if (iWeapon > 0)
			SetEntPropFloat(iWeapon, Prop_Send, "m_flChargeLevel", 1.0);
		
		g_hPyrocarMinionAFKTimer[this.iClient] = CreateTimer(0.0, Timer_Pyrocar_ReplaceMinion, this.iClient);
		
		
	}
	
	
	public void OnButtonPress(int button)
	{
		//Check if the player presses anything, thus isn't AFK
		if (!g_bPyrocarMinionHasMoved[this.iClient])
		{	
			//Reset their über spawn protection
			TF2_RemoveCondition(this.iClient, TFCond_UberchargedCanteen);
			TF2_AddCondition(this.iClient, TFCond_UberchargedCanteen, 3.0);
				
			g_bPyrocarMinionHasMoved[this.iClient] = true;
		}
	}
}

public int Pyrocar_SpawnBestPlayer(ArrayList aClients)
{
	
	int iBestClientIndex = -1;
	int iLength = aClients.Length;
	int iBestScore = -1;
	
	for (int i = 0; i < iLength; i++)
	{
		int iClient = aClients.Get(i);
		
		if (!g_bPyrocarPlayerWasSummoned[iClient])
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
			boss.CallFunction("Destroy");
			
		//Allow them to join the boss team
		Client_AddFlag(iBestClientIndex, ClientFlags_BossTeam);
		TF2_ForceTeamJoin(iBestClientIndex, TFTeam_Boss);
		
		boss.CallFunction("CreateBoss", "CPyrocarMinion");
		TF2_RespawnPlayer(iBestClientIndex);
		
		
		//Duration of this condition will reset when they move
		TF2_AddCondition(iBestClientIndex, TFCond_UberchargedCanteen, 7.0);
		
	}
	
	//Returns index of client who tried to spawn, or -1 if it finds nobody suitable
	return iBestClientIndex;
	
}

public Action Timer_Pyrocar_ReplaceMinion(Handle hTimer, int iClient)
{
	if (hTimer != g_hPyrocarMinionAFKTimer[iClient])
		return;
		
	if (TF2_GetClientTeam(iClient) <= TFTeam_Spectator || !IsPlayerAlive(iClient) || g_bPyrocarMinionHasMoved[iClient])
		return;
	
	//Adjust the countdown on screen
	if (g_iPyrocarMinionAFKTimeLeft[iClient] > 0)
	{
		g_iPyrocarMinionAFKTimeLeft[iClient]--;
		g_hPyrocarMinionAFKTimer[iClient] = CreateTimer(1.0, Timer_Pyrocar_ReplaceMinion, iClient);
		return;
	}
	
	//Snap the AFK player. Note that there's no point in killing them if they're the only acceptable client available
	ArrayList aValidMinions = GetValidSummonableClients();
	int iLength = aValidMinions.Length;
	
	for (int i = 0; i < iLength; i++)
	{
		int iCandidate = aValidMinions.Get(i);
		if (!g_bPyrocarPlayerWasSummoned[iCandidate])
		{
			ForcePlayerSuicide(iClient);
			break;
		}
	}

	delete aValidMinions;
	
	//Set them as moving again, in case the AFK player wasn't killed
	g_bPyrocarMinionHasMoved[iClient] = true;
}