enum TagsFilterType			//List of possible filters
{
	TagsFilterType_Invalid = -1,
	TagsFilterType_Cond = 0,
	TagsFilterType_ActiveWeapon,
	TagsFilterType_AttackWeapon,
	TagsFilterType_Aim,
	TagsFilterType_SentryTarget,
	TagsFilterType_DamageMaximum,
	TagsFilterType_DamageMinimum,
	TagsFilterType_DamageType,
	TagsFilterType_DamageCustom,
	TagsFilterType_HitFromBehind,
	TagsFilterType_BackstabCount,
	TagsFilterType_FeignDeath,
	TagsFilterType_VictimUber,
	TagsFilterType_SelfDamage,
}

enum struct TagsFilterStruct
{
	TagsFilterType nType;	//Type of filter
	any nValue;				//Value to check
	
	bool Load(const char[] sType, const char[] sValue)
	{
		this.nType = TagsFilter_GetType(sType);
		
		switch (this.nType)
		{
			case TagsFilterType_Cond, TagsFilterType_HitFromBehind, TagsFilterType_BackstabCount, TagsFilterType_DamageMaximum, TagsFilterType_DamageMinimum:
			{
				//Get number from string
				return !!StringToIntEx(sValue, this.nValue);
			}
			case TagsFilterType_ActiveWeapon, TagsFilterType_AttackWeapon:
			{
				//Get target type
				this.nValue = TagsTarget_GetType(sValue);
				return !(this.nValue == TagsTarget_Invalid);
			}
			case TagsFilterType_Aim, TagsFilterType_SentryTarget, TagsFilterType_FeignDeath, TagsFilterType_VictimUber, TagsFilterType_SelfDamage:
			{
				this.nValue = !!StringToInt(sValue);	//Turn into boolean
				return true;
			}
			case TagsFilterType_DamageType:
			{
				this.nValue = TagsDamage_GetType(sValue);
				return this.nValue != 0;
			}
			case TagsFilterType_DamageCustom:
			{
				this.nValue = TagsDamage_GetCustom(sValue);
				return this.nValue != 0;
			}
		}
		
		return false;
	}
	
	bool IsAllowed(int iClient, TagsParams tParams = null)
	{
		//Return true/false based on what type and value
		switch (this.nType)
		{
			case TagsFilterType_Cond:
			{
				return TF2_IsPlayerInCondition(iClient, this.nValue);
			}
			case TagsFilterType_ActiveWeapon:
			{
				int iTargetWeapon = TagsTarget_GetTarget(iClient, this.nValue, tParams);
				int iActiveWeapon = GetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon");
				return (iTargetWeapon > MaxClients && iTargetWeapon == iActiveWeapon);
			}
			case TagsFilterType_AttackWeapon:
			{
				int iAttacker = tParams.GetInt("attacker", -1);
				if (0 < iAttacker <= MaxClients)
				{
					int iSlot = TagsTarget_GetWeaponSlot(this.nValue);
					return (tParams.GetInt("weapon", -1) == TF2_GetItemInSlot(iAttacker, iSlot));
				}
			}
			case TagsFilterType_Aim:
			{
				return SaxtonHale_IsValidBoss(Client_GetEyeTarget(iClient));
			}
			case TagsFilterType_SentryTarget:
			{
				int iSentry = TF2_GetBuilding(iClient, TFObject_Sentry);
				if (iSentry > MaxClients)
				{
					//Check if target is valid boss
					int iTarget = GetEntPropEnt(iSentry, Prop_Send, "m_hEnemy");
					return SaxtonHale_IsValidBoss(iTarget);
				}
			}
			case TagsFilterType_DamageType:
			{
				int iDamageType;
				if (!tParams.GetIntEx("filter_damagetype", iDamageType))
					return false;
				
				if (this.nValue > 0)
					return !!(iDamageType & this.nValue);
				else if (this.nValue < 0)
					return !(iDamageType & -this.nValue);
			}
			case TagsFilterType_DamageCustom:
			{
				int iDamageCustom;
				if (!tParams.GetIntEx("filter_damagecustom", iDamageCustom))
					return false;
				
				if (this.nValue > 0)
					return !!(iDamageCustom == this.nValue);
				else if (this.nValue < 0)
					return !(iDamageCustom == -this.nValue);
			}
			case TagsFilterType_HitFromBehind:
			{
				// This mimics the closerange_backattack_minicrits attribute's functionality
				int iVictim = tParams.GetInt("victim");
				float vecClientPos[3], vecVictimPos[3];
				GetClientAbsOrigin(iClient, vecClientPos);
				GetClientAbsOrigin(iVictim, vecVictimPos);
				
				if (this.nValue > 0 && GetVectorDistance(vecClientPos, vecVictimPos, false) > float(this.nValue))
					return false;
				
				float vecVictimAng[3], vecBuffer[3], vecForward[3];
				SubtractVectors(vecVictimPos, vecClientPos, vecBuffer);
				
				GetClientEyeAngles(iVictim, vecVictimAng);
				GetAngleVectors(vecVictimAng, vecForward, NULL_VECTOR, NULL_VECTOR);
				vecBuffer[2] = 0.0;
				NormalizeVector(vecBuffer, vecBuffer);
				
				return GetVectorDotProduct(vecBuffer, vecForward) > 0.259;
			}
			case TagsFilterType_BackstabCount:
			{
				return Tags_GetBackstabCount(iClient, tParams.GetInt("victim")) >= this.nValue;
			}
			case TagsFilterType_FeignDeath:
			{
				bool bFegin = !!GetEntProp(iClient, Prop_Send, "m_bFeignDeathReady");
				return (this.nValue ? bFegin : !bFegin);
			}
			case TagsFilterType_VictimUber:
			{
				int iVictim = tParams.GetInt("victim");
				bool bUbered = TF2_IsUbercharged(iVictim);
				return (this.nValue ? bUbered : !bUbered);
			}
			case TagsFilterType_DamageMaximum:
			{
				int iDamage;
				if (!tParams.GetIntEx("damage", iDamage))
					return false;
				
				return iDamage <= this.nValue;
			}
			case TagsFilterType_DamageMinimum:
			{
				int iDamage;
				if (!tParams.GetIntEx("damage", iDamage))
					return false;
				
				return iDamage >= this.nValue;
			}
			case TagsFilterType_SelfDamage:
			{
				int iVictim = tParams.GetInt("victim");
				int iAttacker = tParams.GetInt("attacker", -1);
				bool bSelf = (iVictim == iAttacker);
				return (this.nValue ? bSelf : !bSelf);
			}
		}
		
		return false;
	}
}

methodmap TagsFilter < ArrayList
{
	public TagsFilter(KeyValues kv)
	{
		if (!kv.JumpToKey("filter"))
			return null;	//Section dont have filter
		
		if (!kv.GotoFirstSubKey(false))
		{
			//Section have filter key but nothing inside it?
			kv.GoBack();
			return null;
		}
		
		TagsFilter filter = view_as<TagsFilter>(new ArrayList(sizeof(TagsFilterStruct)));
		
		do	//Loop through every filter
		{
			char sType[MAXLEN_CONFIG_VALUE], sValue[MAXLEN_CONFIG_VALUE];
			kv.GetSectionName(sType, sizeof(sType));
			kv.GetString(NULL_STRING, sValue, sizeof(sValue));
			
			//Load and push into array if successful
			TagsFilterStruct filterStruct;
			if (filterStruct.Load(sType, sValue))
				filter.PushArray(filterStruct);
			else
				LogMessage("WARNING: Invalid type found in '%s' filter (%s)", sType, sValue);
		}
		while (kv.GotoNextKey(false));
		kv.GoBack();	//From list of filters
		kv.GoBack();	//From "filter" key
		
		return filter;
	}
	
	public bool IsAllowed(int iClient, TagsParams tParams = null)
	{
		if (this == null)	//No filters made/exist, allow
			return true;
		
		int iLength = this.Length;
		for (int i = 0; i < iLength; i++)
		{
			TagsFilterStruct filterStruct;
			this.GetArray(i, filterStruct);
			
			if (!filterStruct.IsAllowed(iClient, tParams))
				return false;
		}
		
		//All checked without any false, should be good
		return true;
	}
}

TagsFilterType TagsFilter_GetType(const char[] sTarget)
{
	static StringMap mFilterType;
	
	if (mFilterType == null)
	{
		mFilterType = new StringMap();
		mFilterType.SetValue("cond", TagsFilterType_Cond);
		mFilterType.SetValue("activeweapon", TagsFilterType_ActiveWeapon);
		mFilterType.SetValue("attackweapon", TagsFilterType_AttackWeapon);
		mFilterType.SetValue("damagemax", TagsFilterType_DamageMaximum);
		mFilterType.SetValue("damagemin", TagsFilterType_DamageMinimum);
		mFilterType.SetValue("aim", TagsFilterType_Aim);
		mFilterType.SetValue("sentrytarget", TagsFilterType_SentryTarget);
		mFilterType.SetValue("damagetype", TagsFilterType_DamageType);
		mFilterType.SetValue("damagecustom", TagsFilterType_DamageCustom);
		mFilterType.SetValue("hitfrombehind", TagsFilterType_HitFromBehind);
		mFilterType.SetValue("backstabcount", TagsFilterType_BackstabCount);
		mFilterType.SetValue("feigndeath", TagsFilterType_FeignDeath);
		mFilterType.SetValue("victimuber", TagsFilterType_VictimUber);
		mFilterType.SetValue("selfdamage", TagsFilterType_SelfDamage);
	}
	
	TagsFilterType nFilterType = TagsFilterType_Invalid;
	mFilterType.GetValue(sTarget, nFilterType);
	return nFilterType;
}
