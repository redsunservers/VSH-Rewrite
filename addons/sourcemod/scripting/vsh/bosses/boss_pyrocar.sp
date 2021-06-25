#define ITEM_NEON_ANNIHILATOR			813
#define ITEM_BACKBURNER					40
#define ITEM_THERMAL_THRUSTER			1179
#define ITEM_GAS_PASSER					1180
#define ATTRIB_LESSHEALING				734
#define TF_DMG_AFTERBURN				DMG_PREVENT_PHYSICS_FORCE | DMG_BURN
#define TF_DMG_GAS_AFTERBURN			DMG_BURN|DMG_PREVENT_PHYSICS_FORCE|DMG_ACID
#define PYROCAR_BACKBURNER_ATTRIBUTES	"24 ; 1.0 ; 72 ; 0.5 ; 112 ; 0.25 ; 178 ; 0.2 ; 179 ; 1.0 ; 181 ; 1.0 ; 252 ; 0.5 ; 259 ; 1.0 ; 356 ; 1.0 ; 839 ; 2.8 ; 841 ; 0 ; 843 ; 8.5 ; 844 ; 1850.0 ; 862 ; 0.45 ; 863 ; 0.01 ; 865 ; 85 ; 214 ; %d"

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

static float g_flGasMinCharge = 225.0;
static int g_iMaxGasPassers = 5;

static int g_iPyrocarCosmetics[sizeof(g_iCosmetics)];

static int g_iPyrocarPrimary[TF_MAXPLAYERS+1];
static int g_iPyrocarJetpack[TF_MAXPLAYERS+1];
static int g_iPyrocarMelee[TF_MAXPLAYERS+1];

static float g_flPyrocarGasCharge[TF_MAXPLAYERS+1];
static float g_flPyrocarJetpackCharge[TF_MAXPLAYERS+1];

static Handle g_hPyrocarHealTimer[TF_MAXPLAYERS+1];
static Handle g_hGasTimer[TF_MAXPLAYERS+1];

static bool g_bUnderEffect[TF_MAXPLAYERS+1];

methodmap CPyroCar < SaxtonHaleBase
{
	public CPyroCar(CPyroCar boss)
	{
		//boss.CallFunction("CreateAbility", "CFloatJump");
		boss.CallFunction("CreateAbility", "CRageGas");
		
		boss.iBaseHealth = 800;
		boss.iHealthPerPlayer = 800;
		boss.nClass = TFClass_Pyro;
		boss.iMaxRageDamage = 2500;
		boss.flSpeed = 350.0;
	}
	
	public void GetBossName(char[] sName, int length)
	{
		strcopy(sName, length, "Pyrocar");
	}
	
	public void GetBossInfo(char[] sInfo, int length)
	{
		StrCat(sInfo, length, "\nHealth: Medium");
		StrCat(sInfo, length, "\nYour backburner does little damage");
		StrCat(sInfo, length, "\nDoused enemies take critical hits");
		StrCat(sInfo, length, "\nYou can chain thermal thruster jumps");
		StrCat(sInfo, length, "\n ");
		StrCat(sInfo, length, "\nAbilities");
		StrCat(sInfo, length, "\n- Throw gas passer (Deal damage to gain up to 5)");
		StrCat(sInfo, length, "\n ");
		StrCat(sInfo, length, "\nRage");
		StrCat(sInfo, length, "\n- Douses enemies around you and grants a speed boost for 8 seconds");
		StrCat(sInfo, length, "\n- 200%% Rage: Increases bonus speed and extends duration to 12 seconds");
	}
	
	public void OnSpawn()
	{
		char attribs[256];
		Format(attribs, sizeof(attribs), PYROCAR_BACKBURNER_ATTRIBUTES, GetRandomInt(9999, 99999));
		g_iPyrocarPrimary[this.iClient] = this.CallFunction("CreateWeapon", ITEM_BACKBURNER, "tf_weapon_flamethrower", 100, TFQual_Strange, attribs);
		g_iPyrocarJetpack[this.iClient] = this.CallFunction("CreateWeapon", ITEM_THERMAL_THRUSTER, "tf_weapon_rocketpack", 100, TFQual_Unusual, "259 ; 1.0 ; 870 ; 1.0 ; 872 ; 1.0 ; 873 ; 1.0");
		if (g_iPyrocarPrimary[this.iClient] > MaxClients)
		{
			SetEntPropEnt(this.iClient, Prop_Send, "m_hActiveWeapon", g_iPyrocarPrimary[this.iClient]);
			//TF2_SetAmmo(this.iClient, WeaponSlot_Primary, 0);	//Reset ammo for TF2 to give correct amount of ammo
		}
		
		g_iPyrocarMelee[this.iClient] = -1;
		g_flPyrocarGasCharge[this.iClient] = 0.0;
			
		/*
		Backburner attributes:
		
		24: allow crits from behind
		37: mult_maxammo_primary
		59: self dmg push force decreased
		72: afterburn damage penalty
		112: ammo regen
		178: deploy time decreased
		179: minicrits become crits
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
		int iWearable = this.CallFunction("CreateWeapon", g_iCosmetics[iRandom], "tf_wearable", 1, TFQual_Collectors, "");
		if (iWearable > MaxClients)
			SetEntProp(iWearable, Prop_Send, "m_nModelIndexOverrides", g_iPyrocarCosmetics[iRandom]);
	}
	
	public void OnThink()
	{
		char attribs[256];
		
		int iWaterLevel = GetEntProp(this.iClient, Prop_Send, "m_nWaterLevel");
		//0 - not in water (WL_NotInWater)
		//1 - feet in water (WL_Feet)
		//2 - waist in water (WL_Waist)
		//3 - head in water (WL_Eyes) 
		
		//Give Neon if Pyrocar is underwater
		if (iWaterLevel >= 3)
		{
			if (IsValidEntity(g_iPyrocarPrimary[this.iClient]) && g_iPyrocarPrimary[this.iClient] > MaxClients)
			{
				TF2_RemoveItemInSlot(this.iClient, WeaponSlot_Primary);
				g_iPyrocarPrimary[this.iClient] = -1;
				Format(attribs, sizeof(attribs), "2 ; 1.50 ; 438 ; 1.0 ; 137 ; 1.5 ; 264 ; 1.5 ; 178 ; 0.01");
				g_iPyrocarMelee[this.iClient] = this.CallFunction("CreateWeapon", ITEM_NEON_ANNIHILATOR, "tf_weapon_breakable_sign", 100, TFQual_Unusual, attribs);
				if (g_iPyrocarMelee[this.iClient] > MaxClients)
				{
					//Check if his active weapon got removed, if so set as that weapon
					int iActiveWep = GetEntPropEnt(this.iClient, Prop_Send, "m_hActiveWeapon");
					if (!(IsValidEntity(iActiveWep)))
						SetEntPropEnt(this.iClient, Prop_Send, "m_hActiveWeapon", g_iPyrocarMelee[this.iClient]);
				}
			}
		}
		else
		{
			if (IsValidEntity(g_iPyrocarMelee[this.iClient]) && g_iPyrocarMelee[this.iClient] > MaxClients)
			{
				TF2_RemoveItemInSlot(this.iClient, WeaponSlot_Melee);
				g_iPyrocarMelee[this.iClient] = -1;
				Format(attribs, sizeof(attribs), PYROCAR_BACKBURNER_ATTRIBUTES, GetRandomInt(9999, 99999));
				g_iPyrocarPrimary[this.iClient] = this.CallFunction("CreateWeapon", ITEM_BACKBURNER, "tf_weapon_flamethrower", 100, TFQual_Strange, attribs);
				if (g_iPyrocarPrimary[this.iClient] > MaxClients)
				{
					//Check if his active weapon got removed, if so set as that weapon
					int iActiveWep = GetEntPropEnt(this.iClient, Prop_Send, "m_hActiveWeapon");
					if (!(IsValidEntity(iActiveWep)))
						SetEntPropEnt(this.iClient, Prop_Send, "m_hActiveWeapon", g_iPyrocarPrimary[this.iClient]);
				}
			}
		}
		
		//Check if Gas Passer has been used
		int iSecondaryWep = GetPlayerWeaponSlot(this.iClient, WeaponSlot_Secondary);
		if (IsValidEntity(iSecondaryWep))
		{
			if (iSecondaryWep != g_iPyrocarJetpack[this.iClient] && GetEntPropFloat(this.iClient, Prop_Send, "m_flItemChargeMeter", 1) < 100.0)
			{
				TF2_RemoveItemInSlot(this.iClient, WeaponSlot_Secondary);

				g_iPyrocarJetpack[this.iClient] = this.CallFunction("CreateWeapon", ITEM_THERMAL_THRUSTER, "tf_weapon_rocketpack", 100, TFQual_Unusual, "259 ; 1.0 ; 872 ; 1.0 ; 873 ; 1.0");
				SetEntPropFloat(this.iClient, Prop_Send, "m_flItemChargeMeter", g_flPyrocarJetpackCharge[this.iClient], 1);

				//Call client to reset HUD meter
				Event event = CreateEvent("localplayer_pickup_weapon", true);
				event.FireToClient(this.iClient);
				event.Cancel();

				//Change active weapon
				if (IsValidEntity(GetPlayerWeaponSlot(this.iClient, WeaponSlot_Primary)))
					SetEntPropEnt(this.iClient, Prop_Send, "m_hActiveWeapon", g_iPyrocarPrimary[this.iClient]);
				else
					SetEntPropEnt(this.iClient, Prop_Send, "m_hActiveWeapon", g_iPyrocarMelee[this.iClient]);
			}
		}
		
		//Prevent marked-for-death to be removed
		int iTeam = GetClientTeam(this.iClient);
		
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) > 1 && GetClientTeam(i) != iTeam)
			{
				if(g_bUnderEffect[i])
				{
					TF2_AddCondition(i, TFCond_MarkedForDeath, 0.25, this.iClient);
				}
				else if (TF2_IsPlayerInCondition(i, TFCond_Gas))
				{
					g_bUnderEffect[i] = true;
					g_hGasTimer[i] = CreateTimer(10.0, Timer_EffectEnd, i);
				}
			}
			
		}
		
		//Handle Pyrocar's M2 ability
		if (GameRules_GetRoundState() == RoundState_Preround) return;
		
		char sMessage[255];
		int iColor[4];
		float flGasCharge = g_flPyrocarGasCharge[this.iClient]/g_flGasMinCharge * 100.0;
		if (flGasCharge < 100.0)
		{
			Format(sMessage, sizeof(sMessage), "Deal damage to charge your gas: %0.2f%%.", flGasCharge);
			iColor[0] = 255; iColor[1] = 255; iColor[2] = 255; iColor[3] = 255;
			Hud_SetColor(this.iClient, iColor);
		}
		else
		{
			Format(sMessage, sizeof(sMessage), "Hold right click to throw your gas! %0.2f%%.", flGasCharge);
			//Avoid dividing by 0
			if (g_iMaxGasPassers > 1)
			{
				//100% to 500%: green to yellow
				iColor[0] = RoundToNearest((flGasCharge-100.0) * (255.0/((g_iMaxGasPassers-1) * 100.0)));
				iColor[1] = 255;
				iColor[2] = 0;
			}
			else
			{
				//100%: green
				iColor[0] = 0;
				iColor[1] = 255;
				iColor[2] = 0;
			}
			
			Hud_SetColor(this.iClient, iColor);
		}
		
		Hud_AddText(this.iClient, sMessage);
		
		//Jetpack regen
		if (g_iPyrocarJetpack[this.iClient] == GetPlayerWeaponSlot(this.iClient, WeaponSlot_Secondary))
		{
			g_flPyrocarJetpackCharge[this.iClient] = GetEntPropFloat(this.iClient, Prop_Send, "m_flItemChargeMeter", 1);
			if(g_flPyrocarJetpackCharge[this.iClient] < 100.0)
				g_flPyrocarJetpackCharge[this.iClient] += 0.1;
			SetEntPropFloat(this.iClient, Prop_Send, "m_flItemChargeMeter", g_flPyrocarJetpackCharge[this.iClient], 1);
		}
		else
		{
			if(g_flPyrocarJetpackCharge[this.iClient] < 100.0)
			g_flPyrocarJetpackCharge[this.iClient] += 0.2;
		}
		
	}
	
	public Action OnTakeDamage(int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
	{
		char sWeaponClassName[32];
		if (inflictor >= 0)
			GetEdictClassname(inflictor, sWeaponClassName, sizeof(sWeaponClassName));
		
		//It's ugly but there's no other way
		float flHealingRate = 0.5;
		if (TF2_IsPlayerInCondition(this.iClient, TFCond_Milked) && this.iClient != attacker && TF2_FindAttribute(attacker, ATTRIB_LESSHEALING, flHealingRate))
			Client_AddHealth(attacker, -RoundToNearest(damage - damage/flHealingRate));
		
		return Plugin_Continue;
	}
	
	public Action OnAttackDamage(int victim, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
	{
		if (TF2_IsPlayerInCondition(victim, TFCond_Ubercharged)) return Plugin_Continue;
		if (weapon == TF2_GetItemInSlot(this.iClient, WeaponSlot_Primary) && !(damagetype == TF_DMG_AFTERBURN || damagetype == TF_DMG_GAS_AFTERBURN))
		{
			//Give victim less healing while damaged by pyrocar
			if (!g_hPyrocarHealTimer[victim])
			{
				TF2Attrib_SetByDefIndex(victim, ATTRIB_LESSHEALING, 0.5);
				TF2Attrib_ClearCache(victim);
			}
			
			g_hPyrocarHealTimer[victim] = CreateTimer(0.2, Timer_RemoveLessHealing, GetClientSerial(victim));
			
			//Deal constant damage for flamethrower
			damage = 7.0;
		}
		
		//Deal constant damage for afterburn
		if (damagetype == TF_DMG_AFTERBURN || damagetype == TF_DMG_GAS_AFTERBURN)
			damage = 1.4;
			
		if (g_flPyrocarGasCharge[this.iClient] <= g_iMaxGasPassers * g_flGasMinCharge)
			g_flPyrocarGasCharge[this.iClient] += damage;
			
		if (g_flPyrocarGasCharge[this.iClient] > g_iMaxGasPassers * g_flGasMinCharge)
			g_flPyrocarGasCharge[this.iClient] = g_iMaxGasPassers * g_flGasMinCharge;
		//Any kind of crit deals 2.5x damage, bonus damage does not give extra gas charge
		if (damagetype & DMG_CRIT)
		{
			damage *= 2.5;
		}
			
		return Plugin_Changed;
	}
	
	public Action OnAttackBuilding(int victim, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
	{
		//Buildings take constant damage
		if (weapon == TF2_GetItemInSlot(this.iClient, WeaponSlot_Primary))
		{
			damage = 17.0;
		}
	}
	
	public void GetSound(char[] sSound, int length, SaxtonHaleSound iSoundType)
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
	
	public void GetSoundKill(char[] sSound, int length, TFClassType nClass)
	{
		strcopy(sSound, length, g_strPyrocarKill[GetRandomInt(0, sizeof(g_strPyrocarKill) - 1)]);
	}
	
	public Action OnSoundPlayed(int clients[MAXPLAYERS], int &numClients, char sample[PLATFORM_MAX_PATH], int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
	{
		if (strncmp(sample, "vo/", 3) == 0)//Block voicelines
			return Plugin_Handled;
		return Plugin_Continue;
	}
	
	public void Destroy()
	{
		for (int iClient = 1; iClient <= MaxClients; iClient++)
		{
			g_hPyrocarHealTimer[iClient] = null;
			g_hGasTimer[iClient] = null;
			
			if (IsClientInGame(iClient))
			{
				TF2Attrib_RemoveByDefIndex(iClient, ATTRIB_LESSHEALING);
				TF2Attrib_ClearCache(iClient);
			}
		}
	}
	
	public void Precache()
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
	
	public void OnButtonPress(int button)
	{
		if (button == IN_ATTACK2 && g_flPyrocarGasCharge[this.iClient] > g_flGasMinCharge && g_iPyrocarJetpack[this.iClient] == GetPlayerWeaponSlot(this.iClient, WeaponSlot_Secondary))
		{
			g_flPyrocarGasCharge[this.iClient] -= g_flGasMinCharge;
			
			int iSecondaryWep = GetPlayerWeaponSlot(this.iClient, WeaponSlot_Secondary);
			if (IsValidEntity(iSecondaryWep))
			{
				TF2_RemoveItemInSlot(this.iClient, WeaponSlot_Secondary);
				
				iSecondaryWep = this.CallFunction("CreateWeapon", ITEM_GAS_PASSER, "tf_weapon_jar_gas", 100, TFQual_Unusual, "");
				SetEntPropFloat(this.iClient, Prop_Send, "m_flItemChargeMeter", 100.0, 1);
			}
		}
	}
};

public Action Timer_RemoveLessHealing(Handle hTimer, int iSerial)
{
	int iClient = GetClientFromSerial(iSerial);
	if (0 < iClient <= MaxClients && g_hPyrocarHealTimer[iClient] == hTimer)
	{
		g_hPyrocarHealTimer[iClient] = null;
		
		if (IsClientInGame(iClient))
		{
			TF2Attrib_RemoveByDefIndex(iClient, ATTRIB_LESSHEALING);
			TF2Attrib_ClearCache(iClient);
		}
	}
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
}