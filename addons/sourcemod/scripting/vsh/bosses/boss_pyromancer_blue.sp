/*
 * Pyromancer Duo Boss: Blue Pyromancer
 * By: ScrewdriverHyena
**/

static char g_strPyromancerRoundStart[][] = 
{
	"vo/pyro_laughevil01.mp3",
	"vo/pyro_laughevil02.mp3",
	"vo/pyro_laughevil03.mp3",
	"vo/pyro_laughevil04.mp3"
};

static char g_strPyromancerRage[][] = 
{
	"vo/pyro_battlecry01.mp3",
	"vo/pyro_battlecry02.mp3",
};

static char g_strPyromancerKill[][] = 
{
	"vo/pyro_cheers01.mp3",
	"vo/pyro_goodjob01.mp3"
};

static char g_strPyromancerJump[][] = 
{
	"vo/pyro_jeers01.mp3",
	"vo/pyro_jeers02.mp3"
};

static char g_strPrecacheCosmetics[][] =
{
	"models/player/items/pyro/pyro_pyromancers_mask.mdl",
	"models/player/items/pyro/hwn_pyro_misc1.mdl",
	"models/player/items/pyro/sore_eyes.mdl",
	"models/workshop/player/items/pyro/hw2013_dragonbutt/hw2013_dragonbutt.mdl"
};

static int g_iCosmetics[] =
{
	316,
	550,
	387,
	30225
};

static int g_iPrecacheCosmetics[4];

static float g_flFlamethrowerRemoveTime[TF_MAXPLAYERS];

methodmap CPyromancerBlue < SaxtonHaleBase
{
	public CPyromancerBlue(CPyromancerBlue boss)
	{
		boss.CallFunction("CreateAbility", "CBraveJump");
		
		//boostJump.flMaxHeigth /= 1.75;
		//boostJump.flMaxDistance = 0.7;
		
		boss.iBaseHealth = 500;
		boss.iHealthPerPlayer = 750;
		boss.nClass = TFClass_Pyro;
		boss.iMaxRageDamage = 1700;
		g_flFlamethrowerRemoveTime[boss.iClient] = 0.0;
	}
	
	public void GetBossName(char[] sName, int length)
	{
		strcopy(sName, length, "Charged Pyromancer");
	}
	
	public void GetBossInfo(char[] sInfo, int length)
	{
		StrCat(sInfo, length, "\nDuo Boss: The Pyromancers");
		StrCat(sInfo, length, "\nMelee deals 80 damage.");
		StrCat(sInfo, length, "\nHealth: Low");
		StrCat(sInfo, length, "\n ");
		StrCat(sInfo, length, "\nAbilities");
		StrCat(sInfo, length, "\n- Boost Jump");
		StrCat(sInfo, length, "\n ");
		StrCat(sInfo, length, "\nRage");
		StrCat(sInfo, length, "\n- Grants a degreaser for 8 seconds");
		StrCat(sInfo, length, "\n- 200%% Rage: Grants a buffed backburner with quick-switch for 8 seconds");
	}
	
	public void OnSpawn()
	{
		const int TF_WEAPON_AXTINGUISHER = 38;
		int iWeapon = this.CallFunction("CreateWeapon", TF_WEAPON_AXTINGUISHER, "tf_weapon_fireaxe", 100, TFQual_Collectors, "2 ; 1.82 ; 20 ; 1.0 ; 252 ; 0.5");
		if (iWeapon > MaxClients)
			SetEntPropEnt(this.iClient, Prop_Send, "m_hActiveWeapon", iWeapon);
		
		/*
		Axtinguisher attributes:
		
		2: damage bonus
		20: crit vs burning players
		252: reduction in push force taken from damage
		*/
		
		for (int i = 0; i < sizeof(g_iCosmetics); i++)
		{
			int iWearable = this.CallFunction("CreateWeapon", g_iCosmetics[i], "tf_wearable", 1, TFQual_Collectors, "");
			if (iWearable > MaxClients)
			{
				SetEntProp(iWearable, Prop_Send, "m_nModelIndexOverrides", g_iPrecacheCosmetics[i]);
				
				if (i == 0) //Pyromancer's Mask
				{
					SetEntProp(iWearable, Prop_Send, "m_nSkin", 2);
					SetEntityRenderColor(iWearable, 0, 0, 255, 200);
				}
				
				if (i == 3) //Cauterizer's Caudal Appendage
				{
					SetEntityRenderColor(iWearable, 0, 0, 255, 255);
				}
			}
		}
		
		PrintHintText(this.iClient, "HINT: Stay near the other Pyromancer so you can crit the ignited players!");
	}
	
	public void OnRage()
	{
		const float RAGE_DURATION = 8.0;
		
		TF2_AddCondition(this.iClient, view_as<TFCond>(26), RAGE_DURATION);
		
		/*
		Degreaser attributes:
		
		72: reduce burn damage
		199: faster switch-from speed
		252: reduction in push force taken from damage
		547: faster switch-to speed
		839: flame spread degree
		841: flame gravity
		843: flame drag
		844: flame speed
		862: flame lifetime
		863: flame random life time offset
		865: flame up speed
		*/
		#define TF_DEGREASER_ATTRIBS "72 ; 0.75 ; 199 ; 0.7 ; 252 ; 0.5 ; 547 ; 0.4 ; 839 ; 2.8 ; 841 ; 0 ; 843 ; 8.5 ; 844 ; 2450 ; 862 ; 0.6 ; 863 ; 0.1 ; 865 ; 50"
		const int TF_WEAPON_DEGREASER = 215;

		/*
		Backburner attributes:
		
		24: allow crits from behind
		72: reduce burn damage
		199: faster switch-from speed
		252: reduction in push force taken from damage
		547: faster switch-to speed
		839: flame spread degree
		841: flame gravity
		843: flame drag
		844: flame speed
		862: flame lifetime
		863: flame random life time offset
		865: flame up speed
		*/
		#define TF_BACKBURNER_ATTRIBS "24 ; 1.0 ; 72 ; 0.1 ; 199 ; 0.9 ; 252 ; 0.5 ; 547 ; 0.9 ; 839 ; 2.8 ; 841 ; 0 ; 843 ; 8.5 ; 844 ; 2450 ; 862 ; 0.6 ; 863 ; 0.1 ; 865 ; 50"
		const int TF_WEAPON_BACKBURNER = 40;
		
		PrintHintText(this.iClient, "HINT: Use your axe to crit players after igniting them!");
		
		int iWeapon = this.CallFunction("CreateWeapon", ((this.bSuperRage) ? TF_WEAPON_BACKBURNER : TF_WEAPON_DEGREASER), "tf_weapon_flamethrower", 1, TFQual_Collectors, ((this.bSuperRage) ? TF_BACKBURNER_ATTRIBS : TF_DEGREASER_ATTRIBS));
		if (iWeapon > MaxClients)
		{
			SetEntPropEnt(this.iClient, Prop_Send, "m_hActiveWeapon", iWeapon);
			
			int iAmmoType = GetEntProp(iWeapon, Prop_Send, "m_iPrimaryAmmoType");
			if (iAmmoType > -1)
				SetEntProp(this.iClient, Prop_Send, "m_iAmmo", 999, 4, iAmmoType);
		}
		
		g_flFlamethrowerRemoveTime[this.iClient] = GetGameTime() + RAGE_DURATION;
	}
	
	public void OnThink()
	{
		if (g_flFlamethrowerRemoveTime[this.iClient] != 0.0 && g_flFlamethrowerRemoveTime[this.iClient] <= GetGameTime())
		{
			g_flFlamethrowerRemoveTime[this.iClient] = 0.0;
			TF2_RemoveWeaponSlot(this.iClient, WeaponSlot_Primary);
			
			int iMeleeWep = GetPlayerWeaponSlot(this.iClient, WeaponSlot_Melee);
			if (iMeleeWep > MaxClients)
				SetEntPropEnt(this.iClient, Prop_Send, "m_hActiveWeapon", iMeleeWep);
		}
	}
	
	public void GetSound(char[] sSound, int length, SaxtonHaleSound iSoundType)
	{
		switch (iSoundType)
		{
			case VSHSound_RoundStart: strcopy(sSound, length, g_strPyromancerRoundStart[GetRandomInt(0,sizeof(g_strPyromancerRoundStart)-1)]);
			case VSHSound_Rage: strcopy(sSound, length, g_strPyromancerRage[GetRandomInt(0,sizeof(g_strPyromancerRage)-1)]);
			case VSHSound_Lastman: strcopy(sSound, length, "vo/pyro_battlecry01.mp3");
			case VSHSound_Win: strcopy(sSound, length, "vo/pyro_cheers01.mp3");
			case VSHSound_Lose: strcopy(sSound, length, "vo/pyro_jeers01.mp3");
			case VSHSound_Backstab: strcopy(sSound, length, "vo/pyro_jeers02.mp3");
		}
	}
	
	public void GetSoundAbility(char[] sSound, int length, const char[] sType)
	{
		if (strcmp(sType, "CBraveJump") == 0)
			strcopy(sSound, length, g_strPyromancerJump[GetRandomInt(0,sizeof(g_strPyromancerJump)-1)]);
	}	
	
	public void GetSoundKill(char[] sSound, int length, TFClassType nClass)
	{
		strcopy(sSound, length, g_strPyromancerKill[GetRandomInt(0,sizeof(g_strPyromancerKill)-1)]);
	}
	
	public void Precache()
	{
		for (int i = 0; i < sizeof(g_iCosmetics); i++)
			g_iPrecacheCosmetics[i] = PrecacheModel(g_strPrecacheCosmetics[i]);
	
		for (int i = 0; i < sizeof(g_strPyromancerRoundStart); i++) PrecacheSound(g_strPyromancerRoundStart[i]);
		for (int i = 0; i < sizeof(g_strPyromancerRage); i++) PrecacheSound(g_strPyromancerRage[i]);
		for (int i = 0; i < sizeof(g_strPyromancerKill); i++) PrecacheSound(g_strPyromancerKill[i]);
		for (int i = 0; i < sizeof(g_strPyromancerJump); i++) PrecacheSound(g_strPyromancerJump[i]);
	}
}