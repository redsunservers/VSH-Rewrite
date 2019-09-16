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

methodmap CPainisCupcake < SaxtonHaleBase
{
	public CPainisCupcake(CPainisCupcake boss)
	{
		boss.CallFunction("CreateAbility", "CWeaponFists");
		boss.CallFunction("CreateAbility", "CBraveJump");
		
		CBodyEat bodyeat = boss.CallFunction("CreateAbility", "CBodyEat");
		bodyeat.iMaxHeal = 400;
		bodyeat.flMaxEatDistance = 100.0;
		bodyeat.flEatRageRadius = 450.0;
		bodyeat.flEatRageDuration = 8.0;
		
		CLightRage light = boss.CallFunction("CreateAbility", "CLightRage");
		light.flLigthRageDuration = 8.0;
		light.flLightRageRadius = 450.0;
		light.iRageLightBrigthness = 6;
		
		CRageAddCond rageCond = boss.CallFunction("CreateAbility", "CRageAddCond");
		rageCond.flRageCondDuration = 8.0;
		rageCond.AddCond(TFCond_UberchargedCanteen);
		rageCond.AddCond(TFCond_SpeedBuffAlly);
		
		boss.iBaseHealth = 650;
		boss.iHealthPerPlayer = 550;
		boss.nClass = TFClass_Soldier;
		boss.iMaxRageDamage = 2500;
	}
	
	public void GetBossName(char[] sName, int length)
	{
		strcopy(sName, length, "Painis Cupcake");
	}
	
	public void GetBossInfo(char[] sInfo, int length)
	{
		StrCat(sInfo, length, "\nHealth: Lowest of all bosses");
		StrCat(sInfo, length, "\n ");
		StrCat(sInfo, length, "\nAbilities");
		StrCat(sInfo, length, "\n- Brave Jump");
		StrCat(sInfo, length, "\n- Holding reload key eats dead bodies to heal, depends on amount of damage player done, max 400");
		StrCat(sInfo, length, "\n ");
		StrCat(sInfo, length, "\nRage");
		StrCat(sInfo, length, "\n- Übercharge and bright glow for 8 seconds");
		StrCat(sInfo, length, "\n- Eats nearby bodies");
		StrCat(sInfo, length, "\n- 200%% Rage: extends duration to 16 seconds");
	}
	
	public void OnRage()
	{
		CLightRage light = this.CallFunction("FindAbility", "CLightRage");
		if (light != INVALID_ABILITY)
		{
			int iColor[4];
			if (GetClientTeam(this.iClient) == TFTeam_Red)
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
			light.SetColor(iColor);
		}
	}
	
	public void OnSpawn()
	{
		char attribs[128];
		Format(attribs, sizeof(attribs), "2 ; 2.80 ; 252 ; 0.5 ; 259 ; 1.0 ; 329 ; 0.65");
		int iWeapon = this.CallFunction("CreateWeapon", 195, "tf_weapon_shovel", 100, TFQual_Strange, attribs);
		if (iWeapon > MaxClients)
			SetEntPropEnt(this.iClient, Prop_Send, "m_hActiveWeapon", iWeapon);
		/*
		Fist attributes:
		
		2: damage bonus
		252: reduction in push force taken from damage
		259: Deals 3x falling damage to the player you land on
		329: reduction in airblast vulnerability
		*/
	}
	
	public void GetSound(char[] sSound, int length, SaxtonHaleSound iSoundType)
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
	
	public void GetSoundAbility(char[] sSound, int length, const char[] sType)
	{
		if (strcmp(sType, "CBraveJump") == 0)
			strcopy(sSound, length, g_strPainisJump[GetRandomInt(0,sizeof(g_strPainisJump)-1)]);
	}
	
	public void GetSoundKill(char[] sSound, int length, TFClassType nClass)
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
	
	public void GetRageMusicInfo(char[] sSound, int length, float &time)
	{
		strcopy(sSound, length, PAINIS_RAGE_MUSIC);
		time = 20.0;
	}
	
	public Action OnSoundPlayed(int clients[MAXPLAYERS], int &numClients, char sample[PLATFORM_MAX_PATH], int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
	{
		if(StrContains(sample, "player/footsteps/", false) != -1)
		{
			EmitSoundToAll(g_strPainisFootsteps[GetRandomInt(0, sizeof(g_strPainisFootsteps)-1)], this.iClient, _, _, _, 0.13, GetRandomInt(95, 100));
			return Plugin_Handled;
		}
		return Plugin_Continue;
	}
	
	public void Precache()
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
};