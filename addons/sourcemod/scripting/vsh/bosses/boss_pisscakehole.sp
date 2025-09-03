#define CAKEHOLE_MODEL "models/player/vsh_rewrite/pisscakehole/pisscakehole.mdl"
#define PISS_RAGE_MUSIC	"vsh_rewrite/pisscakehole/piss_rage.mp3"
#define PISS_KILL "vsh_rewrite/pisscakehole/piss_hitv2.mp3"

static int i_PlayerCounter[MAXPLAYERS + 1]
static float g_flJesusChrist[MAXPLAYERS];

static char g_strPissCakeholeRoundStart[][] = {
	"vsh_rewrite/pisscakehole/piss_intro.mp3"
};

static char g_strPissCakeholeWin[][] = {
	"vsh_rewrite/pisscakehole/piss_win.mp3"
};

static char g_strPissCakeholeLose[][] = {
	"vsh_rewrite/pisscakehole/piss_die1.mp3",
	"vsh_rewrite/pisscakehole/piss_die2.mp3"
};

static char g_strPissCakeholeJump[][] = {
	"vo/sniper_jaratetoss01.mp3",
	"vo/sniper_jaratetoss02.mp3",
	"vo/sniper_jaratetoss03.mp3",
};

static char g_strPissCakeholeLastMan[][] = {
	"vo/sniper_revenge14.mp3",
	"vo/sniper_revenge15.mp3",
	"vo/sniper_revenge07.mp3",
	"vo/sniper_revenge06.mp3",
	"vo/sniper_revenge02.mp3",
};

static char g_strPissCakeholeBackStabbed[][] = {
	"vsh_rewrite/pisscakehole/iampisscakehole.mp3"
};

public void PissCakehole_Create(SaxtonHaleBase boss)
{
	boss.CreateClass("BraveJump");
	
	boss.flSpeed = 250.0; //Fatty
	boss.iHealthPerPlayer = 500;
	boss.flHealthExponential = 1.05;
	boss.nClass = TFClass_Sniper;
	boss.iMaxRageDamage = 2500;
	g_flJesusChrist[boss.iClient] = 0.0;
}

public bool PissCakehole_IsBossHidden(SaxtonHaleBase boss)
{
	return true;
}

public void PissCakehole_GetBossName(SaxtonHaleBase boss, char[] sName, int length)
{
	strcopy(sName, length, "Piss Cakehole");
}

public void PissCakehole_GetBossInfo(SaxtonHaleBase boss, char[] sInfo, int length)
{
	StrCat(sInfo, length, "\nHealth: Medium");
	StrCat(sInfo, length, "\n ");
	StrCat(sInfo, length, "\nAbilities");
	StrCat(sInfo, length, "\n- Brave Jump");
	StrCat(sInfo, length, "\n- Gain more speed as you kill, at the cost of losing damage");
	StrCat(sInfo, length, "\n ");
	StrCat(sInfo, length, "\nRage");
	StrCat(sInfo, length, "\n- Damage requirement: 2500");
	StrCat(sInfo, length, "\n- Gain 5 Jarate jars and infinite jumps");
	StrCat(sInfo, length, "\n- 200%% Rage: Jarate jars are doubled, infinite jumps last longer");
}

public void PissCakehole_OnSpawn(SaxtonHaleBase boss)
{
	int iClient = boss.iClient;
	int iWeapon;
	char attribs[128];
	i_PlayerCounter[boss.iClient] = 0
	TF2Attrib_SetByDefIndex(iClient, 279, 1.0);
	TF2Attrib_SetByDefIndex(iClient, 315, 1.0);
	
	Format(attribs, sizeof(attribs), "2 ; 2.80 ; 252 ; 0.5 ; 259 ; 1.0");
	iWeapon = boss.CallFunction("CreateWeapon", 8, "tf_weapon_bonesaw", 100, TFQual_Unusual, attribs);
	if (iWeapon > MaxClients)
		SetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon", iWeapon);
	/*
	Bonesaw attributes:
	
	2: damage bonus
	252: reduction in push force taken from damage
	259: Deals 3x falling damage to the player you land on
	*/
}

public void PissCakehole_OnPlayerKilled(SaxtonHaleBase boss, Event event, int iVictim)
{
	int iPlayerCount = SaxtonHale_GetAliveAttackPlayers();
	//Check if valid player, if yes, increase boss speed and decrease boss damage
	if(SaxtonHale_IsValidAttack(iVictim))
	{
		//Speed increase above 24 players
		if(iPlayerCount >= 24)
		{
			boss.flSpeed += 7.5;
			i_PlayerCounter[boss.iClient]++;
		}
		//Speed increase above 16 players
		else if(iPlayerCount >= 16)
		{
			boss.flSpeed += 5.0;
			i_PlayerCounter[boss.iClient]++;
		}
		//Speed increase above 8 players
		else if(iPlayerCount >= 8)
		{
			boss.flSpeed += 3.0;
			i_PlayerCounter[boss.iClient]++;
		}
		//Speed increase above 1 player
		else if(iPlayerCount >= 1)
		{
			boss.flSpeed += 2.5;
			i_PlayerCounter[boss.iClient]++;
		}
	}
}

//I think this is the gayest code I have ever written
public void PissCakehole_OnThink(SaxtonHaleBase boss)
{
	int iClient = boss.iClient;
	
	if(g_flJesusChrist[iClient] != 0.0 && g_flJesusChrist[iClient] <= GetGameTime())
	{
		g_flJesusChrist[iClient] = 0.0;
		TF2Attrib_SetByDefIndex(iClient, 279, 0.0);
		TF2Attrib_SetByDefIndex(iClient, 315, 1.0);
		TF2Attrib_SetByDefIndex(iClient, 278, 1.0);
		int iAmmo = TF2_GetAmmo(iClient, TF_AMMO_SECONDARY);
		if(iAmmo <= 1)
		{
			TF2_RemoveItemInSlot(iClient, WeaponSlot_Secondary);
			int iWeapon = boss.CallFunction("CreateWeapon", 58, "tf_weapon_jar", 100, TFQual_Unusual);
			if(iWeapon > MaxClients)
			{
				iWeapon = TF2_GetItemInSlot(boss.iClient, WeaponSlot_Secondary);
			}
		}
	}
}

//Decrease damage on kill up to a cap
public Action PissCakehole_OnAttackDamage(SaxtonHaleBase boss, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	float flDamageMultiplier = 1.0 - (i_PlayerCounter[boss.iClient] * 0.05);
	if(flDamageMultiplier < 0.5)
		flDamageMultiplier = 0.5;
		
	damage *= flDamageMultiplier;
	return Plugin_Changed;
	//0.5 means 50% damage lost max
}

public void PissCakehole_OnRage(SaxtonHaleBase boss)
{
	int iClient = boss.iClient;
	int iPlayerCount = SaxtonHale_GetAliveAttackPlayers();
	g_flJesusChrist[iClient] = GetGameTime()+ 1.0;

	TF2_RemoveItemInSlot(iClient, WeaponSlot_Secondary);
	
	char attribs[256];
	Format(attribs, sizeof(attribs), "6 ; 0.50");
	
	if(!boss.bSuperRage)
		StrCat(attribs, sizeof(attribs), " ; 279 ; 1.0 ; 315 ; 5.0");
	else
		StrCat(attribs, sizeof(attribs), " ; 279 ; 2.0 ; 315 ; 5.0");
	
	int iWeapon = boss.CallFunction("CreateWeapon", 58, "tf_weapon_jar", 100, TFQual_Unusual, attribs);
	if (iWeapon > MaxClients)
	{
		iWeapon = TF2_GetItemInSlot(boss.iClient, WeaponSlot_Secondary);
		TF2_SwitchToWeapon(boss.iClient, iWeapon);
	}

	//Give user longer infinite jumps on super rage
	if (!boss.bSuperRage)
		TF2_AddCondition(boss.iClient, TFCond_HalloweenSpeedBoost, 6.0);
	else
		TF2_AddCondition(boss.iClient, TFCond_HalloweenSpeedBoost, 10.0);

	//Add ammo to jarate
	//I'll be honest dog I have 0 fucking clue which one of these is actually responsible for giving Jarate *the ammo*
	//but it works like flex tape, it works, so don't touch it.
	int iJarate = GetPlayerWeaponSlot(iClient, WeaponSlot_Secondary);
	if(IsValidEntity(iJarate))
	{
		TF2Attrib_SetByDefIndex(iClient, 279, 5.0);
		TF2Attrib_SetByDefIndex(iClient, 278, 0.0);
		TF2Attrib_SetByDefIndex(iClient, 618, 0.0);
		TF2Attrib_SetByDefIndex(iClient, 249, 0.0);
		TF2Attrib_SetByDefIndex(iClient, 874, 0.0);
		int iAmmo = TF2_GetAmmo(iClient, TF_AMMO_SECONDARY);
		iAmmo += (3 + RoundToFloor(iPlayerCount / 4.0));
		if(iAmmo > 5)
			iAmmo = 5;
		TF2_SetAmmo(iClient, TF_AMMO_SECONDARY, iAmmo);
		GivePlayerAmmo(iClient, 5, TF_AMMO_SECONDARY, true)
		int ammoType = GetEntProp(iJarate, Prop_Send, "m_iSecondaryAmmoType");
		SetEntProp(iClient, Prop_Send, "m_iAmmo", 5, ammoType); // sets jar ammo to 5
		SetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon", iJarate);
		SetEntPropFloat(iJarate, Prop_Send, "m_flEffectBarRegenTime", GetGameTime() + 0.5);
		SetEntPropFloat(iJarate, Prop_Send, "m_flNextPrimaryAttack", GetGameTime() + 0.5);
		EquipPlayerWeapon(iClient, iJarate);
	}
	/*
	if(g_flJesusChrist[iClient] > GetGameTime() + 0.0)
	{
		TF2_SetAmmo(iClient, TF_AMMO_SECONDARY, 5);
		SetEntPropFloat(iJarate, Prop_Send, "m_flEffectBarRegenTime", GetGameTime() + 0.5);
		SetEntPropFloat(iJarate, Prop_Send, "m_flNextPrimaryAttack", GetGameTime() + 0.5);
	}
	*/
	
}

public void PissCakehole_GetModel(SaxtonHaleBase boss, char[] sModel, int length)
{
	strcopy(sModel, length, CAKEHOLE_MODEL);
}

public void PissCakehole_GetSound(SaxtonHaleBase boss, char[] sSound, int length, SaxtonHaleSound iSoundType)
{
	switch (iSoundType)
	{
		case VSHSound_RoundStart: strcopy(sSound, length, g_strPissCakeholeRoundStart[GetRandomInt(0,sizeof(g_strPissCakeholeRoundStart)-1)]);
		case VSHSound_Win: strcopy(sSound, length, g_strPissCakeholeWin[GetRandomInt(0,sizeof(g_strPissCakeholeWin)-1)]);
		case VSHSound_Lose: strcopy(sSound, length, g_strPissCakeholeLose[GetRandomInt(0,sizeof(g_strPissCakeholeLose)-1)]);
		case VSHSound_Lastman: strcopy(sSound, length, g_strPissCakeholeLastMan[GetRandomInt(0,sizeof(g_strPissCakeholeLastMan)-1)]);
		case VSHSound_Backstab: strcopy(sSound, length, g_strPissCakeholeBackStabbed[GetRandomInt(0,sizeof(g_strPissCakeholeBackStabbed)-1)]);
	}
}

//I am piss cakehole. Replaces every voiceline except intro/win/loss/lastman
public Action PissCakehole_OnSoundPlayed(SaxtonHaleBase boss, int clients[MAXPLAYERS], int &numClients, char sample[PLATFORM_MAX_PATH], int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
{

	if(StrContains(sample, "vo/", false) == 0)
	{
		EmitSoundToAll(g_strPissCakeholeBackStabbed[GetRandomInt(0, sizeof(g_strPissCakeholeBackStabbed)-1)], boss.iClient, SNDCHAN_VOICE, _, _, 0.8);
		
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

//angry cakehole music
public void PissCakehole_GetRageMusicInfo(SaxtonHaleBase boss, char[] sSound, int length, float &time)
{
	strcopy(sSound, length, PISS_RAGE_MUSIC);
	time = 13.0;
}

public void PissCakehole_GetSoundAbility(SaxtonHaleBase boss, char[] sSound, int length, const char[] sType)
{
	if (strcmp(sType, "BraveJump") == 0)
		strcopy(sSound, length, g_strPissCakeholeJump[GetRandomInt(0,sizeof(g_strPissCakeholeJump)-1)]);
}

//sta-a-a-a-a-b
public void PissCakehole_GetSoundKill(SaxtonHaleBase boss, char[] sSound, int length, TFClassType nClass)
{
	EmitSoundToAll(PISS_KILL, boss.iClient, SNDCHAN_STATIC, _, _, 1.0);
}

//Need to precache all custom assets, except sounds apparently
public void PissCakehole_Precache(SaxtonHaleBase boss)
{
	PrecacheModel(CAKEHOLE_MODEL);
	PrepareSound(PISS_RAGE_MUSIC);
	PrepareSound(PISS_KILL);
	for (int i = 0; i < sizeof(g_strPissCakeholeRoundStart); i++) PrecacheSound(g_strPissCakeholeRoundStart[i]);
	for (int i = 0; i < sizeof(g_strPissCakeholeWin); i++) PrecacheSound(g_strPissCakeholeWin[i]);
	for (int i = 0; i < sizeof(g_strPissCakeholeLose); i++) PrecacheSound(g_strPissCakeholeLose[i]);
	for (int i = 0; i < sizeof(g_strPissCakeholeJump); i++) PrecacheSound(g_strPissCakeholeJump[i]);
	for (int i = 0; i < sizeof(g_strPissCakeholeLastMan); i++) PrecacheSound(g_strPissCakeholeLastMan[i]);
	for (int i = 0; i < sizeof(g_strPissCakeholeBackStabbed); i++) PrecacheSound(g_strPissCakeholeBackStabbed[i]);
	
	AddFileToDownloadsTable("materials/models/player/pisscakehole/sniper_red.vtf");
	AddFileToDownloadsTable("materials/models/player/pisscakehole/sniper_red.vmt");
	AddFileToDownloadsTable("materials/models/player/pisscakehole/sniper_lens.vmt");
	AddFileToDownloadsTable("materials/models/player/pisscakehole/sniper_lens.vtf");
	AddFileToDownloadsTable("materials/models/player/pisscakehole/sniper_head_red.vmt");
	AddFileToDownloadsTable("materials/models/player/pisscakehole/sniper_head_red.vtf");
	
	AddFileToDownloadsTable("models/player/vsh_rewrite/pisscakehole/pisscakehole.mdl");
	AddFileToDownloadsTable("models/player/vsh_rewrite/pisscakehole/pisscakehole.phy");
	AddFileToDownloadsTable("models/player/vsh_rewrite/pisscakehole/pisscakehole.vvd");
	AddFileToDownloadsTable("models/player/vsh_rewrite/pisscakehole/pisscakehole.dx80.vtx");
	AddFileToDownloadsTable("models/player/vsh_rewrite/pisscakehole/pisscakehole.dx90.vtx");
}
