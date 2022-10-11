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

public void Samyro_Create(SaxtonHaleBase boss)
{
	boss.CreateClass("WallClimb");
	
	boss.CreateClass("AddCond");
	AddCond_AddCond(boss, TFCond_RuneAgility);
	boss.SetPropInt("AddCond", "RemoveOnRage", true);
	
	boss.CreateClass("RageAddCond");
	boss.SetPropFloat("RageAddCond", "RageCondDuration", 12.0);
	boss.SetPropFloat("RageAddCond", "RageCondSuperRageMultiplier", 14.0 / 12.0);
	RageAddCond_AddCond(boss, TFCond_RuneHaste);
	RageAddCond_AddCond(boss, TFCond_DefenseBuffed);
	RageAddCond_AddCond(boss, TFCond_Ubercharged, true);
	
	boss.iBaseHealth = 700;
	boss.iHealthPerPlayer = 650;
	boss.nClass = TFClass_Pyro;
	boss.iMaxRageDamage = 2500;
}

public void Samyro_GetBossName(SaxtonHaleBase boss, char[] sName, int length)
{
	strcopy(sName, length, "Samyro");
}

public void Samyro_GetBossInfo(SaxtonHaleBase boss, char[] sInfo, int length)
{
	StrCat(sInfo, length, "\nHealth: Low");
	StrCat(sInfo, length, "\n ");
	StrCat(sInfo, length, "\nAbilities");
	StrCat(sInfo, length, "\n- Passive Rage Gain");
	StrCat(sInfo, length, "\n- Wall Climb");
	StrCat(sInfo, length, "\n- Agility powerup on secondary attack");
	StrCat(sInfo, length, "\n ");
	StrCat(sInfo, length, "\nRage");
	StrCat(sInfo, length, "\n- Gain the Haste powerup and a defensive buff for 12 seconds");
	StrCat(sInfo, length, "\n- Rage overrides Agility powerup");
	StrCat(sInfo, length, "\n- 200%% Rage: Become übercharged and extend duration by 2 seconds");
}

public void Samyro_OnSpawn(SaxtonHaleBase boss)
{
	char attribs[128];
	Format(attribs, sizeof(attribs), "2 ; 2.80 ; 252 ; 0.5 ; 259 ; 1.0 ; 180 ; 0.0 ; 226 ; 0.0"); 
	int iWeapon = boss.CallFunction("CreateWeapon", 357, "tf_weapon_katana", 100, TFQual_Collectors, attribs);
	if (iWeapon > MaxClients)
	{
		SetEntProp(iWeapon, Prop_Send, "m_nModelIndexOverrides", g_iSamyroModelKatana);
		
		int iViewModel = CreateViewModel(boss.iClient, g_iSamyroModelKatana);
		SetEntPropEnt(iViewModel, Prop_Send, "m_hWeaponAssociatedWith", iWeapon);
		SetEntPropEnt(iWeapon, Prop_Send, "m_hExtraWearableViewModel", iViewModel);
		
		CreateViewModel(boss.iClient, g_iSamyroModelHands);
		SetEntProp(GetEntPropEnt(boss.iClient, Prop_Send, "m_hViewModel"), Prop_Send, "m_fEffects", EF_NODRAW);
		
		SetEntPropEnt(boss.iClient, Prop_Send, "m_hActiveWeapon", iWeapon);
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
	
	iWearable = boss.CallFunction("CreateWeapon", 627, "tf_wearable", 1, TFQual_Collectors, ""); //The Flamboyant Flamenco
	if (iWearable > MaxClients)
		SetEntProp(iWearable, Prop_Send, "m_nModelIndexOverrides", g_iSamyroModelHat);
	
	iWearable = boss.CallFunction("CreateWeapon", 570, "tf_wearable", 1, TFQual_Collectors, ""); //The Last Breath
	if (iWearable > MaxClients)
		SetEntProp(iWearable, Prop_Send, "m_nModelIndexOverrides", g_iSamyroModelMask);
}

public void Samyro_OnThink(SaxtonHaleBase boss)
{
	if (GameRules_GetRoundState() == RoundState_Preround)
		return;
	
	//Passive rage gain
	if (g_flClientRageGainLastTime[boss.iClient] <= GetGameTime() - 0.05)
	{
		boss.CallFunction("AddRage", 1);
		g_flClientRageGainLastTime[boss.iClient] = GetGameTime();
	}
}

public void Samyro_OnRage(SaxtonHaleBase boss)
{
	//Prevent boss from using secondary ability while rage is active by adding duration to cooldown
	if (boss.HasClass("AddCond") && boss.HasClass("RageAddCond"))
	{
		float flRageDuration = boss.bSuperRage ? boss.GetPropFloat("RageAddCond", "RageCondDuration") * boss.GetPropFloat("RageAddCond", "RageCondSuperRageMultiplier") : boss.GetPropFloat("RageAddCond", "RageCondDuration");
		boss.SetPropFloat("AddCond", "CondCooldownWait", boss.GetPropFloat("AddCond", "CondCooldownWait") + flRageDuration);
	}
}

public void Samyro_GetSound(SaxtonHaleBase boss, char[] sSound, int length, SaxtonHaleSound iSoundType)
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

public void Samyro_GetSoundAbility(SaxtonHaleBase boss, char[] sSound, int length, const char[] sType)
{
	if (strcmp(sType, "AddCond") == 0)
		strcopy(sSound, length, g_strSamyroAbility[GetRandomInt(0, sizeof(g_strSamyroAbility) - 1)]);
}

public void Samyro_GetSoundKill(SaxtonHaleBase boss, char[] sSound, int length, TFClassType nClass)
{
	strcopy(sSound, length, g_strSamyroKill[GetRandomInt(0, sizeof(g_strSamyroKill) - 1)]);
}

public void Samyro_GetMusicInfo(SaxtonHaleBase boss, char[] sSound, int length, float &time)
{
	strcopy(sSound, length, SAMYRO_MUSIC);
	time = 195.0;
}

public void Samyro_Precache(SaxtonHaleBase boss)
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

public bool Samyro_IsBossHidden(SaxtonHaleBase boss)
{
	return true;
}