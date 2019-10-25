#define SEELDIER_MODEL						"models/player/kirillian/boss/seeldier_fix.mdl"
#define SEELDIER_SEE_SND					"vsh_rewrite/seeldier/see.wav"
#define SEE_BOSSES_INTRO_SND				"vsh_rewrite/seeman/intro.wav"

methodmap CSeeldier < SaxtonHaleBase
{
	public CSeeldier(CSeeldier boss)
	{
		boss.CallFunction("CreateAbility", "CWeaponFists");
		boss.CallFunction("CreateAbility", "CBraveJump");
		
		boss.iBaseHealth = 500;
		boss.iHealthPerPlayer = 700;
		boss.nClass = TFClass_Soldier;
		boss.iMaxRageDamage = 2000;
	}
	
	public void GetBossName(char[] sName, int length)
	{
		strcopy(sName, length, "Seeldier");
	}
	
	public void GetBossInfo(char[] sInfo, int length)
	{
		StrCat(sInfo, length, "\nDuo Boss with SeeMan");
		StrCat(sInfo, length, "\nMelee deals 124 damage");
		StrCat(sInfo, length, "\nHealth: Low");
		StrCat(sInfo, length, "\n ");
		StrCat(sInfo, length, "\nAbilities");
		StrCat(sInfo, length, "\n- Brave Jump");
		StrCat(sInfo, length, "\n ");
		StrCat(sInfo, length, "\nRage");
		StrCat(sInfo, length, "\n- Summons 3 mini seeldiers");
		StrCat(sInfo, length, "\n- 200%% Rage: Summons 6 mini seeldiers");
	}
	
	public void OnSpawn()
	{
		char attribs[128];
		Format(attribs, sizeof(attribs), "2 ; 1.9 ; 252 ; 0.5 ; 259 ; 1.0 ; 329 ; 0.65");
		int iWeapon = this.CallFunction("CreateWeapon", 195, "tf_weapon_shovel", 100, TFQual_Collectors, attribs);
		if (iWeapon > MaxClients)
			SetEntPropEnt(this.iClient, Prop_Send, "m_hActiveWeapon", iWeapon);
		/*
		Fist attributes:
		
		2: damage bonus
		252: reduction in push force taken from damage
		259: Deals 3x falling damage to the player you land on
		329: reduction in airblast vulnerability
		*/
	}
	
	public void GetModel(char[] sModel, int length)
	{
		strcopy(sModel, length, SEELDIER_MODEL);
	}
	
	public void OnRage()
	{
		int iTotalMinions = 3;
		if (this.bSuperRage) iTotalMinions *= 2;
		
		float vecBossPos[3], vecBossAng[3];
		GetClientAbsOrigin(this.iClient, vecBossPos);
		GetClientAbsAngles(this.iClient, vecBossAng);
		vecBossAng[0] = 0.0;
		vecBossAng[2] = 0.0;
		
		ArrayList aValidMinions = new ArrayList();
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i)
				&& GetClientTeam(i) > 1
				&& !IsPlayerAlive(i)
				&& Preferences_Get(i, halePreferences_Revival)
				&& !Client_HasFlag(i, haleClientFlags_Punishment))
			{
				if (SaxtonHale_IsValidBoss(i, false)) continue; // Can't let dead boss ressurect
				
				aValidMinions.Push(i);
			}
		}
		
		aValidMinions.Sort(Sort_Random, Sort_Integer);
		int iLength = aValidMinions.Length;
		if (iLength < iTotalMinions)
			iTotalMinions = iLength;
		else
			iLength = iTotalMinions;
		
		for (int i = 0; i < iLength; i++)
		{
			int iClient = aValidMinions.Get(i);

			// Allow them to join the boss team
			Client_AddFlag(iClient, haleClientFlags_BossTeam);
			TF2_ForceTeamJoin(iClient, BOSS_TEAM);
			
			SaxtonHaleBase boss = SaxtonHaleBase(iClient);
			boss.CallFunction("CreateBoss", "CSeeldierMinion");
			TF2_RespawnPlayer(iClient);
			
			float vecVel[3];
			vecVel[0] = GetRandomFloat(-200.0, 200.0);
			vecVel[1] = GetRandomFloat(-200.0, 200.0);
			vecVel[2] = GetRandomFloat(-200.0, 200.0);
			
			TeleportEntity(iClient, vecBossPos, vecBossAng, vecVel);
			TF2_AddCondition(iClient, TFCond_Ubercharged, 2.0);
		}
		
		delete aValidMinions;
	}
	
	public Action OnTakeDamage(int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
	{
		EmitSoundToAll(SEELDIER_SEE_SND, this.iClient, SNDCHAN_VOICE, SNDLEVEL_SCREAMING);
		return Plugin_Continue;
	}
	
	public void GetSound(char[] sSound, int length, SaxtonHaleSound iSoundType)
	{
		//C on every sounds
		switch (iSoundType)
		{
			case VSHSound_RoundStart: strcopy(sSound, length, SEE_BOSSES_INTRO_SND);
			default: strcopy(sSound, length, SEELDIER_SEE_SND);
		}
	}
	
	public void GetSoundAbility (char[] sSound, int length, const char[] sType)
	{
		if (strcmp(sType, "CBraveJump") == 0)
			strcopy(sSound, length, SEELDIER_SEE_SND);
	}
	
	public void GetSoundKill(char[] sSound, int length, TFClassType nClass)
	{
		strcopy(sSound, length, SEELDIER_SEE_SND);
	}
	
	public Action OnSoundPlayed(int clients[MAXPLAYERS], int &numClients, char sample[PLATFORM_MAX_PATH], int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
	{
		if (strncmp(sample, "vo/", 3) == 0)
		{
			return Plugin_Handled;
		}
		return Plugin_Continue;
	}
	
	public void Precache()
	{
		PrepareSound(SEE_BOSSES_INTRO_SND);
		PrecacheModel(SEELDIER_MODEL);
		PrepareSound(SEELDIER_SEE_SND);
		
		AddFileToDownloadsTable("models/player/kirillian/boss/seeldier_fix.mdl");
		AddFileToDownloadsTable("models/player/kirillian/boss/seeldier_fix.sw.vtx");
		AddFileToDownloadsTable("models/player/kirillian/boss/seeldier_fix.vvd");
		AddFileToDownloadsTable("models/player/kirillian/boss/seeldier_fix.dx80.vtx");
		AddFileToDownloadsTable("models/player/kirillian/boss/seeldier_fix.dx90.vtx");
		AddFileToDownloadsTable("models/player/kirillian/boss/seeldier_fix.phy");
	}
};

methodmap CSeeldierMinion < SaxtonHaleBase
{
	public CSeeldierMinion(CSeeldierMinion boss)
	{
		boss.CallFunction("CreateAbility", "CWeaponFists");
		
		boss.iBaseHealth = 300;
		boss.iHealthPerPlayer = 0;
		boss.nClass = TFClass_Soldier;
		boss.iMaxRageDamage = -1;
		boss.bMinion = true;
		
		EmitSoundToClient(boss.iClient, SOUND_ALERT);	//Alert player as he spawned
	}
	
	public bool IsBossHidden()
	{
		return true;
	}
	
	public void OnSpawn()
	{
		char attribs[128];
		Format(attribs, sizeof(attribs), "2 ; 1.25 ; 252 ; 0.5 ; 259 ; 1.0 ; 329 ; 0.65");
		int iWeapon = this.CallFunction("CreateWeapon", 195, "tf_weapon_shovel", 100, TFQual_Collectors, attribs);
		if (iWeapon > MaxClients)
			SetEntPropEnt(this.iClient, Prop_Send, "m_hActiveWeapon", iWeapon);
		
		SetEntPropFloat(this.iClient, Prop_Send, "m_flModelScale", 0.75);
	}
	
	public void GetModel(char[] sModel, int length)
	{
		strcopy(sModel, length, SEELDIER_MODEL);
	}
	
	public void GetSound(char[] sSound, int length, SaxtonHaleSound iSoundType)
	{
		strcopy(sSound, length, SEELDIER_SEE_SND);
	}
	
	public void GetSoundKill(TFClassType playerClass, char[] sSound, int length)
	{
		strcopy(sSound, length, SEELDIER_SEE_SND);
	}
	
	public Action OnSoundPlayed(int clients[MAXPLAYERS], int &numClients, char sample[PLATFORM_MAX_PATH], int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
	{
		if (strncmp(sample, "vo/", 3) == 0)
		{
			return Plugin_Handled;
		}
		return Plugin_Continue;
	}
	
	public void Destroy()
	{
		SetEntPropFloat(this.iClient, Prop_Send, "m_flModelScale", 1.0);
	}
};