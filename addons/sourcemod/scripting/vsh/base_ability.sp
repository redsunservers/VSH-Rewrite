#define MAX_BOSS_ABILITY 	8

static char g_sAbilityType[TF_MAXPLAYERS+1][MAX_BOSS_ABILITY][64];

methodmap SaxtonHaleAbility < SaxtonHaleBase
{
	public SaxtonHaleBase CreateAbility(char[] type)
	{
		//Find empty ability
		for (int i = 0; i < MAX_BOSS_ABILITY; i++)
		{
			if (StrEmpty(g_sAbilityType[this.iClient][i]))
			{
				strcopy(g_sAbilityType[this.iClient][i], sizeof(g_sAbilityType[][]), type);
				
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
		}
		
		return INVALID_ABILITY;
	}
	
	public SaxtonHaleBase FindAbility(char[] type)
	{
		for (int i = 0; i < MAX_BOSS_ABILITY; i++)
		{
			if (StrEqual(g_sAbilityType[this.iClient][i], type))
			{
				return view_as<SaxtonHaleBase>(this);
			}
		}
		
		return INVALID_ABILITY;
	}
	
	public void DestroyAbility(char[] type)
	{
		for (int i = 0; i < MAX_BOSS_ABILITY; i++)
		{
			if (StrEqual(g_sAbilityType[this.iClient][i], type))
			{
				Format(g_sAbilityType[this.iClient][i], sizeof(g_sAbilityType[][]), "");
				
				char sFunction[256];
				Format(sFunction, sizeof(sFunction), "%s.Destroy", type);
				
				Handle hPlugin = Function_GetPlugin(type);
				Function func = GetFunctionByName(hPlugin, sFunction);
				if (func != INVALID_FUNCTION)
				{
					Call_StartFunction(hPlugin, func);
					Call_PushCell(this);
					Call_Finish();
				}
				
				break;
			}
		}
	}
	
	public void GetAbilityType(char[] type, int length, int iBuffer)
	{
		strcopy(type, length, g_sAbilityType[this.iClient][iBuffer]);
	}
	
	public void Destroy()
	{
		for (int i = 0; i < MAX_BOSS_ABILITY; i++)
			Format(g_sAbilityType[this.iClient][i], sizeof(g_sAbilityType[][]), "");
	}
};