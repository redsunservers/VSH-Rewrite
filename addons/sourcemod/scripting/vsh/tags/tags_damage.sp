public Action TagsDamage_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	//Get values to pass around
	TagsParams tParams = new TagsParams();
	tParams.SetInt("victim", victim);
	tParams.SetInt("attacker", attacker);
	tParams.SetInt("inflictor", inflictor);
	tParams.SetFloat("damage", damage);
	tParams.SetInt("filter_damagetype", damagetype);	//Because 'damagetype' is already used from config to set
	tParams.SetInt("weapon", weapon);
	tParams.SetInt("filter_damagecustom", damagecustom);
	
	//Call takedamage function
	if (SaxtonHale_IsValidAttack(victim))
	{
		for (int iSlot = 0; iSlot <= WeaponSlot_BuilderEngie; iSlot++)
		{
			int iPos = -1;
			Tags tagsStruct;
			while (TagsCore_GetStruct(iPos, victim, TagsCall_TakeDamage, iSlot, tParams, tagsStruct))	//Loop though every active structs
				TagsCore_CallStruct(victim, tagsStruct, tParams);
		}
	}
	
	//Get weapon slot
	int iWeaponSlot = -1;
	if (weapon > MaxClients && HasEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
	{
		int iIndex = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
		iWeaponSlot = TF2_GetItemSlot(iIndex, TF2_GetPlayerClass(attacker));
	}
	
	//Call attackdamage function
	if (SaxtonHale_IsValidAttack(attacker))
	{
		for (int iSlot = 0; iSlot <= WeaponSlot_BuilderEngie; iSlot++)
		{
			int iPos = -1;
			Tags tagsStruct;
			while (TagsCore_GetStruct(iPos, attacker, TagsCall_AttackDamage, iSlot, tParams, tagsStruct))	//Loop though every active structs
			{
				//Only call if either weapon used, or passive
				if (iSlot != iWeaponSlot && tagsStruct.tParams.GetInt("passive") != 1)
					continue;
				
				TagsCore_CallStruct(attacker, tagsStruct, tParams);
			}
		}
	}
	
	//Change values from param
	Action action = Plugin_Continue;
	float flValue;
	
	if (tParams.GetFloatEx("set", flValue))
	{
		damage = flValue;
		action = Plugin_Changed;
	}
	
	if (tParams.GetFloatEx("perplayer", flValue))
	{
		damage = flValue * float(g_iTotalAttackCount);
		action = Plugin_Changed;
	}
	
	if (tParams.GetFloatEx("multiply", flValue))
	{
		damage *= flValue;
		action = Plugin_Changed;
	}
	
	if (tParams.GetFloatEx("min", flValue) && damage < flValue)
	{
		damage = flValue;
		action = Plugin_Changed;
	}
	
	if (tParams.GetFloatEx("max", flValue) && damage > flValue)
	{
		damage = flValue;
		action = Plugin_Changed;
	}
	
	ArrayList aDamageType = tParams.GetStringArray("damagetype");
	if (aDamageType != null)
	{
		int iLength = aDamageType.Length;
		int iBlockSize = aDamageType.BlockSize;
		for (int i = 0; i < iLength; i++)
		{
			//Get damagetype string name, then convert to int
			char[] sBuffer = new char[iBlockSize];
			aDamageType.GetString(i, sBuffer, iBlockSize);
			int iDamageType = TagsDamage_GetType(sBuffer);
			
			if (iDamageType > 0)
				damagetype |= iDamageType;
			else if (iDamageType < 0)
				damagetype &= ~iDamageType;
		}
		
		delete aDamageType;
		action = Plugin_Changed;
	}
	
	delete tParams;
	return action;
}

int TagsDamage_GetType(const char[] sDamageType)
{
	static StringMap mDamageType;
	
	if (mDamageType == null)
	{
		mDamageType = new StringMap();
		mDamageType.SetValue("crit", DMG_CRIT);
		mDamageType.SetValue("nocrit", -DMG_CRIT); //Negative number to indicate we don't want this instead
		mDamageType.SetValue("fall", DMG_FALL);
		mDamageType.SetValue("blast", DMG_BLAST);
		mDamageType.SetValue("shock", DMG_SHOCK);
		mDamageType.SetValue("knockback", -DMG_PREVENT_PHYSICS_FORCE);
		mDamageType.SetValue("noknockback", DMG_PREVENT_PHYSICS_FORCE);
		mDamageType.SetValue("ignite", DMG_IGNITE);
	}
	
	int iDamageType = 0;
	mDamageType.GetValue(sDamageType, iDamageType);
	
	return iDamageType;
}

int TagsDamage_GetCustom(const char[] sDamageCustom)
{
	static StringMap mDamageCustom;
	
	if (mDamageCustom == null)
	{
		mDamageCustom = new StringMap();
		mDamageCustom.SetValue("headshot", TF_CUSTOM_HEADSHOT);
		mDamageCustom.SetValue("noheadshot", -TF_CUSTOM_HEADSHOT); //Negative number to indicate we don't want this instead
		mDamageCustom.SetValue("backstab", TF_CUSTOM_BACKSTAB);
		mDamageCustom.SetValue("stomp", TF_CUSTOM_BOOTS_STOMP);
	}
	
	int iDamageCustom = 0;
	mDamageCustom.GetValue(sDamageCustom, iDamageCustom);
	return iDamageCustom;
}