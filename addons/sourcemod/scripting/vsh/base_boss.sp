#define EFFECT_CLASSNAME		"info_particle_system"	// Any cheap ent that allows SetTransmit

static char g_sClientBossRageMusic[MAXPLAYERS][255];

static float g_flClientBossRageMusicVolume[MAXPLAYERS];

static Handle g_hClientBossModelTimer[MAXPLAYERS];
static Handle g_hClientBossRageMusicTime[MAXPLAYERS];

public void SaxtonHaleBoss_Create(SaxtonHaleBase boss)
{
	boss.bSuperRage = false;
	
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
	boss.flEnvDamageCap = 200.0;
	boss.flGlowTime = 0.0;
	
	boss.bMinion = false;
	boss.bModel = true;
	boss.nClass = TFClass_Unknown;

	g_sClientBossRageMusic[boss.iClient] = "";
	g_flClientBossRageMusicVolume[boss.iClient] = 0.0;
	g_hClientBossRageMusicTime[boss.iClient] = null;
	
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
	bool bGlow = (boss.flGlowTime == -1.0 || boss.flGlowTime >= GetGameTime());
	SetEntProp(boss.iClient, Prop_Send, "m_bGlowEnabled", bGlow);
	
	//Dont modify his speed during setup time or when taunting
	if (boss.flSpeed >= 0.0 && GameRules_GetRoundState() != RoundState_Preround && !TF2_IsPlayerInCondition(boss.iClient, TFCond_Taunting))
	{
		float flMaxSpeed = boss.flSpeed + (boss.flSpeed*boss.flSpeedMult*(1.0-(float(boss.iHealth)/float(boss.iMaxHealth))));
		SetEntPropFloat(boss.iClient, Prop_Data, "m_flMaxspeed", flMaxSpeed);
	}
	
	if (g_bRoundStarted && IsPlayerAlive(boss.iClient) && boss.iMaxRageDamage != -1)
	{
		float flRage = (float(boss.iRageDamage) / float(boss.iMaxRageDamage)) * 100.0;
		
		char sMessage[255];
		Format(sMessage, sizeof(sMessage), "Rage: %d%%%s", RoundToFloor(flRage), (flRage >= 100.0) ? " (Rage is ready! Press E to use your Rage!)" : "");
		
		float flHUD[2];
		flHUD[0] = -1.0;
		flHUD[1] = 0.83;
		
		int iColor[4];
		if (flRage >= 200.0 || flRage >= boss.flMaxRagePercentage * 100.0)
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
			Call_PushCell(TF_STUNFLAGS_SMALLBONK);	//Stunflags
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
	
	if (flDuration > 0.0 && !StrEmpty(sSound))
	{
		StopSound(boss.iClient, SNDCHAN_AUTO, sSound);
		EmitSoundToAll(sSound, boss.iClient, SNDCHAN_AUTO, SNDLEVEL_SCREAMING);
		
		g_hClientBossRageMusicTime[boss.iClient] = CreateTimer((boss.bSuperRage) ? flDuration : (flDuration/2.0), Timer_BossRageMusic, boss);
		strcopy(g_sClientBossRageMusic[boss.iClient], sizeof(g_sClientBossRageMusic[]), sSound);
		g_flClientBossRageMusicVolume[boss.iClient] = 1.0;
	}
	
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
		damage = 999.0;
		return Plugin_Changed;
	}
	
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
					TF2_StunPlayer(boss.iClient, 2.0, _, TF_STUNFLAGS_NORMALBONK, 0);
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
	boss.CallFunction("GetModel", sModel, sizeof(sModel));
	SetVariantString(sModel);
	AcceptEntityInput(iClient, "SetCustomModel");
	SetEntProp(iClient, Prop_Send, "m_bUseClassAnimations", true);
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
