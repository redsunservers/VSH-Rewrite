#define YETI_MODEL "models/player/kirillian/boss/yeti_modded.mdl"
#define YETI_THEME "ui/gamestartup27.mp3"

static char g_strYetiRoundStart[][] =  {
	"ambient_mp3/lair/animal_call_yeti1.mp3", 
	"ambient_mp3/lair/animal_call_yeti2.mp3", 
	"ambient_mp3/lair/animal_call_yeti3.mp3", 
	"ambient_mp3/lair/animal_call_yeti4.mp3", 
	"ambient_mp3/lair/animal_call_yeti5.mp3", 
	"ambient_mp3/lair/animal_call_yeti6.mp3", 
	"ambient_mp3/lair/animal_call_yeti7.mp3"
};

static char g_strYetiWin[][] =  {
	"player/taunt_yeti_roar_first.wav"
};

static char g_strYetiLose[][] =  {
	"player/taunt_yeti_roar_second.wav"
};

static char g_strYetiFreeze[][] =  {
	"player/taunt_yeti_appear_snow.wav", 
	"weapons/icicle_freeze_victim_01.wav"
};

static char g_strYetiGroundSlam[][] =  {
	"player/taunt_yeti_land.wav"
};

static char g_strYetiKill[][] =  {
	"player/taunt_yeti_roar_beginning.wav"
};

static char g_strYetiLastMan[][] =  {
	"ambient_mp3/lair/animal_call_yeti2.mp3", 
};

static char g_strYetiBackStabbed[][] =  {
	"player/taunt_yeti_roar_second.wav"
};

static char g_strYetiVoice[][] =  {
	"player/taunt_yeti_roar_first.wav", 
	"player/taunt_yeti_roar_second.wav"
};

static char g_strYetiFootsteps[][] =  {
	"player/footsteps/giant1.wav", 
	"player/footsteps/giant2.wav"
};

methodmap CYeti < SaxtonHaleBase
{
	public CYeti(CYeti boss)
	{
		// TODO: Abilities
		boss.CallFunction("CreateAbility", "CBraveJump");
		boss.CallFunction("CreateAbility", "CGroundPound");
		//boss.CallFunction("CreateAbility", "CRageFreeze");
		
		boss.iBaseHealth = 800;
		boss.iHealthPerPlayer = 850;
		boss.nClass = TFClass_Heavy;
		boss.iMaxRageDamage = 2500;
	}
	
	public void GetBossName(char[] sName, int length)
	{
		strcopy(sName, length, "Last Yeti");
	}
	
	public void GetBossInfo(char[] sInfo, int length)
	{
		StrCat(sInfo, length, "\nHealth: High");
		StrCat(sInfo, length, "\n ");
		StrCat(sInfo, length, "\nAbilities");
		StrCat(sInfo, length, "\n- Brave Jump");
		StrCat(sInfo, length, "\n- Ground Slam");
		StrCat(sInfo, length, "\n ");
		StrCat(sInfo, length, "\nRage");
		StrCat(sInfo, length, "\n- Slows every player around the yeti for 3 seconds with a freezing aura");
		StrCat(sInfo, length, "\n- Then completely freezes everyone affected by the aura for 5 seconds");
		StrCat(sInfo, length, "\n- 200%% Rage: Extends duration to 10 seconds");
	}
	
	public void OnSpawn()
	{
		char attribs[128];
		Format(attribs, sizeof(attribs), "2 ; 2.80 ; 252 ; 0.5 ; 259 ; 1.0 ; 329 ; 0.65 ; 214 ; %d", GetRandomInt(9999, 99999));
		int iWeapon = this.CallFunction("CreateWeapon", 195, NULL_STRING, 100, TFQual_Strange, attribs);
		if (iWeapon > MaxClients)
		{
			SetEntPropEnt(this.iClient, Prop_Send, "m_hActiveWeapon", iWeapon);
			//Disable fists secondary attack
			SetEntPropFloat(iWeapon, Prop_Send, "m_flNextSecondaryAttack", GetGameTime() + 3600.0);
		}
		/*
		Fist attributes:
		
		2: damage bonus
		252: reduction in push force taken from damage
		259: Deals 3x falling damage to the player you land on
		329: reduction in airblast vulnerability
		214: kill_eater
		*/
	}
	
	public void GetModel(char[] sModel, int length)
	{
		strcopy(sModel, length, YETI_MODEL);
	}
	
	public void GetSound(char[] sSound, int length, SaxtonHaleSound iSoundType)
	{
		switch (iSoundType)
		{
			case VSHSound_RoundStart:strcopy(sSound, length, g_strYetiRoundStart[GetRandomInt(0, sizeof(g_strYetiRoundStart) - 1)]);
			case VSHSound_Win:strcopy(sSound, length, g_strYetiWin[GetRandomInt(0, sizeof(g_strYetiWin) - 1)]);
			case VSHSound_Lose:strcopy(sSound, length, g_strYetiLose[GetRandomInt(0, sizeof(g_strYetiLose) - 1)]);
			case VSHSound_Lastman:strcopy(sSound, length, g_strYetiLastMan[GetRandomInt(0, sizeof(g_strYetiLastMan) - 1)]);
			case VSHSound_Backstab:strcopy(sSound, length, g_strYetiBackStabbed[GetRandomInt(0, sizeof(g_strYetiBackStabbed) - 1)]);
		}
	}
	
	public void GetSoundAbility(char[] sSound, int length, const char[] sType)
	{
		// TODO: Abilities
		//if (strcmp(sType, "CRageFreeze") == 0)
		//strcopy(sSound, length, g_strYetiFreeze[GetRandomInt(0,sizeof(g_strYetiFreeze)-1)]);
		//if (strcmp(sType, "CGroundSlam") == 0)
		//strcopy(sSound, length, g_strYetiGroundSlam[GetRandomInt(0,sizeof(g_strYetiGroundSlam)-1)]);
	}
	
	public void GetSoundKill(char[] sSound, int length, TFClassType nClass)
	{
		strcopy(sSound, length, g_strYetiKill[GetRandomInt(0, sizeof(g_strYetiKill) - 1)]);
	}
	
	public Action OnSoundPlayed(int clients[MAXPLAYERS], int &numClients, char sample[PLATFORM_MAX_PATH], int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
	{
		if (strncmp(sample, "vo/", 3) == 0)
		{
			Format(sample, sizeof(sample), g_strYetiVoice[GetRandomInt(0, sizeof(g_strYetiVoice) - 1)]);
			return Plugin_Changed;
		}
		
		if (StrContains(sample, "player/footsteps/", false) == 0)
		{
			EmitSoundToAll(g_strYetiFootsteps[GetRandomInt(0, sizeof(g_strYetiFootsteps) - 1)], this.iClient, _, _, _, 0.4, GetRandomInt(90, 100));
			return Plugin_Handled;
		}
		
		return Plugin_Continue;
	}
	
	public void GetMusicInfo(char[] sSound, int length, float &time)
	{
		strcopy(sSound, length, YETI_THEME);
		time = 180.0;
	}
	
	public void Precache()
	{
		PrecacheModel(YETI_MODEL);
		
		PrecacheSound(YETI_THEME);
		
		for (int i = 0; i < sizeof(g_strYetiRoundStart); i++)PrecacheSound(g_strYetiRoundStart[i]);
		for (int i = 0; i < sizeof(g_strYetiWin); i++)PrecacheSound(g_strYetiWin[i]);
		for (int i = 0; i < sizeof(g_strYetiLose); i++)PrecacheSound(g_strYetiLose[i]);
		for (int i = 0; i < sizeof(g_strYetiFreeze); i++)PrecacheSound(g_strYetiFreeze[i]);
		for (int i = 0; i < sizeof(g_strYetiGroundSlam); i++)PrecacheSound(g_strYetiGroundSlam[i]);
		for (int i = 0; i < sizeof(g_strYetiKill); i++)PrecacheSound(g_strYetiKill[i]);
		for (int i = 0; i < sizeof(g_strYetiLastMan); i++)PrecacheSound(g_strYetiLastMan[i]);
		for (int i = 0; i < sizeof(g_strYetiBackStabbed); i++)PrecacheSound(g_strYetiBackStabbed[i]);
		for (int i = 0; i < sizeof(g_strYetiVoice); i++)PrecacheSound(g_strYetiVoice[i]);
		for (int i = 0; i < sizeof(g_strYetiFootsteps); i++)PrecacheSound(g_strYetiFootsteps[i]);
	}
};
