#define RANGER_MODEL "models/player/vsh_rewrite/uber_ranger/uber_ranger.mdl"
#define RANGER_THEME "vsh_rewrite/uber_ranger/uberrangers_music.mp3"
#define RANGER_RAGESOUND "mvm/mvm_tele_deliver.wav"

static int g_iUberRangerPrussianPickelhaube;
static int g_iUberRangerBlightedBeak;

static bool g_bUberRangerPlayerWasSummoned[TF_MAXPLAYERS+1];

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
	"vo/medic_paincrticialdeath04.mp3",
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
		CBraveJump abilityJump = boss.CallFunction("CreateAbility", "CBraveJump");
		abilityJump.iJumpChargeBuild = 1;
		
		CRageAddCond rageCond = boss.CallFunction("CreateAbility", "CRageAddCond");
		rageCond.flRageCondDuration = 6.0;
		rageCond.flRageCondSuperRageMultiplier = 1.333;	//This is 7.998 seconds, close enough
		rageCond.AddCond(TFCond_UberchargedCanteen);
		
		boss.iBaseHealth = 650;
		boss.iHealthPerPlayer = 550;
		boss.nClass = TFClass_Medic;
		boss.iMaxRageDamage = 2500;
		boss.bCanBeHealed = true;
	}
	
	public void GetBossName(char[] sName, int length)
	{
		strcopy(sName, length, "White Über Ranger");
	}
	
	public void GetBossInfo(char[] sInfo, int length)
	{
		StrCat(sInfo, length, "\nHealth: Low");
		StrCat(sInfo, length, "\n ");
		StrCat(sInfo, length, "\nAbilities");
		StrCat(sInfo, length, "\n- Brave Jump (slower charge rate)");
		StrCat(sInfo, length, "\n- Equipped with a Medi Gun");
		StrCat(sInfo, length, "\n ");
		StrCat(sInfo, length, "\nRage");
		StrCat(sInfo, length, "\n- Übercharge for 6 seconds");
		StrCat(sInfo, length, "\n- Summons a fellow Über Ranger");
		StrCat(sInfo, length, "\n- Über Rangers are allowed to heal and über each other");
		StrCat(sInfo, length, "\n- 200%% Rage: extends über duration to 8 seconds and summons 3 Über Rangers");
	}
	
	public bool IsBossHidden()
	{
		return true;
	}
	
	public void OnSpawn()
	{
		//Bosses and minions can't be overhealed, so a -max overheal attribute for the Medigun isn't needed
		this.CallFunction("CreateWeapon", 211, "tf_weapon_medigun", 100, TFQual_Collectors, "");
		
		char sAttribs[128];
		Format(sAttribs, sizeof(sAttribs), "2 ; 2.80 ; 252 ; 0.5 ; 259 ; 1.0"); 
		int iWeapon = this.CallFunction("CreateWeapon", 173, "tf_weapon_bonesaw", 100, TFQual_Collectors, sAttribs);
		if (iWeapon > MaxClients)
			SetEntPropEnt(this.iClient, Prop_Send, "m_hActiveWeapon", iWeapon);
			
		/*
		Vitasaw attributes:
		
		2: damage bonus
		252: reduction in push force taken from damage
		259: Deals 3x falling damage to the player you land on
		*/
		
		int iColor[4];
		
		//For reference: 230 230 230 is the color code for TF2's white paint
		for (int i = 0; i < 3; i++)
			iColor[i] = 230;
			
		iColor[3] = 255;
		
		SetEntityRenderColor(this.iClient, iColor[0], iColor[1], iColor[2], iColor[3]);
		
		int iWearable = -1;
		
		iWearable = this.CallFunction("CreateWeapon", 50, "tf_wearable", GetRandomInt(1, 100), TFQual_Normal, "");	//Prussian Pickelhaube
		if (iWearable > MaxClients)
		{
			SetEntProp(iWearable, Prop_Send, "m_nModelIndexOverrides", g_iUberRangerPrussianPickelhaube);
			SetEntityRenderColor(iWearable, iColor[0], iColor[1], iColor[2], iColor[3]);
		}
		
 		iWearable = this.CallFunction("CreateWeapon", 315, "tf_wearable", GetRandomInt(1, 100), TFQual_Normal, "");	//Blighted Beak
		if (iWearable > MaxClients)
		{
			SetEntProp(iWearable, Prop_Send, "m_nModelIndexOverrides", g_iUberRangerBlightedBeak);
			SetEntityRenderColor(iWearable, iColor[0], iColor[1], iColor[2], iColor[3]);
		}
			
		for (int i = 1; i <= MaxClients; i++)
			g_bUberRangerPlayerWasSummoned[i] = false;
	}
	
	public void GetModel(char[] sModel, int length)
	{
		strcopy(sModel, length, RANGER_MODEL);
	}
	
	public void OnRage()
	{
		int iTotalSummons = 1;
		if (this.bSuperRage) iTotalSummons = 3;
		
		float vecBossPos[3], vecBossAng[3];
		GetClientAbsOrigin(this.iClient, vecBossPos);
		GetClientAbsAngles(this.iClient, vecBossAng);
		vecBossAng[0] = 0.0;
		vecBossAng[2] = 0.0;
		
		//Create a lil effect
		CreateTimer(3.0, Timer_EntityCleanup, TF2_SpawnParticle(TF2_GetClientTeam(this.iClient) == TFTeam_Boss ? "teleportedin_blue" : "teleportedin_red", vecBossPos));
		EmitSoundToAll(RANGER_RAGESOUND, this.iClient);
		
		ArrayList aValidMinions = new ArrayList();
		for (int iClient = 1; iClient <= MaxClients; iClient++)
		{
			if (IsClientInGame(iClient)
				&& TF2_GetClientTeam(iClient) > TFTeam_Spectator
				&& !IsPlayerAlive(iClient)
				&& !g_bUberRangerPlayerWasSummoned[iClient]
				&& Preferences_Get(iClient, Preferences_Revival)
				&& !Client_HasFlag(iClient, ClientFlags_Punishment))
			{
				aValidMinions.Push(iClient);
			}
		}
		
		//Give priority to players who have the highest scores
		for (int iSelection = 0; iSelection < iTotalSummons; iSelection++)
		{
			int iBestClientIndex = -1;
			int iLength = aValidMinions.Length;
			int iBestScore = -1;
			
			for (int i = 0; i < iLength; i++)
			{
				int iClient = aValidMinions.Get(i);
				int iClientScore = SaxtonHale_GetScore(iClient);
				if (iClientScore > iBestScore)
				{
					iBestScore = iClientScore;
					iBestClientIndex = i;
				}
			}
			
			if (iBestClientIndex != -1)
			{
				int iClient = aValidMinions.Get(iBestClientIndex);
				
				//Allow them to join the boss team
				Client_AddFlag(iClient, ClientFlags_BossTeam);
				TF2_ForceTeamJoin(iClient, TFTeam_Boss);
				
				//Mark them as selected to not be included in future rages
				g_bUberRangerPlayerWasSummoned[iClient] = true;
				
				SaxtonHaleBase boss = SaxtonHaleBase(iClient);
				boss.CallFunction("CreateBoss", "CMinionRanger");
				TF2_RespawnPlayer(iClient);
				
				float vecVel[3];
				vecVel[0] = GetRandomFloat(-200.0, 200.0);
				vecVel[1] = GetRandomFloat(-200.0, 200.0);
				vecVel[2] = GetRandomFloat(-200.0, 200.0);
				
				TeleportEntity(iClient, vecBossPos, vecBossAng, vecVel);
				TF2_AddCondition(iClient, TFCond_Ubercharged, 2.0);
				
				aValidMinions.Erase(iBestClientIndex);
			}
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
	
	public void Precache()
	{
		PrecacheModel(RANGER_MODEL);
		
		g_iUberRangerPrussianPickelhaube = PrecacheModel("models/player/items/medic/medic_helmet.mdl");
		g_iUberRangerBlightedBeak = PrecacheModel("models/player/items/medic/medic_blighted_beak.mdl");
		
		PrepareSound(RANGER_THEME);
		PrecacheSound(RANGER_RAGESOUND);
		
		for (int i = 0; i < sizeof(g_strUberRangerRoundStart); i++) PrecacheSound(g_strUberRangerRoundStart[i]);
		for (int i = 0; i < sizeof(g_strUberRangerWin); i++) PrecacheSound(g_strUberRangerWin[i]);
		for (int i = 0; i < sizeof(g_strUberRangerLose); i++) PrecacheSound(g_strUberRangerLose[i]);
		for (int i = 0; i < sizeof(g_strUberRangerLastMan); i++) PrecacheSound(g_strUberRangerLastMan[i]);
		for (int i = 0; i < sizeof(g_strUberRangerBackStabbed); i++) PrecacheSound(g_strUberRangerBackStabbed[i]);
		for (int i = 0; i < sizeof(g_strUberRangerJump); i++) PrecacheSound(g_strUberRangerJump[i]);
		
		AddFileToDownloadsTable("materials/models/player/boss/uber_ranger/uberranger_backpack.vmt");
		AddFileToDownloadsTable("materials/models/player/boss/uber_ranger/uberranger_backpack.vtf");
		AddFileToDownloadsTable("materials/models/player/boss/uber_ranger/uberranger_body.vmt");
		AddFileToDownloadsTable("materials/models/player/boss/uber_ranger/uberranger_body.vtf");
		AddFileToDownloadsTable("materials/models/player/boss/uber_ranger/uberranger_head.vmt");
		AddFileToDownloadsTable("materials/models/player/boss/uber_ranger/uberranger_head.vtf");
		
		AddFileToDownloadsTable("models/player/vsh_rewrite/uber_ranger/uber_ranger.mdl");
		AddFileToDownloadsTable("models/player/vsh_rewrite/uber_ranger/uber_ranger.sw.vtx");
		AddFileToDownloadsTable("models/player/vsh_rewrite/uber_ranger/uber_ranger.vvd");
		AddFileToDownloadsTable("models/player/vsh_rewrite/uber_ranger/uber_ranger.phy");
		AddFileToDownloadsTable("models/player/vsh_rewrite/uber_ranger/uber_ranger.dx80.vtx");
		AddFileToDownloadsTable("models/player/vsh_rewrite/uber_ranger/uber_ranger.dx90.vtx");
	}
	
	public void Destroy()
	{
		SetEntityRenderColor(this.iClient, 255, 255, 255, 255);
	}
};

methodmap CMinionRanger < SaxtonHaleBase
{
	public CMinionRanger(CMinionRanger boss)
	{
		boss.iBaseHealth = 600;
		boss.iHealthPerPlayer = 0;
		boss.nClass = TFClass_Medic;
		boss.iMaxRageDamage = -1;
		boss.flWeighDownTimer = -1.0;
		boss.bCanBeHealed = true;
		boss.bMinion = true;
		
		EmitSoundToClient(boss.iClient, SOUND_ALERT);	//Alert player as he spawned
	}
	
	public bool IsBossHidden()
	{
		return true;
	}
	
	public void OnSpawn()
	{
		char sMedigunAttribs[128];
		Format(sMedigunAttribs, sizeof(sMedigunAttribs), "7 ; 0.4");
		this.CallFunction("CreateWeapon", 211, "tf_weapon_medigun", 10, TFQual_Collectors, sMedigunAttribs);
		
		/*
		Medigun attributes:
		
		7: slower heal rate
		*/
		
		char sSawAttribs[128];
		Format(sSawAttribs, sizeof(sSawAttribs), "2 ; 1.25 ; 5 ; 1.2 ; 17 ; 0.25 ; 252 ; 0.5 ; 259 ; 1.0");
		int iWeapon = this.CallFunction("CreateWeapon", 37, "tf_weapon_bonesaw", 10, TFQual_Collectors, sSawAttribs);
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
		
		int iColor[4];
		
		for (int i = 0; i < 3; i++)
			iColor[i] = GetRandomInt(10, 225);
			
		iColor[3] = 255;
		
		SetEntityRenderColor(this.iClient, iColor[0], iColor[1], iColor[2], iColor[3]);
		
		int iWearable = -1;
		
		iWearable = this.CallFunction("CreateWeapon", 50, "tf_wearable", GetRandomInt(1, 100), TFQual_Normal, "");	//Prussian Pickelhaube
		if (iWearable > MaxClients)
		{
			SetEntProp(iWearable, Prop_Send, "m_nModelIndexOverrides", g_iUberRangerPrussianPickelhaube);
			SetEntityRenderColor(iWearable, iColor[0], iColor[1], iColor[2], iColor[3]);
		}
		
		iWearable = this.CallFunction("CreateWeapon", 315, "tf_wearable", GetRandomInt(1, 100), TFQual_Normal, "");	//Blighted Beak
		if (iWearable > MaxClients)
		{
			SetEntProp(iWearable, Prop_Send, "m_nModelIndexOverrides", g_iUberRangerBlightedBeak);
			SetEntityRenderColor(iWearable, iColor[0], iColor[1], iColor[2], iColor[3]);
		}
	}
	
	public void GetModel(char[] sModel, int length)
	{
		strcopy(sModel, length, RANGER_MODEL);
	}
	
	public void Destroy()
	{
		SetEntityRenderColor(this.iClient, 255, 255, 255, 255);
	}
};	
