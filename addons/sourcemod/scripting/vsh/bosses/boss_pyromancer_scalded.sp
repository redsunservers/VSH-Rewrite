/*
 * Pyromancer Duo Boss: Scalded Pyromancer
 * By: ScrewdriverHyena
**/

static const float RAGE_DURATION = 8.0;

static float g_flFlamethrowerRemoveTime[TF_MAXPLAYERS+1];

static CRageAddCond addCond;

methodmap CScaldedPyromancer < SaxtonHaleBase
{
	public CScaldedPyromancer(CScaldedPyromancer boss)
	{
		boss.CallFunction("CreateAbility", "CBraveJump");
		addCond = boss.CallFunction("CreateAbility", "CRageAddCond");
		addCond.flRageCondDuration = RAGE_DURATION;
		addCond.AddCond(TFCond_Buffed);
		
		//boostJump.flMaxHeight /= 1.75;
		//boostJump.flMaxDistance = 0.7;
		
		boss.iBaseHealth = 500;
		boss.iHealthPerPlayer = 750;
		boss.nClass = TFClass_Pyro;
		boss.iMaxRageDamage = 1700;
		g_flFlamethrowerRemoveTime[boss.iClient] = 0.0;
	}
	
	public void GetBossMultiType(char[] sType, int length)
	{
		strcopy(sType, length, "CPyromancers");
	}
	
	public bool IsBossHidden()
	{
		return true;
	}
	
	public void GetBossName(char[] sName, int length)
	{
		strcopy(sName, length, "Scalded Pyromancer");
	}
	
	public void GetBossInfo(char[] sInfo, int length)
	{
		StrCat(sInfo, length, "\nDuo Boss: The Pyromancers");
		StrCat(sInfo, length, "\nMelee deals 80 damage.");
		StrCat(sInfo, length, "\nHealth: Low");
		StrCat(sInfo, length, "\n ");
		StrCat(sInfo, length, "\nAbilities");
		StrCat(sInfo, length, "\n- Boost Jump");
		StrCat(sInfo, length, "\n ");
		StrCat(sInfo, length, "\nRage");
		StrCat(sInfo, length, "\n- Grants a degreaser for 8 seconds");
		StrCat(sInfo, length, "\n- 200%% Rage: Grants a buffed backburner with quick-switch for 8 seconds");
	}
	
	public void OnSpawn()
	{
		const int TF_WEAPON_AXTINGUISHER = 38;
		int iWeapon = this.CallFunction("CreateWeapon", TF_WEAPON_AXTINGUISHER, "tf_weapon_fireaxe", 100, TFQual_Collectors, "2 ; 1.82 ; 20 ; 1.0 ; 252 ; 0.5");
		if (iWeapon > MaxClients)
			SetEntPropEnt(this.iClient, Prop_Send, "m_hActiveWeapon", iWeapon);
		
		/*
		Axtinguisher attributes:
		
		2: damage bonus
		20: crit vs burning players
		252: reduction in push force taken from damage
		*/
	}
	
	public void OnRage()
	{
		/*
		Degreaser attributes:
		
		72: reduce burn damage
		199: faster switch-from speed
		252: reduction in push force taken from damage
		547: faster switch-to speed
		839: flame spread degree
		841: flame gravity
		843: flame drag
		844: flame speed
		862: flame lifetime
		863: flame random life time offset
		865: flame up speed
		*/
		#define TF_DEGREASER_ATTRIBS "72 ; 0.75 ; 199 ; 0.7 ; 252 ; 0.5 ; 547 ; 0.4 ; 839 ; 2.8 ; 841 ; 0 ; 843 ; 8.5 ; 844 ; 2450 ; 862 ; 0.6 ; 863 ; 0.1 ; 865 ; 50"
		const int TF_WEAPON_DEGREASER = 215;

		/*
		Backburner attributes:
		
		24: allow crits from behind
		72: reduce burn damage
		199: faster switch-from speed
		252: reduction in push force taken from damage
		547: faster switch-to speed
		839: flame spread degree
		841: flame gravity
		843: flame drag
		844: flame speed
		862: flame lifetime
		863: flame random life time offset
		865: flame up speed
		*/
		#define TF_BACKBURNER_ATTRIBS "24 ; 1.0 ; 72 ; 0.1 ; 199 ; 0.9 ; 252 ; 0.5 ; 547 ; 0.9 ; 839 ; 2.8 ; 841 ; 0 ; 843 ; 8.5 ; 844 ; 2450 ; 862 ; 0.6 ; 863 ; 0.1 ; 865 ; 50"
		const int TF_WEAPON_BACKBURNER = 40;
		
		int iWeapon = this.CallFunction("CreateWeapon", ((this.bSuperRage) ? TF_WEAPON_BACKBURNER : TF_WEAPON_DEGREASER), "tf_weapon_flamethrower", 1, TFQual_Collectors, ((this.bSuperRage) ? TF_BACKBURNER_ATTRIBS : TF_DEGREASER_ATTRIBS));
		if (iWeapon > MaxClients)
		{
			SetEntPropEnt(this.iClient, Prop_Send, "m_hActiveWeapon", iWeapon);
			
			int iAmmoType = GetEntProp(iWeapon, Prop_Send, "m_iPrimaryAmmoType");
			if (iAmmoType > -1)
				SetEntProp(this.iClient, Prop_Send, "m_iAmmo", 999, 4, iAmmoType);
		}
		
		g_flFlamethrowerRemoveTime[this.iClient] = GetGameTime() + RAGE_DURATION;
	}
	
	public void OnThink()
	{
		if (GetGameTime() <= g_flFlamethrowerRemoveTime[this.iClient] && GetGameTime() >= (g_flFlamethrowerRemoveTime[this.iClient] - RAGE_DURATION))
			Hud_AddText(this.iClient, "HINT: Use your axe to crit players after igniting them!");
		else
			Hud_AddText(this.iClient, "HINT: Stay near the other Pyromancer so you can crit the ignited players!");
		
		if (g_flFlamethrowerRemoveTime[this.iClient] != 0.0 && g_flFlamethrowerRemoveTime[this.iClient] <= GetGameTime())
		{
			g_flFlamethrowerRemoveTime[this.iClient] = 0.0;
			TF2_RemoveWeaponSlot(this.iClient, WeaponSlot_Primary);
			
			int iMeleeWep = GetPlayerWeaponSlot(this.iClient, WeaponSlot_Melee);
			if (iMeleeWep > MaxClients)
				SetEntPropEnt(this.iClient, Prop_Send, "m_hActiveWeapon", iMeleeWep);
		}
	}
}