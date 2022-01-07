#define BODY_CLASSNAME	"prop_ragdoll"
#define BODY_EAT		"vo/sandwicheat09.mp3"
#define BODY_ENTITY_MAX	6

static bool g_bBodyBlockRagdoll;
static ArrayList g_aBodyEntity;

static int g_iMaxHeal[TF_MAXPLAYERS];
static float g_flMaxEatDistance[TF_MAXPLAYERS];
static float g_flEatRageDuration[TF_MAXPLAYERS];
static float g_flEatRageRadius[TF_MAXPLAYERS];

methodmap CBodyEat < SaxtonHaleBase
{
	property int iMaxHeal
	{
		public set(int iVal)
		{
			g_iMaxHeal[this.iClient] = iVal;
		}
		public get()
		{
			return g_iMaxHeal[this.iClient];
		}
	}
	
	property float flMaxEatDistance
	{
		public set(float flVal)
		{
			g_flMaxEatDistance[this.iClient] = flVal;
		}
		public get()
		{
			return g_flMaxEatDistance[this.iClient];
		}
	}
	
	property float flEatRageDuration
	{
		public set(float flVal)
		{
			g_flEatRageDuration[this.iClient] = flVal;
		}
		public get()
		{
			return g_flEatRageDuration[this.iClient];
		}
	}
	
	property float flEatRageRadius
	{
		public set(float flVal)
		{
			g_flEatRageRadius[this.iClient] = flVal;
		}
		public get()
		{
			return g_flEatRageRadius[this.iClient];
		}
	}
	
	public CBodyEat(CBodyEat ability)
	{
		ability.iMaxHeal = 500;
		ability.flMaxEatDistance = 100.0;
		ability.flEatRageRadius = 450.0;
		ability.flEatRageDuration = 10.0;
		
		//Create body arraylist if not already done yet
		if (g_aBodyEntity == null)
			g_aBodyEntity = new ArrayList();
	}

	public void OnPlayerKilled(Event event, int iVictim)
	{
		if (g_bBodyBlockRagdoll) return;
		if (!SaxtonHale_IsValidAttack(iVictim)) return;
		
		g_bBodyBlockRagdoll = true;
		bool bFake = view_as<bool>(event.GetInt("death_flags") & TF_DEATHFLAG_DEADRINGER);
		
		//Check how many bodies in map
		if (g_aBodyEntity.Length > 0)
		{
			//We want to go from max to 0, due to erase shifting above down by one
			for (int i = g_aBodyEntity.Length-1; i >= 0; i--)
			{
				int iEntity = EntRefToEntIndex(g_aBodyEntity.Get(i));
				
				//If invalid entity, remove in arraylist
				if (!IsValidEdict(iEntity))
					g_aBodyEntity.Erase(i);
			}
			
			//if arraylist is above max of allowed bodies in map, kill the oldest in list
			if (g_aBodyEntity.Length >= BODY_ENTITY_MAX)
			{
				int iEntity = EntRefToEntIndex(g_aBodyEntity.Get(0));
				AcceptEntityInput(iEntity, "Kill");
				g_aBodyEntity.Erase(0);
			}
		}
		
		//Any players killed by a boss with this ability will see their client side ragdoll removed and replaced with this server side ragdoll
		//Collect their damage and convert
		int iHeal = RoundToNearest(float(g_iPlayerDamage[iVictim])*0.4) + 50;
		
		if (iHeal > this.iMaxHeal) iHeal = this.iMaxHeal;
		int iColor[4];
		iColor[0] = 255;
		iColor[1] = 255;
		iColor[2] = 0;
		iColor[3] = 255;
		
		//Determine outline color
		float flHeal = float(iHeal);
		float flMaxHeal = float(this.iMaxHeal);
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
		char sModel[255];
		GetEntPropString(iVictim, Prop_Data, "m_ModelName", sModel, sizeof(sModel));
		DispatchKeyValue(iRagdoll, "model", sModel);
		
		//Teleport body to player
		float vecPos[3];
		GetClientEyePosition(iVictim, vecPos);
		DispatchSpawn(iRagdoll);
		TeleportEntity(iRagdoll, vecPos, NULL_VECTOR, NULL_VECTOR);
		
		//Add body to arraylist
		g_aBodyEntity.Push(EntIndexToEntRef(iRagdoll));
		
		//Create glow to body
		TF2_CreateEntityGlow(iRagdoll, sModel, iColor);
		SetEntProp(iRagdoll, Prop_Data, "m_CollisionGroup", COLLISION_GROUP_DEBRIS_TRIGGER);
		SDK_AlwaysTransmitEntity(iRagdoll);
		
		//Kill body from timer
		CreateTimer(30.0, Timer_EntityCleanup, EntIndexToEntRef(iRagdoll));
	}
	
	public void EatBody(int iEnt)
	{
		if (0 < GetEntPropEnt(iEnt, Prop_Send, "m_hOwnerEntity") <= MaxClients) return;
		
		float lastRageTime = this.flRageLastTime;
		float eatDuration = this.flEatRageDuration;
		if (this.bSuperRage)
			eatDuration *= 2.0;
		if (lastRageTime == 0.0 || (GetGameTime()-lastRageTime) > eatDuration)
		{
			TF2_StunPlayer(this.iClient, 2.0, 1.0, 35);
			TF2_AddCondition(this.iClient, TFCond_DefenseBuffed, 2.0);
			EmitSoundToAll(BODY_EAT, this.iClient, SNDCHAN_VOICE, SNDLEVEL_SCREAMING);
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
			
			Client_AddHealth(this.iClient, GetEntProp(iEnt, Prop_Data, "m_iHealth"), 0);
			
			SetEntPropEnt(iEnt, Prop_Send, "m_hOwnerEntity", this.iClient);
		}
	}
	
	public void OnButton(int &buttons)
	{
		if (!(buttons & IN_RELOAD))
			return;
		
		float vecPos[3], vecAng[3], vecEndPos[3];
		GetClientEyePosition(this.iClient, vecPos);
		GetClientEyeAngles(this.iClient, vecAng);
	
		Handle hTrace = TR_TraceRayFilterEx(vecPos, vecAng, MASK_VISIBLE, RayType_Infinite, TraceRay_DontHitPlayersAndObjects);
		int iEnt = TR_GetEntityIndex(hTrace);
		TR_GetEndPosition(vecEndPos, hTrace);
		delete hTrace;
		
		if (GetVectorDistance(vecEndPos, vecPos) > this.flMaxEatDistance) return;
		
		char sClassName[32];
		if (iEnt > 0) GetEdictClassname(iEnt, sClassName, sizeof(sClassName));
		
		if (strcmp(sClassName, BODY_CLASSNAME) == 0)
			this.EatBody(iEnt);
	}
	
	public void OnThink()
	{
		float lastRageTime = this.flRageLastTime;
		float eatDuration = this.flEatRageDuration;
		if (this.bSuperRage)
			eatDuration *= 2.0;
		if (lastRageTime != 0.0 && ((GetGameTime()-lastRageTime) <= eatDuration))
		{
			float vecPos[3], vecBodyPos[3];
			GetClientEyePosition(this.iClient, vecPos);
			
			int iEnt = MaxClients+1;
			while((iEnt = FindEntityByClassname(iEnt, "prop_ragdoll")) > MaxClients)
			{
				GetEntPropVector(iEnt, Prop_Send, "m_ragPos", vecBodyPos);
				if (GetVectorDistance(vecPos, vecBodyPos) > this.flEatRageRadius) continue;
				this.EatBody(iEnt);
			}
		}
	}
	
	public void GetHudInfo(char[] sMessage, int iLength, int iColor[4])
	{
		StrCat(sMessage, iLength, "\nAim at dead bodies and press reload to heal up!");
	}
	
	public void OnEntityCreated(int iEntity, const char[] sClassname)
	{
		if (g_bBodyBlockRagdoll && strcmp(sClassname, "tf_ragdoll") == 0)
		{
			AcceptEntityInput(iEntity, "Kill");
			g_bBodyBlockRagdoll = false;
		}
	}
	
	public void Precache()
	{
		PrecacheSound(BODY_EAT);
	}
};