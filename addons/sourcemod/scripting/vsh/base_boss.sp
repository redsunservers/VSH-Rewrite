static char g_sClientBossType[TF_MAXPLAYERS+1][64];
static char g_sClientBossRageMusic[TF_MAXPLAYERS+1][255];

static float g_flClientBossRageMusicVolume[TF_MAXPLAYERS+1];

static Handle g_hClientBossModelTimer[TF_MAXPLAYERS+1];
static Handle g_hClientBossRageMusicTime[TF_MAXPLAYERS+1];

methodmap SaxtonHaleBoss < SaxtonHaleBase
{
	public SaxtonHaleBase CreateBoss(const char[] type)
	{
		this.bValid = true;
		
		this.bSuperRage = false;
		
		this.iBaseHealth = 0;
		this.iHealthPerPlayer = 0;
		this.iMaxHealth = 0;
		
		this.flSpeed = 370.0;
		this.flSpeedMult = 0.07;
		this.flHealthMultiplier = 1.0;
		this.flMaxRagePercentage = 2.0;
		this.iRageDamage = 0;
		this.flEnvDamageCap = 400.0;
		this.flGlowTime = 0.0;
		this.bMinion = false;
		this.bModel = true;
		this.bCanBeHealed = false;
		this.nClass = TFClass_Unknown;

		strcopy(g_sClientBossType[this.iClient], sizeof(g_sClientBossType[]), type);

		if (g_hClientBossModelTimer[this.iClient] != null)
			delete g_hClientBossModelTimer[this.iClient];

		g_hClientBossModelTimer[this.iClient] = CreateTimer(0.2, Timer_ApplyBossModel, this.iClient, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);

		g_sClientBossRageMusic[this.iClient] = "";
		g_flClientBossRageMusicVolume[this.iClient] = 0.0;
		g_hClientBossRageMusicTime[this.iClient] = null;
		
		char sFunction[256];
		Format(sFunction, sizeof(sFunction), "%s.%s", type, type);
		
		Handle hPlugin = Function_GetPlugin(type);
		Function func = GetFunctionByName(hPlugin, sFunction);
		if (func != INVALID_FUNCTION)
		{
			Call_StartFunction(hPlugin, func);
			Call_PushCell(this);
			Call_PushCell(this);
			Call_Finish();
		}
		
		return view_as<SaxtonHaleBase>(this);
	}
	
	public SaxtonHaleBase CreateModifiers(const char[] type)
	{
		//When modifiers get created, we need to enable bool so base_modifiers can actually get called for CreateModifiers function
		this.bModifiers = true;
		return view_as<SaxtonHaleBase>(this);
	}
	
	public void SetBossType(const char[] type)
	{
		strcopy(g_sClientBossType[this.iClient], sizeof(g_sClientBossType[]), type);
	}
	
	public void GetBossType(char[] type, int length)
	{
		strcopy(type, length, g_sClientBossType[this.iClient]);
	}

	public int CalculateMaxHealth()
	{
		int iTeam = GetClientTeam(this.iClient);
		int iEnemy = 0;
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i))
			{
				int iTargetTeam = GetClientTeam(i);
				if (iTargetTeam > 1 && iTargetTeam != iTeam)
					iEnemy++;
			}
		}

		return RoundToNearest((this.iBaseHealth + this.iHealthPerPlayer*iEnemy) * this.flHealthMultiplier);
	}

	public void OnThink()
	{
		if (this.flGlowTime == -1.0 || this.flGlowTime >= GetGameTime())
		{
			SetEntProp(this.iClient, Prop_Send, "m_bGlowEnabled", true);
		}
		else
		{
			SetEntProp(this.iClient, Prop_Send, "m_bGlowEnabled", false);
		}

		//Dont modify his speed during setup time or when taunting
		if (this.flSpeed >= 0.0 && GameRules_GetRoundState() != RoundState_Preround && !TF2_IsPlayerInCondition(this.iClient, TFCond_Taunting))
		{
			float flMaxSpeed = this.flSpeed + (this.flSpeed*this.flSpeedMult*(1.0-(float(this.iHealth)/float(this.iMaxHealth))));
			SetEntPropFloat(this.iClient, Prop_Data, "m_flMaxspeed", flMaxSpeed);
		}
		
		if (g_bRoundStarted && this.iMaxRageDamage != -1)
		{
			float flRage = (float(this.iRageDamage) / float(this.iMaxRageDamage)) * 100.0;
			
			char sMessage[255];
			Format(sMessage, sizeof(sMessage), "Rage: %d%%%s", RoundToFloor(flRage), (flRage >= 100.0) ? " (Rage is ready! Press E to use your Rage!)" : "");
			
			float flHUD[2];
			flHUD[0] = -1.0;
			flHUD[1] = 0.83;
			
			int iColor[4];
			if (flRage >= 200.0)
			{
				//200% rage, bright yellow
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

			Hud_Display(this.iClient, CHANNEL_RAGE, sMessage, flHUD, 0.2, iColor);
		}
	}

	public void GetBossName(char[] sName, int length)
	{
		Format(sName, length, "Unknown Boss Name");
	}
	
	public void OnSpawn()
	{
		if (this.bModel)
		{
			ApplyBossModel(this.iClient);
			
			//Remove his zombie skin cosmetic
			SetEntProp(this.iClient, Prop_Send, "m_bForcedSkin", 0);
			SetEntProp(this.iClient, Prop_Send, "m_nForcedSkin", 0);
			SetEntProp(this.iClient, Prop_Send, "m_iPlayerSkinOverride", 0);
			
			int iEntity = MaxClients+1;
			while ((iEntity = FindEntityByClassname(iEntity, "tf_wearable*")) > MaxClients)
				if (GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity") == this.iClient || GetEntPropEnt(iEntity, Prop_Send, "moveparent") == this.iClient)
					AcceptEntityInput(iEntity, "Kill");
			
			iEntity = MaxClients+1;
			while ((iEntity = FindEntityByClassname(iEntity, "tf_powerup_bottle")) > MaxClients)
				if (GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity") == this.iClient || GetEntPropEnt(iEntity, Prop_Send, "moveparent") == this.iClient)
					AcceptEntityInput(iEntity, "Kill");
			
			iEntity = MaxClients+1;
			while ((iEntity = FindEntityByClassname(iEntity, "tf_weapon_spellbook")) > MaxClients)
				if (GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity") == this.iClient || GetEntPropEnt(iEntity, Prop_Send, "moveparent") == this.iClient)
					AcceptEntityInput(iEntity, "Kill");
		}
		
		for (int iSlot = WeaponSlot_Primary; iSlot <= WeaponSlot_BuilderEngie; iSlot++)
			TF2_RemoveItemInSlot(this.iClient, iSlot);
		
		int iHealth = this.CallFunction("CalculateMaxHealth");
		if (iHealth > 0)
		{
			this.iMaxHealth = iHealth;
			this.iHealth = iHealth;
		}
	}
	
	public int CreateWeapon(int iIndex, char[] sClassname, int iLevel, TFQuality iQuality, char[] sAttrib)
	{
		return TF2_CreateAndEquipWeapon(this.iClient, iIndex, sClassname, iLevel, iQuality, sAttrib);
	}
	
	public void AddRage(int iAmount)
	{
		int iRageRequirement = this.iMaxRageDamage;
		if (iRageRequirement < 0)	//No rage (-1)
			return;
		
		//Add/Remove rage
		int iRage = this.iRageDamage + iAmount;
		
		int iMaxRage = RoundToNearest(float(iRageRequirement) * this.flMaxRagePercentage);
		if (iRage > iMaxRage) iRage = iMaxRage;
		if (iRage < 0) iRage = 0;
		
		this.iRageDamage = iRage;
	}
	
	public Action OnBuild(TFObjectType nType, TFObjectMode nMode)
	{
		return Plugin_Handled;
	}
	
	public void OnRage()
	{
		this.flRageLastTime = GetGameTime();

		int iNumRageRemove = RoundToFloor(float(this.iRageDamage)/float(this.iMaxRageDamage));
		this.iRageDamage -= this.iMaxRageDamage * iNumRageRemove;
		this.bSuperRage = (iNumRageRemove == 2);

		if (TF2_IsPlayerInCondition(this.iClient, TFCond_Dazed))
			TF2_RemoveCondition(this.iClient, TFCond_Dazed); //Allow hale to escape permastun situations when using rage

		char sSound[255];
		float flDuration = 0.0;
		this.CallFunction("GetRageMusicInfo", sSound, sizeof(sSound), flDuration);
		
		if (flDuration > 0.0 && !StrEmpty(sSound))
		{
			StopSound(this.iClient, SNDCHAN_AUTO, sSound);
			EmitSoundToAll(sSound, this.iClient, SNDCHAN_AUTO, SNDLEVEL_SCREAMING);
			
			g_hClientBossRageMusicTime[this.iClient] = CreateTimer((this.bSuperRage) ? flDuration : (flDuration/2.0), Timer_BossRageMusic, this);
			strcopy(g_sClientBossRageMusic[this.iClient], sizeof(g_sClientBossRageMusic[]), sSound);
			g_flClientBossRageMusicVolume[this.iClient] = 1.0;
		}
		
		this.CallFunction("GetSound", sSound, sizeof(sSound), VSHSound_Rage);
		if (!StrEmpty(sSound))
			EmitSoundToAll(sSound, this.iClient, SNDCHAN_VOICE, SNDLEVEL_SCREAMING);
	}

	public Action OnAttackCritical(int iWeapon, bool &bResult)
	{
		//Disable random crit for bosses
		if (!TF2_IsForceCrit(this.iClient))
		{
			bResult = false;
			return Plugin_Changed;
		}
		
		return Plugin_Continue;
	}
	
	public Action OnSoundPlayed(int clients[MAXPLAYERS], int &numClients, char sample[PLATFORM_MAX_PATH], int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
	{
		//Don't play pain sounds
		if (StrContains(sample, "PainSevere", false) != -1)
			return Plugin_Handled;
		
		return Plugin_Continue;
	}
	
	public Action OnAttackDamage(int &victim, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
	{
		if (damagecustom == TF_CUSTOM_BOOTS_STOMP)
		{
			//Because we made fall damage deal near zero, hard set stomp damage to insta kill
			damage = 999.0;
			return Plugin_Changed;
		}
		
		return Plugin_Continue;
	}

	public Action OnTakeDamage(int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
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
			this.CallFunction("GetSound", sSound, sizeof(sSound), VSHSound_Pain);
			if (!StrEmpty(sSound))
				EmitSoundToAll(sSound, this.iClient, SNDCHAN_VOICE, SNDLEVEL_SCREAMING);
		}

		if (MaxClients < attacker)
		{
			char strAttacker[32];
			GetEdictClassname(attacker, strAttacker, sizeof(strAttacker));
			if (strcmp(strAttacker, "trigger_hurt") == 0)
			{
				float flEnvDamage = damage;
				if ((damagetype & DMG_ACID)) flEnvDamage *= 3.0;

				if (flEnvDamage > this.flEnvDamageCap)
				{
					int iBossSpawn = MaxClients+1;
					int iTeam = GetClientTeam(this.iClient);
					while((iBossSpawn = FindEntityByClassname(iBossSpawn, "info_player_teamspawn")) > MaxClients)
					{
						if (GetEntProp(iBossSpawn, Prop_Send, "m_iTeamNum") == iTeam)
						{
							float vecPos[3];
							GetEntPropVector(iBossSpawn, Prop_Data, "m_vecAbsOrigin", vecPos);
							float vecNoVel[3];
							TeleportEntity(this.iClient, vecPos, NULL_VECTOR, vecNoVel);
							damage = (damagetype & DMG_ACID) ? this.flEnvDamageCap/3.0 : this.flEnvDamageCap;
							TF2_StunPlayer(this.iClient, 2.0, 1.0, 257, 0);
							action = Plugin_Changed;
						}
					}
				}
			}
		}

		return action;
	}

	public void Destroy()
	{
		this.bValid = false;
		
		SetVariantString("");
		AcceptEntityInput(this.iClient, "SetCustomModel");
		TF2_RegeneratePlayer(this.iClient);

		TF2_AddCondition(this.iClient, TFCond_SpeedBuffAlly, 0.01);

		if (!StrEmpty(g_sClientBossRageMusic[this.iClient]))
			StopSound(this.iClient, SNDCHAN_AUTO, g_sClientBossRageMusic[this.iClient]);
		g_hClientBossRageMusicTime[this.iClient] = null;

		if (g_hClientBossModelTimer[this.iClient] != null)
			delete g_hClientBossModelTimer[this.iClient];
	}
};

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

public Action Timer_BossRageMusic(Handle hTimer, SaxtonHaleBoss boss)
{
	if (hTimer != g_hClientBossRageMusicTime[boss.iClient])
		return;
	if (StrEmpty(g_sClientBossRageMusic[boss.iClient]))
		return;
	
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
}