static int g_iBonkBoyModelHelmet;
static int g_iBonkBoyModelMask;
static int g_iBonkBoyModelShirt;
static int g_iBonkBoyModelBag;

static int g_iBonkBoyStunType;

static bool g_bBonkBoyRage[TF_MAXPLAYERS+1];
static float g_flBonkBoyStunTime[TF_MAXPLAYERS+1];
static int g_iBonkBoyBallThrower[TF_MAXPLAYERS+1];

static char g_strBonkBoyRoundStart[][] = {
	"vo/scout_sf12_goodmagic07.mp3",
};

static char g_strBonkBoyWin[][] = {
	"vo/scout_domination14.mp3",
	"vo/scout_jeers07.mp3",
	"vo/taunts/scout_taunts13.mp3",
};

static char g_strBonkBoyLose[][] = {
	"vo/scout_painsevere01.mp3",
};

static char g_strBonkBoyRage[][] = {
	"vo/scout_apexofjump02.mp3",
	"vo/scout_cheers04.mp3",
	"vo/scout_sf12_badmagic11.mp3",
	"vo/scout_sf12_goodmagic03.mp3",
};

static char g_strBonkBoyKill[][] = {
	"vo/scout_domination03.mp3",
	"vo/scout_domination07.mp3",
	"vo/scout_dominationhvy10.mp3",
	"vo/scout_misc09.mp3",
	"vo/scout_revenge02.mp3",
	"vo/scout_revenge03.mp3",
	"vo/scout_specialcompleted01.mp3",
	"vo/scout_specialcompleted02.mp3",
	"vo/scout_specialcompleted03.mp3",
	"vo/scout_specialcompleted04.mp3",
	"vo/taunts/scout_taunts01.mp3",
	"vo/taunts/scout_taunts18.mp3",
};

static char g_strBonkBoyLastMan[][] = {
	"vo/scout_domination05.mp3",
	"vo/scout_domination06.mp3",
	"vo/scout_domination17.mp3",
	"vo/scout_cartgoingbackdefense05.mp3",
};

static char g_strBonkBoyBackStabbed[][] = {
	"vo/scout_autodejectedtie01.mp3",
	"vo/scout_autodejectedtie04.mp3",
	"vo/scout_cartgoingbackoffense02.mp3",
	
};

methodmap CBonkBoy < SaxtonHaleBase
{
	public CBonkBoy(CBonkBoy boss)
	{
		boss.CallFunction("CreateAbility", "CDashJump");
		
		CRageAddCond rageCond = boss.CallFunction("CreateAbility", "CRageAddCond");
		rageCond.flRageCondDuration = 5.0;
		rageCond.AddCond(TFCond_CritHype);
		rageCond.AddCond(TFCond_SpeedBuffAlly);
		
		boss.flSpeed = 400.0;
		boss.iBaseHealth = 700;
		boss.iHealthPerPlayer = 650;
		boss.nClass = TFClass_Scout;
		boss.iMaxRageDamage = 1500;
		
		g_bBonkBoyRage[boss.iClient] = false;
	}
	
	public bool IsBossHidden()
	{
		return true;
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
		StrCat(sInfo, length, "\n- Faster movement speed and extra jump height");
		StrCat(sInfo, length, "\n- Dash Jump");
		StrCat(sInfo, length, "\n- Sandman with fast recharge balls, able to hold 3 max");
		StrCat(sInfo, length, "\n- Medium range ball stuns player and building, moonshot instakills");
		StrCat(sInfo, length, "\n ");
		StrCat(sInfo, length, "\nRage");
		StrCat(sInfo, length, "\n- Soda Popper jumps and faster speed movement for 5 seconds");
		StrCat(sInfo, length, "\n- 200%% Rage: Extends duration to 10 seconds");
	}
	
	public void OnSpawn()
	{
		char attribs[256];
		Format(attribs, sizeof(attribs), "2 ; 2.80 ; 252 ; 0.5 ; 259 ; 1.0 ; 38 ; 1.0 ; 278 ; 0.33 ; 279 ; 3.0 ; 524 ; 1.2 ; 551 ; 1.0");
		int iWeapon = this.CallFunction("CreateWeapon", 44, "tf_weapon_bat_wood", 1, TFQual_Collectors, attribs);
		if (iWeapon > MaxClients)
		{
			SetEntPropEnt(this.iClient, Prop_Send, "m_hActiveWeapon", iWeapon);
			
			//Correctly set ammo to 3
			int iAmmoType = GetEntProp(iWeapon, Prop_Send, "m_iPrimaryAmmoType");
			if (iAmmoType > -1)
				SetEntProp(this.iClient, Prop_Send, "m_iAmmo", 3, 4, iAmmoType);
		}

		/*
		Sandman attributes:
		
		2: damage bonus
		252: reduction in push force taken from damage
		259: Deals 3x falling damage to the player you land on
		
		38: Launches a ball that slows opponents
		278: increase in recharge rate
		279: max misc ammo on wearer
		524: greater jump height when active
		551: special_taunt
		*/
		
		int iWearable = -1;
		
		iWearable = this.CallFunction("CreateWeapon", 106, "tf_wearable", 1, TFQual_Collectors, "");	//Bonk Helm
		if (iWearable > MaxClients)
			SetEntProp(iWearable, Prop_Send, "m_nModelIndexOverrides", g_iBonkBoyModelHelmet);
		
		iWearable = this.CallFunction("CreateWeapon", 451, "tf_wearable", 1, TFQual_Collectors, "");	//Bonk Boy
		if (iWearable > MaxClients)
			SetEntProp(iWearable, Prop_Send, "m_nModelIndexOverrides", g_iBonkBoyModelMask);
		
		iWearable = this.CallFunction("CreateWeapon", 30685, "tf_wearable", 1, TFQual_Collectors, "");	//Thrilling Tracksuit
		if (iWearable > MaxClients)
			SetEntProp(iWearable, Prop_Send, "m_nModelIndexOverrides", g_iBonkBoyModelShirt);
			
		iWearable = this.CallFunction("CreateWeapon", 30751, "tf_wearable", 1, TFQual_Collectors, "");	//Bonk Batter's Backup
		if (iWearable > MaxClients)
			SetEntProp(iWearable, Prop_Send, "m_nModelIndexOverrides", g_iBonkBoyModelBag);
	}
	
	public void OnRage()
	{
		//Just to fix TFCond_CritHype not doing anything
		SetEntPropFloat(this.iClient, Prop_Send, "m_flHypeMeter", 100.0);
		
		this.flSpeed *= 1.5;
		g_bBonkBoyRage[this.iClient] = true;
	}
	
	public void OnThink()
	{
		if (g_bBonkBoyRage[this.iClient] && this.flRageLastTime < GetGameTime() - (this.bSuperRage ? 10.0 : 5.0))
		{
			g_bBonkBoyRage[this.iClient] = false;
			this.flSpeed /= 1.5;
		}
	}
	
	public void OnEntityCreated(int iEntity, const char[] sClassname)
	{
		if (strcmp(sClassname, "tf_projectile_stun_ball") == 0)
		{
			SDK_HookBallImpact(iEntity, BonkBoy_BallImpact);	//To hook when ball impacts player
			SDK_HookBallTouch(iEntity, BonkBoy_BallTouch);		//To hook when ball impacts building
		}
	}
	
	public void GetSound(char[] sSound, int length, SaxtonHaleSound iSoundType)
	{
		switch (iSoundType)
		{
			case VSHSound_RoundStart: strcopy(sSound, length, g_strBonkBoyRoundStart[GetRandomInt(0,sizeof(g_strBonkBoyRoundStart)-1)]);
			case VSHSound_Win: strcopy(sSound, length, g_strBonkBoyWin[GetRandomInt(0,sizeof(g_strBonkBoyWin)-1)]);
			case VSHSound_Lose: strcopy(sSound, length, g_strBonkBoyLose[GetRandomInt(0,sizeof(g_strBonkBoyLose)-1)]);
			case VSHSound_Rage: strcopy(sSound, length, g_strBonkBoyRage[GetRandomInt(0,sizeof(g_strBonkBoyRage)-1)]);
			case VSHSound_Lastman: strcopy(sSound, length, g_strBonkBoyLastMan[GetRandomInt(0,sizeof(g_strBonkBoyLastMan)-1)]);
			case VSHSound_Backstab: strcopy(sSound, length, g_strBonkBoyBackStabbed[GetRandomInt(0,sizeof(g_strBonkBoyBackStabbed)-1)]);
		}
	}
	
	public void GetSoundKill(char[] sSound, int length, TFClassType nClass)
	{
		strcopy(sSound, length, g_strBonkBoyKill[GetRandomInt(0,sizeof(g_strBonkBoyKill)-1)]);
	}
	
	public void Precache()
	{
		g_iBonkBoyStunType = FindSendPropInfo("CTFStunBall", "m_iType");
		
		g_iBonkBoyModelHelmet = PrecacheModel("models/player/items/scout/bonk_helmet.mdl");
		g_iBonkBoyModelMask = PrecacheModel("models/workshop/player/items/scout/bonk_mask/bonk_mask.mdl");
		g_iBonkBoyModelShirt = PrecacheModel("models/workshop/player/items/scout/hwn2015_death_racer_jacket/hwn2015_death_racer_jacket.mdl");
		g_iBonkBoyModelBag = PrecacheModel("models/workshop/player/items/scout/dec15_scout_baseball_bag/dec15_scout_baseball_bag.mdl");
		
		for (int i = 0; i < sizeof(g_strBonkBoyRoundStart); i++) PrecacheSound(g_strBonkBoyRoundStart[i]);
		for (int i = 0; i < sizeof(g_strBonkBoyWin); i++) PrecacheSound(g_strBonkBoyWin[i]);
		for (int i = 0; i < sizeof(g_strBonkBoyLose); i++) PrecacheSound(g_strBonkBoyLose[i]);
		for (int i = 0; i < sizeof(g_strBonkBoyRage); i++) PrecacheSound(g_strBonkBoyRage[i]);
		for (int i = 0; i < sizeof(g_strBonkBoyKill); i++) PrecacheSound(g_strBonkBoyKill[i]);
		for (int i = 0; i < sizeof(g_strBonkBoyLastMan); i++) PrecacheSound(g_strBonkBoyLastMan[i]);
		for (int i = 0; i < sizeof(g_strBonkBoyBackStabbed); i++) PrecacheSound(g_strBonkBoyBackStabbed[i]);
	}
};

public MRESReturn BonkBoy_BallImpact(int iEntity, Handle hParams)
{
	//Get victim whos stunned from ball
	int iVictim = DHookGetParam(hParams, 1);
	if (iVictim <= 0 || iVictim > MaxClients || !IsClientInGame(iVictim))
		return;
	
	//Check if valid ball from Bonk Boy
	int iThrower;
	float flTime;
	if (!BonkBoy_IsValidBall(iEntity, iThrower, flTime))
		return;
	
	g_flBonkBoyStunTime[iVictim] = flTime;
	g_iBonkBoyBallThrower[iVictim] = iThrower;
	
	SDKHook(iVictim, SDKHook_OnTakeDamage, BonkBoy_OnTakeDamage);
	HookEvent("player_death", BonkBoy_PlayerDeath, EventHookMode_Pre);
	RequestFrame(BonkBoy_UnhookBallDamage, GetClientUserId(iVictim));
}

public MRESReturn BonkBoy_BallTouch(int iEntity, Handle hReturn, Handle hParams)
{
	if (GetEntProp(iEntity, Prop_Send, "m_bTouched"))
		return;
	
	//Check if toucher is building
	int iBuilding = DHookGetParam(hParams, 1);
	if (iBuilding <= MaxClients)
		return;
	
	char sClassname[256];
	GetEntityClassname(iBuilding, sClassname, sizeof(sClassname));
	if (StrContains(sClassname, "obj_") != 0)
		return;
	
	//Check if valid ball from Bonk Boy
	int iThrower;
	float flTime;
	if (!BonkBoy_IsValidBall(iEntity, iThrower, flTime))
		return;
	
	//Team check
	if (GetEntProp(iBuilding, Prop_Send, "m_iTeamNum") == GetClientTeam(iThrower))
		return;
	
	//Deal damage
	SDKHooks_TakeDamage(iBuilding, iThrower, iThrower, flTime * 120.0);
	
	//Stun building
	TF2_StunBuilding(iBuilding, flTime * 8.0);
	
	//Mark ball as touched
	SetEntProp(iEntity, Prop_Send, "m_bTouched", true);
}

bool BonkBoy_IsValidBall(int iEntity, int &iThrower = 0, float &flTime = 0.0)
{
	//Check if ball originally came from bonk boy
	int iOwner = GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity");
	if (!SaxtonHale_IsValidBoss(iOwner))
		return false;
	
	SaxtonHaleBase boss = SaxtonHaleBase(iOwner);
	char sBossType[MAX_TYPE_CHAR];
	boss.CallFunction("GetBossType", sBossType, sizeof(sBossType));
	if (!StrEqual(sBossType, "CBonkBoy"))
		return false;
	
	//Get whoever threw the ball, either from bonk boy, or from deflected pyro
	iThrower = GetEntPropEnt(iEntity, Prop_Send, "m_hThrower");
	if (iThrower <= 0 || iThrower > MaxClients || !IsClientInGame(iThrower))
		return false;
	
	//Sandman init time is stored in m_iType + 4 offset
	flTime = GetGameTime() - GetEntDataFloat(iEntity, g_iBonkBoyStunType + 0x04);
	return true;
}

public Action BonkBoy_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	Action action = Plugin_Continue;
	
	if (damagecustom == TF_CUSTOM_BASEBALL && g_flBonkBoyStunTime[victim] > 0.0)
	{
		attacker = g_iBonkBoyBallThrower[victim];
		g_iBonkBoyBallThrower[victim] = 0;
		action = Plugin_Changed;
		
		if (g_flBonkBoyStunTime[victim] > 0.85)
		{
			//Home run baby
			damagetype |= DMG_CRIT;
			damage = 1337.0 / 3.0;
			
			TF2_StunPlayer(victim, 10.0, _, TF_STUNFLAGS_BIGBONK, attacker);
		}
		else if (g_flBonkBoyStunTime[victim] > 0.10)
		{
			//Not so home run
			damage *= g_flBonkBoyStunTime[victim] * 8.0;
			TF2_StunPlayer(victim, g_flBonkBoyStunTime[victim] * 8.0, _, TF_STUNFLAGS_SMALLBONK, attacker);
		}
		
		g_flBonkBoyStunTime[victim] = 0.0;
	}
	
	return action;
}

public Action BonkBoy_PlayerDeath(Event event, const char[] sName, bool bDontBroadcast)
{
	if (event.GetInt("customkill") == TF_CUSTOM_BASEBALL && event.GetInt("stun_flags") == TF_STUNFLAGS_BIGBONK)
	{
		event.SetInt("customkill", TF_CUSTOM_TAUNT_GRAND_SLAM);
		event.SetString("weapon", "taunt_scout");
		event.SetString("weapon_logclassname", "taunt_scout");
	}
}

public void BonkBoy_UnhookBallDamage(int iUserId)
{
	int iClient = GetClientOfUserId(iUserId);
	if (0 < iClient <= MaxClients && IsClientInGame(iClient))
		SDKUnhook(iClient, SDKHook_OnTakeDamage, BonkBoy_OnTakeDamage);
	
	UnhookEvent("player_death", BonkBoy_PlayerDeath, EventHookMode_Pre);
}