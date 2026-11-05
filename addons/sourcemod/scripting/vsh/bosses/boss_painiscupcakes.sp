#define PAINIS_RAGE_MUSIC "vsh_rewrite/painis/rage.mp3"

#define PAINIS_CORPSE_TICK	0.2
#define PAINIS_CORPSE_SCOUT_SPEED	0.10
#define PAINIS_CORPSE_SOLDIER_DAMAGE	20.0
#define PAINIS_CORPSE_SOLDIER_RADIUS	100.0
#define PAINIS_CORPSE_SOLDIER_RADIUS_STACK	50.0
#define PAINIS_CORPSE_SOLDIER_RADIUS_SUPER	50.0
#define PAINIS_CORPSE_PYRO_BURN	5.0
#define PAINIS_CORPSE_PYRO_PULSE	0.5
#define PAINIS_CORPSE_PYRO_RADIUS	135.0
#define PAINIS_CORPSE_PYRO_AFTERBURN	4.0
#define PAINIS_CORPSE_HEAVY_RESIST	0.05
#define PAINIS_CORPSE_RESIST_CAP	0.80
#define PAINIS_CORPSE_DEMO_MELEE	0.10
#define PAINIS_CORPSE_ENGINEER_BUILDING	0.50
#define PAINIS_CORPSE_SNIPER_RANGE	5.0
#define PAINIS_MELEE_BASE_RANGE	48.0
#define PAINIS_ATTRIB_MELEE_RANGE	264
#define PAINIS_CORPSE_SPY_RADIUS	250.0
#define PAINIS_CORPSE_SAPPER_DPS	25.0
#define PAINIS_CORPSE_MEDIC_HEAL	1000
#define PAINIS_MAX_EDICTS	2048
#define PAINIS_RING_PARTICLE	"heavy_ring_of_fire"
#define PAINIS_EXPLOSION_PARTICLE	"ExplosionCore_MidAir"
#define PAINIS_EXPLOSION_SOUND	"weapons/explode1.wav"
#define PAINIS_SAPPER_MODEL	"models/buildables/sapper_placed.mdl"
#define PAINIS_SAPPER_PLANT_SOUND	"weapons/sapper_plant.wav"
#define PAINIS_SAPPER_LOOP_SOUND	"weapons/sapper_timer.wav"
#define PAINIS_SAPPER_REMOVED_SOUND	"weapons/sapper_removed.wav"

static int g_iPainisCorpseStacks[MAXPLAYERS][10];
static bool g_bPainisCorpseActive[MAXPLAYERS];
static float g_flPainisCorpseNextTick[MAXPLAYERS];
static float g_flPainisSpeedApplied[MAXPLAYERS];
static float g_flPainisRangeApplied[MAXPLAYERS];
static int g_iPainisRangeWeapon[MAXPLAYERS];
static float g_flPainisPyroNextPulse[MAXPLAYERS];
static float g_flPainisRingLastHit[MAXPLAYERS];
static int g_iPainisBurnBoss[MAXPLAYERS];
static float g_flPainisBurnEnd[MAXPLAYERS];
static float g_flPainisBurnDamage[MAXPLAYERS];
static int g_iPainisSapBoss[PAINIS_MAX_EDICTS];
static int g_iPainisSapRef[PAINIS_MAX_EDICTS];
static int g_iPainisSapProp[PAINIS_MAX_EDICTS];

static char g_strPainisBuildingClasses[][] = {
	"obj_sentrygun",
	"obj_dispenser",
	"obj_teleporter"
};

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
	boss.SetPropInt("BodyEat", "RageClassEffects", 1);
	
	boss.CreateClass("LightRage");
	boss.SetPropFloat("LightRage", "LigthRageDuration", 8.0);
	boss.SetPropFloat("LightRage", "LightRageRadius", 450.0);
	boss.SetPropInt("LightRage", "RageLightBrigthness", 6);
	
	boss.CreateClass("RageAddCond");
	boss.SetPropFloat("RageAddCond", "RageCondDuration", 8.0);
	RageAddCond_AddCond(boss, TFCond_SpeedBuffAlly);
	
	boss.iHealthPerPlayer = 500;
	boss.flHealthExponential = 1.05;
	boss.nClass = TFClass_Soldier;
	boss.iMaxRageDamage = 2500;

	Painis_ResetCorpseState(boss.iClient);
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
	StrCat(sInfo, length, "\n- Gain damage resistance, automatically eats nearby corpses and gain special effects based on which class the corpse was");
	StrCat(sInfo, length, "\n- 200%% Rage: extends duration to 16 seconds");
}

#define PAINIS_RAGE_DAMAGE_TAKEN	0.8

public Action PainisCupcake_OnTakeDamage(SaxtonHaleBase boss, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	float flDuration = boss.GetPropFloat("RageAddCond", "RageCondDuration");
	if (boss.bSuperRage)
		flDuration *= boss.GetPropFloat("RageAddCond", "RageCondSuperRageMultiplier");
	
	if (boss.flRageLastTime <= 0.0 || GetGameTime() - boss.flRageLastTime > flDuration)
		return Plugin_Continue;

	float flResistance = 1.0 - PAINIS_RAGE_DAMAGE_TAKEN;
	if (g_bPainisCorpseActive[boss.iClient])
		flResistance += PAINIS_CORPSE_HEAVY_RESIST * float(Painis_GetStacks(boss.iClient, TFClass_Heavy)) * Painis_GetCorpseMultiplier(boss);

	if (flResistance > PAINIS_CORPSE_RESIST_CAP)
		flResistance = PAINIS_CORPSE_RESIST_CAP;

	damage *= 1.0 - flResistance;
	return Plugin_Changed;
}

public Action PainisCupcake_OnAttackDamage(SaxtonHaleBase boss, int victim, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	Action action = Plugin_Continue;

	if (damagecustom == TF_CUSTOM_BURNING && 0 < victim <= MaxClients && g_iPainisBurnBoss[victim] == boss.iClient)
	{
		if (GetGameTime() - g_flPainisRingLastHit[victim] < PAINIS_CORPSE_PYRO_PULSE + 0.1)
			return Plugin_Stop;

		damage = g_flPainisBurnDamage[victim];
		action = Plugin_Changed;
	}

	if (g_bPainisCorpseActive[boss.iClient] && Painis_IsMeleeHit(boss, inflictor, weapon, damagecustom))
	{
		int iDemo = Painis_GetStacks(boss.iClient, TFClass_DemoMan);
		if (iDemo > 0)
		{
			damage *= 1.0 + PAINIS_CORPSE_DEMO_MELEE * float(iDemo) * Painis_GetCorpseMultiplier(boss);
			action = Plugin_Changed;
		}

		Painis_QueueExplosion(boss, victim, damagePosition);
	}

	return action;
}

public Action PainisCupcake_OnAttackBuilding(SaxtonHaleBase boss, int building, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if (!g_bPainisCorpseActive[boss.iClient])
		return Plugin_Continue;

	Action action = Plugin_Continue;
	float flMult = Painis_GetCorpseMultiplier(boss);

	if (Painis_IsMeleeHit(boss, inflictor, weapon, damagecustom))
	{
		int iDemo = Painis_GetStacks(boss.iClient, TFClass_DemoMan);
		if (iDemo > 0)
		{
			damage *= 1.0 + PAINIS_CORPSE_DEMO_MELEE * float(iDemo) * flMult;
			action = Plugin_Changed;
		}

		Painis_QueueExplosion(boss, building, damagePosition);
	}

	int iEngineer = Painis_GetStacks(boss.iClient, TFClass_Engineer);
	if (iEngineer > 0)
	{
		damage *= 1.0 + PAINIS_CORPSE_ENGINEER_BUILDING * float(iEngineer) * flMult;
		action = Plugin_Changed;
	}

	return action;
}

public void PainisCupcake_OnRage(SaxtonHaleBase boss)
{
	Painis_EndCorpseEffects(boss);

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

public void PainisCupcake_OnRageBodyEaten(SaxtonHaleBase boss, int iBody, TFClassType nClass)
{
	int iClass = view_as<int>(nClass);
	if (iClass <= view_as<int>(TFClass_Unknown) || iClass >= sizeof(g_iPainisCorpseStacks[]))
		return;

	g_bPainisCorpseActive[boss.iClient] = true;
	g_iPainisCorpseStacks[boss.iClient][iClass]++;

	if (nClass == TFClass_Medic)
		Client_AddHealth(boss.iClient, RoundToNearest(float(PAINIS_CORPSE_MEDIC_HEAL) * Painis_GetCorpseMultiplier(boss)), 0);

	Painis_UpdateCorpseEffects(boss);
}

public void PainisCupcake_OnThink(SaxtonHaleBase boss)
{
	int iClient = boss.iClient;
	float flNow = GetGameTime();
	Painis_PyroPulse(boss);
	if (flNow < g_flPainisCorpseNextTick[iClient])
		return;

	if (g_flPainisCorpseNextTick[iClient] > 0.0 && flNow - g_flPainisCorpseNextTick[iClient] < PAINIS_CORPSE_TICK)
		g_flPainisCorpseNextTick[iClient] += PAINIS_CORPSE_TICK;
	else
		g_flPainisCorpseNextTick[iClient] = flNow + PAINIS_CORPSE_TICK;

	if (g_bPainisCorpseActive[iClient] && (!IsPlayerAlive(iClient) || !BodyEat_IsRageWindow(boss)))
		Painis_EndCorpseEffects(boss);

	Painis_BurnTick(boss);

	if (g_bPainisCorpseActive[iClient])
	{
		Painis_UpdateCorpseEffects(boss);
		Painis_SapperTick(boss);
	}
}

public void PainisCupcake_OnDeath(SaxtonHaleBase boss, Event event)
{
	Painis_EndCorpseEffects(boss);
}

public void PainisCupcake_Destroy(SaxtonHaleBase boss)
{
	Painis_EndCorpseEffects(boss, false);
}

static void Painis_ResetCorpseState(int iClient)
{
	for (int i = 0; i < sizeof(g_iPainisCorpseStacks[]); i++)
		g_iPainisCorpseStacks[iClient][i] = 0;

	g_bPainisCorpseActive[iClient] = false;
	g_flPainisCorpseNextTick[iClient] = 0.0;
	g_flPainisSpeedApplied[iClient] = 1.0;
	g_flPainisRangeApplied[iClient] = 1.0;
	g_iPainisRangeWeapon[iClient] = INVALID_ENT_REFERENCE;
	g_flPainisPyroNextPulse[iClient] = 0.0;

	for (int iVictim = 1; iVictim <= MaxClients; iVictim++)
	{
		if (g_iPainisBurnBoss[iVictim] == iClient)
		{
			g_iPainisBurnBoss[iVictim] = 0;
			g_flPainisBurnEnd[iVictim] = 0.0;
		}
	}
}

static void Painis_EndCorpseEffects(SaxtonHaleBase boss, bool bRevertBoss = true)
{
	int iClient = boss.iClient;
	for (int i = 0; i < sizeof(g_iPainisCorpseStacks[]); i++)
		g_iPainisCorpseStacks[iClient][i] = 0;

	g_bPainisCorpseActive[iClient] = false;

	if (bRevertBoss)
		Painis_UpdateCorpseEffects(boss);

	for (int iBuilding = MaxClients + 1; iBuilding < PAINIS_MAX_EDICTS; iBuilding++)
	{
		if (g_iPainisSapBoss[iBuilding] == iClient)
			Painis_UnsapBuilding(iBuilding, true);
	}
}

static void Painis_UpdateCorpseEffects(SaxtonHaleBase boss)
{
	int iClient = boss.iClient;
	float flMult = Painis_GetCorpseMultiplier(boss);

	float flSpeed = 1.0 + PAINIS_CORPSE_SCOUT_SPEED * float(Painis_GetStacks(iClient, TFClass_Scout)) * flMult;
	if (flSpeed != g_flPainisSpeedApplied[iClient])
	{
		boss.flSpeed = boss.flSpeed / g_flPainisSpeedApplied[iClient] * flSpeed;
		g_flPainisSpeedApplied[iClient] = flSpeed;
	}

	int iMelee = TF2_GetItemInSlot(iClient, WeaponSlot_Melee);
	if (iMelee <= MaxClients || EntRefToEntIndex(g_iPainisRangeWeapon[iClient]) != iMelee)
	{
		g_iPainisRangeWeapon[iClient] = (iMelee > MaxClients) ? EntIndexToEntRef(iMelee) : INVALID_ENT_REFERENCE;
		g_flPainisRangeApplied[iClient] = 1.0;
	}

	float flRange = (PAINIS_MELEE_BASE_RANGE + PAINIS_CORPSE_SNIPER_RANGE * float(Painis_GetStacks(iClient, TFClass_Sniper)) * flMult) / PAINIS_MELEE_BASE_RANGE;
	if (iMelee > MaxClients && flRange != g_flPainisRangeApplied[iClient])
	{
		float flCurrent = 1.0;
		Address pAttrib = TF2Attrib_GetByDefIndex(iMelee, PAINIS_ATTRIB_MELEE_RANGE);
		if (pAttrib != Address_Null)
			flCurrent = TF2Attrib_GetValue(pAttrib);

		TF2Attrib_SetByDefIndex(iMelee, PAINIS_ATTRIB_MELEE_RANGE, flCurrent / g_flPainisRangeApplied[iClient] * flRange);
		TF2Attrib_ClearCache(iMelee);
		g_flPainisRangeApplied[iClient] = flRange;
	}
}

static void Painis_BurnTick(SaxtonHaleBase boss)
{
	int iClient = boss.iClient;
	float flNow = GetGameTime();

	for (int iVictim = 1; iVictim <= MaxClients; iVictim++)
	{
		if (!IsClientInGame(iVictim) || g_iPainisBurnBoss[iVictim] != iClient || flNow < g_flPainisBurnEnd[iVictim])
			continue;

		if (IsPlayerAlive(iVictim) && TF2_IsPlayerInCondition(iVictim, TFCond_OnFire))
			TF2_RemoveCondition(iVictim, TFCond_OnFire);

		g_iPainisBurnBoss[iVictim] = 0;
		g_flPainisBurnEnd[iVictim] = 0.0;
	}
}

static void Painis_PyroPulse(SaxtonHaleBase boss)
{
	int iClient = boss.iClient;
	int iPyro = Painis_GetStacks(iClient, TFClass_Pyro);
	if (!g_bPainisCorpseActive[iClient] || iPyro <= 0 || !IsPlayerAlive(iClient) || !BodyEat_IsRageWindow(boss))
	{
		g_flPainisPyroNextPulse[iClient] = 0.0;
		return;
	}

	float flNow = GetGameTime();
	if (flNow < g_flPainisPyroNextPulse[iClient])
		return;

	if (g_flPainisPyroNextPulse[iClient] > 0.0 && flNow - g_flPainisPyroNextPulse[iClient] < PAINIS_CORPSE_PYRO_PULSE)
		g_flPainisPyroNextPulse[iClient] += PAINIS_CORPSE_PYRO_PULSE;
	else
		g_flPainisPyroNextPulse[iClient] = flNow + PAINIS_CORPSE_PYRO_PULSE;

	char sParticle[64];
	strcopy(sParticle, sizeof(sParticle), PAINIS_RING_PARTICLE);
	float vecFeet[3];
	GetClientAbsOrigin(iClient, vecFeet);
	CreateTimer(2.0, Timer_EntityCleanup, TF2_SpawnParticle(sParticle, vecFeet, NULL_VECTOR, true, iClient));

	float vecBoss[3];
	Painis_GetEntityCenter(iClient, vecBoss);
	float flDamage = PAINIS_CORPSE_PYRO_BURN * float(iPyro) * Painis_GetCorpseMultiplier(boss);
	int iTeam = GetClientTeam(iClient);

	for (int iVictim = 1; iVictim <= MaxClients; iVictim++)
	{
		if (!IsClientInGame(iVictim) || !IsPlayerAlive(iVictim) || GetClientTeam(iVictim) <= 1 || GetClientTeam(iVictim) == iTeam)
			continue;

		if (TF2_IsUbercharged(iVictim))
			continue;

		if (Painis_GetBoxDistance(iVictim, vecBoss) > PAINIS_CORPSE_PYRO_RADIUS || !Painis_IsInSight(vecBoss, iVictim))
			continue;

		g_iPainisBurnBoss[iVictim] = iClient;
		g_flPainisBurnEnd[iVictim] = flNow + PAINIS_CORPSE_PYRO_AFTERBURN;
		g_flPainisBurnDamage[iVictim] = flDamage;
		g_flPainisRingLastHit[iVictim] = flNow;
		TF2_IgnitePlayer(iVictim, iClient, PAINIS_CORPSE_PYRO_AFTERBURN);
		SDKHooks_TakeDamage(iVictim, iClient, iClient, flDamage, DMG_BURN|DMG_PREVENT_PHYSICS_FORCE, -1, NULL_VECTOR, vecBoss, false);
	}
}

static void Painis_SapperTick(SaxtonHaleBase boss)
{
	int iClient = boss.iClient;

	for (int iBuilding = MaxClients + 1; iBuilding < PAINIS_MAX_EDICTS; iBuilding++)
	{
		if (g_iPainisSapBoss[iBuilding] != iClient)
			continue;

		if (EntRefToEntIndex(g_iPainisSapRef[iBuilding]) != iBuilding || GetEntProp(iBuilding, Prop_Send, "m_bCarried"))
		{
			Painis_UnsapBuilding(iBuilding, false);
			continue;
		}

		SetEntProp(iBuilding, Prop_Send, "m_bDisabled", true);
		SDKHooks_TakeDamage(iBuilding, iClient, iClient, PAINIS_CORPSE_SAPPER_DPS * PAINIS_CORPSE_TICK, DMG_GENERIC, -1, NULL_VECTOR, NULL_VECTOR, false);
	}

	int iSpy = Painis_GetStacks(iClient, TFClass_Spy);
	if (iSpy <= 0 || !IsPlayerAlive(iClient))
		return;

	float flRadius = PAINIS_CORPSE_SPY_RADIUS * float(iSpy) * Painis_GetCorpseMultiplier(boss);
	float vecBoss[3];
	Painis_GetEntityCenter(iClient, vecBoss);
	int iTeam = GetClientTeam(iClient);

	for (int i = 0; i < sizeof(g_strPainisBuildingClasses); i++)
	{
		int iBuilding = INVALID_ENT_REFERENCE;
		while ((iBuilding = FindEntityByClassname(iBuilding, g_strPainisBuildingClasses[i])) > MaxClients)
		{
			if (iBuilding >= PAINIS_MAX_EDICTS)
				continue;

			if (g_iPainisSapBoss[iBuilding] != 0 && EntRefToEntIndex(g_iPainisSapRef[iBuilding]) == iBuilding)
				continue;

			if (GetEntProp(iBuilding, Prop_Send, "m_iTeamNum") == iTeam)
				continue;

			if (GetEntProp(iBuilding, Prop_Send, "m_bCarried") || GetEntProp(iBuilding, Prop_Send, "m_bPlacing"))
				continue;

			if (Painis_GetBoxDistance(iBuilding, vecBoss) > flRadius || !Painis_IsInSight(vecBoss, iBuilding))
				continue;

			Painis_SapBuilding(iClient, iBuilding);
		}
	}
}

static void Painis_SapBuilding(int iClient, int iBuilding)
{
	Painis_RemoveSapperProp(iBuilding);

	g_iPainisSapBoss[iBuilding] = iClient;
	g_iPainisSapRef[iBuilding] = EntIndexToEntRef(iBuilding);
	SetEntProp(iBuilding, Prop_Send, "m_bDisabled", true);

	int iProp = CreateEntityByName("prop_dynamic_override");
	if (iProp > MaxClients)
	{
		DispatchKeyValue(iProp, "model", PAINIS_SAPPER_MODEL);
		DispatchKeyValue(iProp, "solid", "0");
		DispatchSpawn(iProp);

		float vecPos[3], vecAng[3];
		GetEntPropVector(iBuilding, Prop_Data, "m_vecAbsOrigin", vecPos);
		GetEntPropVector(iBuilding, Prop_Data, "m_angAbsRotation", vecAng);
		TeleportEntity(iProp, vecPos, vecAng, NULL_VECTOR);

		SetVariantString("!activator");
		AcceptEntityInput(iProp, "SetParent", iBuilding);
		SetVariantString("build_point_0");
		AcceptEntityInput(iProp, "SetParentAttachment", iProp);

		g_iPainisSapProp[iBuilding] = EntIndexToEntRef(iProp);
	}

	EmitSoundToAll(PAINIS_SAPPER_PLANT_SOUND, iBuilding);
	EmitSoundToAll(PAINIS_SAPPER_LOOP_SOUND, iBuilding, SNDCHAN_STATIC);
}

static void Painis_UnsapBuilding(int iBuilding, bool bSound)
{
	Painis_RemoveSapperProp(iBuilding);
	g_iPainisSapBoss[iBuilding] = 0;

	if (EntRefToEntIndex(g_iPainisSapRef[iBuilding]) == iBuilding)
	{
		SetEntProp(iBuilding, Prop_Send, "m_bDisabled", false);
		StopSound(iBuilding, SNDCHAN_STATIC, PAINIS_SAPPER_LOOP_SOUND);
		if (bSound)
			EmitSoundToAll(PAINIS_SAPPER_REMOVED_SOUND, iBuilding);
	}

	g_iPainisSapRef[iBuilding] = INVALID_ENT_REFERENCE;
}

static void Painis_RemoveSapperProp(int iBuilding)
{
	int iProp = EntRefToEntIndex(g_iPainisSapProp[iBuilding]);
	if (iProp > MaxClients)
		RemoveEntity(iProp);

	g_iPainisSapProp[iBuilding] = INVALID_ENT_REFERENCE;
}

static void Painis_QueueExplosion(SaxtonHaleBase boss, int iTarget, const float vecHit[3])
{
	int iSoldier = Painis_GetStacks(boss.iClient, TFClass_Soldier);
	if (iSoldier <= 0)
		return;

	float vecPos[3];
	vecPos = vecHit;
	if (GetVectorLength(vecPos) == 0.0)
		Painis_GetEntityCenter(iTarget, vecPos);

	float flDamage = PAINIS_CORPSE_SOLDIER_DAMAGE * float(iSoldier) * Painis_GetCorpseMultiplier(boss);
	float flRadius = PAINIS_CORPSE_SOLDIER_RADIUS + PAINIS_CORPSE_SOLDIER_RADIUS_STACK * float(iSoldier - 1);
	if (boss.bSuperRage)
		flRadius += PAINIS_CORPSE_SOLDIER_RADIUS_SUPER;

	DataPack hPack = new DataPack();
	hPack.WriteCell(GetClientUserId(boss.iClient));
	hPack.WriteCell(EntIndexToEntRef(iTarget));
	hPack.WriteFloat(vecPos[0]);
	hPack.WriteFloat(vecPos[1]);
	hPack.WriteFloat(vecPos[2]);
	hPack.WriteFloat(flDamage);
	hPack.WriteFloat(flRadius);
	RequestFrame(Painis_Explode, hPack);
}

static void Painis_Explode(DataPack hPack)
{
	hPack.Reset();
	int iClient = GetClientOfUserId(hPack.ReadCell());
	int iStruck = EntRefToEntIndex(hPack.ReadCell());
	float vecPos[3];
	vecPos[0] = hPack.ReadFloat();
	vecPos[1] = hPack.ReadFloat();
	vecPos[2] = hPack.ReadFloat();
	float flDamage = hPack.ReadFloat();
	float flRadius = hPack.ReadFloat();
	delete hPack;

	if (iClient <= 0 || !IsClientInGame(iClient) || !IsPlayerAlive(iClient))
		return;

	char sParticle[64];
	strcopy(sParticle, sizeof(sParticle), PAINIS_EXPLOSION_PARTICLE);
	CreateTimer(3.0, Timer_EntityCleanup, TF2_SpawnParticle(sParticle, vecPos));
	EmitAmbientSound(PAINIS_EXPLOSION_SOUND, vecPos);

	int iTeam = GetClientTeam(iClient);

	for (int iVictim = 1; iVictim <= MaxClients; iVictim++)
	{
		if (!IsClientInGame(iVictim) || !IsPlayerAlive(iVictim) || GetClientTeam(iVictim) <= 1 || GetClientTeam(iVictim) == iTeam)
			continue;

		if (iVictim != iStruck && (Painis_GetBoxDistance(iVictim, vecPos) > flRadius || !Painis_IsInSight(vecPos, iVictim)))
			continue;

		SDKHooks_TakeDamage(iVictim, iClient, iClient, flDamage, DMG_BLAST, -1, NULL_VECTOR, vecPos, false);
	}

	for (int i = 0; i < sizeof(g_strPainisBuildingClasses); i++)
	{
		int iBuilding = INVALID_ENT_REFERENCE;
		while ((iBuilding = FindEntityByClassname(iBuilding, g_strPainisBuildingClasses[i])) > MaxClients)
		{
			if (GetEntProp(iBuilding, Prop_Send, "m_iTeamNum") == iTeam)
				continue;

			if (GetEntProp(iBuilding, Prop_Send, "m_bCarried") || GetEntProp(iBuilding, Prop_Send, "m_bPlacing"))
				continue;

			if (iBuilding != iStruck && (Painis_GetBoxDistance(iBuilding, vecPos) > flRadius || !Painis_IsInSight(vecPos, iBuilding)))
				continue;

			SDKHooks_TakeDamage(iBuilding, iClient, iClient, flDamage, DMG_BLAST, -1, NULL_VECTOR, vecPos, false);
		}
	}
}

static bool Painis_IsMeleeHit(SaxtonHaleBase boss, int iInflictor, int iWeapon, int iDamageCustom)
{
	if (iInflictor != boss.iClient || iWeapon <= MaxClients)
		return false;

	if (iDamageCustom == TF_CUSTOM_BOOTS_STOMP || iDamageCustom == TF_CUSTOM_BURNING)
		return false;

	return iWeapon == TF2_GetItemInSlot(boss.iClient, WeaponSlot_Melee);
}

static int Painis_GetStacks(int iClient, TFClassType nClass)
{
	return g_iPainisCorpseStacks[iClient][view_as<int>(nClass)];
}

static float Painis_GetCorpseMultiplier(SaxtonHaleBase boss)
{
	return boss.bSuperRage ? 2.0 : 1.0;
}

static void Painis_GetEntityCenter(int iEntity, float vecCenter[3])
{
	float vecMins[3], vecMaxs[3];
	GetEntPropVector(iEntity, Prop_Data, "m_vecAbsOrigin", vecCenter);
	GetEntPropVector(iEntity, Prop_Send, "m_vecMins", vecMins);
	GetEntPropVector(iEntity, Prop_Send, "m_vecMaxs", vecMaxs);
	for (int i = 0; i < 3; i++)
		vecCenter[i] += (vecMins[i] + vecMaxs[i]) * 0.5;
}

static float Painis_GetBoxDistance(int iEntity, const float vecPos[3])
{
	float vecOrigin[3], vecMins[3], vecMaxs[3];
	GetEntPropVector(iEntity, Prop_Data, "m_vecAbsOrigin", vecOrigin);
	GetEntPropVector(iEntity, Prop_Send, "m_vecMins", vecMins);
	GetEntPropVector(iEntity, Prop_Send, "m_vecMaxs", vecMaxs);

	float flDistSq = 0.0;
	for (int i = 0; i < 3; i++)
	{
		float flDelta = 0.0;
		if (vecPos[i] < vecOrigin[i] + vecMins[i])
			flDelta = vecOrigin[i] + vecMins[i] - vecPos[i];
		else if (vecPos[i] > vecOrigin[i] + vecMaxs[i])
			flDelta = vecPos[i] - vecOrigin[i] - vecMaxs[i];

		flDistSq += flDelta * flDelta;
	}

	return SquareRoot(flDistSq);
}

static bool Painis_IsInSight(const float vecFrom[3], int iEntity)
{
	float vecTo[3];
	Painis_GetEntityCenter(iEntity, vecTo);
	TR_TraceRayFilter(vecFrom, vecTo, MASK_SOLID, RayType_EndPoint, Painis_TraceGeometry);
	return !TR_DidHit();
}

static bool Painis_TraceGeometry(int iEntity, int iMask, any data)
{
	if (iEntity == 0)
		return true;

	if (iEntity <= MaxClients)
		return false;

	char sClassname[32];
	GetEntityClassname(iEntity, sClassname, sizeof(sClassname));
	if (StrEqual(sClassname, "prop_ragdoll"))
		return false;

	return strncmp(sClassname, "func_", 5) == 0 || strncmp(sClassname, "prop_", 5) == 0;
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

	PrecacheParticleSystem(PAINIS_RING_PARTICLE);
	PrecacheParticleSystem(PAINIS_EXPLOSION_PARTICLE);
	PrecacheModel(PAINIS_SAPPER_MODEL);
	PrecacheSound(PAINIS_EXPLOSION_SOUND);
	PrecacheSound(PAINIS_SAPPER_PLANT_SOUND);
	PrecacheSound(PAINIS_SAPPER_LOOP_SOUND);
	PrecacheSound(PAINIS_SAPPER_REMOVED_SOUND);
}

