static char g_sClientModifiersType[TF_MAXPLAYERS+1][64];

methodmap SaxtonHaleModifiers < SaxtonHaleBase
{
	public SaxtonHaleBase CreateModifiers(char[] type)
	{
		this.bModifiers = true;
		strcopy(g_sClientModifiersType[this.iClient], sizeof(g_sClientModifiersType[]), type);
		
		if (this.StartFunction(type, type))
		{
			Call_PushCell(this);
			Call_Finish();
		}
		
		return view_as<SaxtonHaleBase>(this);
	}
	
	public void SetModifiersType(const char[] type)
	{
		strcopy(g_sClientModifiersType[this.iClient], sizeof(g_sClientModifiersType[]), type);
	}
	
	public void GetModifiersType(char[] type, int length)
	{
		strcopy(type, length, g_sClientModifiersType[this.iClient]);
	}
	
	public bool IsModifiersHidden()
	{
		return false;
	}
	
	public void GetModifiersName(char[] sName, int length)
	{
		Format(sName, length, "Unknown Modifiers Name");
	}
	
	public void OnSpawn()
	{
		int iColor[4] = {255, 255, 255, 255};
		this.CallFunction("GetRenderColor", iColor);
		SetEntityRenderColor(this.iClient, iColor[0], iColor[1], iColor[2], iColor[3]);
	}
	
	public void Destroy()
	{
		//Call destroy function now, since modifiers type get reset before called
		if (this.StartFunction(g_sClientModifiersType[this.iClient], "Destroy"))
			Call_Finish();
		
		strcopy(g_sClientModifiersType[this.iClient], sizeof(g_sClientModifiersType[]), "");
		
		this.bModifiers = false;
		SetEntityRenderColor(this.iClient, 255, 255, 255, 255);
	}
};