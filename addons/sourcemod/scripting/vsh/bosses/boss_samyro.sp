#define SAMYRO_MUSIC	"vsh_rewrite/samyro/samyro_music.mp3"

static int g_iSamyroModelHat;
static int g_iSamyroModelMask;
static int g_iSamyroModelKatana;
static int g_iSamyroModelHands;

static float g_flClientRageGainLastTime[TF_MAXPLAYERS + 1];

static char g_strSamyroRoundStart[][] =  {
	"vo/pyro_battlecry01.mp3", 
	"vo/pyro_battlecry02.mp3"
};

static char g_strSamyroRoundWin[][] =  {
	"vo/taunts/pyro/pyro_taunt_head_pain_21.mp3", 
	"vo/taunts/pyro/pyro_taunt_head_pain_22.mp3"
};

static char g_strSamyroRoundLose[][] =  {
	"vo/pyro_paincrticialdeath01.mp3", 
	"vo/pyro_paincrticialdeath02.mp3", 
	"vo/pyro_paincrticialdeath03.mp3", 
	"vo/taunts/pyro/pyro_taunt_rps_lose_03.mp3"
};

static char g_strSamyroRage[][] =  {
	"vo/pyro_laughlong01.mp3"
};

static char g_strSamyroKill[][] =  {
	"vo/taunts/pyro_taunts01.mp3", 
	"vo/taunts/pyro_taunts02.mp3", 
	"vo/taunts/pyro_taunts03.mp3", 
	"vo/taunts/pyro_taunts04.mp3", 
	"vo/compmode/cm_pyro_pregamelostlast_02.mp3", 
	"vo/compmode/cm_pyro_pregamelostlast_03.mp3"
};

static char g_strSamyroLastMan[][] =  {
	"vo/cm_pyro_pregamewonlast_01.mp3"
};

static char g_strSamyroAbility[][] =  {
	"items/samurai/tf_samurai_noisemaker_seta_01.wav", 
	"items/samurai/tf_samurai_noisemaker_seta_02.wav", 
	"items/samurai/tf_samurai_noisemaker_seta_03.wav"
};

methodmap CSamyro < SaxtonHaleBase
{
	public CSamyro(CSamyro boss)
	{
		boss.CallFunction("CreateAbility", "CWallClimb");
		
		CAddCond abilityCond = boss.CallFunction("CreateAbility", "CAddCond");
		abilityCond.AddCond(TFCond_RuneAgility);
		abilityCond.bRemoveOnRage = true;
		
		CRageAddCond rageCond = boss.CallFunction("CreateAbility", "CRageAddCond");
		rageCond.flRageCondDuration = 12.0;
		rageCond.flRageCondSuperRageMultiplier = 14.0 / 12.0;
		rageCond.AddCond(TFCond_RuneHaste);
		rageCond.AddCond(TFCond_DefenseBuffed);
		
		boss.iBaseHealth = 700;
		boss.iHealthPerPlayer = 650;
		boss.nClass = TFClass_Pyro;
		boss.iMaxRageDamage = 2500;
		
		AddCommandListener(Command_DropItem, "dropitem");
	}
	
	public void GetBossName(char[] sName, int length)
	{
		strcopy(sName, length, "Samyro");
	}
	
	public void GetBossInfo(char[] sInfo, int length)
	{
		StrCat(sInfo, length, "\nHealth: Low");
		StrCat(sInfo, length, "\n ");
		StrCat(sInfo, length, "\nAbilities");
		StrCat(sInfo, length, "\n- Passive Rage Gain");
		StrCat(sInfo, length, "\n- Wall Climb");
		StrCat(sInfo, length, "\n- Agility");
		StrCat(sInfo, length, "\n ");
		StrCat(sInfo, length, "\nRage");
		StrCat(sInfo, length, "\n- Gain the Haste powerup and a defensive buff for 12 seconds");
		StrCat(sInfo, length, "\n- Rage overrides Agility");
		StrCat(sInfo, length, "\n- 200%% Rage: Become übercharged and extend duration by 2 seconds");
	}
	
	public void OnSpawn()
	{
		char attribs[128];
		Format(attribs, sizeof(attribs), "2 ; 2.80 ; 252 ; 0.5 ; 259 ; 1.0 ; 180 ; 0.0 ; 226 ; 0.0"); 
		int iWeapon = this.CallFunction("CreateWeapon", 357, "tf_weapon_katana", 100, TFQual_Collectors, attribs);
		if (iWeapon > MaxClients)
		{
			SetEntProp(iWeapon, Prop_Send, "m_nModelIndexOverrides", g_iSamyroModelKatana);
			
			int iViewModel = CreateViewModel(this.iClient, g_iSamyroModelKatana);
			SetEntPropEnt(iViewModel, Prop_Send, "m_hWeaponAssociatedWith", iWeapon);
			SetEntPropEnt(iWeapon, Prop_Send, "m_hExtraWearableViewModel", iViewModel);
			
			CreateViewModel(this.iClient, g_iSamyroModelHands);
			SetEntProp(GetEntPropEnt(this.iClient, Prop_Send, "m_hViewModel"), Prop_Send, "m_fEffects", EF_NODRAW);
			
			SetEntPropEnt(this.iClient, Prop_Send, "m_hActiveWeapon", iWeapon);
		}
		/*
		Half-Zatoichi attributes:
		
		2: damage bonus
		252: reduction in push force taken from damage
		259: deals 3x falling damage to the player you land on
		180: 0% health restored on kill
		226: not honorbound
		*/
		
		int iWearable = -1;
		
		iWearable = this.CallFunction("CreateWeapon", 627, "tf_wearable", 1, TFQual_Collectors, ""); //The Flamboyant Flamenco
		if (iWearable > MaxClients)
			SetEntProp(iWearable, Prop_Send, "m_nModelIndexOverrides", g_iSamyroModelHat);
		
		iWearable = this.CallFunction("CreateWeapon", 570, "tf_wearable", 1, TFQual_Collectors, ""); //The Last Breath
		if (iWearable > MaxClients)
			SetEntProp(iWearable, Prop_Send, "m_nModelIndexOverrides", g_iSamyroModelMask);
	}
	
	public void OnThink()
	{
		if (GameRules_GetRoundState() == RoundState_Preround)
			return;
		
		//Passive rage gain
		if (g_flClientRageGainLastTime[this.iClient] <= GetGameTime() - 0.05)
		{
			this.CallFunction("AddRage", 1);
			g_flClientRageGainLastTime[this.iClient] = GetGameTime();
		}
	}
	
	public void OnRage()
	{
		//Übercharge on 200% rage
		if (this.bSuperRage)
		{
			CRageAddCond rageCond = this.CallFunction("FindAbility", "CRageAddCond");
			if (rageCond != INVALID_ABILITY)
			{
				TF2_AddCondition(this.iClient, TFCond_Ubercharged, rageCond.flRageCondDuration * rageCond.flRageCondSuperRageMultiplier);
			}
		}
	}
	
	public void GetSound(char[] sSound, int length, SaxtonHaleSound iSoundType)
	{
		switch (iSoundType)
		{
			case VSHSound_RoundStart: strcopy(sSound, length, g_strSamyroRoundStart[GetRandomInt(0, sizeof(g_strSamyroRoundStart) - 1)]);
			case VSHSound_Win: strcopy(sSound, length, g_strSamyroRoundWin[GetRandomInt(0, sizeof(g_strSamyroRoundWin) - 1)]);
			case VSHSound_Lose: strcopy(sSound, length, g_strSamyroRoundLose[GetRandomInt(0, sizeof(g_strSamyroRoundLose) - 1)]);
			case VSHSound_Rage: strcopy(sSound, length, g_strSamyroRage[GetRandomInt(0, sizeof(g_strSamyroRage) - 1)]);
			case VSHSound_Lastman: strcopy(sSound, length, g_strSamyroLastMan[GetRandomInt(0, sizeof(g_strSamyroLastMan) - 1)]);
		}
	}
	
	public void GetSoundAbility(char[] sSound, int length, const char[] sType)
	{
		if (strcmp(sType, "CAddCond") == 0)
			strcopy(sSound, length, g_strSamyroAbility[GetRandomInt(0, sizeof(g_strSamyroAbility) - 1)]);
	}
	
	public void GetSoundKill(char[] sSound, int length, TFClassType nClass)
	{
		strcopy(sSound, length, g_strSamyroKill[GetRandomInt(0, sizeof(g_strSamyroKill) - 1)]);
	}
	
	public void GetMusicInfo(char[] sSound, int length, float &time)
	{
		strcopy(sSound, length, SAMYRO_MUSIC);
		time = 195.0;
	}
	
	public void Precache()
	{
		g_iSamyroModelHat = PrecacheModel("models/player/items/pyro/fwk_pyro_flamenco.mdl");
		g_iSamyroModelMask = PrecacheModel("models/workshop/player/items/pyro/pyro_halloween_gasmask/pyro_halloween_gasmask.mdl");
		g_iSamyroModelKatana = PrecacheModel("models/workshop_partner/weapons/c_models/c_shogun_katana/c_shogun_katana.mdl");
		g_iSamyroModelHands = PrecacheModel("models/weapons/c_models/c_pyro_arms.mdl");
		
		PrepareSound(SAMYRO_MUSIC);
		
		for (int i = 0; i < sizeof(g_strSamyroRoundStart); i++) PrecacheSound(g_strSamyroRoundStart[i]);
		for (int i = 0; i < sizeof(g_strSamyroRoundWin); i++) PrecacheSound(g_strSamyroRoundWin[i]);
		for (int i = 0; i < sizeof(g_strSamyroRoundLose); i++) PrecacheSound(g_strSamyroRoundLose[i]);
		for (int i = 0; i < sizeof(g_strSamyroRage); i++) PrecacheSound(g_strSamyroRage[i]);
		for (int i = 0; i < sizeof(g_strSamyroKill); i++) PrecacheSound(g_strSamyroKill[i]);
		for (int i = 0; i < sizeof(g_strSamyroLastMan); i++) PrecacheSound(g_strSamyroLastMan[i]);
		for (int i = 0; i < sizeof(g_strSamyroAbility); i++) PrecacheSound(g_strSamyroAbility[i]);
	}
	
	public bool IsBossHidden()
	{
		return true;
	}
};

public Action Command_DropItem(int iClient, const char[] sCommand, int iArgs)
{
	//Prevent boss from dropping powerups
	if (SaxtonHaleBase(iClient).bValid)
		return Plugin_Handled;
	
	return Plugin_Continue;
}
