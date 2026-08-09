static ArrayList g_aSpells[MAXPLAYERS];
static int g_iCurrentSpellArray[MAXPLAYERS];
static haleSpells g_rageSpells[MAXPLAYERS];
static float g_flSpellsLastUsed[MAXPLAYERS];

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

public void WeaponSpells_Create(SaxtonHaleBase boss)
{
	boss.SetPropFloat("WeaponSpells", "RageRequirement", 0.25);
	boss.SetPropFloat("WeaponSpells", "Cooldown", 0.0);
	g_rageSpells[boss.iClient] = haleSpells_Invalid;
	g_iCurrentSpellArray[boss.iClient] = 0;
	
	if (g_aSpells[boss.iClient] == null)
		g_aSpells[boss.iClient] = new ArrayList();
	g_aSpells[boss.iClient].Clear();
}

public void WeaponSpells_AddSpells(SaxtonHaleBase boss, haleSpells spells)
{
	g_aSpells[boss.iClient].Push(spells);
}

public void WeaponSpells_RageSpells(SaxtonHaleBase boss, haleSpells spells)
{
	g_rageSpells[boss.iClient] = spells;
}

public void WeaponSpells_OnSpawn(SaxtonHaleBase boss)
{
	int iClient = boss.iClient;
	
	//Create and equip spellbook
	char attribs[128];
	Format(attribs, sizeof(attribs), "547 ; 0.5");
	int iSpellbook = boss.CallFunction("CreateWeapon", 1069, "tf_weapon_spellbook", 100, TFQual_Haunted, attribs);
	if (iSpellbook > MaxClients)
	{
		SetEntProp(iSpellbook, Prop_Send, "m_iSpellCharges", 1);
		if (g_aSpells[iClient].Length > 0)
		{
			SetEntProp(iSpellbook, Prop_Send, "m_iSelectedSpellIndex", view_as<int>(g_aSpells[iClient].Get(0)));
			g_iCurrentSpellArray[boss.iClient] = 0;
		}
	}
}

public void WeaponSpells_GetHudInfo(SaxtonHaleBase boss, char[] sMessage, int iLength, int iColor[4])
{
	int iSpellbook = GetSpellbook(boss.iClient);
	if (iSpellbook <= MaxClients)
		return;
	
	float flRagePercentage = float(boss.iRageDamage) / float(boss.iMaxRageDamage);
	
	if (g_flSpellsLastUsed[boss.iClient] > GetGameTime()-boss.GetPropFloat("WeaponSpells", "Cooldown"))
	{
		int iSec = RoundToCeil(boss.GetPropFloat("WeaponSpells", "Cooldown") - (GetGameTime() - g_flSpellsLastUsed[boss.iClient]));
		Format(sMessage, iLength, "%s\nSpell cooldown %i second%s remaining!", sMessage, iSec, (iSec > 1) ? "s" : "");
	}
	else if (flRagePercentage < boss.GetPropFloat("WeaponSpells", "RageRequirement"))
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
	if (g_aSpells[boss.iClient].Length > 1)
		Format(sMessage, iLength, "%s, and reload to change current spell!", sMessage);
	else
		Format(sMessage, iLength, "%s!", sMessage);
}

public void WeaponSpells_OnThink(SaxtonHaleBase boss)
{
	int iSpellbook = GetSpellbook(boss.iClient);
	if (iSpellbook == -1)
		return;
	
	int iSpellIndex = GetEntProp(iSpellbook, Prop_Send, "m_iSelectedSpellIndex");
	if (view_as<int>(g_rageSpells[boss.iClient]) == iSpellIndex && GetEntProp(iSpellbook, Prop_Send, "m_iSpellCharges") > 0)
	{
		//Force client use rare spell and don't override
		Client_ForceUseAction(boss.iClient);
		return;
	}
	
	//Otherwise make sure client always have normal spell
	SetEntProp(iSpellbook, Prop_Send, "m_iSpellCharges", 1);
	SetEntProp(iSpellbook, Prop_Send, "m_iSelectedSpellIndex", view_as<int>(g_aSpells[boss.iClient].Get(g_iCurrentSpellArray[boss.iClient])));
}

public void WeaponSpells_OnRage(SaxtonHaleBase boss)
{
	if (view_as<int>(g_rageSpells[boss.iClient]) == view_as<int>(haleSpells_Invalid))	// SP 1.10 is weird
		return;
	
	int iClient = boss.iClient;
	
	//Set spellbook to specified rare
	int iSpellbook = GetSpellbook(iClient);
	if (iSpellbook == -1)
		return;
	
	SetEntProp(iSpellbook, Prop_Send, "m_iSelectedSpellIndex", view_as<int>(g_rageSpells[iClient]));
	SetEntProp(iSpellbook, Prop_Send, "m_iSpellCharges", boss.bSuperRage ? 3 : 1);
	
	//Force player use spell
	Client_ForceUseAction(iClient);
}

public Action WeaponSpells_OnCommandKeyValues(SaxtonHaleBase boss, const char[] sCommand)
{
	if (StrEqual(sCommand, "+use_action_slot_item_server"))
	{
		//Check whenever if we should allow him to use spell
		int iSpellbook = GetSpellbook(boss.iClient);
		if (iSpellbook == -1)
			return Plugin_Continue;
		
		int iSpellIndex = view_as<haleSpells>(GetEntProp(iSpellbook, Prop_Send, "m_iSelectedSpellIndex"));
		if (iSpellIndex == view_as<int>(haleSpells_Invalid))
			return Plugin_Handled;
		
		if (view_as<int>(g_rageSpells[boss.iClient]) == iSpellIndex)
		{
			//Allow use rage spell as normal
			return Plugin_Continue;
		}
		
		float flRagePercentage = float(boss.iRageDamage) / float(boss.iMaxRageDamage);
		if (flRagePercentage >= boss.GetPropFloat("WeaponSpells", "RageRequirement") && g_flSpellsLastUsed[boss.iClient] <= GetGameTime()-boss.GetPropFloat("WeaponSpells", "Cooldown"))
		{
			//Normal spell, remove rage on use
			boss.iRageDamage -= RoundToFloor(boss.GetPropFloat("WeaponSpells", "RageRequirement") * float(boss.iMaxRageDamage));
			
			//spell cooldowns, set timer after used
			g_flSpellsLastUsed[boss.iClient] = GetGameTime();
			boss.CallFunction("UpdateHudInfo", 1.0, boss.GetPropFloat("WeaponSpells", "Cooldown"));	//Update every second for cooldown duration
			
			
			//Play ability sound if boss have one
			char sSound[PLATFORM_MAX_PATH];
			boss.CallFunction("GetSoundAbility", sSound, sizeof(sSound), "WeaponSpells");
			if (!StrEmpty(sSound))
				EmitSoundToAll(sSound, boss.iClient, SNDCHAN_VOICE, SNDLEVEL_SCREAMING);
			
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

public void WeaponSpells_OnButtonPress(SaxtonHaleBase boss, int button)
{
	if (button == IN_RELOAD && g_aSpells[boss.iClient].Length > 1)
	{
		float flRagePercentage = float(boss.iRageDamage) / float(boss.iMaxRageDamage);
		if (flRagePercentage >= boss.GetPropFloat("WeaponSpells", "RageRequirement"))
		{
			int iSpellbook = GetSpellbook(boss.iClient);
			if (iSpellbook == -1) return;
			
			//Get current spell
			haleSpells spellIndex = view_as<haleSpells>(GetEntProp(iSpellbook, Prop_Send, "m_iSelectedSpellIndex"));
			
			int i = 0;
			while (i < g_aSpells[boss.iClient].Length)
			{
				//Search in array until we found same spell
				if (g_aSpells[boss.iClient].Get(i) == spellIndex)
				{
					//We found it, get the next spell in array
					i++;
					if (i >= g_aSpells[boss.iClient].Length) i = 0;	//if we already at end, loop back to start
					spellIndex = g_aSpells[boss.iClient].Get(i);
					g_iCurrentSpellArray[boss.iClient] = i;
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
		Client_ForceUseAction(boss.iClient);
	}
}

public void WeaponSpells_OnEntityCreated(SaxtonHaleBase boss, int iEntity, const char[] sClassname)
{
	if (StrEqual(sClassname, "eyeball_boss"))
		SDKHook(iEntity, SDKHook_SpawnPost, WeaponSpells_OnMonoculusSpawnPost);
}

void WeaponSpells_OnMonoculusSpawnPost(int iEntity)
{
	int iOwner = GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity");
	if (iOwner <= 0 || iOwner > MaxClients || !IsClientInGame(iOwner))
		return;
	
	SaxtonHaleBase boss = SaxtonHaleBase(iOwner);
	if (boss.HasClass("WeaponSpells"))
		SetEntProp(iEntity, Prop_Data, "m_takedamage", DAMAGE_NO);
}

//GetPlayerWeaponSlot is not that great into getting spellbook
stock int GetSpellbook(int iClient)
{
	int iSpellbook = MaxClients+1;
	while ((iSpellbook = FindEntityByClassname(iSpellbook, "tf_weapon_spellbook")) != -1)
		if (IsValidEntity(iSpellbook) && GetEntPropEnt(iSpellbook, Prop_Send, "m_hOwnerEntity") == iClient && !GetEntProp(iSpellbook, Prop_Send, "m_bDisguiseWeapon"))
			return iSpellbook;
	
	return -1;
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

