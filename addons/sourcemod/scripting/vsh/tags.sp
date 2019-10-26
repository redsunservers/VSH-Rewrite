static int g_iBackstabCount[TF_MAXPLAYERS+1][TF_MAXPLAYERS+1];
static int g_iClimbAmount[TF_MAXPLAYERS+1];
static int g_iZombieUsed[TF_MAXPLAYERS+1];

static bool g_bTagsLunchbox[TF_MAXPLAYERS+1];

static int g_iTagsAirblastRequirement[TF_MAXPLAYERS+1];
static int g_iTagsAirblastDamage[TF_MAXPLAYERS+1];

static ArrayList g_aAttrib;	//Arrays of active attribs to be removed later

enum
{
	TagsAttrib_Ref,
	TagsAttrib_Index,
	TagsAttrib_Duration,
	TagsAttrib_MAX,
}

void Tags_ResetClient(int iClient)
{
	if (g_aAttrib == null)
		g_aAttrib = new ArrayList(TagsAttrib_MAX);
	
	g_iClimbAmount[iClient] = 0;
	g_iZombieUsed[iClient] = 0;
	g_iTagsAirblastRequirement[iClient] = -1;
	g_iTagsAirblastDamage[iClient] = 0;
	
	for (int iVictim = 1; iVictim <= MaxClients; iVictim++)
		g_iBackstabCount[iClient][iVictim] = 0;
	
	Hud_SetRageView(iClient, false);
}

void Tags_OnThink(int iClient)
{
	TagsCore_CallAll(iClient, TagsCall_Think);
	
	if (GetEntityFlags(iClient) & FL_ONGROUND)
		g_iClimbAmount[iClient] = 0;
	
	if (g_iTagsAirblastRequirement[iClient] >= 0)
	{
		//Detect if airblast is used
		int iPrimary = TF2_GetItemInSlot(iClient, WeaponSlot_Primary);
		if (iPrimary > MaxClients)
		{
			if (g_iTagsAirblastDamage[iClient] >= g_iTagsAirblastRequirement[iClient] && GetEntPropFloat(iPrimary, Prop_Send, "m_flNextSecondaryAttack") > GetGameTime())
			{
				g_iTagsAirblastDamage[iClient] = 0;	//Reset damage
				SetEntPropFloat(iPrimary, Prop_Send, "m_flNextSecondaryAttack", 31536000.0+GetGameTime());	//3 years
			}
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
				int iAmmo = GetEntProp(iClient, Prop_Send, "m_iAmmo", 4, iAmmoType);
				
				if (iAmmo == 1)
				{
					g_bTagsLunchbox[iClient] = false;
				}
				if (iAmmo == 0 && !g_bTagsLunchbox[iClient])
				{
					g_bTagsLunchbox[iClient] = true;
					TagsCore_CallAll(iClient, TagsCall_Lunchbox);
				}
			}
		}
	}
}

void Tags_OnPlayerHurt(int iVictim, int iAttacker, int iDamage)
{
	if (SaxtonHale_IsValidBoss(iVictim) && SaxtonHale_IsValidAttack(iAttacker))
	{
		if (g_iTagsAirblastRequirement[iAttacker] >= 0)
		{
			g_iTagsAirblastDamage[iAttacker] += iDamage;
			
			if (g_iTagsAirblastDamage[iAttacker] >= g_iTagsAirblastRequirement[iAttacker])
			{
				g_iTagsAirblastDamage[iAttacker] = g_iTagsAirblastRequirement[iAttacker];
				
				int iPrimary = TF2_GetItemInSlot(iAttacker, WeaponSlot_Primary);
				if (iPrimary > MaxClients)
					SetEntPropFloat(iPrimary, Prop_Send, "m_flNextSecondaryAttack", 0.0);	//Allow airblast to be used
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
	
	if (StrEqual(sType, "int"))
	{
		int iValue = tParams.GetInt("value");
		
		if (StrEqual(sMath, "add"))
			iValue += GetEntProp(iTarget, Prop_Send, sProp);
		else if (StrEqual(sMath, "multiply"))
			iValue *= GetEntProp(iTarget, Prop_Send, sProp);
		else if (StrEqual(sMath, "damage"))
			iValue = RoundToFloor(float(g_iPlayerDamage[iClient]) / float(iValue));
		
		int iMin, iMax;
		if (tParams.GetIntEx("min", iMin) && iValue < iMin) iValue = iMin;
		if (tParams.GetIntEx("max", iMax) && iValue > iMax) iValue = iMax;
		
		SetEntProp(iTarget, Prop_Send, sProp, iValue);
	}
	else if (StrEqual(sType, "float"))
	{
		float flValue = tParams.GetFloat("value");
		
		if (StrEqual(sMath, "add"))
			flValue += GetEntPropFloat(iTarget, Prop_Send, sProp);
		else if (StrEqual(sMath, "multiply"))
			flValue *= GetEntPropFloat(iTarget, Prop_Send, sProp);
		else if (StrEqual(sMath, "damage"))
			flValue = float(g_iPlayerDamage[iClient]) / flValue;
		
		float flMin, flMax;
		if (tParams.GetFloatEx("min", flMin) && flValue < flMin) flValue = flMin;
		if (tParams.GetFloatEx("max", flMax) && flValue > flMax) flValue = flMax;
		
		SetEntPropFloat(iTarget, Prop_Send, sProp, flValue);
	}
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
	if (boss.flGlowTime < flGlowTime)
		boss.flGlowTime = flGlowTime;
}

public void Tags_Climb(int iClient, int iTarget, TagsParams tParams)
{
	if (iTarget <= 0 || iTarget > MaxClients || !IsClientInGame(iTarget) || !IsPlayerAlive(iTarget))
		return;
	
	float flHeight = tParams.GetFloat("height");
	int iMax = tParams.GetInt("max");
	float flDamage = tParams.GetFloat("selfdamage");
	
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
	Client_AddHealth(iTarget, iAmount, iAmount);
}

public void Tags_AddHealthBase(int iClient, int iTarget, TagsParams tParams)
{
	if (iTarget <= 0 || iTarget > MaxClients || !IsClientInGame(iTarget) || !IsPlayerAlive(iTarget))
		return;
	
	float flAmount = tParams.GetFloat("amount");
	int iMaxHealth = SDK_GetMaxHealth(iTarget);
	
	Client_AddHealth(iTarget, RoundToNearest(float(iMaxHealth) * flAmount), RoundToNearest(float(iMaxHealth) * 0.5));
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
	
	int iAmount = tParams.GetInt("amount");
	SaxtonHaleBase boss = SaxtonHaleBase(iClient);
	boss.CallFunction("AddRage", -iAmount);
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
	int[] iDeadPlayers = new int[MaxClients];
	int iLength = 0;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i)
			&& GetClientTeam(i) > 1
			&& !IsPlayerAlive(i)
			&& Preferences_Get(i, halePreferences_Revival)
			&& !Client_HasFlag(i, haleClientFlags_Punishment)
			&& (!SaxtonHale_IsValidBoss(i, false)))
		{
			iDeadPlayers[iLength] = i;
			iLength++;
		}
	}
	
	//Sort random
	SortIntegers(iDeadPlayers, iLength, Sort_Random);
	if (iMaxCount > iLength)
		iMaxCount = iLength;
	
	//Loop and summon zombies
	for (int i = 0; i < iMaxCount; i++)
	{
		int iZombie = iDeadPlayers[i];
		SaxtonHaleBase boss = SaxtonHaleBase(iZombie);
		if (boss.bValid)
			boss.CallFunction("Destroy");
		
		ChangeClientTeam(iZombie, GetClientTeam(iTarget));
		g_iClientOwner[iZombie] = iTarget;
		
		boss.CallFunction("CreateBoss", "CZombie");
		TF2_RespawnPlayer(iZombie);
		
		float vecPos[3];
		GetClientAbsOrigin(iTarget, vecPos);
		TeleportEntity(iZombie, vecPos, NULL_VECTOR, NULL_VECTOR);
		
		if (GetEntProp(iTarget, Prop_Send, "m_bDucking") || GetEntProp(iTarget, Prop_Send, "m_bDucked"))
		{
			SetEntProp(iZombie, Prop_Send, "m_bDucking", true);
			SetEntProp(iZombie, Prop_Send, "m_bDucked", true);
			SetEntityFlags(iZombie, GetEntityFlags(iZombie)|FL_DUCKING);
		}
	}
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
			int iAmmo = tParams.GetInt("amount") + GetEntProp(iClient, Prop_Send, "m_iAmmo", 4, iAmmoType);	//Primary weapon ammo
			
			int iMaxAmmo;
			if (tParams.GetIntEx("max", iMaxAmmo) && iAmmo > iMaxAmmo)
				iAmmo = iMaxAmmo;
			
			SetEntProp(iClient, Prop_Send, "m_iAmmo", iAmmo, 4, iAmmoType);
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
	g_iTagsAirblastRequirement[iClient] = tParams.GetInt("damage", -1);
	SetEntPropFloat(iTarget, Prop_Send, "m_flNextSecondaryAttack", 31536000.0+GetGameTime());	//3 years
}

public void Tags_Explode(int iClient, int iTarget, TagsParams tParams)
{
	if (iTarget <= 0 || !IsValidEdict(iTarget))
		return;
	
	float flDamage = tParams.GetFloat("damage");
	float flRadius = tParams.GetFloat("radius");
	
	float vecPos[3];
	GetEntPropVector(iTarget, Prop_Send, "m_vecOrigin", vecPos);
	char sSound[255];
	Format(sSound, sizeof(sSound), "weapons/airstrike_small_explosion_0%i.wav", GetRandomInt(1,3));
	TF2_Explode(iClient, vecPos, flDamage, flRadius, "ExplosionCore_MidAir", sSound);
}

public void Tags_KillWeapon(int iClient, int iTarget, TagsParams tParams)
{
	//Find slot from given target
	for (int iSlot = 0; iSlot <= WeaponSlot_BuilderEngie; iSlot++)
	{
		if (TF2_GetItemInSlot(iClient, iSlot) == iTarget)
		{
			//Kill em
			TF2_RemoveItemInSlot(iClient, iSlot);
			
			//Refresh tags stuff now that weapon is crabbed, without clearing any pending function timers
			TagsCore_RefreshClient(iClient, false);
			return;
		}
	}
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
		int iTeam = GetClientTeam(iClient);

		for (int i = 1; i <= MaxClients; i++)
		{
			if (SaxtonHale_IsValidAttack(i) && IsPlayerAlive(i))
			{
				GetClientAbsOrigin(i, vecTargetPos);
				if (GetVectorDistance(vecPos, vecTargetPos) <= flRadius)
				{
					if (view_as<int>(cond) >= 0)
						TF2_AddCondition(i, cond, 0.05);
				}
			}
		}
		
		int iColor[4];
		iColor[3] = 255;
		if (iTeam == TFTeam_Red) iColor[0] = 255;
		else if (iTeam == TFTeam_Blue) iColor[2] = 255;
		
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
}

public Action Timer_ResetAttrib(Handle hTimer, DataPack data)
{
	data.Reset();
	int iRef = data.ReadCell();
	int iIndex = data.ReadCell();
	
	int iEntity = EntRefToEntIndex(iRef);
	if (iEntity <= 0 || !IsValidEdict(iEntity))
		return;
	
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
			return;
		}
	}
}

stock int Tags_GetBackstabCount(int iClient, int iVictim)
{
	return g_iBackstabCount[iClient][iVictim];
}

stock float Tags_GetAirblastPercentage(int iClient)
{
	if (g_iTagsAirblastRequirement[iClient] < 0)
		return -1.0;
	
	return float(g_iTagsAirblastDamage[iClient]) / float(g_iTagsAirblastRequirement[iClient]);
}