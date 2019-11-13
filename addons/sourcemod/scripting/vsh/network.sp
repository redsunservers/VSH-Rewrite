static bool g_bClientAndEntityNetwork[2049][MAXPLAYERS+1];

stock void Network_HookEntity(int iEnt)
{
	Network_ResetEntity(iEnt);
	SDKHook(iEnt, SDKHook_SetTransmit, NetworkHook_EntityTransmission);
}

public Action NetworkHook_EntityTransmission(int iEntity, int iClient)
{
	if (!Network_ClientHasSeenEntity(iClient, iEntity))
	{
		DataPack networkData = new DataPack();
		networkData.WriteCell(EntIndexToEntRef(iEntity));
		networkData.WriteCell(GetClientUserId(iClient));
		RequestFrame(Frame_UpdateClientEntityInfo, networkData);
	}
	return Plugin_Continue;
}

public void Frame_UpdateClientEntityInfo(DataPack networkData)
{
	networkData.Reset(); 
	int iRef = networkData.ReadCell();
	int userid = networkData.ReadCell();
	delete networkData;
	int iEntity = EntRefToEntIndex(iRef);
	int iClient = GetClientOfUserId(userid);
	
	if (iEntity > 0 && iClient > 0)
		g_bClientAndEntityNetwork[iEntity][iClient] = true;
}

stock void Network_ResetClient(int iClient)
{
	for (int i = 0; i < 2049; i++)
	{
		g_bClientAndEntityNetwork[i][iClient] = false;
	}
}

stock void Network_ResetEntity(int iEnt)
{
	for (int i = 0; i <= MaxClients; i++)
	{
		g_bClientAndEntityNetwork[iEnt][i] = false;
	}
}

stock bool Network_ClientHasSeenEntity(int iClient, int iEnt)
{
	return g_bClientAndEntityNetwork[iEnt][iClient];
}

stock bool Network_CreateEntityGlow(int iEntity, char[] sModel, int iColor[4] = {255, 255, 255, 255}, SDKHookCB callback)
{
	if (strlen(sModel) == 0) 
		return false;
	
	int iGlow = CreateEntityByName("tf_taunt_prop");
	if (iGlow != -1)
	{
		SetEntityModel(iGlow, sModel);
		
		DispatchSpawn(iGlow);
		ActivateEntity(iGlow);
		
		SetEntityRenderMode(iGlow, RENDER_TRANSCOLOR);
		SetEntityRenderColor(iGlow, 0, 0, 0, 0);
		
		int iGlowManager = TF2_CreateGlow(iGlow, iColor);
		DHookEntity(g_hHookShouldTransmit, true, iGlowManager);
		DHookEntity(g_hHookShouldTransmit, true, iGlow);
		
		// Set effect flags.
		int iFlags = GetEntProp(iGlow, Prop_Send, "m_fEffects");
		SetEntProp(iGlow, Prop_Send, "m_fEffects", iFlags | EF_BONEMERGE); // EF_BONEMERGE
		
		SetVariantString("!activator");
		AcceptEntityInput(iGlow, "SetParent", iEntity);
		
		SetEntPropEnt(iGlow, Prop_Send, "m_hOwnerEntity", iGlowManager);
		
		Network_HookEntity(iGlow);
		Network_HookEntity(iEntity);
		SDKHook(iGlow, SDKHook_SetTransmit, callback);
		
		return true;
	}
	
	return false;
}