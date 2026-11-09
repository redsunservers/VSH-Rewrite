#define EFFECT_CLASSNAME		"info_particle_system"	// Any cheap ent that allows SetTransmit

#define BOSS_RAGE_COOLDOWN_DEFAULT	20.0
#define BOSS_ISOLATION_LINK_RADIUS	300.0
#define BOSS_ISOLATION_GROUP_MIN	4
#define BOSS_ISOLATION_DISTANCE		2000.0
#define BOSS_ISOLATION_INTERVAL		0.2
#define BOSS_STOMP_DAMAGE_PER_FALL_SPEED	0.3182
#define BOSS_ISOLATION_MARK_DURATION	0.5
#define BOSS_STUN_SELF_WINDOW	0.2

static char g_sClientBossRageMusic[MAXPLAYERS][255];

static float g_flClientBossRageMusicVolume[MAXPLAYERS];

static Handle g_hClientBossModelTimer[MAXPLAYERS];
static Handle g_hClientBossRageMusicTime[MAXPLAYERS];

static bool g_bClientBossRageModelActive[MAXPLAYERS];

static bool g_bClientBossRageMusicLoopActive[MAXPLAYERS];

static bool g_bClientBossIsolated[MAXPLAYERS];
static float g_flClientBossIsolationNextCheck[MAXPLAYERS];
static float g_flClientBossIsolationMarkEnd[MAXPLAYERS];
static bool g_bClientBossIsolationWarned[MAXPLAYERS];
static bool g_bClientBossIsolationHighlight[MAXPLAYERS][MAXPLAYERS];
static int g_iClientIsolationGlow[MAXPLAYERS];

static float g_flClientBossFallSpeed[MAXPLAYERS];

static float g_flClientBossRageCooldownCleared[MAXPLAYERS];
static float g_flClientBossSelfStunTime[MAXPLAYERS];

public void SaxtonHaleBoss_Create(SaxtonHaleBase boss)
{
	boss.bSuperRage = false;
	
	boss.SetPropFloat("SaxtonHaleBoss", "RageCooldown", BOSS_RAGE_COOLDOWN_DEFAULT);
	
	g_bClientBossIsolated[boss.iClient] = false;
	g_flClientBossIsolationNextCheck[boss.iClient] = 0.0;
	g_flClientBossIsolationMarkEnd[boss.iClient] = 0.0;
	g_bClientBossIsolationWarned[boss.iClient] = false;
	BaseBoss_ClearIsolationHighlight(boss.iClient);
	g_flClientBossFallSpeed[boss.iClient] = 0.0;
	g_flClientBossRageCooldownCleared[boss.iClient] = -1.0;
	g_flClientBossSelfStunTime[boss.iClient] = 0.0;

	boss.iBaseHealth = 0;
	boss.iHealthPerPlayer = 0;
	boss.iMaxHealth = 0;
	boss.flHealthExponential = 1.0;
	boss.flHealthMultiplier = 1.0;
	boss.bHealthPerPlayerAlive = false;

	boss.flSpeed = 370.0;
	boss.flSpeedMult = 0.07;
	boss.flMaxRagePercentage = 2.0;
	boss.iRageDamage = 0;
	boss.flRageLastTime = 0.0;	//this probably should've been a boolean. but whatever
	boss.flEnvDamageCap = 200.0;
	boss.flGlowTime = 0.0;
	
	boss.bMinion = false;
	boss.bModel = true;
	boss.nClass = TFClass_Unknown;

	g_sClientBossRageMusic[boss.iClient] = "";
	g_flClientBossRageMusicVolume[boss.iClient] = 0.0;
	g_hClientBossRageMusicTime[boss.iClient] = null;

	g_bClientBossRageModelActive[boss.iClient] = false;
	g_bClientBossRageMusicLoopActive[boss.iClient] = false;
	
	if (g_hClientBossModelTimer[boss.iClient] != null)
		delete g_hClientBossModelTimer[boss.iClient];
	
	if (boss.bModel)
		g_hClientBossModelTimer[boss.iClient] = CreateTimer(0.2, Timer_ApplyBossModel, boss.iClient, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	
	if (boss.nClass != TFClass_Unknown)
		TF2_SetPlayerClass(boss.iClient, boss.nClass);
}

public int SaxtonHaleBoss_CalculateMaxHealth(SaxtonHaleBase boss)
{
	float flHealth;
	if (boss.bHealthPerPlayerAlive)
		flHealth = float(boss.iHealthPerPlayer * SaxtonHale_GetAliveAttackPlayers());
	else
		flHealth = float(boss.iHealthPerPlayer * g_iTotalAttackCount);
	
	flHealth += float(boss.iBaseHealth);
	flHealth = Pow(flHealth, boss.flHealthExponential);
	return RoundToNearest(flHealth * boss.flHealthMultiplier);
}

public void SaxtonHaleBoss_OnThink(SaxtonHaleBase boss)
{
	if (IsFakeClient(boss.iClient) && boss.iRageDamage >= boss.iMaxRageDamage && BaseBoss_GetRageCooldownLeft(boss) <= 0.0)
		boss.CallFunction("OnRage");
	
	BaseBoss_UpdateIsolation(boss);
	
	bool bGlow = (boss.flGlowTime == -1.0 || boss.flGlowTime >= GetGameTime() || g_bClientBossIsolated[boss.iClient]);
	SetEntProp(boss.iClient, Prop_Send, "m_bGlowEnabled", bGlow);
	
	if (!(GetEntityFlags(boss.iClient) & FL_ONGROUND))
	{
		float vecFallVel[3];
		GetEntPropVector(boss.iClient, Prop_Data, "m_vecVelocity", vecFallVel);
		g_flClientBossFallSpeed[boss.iClient] = (vecFallVel[2] < 0.0) ? -vecFallVel[2] : 0.0;
	}
	
	if ((GetEntityFlags(boss.iClient) & FL_ONGROUND) && TF2_IsPlayerInCondition(boss.iClient, TFCond_BlastJumping))
		TF2_RemoveCondition(boss.iClient, TFCond_BlastJumping);
	
	//Dont modify his speed during setup time or when taunting
	if (boss.flSpeed >= 0.0 && GameRules_GetRoundState() != RoundState_Preround && !TF2_IsPlayerInCondition(boss.iClient, TFCond_Taunting))
	{
		float flMaxSpeed = boss.flSpeed + (boss.flSpeed*boss.flSpeedMult*(1.0-(float(boss.iHealth)/float(boss.iMaxHealth))));
		SetEntPropFloat(boss.iClient, Prop_Data, "m_flMaxspeed", flMaxSpeed);
	}
	
	if (g_bRoundStarted && IsPlayerAlive(boss.iClient) && boss.iMaxRageDamage != -1)
	{
		float flHUD[2];
		flHUD[0] = -1.0;
		flHUD[1] = 0.83;

		char sMessage[255];
		int iColor[4];

		//Replace rage meter when needed, i.e type "press e to cancel rage"
		char sRageHudOverride[128];
		sRageHudOverride[0] = '\0';	//Function system passes the buffer content in, start it empty
		boss.CallFunction("GetRageHudInfo", sRageHudOverride, sizeof(sRageHudOverride));

		if (sRageHudOverride[0] != '\0')
		{
			strcopy(sMessage, sizeof(sMessage), sRageHudOverride);
			iColor[0] = 255;
			iColor[1] = 255;
			iColor[2] = 0;
			iColor[3] = 255;
		}
		else
		{
			float flRage = (float(boss.iRageDamage) / float(boss.iMaxRageDamage)) * 100.0;
			float flRageCooldown = BaseBoss_GetRageCooldownLeft(boss);

			if (flRageCooldown > 0.0)
			{
				Format(sMessage, sizeof(sMessage), "Rage: %d%%%% (%ds)", RoundToFloor(flRage), RoundToCeil(flRageCooldown));
			}
			else
			{
				Format(sMessage, sizeof(sMessage), "Rage: %d%%%%%s", RoundToFloor(flRage), (flRage >= 100.0) ? " (Ready)" : "");
			}

			if (flRageCooldown > 0.0)
			{
				iColor[0] = 105;
				iColor[1] = 105;
				iColor[2] = 105;
			}
			else if (flRage >= 200.0 || flRage >= boss.flMaxRagePercentage * 100.0)
			{
				//200% rage or max, bright yellow
				iColor[0] = 255;
				iColor[1] = 255;
				iColor[2] = 0;
			}
			else if (flRage < 100.0)
			{
				//0% to 99%: white to red
				iColor[0] = 255;
				iColor[1] = RoundToNearest((100.0-flRage) * (255.0/100.0));
				iColor[2] = RoundToNearest((100.0-flRage) * (255.0/100.0));
			}
			else
			{
				//100% to 199%: green to red
				iColor[0] = RoundToNearest((flRage-100.0) * (255.0/100.0));
				iColor[1] = RoundToNearest((200.0-flRage) * (255.0/100.0));
				iColor[2] = 0;
			}

			iColor[3] = 255;
		}

		Hud_Display(boss.iClient, CHANNEL_RAGE, sMessage, flHUD, 0.2, iColor);
	}
}

public void SaxtonHaleBoss_OnSpawn(SaxtonHaleBase boss)
{
	if (boss.bModel)
	{
		ApplyBossModel(boss.iClient);
		
		//Remove zombie skin cosmetic
		SetEntProp(boss.iClient, Prop_Send, "m_bForcedSkin", 0);
		SetEntProp(boss.iClient, Prop_Send, "m_nForcedSkin", 0);
		SetEntProp(boss.iClient, Prop_Send, "m_iPlayerSkinOverride", 0);
	}
	
	if (boss.bMinion && GameRules_GetRoundState() != RoundState_Preround)
		EmitSoundToClient(boss.iClient, SOUND_ALERT);
	
	if (!boss.bMinion)
	{
		//Give every boss ground pound by default
		if (!boss.HasClass("GroundPound"))
			boss.CreateClass("GroundPound");
		
		//Give every bosses able to scare scout by default
		if (!boss.HasClass("ScareRage")) //If boss don't have scare rage ability, give him one
			boss.CreateClass("ScareRage");
		
		if (boss.StartFunction("ScareRage", "SetClass"))
		{
			Call_PushCell(TFClass_Scout);	//Class to set
			Call_PushFloat(400.0);	//Radius, halfed of hale
			Call_PushFloat(5.0);	//Duration (using default)
			Call_PushCell(TF_STUNFLAG_SLOWDOWN | TF_STUNFLAG_GHOSTEFFECT);	//Stunflags
			Call_PushFloat(0.25);	//Slowdown
			Call_Finish();
		}
	}
	
	int iHealth = boss.CallFunction("CalculateMaxHealth");
	if (iHealth > 0)
	{
		boss.iMaxHealth = iHealth;
		boss.iHealth = iHealth;
	}
	
	ClearBossEffects(boss.iClient);
	RequestFrame(ApplyBossEffects, boss.iClient);
	
	boss.CallFunction("UpdateHudInfo", 0.0, 0.01);	//Update after frame when boss have all weapons equipped
}

public Action SaxtonHaleBoss_OnGiveNamedItem(SaxtonHaleBase boss, const char[] sClassname, int iIndex)
{
	//If dont modify player model, allow keep cosmetics
	if (!boss.bModel)
	{
		int iSlot = TF2_GetItemSlot(iIndex, TF2_GetPlayerClass(boss.iClient));
		if (iSlot > WeaponSlot_BuilderEngie)
			return Plugin_Continue;
	}
	
	//Otherwise block everything by default
	return Plugin_Handled;
}

public int SaxtonHaleBoss_CreateWeapon(SaxtonHaleBase boss, int iIndex, char[] sClassname, int iLevel, TFQuality iQuality, char[] sAttrib)
{
	return TF2_CreateAndEquipWeapon(boss.iClient, iIndex, sClassname, iLevel, iQuality, sAttrib);
}

public void SaxtonHaleBoss_AddRage(SaxtonHaleBase boss, int iAmount)
{
	int iRageRequirement = boss.iMaxRageDamage;
	if (iRageRequirement < 0)	//No rage (-1)
		return;
	
	//Add/Remove rage
	int iRage = boss.iRageDamage + iAmount;
	
	int iMaxRage = RoundToNearest(float(iRageRequirement) * boss.flMaxRagePercentage);
	if (iRage > iMaxRage) iRage = iMaxRage;
	if (iRage < 0) iRage = 0;
	
	boss.iRageDamage = iRage;
}

public Action SaxtonHaleBoss_OnBuild(SaxtonHaleBase boss, TFObjectType nType, TFObjectMode nMode)
{
	return Plugin_Handled;
}

public void SaxtonHaleBoss_OnRage(SaxtonHaleBase boss)
{
	boss.flRageLastTime = GetGameTime();
	boss.bSuperRage = false;
	
	if (boss.iRageDamage >= boss.iMaxRageDamage * 2)
	{
		//Super rage by 200% or higher
		boss.bSuperRage = true;
		boss.iRageDamage -= boss.iMaxRageDamage * 2;
	}
	else if (boss.iRageDamage >= boss.iMaxRageDamage * boss.flMaxRagePercentage)
	{
		//Super rage by max rage percentage, but less than 200%
		boss.bSuperRage = true;
		boss.iRageDamage = 0;
	}
	else
	{
		//Normal rage
		boss.iRageDamage -= boss.iMaxRageDamage;
	}
	
	if (TF2_IsPlayerInCondition(boss.iClient, TFCond_Dazed))
		TF2_RemoveCondition(boss.iClient, TFCond_Dazed); //Allow hale to escape permastun situations when using rage

	char sSound[255];
	float flDuration = 0.0;
	boss.CallFunction("GetRageMusicInfo", sSound, sizeof(sSound), flDuration);

	//check if the boss is using boss music.
	bool bRageMusicLoop = boss.CallFunction("GetRageMusicLoop");
	if (bRageMusicLoop && flDuration > 0.0 && !StrEmpty(sSound) && !g_bClientBossRageMusicLoopActive[boss.iClient])
	{
		g_bClientBossRageMusicLoopActive[boss.iClient] = true;

		//stop music for everyone and replace with rage music
		char sRageMusic[PLATFORM_MAX_PATH];
		Format(sRageMusic, sizeof(sRageMusic), "#%s", sSound);

		if (!StrEmpty(g_sBossMusic))
		{
			for (int iClient = 1; iClient <= MaxClients; iClient++)
			{
				if (IsClientInGame(iClient))
				{
					StopSound(iClient, SNDCHAN_STATIC, g_sBossMusic);
					if (Preferences_Get(iClient, VSHPreferences_Music))
						EmitSoundToClient(iClient, sRageMusic, _, SNDCHAN_STATIC, SNDLEVEL_NONE);
				}
			}
		}

		strcopy(g_sBossMusic, sizeof(g_sBossMusic), sRageMusic);

		if (g_hTimerBossMusic != null)
			delete g_hTimerBossMusic;
		//repeat boss music, so it loops correctly.
		g_hTimerBossMusic = CreateTimer(flDuration, Timer_Music, boss, TIMER_REPEAT);
	}
	else if (!bRageMusicLoop && flDuration > 0.0 && !StrEmpty(sSound))
	{
		StopSound(boss.iClient, SNDCHAN_AUTO, sSound);
		EmitSoundToAll(sSound, boss.iClient, SNDCHAN_AUTO, SNDLEVEL_SCREAMING);

		g_hClientBossRageMusicTime[boss.iClient] = CreateTimer((boss.bSuperRage) ? flDuration : (flDuration/2.0), Timer_BossRageMusic, boss);
		strcopy(g_sClientBossRageMusic[boss.iClient], sizeof(g_sClientBossRageMusic[]), sSound);
		g_flClientBossRageMusicVolume[boss.iClient] = 1.0;
	}

	//swap to rage model if defined, then re-apply it constantly just like normal hale model
	g_bClientBossRageModelActive[boss.iClient] = true;

	boss.CallFunction("GetSound", sSound, sizeof(sSound), VSHSound_Rage);
	if (!StrEmpty(sSound))
		EmitSoundToAll(sSound, boss.iClient, SNDCHAN_VOICE, SNDLEVEL_SCREAMING);
}

public Action SaxtonHaleBoss_OnAttackCritical(SaxtonHaleBase boss, int iWeapon, bool &bResult)
{
	//Disable random crit for bosses
	if (!TF2_IsForceCrit(boss.iClient))
	{
		bResult = false;
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}

public Action SaxtonHaleBoss_OnSoundPlayed(SaxtonHaleBase boss, int clients[MAXPLAYERS], int &numClients, char sample[PLATFORM_MAX_PATH], int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
	//Don't play pain sounds
	if (StrContains(sample, "PainSevere", false) != -1)
		return Plugin_Handled;
	
	return Plugin_Continue;
}

public Action SaxtonHaleBoss_OnAttackDamage(SaxtonHaleBase boss, int victim, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if (damagecustom == TF_CUSTOM_BOOTS_STOMP)
	{
		//Because we made fall damage deal near zero, hard set stomp damage to insta kill
		float flFallSpeed = g_flClientBossFallSpeed[boss.iClient];
		float flFallVelocity = GetEntPropFloat(boss.iClient, Prop_Send, "m_flFallVelocity");
		if (flFallVelocity > flFallSpeed)
			flFallSpeed = flFallVelocity;
		
		damage = flFallSpeed * BOSS_STOMP_DAMAGE_PER_FALL_SPEED;
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}

float BaseBoss_GetRageCooldownLeft(SaxtonHaleBase boss)
{
	if (boss.flRageLastTime <= 0.0)
		return 0.0;
	
	if (g_flClientBossRageCooldownCleared[boss.iClient] == boss.flRageLastTime)
		return 0.0;
	
	float flLeft = boss.flRageLastTime + boss.GetPropFloat("SaxtonHaleBoss", "RageCooldown") - GetGameTime();
	return (flLeft > 0.0) ? flLeft : 0.0;
}

public void SaxtonHaleBoss_OnConditionAdded(SaxtonHaleBase boss, TFCond nCond)
{
	if (nCond != TFCond_Dazed || boss.flRageLastTime <= 0.0)
		return;
	
	if (GetGameTime() - g_flClientBossSelfStunTime[boss.iClient] <= BOSS_STUN_SELF_WINDOW)
		return;
	
	g_flClientBossRageCooldownCleared[boss.iClient] = boss.flRageLastTime;
}

void BaseBoss_SelfStun(int iClient, float flDuration, float flSlowdown, int iStunFlags, int iAttacker = 0)
{
	g_flClientBossSelfStunTime[iClient] = GetGameTime();
	TF2_StunPlayer(iClient, flDuration, flSlowdown, iStunFlags, iAttacker);
}

static void BaseBoss_UpdateIsolation(SaxtonHaleBase boss)
{
	int iClient = boss.iClient;
	float flTime = GetGameTime();
	
	if (boss.bMinion || !g_bRoundStarted || !IsPlayerAlive(iClient))
	{
		g_bClientBossIsolated[iClient] = false;
		BaseBoss_ClearIsolationHighlight(iClient);
		return;
	}
	
	if (flTime >= g_flClientBossIsolationNextCheck[iClient])
	{
		g_flClientBossIsolationNextCheck[iClient] = flTime + BOSS_ISOLATION_INTERVAL;
		bool bClosestGroup[MAXPLAYERS];
		g_bClientBossIsolated[iClient] = BaseBoss_IsIsolated(iClient, bClosestGroup);
		for (int iAttacker = 1; iAttacker <= MaxClients; iAttacker++)
		{
			g_bClientBossIsolationHighlight[iClient][iAttacker] = (g_bClientBossIsolated[iClient] && bClosestGroup[iAttacker]);
			if (g_bClientBossIsolationHighlight[iClient][iAttacker])
				BaseBoss_UpdateIsolationGlow(iAttacker);
		}
		
		if (g_bClientBossIsolated[iClient] && !g_bClientBossIsolationWarned[iClient])
		{
			g_bClientBossIsolationWarned[iClient] = true;
			PrintToChat(iClient, "%s%s You become marked for death and outlined if you are too far away from where most of red team currently is.", TEXT_TAG, TEXT_ERROR);
		}
	}
	
	if (!g_bClientBossIsolated[iClient])
		return;
	
	bool bMarked = TF2_IsPlayerInCondition(iClient, TFCond_MarkedForDeath);
	bool bOurMark = (g_flClientBossIsolationMarkEnd[iClient] > flTime);
	if (!bMarked || (bOurMark && g_flClientBossIsolationMarkEnd[iClient] - flTime < BOSS_ISOLATION_MARK_DURATION / 2.0))
	{
		TF2_AddCondition(iClient, TFCond_MarkedForDeath, BOSS_ISOLATION_MARK_DURATION);
		g_flClientBossIsolationMarkEnd[iClient] = flTime + BOSS_ISOLATION_MARK_DURATION;
	}
}

static bool BaseBoss_IsIsolated(int iBoss, bool bClosestGroup[MAXPLAYERS])
{
	int iCount = 0;
	int iClients[MAXPLAYERS];
	float vecPos[MAXPLAYERS][3];
	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		bClosestGroup[iClient] = false;
		if (SaxtonHale_IsValidAttack(iClient) && IsPlayerAlive(iClient))
		{
			GetClientAbsOrigin(iClient, vecPos[iCount]);
			iClients[iCount] = iClient;
			iCount++;
		}
	}
	
	if (iCount < BOSS_ISOLATION_GROUP_MIN)
		return false;
	
	float vecBoss[3];
	GetClientAbsOrigin(iBoss, vecBoss);
	
	float flLinkSq = BOSS_ISOLATION_LINK_RADIUS * BOSS_ISOLATION_LINK_RADIUS;
	float flFarSq = BOSS_ISOLATION_DISTANCE * BOSS_ISOLATION_DISTANCE;
	
	int iGroup[MAXPLAYERS];
	int iGroups = 0;
	int iStack[MAXPLAYERS];
	int iClosestGroup = 0;
	float flClosestGroupSq = -1.0;
	
	for (int iStart = 0; iStart < iCount; iStart++)
	{
		if (iGroup[iStart])
			continue;
		
		iGroups++;
		int iSize = 0;
		int iStackLen = 0;
		float flClosestSq = -1.0;
		
		iGroup[iStart] = iGroups;
		iStack[iStackLen] = iStart;
		iStackLen++;
		
		while (iStackLen > 0)
		{
			iStackLen--;
			int iCurrent = iStack[iStackLen];
			iSize++;
			
			float flDistSq = GetVectorDistance(vecBoss, vecPos[iCurrent], true);
			if (flClosestSq < 0.0 || flDistSq < flClosestSq)
				flClosestSq = flDistSq;
			
			for (int iOther = 0; iOther < iCount; iOther++)
			{
				if (!iGroup[iOther] && GetVectorDistance(vecPos[iCurrent], vecPos[iOther], true) <= flLinkSq)
				{
					iGroup[iOther] = iGroups;
					iStack[iStackLen] = iOther;
					iStackLen++;
				}
			}
		}
		
		if (iSize >= BOSS_ISOLATION_GROUP_MIN)
		{
			if (flClosestSq <= flFarSq)
				return false;
			
			if (flClosestGroupSq < 0.0 || flClosestSq < flClosestGroupSq)
			{
				flClosestGroupSq = flClosestSq;
				iClosestGroup = iGroups;
			}
		}
	}
	
	if (!iClosestGroup)
		return false;
	
	for (int i = 0; i < iCount; i++)
	{
		if (iGroup[i] == iClosestGroup)
			bClosestGroup[iClients[i]] = true;
	}
	
	return true;
}

static void BaseBoss_UpdateIsolationGlow(int iClient)
{
	char sModel[PLATFORM_MAX_PATH];
	GetEntPropString(iClient, Prop_Data, "m_ModelName", sModel, sizeof(sModel));
	
	if (g_iClientIsolationGlow[iClient] == 0 || !IsValidEntity(g_iClientIsolationGlow[iClient]))
	{
		g_iClientIsolationGlow[iClient] = TF2_CreateTransmitGlow(iClient, sModel, BaseBoss_IsolationGlowTransmit);
		return;
	}
	
	char sGlowModel[PLATFORM_MAX_PATH];
	GetEntPropString(g_iClientIsolationGlow[iClient], Prop_Data, "m_ModelName", sGlowModel, sizeof(sGlowModel));
	if (!StrEqual(sModel, sGlowModel))
		SetEntityModel(g_iClientIsolationGlow[iClient], sModel);
}

static void BaseBoss_ClearIsolationHighlight(int iBoss)
{
	for (int iClient = 0; iClient < MAXPLAYERS; iClient++)
		g_bClientBossIsolationHighlight[iBoss][iClient] = false;
}

public Action BaseBoss_IsolationGlowTransmit(int iEntity, int iTarget)
{
	int iClient = GetEntPropEnt(iEntity, Prop_Data, "m_hParent");
	if (iClient <= 0 || iClient > MaxClients || iTarget <= 0 || iTarget > MaxClients)
		return Plugin_Stop;
	
	if (!g_bClientBossIsolationHighlight[iTarget][iClient] || !g_bClientBossIsolated[iTarget] || !SaxtonHale_IsValidBoss(iTarget) || !IsPlayerAlive(iTarget) || !IsPlayerAlive(iClient))
		return Plugin_Stop;
	
	if (TF2_IsPlayerInCondition(iClient, TFCond_Cloaked) || TF2_IsPlayerInCondition(iClient, TFCond_Disguised) || TF2_IsPlayerInCondition(iClient, TFCond_Stealthed))
		return Plugin_Stop;
	
	return Plugin_Continue;
}

public Action SaxtonHaleBoss_OnTakeDamage(SaxtonHaleBase boss, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	Action action = Plugin_Continue;
	
	if (damagetype & DMG_FALL)
	{
		if ((attacker <= 0 || attacker > MaxClients) && inflictor == 0)
		{
			//Make fall damage deal 0.1, so boss dont take any damage but allow stomp damage hook to work 
			damage = 0.1;
			action = Plugin_Changed;
		}
	}
	else
	{
		//Only play pain sound if it not fall damage
		char sSound[255];
		boss.CallFunction("GetSound", sSound, sizeof(sSound), VSHSound_Pain);
		if (!StrEmpty(sSound))
			EmitSoundToAll(sSound, boss.iClient, SNDCHAN_VOICE, SNDLEVEL_SCREAMING);
	}

	if (GetEntityFlags(boss.iClient) & FL_ONGROUND || TF2_IsUbercharged(boss.iClient))
	{
		damagetype |= DMG_PREVENT_PHYSICS_FORCE;
		action = Plugin_Changed;
	}

	if (inflictor > MaxClients && !boss.bMinion)
	{
		char sInflictor[32];
		GetEdictClassname(inflictor, sInflictor, sizeof(sInflictor));
		if (strcmp(sInflictor, "tf_projectile_sentryrocket") == 0 || strcmp(sInflictor, "obj_sentrygun") == 0)
		{
			damagetype |= DMG_PREVENT_PHYSICS_FORCE;
			action = Plugin_Changed;
		}
	}

	if (MaxClients < attacker)
	{
		char strAttacker[32];
		GetEdictClassname(attacker, strAttacker, sizeof(strAttacker));
		if (strcmp(strAttacker, "trigger_hurt") == 0)
		{
			float flEnvDamage = damage;
			if ((damagetype & DMG_ACID)) flEnvDamage *= 3.0;

			if (flEnvDamage >= boss.flEnvDamageCap)
			{
				int iTeam = GetClientTeam(boss.iClient);
				ArrayList aSpawnPoints = new ArrayList();
				
				int iBossSpawn = INVALID_ENT_REFERENCE;
				while ((iBossSpawn = FindEntityByClassname(iBossSpawn, "info_player_teamspawn")) != INVALID_ENT_REFERENCE)
					if (GetEntProp(iBossSpawn, Prop_Send, "m_iTeamNum") == iTeam)
						aSpawnPoints.Push(iBossSpawn);
				
				if (aSpawnPoints.Length > 0)
				{
					aSpawnPoints.Sort(Sort_Random, Sort_Integer);
					float vecPos[3];
					GetEntPropVector(aSpawnPoints.Get(0), Prop_Data, "m_vecAbsOrigin", vecPos);
					float vecNoVel[3];
					TeleportEntity(boss.iClient, vecPos, NULL_VECTOR, vecNoVel);
					BaseBoss_SelfStun(boss.iClient, 2.0, 0.0, TF_STUNFLAGS_NORMALBONK, 0);
				}
				
				delete aSpawnPoints;
				damage = (damagetype & DMG_ACID) ? boss.flEnvDamageCap/3.0 : boss.flEnvDamageCap;
				action = Plugin_Changed;
			}
		}
	}

	return action;
}

public void SaxtonHaleBoss_OnPickupTouch(SaxtonHaleBase boss, int iEntity, bool &bResult)
{
	bResult = false;
}

public void SaxtonHaleBoss_UpdateHudInfo(SaxtonHaleBase boss, float flinterval, float flDuration)
{
	Hud_UpdateBossInfo(boss.iClient, flinterval, flDuration);
}

public void SaxtonHaleBoss_Destroy(SaxtonHaleBase boss)
{
	ClearBossEffects(boss.iClient);

	//Drop any cached boss HUD text (nanomachines/explosive charge/etc.) so it
	//doesn't persist if this client becomes a valid boss again next round or
	//gets team-swapped into a minion without a fresh spawn.
	Hud_ClearBossInfo(boss.iClient);

	SetVariantString("");
	AcceptEntityInput(boss.iClient, "SetCustomModel");
	TF2_RegeneratePlayer(boss.iClient);

	TF2_AddCondition(boss.iClient, TFCond_SpeedBuffAlly, 0.01);

	if (!StrEmpty(g_sClientBossRageMusic[boss.iClient]))
		StopSound(boss.iClient, SNDCHAN_AUTO, g_sClientBossRageMusic[boss.iClient]);
	g_hClientBossRageMusicTime[boss.iClient] = null;

	if (g_hClientBossModelTimer[boss.iClient] != null)
		delete g_hClientBossModelTimer[boss.iClient];
}

public Action Timer_ApplyBossModel(Handle hTimer, int iClient)
{
	if (!SaxtonHale_IsValidBoss(iClient))
	{
		g_hClientBossModelTimer[iClient] = null;
		return Plugin_Stop;
	}

	if (g_hClientBossModelTimer[iClient] != hTimer)
	{
		g_hClientBossModelTimer[iClient] = null;
		return Plugin_Stop;
	}

	//Prevents plugins like model manager to override our model
	ApplyBossModel(iClient);
	
	return Plugin_Continue;
}

public void ApplyBossModel(int iClient)
{
	SaxtonHaleBase boss = SaxtonHaleBase(iClient);
	if (!boss.bValid) return;

	char sModel[255];
	bool bTempModel = TempModel_GetActiveModel(iClient, sModel, sizeof(sModel));
	if (!bTempModel)
	{
		bool bUseRageModel = false;
		if (g_bClientBossRageModelActive[iClient])
		{
			boss.CallFunction("GetRageModel", sModel, sizeof(sModel));
			bUseRageModel = !StrEmpty(sModel);
		}

		if (!bUseRageModel)
			boss.CallFunction("GetModel", sModel, sizeof(sModel));
	}

	//Re-assert class animations just in case.
	SetEntProp(iClient, Prop_Send, "m_bUseClassAnimations", !(bTempModel && TempModel_IsSelfAnimating(iClient)));

	//Only reset the model when it actually changed. 
	char sCurrentModel[PLATFORM_MAX_PATH];
	GetEntPropString(iClient, Prop_Data, "m_ModelName", sCurrentModel, sizeof(sCurrentModel));
	if (StrEqual(sCurrentModel, sModel))
		return;

	SetVariantString(sModel);
	AcceptEntityInput(iClient, "SetCustomModel");
}

public Action Timer_BossRageMusic(Handle hTimer, SaxtonHaleBase boss)
{
	if (hTimer != g_hClientBossRageMusicTime[boss.iClient])
		return Plugin_Continue;
	if (StrEmpty(g_sClientBossRageMusic[boss.iClient]))
		return Plugin_Continue;
	
	if (g_flClientBossRageMusicVolume[boss.iClient] > 0.0)
	{
		//Start music fade
		g_flClientBossRageMusicVolume[boss.iClient] -= 0.1;
		EmitSoundToAll(g_sClientBossRageMusic[boss.iClient], boss.iClient, SNDCHAN_AUTO, SNDLEVEL_SCREAMING, SND_CHANGEVOL, g_flClientBossRageMusicVolume[boss.iClient]);
		g_hClientBossRageMusicTime[boss.iClient] = CreateTimer(0.1, Timer_BossRageMusic, boss);
	}
	else
	{
		//Music ends
		g_flClientBossRageMusicVolume[boss.iClient] = 0.0;
		StopSound(boss.iClient, SNDCHAN_AUTO, g_sClientBossRageMusic[boss.iClient]);
	}
	
	return Plugin_Continue;
}

Action AttachEnt_SetTransmit(int iAttachEnt, int iClient)
{
	int iOwner = GetEntPropEnt(iAttachEnt, Prop_Data, "m_pParent");
	if (iOwner == INVALID_ENT_REFERENCE)
		return Plugin_Stop;
	
	if (iOwner != iClient)
	{
		if (GetEntPropEnt(iClient, Prop_Send, "m_hObserverTarget") == iOwner && GetEntProp(iClient, Prop_Send, "m_iObserverMode") == OBS_MODE_IN_EYE)
		    return Plugin_Stop;
	}
	else if (!TF2_IsPlayerInCondition(iOwner, TFCond_Taunting))
	{
		return Plugin_Stop;
	}

	if (TF2_IsPlayerInCondition(iOwner, TFCond_Cloaked) || TF2_IsPlayerInCondition(iOwner, TFCond_Disguised) || TF2_IsPlayerInCondition(iOwner, TFCond_Stealthed))
		return Plugin_Stop;
	
	return Plugin_Continue;
}

void ApplyBossEffects(SaxtonHaleBase boss)
{
	ClearBossEffects(boss.iClient);

	char sEffect[64];
	for(int i = 0; ; i++)
	{
		boss.CallFunction("GetParticleEffect", i, sEffect, sizeof(sEffect));
		if (!sEffect[0])
			break;
		
		int iEntity = TF2_AttachParticle(sEffect, boss.iClient);
		SetEdictFlags(iEntity, GetEdictFlags(iEntity) | FL_EDICT_ALWAYS);
		CreateTimer(0.2, Timer_ApplySetTransmit, iEntity, TIMER_FLAG_NO_MAPCHANGE);
		
		sEffect[0] = 0;
	}
}

static Action Timer_ApplySetTransmit(Handle hTimer, int iEntity)
{
	// Entity reference here
	if(IsValidEntity(iEntity))
	{
		SetEdictFlags(iEntity, GetEdictFlags(iEntity) &~ FL_EDICT_ALWAYS);
		SDKHook(iEntity, SDKHook_SetTransmit, AttachEnt_SetTransmit);
	}
	
	return Plugin_Continue;
}

void ClearBossEffects(int iClient)
{
	int iEntity = INVALID_ENT_REFERENCE;
	while ((iEntity = FindEntityByClassname(iEntity, EFFECT_CLASSNAME)) != INVALID_ENT_REFERENCE)
	{
		if (GetEntPropEnt(iEntity, Prop_Data, "m_pParent") != iClient)
			continue;
		
		SetVariantString("ParticleEffectStop");
		AcceptEntityInput(iEntity, "DispatchEffect");
		AcceptEntityInput(iEntity, "ClearParent");
		
		//Some particles don't get removed properly, teleport far away then delete it
		const float flCrazyBigNumber = 8192.00; // 2^13
		float vecPos[3] = {flCrazyBigNumber, flCrazyBigNumber, flCrazyBigNumber};
		TeleportEntity(iEntity, vecPos);
		
		CreateTimer(0.5, Timer_EntityCleanup, EntIndexToEntRef(iEntity));	//Give enough time for effect to fade out before getting destroyed
	}
}
