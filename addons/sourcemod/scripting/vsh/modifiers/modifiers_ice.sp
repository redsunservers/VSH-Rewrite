#define ICE_SLOWDOWN 0.7
#define ICE_DURATION 2.0

static float g_flClientIceSlowdown[TF_MAXPLAYERS+1];

methodmap CModifiersIce < SaxtonHaleBase
{
	public CModifiersIce(CModifiersIce boss)
	{
	}
	
	public void GetModifiersName(char[] sName, int length)
	{
		strcopy(sName, length, "Ice");
	}
	
	public void GetModifiersInfo(char[] sInfo, int length)
	{
		StrCat(sInfo, length, "\nColor: Blue");
		StrCat(sInfo, length, "\n ");
		StrCat(sInfo, length, "\n- Every stomp slows nearby players");
		StrCat(sInfo, length, "\n- Stomp deals no damage");
	}
	
	public int GetRenderColor(int iColor[4])
	{
		iColor[0] = 128;
		iColor[1] = 176;
		iColor[2] = 255;
		iColor[3] = 255;
	}
	
	public void OnPlayerKilled(Event event, int iVictim)
	{
		if (g_flClientIceSlowdown[iVictim] > GetGameTime())
			g_bIceRagdoll = true;
	}
	
	public Action OnTakeDamage(int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
	{		
		if (!(damagetype & DMG_FALL))
			return Plugin_Continue;
		
		int iTeam = GetClientTeam(this.iClient);
		
		float vecClientPos[3];
		GetClientAbsOrigin(this.iClient, vecClientPos);
		
		int iColor[4];
		iColor[0] = 128;
		iColor[1] = 176;
		iColor[2] = 255;
		iColor[3] = 255;
		
		int iLight = TF2_CreateLightEntity(250.0, iColor, 6);
		if (iLight != -1)
		{
			TeleportEntity(iLight, vecClientPos, view_as<float>({ 90.0, 0.0, 0.0 }), NULL_VECTOR);
			
			Handle iData = CreateDataPack();
			WritePackCell(iData, EntIndexToEntRef(iLight));
			WritePackCell(iData, 6);
			CreateTimer(1.0, Timer_IceLight, iData);
			
			CreateTimer(6.0, Timer_DestroyLight, EntIndexToEntRef(iLight));
		}
		
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) > 1 && GetClientTeam(i) != iTeam)
			{
				float vecTargetPos[3];
				GetClientAbsOrigin(i, vecTargetPos);
				
				if (GetVectorDistance(vecClientPos, vecTargetPos) < 250.0)
				{
					g_flClientIceSlowdown[i] = GetGameTime() + ICE_DURATION;
					TF2_StunPlayer(i, ICE_DURATION, ICE_SLOWDOWN, TF_STUNFLAG_SLOWDOWN);
					
					CreateTimer(ICE_DURATION, Timer_ResetSpeed, EntIndexToEntRef(i));
				}
			}
		}
		
		return Plugin_Stop;
	}
};

public void Ice_RagdollSpawn(int iRef)
{
	int iEntity = EntRefToEntIndex(iRef);
	if (iEntity <= 0 || !IsValidEntity(iEntity)) return;
	
	SetEntProp(iEntity, Prop_Send, "m_bIceRagdoll", 1);
}

public Action Timer_IceLight(Handle hTimer, DataPack iData)
{
	ResetPack(iData);
	int iLight = EntRefToEntIndex(ReadPackCell(iData));
	int iBrightness = ReadPackCell(iData);
	delete iData;
	
	if (iLight > MaxClients)
	{
		iBrightness--;
		SetVariantInt(iBrightness);
		AcceptEntityInput(iLight, "brightness");
		
		iData = CreateDataPack();
		WritePackCell(iData, EntIndexToEntRef(iLight));
		WritePackCell(iData, iBrightness);
		CreateTimer(1.0, Timer_IceLight, iData);
	}
}

public Action Timer_ResetSpeed(Handle hTimer, int iRef)
{
	int iClient = EntRefToEntIndex(iRef);
	
	if (iClient <= 0 || iClient > MaxClients || !IsClientInGame(iClient))
		return;
	
	TF2_StunPlayer(iClient, 0.0, 0.0, TF_STUNFLAG_SLOWDOWN);
}