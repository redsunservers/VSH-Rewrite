//#define DOME_PROP_RADIUS 185.0	//Small prop
#define DOME_PROP_RADIUS 10000.0	//Huge prop, exactly 10k weeeeeeeeeeee

#define DOME_FADE_START_MULTIPLIER 0.7
#define DOME_FADE_ALPHA_MAX 64

#define DOME_START_SOUND	"vsh_rewrite/cp_unlocked.mp3"
#define DOME_NEARBY_SOUND	"ui/medic_alert.wav"
#define DOME_PERPARE_DURATION 4.5

static float g_flDomeEnableTime = 0.0;
static float g_flDomeStart = 0.0;
static float g_flDomeRadius = 0.0;
static float g_flDomePreviousGameTime = 0.0;
static float g_flDomeFreeze = 0.0;
static float g_flDomePlayerTime[TF_MAXPLAYERS+1] = 0.0;
static bool g_bDomePlayerOutside[TF_MAXPLAYERS+1] = false;
static Handle g_hDomeTimerBleed = null;

static char g_strCP[64];
static float g_vecCP[3];
static int g_vecColor[3];

void Dome_Init()
{
	g_ConfigConvar.Create("vsh_dome_enable", "1", "Enable dome?", _, true, 0.0, true, 1.0);
	g_ConfigConvar.Create("vsh_dome_centre", "", "Map centre pos for Dome/CP (blank for CP's default centre)");
	g_ConfigConvar.Create("vsh_dome_color", "255 0 0", "Color of dome in RGB");
	g_ConfigConvar.Create("vsh_dome_radius_max", "3500", "Max radius of dome", _, true, 0.0);
	g_ConfigConvar.Create("vsh_dome_radius_min", "0", "Min radius of dome", _, true, 0.0);
	g_ConfigConvar.Create("vsh_dome_speed_max", "30", "Start speed of dome", _, true, 0.0);
	g_ConfigConvar.Create("vsh_dome_speed_min", "20", "End speed of dome", _, true, 0.0);
	g_ConfigConvar.Create("vsh_dome_freeze_duration", "8", "Duration in seconds to stop dome whenever player dies", _, true, 0.0);
}

void Dome_MapStart()
{
	/*
	//Small prop
	AddFileToDownloadsTable("models/kirillian/brsphere.dx80.vtx");
	AddFileToDownloadsTable("models/kirillian/brsphere.dx90.vtx");
	AddFileToDownloadsTable("models/kirillian/brsphere.mdl");
	AddFileToDownloadsTable("models/kirillian/brsphere.sw.vtx");
	AddFileToDownloadsTable("models/kirillian/brsphere.vvd");
	*/

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
}

void Dome_RoundStart()
{
	g_flDomeEnableTime = 0.0;
	g_flDomeStart = 0.0;
	g_flDomeRadius = 0.0;
	g_flDomePreviousGameTime = 0.0;
	g_flDomeFreeze = 0.0;
	g_hDomeTimerBleed = null;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		g_flDomePlayerTime[i] = 0.0;
		g_bDomePlayerOutside[i] = false;
	}
	
	char sCentre[256];
	g_ConfigConvar.LookupString("vsh_dome_centre", sCentre);
	if (!StrEmpty(sCentre))
	{
		//Get vec pos to move CP
		float flVec[3];
		char sVec[3][32];
		int iCount = ExplodeString(sCentre, " ", sVec, 3, 32);
		if (iCount == 3)
			for (int i = 0; i < 3; i++)
				flVec[i] = StringToFloat(sVec[i]);
			
		//Find CP to teleport
		int iCP = FindEntityByClassname(-1, "team_control_point");
		if (IsValidEntity(iCP))
		{
			TeleportEntity(iCP, flVec, NULL_VECTOR, NULL_VECTOR);
		}
			
		//Find any CP prop to move aswell
		int iProp = MaxClients+1;
		while ((iProp = FindEntityByClassname(iProp, "prop_dynamic")) > MaxClients)
		{
			char strModel[128];
			GetEntPropString(iProp, Prop_Data, "m_ModelName", strModel, sizeof(strModel));
			
			if (StrEqual(strModel, "models/props_gameplay/cap_point_base.mdl")
				|| StrEqual(strModel, "models/props_doomsday/cap_point_small.mdl"))
			{
				TeleportEntity(iProp, flVec, NULL_VECTOR, NULL_VECTOR);
				DispatchKeyValue(iProp, "disableshadows", "1");
			}
		}
	}

	GameRules_SetPropFloat("m_flCapturePointEnableTime", 31536000.0+GetGameTime()); //3 years
	
	//Hide CP in hud, 0 for default, 1 for CTF, 2 for CP, 3 for Payload
	//0 and 2 displays CP, 1 displays CTF with no intels, so 3 is the only option left as there no payload in map, nothing to display
	GameRules_SetProp("m_nHudType", 3);
}

void Dome_RoundSelected(Event event)
{
	//If map have team_control_point_round, we get active CP for dome
	char strRound[64];
	event.GetString("round", strRound, sizeof(strRound));

	//Search for each team_control_point_round
	int iRound = MaxClients+1;
	while((iRound = FindEntityByClassname(iRound, "team_control_point_round")) > MaxClients)
	{
		//Check if it the same name as from event
		char strName[64];
		GetEntPropString(iRound, Prop_Data, "m_iName", strName, sizeof(strName));
		if (strcmp(strRound, strName) == 0)
		{
			//Take his CP, then save into global g_strCP
			char strCPName[64];
			GetEntPropString(iRound, Prop_Data, "m_iszCPNames", strCPName, sizeof(strCPName));
			strcopy(g_strCP, sizeof(g_strCP), strCPName);
		}
	}
}

void Dome_RoundArenaStart()
{
	if (!g_ConfigConvar.LookupBool("vsh_dome_enable")) return;
	
	g_flDomeEnableTime = GetGameTime() + 60.0;	//60 seconds initial time
	RequestFrame(Dome_Frame_Start);	//Start the checks when we reached the time
}

void Dome_PlayerDeath(int iPlayerCount)
{
	if (!g_ConfigConvar.LookupBool("vsh_dome_enable")) return;
	
	//Check if dome isnt enabled yet
	if (g_flDomeStart == 0.0)
	{
		//Add time everytime (non-zombie) attack team dies
		g_flDomeEnableTime += g_ConfigConvar.LookupFloat("vsh_dome_freeze_duration");

		//Calculate max time we can allow for dome to start based on current alive player count
		float flMaxTime = float(iPlayerCount) * 8.0;
		if (flMaxTime > 60.0)
			flMaxTime = 60.0;
		
		//If dome is going to be triggered longer than max time, set as that time
		float flGameTime = GetGameTime();
		if (g_flDomeEnableTime > flGameTime + flMaxTime)
			g_flDomeEnableTime = flGameTime + flMaxTime;
	}
	else
	{
		//If boss kills attack team while dome is on, pause dome
		g_flDomeFreeze = GetGameTime() + g_ConfigConvar.LookupFloat("vsh_dome_freeze_duration");
	}
}

void Dome_Frame_Start(int i = 0)
{
	if (!g_ConfigConvar.LookupBool("vsh_dome_enable") || g_flDomeEnableTime == 0.0 || g_flDomeStart != 0.0) return;

	//Check if time reached to start the dome
	if (g_flDomeEnableTime < GetGameTime())
		Dome_Start();	//Start the dome
	else
		RequestFrame(Dome_Frame_Start);
}

bool Dome_Start()
{
	if (g_flDomeStart != 0.0) return false;	//Check if we already have dome enabled, if so return false

	//Find current active CP
	int iCP = MaxClients + 1;
	while((iCP = FindEntityByClassname(iCP, "team_control_point")) > MaxClients)
	{
		char strName[64];
		GetEntPropString(iCP, Prop_Data, "m_iName", strName, sizeof(strName));
		if (strcmp(g_strCP, strName) == 0 || StrEmpty(g_strCP))
			break;
	}

	if (IsValidEntity(iCP))
	{
		GetEntPropVector(iCP, Prop_Send, "m_vecOrigin", g_vecCP);

		//Create dome prop
		int iDome = CreateEntityByName("prop_dynamic");
		if (IsValidEntity(iDome))
		{
			g_flDomeRadius = g_ConfigConvar.LookupFloat("vsh_dome_radius_max");
			
			DispatchKeyValueVector(iDome, "origin", g_vecCP);						//Set origin to CP
			DispatchKeyValue(iDome, "model", "models/kirillian/brsphere_huge.mdl");	//Set model
			DispatchKeyValue(iDome, "disableshadows", "1");							//Disable shadow
			SetEntPropFloat(iDome, Prop_Send, "m_flModelScale", SquareRoot(g_flDomeRadius / DOME_PROP_RADIUS));	//Calculate model scale
			
			//Set color
			char sBuffer[256];
			g_ConfigConvar.LookupString("vsh_dome_color", sBuffer);
			if (!StrEmpty(sBuffer))
			{
				char sColor[3][32];
				int iCount = ExplodeString(sBuffer, " ", sColor, 3, 32);
				if (iCount == 3)
					for (int i = 0; i < 3; i++)
						g_vecColor[i] = StringToInt(sColor[i]);
				
				SetEntityRenderMode(iDome, RENDER_TRANSCOLOR);
				SetEntityRenderColor(iDome, g_vecColor[0], g_vecColor[1], g_vecColor[2], 0);
			}
			
			DispatchSpawn(iDome);
			
			g_flDomeStart = GetGameTime();
			EmitSoundToAll(DOME_START_SOUND);
			PrintHintTextToAll("The dome is active. Prepare to move!");
			
			//Call any map events from CP unlock
			FireEntityOutput(iCP, "OnUnlocked");
			int iLogicArena = FindEntityByClassname(-1, "tf_logic_arena");
			if (IsValidEntity(iLogicArena))
				FireEntityOutput(iLogicArena, "OnCapEnabled");
			
			RequestFrame(Dome_Frame_Prepare, EntIndexToEntRef(iDome));

			return true;
		}
	}

	return false;
}

void Dome_Frame_Prepare(int iRef)
{
	if (g_flDomeStart == 0.0) return;

	int iDome = EntRefToEntIndex(iRef);
	if (!IsValidEntity(iDome)) return;

	float flTime = GetGameTime() - g_flDomeStart;

	if (flTime < DOME_PERPARE_DURATION)
	{
		//Calculate transparent to dome during prepare, i should also redo this
		float flRender = flTime;

		while (flRender > 1.0)
			flRender -= 1.0;

		if (flRender > 0.5)
			flRender = (1 - flRender);

		flRender *= 255.0 * 2;
		SetEntityRenderColor(iDome, g_vecColor[0], g_vecColor[1], g_vecColor[2], RoundToFloor(flRender));
		
		//Create fade to players near/outside of dome
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) > 1)
			{
				// 0.0 = centre of CP
				//<1.0 = inside dome
				// 1.0 = at border of dome
				//>1.0 = outside of dome 
				float flDistanceMultiplier = Dome_GetDistance(i) / g_flDomeRadius;
				
				if (flDistanceMultiplier > DOME_FADE_START_MULTIPLIER)
				{
					float flAlpha;
					if (flDistanceMultiplier > 1.0)
						flAlpha = DOME_FADE_ALPHA_MAX * (flRender/255.0);
					else
						flAlpha = (flDistanceMultiplier - DOME_FADE_START_MULTIPLIER) * (1.0/(1.0-DOME_FADE_START_MULTIPLIER)) * DOME_FADE_ALPHA_MAX * (flRender/255.0);
					
					Dome_Fade(i, RoundToNearest(flAlpha));
				}
			}
		}
		
		RequestFrame(Dome_Frame_Prepare, iRef);
	}
	else
	{
		//Start the shrink
		SetEntityRenderColor(iDome, g_vecColor[0], g_vecColor[1], g_vecColor[2], 255);
		g_hDomeTimerBleed = CreateTimer(0.5, Dome_TimerBleed, _, TIMER_REPEAT);

		g_flDomePreviousGameTime = GetGameTime();
		RequestFrame(Dome_Frame_Shrink, iRef);
	}
}

void Dome_Frame_Shrink(int iRef)
{
	if (g_flDomeStart == 0.0) return;

	int iDome = EntRefToEntIndex(iRef);
	if (!IsValidEntity(iDome)) return;
	
	Dome_UpdateRadius();
	SetEntPropFloat(iDome, Prop_Send, "m_flModelScale", SquareRoot(g_flDomeRadius / DOME_PROP_RADIUS));

	//Give client bleed if outside of dome
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) > 1)
		{
			// 0.0 = centre of CP
			//<1.0 = inside dome
			// 1.0 = at border of dome
			//>1.0 = outside of dome 
			float flDistanceMultiplier = Dome_GetDistance(i) / g_flDomeRadius;
			
			if (flDistanceMultiplier > 1.0)
			{
				//If client is outside of dome, state that player is outside of dome
				if (!g_bDomePlayerOutside[i])
					g_bDomePlayerOutside[i] = true;
				
				//Add time on how long player have been outside of dome
				g_flDomePlayerTime[i] += GetGameTime() - g_flDomePreviousGameTime;

				//give bleed if havent been given one
				if (!TF2_IsPlayerInCondition(i, TFCond_Bleeding))
					TF2_MakeBleed(i, i, 9999.0);	//Does no damage, ty sourcemod
			}
			else
			{
				//If client is not outside of dome, remove bleed
				if (g_bDomePlayerOutside[i])
				{
					TF2_RemoveCondition(i, TFCond_Bleeding);
					g_bDomePlayerOutside[i] = false;
				}
			}
			
			//Create fade
			if (flDistanceMultiplier > DOME_FADE_START_MULTIPLIER)
			{
				float flAlpha;
				if (flDistanceMultiplier > 1.0)
					flAlpha = float(DOME_FADE_ALPHA_MAX);
				else
					flAlpha = (flDistanceMultiplier - DOME_FADE_START_MULTIPLIER) * (1.0/(1.0-DOME_FADE_START_MULTIPLIER)) * DOME_FADE_ALPHA_MAX;
				
				Dome_Fade(i, RoundToNearest(flAlpha));
			}
		}
	}

	g_flDomePreviousGameTime = GetGameTime();

	RequestFrame(Dome_Frame_Shrink, iRef);
}

public Action Dome_TimerBleed(Handle hTimer)
{
	if (g_hDomeTimerBleed != hTimer)
		return Plugin_Stop;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) > 1)
		{
			StopSound(i, SNDCHAN_AUTO, DOME_NEARBY_SOUND);
			
			//Check if player is outside of dome
			if (g_bDomePlayerOutside[i])
			{
				float flDamage;
				if (SaxtonHale_IsValidBoss(i, false))
				{
					//Calculate max possible damage to deal boss based from player count
					flDamage = float(g_iTotalAttackCount) * 25.0;
					
					//Scale damage down by current progress dome is at
					float flRadiusMax = g_ConfigConvar.LookupFloat("vsh_dome_radius_max");
					float flRadiusMin = g_ConfigConvar.LookupFloat("vsh_dome_radius_min");
					float flRadiusPrecentage = (g_flDomeRadius - flRadiusMin) / (flRadiusMax - flRadiusMin);
					flDamage *= (1.0 - flRadiusPrecentage);
				}
				else
				{
					//Calculate damage, the longer the player is outside of the dome, the more damage it deals
					flDamage = Pow(2.0, g_flDomePlayerTime[i]);
				}
				
				if (flDamage < 1.0)
					flDamage = 1.0;

				//Deal damage
				SDKHooks_TakeDamage(i, 0, i, flDamage, DMG_PREVENT_PHYSICS_FORCE);
				EmitSoundToClient(i, DOME_NEARBY_SOUND);
			}
		}
	}

	//Deal damage to engineer buildings
	int iEntity;

	iEntity = MaxClients+1;
	while((iEntity = FindEntityByClassname(iEntity, "obj_sentrygun")) > MaxClients)
		Dome_Building_Damage(iEntity);

	iEntity = MaxClients+1;
	while((iEntity = FindEntityByClassname(iEntity, "obj_dispenser")) > MaxClients)
		Dome_Building_Damage(iEntity);

	iEntity = MaxClients+1;
	while((iEntity = FindEntityByClassname(iEntity, "obj_teleporter")) > MaxClients)
		Dome_Building_Damage(iEntity);

	return Plugin_Continue;
}

void Dome_Building_Damage(int iEntity)
{
	if (Dome_GetDistance(iEntity) <= g_flDomeRadius) return;
	
	if (GetEntProp(iEntity, Prop_Send, "m_bCarried")) return;
	
	SetVariantInt(15);
	AcceptEntityInput(iEntity, "RemoveHealth");
}

void Dome_Fade(int iClient, int iAlpha)
{
	Handle hFade = StartMessageOne("Fade", iClient);
	BfWriteShort(hFade, 2000);				//Fade duration
	BfWriteShort(hFade, 0);
	BfWriteShort(hFade, 0x0001);
	BfWriteByte(hFade, g_vecColor[0]);	//Red
	BfWriteByte(hFade, g_vecColor[1]);	//Green
	BfWriteByte(hFade, g_vecColor[2]);	//Blue
	BfWriteByte(hFade, iAlpha);				//Alpha
	EndMessage();
}

void Dome_UpdateRadius()
{
	float flGameTime = GetGameTime();
	float flGameTimeDifference = flGameTime - g_flDomePreviousGameTime;
	
	//Check if we are in freeze process
	if (g_flDomeFreeze < flGameTime)
	{
		//Calculate how fast dome should be in hu per second
		float flRadiusMax = g_ConfigConvar.LookupFloat("vsh_dome_radius_max");
		float flRadiusMin = g_ConfigConvar.LookupFloat("vsh_dome_radius_min");
		float flRadiusPrecentage = (g_flDomeRadius - flRadiusMin) / (flRadiusMax - flRadiusMin);
		
		float flSpeedMax = g_ConfigConvar.LookupFloat("vsh_dome_speed_max");
		float flSpeedMin = g_ConfigConvar.LookupFloat("vsh_dome_speed_min");
		float flSpeed = ((flSpeedMax - flSpeedMin) * flRadiusPrecentage) + flSpeedMin;
		
		//Check if we already reached min value
		float flRadius = g_flDomeRadius - (flSpeed * flGameTimeDifference);
		if (flRadius < flRadiusMin)
			flRadius = flRadiusMin;
		
		//Update global variable
		g_flDomeRadius = flRadius;
	}
}

float Dome_GetDistance(int iEntity)
{
	float flDistance = -1.0;
	float vecPos[3];
	
	//Client
	if (0 < iEntity <= MaxClients && IsClientInGame(iEntity) && IsPlayerAlive(iEntity))
		GetClientEyePosition(iEntity, vecPos);
	
	//Buildings
	else if (IsValidEntity(iEntity))
		GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", vecPos);
	
	else return -1.0;
	
	flDistance = GetVectorDistance(vecPos, g_vecCP);
	return flDistance;
}