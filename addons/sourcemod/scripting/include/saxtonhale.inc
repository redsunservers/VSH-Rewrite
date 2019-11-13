#if defined _saxtonhale_included
	#endinput
#endif
#define _saxtonhale_included

#include <tf2_stocks>

/**
 * List of TF2 item quality to set boss's weapon
 */
enum TFQuality
{
	TFQual_None = -1,
	TFQual_Normal = 0,
	TFQual_Genuine,
	TFQual_Rarity2,		//Unused
	TFQual_Vintage,
	TFQual_Rarity3,		//Unused
	TFQual_Unusual,
	TFQual_Unique,
	TFQual_Community,
	TFQual_Developer,	//Known as Valve quality
	TFQual_Selfmade,
	TFQual_Customized,	//Unused
	TFQual_Strange,
	TFQual_Completed,	//Unused
	TFQual_Haunted,
	TFQual_Collectors,
	TFQual_Decorated,
};

/**
 * List of sounds to get from bosses
 */
enum SaxtonHaleSound
{
	VSHSound_RoundStart,
	VSHSound_Win,
	VSHSound_Lose,
	VSHSound_Pain,
	VSHSound_Rage,
	VSHSound_KillBuilding,
	VSHSound_Lastman,
	VSHSound_Backstab,
};

/**
 * Registers a boss to be selected, use more than 1 bosses in 1 native for misc boss
 *
 * @note Make sure plugin unregisters boss once unloaded
 *
 * @param ...               Methodmap constructor of boss type.
 * @noreturn
 * @error                   No params passed, or constructor already exists from boss, modifiers or ability
 */
native void SaxtonHale_RegisterBoss(const char[] ...);

/**
 * Unregisters a boss
 *
 * @note If one of misc boss is removed while other boss still here, it get auto-moved to normal boss pick.
 *
 * @param                   sBossType Methodmap constructor of boss type.
 * @noreturn
 */
native void SaxtonHale_UnregisterBoss(const char[] sBossType);

/**
 * Registers a modifier to be selected
 *
 * @note Make sure plugin unregisters modifiers once unloaded
 *
 * @param sModifiersType    Methodmap constructor of modifiers type.
 * @noreturn
 * @error                   Constructor already exists from boss, modifiers or ability
 */
native void SaxtonHale_RegisterModifiers(const char[] sModifiersType);

/**
 * Unregisters a modifier
 *
 * @note If one of misc boss is removed while other boss still here, it get auto-moved to normal boss pick.
 *
 * @param sModifiersType    Methodmap constructor of modifiers type.
 * @noreturn
 */
native void SaxtonHale_UnregisterModifiers(const char[] sModifiersType);

/**
 * Registers an ability to have functions be called
 *
 * @note Make sure plugin unregisters ability once unloaded
 *
 * @param sAbilityType      Methodmap constructor of ability type.
 * @noreturn
 * @error                   Constructor already exists from boss, modifiers or ability
 */
native void SaxtonHale_RegisterAbility(const char[] sAbilityType);

/**
 * Unregisters an ability
 *
 * @note If one of misc boss is removed while other boss still here, it get auto-moved to normal boss pick.
 *
 * @param sAbilityType      Methodmap constructor of modifiers type.
 * @noreturn
 */
native void SaxtonHale_UnregisterAbility(const char[] sAbilityType);

/**
 * Gets constructor's plugin owner
 *
 * @param sType             Methodmap constructor to get plugin owner.
 * @return                  Constructor's plugin owner handle, null if constructor does not exist
 */
native Handle SaxtonHale_GetPlugin(const char[] sType);

/**
 * Boss methodmap
 */
methodmap SaxtonHaleBase
{
	public SaxtonHaleBase(int iClient)
	{
		return view_as<SaxtonHaleBase>(iClient);
	}
	
	// Calls a function to client boss
	//
	// @note String and arrays passed have max size 512, exceeding further can cause crashes
	//
	// @param sName         Name of function to call
	// @param ...           Params of function
	// @return			    Return value of function
	// @error               Invalid function name, too few params expected, incorrect ParamType or reached max allowed call stack.
	public native any CallFunction(const char[] sName, any...);
	
	// Starts a function to specified constructor and function name, ignoring hooks
	//
	// @param sType         Name of constructor to call
	// @param sFunction     Function name to call
	// @return              True if found and function call started, false if function does not exist
	public bool StartFunction(const char[] sType, const char[] sFunction)
	{
		Handle hPlugin = SaxtonHale_GetPlugin(sType);
		if (hPlugin == null)
			return false;
		
		char sBuffer[64];
		Format(sBuffer, sizeof(sBuffer), "%s.%s", sType, sFunction);
		
		Function func = GetFunctionByName(hPlugin, sBuffer);
		if (func == INVALID_FUNCTION)
			return false;
		
		Call_StartFunction(hPlugin, func);
		Call_PushCell(this);
		return true;
	}
	
	// Retrieve client index.
	property int iClient
	{
		public get()
		{
			return view_as<int>(this);
		}
	}
	
	// Retrieve/Set whenever if client is active boss
	property bool bValid
	{
		public native get();
		public native set(bool val);
	}
	
	// Retrieve/Set whenever if client is active modifiers
	property bool bModifiers
	{
		public native get();
		public native set(bool val);
	}
	
	// Retrieve/Set whenever if boss is a minion
	property bool bMinion
	{
		public native get();
		public native set(bool val);
	}
	
	// Retrieve whenever if current/previous rage is a super rage
	property bool bSuperRage
	{
		public native get();
		public native set(bool val);
	}
	
	// Retrieve/Set whenever if boss should have custom model, and remove cosmetics
	property bool bModel
	{
		public native get();
		public native set(bool val);
	}
	
	// Retrieve/Set whenever if boss is allowed to be healed from healing sources
	property bool bCanBeHealed
	{
		public native get();
		public native set(bool val);
	}
	
	// Retrieve/Set max speed
	property float flSpeed
	{
		public native get();
		public native set(float val);
	}
	
	// Retrieve/Set speed multiplier at zero health
	property float flSpeedMult
	{
		public native get();
		public native set(float val);
	}
	
	// Retrieve/Set max env damage to be teleported to spawn
	property float flEnvDamageCap
	{
		public native get();
		public native set(float val);
	}
	
	// Retrieve/Set timer while in air to allow weighdown, -1.0 to disable weighdown
	property float flWeighDownTimer
	{
		public native get();
		public native set(float val);
	}
	
	// Retrieve/Set weighdown force
	property float flWeighDownForce
	{
		public native get();
		public native set(float val);
	}
	
	// Retrieve/Set time remaining for glow to end in seconds, 0.0 for no glow, -1.0 for permanent 
	property float flGlowTime
	{
		public native get();
		public native set(float val);
	}
	
	// Retrieve/Set rage previously used in seconds, -1.0 if had not use rage yet
	property float flRageLastTime
	{
		public native get();
		public native set(float val);
	}
	
	// Retrieve/Set max rage precentage
	property float flMaxRagePercentage
	{
		public native get();
		public native set(float val);
	}
	
	// Retrieve/Set health multiplier to calculate 
	property float flHealthMultiplier
	{
		public native get();
		public native set(float val);
	}
	
	// Retrieve/Set current health
	property int iHealth
	{
		public get()
		{
			return GetEntProp(this.iClient, Prop_Send, "m_iHealth");
		}
		public set(int val)
		{
			SetEntProp(this.iClient, Prop_Send, "m_iHealth", val);
		}
	}
	
	// Retrieve/Set max health
	property int iMaxHealth
	{
		public native get();
		public native set(int val);
	}
	
	// Retrieve/Set base health
	property int iBaseHealth
	{
		public native get();
		public native set(int val);
	}
	
	// Retrieve/Set health per player
	property int iHealthPerPlayer
	{
		public native get();
		public native set(int val);
	}
	
	// Retrieve/Set current damage gained for rage
	property int iRageDamage
	{
		public native get();
		public native set(int val);
	}
	
	// Retrieve/Set damage required to reach 100% rage, -1 if no rage
	property int iMaxRageDamage
	{
		public native get();
		public native set(int val);
	}
	
	// Retrieve/Set boss class
	property TFClassType nClass
	{
		public native get();
		public native set(TFClassType val);
	}
}

/*
 * Used to register/get ability from boss, determine whenever if valid or not
 */
const SaxtonHaleBase INVALID_ABILITY = view_as<SaxtonHaleBase>(-1);

/**
 * Initialize a function for plugins to use said function
 *
 * @param sName             Name of function to create.
 * @param type              Execution type to be used.
 * @param ...               Variable number of parameter types
 * @noreturn
 * @error                   Function name already initialized, more than 16 ParamType passed or unsupported ParamType
 */
native void SaxtonHale_InitFunction(const char[] sName, ExecType type, ParamType ...);

/**
 * Type of hooks
 */
enum SaxtonHaleHookMode
{
 	VSHHookMode_Pre,
 	VSHHookMode_Post,
};

/**
 * Callback of hook functions
 */
typeset SaxtonHaleHookCallback
{	
	// Callback when function is being called.
	//
	// @param boss          Client boss whose being called.
	// @param result        Current value to return function as, overriding does nothing.
	// @noreturn
	function void (SaxtonHaleBase boss);
	function void (SaxtonHaleBase boss, any &result);
	
	// Callback when function is being called.
	//
	// @param boss          Client boss whose being called.
	// @param result        Current value to return function as, can override if returned higher than Plugin_Continue.
	//
	// @return              Plugin_Continue if no actions with return and params
	// @return              Plugin_Changed to override return and params. Note that if hook type is pre, functions may override values agian.
	// @return              Plugin_Handled to override return and params, prevent further functions and hooks overriding, but still call.
	// @return              Plugin_Stop to override return and params even if current return is Plugin_Handled, prevent further functions and hooks called.
	function Action (SaxtonHaleBase boss);
	function Action (SaxtonHaleBase boss, any &result);
}

/**
 * Hook a boss function to use when function get called. Also allows to override return and params before returning real value
 *
 * @param sName             Name of function to hook.
 * @param callback          Callback when function get called.
 * @param hookType          Type of hook, pre to call before functions get called, or post to call after functions get called. Overriding return and params work on both pre and post.
 * @noreturn
 */
native void SaxtonHale_HookFunction(const char[] sName, SaxtonHaleHookCallback callback, SaxtonHaleHookMode hookType = VSHHookMode_Post);

/**
 * Unhook a boss function
 *
 * @note It is not necessary to unhook a function on plugin end
 *
 * @param sName             Name of function to unhook.
 * @param callback          Callback when function get called.
 * @param hookType          Type of hook, pre or post.
 * @noreturn
 */
native void SaxtonHale_UnhookFunction(const char[] sName, SaxtonHaleHookCallback callback, SaxtonHaleHookMode hookType = VSHHookMode_Post);

/**
 * Get param from function hook
 *
 * @param iParam            Param number to get.
 * @return                  Value of param
 * @error                   Called while not inside hook, param outside of bounds, or ParamType not Cell/Float/CellByRef/FloatByRef
 */
native any SaxtonHale_GetParam(int iParam);

/**
 * Set param from function hook
 *
 * @param iParam            Param number to set.
 * @param value             Value to set.
 * @noreturn
 * @error                   Called while not inside hook, param outside of bounds, or ParamType not CellByRef/FloatByRef
 */
native void SaxtonHale_SetParam(int iParam, any value);

/**
 * Get array param from function hook
 *
 * @param iParam            Param number to get.
 * @param value             Array value to get.
 * @param iLength           Length of array
 * @noreturn
 * @error                   Called while not inside hook, param outside of bounds, or ParamType not Array
 */
native void SaxtonHale_GetParamArray(int iParam, any[] value, int iLength);

/**
 * Set array param from function hook
 *
 * @param iParam            Param number to set.
 * @param value             Array value to set.
 * @noreturn
 * @error                   Called while not inside hook, param outside of bounds, or ParamType not Array
 */
native void SaxtonHale_SetParamArray(int iParam, any[] value);

/**
 * Get string param from function hook
 *
 * @param iParam            Param number to get.
 * @param value             String value to get.
 * @param iLength           Length of string
 * @noreturn
 * @error                   Called while not inside hook, param outside of bounds, or ParamType not String
 */
native void SaxtonHale_GetParamString(int iParam, char[] value, int iLength);

/**
 * Set string param from function hook
 *
 * @param iParam            Param number to set.
 * @param value             String value to set.
 * @noreturn
 * @error                   Called while not inside hook, param outside of bounds, or ParamType not String
 */
native void SaxtonHale_SetParamString(int iParam, char[] value);

/**
 * Forward called when boss got telefraged
 *
 * @param iBoss				Client boss whose got telefraged
 * @param iAttacker 		Client whose took the teleporter
 * @param iTeleporterOwner	Client whose the owner of teleporter used
 * @noreturn
 */
forward void SaxtonHale_OnTeleportDamage(int iBoss, int iAttacker, int iTeleporterOwner);

/**
 * Forward called when client deals damage with damage_backstab_chain tag
 *
 * @param iClient		    Client whose done enough backstabs
 * @param iBoss 		    Client boss whose taken damage from backstab
 * @noreturn
 */
forward void SaxtonHale_OnChainStabs(int iAttacker, int iBoss);

/**
 * Forward called whenever client have whatever preferences updated
 *
 * @param iClient		    Client that his preferences got updated
 * @param iPreferences	    New preferences
 * @noreturn
 */
forward void SaxtonHale_OnUpdatePreferences(int iClient, int iPreferences);

/**
 * Forward called whenever client have queue points updated
 *
 * @param iClient	        Client that his queue got updated
 * @param iQueue	        New queue points
 * @noreturn
 */
forward void SaxtonHale_OnUpdateQueue(int iClient, int iQueue);

/**
 * Forward called whenever client have winstreaks updated
 *
 * @param iClient		    Client that his winstreak got updated
 * @param iWinstreak    	New winstreak amount
 * @noreturn
 */
forward void SaxtonHale_OnUpdateWinstreak(int iClient, int iWinstreak);

/**
 * Gets boss team
 *
 * @return                  TFTeam of boss team
 */
native TFTeam SaxtonHale_GetBossTeam();

/**
 * Gets attack team
 *
 * @return                  TFTeam of attack team
 */
native TFTeam SaxtonHale_GetAttackTeam();

/**
 * Gets main class player is currently playing
 *
 * @param iClient        	Client to get main class
 * @return		        	Class the client main class
 * @error                   Invalid client index or client not in game
 */
native TFClassType SaxtonHale_GetMainClass(int iClient);

/**
 * Gets client damage dealt to boss in a single round
 *
 * @param iClient        	Client to get damage dealt
 * @return		        	Damage dealt from client
 * @error                   Invalid client index or client not in game
 */
native int SaxtonHale_GetDamage(int iClient);

/**
 * Gets client assist damage in a single round
 *
 * @param iClient	        Client to get assist damage
 * @return			        Assist damage dealt from client
 * @error                   Invalid client index or client not in game
 */
native int SaxtonHale_GetAssistDamage(int iClient);

/**
 * Force a special round on client next turn as boss
 *
 * @param iClient	        Client to force special round, 0 for next client in queue
 * @param nClass	        Class to force special round, TFClass_Unknown for random class
 * @return		        	True on success, false on fail
 */
native bool SaxtonHale_ForceSpecialRound(int iClient = 0, TFClassType nClass = TFClass_Unknown);

/**
 * Set whoever client all preferences
 *
 * @param iClient	    	Client to set new preferences
 * @param preferences	    New preferences to set
 * @noreturn
 * @error                   Invalid client index or client not connected
 */
native void SaxtonHale_SetPreferences(int iClient, int iPreferences);

/**
 * Set whoever client queue points
 *
 * @param iClient        	Client to set new preferences
 * @param iQueue        	Queue points to set
 * @noreturn
 * @error                   Invalid client index or client not connected
 */
native void SaxtonHale_SetQueue(int iClient, int iQueue);

/**
 * Set whoever client winstreak
 *
 * @param iClient           Client to set new winstreak
 * @param iWinstreak    	Winstreak amount to set
 * @noreturn
 * @error                   Invalid client index or client not connected
 */
native void SaxtonHale_SetWinstreak(int iClient, int iWinstreak);

/**
 * Return whenever if winstreak mode is on or off
 *
 * @return	            	True/False
 */
native bool SaxtonHale_IsWinstreakEnable();

/**
 * Set whoever client to allow admin commands or not
 *
 * @param iClient        	Client to set admin status
 * @param bEnable        	True if allow to give admin command, false otherwise
 * @noreturn
 * @error                   Invalid client index or client not connected
 */
native void SaxtonHale_SetAdmin(int iClient, bool bEnable);

/**
 * Set whoever client to make his gameplay more harsher or not
 *
 * @param iClient        	Client to set punishment status
 * @param bEnable        	True if give punishment, false otherwise
 * @noreturn
 * @error                   Invalid client index or client not connected
 */
native void SaxtonHale_SetPunishment(int iClient, bool bEnable);

/**
 * Gets whoever client is a valid boss or not
 *
 * @param iClient           Client to get whenever if boss or not
 * @param bMinion           Should minion be consider as a valid boss?
 * @return		        	True if boss, false otherwise
 */
stock bool SaxtonHale_IsValidBoss(int iClient, bool bMinion = true)
{
	if (iClient <= 0 || iClient > MaxClients || !IsClientInGame(iClient))
		return false;
	
	SaxtonHaleBase boss = SaxtonHaleBase(iClient);
	if (boss.bValid && (bMinion || !boss.bMinion))
		return true;
	
	return false;
}

/**
 * Get whenever if client is a valid attack
 *
 * @note Does not count minions in attack team
 *
 * @param iClient           Client whenever if valid or not
 * @return			        True if valid attack, false otherwise
 */
stock bool SaxtonHale_IsValidAttack(int iClient)
{
	return (0 < iClient <= MaxClients
		&& IsClientInGame(iClient)
		&& SaxtonHale_GetAttackTeam() == TF2_GetClientTeam(iClient)
		&& !SaxtonHale_IsValidBoss(iClient));
}

/**
 * Get current total amount of alive attack players
 *
 * @note Does not count minions in attack team
 *
 * @return		        	Amount of alive attack players
 */
stock int SaxtonHale_GetAliveAttackPlayers()
{
	int iAlive = 0;
	for (int iClient = 1; iClient <= MaxClients; iClient++)
		if (SaxtonHale_IsValidAttack(iClient) && IsPlayerAlive(iClient))
			iAlive++;

	return iAlive;
}

/**
 * Gets client score in a single round
 *
 * @param iClient        	Client to get score
 * @return		        	Assist damage dealt from client
 */
stock int SaxtonHale_GetScore(int iClient)
{
	return SaxtonHale_GetDamage(iClient) + RoundToFloor(float(SaxtonHale_GetAssistDamage(iClient)) / 2.0);
}

/**
 * Precaches sound and add to download table
 *
 * @param sSound            Sound to precache and add to download table
 * @noreturn
 */
stock void SaxtonHale_PrepareSound(const char[] sSound)
{
	PrecacheSound(sSound, true);
	char sBuffer[PLATFORM_MAX_PATH];
	Format(sBuffer, sizeof(sBuffer), "sound/%s", sSound);
	AddFileToDownloadsTable(sBuffer);
}

public SharedPlugin __pl_saxtonhale =
{
	name = "saxtonhale",
	file = "saxtonhale.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public __pl_saxtonhale_SetNTVOptional()
{
	MarkNativeAsOptional("SaxtonHaleBase.CallFunction");
	
	MarkNativeAsOptional("SaxtonHaleBase.bValid.get");
	MarkNativeAsOptional("SaxtonHaleBase.bValid.set");
	MarkNativeAsOptional("SaxtonHaleBase.bModifiers.get");
	MarkNativeAsOptional("SaxtonHaleBase.bModifiers.set");
	MarkNativeAsOptional("SaxtonHaleBase.bMinion.get");
	MarkNativeAsOptional("SaxtonHaleBase.bMinion.set");
	MarkNativeAsOptional("SaxtonHaleBase.bSuperRage.get");
	MarkNativeAsOptional("SaxtonHaleBase.bSuperRage.set");
	MarkNativeAsOptional("SaxtonHaleBase.bModel.get");
	MarkNativeAsOptional("SaxtonHaleBase.bModel.set");
	MarkNativeAsOptional("SaxtonHaleBase.bCanBeHealed.get");
	MarkNativeAsOptional("SaxtonHaleBase.bCanBeHealed.set");
	MarkNativeAsOptional("SaxtonHaleBase.flSpeed.get");
	MarkNativeAsOptional("SaxtonHaleBase.flSpeed.set");
	MarkNativeAsOptional("SaxtonHaleBase.flSpeedMult.get");
	MarkNativeAsOptional("SaxtonHaleBase.flSpeedMult.set");
	MarkNativeAsOptional("SaxtonHaleBase.flEnvDamageCap.get");
	MarkNativeAsOptional("SaxtonHaleBase.flEnvDamageCap.set");
	MarkNativeAsOptional("SaxtonHaleBase.flGlowTime.get");
	MarkNativeAsOptional("SaxtonHaleBase.flGlowTime.set");
	MarkNativeAsOptional("SaxtonHaleBase.flRageLastTime.get");
	MarkNativeAsOptional("SaxtonHaleBase.flRageLastTime.set");
	MarkNativeAsOptional("SaxtonHaleBase.flMaxRagePercentage.get");
	MarkNativeAsOptional("SaxtonHaleBase.flMaxRagePercentage.set");
	MarkNativeAsOptional("SaxtonHaleBase.flHealthMultiplier.get");
	MarkNativeAsOptional("SaxtonHaleBase.flHealthMultiplier.set");
	MarkNativeAsOptional("SaxtonHaleBase.iMaxHealth.get");
	MarkNativeAsOptional("SaxtonHaleBase.iMaxHealth.set");
	MarkNativeAsOptional("SaxtonHaleBase.iBaseHealth.get");
	MarkNativeAsOptional("SaxtonHaleBase.iBaseHealth.set");
	MarkNativeAsOptional("SaxtonHaleBase.iHealthPerPlayer.get");
	MarkNativeAsOptional("SaxtonHaleBase.iHealthPerPlayer.set");
	MarkNativeAsOptional("SaxtonHaleBase.iRageDamage.get");
	MarkNativeAsOptional("SaxtonHaleBase.iRageDamage.set");
	MarkNativeAsOptional("SaxtonHaleBase.iMaxRageDamage.get");
	MarkNativeAsOptional("SaxtonHaleBase.iMaxRageDamage.set");
	MarkNativeAsOptional("SaxtonHaleBase.nClass.get");
	MarkNativeAsOptional("SaxtonHaleBase.nClass.set");
	
	MarkNativeAsOptional("SaxtonHale_InitFunction");
	
	MarkNativeAsOptional("SaxtonHale_HookFunction");
	MarkNativeAsOptional("SaxtonHale_UnhookFunction");
	
	MarkNativeAsOptional("SaxtonHale_GetParam");
	MarkNativeAsOptional("SaxtonHale_SetParam");
	MarkNativeAsOptional("SaxtonHale_GetParamArray");
	MarkNativeAsOptional("SaxtonHale_SetParamArray");
	MarkNativeAsOptional("SaxtonHale_GetParamString");
	MarkNativeAsOptional("SaxtonHale_SetParamString");
	
	MarkNativeAsOptional("SaxtonHale_RegisterBoss");
	MarkNativeAsOptional("SaxtonHale_UnregisterBoss");
	MarkNativeAsOptional("SaxtonHale_RegisterModifiers");
	MarkNativeAsOptional("SaxtonHale_UnregisterModifiers");
	MarkNativeAsOptional("SaxtonHale_RegisterAbility");
	MarkNativeAsOptional("SaxtonHale_UnregisterAbility");
	
	MarkNativeAsOptional("SaxtonHale_GetBossTeam");
	MarkNativeAsOptional("SaxtonHale_GetAttackTeam");
	MarkNativeAsOptional("SaxtonHale_GetMainClass");
	MarkNativeAsOptional("SaxtonHale_GetDamage");
	MarkNativeAsOptional("SaxtonHale_GetAssistDamage");
	MarkNativeAsOptional("SaxtonHale_ForceSpecialRound");
	MarkNativeAsOptional("SaxtonHale_SetPreferences");
	MarkNativeAsOptional("SaxtonHale_SetQueue");
	MarkNativeAsOptional("SaxtonHale_SetWinstreak");
	MarkNativeAsOptional("SaxtonHale_IsWinstreakEnable");
	MarkNativeAsOptional("SaxtonHale_SetAdmin");
	MarkNativeAsOptional("SaxtonHale_SetPunishment");
}
#endif