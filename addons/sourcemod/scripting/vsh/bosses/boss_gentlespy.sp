#define GENTLE_SPY_MODEL "models/freak_fortress_2/gentlespy/the_gentlespy_v1.mdl"
#define GENTLE_SPY_THEME "vsh_rewrite/gentlespy/gentle_music.mp3"

static bool g_bFirstCloak[MAXPLAYERS];
static bool g_bIsCloaked[MAXPLAYERS];

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

public void GentleSpy_Create(SaxtonHaleBase boss)
{
	boss.iHealthPerPlayer = 600;
	boss.flHealthExponential = 1.05;
	boss.nClass = TFClass_Spy;
	boss.iMaxRageDamage = 2000;
	
	g_bFirstCloak[boss.iClient] = false;
	g_bIsCloaked[boss.iClient] = false;
}

public void GentleSpy_GetBossName(SaxtonHaleBase boss, char[] sName, int length)
{
	strcopy(sName, length, "Gentle Spy");
}

public void GentleSpy_GetBossInfo(SaxtonHaleBase boss, char[] sInfo, int length)
{
	StrCat(sInfo, length, "\nHealth: Medium");
	StrCat(sInfo, length, "\n ");
	StrCat(sInfo, length, "\nAbilities");
	StrCat(sInfo, length, "\n- Passive Invis Watch");
	StrCat(sInfo, length, "\n- Super fast speed and high jump during cloak");
	StrCat(sInfo, length, "\n ");
	StrCat(sInfo, length, "\nRage");
	StrCat(sInfo, length, "\n- Damage requirement: 2000");
	StrCat(sInfo, length, "\n- Adds 50%% to cloak meter");
	StrCat(sInfo, length, "\n- Ambassador with high damage and penetrates");
	StrCat(sInfo, length, "\n- 200%% Rage: Sets cloak meter to 100%%");
}

public void GentleSpy_OnSpawn(SaxtonHaleBase boss)
{
	int iClient = boss.iClient;
	int iWeapon;
	char attribs[128];
	
	Format(attribs, sizeof(attribs), "2 ; 8.0 ; 4 ; 1.34 ; 37 ; 0.0 ; 106 ; 0.0 ; 117 ; 0.0 ; 389 ; 1.0");
	iWeapon = boss.CallFunction("CreateWeapon", 61, "tf_weapon_revolver", 100, TFQual_Collectors, attribs);
	if (iWeapon > MaxClients)
	{
		SetEntProp(iWeapon, Prop_Send, "m_iClip1", 0);
		TF2_SetAmmo(iClient, TF_AMMO_SECONDARY, 0);
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
	iWeapon = boss.CallFunction("CreateWeapon", 30, "tf_weapon_invis", 100, TFQual_Collectors, attribs);
	if (iWeapon > MaxClients)
		SetEntPropFloat(iClient, Prop_Send, "m_flCloakMeter", 0.0);
	/*
	Invis Watch attributes:
	
	83: cloak duration
	85: cloak regeneration rate
	221: Attrib_DecloakRate
	*/
	
	Format(attribs, sizeof(attribs), "2 ; 4.55 ; 252 ; 0.5 ; 259 ; 1.0");
	iWeapon = boss.CallFunction("CreateWeapon", 194, "tf_weapon_knife", 100, TFQual_Collectors, attribs);
	if (iWeapon > MaxClients)
		SetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon", iWeapon);
	/*
	Knife attributes:
	
	2: damage bonus
	252: reduction in push force taken from damage
	259: Deals 3x falling damage to the player you land on
	*/
}

public void GentleSpy_GetModel(SaxtonHaleBase boss, char[] sModel, int length)
{
	strcopy(sModel, length, GENTLE_SPY_MODEL);
}

public void GentleSpy_GetSound(SaxtonHaleBase boss, char[] sSound, int length, SaxtonHaleSound iSoundType)
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

public void GentleSpy_GetSoundKill(SaxtonHaleBase boss, char[] sSound, int length, TFClassType nClass)
{
	strcopy(sSound, length, g_strGentleSpyKill[GetRandomInt(0,sizeof(g_strGentleSpyKill)-1)]);
}

public void GentleSpy_GetMusicInfo(SaxtonHaleBase boss, char[] sSound, int length, float &time)
{
	strcopy(sSound, length, GENTLE_SPY_THEME);
	time = 148.0;
}

public Action GentleSpy_OnSoundPlayed(SaxtonHaleBase boss, int clients[MAXPLAYERS], int &numClients, char sample[PLATFORM_MAX_PATH], int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
	//Block sounds if cloaked
	if (TF2_IsPlayerInCondition(boss.iClient, TFCond_Cloaked) || TF2_IsPlayerInCondition(boss.iClient, TFCond_CloakFlicker))
		return Plugin_Handled;
	return Plugin_Continue;
}

public void GentleSpy_OnRage(SaxtonHaleBase boss)
{
	int iClient = boss.iClient;
	
	//Give cloak mater
	float flCloak;
	if (boss.bSuperRage)
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
	boss.CallFunction("UpdateHudInfo", 0.0, 0.0);	//Update once
	
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

public void GentleSpy_OnThink(SaxtonHaleBase boss)
{
	float flCloak = GetEntPropFloat(boss.iClient, Prop_Send, "m_flCloakMeter");
	if (flCloak < 0.5)
		flCloak = 0.0;
	
	//Cloak regen rate attribute didnt take into effect until proper cloak done, shitty temp fix below aeiou
	if (!g_bFirstCloak[boss.iClient])
	{
		if (flCloak > 75.0)
			flCloak = 100.0;
		else if (flCloak > 25.0)
			flCloak = 50.0;
		else
			flCloak = 0.0;
		
		SetEntPropFloat(boss.iClient, Prop_Send, "m_flCloakMeter", flCloak);
	}
			
	if (TF2_IsPlayerInCondition(boss.iClient, TFCond_Cloaked) || TF2_IsPlayerInCondition(boss.iClient, TFCond_CloakFlicker))
	{	
		if (!g_bIsCloaked[boss.iClient])
		{
			//Cloak started
			g_bFirstCloak[boss.iClient] = true;
			g_bIsCloaked[boss.iClient] = true;
			boss.flSpeed *= 1.4;
			//TF2_AddCondition(boss.iClient, TFCond_DefenseBuffMmmph, -1.0);

			int iInvisWatch = GetPlayerWeaponSlot(boss.iClient, WeaponSlot_InvisWatch);
			if (iInvisWatch > MaxClients && IsValidEntity(iInvisWatch))
				TF2Attrib_SetByDefIndex(iInvisWatch, ATTRIB_JUMP_HEIGHT, 3.0);
		}
		
		//Remove all cond in the list if have one
		for (int i = 0; i < sizeof(g_nGentleSpyCloak); i++)
			if (TF2_IsPlayerInCondition(boss.iClient, g_nGentleSpyCloak[i]))
				TF2_RemoveCondition(boss.iClient, g_nGentleSpyCloak[i]);
		
		//Cloak meter is draining, update hud
		boss.CallFunction("UpdateHudInfo", 0.0, 0.0);
	}
	else
	{					
		if (g_bIsCloaked[boss.iClient])
		{
			//Cloak ended
			g_bIsCloaked[boss.iClient] = false;
			boss.flSpeed /= 1.4;
			//TF2_RemoveCondition(boss.iClient, TFCond_DefenseBuffMmmph);
			
			int iInvisWatch = GetPlayerWeaponSlot(boss.iClient, WeaponSlot_InvisWatch);
			if (iInvisWatch > MaxClients && IsValidEntity(iInvisWatch))
				TF2Attrib_RemoveByDefIndex(iInvisWatch, ATTRIB_JUMP_HEIGHT);
		}
	}
}

public void GentleSpy_GetHudInfo(SaxtonHaleBase boss, char[] sMessage, int iLength, int iColor[4])
{
	float flCloak = GetEntPropFloat(boss.iClient, Prop_Send, "m_flCloakMeter");
	if (flCloak > 99.5)
		Format(sMessage, iLength, "%s\n%0.0f%%%%%%%% Cloak: You can use cloak!", sMessage, flCloak);
	else if (flCloak < 10.5)
		Format(sMessage, iLength, "%s\n%0.0f%%%%%%%% Cloak: Gain cloak by using rage!", sMessage, flCloak);
	else
		Format(sMessage, iLength, "%s\n%0.0f%%%%%%%% Cloak", sMessage, flCloak);
	
	iColor[0] = RoundToNearest(2.55 * (100.0 - flCloak));
	iColor[1] = 255;
	iColor[2] = RoundToNearest(2.55 * (100.0 - flCloak));
	iColor[3] = 255;
}

public Action GentleSpy_OnAttackDamage(SaxtonHaleBase boss, int victim, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if (damagetype & DMG_FALL && TF2_IsPlayerInCondition(boss.iClient, TFCond_Cloaked))
	{
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

public void GentleSpy_OnButton(SaxtonHaleBase boss, int &buttons)
{
	int iClient = boss.iClient;
	
	//Prevent boss from uncloaking while in air
	if (buttons & IN_ATTACK2 && TF2_IsPlayerInCondition(iClient, TFCond_Cloaked))
	{
		if (!(GetEntityFlags(iClient) & FL_ONGROUND) || !(GetEntProp(iClient, Prop_Send, "m_fFlags") & FL_ONGROUND))
			buttons -= IN_ATTACK2;
	}
}

public void GentleSpy_Destroy(SaxtonHaleBase boss)
{
	int iClient = boss.iClient;
	
	g_bFirstCloak[iClient] = false;
	g_bIsCloaked[iClient] = false;
}

public void GentleSpy_Precache(SaxtonHaleBase boss)
{
	PrecacheModel(GENTLE_SPY_MODEL);
	
	PrepareMusic(GENTLE_SPY_THEME);
	
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
	AddFileToDownloadsTable("models/freak_fortress_2/gentlespy/the_gentlespy_v1.vvd");
	AddFileToDownloadsTable("models/freak_fortress_2/gentlespy/the_gentlespy_v1.dx80.vtx");
	AddFileToDownloadsTable("models/freak_fortress_2/gentlespy/the_gentlespy_v1.dx90.vtx");
}
