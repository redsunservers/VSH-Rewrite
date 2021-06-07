#define DOME_PROP_RADIUS 10000.0	//Dome prop radius, exactly 10k weeeeeeeeeeee

#define DOME_FADE_START_MULTIPLIER 0.7
#define DOME_FADE_ALPHA_MAX 64

#define DOME_START_SOUND	"vsh_rewrite/cp_unlocked.mp3"
#define DOME_NEARBY_SOUND	"ui/medic_alert.wav"
#define DOME_PERPARE_DURATION 4.5

//CP
static bool g_bDomeCustomPos;	//Whenever if capture point is in custom pos
static float g_vecDomeCP[3];	//Pos of CP
static int g_iDomeTriggerRef;	//Trigger to control touch
static bool g_bDomeCapturing[TF_MAXPLAYERS+1];

//Dome prop
static int g_iDomeEntRef;
static TFTeam g_nDomeTeamOwner = TFTeam_Unassigned;
static int g_iDomeColor[4];

static float g_flDomeStart = 0.0;
static float g_flDomeRadius = 0.0;
static float g_flDomePreviousGameTime = 0.0;
static float g_flDomePlayerTime[TF_MAXPLAYERS+1] = 0.0;
static bool g_bDomePlayerOutside[TF_MAXPLAYERS+1] = false;
static Handle g_hDomeTimerBleed = null;

void Dome_Init()
{
	g_ConfigConvar.Create("vsh_dome_enable", "1", "Enable dome?", _, true, 0.0, true, 1.0);
	g_ConfigConvar.Create("vsh_dome_centre", "", "Map centre pos for Dome/CP (blank for CP's default centre)");
	g_ConfigConvar.Create("vsh_dome_cp_radius", "250", "If vsh_dome_centre specified, new radius from CP to capture");
	g_ConfigConvar.Create("vsh_dome_cp_unlock", "60", "Time in second to unlock CP on round start", _, true, 0.0);
	g_ConfigConvar.Create("vsh_dome_cp_unlockplayer", "5", "Time in second to add on every player to unlock CP on round start", _, true, 0.0);
	g_ConfigConvar.Create("vsh_dome_cp_captime", "15", "How long to capture CP", _, true, 0.0);
	g_ConfigConvar.Create("vsh_dome_cp_bossrate", "3", "Capture value for boss", _, true, 1.0);
	g_ConfigConvar.Create("vsh_dome_color_neu", "192 192 192 255", "Color of dome in RGBA if nobody owns the capture point");
	g_ConfigConvar.Create("vsh_dome_color_red", "255 0 0 255", "Color of dome in RGBA if red owns the capture point");
	g_ConfigConvar.Create("vsh_dome_color_blu", "0 0 255 255", "Color of dome in RGBA if blu owns the capture point");
	g_ConfigConvar.Create("vsh_dome_radius_start", "3500", "Start radius of dome", _, true, 0.0);
	g_ConfigConvar.Create("vsh_dome_radius_end", "0", "End radius of dome", _, true, 0.0);
	g_ConfigConvar.Create("vsh_dome_speed_duration", "120", "How long it takes in second for dome to fully shrink, without any slowdown", _, true, 0.0);
	
	HookEntityOutput("tf_logic_arena", "OnCapEnabled", Dome_OnCapEnabled);
	
	HookEntityOutput("team_control_point", "OnOwnerChangedToTeam1", Dome_BlockOutput);
	HookEntityOutput("team_control_point", "OnOwnerChangedToTeam2", Dome_BlockOutput);
	HookEntityOutput("team_control_point", "OnCapReset", Dome_BlockOutput);
	HookEntityOutput("team_control_point", "OnCapTeam1", Dome_BlockOutput);
	HookEntityOutput("team_control_point", "OnCapTeam2", Dome_BlockOutput);
	HookEntityOutput("trigger_capture_area", "OnCapTeam1", Dome_BlockOutput);
	HookEntityOutput("trigger_capture_area", "OnCapTeam2", Dome_BlockOutput);
	HookEntityOutput("trigger_capture_area", "OnEndCap", Dome_BlockOutput);
}

void Dome_MapStart()
{
	//Huge prop
	AddFileToDownloadsTable("models/kirillian/brsphere_huge.dx80.vtx");
	AddFileToDownloadsTable("models/kirillian/brsphere_huge.dx90.vtx");
	AddFileToDownloadsTable("models/kirillian/brsphere_huge.mdl");
	AddFileToDownloadsTable("models/kirillian/brsphere_huge.sw.vtx");
	AddFileToDownloadsTable("models/kirillian/brsphere_huge.vvd");

	AddFileToDownloadsTable("materials/models/kirillian/brsphere/br_fog.vmt");
	AddFileToDownloadsTable("materials/models/kirillian/brsphere/br_fog.vtf");

	PrepareSound(DOME_START_SOUND);
	PrecacheSound(DOME_NEARBY_SOUND);
	
	SDK_HookGetCaptureValueForPlayer(Dome_GetCaptureValueForPlayer);
}

public MRESReturn Dome_GetCaptureValueForPlayer(Handle hReturn, Handle hParams)
{
	int iClient = DHookGetParam(hParams, 1);
	if (SaxtonHale_IsValidBoss(iClient, false))
	{
		DHookSetReturn(hReturn, g_ConfigConvar.LookupInt("vsh_dome_cp_bossrate"));
		return MRES_Supercede;
	}

	return MRES_Ignored;
}

public void Dome_MasterSpawn(int iMaster)
{
	//Prevent round win from capture
	DispatchKeyValue(iMaster, "cpm_restrict_team_cap_win", "1");
}

public void Dome_TriggerSpawn(int iTrigger)
{
	//Set time to cap to whatever in convar
	DispatchKeyValueFloat(iTrigger, "area_time_to_cap", g_ConfigConvar.LookupFloat("vsh_dome_cp_captime") / 2.0);
	//If mp_capstyle is set to 1, team_numcap_ keyvalues are used in the captime calculations
	DispatchKeyValue(iTrigger, "team_numcap_2", "1");
	DispatchKeyValue(iTrigger, "team_numcap_3", "1");
	g_iDomeTriggerRef = EntIndexToEntRef(iTrigger);
}

public Action Dome_TriggerTouch(int iTrigger, int iToucher)
{
	if (iToucher <= 0 || iToucher > MaxClients)
		return Plugin_Continue;
	
	//If CP is in custom pos and player is not nearby new pos (touching original pos), prevent call
	if (g_bDomeCustomPos && !g_bDomeCapturing[iToucher])
		return Plugin_Handled;
	
	return Plugin_Continue;
}

public Action Dome_OnCapEnabled(const char[] output, int caller, int activator, float delay)
{
	if (!g_bEnabled) return;
	
	Dome_Start();
}

public Action Dome_BlockOutput(const char[] output, int caller, int activator, float delay)
{
	if (!g_bEnabled) return Plugin_Continue; //Don't block outside of VSH
	
	//Always block this function, maps may assume round ended
	return Plugin_Handled;
}

void Dome_RoundStart()
{
	g_bDomeCustomPos = false;
	
	g_iDomeEntRef = 0;
	Dome_SetTeam(TFTeam_Unassigned);
	
	g_flDomeStart = 0.0;
	g_flDomeRadius = 0.0;
	g_flDomePreviousGameTime = 0.0;
	g_hDomeTimerBleed = null;
	
	for (int iClient = 1; iClient <= MaxClients; iClient++)
		g_bDomePlayerOutside[iClient] = false;
	
	//CP hud is in the way from our VSH hud, move em to better place
	int iObjectiveRessource = TF2_GetObjectiveResource();
	if (iObjectiveRessource > MaxClients)
	{
		SetEntPropFloat(iObjectiveRessource, Prop_Send, "m_flCustomPositionX", 0.20);
		SetEntPropFloat(iObjectiveRessource, Prop_Send, "m_flCustomPositionY", -1.0);
	}
	
	if (g_ConfigConvar.LookupFloatArray("vsh_dome_centre", g_vecDomeCP, sizeof(g_vecDomeCP)))
	{
		//Find CP to teleport
		int iCP = FindEntityByClassname(-1, "team_control_point");
		if (iCP <= MaxClients)
			return;
		
		g_bDomeCustomPos = true;
		TeleportEntity(iCP, g_vecDomeCP, NULL_VECTOR, NULL_VECTOR);
		
		//Find any CP prop to move aswell
		int iProp = MaxClients+1;
		while ((iProp = FindEntityByClassname(iProp, "prop_dynamic")) > MaxClients)
		{
			if (Dome_IsDomeProp(iProp))
			{
				TeleportEntity(iProp, g_vecDomeCP, NULL_VECTOR, NULL_VECTOR);
				DispatchKeyValue(iProp, "disableshadows", "1");
			}
		}
	}
}

void Dome_RoundArenaStart()
{
	if (!g_ConfigConvar.LookupBool("vsh_dome_enable"))
		return;
	
	float flTime = g_ConfigConvar.LookupFloat("vsh_dome_cp_unlock") + (g_ConfigConvar.LookupFloat("vsh_dome_cp_unlockplayer") * g_iTotalAttackCount);
	GameRules_SetPropFloat("m_flCapturePointEnableTime", GetGameTime() + flTime);
}

void Dome_OnThink(int iClient)
{
	//Call our own StartTouch and EndTouch if CP is in custom pos
	if (!g_bDomeCustomPos)
		return;
	
	int iTrigger = EntRefToEntIndex(g_iDomeTriggerRef);
	if (iTrigger <= MaxClients)
		return;
	
	static int iOffset = -1;
	if (iOffset == -1)
		iOffset = FindDataMapInfo(iTrigger, "m_flCapTime");
	
	TFTeam nCapturingTeam = view_as<TFTeam>(GetEntData(iTrigger, iOffset - 12));	// m_nCapturingTeam
	if (TF2_GetClientTeam(iClient) != nCapturingTeam && nCapturingTeam > TFTeam_Spectator)
	{
		//Reversing capture
		if (GetEntDataFloat(iTrigger, iOffset) * 2.0 < GetEntDataFloat(iTrigger, iOffset + 4))	// m_flCapTime & m_fTimeRemaining
		{
			//Reverse capture ended, force end touch
			if (g_bDomeCapturing[iClient])
			{
				AcceptEntityInput(iTrigger, "EndTouch", iClient, iClient);
				g_bDomeCapturing[iClient] = false;
			}
			
			//Don't attempt call start touch
			return;
		}
	}
	
	bool bTouch;
	if (IsPlayerAlive(iClient) && IsClientInRange(iClient, g_vecDomeCP, g_ConfigConvar.LookupFloat("vsh_dome_cp_radius")))
	{
		//Can client pos see dome center
		float vecStart[3], vecEnd[3];
		GetClientAbsOrigin(iClient, vecStart);
		vecEnd = g_vecDomeCP;
		vecEnd[2] += 8.0;
		TR_TraceRayFilter(vecStart, vecEnd, MASK_PLAYERSOLID, RayType_EndPoint, TraceFilter_Dome);
		if (!TR_DidHit())
		{
			bTouch = true;
			g_bDomeCapturing[iClient] = true;
			AcceptEntityInput(iTrigger, "StartTouch", iClient, iClient);
		}
	}
	
	if (!bTouch && g_bDomeCapturing[iClient])
	{
		AcceptEntityInput(iTrigger, "EndTouch", iClient, iClient);
		g_bDomeCapturing[iClient] = false;
	}
}

stock bool TraceFilter_Dome(int iEntity, int iMask, any iData)
{
	if (0 < iEntity <= MaxClients)
		return false;
	
	if (Dome_IsDomeProp(iEntity))
		return false;
	
	return true;
}

bool Dome_Start(int iCP = 0)
{
	if (g_flDomeStart != 0.0)	//Check if we already have dome enabled, if so return false
		return false;

	if (iCP <= MaxClients)
	{
		iCP = FindEntityByClassname(-1, "team_control_point");
		if (iCP <= MaxClients)
			return false;
	}
	
	GetEntPropVector(iCP, Prop_Send, "m_vecOrigin", g_vecDomeCP);
	
	//Create dome prop
	int iDome = CreateEntityByName("prop_dynamic");
	if (iDome <= MaxClients)
		return false;
	
	g_flDomeRadius = g_ConfigConvar.LookupFloat("vsh_dome_radius_start");
	
	DispatchKeyValueVector(iDome, "origin", g_vecDomeCP);						//Set origin to CP
	DispatchKeyValue(iDome, "model", "models/kirillian/brsphere_huge.mdl");	//Set model
	DispatchKeyValue(iDome, "disableshadows", "1");							//Disable shadow
	SetEntPropFloat(iDome, Prop_Send, "m_flModelScale", SquareRoot(g_flDomeRadius / DOME_PROP_RADIUS));	//Calculate model scale
	
	DispatchSpawn(iDome);
	
	SetEntityRenderMode(iDome, RENDER_TRANSCOLOR);
	SetEntityRenderColor(iDome, g_iDomeColor[0], g_iDomeColor[1], g_iDomeColor[2], 0);
	SDK_AlwaysTransmitEntity(iDome);
	
	GameRules_SetPropFloat("m_flCapturePointEnableTime", 0.0);
	g_flDomeStart = GetGameTime();
	EmitSoundToAll(DOME_START_SOUND);
	PrintHintTextToAll("The dome is now active!");
	
	g_iDomeEntRef = EntIndexToEntRef(iDome);
	RequestFrame(Dome_Frame_Prepare);
	return true;
}

void Dome_SetTeam(TFTeam nTeam)
{
	g_nDomeTeamOwner = nTeam;
	
	//Get new dome color
	switch (nTeam)
	{
		case TFTeam_Red: g_ConfigConvar.LookupIntArray("vsh_dome_color_red", g_iDomeColor, sizeof(g_iDomeColor));
		case TFTeam_Blue: g_ConfigConvar.LookupIntArray("vsh_dome_color_blu", g_iDomeColor, sizeof(g_iDomeColor));
		default: g_ConfigConvar.LookupIntArray("vsh_dome_color_neu", g_iDomeColor, sizeof(g_iDomeColor));
	}
	
	//Set dome ent to new color
	int iDome = EntRefToEntIndex(g_iDomeEntRef);
	if (iDome > MaxClients)
	{
		SetEntityRenderMode(iDome, RENDER_TRANSCOLOR);
		SetEntityRenderColor(iDome, g_iDomeColor[0], g_iDomeColor[1], g_iDomeColor[2], g_iDomeColor[3]);
	}
	
	//Update CP to new owner
	int iCP = MaxClients+1;
	while ((iCP = FindEntityByClassname(iCP, "team_control_point")) > MaxClients)
	{
		SetVariantInt(view_as<int>(nTeam));
		AcceptEntityInput(iCP, "SetOwner", 0, 0);
	}
	
	//Update CP model skin
	int iProp = MaxClients+1;
	while ((iProp = FindEntityByClassname(iProp, "prop_dynamic")) > MaxClients)
	{
		char sModel[128];
		GetEntPropString(iProp, Prop_Data, "m_ModelName", sModel, sizeof(sModel));
		
		if (StrEqual(sModel, "models/props_gameplay/cap_point_base.mdl")
			|| StrEqual(sModel, "models/props_doomsday/cap_point_small.mdl"))
		{
			switch (nTeam)
			{
				case TFTeam_Red: SetEntProp(iProp, Prop_Send, "m_nSkin", 1);
				case TFTeam_Blue: SetEntProp(iProp, Prop_Send, "m_nSkin", 2);
				default: SetEntProp(iProp, Prop_Send, "m_nSkin", 0);
			}
		}
	}
	
	//Reset time player in dome
	for (int iClient = 1; iClient <= MaxClients; iClient++)
		g_flDomePlayerTime[iClient] = 0.0;
}

public void Dome_Frame_Prepare()
{
	if (g_flDomeStart == 0.0)
		return;

	int iDome = EntRefToEntIndex(g_iDomeEntRef);
	if (!IsValidEntity(iDome))
		return;

	float flTime = GetGameTime() - g_flDomeStart;

	if (flTime < DOME_PERPARE_DURATION)
	{
		//Calculate transparent to dome during prepare, i should also redo this
		float flRender = flTime;
		
		while (flRender > 1.0)
			flRender -= 1.0;
		
		if (flRender > 0.5)
			flRender = (1 - flRender);
		
		flRender *= 2 * float(g_iDomeColor[3]);
		SetEntityRenderColor(iDome, g_iDomeColor[0], g_iDomeColor[1], g_iDomeColor[2], RoundToFloor(flRender));
		
		//Create fade to players near/outside of dome
		for (int iClient = 1; iClient <= MaxClients; iClient++)
		{
			if (IsClientInGame(iClient) && IsPlayerAlive(iClient))
			{
				TFTeam nTeam = TF2_GetClientTeam(iClient);
				if (nTeam <= TFTeam_Spectator || nTeam == g_nDomeTeamOwner)
					continue;
				
				// 0.0 = centre of CP
				//<1.0 = inside dome
				// 1.0 = at border of dome
				//>1.0 = outside of dome 
				float flDistanceMultiplier = Dome_GetDistance(iClient) / g_flDomeRadius;
				
				if (flDistanceMultiplier > DOME_FADE_START_MULTIPLIER)
				{
					float flAlpha;
					if (flDistanceMultiplier > 1.0)
						flAlpha = DOME_FADE_ALPHA_MAX * (flRender/255.0);
					else
						flAlpha = (flDistanceMultiplier - DOME_FADE_START_MULTIPLIER) * (1.0/(1.0-DOME_FADE_START_MULTIPLIER)) * DOME_FADE_ALPHA_MAX * (flRender/255.0);
					
					CreateFade(iClient, _, g_iDomeColor[0], g_iDomeColor[1], g_iDomeColor[2], RoundToNearest(flAlpha));
				}
			}
		}
		
		RequestFrame(Dome_Frame_Prepare);
	}
	else
	{
		//Start the shrink
		SetEntityRenderColor(iDome, g_iDomeColor[0], g_iDomeColor[1], g_iDomeColor[2], g_iDomeColor[3]);
		g_hDomeTimerBleed = CreateTimer(0.5, Dome_TimerBleed, _, TIMER_REPEAT);
		
		g_flDomePreviousGameTime = GetGameTime();
		RequestFrame(Dome_Frame_Shrink);
	}
}

public void Dome_Frame_Shrink()
{
	if (g_flDomeStart == 0.0)
		return;

	int iDome = EntRefToEntIndex(g_iDomeEntRef);
	if (!IsValidEntity(iDome))
		return;
	
	Dome_UpdateRadius();
	SetEntPropFloat(iDome, Prop_Send, "m_flModelScale", SquareRoot(g_flDomeRadius / DOME_PROP_RADIUS));

	//Give client bleed if outside of dome
	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if (IsClientInGame(iClient) && IsPlayerAlive(iClient))
		{
			// 0.0 = centre of CP
			//<1.0 = inside dome
			// 1.0 = at border of dome
			//>1.0 = outside of dome
			TFTeam nTeam = TF2_GetClientTeam(iClient);
			float flDistanceMultiplier = Dome_GetDistance(iClient) / g_flDomeRadius;
			
			if (flDistanceMultiplier > 1.0 && nTeam > TFTeam_Spectator && nTeam != g_nDomeTeamOwner)
			{
				//Client is outside of dome, state that player is outside of dome
				g_bDomePlayerOutside[iClient] = true;
				
				//Add time on how long player have been outside of dome
				g_flDomePlayerTime[iClient] += GetGameTime() - g_flDomePreviousGameTime;
				
				//give bleed if havent been given one
				if (!TF2_IsPlayerInCondition(iClient, TFCond_Bleeding))
					TF2_MakeBleed(iClient, iClient, 9999.0);	//Does no damage, ty sourcemod
			}
			else if (g_bDomePlayerOutside[iClient])
			{
				//Client is not outside of dome, remove bleed
				TF2_RemoveCondition(iClient, TFCond_Bleeding);
				g_bDomePlayerOutside[iClient] = false;
			}
			
			//Create fade
			if (flDistanceMultiplier > DOME_FADE_START_MULTIPLIER && nTeam > TFTeam_Spectator && nTeam != g_nDomeTeamOwner)
			{
				float flAlpha;
				if (flDistanceMultiplier > 1.0)
					flAlpha = float(DOME_FADE_ALPHA_MAX);
				else
					flAlpha = (flDistanceMultiplier - DOME_FADE_START_MULTIPLIER) * (1.0/(1.0-DOME_FADE_START_MULTIPLIER)) * DOME_FADE_ALPHA_MAX;
				
				CreateFade(iClient, _, g_iDomeColor[0], g_iDomeColor[1], g_iDomeColor[2], RoundToNearest(flAlpha));
			}
		}
	}

	g_flDomePreviousGameTime = GetGameTime();

	RequestFrame(Dome_Frame_Shrink);
}

public Action Dome_TimerBleed(Handle hTimer)
{
	if (g_hDomeTimerBleed != hTimer)
		return Plugin_Stop;

	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if (IsClientInGame(iClient) && IsPlayerAlive(iClient))
		{
			TFTeam nTeam = TF2_GetClientTeam(iClient);
			if (nTeam <= TFTeam_Spectator || nTeam == g_nDomeTeamOwner)
				continue;
			
			StopSound(iClient, SNDCHAN_AUTO, DOME_NEARBY_SOUND);
			
			//Check if player is outside of dome
			if (g_bDomePlayerOutside[iClient])
			{
				float flDamage;
				if (SaxtonHale_IsValidBoss(iClient, false))
				{
					//Calculate max possible damage to deal boss based from player count
					flDamage = float(g_iTotalAttackCount) * 25.0;
					
					//Scale damage down by current progress dome is at
					float flRadiusMax = g_ConfigConvar.LookupFloat("vsh_dome_radius_start");
					float flRadiusMin = g_ConfigConvar.LookupFloat("vsh_dome_radius_end");
					float flRadiusPrecentage = (g_flDomeRadius - flRadiusMin) / (flRadiusMax - flRadiusMin);
					flDamage *= (1.0 - flRadiusPrecentage);
				}
				else
				{
					//Calculate damage, the longer the player is outside of the dome, the more damage it deals
					flDamage = Pow(2.0, g_flDomePlayerTime[iClient]);
				}
				
				if (flDamage < 1.0)
					flDamage = 1.0;
				
				//Deal damage
				SDKHooks_TakeDamage(iClient, 0, iClient, flDamage, DMG_PREVENT_PHYSICS_FORCE);
				EmitSoundToClient(iClient, DOME_NEARBY_SOUND);
			}
		}
	}

	//Deal damage to engineer buildings
	
	int iEntity = MaxClients+1;
	while ((iEntity = FindEntityByClassname(iEntity, "obj_*")) > MaxClients)
	{
		if (Dome_GetDistance(iEntity) <= g_flDomeRadius)
			continue;
		
		if (GetEntProp(iEntity, Prop_Send, "m_bCarried"))
			continue;
		
		if (view_as<TFTeam>(GetEntProp(iEntity, Prop_Send, "m_iTeamNum")) == g_nDomeTeamOwner)
			continue;
		
		SetVariantInt(15);
		AcceptEntityInput(iEntity, "RemoveHealth");
	}
	
	return Plugin_Continue;
}

void Dome_UpdateRadius()
{
	//Get current game time
	float flGameTime = GetGameTime();
	float flGameTimeDifference = flGameTime - g_flDomePreviousGameTime;
	
	//Get distance to travel
	float flRadiusStart = g_ConfigConvar.LookupFloat("vsh_dome_radius_start");
	float flRadiusEnd = g_ConfigConvar.LookupFloat("vsh_dome_radius_end");
	float flRadiusDistance = flRadiusStart - flRadiusEnd;
	
	//Calculate speed dome should be
	float flSpeed = flRadiusDistance / g_ConfigConvar.LookupFloat("vsh_dome_speed_duration");
	
	//Calculate new radius from speed and time
	float flRadius = g_flDomeRadius - (flSpeed * flGameTimeDifference);
	
	//Check if we already reached min value
	if (flRadius < flRadiusEnd)
		flRadius = flRadiusEnd;
	
	//Update global variable
	g_flDomeRadius = flRadius;
}

float Dome_GetDistance(int iEntity)
{
	float vecPos[3];
	
	//Client
	if (0 < iEntity <= MaxClients && IsClientInGame(iEntity) && IsPlayerAlive(iEntity))
		GetClientEyePosition(iEntity, vecPos);
	
	//Buildings
	else if (IsValidEntity(iEntity))
		GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", vecPos);
	
	else return -1.0;
	
	return GetVectorDistance(vecPos, g_vecDomeCP);
}

bool Dome_IsDomeProp(int iProp)
{
	char sModel[PLATFORM_MAX_PATH];
	GetEntPropString(iProp, Prop_Data, "m_ModelName", sModel, sizeof(sModel));
			
	return StrEqual(sModel, "models/props_gameplay/cap_point_base.mdl") || StrEqual(sModel, "models/props_doomsday/cap_point_small.mdl");
}