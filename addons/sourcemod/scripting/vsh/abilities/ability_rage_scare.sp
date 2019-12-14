static float g_flScareRadius[TF_MAXPLAYERS+1];
static float g_flScareDuration[TF_MAXPLAYERS+1];
static int g_iScareStunFlags[TF_MAXPLAYERS+1];
static float g_flScareRadiusClass[TF_MAXPLAYERS+1][10];
static float g_flScareDurationClass[TF_MAXPLAYERS+1][10];
static int g_iScareStunFlagsClass[TF_MAXPLAYERS+1][10];
static TFClassType g_nScareClass[TF_MAXPLAYERS+1];

methodmap CScareRage < SaxtonHaleBase
{
	property float flRadius
	{
		public get()
		{
			return g_flScareRadius[this.iClient];
		}
		public set(float val)
		{
			g_flScareRadius[this.iClient] = val;
		}
	}
	
	property float flDuration
	{
		public get()
		{
			return g_flScareDuration[this.iClient];
		}
		public set(float val)
		{
			g_flScareDuration[this.iClient] = val;
		}
	}
	
	property int iStunFlags
	{
		public get()
		{
			return g_iScareStunFlags[this.iClient];
		}
		public set(int val)
		{
			g_iScareStunFlags[this.iClient] = val;
		}
	}
	
	property float flRadiusClass
	{
		public get()
		{
			return g_flScareRadiusClass[this.iClient][g_nScareClass[this.iClient]];
		}
		public set(float val)
		{
			g_flScareRadiusClass[this.iClient][g_nScareClass[this.iClient]] = val;
		}
	}
	
	property float flDurationClass
	{
		public get()
		{
			return g_flScareDurationClass[this.iClient][g_nScareClass[this.iClient]];
		}
		public set(float val)
		{
			g_flScareDurationClass[this.iClient][g_nScareClass[this.iClient]] = val;
		}
	}
	
	property int iStunFlagsClass
	{
		public get()
		{
			return g_iScareStunFlagsClass[this.iClient][g_nScareClass[this.iClient]];
		}
		public set(int val)
		{
			g_iScareStunFlagsClass[this.iClient][g_nScareClass[this.iClient]] = val;
		}
	}
	
	property TFClassType nSetClass
	{
		public get()
		{
			return g_nScareClass[this.iClient];
		}
		public set(TFClassType val)
		{
			g_nScareClass[this.iClient] = val;
		}
	}
	
	public CScareRage(CScareRage ability)
	{
		//Default values, these can be changed if needed
		ability.flRadius = -1.0;
		ability.flDuration = 5.0;
		ability.iStunFlags = TF_STUNFLAGS_GHOSTSCARE;
		
		for (TFClassType nClass = TFClass_Scout; nClass <= TFClass_Engineer; nClass++)
		{
			ability.nSetClass = nClass;
			ability.flRadiusClass = -1.0;
			ability.flDurationClass = -1.0;
			ability.iStunFlagsClass = -1;
		}
	}
	
	public void OnRage()
	{
		int iClient = this.iClient;
		int bossTeam = GetClientTeam(iClient);
		float vecPos[3], vecTargetPos[3];
		GetClientAbsOrigin(iClient, vecPos);
		
		for (int iVictim = 1; iVictim <= MaxClients; iVictim++)
		{
			if (IsClientInGame(iVictim) && IsPlayerAlive(iVictim) && GetClientTeam(iVictim) != bossTeam && !TF2_IsUbercharged(iVictim))
			{
				GetClientAbsOrigin(iVictim, vecTargetPos);
				TFClassType nClass = TF2_GetPlayerClass(iVictim);
				this.nSetClass = nClass;
				
				float flRadius = (this.flRadiusClass >= 0.0) ? this.flRadiusClass : this.flRadius;
				if (this.bSuperRage) flRadius *= 1.5;
				float flDuration = (this.flDurationClass >= 0.0) ? this.flDurationClass : this.flDuration;
				if (this.bSuperRage) flDuration *= 1.5;
				int iStunFlags = (this.iStunFlagsClass >= 0) ? this.iStunFlagsClass : this.iStunFlags;
				
				float flDistance = GetVectorDistance(vecTargetPos, vecPos);
				
				if (flDistance <= flRadius)
					TF2_StunPlayer(iVictim, flDuration, 0.1, iStunFlags, 0);
			}
		}
		
		int iEntity = MaxClients+1;
		while ((iEntity = FindEntityByClassname(iEntity, "obj_sentrygun")) > MaxClients)
		{
			if (GetEntProp(iEntity, Prop_Send, "m_iTeamNum") != bossTeam)
			{
				float flDuration = (this.bSuperRage) ? this.flDuration*1.5 : this.flDuration;
				float flRadius = (this.bSuperRage) ? this.flRadius*1.5 : this.flRadius;
				
				GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", vecTargetPos);
				if (GetVectorDistance(vecTargetPos, vecPos) <= flRadius)
					TF2_StunBuilding(iEntity, flDuration);
			}
		}
	}
};