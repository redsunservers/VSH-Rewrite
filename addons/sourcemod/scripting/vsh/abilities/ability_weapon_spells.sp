static ArrayList g_aSpells[TF_MAXPLAYERS];
static haleSpells g_rageSpells[TF_MAXPLAYERS];
static float g_flRageRequirement[TF_MAXPLAYERS];
static bool g_bSpellsRage[TF_MAXPLAYERS];
static float g_flSpellsCooldown[TF_MAXPLAYERS];
static float g_flSpellsLastUsed[TF_MAXPLAYERS];

enum haleSpells
{
	haleSpells_Invalid = -1,
	haleSpells_Fireball = 0,
	haleSpells_Bats,
	haleSpells_Heal,
	haleSpells_Pumpkin,
	haleSpells_Jump,
	haleSpells_Stealth,
	haleSpells_Teleport,
	haleSpells_Lightning,
	haleSpells_Tiny,
	haleSpells_Meteor,
	haleSpells_Monoculus,
	haleSpells_Skeleton,
};

static char g_strSpellsName[][] =
{
	"Fireball",
	"Swarm of Bats",
	"Uber Heal",
	"Pumpkin MIRV",
	"Blast Jump",
	"Stealth",
	"Teleport",
	"Ball o' Lightning",
	"Tiny and Athletic",
	"Meteor Storm",
	"MONOCULUS!",
	"Skeleton Horde",
};

methodmap CWeaponSpells < SaxtonHaleBase
{
	property float flCooldown
	{
		public get()
		{
			return g_flSpellsCooldown[this.iClient];
		}
		public set(float val)
		{
			g_flSpellsCooldown[this.iClient] = val;
		}
	}
	
	property float flRageRequirement
	{
		public get()
		{
			return g_flRageRequirement[this.iClient];
		}
		public set(float val)
		{
			g_flRageRequirement[this.iClient] = val;
		}
	}
	
	public CWeaponSpells(CWeaponSpells ability)
	{
		ability.flRageRequirement = 0.25;
		ability.flCooldown = 0.0;
		g_rageSpells[ability.iClient] = haleSpells_Invalid;
		
		g_bSpellsRage[ability.iClient] = false;
		
		if (g_aSpells[ability.iClient] == null)
			g_aSpells[ability.iClient] = new ArrayList();
		g_aSpells[ability.iClient].Clear();
	}
	
	public void AddSpells(haleSpells spells)
	{
		g_aSpells[this.iClient].Push(spells);
	}
	
	public void RageSpells(haleSpells spells)
	{
		g_rageSpells[this.iClient] = spells;
	}
	
	public void OnSpawn()
	{
		int iClient = this.iClient;
		
		//Create and equip spellbook
		char attribs[128];
		Format(attribs, sizeof(attribs), "547 ; 0.5");
		int iSpellbook = this.CallFunction("CreateWeapon", 1069, "tf_weapon_spellbook", 100, TFQual_Haunted, attribs);
		if (iSpellbook > MaxClients)
		{
			SetEntProp(iSpellbook, Prop_Send, "m_iSpellCharges", 9999);
			if (g_aSpells[iClient].Length > 0)
				SetEntProp(iSpellbook, Prop_Send, "m_iSelectedSpellIndex", view_as<int>(g_aSpells[iClient].Get(0)));
		}
	}
	
	public void GetHudInfo(char[] sMessage, int iLength, int iColor[4])
	{
		int iSpellbook = GetSpellbook(this.iClient);
		if (iSpellbook <= MaxClients)
			return;
		
		float flRagePercentage = float(this.iRageDamage) / float(this.iMaxRageDamage);
		
		if (g_flSpellsLastUsed[this.iClient] > GetGameTime()-this.flCooldown)
		{
			int iSec = RoundToCeil(this.flCooldown - (GetGameTime() - g_flSpellsLastUsed[this.iClient]));
			Format(sMessage, iLength, "%s\nSpell cooldown %i second%s remaining!", sMessage, iSec, (iSec > 1) ? "s" : "");
		}
		else if (flRagePercentage < this.flRageRequirement)
		{
			Format(sMessage, iLength, "%s\nNot enough rage for spells!", sMessage);
		}
		else
		{
			int iSpellIndex = GetEntProp(iSpellbook, Prop_Send, "m_iSelectedSpellIndex");
			if (iSpellIndex < 0)
				return;
			
			Format(sMessage, iLength, "%s\nSpell: %s", sMessage, g_strSpellsName[iSpellIndex]);
		}
		
		Format(sMessage, iLength, "%s\nUse attack2 for spell", sMessage);
		if (g_aSpells[this.iClient].Length > 1)
			Format(sMessage, iLength, "%s, and reload to change current spell!", sMessage);
		else
			Format(sMessage, iLength, "%s!", sMessage);
	}
	
	public void OnRage()
	{
		if (g_rageSpells[this.iClient] == view_as<int>(haleSpells_Invalid))
			return;
		
		int iClient = this.iClient;
		
		//Set spellbook to specified rare
		int iSpellbook = GetSpellbook(iClient);
		if (iSpellbook == -1) return;
		haleSpells spellIndex = view_as<haleSpells>(GetEntProp(iSpellbook, Prop_Send, "m_iSelectedSpellIndex"));
		SetEntProp(iSpellbook, Prop_Send, "m_iSelectedSpellIndex", view_as<int>(g_rageSpells[iClient]));
		
		//Force player use spell
		g_bSpellsRage[iClient] = true;
		Client_ForceUseAction(iClient);
		float flDuration = 0.85;
		
		if (this.bSuperRage)
		{
			int iRef = EntIndexToEntRef(iClient);
			CreateTimer(0.85, Timer_ForceUseAction, iRef);
			CreateTimer(1.70, Timer_ForceUseAction, iRef);
			flDuration = 2.55;
		}
		
		//Create timer to set spell back to what it used to be
		DataPack data;
		CreateDataTimer(flDuration, Timer_SetSpellIndex, data);
		data.WriteCell(EntIndexToEntRef(iClient));
		data.WriteCell(spellIndex);
	}
	
	public Action OnCommandKeyValues(const char[] sCommand)
	{
		if (StrEqual(sCommand, "+use_action_slot_item_server"))
		{
			//Check whenever if we should allow him to use spell
			int iClient = this.iClient;
			
			if (g_bSpellsRage[iClient])
			{
				//Rage
				g_bSpellsRage[iClient] = false;
				return Plugin_Continue;
			}
			
			float flRagePercentage = float(this.iRageDamage) / float(this.iMaxRageDamage);
			if (flRagePercentage >= this.flRageRequirement && g_flSpellsLastUsed[this.iClient] <= GetGameTime()-this.flCooldown)
			{
				//Normal spell, remove rage on use
				this.iRageDamage -= RoundToFloor(this.flRageRequirement * float(this.iMaxRageDamage));
				
				//spell cooldowns, set timer after used
				g_flSpellsLastUsed[this.iClient] = GetGameTime();
				this.CallFunction("UpdateHudInfo", 1.0, this.flCooldown);	//Update every second for cooldown duration
				
				
				//Play ability sound if boss have one
				char sSound[PLATFORM_MAX_PATH];
				this.CallFunction("GetSoundAbility", sSound, sizeof(sSound), "CWeaponSpells");
				if (!StrEmpty(sSound))
					EmitSoundToAll(sSound, this.iClient, SNDCHAN_VOICE, SNDLEVEL_SCREAMING);
				
				return Plugin_Continue;
			}
			else
			{
				//Not enough rage, dont allow him use spell
				return Plugin_Handled;
			}
		}
		
		return Plugin_Continue;
	}
	
	public void OnButtonPress(int button)
	{
		int iClient = this.iClient;
		
		if (button == IN_RELOAD && g_aSpells[iClient].Length > 1)
		{
			float flRagePercentage = float(this.iRageDamage) / float(this.iMaxRageDamage);
			if (flRagePercentage >= this.flRageRequirement)
			{
				int iSpellbook = GetSpellbook(iClient);
				if (iSpellbook == -1) return;
				
				//Get current spell
				haleSpells spellIndex = view_as<haleSpells>(GetEntProp(iSpellbook, Prop_Send, "m_iSelectedSpellIndex"));
				
				int i = 0;
				while (i < g_aSpells[iClient].Length)
				{
					//Search in array until we found same spell
					if (g_aSpells[iClient].Get(i) == spellIndex)
					{
						//We found it, get the next spell in array
						i++;
						if (i >= g_aSpells[iClient].Length) i = 0;	//if we already at end, loop back to start
						spellIndex = g_aSpells[iClient].Get(i);
						break;
					}
					
					i++;
				}
				
				SetEntProp(iSpellbook, Prop_Send, "m_iSelectedSpellIndex", view_as<int>(spellIndex));
			}
		}
		else if (button == IN_ATTACK2)
		{
			//Just another way to use spells rather than using default H key
			Client_ForceUseAction(iClient);
		}
	}
};

//GetPlayerWeaponSlot is not that great into getting spellbook
stock int GetSpellbook(int iClient)
{
	int iSpellbook = MaxClients+1;
	while ((iSpellbook = FindEntityByClassname(iSpellbook, "tf_weapon_spellbook")) != -1)
		if (IsValidEntity(iSpellbook) && GetEntPropEnt(iSpellbook, Prop_Send, "m_hOwnerEntity") == iClient && !GetEntProp(iSpellbook, Prop_Send, "m_bDisguiseWeapon"))
			return iSpellbook;
	
	return -1;
}

public Action Timer_SetSpellIndex(Handle hTimer, DataPack data)
{
	data.Reset();
	int iClient = EntRefToEntIndex(data.ReadCell());
	haleSpells spellIndex = data.ReadCell();
	
	if (iClient <= 0 || iClient > MaxClients || !IsClientInGame(iClient)) return;
	
	int iSpellbook = GetSpellbook(iClient);
	if (iSpellbook == -1) return;
	
	SetEntProp(iSpellbook, Prop_Send, "m_iSelectedSpellIndex", view_as<int>(spellIndex));
}

public Action Timer_ForceUseAction(Handle hTimer, int iRef)
{
	int iClient = EntRefToEntIndex(iRef);
	if (iClient <= 0 || iClient > MaxClients || !IsClientInGame(iClient)) return;
	
	g_bSpellsRage[iClient] = true;
	Client_ForceUseAction(iClient);
}

void Client_ForceUseAction(int iClient)
{
	KeyValues kv;
	
	kv = new KeyValues("+use_action_slot_item_server");
	FakeClientCommandKeyValues(iClient, kv);
	delete kv;
	
	kv = new KeyValues("-use_action_slot_item_server");
	FakeClientCommandKeyValues(iClient, kv);
	delete kv;
}
