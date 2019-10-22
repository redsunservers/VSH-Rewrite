static float g_flZombieLastDamage[TF_MAXPLAYERS+1];

methodmap CZombie < SaxtonHaleBase
{
	public CZombie(CZombie boss)
	{
		boss.nClass = TFClass_Scout;
		boss.flSpeed = -1.0;
		boss.iMaxRageDamage = -1;
		boss.bMinion = true;
		boss.bModel = false;
		
		SetEntityRenderColor(boss.iClient, 206, 100, 100, _);
		EmitSoundToClient(boss.iClient, SOUND_ALERT);	//Alert player as he spawned
	}
	
	public bool IsBossHidden()
	{
		return true;
	}
	
	public void OnSpawn()
	{
		int iWeapon = this.CallFunction("CreateWeapon", 0, "tf_weapon_bat", 0, TFQual_Normal, "");
		if (iWeapon > MaxClients)
			SetEntPropEnt(this.iClient, Prop_Send, "m_hActiveWeapon", iWeapon);
		
		TF2_AddCondition(this.iClient, TFCond_CritOnDamage, TFCondDuration_Infinite);
		
		SetVariantString("TLK_RESURRECTED");
		AcceptEntityInput(this.iClient, "SpeakResponseConcept");
	}
	
	public void OnThink()
	{
		int iClient = this.iClient;
		
		if (!IsPlayerAlive(iClient)) return;
		
		if (g_flZombieLastDamage[iClient] == 0.0 || g_flZombieLastDamage[iClient] <= GetGameTime()-1.0)
		{
			SDKHooks_TakeDamage(iClient, 0, iClient, float(RoundToCeil(SDK_GetMaxHealth(iClient)*0.04)), DMG_PREVENT_PHYSICS_FORCE);
			g_flZombieLastDamage[iClient] = GetGameTime();
		}
		
		if (!TF2_IsPlayerInCondition(iClient, TFCond_Bleeding))
			TF2_MakeBleed(iClient, iClient, 99999.0);
	}
	
	public Action OnAttackDamage(int &victim, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
	{
		if (this.iClient != victim && GetClientTeam(this.iClient) != GetClientTeam(victim))
		{
			int iHeal = RoundToNearest(damage);
			if (iHeal > 20) iHeal = 20;
			
			Client_AddHealth(this.iClient, iHeal, 0);
		}
	}
	
	public Action OnVoiceCommand(char sCmd1[8], char sCmd2[8])
	{
		if (sCmd1[0] == '0' && sCmd2[0] == '0')
		{
			//Since zombie scout cant get healed from medic, dont allow him to call medic
			PrintHintText(this.iClient, "You can't heal as zombie!");
			return Plugin_Handled;
		}
		
		return Plugin_Continue;
	}
	
	public void Destroy()
	{
		SetEntityRenderColor(this.iClient, 255, 255, 255, _);
		
		if (TF2_IsPlayerInCondition(this.iClient, TFCond_CritOnDamage))
			TF2_RemoveCondition(this.iClient, TFCond_CritOnDamage);
	}
};