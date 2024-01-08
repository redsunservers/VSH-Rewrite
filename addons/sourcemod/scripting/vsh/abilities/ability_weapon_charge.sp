#define ATTRIB_CHARGE_DURATION_SEC		202
#define ATTRIB_FULL_TURN_CONTROL		639

static float g_flChargePreviousSound[MAXPLAYERS];
static bool g_bChargeIsCharging[MAXPLAYERS];
static bool g_bChargeRage[MAXPLAYERS];
static bool g_bChargeJump[MAXPLAYERS];

public void WeaponCharge_Create(SaxtonHaleBase boss)
{
	g_flChargePreviousSound[boss.iClient] = 0.0;
	g_bChargeRage[boss.iClient] = false;
	
	boss.SetPropFloat("WeaponCharge", "RageDuration", 5.0);
}

public void WeaponCharge_OnSpawn(SaxtonHaleBase boss)
{
	boss.CallFunction("CreateWeapon", 131, "tf_wearable_demoshield", 0, TFQual_Normal, "");
}

public void WeaponCharge_OnThink(SaxtonHaleBase boss)
{
	int iClient = boss.iClient;
	float flDuration = boss.GetPropFloat("WeaponCharge", "RageDuration") * (boss.bSuperRage ? 2 : 1);
	
	//Check if currently rage charging, and not attempting to jump
	if (g_bChargeRage[iClient] && boss.flRageLastTime > GetGameTime() - flDuration && !(g_bChargeJump[iClient] && GetEntityFlags(iClient) & FL_ONGROUND))
	{
		g_bChargeJump[iClient] = false;
		
		//Spam charge sound every second because we like to make this very annoying
		if (g_flChargePreviousSound[iClient] < GetGameTime() - 1.0)
		{
			char sSound[PLATFORM_MAX_PATH];
			boss.CallFunction("GetSoundAbility", sSound, sizeof(sSound), "WeaponCharge");
			if (!StrEmpty(sSound))
				EmitSoundToAll(sSound, iClient, SNDCHAN_VOICE, SNDLEVEL_SCREAMING);
			
			g_flChargePreviousSound[iClient] = GetGameTime();
		}
		
		float vecVel[3];
		GetEntPropVector(iClient, Prop_Data, "m_vecVelocity", vecVel);
		float flSpeed = GetVectorLength(vecVel);
		if (flSpeed < 300.0 && TF2_IsPlayerInCondition(iClient, TFCond_Charging))
			TF2_RemoveCondition(iClient, TFCond_Charging);
		
		if (!g_bChargeIsCharging[boss.iClient])	//TF2_IsPlayerInCondition can be a lie when it comes to OnConditionAdded/OnConditionRemoved
		{
			//Make sure boss is still charging during rage
			SetEntPropFloat(boss.iClient, Prop_Send, "m_flChargeMeter", 100.0);
			TF2_AddCondition(boss.iClient, TFCond_Charging, TFCondDuration_Infinite);
		}
	}
	else if (g_bChargeRage[iClient] && boss.flRageLastTime <= GetGameTime() - flDuration)
	{
		//Rage ended, remove charge
		g_bChargeRage[iClient] = false;
		g_bChargeJump[iClient] = false;
		TF2_RemoveCondition(iClient, TFCond_Charging);
		
		//Remove extra duration and turn control
		int iWeapon = TF2_GetItemInSlot(iClient, WeaponSlot_Secondary);
		if (IsValidEdict(iWeapon))
		{
			TF2Attrib_SetByDefIndex(iWeapon, ATTRIB_CHARGE_DURATION_SEC, 0.0);
			TF2Attrib_SetByDefIndex(iWeapon, ATTRIB_FULL_TURN_CONTROL, 0.0);
			TF2Attrib_ClearCache(iWeapon);
		}
	}
}

public void WeaponCharge_GetHudInfo(SaxtonHaleBase boss, char[] sMessage, int iLength, int iColor[4])
{
	StrCat(sMessage, iLength, "\nUse your reload key to charge!");
}

public void WeaponCharge_OnRage(SaxtonHaleBase boss)
{
	float flDuration = boss.GetPropFloat("WeaponCharge", "RageDuration") * (boss.bSuperRage ? 2 : 1);
	
	//Give Chargin Targe extra duration and full turn control
	int iWeapon = TF2_GetItemInSlot(boss.iClient, WeaponSlot_Secondary);
	if (IsValidEdict(iWeapon))
	{
		TF2Attrib_SetByDefIndex(iWeapon, ATTRIB_CHARGE_DURATION_SEC, flDuration - 1.5);	//1.5 sec from Chargin Targe normal duration
		TF2Attrib_SetByDefIndex(iWeapon, ATTRIB_FULL_TURN_CONTROL, 50.0);	//Apparently value is 50 for Tide Turner
		TF2Attrib_ClearCache(iWeapon);
	}
	
	//Force boss to charge in Think()
	g_bChargeRage[boss.iClient] = true;
}

public void WeaponCharge_OnButton(SaxtonHaleBase boss, int &buttons)
{
	//If client is holding reload, make him hold attack2, otherwise prevent it
	if (buttons & IN_RELOAD)
		buttons |= IN_ATTACK2;
	else
		buttons &= ~IN_ATTACK2;
	
	//If attempted to jump while charge rage, remove charge cond to allow jump
	if (buttons & IN_JUMP && g_bChargeRage[boss.iClient] && GetEntityFlags(boss.iClient) & FL_ONGROUND)
	{
		g_bChargeJump[boss.iClient] = true;
		TF2_RemoveCondition(boss.iClient, TFCond_Charging);
	}
}

public void WeaponCharge_OnConditionAdded(SaxtonHaleBase boss, TFCond nCond)
{
	if (nCond == TFCond_Charging)
	{
		g_bChargeIsCharging[boss.iClient] = true;
		boss.flSpeed *= 2.0;
		
		if (g_bChargeRage[boss.iClient])
		{
			float flDuration = boss.GetPropFloat("WeaponCharge", "RageDuration") * (boss.bSuperRage ? 2 : 1);
			float flTimeLeft = flDuration - (GetGameTime() - boss.flRageLastTime);
			SetEntPropFloat(boss.iClient, Prop_Send, "m_flChargeMeter", (flTimeLeft / flDuration) * 100.0);
		}
	}
}

public void WeaponCharge_OnConditionRemoved(SaxtonHaleBase boss, TFCond nCond)
{
	if (nCond == TFCond_Charging)
	{
		g_bChargeIsCharging[boss.iClient] = false;
		boss.flSpeed /= 2.0;
	}
	
	if (nCond == TFCond_Charging && !(g_bChargeJump[boss.iClient] && GetEntityFlags(boss.iClient) & FL_ONGROUND))
	{
		//Find player infront of it
		
		float vecStart[3], vecEnd[3], vecAngles[3], vecForward[3];
		GetClientAbsOrigin(boss.iClient, vecStart);			
		vecStart[2] += 32.0;
		
		GetClientEyeAngles(boss.iClient, vecAngles);
		vecAngles[0] = 0.0;
		GetAngleVectors(vecAngles, vecForward, NULL_VECTOR, NULL_VECTOR);
		ScaleVector(vecForward, 48.0);
		AddVectors(vecStart, vecForward, vecEnd);
		
		//Trace
		TR_TraceHullFilter(vecStart, vecEnd, view_as<float>({-24.0, -24.0, -24.0}), view_as<float>({24.0, 24.0, 24.0}), MASK_PLAYERSOLID, TraceRay_HitEnemyPlayersAndObjects, boss.iClient);
		
		if (TR_DidHit())
		{
			int iWeapon = TF2_GetItemInSlot(boss.iClient, WeaponSlot_Secondary);
			int iEntity = TR_GetEntityIndex();
			
			if (0 < iEntity <= MaxClients)
			{
				GetAngleVectors(vecAngles, vecForward, NULL_VECTOR, NULL_VECTOR);
				ScaleVector(vecForward, 1000.0);
				
				float vecVictim[3];
				GetEntPropVector(iEntity, Prop_Data, "m_vecVelocity", vecVictim);
				AddVectors(vecVictim, vecForward, vecVictim);
				TeleportEntity(iEntity, NULL_VECTOR, NULL_VECTOR, vecVictim);
				
				SDKHooks_TakeDamage(iEntity, iWeapon, boss.iClient, 150.0, DMG_CLUB, iWeapon, vecForward, vecStart);
			}
			else if (iEntity > MaxClients)
			{
				//obj_
				SDKHooks_TakeDamage(iEntity, iWeapon, boss.iClient, 500.0, DMG_CLUB, iWeapon);
			}
		}
	}
}

public Action WeaponCharge_OnAttackDamage(SaxtonHaleBase boss, int victim, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if (damagecustom == TF_CUSTOM_CHARGE_IMPACT)
		return Plugin_Stop;	//We want to do the dmg, not TF2. SDKHooks_TakeDamage doesn't allow custom dmg stuff
	
	return Plugin_Continue;
}

public Action WeaponCharge_OnPlayerKilled(SaxtonHaleBase boss, Event event, int iVictim)
{
	//Because SDKHooks_TakeDamage doesnt even set damage sources from chargin targe properly
	char sWeapon[256];
	event.GetString("weapon", sWeapon, sizeof(sWeapon));
	
	if (StrEqual(sWeapon, "tf_wearable_demoshield"))
	{
		event.SetString("weapon_logclassname", "demoshield");
		event.SetString("weapon", "demoshield");
		event.SetInt("customkill", TF_CUSTOM_CHARGE_IMPACT);
	}
	
	return Plugin_Continue;
}
