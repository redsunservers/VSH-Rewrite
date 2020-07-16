#define ITEM_NEON_ANNIHILATOR			813
#define ITEM_BACKBURNER					40
#define ATTRIB_LESSHEALING				734
#define PYROCAR_BACKBURNER_ATTRIBUTES	"24 ; 1.0 ; 37 ; 0.025 ; 59 ; 1.0 ; 72 ; 0.0 ; 178 ; 0.01 ; 181 ; 1.0 ; 252 ; 0.5 ; 259 ; 1.0 ; 356 ; 1.0 ; 839 ; 2.8 ; 841 ; 0 ; 843 ; 8.5 ; 844 ; 1600.0 ; 862 ; 0.35 ; 863 ; 0.01 ; 865 ; 85 ; 214 ; %d"

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

static char g_strPyrocarJump[][] =  {
	"weapons/bumper_car_speed_boost_start.wav"
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

static int g_iPyrocarCosmetics[sizeof(g_iCosmetics)];

static int g_iPyrocarPrimary[TF_MAXPLAYERS+1];
static int g_iPyrocarMelee[TF_MAXPLAYERS+1];

static Handle g_hPyrocarHealTimer[TF_MAXPLAYERS+1];
static Handle g_hPyrocarAmmoTimer[TF_MAXPLAYERS+1];

methodmap CPyroCar < SaxtonHaleBase
{
	public CPyroCar(CPyroCar boss)
	{
		boss.CallFunction("CreateAbility", "CFloatJump");
		boss.CallFunction("CreateAbility", "CRageHop");
		
		boss.iBaseHealth = 800;
		boss.iHealthPerPlayer = 800;
		boss.nClass = TFClass_Pyro;
		boss.iMaxRageDamage = 2500;
	}
	
	public void GetBossName(char[] sName, int length)
	{
		strcopy(sName, length, "Pyrocar");
	}
	
	public void GetBossInfo(char[] sInfo, int length)
	{
		StrCat(sInfo, length, "\nHealth: Medium");
		StrCat(sInfo, length, "\nYour flamethrower range is shorter and has no afterburn");
		StrCat(sInfo, length, "\nIt fires in powerful short bursts");
		StrCat(sInfo, length, "\nYour current target obtains healing penalty");
		StrCat(sInfo, length, "\n ");
		StrCat(sInfo, length, "\nAbilities");
		StrCat(sInfo, length, "\n- Float Jump, gains less gravity while in air");
		StrCat(sInfo, length, "\n ");
		StrCat(sInfo, length, "\nRage");
		StrCat(sInfo, length, "\n- Hops repeatedly dealing explosive damage near the impact for 8 seconds");
		StrCat(sInfo, length, "\n- Rage also grants you defensive buff and immunity to knockback");
		StrCat(sInfo, length, "\n- 200%% Rage: Increases explosion damage and extends the duration to 12 seconds");
	}
	
	public void OnSpawn()
	{
		char attribs[256];
		Format(attribs, sizeof(attribs), PYROCAR_BACKBURNER_ATTRIBUTES, GetRandomInt(9999, 99999));
		g_iPyrocarPrimary[this.iClient] = this.CallFunction("CreateWeapon", ITEM_BACKBURNER, "tf_weapon_flamethrower", 100, TFQual_Strange, attribs);
		if (g_iPyrocarPrimary[this.iClient] > MaxClients)
		{
			SetEntPropEnt(this.iClient, Prop_Send, "m_hActiveWeapon", g_iPyrocarPrimary[this.iClient]);
			TF2_SetAmmo(this.iClient, WeaponSlot_Primary, 0);	//Reset ammo for TF2 to give correct amount of ammo
		}
				
		g_iPyrocarMelee[this.iClient] = -1;
			
		/*
		Backburner attributes:
		
		24: allow crits from behind
		37: mult_maxammo_primary
		59: self dmg push force decreased
		72: afterburn damage penalty
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
			
			if (TF2_GetAmmo(this.iClient, WeaponSlot_Primary) == 0 && g_hPyrocarAmmoTimer[this.iClient] == null)
			{
				g_hPyrocarAmmoTimer[this.iClient] = CreateTimer(1.0, Timer_RefillAmmo, this.iClient);
			}
		}
	}
	
	public Action OnTakeDamage(int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
	{
		char sWeaponClassName[32];
		if (inflictor >= 0)
			GetEdictClassname(inflictor, sWeaponClassName, sizeof(sWeaponClassName));
		
		//Disable self-damage from bomb rage ability
		if (this.iClient == attacker && strcmp(sWeaponClassName, "tf_generic_bomb") == 0)
			return Plugin_Stop;
		
		//It's ugly but there's no other way
		float flHealingRate = 1.0;
		if (TF2_IsPlayerInCondition(this.iClient, TFCond_Milked) && this.iClient != attacker && TF2_FindAttribute(attacker, ATTRIB_LESSHEALING, flHealingRate))
			Client_AddHealth(attacker, -RoundToNearest(damage - damage/flHealingRate));
		
		return Plugin_Continue;
	}
	
	public Action OnAttackDamage(int victim, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
	{
		if (weapon == TF2_GetItemInSlot(this.iClient, WeaponSlot_Primary))
		{
			//Give victim less healing while damaged by pyrocar
			if (!g_hPyrocarHealTimer[victim])
			{
				TF2Attrib_SetByDefIndex(victim, ATTRIB_LESSHEALING, 0.4);
				TF2Attrib_ClearCache(victim);
			}
			
			g_hPyrocarHealTimer[victim] = CreateTimer(1.0, Timer_RemoveLessHealing, GetClientSerial(victim));
			
			//Deal constant damage for flamethrower
			damage = 17.0;
			return Plugin_Changed;
		}
		
		return Plugin_Continue;
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
	
	public void GetSoundAbility(char[] sSound, int length, const char[] sType)
	{
		if (strcmp(sType, "CFloatJump") == 0)
			strcopy(sSound, length, g_strPyrocarJump[GetRandomInt(0,sizeof(g_strPyrocarJump)-1)]);
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
			g_hPyrocarAmmoTimer[iClient] = null;
			
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
		for (int i = 0; i < sizeof(g_strPyrocarJump); i++) PrecacheSound(g_strPyrocarJump[i]);
		for (int i = 0; i < sizeof(g_strPyrocarKill); i++) PrepareSound(g_strPyrocarKill[i]);
		for (int i = 0; i < sizeof(g_strPyrocarKillBuilding); i++) PrepareSound(g_strPyrocarKillBuilding[i]);
		for (int i = 0; i < sizeof(g_strPyrocarLastMan); i++) PrepareSound(g_strPyrocarLastMan[i]);
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
			
			if (TF2_IsPlayerInCondition(iClient, TFCond_OnFire))
				TF2_RemoveCondition(iClient, TFCond_OnFire);
		}
	}
}

public Action Timer_RefillAmmo(Handle hTimer, int iClient)
{
	if (0 < iClient <= MaxClients && g_hPyrocarAmmoTimer[iClient] == hTimer)
	{
		g_hPyrocarAmmoTimer[iClient] = null;
		
		if (IsClientInGame(iClient))
		{
			TF2_SetAmmo(iClient, WeaponSlot_Primary, 5);
		}
	}
}
