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
	TagsDamage damageStruct;
	damageStruct.iVictim = victim;
	damageStruct.iAttacker = attacker;
	damageStruct.iInflictor = inflictor;
	damageStruct.flDamage = damage;
	damageStruct.iDamageType = damagetype;
	damageStruct.iWeapon = weapon;
	damageStruct.flDamageForce = damageForce;
	damageStruct.flDamagePosition = damagePosition;
	damageStruct.iDamageCustom = damagecustom;
	
	Action action = Plugin_Continue;
	
	//Call takedamage function
	for (int iSlot = 0; iSlot <= WeaponSlot_BuilderEngie; iSlot++)
	{
		Action actionTemp = Tags_CallSlotDamage(damageStruct.iVictim, TagsCall_TakeDamage, iSlot, damageStruct);
		if (action < actionTemp)
			action = actionTemp;
	}
	
	//Call attackdamage function
	if (damageStruct.iWeapon > MaxClients && HasEntProp(damageStruct.iWeapon, Prop_Send, "m_iItemDefinitionIndex"))
	{
		int iIndex = GetEntProp(damageStruct.iWeapon, Prop_Send, "m_iItemDefinitionIndex");
		int iSlot = TF2_GetSlotInItem(iIndex, TF2_GetPlayerClass(damageStruct.iAttacker));
		if (iSlot > -1)
		{
			Action actionTemp = Tags_CallSlotDamage(damageStruct.iAttacker, TagsCall_AttackDamage, iSlot, damageStruct);
			if (action < actionTemp)
				action = actionTemp;
		}
	}
	
	if (action == Plugin_Changed)
	{
		//Set values back
		attacker = damageStruct.iAttacker;
		inflictor = damageStruct.iInflictor;
		damage = damageStruct.flDamage;
		damagetype = damageStruct.iDamageType;
		weapon = damageStruct.iWeapon;
		damageForce = damageStruct.flDamageForce;
		damagePosition = damageStruct.flDamagePosition;
	}
	
	return action;
}

Action Tags_CallSlotDamage(int iClient, TagsCall nCall, int iSlot, TagsDamage damageStruct)
{
	if (!SaxtonHale_IsValidAttack(iClient))
		return Plugin_Continue;
	
	g_damageStruct = damageStruct;
	g_bTagsDamageCall = true;
	
	TagsCore_CallSlot(iClient, nCall, iSlot);
	
	Action action = Plugin_Continue;
	
	int iPos = -1;
	Tags tagsStruct;
	while (TagsCore_GetStruct(iPos, iClient, nCall, iSlot, tagsStruct))	//Loop though every active structs
	{
		if (tagsStruct.flSet >= 0.0)
		{
			damageStruct.flDamage = tagsStruct.flSet;
			action = Plugin_Changed;
		}
		
		if (tagsStruct.flPerPlayer >= 0.0)
		{
			damageStruct.flDamage = tagsStruct.flPerPlayer * float(g_iTotalAttackCount);
			action = Plugin_Changed;
		}
		
		if (tagsStruct.flMultiply >= 0.0)
		{
			damageStruct.flDamage *= tagsStruct.flMultiply;
			action = Plugin_Changed;
		}
		
		if (tagsStruct.flMin > damageStruct.flDamage)
		{
			damageStruct.flDamage = tagsStruct.flMin;
			action = Plugin_Changed;
		}
		
		if (tagsStruct.flMax >= 0.0 && tagsStruct.flMax < damageStruct.flDamage)
		{
			damageStruct.flDamage = tagsStruct.flMax;
			action = Plugin_Changed;
		}
		
		if (tagsStruct.iKnockback == 0)
		{
			damageStruct.iDamageType |= DMG_PREVENT_PHYSICS_FORCE;
			action = Plugin_Changed;
		}
		else if (tagsStruct.iKnockback == 1)
		{
			damageStruct.iDamageType &= ~DMG_PREVENT_PHYSICS_FORCE;
			action = Plugin_Changed;
		}
	}
	
	g_bTagsDamageCall = false;
	
	return action;
}