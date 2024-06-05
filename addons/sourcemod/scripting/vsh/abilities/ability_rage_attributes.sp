enum struct AttribData
{
	int iIndex;			// Attribute index
	float flValue;		// Value multiplied
	float flSuperValue;	// Value multiplied on Super Rage
	bool bAddition;		// If to add instead of multiply
}

static Handle g_hRevertTimer[MAXPLAYERS];
static ArrayList g_aAttributes[MAXPLAYERS];

public void RageAttributes_AddAttrib(SaxtonHaleBase boss, int iIndex, float flValue, float flSuperValue, bool bAddition)
{
	AttribData data;
	data.iIndex = iIndex;
	data.flValue = flValue;
	data.flSuperValue = flSuperValue;
	data.bAddition = bAddition;
	g_aAttributes[boss.iClient].PushArray(data);
}

public void RageAttributes_Create(SaxtonHaleBase boss)
{
	if (g_aAttributes[boss.iClient] == null)
		g_aAttributes[boss.iClient] = new ArrayList(sizeof(AttribData));
	g_aAttributes[boss.iClient].Clear();
	
	boss.SetPropFloat("RageAttributes", "RageAttribDuration", 5.0);
	boss.SetPropFloat("RageAttributes", "RageAttribSuperRageMultiplier", 2.0);
	boss.SetPropInt("RageAttributes", "RageAttribWeaponSlot", WeaponSlot_Melee);
}

public void RageAttributes_OnRage(SaxtonHaleBase boss)
{
	if (g_hRevertTimer[boss.iClient])
	{
		// Prevent stacking on self
		TriggerTimer(g_hRevertTimer[boss.iClient]);
	}
	
	int iLength = g_aAttributes[boss.iClient].Length;
	
	float flDuration = boss.GetPropFloat("RageAttributes", "RageAttribDuration");
	if (boss.bSuperRage)
		flDuration *= boss.GetPropFloat("RageAttributes", "RageAttribSuperRageMultiplier");
	
	int iSlot = boss.GetPropInt("RageAttributes", "RageAttribWeaponSlot");
	int iWeapon = TF2_GetItemInSlot(boss.iClient, iSlot);
	if (iWeapon != INVALID_ENT_REFERENCE)
	{
		float flPrevValue;
		AttribData data;
		for (int i = 0; i < iLength; i++)
		{
			g_aAttributes[boss.iClient].GetArray(i, data);

			Address addAttrib = TF2Attrib_GetByDefIndex(iWeapon, data.iIndex);
			if (addAttrib == Address_Null)
			{
				// Default to 0 or 1 for our attribute
				flPrevValue = data.bAddition ? 0.0 : 1.0;
			}
			else
			{
				flPrevValue = TF2Attrib_GetValue(addAttrib);
			}

			float flValue = boss.bSuperRage ? data.flSuperValue : data.flValue;

			if (data.bAddition)
			{
				TF2Attrib_SetByDefIndex(iWeapon, data.iIndex, flPrevValue + flValue);
			}
			else
			{
				TF2Attrib_SetByDefIndex(iWeapon, data.iIndex, flPrevValue * flValue);
			}
		}

		TF2Attrib_ClearCache(iWeapon);

		// Remember what we changed for that specific weapon
		// This method allows stacking with similar methods
		DataPack hPack;
		g_hRevertTimer[boss.iClient] = CreateDataTimer(flDuration, RevertAttributes, hPack);
		hPack.WriteCell(boss.iClient);
		hPack.WriteCell(g_aAttributes[boss.iClient].Clone());
		hPack.WriteCell(EntIndexToEntRef(iWeapon));
		hPack.WriteCell(boss.bSuperRage);
	}
}

static Action RevertAttributes(Handle timer, DataPack hPack)
{
	hPack.Reset();
	int iClient = hPack.ReadCell();
	g_hRevertTimer[iClient] = null;

	ArrayList aAttributes = hPack.ReadCell();
	int iWeapon = EntRefToEntIndex(hPack.ReadCell());
	if (iWeapon != INVALID_ENT_REFERENCE)
	{
		bool bSuperRage = hPack.ReadCell();
		float flPrevValue;
		AttribData data;
		int iLength = aAttributes.Length;
		for (int i = 0; i < iLength; i++)
		{
			aAttributes.GetArray(i, data);

			Address addAttrib = TF2Attrib_GetByDefIndex(iWeapon, data.iIndex);
			if (addAttrib == Address_Null)
			{
				// Default to 0 or 1 for our attribute
				flPrevValue = data.bAddition ? 0.0 : 1.0;
			}
			else
			{
				flPrevValue = TF2Attrib_GetValue(addAttrib);
			}

			float flValue = bSuperRage ? data.flSuperValue : data.flValue;

			if (data.bAddition)
			{
				TF2Attrib_SetByDefIndex(iWeapon, data.iIndex, flPrevValue - flValue);
			}
			else if (flValue != 0.0)
			{
				// If we multiplied by zero before uh, yippie
				TF2Attrib_SetByDefIndex(iWeapon, data.iIndex, flPrevValue / flValue);
			}
		}

		TF2Attrib_ClearCache(iWeapon);
	}

	delete aAttributes;
	return Plugin_Continue;
}
