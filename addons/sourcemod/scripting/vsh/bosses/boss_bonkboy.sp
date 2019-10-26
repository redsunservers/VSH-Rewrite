static int g_iBonkBoyModelHelmet;
static int g_iBonkBoyModelMask;
static int g_iBonkBoyModelBag;
/*
static char g_strBonkBoyRoundStart[][] = {
	
};

static char g_strBonkBoyWin[][] = {
	
};

static char g_strBonkBoyLose[][] = {
	
};

static char g_strBonkBoyRage[][] = {
	
};

static char g_strBonkBoyJump[][] = {
	
};

static char g_strBonkBoyKillScout[][] = {
	
};

static char g_strBonkBoyKillSoldier[][] = {
	
};

static char g_strBonkBoyKillPyro[][] = {
	
};

static char g_strBonkBoyKillDemoman[][] = {
	
};

static char g_strBonkBoyKillHeavy[][] = {
	
};

static char g_strBonkBoyKillEngineer[][] = {
	
};

static char g_strBonkBoyKillMedic[][] = {
	
};

static char g_strBonkBoyKillSniper[][] = {
	
};

static char g_strBonkBoyKillSpy[][] = {
	
};

static char g_strBonkBoyKillBuilding[][] = {
	
};

static char g_strBonkBoyLastMan[][] = {
	
};

static char g_strBonkBoyBackStabbed[][] = {
	
};
*/
methodmap CBonkBoy < SaxtonHaleBase
{
	public CBonkBoy(CBonkBoy boss)
	{
		boss.CallFunction("CreateAbility", "CDashJump");
		
		boss.iBaseHealth = 700;
		boss.iHealthPerPlayer = 650;
		boss.nClass = TFClass_Scout;
		boss.iMaxRageDamage = 2000;
		
		boss.flSpeed = 370.0;
	}
	
	public void GetBossName(char[] sName, int length)
	{
		strcopy(sName, length, "Bonk Boy");
	}
	
	public void GetBossInfo(char[] sInfo, int length)
	{
		StrCat(sInfo, length, "\nHealth: Low");
		StrCat(sInfo, length, "\n ");
		StrCat(sInfo, length, "\nAbilities");
		StrCat(sInfo, length, "\n- Faster speed movement");
		StrCat(sInfo, length, "\n ");
		StrCat(sInfo, length, "\nRage");
		StrCat(sInfo, length, "\n- ");
		StrCat(sInfo, length, "\n- 200%% Rage: ");
	}
	
	public void OnSpawn()
	{
		char attribs[128];
		Format(attribs, sizeof(attribs), "2 ; 2.80 ; 252 ; 0.5 ; 259 ; 1.0 ; 329 ; 0.65");	// ; 278 ; 0.0
		int iWeapon = this.CallFunction("CreateWeapon", 44, "tf_weapon_bat_wood", 1, TFQual_Collectors, attribs);
		if (iWeapon > MaxClients)
		{
			SetEntPropFloat(iWeapon, Prop_Send, "m_flEffectBarRegenTime", 0.0);	//Set meter to 0
			SetEntPropEnt(this.iClient, Prop_Send, "m_hActiveWeapon", iWeapon);
			
			//Set ball count to 0
			int iAmmoType = GetEntProp(iWeapon, Prop_Send, "m_iPrimaryAmmoType");
			if (iAmmoType > -1)
				SetEntProp(this.iClient, Prop_Send, "m_iAmmo", 0, 4, iAmmoType);
		}

		/*
		Sandman attributes:
		
		2: damage bonus
		252: reduction in push force taken from damage
		259: Deals 3x falling damage to the player you land on
		329: reduction in airblast vulnerability
		
		278: increase in recharge rate
		*/
		
		int iWearable = -1;
		
		iWearable = this.CallFunction("CreateWeapon", 106, "tf_wearable", 1, TFQual_Collectors, "");	//Bonk Helm
		if (iWearable > MaxClients)
			SetEntProp(iWearable, Prop_Send, "m_nModelIndexOverrides", g_iBonkBoyModelHelmet);
		
		iWearable = this.CallFunction("CreateWeapon", 451, "tf_wearable", 1, TFQual_Collectors, "");	//Bonk Boy
		if (iWearable > MaxClients)
			SetEntProp(iWearable, Prop_Send, "m_nModelIndexOverrides", g_iBonkBoyModelMask);
		
		iWearable = this.CallFunction("CreateWeapon", 30751, "tf_wearable", 1, TFQual_Collectors, "");	//Bonk Batter's Backup
		if (iWearable > MaxClients)
			SetEntProp(iWearable, Prop_Send, "m_nModelIndexOverrides", g_iBonkBoyModelBag);
	}
	
	public void OnThink()
	{
		//Set sandman meter to 0
		int iWeapon = TF2_GetItemInSlot(this.iClient, WeaponSlot_Melee);
		if (iWeapon > MaxClients)
			SetEntPropFloat(iWeapon, Prop_Send, "m_flEffectBarRegenTime", 0.0);
	}
	
	public void OnRage()
	{
		//Add 10 balls
		int iWeapon = TF2_GetItemInSlot(this.iClient, WeaponSlot_Melee);
		if (iWeapon > MaxClients)
		{
			int iAmmoType = GetEntProp(iWeapon, Prop_Send, "m_iPrimaryAmmoType");
			if (iAmmoType > -1)
			{
				int iAmmo = GetEntProp(this.iClient, Prop_Send, "m_iAmmo", 4, iAmmoType);
				SetEntProp(this.iClient, Prop_Send, "m_iAmmo", iAmmo+10, 4, iAmmoType);
			}
		}
	}
	/*
	public void GetSound(char[] sSound, int length, SaxtonHaleSound iSoundType)
	{
		switch (iSoundType)
		{
			case VSHSound_RoundStart: strcopy(sSound, length, g_strBonkBoyRoundStart[GetRandomInt(0,sizeof(g_strBonkBoyRoundStart)-1)]);
			case VSHSound_Win: strcopy(sSound, length, g_strBonkBoyWin[GetRandomInt(0,sizeof(g_strBonkBoyWin)-1)]);
			case VSHSound_Lose: strcopy(sSound, length, g_strBonkBoyLose[GetRandomInt(0,sizeof(g_strBonkBoyLose)-1)]);
			case VSHSound_Rage: strcopy(sSound, length, g_strBonkBoyRage[GetRandomInt(0,sizeof(g_strBonkBoyRage)-1)]);
			case VSHSound_KillBuilding: strcopy(sSound, length, g_strBonkBoyKillBuilding[GetRandomInt(0,sizeof(g_strBonkBoyKillBuilding)-1)]);
			case VSHSound_Lastman: strcopy(sSound, length, g_strBonkBoyLastMan[GetRandomInt(0,sizeof(g_strBonkBoyLastMan)-1)]);
			case VSHSound_Backstab: strcopy(sSound, length, g_strBonkBoyBackStabbed[GetRandomInt(0,sizeof(g_strBonkBoyBackStabbed)-1)]);
		}
	}
	
	public void GetSoundKill(char[] sSound, int length, TFClassType nClass)
	{
		switch (nClass)
		{
			case TFClass_Scout: strcopy(sSound, length, g_strBonkBoyKillScout[GetRandomInt(0,sizeof(g_strBonkBoyKillScout)-1)]);
			case TFClass_Soldier: strcopy(sSound, length, g_strBonkBoyKillSoldier[GetRandomInt(0,sizeof(g_strBonkBoyKillSoldier)-1)]);
			case TFClass_Pyro: strcopy(sSound, length, g_strBonkBoyKillPyro[GetRandomInt(0,sizeof(g_strBonkBoyKillPyro)-1)]);
			case TFClass_DemoMan: strcopy(sSound, length, g_strBonkBoyKillDemoman[GetRandomInt(0,sizeof(g_strBonkBoyKillDemoman)-1)]);
			case TFClass_Heavy: strcopy(sSound, length, g_strBonkBoyKillHeavy[GetRandomInt(0,sizeof(g_strBonkBoyKillHeavy)-1)]);
			case TFClass_Engineer: strcopy(sSound, length, g_strBonkBoyKillEngineer[GetRandomInt(0,sizeof(g_strBonkBoyKillEngineer)-1)]);
			case TFClass_Medic: strcopy(sSound, length, g_strBonkBoyKillMedic[GetRandomInt(0,sizeof(g_strBonkBoyKillMedic)-1)]);
			case TFClass_Sniper: strcopy(sSound, length, g_strBonkBoyKillSniper[GetRandomInt(0,sizeof(g_strBonkBoyKillSniper)-1)]);
			case TFClass_Spy: strcopy(sSound, length, g_strBonkBoyKillSpy[GetRandomInt(0,sizeof(g_strBonkBoyKillSpy)-1)]);
		}
	}
	*/
	public void Precache()
	{
		g_iBonkBoyModelHelmet = PrecacheModel("models/player/items/scout/bonk_helmet.mdl");
		g_iBonkBoyModelMask = PrecacheModel("models/workshop/player/items/scout/bonk_mask/bonk_mask.mdl");
		g_iBonkBoyModelBag = PrecacheModel("models/workshop/player/items/scout/dec15_scout_baseball_bag/dec15_scout_baseball_bag.mdl");
		/*
		for (int i = 0; i < sizeof(g_strBonkBoyRoundStart); i++) PrepareSound(g_strBonkBoyRoundStart[i]);
		for (int i = 0; i < sizeof(g_strBonkBoyWin); i++) PrepareSound(g_strBonkBoyWin[i]);
		for (int i = 0; i < sizeof(g_strBonkBoyLose); i++) PrepareSound(g_strBonkBoyLose[i]);
		for (int i = 0; i < sizeof(g_strBonkBoyRage); i++) PrepareSound(g_strBonkBoyRage[i]);
		for (int i = 0; i < sizeof(g_strBonkBoyJump); i++) PrepareSound(g_strBonkBoyJump[i]);
		for (int i = 0; i < sizeof(g_strBonkBoyKillScout); i++) PrepareSound(g_strBonkBoyKillScout[i]);
		for (int i = 0; i < sizeof(g_strBonkBoyKillSoldier); i++) PrepareSound(g_strBonkBoyKillSoldier[i]);
		for (int i = 0; i < sizeof(g_strBonkBoyKillPyro); i++) PrepareSound(g_strBonkBoyKillPyro[i]);
		for (int i = 0; i < sizeof(g_strBonkBoyKillDemoman); i++) PrepareSound(g_strBonkBoyKillDemoman[i]);
		for (int i = 0; i < sizeof(g_strBonkBoyKillHeavy); i++) PrepareSound(g_strBonkBoyKillHeavy[i]);
		for (int i = 0; i < sizeof(g_strBonkBoyKillEngineer); i++) PrepareSound(g_strBonkBoyKillEngineer[i]);
		for (int i = 0; i < sizeof(g_strBonkBoyKillMedic); i++) PrepareSound(g_strBonkBoyKillMedic[i]);
		for (int i = 0; i < sizeof(g_strBonkBoyKillSniper); i++) PrepareSound(g_strBonkBoyKillSniper[i]);
		for (int i = 0; i < sizeof(g_strBonkBoyKillSpy); i++) PrepareSound(g_strBonkBoyKillSpy[i]);
		for (int i = 0; i < sizeof(g_strBonkBoyKillBuilding); i++) PrepareSound(g_strBonkBoyKillBuilding[i]);
		for (int i = 0; i < sizeof(g_strBonkBoyLastMan); i++) PrepareSound(g_strBonkBoyLastMan[i]);
		for (int i = 0; i < sizeof(g_strBonkBoyBackStabbed); i++) PrepareSound(g_strBonkBoyBackStabbed[i]);
		*/
	}
};