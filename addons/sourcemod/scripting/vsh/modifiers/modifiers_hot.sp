methodmap CModifiersHot < SaxtonHaleBase
{
	public CModifiersHot(CModifiersHot boss)
	{
	}
	
	public void GetModifiersName(char[] sName, int length)
	{
		strcopy(sName, length, "Hot");
	}
	
	public void GetModifiersInfo(char[] sInfo, int length)
	{
		StrCat(sInfo, length, "\nColor: Red");
		StrCat(sInfo, length, "\n ");
		StrCat(sInfo, length, "\n- Ignites nearby players for 10 seconds, dealing 3 damage");
		StrCat(sInfo, length, "\n- Boss ignites when taking any damage");
	}
	
	public int GetRenderColor(int iColor[4])
	{
		iColor[0] = 255;
		iColor[1] = 64;
		iColor[2] = 64;
		iColor[3] = 255;
	}
	
	public void OnThink()
	{
		int iTeam = GetClientTeam(this.iClient);
		
		if (!IsPlayerAlive(this.iClient)) return;
		
		float vecClientPos[3];
		GetClientAbsOrigin(this.iClient, vecClientPos);
		
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) > 1 && GetClientTeam(i) != iTeam)
			{
				float vecTargetPos[3];
				GetClientAbsOrigin(i, vecTargetPos);
				
				if (GetVectorDistance(vecClientPos, vecTargetPos) < 200.0)
					TF2_IgnitePlayer(i, this.iClient);
			}
		}
	}
	
	public Action OnAttackDamage(int &victim, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
	{
		if (damagetype & DMG_BURN)
		{
			damage *= 0.75;
			return Plugin_Changed;
		}
		
		return Plugin_Continue;
	}
	
	public Action OnTakeDamage(int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
	{
		if (TF2_IsUbercharged(this.iClient))
			return Plugin_Continue;
		
		if (damagetype & DMG_BURN)
		{
			damage *= 3.0;
			if (damage > 12.0) damage = 12.0;
			return Plugin_Continue;
		}
		
		if (0 < attacker <= MaxClients && IsClientInGame(attacker))
			TF2_IgnitePlayer(this.iClient, attacker);
		
		return Plugin_Continue;
	}
};