static char g_sDropModelPath[TF_MAXPLAYERS][PLATFORM_MAX_PATH];

methodmap CDropModel < SaxtonHaleBase
{
	public void SetModel(char[] sPath)
	{
		strcopy(g_sDropModelPath[this.iClient], sizeof(g_sDropModelPath[]), sPath);
	}
	
	public CDropModel(CDropModel ability)
	{
		g_sDropModelPath[ability.iClient] = "";
	}
	
	public void OnPlayerKilled(Event event, int iVictim)
	{
		float vecOrigin[3];
		GetClientEyePosition(iVictim, vecOrigin);
		
		int iRandom = GetRandomInt(1, 3);
		for (int i = 0; i < iRandom; i++)
		{
			int iEntity = CreateEntityByName("prop_physics_override");
			if (IsValidEntity(iEntity))
			{
				SetEntProp(iEntity, Prop_Send, "m_CollisionGroup", COLLISION_GROUP_DEBRIS);
				SetEntPropFloat(iEntity, Prop_Data, "m_flModelScale", 3.0);
				SetEntityModel(iEntity, g_sDropModelPath[this.iClient]);
				
				DispatchSpawn(iEntity);
				
				//Create random angles & velocity
				float vecAngles[3], vecVelocity[3];
				
				for (int j = 0; j < sizeof(vecAngles); j++)
					vecAngles[j] = GetRandomFloat(0.0, 360.0);
				
				for (int j = 0; j < sizeof(vecVelocity); j++)
					vecVelocity[j] = GetRandomFloat(0.0, 360.0);
				
				TeleportEntity(iEntity, vecOrigin, vecAngles, vecVelocity);
				
				CreateTimer(60.0, Timer_EntityCleanup, EntIndexToEntRef(iEntity));
			}
		}
	}
};