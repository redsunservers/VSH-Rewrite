static char g_sClientModifiersType[TF_MAXPLAYERS+1][64];

methodmap SaxtonHaleModifiers < SaxtonHaleBase
{
	public SaxtonHaleBase CreateModifiers(char[] type)
	{
		this.bModifiers = true;
		strcopy(g_sClientModifiersType[this.iClient], sizeof(g_sClientModifiersType[]), type);
		
		char sFunction[256];
		Format(sFunction, sizeof(sFunction), "%s.%s", type, type);
		
		Handle hPlugin = Function_GetPlugin(type);
		Function func = GetFunctionByName(hPlugin, sFunction);
		if (func != INVALID_FUNCTION)
		{
			Call_StartFunction(hPlugin, func);
			Call_PushCell(this);
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
		this.bModifiers = false;
		strcopy(g_sClientModifiersType[this.iClient], sizeof(g_sClientModifiersType[]), "");
		SetEntityRenderColor(this.iClient, 255, 255, 255, 255);
	}
};