static ArrayList g_aConditions[MAXPLAYERS];

public void RageAddCond_AddCond(SaxtonHaleBase boss, TFCond cond)
{
	g_aConditions[boss.iClient].Push(cond);
}

public void RageAddCond_Create(SaxtonHaleBase boss)
{
	if (g_aConditions[boss.iClient] == null)
		g_aConditions[boss.iClient] = new ArrayList();
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
		TF2_AddCondition(boss.iClient, g_aConditions[boss.iClient].Get(i), flDuration);
}
