#define MAX_AMMO_LEVEL_1	75
#define MAX_AMMO_LEVEL_2	100

public void WeaponSentry_Create(SaxtonHaleBase boss)
{
}

public void WeaponSentry_OnSpawn(SaxtonHaleBase boss)
{
	TF2_SetAmmo(boss.iClient, TF_AMMO_METAL, 0);
	boss.CallFunction("CreateWeapon", 25, "tf_weapon_pda_engineer_build", 100, TFQual_Unusual, "");
}

public Action WeaponSentry_OnGiveNamedItem(SaxtonHaleBase boss, const char[] sClassname, int iIndex)
{
	//Allow keep tf_weapon_builder
	if (StrEqual(sClassname, "tf_weapon_builder"))
		return Plugin_Continue;
	
	return Plugin_Handled;
}

public Action WeaponSentry_OnBuild(SaxtonHaleBase boss, TFObjectType nType, TFObjectMode nMode)
{
	if (nType == TFObject_Sentry)	//Allow sentry to be built, block otherwise
		return Plugin_Continue;
	
	return Plugin_Handled;
}

public Action WeaponSentry_OnBuildObject(SaxtonHaleBase boss, Event event)
{
	int iSentry = event.GetInt("index");
	int iAliveCount = SaxtonHale_GetAliveAttackPlayers();
	
	int iSentryHealth = iAliveCount * 100 + 200;
	
	SetEntProp(iSentry, Prop_Send, "m_bCarryDeploy", true);
	SetEntData(iSentry, FindSendPropInfo("CObjectSentrygun", "m_flPercentageConstructed") - 8, iSentryHealth);	//m_iHealthOnPickup
	
	SetVariantInt(iSentryHealth);
	AcceptEntityInput(iSentry, "SetHealth");	//Sets sentry health
	
	SDK_RemoveObject(boss.iClient, iSentry);	//Make the boss not the sentry's original owner so he gets to potentially build more of them
	
	if (boss.bSuperRage)	//lvl 2 sentry
		SetEntProp(iSentry, Prop_Send, "m_iHighestUpgradeLevel", 2);
	
	return Plugin_Continue;
}

public Action WeaponSentry_OnObjectSapped(SaxtonHaleBase boss, Event event)
{
	int iVictim = GetClientOfUserId(event.GetInt("ownerid"));
	
	//Prevent sapper from disabling sentry, only let damage over time
	int iSentry = MaxClients+1;
	while((iSentry = FindEntityByClassname(iSentry, "obj_sentrygun")) > MaxClients)
		if (GetEntPropEnt(iSentry, Prop_Send, "m_hBuilder") == iVictim)
			SetEntProp(iSentry, Prop_Send, "m_bDisabled", 0);
	
	return Plugin_Continue;
}

public void WeaponSentry_OnRage(SaxtonHaleBase boss)
{
	TF2_SetAmmo(boss.iClient, TF_AMMO_METAL, 130);
	FakeClientCommand(boss.iClient, "build 2 0");
}

public void WeaponSentry_OnThink(SaxtonHaleBase boss)
{
	int iSentry = MaxClients+1;
	while((iSentry = FindEntityByClassname(iSentry, "obj_sentrygun")) > MaxClients)
	{
		if (GetEntPropEnt(iSentry, Prop_Send, "m_hBuilder") == boss.iClient)
		{
			if (!GetEntProp(iSentry, Prop_Send, "m_bPlacing"))	//For 200% rage, instant build lvl 2 sentry
				SetEntData(iSentry, FindSendPropInfo("CObjectSentrygun", "m_bServerOverridePlacement") + 28, true, 1);	//m_bForceQuickBuild
			
			if (GetEntPropFloat(iSentry, Prop_Send, "m_flModelScale") != 1.22)
				SetEntPropFloat(iSentry, Prop_Send, "m_flModelScale", 1.22);
			
			//m_iState: 0 is being carried or in the process of building, 1 is idle (can be either enabled or disabled), 2 is shooting at a target or being wrangled, 3 is in the process of upgrading
			if (GetEntProp(iSentry, Prop_Send, "m_iState") > 0)
			{
				//Set turn rate super crazy
				int iOffsetState = FindSendPropInfo("CObjectSentrygun", "m_iState");
				SetEntData(iSentry, iOffsetState + 24, 1000);	//m_iBaseTurnRate
				SetEntDataFloat(iSentry, iOffsetState + 44, GetRandomFloat(-90.0, 90.0));	//m_vecGoalAngles.x
				SetEntDataFloat(iSentry, iOffsetState + 48, GetRandomFloat(0.0, 360.0));	//m_vecGoalAngles.y
				
				int iOffsetAmmoShells = FindSendPropInfo("CObjectSentrygun", "m_iAmmoShells");
				int iOldAmmoShells = GetEntData(iSentry, iOffsetAmmoShells + 16);
				if (iOldAmmoShells == 0)	//m_iOldAmmoShells
				{
					//Sentry finished construction, start filling ammo
					if (GetEntProp(iSentry, Prop_Send, "m_iHighestUpgradeLevel") == 1)
					{
						SetEntProp(iSentry, Prop_Send, "m_iAmmoShells", MAX_AMMO_LEVEL_1);
						SetEntData(iSentry, iOffsetAmmoShells + 4, MAX_AMMO_LEVEL_1);	//m_iMaxAmmoShells
						SetEntData(iSentry, iOffsetAmmoShells + 16, MAX_AMMO_LEVEL_1);	//m_iOldAmmoShells
					}
					else
					{
						SetEntProp(iSentry, Prop_Send, "m_iAmmoShells", MAX_AMMO_LEVEL_2);
						SetEntData(iSentry, iOffsetAmmoShells + 4, MAX_AMMO_LEVEL_2);	//m_iMaxAmmoShells
						SetEntData(iSentry, iOffsetAmmoShells + 16, MAX_AMMO_LEVEL_2);	//m_iOldAmmoShells
					}
				}
				else
				{
					int iAmmoShells = GetEntProp(iSentry, Prop_Send, "m_iAmmoShells");
					if (iAmmoShells == 0)
					{
						//No more ammo to shoot
						SetVariantInt(999999);
						AcceptEntityInput(iSentry, "RemoveHealth");
					}
					else if (iAmmoShells < iOldAmmoShells)
					{
						//Sentry just shoot ammo, update values and reduce sentry health
						SetEntData(iSentry, iOffsetAmmoShells + 4, iAmmoShells);	//m_iMaxAmmoShells
						SetEntData(iSentry, iOffsetAmmoShells + 16, iAmmoShells);	//m_iOldAmmoShells
						
						float flPercentage = float(iOldAmmoShells - iAmmoShells);
						if (GetEntProp(iSentry, Prop_Send, "m_iHighestUpgradeLevel") == 1)
							flPercentage /= MAX_AMMO_LEVEL_1;
						else
							flPercentage /= MAX_AMMO_LEVEL_2;
						
						int iRemoveHealth = RoundToFloor(flPercentage * float(GetEntProp(iSentry, Prop_Send, "m_iMaxHealth")));
						SetVariantInt(iRemoveHealth);
						AcceptEntityInput(iSentry, "RemoveHealth");
					}
				}
			}
		}
	}
}

public void WeaponSentry_GetHudInfo(SaxtonHaleBase boss, char[] sMessage, int iLength, int iColor[4])
{
	StrCat(sMessage, iLength, "\nUse your rage to build sentry!");
}

public void WeaponSentry_Destroy(SaxtonHaleBase boss)
{
	int iSentry = MaxClients+1;
	while((iSentry = FindEntityByClassname(iSentry, "obj_sentrygun")) > MaxClients)
	{
		if (GetEntPropEnt(iSentry, Prop_Send, "m_hBuilder") == boss.iClient)
		{
			SetVariantInt(999999);
			AcceptEntityInput(iSentry, "RemoveHealth");
		}
	}
}
