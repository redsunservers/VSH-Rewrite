static int g_iBackstabCount[MAXPLAYERS][MAXPLAYERS];
static int g_iClimbAmount[MAXPLAYERS];
static int g_iZombieUsed[MAXPLAYERS];
static float g_flUberBeforeHealingBuilding[MAXPLAYERS];
static float g_flDispenserBoost[MAXPLAYERS];

static bool g_bTagsLunchbox[MAXPLAYERS];

static float g_flTagsAirblastCooldown[MAXPLAYERS];
static float g_flTagsAirblastLastUsed[MAXPLAYERS];
static FlamethrowerState g_nTagsAirblastState[MAXPLAYERS];

static ArrayList g_aAttrib;	//Arrays of active attribs to be removed later

enum
{
	TagsAttrib_Ref,
	TagsAttrib_Index,
	TagsAttrib_Duration,
	TagsAttrib_MAX,
}

enum TagsMath
{
	TagsMath_Set,
	TagsMath_Add,
	TagsMath_Multiply,
	TagsMath_Damage
}

void Tags_ResetClient(int iClient)
{
	if (g_aAttrib == null)
		g_aAttrib = new ArrayList(TagsAttrib_MAX);
	
	g_iClimbAmount[iClient] = 0;
	g_iZombieUsed[iClient] = 0;
	g_flUberBeforeHealingBuilding[iClient] = 0.0;
	g_flDispenserBoost[iClient] = 0.0;
	
	g_flTagsAirblastCooldown[iClient] = 0.0;
	g_flTagsAirblastLastUsed[iClient] = 0.0;
	
	for (int iVictim = 1; iVictim <= MaxClients; iVictim++)
		g_iBackstabCount[iClient][iVictim] = 0;
	
	TF2Attrib_SetByDefIndex(iClient, ATTRIB_BIDERECTIONAL, 0.0);
	
	Hud_SetRageView(iClient, false);
}

void Tags_OnThink(int iClient)
{
	TagsCore_CallAll(iClient, TagsCall_Think);
	
	if (GetEntityFlags(iClient) & FL_ONGROUND)
		g_iClimbAmount[iClient] = 0;
	
	if (g_flTagsAirblastCooldown[iClient] > 0.0 && g_flTagsAirblastLastUsed[iClient] + g_flTagsAirblastCooldown[iClient] < GetGameTime())
	{
		//Detect if airblast is used, and reset if so
		int iPrimary = TF2_GetItemInSlot(iClient, WeaponSlot_Primary);
		if (iPrimary > MaxClients)
		{
			FlamethrowerState nState = view_as<FlamethrowerState>(GetEntProp(iPrimary, Prop_Send, "m_iWeaponState"));
			if (nState != g_nTagsAirblastState[iClient] && nState == FlamethrowerState_Airblast)
			{
				g_flTagsAirblastLastUsed[iClient] = GetGameTime();	//Set cooldown
				SetEntPropFloat(iPrimary, Prop_Send, "m_flNextSecondaryAttack", GetGameTime() + g_flTagsAirblastCooldown[iClient]);
			}
			
			g_nTagsAirblastState[iClient] = nState;
		}
	}
	
	int iSecondary = TF2_GetItemInSlot(iClient, WeaponSlot_Secondary);
	if (iSecondary > MaxClients)
	{
		char sClassname[256];
		GetEntityClassname(iSecondary, sClassname, sizeof(sClassname));
		if (StrContains(sClassname, "tf_weapon_lunchbox") == 0)
		{
			int iAmmoType = GetEntProp(iSecondary, Prop_Send, "m_iPrimaryAmmoType");
			if (iAmmoType > -1)
			{
				int iAmmo = TF2_GetAmmo(iClient, iAmmoType);
				
				if (iAmmo == 1)
				{
					g_bTagsLunchbox[iClient] = false;
				}
				if (iAmmo == 0 && !g_bTagsLunchbox[iClient])
				{
					g_bTagsLunchbox[iClient] = true;
					
					if (TF2_IsPlayerInCondition(iClient, TFCond_Taunting))
						TagsCore_CallAll(iClient, TagsCall_Lunchbox);
				}
			}
		}
		else if (StrContains(sClassname, "tf_weapon_medigun") == 0)
		{
			//Healing buildings, Set uber back to what it was when healing building
			int iHealTarget = GetEntPropEnt(iSecondary, Prop_Send, "m_hHealingTarget");
			
			if (iHealTarget > -1 && GetEntProp(iSecondary, Prop_Send, "m_bChargeRelease"))
			{
				g_flUberBeforeHealingBuilding[iClient] = 0.0;
			}
			else if (iHealTarget > MaxClients)
			{
				float flChargeLevel = GetEntPropFloat(iSecondary, Prop_Send, "m_flChargeLevel");
				if (flChargeLevel < g_flUberBeforeHealingBuilding[iClient])
					g_flUberBeforeHealingBuilding[iClient] = flChargeLevel;
				else
					SetEntPropFloat(iSecondary, Prop_Send, "m_flChargeLevel", g_flUberBeforeHealingBuilding[iClient]);
			}
			else
			{
				g_flUberBeforeHealingBuilding[iClient] = GetEntPropFloat(iSecondary, Prop_Send, "m_flChargeLevel");
			}
		}
	}
	
	static int TELEPORTER_BODYGROUP_ARROW 	= (1 << 1);
	
	//Compiler no like this
	const int iObjectType = view_as<int>(TFObject_Sentry) + 1;
	const int iObjectMode = view_as<int>(TFObjectMode_Exit) + 1;
	int iBuilding[iObjectType][iObjectMode];	//Building index built from client
	
	TFTeam nTeam = TF2_GetClientTeam(iClient);
	
	//Get buildings that were healed
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i) && TF2_GetClientTeam(i) == nTeam)
		{
			char sClassname[32];
			int iMedigun = GetPlayerWeaponSlot(i, WeaponSlot_Secondary);
			if (iMedigun <= MaxClients)
				continue;
			
			GetEdictClassname(iMedigun, sClassname, sizeof(sClassname));
			if (StrContains(sClassname, "tf_weapon_medigun") != 0)
				continue;
			
			int iPatient = GetEntPropEnt(iMedigun, Prop_Send, "m_hHealingTarget");
			if (iPatient > MaxClients)
			{
				char sPatientClassname[64];
				GetEdictClassname(iPatient, sPatientClassname, sizeof(sPatientClassname));
				if (StrContains(sPatientClassname, "obj_") == 0 && GetEntPropEnt(iPatient, Prop_Send, "m_hBuilder") == iClient)
				{
					TFObjectType nType = view_as<TFObjectType>(GetEntProp(iPatient, Prop_Send, "m_iObjectType"));
					TFObjectType nMode = view_as<TFObjectType>(GetEntProp(iPatient, Prop_Send, "m_iObjectMode"));
					iBuilding[nType][nMode] = iPatient;
				}
			}
		}
	}
	
	//Sentry
	if (iBuilding[TFObject_Sentry][TFObjectMode_None] > MaxClients)
		TF2_AddCondition(iClient, TFCond_Buffed, 0.05);
	
	//Dispenser
	if (iBuilding[TFObject_Dispenser][TFObjectMode_None] > MaxClients && g_flDispenserBoost[iClient] <= GetGameTime())
	{
		int iMetal = GetEntProp(iBuilding[TFObject_Dispenser][TFObjectMode_None], Prop_Send, "m_iAmmoMetal");
		if (iMetal < 400)
		{
			SetEntProp(iBuilding[TFObject_Dispenser][TFObjectMode_None], Prop_Send, "m_iAmmoMetal", iMetal+1);
			g_flDispenserBoost[iClient] = GetGameTime()+0.25;
		}
	}
	
	//Teleporter
	if (iBuilding[TFObject_Teleporter][TFObjectMode_Entrance] <= MaxClients && iBuilding[TFObject_Teleporter][TFObjectMode_Exit] <= MaxClients)
	{
		float flVal;
		if (TF2_FindAttribute(iClient, ATTRIB_BIDERECTIONAL, flVal) && flVal >= 1.0)
		{
			TF2Attrib_SetByDefIndex(iClient, ATTRIB_BIDERECTIONAL, 0.0);
			
			int iTeleporterExit = TF2_GetBuilding(iClient, TFObject_Teleporter, TFObjectMode_Exit);
			if (iTeleporterExit > MaxClients)
			{
				int iBodyGroups = GetEntProp(iTeleporterExit, Prop_Send, "m_nBody");
				SetEntProp(iTeleporterExit, Prop_Send, "m_nBody", iBodyGroups &~ TELEPORTER_BODYGROUP_ARROW);
			}
		}
	}
	else
	{
		TF2Attrib_SetByDefIndex(iClient, ATTRIB_BIDERECTIONAL, 1.0);
		
		int iTeleporterExit = TF2_GetBuilding(iClient, TFObject_Teleporter, TFObjectMode_Exit);
		if (iTeleporterExit > MaxClients)
		{
			int iBodyGroups = GetEntProp(iTeleporterExit, Prop_Send, "m_nBody");
			SetEntProp(iTeleporterExit, Prop_Send, "m_nBody", iBodyGroups | TELEPORTER_BODYGROUP_ARROW);
		}
	}
}

void Tags_OnButton(int iClient, int &iButtons)
{
	//Prevent clients holding m2 while airblast in cooldown
	if (iButtons & IN_ATTACK2 && g_flTagsAirblastLastUsed[iClient] + g_flTagsAirblastCooldown[iClient] > GetGameTime())
	{
		int iPrimary = TF2_GetItemInSlot(iClient, WeaponSlot_Primary);
		int iActiveWep = GetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon");
		if (iActiveWep > MaxClients && iPrimary == iActiveWep)
			iButtons &= ~IN_ATTACK2;
		
		//Change the m_iWeaponState to a proper value after the airblast to prevent the visual bug
		if (g_nTagsAirblastState[iClient] == FlamethrowerState_Airblast)
		{
			if (iButtons & IN_ATTACK)
			{
				g_nTagsAirblastState[iClient] = FlamethrowerState_Firing;
				SetEntProp(iPrimary, Prop_Send, "m_iWeaponState", FlamethrowerState_Firing);
			}
			else
			{
				g_nTagsAirblastState[iClient] = FlamethrowerState_Idle;
				SetEntProp(iPrimary, Prop_Send, "m_iWeaponState", FlamethrowerState_Idle);
			}
		}
	}
}

public Action Tags_OnProjectileTouch(int iProjectile, int iToucher)
{
	if (!g_bEnabled) return Plugin_Continue;
	if (g_iTotalRoundPlayed <= 0) return Plugin_Continue;
	
	int iClient = GetEntPropEnt(iProjectile, Prop_Send, "m_hOwnerEntity");
	if (SaxtonHale_IsValidAttack(iClient))
	{
		int iWeapon = GetEntPropEnt(iProjectile, Prop_Send, "m_hOriginalLauncher");	//There also similar m_hLauncher
		int iSlot = TF2_GetSlotFromWeapon(iWeapon);
		
		if (iSlot > -1)
		{
			TagsParams tParams = new TagsParams();
			tParams.SetInt("projectile", iProjectile);
			TagsCore_CallSlot(iClient, TagsCall_Projectile, iSlot, tParams);
			delete tParams;
		}
	}
	
	return Plugin_Continue;
}

//---------------------------

public void Tags_AddCond(int iClient, int iTarget, TagsParams tParams)
{
	if (iTarget <= 0 || iTarget > MaxClients || !IsClientInGame(iTarget) || !IsPlayerAlive(iTarget))
		return;
	
	TFCond nCond = tParams.GetInt("cond", -1);
	float flDuration = tParams.GetFloat("duration", 0.05);	//By default, duration is as small as enough for think function
	TF2_AddCondition(iTarget, nCond, flDuration);
}

public void Tags_AddCondVaccinator(int iClient, int iTarget, TagsParams tParams)
{
	if (iTarget <= 0 || iTarget > MaxClients || !IsClientInGame(iTarget) || !IsPlayerAlive(iTarget))
		return;
	
	int iWeapon = TF2_GetItemInSlot(iClient, WeaponSlot_Secondary);
	int iType = GetEntProp(iWeapon, Prop_Send, "m_nChargeResistType");
	float flDuration = tParams.GetFloat("duration", 0.05);	//By default, duration is as small as enough for think function
	
	static const TFCond TFCond_Invalid = view_as<TFCond>(-1);
	TFCond nCond = TFCond_Invalid;
	switch (iType)
	{
		case 0: nCond = tParams.GetInt("bullet", TFCond_Invalid);
		case 1: nCond = tParams.GetInt("blast", TFCond_Invalid);
		case 2: nCond = tParams.GetInt("fire", TFCond_Invalid);
	}
	
	if (nCond > TFCond_Invalid)
		TF2_AddCondition(iTarget, nCond, flDuration);
}

public void Tags_RemoveCond(int iClient, int iTarget, TagsParams tParams)
{
	if (iTarget <= 0 || iTarget > MaxClients || !IsClientInGame(iTarget) || !IsPlayerAlive(iTarget))
		return;
	
	TFCond nCond = tParams.GetInt("cond", -1);
	TF2_RemoveCondition(iTarget, nCond);
}

public void Tags_SetEntProp(int iClient, int iTarget, TagsParams tParams)
{
	if (iTarget <= 0 || !IsValidEdict(iTarget))
		return;
	
	//Get stuffs
	char sType[8], sProp[32], sMath[32];
	tParams.GetString("type", sType, sizeof(sType));
	tParams.GetString("prop", sProp, sizeof(sProp));
	tParams.GetString("math", sMath, sizeof(sMath));
	int iElement = tParams.GetInt("element", 0);
	
	if (StrEqual(sType, "int"))
	{
		int iValue = tParams.GetInt("value");
		
		switch (Tags_GetMath(sMath))
		{
			case TagsMath_Add: iValue += GetEntProp(iTarget, Prop_Send, sProp);
			case TagsMath_Multiply: iValue *= GetEntProp(iTarget, Prop_Send, sProp);
			case TagsMath_Damage: iValue = RoundToFloor(float(g_iPlayerDamage[iClient]) / float(iValue));
		}
		
		int iMin, iMax;
		if (tParams.GetIntEx("min", iMin) && iValue < iMin) iValue = iMin;
		if (tParams.GetIntEx("max", iMax) && iValue > iMax) iValue = iMax;
		
		SetEntProp(iTarget, Prop_Send, sProp, iValue, _, iElement);
	}
	else if (StrEqual(sType, "float"))
	{
		float flValue = tParams.GetFloat("value");
		
		switch (Tags_GetMath(sMath))
		{
			case TagsMath_Add: flValue += GetEntPropFloat(iTarget, Prop_Send, sProp);
			case TagsMath_Multiply: flValue *= GetEntPropFloat(iTarget, Prop_Send, sProp);
			case TagsMath_Damage: flValue = float(g_iPlayerDamage[iClient]) / flValue;
		}
		
		float flMin, flMax;
		if (tParams.GetFloatEx("min", flMin) && flValue < flMin) flValue = flMin;
		if (tParams.GetFloatEx("max", flMax) && flValue > flMax) flValue = flMax;
		
		SetEntPropFloat(iTarget, Prop_Send, sProp, flValue, iElement);
	}
}

public void Tags_SetAttrib(int iClient, int iTarget, TagsParams tParams)
{
	if (iTarget <= 0 || !IsValidEdict(iTarget))
		return;
	
	int iIndex = tParams.GetInt("index");
	float flValue = tParams.GetFloat("value");
	
	float flCurrentValue = 0.0;
	TF2_FindAttribute(iTarget, iIndex, flCurrentValue);
	
	char sMath[32];
	tParams.GetString("math", sMath, sizeof(sMath));
	
	switch (Tags_GetMath(sMath))
	{
		case TagsMath_Add: flValue += flCurrentValue;
		case TagsMath_Multiply: flValue *= flCurrentValue;
		case TagsMath_Damage: flValue = float(g_iPlayerDamage[iClient]) / flValue;
	}
	
	float flMin, flMax;
	if (tParams.GetFloatEx("min", flMin) && flValue < flMin) flValue = flMin;
	if (tParams.GetFloatEx("max", flMax) && flValue > flMax) flValue = flMax;
	
	//Set attrib
	TF2Attrib_SetByDefIndex(iTarget, iIndex, flValue);
	TF2Attrib_ClearCache(iTarget);
}

public void Tags_AddAttrib(int iClient, int iTarget, TagsParams tParams)
{
	if (iTarget <= 0 || !IsValidEdict(iTarget))
		return;
	
	int iRef = EntIndexToEntRef(iTarget);
	int iIndex = tParams.GetInt("index");
	float flValue = tParams.GetFloat("value");
	float flDuration = tParams.GetFloat("duration");
	
	//Check if weapon already have same attrib
	int iPos;
	bool bFound = false;
	int iLength = g_aAttrib.Length;
	for (iPos = 0; iPos < iLength; iPos++)
	{
		if (g_aAttrib.Get(iPos, TagsAttrib_Ref) == iRef && g_aAttrib.Get(iPos, TagsAttrib_Index) == iIndex)
		{
			bFound = true;
			break;
		}
	}
	
	if (!bFound)
	{
		//Add attrib
		TF2Attrib_SetByDefIndex(iTarget, iIndex, flValue);
		TF2Attrib_ClearCache(iTarget);
		
		int iSize = g_aAttrib.Length;
		g_aAttrib.Resize(iSize+1);
		g_aAttrib.Set(iSize, iRef, TagsAttrib_Ref);
		g_aAttrib.Set(iSize, iIndex, TagsAttrib_Index);
		g_aAttrib.Set(iSize, GetGameTime() + flDuration, TagsAttrib_Duration);
	}
	else if (g_aAttrib.Get(iPos, TagsAttrib_Duration) <= GetGameTime() + flDuration)
	{
		//Set new duration
		g_aAttrib.Set(iPos, GetGameTime() + flDuration, TagsAttrib_Duration);
	}
	else
	{
		//Don't need to create timer to reset
		return;
	}
	
	DataPack data;
	CreateDataTimer(flDuration, Timer_ResetAttrib, data);
	data.WriteCell(iRef);
	data.WriteCell(iIndex);
}

public void Tags_RemoveAttrib(int iClient, int iTarget, TagsParams tParams)
{
	if (iTarget <= 0 || !IsValidEdict(iTarget))
		return;
	
	int iRef = EntIndexToEntRef(iTarget);
	int iIndex = tParams.GetInt("index");
	
	TF2Attrib_RemoveByDefIndex(iTarget, iIndex);
	TF2Attrib_ClearCache(iTarget);
	
	//Find in array thats using added attrib and remove it
	int iLength = g_aAttrib.Length;
	for (int iPos = 0; iPos < iLength; iPos++)
	{
		if (g_aAttrib.Get(iPos, TagsAttrib_Ref) == iRef && g_aAttrib.Get(iPos, TagsAttrib_Index) == iIndex)
		{
			g_aAttrib.Erase(iPos);
			return;
		}
	}
}

public void Tags_AreaOfEffect(int iClient, int iTarget, TagsParams tParams)
{
	if (iTarget <= 0 || iTarget > MaxClients || !IsClientInGame(iTarget) || !IsPlayerAlive(iTarget))
		return;
	
	DataPack data = new DataPack();
	data.WriteCell(EntIndexToEntRef(iTarget));
	data.WriteFloat(tParams.GetFloat("duration", 0.0) + GetGameTime());
	data.WriteFloat(tParams.GetFloat("radius", 0.0));
	data.WriteCell(tParams.GetInt("cond", -1));
	
	RequestFrame(Frame_AreaOfRange, data);
}

public void Tags_Glow(int iClient, int iTarget, TagsParams tParams)
{
	if (!SaxtonHale_IsValidBoss(iTarget))
		return;
	
	float flGlowTime = tParams.GetFloat("duration");
	
	int iWeapon = tParams.GetInt("weapon", -1);
	if (iWeapon > MaxClients && HasEntProp(iWeapon, Prop_Send, "m_flChargedDamage"))
		flGlowTime *= GetEntPropFloat(iWeapon, Prop_Send, "m_flChargedDamage") / 100.0;
	
	flGlowTime += GetGameTime();
	
	SaxtonHaleBase boss = SaxtonHaleBase(iTarget);
	if (boss.flGlowTime != -1.0 && boss.flGlowTime < flGlowTime)
		boss.flGlowTime = flGlowTime;
}

public void Tags_Climb(int iClient, int iTarget, TagsParams tParams)
{
	if (iTarget <= 0 || iTarget > MaxClients || !IsClientInGame(iTarget) || !IsPlayerAlive(iTarget))
		return;
	
	float flHeight = tParams.GetFloat("height");
	int iMax = tParams.GetInt("max");
	float flDamage = tParams.GetFloat("selfdamage");
	float flHorizontalSpeedMult = tParams.GetFloat("horizontal", 1.0);
	
	if (iMax >= 0 && iMax <= g_iClimbAmount[iTarget])
		return;
	
	if (float(GetEntProp(iTarget, Prop_Send, "m_iHealth")) <= flDamage)
		return;
	
	float vecClientEyePos[3], vecClientEyeAng[3];
	GetClientEyePosition(iTarget, vecClientEyePos);
	GetClientEyeAngles(iTarget, vecClientEyeAng);

	//Check for colliding entities
	TR_TraceRayFilter(vecClientEyePos, vecClientEyeAng, MASK_PLAYERSOLID, RayType_Infinite, TraceRay_DontHitEntity, iTarget);
	if (!TR_DidHit(INVALID_HANDLE)) return;
	
	int iEntity = TR_GetEntityIndex(INVALID_HANDLE);
	
	char sClassname[64];
	GetEdictClassname(iEntity, sClassname, sizeof(sClassname));
	if (strcmp(sClassname, "worldspawn") != 0 && strncmp(sClassname, "prop_", 5) != 0)
		return;
	
	float vecNormal[3];
	TR_GetPlaneNormal(INVALID_HANDLE, vecNormal);
	GetVectorAngles(vecNormal, vecNormal);

	if (vecNormal[0] >= 30.0 && vecNormal[0] <= 330.0) return;
	if (vecNormal[0] <= -30.0) return;
	
	float vecPos[3];
	TR_GetEndPosition(vecPos);
	float flDistance = GetVectorDistance(vecClientEyePos, vecPos);

	if (flDistance >= 100.0) return;
	
	float fVelocity[3];
	GetEntPropVector(iTarget, Prop_Data, "m_vecVelocity", fVelocity);
	fVelocity[0] *= flHorizontalSpeedMult;
	fVelocity[1] *= flHorizontalSpeedMult;
	fVelocity[2] = flHeight;
	TeleportEntity(iTarget, NULL_VECTOR, NULL_VECTOR, fVelocity);
	
	g_iClimbAmount[iTarget]++;
	SDKHooks_TakeDamage(iTarget, 0, iTarget, flDamage, DMG_PREVENT_PHYSICS_FORCE);
	
	int iFlags = GetEntityFlags(iClient);
	iFlags &= ~FL_ONGROUND;
	SetEntityFlags(iClient, iFlags);
}

public void Tags_OnBackstab(int iClient, int iTarget, TagsParams tParams)
{
	if (iTarget <= 0 || iTarget > MaxClients || !IsClientInGame(iTarget) || !IsPlayerAlive(iTarget))
		return;
	
	//Anounce both attacker and victim the backstab
	EmitSoundToClient(iClient, SOUND_BACKSTAB);
	EmitSoundToClient(iTarget, SOUND_BACKSTAB);
	PrintCenterText(iClient, "You backstabbed the boss!");
	PrintCenterText(iTarget, "You were backstabbed!");
	
	//Play boss backstab sound
	char sSound[255];
	SaxtonHaleBase boss = SaxtonHaleBase(iTarget);
	boss.CallFunction("GetSound", sSound, sizeof(sSound), VSHSound_Backstab);
	if (!StrEmpty(sSound))
		EmitSoundToAll(sSound, iTarget, SNDCHAN_VOICE, SNDLEVEL_SCREAMING);
	
	int iWeapon = TF2_GetItemInSlot(iClient, WeaponSlot_Melee);
	
	//Add cooldown to weapon
	float flBackStabCooldown = GetGameTime() + 2.0;
	SetEntPropFloat(iWeapon, Prop_Send, "m_flNextPrimaryAttack", flBackStabCooldown);
	SetEntPropFloat(iClient, Prop_Send, "m_flNextAttack", flBackStabCooldown);
	SetEntPropFloat(iClient, Prop_Send, "m_flStealthNextChangeTime", flBackStabCooldown);
	
	SDK_SendWeaponAnim(iWeapon, 0x648);
	
	g_iBackstabCount[iClient][iTarget]++;
}

public void Tags_OnBackstabChain(int iClient, int iTarget, TagsParams tParams)
{
	int iTotalBackstab = g_iBackstabCount[iClient][iTarget];
	int iRequiredBackstab = tParams.GetInt("requirement");
	
	//Special backstab sound, right now we only have 4 for it
	if (1 <= iTotalBackstab <= 4)
	{
		char sBackStabSound[PLATFORM_MAX_PATH];
		Format(sBackStabSound, sizeof(sBackStabSound), "vsh_rewrite/stab0%i.mp3", iTotalBackstab);
		EmitSoundToAll(sBackStabSound);
	}
	
	//Message
	char sMessage[255];
	Format(sMessage, sizeof(sMessage), "%N vs %N\nTotal backstab: %d/%d", iClient, iTarget, iTotalBackstab, iRequiredBackstab);
	PrintHintTextToAll(sMessage);
	
	if (iTotalBackstab == iRequiredBackstab)
		Forward_ChainStab(iClient, iTarget);
}

public void Tags_OnMarketGardened(int iClient, int iTarget, TagsParams tParams)
{
	PrintCenterText(iClient, "You market gardened him!");
	PrintCenterText(iTarget, "You were just market gardened!");
	
	EmitSoundToAll(SOUND_DOUBLEDONK, iClient);
}

public void Tags_AddHealth(int iClient, int iTarget, TagsParams tParams)
{
	if (iTarget <= 0 || iTarget > MaxClients || !IsClientInGame(iTarget) || !IsPlayerAlive(iTarget))
		return;
	
	int iAmount = tParams.GetInt("amount");
	float flMaxOverheal = tParams.GetFloat("overheal", 1.5);
	
	int iMaxHealth = SDK_GetMaxHealth(iTarget);
	
	Client_AddHealth(iTarget, iAmount, RoundToNearest(float(iMaxHealth) * (flMaxOverheal - 1.0)));
}

public void Tags_AddHealthBase(int iClient, int iTarget, TagsParams tParams)
{
	if (iTarget <= 0 || iTarget > MaxClients || !IsClientInGame(iTarget) || !IsPlayerAlive(iTarget))
		return;
	
	float flAmount = tParams.GetFloat("amount");
	float flMaxOverheal = tParams.GetFloat("overheal", 1.5);
	
	int iMaxHealth = SDK_GetMaxHealth(iTarget);
	
	Client_AddHealth(iTarget, RoundToNearest(float(iMaxHealth) * flAmount), RoundToNearest(float(iMaxHealth) * (flMaxOverheal - 1.0)));
}

public void Tags_DropHealth(int iClient, int iTarget, TagsParams tParams)
{
	if (iTarget <= 0 || iTarget > MaxClients || !IsClientInGame(iTarget) || !IsPlayerAlive(iTarget))
		return;
	
	int iHealthPack = CreateEntityByName("item_healthkit_small");
	float vecPos[3];
	GetClientAbsOrigin(iTarget, vecPos);
	vecPos[2] += 20.0;
	if (iHealthPack > MaxClients)
	{
		DispatchKeyValue(iHealthPack, "OnPlayerTouch", "!self,Kill,,0,-1");
		DispatchSpawn(iHealthPack);
		SetEntProp(iHealthPack, Prop_Send, "m_iTeamNum", GetClientTeam(iClient));
		SetEntityMoveType(iHealthPack, MOVETYPE_VPHYSICS);
		float vecVel[3];
		vecVel[0] = float(GetRandomInt(-10, 10)), vecVel[1] = float(GetRandomInt(-10, 10)), vecVel[2] = 50.0;
		TeleportEntity(iHealthPack, vecPos, NULL_VECTOR, vecVel);
	}
}

public void Tags_RemoveRage(int iClient, int iTarget, TagsParams tParams)
{
	if (!SaxtonHale_IsValidBoss(iTarget))
		return;
	
	SaxtonHaleBase boss = SaxtonHaleBase(iTarget);
	int iOldRageDamage = boss.iRageDamage;
	boss.CallFunction("AddRage", -tParams.GetInt("amount"));
	g_iPlayerAssistDamage[iClient] += (iOldRageDamage - boss.iRageDamage);
}

public void Tags_ViewRage(int iClient, int iTarget, TagsParams tParams)
{
	if (iTarget <= 0 || iTarget > MaxClients || !IsClientInGame(iTarget) || !IsPlayerAlive(iTarget))
		return;
	
	Hud_SetRageView(iTarget, true);
}

public void Tags_AddClip(int iClient, int iTarget, TagsParams tParams)
{
	if (iTarget <= 0 || !IsValidEdict(iTarget))
		return;
	
	int iAmount = tParams.GetInt("amount");
	float flDuration = tParams.GetFloat("duration");
	
	int iClip = GetEntProp(iTarget, Prop_Send, "m_iClip1");
	SetEntProp(iTarget, Prop_Send, "m_iClip1", iClip+iAmount);
	
	if (flDuration >= 0.0)
		CreateTimer(flDuration, Timer_ResetClip, EntIndexToEntRef(iTarget));
}

public void Tags_SummonZombie(int iClient, int iTarget, TagsParams tParams)
{
	if (iTarget <= 0 || iTarget > MaxClients || !IsClientInGame(iTarget) || !IsPlayerAlive(iTarget))
		return;
	
	int iMax = tParams.GetInt("max");
	int iMin = tParams.GetInt("min");
	int iReduce = tParams.GetInt("reduce");
	
	int iMaxCount = iMax - (iReduce * g_iZombieUsed[iTarget]);
	if (iMaxCount < iMin)
		iMaxCount = iMin;
	
	//Collect list of valid players
	ArrayList aDeadPlayers = GetValidSummonableClients();
	int iLength = aDeadPlayers.Length;
	
	if (iMaxCount > iLength)
		iMaxCount = iLength;
	
	//Loop and summon zombies
	for (int i = 0; i < iMaxCount; i++)
	{
		int iZombie = aDeadPlayers.Get(i);
		SaxtonHaleBase boss = SaxtonHaleBase(iZombie);
		if (boss.bValid)
			boss.DestroyAllClass();
		
		ChangeClientTeam(iZombie, GetClientTeam(iTarget));
		g_iClientOwner[iZombie] = iTarget;
		
		boss.CreateClass("Zombie");
		TF2_RespawnPlayer(iZombie);
		
		TF2_TeleportToClient(iZombie, iTarget);
	}
	
	delete aDeadPlayers;
	g_iZombieUsed[iTarget]++;
}

public void Tags_AddAmmo(int iClient, int iTarget, TagsParams tParams)
{
	if (iTarget <= 0 || !IsValidEdict(iTarget))
		return;
	
	int iAmmoType = GetEntProp(iTarget, Prop_Send, "m_iPrimaryAmmoType");
	if (iAmmoType <= 0)
		return;
	
	//Find slot from given target
	for (int iSlot = 0; iSlot <= WeaponSlot_BuilderEngie; iSlot++)
	{
		if (TF2_GetItemInSlot(iClient, iSlot) == iTarget)
		{
			//Slot found
			int iAmmo = tParams.GetInt("amount") + TF2_GetAmmo(iClient, iAmmoType);	//Primary weapon ammo
			
			int iMaxAmmo;
			if (tParams.GetIntEx("max", iMaxAmmo) && iAmmo > iMaxAmmo)
				iAmmo = iMaxAmmo;
			
			TF2_SetAmmo(iClient, iAmmoType, iAmmo);
			return;
		}
	}
}

public void Tags_AddHealersUber(int iClient, int iTarget, TagsParams tParams)
{
	int[] iClients = new int[MaxClients];
	int iLength = 0;
	
	//Get list of healing clients
	for (int i = 1; i <= MaxClients; i++)
	{
		if (SaxtonHale_IsValidAttack(i) && IsPlayerAlive(i))
		{
			int iMedigun = GetPlayerWeaponSlot(i, WeaponSlot_Secondary);
			if (iMedigun > MaxClients)
			{
				char sClassname[64];
				GetEdictClassname(iMedigun, sClassname, sizeof(sClassname));
				if (StrEqual(sClassname, "tf_weapon_medigun"))
				{
					int iHealTarget = GetEntPropEnt(iMedigun, Prop_Send, "m_hHealingTarget");
					if (iHealTarget == iTarget)
					{
						iClients[iLength] = i;
						iLength++;
					}
				}
			}
		}
	}
	
	if (iLength == 0)	//No healers
		return;
	
	//Split uber amount to each clients
	float flUber = tParams.GetFloat("amount")/float(iLength);
	for (int i = 0; i < iLength; i++)
	{
		int iMedigun = GetPlayerWeaponSlot(iClients[i], WeaponSlot_Secondary);
		float flNewUber = GetEntPropFloat(iMedigun, Prop_Send, "m_flChargeLevel")+flUber;
		if (flNewUber > 1.0) flNewUber = 1.0;
		SetEntPropFloat(iMedigun, Prop_Send, "m_flChargeLevel", flNewUber);
	}
}

public void Tags_Airblast(int iClient, int iTarget, TagsParams tParams)
{
	g_flTagsAirblastCooldown[iClient] = tParams.GetFloat("cooldown", 0.0);
}

public void Tags_Explode(int iClient, int iTarget, TagsParams tParams)
{
	if (iTarget <= 0 || !IsValidEdict(iTarget) || GameRules_GetRoundState() == RoundState_Preround)
		return;
	
	float flDamage = tParams.GetFloat("damage");
	float flRadius = tParams.GetFloat("radius");
	
	//If no particle was specified, pick a generic explosion particle
	char sParticle[MAXLEN_CONFIG_VALUE];
	if (!tParams.GetString("particle", sParticle, sizeof(sParticle)))
		Format(sParticle, sizeof(sParticle), "ExplosionCore_MidAir");
	
	//If no sounds were specified, pick a generic explosion sound. If multiple sounds were specified, pick a random one
	char sSound[MAXLEN_CONFIG_VALUE];
	if (!tParams.GetStringRandom("sound", sSound, sizeof(sSound)))
		Format(sSound, sizeof(sSound), "weapons/airstrike_small_explosion_0%d.wav", GetRandomInt(1, 3));
	
	float vecPos[3];
	GetEntPropVector(iTarget, Prop_Send, "m_vecOrigin", vecPos);
	TF2_Explode(iClient, vecPos, flDamage, flRadius, sParticle, sSound);
}

public void Tags_DestroyEntity(int iClient, int iTarget, TagsParams tParams)
{
	if (iTarget <= 0 || !IsValidEntity(iTarget))
		return;
	
	//Check if target is a weapon
	for (int iSlot = 0; iSlot <= WeaponSlot_BuilderEngie; iSlot++)
	{
		if (TF2_GetItemInSlot(iClient, iSlot) != iTarget)
			continue;
		
		//Has attribute?
		int iAttrib;
		if (tParams.GetIntEx("attrib", iAttrib))
		{
			float flValue;
			TF2_WeaponFindAttribute(iTarget, iAttrib, flValue);
			if (flValue != tParams.GetFloat("value"))
				return;	//Dont remove weapon
		}
		
		//Kill em
		TF2_RemoveItemInSlot(iClient, iSlot);
		
		//Refresh tags stuff now that weapon is crabbed, without clearing any pending function timers
		TagsCore_RefreshClient(iClient, false);
		
		//Check if active weapon need to be switched
		if (GetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon") == INVALID_ENT_REFERENCE)
		{
			for (int i = 0; i <= WeaponSlot_BuilderEngie; i++)
			{
				int iWeapon = TF2_GetItemInSlot(iClient, i);
				if (iWeapon == INVALID_ENT_REFERENCE)
					continue;
				
				if (TF2_SwitchToWeapon(iClient, iWeapon))
					break;	//Switch successful
			}
		}
		
		return;
	}
	
	//Not a weapon, remove as normal
	RemoveEntity(iTarget);
}

public void Tags_ForceSuicide(int iClient, int iTarget, TagsParams tParams)
{
	if (iTarget <= 0 || iTarget > MaxClients || !IsClientInGame(iTarget) || !IsPlayerAlive(iTarget))
		return;
	
	//Pretty straight-forward, isn't it?
	ForcePlayerSuicide(iTarget);
}

public void Tags_Stun(int iClient, int iTarget, TagsParams tParams)
{
	if (iTarget <= 0 || iTarget > MaxClients || !IsClientInGame(iTarget) || !IsPlayerAlive(iTarget))
		return;
	
	float flDuration = tParams.GetFloat("duration");
	float flSlowdown = tParams.GetFloat("slowdown");
	int iStunflags = tParams.GetInt("type", 1);

	TF2_StunPlayer(iTarget, flDuration, flSlowdown, iStunflags);
}
 
public void Tags_MakeBleed(int iClient, int iTarget, TagsParams tParams)
{
	if (iTarget <= 0 || iTarget > MaxClients || !IsClientInGame(iTarget) || !IsPlayerAlive(iTarget))
		return;
	
	TF2_MakeBleed(iTarget, iClient, tParams.GetFloat("duration"));
}

public void Tags_IgnitePlayer(int iClient, int iTarget, TagsParams tParams)
{
	if (iTarget <= 0 || iTarget > MaxClients || !IsClientInGame(iTarget) || !IsPlayerAlive(iTarget))
		return;
	
	TF2_IgnitePlayer(iTarget, iClient, tParams.GetFloat("duration"));
}

public void Tags_DelayNextAttack(int iClient, int iTarget, TagsParams tParams)
{
	if (iTarget <= 0 || !IsValidEdict(iTarget))
		return;
	
	float flTime = GetGameTime() + tParams.GetFloat("seconds");
	
	SetEntPropFloat(iTarget, Prop_Send, "m_flNextPrimaryAttack", flTime);
	SetEntPropFloat(iTarget, Prop_Send, "m_flNextSecondaryAttack", flTime);
}
//---------------------------

public void Frame_AreaOfRange(DataPack data)
{
	data.Reset();
	int iClient = EntRefToEntIndex(data.ReadCell());
	float flDuration = data.ReadFloat();
	float flRadius = data.ReadFloat();
	TFCond cond = data.ReadCell();
	
	if (flDuration > GetGameTime() && IsClientInGame(iClient) && IsPlayerAlive(iClient))
	{
		float vecPos[3], vecTargetPos[3];
		GetClientAbsOrigin(iClient, vecPos);
		TFTeam nTeam = TF2_GetClientTeam(iClient);

		for (int i = 1; i <= MaxClients; i++)
		{
			g_bClientAreaOfEffect[iClient][i] = false;
			
			if (SaxtonHale_IsValidAttack(i) && IsPlayerAlive(i))
			{
				GetClientAbsOrigin(i, vecTargetPos);
				if (GetVectorDistance(vecPos, vecTargetPos) <= flRadius)
				{
					TF2_AddCondition(i, cond, 0.05);
					g_bClientAreaOfEffect[iClient][i] = true;
				}
			}
		}
		
		int iColor[4];
		iColor[3] = 255;
		if (nTeam == TFTeam_Red) iColor[0] = 255;
		else if (nTeam == TFTeam_Blue) iColor[2] = 255;
		
		//Ring effect
		vecPos[2] += 8.0;
		TE_SetupBeamRingPoint(vecPos, flRadius*2.0, (flRadius*2.0)+1.0, g_iSpritesLaserbeam, g_iSpritesGlow, 0, 10, 0.1, 3.0, 0.0, iColor, 10, 0);
		TE_SendToAll();
		
		RequestFrame(Frame_AreaOfRange, data);
	}
	else
	{
		//Duration ended
		delete data;
		
		if (0 < iClient <= MaxClients)
			for (int i = 1; i <= MaxClients; i++)
				g_bClientAreaOfEffect[iClient][i] = false;
	}
}

public Action Timer_ResetClip(Handle hTimer, int iRef)
{
	int iEntity = EntRefToEntIndex(iRef);
	if (iEntity > MaxClients)
	{
		int iMaxClip = SDK_GetMaxClip(iEntity);
		int iCurrentClip = GetEntProp(iEntity, Prop_Send, "m_iClip1");
		if (iCurrentClip > iMaxClip)
			iCurrentClip = iMaxClip;
		
		SetEntProp(iEntity, Prop_Send, "m_iClip1", iCurrentClip);
	}
	
	return Plugin_Continue;
}

public Action Timer_ResetAttrib(Handle hTimer, DataPack data)
{
	data.Reset();
	int iRef = data.ReadCell();
	int iIndex = data.ReadCell();
	
	int iEntity = EntRefToEntIndex(iRef);
	if (iEntity <= 0 || !IsValidEdict(iEntity))
		return Plugin_Continue;
	
	//Check if still exists and outside of time
	int iLength = g_aAttrib.Length;
	for (int iPos = 0; iPos < iLength; iPos++)
	{
		if (g_aAttrib.Get(iPos, TagsAttrib_Ref) == iRef
			&& g_aAttrib.Get(iPos, TagsAttrib_Index) == iIndex
			&& g_aAttrib.Get(iPos, TagsAttrib_Duration) <= GetGameTime() + 0.1)
		{
			//Found with same ref, attrib index and outside of time
			TF2Attrib_RemoveByDefIndex(iEntity, iIndex);
			TF2Attrib_ClearCache(iEntity);
			g_aAttrib.Erase(iPos);
			return Plugin_Continue;
		}
	}
	
	return Plugin_Continue;
}

stock TagsMath Tags_GetMath(const char[] sMath)
{
	if (StrEqual(sMath, "set"))
		return TagsMath_Set;
	else if (StrEqual(sMath, "add"))
		return TagsMath_Add;
	else if (StrEqual(sMath, "multiply"))
		return TagsMath_Multiply;
	else if (StrEqual(sMath, "damage"))
		return TagsMath_Damage;
	
	return TagsMath_Set;
}

stock int Tags_GetBackstabCount(int iClient, int iVictim)
{
	return g_iBackstabCount[iClient][iVictim];
}

stock float Tags_GetAirblastCooldown(int iClient)
{
	return g_flTagsAirblastLastUsed[iClient] + g_flTagsAirblastCooldown[iClient] - GetGameTime();
}
