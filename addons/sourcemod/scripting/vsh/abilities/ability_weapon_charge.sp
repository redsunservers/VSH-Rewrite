#define ATTRIB_CHARGE_DURATION_SEC		202
#define ATTRIB_FULL_TURN_CONTROL		639

static float g_flChargeRageDuration[TF_MAXPLAYERS+1];
static bool g_bChargeIsCharging[TF_MAXPLAYERS+1];

static Handle g_hChargeTimer[TF_MAXPLAYERS+1];
static bool g_bChargeJump[TF_MAXPLAYERS+1];

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
		g_bChargeIsCharging[ability.iClient] = false;
		g_hChargeTimer[ability.iClient] = null;
		
		//Hook touchs to check for charge bash damage
		SDKHook(ability.iClient, SDKHook_StartTouchPost, Charge_StartTouch);
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
		if (g_hChargeTimer[iClient] && !(g_bChargeJump[iClient] && GetEntityFlags(iClient) & FL_ONGROUND))
		{
			g_bChargeJump[iClient] = false;
			
			//Make sure boss is still charging during rage
			if (!TF2_IsPlayerInCondition(iClient, TFCond_Charging))
			{
				float flTimeLeft = flDuration - (GetGameTime() - this.flRageLastTime);
				SetEntPropFloat(iClient, Prop_Send, "m_flChargeMeter", (flTimeLeft / flDuration) * 100.0);
				
				TF2_AddCondition(this.iClient, TFCond_Charging, TFCondDuration_Infinite);
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
	
	public void PlayChargeSound()
	{
		if (!g_hChargeTimer[this.iClient])
			return;
		
		//Spam charge sound every second because we like to make this very annoying
		char sSound[PLATFORM_MAX_PATH];
		this.CallFunction("GetSoundAbility", sSound, sizeof(sSound), "CWeaponCharge");
		if (!StrEmpty(sSound))
			EmitSoundToAll(sSound, this.iClient, SNDCHAN_VOICE, SNDLEVEL_SCREAMING);
		
		this.CallFunction("CreateTimer", 1.0, "CWeaponCharge", "PlayChargeSound");
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
		
		this.PlayChargeSound();
		
		this.CallFunction("KillTimer", g_hChargeTimer[this.iClient]);
		g_hChargeTimer[this.iClient] = this.CallFunction("CreateTimer", flDuration, "CWeaponCharge", "OnRageEnd");
	}
	
	public void OnRageEnd()
	{
		g_hChargeTimer[this.iClient] = null;
		g_bChargeJump[this.iClient] = false;
		TF2_RemoveCondition(this.iClient, TFCond_Charging);
		
		//Remove extra duration and turn control
		int iWeapon = TF2_GetItemInSlot(this.iClient, WeaponSlot_Secondary);
		if (IsValidEntity(iWeapon))
		{
			TF2Attrib_SetByDefIndex(iWeapon, ATTRIB_CHARGE_DURATION_SEC, 0.0);
			TF2Attrib_SetByDefIndex(iWeapon, ATTRIB_FULL_TURN_CONTROL, 0.0);
			TF2Attrib_ClearCache(iWeapon);
		}
	}
	
	public void OnButton(int &buttons)
	{
		//If client is holding reload, make him hold attack2, otherwise prevent it
		if (buttons & IN_RELOAD)
			buttons |= IN_ATTACK2;
		else
			buttons &= ~IN_ATTACK2;
		
		//If attempted to jump while charge rage, remove charge cond to allow jump
		if (buttons & IN_JUMP && g_hChargeTimer[this.iClient] && GetEntityFlags(this.iClient) & FL_ONGROUND)
		{
			g_bChargeJump[this.iClient] = true;
			TF2_RemoveCondition(this.iClient, TFCond_Charging);
		}
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
	
	public void Destroy()
	{
		SDKUnhook(this.iClient, SDKHook_StartTouchPost, Charge_StartTouch);
	}
};

public void Charge_StartTouch(int iClient, int iToucher)
{
	if (TF2_IsPlayerInCondition(iClient, TFCond_Charging))
	{
		if (0 < iToucher <= MaxClients && GetClientTeam(iClient) != GetClientTeam(iToucher) && GetClientTeam(iToucher) > 1)
		{
			//Deal damage a frame later, otherwise possible crash
			DataPack data = new DataPack();
			data.WriteCell(EntIndexToEntRef(iClient));
			data.WriteCell(EntIndexToEntRef(iToucher));
			
			RequestFrame(Charge_BashDamage, data);
		}
		else if (iToucher > MaxClients && IsValidEdict(iToucher))
		{
			//Check if building, and deal damage
			char sClassname[256];
			GetEntityClassname(iToucher, sClassname, sizeof(sClassname));
			if (StrEqual(sClassname, "obj_sentrygun") || StrEqual(sClassname, "obj_dispenser") || StrEqual(sClassname, "obj_teleporter"))
			{
				int iTeam = GetEntProp(iToucher, Prop_Send, "m_iTeamNum");
				if (iTeam != GetClientTeam(iClient) && iTeam > 1)
				{
					DataPack data = new DataPack();
					data.WriteCell(EntIndexToEntRef(iClient));
					data.WriteCell(EntIndexToEntRef(iToucher));
					
					RequestFrame(Charge_BashDamage, data);
				}
			}
		}
	}
}

public void Charge_BashDamage(DataPack data)
{
	data.Reset();
	int iClient = EntRefToEntIndex(data.ReadCell());
	int iToucher = EntRefToEntIndex(data.ReadCell());
	delete data;
	
	//Client check
	if (iClient <= 0 || iClient > MaxClients || !IsClientInGame(iClient) || !IsPlayerAlive(iClient))
		return;
	
	if (0 < iToucher <= MaxClients && IsClientInGame(iToucher) && IsPlayerAlive(iToucher))
	{
		//Player damage
		int iWeapon = TF2_GetItemInSlot(iClient, WeaponSlot_Secondary);
		if (iWeapon > MaxClients && IsValidEdict(iWeapon))
			SDKHooks_TakeDamage(iToucher, iWeapon, iClient, 500.0, DMG_CLUB, iWeapon);
	}
	else if (iToucher > MaxClients && IsValidEdict(iToucher))
	{
		//Building damage
		int iWeapon = TF2_GetItemInSlot(iClient, WeaponSlot_Secondary);
		if (iWeapon > MaxClients && IsValidEdict(iWeapon))
			SDKHooks_TakeDamage(iToucher, iWeapon, iClient, 500.0, DMG_CLUB, iWeapon);
	}
}
