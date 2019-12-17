/*
 * Pyromancer Duo Boss: Red Pyromancer
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

methodmap CPyromancerRed < SaxtonHaleBase
{
	public CPyromancerRed(CPyromancerRed boss)
	{
		boss.CallFunction("CreateAbility", "CBraveJump");
		
		//boostJump.flMaxHeigth /= 2.0;
		//boostJump.flMaxDistance = 0.7;
		
		boss.iBaseHealth = 500;
		boss.iHealthPerPlayer = 750;
		boss.nClass = TFClass_Pyro;
		boss.iMaxRageDamage = 1700;
	}
	
	public void GetBossName(char[] sName, int length)
	{
		strcopy(sName, length, "Scorched Pyromancer");
	}
	
	public void GetBossInfo(char[] sInfo, int length)
	{
		StrCat(sInfo, length, "\nDuo Boss: The Pyromancers");
		StrCat(sInfo, length, "\nMelee deals 80 damage");
		StrCat(sInfo, length, "\nHealth: Low");
		StrCat(sInfo, length, "\n ");
		StrCat(sInfo, length, "\nAbilities");
		StrCat(sInfo, length, "\n- Boost Jump");
		StrCat(sInfo, length, "\n ");
		StrCat(sInfo, length, "\nRage");
		StrCat(sInfo, length, "\n- Ignite all players within 500 units");
		StrCat(sInfo, length, "\n- 200%% Rage: Ignite all players on the map");
	}
	
	public void OnSpawn()
	{
		const int TF_WEAPON_SHARPENED_VOLCANO_FRAGMENT = 348;
		int iWeapon = this.CallFunction("CreateWeapon", TF_WEAPON_SHARPENED_VOLCANO_FRAGMENT, "tf_weapon_fireaxe", 100, TFQual_Collectors, "2 ; 1.54 ; 208 ; 1.0 ; 252 ; 0.5");
		if (iWeapon > MaxClients)
			SetEntPropEnt(this.iClient, Prop_Send, "m_hActiveWeapon", iWeapon);
		/*
		Fragment attributes:
		
		2: damage bonus
		208: ignite target on hit
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
					SetEntityRenderColor(iWearable, 255, 0, 0, 200);
				}
				
				if (i == 3) //Cauterizer's Caudal Appendage
				{
					SetEntityRenderColor(iWearable, 255, 0, 0, 255);
				}
			}
		}
		
		PrintHintText(this.iClient, "HINT: Stay near the other Pyromancer so they can crit ignited players!");
	}
	
	public void OnRage()
	{
		const float RAGE_RADIUS = 750.0;
		const float RAGE_DURATION = 8.0;
		
		int iClient = this.iClient;
		int bossTeam = GetClientTeam(iClient);
		float vecPos[3], vecTargetPos[3];
		GetClientAbsOrigin(iClient, vecPos);
		
		TF2_AddCondition(this.iClient, view_as<TFCond>(26), RAGE_DURATION);
		
		for (int iVictim = 1; iVictim <= MaxClients; iVictim++)
		{
			if (IsClientInGame(iVictim) && IsPlayerAlive(iVictim) && GetClientTeam(iVictim) != bossTeam && !TF2_IsUbercharged(iVictim))
			{
				GetClientAbsOrigin(iVictim, vecTargetPos);
				
				float flDistance = GetVectorDistance(vecTargetPos, vecPos);
				
				if (this.bSuperRage || flDistance <= RAGE_RADIUS)
					TF2_IgnitePlayer(iVictim, iClient, 8.0);
			}
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