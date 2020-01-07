stock void Client_AddHealth(int iClient, int iAdditionalHeal, int iMaxOverHeal=0)
{
	int iMaxHealth = SDK_GetMaxHealth(iClient);
	int iHealth = GetEntProp(iClient, Prop_Send, "m_iHealth");
	int iTrueMaxHealth = iMaxHealth+iMaxOverHeal;

	if (iHealth < iTrueMaxHealth)
	{
		iHealth += iAdditionalHeal;
		if (iHealth > iTrueMaxHealth) iHealth = iTrueMaxHealth;
		SetEntProp(iClient, Prop_Send, "m_iHealth", iHealth);
	}
}

stock void Client_AddFlag(int iClient, ClientFlags flag)
{
	g_iClientFlags[iClient] |= view_as<int>(flag);
}

stock void Client_RemoveFlag(int iClient, ClientFlags flag)
{
	g_iClientFlags[iClient] &= ~view_as<int>(flag);
}

stock bool Client_HasFlag(int iClient, ClientFlags flag)
{
	return !!(g_iClientFlags[iClient] & view_as<int>(flag));
}

stock int Client_GetEyeTarget(int iClient)
{
	float vecPos[3], vecAng[3];
	GetClientEyePosition(iClient, vecPos);
	GetClientEyeAngles(iClient, vecAng);
	
	Handle hTrace = TR_TraceRayFilterEx(vecPos, vecAng, MASK_PLAYERSOLID, RayType_Infinite, TraceRay_DontHitEntity, iClient);
	int iHit = TR_GetEntityIndex(hTrace);
	delete hTrace;
	
	return iHit;
}

stock bool TraceRay_DontHitEntity(int iEntity, int contentsMask, int data)
{
	if (iEntity == data) return false;

	return true;
}

stock bool TraceRay_DontHitPlayers(int entity, int mask, any data)
{
	if (entity > 0 && entity <= MaxClients) return false;
	return true;
}

stock int GetMainBoss()
{
	int iBoss = 0;
	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if (SaxtonHale_IsValidBoss(iClient, false))
		{
			if (iBoss != 0) return 0;	//If more than 1 boss active, return 0
			iBoss = iClient;
		}
	}
	
	return iBoss;
}

stock ArrayList GetValidSummonableClients(bool bAllowBoss = false)
{
	ArrayList aClients = new ArrayList();
	
	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if (IsClientInGame(iClient)
			&& TF2_GetClientTeam(iClient) > TFTeam_Spectator
			&& !IsPlayerAlive(iClient)
			&& Preferences_Get(iClient, Preferences_Revival)
			&& !Client_HasFlag(iClient, ClientFlags_Punishment))
		{
			if (!bAllowBoss)
				if (SaxtonHale_IsValidBoss(iClient, false)) continue;
				
			aClients.Push(iClient);
		}
	}
	
	aClients.Sort(Sort_Random, Sort_Integer);
	
	return aClients;
}

stock void TF2_ForceTeamJoin(int iClient, TFTeam nTeam)
{
	TFClassType nClass = TF2_GetPlayerClass(iClient);
	if (nClass == TFClass_Unknown)
	{
		// Player hasn't chosen a class. Choose one for him.
		TF2_SetPlayerClass(iClient, view_as<TFClassType>(GetRandomInt(1, 9)), true, true);
	}

	SetEntProp(iClient, Prop_Send, "m_lifeState", LifeState_Dead);
	TF2_ChangeClientTeam(iClient, nTeam);
	SetEntProp(iClient, Prop_Send, "m_lifeState", LifeState_Alive);

	TF2_RespawnPlayer(iClient);
}

stock int TF2_CreateGlow(int iEnt, int iColor[4])
{
	char oldEntName[64];
	GetEntPropString(iEnt, Prop_Data, "m_iName", oldEntName, sizeof(oldEntName));

	char strName[126], strClass[64];
	GetEntityClassname(iEnt, strClass, sizeof(strClass));
	Format(strName, sizeof(strName), "%s%i", strClass, iEnt);
	DispatchKeyValue(iEnt, "targetname", strName);

	int ent = CreateEntityByName("tf_glow");
	DispatchKeyValue(ent, "targetname", "entity_glow");
	DispatchKeyValue(ent, "target", strName);
	DispatchKeyValue(ent, "Mode", "0");
	DispatchSpawn(ent);

	AcceptEntityInput(ent, "Enable");
	SetEntPropString(iEnt, Prop_Data, "m_iName", oldEntName);

	SetVariantColor(iColor);
	AcceptEntityInput(ent, "SetGlowColor");

	SetVariantString("!activator");
	AcceptEntityInput(ent, "SetParent", iEnt);

	return ent;
}

stock bool TF2_FindAttribute(int iEntity, int iAttrib, float &flVal)
{
	Address addAttrib = TF2Attrib_GetByDefIndex(iEntity, iAttrib);
	if (addAttrib != Address_Null)
	{
		flVal = TF2Attrib_GetValue(addAttrib);
		return true;
	}
	return false;
}

stock bool TF2_WeaponFindAttribute(int iWeapon, int iAttrib, float &flVal)
{
	Address addAttrib = TF2Attrib_GetByDefIndex(iWeapon, iAttrib);
	if (addAttrib == Address_Null)
	{
		int iItemDefIndex = GetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex");
		int iAttributes[16];
		float flAttribValues[16];

		int iMaxAttrib = TF2Attrib_GetStaticAttribs(iItemDefIndex, iAttributes, flAttribValues);
		for (int i = 0; i < iMaxAttrib; i++)
		{
			if (iAttributes[i] == iAttrib)
			{
				flVal = flAttribValues[i];
				return true;
			}
		}
		return false;
	}
	flVal = TF2Attrib_GetValue(addAttrib);
	return true;
}

stock void TF2_AddAttributeStack(int iClient, int iAttrib, float flAddVal)
{
	float flVal = 1.0;
	if (TF2_FindAttribute(iClient, iAttrib, flVal))
		TF2Attrib_RemoveByDefIndex(iClient, iAttrib);

	if ((flVal + flAddVal) != 1.0)
		TF2Attrib_SetByDefIndex(iClient, iAttrib, (flVal + flAddVal));

	TF2Attrib_ClearCache(iClient);
}

stock bool TF2_IsUbercharged(int iClient)
{
	return (TF2_IsPlayerInCondition(iClient, TFCond_Ubercharged) ||
		TF2_IsPlayerInCondition(iClient, TFCond_UberchargedHidden) ||
		TF2_IsPlayerInCondition(iClient, TFCond_UberchargedOnTakeDamage) ||
		TF2_IsPlayerInCondition(iClient, TFCond_UberchargedCanteen));
}

stock bool TF2_IsForceCrit(int iClient)
{
	return (TF2_IsPlayerInCondition(iClient, TFCond_HalloweenCritCandy) ||
		TF2_IsPlayerInCondition(iClient, TFCond_CritCanteen) ||
		TF2_IsPlayerInCondition(iClient, TFCond_CritDemoCharge) ||
		TF2_IsPlayerInCondition(iClient, TFCond_CritOnFirstBlood) ||
		TF2_IsPlayerInCondition(iClient, TFCond_CritOnWin) ||
		TF2_IsPlayerInCondition(iClient, TFCond_CritOnFlagCapture) ||
		TF2_IsPlayerInCondition(iClient, TFCond_CritOnKill) ||
		TF2_IsPlayerInCondition(iClient, TFCond_CritMmmph) ||
		TF2_IsPlayerInCondition(iClient, TFCond_CritOnDamage) ||
		TF2_IsPlayerInCondition(iClient, TFCond_CritRuneTemp));
}

stock TFClassType TF2_GetClassType(const char[] sClass)
{
	for (int iClass = 1; iClass < sizeof(g_strClassName); iClass++)
	{
		if (StrContains(g_strClassName[iClass], sClass, false) != -1)
			return view_as<TFClassType>(iClass);
		
		if (StrContains(sClass, g_strClassName[iClass], false) != -1)
			return view_as<TFClassType>(iClass);
	}
	
	return TFClass_Unknown;
}

stock int TF2_GetSlotFromWeapon(int iWeapon)
{
	if (iWeapon <= MaxClients) return -1;
	
	int iClient = GetEntPropEnt(iWeapon, Prop_Send, "m_hOwnerEntity");
	for (int iSlot = 0; iSlot <= WeaponSlot_BuilderEngie; iSlot++)
		if (TF2_GetItemInSlot(iClient, iSlot) == iWeapon)
			return iSlot;
	
	return -1;
}

stock int TF2_GetItemSlot(int iIndex, TFClassType nClass)
{
	int iSlot = TF2Econ_GetItemSlot(iIndex, nClass);
	if (iSlot >= 0)
	{
		// Econ reports wrong slots for Engineer and Spy
		switch (nClass)
		{
			case TFClass_Engineer:
			{
				switch (iSlot)
				{
					case 4: iSlot = WeaponSlot_BuilderEngie; // Toolbox
					case 5: iSlot = WeaponSlot_PDABuild; // Construction PDA
					case 6: iSlot = WeaponSlot_PDADestroy; // Destruction PDA
				}
			}
			case TFClass_Spy:
			{
				switch (iSlot)
				{
					case 1: iSlot = WeaponSlot_Primary; // Revolver
					case 4: iSlot = WeaponSlot_Secondary; // Sapper
					case 5: iSlot = WeaponSlot_PDADisguise; // Disguise Kit
					case 6: iSlot = WeaponSlot_InvisWatch; // Invis Watch
				}
			}
		}
	}
	
	return iSlot;
}

stock int TF2_GetItemInSlot(int iClient, int iSlot)
{
	int iWeapon = GetPlayerWeaponSlot(iClient, iSlot);
	if (!IsValidEdict(iWeapon))
	{
		//If weapon not found in slot, check if it a wearable
		int iWearable = SDK_GetEquippedWearable(iClient, iSlot);
		if (IsValidEdict(iWearable))
			iWeapon = iWearable;
	}
	
	return iWeapon;
}

stock void TF2_RemoveItemInSlot(int client, int slot)
{
	TF2_RemoveWeaponSlot(client, slot);

	int iWearable = SDK_GetEquippedWearable(client, slot);
	if (iWearable > MaxClients)
	{
		SDK_RemoveWearable(client, iWearable);
		AcceptEntityInput(iWearable, "Kill");
	}
}

stock int TF2_GetAmmo(int iClient, int iSlot)
{
	int iWeapon = GetPlayerWeaponSlot(iClient, iSlot);
	if (iWeapon > MaxClients)
	{
		int iAmmoType = GetEntProp(iWeapon, Prop_Send, "m_iPrimaryAmmoType");
		if (iAmmoType > -1)
			return GetEntProp(iClient, Prop_Send, "m_iAmmo", _, iAmmoType);
	}
	
	return -1;
}

stock void TF2_SetAmmo(int iClient, int iSlot, int iAmmo)
{
	int iWeapon = GetPlayerWeaponSlot(iClient, iSlot);
	if (iWeapon > MaxClients)
	{
		int iAmmoType = GetEntProp(iWeapon, Prop_Send, "m_iPrimaryAmmoType");
		if (iAmmoType > -1)
			SetEntProp(iClient, Prop_Send, "m_iAmmo", iAmmo, _, iAmmoType);
	}
}

stock int TF2_GetPatient(int iClient)
{
	if (iClient <= 0 || iClient > MaxClients || !IsClientInGame(iClient) || !IsPlayerAlive(iClient))
		return -1;
	
	int iWeapon = TF2_GetItemInSlot(iClient, WeaponSlot_Secondary);
	if (!IsValidEdict(iWeapon))
		return -1;
			
	char sClassname[256];
	GetEntityClassname(iWeapon, sClassname, sizeof(sClassname));
	if (!StrEqual(sClassname, "tf_weapon_medigun"))
		return -1;
	
	return GetEntPropEnt(iWeapon, Prop_Send, "m_hHealingTarget");
}

stock int TF2_GetBuilding(int iClient, TFObjectType nType, TFObjectMode nMode = TFObjectMode_None)
{
	int iBuilding = MaxClients+1;
	while ((iBuilding = FindEntityByClassname(iBuilding, "obj_*")) > MaxClients)
	{
		if (GetEntPropEnt(iBuilding, Prop_Send, "m_hBuilder") == iClient
			&& view_as<TFObjectType>(GetEntProp(iBuilding, Prop_Send, "m_iObjectType")) == nType
			&& view_as<TFObjectMode>(GetEntProp(iBuilding, Prop_Send, "m_iObjectMode")) == nMode)
		{
			return iBuilding;
		}
	}
	
	return -1;
}

stock void TF2_StunBuilding(int iBuilding, float flDuration)
{
	SetEntProp(iBuilding, Prop_Send, "m_bDisabled", true);
	CreateTimer(flDuration, Timer_EnableBuilding, EntIndexToEntRef(iBuilding));
}

public Action Timer_EnableBuilding(Handle timer, int iRef)
{
	int iBuilding = EntRefToEntIndex(iRef);
	if (iBuilding > MaxClients)
		SetEntProp(iBuilding, Prop_Send, "m_bDisabled", false);
}

stock int TF2_CreateAndEquipWeapon(int iClient, int iIndex, char[] sClassnameTemp = NULL_STRING, int iLevel = 0, TFQuality iQuality = TFQual_Normal, char[] sAttrib = NULL_STRING, bool bAttrib = false)
{
	char sClassname[256];
	if (StrEmpty(sClassnameTemp))
		TF2Econ_GetItemClassName(iIndex, sClassname, sizeof(sClassname));
	else
		strcopy(sClassname, sizeof(sClassname), sClassnameTemp);
	
	int iWeapon = CreateEntityByName(sClassname);
	
	if (IsValidEntity(iWeapon))
	{
		SetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex", iIndex);
		SetEntProp(iWeapon, Prop_Send, "m_bInitialized", 1);
		SetEntProp(iWeapon, Prop_Send, "m_bOnlyIterateItemViewAttributes", !bAttrib);	//Whenever if weapon should have default attribs or not
		
		//Allow quality / level override by updating through the offset.
		char sNetClass[64];
		GetEntityNetClass(iWeapon, sNetClass, sizeof(sNetClass));
		SetEntData(iWeapon, FindSendPropInfo(sNetClass, "m_iEntityQuality"), iQuality);
		SetEntData(iWeapon, FindSendPropInfo(sNetClass, "m_iEntityLevel"), iLevel);
		
		SetEntProp(iWeapon, Prop_Send, "m_iEntityQuality", iQuality);
		SetEntProp(iWeapon, Prop_Send, "m_iEntityLevel", iLevel);
		
		DispatchSpawn(iWeapon);
		SetEntProp(iWeapon, Prop_Send, "m_bValidatedAttachedEntity", true);
		
		if (StrContains(sClassname, "tf_wearable") == 0)
		{
			SDK_EquipWearable(iClient, iWeapon);
		}
		else
		{
			EquipPlayerWeapon(iClient, iWeapon);
			
			//Make sure max ammo is set correctly
			int iSlot = TF2_GetItemSlot(iIndex, TF2_GetPlayerClass(iClient));
			int iMaxAmmo = SDK_GetMaxAmmo(iClient, iSlot);
			int iAmmoType = GetEntProp(iWeapon, Prop_Send, "m_iPrimaryAmmoType");
			
			if (iMaxAmmo > 0 && iAmmoType > -1)
				SetEntProp(iClient, Prop_Send, "m_iAmmo", iMaxAmmo, 4, iAmmoType);
		}
		
		char atts[32][32];
		int count = ExplodeString(sAttrib, " ; ", atts, 32, 32);
		if (count > 1)
		{
			for (int j = 0; j < count; j+= 2)
				TF2Attrib_SetByDefIndex(iWeapon, StringToInt(atts[j]), StringToFloat(atts[j+1]));

			TF2Attrib_ClearCache(iWeapon);
		}
	}
	
	return iWeapon;
}

stock int TF2_GetObjectiveResource()
{
	static int iRefObj = 0;
	
	if (iRefObj != 0)
	{
		int iObj = EntRefToEntIndex(iRefObj);
		if (iObj > MaxClients)
			return iObj;
		
		iRefObj = 0;
	}
	
	int iObj = FindEntityByClassname(MaxClients+1, "tf_objective_resource");
	if (iObj > MaxClients)
		iRefObj = EntIndexToEntRef(iObj);
	
	return iObj;
}

stock void CheckForceAttackWin(int iVictim=0)
{
	//Check if all main bosses died while minions still alive, if so force make round end
	int iBossCount = 0;
	int iMinionCount = 0;
	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if (iClient != iVictim && IsClientInGame(iClient) && IsPlayerAlive(iClient) && TF2_GetClientTeam(iClient) == TFTeam_Boss)
		{
			if (SaxtonHale_IsValidBoss(iClient, false))
				iBossCount++;
			else
				iMinionCount++;
		}
	}
	
	if (iBossCount == 0 && iMinionCount > 0)
	{
		int iRoundWin = CreateEntityByName("game_round_win"); 
		DispatchSpawn(iRoundWin);
		
		SetVariantString("force_map_reset 1");
		AcceptEntityInput(iRoundWin, "AddOutput");
		SetVariantInt(view_as<int>(TFTeam_Attack));
		AcceptEntityInput(iRoundWin, "SetTeam");
		AcceptEntityInput(iRoundWin, "RoundWin");
	}
}

stock void TF2_Explode(int iAttacker = -1, float flPos[3], float flDamage, float flRadius, const char[] strParticle, const char[] strSound)
{
	int iBomb = CreateEntityByName("tf_generic_bomb");
	DispatchKeyValueVector(iBomb, "origin", flPos);
	DispatchKeyValueFloat(iBomb, "damage", flDamage);
	DispatchKeyValueFloat(iBomb, "radius", flRadius);
	DispatchKeyValue(iBomb, "health", "1");
	DispatchKeyValue(iBomb, "explode_particle", strParticle);
	DispatchKeyValue(iBomb, "sound", strSound);
	DispatchSpawn(iBomb);

	if (iAttacker == -1)
		AcceptEntityInput(iBomb, "Detonate");
	else
		SDKHooks_TakeDamage(iBomb, 0, iAttacker, 9999.0);
}

stock void TF2_Shake(float vecOrigin[3], float flAmplitude, float flRadius, float flDuration, float flFrequency)
{
	int iShake = CreateEntityByName("env_shake");
	if (iShake != -1)
	{
		DispatchKeyValueVector(iShake, "origin", vecOrigin);
		DispatchKeyValueFloat(iShake, "amplitude", flAmplitude);
		DispatchKeyValueFloat(iShake, "radius", flRadius);
		DispatchKeyValueFloat(iShake, "duration", flDuration);
		DispatchKeyValueFloat(iShake, "frequency", flFrequency);
		
		DispatchSpawn(iShake);
		AcceptEntityInput(iShake, "StartShake");
		RemoveEntity(iShake);
	}
}

stock int TF2_SpawnParticle(char[] sParticle, float vecOrigin[3] = NULL_VECTOR, float flAngles[3] = NULL_VECTOR, bool bActivate = true, int iEntity = 0, int iControlPoint = 0)
{
	int iParticle = CreateEntityByName("info_particle_system");
	TeleportEntity(iParticle, vecOrigin, flAngles, NULL_VECTOR);
	DispatchKeyValue(iParticle, "effect_name", sParticle);
	DispatchSpawn(iParticle);
	
	if (0 < iEntity && IsValidEntity(iEntity))
	{
		SetVariantString("!activator");
		AcceptEntityInput(iParticle, "SetParent", iEntity);
	}
	
	if (0 < iControlPoint && IsValidEntity(iControlPoint))
	{
		//Array netprop, but really only need element 0 anyway
		SetEntPropEnt(iParticle, Prop_Send, "m_hControlPointEnts", iControlPoint, 0);
		SetEntProp(iParticle, Prop_Send, "m_iControlPointParents", iControlPoint, _, 0);
	}
	
	if (bActivate)
	{
		ActivateEntity(iParticle);
		AcceptEntityInput(iParticle, "Start");
	}
	
	//Return ref of entity
	return EntIndexToEntRef(iParticle);
}

stock void TF2_TeleportToClient(int iClient, int iTarget)
{
	if (iClient <= 0 || iClient > MaxClients || !IsClientInGame(iClient) || !IsPlayerAlive(iClient))
		return;
	if (iTarget <= 0 || iTarget > MaxClients || !IsClientInGame(iTarget) || !IsPlayerAlive(iTarget))
		return;
	
	float vecTargetPos[3], vecTargetAng[3];
	GetClientAbsOrigin(iTarget, vecTargetPos);
	GetClientAbsAngles(iTarget, vecTargetAng);
	vecTargetAng[0] = 0.0;
	vecTargetAng[2] = 0.0;
	
	TeleportEntity(iClient, vecTargetPos, vecTargetAng, NULL_VECTOR);
	
	//Force whoever was teleported to crouch if its target was crouching, to prevent them from getting stuck
	if (GetEntProp(iTarget, Prop_Send, "m_bDucking") || GetEntProp(iTarget, Prop_Send, "m_bDucked"))
	{
		SetEntProp(iClient, Prop_Send, "m_bDucking", true);
		SetEntProp(iClient, Prop_Send, "m_bDucked", true);
		SetEntityFlags(iClient, GetEntityFlags(iClient)|FL_DUCKING);
	}
}

stock void TF2_TeleportSwap(int iClient[2])
{
	float vecOrigin[2][3];
	float vecAngles[2][3];
	float vecVel[2][3];
	
	for (int i = 0; i <= 1; i++)
	{
		//Remove Sniper scope before teleporting, otherwise huge server hang can happen
		if (TF2_IsPlayerInCondition(iClient[i], TFCond_Zoomed)) TF2_RemoveCondition(iClient[i], TFCond_Zoomed);
		if (TF2_IsPlayerInCondition(iClient[i], TFCond_Slowed)) TF2_RemoveCondition(iClient[i], TFCond_Slowed);
		
		//Get its origin, angles and vel
		GetClientAbsOrigin(iClient[i], vecOrigin[i]);
		GetClientAbsAngles(iClient[i], vecAngles[i]);
		GetEntPropVector(iClient[i], Prop_Data, "m_vecVelocity", vecVel[i]);
		
		//Create particle
		CreateTimer(3.0, Timer_EntityCleanup, TF2_SpawnParticle(PARTICLE_GHOST, vecOrigin[i], vecAngles[i]));
	}
	
	for (int i = 0; i <= 1; i++)
	{
		int j = ((i == 1) ? 0 : 1);
		
		TeleportEntity(iClient[j], vecOrigin[i], vecAngles[i], vecVel[i]);
		
		if (GetEntProp(iClient[i], Prop_Send, "m_bDucking") || GetEntProp(iClient[i], Prop_Send, "m_bDucked"))
		{
			SetEntProp(iClient[j], Prop_Send, "m_bDucking", true);
			SetEntProp(iClient[j], Prop_Send, "m_bDucked", true);
			SetEntityFlags(iClient[j], GetEntityFlags(iClient[j])|FL_DUCKING);
		}
	}
}

stock int TF2_CreateLightEntity(float flRadius, int iColor[4], int iBrightness)
{
	int iGlow = CreateEntityByName("light_dynamic");
	if (iGlow != -1)
	{			
		char sLigthColor[60];
		Format(sLigthColor, sizeof(sLigthColor), "%i %i %i", iColor[0], iColor[1], iColor[2]);
		DispatchKeyValue(iGlow, "rendercolor", sLigthColor);
		
		SetVariantFloat(flRadius);
		AcceptEntityInput(iGlow, "spotlight_radius");
		
		SetVariantFloat(flRadius);
		AcceptEntityInput(iGlow, "distance");
		
		SetVariantInt(iBrightness);
		AcceptEntityInput(iGlow, "brightness");
		
		SetVariantInt(1);
		AcceptEntityInput(iGlow, "cone");
		
		DispatchSpawn(iGlow);
		
		ActivateEntity(iGlow);
		AcceptEntityInput(iGlow, "TurnOn");
		SetEntityRenderFx(iGlow, RENDERFX_SOLID_SLOW);
		SetEntityRenderColor(iGlow, iColor[0], iColor[1], iColor[2], iColor[3]);
		
		int iFlags = GetEdictFlags(iGlow);
		if (!(iFlags & FL_EDICT_ALWAYS))
		{
			iFlags |= FL_EDICT_ALWAYS;
			SetEdictFlags(iGlow, iFlags);
		}
	}
	
	return iGlow;
}

stock bool EmitGameSoundToTeam(TFTeam nTeam,
				const char[] gameSound,
				int entity = SOUND_FROM_PLAYER,
				int flags = SND_NOFLAGS,
				int speakerentity = -1,
				const float origin[3] = NULL_VECTOR,
				const float dir[3] = NULL_VECTOR,
				bool updatePos = true,
				float soundtime = 0.0)
{
	int[] iClients = new int[MaxClients];
	int iTotal = 0;

	for (int iClient = 1; iClient <= MaxClients; iClient++)
		if (IsClientInGame(iClient) && TF2_GetClientTeam(iClient) == nTeam)
			iClients[iTotal++] = iClient;
	
	if (!iTotal)
		return false;
	
	return EmitGameSound(iClients, iTotal, gameSound, entity, flags, speakerentity, origin, dir, updatePos, soundtime);
}

stock void BroadcastSoundToTeam(TFTeam nTeam, const char[] strSound)
{
	switch (nTeam)
	{
		case TFTeam_Red, TFTeam_Blue:
		{
			for (int iClient = 1; iClient <= MaxClients; iClient++)
				if (IsClientInGame(iClient) && !IsFakeClient(iClient) && TF2_GetClientTeam(iClient) == nTeam)
					ClientCommand(iClient, "playgamesound %s", strSound);
		}
		default:
		{
			for (int iClient = 1; iClient <= MaxClients; iClient++)
				if(IsClientInGame(iClient) && !IsFakeClient(iClient))
					ClientCommand(iClient, "playgamesound %s", strSound);
		}
	}
}

stock bool StrEmpty(char[] sBuffer)
{
	return sBuffer[0] == '\0';
}

stock void StrToLower(char[] sBuffer)
{
	int iLength = strlen(sBuffer);
	for (int i = 0; i < iLength; i++)
		sBuffer[i] = CharToLower(sBuffer[i]);
}

stock void PrepareSound(const char[] sSoundPath)
{
	PrecacheSound(sSoundPath, true);
	char s[PLATFORM_MAX_PATH];
	Format(s, sizeof(s), "sound/%s", sSoundPath);
	AddFileToDownloadsTable(s);
}

stock int PrecacheParticleSystem(const char[] particleSystem)
{
	static int particleEffectNames = INVALID_STRING_TABLE;
	if (particleEffectNames == INVALID_STRING_TABLE)
	{
		if ((particleEffectNames = FindStringTable("ParticleEffectNames")) == INVALID_STRING_TABLE)
		{
			return INVALID_STRING_INDEX;
		}
	}

	int index = FindStringIndex2(particleEffectNames, particleSystem);
	if (index == INVALID_STRING_INDEX)
	{
		int numStrings = GetStringTableNumStrings(particleEffectNames);
		if (numStrings >= GetStringTableMaxStrings(particleEffectNames))
		{
			return INVALID_STRING_INDEX;
		}

		AddToStringTable(particleEffectNames, particleSystem);
		index = numStrings;
	}

	return index;
}

stock int FindStringIndex2(int tableidx, const char[] str)
{
	char buf[1024];
	int numStrings = GetStringTableNumStrings(tableidx);
	for (int i = 0; i < numStrings; i++)
	{
		ReadStringTable(tableidx, i, buf, sizeof(buf));
		if (StrEqual(buf, str))
		{
			return i;
		}
	}

	return INVALID_STRING_INDEX;
}

stock bool IsClientInRange(int iClient, float vecOrigin[3], float flRadius)
{
	float vecClientOrigin[3];
	GetClientAbsOrigin(iClient, vecClientOrigin);
	return GetVectorDistance(vecOrigin, vecClientOrigin) <= flRadius;
}

stock void CreateFade(int iClient, int iDuration = 2000, int iRed = 255, int iGreen = 255, int iBlue = 255, int iAlpha = 255)
{
	BfWrite bf = UserMessageToBfWrite(StartMessageOne("Fade", iClient));
	bf.WriteShort(iDuration);	//Fade duration
	bf.WriteShort(0);
	bf.WriteShort(0x0001);
	bf.WriteByte(iRed);			//Red
	bf.WriteByte(iGreen);		//Green
	bf.WriteByte(iBlue);		//Blue
	bf.WriteByte(iAlpha);		//Alpha
	EndMessage();
}