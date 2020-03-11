#define GENTLE_SPY_MODEL "models/freak_fortress_2/gentlespy/the_gentlespy_v1.mdl"
#define GENTLE_SPY_THEME "vsh_rewrite/gentlespy/gentle_music.mp3"

static bool g_bFirstCloak[TF_MAXPLAYERS+1];
static bool g_bIsCloaked[TF_MAXPLAYERS+1];

static char g_strGentleSpyRoundStart[][] = {
	"vo/spy_cloakedspy01.mp3",
	"vo/spy_mvm_resurrect01.mp3"
};

static char g_strGentleSpyWin[][] = {
	"vo/spy_goodjob01.mp3",
	"vo/spy_mvm_loot_common01.mp3",
	"vo/spy_positivevocalization01.mp3",
	"vo/spy_rpswin01.mp3",
	"vo/compmode/cm_spy_pregamewonlast_10.mp3",
	"vo/taunts/spy_taunts12.mp3",
	"vo/toughbreak/spy_quest_complete_easy_07.mp3"
};

static char g_strGentleSpyLose[][] = {
	"vo/spy_jeers02.mp3",
	"vo/spy_jeers04.mp3"
};

static char g_strGentleSpyRage[][] = {
	"vo/spy_stabtaunt02.mp3",
	"vo/spy_stabtaunt06.mp3",
	"vo/taunts/spy_highfive05.mp3"
};

static char g_strGentleSpyKill[][] = {
	"vo/spy_jaratehit03.mp3",
	"vo/spy_laughevil02.mp3",
	"vo/spy_laughshort06.mp3",
	"vo/spy_specialcompleted04.mp3",
	"vo/spy_specialcompleted11.mp3",
	"vo/taunts/spy_taunts13.mp3",
	"vo/taunts/spy_taunts15.mp3"
};

static char g_strGentleSpyLastMan[][] = {
	"vo/spy_stabtaunt02.mp3",
	"vo/spy_stabtaunt14.mp3",
	"vo/spy_stabtaunt16.mp3",
	"vo/spy_revenge01.mp3",
	"vo/taunts/spy_highfive13.mp3",
	"vo/taunts/spy_taunts07.mp3",
	"vo/taunts/spy_taunts10.mp3",
	"vo/taunts/spy_taunts11.mp3"
};

static char g_strGentleSpyBackStabbed[][] = {
	"vo/spy_jeers06.mp3",
	"vo/spy_negativevocalization02.mp3",
	"vo/spy_sf13_magic_reac03.mp3"
};

static TFCond g_nGentleSpyCloak[] = {
	TFCond_OnFire,
	TFCond_Bleeding,
	TFCond_Milked,
	TFCond_Gas,
};

methodmap CGentleSpy < SaxtonHaleBase
{
	public CGentleSpy(CGentleSpy boss)
	{
		boss.iBaseHealth = 700;
		boss.iHealthPerPlayer = 650;
		boss.nClass = TFClass_Spy;
		boss.iMaxRageDamage = 2000;
		
		g_bFirstCloak[boss.iClient] = false;
		g_bIsCloaked[boss.iClient] = false;
	}
	
	public void GetBossName(char[] sName, int length)
	{
		strcopy(sName, length, "Gentle Spy");
	}
	
	public void GetBossInfo(char[] sInfo, int length)
	{
		StrCat(sInfo, length, "\nHealth: Low");
		StrCat(sInfo, length, "\n ");
		StrCat(sInfo, length, "\nAbilities");
		StrCat(sInfo, length, "\n- Passive Invis Watch");
		StrCat(sInfo, length, "\n- Super fast speed and high jump during cloak");
		StrCat(sInfo, length, "\n ");
		StrCat(sInfo, length, "\nRage");
		StrCat(sInfo, length, "\n- Adds cloak meter to 50%%");
		StrCat(sInfo, length, "\n- Ambassador with high damage and penetrates");
		StrCat(sInfo, length, "\n- 200%% Rage: Sets cloak meter to 100%%");
	}
	
	public void OnSpawn()
	{
		int iClient = this.iClient;
		int iWeapon;
		char attribs[128];
		
		Format(attribs, sizeof(attribs), "2 ; 8.0 ; 4 ; 1.34 ; 37 ; 0.0 ; 106 ; 0.0 ; 117 ; 0.0 ; 389 ; 1.0");
		iWeapon = this.CallFunction("CreateWeapon", 61, "tf_weapon_revolver", 100, TFQual_Collectors, attribs);
		if (iWeapon > MaxClients)
		{
			SetEntProp(iWeapon, Prop_Send, "m_iClip1", 0);
			SetEntProp(iClient, Prop_Send, "m_iAmmo", 0, _, 2);
		}
		/*
		Ambassador attributes:
		
		2: Damage bonus
		4: Clip size
		37: mult_maxammo_primary
		106: More accurate
		117: Attrib_Dmg_Falloff_Increased	//Doesnt even work thanks valve
		389: Shot penetrates
		*/
		
		Format(attribs, sizeof(attribs), "83 ; 0.33 ; 85 ; 0.0 ; 221 ; 0.5");
		iWeapon = this.CallFunction("CreateWeapon", 30, "tf_weapon_invis", 100, TFQual_Collectors, attribs);
		if (iWeapon > MaxClients)
			SetEntPropFloat(iClient, Prop_Send, "m_flCloakMeter", 0.0);
		/*
		Invis Watch attributes:
		
		83: cloak duration
		85: cloak regeneration rate
		221: Attrib_DecloakRate
		*/
		
		Format(attribs, sizeof(attribs), "2 ; 4.55 ; 252 ; 0.5 ; 259 ; 1.0");
		iWeapon = this.CallFunction("CreateWeapon", 194, "tf_weapon_knife", 100, TFQual_Collectors, attribs);
		if (iWeapon > MaxClients)
			SetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon", iWeapon);
		/*
		Knife attributes:
		
		2: damage bonus
		252: reduction in push force taken from damage
		259: Deals 3x falling damage to the player you land on
		*/
	}
	
	public void GetModel(char[] sModel, int length)
	{
		strcopy(sModel, length, GENTLE_SPY_MODEL);
	}
	
	public void GetSound(char[] sSound, int length, SaxtonHaleSound iSoundType)
	{
		switch (iSoundType)
		{
			case VSHSound_RoundStart: strcopy(sSound, length, g_strGentleSpyRoundStart[GetRandomInt(0,sizeof(g_strGentleSpyRoundStart)-1)]);
			case VSHSound_Win: strcopy(sSound, length, g_strGentleSpyWin[GetRandomInt(0,sizeof(g_strGentleSpyWin)-1)]);
			case VSHSound_Lose: strcopy(sSound, length, g_strGentleSpyLose[GetRandomInt(0,sizeof(g_strGentleSpyLose)-1)]);
			case VSHSound_Rage: strcopy(sSound, length, g_strGentleSpyRage[GetRandomInt(0,sizeof(g_strGentleSpyRage)-1)]);
			case VSHSound_Lastman: strcopy(sSound, length, g_strGentleSpyLastMan[GetRandomInt(0,sizeof(g_strGentleSpyLastMan)-1)]);
			case VSHSound_Backstab: strcopy(sSound, length, g_strGentleSpyBackStabbed[GetRandomInt(0,sizeof(g_strGentleSpyBackStabbed)-1)]);
		}
	}
	
	public void GetSoundKill(char[] sSound, int length, TFClassType nClass)
	{
		strcopy(sSound, length, g_strGentleSpyKill[GetRandomInt(0,sizeof(g_strGentleSpyKill)-1)]);
	}
	
	public void GetMusicInfo(char[] sSound, int length, float &time)
	{
		strcopy(sSound, length, GENTLE_SPY_THEME);
		time = 148.0;
	}
	
	public Action OnSoundPlayed(int clients[MAXPLAYERS], int &numClients, char sample[PLATFORM_MAX_PATH], int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
	{
		//Block sounds if cloaked
		if (TF2_IsPlayerInCondition(this.iClient, TFCond_Cloaked) || TF2_IsPlayerInCondition(this.iClient, TFCond_CloakFlicker))
			return Plugin_Handled;
		return Plugin_Continue;
	}
	
	public void OnRage()
	{
		int iClient = this.iClient;
		
		//Give cloak mater
		float flCloak;
		if (this.bSuperRage)
		{
			flCloak = 100.0;
		}
		else
		{
			flCloak = GetEntPropFloat(iClient, Prop_Send, "m_flCloakMeter");
			flCloak += 50.0;
			if (flCloak > 100.0) flCloak = 100.0;
		}
		
		SetEntPropFloat(iClient, Prop_Send, "m_flCloakMeter", flCloak);
		
		int iPlayerCount = SaxtonHale_GetAliveAttackPlayers();
		
		//Add ammo to primary weapon
		int iPrimaryWep = GetPlayerWeaponSlot(iClient, WeaponSlot_Primary);
		if (IsValidEntity(iPrimaryWep))
		{
			int iClip = GetEntProp(iPrimaryWep, Prop_Send, "m_iClip1");
			iClip += (2 + RoundToFloor(iPlayerCount / 8.0));
			if (iClip > 8)
				iClip = 8;
			SetEntProp(iPrimaryWep, Prop_Send, "m_iClip1", iClip);
			SetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon", iPrimaryWep);
		}
	}
	
	public void OnThink()
	{
		int iClient = this.iClient;
		
		float flCloak = GetEntPropFloat(iClient, Prop_Send, "m_flCloakMeter");
		if (flCloak < 0.5) flCloak = 0.0;
		
		//Cloak regen rate attribute didnt take into effect until proper cloak done, shitty temp fix below aeiou
		if (!g_bFirstCloak[iClient])
		{
			if (flCloak > 75.0)
				flCloak = 100.0;
			else if (flCloak > 25.0)
				flCloak = 50.0;
			else
				flCloak = 0.0;
			
			SetEntPropFloat(iClient, Prop_Send, "m_flCloakMeter", flCloak);
		}
				
		if (TF2_IsPlayerInCondition(iClient, TFCond_Cloaked) || TF2_IsPlayerInCondition(iClient, TFCond_CloakFlicker))
		{	
			if (!g_bIsCloaked[iClient])
			{
				//Cloak started
				g_bFirstCloak[iClient] = true;
				g_bIsCloaked[iClient] = true;
				this.flSpeed *= 1.4;
				//TF2_AddCondition(iClient, TFCond_DefenseBuffMmmph, -1.0);

				int iInvisWatch = GetPlayerWeaponSlot(iClient, WeaponSlot_InvisWatch);
				if (iInvisWatch > MaxClients && IsValidEntity(iInvisWatch))
					TF2Attrib_SetByDefIndex(iInvisWatch, ATTRIB_JUMP_HEIGHT, 3.0);
			}
			
			//Remove all cond in the list if have one
			for (int i = 0; i < sizeof(g_nGentleSpyCloak); i++)
				if (TF2_IsPlayerInCondition(iClient, g_nGentleSpyCloak[i]))
					TF2_RemoveCondition(iClient, g_nGentleSpyCloak[i]);
		}
		else
		{					
			if (g_bIsCloaked[iClient])
			{
				//Cloak ended
				g_bIsCloaked[iClient] = false;
				this.flSpeed /= 1.4;
				//TF2_RemoveCondition(iClient, TFCond_DefenseBuffMmmph);
				
				int iInvisWatch = GetPlayerWeaponSlot(iClient, WeaponSlot_InvisWatch);
				if (iInvisWatch > MaxClients && IsValidEntity(iInvisWatch))
					TF2Attrib_RemoveByDefIndex(iInvisWatch, ATTRIB_JUMP_HEIGHT);
			}
		}
		
		//Hud
		if (GameRules_GetRoundState() == RoundState_Preround) return;
		
		char sMessage[256];
		Format(sMessage, sizeof(sMessage), "%0.0f%%%% Cloak", flCloak);
		if (flCloak > 99.5)
			Format(sMessage, sizeof(sMessage), "%s: You can use cloak!", sMessage);
		else if (flCloak < 10.5)
			Format(sMessage, sizeof(sMessage), "%s: Gain cloak by using rage!", sMessage);
		
		int iColor[4];
		iColor[0] = RoundToNearest(2.55 * (100.0 - flCloak));
		iColor[1] = 255;
		iColor[2] = RoundToNearest(2.55 * (100.0 - flCloak));
		iColor[3] = 255;
		
		Hud_AddText(iClient, sMessage);
		Hud_SetColor(iClient, iColor);
	}
	
	public Action OnAttackDamage(int victim, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
	{
		if (damagetype & DMG_FALL && TF2_IsPlayerInCondition(this.iClient, TFCond_Cloaked))
		{
			return Plugin_Stop;
		}
		
		return Plugin_Continue;
	}
	
	public void OnButton(int &buttons)
	{
		int iClient = this.iClient;
		
		//Prevent boss from uncloaking while in air
		if (buttons & IN_ATTACK2 && TF2_IsPlayerInCondition(iClient, TFCond_Cloaked))
		{
			if (!(GetEntityFlags(iClient) & FL_ONGROUND) || !(GetEntProp(iClient, Prop_Send, "m_fFlags") & FL_ONGROUND))
				buttons -= IN_ATTACK2;
		}
	}
	
	public void Destroy()
	{
		int iClient = this.iClient;
		
		g_bFirstCloak[iClient] = false;
		g_bIsCloaked[iClient] = false;
	}
	
	public void Precache()
	{
		PrecacheModel(GENTLE_SPY_MODEL);
		
		PrepareSound(GENTLE_SPY_THEME);
		
		for (int i = 0; i < sizeof(g_strGentleSpyRoundStart); i++) PrecacheSound(g_strGentleSpyRoundStart[i]);
		for (int i = 0; i < sizeof(g_strGentleSpyWin); i++) PrecacheSound(g_strGentleSpyWin[i]);
		for (int i = 0; i < sizeof(g_strGentleSpyLose); i++) PrecacheSound(g_strGentleSpyLose[i]);
		for (int i = 0; i < sizeof(g_strGentleSpyRage); i++) PrecacheSound(g_strGentleSpyRage[i]);
		for (int i = 0; i < sizeof(g_strGentleSpyKill); i++) PrecacheSound(g_strGentleSpyKill[i]);
		for (int i = 0; i < sizeof(g_strGentleSpyLastMan); i++) PrecacheSound(g_strGentleSpyLastMan[i]);
		for (int i = 0; i < sizeof(g_strGentleSpyBackStabbed); i++) PrecacheSound(g_strGentleSpyBackStabbed[i]);
		
		AddFileToDownloadsTable("materials/freak_fortress_2/gentlespy_tex/stylish_spy_blue.vmt");
		AddFileToDownloadsTable("materials/freak_fortress_2/gentlespy_tex/stylish_spy_blue.vtf");
		AddFileToDownloadsTable("materials/freak_fortress_2/gentlespy_tex/stylish_spy_blue_invun.vmt");
		AddFileToDownloadsTable("materials/freak_fortress_2/gentlespy_tex/stylish_spy_blue_invun.vtf");
		AddFileToDownloadsTable("materials/freak_fortress_2/gentlespy_tex/stylish_spy_normal.vtf");
		
		AddFileToDownloadsTable("models/freak_fortress_2/gentlespy/the_gentlespy_v1.mdl");
		AddFileToDownloadsTable("models/freak_fortress_2/gentlespy/the_gentlespy_v1.sw.vtx");
		AddFileToDownloadsTable("models/freak_fortress_2/gentlespy/the_gentlespy_v1.vvd");
		AddFileToDownloadsTable("models/freak_fortress_2/gentlespy/the_gentlespy_v1.dx80.vtx");
		AddFileToDownloadsTable("models/freak_fortress_2/gentlespy/the_gentlespy_v1.dx90.vtx");
	}
};