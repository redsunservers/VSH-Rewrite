#define ANNOUNCER_MODEL "models/player/kirillian/boss/sedisocks_administrator.mdl"
#define ANNOUNCER_THEME "vsh_rewrite/administrator/admin_music.mp3"

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
	"vo/announcer_dec_missionbegins30s02.mp3",
};

static char g_strAnnouncerKillMinion[][] = {
	"vo/mvm_general_destruction02.mp3",
	"vo/mvm_general_destruction04.mp3",
	"vo/mvm_general_destruction05.mp3",
	"vo/mvm_general_destruction08.mp3",
	"vo/announcer_dec_kill07.mp3",
	"vo/announcer_dec_kill10.mp3",
};

static char g_strAnnouncerDisguise[][] = {
	"vo/announcer_dec_missionbegins30s04.mp3",
	"vo/announcer_dec_missionbegins30s05.mp3",
	"vo/announcer_you_must_not_fail_this_time.mp3",
};

static char g_strAnnouncerLastMan[][] = {
	"vo/announcer_am_lastmanalive01.mp3",
	"vo/announcer_am_lastmanalive03.mp3",
	"vo/announcer_am_lastmanalive04.mp3",
};

static char g_strAnnouncerBackStabbed[][] = {
	"vo/compmode/cm_admin_misc_07.mp3",
	"vo/compmode/cm_admin_misc_09.mp3",
	"vo/announcer_sd_monkeynaut_end_crash02.mp3",
};

static char g_strAnnouncerHitBuilding[][] = {
	"weapons/sentry_damage1.wav",
	"weapons/sentry_damage2.wav",
	"weapons/sentry_damage3.wav",
	"weapons/sentry_damage4.wav",
};

public void Announcer_Create(SaxtonHaleBase boss)
{
	boss.iHealthPerPlayer = 600;
	boss.flHealthExponential = 1.05;
	boss.nClass = TFClass_Spy;
	boss.iMaxRageDamage = 2500;
}

public void Announcer_GetBossName(SaxtonHaleBase boss, char[] sName, int length)
{
	strcopy(sName, length, "Announcer");
}

public void Announcer_GetBossInfo(SaxtonHaleBase boss, char[] sInfo, int length)
{
	StrCat(sInfo, length, "\nHealth: Medium");
	StrCat(sInfo, length, "\n ");
	StrCat(sInfo, length, "\nAbilities");
	StrCat(sInfo, length, "\n- Brings players and buildings shot by your Diamondback to your team");
	StrCat(sInfo, length, "\n ");
	StrCat(sInfo, length, "\nRage");
	StrCat(sInfo, length, "\n- Damage requirement: 2500");
	StrCat(sInfo, length, "\n- Ammo is added to your Diamondback");
	StrCat(sInfo, length, "\n- 200%% Rage: Ammo added is doubled");
}

public void Announcer_OnSpawn(SaxtonHaleBase boss)
{
	int iClient = boss.iClient;
	int iWeapon;
	char attribs[128];
	
	Format(attribs, sizeof(attribs), "37 ; 0.0 ; 106 ; 0.0 ; 117 ; 0.0");
	iWeapon = boss.CallFunction("CreateWeapon", 525, "tf_weapon_revolver", 100, TFQual_Collectors, attribs);
	if (iWeapon > MaxClients)
	{
		SetEntProp(iWeapon, Prop_Send, "m_iClip1", 0);
		TF2_SetAmmo(iClient, TF_AMMO_SECONDARY, 0);
	}
	/*
	Diamondback attributes:
	
	2: Damage bonus
	37: mult_maxammo_primary
	106: More accurate
	117: Attrib_Dmg_Falloff_Increased	//Doesnt even work thanks valve
	*/
	
	Format(attribs, sizeof(attribs), "2 ; 4.55 ; 252 ; 0.5 ; 259 ; 1.0");
	iWeapon = boss.CallFunction("CreateWeapon", 194, "tf_weapon_knife", 100, TFQual_Collectors, attribs);
	if (iWeapon > MaxClients)
		SetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon", iWeapon);
	/*
	Knife attributes:
	
	2: Damage bonus
	252: reduction in push force taken from damage
	259: Deals 3x falling damage to the player you land on
	*/
}

public void Announcer_GetModel(SaxtonHaleBase boss, char[] sModel, int length)
{
	strcopy(sModel, length, ANNOUNCER_MODEL);
}

public void Announcer_GetSound(SaxtonHaleBase boss, char[] sSound, int length, SaxtonHaleSound iSoundType)
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

public void Announcer_GetSoundKill(SaxtonHaleBase boss, char[] sSound, int length, TFClassType nClass)
{
	strcopy(sSound, length, g_strAnnouncerKill[GetRandomInt(0,sizeof(g_strAnnouncerKill)-1)]);
}

public void Announcer_GetMusicInfo(SaxtonHaleBase boss, char[] sSound, int length, float &time)
{
	strcopy(sSound, length, ANNOUNCER_THEME);
	time = 67.5;
}

public Action Announcer_OnSoundPlayed(SaxtonHaleBase boss, int clients[MAXPLAYERS], int &numClients, char sample[PLATFORM_MAX_PATH], int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
	//Need to block gun sounds
	
	if (strncmp(sample, "vo/", 3) == 0 && !(strncmp(sample, "vo/announcer_", 13) == 0 || strncmp(sample, "vo/mvm_", 7) == 0 || strncmp(sample, "vo/compmode/cm_admin_", 21) == 0))	//Block voicelines, except her own's
		return Plugin_Handled;
	return Plugin_Continue;
}

public void Announcer_OnRage(SaxtonHaleBase boss)
{
	int iPlayerCount = SaxtonHale_GetAliveAttackPlayers();
	
	//Add ammo to primary weapon
	int iPrimaryWep = GetPlayerWeaponSlot(boss.iClient, WeaponSlot_Primary);
	if (IsValidEntity(iPrimaryWep))
	{
		int iClip = 2 + RoundToFloor(iPlayerCount / 8.0);
		if (boss.bSuperRage) iClip *= 2;
		iClip += GetEntProp(iPrimaryWep, Prop_Send, "m_iClip1");
		if (iClip > 8) iClip = 8;
		
		SetEntProp(iPrimaryWep, Prop_Send, "m_iClip1", iClip);
		TF2_SwitchToWeapon(boss.iClient, iPrimaryWep);
	}
}

public Action Announcer_OnAttackDamage(SaxtonHaleBase boss, int victim, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if (weapon <= MaxClients)
		return Plugin_Continue;
	
	int iIndex = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
	if (TF2_GetItemSlot(iIndex, TF2_GetPlayerClass(boss.iClient)) != WeaponSlot_Primary)
		return Plugin_Continue;
	
	if (TF2_IsUbercharged(victim))
		return Plugin_Continue;
	
	if (!SaxtonHale_IsValidAttack(victim))
	{
		damage = 999.0;
		return Plugin_Changed;
	}
	
	SaxtonHaleBase bossVictim = SaxtonHaleBase(victim);
	if (bossVictim.bValid)
		bossVictim.DestroyAllClass();
	
	bossVictim.CreateClass("AnnouncerMinion");
	
	//Alert teammates, herself and unconverted minions that the victim is about to change teams
	TFClassType nClass = TF2_GetPlayerClass(victim);
	char sMessage[128];
	Format(sMessage, sizeof(sMessage), "A%s %s was hit and will switch teams!", (nClass == TFClass_Engineer ? "n" : ""), g_strClassName[nClass]);
	Announcer_ShowAnnotation(victim, sMessage, 6.0);
	
	EmitSoundToClient(boss.iClient, SOUND_BACKSTAB);
	EmitSoundToClient(victim, SOUND_ALERT);
	EmitSoundToClient(victim, g_strAnnouncerDisguise[GetRandomInt(0, sizeof(g_strAnnouncerDisguise)-1)]);
	
	damage = 0.0;
	return Plugin_Stop;
}

public Action Announcer_OnAttackBuilding(SaxtonHaleBase boss, int building, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if (weapon <= MaxClients)
		return Plugin_Continue;
	
	int iIndex = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
	if (TF2_GetItemSlot(iIndex, TF2_GetPlayerClass(boss.iClient)) != WeaponSlot_Primary)
		return Plugin_Continue;
	
	//Alert teammates, herself and unconverted minions that the building has changed teams
	TFObjectType nType = TF2_GetBuildingType(building);
	TFObjectMode nMode = TF2_GetBuildingMode(building);
	
	char sMessage[128];
	Format(sMessage, sizeof(sMessage), "A %s was hit and has switched teams!", g_strBuildingName[nType][nMode]);
	Announcer_ShowAnnotation(building, sMessage, 3.0);
	
	TF2_SetBuildingTeam(building, TF2_GetClientTeam(boss.iClient), boss.iClient);
	EmitSoundToClient(boss.iClient, g_strAnnouncerHitBuilding[GetRandomInt(0, sizeof(g_strAnnouncerHitBuilding)-1)]);
	damage = 0.0;
	return Plugin_Changed;
}

public void Announcer_Precache(SaxtonHaleBase boss)
{
	PrecacheModel(ANNOUNCER_MODEL);
	
	PrepareMusic(ANNOUNCER_THEME);
	
	for (int i = 0; i < sizeof(g_strAnnouncerRoundStart); i++) PrecacheSound(g_strAnnouncerRoundStart[i]);
	for (int i = 0; i < sizeof(g_strAnnouncerWin); i++) PrecacheSound(g_strAnnouncerWin[i]);
	for (int i = 0; i < sizeof(g_strAnnouncerLose); i++) PrecacheSound(g_strAnnouncerLose[i]);
	for (int i = 0; i < sizeof(g_strAnnouncerKill); i++) PrecacheSound(g_strAnnouncerKill[i]);
	for (int i = 0; i < sizeof(g_strAnnouncerKillMinion); i++) PrecacheSound(g_strAnnouncerKillMinion[i]);
	for (int i = 0; i < sizeof(g_strAnnouncerDisguise); i++) PrecacheSound(g_strAnnouncerDisguise[i]);
	for (int i = 0; i < sizeof(g_strAnnouncerLastMan); i++) PrecacheSound(g_strAnnouncerLastMan[i]);
	for (int i = 0; i < sizeof(g_strAnnouncerBackStabbed); i++) PrecacheSound(g_strAnnouncerBackStabbed[i]);
	for (int i = 0; i < sizeof(g_strAnnouncerHitBuilding); i++) PrecacheSound(g_strAnnouncerHitBuilding[i]);
	
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
	AddFileToDownloadsTable("models/player/kirillian/boss/sedisocks_administrator.vvd");
}

static Handle g_hAnnouncerMinionTimer[MAXPLAYERS];
static int g_iAnnouncerMinionTimeLeft[MAXPLAYERS];

public void AnnouncerMinion_Create(SaxtonHaleBase boss)
{
	boss.flSpeed = -1.0;
	boss.iMaxRageDamage = -1;
	boss.bMinion = true;
	boss.bModel = false;
	
	g_iAnnouncerMinionTimeLeft[boss.iClient] = 6;	//6 seconds before swapping to boss team
	g_hAnnouncerMinionTimer[boss.iClient] = CreateTimer(0.0, Timer_AnnouncerChangeTeam, boss.iClient);
	
	//Make minions untargetable by all sentries until the team-swapping countdown ends
	SetEntityFlags(boss.iClient, (GetEntityFlags(boss.iClient) | FL_NOTARGET));
}

public bool AnnouncerMinion_IsBossHidden(SaxtonHaleBase boss)
{
	return true;
}

public Action AnnouncerMinion_OnAttackDamage(SaxtonHaleBase boss, int victim, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	//Don't allow minion attack boss team
	if (boss.iClient != victim && TF2_GetClientTeam(victim) == TFTeam_Boss)
	{
		damage = 0.0;
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

public Action AnnouncerMinion_OnAttackBuilding(SaxtonHaleBase boss, int building, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	//Stop minions from damaging buildings of other minions in opposite teams or players in the boss team
	int iBuilder = TF2_GetBuildingOwner(building);
	SaxtonHaleBase bossBuilder = SaxtonHaleBase(iBuilder);
	
	if (TF2_GetClientTeam(iBuilder) == TFTeam_Boss || (bossBuilder.bValid && bossBuilder.HasClass("AnnouncerMinion")))
	{
		damage = 0.0;
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

public Action AnnouncerMinion_OnTakeDamage(SaxtonHaleBase boss, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if (attacker <= 0 || attacker > MaxClients)
		return Plugin_Continue;
	
	//Don't allow minion take damage from boss team
	if (boss.iClient != attacker && TF2_GetClientTeam(attacker) == TFTeam_Boss)
	{
		damage = 0.0;
		return Plugin_Stop;
	}
	
	//Because minions have defense buff to block crits, prevent the 35% resist from happening
	damage *= (1.0 / 0.65);
	return Plugin_Changed;
}

public Action AnnouncerMinion_OnBuild(SaxtonHaleBase boss, TFObjectType nType, TFObjectMode nMode)
{
	//Let them build normally
	return Plugin_Continue;
}

public Action AnnouncerMinion_CanHealTarget(SaxtonHaleBase boss, int iTarget, bool &bResult)
{
	//Don't allow heal main bosses
	if (SaxtonHale_IsValidBoss(iTarget, false))
	{
		bResult = false;
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}

public void AnnouncerMinion_OnPlayerKilled(SaxtonHaleBase boss, Event eventInfo, int iVictim)
{
	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		SaxtonHaleBase bossOther = SaxtonHaleBase(iClient);
		if (bossOther.bValid && IsPlayerAlive(iClient))
		{
			if (bossOther.HasClass("Announcer"))
				EmitSoundToAll(g_strAnnouncerKillMinion[GetRandomInt(0,sizeof(g_strAnnouncerKillMinion)-1)], iClient, SNDCHAN_VOICE, SNDLEVEL_SCREAMING);
		}
	}
}

public void AnnouncerMinion_OnPickupTouch(SaxtonHaleBase boss, int iEntity, bool &bResult)
{
	// Allow minions to pick up healthkits/ammopacks
	bResult = true;
}

public void AnnouncerMinion_Destroy(SaxtonHaleBase boss)
{
	g_hAnnouncerMinionTimer[boss.iClient] = null;
	
	//Make them targetable by sentries, just in case
	SetEntityFlags(boss.iClient, (GetEntityFlags(boss.iClient) & ~FL_NOTARGET));
}

public Action Timer_AnnouncerChangeTeam(Handle hTimer, int iClient)
{
	if (hTimer != g_hAnnouncerMinionTimer[iClient])
		return Plugin_Continue;
	
	if (TF2_GetClientTeam(iClient) == TFTeam_Boss || TF2_GetClientTeam(iClient) <= TFTeam_Spectator || !IsPlayerAlive(iClient))
		return Plugin_Continue;
	
	if (g_iAnnouncerMinionTimeLeft[iClient] > 0)
	{
		//Warning on about to become boss
		PrintCenterText(iClient, "YOU'RE SWAPPING TEAMS IN %d SECOND%s", g_iAnnouncerMinionTimeLeft[iClient], g_iAnnouncerMinionTimeLeft[iClient] > 1 ? "S" : "");
		g_iAnnouncerMinionTimeLeft[iClient]--;
		g_hAnnouncerMinionTimer[iClient] = CreateTimer(1.0, Timer_AnnouncerChangeTeam, iClient);
		return Plugin_Continue;
	}
	
	//Need to detach buildings from engineers before switching teams so they don't explode
	int iBuilding = MaxClients+1;
	while ((iBuilding = FindEntityByClassname(iBuilding, "obj_*")) > MaxClients)
	{
		//Even when keeping the same builder, the "original builder" will be detached from the building
		if (GetEntPropEnt(iBuilding, Prop_Send, "m_hBuilder") == iClient)
			TF2_SetBuildingTeam(iBuilding, TFTeam_Boss);
	}
	
	PrintCenterText(iClient, "YOU'RE NOW IN BOSS TEAM");
	
	SetEntProp(iClient, Prop_Send, "m_lifeState", LifeState_Dead);
	TF2_ChangeClientTeam(iClient, TFTeam_Boss);
	SetEntProp(iClient, Prop_Send, "m_lifeState", LifeState_Alive);
	
	//...and add them all back
	iBuilding = MaxClients+1;
	while ((iBuilding = FindEntityByClassname(iBuilding, "obj_*")) > MaxClients)
	{
		if (GetEntPropEnt(iBuilding, Prop_Send, "m_hBuilder") == iClient)
			SDK_AddObject(iClient, iBuilding);
	}
	
	//Update wearable teams
	int iEntity = MaxClients+1;
	while ((iEntity = FindEntityByClassname(iEntity, "tf_wearable*")) > MaxClients)
		if (GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity") == iClient || GetEntPropEnt(iEntity, Prop_Send, "moveparent") == iClient)
			SetEntProp(iEntity, Prop_Send, "m_iTeamNum", view_as<int>(TFTeam_Boss));
	
	for (int iSlot = 0; iSlot <= WeaponSlot_BuilderEngie; iSlot++)
	{
		int iWeapon = TF2_GetItemInSlot(iClient, iSlot);
		if (iWeapon > MaxClients)
		{
			//Change weapon teams
			SetEntProp(iWeapon, Prop_Send, "m_iTeamNum", view_as<int>(TFTeam_Boss));
			
			//Remove attribs added from config, attribs added from TF2 itself is kept
			int iAttribIndex[MAX_ATTRIBUTES_SENT];
			int iCount = TF2Attrib_ListDefIndices(iWeapon, iAttribIndex, sizeof(iAttribIndex));
			
			for (int i = 0; i < iCount; i++)
				TF2Attrib_RemoveByDefIndex(iWeapon, iAttribIndex[i]);
			
			TF2Attrib_ClearCache(iWeapon);
		}
	}
	
	//Refill health
	SetEntProp(iClient, Prop_Send, "m_iHealth", SDK_GetMaxHealth(iClient));
	
	//Refill ammo (jank)
	int iAmmoPack = CreateEntityByName("item_ammopack_full");
	SetEntityOwner(iAmmoPack, iClient);
	SDKHook(iAmmoPack, SDKHook_Touch, AnnouncerMinion_OnRageAmmoPackTouch);
	
	DispatchSpawn(iAmmoPack);
	SetEntityRenderMode(iAmmoPack, RENDER_NONE);
	
	float vecClientPos[3];
	GetClientAbsOrigin(iClient, vecClientPos);
	TeleportEntity(iAmmoPack, vecClientPos, NULL_VECTOR, NULL_VECTOR);
	CreateTimer(0.1, Timer_EntityCleanup, EntIndexToEntRef(iAmmoPack));
	
	//Allow sentries to target this fella from now on
	SetEntityFlags(iClient, (GetEntityFlags(iClient) & ~FL_NOTARGET));
	
	//Give crit resistance 
	TF2_AddCondition(iClient, TFCond_DefenseBuffed, TFCondDuration_Infinite);
	return Plugin_Continue;
}

public void Announcer_ShowAnnotation(int iTarget, char[] sMessage, float flDuration)
{
	int[] iClients = new int[MaxClients];
	int iCount = 0;
	
	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if (IsClientInGame(iClient) && iClient != iTarget)
		{
			SaxtonHaleBase boss = SaxtonHaleBase(iClient);
			
			if (TF2_GetClientTeam(iClient) != TFTeam_Attack || (boss.bValid && boss.HasClass("CAnnouncerMinion")))
				iClients[iCount++] = iClient;
		}
	}
	
	if (iCount <= 0)
		return;
	
	TF2_ShowAnnotation(iClients, iCount, iTarget, sMessage, flDuration);
}

Action AnnouncerMinion_OnRageAmmoPackTouch(int iEntity, int iClient)
{
	int iOwner = GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity");
	if (iClient != iOwner)
		return Plugin_Handled;
	
	return Plugin_Continue;
}