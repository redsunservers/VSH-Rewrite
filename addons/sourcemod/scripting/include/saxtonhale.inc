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
	TFQual_Rarity2,         /**< Unused */
	TFQual_Vintage,
	TFQual_Rarity3,         /**< Unused */
	TFQual_Unusual,
	TFQual_Unique,
	TFQual_Community,
	TFQual_Developer,       /**< Known as Valve Quality */
	TFQual_Selfmade,
	TFQual_Customized,      /**< Unused */
	TFQual_Strange,
	TFQual_Completed,       /**< Unused */
	TFQual_Haunted,
	TFQual_Collectors,
	TFQual_Decorated,
};

/**
 * Array types for each boss function params, for Param_String and Param_Array
 */
enum SaxtonHaleArrayType
{
	VSHArrayType_None,      /**< Not Param_String or Param_Array */
	VSHArrayType_Const,     /**< Only works on Param_String. Length same as size of string, and always constant */
	VSHArrayType_Static,    /**< Data is the fixed length of array */
	VSHArrayType_Dynamic,   /**< Data is Param_Cell param position for length of array, starting from 1 */
}

/**
 * Boss Functions methodmap
 */
methodmap SaxtonHaleFunction
{
	// Initialize a function for methodmap class to use
	//
	// Supported ParamType for calling boss functions:
	// Param_Cell
	// Param_CellByRef
	// Param_Float
	// Param_FloatByRef
	// Param_String (Default array type VSHArrayType_Const)
	// Param_Array (Default array type VSHArrayType_Static with size 1)
	//
	// @param sFunction         Name of function to create.
	// @param nExecType         Execution type to be used.
	// @param ...               Variable number of parameter types
	// @return                  Boss Function Id
	// @error                   Function name already initialized, too many ParamType passed, or unsupported ParamType
	public native SaxtonHaleFunction(const char[] sFunction, ExecType nExecType, ParamType...);
	
	// Add parameter type to this function
	//
	// @param nParamType        Type of parameter
	// @param nArrayType        If string or array, how should size of array be handled?
	// @param iArrayData        Data of nArrayType to be handled
	// @error                   Reached max param size, or invalid param type and array type combined
	public native void AddParam(ParamType nParamType, SaxtonHaleArrayType nArrayType = VSHArrayType_None, int iArrayData = 0);
	
	// Set parameter type to this function, overriding old param
	//
	// @param iParam            Parameter to set, starting from 1
	// @param nParamType        Type of parameter
	// @param nArrayType        If string or array, how should size of array be handled?
	// @param iArrayData        Data of nArrayType to be handled
	// @error                   Invalid parameter number, or invalid param type and array type combined
	public native void SetParam(int iParam, ParamType nParamType, SaxtonHaleArrayType nArrayType = VSHArrayType_None, int iArrayData = 0);
}

/**
 * List of class types
 */
enum SaxtonHaleClassType
{
	VSHClassType_Core,      /**< Core Class from main plugin, called for every client bosses */
	VSHClassType_Boss,      /**< Boss */
	VSHClassType_BossMulti,	/**< Multi Boss */
	VSHClassType_Ability,   /**< Ability */
	VSHClassType_Modifier,  /**< Modifier */
};

/**
 * Registers a class to be used and selected
 *
 * @note Make sure plugin unregisters class once unloaded
 *
 * @param sClass            Class name to register.
 * @param nClassType        Type of class, boss, ability or modifier.
 * @error                   Class name already registered, or VSHClassType_Core passed not from main plugin
 */
native void SaxtonHale_RegisterClass(const char[] sClass, SaxtonHaleClassType nClassType);

/**
 * Unregisters a class
 *
 * @param sClass            Class name to unregister.
 * @error                   Class Type is VSHClassType_Core
 */
native void SaxtonHale_UnregisterClass(const char[] sClass);

/**
 * Gets class's plugin owner
 *
 * @param sClass            Class name to get plugin owner.
 * @return                  Class's plugin owner handle, null if class does not exist
 */
native Handle SaxtonHale_GetPlugin(const char[] sClass);

/**
 * Gets all registered class name
 *
 * @note Returned ArrayList is newly created from calling plugin, so it should be deleted when not needed
 *
 * @return                  Newly created ArrayList of registered class name
 */
native ArrayList SaxtonHale_GetAllClass();

/**
 * Gets all registered class name, filtered by class type
 *
 * @note Returned ArrayList is newly created from calling plugin, so it should be deleted when not needed
 *
 * @return                  Newly created ArrayList of registered class name, filtered by class type
 */
native ArrayList SaxtonHale_GetAllClassType(SaxtonHaleClassType nClassType);

/* Calls a class function
 *
 * @note SaxtonHaleBase parameter will always be 0
 *
 * @param sName             Name of function to call
 * @param ...               Params of function
 * @return			        Return value of function
 * @error                   Invalid function name, too few params expected, incorrect ParamType or reached max allowed call stack.
 */
native any SaxtonHale_CallFunction(const char[] sClass, const char[] sFunction, any...);

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
	VSHSound_Death,
};

/**
 * Client Boss methodmap
 */
methodmap SaxtonHaleBase
{
	public SaxtonHaleBase(int iClient)
	{
		return view_as<SaxtonHaleBase>(iClient);
	}
	
	// Creates a class to client
	//
	// @param sClass        Class name to create
	// @error               Invalid class name passed
	public native void CreateClass(const char[] sClass);
	
	// Return whenever if client has specified class
	//
	// @param sClass        Class name to check
	// @return			    True if client have class, false otherwise
	public native bool HasClass(const char[] sClass);
	
	// Destroys a class to client
	//
	// @param sClass        Class name to destroy
	// @error               Invalid class name passed
	public native void DestroyClass(const char[] sClass);
	
	// Destroy all classes client has
	public native bool DestroyAllClass();
	
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
	// @param sClass        Class name to call
	// @param sFunction     Function name to call
	// @return              True if found and function call started, false if function does not exist
	public bool StartFunction(const char[] sClass, const char[] sFunction)
	{
		Handle hPlugin = SaxtonHale_GetPlugin(sClass);
		if (hPlugin == null)
			return false;
		
		char sBuffer[64];
		Format(sBuffer, sizeof(sBuffer), "%s_%s", sClass, sFunction);
		
		Function func = GetFunctionByName(hPlugin, sBuffer);
		if (func == INVALID_FUNCTION)
			return false;
		
		Call_StartFunction(hPlugin, func);
		Call_PushCell(this);
		return true;
	}
	
	// Get an int property from type
	//
	// @param sClass        Name of type to get
	// @param sProp         Property name to get
	// @return              Value of property
	// @error               Invalid client index, client not in game, or client do not have specified class
	public native int GetPropInt(const char[] sClass, const char[] sProp);
	
	// Get a float property from type
	//
	// @param sClass        Name of type to get
	// @param sProp         Property name to get
	// @return              Value of property
	// @error               Invalid client index, client not in game, or client do not have specified class
	public native float GetPropFloat(const char[] sClass, const char[] sProp);
	
	// Set an int property to type
	//
	// @param sClass        Name of type to set
	// @param sProp         Property name to set
	// @param iVal          Value to set
	// @error               Invalid client index, client not in game, or client do not have specified class
	public native void SetPropInt(const char[] sClass, const char[] sProp, int iVal);
	
	// Set a float property to type
	//
	// @param sClass        Name of type to set
	// @param sProp         Property name to set
	// @param iVal          Value to set
	// @error               Invalid client index, client not in game, or client do not have specified class
	public native void SetPropFloat(const char[] sClass, const char[] sProp, float flVal);
	
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
	
	// Retrieve/Set whether the boss' max health calculation should consider currently-living players or the playercount at the beginning of the round
	property bool bHealthPerPlayerAlive
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
	
	// Retrieve/Set health exponential to calculate
	property float flHealthExponential
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
	// @param result        Optional current value to return function as, can override if returned higher than Plugin_Continue.
	//
	// @return              Plugin_Continue if no actions with return and params
	// @return              Plugin_Changed to override return and params. Note that if hook type is pre, functions may override values agian.
	// @return              Plugin_Handled to override return and params, Call other functions, but prevent further override.
	// @return              Plugin_Stop to override return and params even if current return is Plugin_Handled, prevent further functions and hooks called.
	function void (SaxtonHaleBase boss);
	function void (SaxtonHaleBase boss, any &result);
	function Action (SaxtonHaleBase boss);
	function Action (SaxtonHaleBase boss, any &result);
}

/**
 * Hook a boss function to use when function get called. Also allows to override return and params before returning real value
 *
 * @param sName             Name of function to hook.
 * @param callback          Callback when function get called.
 * @param hookType          Type of hook, pre to call before functions called, or post to call after functions called. Overriding return and params work on both pre and post.
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
 */
native void SaxtonHale_UnhookFunction(const char[] sName, SaxtonHaleHookCallback callback, SaxtonHaleHookMode hookType = VSHHookMode_Post);

/**
 * Get param from function hook, only works on Param_Cell, Param_CellByRef, Param_Float, and Param_FloatByRef
 *
 * @param iParam            Param number to get.
 * @return                  Value of param
 * @error                   Called while not inside hook, param outside of bounds, or incorrect ParamType
 */
native any SaxtonHale_GetParam(int iParam);

/**
 * Set param to function hook, only works on Param_CellByRef, and Param_FloatByRef
 *
 * @param iParam            Param number to set.
 * @param value             Value to set.
 * @error                   Called while not inside hook, param outside of bounds, or incorrect ParamType
 */
native void SaxtonHale_SetParam(int iParam, any value);

/**
 * Get string param size from function hook, used to get Param_String max size buffer and modify it
 *
 * @param iParam            Param number to get.
 * @return                  Length of string
 * @error                   Called while not inside hook, param outside of bounds, or incorrect ParamType
 */
native int SaxtonHale_GetParamStringLength(int iParam);

/**
 * Get string param from function hook, only works on Param_String
 *
 * @param iParam            Param number to get.
 * @param value             String value to get.
 * @param iLength           Length of string
 * @error                   Called while not inside hook, param outside of bounds, or incorrect ParamType
 */
native void SaxtonHale_GetParamString(int iParam, char[] value, int iLength);

/**
 * Set string param to function hook, only works on Param_String, and not VSHArrayType_Const
 *
 * @param iParam            Param number to set.
 * @param value             String value to set.
 * @error                   Called while not inside hook, param outside of bounds, or incorrect ParamType
 */
native void SaxtonHale_SetParamString(int iParam, const char[] value);

/**
 * Get array param from function hook, only works on Param_Array
 *
 * @param iParam            Param number to get.
 * @param value             Array value to get.
 * @param iLength           Length of array
 * @error                   Called while not inside hook, param outside of bounds, or incorrect ParamType
 */
native void SaxtonHale_GetParamArray(int iParam, any[] value, int iLength);

/**
 * Set array param to function hook, only works on Param_Array
 *
 * @param iParam            Param number to set.
 * @param value             Array value to set.
 * @error                   Called while not inside hook, param outside of bounds, or incorrect ParamType
 */
native void SaxtonHale_SetParamArray(int iParam, const any[] value);

/**
 * Methodmap to force set next boss
 */
methodmap SaxtonHaleNextBoss
{
	//Creates new SaxtonHaleNextBoss to set boss, modifier and special round for next match in the list
	//
	// @note If valid client index, client's existing next boss is passed. Otherwise if client index is 0, new Next Boss is made.
	//
	// @param iClient       Client to specify, or 0 for next client in queue
	// @return              Next Boss Methodmap to get and set next boss
	public native SaxtonHaleNextBoss(int iClient = 0);
	
	//Gets current boss type
	//
	// @param sBossType     String value to get, NULL_STRING if not specified yet
	// @param iLength       Size of string
	public native void GetBoss(char[] sBossType, int iLength);
	
	//Sets new boss type
	//
	// @param sBossType     String value to set, NULL_STRING for random boss
	public native void SetBoss(const char[] sBossType);
	
	//Gets current boss multi type
	//
	// @param sMultiType    String value to get, NULL_STRING if not specified yet
	// @param iLength       Size of string
	public native void GetBossMulti(char[] sMultiType, int iLength);
	
	//Sets new boss multi type
	//
	// @param sMultiType    String value to set, NULL_STRING for random boss
	public native void SetBossMulti(const char[] sMultiType);
	
	//Gets current modifier type
	//
	// @param sModifierType String value to get, empty string if none
	// @param iLength       Size of string
	// @return              True if modifier set, or as none. False otherwise
	public native bool GetModifier(char[] sModifierType, int iLength);
	
	//Sets new modifier type
	//
	// @param sModifierType String value to set, empty string for none, NULL_STRING for random modifier
	public native void SetModifier(const char[] sModifierType);
	
	//Gets name to display in chat with client, boss and modifier
	//
	// @param sBuffer       String value to get
	// @param iLength       Size of string
	public native void GetName(char[] sBuffer, int iLength);
	
	// Retrieve client index to play as this boss
	property int iClient
	{
		public native get();
	}
	
	// Retrieve/Set this boss to force play next round
	property bool bForceNext
	{
		public native get();
		public native set(bool val);
	}
	
	// Retrieve/Set this boss round to be a special class round
	property bool bSpecialClassRound
	{
		public native get();
		public native set(bool val);
	}
	
	// Retrieve/Set this boss to play class if bSpecialClassRound is true, random class if TFClass_Unknown
	property TFClassType nSpecialClassType
	{
		public native get();
		public native set(TFClassType val);
	}
}

/**
 * Forward called when boss got telefraged
 *
 * @param iBoss				Client boss whose got telefraged
 * @param iAttacker 		Client whose took the teleporter
 * @param iTeleporterOwner	Client whose the owner of teleporter used
 */
forward void SaxtonHale_OnTeleportDamage(int iBoss, int iAttacker, int iTeleporterOwner);

/**
 * Forward called when client deals damage with damage_backstab_chain tag
 *
 * @param iClient		    Client whose done enough backstabs
 * @param iBoss 		    Client boss whose taken damage from backstab
 */
forward void SaxtonHale_OnChainStabs(int iAttacker, int iBoss);

/**
 * Forward called whenever client have whatever preferences updated
 *
 * @param iClient		    Client that his preferences got updated
 * @param iPreferences	    New preferences
 */
forward void SaxtonHale_OnUpdatePreferences(int iClient, int iPreferences);

/**
 * Forward called whenever client have queue points updated
 *
 * @param iClient	        Client that his queue got updated
 * @param iQueue	        New queue points
 */
forward void SaxtonHale_OnUpdateQueue(int iClient, int iQueue);

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
 * Set whoever client all preferences
 *
 * @param iClient	    	Client to set new preferences
 * @param iPreferences	    New preferences to set
 * @error                   Invalid client index or client not connected
 */
native void SaxtonHale_SetPreferences(int iClient, int iPreferences);

/**
 * Set whoever client queue points
 *
 * @param iClient        	Client to set new preferences
 * @param iQueue        	Queue points to set
 * @error                   Invalid client index or client not connected
 */
native void SaxtonHale_SetQueue(int iClient, int iQueue);

/**
 * Set whoever client to allow admin commands or not
 *
 * @param iClient        	Client to set admin status
 * @param bEnable        	True if allow to give admin command, false otherwise
 * @error                   Invalid client index or client not connected
 */
native void SaxtonHale_SetAdmin(int iClient, bool bEnable);

/**
 * Set whoever client to make his gameplay more harsher or not
 *
 * @param iClient        	Client to set punishment status
 * @param bEnable        	True if give punishment, false otherwise
 * @error                   Invalid client index or client not connected
 */
native void SaxtonHale_SetPunishment(int iClient, bool bEnable);

enum SaxtonHalePreferences
{
	VSHPreferences_PickAsBoss,
	VSHPreferences_Rank,
	VSHPreferences_MultiBoss,
	VSHPreferences_Music,
	VSHPreferences_Revival,
};

/**
 * Get whoever client has given preferences
 *
 * @param iClient	    	Client to set get preferences
 * @param iPreferences	    Preferences to get
 * @error                   Invalid client index or client not connected
 */
native bool SaxtonHale_HasPreferences(int iClient, SaxtonHalePreferences nPreferences);

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
 */
stock void SaxtonHale_PrepareSound(const char[] sSound)
{
	PrecacheSound(sSound, true);
	char sBuffer[PLATFORM_MAX_PATH];
	Format(sBuffer, sizeof(sBuffer), "sound/%s", sSound);
	AddFileToDownloadsTable(sBuffer);
}

/**
 * Precaches a sound and adds music volume compatibility
 *
 * @param sSound			Sound to precache
 * @param bCustom			Should the sound be added to the downloads table?
 */
stock void SaxtonHale_PrepareMusic(const char[] sSound, bool bCustom = true)
{
	// Prefix the filepath with #, so it's considered as music by the engine, allowing people to adjust its volume through the music volume slider
	char sBuffer[PLATFORM_MAX_PATH];
	FormatEx(sBuffer, sizeof(sBuffer), "#%s", sSound);
	PrecacheSound(sBuffer, true);
	
	if (!bCustom)
		return;
	
	if (ReplaceString(sBuffer, sizeof(sBuffer), "#", "sound/") != 1)
	{
		LogError("PrepareMusic could not prepare %s: filepath must not have any '#' characters.", sSound);
		return;
	}
	
	AddFileToDownloadsTable(sBuffer);
}

/**
 * Deprecated functions, do not use
 */

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
	MarkNativeAsOptional("SaxtonHaleFunction.SaxtonHaleFunction");
	MarkNativeAsOptional("SaxtonHaleFunction.AddParam");
	MarkNativeAsOptional("SaxtonHaleFunction.SetParam");
	
	MarkNativeAsOptional("SaxtonHale_RegisterClass");
	MarkNativeAsOptional("SaxtonHale_UnregisterClass");
	MarkNativeAsOptional("SaxtonHale_GetPlugin");
	MarkNativeAsOptional("SaxtonHale_GetAllClass");
	MarkNativeAsOptional("SaxtonHale_GetAllClassType");
	MarkNativeAsOptional("SaxtonHale_CallFunction");
	
	MarkNativeAsOptional("SaxtonHaleBase.CreateClass");
	MarkNativeAsOptional("SaxtonHaleBase.HasClass");
	MarkNativeAsOptional("SaxtonHaleBase.DestroyClass");
	MarkNativeAsOptional("SaxtonHaleBase.DestroyAllClass");
	MarkNativeAsOptional("SaxtonHaleBase.CallFunction");
	MarkNativeAsOptional("SaxtonHaleBase.GetPropInt");
	MarkNativeAsOptional("SaxtonHaleBase.GetPropFloat");
	MarkNativeAsOptional("SaxtonHaleBase.SetPropInt");
	MarkNativeAsOptional("SaxtonHaleBase.SetPropFloat");
	
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
	MarkNativeAsOptional("SaxtonHaleBase.bHealthPerPlayerAlive.get");
	MarkNativeAsOptional("SaxtonHaleBase.bHealthPerPlayerAlive.set");
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
	MarkNativeAsOptional("SaxtonHaleBase.flHealthExponential.get");
	MarkNativeAsOptional("SaxtonHaleBase.flHealthExponential.set");
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
	
	MarkNativeAsOptional("SaxtonHale_HookFunction");
	MarkNativeAsOptional("SaxtonHale_UnhookFunction");
	
	MarkNativeAsOptional("SaxtonHale_GetParam");
	MarkNativeAsOptional("SaxtonHale_SetParam");
	MarkNativeAsOptional("SaxtonHale_GetParamStringLength");
	MarkNativeAsOptional("SaxtonHale_GetParamString");
	MarkNativeAsOptional("SaxtonHale_SetParamString");
	MarkNativeAsOptional("SaxtonHale_GetParamArray");
	MarkNativeAsOptional("SaxtonHale_SetParamArray");
	
	MarkNativeAsOptional("SaxtonHaleNextBoss.SaxtonHaleNextBoss");
	MarkNativeAsOptional("SaxtonHaleNextBoss.GetBoss");
	MarkNativeAsOptional("SaxtonHaleNextBoss.SetBoss");
	MarkNativeAsOptional("SaxtonHaleNextBoss.GetModifier");
	MarkNativeAsOptional("SaxtonHaleNextBoss.SetModifier");
	MarkNativeAsOptional("SaxtonHaleNextBoss.GetName");
	MarkNativeAsOptional("SaxtonHaleNextBoss.iClient.get");
	MarkNativeAsOptional("SaxtonHaleNextBoss.bForceNext.get");
	MarkNativeAsOptional("SaxtonHaleNextBoss.bForceNext.set");
	MarkNativeAsOptional("SaxtonHaleNextBoss.bSpecialClassRound.get");
	MarkNativeAsOptional("SaxtonHaleNextBoss.bSpecialClassRound.set");
	MarkNativeAsOptional("SaxtonHaleNextBoss.nSpecialClassType.get");
	MarkNativeAsOptional("SaxtonHaleNextBoss.nSpecialClassType.set");
	
	MarkNativeAsOptional("SaxtonHale_GetBossTeam");
	MarkNativeAsOptional("SaxtonHale_GetAttackTeam");
	MarkNativeAsOptional("SaxtonHale_GetMainClass");
	MarkNativeAsOptional("SaxtonHale_GetDamage");
	MarkNativeAsOptional("SaxtonHale_GetAssistDamage");
	MarkNativeAsOptional("SaxtonHale_SetPreferences");
	MarkNativeAsOptional("SaxtonHale_SetQueue");
	MarkNativeAsOptional("SaxtonHale_SetAdmin");
	MarkNativeAsOptional("SaxtonHale_SetPunishment");
	MarkNativeAsOptional("SaxtonHale_HasPreferences");
}
#endif