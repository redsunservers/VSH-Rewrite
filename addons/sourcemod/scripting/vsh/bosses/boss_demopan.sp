//#define DEMOPAN_DROP_MODEL	"models/player/items/soldier/soldier_shako.mdl"

static int g_iDemoPanModelBountyHat;
static int g_iDemoPanModelDangeresqueToo;

static float g_flDemoPanPreviousKill[TF_MAXPLAYERS];

static char g_strDemoPanRoundStart[][] = {
	"vsh_rewrite/demopan/demopan_begin.mp3"
};

static char g_strDemoPanWin[][] = {
	"vsh_rewrite/demopan/demopan_win.mp3"
};

static char g_strDemoPanLose[][] = {
	"vo/demoman_jeers05.mp3",
	"vo/demoman_sf13_bosses03.mp3"
};

static char g_strDemoPanJump[][] = {
	"vo/taunts/demo/taunt_demo_exert_04.mp3",
	"vo/taunts/demo/taunt_demo_exert_06.mp3",
	"vo/taunts/demo/taunt_demo_exert_08.mp3",
	"vo/demoman_specialcompleted12.mp3"
};

static char g_strDemoPanCharge[][] = {
	"weapons/demo_charge_windup1.wav",
	"weapons/demo_charge_windup2.wav",
	"weapons/demo_charge_windup3.wav"
};

static char g_strDemoPanKill[][] = {
	"vo/taunts/demo/taunt_demo_burp_03.mp3",
	"vo/taunts/demo/taunt_demo_nuke_3_spit_lid.mp3",
	"vo/demoman_specialcompleted08.mp3"
};

static char g_strDemoPanKillPan[][] = {
	"weapons/pan/melee_frying_pan_01.wav",
	"weapons/pan/melee_frying_pan_02.wav",
	"weapons/pan/melee_frying_pan_03.wav",
	"weapons/pan/melee_frying_pan_04.wav"
};

static char g_strDemoPanKillSpree[][] = {
	"vsh_rewrite/demopan/demopan_kspree.mp3"
};

static char g_strDemoPanLastMan[][] = {
	"vo/taunts/demoman_taunts10.mp3",
	"vo/demoman_dominationpyro02",
	"vo/compmode/cm_demo_pregametie_01"
};

static char g_strDemoPanBackStabbed[][] = {
	"vo/demoman_negativevocalization03.mp3",
	"vo/demoman_negativevocalization04.mp3",
	"vo/demoman_negativevocalization05.mp3",
	"vo/demoman_sf12_badmagic10.mp3"
};

methodmap CDemoPan < SaxtonHaleBase
{
	public CDemoPan(CDemoPan boss)
	{
		boss.CallFunction("CreateAbility", "CWeaponCharge");
		boss.CallFunction("CreateAbility", "CBraveJump");
		//CDropModel dropmodel = boss.CallFunction("CreateAbility", "CDropModel");
		//dropmodel.SetModel(DEMOPAN_DROP_MODEL);
		
		boss.iBaseHealth = 800;
		boss.iHealthPerPlayer = 800;
		boss.nClass = TFClass_DemoMan;
		boss.iMaxRageDamage = 3000;
		
		g_flDemoPanPreviousKill[boss.iClient] = 0.0;
	}
	
	public void GetBossName(char[] sName, int length)
	{
		strcopy(sName, length, "Demopan");
	}
	
	public void GetBossInfo(char[] sInfo, int length)
	{
		StrCat(sInfo, length, "\nHealth: Medium");
		StrCat(sInfo, length, "\n ");
		StrCat(sInfo, length, "\nAbilities");
		StrCat(sInfo, length, "\n- Brave Jump");
		StrCat(sInfo, length, "\n- Passive Chargin' Targe, reload to charge");
		StrCat(sInfo, length, "\n ");
		StrCat(sInfo, length, "\nRage");
		StrCat(sInfo, length, "\n- 5 seconds of force full-control charging");
		StrCat(sInfo, length, "\n- 200%% Rage: extends duration to 10 seconds");
	}
	
	public void OnSpawn()
	{
		char attribs[128];
		Format(attribs, sizeof(attribs), "2 ; 2.80 ; 252 ; 0.5 ; 259 ; 1.0");
		int iWeapon = this.CallFunction("CreateWeapon", 264, "tf_weapon_bottle", 100, TFQual_Collectors, attribs);	//Frying Pan Index, classname doesnt like saxxy
		if (iWeapon > MaxClients)
			SetEntPropEnt(this.iClient, Prop_Send, "m_hActiveWeapon", iWeapon);
		/*
		Frying Pan attributes:
		
		2: damage bonus
		252: reduction in push force taken from damage
		259: Deals 3x falling damage to the player you land on
		*/
		
		//Not really a weapon but still works lul
		int iWearable = -1;
		
		iWearable = this.CallFunction("CreateWeapon", 332, "tf_wearable", 0, TFQual_Normal, "");	//Bounty Hat
		if (iWearable > MaxClients)
			SetEntProp(iWearable, Prop_Send, "m_nModelIndexOverrides", g_iDemoPanModelBountyHat);
		
		iWearable = this.CallFunction("CreateWeapon", 295, "tf_wearable", 0, TFQual_Normal, "");	//Dangeresque, Too?
		if (iWearable > MaxClients)
			SetEntProp(iWearable, Prop_Send, "m_nModelIndexOverrides", g_iDemoPanModelDangeresqueToo);
	}
	
	public void GetSound(char[] sSound, int length, SaxtonHaleSound iSoundType)
	{
		switch (iSoundType)
		{
			case VSHSound_RoundStart: strcopy(sSound, length, g_strDemoPanRoundStart[GetRandomInt(0,sizeof(g_strDemoPanRoundStart)-1)]);
			case VSHSound_Win: strcopy(sSound, length, g_strDemoPanWin[GetRandomInt(0,sizeof(g_strDemoPanWin)-1)]);
			case VSHSound_Lose: strcopy(sSound, length, g_strDemoPanLose[GetRandomInt(0,sizeof(g_strDemoPanLose)-1)]);
			case VSHSound_Lastman: strcopy(sSound, length, g_strDemoPanLastMan[GetRandomInt(0,sizeof(g_strDemoPanLastMan)-1)]);
			case VSHSound_Backstab: strcopy(sSound, length, g_strDemoPanBackStabbed[GetRandomInt(0,sizeof(g_strDemoPanBackStabbed)-1)]);
		}
	}
	
	public void GetSoundAbility(char[] sSound, int length, const char[] sType)
	{
		if (strcmp(sType, "CBraveJump") == 0)
			strcopy(sSound, length, g_strDemoPanJump[GetRandomInt(0,sizeof(g_strDemoPanJump)-1)]);
		else if (strcmp(sType, "CWeaponCharge") == 0)
			strcopy(sSound, length, g_strDemoPanCharge[GetRandomInt(0,sizeof(g_strDemoPanCharge)-1)]);
	}
	
	public void GetSoundKill(char[] sSound, int length, TFClassType nClass)
	{
		int iClient = this.iClient;
		if (g_flDemoPanPreviousKill[iClient] > GetGameTime() - 2.0 && g_flDemoPanPreviousKill[iClient] != 0.0)
		{
			strcopy(sSound, length, g_strDemoPanKillSpree[GetRandomInt(0,sizeof(g_strDemoPanKillSpree)-1)]);
			g_flDemoPanPreviousKill[iClient] = 0.0;
		}
		else
		{
			strcopy(sSound, length, g_strDemoPanKill[GetRandomInt(0,sizeof(g_strDemoPanKill)-1)]);
			g_flDemoPanPreviousKill[iClient] = GetGameTime();
		}
	}
	
	public void OnPlayerKilled(Event event, int iVictim)
	{
		char strWeaponLog[50];
		event.GetString("weapon_logclassname", strWeaponLog, sizeof(strWeaponLog));
		if (StrEqual(strWeaponLog, "fryingpan"))
			EmitSoundToAll(g_strDemoPanKillPan[GetRandomInt(0,sizeof(g_strDemoPanKillPan)-1)]);
	}
	
	public void Precache()
	{
		//PrecacheModel(DEMOPAN_DROP_MODEL);
		
		g_iDemoPanModelBountyHat = PrecacheModel("models/player/items/all_class/treasure_hat_01_demo.mdl");
		g_iDemoPanModelDangeresqueToo = PrecacheModel("models/player/items/demo/ttg_glasses.mdl");
		
		for (int i = 0; i < sizeof(g_strDemoPanRoundStart); i++) PrepareSound(g_strDemoPanRoundStart[i]);	//Custom sound
		for (int i = 0; i < sizeof(g_strDemoPanWin); i++) PrepareSound(g_strDemoPanWin[i]);					//Custom sound
		for (int i = 0; i < sizeof(g_strDemoPanLose); i++) PrecacheSound(g_strDemoPanLose[i]);
		for (int i = 0; i < sizeof(g_strDemoPanCharge); i++) PrecacheSound(g_strDemoPanCharge[i]);
		for (int i = 0; i < sizeof(g_strDemoPanJump); i++) PrecacheSound(g_strDemoPanJump[i]);
		for (int i = 0; i < sizeof(g_strDemoPanKill); i++) PrecacheSound(g_strDemoPanKill[i]);
		for (int i = 0; i < sizeof(g_strDemoPanKillPan); i++) PrecacheSound(g_strDemoPanKillPan[i]);
		for (int i = 0; i < sizeof(g_strDemoPanKillSpree); i++) PrepareSound(g_strDemoPanKillSpree[i]);		//Custom sound
		for (int i = 0; i < sizeof(g_strDemoPanLastMan); i++) PrecacheSound(g_strDemoPanLastMan[i]);
		for (int i = 0; i < sizeof(g_strDemoPanBackStabbed); i++) PrecacheSound(g_strDemoPanBackStabbed[i]);
	}
};