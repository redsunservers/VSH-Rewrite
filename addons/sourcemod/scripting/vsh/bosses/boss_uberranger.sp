#define RANGER_MODEL 		"models/player/vsh_rewrite/uber_ranger/uber_ranger_v2.mdl"
#define RANGER_THEME 		"vsh_rewrite/uber_ranger/uberrangers_music.mp3"
#define RANGER_RAGESOUND 	"mvm/mvm_tele_deliver.wav"

static int g_iUberRangerMinionAFKTimeLeft[TF_MAXPLAYERS];

static ArrayList g_aUberRangerColorList;

static Handle g_hUberRangerMinionAFKTimer[TF_MAXPLAYERS];

static bool g_bUberRangerPlayerWasSummoned[TF_MAXPLAYERS];
static bool g_bUberRangerMinionHasMoved[TF_MAXPLAYERS];

static char g_strUberRangerRoundStart[][] = {
	"vo/medic_battlecry05.mp3"
};

static char g_strUberRangerWin[][] = {
	"vo/medic_specialcompleted12.mp3",
	"vo/taunts/medic/medic_taunt_kill_22.mp3",
	"vo/medic_autocappedcontrolpoint01.mp3"
};

static char g_strUberRangerLose[][] = {
	"vo/medic_paincrticialdeath01.mp3",
	"vo/medic_paincrticialdeath02.mp3",
	"vo/medic_paincrticialdeath03.mp3",
	"vo/medic_paincrticialdeath04.mp3"
};

static char g_strUberRangerRage[][] = {
	"vo/medic_specialcompleted04.mp3",
	"vo/medic_specialcompleted05.mp3",
	"vo/medic_specialcompleted06.mp3"
};

static char g_strUberRangerJump[][] = {
	"vo/medic_go05.mp3",
	"vo/medic_cheers05.mp3"
};

static char g_strUberRangerLastMan[][] = {
	"vo/taunts/medic_taunt_kill_08.mp3"
};

static char g_strUberRangerBackStabbed[][] = {
	"vo/medic_autodejectedtie01.mp3",
	"vo/medic_sf12_badmagic10.mp3", 
	"vo/medic_taunts11.mp3"
};

methodmap CUberRanger < SaxtonHaleBase
{
	public CUberRanger(CUberRanger boss)
	{
		boss.CallFunction("CreateAbility", "CBraveJump");
		
		CRageAddCond rageCond = boss.CallFunction("CreateAbility", "CRageAddCond");
		rageCond.flRageCondDuration = 5.0;
		rageCond.flRageCondSuperRageMultiplier = 1.6;	//8 seconds
		rageCond.AddCond(TFCond_UberchargedCanteen);
		
		boss.iHealthPerPlayer = 500;
		boss.flHealthExponential = 1.05;
		boss.nClass = TFClass_Medic;
		boss.iMaxRageDamage = 2500;
		
		for (int i = 1; i <= MaxClients; i++)
			g_bUberRangerPlayerWasSummoned[i] = false;
		
		UberRanger_ResetColorList();
	}
	
	public void GetBossName(char[] sName, int length)
	{
		strcopy(sName, length, "Über Ranger");
	}
	
	public void GetBossInfo(char[] sInfo, int length)
	{
		StrCat(sInfo, length, "\nHealth: Low");
		StrCat(sInfo, length, "\n ");
		StrCat(sInfo, length, "\nAbilities");
		StrCat(sInfo, length, "\n- Brave Jump");
		StrCat(sInfo, length, "\n- Equipped with a Medi Gun");
		StrCat(sInfo, length, "\n ");
		StrCat(sInfo, length, "\nRage");
		StrCat(sInfo, length, "\n- Damage requirement: 2500");
		StrCat(sInfo, length, "\n- Übercharge for 5 seconds");
		StrCat(sInfo, length, "\n- Summons a fellow Über Ranger");
		StrCat(sInfo, length, "\n- Über Rangers can heal and über each other");
		StrCat(sInfo, length, "\n- 200%% Rage: extends über duration to 8 seconds and summons 3 Über Rangers");
	}
	
	public void OnSpawn()
	{
		char sAttribs[64];
		strcopy(sAttribs, sizeof(sAttribs), "9 ; 0.4");
		this.CallFunction("CreateWeapon", 211, "tf_weapon_medigun", 100, TFQual_Collectors, sAttribs);
		
		/*
		Medigun attribute:
		
		9: ubercharge rate penalty
		*/
		
		strcopy(sAttribs, sizeof(sAttribs), "2 ; 2.80 ; 17 ; 0.1 ; 69 ; 0.5 ; 252 ; 0.5 ; 259 ; 1.0");
		int iWeapon = this.CallFunction("CreateWeapon", 37, "tf_weapon_bonesaw", 100, TFQual_Collectors, sAttribs);
		if (iWeapon > MaxClients)
			SetEntPropEnt(this.iClient, Prop_Send, "m_hActiveWeapon", iWeapon);
			
		/*
		Ubersaw attributes:
		
		2: damage bonus
		17: add uber on hit
		69: health from healers reduced
		252: reduction in push force taken from damage
		259: Deals 3x falling damage to the player you land on
		*/
		
		//For reference: 230 230 230 is the color code for TF2's white paint
		int iColor[4] = { 230, 230, 230, 255 };
		
		SetEntityRenderColor(this.iClient, iColor[0], iColor[1], iColor[2], iColor[3]);
	}
	
	public void GetModel(char[] sModel, int length)
	{
		strcopy(sModel, length, RANGER_MODEL);
	}
	
	public void OnRage()
	{
		int iTotalSummons = 1;
		if (this.bSuperRage) iTotalSummons = 3;
		
		//Create a lil effect
		float vecBossPos[3];
		GetClientAbsOrigin(this.iClient, vecBossPos);
		CreateTimer(3.0, Timer_EntityCleanup, TF2_SpawnParticle(TF2_GetClientTeam(this.iClient) == TFTeam_Blue ? "teleportedin_blue" : "teleportedin_red", vecBossPos));
		EmitSoundToAll(RANGER_RAGESOUND, this.iClient);
		
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
			int iClient = UberRanger_SpawnBestPlayer(aValidMinions);
			
			if (iClient > 0)		
				TF2_TeleportToClient(iClient, this.iClient);
		}
			
		delete aValidMinions;
	}
	
	public void GetSound(char[] sSound, int length, SaxtonHaleSound iSoundType)
	{
		switch (iSoundType)
		{
			case VSHSound_RoundStart: strcopy(sSound, length, g_strUberRangerRoundStart[GetRandomInt(0,sizeof(g_strUberRangerRoundStart)-1)]);
			case VSHSound_Win: strcopy(sSound, length, g_strUberRangerWin[GetRandomInt(0,sizeof(g_strUberRangerWin)-1)]);
			case VSHSound_Lose: strcopy(sSound, length, g_strUberRangerLose[GetRandomInt(0,sizeof(g_strUberRangerLose)-1)]);
			case VSHSound_Rage: strcopy(sSound, length, g_strUberRangerRage[GetRandomInt(0,sizeof(g_strUberRangerRage)-1)]);
			case VSHSound_Lastman: strcopy(sSound, length, g_strUberRangerLastMan[GetRandomInt(0,sizeof(g_strUberRangerLastMan)-1)]);
			case VSHSound_Backstab: strcopy(sSound, length, g_strUberRangerBackStabbed[GetRandomInt(0,sizeof(g_strUberRangerBackStabbed)-1)]);
		}
	}
	
	public void GetSoundAbility(char[] sSound, int length, const char[] sType)
	{
		if (strcmp(sType, "CBraveJump") == 0)
			strcopy(sSound, length, g_strUberRangerJump[GetRandomInt(0,sizeof(g_strUberRangerJump)-1)]);
	}
	
	public void GetMusicInfo(char[] sSound, int length, float &time)
	{
		strcopy(sSound, length, RANGER_THEME);
		time = 235.0;
	}
	
	public void GetHudInfo(char[] sMessage, int iLength, int iColor[4])
	{		
		StrCat(sMessage, iLength, "\nUse your Medigun to heal your companions!");
	}
	
	public void Precache()
	{
		PrecacheModel(RANGER_MODEL);
		PrepareSound(RANGER_THEME);
		PrecacheSound(RANGER_RAGESOUND);
		
		for (int i = 0; i < sizeof(g_strUberRangerRoundStart); i++) PrecacheSound(g_strUberRangerRoundStart[i]);
		for (int i = 0; i < sizeof(g_strUberRangerWin); i++) PrecacheSound(g_strUberRangerWin[i]);
		for (int i = 0; i < sizeof(g_strUberRangerLose); i++) PrecacheSound(g_strUberRangerLose[i]);
		for (int i = 0; i < sizeof(g_strUberRangerLastMan); i++) PrecacheSound(g_strUberRangerLastMan[i]);
		for (int i = 0; i < sizeof(g_strUberRangerBackStabbed); i++) PrecacheSound(g_strUberRangerBackStabbed[i]);
		for (int i = 0; i < sizeof(g_strUberRangerJump); i++) PrecacheSound(g_strUberRangerJump[i]);
		
		AddFileToDownloadsTable("materials/models/player/boss/uber_ranger/uberranger_backpack_v2.vmt");
		AddFileToDownloadsTable("materials/models/player/boss/uber_ranger/uberranger_backpack_v2.vtf");
		AddFileToDownloadsTable("materials/models/player/boss/uber_ranger/uberranger_body_v2.vmt");
		AddFileToDownloadsTable("materials/models/player/boss/uber_ranger/uberranger_body_v2.vtf");
		AddFileToDownloadsTable("materials/models/player/boss/uber_ranger/uberranger_head_v2.vmt");
		AddFileToDownloadsTable("materials/models/player/boss/uber_ranger/uberranger_head_v2.vtf");
		AddFileToDownloadsTable("materials/models/player/boss/uber_ranger/uberranger_beak.vmt");
		AddFileToDownloadsTable("materials/models/player/boss/uber_ranger/uberranger_beak_leather.vmt");
		AddFileToDownloadsTable("materials/models/player/boss/uber_ranger/uberranger_helmet.vmt");
		
		AddFileToDownloadsTable("models/player/vsh_rewrite/uber_ranger/uber_ranger_v2.mdl");
		AddFileToDownloadsTable("models/player/vsh_rewrite/uber_ranger/uber_ranger_v2.sw.vtx");
		AddFileToDownloadsTable("models/player/vsh_rewrite/uber_ranger/uber_ranger_v2.vvd");
		AddFileToDownloadsTable("models/player/vsh_rewrite/uber_ranger/uber_ranger_v2.phy");
		AddFileToDownloadsTable("models/player/vsh_rewrite/uber_ranger/uber_ranger_v2.dx80.vtx");
		AddFileToDownloadsTable("models/player/vsh_rewrite/uber_ranger/uber_ranger_v2.dx90.vtx");
	}
	
	public void Destroy()
	{
		SetEntityRenderColor(this.iClient, 255, 255, 255, 255);
		delete g_aUberRangerColorList;
	}
};

methodmap CMinionRanger < SaxtonHaleBase
{
	public CMinionRanger(CMinionRanger boss)
	{
		CBraveJump abilityJump = boss.CallFunction("CreateAbility", "CBraveJump");
		abilityJump.flMaxHeight *= 0.65;	//Lower max height for super jumps
		
		boss.iBaseHealth = 400;
		boss.iHealthPerPlayer = 40;
		boss.nClass = TFClass_Medic;
		boss.iMaxRageDamage = -1;
		boss.flWeighDownTimer = -1.0;
		boss.bMinion = true;
		boss.bHealthPerPlayerAlive = true;
		
		g_bUberRangerPlayerWasSummoned[boss.iClient] = true;	//Mark the player as summoned so they won't become a miniboss again in this round
		g_bUberRangerMinionHasMoved[boss.iClient] = false;		//Will check if the player has moved to determine if they're AFK or not
		g_iUberRangerMinionAFKTimeLeft[boss.iClient] = 6;		//The player has 6 seconds to move after being summoned, else they'll be taken as AFK and replaced by someone else
		
		EmitSoundToClient(boss.iClient, SOUND_ALERT);			//Alert player as they (re)spawned
	}
	
	public bool IsBossHidden()
	{
		return true;
	}
	
	public void OnSpawn()
	{
		
		char sAttribs[64];
		strcopy(sAttribs, sizeof(sAttribs), "9 ; 0.4");
		this.CallFunction("CreateWeapon", 211, "tf_weapon_medigun", 100, TFQual_Collectors, sAttribs);
		
		/*
		Medigun attribute:
		
		9: ubercharge rate penalty
		*/
		
		strcopy(sAttribs, sizeof(sAttribs), "2 ; 1.25 ; 5 ; 1.2 ; 17 ; 0.25 ; 252 ; 0.5 ; 259 ; 1.0");
		int iWeapon = this.CallFunction("CreateWeapon", 37, "tf_weapon_bonesaw", 10, TFQual_Collectors, sAttribs);
		if (iWeapon > MaxClients)
			SetEntPropEnt(this.iClient, Prop_Send, "m_hActiveWeapon", iWeapon);
		
		/*
		Ubersaw attributes:
		
		2: damage bonus
		5: slower firing speed
		17: add uber on hit
		252: reduction in push force taken from damage
		259: Deals 3x falling damage to the player you land on
		*/
		
		//We're selecting their color from a preset list, so check if it is there at all or has been emptied
		if (g_aUberRangerColorList == null || g_aUberRangerColorList.Length <= 0)
			UberRanger_ResetColorList();
			
		//Assign color
		int iColor[4];
		g_aUberRangerColorList.GetArray(0, iColor);
		g_aUberRangerColorList.Erase(0);
		iColor[3] = 255;
		SetEntityRenderColor(this.iClient, iColor[0], iColor[1], iColor[2], iColor[3]);
		
		//Add glow for him to be easily recognizable as not the boss during spawn uber
		//Round started check is there so it doesn't show up when spawning on the next round as well
		if (GameRules_GetRoundState() != RoundState_Preround)
			CreateTimer(3.0, Timer_EntityCleanup, TF2_CreateGlow(this.iClient, iColor));
		
		g_hUberRangerMinionAFKTimer[this.iClient] = CreateTimer(0.0, Timer_UberRanger_ReplaceMinion, this.iClient);
	}
	
	public void OnButtonPress(int button)
	{
		//Check if the player presses anything, thus isn't AFK
		if (!g_bUberRangerMinionHasMoved[this.iClient])
		{	
			//Reset their über spawn protection
			TF2_RemoveCondition(this.iClient, TFCond_UberchargedCanteen);
			TF2_AddCondition(this.iClient, TFCond_UberchargedCanteen, 3.0);
				
			g_bUberRangerMinionHasMoved[this.iClient] = true;
		}
	}
	
	public void GetModel(char[] sModel, int length)
	{
		strcopy(sModel, length, RANGER_MODEL);
	}
	
	public void GetSoundAbility(char[] sSound, int length, const char[] sType)
	{
		if (strcmp(sType, "CBraveJump") == 0)
			strcopy(sSound, length, g_strUberRangerJump[GetRandomInt(0,sizeof(g_strUberRangerJump)-1)]);
	}
	
	public void GetHudInfo(char[] sMessage, int iLength, int iColor[4])
	{
		if (!g_bUberRangerMinionHasMoved[this.iClient])
			Format(sMessage, iLength, "%s\nYou have %d second%s to move before getting replaced!", sMessage, g_iUberRangerMinionAFKTimeLeft[this.iClient], g_iUberRangerMinionAFKTimeLeft[this.iClient] != 1 ? "s" : "");
		else
			StrCat(sMessage, iLength, "\nUse your Medigun to heal your companions!");
	}
	
	public void OnDeath()
	{
		//This is called on death in case people suicide after getting summoned instead of disabling respawn
		if (!g_bUberRangerMinionHasMoved[this.iClient])
		{
			ArrayList aValidMinions = GetValidSummonableClients();
			
			//Spawn and teleport the replacement to where this AFK minion is, if valid
			int iBestClient = UberRanger_SpawnBestPlayer(aValidMinions);	
			if (iBestClient > 0)
				TF2_TeleportToClient(iBestClient, this.iClient);
				
			delete aValidMinions;
		}
	}
	
	public void Destroy()
	{
		SetEntityRenderColor(this.iClient, 255, 255, 255, 255);
		g_hUberRangerMinionAFKTimer[this.iClient] = null;
	}
};

public void UberRanger_ResetColorList()
{
	if (g_aUberRangerColorList == null)
		g_aUberRangerColorList = new ArrayList(3);
	else
		g_aUberRangerColorList.Clear();
	
	//Hand-picked colors mostly based out of TF2 paint colors, but brightened up so they stand out more
	g_aUberRangerColorList.PushArray({ 20, 20, 20 }); 		// A Distinctive Lack of Hue
	g_aUberRangerColorList.PushArray({ 40, 70, 102 }); 		// An Air of Debonair (BLU) (modified)
	g_aUberRangerColorList.PushArray({ 255, 202, 59 }); 	// Australium Gold (modified)
	g_aUberRangerColorList.PushArray({ 255, 115, 200 }); 	// Pink as Hell (modified)
	g_aUberRangerColorList.PushArray({ 105, 77, 58 }); 		// Radigan Conagher Brown (modified)
	g_aUberRangerColorList.PushArray({ 88, 160, 187 }); 	// Team Spirit (BLU) (modified)
	g_aUberRangerColorList.PushArray({ 210, 59, 59 }); 		// Team Spirit (RED) (modified)
	g_aUberRangerColorList.PushArray({ 50, 205, 50 }); 		// The Bitter Taste of Defeat and Lime
	g_aUberRangerColorList.PushArray({ 79, 100, 59 }); 		// Zepheniah's Greed (modified)

	g_aUberRangerColorList.PushArray({ 25, 230, 230 }); 	// Cyan
	g_aUberRangerColorList.PushArray({ 100, 100, 100 }); 	// Gray
	g_aUberRangerColorList.PushArray({ 255, 110, 0 }); 		// Orangered
	g_aUberRangerColorList.PushArray({ 88, 21, 132 }); 		// Purple (dark)
	
	g_aUberRangerColorList.Sort(Sort_Random, Sort_Integer);
}

public int UberRanger_SpawnBestPlayer(ArrayList aClients)
{
	int iBestClientIndex = -1;
	int iLength = aClients.Length;
	int iBestScore = -1;
	
	for (int i = 0; i < iLength; i++)
	{
		int iClient = aClients.Get(i);
		
		if (!g_bUberRangerPlayerWasSummoned[iClient])
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
		
		boss.CallFunction("CreateBoss", "CMinionRanger");
		TF2_ForceTeamJoin(iBestClientIndex, TFTeam_Boss);
		
		//Duration of this condition will reset when they move
		TF2_AddCondition(iBestClientIndex, TFCond_UberchargedCanteen, 7.0);
	}
	
	//Returns index of client who tried to spawn, or -1 if it finds nobody suitable
	return iBestClientIndex;
}

public Action Timer_UberRanger_ReplaceMinion(Handle hTimer, int iClient)
{
	if (hTimer != g_hUberRangerMinionAFKTimer[iClient])
		return;
		
	if (TF2_GetClientTeam(iClient) <= TFTeam_Spectator || !IsPlayerAlive(iClient) || g_bUberRangerMinionHasMoved[iClient])
		return;
	
	//Adjust the countdown on screen
	if (g_iUberRangerMinionAFKTimeLeft[iClient] > 0)
	{
		g_iUberRangerMinionAFKTimeLeft[iClient]--;
		SaxtonHaleBase(iClient).CallFunction("UpdateHudInfo", 0.0, 0.0);	//Update once
		g_hUberRangerMinionAFKTimer[iClient] = CreateTimer(1.0, Timer_UberRanger_ReplaceMinion, iClient);
		return;
	}
	
	//Snap the AFK player. Note that there's no point in killing them if they're the only acceptable client available
	ArrayList aValidMinions = GetValidSummonableClients();
	int iLength = aValidMinions.Length;
	
	for (int i = 0; i < iLength; i++)
	{
		int iCandidate = aValidMinions.Get(i);
		if (!g_bUberRangerPlayerWasSummoned[iCandidate])
		{
			ForcePlayerSuicide(iClient);
			break;
		}
	}

	delete aValidMinions;
	
	//Set them as moving again, in case the AFK player wasn't killed
	g_bUberRangerMinionHasMoved[iClient] = true;
}