static int g_iClimbAmount[TF_MAXPLAYERS+1][WeaponSlot_InvisWatch+1];
static int g_iEventUsed[TF_MAXPLAYERS+1][WeaponSlot_InvisWatch+1];
static bool g_bEventConsumed[TF_MAXPLAYERS+1][WeaponSlot_InvisWatch+1];
static Handle g_hEventAttribTimer[TF_MAXPLAYERS+1][WeaponSlot_InvisWatch+1][WeaponSlot_InvisWatch+1];
static float g_flEventPreviousTime[TF_MAXPLAYERS+1][WeaponSlot_InvisWatch+1];
static float g_flEventEnd[TF_MAXPLAYERS+1][WeaponSlot_InvisWatch+1];
static float g_flEventBlockAttack1[TF_MAXPLAYERS+1][WeaponSlot_InvisWatch+1];
static float g_flEventBlockAttack2[TF_MAXPLAYERS+1][WeaponSlot_InvisWatch+1];
static float g_flUberBeforeHealingBuilding[TF_MAXPLAYERS+1];
static float g_flDispenserBoost[TF_MAXPLAYERS+1];

//If tag exists, return true and sValue of it, false if doesnt exist
public bool Tags_Lookup(int iClient, int iSlot, char[] sTags, char[] sValue, int iLength)
{
	if (iClient <= 0 || iClient > MaxClients || !IsClientInGame(iClient)) return false;
	if (iSlot < 0) return false;
	
	int iWeapon = TF2_GetItemInSlot(iClient, iSlot);
	if (IsValidEdict(iWeapon))
	{
		//Get weapon index & prefabs
		int iIndex = GetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex");
		
		for (int i = 0; i <= 1; i++)
		{
			char sSearch[MAXLEN_CONFIG_VALUE];
			
			//Find tag in weapon index
			if (i == 0 && !g_ConfigIndex.GetTags(iIndex, sSearch, sizeof(sSearch)))
				continue;
			
			//If still not found, try class slot instead
			if (i == 1 && !g_ConfigClass[TF2_GetPlayerClass(iClient)][iSlot].GetTags(sSearch, sizeof(sSearch)))
				return false;

			//Since we assuming more than 1 tags, search through each of them
			char buffer[32][32];
			int count = ExplodeString(sSearch, " ; ", buffer, 32, 32);
			if (count > 1)
			{
				for (int j = 0; j < count; j+= 2)
				{
					if (StrEqual(buffer[j], sTags, false))
					{
						//Tag found, set value as next and return true
						TrimString(buffer[j+1]);
						Format(sValue, iLength, buffer[j+1]);
						return true;
					}
				}
			}
		}
	}
	
	return false;
}

public bool Tags_GetInt(int iClient, int iSlot, char[] sTags, int &iValue)
{
	char sValue[MAXLEN_CONFIG_VALUE];
	bool bFound = Tags_Lookup(iClient, iSlot, sTags, sValue, sizeof(sValue));
	
	if (bFound) iValue = StringToInt(sValue);
	return bFound;
}

public bool Tags_GetFloat(int iClient, int iSlot, char[] sTags, float &flValue)
{
	char sValue[MAXLEN_CONFIG_VALUE];
	bool bFound = Tags_Lookup(iClient, iSlot, sTags, sValue, sizeof(sValue));
	
	if (bFound) flValue = StringToFloat(sValue);
	return bFound;
}

public bool Tags_GetString(int iClient, int iSlot, char[] sTags, char[] sValue, int iLength)
{
	return Tags_Lookup(iClient, iSlot, sTags, sValue, iLength);
}

public bool Tags_GetArray(int iClient, int iSlot, char[] sTags, ArrayList &aValue)
{
	char sValue[MAXLEN_CONFIG_VALUE];
	bool bFound = Tags_Lookup(iClient, iSlot, sTags, sValue, sizeof(sValue));
	
	if (bFound)
	{
		if (aValue == null)
			aValue = new ArrayList();
		else
			aValue.Clear();
		
		char buffer[32][32];
		int count = ExplodeString(sValue, ",", buffer, 32, 32);
		if (count > 0)
			for (int j = 0; j < count; j++)
				aValue.Push(StringToFloat(buffer[j]));
	}
	
	return bFound;
}

public void Tags_RoundStart()
{
	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		for (int iSlot = 0; iSlot <= WeaponSlot_InvisWatch; iSlot++)
		{
			g_iEventUsed[iClient][iSlot] = 0;
			g_flEventPreviousTime[iClient][iSlot] = 0.0;
			g_flEventEnd[iClient][iSlot] = 0.0;
			g_flEventBlockAttack1[iClient][iSlot] = 0.0;
			g_flEventBlockAttack2[iClient][iSlot] = 0.0;
		}
		
		g_flUberBeforeHealingBuilding[iClient] = 0.0;
		g_flDispenserBoost[iClient] = 0.0;
	}
}

//Event tags

public Action Timer_CallEvent(Handle hTimer, DataPack data)
{
	data.Reset();
	int iClient = EntRefToEntIndex(data.ReadCell());
	int iSlot = data.ReadCell();
	delete data;
	
	if (iClient <= 0 || iClient > MaxClients || !IsClientInGame(iClient) || !IsPlayerAlive(iClient))
		return;
	
	Tags_CallEvent(iClient, iSlot);
}

public void Tags_CallEvent(int iClient, int iSlot)
{
	g_iEventUsed[iClient][iSlot]++;
	
	int iWeapon = TF2_GetItemInSlot(iClient, iSlot);
	
	int iVal;
	float flVal;
	ArrayList aVal;
	float flDuration = -1.0;
	
	//Duration for various other tags
	if (Tags_GetFloat(iClient, iSlot, "event_duration", flVal))
	{
		flDuration = flVal;
		g_flEventEnd[iClient][iSlot] = GetGameTime() + flVal;
	}
	
	//block attack1
	if (Tags_GetFloat(iClient, iSlot, "event_block_attack1", flVal))
	{
		SetEntPropFloat(iWeapon, Prop_Send, "m_flNextPrimaryAttack", GetGameTime() + flVal);
		g_flEventBlockAttack1[iClient][iSlot] = GetGameTime() + flVal;
	}
	
	//block attack2
	if (Tags_GetFloat(iClient, iSlot, "event_block_attack2", flVal))
	{
		SetEntPropFloat(iWeapon, Prop_Send, "m_flNextSecondaryAttack", GetGameTime() + flVal);
		g_flEventBlockAttack2[iClient][iSlot] = GetGameTime() + flVal;
	}
	
	//Add conds
	if (Tags_GetArray(iClient, iSlot, "event_cond_add", aVal) && aVal.Length > 0)
	{
		ApplyPlayerCond(iClient, aVal, flDuration);
	}
	
	//Remove conds
	if (Tags_GetArray(iClient, iSlot, "event_cond_remove", aVal) && aVal.Length > 0)
	{
		for (int i = 0; i < aVal.Length; i++)
		{
			TFCond cond = view_as<TFCond>(RoundToNearest(aVal.Get(i)));
			if (TF2_IsPlayerInCondition(iClient, cond))
				TF2_RemoveCondition(iClient, cond);
		}
	}
	
	//Add attribs to weapon
	if (Tags_GetArray(iClient, iSlot, "event_attrib_primary", aVal))
		ApplyWeaponAttribs(iClient, iSlot, WeaponSlot_Primary, aVal, flDuration);
	
	if (Tags_GetArray(iClient, iSlot, "event_attrib_secondary", aVal))
		ApplyWeaponAttribs(iClient, iSlot, WeaponSlot_Secondary, aVal, flDuration);
	
	if (Tags_GetArray(iClient, iSlot, "event_attrib_melee", aVal))
		ApplyWeaponAttribs(iClient, iSlot, WeaponSlot_Melee, aVal, flDuration);
	
	//Add health/take damage
	if (Tags_GetInt(iClient, iSlot, "event_heal", iVal))
	{
		if (iVal > 0)
			Client_AddHealth(iClient, iVal, iVal);
		
		else if (iVal < 0)
			SDKHooks_TakeDamage(iClient, 0, iClient, -float(iVal), DMG_PREVENT_PHYSICS_FORCE);
	}
	
	//Add/Remove cloak meter
	if (Tags_GetFloat(iClient, iSlot, "event_cloak", flVal) && flVal != 0.0)
	{
		float flCloakMeter = GetEntPropFloat(iClient, Prop_Send, "m_flCloakMeter");
		flCloakMeter += flVal;
		if (flCloakMeter < 0.0) flCloakMeter = 0.0;
		if (flCloakMeter > 100.0) flCloakMeter = 100.0;
		SetEntPropFloat(iClient, Prop_Send, "m_flCloakMeter", flCloakMeter);
	}
	
	//Apply clip bonus to primary weapon
	if (Tags_GetInt(iClient, iSlot, "event_primary_clip_bonus", iVal) && iVal > 0.0)
	{
		int iPrimaryWep = GetPlayerWeaponSlot(iClient, WeaponSlot_Primary);
		if (IsValidEdict(iPrimaryWep))
		{
			//Cow mangler clip size is a bit wonky, as we have to use a different method for it
			char sClassname[64];
			GetEntityClassname(iPrimaryWep, sClassname, sizeof(sClassname));
			bool bIsEnergyWeapon = StrEqual(sClassname, "tf_weapon_particle_cannon", false);

			if (!bIsEnergyWeapon)
			{
				int iClip = SDK_GetMaxClip(iPrimaryWep);
				if(iClip > 0)
					SetEntProp(iPrimaryWep, Prop_Send, "m_iClip1", iClip+iVal);
			}
			else
			{
				//Cow Mangler's energy meter is 5.0 for every clip, so 4 max is 20.0. We multiply 5.0 by the value in config plus 4 (Cow Mangler's max clip size)
				SetEntPropFloat(iPrimaryWep, Prop_Send, "m_flEnergy", float(iVal + 4) * 5.0);
			}

			//SetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon", iPrimaryWep);
			
			//Create timer to reset bonus
			if (flDuration >= 0.0)
				CreateTimer(flDuration, Timer_RemoveClipBonus, EntIndexToEntRef(iPrimaryWep));
		}
	}
	
	//Apply ammo regen to primary weapon
	if (Tags_GetInt(iClient, iSlot, "event_primary_ammo_regen", iVal) && iVal > 0)
	{
		int iPrimaryWep = GetPlayerWeaponSlot(iClient, WeaponSlot_Primary);
		if (IsValidEdict(iPrimaryWep))
		{
			DataPack data = new DataPack();
			data.WriteCell(EntIndexToEntRef(iClient));
			data.WriteCell(iSlot);
			data.WriteCell(EntIndexToEntRef(iPrimaryWep));
			data.WriteCell(iVal);
				
			CreateTimer(0.0, Timer_AmmoRegen, data);
		}
	}
	
	//Summon zombies
	if (Tags_GetInt(iClient, iSlot, "event_zombie_max", iVal) && iVal > 0.0)
	{
		int iMaxCount = iVal;
		
		if (Tags_GetInt(iClient, iSlot, "event_reduce_on_use", iVal) && iVal > 0.0)
			iMaxCount -= (g_iEventUsed[iClient][iSlot] - 1) * iVal;
		
		if (Tags_GetInt(iClient, iSlot, "event_zombie_min", iVal) && iMaxCount < iVal)
			iMaxCount = iVal;
		
		//Collect list of valid players
		ArrayList aDeadPlayers = new ArrayList();
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i)
				&& GetClientTeam(i) > 1
				&& !IsPlayerAlive(i)
				&& Preferences_Get(i, halePreferences_Revival)
				&& !Client_HasFlag(i, haleClientFlags_Punishment)
				&& (!SaxtonHale_IsValidBoss(i, false)))
			{
				aDeadPlayers.Push(i);
			}
		}
		
		SortADTArray(aDeadPlayers, Sort_Random, Sort_Integer);
		
		if (iMaxCount > aDeadPlayers.Length)
			iMaxCount = aDeadPlayers.Length;
		
		for (int i = 0; i < iMaxCount; i++)
			SpawnZombie(aDeadPlayers.Get(i), iClient);
		
		delete aDeadPlayers;
	}
	
	//Give nearby players cond
	if (Tags_GetFloat(iClient, iSlot, "event_aoe_radius", flVal) && flVal > 0.0)
	{
		int iCond = -1;
		TFCond cond = view_as<TFCond>(-1);
		if (Tags_GetInt(iClient, iSlot, "event_aoe_cond", iCond) && iCond >= 0)
			cond = view_as<TFCond>(iCond);
		
		float flHeal = 0.0;
		if (Tags_GetFloat(iClient, iSlot, "event_aoe_heal", flHeal) && flHeal != 0.0)
			flHeal = 1.0 / flHeal;
		
		DataPack data = new DataPack();
		data.WriteCell(EntIndexToEntRef(iClient));
		data.WriteCell(iSlot);
		data.WriteFloat(flVal);
		data.WriteCell(cond);
		data.WriteFloat(flHeal);
		
		RequestFrame(Frame_AreaOfRange, data);
	}
	
	delete aVal;
}

public void ApplyPlayerCond(int iClient, ArrayList aCond, float flDuration)
{
	for (int i = 0; i < aCond.Length; i++)
	{
		TFCond cond = view_as<TFCond>(RoundToNearest(aCond.Get(i)));
		TF2_AddCondition(iClient, cond, flDuration);
	}
}

public void ApplyWeaponAttribs(int iClient, int iSlot, int iSlotAttrib, ArrayList aAttribs, float flDuration)
{
	int iWeapon = TF2_GetItemInSlot(iClient, iSlotAttrib);
	if (!IsValidEdict(iWeapon)) return;
	if (aAttribs == null || aAttribs.Length <= 1) return;
	
	//Check if they don't already have attrib from timer
	if (g_hEventAttribTimer[iClient][iSlot][iSlotAttrib] == null)
	{
		//Loop to apply attrib
		for (int i = 0; i < aAttribs.Length; i+= 2)
			TF2Attrib_SetByDefIndex(iWeapon, RoundToNearest(aAttribs.Get(i)), aAttribs.Get(i+1));
		
		TF2Attrib_ClearCache(iWeapon);
	}
	
	//Create timer to remove attrib
	if (flDuration >= 0.0)
	{
		DataPack data = new DataPack();
		data.WriteCell(EntIndexToEntRef(iClient));
		data.WriteCell(iSlot);
		data.WriteCell(iSlotAttrib);
		data.WriteCell(aAttribs.Clone());	//Because aAttribs get deleted in CallEvent
		g_hEventAttribTimer[iClient][iSlot][iSlotAttrib] = CreateTimer(flDuration, Timer_RemoveAttribute, data);
	}
}

public Action Timer_RemoveAttribute(Handle hTimer, DataPack data)
{
	data.Reset();
	int iClient = EntRefToEntIndex(data.ReadCell());
	int iSlot = data.ReadCell();
	int iSlotAttrib = data.ReadCell();
	ArrayList aAttribs = data.ReadCell();
	delete data;
	
	if (iClient <= 0 || iClient > MaxClients || !IsClientInGame(iClient))
	{
		delete aAttribs;
		return;
	}
	
	//If event been called again while having attrib, dont remove
	if (g_hEventAttribTimer[iClient][iSlot][iSlotAttrib] == hTimer)
	{
		int iWeapon = TF2_GetItemInSlot(iClient, iSlotAttrib);
		if (iWeapon > MaxClients)
		{
			//Loop to remove attrib
			for (int i = 0; i < aAttribs.Length; i+= 2)
				TF2Attrib_RemoveByDefIndex(iWeapon, RoundToNearest(aAttribs.Get(i)));
			
			TF2Attrib_ClearCache(iWeapon);
		}
		
		g_hEventAttribTimer[iClient][iSlot][iSlotAttrib] = null;
	}
	
	delete aAttribs;
}

public Action Timer_RemoveClipBonus(Handle hTimer, int iRef)
{
	int iEntity = EntRefToEntIndex(iRef);
	if (iEntity > MaxClients)
	{
		//Cow mangler clip size is a bit wonky, as we have to use a different method for it
		char sClassname[64];
		GetEntityClassname(iEntity, sClassname, sizeof(sClassname));
		bool bIsEnergyWeapon = StrEqual(sClassname, "tf_weapon_particle_cannon", false);

		if (!bIsEnergyWeapon)
		{
			int iMaxClip = SDK_GetMaxClip(iEntity);
			int iCurrentClip = GetEntProp(iEntity, Prop_Send, "m_iClip1");
			if (iCurrentClip > iMaxClip)
				iCurrentClip = iMaxClip;
			SetEntProp(iEntity, Prop_Send, "m_iClip1", iCurrentClip);
		}
		else
		{
			//Cow Mangler's energy meter is 5.0 for every clip, so 4 max is 20.0.
			float flEnergy = GetEntPropFloat(iEntity, Prop_Send, "m_flEnergy");
			if (flEnergy > 20.0)
				flEnergy = 20.0;
			SetEntPropFloat(iEntity, Prop_Send, "m_flEnergy", flEnergy);
		}
	}
}

public Action Timer_AmmoRegen(Handle hTimer, DataPack data)
{
	data.Reset();
	int iClient = EntRefToEntIndex(data.ReadCell());
	int iSlot = data.ReadCell();
	int iEntity = EntRefToEntIndex(data.ReadCell());
	int iAmmoBonus = data.ReadCell();
	
	if (iClient <= 0 || iClient > MaxClients || !IsClientInGame(iClient) || SaxtonHale_IsValidBoss(iClient))
		return Plugin_Stop;
	
	if (!IsValidEdict(iEntity))
		return Plugin_Stop;
	
	if (g_flEventEnd[iClient][iSlot] > GetGameTime())
	{
		int iAmmoType = GetEntProp(iEntity, Prop_Send, "m_iPrimaryAmmoType");
		if (iAmmoType > -1)
		{
			int iAmmo = iAmmoBonus + GetEntProp(iClient, Prop_Send, "m_iAmmo", 4, iAmmoType);	//Primary weapon ammo
			int iMaxAmmo = SDK_GetMaxAmmo(iClient, iSlot);
			
			if (iAmmo > iMaxAmmo)
				iAmmo = iMaxAmmo;
			
			SetEntProp(iClient, Prop_Send, "m_iAmmo", iAmmo, 4, iAmmoType);
			
			CreateTimer(1.0, Timer_AmmoRegen, data);
		}
	}
	else
	{
		//Duration ended
		delete data;
	}
	
	return Plugin_Stop;
}

public void SpawnZombie(int iZombie, int iOwner)
{
	SaxtonHaleBase boss = SaxtonHaleBase(iZombie);
	if (boss.bValid)
		boss.CallFunction("Destroy");
	
	ChangeClientTeam(iZombie, GetClientTeam(iOwner));
	g_iClientOwner[iZombie] = iOwner;
	
	boss.CallFunction("CreateBoss", "CZombie");
	TF2_RespawnPlayer(iZombie);
	
	float vecPos[3];
	GetClientAbsOrigin(iOwner, vecPos);
	TeleportEntity(iZombie, vecPos, NULL_VECTOR, NULL_VECTOR);
	
	if (GetEntProp(iOwner, Prop_Send, "m_bDucking") || GetEntProp(iOwner, Prop_Send, "m_bDucked"))
	{
		SetEntProp(iZombie, Prop_Send, "m_bDucking", true);
		SetEntProp(iZombie, Prop_Send, "m_bDucked", true);
		SetEntityFlags(iZombie, GetEntityFlags(iZombie)|FL_DUCKING);
	}
}

public void Frame_AreaOfRange(DataPack data)
{
	data.Reset();
	int iClient = EntRefToEntIndex(data.ReadCell());
	int iSlot = data.ReadCell();
	float flRadius = data.ReadFloat();
	TFCond cond = data.ReadCell();
	float flHeal = data.ReadFloat();
	
	if (g_flEventEnd[iClient][iSlot] > GetGameTime() && IsClientInGame(iClient) && IsPlayerAlive(iClient))
	{
		bool bHeal = false;
		if (g_flEventPreviousTime[iClient][iSlot] <= GetGameTime() && flHeal != 0.0)
		{
			//PrintToConsoleAll("Do heal");
			g_flEventPreviousTime[iClient][iSlot] = GetGameTime() + flHeal;
			bHeal = true;
		}
		
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
					
					if (bHeal)
						Client_AddHealth(i, 1, RoundToNearest(float(SDK_GetMaxHealth(i)) * 0.5));
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

//Damage Tags

public Action Tags_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	int iIndex = -1;
	int iSlot = -1;
	if (weapon > MaxClients && HasEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
	{
		iIndex = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
		iSlot = TF2_GetSlotInItem(iIndex, TF2_GetPlayerClass(attacker));
	}
	
	Action finalAction = Plugin_Continue;
	int iVal;
	float flVal;
	
	SaxtonHaleBase bossVictim = SaxtonHaleBase(victim);
	
	//Attacker is 0/world for fall damage 
	if (damagetype & DMG_FALL && !bossVictim.bValid)
	{
		for (int i = 0; i <= WeaponSlot_InvisWatch; i++)
		{
			if (Tags_GetFloat(victim, i, "damage_resistances_fall", flVal) && flVal != 1.0)
			{
				damage *= flVal;
				finalAction = Plugin_Changed;
			}
		}
	}
	
	if (0 < attacker <= MaxClients && IsClientInGame(attacker))
	{		
		if (!SaxtonHale_IsValidBoss(attacker))
		{
			if (bossVictim.bValid && !bossVictim.bMinion && !TF2_IsUbercharged(victim))
			{
				if (damagecustom == TF_CUSTOM_BACKSTAB)
				{
					//Anounce both attacker and victim the backstab
					EmitSoundToClient(attacker, SOUND_BACKSTAB);
					EmitSoundToClient(victim, SOUND_BACKSTAB);
					PrintCenterText(attacker, "You backstabbed the boss!");
					PrintCenterText(victim, "You were backstabbed!");
					
					//Play boss backstab sound
					char sSound[255];
					bossVictim.CallFunction("GetSound", sSound, sizeof(sSound), VSHSound_Backstab);
					if (!StrEmpty(sSound))
						EmitSoundToAll(sSound, victim, SNDCHAN_VOICE, SNDLEVEL_SCREAMING);
					
					//Add cooldown to weapon
					float flBackStabCooldown = GetGameTime() + 2.0;
					SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", flBackStabCooldown);
					SetEntPropFloat(attacker, Prop_Send, "m_flNextAttack", flBackStabCooldown);
					SetEntPropFloat(attacker, Prop_Send, "m_flStealthNextChangeTime", flBackStabCooldown);
					
					SDK_SendWeaponAnim(weapon, 0x648);
					damagetype |= DMG_PREVENT_PHYSICS_FORCE;
					finalAction = Plugin_Changed;
					
					g_iPlayerTotalBackstab[attacker][victim]++;
					
					//Special backstab chain
					if (Tags_GetInt(attacker, iSlot, "damage_backstab_chain", iVal) && iVal > 0)
					{
						int iTotalBackstab = g_iPlayerTotalBackstab[attacker][victim];
						int iRequiredBackstab = iVal;
						
						//Special backstab sound, right now we only have 4 for it
						if (1 <= iTotalBackstab <= 4)
						{
							char sBackStabSound[PLATFORM_MAX_PATH];
							Format(sBackStabSound, sizeof(sBackStabSound), "vsh_rewrite/stab0%i.mp3", iTotalBackstab);
							EmitSoundToAll(sBackStabSound);
						}
						
						//Message
						char sMessage[255];
						Format(sMessage, sizeof(sMessage), "%N vs %N\nTotal backstab: %i/%i", attacker, victim, iTotalBackstab, iRequiredBackstab);
						PrintHintTextToAll(sMessage);
						
						if (iTotalBackstab < iRequiredBackstab)
						{
							damage = 0.0;
						}
						else if (iTotalBackstab == iRequiredBackstab)
						{
							Forward_ChainStab(attacker, victim);
						}
					}
					
					//Calculate damage
					if (damage != 0.0 && Tags_GetFloat(attacker, iSlot, "damage_backstab_player", flVal) && flVal != -1.0)
						damage = flVal * float(g_iTotalAttackCount) / 3.0;
					
					if (Tags_GetFloat(attacker, iSlot, "damage_backstab_min", flVal) && flVal != -1.0 && damage < flVal / 3.0)
						damage = flVal / 3.0;
					
					if (Tags_GetFloat(attacker, iSlot, "damage_backstab_max", flVal) && flVal != -1.0 && damage > flVal / 3.0)
						damage = flVal / 3.0;
					
					if (Tags_GetInt(attacker, WeaponSlot_Primary, "damage_backstab_crit", iVal) && iVal > 0.0)
					{
						int iCrits = GetEntProp(attacker, Prop_Send, "m_iRevengeCrits");
						SetEntProp(attacker, Prop_Send, "m_iRevengeCrits", iCrits+iVal);
					}
					
					//Call event tags for backstab
					Tags_CallEvent(attacker, iSlot);
				}
				else if (damagecustom == TF_CUSTOM_BOOTS_STOMP)
				{
					//Thermal Thruster stomp gives weapon as -1, so we check every slots for it
					for (int i = 0; i <= WeaponSlot_InvisWatch; i++)
					{
						if (Tags_GetFloat(attacker, i, "damage_stomp", flVal) && flVal >= 0.0)
						{
							damage = flVal;
							finalAction = Plugin_Changed;
							break;
						}
					}
				}
				
				if (Tags_GetFloat(attacker, iSlot, "damage_glow", flVal) && flVal > 0.0)
				{
					float flGlowTime = flVal;
					if (HasEntProp(weapon, Prop_Send, "m_flChargedDamage"))
						flGlowTime *= GetEntPropFloat(weapon, Prop_Send, "m_flChargedDamage") / 100.0;
					
					flGlowTime += GetGameTime();
					
					if (bossVictim.flGlowTime < flGlowTime)
						bossVictim.flGlowTime = flGlowTime;
				}
				
				if (damagecustom == TF_CUSTOM_HEADSHOT)
				{
					if (Tags_GetInt(attacker, iSlot, "damage_headshot_decap", iVal) && iVal > 0)
						SetEntProp(attacker, Prop_Send, "m_iDecapitations", GetEntProp(attacker, Prop_Send, "m_iDecapitations") + iVal);
				
					if (Tags_GetFloat(attacker, iSlot, "damage_headshot_multiplier", flVal) && flVal != 1.0)
					{
						damage *= flVal;
						finalAction = Plugin_Changed;
					}
					
					//Call event tags for headshot
					Tags_CallEvent(attacker, iSlot);
				}
				else if (!(damagetype & DMG_CRIT))	//Don't give bodyshot dmg bonus if crit boosted
				{
					if (Tags_GetFloat(attacker, iSlot, "damage_bodyshot_multiplier", flVal) && flVal != 1.0)
					{
						damage *= flVal;
						finalAction = Plugin_Changed;
					}
				}
				
				if (Tags_GetFloat(attacker, iSlot, "damage_uber_healers", flVal) && flVal > 0.0)
				{
					ArrayList aHealer = new ArrayList();
					for (int i = 1; i <= MaxClients; i++)
					{
						SaxtonHaleBase boss = SaxtonHaleBase(i);
						if (IsClientInGame(i) && IsPlayerAlive(i) && !boss.bValid)
						{
							int iMedigun = GetPlayerWeaponSlot(i, WeaponSlot_Secondary);
							if (iMedigun > MaxClients)
							{
								char sWepClassName[64];
								GetEdictClassname(iMedigun, sWepClassName, sizeof(sWepClassName));
								if (strcmp(sWepClassName, "tf_weapon_medigun") == 0)
								{
									//bool bChargeReleased = view_as<bool>(GetEntProp(iMedigun, Prop_Send, "m_bChargeRelease"));
									//if (bChargeReleased) continue;
				
									int iHealTarget = GetEntPropEnt(iMedigun, Prop_Send, "m_hHealingTarget");
									if (iHealTarget == attacker)
										aHealer.Push(i);
								}
							}
						}
					}
				
					int iTotalHealer = aHealer.Length;
					float flUber = flVal/float(iTotalHealer);
					for (int i = 0; i < iTotalHealer; i++)
					{
						int iHealTarget = aHealer.Get(i);
						int iMedigun = GetPlayerWeaponSlot(iHealTarget, WeaponSlot_Secondary);
						float flNewUber = GetEntPropFloat(iMedigun, Prop_Send, "m_flChargeLevel")+flUber;
						if (flNewUber > 1.0) flNewUber = 1.0;
						SetEntPropFloat(iMedigun, Prop_Send, "m_flChargeLevel", flNewUber);
					}
					delete aHealer;
				}
				
				if (Tags_GetInt(attacker, iSlot, "damage_rage_any", iVal) && iVal != 0)
					bossVictim.CallFunction("AddRage", iVal);
				
				if ((damagetype & DMG_SHOCK) && Tags_GetInt(attacker, iSlot, "damage_rage_shock", iVal) && iVal != 0)
					bossVictim.CallFunction("AddRage", iVal);
				
				if ((damagetype & DMG_BLAST) && Tags_GetFloat(attacker, iSlot, "damage_explosion_multiplier", flVal) && flVal != 1.0)
				{
					damage *= flVal;
					finalAction = Plugin_Changed;
				}
				
				if (TF2_IsPlayerInCondition(attacker, TFCond_BlastJumping))
				{
					if (Tags_GetFloat(attacker, iSlot, "damage_airborne_player", flVal) && flVal > 0.0)
					{
						//Divide damage by 3 due to force crit
						damagetype |= DMG_CRIT;
						
						damage = flVal * float(g_iTotalAttackCount) / 3.0;
						
						if (Tags_GetFloat(attacker, iSlot, "damage_airborne_min", flVal) && flVal != -1.0 && damage < flVal / 3.0)
							damage = flVal / 3.0;
						
						if (Tags_GetFloat(attacker, iSlot, "damage_airborne_max", flVal) && flVal != -1.0 && damage > flVal / 3.0)
							damage = flVal / 3.0;
						
						PrintCenterText(attacker, "You market gardened him!");
						PrintCenterText(victim, "You were just market gardened!");
						
						EmitSoundToAll(SOUND_DOUBLEDONK, attacker);
						TF2_RemoveCondition(victim, TFCond_BlastJumping);
						finalAction = Plugin_Changed;
					}
				}					
				
				int iBossFlags = GetEntityFlags(victim);
				if (iBossFlags & (FL_ONGROUND|FL_DUCKING))
				{
					damagetype |= DMG_PREVENT_PHYSICS_FORCE;
					finalAction = Plugin_Changed;
				}
				
				if (Tags_GetInt(attacker, iSlot, "damage_knockback", iVal))
				{
					if (iVal == 0) damagetype |= DMG_PREVENT_PHYSICS_FORCE;
					else if (iVal == 1) damagetype &= ~DMG_PREVENT_PHYSICS_FORCE;
					
					finalAction = Plugin_Changed;
				}
			}
		}
		else
		{		
			if (!bossVictim.bValid && !TF2_IsUbercharged(victim))
			{					
				//TF2_GetSlotInItem wont work for some boss (e.g Saxton Hale with fists for heavy as soldier)
				bool bIsMeleeAttack = (weapon == TF2_GetItemInSlot(attacker, WeaponSlot_Melee));
				
				//Drain cloack meter if attacked by a boss
				if (TF2_IsPlayerInCondition(victim, TFCond_Cloaked))
				{
					if (Tags_GetFloat(victim, WeaponSlot_InvisWatch, "damage_resistances_cloak", flVal) && flVal != 1.0)
					{
						//damagetype &= ~DMG_CRIT;
						damage *= flVal;
						
						//Melee hit
						if (bIsMeleeAttack)
						{
							float flCloakMeter = GetEntPropFloat(victim, Prop_Send, "m_flCloakMeter");
							if (flCloakMeter <= 0.1)
								TF2_RemoveCondition(victim, TFCond_Cloaked);
							SetEntPropFloat(victim, Prop_Send, "m_flCloakMeter", GetEntPropFloat(victim, Prop_Send, "m_flCloakMeter") / 10.0);
						}
						
						finalAction = Plugin_Changed;
					}
				}
				
				if (GetEntProp(victim, Prop_Send, "m_bFeignDeathReady"))
				{
					if (Tags_GetFloat(victim, WeaponSlot_InvisWatch, "damage_resistances_cloak", flVal) && flVal != 1.0)
					{
						//damagetype &= ~DMG_CRIT;
						damage *= flVal;
				
						finalAction = Plugin_Changed;
					}
				}
				
				//Damage resis is used steak
				if (TF2_IsPlayerInCondition(victim, TFCond_CritCola) && TF2_IsPlayerInCondition(victim, TFCond_RestrictToMelee))
				{
					if (Tags_GetFloat(victim, WeaponSlot_Secondary, "damage_resistances_steak", flVal) && flVal != 1.0)
					{
						damage *= flVal;
						finalAction = Plugin_Changed;
					}
				}
				
				if (bIsMeleeAttack)
				{
					if (Tags_GetInt(victim, WeaponSlot_Secondary, "damage_shield", iVal) && iVal == 1)
					{
						EmitSoundToAll(SOUND_BACKSTAB, victim, _, SNDLEVEL_DISHWASHER);

						TF2_AddCondition(victim, TFCond_Bonked, 0.1);
						TF2_AddCondition(victim, TFCond_SpeedBuffAlly, 1.0);
						damage = 1.0;
						
						TF2_RemoveItemInSlot(victim, WeaponSlot_Secondary);
						finalAction = Plugin_Changed;
					}
				}
			}
		}
	}
	
	return finalAction;
}

public void Tags_PlayerHurt(int iVictim, int iAttacker, int iDamageAmount)
{
	for (int iSlot = 0; iSlot <= WeaponSlot_InvisWatch; iSlot++)
	{
		int iVal = 0;
		float flVal = 0.0;
		
		if (Tags_GetFloat(iAttacker, iSlot, "damage_hype_add", flVal) && flVal != 0.0)
		{
			float flHypeMeter = GetEntPropFloat(iAttacker, Prop_Send, "m_flHypeMeter");
			
			flHypeMeter += iDamageAmount * (100.0 / flVal);
			if (flHypeMeter > 100.0)
				flHypeMeter = 100.0;
			
			SetEntPropFloat(iAttacker, Prop_Send, "m_flHypeMeter", flHypeMeter);
			
			//Recalculate player's speed
			TF2_AddCondition(iAttacker, TFCond_SpeedBuffAlly, 0.01);
		}
		
		if (Tags_GetInt(iAttacker, iSlot, "damage_head_required", iVal) && iVal > 0)
			SetEntProp(iAttacker, Prop_Send, "m_iDecapitations", RoundToFloor(float(g_iPlayerDamage[iAttacker]) / float(iVal)));
	}
}

public void Tags_OnThink(int iClient)
{
	int iWeapon = GetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon");
	if (!IsValidEntity(iWeapon)) return;
	
	int iIndex = GetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex");
	int iSlot = TF2_GetSlotInItem(iIndex, TF2_GetPlayerClass(iClient));
	if (iSlot < 0 || iSlot > WeaponSlot_InvisWatch) return;
	
	char sClassname[256];
	GetEntityClassname(iWeapon, sClassname, sizeof(sClassname));
	
	int iHealTarget = -1;
	if (HasEntProp(iWeapon, Prop_Send, "m_hHealingTarget"))
		iHealTarget = GetEntPropEnt(iWeapon, Prop_Send, "m_hHealingTarget");
	
	ArrayList aVal;
	
	//Add conds if sentry targeting at boss
	if (Tags_GetArray(iClient, iSlot, "sentry_target_cond_add", aVal) && aVal.Length > 0)
	{
		//Find sentry
		int iSentry = MaxClients+1;
		while((iSentry = FindEntityByClassname(iSentry, "obj_sentrygun")) > MaxClients)
		{
			//Check if same builder
			if (GetEntPropEnt(iSentry, Prop_Send, "m_hBuilder") == iClient)
			{
				//Check if target is valid boss
				int iTarget = GetEntPropEnt(iSentry, Prop_Send, "m_hEnemy");
				if (SaxtonHale_IsValidBoss(iTarget))
				{
					ApplyPlayerCond(iClient, aVal, 0.05);
				}
			}
		}
	}
	
	//Add conds if disguised
	if (TF2_IsPlayerInCondition(iClient, TFCond_Disguised))
		if (Tags_GetArray(iClient, iSlot, "disguise_cond_add", aVal) && aVal.Length > 0)
			ApplyPlayerCond(iClient, aVal, 0.05);
	
	//Add conds for heal target
	if (0 < iHealTarget <= MaxClients && IsClientInGame(iHealTarget))
		if (Tags_GetArray(iClient, iSlot, "heal_cond_add", aVal) && aVal.Length > 0)
			ApplyPlayerCond(iHealTarget, aVal, 0.05);

	//Healing buildings, Set uber back to what it was when healing building
	if (iHealTarget > -1 && GetEntProp(iWeapon, Prop_Send, "m_bChargeRelease"))
		g_flUberBeforeHealingBuilding[iClient] = 0.0;
	else if (iHealTarget > MaxClients)
		SetEntPropFloat(iWeapon, Prop_Send, "m_flChargeLevel", g_flUberBeforeHealingBuilding[iClient]);
	
	delete aVal;
	
	//If weapon cooldown from event is somehow less than expected, fix that
	if (iWeapon > MaxClients && HasEntProp(iWeapon, Prop_Send, "m_flNextPrimaryAttack"))
		if (GetEntPropFloat(iWeapon, Prop_Send, "m_flNextPrimaryAttack") < g_flEventBlockAttack1[iClient][iSlot])
			SetEntPropFloat(iWeapon, Prop_Send, "m_flNextPrimaryAttack", g_flEventBlockAttack1[iClient][iSlot]);
	
	if (iWeapon > MaxClients && HasEntProp(iWeapon, Prop_Send, "m_flNextSecondaryAttack"))
		if (GetEntPropFloat(iWeapon, Prop_Send, "m_flNextSecondaryAttack") < g_flEventBlockAttack2[iClient][iSlot])
			SetEntPropFloat(iWeapon, Prop_Send, "m_flNextSecondaryAttack", g_flEventBlockAttack2[iClient][iSlot]);
	
	//Reset climb max state if on ground
	if (GetEntityFlags(iClient) & FL_ONGROUND)
		g_iClimbAmount[iClient][iSlot] = 0;
	
	if (StrEqual(sClassname, "tf_weapon_lunchbox") || StrEqual(sClassname, "tf_weapon_lunchbox_drink"))
	{
		int iAmmoType = GetEntProp(iWeapon, Prop_Send, "m_iPrimaryAmmoType");
		if (iAmmoType > -1)
		{
			int iAmmo = GetEntProp(iClient, Prop_Send, "m_iAmmo", 4, iAmmoType);
			
			if (iAmmo == 1)
			{
				g_bEventConsumed[iClient][iSlot] = false;
			}
			if (iAmmo == 0 && !g_bEventConsumed[iClient][iSlot])
			{
				g_bEventConsumed[iClient][iSlot] = true;
				
				DataPack data = new DataPack();
				data.WriteCell(EntIndexToEntRef(iClient));
				data.WriteCell(iSlot);
				
				//It takes a few seconds to drink/eat before effect actually get applied
				float flDuration = 0.0;
				if (StrEqual(sClassname, "tf_weapon_lunchbox")) flDuration = 4.3;
				if (StrEqual(sClassname, "tf_weapon_lunchbox_drink")) flDuration = 1.2;
				
				CreateTimer(flDuration, Timer_CallEvent, data);
			}
		}
	}
	
	//Building effects from heal_building tag
	if (TF2_GetPlayerClass(iClient) == TFClass_Engineer)
	{
		static int TELEPORTER_BODYGROUP_ARROW 	= (1 << 1);
		bool bSentryHealed = false;
		bool bDispenserHealed = false;
		bool bTeleporterHealed = false;
		
		int iTeam = GetClientTeam(iClient);
		
		for (int i = 1; i<= MaxClients; i++)
		{
			if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == iTeam)
			{
				char sWepClassName[32];
				int iMedigun = GetPlayerWeaponSlot(i, WeaponSlot_Secondary);
				if (iMedigun >= 0) GetEdictClassname(iMedigun, sWepClassName, sizeof(sWepClassName));

				if (strcmp(sWepClassName, "tf_weapon_medigun") != 0) continue;

				int iBuilding = GetEntPropEnt(iMedigun, Prop_Send, "m_hHealingTarget");
				if (iBuilding > MaxClients)
				{
					char sBuildingClassname[64];
					GetEdictClassname(iBuilding, sBuildingClassname, sizeof(sBuildingClassname));
					if (strncmp(sBuildingClassname, "obj_", 4) == 0 && GetEntPropEnt(iBuilding, Prop_Send, "m_hBuilder") == iClient)
					{
						if (!bSentryHealed && strcmp(sBuildingClassname, "obj_sentrygun") == 0)
							bSentryHealed = true;
						if (!bDispenserHealed && strcmp(sBuildingClassname, "obj_dispenser") == 0)
							bDispenserHealed = true;
						if (!bTeleporterHealed && strcmp(sBuildingClassname, "obj_teleporter") == 0)
							bTeleporterHealed = true;
						if (bSentryHealed && bDispenserHealed && bTeleporterHealed)
							break;
					}
				}
			}
		}
		
		//Sentry
		TF2Attrib_SetByDefIndex(iClient, ATTRIB_SENTRYATTACKSPEED, (bSentryHealed) ? 0.5 : 1.0);
		
		//Dispenser
		if (bDispenserHealed && g_flDispenserBoost[iClient] <= GetGameTime())
		{
			int iDispenser = MaxClients+1;
			while((iDispenser = FindEntityByClassname(iDispenser, "obj_dispenser")) > MaxClients)
			{
				if (GetEntPropEnt(iDispenser, Prop_Send, "m_hBuilder") == iClient)
				{
					int iMetal = GetEntProp(iDispenser, Prop_Send, "m_iAmmoMetal");
					if (iMetal < 400)
					{
						SetEntProp(iDispenser, Prop_Send, "m_iAmmoMetal", iMetal+1);
						g_flDispenserBoost[iClient] = GetGameTime()+0.25;
					}
				}
			}
		}
		
		//Teleporter
		float flVal;
		bool bHadBidirectionalTeleport = false;
		if (!bTeleporterHealed && TF2_FindAttribute(iClient,ATTRIB_BIDERECTIONAL, flVal) && flVal >= 1.0)
		{
			bHadBidirectionalTeleport = true;
			int tele = MaxClients+1;
			while((tele = FindEntityByClassname(tele, "obj_teleporter")) > MaxClients)
			{
				TFObjectMode mode = view_as<TFObjectMode>(GetEntProp(tele, Prop_Send, "m_iObjectMode"));
				if(mode == TFObjectMode_Exit && GetEntPropEnt(tele, Prop_Send, "m_hBuilder") == iClient)
				{
					int iBodyGroups = GetEntProp(tele, Prop_Send, "m_nBody");
					SetEntProp(tele, Prop_Send, "m_nBody", iBodyGroups &~ TELEPORTER_BODYGROUP_ARROW);
					break;
				}
			}
		}
		TF2Attrib_SetByDefIndex(iClient, ATTRIB_BIDERECTIONAL, (bTeleporterHealed) ? 1.0 : 0.0);
		if (bTeleporterHealed && !bHadBidirectionalTeleport)
		{
			int tele = MaxClients+1;
			while((tele = FindEntityByClassname(tele, "obj_teleporter")) > MaxClients)
			{
				TFObjectMode mode = view_as<TFObjectMode>(GetEntProp(tele, Prop_Send, "m_iObjectMode"));
				if(mode == TFObjectMode_Exit && GetEntPropEnt(tele, Prop_Send, "m_hBuilder") == iClient)
				{
					int iBodyGroups = GetEntProp(tele, Prop_Send, "m_nBody");
					SetEntProp(tele, Prop_Send, "m_nBody", iBodyGroups | TELEPORTER_BODYGROUP_ARROW);
					break;
				}
			}
		}
	}
}

public void Tags_OnButton(int iClient, int &iButtons)
{
	//Block buttons if weapon in cooldown
	if (iButtons & IN_ATTACK || iButtons & IN_ATTACK2)
	{
		int iWeapon = GetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon");
		if (iWeapon > MaxClients)
		{
			int iIndex = GetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex");
			int iSlot = TF2_GetSlotInItem(iIndex, TF2_GetPlayerClass(iClient));
			if (iSlot > WeaponSlot_InvisWatch) return;
			
			if (iButtons & IN_ATTACK && g_flEventBlockAttack1[iClient][iSlot] > GetGameTime())
				iButtons &= ~IN_ATTACK;
			
			if (iButtons & IN_ATTACK2 && g_flEventBlockAttack2[iClient][iSlot] > GetGameTime())
				iButtons &= ~IN_ATTACK2;
		}
	}
}

public void Tags_ConditionAdded(int iClient, TFCond nCond)
{
	if (nCond == TFCond_Charging)
	{
		Tags_CallEvent(iClient, WeaponSlot_Secondary);
	}
	else if (nCond == TFCond_Dazed)
	{
		float flVal;
		
		for (int iSlot = 0; iSlot <= WeaponSlot_InvisWatch; iSlot++)
		{
			if (Tags_GetFloat(iClient, iSlot, "stun_hype", flVal) && flVal != 0.0)
			{
				float flHypeMeter = GetEntPropFloat(iClient, Prop_Send, "m_flHypeMeter");
				
				flHypeMeter += flVal;
				if (flHypeMeter < 0.0) flHypeMeter = 0.0;
				if (flHypeMeter > 100.0) flHypeMeter = 100.0;
				
				SetEntPropFloat(iClient, Prop_Send, "m_flHypeMeter", flHypeMeter);
				
				//Recalculate player's speed
				TF2_AddCondition(iClient, TFCond_SpeedBuffAlly, 0.01);
			}
		}
	}
}

public Action Tags_AttackCritical(int iClient, int iWeapon, bool &bResult)
{
	//Wallclimb
	int iIndex = GetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex");
	int iSlot = TF2_GetSlotInItem(iIndex, TF2_GetPlayerClass(iClient));
	
	int iVal;
	float flVal;
	
	//Wallclimb
	if (g_flEventBlockAttack1[iClient][iSlot] < GetGameTime()
		&& Tags_GetFloat(iClient, iSlot, "climb", flVal) && flVal > 0.0)
	{
		Client_TryClimb(iClient, iSlot, flVal);
	}
	
	//Crit when aiming at boss
	if (Tags_GetInt(iClient, iSlot, "aim_crit", iVal) && iVal == 1.0)
	{
		float eyePos[3], eyeAng[3];
		GetClientEyePosition(iClient, eyePos);
		GetClientEyeAngles(iClient, eyeAng);
		
		Handle hTrace = TR_TraceRayFilterEx(eyePos, eyeAng, MASK_PLAYERSOLID, RayType_Infinite, TraceRay_DontHitEntity, iClient);
		int iCollisionEntity = TR_GetEntityIndex(hTrace);
		delete hTrace;
		
		if (SaxtonHale_IsValidBoss(iCollisionEntity))
		{
			bResult = true;
			return Plugin_Changed;
		}
	}
	
	return Plugin_Continue;
}

public bool Tags_IsAllowedToHealTarget(int iMedigun, int iHealTarget)
{
	if (MaxClients < iHealTarget < 2048)
	{
		int iClient = GetEntPropEnt(iMedigun, Prop_Send, "m_hOwnerEntity");
		int iIndex = GetEntProp(iMedigun, Prop_Send, "m_iItemDefinitionIndex");
		int iSlot = TF2_GetSlotInItem(iIndex, TF2_GetPlayerClass(iClient));
		
		int iVal;
		if (Tags_GetInt(iClient, iSlot, "heal_building", iVal) && iVal == 1.0)
		{
			char classname[64];
			GetEdictClassname(iHealTarget, classname, sizeof(classname));
			if (strcmp(classname, "obj_sentrygun") == 0 || strcmp(classname, "obj_dispenser") == 0 || strcmp(classname, "obj_teleporter") == 0)
			{
				if (GetEntProp(iHealTarget, Prop_Send, "m_iTeamNum") == GetClientTeam(iClient) && !GetEntProp(iHealTarget, Prop_Send, "m_bCarried"))
				{
					if (GetEntProp(iMedigun, Prop_Send, "m_bChargeRelease"))
						g_flUberBeforeHealingBuilding[iClient] = 0.0;
					else
						g_flUberBeforeHealingBuilding[iClient] = GetEntPropFloat(iMedigun, Prop_Send, "m_flChargeLevel");
					
					return true;
				}
			}
		}
	}
	
	return false;
}

public void Client_TryClimb(int iClient, int iSlot, float flHeight)
{
	//If have self-damage tag, check if enough health to climb
	int iVal;
	if (Tags_GetInt(iClient, iSlot, "event_heal", iVal) && iVal < 0)
	{
		int iHealth = GetEntProp(iClient, Prop_Send, "m_iHealth");
		if (iHealth <= -iVal) return;
	}

	//Don't call event & climb_max if in crikey effect
	bool bCrikey = false;
	if (TF2_IsPlayerInCondition(iClient, TFCond_CritCola))
		if (Tags_GetInt(iClient, WeaponSlot_Secondary, "climb_crikey_noevent", iVal) && iVal == 1)
			bCrikey = true;

	//If have climb_max tag, check if already climbed enough before touching ground
	if (!bCrikey && Tags_GetInt(iClient, iSlot, "climb_max", iVal) && iVal > 0)
	{
		if (g_iClimbAmount[iClient][iSlot] >= iVal)
			return;
	}

	char sClassname[64];
	float vecClientEyePos[3], vecClientEyeAng[3];
	GetClientEyePosition(iClient, vecClientEyePos);
	GetClientEyeAngles(iClient, vecClientEyeAng);

	//Check for colliding entities
	TR_TraceRayFilter(vecClientEyePos, vecClientEyeAng, MASK_PLAYERSOLID, RayType_Infinite, TraceRay_DontHitEntity, iClient);

	if (!TR_DidHit(INVALID_HANDLE)) return;

	int iEntity = TR_GetEntityIndex(INVALID_HANDLE);
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
	GetEntPropVector(iClient, Prop_Data, "m_vecVelocity", fVelocity);
	fVelocity[2] = flHeight;
	TeleportEntity(iClient, NULL_VECTOR, NULL_VECTOR, fVelocity);
	
	g_iClimbAmount[iClient][iSlot]++;
	int iFlags = GetEntityFlags(iClient);
	iFlags &= ~FL_ONGROUND;
	SetEntityFlags(iClient, iFlags);
	
	if (!bCrikey) Tags_CallEvent(iClient, iSlot);
}

public Action Arrow_OnTouch(int iEntity, int iOther)
{
	if (!g_bEnabled) return Plugin_Continue;
	if (g_iTotalRoundPlayed <= 0) return Plugin_Continue;
	
	int iClient = GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity");
	if (SaxtonHale_IsValidAttack(iClient))
	{
		float flVal = -1.0;
		if (Tags_GetFloat(iClient, WeaponSlot_Primary, "projectile_explosion", flVal) && flVal != -1.0)
		{
			float vecPos[3];
			GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", vecPos);
			char sSound[255];
			Format(sSound, sizeof(sSound), "weapons/airstrike_small_explosion_0%i.wav", GetRandomInt(1,3));
			TF2_Explode(iClient, vecPos, flVal, 120.0, "ExplosionCore_MidAir", sSound);
		}
	}
	return Plugin_Continue;
}