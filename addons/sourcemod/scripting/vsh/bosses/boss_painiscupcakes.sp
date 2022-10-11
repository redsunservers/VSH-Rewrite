#define PAINIS_RAGE_MUSIC "vsh_rewrite/painis/rage.mp3"

static char g_strPainisRoundStart[][] = {
	"vsh_rewrite/painis/intro.mp3"
};

static char g_strPainisWin[][] = {
	"vo/soldier_laughevil01.mp3",
	"vo/soldier_laughevil02.mp3",
	"vo/soldier_laughevil03.mp3"
};

static char g_strPainisLose[][] = {
	"vo/soldier_autodejectedtie03.mp3"
};

static char g_strPainisRage[][] = {
	"vo/soldier_paincrticialdeath01.mp3",
	"vo/soldier_paincrticialdeath02.mp3",
	"vo/soldier_paincrticialdeath03.mp3",
	"vo/soldier_paincrticialdeath04.mp3"
};

static char g_strPainisJump[][] = {
	"vo/soldier_laughshort01.mp3",
	"vo/soldier_laughshort02.mp3",
	"vo/soldier_laughshort03.mp3",
	"vo/soldier_laughshort04.mp3"
};

static char g_strPainisKillScout[][] = {
	"vo/soldier_dominationscout11.mp3"
};

static char g_strPainisKillSniper[][] = {
	"vo/soldier_dominationsniper12.mp3"
};

static char g_strPainisKillDemoMan[][] = {
	"vo/soldier_dominationdemoman02.mp3"
};

static char g_strPainisKillMedic[][] = {
	"vo/soldier_dominationmedic07.mp3"
};

static char g_strPainisKillSpy[][] = {
	"vo/soldier_dominationspy01.mp3"
};

static char g_strPainisKillEngie[][] = {
	"vo/soldier_dominationengineer04.mp3"
};

static char g_strPainisLastMan[][] = {
	"vo/soldier_pickaxetaunt01.mp3",
	"vo/soldier_pickaxetaunt02.mp3",
	"vo/soldier_pickaxetaunt03.mp3",
	"vo/soldier_pickaxetaunt04.mp3",
	"vo/soldier_pickaxetaunt05.mp3"
};

static char g_strPainisBackStabbed[][] = {
	"vo/soldier_weapon_taunts05.mp3",
	"vo/soldier_weapon_taunts04.mp3",
	"vo/soldier_weapon_taunts01.mp3"
};

static char g_strPainisFootsteps[][] = {
	"weapons/shotgun_cock_back.wav",
	"weapons/shotgun_cock_forward.wav"
};

public void PainisCupcake_Create(SaxtonHaleBase boss)
{
	boss.CreateClass("WeaponFists");
	boss.CreateClass("BraveJump");
	
	boss.CreateClass("BodyEat");
	boss.SetPropInt("BodyEat", "MaxHeal", 400);
	boss.SetPropFloat("BodyEat", "MaxEatDistance", 100.0);
	boss.SetPropFloat("BodyEat", "EatRageRadius", 450.0);
	boss.SetPropFloat("BodyEat", "EatRageDuration", 8.0);
	
	boss.CreateClass("LightRage");
	boss.SetPropFloat("LightRage", "LigthRageDuration", 8.0);
	boss.SetPropFloat("LightRage", "LightRageRadius", 450.0);
	boss.SetPropInt("LightRage", "RageLightBrigthness", 6);
	
	boss.CreateClass("RageAddCond");
	boss.SetPropFloat("RageAddCond", "RageCondDuration", 8.0);
	RageAddCond_AddCond(boss, TFCond_UberchargedCanteen);
	RageAddCond_AddCond(boss, TFCond_SpeedBuffAlly);
	
	boss.iHealthPerPlayer = 500;
	boss.flHealthExponential = 1.05;
	boss.nClass = TFClass_Soldier;
	boss.iMaxRageDamage = 2500;
}

public void PainisCupcake_GetBossName(SaxtonHaleBase boss, char[] sName, int length)
{
	strcopy(sName, length, "Painis Cupcake");
}

public void PainisCupcake_GetBossInfo(SaxtonHaleBase boss, char[] sInfo, int length)
{
	StrCat(sInfo, length, "\nHealth: Low");
	StrCat(sInfo, length, "\n ");
	StrCat(sInfo, length, "\nAbilities");
	StrCat(sInfo, length, "\n- Brave Jump");
	StrCat(sInfo, length, "\n- Holding reload key eats dead bodies to heal up to 400 HP, recovered health depends on damage the player did");
	StrCat(sInfo, length, "\n ");
	StrCat(sInfo, length, "\nRage");
	StrCat(sInfo, length, "\n- Damage requirement: 2500");
	StrCat(sInfo, length, "\n- Übercharge and bright glow for 8 seconds");
	StrCat(sInfo, length, "\n- Automatically eats nearby bodies");
	StrCat(sInfo, length, "\n- 200%% Rage: extends duration to 16 seconds");
}

public void PainisCupcake_OnRage(SaxtonHaleBase boss)
{
	if (boss.HasClass("LightRage"))
	{
		int iColor[4];
		if (TF2_GetClientTeam(boss.iClient) == TFTeam_Red)
		{
			iColor[0] = 255;
			iColor[1] = 0;
			iColor[2] = 0;
		}
		else
		{
			iColor[0] = 0;
			iColor[1] = 0;
			iColor[2] = 255;
		}
		
		iColor[3] = 255;
		LightRage_SetColor(boss, iColor);
	}
}

public void PainisCupcake_OnSpawn(SaxtonHaleBase boss)
{
	char attribs[128];
	Format(attribs, sizeof(attribs), "2 ; 2.80 ; 252 ; 0.5 ; 259 ; 1.0");
	int iWeapon = boss.CallFunction("CreateWeapon", 195, "tf_weapon_shovel", 100, TFQual_Strange, attribs);
	if (iWeapon > MaxClients)
		SetEntPropEnt(boss.iClient, Prop_Send, "m_hActiveWeapon", iWeapon);
	/*
	Fist attributes:
	
	2: damage bonus
	252: reduction in push force taken from damage
	259: Deals 3x falling damage to the player you land on
	*/
}

public void PainisCupcake_GetSound(SaxtonHaleBase boss, char[] sSound, int length, SaxtonHaleSound iSoundType)
{
	switch (iSoundType)
	{
		case VSHSound_RoundStart: strcopy(sSound, length, g_strPainisRoundStart[GetRandomInt(0,sizeof(g_strPainisRoundStart)-1)]);
		case VSHSound_Win: strcopy(sSound, length, g_strPainisWin[GetRandomInt(0,sizeof(g_strPainisWin)-1)]);
		case VSHSound_Lose: strcopy(sSound, length, g_strPainisLose[GetRandomInt(0,sizeof(g_strPainisLose)-1)]);
		case VSHSound_Rage: strcopy(sSound, length, g_strPainisRage[GetRandomInt(0,sizeof(g_strPainisRage)-1)]);
		case VSHSound_Lastman: strcopy(sSound, length, g_strPainisLastMan[GetRandomInt(0,sizeof(g_strPainisLastMan)-1)]);
		case VSHSound_Backstab: strcopy(sSound, length, g_strPainisBackStabbed[GetRandomInt(0,sizeof(g_strPainisBackStabbed)-1)]);
	}
}

public void PainisCupcake_GetSoundAbility(SaxtonHaleBase boss, char[] sSound, int length, const char[] sType)
{
	if (strcmp(sType, "BraveJump") == 0)
		strcopy(sSound, length, g_strPainisJump[GetRandomInt(0,sizeof(g_strPainisJump)-1)]);
}

public void PainisCupcake_GetSoundKill(SaxtonHaleBase boss, char[] sSound, int length, TFClassType nClass)
{
	switch (nClass)
	{
		case TFClass_Scout: strcopy(sSound, length, g_strPainisKillScout[GetRandomInt(0,sizeof(g_strPainisKillScout)-1)]);
		case TFClass_DemoMan: strcopy(sSound, length, g_strPainisKillDemoMan[GetRandomInt(0,sizeof(g_strPainisKillDemoMan)-1)]);
		case TFClass_Engineer: strcopy(sSound, length, g_strPainisKillEngie[GetRandomInt(0,sizeof(g_strPainisKillEngie)-1)]);
		case TFClass_Medic: strcopy(sSound, length, g_strPainisKillMedic[GetRandomInt(0,sizeof(g_strPainisKillMedic)-1)]);
		case TFClass_Sniper: strcopy(sSound, length, g_strPainisKillSniper[GetRandomInt(0,sizeof(g_strPainisKillSniper)-1)]);
		case TFClass_Spy: strcopy(sSound, length, g_strPainisKillSpy[GetRandomInt(0,sizeof(g_strPainisKillSpy)-1)]);
	}
}

public void PainisCupcake_GetRageMusicInfo(SaxtonHaleBase boss, char[] sSound, int length, float &time)
{
	strcopy(sSound, length, PAINIS_RAGE_MUSIC);
	time = 20.0;
}

public Action PainisCupcake_OnSoundPlayed(SaxtonHaleBase boss, int clients[MAXPLAYERS], int &numClients, char sample[PLATFORM_MAX_PATH], int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
	if(StrContains(sample, "player/footsteps/", false) != -1)
	{
		EmitSoundToAll(g_strPainisFootsteps[GetRandomInt(0, sizeof(g_strPainisFootsteps)-1)], boss.iClient, _, _, _, 0.13, GetRandomInt(95, 100));
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public void PainisCupcake_Precache(SaxtonHaleBase boss)
{
	PrepareSound(PAINIS_RAGE_MUSIC);
	for (int i = 0; i < sizeof(g_strPainisRoundStart); i++) PrepareSound(g_strPainisRoundStart[i]);
	for (int i = 0; i < sizeof(g_strPainisWin); i++) PrepareSound(g_strPainisWin[i]);
	for (int i = 0; i < sizeof(g_strPainisLose); i++) PrepareSound(g_strPainisLose[i]);
	for (int i = 0; i < sizeof(g_strPainisRage); i++) PrepareSound(g_strPainisRage[i]);
	for (int i = 0; i < sizeof(g_strPainisJump); i++) PrepareSound(g_strPainisJump[i]);
	for (int i = 0; i < sizeof(g_strPainisKillScout); i++) PrepareSound(g_strPainisKillScout[i]);
	for (int i = 0; i < sizeof(g_strPainisKillSniper); i++) PrepareSound(g_strPainisKillSniper[i]);
	for (int i = 0; i < sizeof(g_strPainisKillDemoMan); i++) PrepareSound(g_strPainisKillDemoMan[i]);
	for (int i = 0; i < sizeof(g_strPainisKillMedic); i++) PrepareSound(g_strPainisKillMedic[i]);
	for (int i = 0; i < sizeof(g_strPainisKillSpy); i++) PrepareSound(g_strPainisKillSpy[i]);
	for (int i = 0; i < sizeof(g_strPainisKillEngie); i++) PrepareSound(g_strPainisKillEngie[i]);
	for (int i = 0; i < sizeof(g_strPainisLastMan); i++) PrepareSound(g_strPainisLastMan[i]);
	for (int i = 0; i < sizeof(g_strPainisBackStabbed); i++) PrepareSound(g_strPainisBackStabbed[i]);
	for (int i = 0; i < sizeof(g_strPainisFootsteps); i++) PrepareSound(g_strPainisFootsteps[i]);
}

