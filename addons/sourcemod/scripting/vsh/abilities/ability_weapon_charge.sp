#define ATTRIB_CHARGE_DURATION_SEC		202
#define ATTRIB_FULL_TURN_CONTROL		639

static float g_flChargeRageDuration[TF_MAXPLAYERS+1];
static float g_flChargePreviousSound[TF_MAXPLAYERS+1];
static bool g_bChargeIsCharging[TF_MAXPLAYERS+1] = false;
static bool g_bChargeRage[TF_MAXPLAYERS+1] = false;
static bool g_bChargeJump[TF_MAXPLAYERS+1] = false;

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
		g_bChargeIsCharging[ability.iClient] = false;
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
		
		Hud_AddText(iClient, "Use your reload key to charge!");
		
		//Check if currently rage charging, and not attempting to jump
		if (g_bChargeRage[iClient] && this.flRageLastTime > GetGameTime() - flDuration && !(g_bChargeJump[iClient] && GetEntityFlags(iClient) & FL_ONGROUND))
		{
			g_bChargeJump[iClient] = false;
			
			//Spam charge sound every second because we like to make this very annoying
			if (g_flChargePreviousSound[iClient] < GetGameTime() - 1.0)
			{
				char sSound[PLATFORM_MAX_PATH];
				this.CallFunction("GetSoundAbility", "CWeaponCharge", sSound, sizeof(sSound));
				if (!StrEmpty(sSound))
					EmitSoundToAll(sSound, iClient, SNDCHAN_VOICE, SNDLEVEL_SCREAMING);
				
				g_flChargePreviousSound[iClient] = GetGameTime();
			}
			
			//Make sure boss is still charging during rage
			if (!TF2_IsPlayerInCondition(iClient, TFCond_Charging))
			{
				float flTimeLeft = flDuration - (GetGameTime() - this.flRageLastTime);
				SetEntPropFloat(iClient, Prop_Send, "m_flChargeMeter", (flTimeLeft / flDuration) * 100.0);
				
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
		
		if (TF2_IsPlayerInCondition(iClient, TFCond_Charging))
		{
			if (!g_bChargeIsCharging[iClient])
			{
				g_bChargeIsCharging[iClient] = true;
				this.flSpeed *= 2.0;
			}
		}
		else
		{
			if (g_bChargeIsCharging[iClient])
			{
				g_bChargeIsCharging[iClient] = false;
				this.flSpeed /= 2.0;
			}
		}
	}
	
	public void OnRage()
	{
		int iClient = this.iClient;
		float flDuration = this.flRageDuration * (this.bSuperRage ? 2 : 1);
		
		//Give Chargin Targe extra duration and full turn control
		int iWeapon = TF2_GetItemInSlot(iClient, WeaponSlot_Secondary);
		if (IsValidEdict(iWeapon))
		{
			TF2Attrib_SetByDefIndex(iWeapon, ATTRIB_CHARGE_DURATION_SEC, flDuration - 1.5);	//1.5 sec from Chargin Targe normal duration
			TF2Attrib_SetByDefIndex(iWeapon, ATTRIB_FULL_TURN_CONTROL, 50.0);	//Apparently value is 50 for Tide Turner
			TF2Attrib_ClearCache(iWeapon);
		}
		
		//Force boss to charge in Think()
		g_bChargeRage[iClient] = true;
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
};