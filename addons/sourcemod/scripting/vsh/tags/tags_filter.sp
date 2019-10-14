enum TagsFilterType			//List of possible filters
{
	TagsFilterType_Invalid = -1,
	TagsFilterType_Cond = 0,
	TagsFilterType_ActiveWeapon,
	TagsFilterType_AttackWeapon,
	TagsFilterType_Aim,
	TagsFilterType_SentryTarget,
	TagsFilterType_DamageType,
	TagsFilterType_DamageCustom,
	TagsFilterType_BackstabCount,
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
			case TagsFilterType_Cond, TagsFilterType_BackstabCount:
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
			case TagsFilterType_Aim, TagsFilterType_SentryTarget:
			{
				this.nValue = 1;
				return true;
			}
			case TagsFilterType_DamageType:
			{
				this.nValue = TagsFilter_GetDamageType(sValue);
				return this.nValue != 0;
			}
			case TagsFilterType_DamageCustom:
			{
				this.nValue = TagsFilter_GetDamageCustom(sValue);
				return this.nValue != 0;
			}
		}
		
		return false;
	}
	
	bool IsAllowed(int iClient)
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
				int iTargetWeapon = TagsTarget_GetTarget(iClient, this.nValue);
				int iActiveWeapon = GetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon");
				return (iTargetWeapon > MaxClients && iTargetWeapon == iActiveWeapon);
			}
			case TagsFilterType_AttackWeapon:
			{
				int iSlot = TagsTarget_GetWeaponSlot(this.nValue);
				return (TagsDamage_GetWeapon() == TF2_GetItemInSlot(TagsDamage_GetAttacker(), iSlot));
			}
			case TagsFilterType_Aim:
			{
				return SaxtonHale_IsValidBoss(Client_GetEyeTarget(iClient));
			}
			case TagsFilterType_SentryTarget:
			{
				int iSentry = Client_GetBuilding(iClient, "obj_sentrygun");
				if (iSentry > MaxClients)
				{
					//Check if target is valid boss
					int iTarget = GetEntPropEnt(iSentry, Prop_Send, "m_hEnemy");
					return SaxtonHale_IsValidBoss(iTarget);
				}
			}
			case TagsFilterType_DamageType:
			{
				return TagsDamage_HasDamageType(this.nValue);
			}
			case TagsFilterType_DamageCustom:
			{
				return TagsDamage_HasDamageCustom(this.nValue);
			}
			case TagsFilterType_BackstabCount:
			{
				return Tags_GetBackstabCount(iClient, TagsDamage_GetVictim()) >= this.nValue;
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
	
	public bool IsAllowed(int iClient)
	{
		if (this == null)	//No filters made/exist, allow
			return true;
		
		int iLength = this.Length;
		for (int i = 0; i < iLength; i++)
		{
			TagsFilterStruct filterStruct;
			this.GetArray(i, filterStruct);
			
			if (!filterStruct.IsAllowed(iClient))
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
		mFilterType.SetValue("aim", TagsFilterType_Aim);
		mFilterType.SetValue("sentrytarget", TagsFilterType_SentryTarget);
		mFilterType.SetValue("damagetype", TagsFilterType_DamageType);
		mFilterType.SetValue("damagecustom", TagsFilterType_DamageCustom);
		mFilterType.SetValue("backstabcount", TagsFilterType_BackstabCount);
	}
	
	TagsFilterType nFilterType = TagsFilterType_Invalid;
	mFilterType.GetValue(sTarget, nFilterType);
	return nFilterType;
}

int TagsFilter_GetDamageType(const char[] sDamageType)
{
	static StringMap mDamageType;
	
	if (mDamageType == null)
	{
		mDamageType = new StringMap();
		mDamageType.SetValue("crit", DMG_CRIT);
		mDamageType.SetValue("notcrit", -DMG_CRIT); //Negative number to indicate we don't want this instead
		mDamageType.SetValue("fall", DMG_FALL);
		mDamageType.SetValue("blast", DMG_BLAST);
		mDamageType.SetValue("shock", DMG_SHOCK);
	}
	
	int iDamageType = 0;
	mDamageType.GetValue(sDamageType, iDamageType);
	return iDamageType;
}

int TagsFilter_GetDamageCustom(const char[] sDamageCustom)
{
	static StringMap mDamageCustom;
	
	if (mDamageCustom == null)
	{
		mDamageCustom = new StringMap();
		mDamageCustom.SetValue("headshot", TF_CUSTOM_HEADSHOT);
		mDamageCustom.SetValue("notheadshot", -TF_CUSTOM_HEADSHOT); //Negative number to indicate we don't want this instead
		mDamageCustom.SetValue("backstab", TF_CUSTOM_BACKSTAB);
		mDamageCustom.SetValue("stomp", TF_CUSTOM_BOOTS_STOMP);
	}
	
	int iDamageCustom = 0;
	mDamageCustom.GetValue(sDamageCustom, iDamageCustom);
	return iDamageCustom;
}