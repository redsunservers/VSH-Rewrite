#define SEELDIER_MODEL						"models/player/kirillian/boss/seeldier_fix.mdl"
#define SEELDIER_SEE_SND					"vsh_rewrite/seeldier/see.mp3"

#define SEELDIER_MINION_SPEED_MULTIPLIER	1.2
#define SEELDIER_MINION_JUMP_HEIGHT	500.0
#define SEELDIER_MINION_SMACK_DELAY	0.2
#define SEELDIER_MINION_SWING_RANGE	48.0
#define SEELDIER_MINION_SWING_HULL	18.0
#define SEELDIER_MINION_GROUND_NORMAL	0.7
#define SEELDIER_MINION_EXPLOSION_PARTICLE	"ExplosionCore_MidAir"
#define SEELDIER_MINION_EXPLOSION_SOUND	"weapons/explode1.wav"
#define SEELDIER_MINION_BLAST_COOLDOWN	6.0

static float g_flSeeldierMinionSmackTime[MAXPLAYERS];
static ConVar g_cvSeeldierGravity;
static float g_flSeeldierMinionBlastReady[MAXPLAYERS];

public void Seeldier_Create(SaxtonHaleBase boss)
{
	boss.CreateClass("WeaponFists");
	boss.CreateClass("BraveJump");
	
	boss.iHealthPerPlayer = 550;
	boss.flHealthExponential = 1.05;
	boss.nClass = TFClass_Soldier;
	boss.iMaxRageDamage = 2000;
}

public void Seeldier_GetBossMultiType(SaxtonHaleBase boss, char[] sType, int length)
{
	strcopy(sType, length, "SeeManSeeldier");
}

public bool Seeldier_IsBossHidden(SaxtonHaleBase boss)
{
	return true;
}

public void Seeldier_GetBossName(SaxtonHaleBase boss, char[] sName, int length)
{
	strcopy(sName, length, "Seeldier");
}

public void Seeldier_GetBossInfo(SaxtonHaleBase boss, char[] sInfo, int length)
{
	StrCat(sInfo, length, "\nDuo Boss with Seeman");
	StrCat(sInfo, length, "\nMelee deals 124 damage");
	StrCat(sInfo, length, "\nHealth: Low");
	StrCat(sInfo, length, "\n ");
	StrCat(sInfo, length, "\nAbilities");
	StrCat(sInfo, length, "\n- Brave Jump");
	StrCat(sInfo, length, "\n ");
	StrCat(sInfo, length, "\nRage");
	StrCat(sInfo, length, "\n- Damage requirement: 2000");
	StrCat(sInfo, length, "\n- Summons 3 mini-Seeldiers");
	StrCat(sInfo, length, "\n- 200%% Rage: Summons 6 mini-Seeldiers");
}

public void Seeldier_OnSpawn(SaxtonHaleBase boss)
{
	char attribs[128];
	Format(attribs, sizeof(attribs), "2 ; 1.9 ; 252 ; 0.5 ; 259 ; 1.0");
	int iWeapon = boss.CallFunction("CreateWeapon", 195, "tf_weapon_shovel", 100, TFQual_Collectors, attribs);
	if (iWeapon > MaxClients)
		SetEntPropEnt(boss.iClient, Prop_Send, "m_hActiveWeapon", iWeapon);
	/*
	Fist attributes:
	
	2: damage bonus
	252: reduction in push force taken from damage
	259: Deals 3x falling damage to the player you land on
	*/
}

public void Seeldier_GetModel(SaxtonHaleBase boss, char[] sModel, int length)
{
	strcopy(sModel, length, SEELDIER_MODEL);
}

public void Seeldier_OnRage(SaxtonHaleBase boss)
{
	int iTotalMinions = 3;
	if (boss.bSuperRage) iTotalMinions *= 2;
	
	ArrayList aValidMinions = GetValidSummonableClients();
	
	int iLength = aValidMinions.Length;
	if (iLength < iTotalMinions)
		iTotalMinions = iLength;
	else
		iLength = iTotalMinions;
	
	for (int i = 0; i < iLength; i++)
	{
		int iClient = aValidMinions.Get(i);
		
		SaxtonHaleBase bossMinion = SaxtonHaleBase(iClient);
		if (bossMinion.bValid)
			bossMinion.DestroyAllClass();
		
		bossMinion.CreateClass("SeeldierMinion");
		TF2_ForceTeamJoin(iClient, TFTeam_Boss);
		
		TF2_TeleportToClient(iClient, boss.iClient);
		TF2_AddCondition(iClient, TFCond_Ubercharged, 2.0);
	}
	
	delete aValidMinions;
}

public Action Seeldier_OnTakeDamage(SaxtonHaleBase boss, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	EmitSoundToAll(SEELDIER_SEE_SND, boss.iClient, SNDCHAN_VOICE, SNDLEVEL_SCREAMING);
	return Plugin_Continue;
}

public void Seeldier_GetSound(SaxtonHaleBase boss, char[] sSound, int length, SaxtonHaleSound iSoundType)
{
	//C on every sounds
	if (iSoundType != VSHSound_RoundStart)
		strcopy(sSound, length, SEELDIER_SEE_SND);
}

public void Seeldier_GetSoundAbility(SaxtonHaleBase boss, char[] sSound, int length, const char[] sType)
{
	if (strcmp(sType, "BraveJump") == 0)
		strcopy(sSound, length, SEELDIER_SEE_SND);
}

public void Seeldier_GetSoundKill(SaxtonHaleBase boss, char[] sSound, int length, TFClassType nClass)
{
	strcopy(sSound, length, SEELDIER_SEE_SND);
}

public Action Seeldier_OnSoundPlayed(SaxtonHaleBase boss, int clients[MAXPLAYERS], int &numClients, char sample[PLATFORM_MAX_PATH], int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
	if (strncmp(sample, "vo/", 3) == 0)
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public void Seeldier_Precache(SaxtonHaleBase boss)
{
	PrecacheModel(SEELDIER_MODEL);
	PrepareSound(SEELDIER_SEE_SND);
	PrecacheSound(SEELDIER_MINION_EXPLOSION_SOUND);
	
	AddFileToDownloadsTable("models/player/kirillian/boss/seeldier_fix.mdl");
	AddFileToDownloadsTable("models/player/kirillian/boss/seeldier_fix.vvd");
	AddFileToDownloadsTable("models/player/kirillian/boss/seeldier_fix.dx80.vtx");
	AddFileToDownloadsTable("models/player/kirillian/boss/seeldier_fix.dx90.vtx");
	AddFileToDownloadsTable("models/player/kirillian/boss/seeldier_fix.phy");
}

public void SeeldierMinion_Create(SaxtonHaleBase boss)
{
	boss.CreateClass("WeaponFists");
	
	boss.iBaseHealth = 300;
	boss.iHealthPerPlayer = 0;
	boss.nClass = TFClass_Soldier;
	boss.iMaxRageDamage = -1;
	boss.bMinion = true;
	boss.flSpeed *= SEELDIER_MINION_SPEED_MULTIPLIER;
	g_flSeeldierMinionSmackTime[boss.iClient] = 0.0;
	g_flSeeldierMinionBlastReady[boss.iClient] = 0.0;
}

public bool SeeldierMinion_IsBossHidden(SaxtonHaleBase boss)
{
	return true;
}

public void SeeldierMinion_OnSpawn(SaxtonHaleBase boss)
{
	char attribs[128];
	Format(attribs, sizeof(attribs), "2 ; 1.9 ; 252 ; 0.5 ; 259 ; 1.0");
	int iWeapon = boss.CallFunction("CreateWeapon", 195, "tf_weapon_shovel", 100, TFQual_Collectors, attribs);
	if (iWeapon > MaxClients)
		SetEntPropEnt(boss.iClient, Prop_Send, "m_hActiveWeapon", iWeapon);
	
	SetEntityModelScale(boss.iClient, 0.75);
}

public Action SeeldierMinion_OnAttackCritical(SaxtonHaleBase boss, int iWeapon, bool &bResult)
{
	if (iWeapon > MaxClients && iWeapon == TF2_GetItemInSlot(boss.iClient, WeaponSlot_Melee))
		g_flSeeldierMinionSmackTime[boss.iClient] = GetGameTime() + SEELDIER_MINION_SMACK_DELAY;
	
	return Plugin_Continue;
}

public void SeeldierMinion_OnThink(SaxtonHaleBase boss)
{
	if (g_flSeeldierMinionSmackTime[boss.iClient] <= 0.0 || GetGameTime() < g_flSeeldierMinionSmackTime[boss.iClient])
		return;
	
	g_flSeeldierMinionSmackTime[boss.iClient] = 0.0;
	if (IsPlayerAlive(boss.iClient))
		SeeldierMinion_GroundBlast(boss.iClient);
}

static void SeeldierMinion_GroundBlast(int iClient)
{
	if (GetGameTime() < g_flSeeldierMinionBlastReady[iClient])
		return;
	
	int iWeapon = TF2_GetItemInSlot(iClient, WeaponSlot_Melee);
	if (iWeapon <= MaxClients)
		return;
	
	float flRange = TF2Attrib_HookValueFloat(SEELDIER_MINION_SWING_RANGE, "melee_range_multiplier", iWeapon);
	float flHull = TF2Attrib_HookValueFloat(SEELDIER_MINION_SWING_HULL, "melee_bounds_multiplier", iWeapon);
	
	float vecStart[3], vecAngles[3], vecForward[3], vecEnd[3];
	GetClientEyePosition(iClient, vecStart);
	GetClientEyeAngles(iClient, vecAngles);
	GetAngleVectors(vecAngles, vecForward, NULL_VECTOR, NULL_VECTOR);
	for (int i = 0; i < 3; i++)
		vecEnd[i] = vecStart[i] + vecForward[i] * flRange;
	
	float vecMins[3], vecMaxs[3];
	for (int i = 0; i < 3; i++)
	{
		vecMins[i] = -flHull;
		vecMaxs[i] = flHull;
	}
	
	TR_TraceRayFilter(vecStart, vecEnd, MASK_SOLID, RayType_EndPoint, SeeldierMinion_TraceFilter, iClient);
	if (!TR_DidHit())
	{
		TR_TraceHullFilter(vecStart, vecEnd, vecMins, vecMaxs, MASK_SOLID, SeeldierMinion_TraceFilter, iClient);
		if (!TR_DidHit())
			return;
	}
	
	int iHit = TR_GetEntityIndex();
	if (0 < iHit <= MaxClients)
		return;
	
	if (iHit > MaxClients)
	{
		char sClassname[64];
		GetEntityClassname(iHit, sClassname, sizeof(sClassname));
		if (strncmp(sClassname, "obj_", 4) == 0)
			return;
	}
	
	float vecNormal[3], vecPos[3];
	TR_GetPlaneNormal(null, vecNormal);
	if (vecNormal[2] < SEELDIER_MINION_GROUND_NORMAL)
		return;
	
	TR_GetEndPosition(vecPos);
	
	char sParticle[64];
	strcopy(sParticle, sizeof(sParticle), SEELDIER_MINION_EXPLOSION_PARTICLE);
	CreateTimer(3.0, Timer_EntityCleanup, TF2_SpawnParticle(sParticle, vecPos));
	EmitAmbientSound(SEELDIER_MINION_EXPLOSION_SOUND, vecPos);
	
	if (g_cvSeeldierGravity == null)
		g_cvSeeldierGravity = FindConVar("sv_gravity");
	
	float flGravity = (g_cvSeeldierGravity != null) ? g_cvSeeldierGravity.FloatValue : 800.0;
	float flScale = GetEntityGravity(iClient);
	if (flScale > 0.0)
		flGravity *= flScale;
	
	float vecVelocity[3];
	GetEntPropVector(iClient, Prop_Data, "m_vecVelocity", vecVelocity);
	vecVelocity[2] = SquareRoot(2.0 * flGravity * SEELDIER_MINION_JUMP_HEIGHT);
	TeleportEntity(iClient, NULL_VECTOR, NULL_VECTOR, vecVelocity);
	
	g_flSeeldierMinionBlastReady[iClient] = GetGameTime() + SEELDIER_MINION_BLAST_COOLDOWN;
	SaxtonHaleBase(iClient).CallFunction("UpdateHudInfo", 1.0, SEELDIER_MINION_BLAST_COOLDOWN + 1.0);
}

public void SeeldierMinion_GetHudInfo(SaxtonHaleBase boss, char[] sMessage, int iLength, int iColor[4])
{
	float flLeft = g_flSeeldierMinionBlastReady[boss.iClient] - GetGameTime();
	if (flLeft <= 0.0)
		return;
	
	int iSec = RoundToCeil(flLeft);
	char sPlural[2];
	if (iSec > 1)
		strcopy(sPlural, sizeof(sPlural), "s");
	
	Format(sMessage, iLength, "%s\nBlast-jump cooldown %i second%s remaining!", sMessage, iSec, sPlural);
}

public bool SeeldierMinion_TraceFilter(int iEntity, int iMask, int iClient)
{
	if (iEntity == iClient)
		return false;
	
	if (0 < iEntity <= MaxClients && IsClientInGame(iEntity) && GetClientTeam(iEntity) == GetClientTeam(iClient))
		return false;
	
	return true;
}

public void SeeldierMinion_GetModel(SaxtonHaleBase boss, char[] sModel, int length)
{
	strcopy(sModel, length, SEELDIER_MODEL);
}

public void SeeldierMinion_GetSound(SaxtonHaleBase boss, char[] sSound, int length, SaxtonHaleSound iSoundType)
{
	strcopy(sSound, length, SEELDIER_SEE_SND);
}

public void SeeldierMinion_GetSoundKill(SaxtonHaleBase boss, TFClassType playerClass, char[] sSound, int length)
{
	strcopy(sSound, length, SEELDIER_SEE_SND);
}

public Action SeeldierMinion_OnSoundPlayed(SaxtonHaleBase boss, int clients[MAXPLAYERS], int &numClients, char sample[PLATFORM_MAX_PATH], int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
	if (strncmp(sample, "vo/", 3) == 0)
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public void SeeldierMinion_Destroy(SaxtonHaleBase boss)
{
	SetEntityModelScale(boss.iClient, 1.0);
	g_flSeeldierMinionSmackTime[boss.iClient] = 0.0;
	g_flSeeldierMinionBlastReady[boss.iClient] = 0.0;
}
