enum TagsTarget	//List of possible targets
{
	TagsTarget_Invalid = -1,
	
	//Clients
	TagsTarget_Client = 0,
	TagsTarget_Victim,
	TagsTarget_Attacker,
	TagsTarget_Patient,
	
	//Weapons
	TagsTarget_Primary,
	TagsTarget_Secondary,
	TagsTarget_Melee,
	TagsTarget_PDA1,
	TagsTarget_PDA2,
	TagsTarget_Building,
};

int TagsTarget_GetTarget(int iClient, TagsTarget nTarget)
{
	switch (nTarget)
	{
		case TagsTarget_Client: return iClient;
		case TagsTarget_Victim:	return TagsDamage_GetVictim();
		case TagsTarget_Attacker: return TagsDamage_GetAttacker();
		case TagsTarget_Patient: return TF2_GetPatient(iClient);
		
		case TagsTarget_Primary: return TF2_GetItemInSlot(iClient, WeaponSlot_Primary);
		case TagsTarget_Secondary: return TF2_GetItemInSlot(iClient, WeaponSlot_Secondary);
		case TagsTarget_Melee: return TF2_GetItemInSlot(iClient, WeaponSlot_Melee);
		case TagsTarget_PDA1: return TF2_GetItemInSlot(iClient, WeaponSlot_PDABuild);
		case TagsTarget_PDA2: return TF2_GetItemInSlot(iClient, WeaponSlot_PDADestroy);
		case TagsTarget_Building: return TF2_GetItemInSlot(iClient, WeaponSlot_BuilderEngie);
	}
	
	return -1;
}

TagsTarget TagsTarget_GetType(const char[] sTarget)
{
	static StringMap mTarget;
	
	if (mTarget == null)
	{
		mTarget = new StringMap();
		mTarget.SetValue("client", TagsTarget_Client);
		mTarget.SetValue("victim", TagsTarget_Victim);
		mTarget.SetValue("attacker", TagsTarget_Attacker);
		mTarget.SetValue("patient", TagsTarget_Patient);
		mTarget.SetValue("primary", TagsTarget_Primary);
		mTarget.SetValue("secondary", TagsTarget_Secondary);
		mTarget.SetValue("melee", TagsTarget_Melee);
		mTarget.SetValue("pda1", TagsTarget_PDA1);
		mTarget.SetValue("pda2", TagsTarget_PDA2);
		mTarget.SetValue("building", TagsTarget_Building);
	}
	
	TagsTarget nTarget = TagsTarget_Invalid;
	mTarget.GetValue(sTarget, nTarget);
	return nTarget;
}