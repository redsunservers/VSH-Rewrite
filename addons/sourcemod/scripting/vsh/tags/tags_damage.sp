enum struct TagsDamage	//Stuffs to pass around tags
{
	int iVictim;
	int iAttacker;
	int iInflictor;
	float flDamage;
	int iDamageType;
	int iWeapon;
	float flDamageForce[3];
	float flDamagePosition[3];
	int iDamageCustom;
}

static TagsDamage g_damageStruct;
static bool g_bTagsDamageCall;

int TagsDamage_GetVictim()
{
	if (!g_bTagsDamageCall)
		PluginStop(true, "[VSH] ATTEMPTING TO GET VICTIM WHILE OUTSIDE OF DAMAGE CALL!!!!");
	
	return g_damageStruct.iVictim;
}

int TagsDamage_GetAttacker()
{
	if (!g_bTagsDamageCall)
		PluginStop(true, "[VSH] ATTEMPTING TO GET ATTACKER WHILE OUTSIDE OF DAMAGE CALL!!!!");
	
	return g_damageStruct.iAttacker;
}

int TagsDamage_GetWeapon()
{
	if (!g_bTagsDamageCall)
		PluginStop(true, "[VSH] ATTEMPTING TO GET WEAPON WHILE OUTSIDE OF DAMAGE CALL!!!!");
	
	return g_damageStruct.iWeapon;
}

bool TagsDamage_HasDamageType(int iDamageType)
{
	if (!g_bTagsDamageCall)
		PluginStop(true, "[VSH] ATTEMPTING TO GET DAMAGE TYPE WHILE OUTSIDE OF DAMAGE CALL!!!!");
	
	//We use negative number as reverse of yes/no
	if (iDamageType >= 0)
		return !!(g_damageStruct.iDamageType & iDamageType);
	else
		return !(g_damageStruct.iDamageType & -iDamageType);
}

bool TagsDamage_HasDamageCustom(int iDamageCustom)
{
	if (!g_bTagsDamageCall)
		PluginStop(true, "[VSH] ATTEMPTING TO GET DAMAGE CUSTOM WHILE OUTSIDE OF DAMAGE CALL!!!!");
	
	//We use negative number as reverse of yes/no
	if (iDamageCustom >= 0)
		return !!(g_damageStruct.iDamageCustom == iDamageCustom);
	else
		return !(g_damageStruct.iDamageCustom == -iDamageCustom);
}

Action TagsDamage_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	//Get values to pass around
	g_damageStruct.iVictim = victim;
	g_damageStruct.iAttacker = attacker;
	g_damageStruct.iInflictor = inflictor;
	g_damageStruct.flDamage = damage;
	g_damageStruct.iDamageType = damagetype;
	g_damageStruct.iWeapon = weapon;
	g_damageStruct.flDamageForce = damageForce;
	g_damageStruct.flDamagePosition = damagePosition;
	g_damageStruct.iDamageCustom = damagecustom;
	
	g_bTagsDamageCall = true;
	
	Action action = Plugin_Continue;
	
	//Call takedamage function
	if (SaxtonHale_IsValidAttack(victim))
	{
		for (int iSlot = 0; iSlot <= WeaponSlot_BuilderEngie; iSlot++)
		{
			int iPos = -1;
			Tags tagsStruct;
			while (TagsCore_GetStruct(iPos, victim, TagsCall_TakeDamage, iSlot, tagsStruct))	//Loop though every active structs
			{
				Action actionTemp = TagsDamage_CallStruct(tagsStruct);
				if (action < actionTemp) action = actionTemp;
				
				TagsCore_CallStruct(victim, tagsStruct);
			}
		}
	}
	
	//Get weapon slot
	int iWeaponSlot = -1;
	if (g_damageStruct.iWeapon > MaxClients && HasEntProp(g_damageStruct.iWeapon, Prop_Send, "m_iItemDefinitionIndex"))
	{
		int iIndex = GetEntProp(g_damageStruct.iWeapon, Prop_Send, "m_iItemDefinitionIndex");
		iWeaponSlot = TF2_GetSlotInItem(iIndex, TF2_GetPlayerClass(g_damageStruct.iAttacker));
	}
	
	//Call attackdamage function
	if (SaxtonHale_IsValidAttack(attacker))
	{
		for (int iSlot = 0; iSlot <= WeaponSlot_BuilderEngie; iSlot++)
		{
			int iPos = -1;
			Tags tagsStruct;
			while (TagsCore_GetStruct(iPos, attacker, TagsCall_AttackDamage, iSlot, tagsStruct))	//Loop though every active structs
			{
				//Only call if either weapon used, or passive
				if (iSlot != iWeaponSlot && !tagsStruct.bPassive)
					continue;
				
				Action actionTemp = TagsDamage_CallStruct(tagsStruct);
				if (action < actionTemp) action = actionTemp;
				
				TagsCore_CallStruct(attacker, tagsStruct);
			}
		}
	}
	
	g_bTagsDamageCall = false;
	
	if (action == Plugin_Changed)
	{
		//Set values back
		attacker = g_damageStruct.iAttacker;
		inflictor = g_damageStruct.iInflictor;
		damage = g_damageStruct.flDamage;
		damagetype = g_damageStruct.iDamageType;
		weapon = g_damageStruct.iWeapon;
		damageForce = g_damageStruct.flDamageForce;
		damagePosition = g_damageStruct.flDamagePosition;
	}
	
	return action;
}

Action TagsDamage_CallStruct(Tags tagsStruct)
{
	Action action = Plugin_Continue;
	
	if (tagsStruct.flSet >= 0.0)
	{
		g_damageStruct.flDamage = tagsStruct.flSet;
		action = Plugin_Changed;
	}
	
	if (tagsStruct.flPerPlayer >= 0.0)
	{
		g_damageStruct.flDamage = tagsStruct.flPerPlayer * float(g_iTotalAttackCount);
		action = Plugin_Changed;
	}
	
	if (tagsStruct.flMultiply >= 0.0)
	{
		g_damageStruct.flDamage *= tagsStruct.flMultiply;
		action = Plugin_Changed;
	}
	
	if (tagsStruct.flMin > g_damageStruct.flDamage)
	{
		g_damageStruct.flDamage = tagsStruct.flMin;
		action = Plugin_Changed;
	}
	
	if (tagsStruct.flMax >= 0.0 && tagsStruct.flMax < g_damageStruct.flDamage)
	{
		g_damageStruct.flDamage = tagsStruct.flMax;
		action = Plugin_Changed;
	}
	
	if (tagsStruct.aDamageType != null)
	{
		int iLength = tagsStruct.aDamageType.Length;
		for (int i = 0; i < iLength; i++)
		{
			int iDamageType = tagsStruct.aDamageType.Get(i);
			if (iDamageType > 0)
				g_damageStruct.iDamageType |= iDamageType;
			else if (iDamageType < 0)
				g_damageStruct.iDamageType &= ~iDamageType;
		}
		
		action = Plugin_Changed;
	}
	
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