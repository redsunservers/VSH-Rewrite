#define BODY_CLASSNAME	"prop_ragdoll"
#define BODY_EAT		"vo/sandwicheat09.mp3"

static bool g_bBodyBlockRagdoll;

public void BodyEat_Create(SaxtonHaleBase boss)
{
	boss.SetPropInt("BodyEat", "MaxHeal", 500);
	boss.SetPropFloat("BodyEat", "MaxEatDistance", 100.0);
	boss.SetPropFloat("BodyEat", "EatRageRadius", 450.0);
	boss.SetPropFloat("BodyEat", "EatRageDuration", 10.0);
}

public void BodyEat_OnPlayerKilled(SaxtonHaleBase boss, Event event, int iVictim)
{
	if (g_bBodyBlockRagdoll) return;
	if (!SaxtonHale_IsValidAttack(iVictim)) return;
	
	g_bBodyBlockRagdoll = true;
	bool bFake = view_as<bool>(event.GetInt("death_flags") & TF_DEATHFLAG_DEADRINGER);
	
	//Any players killed by a boss with this ability will see their client side ragdoll removed and replaced with this server side ragdoll
	//Collect their damage and convert
	int iHeal = RoundToNearest(float(g_iPlayerDamage[iVictim])*0.4) + 50;
	
	if (iHeal > boss.GetPropInt("BodyEat", "MaxHeal")) iHeal = boss.GetPropInt("BodyEat", "MaxHeal");
	int iColor[4];
	iColor[0] = 255;
	iColor[1] = 255;
	iColor[2] = 0;
	iColor[3] = 255;
	
	//Determine outline color
	float flHeal = float(iHeal);
	float flMaxHeal = float(boss.GetPropInt("BodyEat", "MaxHeal"));
	if (flHeal <= flMaxHeal/2.0)
	{
		float flVal = flHeal/(flMaxHeal/2.0);
		iColor[1] = RoundToNearest(float(iColor[1])*flVal);
	}
	else
	{
		float flVal = 1.0-((flHeal-(flMaxHeal/2.0))/(flMaxHeal/2.0));
		iColor[0] = RoundToNearest(float(iColor[0])*flVal);
	}
	
	//Create body entity
	int iRagdoll = CreateEntityByName(BODY_CLASSNAME);
	SetEntProp(iRagdoll, Prop_Data, "m_iMaxHealth", (bFake) ? 0 : iHeal);
	SetEntProp(iRagdoll, Prop_Data, "m_iHealth", (bFake) ? 0 : iHeal);
	
	//Set model to body
	char sModel[PLATFORM_MAX_PATH];
	GetEntPropString(iVictim, Prop_Data, "m_ModelName", sModel, sizeof(sModel));
	DispatchKeyValue(iRagdoll, "model", sModel);
	
	//Teleport body to player
	float vecPos[3], vecAng[3], vecVel[3];
	GetClientAbsOrigin(iVictim, vecPos);
	GetClientEyeAngles(iVictim, vecAng);
	GetEntPropVector(iVictim, Prop_Data, "m_vecVelocity", vecVel);
	
	//Adjust angles and position
	vecAng[0] = 0.0;
	vecPos[2] += 45.0;
	
	DispatchSpawn(iRagdoll);
	TeleportEntity(iRagdoll, vecPos, vecAng, vecVel);
	
	//Create glow to body
	TF2_CreateEntityGlow(iRagdoll, sModel, iColor);
	SetEntityCollisionGroup(iRagdoll, COLLISION_GROUP_DEBRIS_TRIGGER);
	SDK_AlwaysTransmitEntity(iRagdoll);
	
	//Kill body from timer
	CreateTimer(30.0, Timer_EntityCleanup, EntIndexToEntRef(iRagdoll));
}

public void BodyEat_EatBody(SaxtonHaleBase boss, int iEnt)
{
	if (0 < GetEntPropEnt(iEnt, Prop_Send, "m_hOwnerEntity") <= MaxClients) return;
	
	float lastRageTime = boss.flRageLastTime;
	float eatDuration = boss.GetPropFloat("BodyEat", "EatRageDuration");
	if (boss.bSuperRage)
		eatDuration *= 2.0;
	if (lastRageTime == 0.0 || (GetGameTime()-lastRageTime) > eatDuration)
	{
		TF2_StunPlayer(boss.iClient, 2.0, 1.0, 35);
		TF2_AddCondition(boss.iClient, TFCond_DefenseBuffed, 2.0);
		EmitSoundToAll(BODY_EAT, boss.iClient, SNDCHAN_VOICE, SNDLEVEL_SCREAMING);
	}
	
	int iDissolve = CreateEntityByName("env_entity_dissolver");
	if (iDissolve > 0)
	{
		char sName[32];
		Format(sName, sizeof(sName), "Ref_%d_Ent_%d", EntIndexToEntRef(iEnt), iEnt);

		DispatchKeyValue(iEnt, "targetname", sName);
		DispatchKeyValue(iDissolve, "target", sName);
		DispatchKeyValue(iDissolve, "dissolvetype", "2");
		DispatchKeyValue(iDissolve, "magnitude", "15.0");
		AcceptEntityInput(iDissolve, "Dissolve");
		AcceptEntityInput(iDissolve, "Kill");
		
		Client_AddHealth(boss.iClient, GetEntProp(iEnt, Prop_Data, "m_iHealth"), 0);
		
		SetEntPropEnt(iEnt, Prop_Send, "m_hOwnerEntity", boss.iClient);
	}
}

public void BodyEat_OnButton(SaxtonHaleBase boss, int &buttons)
{
	if (!(buttons & IN_RELOAD))
		return;
	
	float vecPos[3], vecAng[3], vecEndPos[3];
	GetClientEyePosition(boss.iClient, vecPos);
	GetClientEyeAngles(boss.iClient, vecAng);

	Handle hTrace = TR_TraceRayFilterEx(vecPos, vecAng, MASK_VISIBLE, RayType_Infinite, TraceRay_DontHitPlayersAndObjects);
	int iEnt = TR_GetEntityIndex(hTrace);
	TR_GetEndPosition(vecEndPos, hTrace);
	delete hTrace;
	
	if (GetVectorDistance(vecEndPos, vecPos) > boss.GetPropFloat("BodyEat", "MaxEatDistance")) return;
	
	char sClassName[32];
	if (iEnt > 0) GetEdictClassname(iEnt, sClassName, sizeof(sClassName));
	
	if (strcmp(sClassName, BODY_CLASSNAME) == 0)
		BodyEat_EatBody(boss, iEnt);
}

public void BodyEat_OnThink(SaxtonHaleBase boss)
{
	float lastRageTime = boss.flRageLastTime;
	float eatDuration = boss.GetPropFloat("BodyEat", "EatRageDuration");
	if (boss.bSuperRage)
		eatDuration *= 2.0;
	if (lastRageTime != 0.0 && ((GetGameTime()-lastRageTime) <= eatDuration))
	{
		float vecPos[3], vecBodyPos[3];
		GetClientEyePosition(boss.iClient, vecPos);
		
		int iEnt = MaxClients+1;
		while((iEnt = FindEntityByClassname(iEnt, "prop_ragdoll")) > MaxClients)
		{
			GetEntPropVector(iEnt, Prop_Send, "m_ragPos", vecBodyPos);
			if (GetVectorDistance(vecPos, vecBodyPos) > boss.GetPropFloat("BodyEat", "EatRageRadius")) continue;
			BodyEat_EatBody(boss, iEnt);
		}
	}
}

public void BodyEat_GetHudInfo(SaxtonHaleBase boss, char[] sMessage, int iLength, int iColor[4])
{
	StrCat(sMessage, iLength, "\nAim at dead bodies and press reload to heal up!");
}

public void BodyEat_OnEntityCreated(SaxtonHaleBase boss, int iEntity, const char[] sClassname)
{
	if (g_bBodyBlockRagdoll && strcmp(sClassname, "tf_ragdoll") == 0)
	{
		AcceptEntityInput(iEntity, "Kill");
		g_bBodyBlockRagdoll = false;
	}
}

public void BodyEat_Precache(SaxtonHaleBase boss)
{
	PrecacheSound(BODY_EAT);
}
