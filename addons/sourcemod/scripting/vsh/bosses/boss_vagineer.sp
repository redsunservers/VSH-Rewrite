#define VAGINEER_MODEL		"models/player/saxton_hale/vagineer_v150.mdl"
#define VAGINEER_KILL_SOUND "vsh_rewrite/vagineer/vagineer_kill.mp3"

static float g_flVagineerSentryHealthDecay[TF_MAXPLAYERS+1] = 0.0;

static char g_strVagineerRageMusic[][] = {
	"vsh_rewrite/vagineer/vagineer_rage_music_1.mp3",
	"vsh_rewrite/vagineer/vagineer_rage_music_2.mp3",
	"vsh_rewrite/vagineer/vagineer_rage_music_3.mp3"
};

static char g_strVagineerRoundStart[][] = {
	"vsh_rewrite/vagineer/vagineer_responce_intro_1.mp3",
	"vsh_rewrite/vagineer/vagineer_responce_intro_2.mp3"
};

static char g_strVagineerLose[][] = {
	"vsh_rewrite/vagineer/vagineer_responce_fail_1.mp3",
	"vsh_rewrite/vagineer/vagineer_responce_fail_2.mp3"
};

static char g_strVagineerRage[][] = {
	"vsh_rewrite/vagineer/vagineer_responce_rage_1.mp3",
	"vsh_rewrite/vagineer/vagineer_responce_rage_2.mp3",
	"vsh_rewrite/vagineer/vagineer_responce_rage_3.mp3",
	"vsh_rewrite/vagineer/vagineer_responce_rage_4.mp3"
};

static char g_strVagineerJump[][] = {
	"vsh_rewrite/vagineer/vagineer_responce_jump_1.mp3",
	"vsh_rewrite/vagineer/vagineer_responce_jump_2.mp3"
};

static char g_strVagineerKill[][] = {
	"vsh_rewrite/vagineer/vagineer_responce_taunt_1.mp3",
	"vsh_rewrite/vagineer/vagineer_responce_taunt_2.mp3",
	"vsh_rewrite/vagineer/vagineer_responce_taunt_3.mp3",
	"vsh_rewrite/vagineer/vagineer_responce_taunt_4.mp3",
	"vsh_rewrite/vagineer/vagineer_responce_taunt_5.mp3",
	"vsh_rewrite/vagineer/vagineer_responce_taunt_6.mp3"
};

static char g_strVagineerLastMan[][] = {
	"vsh_rewrite/vagineer/vagineer_lastman.mp3"
};

static char g_strVagineerBackStabbed[][] = {
	"vsh_rewrite/vagineer/vagineer_responce_rage_2.mp3",
	"vsh_rewrite/vagineer/vagineer_responce_rage_3.mp3"
};

methodmap CVagineer < SaxtonHaleBase
{
	public CVagineer(CVagineer boss)
	{
		boss.CallFunction("CreateAbility", "CBraveJump");
		CScareRage scareAbility = boss.CallFunction("CreateAbility", "CScareRage");
		scareAbility.flRadius = 200.0;
		
		boss.iBaseHealth = 750;
		boss.iHealthPerPlayer = 700;
		boss.nClass = TFClass_Engineer;
		boss.iMaxRageDamage = 2500;
		
		g_flVagineerSentryHealthDecay[boss.iClient] = 0.0;
	}
	
	public bool IsBossHidden()
	{
		return true;
	}
	
	public void GetBossName(char[] sName, int length)
	{
		strcopy(sName, length, "Vagineer");
	}
	
	public void GetBossInfo(char[] sInfo, int length)
	{
		StrCat(sInfo, length, "\nHealth: Slightly low");
		StrCat(sInfo, length, "\n ");
		StrCat(sInfo, length, "\nAbilities");
		StrCat(sInfo, length, "\n- Brave Jump");
		StrCat(sInfo, length, "\n ");
		StrCat(sInfo, length, "\nRage");
		StrCat(sInfo, length, "\n- Builds Sentry with faster firing speed, and health scales with players alive");
		StrCat(sInfo, length, "\n- Scares players at small range for 5 seconds");
		StrCat(sInfo, length, "\n- 200%% Rage: 50%% extra Sentry health, larger scare range and extends duration to 7.5 seconds");
	}
	
	public void OnSpawn()
	{
		SetEntProp(this.iClient, Prop_Send, "m_iAmmo", 0, 4, 3);
		this.CallFunction("CreateWeapon", 25, "tf_weapon_pda_engineer_build", 100, TFQual_Unusual, "");
		int iWeapon = this.CallFunction("CreateWeapon", 28, "tf_weapon_builder", 100, TFQual_Unusual, "");
		if (iWeapon > MaxClients)
			SetEntProp(iWeapon, Prop_Send, "m_aBuildableObjectTypes", 1, _, view_as<int>(TFObject_Sentry));	//Allow sentry to actually be built
		
		char attribs[256];
		Format(attribs, sizeof(attribs), "2 ; 2.80 ; 252 ; 0.5 ; 259 ; 1.0 ; 329 ; 0.65 ; 93 ; 0.0 ; 95 ; 0.0 ; 343 ; 0.5 ; 353 ; 1.0 ; 436 ; 1.0 ; 464 ; 10.0 ; 2043 ; 0.0");
		iWeapon = this.CallFunction("CreateWeapon", 7, "tf_weapon_wrench", 100, TFQual_Collectors, attribs);
		if (iWeapon > MaxClients)
			SetEntPropEnt(this.iClient, Prop_Send, "m_hActiveWeapon", iWeapon);
		/*
		Wrench attributes:
		
		2: damage bonus
		252: reduction in push force taken from damage
		259: Deals 3x falling damage to the player you land on
		329: reduction in airblast vulnerability
		
		93: Construction hit speed boost decreased
		95: Slower repair speed
		343: Sentry firing speed bonus
		353: Cannot carry buildings
		436: Plasma effect
		464: Sentry build speed increased
		2043: slower upgrade rate
		*/
	}
	
	public void GetModel(char[] sModel, int length)
	{
		strcopy(sModel, length, VAGINEER_MODEL);
	}
	
	public void GetSound(char[] sSound, int length, SaxtonHaleSound iSoundType)
	{
		switch (iSoundType)
		{
			case VSHSound_RoundStart: strcopy(sSound, length, g_strVagineerRoundStart[GetRandomInt(0,sizeof(g_strVagineerRoundStart)-1)]);
			case VSHSound_Lose: strcopy(sSound, length, g_strVagineerLose[GetRandomInt(0,sizeof(g_strVagineerLose)-1)]);
			case VSHSound_Rage: strcopy(sSound, length, g_strVagineerRage[GetRandomInt(0,sizeof(g_strVagineerRage)-1)]);
			case VSHSound_Lastman: strcopy(sSound, length, g_strVagineerLastMan[GetRandomInt(0,sizeof(g_strVagineerLastMan)-1)]);
			case VSHSound_Backstab: strcopy(sSound, length, g_strVagineerBackStabbed[GetRandomInt(0,sizeof(g_strVagineerBackStabbed)-1)]);
		}
	}
	
	public void GetSoundAbility(char[] sSound, int length, const char[] sType)
	{
		if (strcmp(sType, "CBraveJump") == 0)
			strcopy(sSound, length, g_strVagineerJump[GetRandomInt(0,sizeof(g_strVagineerJump)-1)]);
	}
	
	public void GetSoundKill(char[] sSound, int length, TFClassType nClass)
	{
		strcopy(sSound, length, g_strVagineerKill[GetRandomInt(0,sizeof(g_strVagineerKill)-1)]);
	}
	
	public void OnPlayerKilled(Event event, int iVictim)
	{
		EmitSoundToAll(VAGINEER_KILL_SOUND);
	}
	
	public void GetRageMusicInfo(char[] sSound, int length, float &time)
	{
		strcopy(sSound, length, g_strVagineerRageMusic[GetRandomInt(0,sizeof(g_strVagineerRageMusic)-1)]);
		time = 19.0;
	}
	
	public Action OnSoundPlayed(int clients[MAXPLAYERS], int &numClients, char sample[PLATFORM_MAX_PATH], int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
	{
		if (strncmp(sample, "vo/", 3) == 0)//Block voicelines
			return Plugin_Handled;
		return Plugin_Continue;
	}
	
	public Action OnBuild(TFObjectType nType, TFObjectMode nMode)
	{
		if (nType == TFObject_Sentry)	//Allow sentry to be built, block otherwise
			return Plugin_Continue;
		
		return Plugin_Handled;
	}
	
	public Action OnBuildObject(Event event)
	{
		int iEntity = event.GetInt("index");
		int iAliveCount = SaxtonHale_GetAliveAttackPlayers();
		
		int iSentryHealth = iAliveCount * 150 + 200;
		if (iSentryHealth > 1800)
			iSentryHealth = 1800;
			
		if (this.bSuperRage)
			iSentryHealth = RoundToNearest(float(iSentryHealth) * 1.5);
		
		SetVariantInt(iSentryHealth);
		AcceptEntityInput(iEntity, "SetHealth");	//Sets sentry health
		
		return Plugin_Continue;
	}
	
	public Action OnObjectSapped(Event event)
	{
		int iVictim = GetClientOfUserId(event.GetInt("ownerid"));
		
		int iSentry = MaxClients+1;
		while((iSentry = FindEntityByClassname(iSentry, "obj_sentrygun")) > MaxClients)
			if (GetEntPropEnt(iSentry, Prop_Send, "m_hBuilder") == iVictim)
				SetEntProp(iSentry, Prop_Send, "m_bDisabled", 0);
	}
	
	public void OnRage()
	{
		FakeClientCommand(this.iClient, "destroy 2 0");
		SetEntProp(this.iClient, Prop_Send, "m_iAmmo", 130, 4, 3);
		FakeClientCommand(this.iClient, "build 2 0");
	}
	
	public void OnThink()
	{		
		Hud_AddText(this.iClient, "Use your rage to build sentry at a safe place!");
		
		int iSentry = MaxClients+1;
		while((iSentry = FindEntityByClassname(iSentry, "obj_sentrygun")) > MaxClients)
		{
			if (GetEntPropEnt(iSentry, Prop_Send, "m_hBuilder") == this.iClient)
			{				
				if (g_flVagineerSentryHealthDecay[this.iClient] < GetGameTime() - 0.01)
				{
					SetVariantInt(1);
					AcceptEntityInput(iSentry, "RemoveHealth");
					g_flVagineerSentryHealthDecay[this.iClient] = GetGameTime();
					
					if (GetEntPropFloat(iSentry, Prop_Send, "m_flModelScale") != 1.22)
						SetEntPropFloat(iSentry, Prop_Send, "m_flModelScale", 1.22);
				}
			}
		}
	}
	
	public void Precache()
	{
		PrepareSound(VAGINEER_KILL_SOUND);
		for (int i = 0; i < sizeof(g_strVagineerRageMusic); i++) PrepareSound(g_strVagineerRageMusic[i]);
		for (int i = 0; i < sizeof(g_strVagineerRoundStart); i++) PrepareSound(g_strVagineerRoundStart[i]);
		for (int i = 0; i < sizeof(g_strVagineerLose); i++) PrepareSound(g_strVagineerLose[i]);
		for (int i = 0; i < sizeof(g_strVagineerRage); i++) PrepareSound(g_strVagineerRage[i]);
		for (int i = 0; i < sizeof(g_strVagineerJump); i++) PrepareSound(g_strVagineerJump[i]);
		for (int i = 0; i < sizeof(g_strVagineerKill); i++) PrepareSound(g_strVagineerKill[i]);
		for (int i = 0; i < sizeof(g_strVagineerLastMan); i++) PrepareSound(g_strVagineerLastMan[i]);
		for (int i = 0; i < sizeof(g_strVagineerBackStabbed); i++) PrepareSound(g_strVagineerBackStabbed[i]);
		
		AddFileToDownloadsTable("models/player/saxton_hale/vagineer_v150.mdl");
		AddFileToDownloadsTable("models/player/saxton_hale/vagineer_v150.phy");
		AddFileToDownloadsTable("models/player/saxton_hale/vagineer_v150.sw.vtx");
		AddFileToDownloadsTable("models/player/saxton_hale/vagineer_v150.vvd");
		AddFileToDownloadsTable("models/player/saxton_hale/vagineer_v150.dx80.vtx");
		AddFileToDownloadsTable("models/player/saxton_hale/vagineer_v150.dx90.vtx");
	}
};