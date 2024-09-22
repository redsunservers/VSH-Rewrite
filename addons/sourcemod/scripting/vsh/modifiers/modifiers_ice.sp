#define ICE_SLOWDOWN 0.7
#define ICE_DURATION 2.0
#define ICE_RANGE 250.0

static bool g_bIceRagdoll;
static float g_flClientIceSlowdown[MAXPLAYERS];

public void ModifiersIce_Create(SaxtonHaleBase boss)
{
}

public void ModifiersIce_GetModifiersName(SaxtonHaleBase boss, char[] sName, int length)
{
	strcopy(sName, length, "Ice");
}

public void ModifiersIce_GetModifiersInfo(SaxtonHaleBase boss, char[] sInfo, int length)
{
	StrCat(sInfo, length, "\nColor: Light Blue");
	StrCat(sInfo, length, "\n ");
	StrCat(sInfo, length, "\n- Every stomp slows nearby players");
	StrCat(sInfo, length, "\n- Stomp deals no damage");
}

public void ModifiersIce_GetRenderColor(SaxtonHaleBase boss, int iColor[4])
{
	iColor[0] = 128;
	iColor[1] = 176;
	iColor[2] = 255;
	iColor[3] = 255;
}

public void ModifiersIce_GetParticleEffect(SaxtonHaleBase boss, int index, char[] sEffect, int length)
{
	switch (index)
	{
		case 0:
			strcopy(sEffect, length, "utaunt_ice_bodyglow");
		
		case 1, 2, 3, 4, 5:
			strcopy(sEffect, length, "utaunt_festivelights_blue_lights1");
	}
}

public void ModifiersIce_OnDeath(SaxtonHaleBase boss, Event event)
{
	g_bIceRagdoll = true;
}

public void ModifiersIce_OnPlayerKilled(SaxtonHaleBase boss, Event event, int iVictim)
{
	if (g_flClientIceSlowdown[iVictim] > GetGameTime())
		g_bIceRagdoll = true;
}

public void ModifiersIce_OnEntityCreated(SaxtonHaleBase boss, int iEntity, const char[] sClassname)
{
	if (g_bIceRagdoll && strcmp(sClassname, "tf_ragdoll") == 0)
	{
		RequestFrame(Ice_RagdollSpawn, EntIndexToEntRef(iEntity));
		g_bIceRagdoll = false;
	}
}

public Action ModifiersIce_OnTakeDamage(SaxtonHaleBase boss, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	//OnTakeDamageAlive takes stomping as dealing damage through falling, so we only trigger the effect if the server deals damage
	if (!(damagetype & DMG_FALL) || attacker != 0)
		return Plugin_Continue;
	
	int iTeam = GetClientTeam(boss.iClient);
	
	float vecClientPos[3];
	GetClientAbsOrigin(boss.iClient, vecClientPos);
	
	int iColor[4];
	boss.CallFunction("GetRenderColor", iColor);
	
	int iLight = TF2_CreateLightEntity(250.0, iColor, 6);
	if (iLight != -1)
	{
		TeleportEntity(iLight, vecClientPos, view_as<float>({ 90.0, 0.0, 0.0 }), NULL_VECTOR);
		
		DataPack data;
		CreateDataTimer(1.0, Timer_IceLight, data);
		data.WriteCell(EntIndexToEntRef(iLight));
		data.WriteCell(6);
		
		CreateTimer(6.0, Timer_DestroyLight, EntIndexToEntRef(iLight));
	}
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) > 1 && GetClientTeam(i) != iTeam)
		{
			float vecTargetPos[3];
			GetClientAbsOrigin(i, vecTargetPos);
			
			if (GetVectorDistance(vecClientPos, vecTargetPos) < ICE_RANGE)
			{
				g_flClientIceSlowdown[i] = GetGameTime() + ICE_DURATION;
				TF2_StunPlayer(i, ICE_DURATION, ICE_SLOWDOWN, TF_STUNFLAG_SLOWDOWN);
			}
		}
	}
	
	return Plugin_Stop;
}

public Action ModifiersIce_OnAttackDamage(SaxtonHaleBase boss, int victim, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if (damagecustom == TF_CUSTOM_BOOTS_STOMP)
		return Plugin_Stop;
	
	return Plugin_Continue;
}

public void Ice_RagdollSpawn(int iRef)
{
	int iEntity = EntRefToEntIndex(iRef);
	if (iEntity <= 0 || !IsValidEntity(iEntity)) return;
	
	SetEntProp(iEntity, Prop_Send, "m_bIceRagdoll", 1);
}

public Action Timer_IceLight(Handle hTimer, DataPack data)
{
	data.Reset();
	int iRef = data.ReadCell();
	int iBrightness = data.ReadCell();
	
	int iLight = EntRefToEntIndex(iRef);
	if (iLight > MaxClients)
	{
		iBrightness--;
		SetVariantInt(iBrightness);
		AcceptEntityInput(iLight, "brightness");
		
		CreateDataTimer(1.0, Timer_IceLight, data);
		data.WriteCell(iRef);
		data.WriteCell(iBrightness);
	}
	
	return Plugin_Continue;
}
