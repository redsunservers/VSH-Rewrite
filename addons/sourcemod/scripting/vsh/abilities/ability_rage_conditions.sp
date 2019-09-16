static float g_flRageCondDuration[TF_MAXPLAYERS+1];
static float g_flRageCondSuperRageMultiplier[TF_MAXPLAYERS+1];
static ArrayList g_aConditions[TF_MAXPLAYERS+1];

methodmap CRageAddCond < SaxtonHaleBase
{
	property float flRageCondDuration
	{
		public set(float flVal)
		{
			g_flRageCondDuration[this.iClient] = flVal;
		}
		public get()
		{
			return g_flRageCondDuration[this.iClient];
		}
	}
	
	property float flRageCondSuperRageMultiplier
	{
		public set(float flVal)
		{
			g_flRageCondSuperRageMultiplier[this.iClient] = flVal;
		}
		public get()
		{
			return g_flRageCondSuperRageMultiplier[this.iClient];
		}
	}
	
	public void AddCond(TFCond cond)
	{
		g_aConditions[this.iClient].Push(cond);
	}
	
	public CRageAddCond(CRageAddCond ability)
	{
		if (g_aConditions[ability.iClient] == null)
			g_aConditions[ability.iClient] = new ArrayList();
		g_aConditions[ability.iClient].Clear();
		
		g_flRageCondDuration[ability.iClient] = 5.0;
		g_flRageCondSuperRageMultiplier[ability.iClient] = 2.0;
	}
	
	public void OnRage()
	{
		int iLength = g_aConditions[this.iClient].Length;
		
		float flDuration = this.flRageCondDuration;
		if (this.bSuperRage)
			flDuration *= this.flRageCondSuperRageMultiplier;
		
		for (int i = 0; i < iLength; i++)
			TF2_AddCondition(this.iClient, g_aConditions[this.iClient].Get(i), flDuration);
	}
};