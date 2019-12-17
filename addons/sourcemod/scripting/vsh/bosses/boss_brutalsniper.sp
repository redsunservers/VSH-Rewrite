#define BRUTALSNIPER_MODEL "models/player/saxton_hale/cbs_v4.mdl"
#define BRUTALSNIPER_THEME "vsh_rewrite/brutalsniper/brutalsniper_music.mp3"
#define BRUTALSNIPER_MAXWEAPONS 4

#define ITEM_KUKRI			3
#define ITEM_TRIBALMAN_SHIV	171
#define ITEM_BUSHWACKA		232
#define ITEM_SHAHANSHAH		401

static int g_iBrutalSniperWeaponCooldown[TF_MAXPLAYERS+1][BRUTALSNIPER_MAXWEAPONS];

static char g_strBrutalSniperRoundStart[][] = {
	"vo/sniper_specialweapon08.mp3"
};

static char g_strBrutalSniperWin[][] = {
	"vo/sniper_award09.mp3",
	"vo/sniper_award12.mp3"
};

static char g_strBrutalSniperLose[][] = {
	"vo/sniper_autodejectedtie02.mp3",
	"vo/sniper_jeers01.mp3"
};

static char g_strBrutalSniperRage[][] = {
	"vo/sniper_battlecry03.mp3"
};

static char g_strBrutalSniperJump[][] = {
	"vo/sniper_jaratetoss01.mp3",
	"vo/sniper_jaratetoss02.mp3",
	"vo/sniper_specialcompleted11.mp3",
	"vo/sniper_specialcompleted19.mp3"
};

static char g_strBrutalSniperKill[][] = {
	"vo/sniper_award01.mp3",
	"vo/sniper_award02.mp3",
	"vo/sniper_award03.mp3",
	"vo/sniper_award05.mp3",
	"vo/sniper_award07.mp3",
	"vo/sniper_positivevocalization03.mp3",
	"vo/sniper_specialcompleted04.mp3",
	"vo/taunts/sniper_taunts02.mp3"
};

static char g_strBrutalSniperKillPrimary[][] = {
	"vo/sniper_niceshot01.mp3",
	"vo/sniper_niceshot02.mp3",
	"vo/sniper_niceshot03.mp3"
};

static char g_strBrutalSniperKillMelee[][] = {
	"vo/sniper_meleedare01.mp3",
	"vo/sniper_meleedare02.mp3",
	"vo/sniper_meleedare05.mp3",
	"vo/sniper_meleedare07.mp3"
};

static char g_strBrutalSniperLastMan[][] = {
	"vo/sniper_award11.mp3",
	"vo/sniper_domination02.mp3",
	"vo/sniper_domination03.mp3",
	"vo/sniper_domination18.mp3"
};

static char g_strBrutalSniperBackStabbed[][] = {
	"vo/sniper_jeers03.mp3",
	"vo/sniper_jeers05.mp3",
	"vo/sniper_jeers08.mp3",
	"vo/sniper_negativevocalization02.mp3"
};

methodmap CBrutalSniper < SaxtonHaleBase
{
	public CBrutalSniper(CBrutalSniper boss)
	{
		boss.CallFunction("CreateAbility", "CBraveJump");
		
		CScareRage scareAbility = boss.CallFunction("CreateAbility", "CScareRage");
		scareAbility.flRadius = 200.0;
		
		boss.iBaseHealth = 800;
		boss.iHealthPerPlayer = 800;
		boss.nClass = TFClass_Sniper;
		boss.iMaxRageDamage = 2500;
	}
	
	public void GetBossName(char[] sName, int length)
	{
		strcopy(sName, length, "Christian Brutal Sniper");
	}
	
	public void GetBossInfo(char[] sInfo, int length)
	{
		StrCat(sInfo, length, "\nHealth: Medium");
		StrCat(sInfo, length, "\n ");
		StrCat(sInfo, length, "\nAbilities");
		StrCat(sInfo, length, "\n- Brave Jump");
		StrCat(sInfo, length, "\n- Changes your melee to a random knife on melee kill");
		StrCat(sInfo, length, "\n  - Kukri: Default");
		StrCat(sInfo, length, "\n  - Tribalman Shiv: 10 seconds bleed, 15%% dmg penalty");
		StrCat(sInfo, length, "\n  - Bushwacka: Always crit, 20%% dmg vulnerability");
		StrCat(sInfo, length, "\n  - Shahanshah: +15%% dmg when <50%% health, -15%% dmg when >50%% health");
		StrCat(sInfo, length, "\n ");
		StrCat(sInfo, length, "\nRage");
		StrCat(sInfo, length, "\n- Huntsman with high damage and faster charge time");
		StrCat(sInfo, length, "\n- Scares players at small range for 5 seconds");
		StrCat(sInfo, length, "\n- 200%% Rage: larger scare range and extends duration to 7.5 seconds");
	}
	
	public void OnSpawn()
	{
		int iClient = this.iClient;
		int iWeapon;
		char attribs[128];
		
		Format(attribs, sizeof(attribs), "2 ; 2.1 ; 6 ; 0.3 ; 280 ; 19 ; 551 ; 1.0");
		iWeapon = this.CallFunction("CreateWeapon", 56, "tf_weapon_compound_bow", 100, TFQual_Collectors, attribs);
		if (IsValidEntity(iWeapon)) 
		{
			SetEntProp(iWeapon, Prop_Send, "m_iClip1", 0);
			SetEntProp(iClient, Prop_Send, "m_iAmmo", 0, _, 1);
		}
		/*
		Huntsman attributes:
		
		2: Damage bonus
		6: faster firing speed
		280: override_projectile_type
		551: special_taunt
		*/
		
		g_iBrutalSniperWeaponCooldown[this.iClient][0] = BRUTALSNIPER_MAXWEAPONS - 2;	//Kukri
		Format(attribs, sizeof(attribs), "2 ; 2.80 ; 252 ; 0.5 ; 259 ; 1.0");
		iWeapon = this.CallFunction("CreateWeapon", ITEM_KUKRI, "tf_weapon_club", 100, TFQual_Collectors, attribs);
		if (iWeapon > MaxClients)
			SetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon", iWeapon);
		/*
		Kukri attributes:
		
		2: damage bonus
		252: reduction in push force taken from damage
		259: Deals 3x falling damage to the player you land on
		*/
	}
	
	public void OnPlayerKilled(Event event, int iVictim)
	{
		int iClient = this.iClient;
		
		char sWeapon[50];
		event.GetString("weapon", sWeapon, sizeof(sWeapon));
		
		//Check if player is killed from Sniper's melee or bleed
		if (StrContains(sWeapon, "club", false) != -1
			|| StrContains(sWeapon, "kukri", false) != -1
			|| StrContains(sWeapon, "bleed", false) != -1
			|| StrContains(sWeapon, "bushwacka", false) != -1
			|| StrContains(sWeapon, "shahanshah", false) != -1)
		{
			//Check if it a valid attack player
			if (SaxtonHale_IsValidAttack(iVictim))
			{
				//Remove Sniper's melee weapon and generate a new one
				TF2_RemoveItemInSlot(iClient, WeaponSlot_Melee);
				
				int iRandom = -1;
				int iIndex;
				//Get a random melee weapon thats not in cooldown
				while (iRandom == -1)
				{					
					iRandom = GetRandomInt(0, (BRUTALSNIPER_MAXWEAPONS - 1));
					
					//Check if that weapon is not in cooldown
					if (g_iBrutalSniperWeaponCooldown[iClient][iRandom] == 0)
						g_iBrutalSniperWeaponCooldown[iClient][iRandom] = BRUTALSNIPER_MAXWEAPONS - 1;	//Give new cooldown
					else
						iRandom = -1;	//Try find another number
				}
				
				//Reduce all melee cooldown
				for (int i = 0; i < BRUTALSNIPER_MAXWEAPONS; i++)
					if (g_iBrutalSniperWeaponCooldown[iClient][i] > 0)
						g_iBrutalSniperWeaponCooldown[iClient][i] --;
				
				//Attribute for all melee weapons
				char attribs[128];
				Format(attribs, sizeof(attribs), "2 ; 2.80 ; 252 ; 0.5 ; 259 ; 1.0");
				
				//Get new melee from random
				switch (iRandom)
				{
					case 0: 
					{
						iIndex = ITEM_KUKRI;
						//Default weapon, no extra attributes
					}
					case 1:
					{
						iIndex = ITEM_TRIBALMAN_SHIV;
						Format(attribs, sizeof(attribs), "%s ; 1 ; 0.85 ; 149 ; 10.0", attribs);
						//1: damage penalty
						//149: On Hit: Bleed
					}
					case 2:
					{
						iIndex = ITEM_BUSHWACKA;
						Format(attribs, sizeof(attribs), "%s ; 412 ; 1.2", attribs);
						//412: damage vulnerability on wearer
					}
					case 3:
					{
						iIndex = ITEM_SHAHANSHAH;
						Format(attribs, sizeof(attribs), "%s ; 224 ; 1.15 ; 225 ; 0.85", attribs);
						//224: increase in damage when health <50% of max
						//225: decrease in damage when health >50% of max
					}
				}
				
				if (iIndex <= 0) return;
				
				//Generate new melee weapon
				int iNewMelee = this.CallFunction("CreateWeapon", iIndex, "tf_weapon_club", 100, TFQual_Unusual, attribs);
				if (iNewMelee > MaxClients)
				{
					//Check if his active weapon got removed, if so set as that weapon
					int iActiveWep = GetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon");
					if (!(IsValidEntity(iActiveWep)))
						SetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon", iNewMelee);
				}
			}
		}
	}
	
	public void OnThink()
	{
		int iClient = this.iClient;
		
		int iActiveWeapon = GetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon");
		
		//Crit if holding Bushwacka
		if (IsValidEntity(iActiveWeapon) && GetEntProp(iActiveWeapon, Prop_Send, "m_iItemDefinitionIndex") == ITEM_BUSHWACKA)
			TF2_AddCondition(iClient, TFCond_CritOnDamage, 0.05);
		
		char sMessage[255];
		int iColor[4];
		
		int iWeapon = TF2_GetItemInSlot(iClient, WeaponSlot_Melee);
		
		if (iWeapon <= MaxClients) return;
		
		int iIndex = GetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex");
		switch(iIndex)
		{
			case ITEM_KUKRI:
			{
				Format(sMessage, sizeof(sMessage), "Kukri: Default");
				iColor[0] = 192; iColor[1] = 192; iColor[2] = 192;
			}
			case ITEM_TRIBALMAN_SHIV:
			{
				Format(sMessage, sizeof(sMessage), "Tribalman Shiv: 10 seconds bleed, 15%% dmg penalty");
				iColor[0] = 192; iColor[1] = 32; iColor[2] = 0;
			}
			case ITEM_BUSHWACKA:
			{
				Format(sMessage, sizeof(sMessage), "Bushwacka: Always crit, 20%% dmg vulnerability");
				iColor[0] = 224; iColor[1] = 160; iColor[2] = 0;
			}
			case ITEM_SHAHANSHAH:
			{
				Format(sMessage, sizeof(sMessage), "Shahanshah: +15%% dmg when <50%% health, -15%% dmg when >50%% health");
				iColor[0] = 144; iColor[1] = 92; iColor[2] = 0;
			}
		}
		
		iColor[3] = 255;
		
		Hud_AddText(iClient, sMessage);
		Hud_SetColor(iClient, iColor);
	}
	
	public void OnRage()
	{
		int iClient = this.iClient;
		int iPlayerCount = SaxtonHale_GetAliveAttackPlayers();
		
		//Add ammo to huntsman
		int iPrimaryWep = GetPlayerWeaponSlot(iClient, WeaponSlot_Primary);
		if (IsValidEntity(iPrimaryWep))
		{
			int iAmmo = GetEntProp(iClient, Prop_Send, "m_iAmmo", _, 1);
			iAmmo += (1 + RoundToFloor(iPlayerCount / 4.0));
			if (iAmmo > 6)
				iAmmo = 6;
			SetEntProp(iClient, Prop_Send, "m_iAmmo", iAmmo, _, 1);
			SetEntProp(iPrimaryWep, Prop_Send, "m_iClip1", 1);
			SetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon", iPrimaryWep);
		}
	}
	
	public void GetModel(char[] sModel, int length)
	{
		strcopy(sModel, length, BRUTALSNIPER_MODEL);
	}
	
	public void GetSound(char[] sSound, int length, SaxtonHaleSound iSoundType)
	{
		switch (iSoundType)
		{
			case VSHSound_RoundStart: strcopy(sSound, length, g_strBrutalSniperRoundStart[GetRandomInt(0,sizeof(g_strBrutalSniperRoundStart)-1)]);
			case VSHSound_Win: strcopy(sSound, length, g_strBrutalSniperWin[GetRandomInt(0,sizeof(g_strBrutalSniperWin)-1)]);
			case VSHSound_Lose: strcopy(sSound, length, g_strBrutalSniperLose[GetRandomInt(0,sizeof(g_strBrutalSniperLose)-1)]);
			case VSHSound_Rage: strcopy(sSound, length, g_strBrutalSniperRage[GetRandomInt(0,sizeof(g_strBrutalSniperRage)-1)]);
			case VSHSound_Lastman: strcopy(sSound, length, g_strBrutalSniperLastMan[GetRandomInt(0,sizeof(g_strBrutalSniperLastMan)-1)]);
			case VSHSound_Backstab: strcopy(sSound, length, g_strBrutalSniperBackStabbed[GetRandomInt(0,sizeof(g_strBrutalSniperBackStabbed)-1)]);
		}
	}
	
	public void GetSoundAbility(char[] sSound, int length, const char[] sType)
	{
		if (strcmp(sType, "CBraveJump") == 0)
			strcopy(sSound, length, g_strBrutalSniperJump[GetRandomInt(0,sizeof(g_strBrutalSniperJump)-1)]);
	}
	
	public void GetSoundKill(char[] sSound, int length, TFClassType nClass)
	{
		int iClient = this.iClient;
		int iPrimary = GetPlayerWeaponSlot(iClient, WeaponSlot_Primary);
		int iMelee = GetPlayerWeaponSlot(iClient, WeaponSlot_Melee);
		int iActiveWep = GetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon");
		
		if (iActiveWep == iPrimary && GetRandomInt(0, 1))
			strcopy(sSound, length, g_strBrutalSniperKillPrimary[GetRandomInt(0,sizeof(g_strBrutalSniperKillPrimary)-1)]);
		else if (iActiveWep == iMelee && GetRandomInt(0, 3))
			strcopy(sSound, length, g_strBrutalSniperKillMelee[GetRandomInt(0,sizeof(g_strBrutalSniperKillMelee)-1)]);
		else
			strcopy(sSound, length, g_strBrutalSniperKill[GetRandomInt(0,sizeof(g_strBrutalSniperKill)-1)]);
	}
	
	public void GetMusicInfo(char[] sSound, int length, float &time)
	{
		strcopy(sSound, length, BRUTALSNIPER_THEME);
		time = 132.0;
	}
	
	public void Precache()
	{
		PrecacheModel(BRUTALSNIPER_MODEL);
		
		PrepareSound(BRUTALSNIPER_THEME);
		
		for (int i = 0; i < sizeof(g_strBrutalSniperRoundStart); i++) PrecacheSound(g_strBrutalSniperRoundStart[i]);
		for (int i = 0; i < sizeof(g_strBrutalSniperWin); i++) PrecacheSound(g_strBrutalSniperWin[i]);
		for (int i = 0; i < sizeof(g_strBrutalSniperLose); i++) PrecacheSound(g_strBrutalSniperLose[i]);
		for (int i = 0; i < sizeof(g_strBrutalSniperRage); i++) PrecacheSound(g_strBrutalSniperRage[i]);
		for (int i = 0; i < sizeof(g_strBrutalSniperJump); i++) PrecacheSound(g_strBrutalSniperJump[i]);
		for (int i = 0; i < sizeof(g_strBrutalSniperKill); i++) PrecacheSound(g_strBrutalSniperKill[i]);
		for (int i = 0; i < sizeof(g_strBrutalSniperKillPrimary); i++) PrecacheSound(g_strBrutalSniperKillPrimary[i]);
		for (int i = 0; i < sizeof(g_strBrutalSniperKillMelee); i++) PrecacheSound(g_strBrutalSniperKillMelee[i]);
		for (int i = 0; i < sizeof(g_strBrutalSniperLastMan); i++) PrecacheSound(g_strBrutalSniperLastMan[i]);
		for (int i = 0; i < sizeof(g_strBrutalSniperBackStabbed); i++) PrecacheSound(g_strBrutalSniperBackStabbed[i]);
		
		AddFileToDownloadsTable("materials/models/player/saxton_hale/sniper_head.vtf");
		AddFileToDownloadsTable("materials/models/player/saxton_hale/sniper_head_red.vmt");
		AddFileToDownloadsTable("materials/models/player/saxton_hale/sniper_lens.vmt");
		AddFileToDownloadsTable("materials/models/player/saxton_hale/sniper_lens.vtf");
		AddFileToDownloadsTable("materials/models/player/saxton_hale/sniper_red.vmt");
		AddFileToDownloadsTable("materials/models/player/saxton_hale/sniper_red.vtf");
		
		AddFileToDownloadsTable("models/player/saxton_hale/cbs_v4.mdl");
		AddFileToDownloadsTable("models/player/saxton_hale/cbs_v4.phy");
		AddFileToDownloadsTable("models/player/saxton_hale/cbs_v4.sw.vtx");
		AddFileToDownloadsTable("models/player/saxton_hale/cbs_v4.vvd");
		AddFileToDownloadsTable("models/player/saxton_hale/cbs_v4.dx80.vtx");
		AddFileToDownloadsTable("models/player/saxton_hale/cbs_v4.dx90.vtx");
	}
};