public void WeaponFists_OnPlayerKilled(SaxtonHaleBase boss, Event event, int iVictim)
{
	int iWeaponId = event.GetInt("weaponid");
	
	if (iWeaponId == TF_WEAPON_SHOVEL || iWeaponId == TF_WEAPON_BOTTLE)
	{
		event.SetString("weapon_logclassname", "fists");	//Update his kills to be more like fists
		event.SetString("weapon", "fists");
		event.SetInt("weaponid", TF_WEAPON_FISTS);
	}
}

public void WeaponFists_OnDestroyObject(SaxtonHaleBase boss, Event event)
{
	int iWeaponId = event.GetInt("weaponid");
	
	if (iWeaponId == TF_WEAPON_SHOVEL || iWeaponId == TF_WEAPON_BOTTLE)
	{
		//event.SetString("weapon_logclassname", "fists");	//Update his kills to be more like fists
		event.SetString("weapon", "fists");
		event.SetInt("weaponid", TF_WEAPON_FISTS);
	}
}
