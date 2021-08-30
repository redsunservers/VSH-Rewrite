static char g_sClientBossMultiType[TF_MAXPLAYERS][64];

methodmap SaxtonHaleBossMulti < SaxtonHaleBase
{
	public SaxtonHaleBase CreateBossMulti(const char[] type)
	{
		if (type[0])
		{
			strcopy(g_sClientBossMultiType[this.iClient], sizeof(g_sClientBossMultiType[]), type);
		}
		else
		{
			//Empty? get default multi boss
			this.CallFunction("GetBossMultiType", g_sClientBossMultiType[this.iClient], sizeof(g_sClientBossMultiType[]));
		}
		
		//Call boss multi constructor function
		if (this.StartFunction(g_sClientBossMultiType[this.iClient], g_sClientBossMultiType[this.iClient]))
		{
			Call_PushCell(this);
			Call_Finish();
		}
		
		return view_as<SaxtonHaleBase>(this);
	}
	
	public void SetBossMultiType(const char[] type)
	{
		strcopy(g_sClientBossMultiType[this.iClient], sizeof(g_sClientBossMultiType[]), type);
	}
	
	public void GetBossMultiType(char[] type, int length)
	{
		//If we dont have any, allow bosses use it default multi type
		if (!StrEmpty(g_sClientBossMultiType[this.iClient]))
			strcopy(type, length, g_sClientBossMultiType[this.iClient]);
	}
	
	public bool IsBossMultiType(const char[] type)
	{
		return StrEqual(g_sClientBossMultiType[this.iClient], type);
	}

	public void GetBossMultiName(char[] sName, int length)
	{
		Format(sName, length, "Unknown Boss Multi Name");
	}
	
	public void Destroy()
	{
		//Call destroy function now, since boss type get reset before called
		if (this.StartFunction(g_sClientBossMultiType[this.iClient], "Destroy"))
			Call_Finish();
		
		strcopy(g_sClientBossMultiType[this.iClient], sizeof(g_sClientBossMultiType[]), "");
	}
};