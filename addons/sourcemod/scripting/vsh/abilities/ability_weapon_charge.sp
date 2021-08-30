#define ATTRIB_CHARGE_DURATION_SEC		202
#define ATTRIB_FULL_TURN_CONTROL		639

static float g_flChargeRageDuration[TF_MAXPLAYERS];
static float g_flChargePreviousSound[TF_MAXPLAYERS];
static bool g_bChargeIsCharging[TF_MAXPLAYERS];
static bool g_bChargeRage[TF_MAXPLAYERS];
static bool g_bChargeJump[TF_MAXPLAYERS];

methodmap CWeaponCharge < SaxtonHaleBase
{
	property float flRageDuration
	{
		public set(float flVal)
		{
			g_flChargeRageDuration[this.iClient] = flVal;
		}
		public get()
		{
			return g_flChargeRageDuration[this.iClient];
		}
	}
	
	public CWeaponCharge(CWeaponCharge ability)
	{
		g_flChargeRageDuration[ability.iClient] = 5.0;
		g_flChargePreviousSound[ability.iClient] = 0.0;
		g_bChargeRage[ability.iClient] = false;
	}
	
	public void OnSpawn()
	{
		this.CallFunction("CreateWeapon", 131, "tf_wearable_demoshield", 0, TFQual_Normal, "");
	}
	
	public void OnThink()
	{
		int iClient = this.iClient;
		float flDuration = this.flRageDuration * (this.bSuperRage ? 2 : 1);
		
		//Check if currently rage charging, and not attempting to jump
		if (g_bChargeRage[iClient] && this.flRageLastTime > GetGameTime() - flDuration && !(g_bChargeJump[iClient] && GetEntityFlags(iClient) & FL_ONGROUND))
		{
			g_bChargeJump[iClient] = false;
			
			//Spam charge sound every second because we like to make this very annoying
			if (g_flChargePreviousSound[iClient] < GetGameTime() - 1.0)
			{
				char sSound[PLATFORM_MAX_PATH];
				this.CallFunction("GetSoundAbility", sSound, sizeof(sSound), "CWeaponCharge");
				if (!StrEmpty(sSound))
					EmitSoundToAll(sSound, iClient, SNDCHAN_VOICE, SNDLEVEL_SCREAMING);
				
				g_flChargePreviousSound[iClient] = GetGameTime();
			}
			
			float vecVel[3];
			GetEntPropVector(iClient, Prop_Data, "m_vecVelocity", vecVel);
			float flSpeed = GetVectorLength(vecVel);
			if (flSpeed < 300.0 && TF2_IsPlayerInCondition(iClient, TFCond_Charging))
				TF2_RemoveCondition(iClient, TFCond_Charging);
			
			if (!g_bChargeIsCharging[this.iClient])	//TF2_IsPlayerInCondition can be a lie when it comes to OnConditionAdded/OnConditionRemoved
			{
				//Make sure boss is still charging during rage
				SetEntPropFloat(this.iClient, Prop_Send, "m_flChargeMeter", 100.0);
				TF2_AddCondition(this.iClient, TFCond_Charging, TFCondDuration_Infinite);
			}
		}
		else if (g_bChargeRage[iClient] && this.flRageLastTime <= GetGameTime() - flDuration)
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
	
	public void GetHudText(char[] sMessage, int iLength)
	{
		StrCat(sMessage, iLength, "\nUse your reload key to charge!");
	}
	
	public void OnRage()
	{
		float flDuration = this.flRageDuration * (this.bSuperRage ? 2 : 1);
		
		//Give Chargin Targe extra duration and full turn control
		int iWeapon = TF2_GetItemInSlot(this.iClient, WeaponSlot_Secondary);
		if (IsValidEdict(iWeapon))
		{
			TF2Attrib_SetByDefIndex(iWeapon, ATTRIB_CHARGE_DURATION_SEC, flDuration - 1.5);	//1.5 sec from Chargin Targe normal duration
			TF2Attrib_SetByDefIndex(iWeapon, ATTRIB_FULL_TURN_CONTROL, 50.0);	//Apparently value is 50 for Tide Turner
			TF2Attrib_ClearCache(iWeapon);
		}
		
		//Force boss to charge in Think()
		g_bChargeRage[this.iClient] = true;
	}
	
	public void OnButton(int &buttons)
	{
		//If client is holding reload, make him hold attack2, otherwise prevent it
		if (buttons & IN_RELOAD)
			buttons |= IN_ATTACK2;
		else
			buttons &= ~IN_ATTACK2;
		
		//If attempted to jump while charge rage, remove charge cond to allow jump
		if (buttons & IN_JUMP && g_bChargeRage[this.iClient] && GetEntityFlags(this.iClient) & FL_ONGROUND)
		{
			g_bChargeJump[this.iClient] = true;
			TF2_RemoveCondition(this.iClient, TFCond_Charging);
		}
	}
	
	public void OnConditionAdded(TFCond nCond)
	{
		if (nCond == TFCond_Charging)
		{
			g_bChargeIsCharging[this.iClient] = true;
			this.flSpeed *= 2.0;
			
			if (g_bChargeRage[this.iClient])
			{
				float flDuration = this.flRageDuration * (this.bSuperRage ? 2 : 1);
				float flTimeLeft = flDuration - (GetGameTime() - this.flRageLastTime);
				SetEntPropFloat(this.iClient, Prop_Send, "m_flChargeMeter", (flTimeLeft / flDuration) * 100.0);
			}
		}
	}
	
	public void OnConditionRemoved(TFCond nCond)
	{
		if (nCond == TFCond_Charging)
		{
			g_bChargeIsCharging[this.iClient] = false;
			this.flSpeed /= 2.0;
		}
		
		if (nCond == TFCond_Charging && !(g_bChargeJump[this.iClient] && GetEntityFlags(this.iClient) & FL_ONGROUND))
		{
			//Find player infront of it
			
			float vecStart[3], vecEnd[3], vecAngles[3], vecForward[3];
			GetClientAbsOrigin(this.iClient, vecStart);			
			vecStart[2] += 32.0;
			
			GetClientEyeAngles(this.iClient, vecAngles);
			vecAngles[0] = 0.0;
			GetAngleVectors(vecAngles, vecForward, NULL_VECTOR, NULL_VECTOR);
			ScaleVector(vecForward, 48.0);
			AddVectors(vecStart, vecForward, vecEnd);
			
			//Trace
			TR_TraceHullFilter(vecStart, vecEnd, view_as<float>({-24.0, -24.0, -24.0}), view_as<float>({24.0, 24.0, 24.0}), MASK_PLAYERSOLID, TraceRay_HitEnemyPlayersAndObjects, this.iClient);
			
			if (TR_DidHit())
			{
				int iWeapon = TF2_GetItemInSlot(this.iClient, WeaponSlot_Secondary);
				int iEntity = TR_GetEntityIndex();
				
				if (0 < iEntity <= MaxClients)
				{
					GetAngleVectors(vecAngles, vecForward, NULL_VECTOR, NULL_VECTOR);
					ScaleVector(vecForward, 1000.0);
					
					float vecVictim[3];
					GetEntPropVector(iEntity, Prop_Data, "m_vecVelocity", vecVictim);
					AddVectors(vecVictim, vecForward, vecVictim);
					TeleportEntity(iEntity, NULL_VECTOR, NULL_VECTOR, vecVictim);
					
					SDKHooks_TakeDamage(iEntity, iWeapon, this.iClient, 150.0, DMG_CLUB, iWeapon, vecForward, vecStart);
				}
				else if (iEntity > MaxClients)
				{
					//obj_
					SDKHooks_TakeDamage(iEntity, iWeapon, this.iClient, 500.0, DMG_CLUB, iWeapon);
				}
			}
		}
	}
	
	public Action OnAttackDamage(int victim, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
	{
		if (damagecustom == TF_CUSTOM_CHARGE_IMPACT)
			return Plugin_Stop;	//We want to do the dmg, not TF2. SDKHooks_TakeDamage doesn't allow custom dmg stuff
		
		return Plugin_Continue;
	}
	
	public Action OnPlayerKilled(Event event, int iVictim)
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
	}
};