#define ITEM_NEON_ANNIHILATOR			813
#define ITEM_BACKBURNER					40
#define ITEM_THERMAL_THRUSTER			1179
#define ITEM_GAS_PASSER					1180
#define TF_DMG_AFTERBURN				DMG_PREVENT_PHYSICS_FORCE | DMG_BURN
#define TF_DMG_GAS_AFTERBURN			DMG_BURN|DMG_PREVENT_PHYSICS_FORCE|DMG_ACID
#define PYROCAR_BACKBURNER_ATTRIBUTES	"24 ; 1.0 ; 72 ; 0.5 ; 74 ; 0.0 ; 112 ; 0.25 ; 178 ; 0.2 ; 181 ; 1.0 ; 252 ; 0.5 ; 259 ; 1.0 ; 356 ; 1.0 ; 839 ; 2.8 ; 841 ; 0 ; 843 ; 8.5 ; 844 ; 1850.0 ; 862 ; 0.45 ; 863 ; 0.01 ; 865 ; 85 ; 214 ; %d"
#define PYROCAR_THERMAL_THRUSTER_ATTRIBUTES	"259 ; 1.0 ; 801 ; 20.0 ; 856 ; 1.0 ; 870 ; 1.0 ; 872 ; 1.0 ; 873 ; 1.0"
#define PYROCAR_HEALINGREDUCTION		0.5

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

static char g_strPyrocarRage[][] =  {
	"misc/halloween/spell_blast_jump.wav"
};

static char g_strPyrocarKill[][] =  {
	"vsh_rewrite/pyrocar/pyrocar_w.mp3", 
	"vsh_rewrite/pyrocar/pyrocar_team.mp3",
	"vsh_rewrite/pyrocar/pyrocar_backlines.mp3",
	"vsh_rewrite/pyrocar/pyrocar_besthat.mp3",
	"vsh_rewrite/pyrocar/pyrocar_burning.mp3",
	"vsh_rewrite/pyrocar/pyrocar_theme.mp3",
	"vsh_rewrite/pyrocar/pyrocar_medic.mp3"
};

static char g_strPyrocarKillBuilding[][] =  {
	"vsh_rewrite/pyrocar/pyrocar_transport.mp3"
};

static char g_strPyrocarLastMan[][] =  {
	"vsh_rewrite/pyrocar/pyrocar_burning.mp3",
	"vsh_rewrite/pyrocar/pyrocar_goingdown.mp3"
};

static char g_strPrecacheCosmetics[][] =  {
	"models/player/items/pyro/pyro_hat.mdl",
	"models/player/items/pyro/fireman_helmet.mdl",
	"models/player/items/all_class/ghostly_gibus_pyro.mdl",
	"models/player/items/pyro/pyro_madame_dixie.mdl",
	"models/player/items/pyro/pyro_chef_hat.mdl"
};

static int g_iCosmetics[] =  {
	51, //Pyro's Beanie
	105, //Brigade Helm
	116, //Ghastly Gibus
	321, //Madame Dixie
	394 //Connoisseur's Cap
};

static float g_flGasMinCharge = 350.0;
static int g_iMaxGasPassers = 3;

static int g_iPyrocarCosmetics[sizeof(g_iCosmetics)];

static int g_iPyrocarPrimary[MAXPLAYERS];
static int g_iPyrocarMelee[MAXPLAYERS];

static float g_flPyrocarBurnEnd[MAXPLAYERS];
static float g_flPyrocarGasCharge[MAXPLAYERS];

static Handle g_hPyrocarHealTimer[MAXPLAYERS];
static Handle g_hGasTimer[MAXPLAYERS];

static bool g_bUnderEffect[MAXPLAYERS];

public void PyroCar_Create(SaxtonHaleBase boss)
{
	boss.CreateClass("RageGas");
	
	boss.iHealthPerPlayer = 600;
	boss.flHealthExponential = 1.05;
	boss.nClass = TFClass_Pyro;
	boss.iMaxRageDamage = 2500;
	boss.flSpeed = 350.0;
	boss.flSpeedMult = 0.08;
}

public void PyroCar_GetBossName(SaxtonHaleBase boss, char[] sName, int length)
{
	strcopy(sName, length, "Pyrocar");
}

public void PyroCar_GetBossInfo(SaxtonHaleBase boss, char[] sInfo, int length)
{
	StrCat(sInfo, length, "\nHealth: Medium");
	StrCat(sInfo, length, "\nDoused enemies take mini crits");
	StrCat(sInfo, length, "\nYou can chain thermal thruster jumps");
	StrCat(sInfo, length, "\n ");
	StrCat(sInfo, length, "\nAbilities");
	StrCat(sInfo, length, "\n- Throw gas passer (Deal damage to gain up to 3)");
	StrCat(sInfo, length, "\n ");
	StrCat(sInfo, length, "\nRage");
	StrCat(sInfo, length, "\n- Damage requirement: 2500");
	StrCat(sInfo, length, "\n- Douses enemies around you and grants a speed boost for 8 seconds");
	StrCat(sInfo, length, "\n- Minicrits become crits");
	StrCat(sInfo, length, "\n- 200%% Rage: Increases bonus speed and extends duration to 12 seconds");
}

public void PyroCar_OnSpawn(SaxtonHaleBase boss)
{
	char attribs[256];
	Format(attribs, sizeof(attribs), PYROCAR_BACKBURNER_ATTRIBUTES, GetRandomInt(9999, 99999));
	g_iPyrocarPrimary[boss.iClient] = boss.CallFunction("CreateWeapon", ITEM_BACKBURNER, "tf_weapon_flamethrower", 100, TFQual_Strange, attribs);
	if (g_iPyrocarPrimary[boss.iClient] > MaxClients)
	{
		SetEntPropEnt(boss.iClient, Prop_Send, "m_hActiveWeapon", g_iPyrocarPrimary[boss.iClient]);
		//TF2_SetAmmo(boss.iClient, TF_AMMO_PRIMARY, 0);	//Reset ammo for TF2 to give correct amount of ammo
	}
	
	boss.CallFunction("CreateWeapon", ITEM_THERMAL_THRUSTER, "tf_weapon_rocketpack", 100, TFQual_Unusual, PYROCAR_THERMAL_THRUSTER_ATTRIBUTES);
	SetEntPropFloat(boss.iClient, Prop_Send, "m_flItemChargeMeter", 0.0, 1);
	
	g_iPyrocarMelee[boss.iClient] = -1;
	g_flPyrocarGasCharge[boss.iClient] = 0.0;
		
	/*
	Backburner attributes:
	
	24: allow crits from behind
	59: self dmg push force decreased
	72: afterburn damage penalty
	74: afterburn duration
	112: ammo regen
	178: deploy time decreased
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
	
	
	int iRandom = GetRandomInt(0, sizeof(g_iCosmetics)-1);
	int iWearable = boss.CallFunction("CreateWeapon", g_iCosmetics[iRandom], "tf_wearable", 1, TFQual_Collectors, "");
	if (iWearable > MaxClients)
		SetEntProp(iWearable, Prop_Send, "m_nModelIndexOverrides", g_iPyrocarCosmetics[iRandom]);
}

public void PyroCar_OnThink(SaxtonHaleBase boss)
{
	//No jetpack charging during preround
	if (GameRules_GetRoundState() == RoundState_Preround)
		SetEntPropFloat(boss.iClient, Prop_Send, "m_flItemChargeMeter", 0.0, 1);
	
	char attribs[256];
	
	int iWaterLevel = GetEntProp(boss.iClient, Prop_Send, "m_nWaterLevel");
	//0 - not in water (WL_NotInWater)
	//1 - feet in water (WL_Feet)
	//2 - waist in water (WL_Waist)
	//3 - head in water (WL_Eyes) 
	
	//Give Neon if Pyrocar is underwater
	if (iWaterLevel >= 3)
	{
		if (IsValidEntity(g_iPyrocarPrimary[boss.iClient]) && g_iPyrocarPrimary[boss.iClient] > MaxClients)
		{
			TF2_RemoveItemInSlot(boss.iClient, WeaponSlot_Primary);
			g_iPyrocarPrimary[boss.iClient] = -1;
			Format(attribs, sizeof(attribs), "2 ; 1.50 ; 438 ; 1.0 ; 137 ; 1.5 ; 264 ; 1.5 ; 178 ; 0.01");
			g_iPyrocarMelee[boss.iClient] = boss.CallFunction("CreateWeapon", ITEM_NEON_ANNIHILATOR, "tf_weapon_breakable_sign", 100, TFQual_Unusual, attribs);
			if (g_iPyrocarMelee[boss.iClient] > MaxClients)
			{
				//Check if his active weapon got removed, if so set as that weapon
				int iActiveWep = GetEntPropEnt(boss.iClient, Prop_Send, "m_hActiveWeapon");
				if (!(IsValidEntity(iActiveWep)))
					TF2_SwitchToWeapon(boss.iClient, g_iPyrocarMelee[boss.iClient]);
			}
		}
	}
	else
	{
		if (IsValidEntity(g_iPyrocarMelee[boss.iClient]) && g_iPyrocarMelee[boss.iClient] > MaxClients)
		{
			TF2_RemoveItemInSlot(boss.iClient, WeaponSlot_Melee);
			g_iPyrocarMelee[boss.iClient] = -1;
			Format(attribs, sizeof(attribs), PYROCAR_BACKBURNER_ATTRIBUTES, GetRandomInt(9999, 99999));
			g_iPyrocarPrimary[boss.iClient] = boss.CallFunction("CreateWeapon", ITEM_BACKBURNER, "tf_weapon_flamethrower", 100, TFQual_Strange, attribs);
			if (g_iPyrocarPrimary[boss.iClient] > MaxClients)
			{
				//Check if his active weapon got removed, if so set as that weapon
				int iActiveWep = GetEntPropEnt(boss.iClient, Prop_Send, "m_hActiveWeapon");
				if (!(IsValidEntity(iActiveWep)))
					TF2_SwitchToWeapon(boss.iClient, g_iPyrocarPrimary[boss.iClient]);
			}
		}
	}
	
	//Prevent marked-for-death to be removed
	int iTeam = GetClientTeam(boss.iClient);
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) > 1 && GetClientTeam(i) != iTeam)
		{
			if(g_bUnderEffect[i])
			{
				TF2_AddCondition(i, TFCond_MarkedForDeath, 0.25, boss.iClient);
			}
			else if (TF2_IsPlayerInCondition(i, TFCond_Gas))
			{
				g_bUnderEffect[i] = true;
				g_hGasTimer[i] = CreateTimer(10.0, Timer_EffectEnd, i);
			}
		}
	}
}

public void PyroCar_GetHudInfo(SaxtonHaleBase boss, char[] sMessage, int iLength, int iColor[4])
{
	float flGasCharge = g_flPyrocarGasCharge[boss.iClient]/g_flGasMinCharge * 100.0;
	if (flGasCharge < 100.0)
		Format(sMessage, iLength, "%s\nDeal damage to charge your gas: %0.2f%%.", sMessage, flGasCharge);
	else
		Format(sMessage, iLength, "%s\nHold right click to throw your gas! %0.2f%%.", sMessage, flGasCharge);
	
	if (flGasCharge < 100.0)
	{
		iColor = {255, 255, 255, 255};
	}
	else if (g_iMaxGasPassers > 1)
	{
		//Avoid dividing by 0
		//100% to 500%: green to yellow
		iColor[0] = RoundToNearest((flGasCharge-100.0) * (255.0/((g_iMaxGasPassers-1) * 100.0)));
		iColor[1] = 255;
		iColor[2] = 0;
		iColor[3] = 255;
	}
	else
	{
		//100%: green
		iColor = {0, 255, 0, 255};
	}
}

public Action PyroCar_OnAttackDamageAlive(SaxtonHaleBase boss, int victim, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if (TF2_IsUbercharged(victim))
		return Plugin_Continue;
	
	if (damagetype & DMG_IGNITE)
	{
		//Direct flamethrower damage
		float flGameTime = GetGameTime();
		float flDuration = g_flPyrocarBurnEnd[victim] - flGameTime;
		if (flDuration < 0.0)
			flDuration = 0.0;
		
		flDuration += 0.15;
		if (flDuration > 10.0)
			flDuration = 10.0;
		
		g_flPyrocarBurnEnd[victim] = flGameTime + flDuration;
		TF2_IgnitePlayer(victim, boss.iClient, flDuration);
		
		//Give victim less healing while damaged by pyrocar
		if (!g_hPyrocarHealTimer[victim])
		{
			for (int iSlot = 0; iSlot <= WeaponSlot_BuilderEngie; iSlot++)
			{
				int iWeapon = GetPlayerWeaponSlot(boss.iClient, iSlot);
				if (iWeapon > MaxClients)
				{
					TF2Attrib_SetByDefIndex(iWeapon, ATTRIB_LESSHEALING, 0.5);
					TF2Attrib_ClearCache(iWeapon);
				}
			}
		}
		
		g_hPyrocarHealTimer[victim] = CreateTimer(0.4, Timer_RemoveLessHealing, GetClientSerial(victim));
	}
	
	if (g_flPyrocarGasCharge[boss.iClient] <= g_iMaxGasPassers * g_flGasMinCharge)
		g_flPyrocarGasCharge[boss.iClient] += damage;
		
	if (g_flPyrocarGasCharge[boss.iClient] > g_iMaxGasPassers * g_flGasMinCharge)
		g_flPyrocarGasCharge[boss.iClient] = g_iMaxGasPassers * g_flGasMinCharge;
	
	boss.CallFunction("UpdateHudInfo", 0.0, 0.0);	//Update once
	return Plugin_Changed;
}

public Action PyroCar_OnAttackBuilding(SaxtonHaleBase boss, int victim, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	//Buildings take constant damage
	if (weapon == TF2_GetItemInSlot(boss.iClient, WeaponSlot_Primary))
	{
		damage = 20.0;
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}

public void PyroCar_GetSound(SaxtonHaleBase boss, char[] sSound, int length, SaxtonHaleSound iSoundType)
{
	switch (iSoundType)
	{
		case VSHSound_RoundStart: strcopy(sSound, length, g_strPyrocarRoundStart[GetRandomInt(0,sizeof(g_strPyrocarRoundStart)-1)]);
		case VSHSound_Win: strcopy(sSound, length, g_strPyrocarWin[GetRandomInt(0,sizeof(g_strPyrocarWin)-1)]);
		case VSHSound_Lose: strcopy(sSound, length, g_strPyrocarLose[GetRandomInt(0,sizeof(g_strPyrocarLose)-1)]);
		case VSHSound_Rage: strcopy(sSound, length, g_strPyrocarRage[GetRandomInt(0,sizeof(g_strPyrocarRage)-1)]);
		case VSHSound_KillBuilding: strcopy(sSound, length, g_strPyrocarKillBuilding[GetRandomInt(0,sizeof(g_strPyrocarKillBuilding)-1)]);
		case VSHSound_Lastman: strcopy(sSound, length, g_strPyrocarLastMan[GetRandomInt(0,sizeof(g_strPyrocarLastMan)-1)]);
	}
}

public void PyroCar_GetSoundKill(SaxtonHaleBase boss, char[] sSound, int length, TFClassType nClass)
{
	strcopy(sSound, length, g_strPyrocarKill[GetRandomInt(0, sizeof(g_strPyrocarKill) - 1)]);
}

public Action PyroCar_OnSoundPlayed(SaxtonHaleBase boss, int clients[MAXPLAYERS], int &numClients, char sample[PLATFORM_MAX_PATH], int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
	if (strncmp(sample, "vo/", 3) == 0)//Block voicelines
		return Plugin_Handled;
	return Plugin_Continue;
}

public void PyroCar_Destroy(SaxtonHaleBase boss)
{
	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		g_flPyrocarBurnEnd[iClient] = 0.0;
		g_hPyrocarHealTimer[iClient] = null;
		g_hGasTimer[iClient] = null;
		
		if (IsClientInGame(iClient))
		{
			for (int iSlot = 0; iSlot <= WeaponSlot_BuilderEngie; iSlot++)
			{
				int iWeapon = GetPlayerWeaponSlot(boss.iClient, iSlot);
				if (iWeapon > MaxClients)
				{
					TF2Attrib_RemoveByDefIndex(iWeapon, ATTRIB_LESSHEALING);
					TF2Attrib_ClearCache(iWeapon);
				}
			}
		}
	}
}

public void PyroCar_Precache(SaxtonHaleBase boss)
{
	for (int i = 0; i < sizeof(g_iCosmetics); i++)
		g_iPyrocarCosmetics[i] = PrecacheModel(g_strPrecacheCosmetics[i]);
		
	for (int i = 0; i < sizeof(g_strPyrocarRoundStart); i++) PrepareSound(g_strPyrocarRoundStart[i]);
	for (int i = 0; i < sizeof(g_strPyrocarWin); i++) PrepareSound(g_strPyrocarWin[i]);
	for (int i = 0; i < sizeof(g_strPyrocarLose); i++) PrepareSound(g_strPyrocarLose[i]);
	for (int i = 0; i < sizeof(g_strPyrocarRage); i++) PrecacheSound(g_strPyrocarRage[i]);
	for (int i = 0; i < sizeof(g_strPyrocarKill); i++) PrepareSound(g_strPyrocarKill[i]);
	for (int i = 0; i < sizeof(g_strPyrocarKillBuilding); i++) PrepareSound(g_strPyrocarKillBuilding[i]);
	for (int i = 0; i < sizeof(g_strPyrocarLastMan); i++) PrepareSound(g_strPyrocarLastMan[i]);
}

public void PyroCar_OnButtonPress(SaxtonHaleBase boss, int button)
{
	if (button == IN_ATTACK2 && g_flPyrocarGasCharge[boss.iClient] > g_flGasMinCharge)
	{
		g_flPyrocarGasCharge[boss.iClient] -= g_flGasMinCharge;
		boss.CallFunction("UpdateHudInfo", 0.0, 0.0);	//Update once
		
		int iWeapon = CreateEntityByName("tf_weapon_jar_gas");
		SetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex", ITEM_GAS_PASSER);
		
		int iActiveWeapon = GetEntPropEnt(boss.iClient, Prop_Send, "m_hActiveWeapon");
		float flChargeMeter = GetEntPropFloat(boss.iClient, Prop_Send, "m_flItemChargeMeter", 1);
		
		DispatchSpawn(iWeapon);
		EquipPlayerWeapon(boss.iClient, iWeapon);
		SDK_TossJarThink(iWeapon);
		RemovePlayerItem(boss.iClient, iWeapon);
		RemoveEntity(iWeapon);
		
		TF2_SwitchToWeapon(boss.iClient, iActiveWeapon);
		SetEntPropFloat(boss.iClient, Prop_Send, "m_flItemChargeMeter", flChargeMeter, 1);
	}
}

public Action Timer_RemoveLessHealing(Handle hTimer, int iSerial)
{
	int iClient = GetClientFromSerial(iSerial);
	if (0 < iClient <= MaxClients && g_hPyrocarHealTimer[iClient] == hTimer)
	{
		g_hPyrocarHealTimer[iClient] = null;
		
		if (IsClientInGame(iClient))
		{
			for (int iSlot = 0; iSlot <= WeaponSlot_BuilderEngie; iSlot++)
			{
				int iWeapon = GetPlayerWeaponSlot(iClient, iSlot);
				if (iWeapon > MaxClients)
				{
					TF2Attrib_RemoveByDefIndex(iWeapon, ATTRIB_LESSHEALING);
					TF2Attrib_ClearCache(iWeapon);
				}
			}
		}
	}
	
	return Plugin_Continue;
}

public Action Timer_EffectEnd(Handle hTimer, int iClient)
{
	if (IsClientInGame(iClient) && IsPlayerAlive(iClient))
	{
		TF2_RemoveCondition(iClient, TFCond_Gas);
		TF2_RemoveCondition(iClient, TFCond_MarkedForDeath);
	}
	
	g_bUnderEffect[iClient] = false;
	g_hGasTimer[iClient] = null;
	return Plugin_Continue;
}
