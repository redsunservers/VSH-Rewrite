#define SPELL_CYCLE_SOUND		"weapons/vaccinator_toggle.wav" //tf2 wav so no mp3 bye

static ArrayList g_aSpells[MAXPLAYERS];
static int g_iCurrentSpellArray[MAXPLAYERS];
static haleSpells g_rageSpells[MAXPLAYERS];
static float g_flSpellsRechargeStart[MAXPLAYERS];
static int g_iSpellsStored[MAXPLAYERS];
static float g_flSpellsHudEnd[MAXPLAYERS];
static bool g_bSpellArmed[MAXPLAYERS];

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
	boss.SetPropInt("WeaponSpells", "MaxCharges", 1);
	g_rageSpells[boss.iClient] = haleSpells_Invalid;
	g_iCurrentSpellArray[boss.iClient] = 0;
	g_iSpellsStored[boss.iClient] = 1;
	g_flSpellsRechargeStart[boss.iClient] = GetGameTime();
	g_flSpellsHudEnd[boss.iClient] = 0.0;
	
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

public void WeaponSpells_Precache(SaxtonHaleBase boss)
{
	PrecacheSound(SPELL_CYCLE_SOUND);
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

static int WeaponSpells_GetMaxCharges(SaxtonHaleBase boss)
{
	int iMax = boss.GetPropInt("WeaponSpells", "MaxCharges");
	return (iMax < 1) ? 1 : iMax;
}

static int WeaponSpells_GetCharges(SaxtonHaleBase boss, float &flNext)
{
	int iClient = boss.iClient;
	int iMax = WeaponSpells_GetMaxCharges(boss);
	int iStored = g_iSpellsStored[iClient];
	float flCooldown = boss.GetPropFloat("WeaponSpells", "Cooldown");
	
	flNext = 0.0;
	if (iStored >= iMax || flCooldown <= 0.0)
		return iMax;
	
	float flElapsed = GetGameTime() - g_flSpellsRechargeStart[iClient];
	if (flElapsed < 0.0)
		flElapsed = 0.0;
	
	int iGained = RoundToFloor(flElapsed / flCooldown);
	iStored += iGained;
	if (iStored >= iMax)
		return iMax;
	
	flNext = flCooldown - (flElapsed - float(iGained) * flCooldown);
	return iStored;
}

static void WeaponSpells_UpdateHud(SaxtonHaleBase boss)
{
	float flNext;
	int iStored = WeaponSpells_GetCharges(boss, flNext);
	float flDuration = flNext + float(WeaponSpells_GetMaxCharges(boss) - iStored - 1) * boss.GetPropFloat("WeaponSpells", "Cooldown");
	if (flDuration < 0.0)
		flDuration = 0.0;
	
	g_flSpellsHudEnd[boss.iClient] = GetGameTime() + flDuration;
	boss.CallFunction("UpdateHudInfo", 1.0, flDuration);
}

static void WeaponSpells_Recharge(SaxtonHaleBase boss)
{
	int iClient = boss.iClient;
	int iMax = WeaponSpells_GetMaxCharges(boss);
	if (g_iSpellsStored[iClient] >= iMax)
		return;
	
	if (!g_bRoundStarted)
	{
		g_flSpellsRechargeStart[iClient] = GetGameTime();
		return;
	}
	
	if (g_flSpellsRechargeStart[iClient] < g_flRoundStartTime)
		g_flSpellsRechargeStart[iClient] = g_flRoundStartTime;
	
	float flNext;
	int iStored = WeaponSpells_GetCharges(boss, flNext);
	if (iStored > g_iSpellsStored[iClient])
	{
		g_flSpellsRechargeStart[iClient] += float(iStored - g_iSpellsStored[iClient]) * boss.GetPropFloat("WeaponSpells", "Cooldown");
		g_iSpellsStored[iClient] = iStored;
		boss.CallFunction("UpdateHudInfo", 0.0, 0.0);
	}
	
	if (g_iSpellsStored[iClient] < iMax && g_flSpellsHudEnd[iClient] <= GetGameTime())
		WeaponSpells_UpdateHud(boss);
}

static void WeaponSpells_UseCharge(SaxtonHaleBase boss)
{
	int iClient = boss.iClient;
	if (g_iSpellsStored[iClient] >= WeaponSpells_GetMaxCharges(boss))
		g_flSpellsRechargeStart[iClient] = GetGameTime();
	
	if (g_iSpellsStored[iClient] > 0)
		g_iSpellsStored[iClient]--;
}

public void WeaponSpells_GetHudInfo(SaxtonHaleBase boss, char[] sMessage, int iLength, int iColor[4])
{
	int iSpellbook = GetSpellbook(boss.iClient);
	if (iSpellbook <= MaxClients)
		return;

	float flRagePercentage = float(boss.iRageDamage) / float(boss.iMaxRageDamage);

	//show current spell at all times here
	int iSpellIndex = GetEntProp(iSpellbook, Prop_Send, "m_iSelectedSpellIndex");
	if (iSpellIndex >= 0 && view_as<int>(g_rageSpells[boss.iClient]) != iSpellIndex)
		Format(sMessage, iLength, "%s\nSpell: %s", sMessage, g_strSpellsName[iSpellIndex]);

	//show spell status on a separate line, so you know what spell you keep.
	float flNext;
	int iMaxCharges = WeaponSpells_GetMaxCharges(boss);
	int iStored = WeaponSpells_GetCharges(boss, flNext);
	if (iStored < iMaxCharges)
	{
		int iSec = RoundToCeil(flNext);
		Format(sMessage, iLength, "%s\nSpell cooldown %i second%s remaining!", sMessage, iSec, (iSec > 1) ? "s" : "");
		if (iMaxCharges > 1)
			Format(sMessage, iLength, "%s (%d/%d)", sMessage, iStored, iMaxCharges);
	}
	else if (flRagePercentage < boss.GetPropFloat("WeaponSpells", "RageRequirement"))
	{
		Format(sMessage, iLength, "%s\nNot enough rage for spells!", sMessage);
	}
	else if (iMaxCharges > 1)
	{
		Format(sMessage, iLength, "%s\n(%d/%d)", sMessage, iStored, iMaxCharges);
	}

	Format(sMessage, iLength, "%s\nUse attack2 for spell", sMessage);
	if (g_aSpells[boss.iClient].Length > 1)
		Format(sMessage, iLength, "%s, and reload to change current spell!", sMessage);
	else
		Format(sMessage, iLength, "%s!", sMessage);
}

public void WeaponSpells_OnThink(SaxtonHaleBase boss)
{
	int iClient = boss.iClient;
	int iSpellbook = GetSpellbook(iClient);
	if (iSpellbook == -1)
	{
		g_bSpellArmed[iClient] = false;
		return;
	}

	int iSpellIndex = GetEntProp(iSpellbook, Prop_Send, "m_iSelectedSpellIndex");
	int iCharges = GetEntProp(iSpellbook, Prop_Send, "m_iSpellCharges");

	if (view_as<int>(g_rageSpells[iClient]) == iSpellIndex && iCharges > 0)
	{
		//Force client use rare spell and don't override
		Client_ForceUseAction(iClient);
		return;
	}

	//im gonna explode. the keyvalues differ between sourcemod versions. why are we still running ancient stu- oh right...
	float flRagePercentage = float(boss.iRageDamage) / float(boss.iMaxRageDamage);
	WeaponSpells_Recharge(boss);
	bool bCanCast = (flRagePercentage >= boss.GetPropFloat("WeaponSpells", "RageRequirement")
					 && g_iSpellsStored[iClient] > 0);

	if (g_bSpellArmed[iClient])
	{
		if (iCharges <= 0)
		{
			//The engine consumed the charge -> the player really cast the normal spell.
			boss.iRageDamage -= RoundToFloor(boss.GetPropFloat("WeaponSpells", "RageRequirement") * float(boss.iMaxRageDamage));
			WeaponSpells_UseCharge(boss);
			bCanCast = (bCanCast && g_iSpellsStored[iClient] > 0);
			WeaponSpells_UpdateHud(boss);

			char sSound[PLATFORM_MAX_PATH];
			boss.CallFunction("GetSoundAbility", sSound, sizeof(sSound), "WeaponSpells");
			if (!StrEmpty(sSound))
				EmitSoundToAll(sSound, iClient, SNDCHAN_VOICE, SNDLEVEL_SCREAMING);
		}
		g_bSpellArmed[iClient] = false;
	}
	else if (iCharges > 0)
	{
		if (!bCanCast)
			SetEntProp(iSpellbook, Prop_Send, "m_iSpellCharges", 0);
	}

	if (bCanCast)
	{
		//one charge one cast
		SetEntProp(iSpellbook, Prop_Send, "m_iSpellCharges", 1);
		SetEntProp(iSpellbook, Prop_Send, "m_iSelectedSpellIndex", view_as<int>(g_aSpells[iClient].Get(g_iCurrentSpellArray[iClient])));
		g_bSpellArmed[iClient] = true;
	}
}

public void WeaponSpells_OnRage(SaxtonHaleBase boss)
{
	if (view_as<int>(g_rageSpells[boss.iClient]) == view_as<int>(haleSpells_Invalid))	// SP 1.10 is weird
		return;
	
	int iClient = boss.iClient;
	
	//set spellbook to specified rare, rage stuff can't be flipped through
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
		int iSpellbook = GetSpellbook(boss.iClient);
		if (iSpellbook == -1)
			return Plugin_Continue;

		int iSpellIndex = view_as<haleSpells>(GetEntProp(iSpellbook, Prop_Send, "m_iSelectedSpellIndex"));
		if (iSpellIndex == view_as<int>(haleSpells_Invalid))
			return Plugin_Handled;

		if (view_as<int>(g_rageSpells[boss.iClient]) == iSpellIndex)
		{
			//allow use rage spell as normal
			return Plugin_Continue;
		}

		float flRagePercentage = float(boss.iRageDamage) / float(boss.iMaxRageDamage);
		if (flRagePercentage >= boss.GetPropFloat("WeaponSpells", "RageRequirement") && g_iSpellsStored[boss.iClient] > 0)
		{
			//enforcement is handled in OnThink; just let the cast through.
			return Plugin_Continue;
		}
		else
		{
			//not enough rage
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
					//get the next spell in array
					i++;
					if (i >= g_aSpells[boss.iClient].Length) i = 0;	//if we already at end, loop back to start
					spellIndex = g_aSpells[boss.iClient].Get(i);
					g_iCurrentSpellArray[boss.iClient] = i;
					break;
				}
				
				i++;
			}
			
		SetEntProp(iSpellbook, Prop_Send, "m_iSelectedSpellIndex", view_as<int>(spellIndex));
		boss.CallFunction("UpdateHudInfo", 0.0, 0.0);	//hud update on switch
		g_bSpellArmed[boss.iClient] = false;	//selected spell changed; let OnThink re-arm cleanly
		ClientCommand(boss.iClient, "playgamesound %s", SPELL_CYCLE_SOUND);	//vaccinator sound, because it feels nice. clientside
		}
	}
	else if (button == IN_ATTACK2) //self explanatory, reuse method on attack2
	{
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

