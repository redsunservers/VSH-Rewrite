static ArrayList g_aConditions[TF_MAXPLAYERS];

void RageAddCond_AddCond(SaxtonHaleBase boss, TFCond cond, bool bSuperRage = false)
{
	int iLength = g_aConditions[boss.iClient].Length;
	g_aConditions[boss.iClient].Resize(iLength+1);
	g_aConditions[boss.iClient].Set(iLength, cond, 0);
	g_aConditions[boss.iClient].Set(iLength, bSuperRage, 1);
}

public void RageAddCond_Create(SaxtonHaleBase boss)
{
	if (g_aConditions[boss.iClient] == null)
		g_aConditions[boss.iClient] = new ArrayList(2);
	g_aConditions[boss.iClient].Clear();
	
	boss.SetPropFloat("RageAddCond", "RageCondDuration", 5.0);
	boss.SetPropFloat("RageAddCond", "RageCondSuperRageMultiplier", 2.0);
}

public void RageAddCond_OnRage(SaxtonHaleBase boss)
{
	int iLength = g_aConditions[boss.iClient].Length;
	
	float flDuration = boss.GetPropFloat("RageAddCond", "RageCondDuration");
	if (boss.bSuperRage)
		flDuration *= boss.GetPropFloat("RageAddCond", "RageCondSuperRageMultiplier");
	
	for (int i = 0; i < iLength; i++)
	{
		bool bSuperRageCond = g_aConditions[boss.iClient].Get(i, 1);
		
		if (!bSuperRageCond || bSuperRageCond && boss.bSuperRage)
			TF2_AddCondition(boss.iClient, g_aConditions[boss.iClient].Get(i, 0), flDuration);
	}
}