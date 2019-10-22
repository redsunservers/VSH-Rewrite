#define ANNOUNCER_MODEL "models/player/kirillian/boss/sedisocks_administrator.mdl"
#define ANNOUNCER_THEME "freak_fortress_2/admin/admin_music.mp3"

static char g_strAnnouncerRoundStart[][] = {
	"vo/announcer_dec_missionbegins60s01.mp3",
	"vo/announcer_dec_missionbegins60s02.mp3",
	"vo/compmode/cm_admin_callout_question_03.mp3",
	"vo/compmode/cm_admin_outlier_question_02.mp3",
};

static char g_strAnnouncerWin[][] = {
	"vo/announcer_you_failed.mp3",
	"vo/announcer_dec_success01.mp3",
	"vo/compmode/cm_admin_callout_no_06.mp3",
	"vo/compmode/cm_admin_csummarycheer_02.mp3",
};

static char g_strAnnouncerLose[][] = {
	"vo/announcer_dec_failure01.mp3",
	"vo/announcer_dec_failure02.mp3",
	"vo/announcer_dec_missionbegins60s04.mp3",
};

static char g_strAnnouncerKill[][] = {
	"vo/announcer_am_lastmanforfeit01.mp3",
	"vo/announcer_am_lastmanforfeit03.mp3",
	"vo/announcer_dec_kill07.mp3",
	"vo/announcer_dec_kill10.mp3",
	"vo/announcer_dec_missionbegin30s02.mp3",
};

static char g_strAnnouncerKillMinion[][] = {
	"vo/mvm_general_destruction02.mp3",
	"vo/mvm_general_destruction04.mp3",
	"vo/mvm_general_destruction05.mp3",
	"vo/mvm_general_destruction028.mp3",
};

static char g_strAnnouncerDisguise[][] = {
	"vo/announcer_dec_missionbegins30s04.mp3",
	"vo/announcer_dec_missionbegins30s05.mp3",
	"vo/announcer_you_must_not_fail_this_time.mp3",
};

static char g_strAnnouncerLastMan[][] = {
	"vo/taunts/announcer_am_lastmanalive02.mp3",
	"vo/taunts/announcer_am_lastmanalive03.mp3",
};

static char g_strAnnouncerBackStabbed[][] = {
	"vo/compmode/cm_admin_misc_07.mp3",
	"vo/compmode/cm_admin_misc_09.mp3",
};

methodmap CAnnouncer < SaxtonHaleBase
{
	public CAnnouncer(CAnnouncer boss)
	{
		boss.iBaseHealth = 800;
		boss.iHealthPerPlayer = 800;
		boss.nClass = TFClass_Spy;
		boss.iMaxRageDamage = 2500;
	}
	
	public void GetBossName(char[] sName, int length)
	{
		strcopy(sName, length, "Announcer");
	}
	
	public void GetBossInfo(char[] sInfo, int length)
	{
		StrCat(sInfo, length, "\nHealth: Medium");
		StrCat(sInfo, length, "\n ");
		StrCat(sInfo, length, "\nAbilities");
		StrCat(sInfo, length, "\n- Swaps player you shot using Diamondback to your team");
		StrCat(sInfo, length, "\n ");
		StrCat(sInfo, length, "\nRage");
		StrCat(sInfo, length, "\n- Diamondback with ammos added");
		StrCat(sInfo, length, "\n- 200%% Rage: Double ammo added to Diamondback");
	}
	
	public void OnSpawn()
	{
		int iClient = this.iClient;
		int iWeapon;
		char attribs[128];
		
		Format(attribs, sizeof(attribs), "37 ; 0.0 ; 106 ; 0.0 ; 117 ; 0.0");
		iWeapon = this.CallFunction("CreateWeapon", 525, "tf_weapon_revolver", 100, TFQual_Collectors, attribs);
		if (iWeapon > MaxClients)
		{
			SetEntProp(iWeapon, Prop_Send, "m_iClip1", 0);
			SetEntProp(iClient, Prop_Send, "m_iAmmo", 0, _, 2);
		}
		/*
		Diamondback attributes:
		
		2: Damage bonus
		37: mult_maxammo_primary
		106: More accurate
		117: Attrib_Dmg_Falloff_Increased	//Doesnt even work thanks valve
		*/
		
		Format(attribs, sizeof(attribs), "2 ; 4.55 ; 252 ; 0.5 ; 259 ; 1.0 ; 329 ; 0.65");
		iWeapon = this.CallFunction("CreateWeapon", 194, "tf_weapon_knife", 100, TFQual_Collectors, attribs);
		if (iWeapon > MaxClients)
			SetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon", iWeapon);
		/*
		Knife attributes:
		
		2: Damage bonus
		252: reduction in push force taken from damage
		259: Deals 3x falling damage to the player you land on
		329: reduction in airblast vulnerability
		*/
	}
	
	public void GetModel(char[] sModel, int length)
	{
		strcopy(sModel, length, ANNOUNCER_MODEL);
	}
	
	public void GetSound(char[] sSound, int length, SaxtonHaleSound iSoundType)
	{
		switch (iSoundType)
		{
			case VSHSound_RoundStart: strcopy(sSound, length, g_strAnnouncerRoundStart[GetRandomInt(0,sizeof(g_strAnnouncerRoundStart)-1)]);
			case VSHSound_Win: strcopy(sSound, length, g_strAnnouncerWin[GetRandomInt(0,sizeof(g_strAnnouncerWin)-1)]);
			case VSHSound_Lose: strcopy(sSound, length, g_strAnnouncerLose[GetRandomInt(0,sizeof(g_strAnnouncerLose)-1)]);
			case VSHSound_Lastman: strcopy(sSound, length, g_strAnnouncerLastMan[GetRandomInt(0,sizeof(g_strAnnouncerLastMan)-1)]);
			case VSHSound_Backstab: strcopy(sSound, length, g_strAnnouncerBackStabbed[GetRandomInt(0,sizeof(g_strAnnouncerBackStabbed)-1)]);
		}
	}
	
	public void GetSoundKill(char[] sSound, int length, TFClassType nClass)
	{
		strcopy(sSound, length, g_strAnnouncerKill[GetRandomInt(0,sizeof(g_strAnnouncerKill)-1)]);
	}
	
	public void GetMusicInfo(char[] sSound, int length, float &time)
	{
		strcopy(sSound, length, ANNOUNCER_THEME);
		time = 67.5;
	}
	
	public Action OnSoundPlayed(int clients[MAXPLAYERS], int &numClients, char sample[PLATFORM_MAX_PATH], int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
	{
		//Need to block gun sounds
		
		if (strncmp(sample, "vo/", 3) == 0)//Block voicelines
			return Plugin_Handled;
		return Plugin_Continue;
	}
	
	public void OnRage()
	{
		int iPlayerCount = SaxtonHale_GetAliveAttackPlayers();
		
		//Add ammo to primary weapon
		int iPrimaryWep = GetPlayerWeaponSlot(this.iClient, WeaponSlot_Primary);
		if (IsValidEntity(iPrimaryWep))
		{
			int iClip = 2 + RoundToFloor(iPlayerCount / 8.0);
			if (this.bSuperRage) iClip *= 2;
			iClip += GetEntProp(iPrimaryWep, Prop_Send, "m_iClip1");
			if (iClip > 8) iClip = 8;
			
			SetEntProp(iPrimaryWep, Prop_Send, "m_iClip1", iClip);
			SetEntPropEnt(this.iClient, Prop_Send, "m_hActiveWeapon", iPrimaryWep);
		}
	}
	
	public Action OnAttackDamage(int &victim, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
	{
		if (weapon <= MaxClients)
			return Plugin_Continue;
		
		int iIndex = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
		if (TF2_GetSlotInItem(iIndex, TF2_GetPlayerClass(this.iClient)) != WeaponSlot_Primary)
			return Plugin_Continue;
		
		if (TF2_IsUbercharged(victim))
			return Plugin_Continue;
		
		if (!SaxtonHale_IsValidAttack(victim))
		{
			damage = 999.0;
			return Plugin_Changed;
		}
		
		SaxtonHaleBase boss = SaxtonHaleBase(victim);
		if (boss.bValid)
			boss.CallFunction("Destroy");
		
		boss.CallFunction("CreateBoss", "CAnnouncerMinion");
		
		EmitSoundToClient(this.iClient, SOUND_BACKSTAB);
		EmitSoundToClient(victim, SOUND_ALERT);
		EmitSoundToClient(victim, g_strAnnouncerDisguise[GetRandomInt(0, sizeof(g_strAnnouncerDisguise)-1)]);
		
		damage = 0.0;
		return Plugin_Stop;
	}
	
	public void Precache()
	{
		PrecacheModel(ANNOUNCER_MODEL);
		
		PrepareSound(ANNOUNCER_THEME);
		
		for (int i = 0; i < sizeof(g_strAnnouncerRoundStart); i++) PrecacheSound(g_strAnnouncerRoundStart[i]);
		for (int i = 0; i < sizeof(g_strAnnouncerWin); i++) PrecacheSound(g_strAnnouncerWin[i]);
		for (int i = 0; i < sizeof(g_strAnnouncerLose); i++) PrecacheSound(g_strAnnouncerLose[i]);
		for (int i = 0; i < sizeof(g_strAnnouncerKill); i++) PrecacheSound(g_strAnnouncerKill[i]);
		for (int i = 0; i < sizeof(g_strAnnouncerKillMinion); i++) PrecacheSound(g_strAnnouncerKillMinion[i]);
		for (int i = 0; i < sizeof(g_strAnnouncerDisguise); i++) PrecacheSound(g_strAnnouncerDisguise[i]);
		for (int i = 0; i < sizeof(g_strAnnouncerLastMan); i++) PrecacheSound(g_strAnnouncerLastMan[i]);
		for (int i = 0; i < sizeof(g_strAnnouncerBackStabbed); i++) PrecacheSound(g_strAnnouncerBackStabbed[i]);
		
		AddFileToDownloadsTable("materials/models/player/administrator/admin_body.vmt");
		AddFileToDownloadsTable("materials/models/player/administrator/admin_body.vtf");
		AddFileToDownloadsTable("materials/models/player/administrator/admin_body_uber.vmt");
		AddFileToDownloadsTable("materials/models/player/administrator/admin_body_uber.vtf");
		AddFileToDownloadsTable("materials/models/player/administrator/admin_hair.vmt");
		AddFileToDownloadsTable("materials/models/player/administrator/admin_hair.vtf");
		AddFileToDownloadsTable("materials/models/player/administrator/admin_hair_uber.vmt");
		AddFileToDownloadsTable("materials/models/player/administrator/admin_hair_uber.vtf");
		AddFileToDownloadsTable("materials/models/player/administrator/admin_head.vmt");
		AddFileToDownloadsTable("materials/models/player/administrator/admin_head.vtf");
		AddFileToDownloadsTable("materials/models/player/administrator/admin_head_uber.vmt");
		AddFileToDownloadsTable("materials/models/player/administrator/admin_head_uber.vtf");
		AddFileToDownloadsTable("materials/models/player/administrator/tongue.vmt");
		
		AddFileToDownloadsTable("models/player/kirillian/boss/sedisocks_administrator.dx80.vtx");
		AddFileToDownloadsTable("models/player/kirillian/boss/sedisocks_administrator.dx90.vtx");
		AddFileToDownloadsTable("models/player/kirillian/boss/sedisocks_administrator.mdl");
		AddFileToDownloadsTable("models/player/kirillian/boss/sedisocks_administrator.phy");
		AddFileToDownloadsTable("models/player/kirillian/boss/sedisocks_administrator.sw.vtx");
		AddFileToDownloadsTable("models/player/kirillian/boss/sedisocks_administrator.vvd");
	}
};

static Handle g_hAnnouncerMinionTimer[TF_MAXPLAYERS+1];
static int g_iAnnouncerMinionTimeLeft[TF_MAXPLAYERS+1];

methodmap CAnnouncerMinion < SaxtonHaleBase
{
	public CAnnouncerMinion(CAnnouncerMinion boss)
	{
		boss.flSpeed = -1.0;
		boss.iMaxRageDamage = -1;
		boss.bMinion = true;
		boss.bCanBeHealed = true;
		boss.bModel = false;
		
		g_iAnnouncerMinionTimeLeft[boss.iClient] = 6;	//6 seconds before swapping to boss team
		g_hAnnouncerMinionTimer[boss.iClient] = CreateTimer(0.0, Timer_AnnouncerChangeTeam, boss.iClient);
	}
	
	public bool IsBossHidden()
	{
		return true;
	}
	
	public Action OnAttackDamage(int &victim, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
	{
		//Don't allow minion attack boss team
		if (this.iClient != victim && GetClientTeam(victim) == BOSS_TEAM)
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
		if (this.iClient != attacker && GetClientTeam(attacker) == BOSS_TEAM)
		{
			damage = 0.0;
			return Plugin_Stop;
		}
		
		//Because minions have defense buff to block crits, prevent the 35% resist from happening
		damage *= (1.0 / 0.65);
		return Plugin_Changed;
	}
	
	public Action OnBuild(TFObjectType nType, TFObjectMode nMode)
	{
		//Allow Engineer build anything
		return Plugin_Continue;
	}
	
	public void OnPlayerKilled(Event eventInfo, int iVictim)
	{
		for (int iClient = 1; iClient <= MaxClients; iClient++)
		{
			SaxtonHaleBase boss = SaxtonHaleBase(iClient);
			if (boss.bValid && IsPlayerAlive(iClient))
			{
				char sType[128];
				boss.CallFunction("GetBossType", sType, sizeof(sType));
				if (StrEqual(sType, "CAnnouncer"))
				{
					EmitSoundToAll(g_strAnnouncerKillMinion[GetRandomInt(0,sizeof(g_strAnnouncerKillMinion)-1)], iClient, SNDCHAN_VOICE, SNDLEVEL_SCREAMING);
				}
			}
		}
	}
	/*
	public void Think()
	{
		//Ring effect, only show to whoever in boss team or spectators
		
		if (GetClientTeam(this.iClient) != BOSS_TEAM && IsPlayerAlive(this.iClient))
		{
			float vecPos[3];
			GetClientAbsOrigin(this.iClient, vecPos);
			int iTeam = GetClientTeam(this.iClient);
			
			int iColor[4];
			iColor[3] = 255;
			if (iTeam == TFTeam_Blue) iColor[0] = 255;
			else if (iTeam == TFTeam_Red) iColor[2] = 255;
			
			int iClients[MAXPLAYERS];
			int iLength = 0;
			for (int iClient = 1; iClient <= MaxClients; iClient++)
			{
				if (IsClientInGame(iClient))
				{
					char sBossType[256];
					if (g_clientBoss[iClient].IsValid())
						g_clientBoss[iClient].GetType(sBossType, sizeof(sBossType));
					
					if (GetClientTeam(iClient) != ATTACK_TEAM || !IsPlayerAlive(iClient) || StrEqual(sBossType, "CAnnouncerMinion"))
					{
						iClients[iLength] = iClient;
						iLength++;
					}
				}
			}
			
			for (int i = 1; i <= 3; i++)
			{
				vecPos[2] += 18.0;
				TE_SetupBeamRingPoint(vecPos, 40.0, 41.0, g_iSpritesLaserbeam, g_iSpritesGlow, 0, 10, 0.1, 3.0, 0.0, iColor, 10, 0);
				TE_Send(iClients, iLength);
			}
		}
	}
	*/
	public void Destroy()
	{
		g_hAnnouncerMinionTimer[this.iClient] = null;
	}
};

public Action Timer_AnnouncerChangeTeam(Handle hTimer, int iClient)
{
	if (hTimer != g_hAnnouncerMinionTimer[iClient])
		return;
	
	if (GetClientTeam(iClient) == BOSS_TEAM || GetClientTeam(iClient) <= 1 || !IsPlayerAlive(iClient))
		return;
	
	if (g_iAnnouncerMinionTimeLeft[iClient] > 0)
	{
		//Warning on about to become boss
		PrintCenterText(iClient, "YOU'RE SWAPPING TEAMS IN %d SECOND%s", g_iAnnouncerMinionTimeLeft[iClient], g_iAnnouncerMinionTimeLeft[iClient] > 1 ? "S" : "");
		g_iAnnouncerMinionTimeLeft[iClient]--;
		g_hAnnouncerMinionTimer[iClient] = CreateTimer(1.0, Timer_AnnouncerChangeTeam, iClient);
		return;
	}
	
	PrintCenterText(iClient, "YOU'RE NOW IN BOSS TEAM");
	
	Client_AddFlag(iClient, haleClientFlags_BossTeam);
	SetEntProp(iClient, Prop_Send, "m_lifeState", LifeState_Dead);
	ChangeClientTeam(iClient, BOSS_TEAM);
	SetEntProp(iClient, Prop_Send, "m_lifeState", LifeState_Alive);
	
	//Restore weapons, health, ammo and cosmetics after changing teams
	TF2_RegeneratePlayer(iClient);
	
	/*
	//Reset attributes for every weapons, to not include any extras from config
	for (int iSlot = 0; iSlot <= WeaponSlot_BuilderEngie; iSlot++)
	{
		int iWeapon = TF2_GetItemInSlot(iClient, iSlot);
		if (IsValidEdict(iWeapon))
		{
			TF2Attrib_RemoveAll(iWeapon);
			
			int iIndex = GetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex");
			ArrayList aAttrib = TF2Econ_GetItemStaticAttributes(iIndex);
			
			int iLength = aAttrib.Length;
			for (int i = 0; i < iLength; i++)
				TF2Attrib_SetByDefIndex(iWeapon, aAttrib.Get(i, 0), aAttrib.Get(i, 1));	//0 is attrib index, 1 is value
			
			TF2Attrib_ClearCache(iWeapon);
			delete aAttrib;
		}
	}
	*/
	
	int iWeapon = GetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon");
	if (iWeapon > MaxClients)
	{
		char sClassname[256];
		GetEntityClassname(iWeapon, sClassname, sizeof(sClassname));
		
		//Minigun bug with status during team switch while attacking
		if (StrEqual(sClassname, "tf_weapon_minigun"))
		{
			if (GetEntProp(iWeapon, Prop_Send, "m_iWeaponState") == view_as<int>(MinigunState_Shooting)
				|| GetEntProp(iWeapon, Prop_Send, "m_iWeaponState") == view_as<int>(MinigunState_Spinning))
			{
				SetEntProp(iWeapon, Prop_Send, "m_iWeaponState", MinigunState_Idle);
			}
		}
	}
	
	//Dont give health overheal
	SetEntProp(iClient, Prop_Send, "m_iHealth", SDK_GetMaxHealth(iClient));
	
	//TF2_AddCondition(iClient, TFCond_Buffed, TFCondDuration_Infinite);
	TF2_AddCondition(iClient, TFCond_DefenseBuffed, TFCondDuration_Infinite);
}