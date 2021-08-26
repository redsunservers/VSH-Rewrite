#define MAX_BOSS_ABILITY 	8

static char g_sAbilityType[TF_MAXPLAYERS][MAX_BOSS_ABILITY][64];

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
				
				//Call ability's constructor function
				if (this.StartFunction(type, type))
				{
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
				
				//Call destroy function
				if (this.StartFunction(type, "Destroy"))
					Call_Finish();
				
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
		//Call destroy function now, since ability type get reset before called
		for (int i = 0; i < MAX_BOSS_ABILITY; i++)
		{
			if (this.StartFunction(g_sAbilityType[this.iClient][i], "Destroy"))
				Call_Finish();
			
			Format(g_sAbilityType[this.iClient][i], sizeof(g_sAbilityType[][]), "");
		}
	}
};