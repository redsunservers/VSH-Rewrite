#define SANS_MODEL "models/freak_fortress_2/sanstheskeleton/sans.mdl"
#define SANS_RAGE_MODEL "models/freak_fortress_2/sanstheskeleton/sansrage.mdl"
#define SANS_THEME "freak_fortress_2/sanstheskeleton/bgm.wav"

#define SANS_CATCHPHRASE "freak_fortress_2/sanstheskeleton/catchphrase.wav"

static char g_strSansRoundStart[][] = {
	"freak_fortress_2/sanstheskeleton/intro.wav"
};

static char g_strSansWin[][] = {
	"freak_fortress_2/sanstheskeleton/win.wav"
};

static char g_strSansLose[][] = {
	"freak_fortress_2/sanstheskeleton/win.wav"
};

static char g_strSansKill[][] = {
	"freak_fortress_2/sanstheskeleton/kill.wav"
};

static char g_strSansLastMan[][] = {
	"freak_fortress_2/sanstheskeleton/lastman.wav"
};

static char g_strSansBackStabbed[][] = {
	"freak_fortress_2/sanstheskeleton/backstabbed.wav"
};

methodmap CSans < SaxtonHaleBase
{
	public CSans(CSans boss)
	{
		boss.CallFunction("CreateAbility", "CTeleportSwap");
		CScareRage gasterBlaster = boss.CallFunction("CreateAbility", "CScareRage");
		
		gasterBlaster.flRadius = 1300.0;
		
		boss.iBaseHealth = 700;
		boss.iHealthPerPlayer = 700;
		boss.nClass = TFClass_Sniper;
		boss.iMaxRageDamage = 2150;
	}
	
	public void GetBossName(char[] sName, int length)
	{
		strcopy(sName, length, "Sans The Skeleton");
	}
	
	public void GetBossInfo(char[] sInfo, int length)
	{
		StrCat(sInfo, length, "\nHealth: Medium");
		StrCat(sInfo, length, "\n ");
		StrCat(sInfo, length, "\nAbilities");
		StrCat(sInfo, length, "\n- Teleport");
		StrCat(sInfo, length, "\n ");
		StrCat(sInfo, length, "\nRage");
		StrCat(sInfo, length, "\n- Scares the enemy and gives you a CAPPER with double fire rate");
		StrCat(sInfo, length, "\n- 200%% Rage: Longer Duration");
	}
	
	public void OnSpawn()
	{
		int iClient = this.iClient;

		int iWeapon = this.CallFunction("CreateWeapon", 30666, "tf_weapon_smg", 69, TFQual_Collectors, "6 ; 1.0");
		if (IsValidEntity(iWeapon)) 
		{
			SetEntProp(iWeapon, Prop_Send, "m_iClip1", 0);
			SetEntProp(iClient, Prop_Send, "m_iAmmo", 0, _, 2);
		}
		
		iWeapon = this.CallFunction("CreateWeapon", 939, "tf_weapon_club", 69, TFQual_Strange, "138 ; 0.80 ; 326 ; 2.00");
		if (IsValidEntity(iWeapon))
			SetEntPropEnt(this.iClient, Prop_Send, "m_hActiveWeapon", iWeapon);
	}
	
	public bool IsBossHidden()
	{
		return true;
	}
	
	public void GetModel(char[] sModel, int length)
	{
		strcopy(sModel, length, SANS_MODEL);
	}
	
	public void GetSound(char[] sSound, int length, SaxtonHaleSound iSoundType)
	{
		switch (iSoundType)
		{
			case VSHSound_RoundStart: strcopy(sSound, length, g_strSansRoundStart[GetRandomInt(0,sizeof(g_strSansRoundStart)-1)]);
			case VSHSound_Win: strcopy(sSound, length, g_strSansWin[GetRandomInt(0,sizeof(g_strSansWin)-1)]);
			case VSHSound_Lose: strcopy(sSound, length, g_strSansLose[GetRandomInt(0,sizeof(g_strSansLose)-1)]);
			case VSHSound_Rage: strcopy(sSound, length, SANS_CATCHPHRASE);
			case VSHSound_KillBuilding: strcopy(sSound, length, g_strSansKill[GetRandomInt(0,sizeof(g_strSansKill)-1)]);
			case VSHSound_Lastman: strcopy(sSound, length, g_strSansLastMan[GetRandomInt(0,sizeof(g_strSansLastMan)-1)]);
			case VSHSound_Backstab: strcopy(sSound, length, g_strSansBackStabbed[GetRandomInt(0,sizeof(g_strSansBackStabbed)-1)]);
		}
	}
	
	public void OnRage()
	{
		int iClient = this.iClient;
		int iPlayerCount = SaxtonHale_GetAliveAttackPlayers();
		
		int iWep = GetPlayerWeaponSlot(iClient, WeaponSlot_Secondary);
		if (IsValidEntity(iWep))
		{
			int iAmmo = GetEntProp(iClient, Prop_Send, "m_iAmmo", _, 1);
			iAmmo += (1 + RoundToFloor(view_as<float>(iPlayerCount) * 10.0));
			SetEntProp(iClient, Prop_Send, "m_iAmmo", iAmmo, _, 2);
			SetEntProp(iWep, Prop_Send, "m_iClip1", 25);
			SetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon", iWep);
		}
	}
	
	public void GetSoundAbility(char[] sSound, int length, const char[] sType)
	{
		if (strcmp(sType, "CTeleport") == 0)
			strcopy(sSound, length, SANS_CATCHPHRASE);
	}
	
	public void GetSoundKill(char[] sSound, int length, TFClassType nClass)
	{
		strcopy(sSound, length, g_strSansKill[GetRandomInt(0,sizeof(g_strSansKill)-1)]);
	}
	
	public Action OnSoundPlayed(int clients[MAXPLAYERS], int &numClients, char sample[PLATFORM_MAX_PATH], int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
	{
		if (strncmp(sample, "vo/", 3) == 0)//Block voicelines
			return Plugin_Handled;
		return Plugin_Continue;
	}
	
	public void GetMusicInfo(char[] sSound, int length, float &time)
	{
		strcopy(sSound, length, SANS_THEME);
		time = 155.0;
	}
	
	public void Precache()
	{
		PrecacheModel(SANS_MODEL);
		PrecacheModel(SANS_RAGE_MODEL);
		for (int i = 0; i < sizeof(g_strSansRoundStart); i++) PrepareSound(g_strSansRoundStart[i]);
		for (int i = 0; i < sizeof(g_strSansWin); i++) PrepareSound(g_strSansWin[i]);
		for (int i = 0; i < sizeof(g_strSansLose); i++) PrepareSound(g_strSansLose[i]);
		for (int i = 0; i < sizeof(g_strSansKill); i++) PrepareSound(g_strSansKill[i]);
		for (int i = 0; i < sizeof(g_strSansLastMan); i++) PrepareSound(g_strSansLastMan[i]);
		for (int i = 0; i < sizeof(g_strSansBackStabbed); i++) PrepareSound(g_strSansBackStabbed[i]);
		
		PrepareSound(SANS_CATCHPHRASE);
		
		AddFileToDownloadsTable("materials/freak_fortress_2/sans/bone.vmt");
		AddFileToDownloadsTable("materials/freak_fortress_2/sans/bone.vtf");
		AddFileToDownloadsTable("materials/freak_fortress_2/sans/bonenorm.vtf");
		AddFileToDownloadsTable("materials/freak_fortress_2/sans/sans_diff.vmt");
		AddFileToDownloadsTable("materials/freak_fortress_2/sans/sans_diff.vtf");
		AddFileToDownloadsTable("materials/freak_fortress_2/sans/sans_glow.vmt");
		AddFileToDownloadsTable("materials/freak_fortress_2/sans/sans_norm.vtf");
		
		AddFileToDownloadsTable("models/freak_fortress_2/sanstheskeleton/sans.mdl");
		AddFileToDownloadsTable("models/freak_fortress_2/sanstheskeleton/sans.sw.vtx");
		AddFileToDownloadsTable("models/freak_fortress_2/sanstheskeleton/sans.vvd");
		AddFileToDownloadsTable("models/freak_fortress_2/sanstheskeleton/sans.dx80.vtx");
		AddFileToDownloadsTable("models/freak_fortress_2/sanstheskeleton/sans.dx90.vtx");
		AddFileToDownloadsTable("models/freak_fortress_2/sanstheskeleton/sansrage.mdl");
		AddFileToDownloadsTable("models/freak_fortress_2/sanstheskeleton/sansrage.sw.vtx");
		AddFileToDownloadsTable("models/freak_fortress_2/sanstheskeleton/sansrage.vvd");
		AddFileToDownloadsTable("models/freak_fortress_2/sanstheskeleton/sansrage.dx80.vtx");
		AddFileToDownloadsTable("models/freak_fortress_2/sanstheskeleton/sansrage.dx90.vtx");
	}
};
