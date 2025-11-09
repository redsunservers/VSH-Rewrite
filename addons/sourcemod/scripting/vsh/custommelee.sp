#pragma semicolon 1
#pragma newdecls required

enum struct MeleeData
{
	int iEntity;
	float flMeleeRange;
	float flMeleeBounds;
}

static ArrayList g_aMeleeSavedData;
static bool g_bGlobalNextSound[MAXPLAYERS + 1];

void CustomMelee_Init()
{
	g_aMeleeSavedData = new ArrayList(sizeof(MeleeData));
}

void CustomMelee_OnMapStart()
{
	g_aMeleeSavedData.Clear();
}

void CustomMelee_OnEntityDestroyed(int iEntity)
{
	int iIndex = g_aMeleeSavedData.FindValue(iEntity);
	if (iIndex != -1)
		g_aMeleeSavedData.Erase(iIndex);
}

void CustomMelee_OnPluginEnd()
{
	int iEntity = INVALID_ENT_REFERENCE;
	while ((iEntity = FindEntityByClassname(iEntity, "tf_weap*")) != INVALID_ENT_REFERENCE)
	{
		int iIndex = g_aMeleeSavedData.FindValue(iEntity);
		if (iIndex != -1)
			RestoreMeleeData(iEntity);
	}
}

Action CustomMelee_OnSoundHook(int clients[MAXPLAYERS], int &numClients, int &entity, int &channel)
{
	if (channel == SNDCHAN_STATIC && entity > 0 && entity <= MaxClients)
	{
		// Play the server-sided sound to the client
		if (g_bGlobalNextSound[entity])
		{
			g_bGlobalNextSound[entity] = false;

			clients[numClients] = entity;
			numClients++;
			return Plugin_Changed;
		}
	}
	
	return Plugin_Continue;
}

void CustomMelee_CalcIsAttackCritical(int iWeapon, const char[] sClassname)
{
	if (!g_ConfigConvar.LookupBool("vsh_block_fake_hit_sound"))
		return;
	
	int iOwner = GetEntPropEnt(iWeapon, Prop_Send, "m_hOwnerEntity");
	if (iOwner <= 0 || iOwner > MaxClients)
		return;
	
	if (TF2_GetItemInSlot(iOwner, TFWeaponSlot_Melee) != iWeapon)
		return;
	
	// Ignore spy knives with this logic for now
	if (StrEqual(sClassname, "tf_weapon_knife"))
		return;
	
	SaveMeleeData(iWeapon);
}

void CustomMelee_DoSwingTracePre(int iWeapon)
{
	if (!g_ConfigConvar.LookupBool("vsh_block_fake_hit_sound"))
		return;
	
	RestoreMeleeData(iWeapon);
}

void CustomMelee_DoSwingTracePost(int iWeapon, bool bHit)
{
	if (!g_ConfigConvar.LookupBool("vsh_block_fake_hit_sound"))
		return;
	
	int iIndex = g_aMeleeSavedData.FindValue(iWeapon);
	if (iIndex == -1)
		return;
	
	TF2Attrib_SetByName(iWeapon, "melee bounds multiplier", 0.0);
	TF2Attrib_SetByName(iWeapon, "melee range multiplier", 0.0);
	
	if (bHit)
	{
		// Play the server-sided sound to the client
		int iOwner = GetEntPropEnt(iWeapon, Prop_Send, "m_hOwnerEntity");
		if (iOwner > 0 && iOwner <= MaxClients)
		{
			char sClassname[64];
			GetEntityClassname(iWeapon, sClassname, sizeof(sClassname));
			if (!StrEqual(sClassname, "tf_weapon_knife"))
				g_bGlobalNextSound[iOwner] = true;
		}
	}
}

static void SaveMeleeData(int iWeapon)
{
	float flBounds = TF2Attrib_HookValueFloat(1.0, "melee_bounds_multiplier", iWeapon);
	float flRange = TF2Attrib_HookValueFloat(1.0, "melee_range_multiplier", iWeapon);
	
	int iIndex = g_aMeleeSavedData.FindValue(iWeapon);
	if (flBounds > 0.0 || flRange > 0.0 || iIndex == -1)
	{
		MeleeData data;
		data.iEntity = iWeapon;
		data.flMeleeBounds = flBounds;
		data.flMeleeRange = flRange;
		
		if (iIndex != -1)
			g_aMeleeSavedData.SetArray(iIndex, data);
		else
			g_aMeleeSavedData.PushArray(data);
	}

	TF2Attrib_SetByName(iWeapon, "melee bounds multiplier", 0.0);
	TF2Attrib_SetByName(iWeapon, "melee range multiplier", 0.0);
}

static void RestoreMeleeData(int iWeapon)
{
	int iIndex = g_aMeleeSavedData.FindValue(iWeapon);
	if (iIndex == -1)
		return;
	
	MeleeData data;
	g_aMeleeSavedData.GetArray(iIndex, data, sizeof(data));
	
	if (data.flMeleeBounds > 0.0)
		TF2Attrib_SetByName(iWeapon, "melee bounds multiplier", data.flMeleeBounds);
	
	if (data.flMeleeRange > 0.0)
		TF2Attrib_SetByName(iWeapon, "melee range multiplier", data.flMeleeRange);
	
	g_aMeleeSavedData.Erase(iIndex);
}