/* !!! YOU MUST USE SOURCEPAWN PUBLIC METHODMAP COMPILER TO COMPILE THIS PLUGIN CORRECTLY !!! */
#if !defined __sourcepawn_methodmap__
	#warning This plugin should be compiled with SourcePawn Public Methodmap to be compiled correctly!
#endif

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <clientprefs>
#include <tf2>
#include <tf2_stocks>
#include <tf2attributes>
#include <tf_econ_data>
#include <dhooks>

#undef REQUIRE_EXTENSIONS
#tryinclude <tf2items>
#define REQUIRE_EXTENSIONS

#pragma semicolon 1
#pragma newdecls required

#include "include/saxtonhale.inc"

#define PLUGIN_VERSION 					"1.4.2"
#define PLUGIN_VERSION_REVISION 		"manual"

#if !defined SP_MAX_EXEC_PARAMS
	#define SP_MAX_EXEC_PARAMS			32		//Max possible params in SourcePawn
#endif

#define MAX_BUTTONS 					26
#define MAX_TYPE_CHAR					32		//Max char size of methodmaps name

#define MAX_CONFIG_ARRAY				16		//Config: Max array size for multiple values of a single parameter
#define MAXLEN_CONFIG_VALUE 			256		//Config: Max string buffer size for individual values
#define MAXLEN_CONFIG_VALUEARRAY		1024	//Config: Max string buffer size for groups of values

#define TF_MAXPLAYERS					32
#define MAX_ATTRIBUTES_SENT 			20

#define ATTRIB_MELEE_RANGE_MULTIPLIER	264
#define ATTRIB_BIDERECTIONAL			276
#define ATTRIB_JUMP_HEIGHT				326
#define ATTRIB_SENTRYATTACKSPEED		343

#define ITEM_ROCK_PAPER_SCISSORS		1110

#define SOUND_ALERT			"ui/system_message_alert.wav"
#define SOUND_METERFULL		"player/recharged.wav"
#define SOUND_BACKSTAB		"player/spy_shield_break.wav"
#define SOUND_DOUBLEDONK	"player/doubledonk.wav"
#define SOUND_NULL			"vo/null.mp3"

#define PARTICLE_GHOST 		"ghost_appearation"

#define FL_EDICT_CHANGED	(1<<0)	// Game DLL sets this when the entity state changes
									// Mutually exclusive with FL_EDICT_PARTIAL_CHANGE.

#define FL_EDICT_FREE		(1<<1)	// this edict if free for reuse
#define FL_EDICT_FULL		(1<<2)	// this is a full server entity

#define FL_EDICT_FULLCHECK	(0<<0)  // call ShouldTransmit() each time, this is a fake flag
#define FL_EDICT_ALWAYS		(1<<3)	// always transmit this entity
#define FL_EDICT_DONTSEND	(1<<4)	// don't transmit this entity
#define FL_EDICT_PVSCHECK	(1<<5)	// always transmit entity, but cull against PVS

#define TEXT_TAG			"\x07E19300[\x07E17100VSH REWRITE\x07E19300]\x01"
#define TEXT_COLOR			"\x07E19F00"
#define TEXT_DARK			"\x07E17100"
#define TEXT_POSITIVE		"\x0744FF11"
#define TEXT_NEGATIVE		"\x07FF4411"
#define TEXT_NEUTRAL		"\x07EEEEEE"
#define TEXT_ERROR			"\x07FF2F00"

const TFTeam TFTeam_Boss = TFTeam_Blue;
const TFTeam TFTeam_Attack = TFTeam_Red;

const TFObjectType TFObject_Invalid = view_as<TFObjectType>(-1);
const TFObjectMode TFObjectMode_Invalid = view_as<TFObjectMode>(-1);

enum ClientFlags ( <<=1 )
{
	ClientFlags_Admin = 1,
	ClientFlags_Punishment,
};

enum
{
	WeaponSlot_Primary = 0,
	WeaponSlot_Secondary,
	WeaponSlot_Melee,
	WeaponSlot_PDABuild,
	WeaponSlot_PDADisguise = 3,
	WeaponSlot_PDADestroy,
	WeaponSlot_InvisWatch = 4,
	WeaponSlot_BuilderEngie,
	WeaponSlot_Unknown1,
	WeaponSlot_Head,
	WeaponSlot_Misc1,
	WeaponSlot_Action,
	WeaponSlot_Misc2
};

enum
{
	LifeState_Alive = 0,
	LifeState_Dead = 2
};

enum FlamethrowerState
{
	FlamethrowerState_Idle = 0,
	FlamethrowerState_StartFiring,
	FlamethrowerState_Firing,
	FlamethrowerState_Airblast,
};

enum
{
	COLLISION_GROUP_NONE  = 0,
	COLLISION_GROUP_DEBRIS,			// Collides with nothing but world and static stuff
	COLLISION_GROUP_DEBRIS_TRIGGER, // Same as debris, but hits triggers
	COLLISION_GROUP_INTERACTIVE_DEBRIS,	// Collides with everything except other interactive debris or debris
	COLLISION_GROUP_INTERACTIVE,	// Collides with everything except interactive debris or debris
	COLLISION_GROUP_PLAYER,
	COLLISION_GROUP_BREAKABLE_GLASS,
	COLLISION_GROUP_VEHICLE,
	COLLISION_GROUP_PLAYER_MOVEMENT,  // For HL2, same as Collision_Group_Player, for
										// TF2, this filters out other players and CBaseObjects
	COLLISION_GROUP_NPC,			// Generic NPC group
	COLLISION_GROUP_IN_VEHICLE,		// for any entity inside a vehicle
	COLLISION_GROUP_WEAPON,			// for any weapons that need collision detection
	COLLISION_GROUP_VEHICLE_CLIP,	// vehicle clip brush to restrict vehicle movement
	COLLISION_GROUP_PROJECTILE,		// Projectiles!
	COLLISION_GROUP_DOOR_BLOCKER,	// Blocks entities not permitted to get near moving doors
	COLLISION_GROUP_PASSABLE_DOOR,	// Doors that the player shouldn't collide with
	COLLISION_GROUP_DISSOLVING,		// Things that are dissolving are in this group
	COLLISION_GROUP_PUSHAWAY,		// Nonsolid on client and server, pushaway in player code

	COLLISION_GROUP_NPC_ACTOR,		// Used so NPCs in scripts ignore the player.
	COLLISION_GROUP_NPC_SCRIPTED,	// USed for NPCs in scripts that should not collide with each other

	LAST_SHARED_COLLISION_GROUP
};

// entity effects
enum
{
	EF_BONEMERGE			= (1<<0),	// Performs bone merge on client side
	EF_BRIGHTLIGHT			= (1<<1),	// DLIGHT centered at entity origin
	EF_DIMLIGHT				= (1<<2),	// player flashlight
	EF_NOINTERP				= (1<<3),	// don't interpolate the next frame
	EF_NOSHADOW				= (1<<4),	// Don't cast no shadow
	EF_NODRAW				= (1<<5),	// don't draw entity
	EF_NORECEIVESHADOW		= (1<<6),	// Don't receive no shadow
	EF_BONEMERGE_FASTCULL	= (1<<7),	// For use with EF_BONEMERGE. If this is set, then it places this ent's origin at its
										// parent and uses the parent's bbox + the max extents of the aiment.
										// Otherwise, it sets up the parent's bones every frame to figure out where to place
										// the aiment, which is inefficient because it'll setup the parent's bones even if
										// the parent is not in the PVS.
	EF_ITEM_BLINK			= (1<<8),	// blink an item so that the user notices it.
	EF_PARENT_ANIMATES		= (1<<9),	// always assume that the parent entity is animating
};

// Beam types, encoded as a byte
enum 
{
	BEAM_POINTS = 0,
	BEAM_ENTPOINT,
	BEAM_ENTS,
	BEAM_HOSE,
	BEAM_SPLINE,
	BEAM_LASER,
	NUM_BEAM_TYPES,
};

// Settings for m_takedamage - from shareddefs.h
enum
{
	DAMAGE_NO = 0,
	DAMAGE_EVENTS_ONLY,		// Call damage functions, but don't modify health
	DAMAGE_YES,
	DAMAGE_AIM,
};

enum
{
	CHANNEL_INTRO = 0,
	CHANNEL_HELP,
	CHANNEL_RAGE,
	CHANNEL_UNUSED1,
	CHANNEL_UNUSED2,
	CHANNEL_UNUSED3,
	CHANNEL_MAX = 6,
};

char g_strPreferencesName[][] = {
	"Boss Selection",
	"Rank Mode",
	"Multi Boss",
	"Music",
	"Revival"
};

// TF2 Class names, ordered from TFClassType
char g_strClassName[TFClassType][] = {
	"Unknown",
	"Scout",
	"Sniper",
	"Soldier",
	"Demoman",
	"Medic",
	"Heavy",
	"Pyro",
	"Spy",
	"Engineer",
};

// TF2 Slot names
char g_strSlotName[][] = {
	"Primary",
	"Secondary",
	"Melee",
	"PDA1",
	"PDA2",
	"Building"
};

// TF2 Building names
char g_strBuildingName[TFObjectType][TFObjectMode][] = {
	{"Dispenser", ""},
	{"Teleporter Entrance", "Teleporter Exit"},
	{"Sentry Gun", ""},
	{"Sapper", ""},
};

// Color Tag
char g_strColorTag[][] = {
	"{positive}",
	"{green}",
	"{negative}",
	"{red}",
	"{neutral}",
	"{grey}"
};

// Color Code
char g_strColorCode[][] = {
	TEXT_POSITIVE,
	TEXT_POSITIVE,
	TEXT_NEGATIVE,
	TEXT_NEGATIVE,
	TEXT_NEUTRAL,
	TEXT_NEUTRAL
};

// Default weapon index for each class and slot
int g_iDefaultWeaponIndex[][] = {
	{-1, -1, -1, -1, -1, -1},	//Unknown
	{13, 23, 0, -1, -1, -1},	//Scout
	{14, 16, 3, -1, -1, -1},	//Sniper
	{18, 10, 6, -1, -1, -1},	//Soldier
	{19, 20, 1, -1, -1, -1},	//Demoman
	{17, 29, 8, -1, -1, -1},	//Medic
	{15, 11, 5, -1, -1, -1},	//Heavy
	{21, 12, 2, -1, -1, -1},	//Pyro
	{24, 735, 4, 27, 30, -1},	//Spy
	{9, 22, 7, 25, 26, 28},		//Engineer
};

// List of class we use to display
TFClassType g_nClassDisplay[sizeof(g_strClassName)] = {
	TFClass_Unknown,
	TFClass_Scout,
	TFClass_Soldier,
	TFClass_Pyro,
	TFClass_DemoMan,
	TFClass_Heavy,
	TFClass_Engineer,
	TFClass_Medic,
	TFClass_Sniper,
	TFClass_Spy,
};

enum struct NextBoss
{
	int iId;							//Id, must be at top of this struct
	int iClient;						//Client to have those values, must be at 2nd top of this struct
	char sBossType[MAX_TYPE_CHAR];		//Boss to play on next turn
	char sBossMultiType[MAX_TYPE_CHAR];	//Boss multi to play on next turn
	char sModifierType[MAX_TYPE_CHAR];	//Modifier to play on next turn
	bool bForceNext;					//This client will be boss next round
	bool bSpecialClassRound;			//All-Class on next turn
	TFClassType nSpecialClassType;		//If bSpecialClassRound, class to force, or TFClass_Unknown for random all-class
}

ArrayList g_aNextBoss;	//Arrays of NextBoss struct
int g_iNextBossId;		//Newest created id

bool g_bEnabled;
bool g_bRoundStarted;
bool g_bTF2Items;

int g_iSpritesLaserbeam;
int g_iSpritesGlow;

Handle g_hTimerBossMusic;
char g_sBossMusic[PLATFORM_MAX_PATH];
int g_iHealthBarHealth;
int g_iHealthBarMaxHealth;

//Player data
int g_iPlayerLastButtons[TF_MAXPLAYERS+1];
int g_iPlayerDamage[TF_MAXPLAYERS+1];
int g_iPlayerAssistDamage[TF_MAXPLAYERS+1];
int g_iClientOwner[TF_MAXPLAYERS+1];

int g_iClientFlags[TF_MAXPLAYERS+1];

//Game state data
int g_iTotalRoundPlayed;
int g_iTotalAttackCount;

//ConVars
ConVar tf_arena_use_queue;
ConVar mp_teams_unbalance_limit;
ConVar tf_arena_first_blood;
ConVar tf_dropped_weapon_lifetime;
ConVar mp_forcecamera;
ConVar tf_scout_hype_pep_max;
ConVar tf_damage_disablespread;
ConVar tf_feign_death_activate_damage_scale;
ConVar tf_feign_death_damage_scale;
ConVar tf_stealth_damage_reduction;
ConVar tf_feign_death_duration;
ConVar tf_feign_death_speed_duration;
ConVar tf_arena_preround_time;

#include "vsh/base_ability.sp"
#include "vsh/base_boss.sp"
#include "vsh/base_bossmulti.sp"
#include "vsh/base_modifiers.sp"

#include "vsh/abilities/ability_body_eat.sp"
#include "vsh/abilities/ability_brave_jump.sp"
#include "vsh/abilities/ability_dash_jump.sp"
#include "vsh/abilities/ability_drop_model.sp"
#include "vsh/abilities/ability_float_jump.sp"
#include "vsh/abilities/ability_force_forward.sp"
#include "vsh/abilities/ability_groundpound.sp"
#include "vsh/abilities/ability_model_override.sp"
#include "vsh/abilities/ability_rage_bomb.sp"
#include "vsh/abilities/ability_rage_bomb_projectile.sp"
#include "vsh/abilities/ability_rage_conditions.sp"
#include "vsh/abilities/ability_rage_freeze.sp"
#include "vsh/abilities/ability_rage_gas.sp"
#include "vsh/abilities/ability_rage_ghost.sp"
#include "vsh/abilities/ability_rage_hop.sp"
#include "vsh/abilities/ability_rage_light.sp"
#include "vsh/abilities/ability_rage_scare.sp"
#include "vsh/abilities/ability_teleport_swap.sp"
#include "vsh/abilities/ability_teleport_view.sp"
#include "vsh/abilities/ability_wallclimb.sp"
#include "vsh/abilities/ability_weapon_ball.sp"
#include "vsh/abilities/ability_weapon_charge.sp"
#include "vsh/abilities/ability_weapon_fists.sp"
#include "vsh/abilities/ability_weapon_spells.sp"

#include "vsh/bosses/boss_announcer.sp"
#include "vsh/bosses/boss_blutarch.sp"
#include "vsh/bosses/boss_bonkboy.sp"
#include "vsh/bosses/boss_brutalsniper.sp"
#include "vsh/bosses/boss_demopan.sp"
#include "vsh/bosses/boss_demorobot.sp"
#include "vsh/bosses/boss_gentlespy.sp"
#include "vsh/bosses/boss_hale.sp"
#include "vsh/bosses/boss_horsemann.sp"
#include "vsh/bosses/boss_painiscupcakes.sp"
#include "vsh/bosses/boss_pyrocar.sp"
#include "vsh/bosses/boss_pyromancer_scorched.sp"
#include "vsh/bosses/boss_pyromancer_scalded.sp"
#include "vsh/bosses/boss_redmond.sp"
#include "vsh/bosses/boss_seeldier.sp"
#include "vsh/bosses/boss_seeman.sp"
#include "vsh/bosses/boss_uberranger.sp"
#include "vsh/bosses/boss_vagineer.sp"
#include "vsh/bosses/boss_yeti.sp"
#include "vsh/bosses/boss_zombie.sp"
#include "vsh/bosses/boss_merasmus.sp"

#include "vsh/bossesmulti/bossmulti_mannbrothers.sp"
#include "vsh/bossesmulti/bossmulti_pyromancers.sp"
#include "vsh/bossesmulti/bossmulti_seemanseeldier.sp"

#include "vsh/modifiers/modifiers_angry.sp"
#include "vsh/modifiers/modifiers_electric.sp"
#include "vsh/modifiers/modifiers_hot.sp"
#include "vsh/modifiers/modifiers_ice.sp"
#include "vsh/modifiers/modifiers_jumper.sp"
#include "vsh/modifiers/modifiers_magnet.sp"
#include "vsh/modifiers/modifiers_overload.sp"
#include "vsh/modifiers/modifiers_speed.sp"
#include "vsh/modifiers/modifiers_vampire.sp"

#include "vsh/tags/tags_params.sp"
#include "vsh/tags/tags_target.sp"
#include "vsh/tags/tags_filter.sp"
#include "vsh/tags/tags_block.sp"
#include "vsh/tags/tags_function.sp"
#include "vsh/tags/tags_call.sp"
#include "vsh/tags/tags_core.sp"
#include "vsh/tags/tags_damage.sp"
#include "vsh/tags/tags_name.sp"
#include "vsh/tags.sp"

#include "vsh/config.sp"

#include "vsh/menu/menu_admin.sp"
#include "vsh/menu/menu_boss.sp"
#include "vsh/menu/menu_weapon.sp"
#include "vsh/menu.sp"

#include "vsh/function/func_stack.sp"
#include "vsh/function/func_call.sp"
#include "vsh/function/func_class.sp"
#include "vsh/function/func_function.sp"
#include "vsh/function/func_hook.sp"
#include "vsh/function/func_native.sp"

#include "vsh/classlimit.sp"
#include "vsh/command.sp"
#include "vsh/console.sp"
#include "vsh/cookies.sp"
#include "vsh/dome.sp"
#include "vsh/event.sp"
#include "vsh/forward.sp"
#include "vsh/hud.sp"
#include "vsh/native.sp"
#include "vsh/network.sp"
#include "vsh/nextboss.sp"
#include "vsh/preferences.sp"
#include "vsh/property.sp"
#include "vsh/queue.sp"
#include "vsh/rank.sp"
#include "vsh/sdk.sp"
#include "vsh/stocks.sp"

public Plugin myinfo =
{
	name = "Versus Saxton Hale Rewrite",
	author = "42, Kenzzer",
	description = "Popular VSH Gamemode Rewritten from scrach",
	version = PLUGIN_VERSION ... "." ... PLUGIN_VERSION_REVISION,
	url = "https://github.com/redsunservers/VSH-Rewrite",
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	Forward_AskLoad();
	FuncNative_AskLoad();
	Native_AskLoad();
	Property_AskLoad();

#if !defined __sourcepawn_methodmap__
	Format(error, err_max, "This plugin should be compiled with SourcePawn Public Methodmap to be compiled correctly!");
	return APLRes_Failure;
#else
	RegPluginLibrary("saxtonhale");
	return APLRes_Success;
#endif
}

public void OnPluginStart()
{
	//OnLibraryAdded dont always call TF2Items on plugin start
	g_bTF2Items = LibraryExists("TF2Items");
	
	AddMultiTargetFilter("@hale", BossTargetFilter, "all bosses", false);
	AddMultiTargetFilter("@boss", BossTargetFilter, "all bosses", false);
	AddMultiTargetFilter("@!hale", BossTargetFilter, "all non-bosses", false);
	AddMultiTargetFilter("@!boss", BossTargetFilter, "all non-bosses", false);

	//Collect the convars
	tf_arena_use_queue = FindConVar("tf_arena_use_queue");
	mp_teams_unbalance_limit = FindConVar("mp_teams_unbalance_limit");
	tf_arena_first_blood = FindConVar("tf_arena_first_blood");
	tf_dropped_weapon_lifetime = FindConVar("tf_dropped_weapon_lifetime");
	mp_forcecamera = FindConVar("mp_forcecamera");
	tf_scout_hype_pep_max = FindConVar("tf_scout_hype_pep_max");
	tf_damage_disablespread = FindConVar("tf_damage_disablespread");
	tf_feign_death_activate_damage_scale = FindConVar("tf_feign_death_activate_damage_scale");
	tf_feign_death_damage_scale = FindConVar("tf_feign_death_damage_scale");
	tf_stealth_damage_reduction = FindConVar("tf_stealth_damage_reduction");
	tf_feign_death_duration = FindConVar("tf_feign_death_duration");
	tf_feign_death_speed_duration = FindConVar("tf_feign_death_speed_duration");
	tf_arena_preround_time = FindConVar("tf_arena_preround_time");

	AddNormalSoundHook(NormalSoundHook);

	//Allow client 0 (server/console) use admin commands
	Client_AddFlag(0, ClientFlags_Admin);
	
	//Client 0 also used to call boss function and fetch data without needing active boss (precache, menus etc)
	//Modifiers should always be enabled, so modifiers function can be called
	SaxtonHaleBase boss = SaxtonHaleBase(0);
	boss.bModifiers = true;
	
	Config_Init();
	
	ClassLimit_Init();
	Command_Init();
	Console_Init();
	Cookies_Init();
	Dome_Init();
	Event_Init();
	FuncClass_Init();
	FuncFunction_Init();
	FuncHook_Init();
	FuncNative_Init();
	FuncStack_Init();
	Menu_Init();
	NextBoss_Init();
	Rank_Init();
	SDK_Init();
	TagsCall_Init();
	TagsCore_Init();
	TagsName_Init();
	
	SaxtonHaleFunction func;
	
	//Boss functions
	SaxtonHaleFunction("CreateBoss", ET_Single, Param_String);
	SaxtonHaleFunction("IsBossHidden", ET_Single);
	SaxtonHaleFunction("IsBossType", ET_Single, Param_String);
	SaxtonHaleFunction("SetBossType", ET_Ignore, Param_String);
	
	func = SaxtonHaleFunction("GetBossType", ET_Ignore, Param_String, Param_Cell);
	func.SetParam(1, Param_String, VSHArrayType_Dynamic, 2);
	
	func = SaxtonHaleFunction("GetBossName", ET_Ignore, Param_String, Param_Cell);
	func.SetParam(1, Param_String, VSHArrayType_Dynamic, 2);
	
	func = SaxtonHaleFunction("GetBossInfo", ET_Ignore, Param_String, Param_Cell);
	func.SetParam(1, Param_String, VSHArrayType_Dynamic, 2);
	
	//Multi Boss Functions
	SaxtonHaleFunction("CreateBossMulti", ET_Single, Param_String);
	SaxtonHaleFunction("IsBossMultiHidden", ET_Single);
	SaxtonHaleFunction("IsBossMultiType", ET_Single, Param_String);
	SaxtonHaleFunction("SetBossMultiType", ET_Ignore, Param_String);
	SaxtonHaleFunction("GetBossMultiList", ET_Ignore, Param_Cell);
	
	func = SaxtonHaleFunction("GetBossMultiType", ET_Ignore, Param_String, Param_Cell);
	func.SetParam(1, Param_String, VSHArrayType_Dynamic, 2);
	
	func = SaxtonHaleFunction("GetBossMultiName", ET_Ignore, Param_String, Param_Cell);
	func.SetParam(1, Param_String, VSHArrayType_Dynamic, 2);
	
	func = SaxtonHaleFunction("GetBossMultiInfo", ET_Ignore, Param_String, Param_Cell);
	func.SetParam(1, Param_String, VSHArrayType_Dynamic, 2);
	
	//Modifiers functions
	SaxtonHaleFunction("CreateModifiers", ET_Single, Param_String);
	SaxtonHaleFunction("IsModifiersHidden", ET_Single);
	SaxtonHaleFunction("SetModifiersType", ET_Ignore, Param_String);
	
	func = SaxtonHaleFunction("GetModifiersType", ET_Ignore, Param_String, Param_Cell);
	func.SetParam(1, Param_String, VSHArrayType_Dynamic, 2);
	
	func = SaxtonHaleFunction("GetModifiersName", ET_Ignore, Param_String, Param_Cell);
	func.SetParam(1, Param_String, VSHArrayType_Dynamic, 2);
	
	func = SaxtonHaleFunction("GetModifiersInfo", ET_Ignore, Param_String, Param_Cell);
	func.SetParam(1, Param_String, VSHArrayType_Dynamic, 2);
	
	//Ability functions
	SaxtonHaleFunction("CreateAbility", ET_Single, Param_String);
	SaxtonHaleFunction("FindAbility", ET_Single, Param_String);
	SaxtonHaleFunction("DestroyAbility", ET_Ignore, Param_String);
	
	//General functions
	SaxtonHaleFunction("OnThink", ET_Ignore);
	SaxtonHaleFunction("OnSpawn", ET_Ignore);
	SaxtonHaleFunction("OnRage", ET_Ignore);
	SaxtonHaleFunction("OnGiveNamedItem", ET_Single, Param_String, Param_Cell);
	SaxtonHaleFunction("OnEntityCreated", ET_Ignore, Param_Cell, Param_String);
	SaxtonHaleFunction("OnCommandKeyValues", ET_Hook, Param_String);
	SaxtonHaleFunction("OnAttackCritical", ET_Hook, Param_Cell, Param_CellByRef);
	SaxtonHaleFunction("OnVoiceCommand", ET_Hook, Param_String, Param_String);
	SaxtonHaleFunction("OnWeaponSwitchPost", ET_Ignore, Param_Cell);
	
	func = SaxtonHaleFunction("OnSoundPlayed", ET_Hook, Param_Array, Param_CellByRef, Param_String, Param_CellByRef, Param_FloatByRef, Param_CellByRef, Param_CellByRef, Param_CellByRef, Param_String, Param_CellByRef);
	func.SetParam(1, Param_Array, VSHArrayType_Static, MAXPLAYERS);
	func.SetParam(3, Param_String, VSHArrayType_Static, PLATFORM_MAX_PATH);
	func.SetParam(9, Param_String, VSHArrayType_Static, PLATFORM_MAX_PATH);
	
	//Damage/Death functions
	SaxtonHaleFunction("OnPlayerKilled", ET_Ignore, Param_Cell, Param_Cell);
	SaxtonHaleFunction("OnDeath", ET_Ignore, Param_Cell);
	
	func = SaxtonHaleFunction("OnAttackBuilding", ET_Hook, Param_Cell, Param_CellByRef, Param_FloatByRef, Param_CellByRef, Param_CellByRef, Param_Array, Param_Array, Param_Cell);
	func.SetParam(6, Param_Array, VSHArrayType_Static, 3);
	func.SetParam(7, Param_Array, VSHArrayType_Static, 3);
	
	func = SaxtonHaleFunction("OnAttackDamage", ET_Hook, Param_Cell, Param_CellByRef, Param_FloatByRef, Param_CellByRef, Param_CellByRef, Param_Array, Param_Array, Param_Cell);
	func.SetParam(6, Param_Array, VSHArrayType_Static, 3);
	func.SetParam(7, Param_Array, VSHArrayType_Static, 3);
	
	func = SaxtonHaleFunction("OnTakeDamage", ET_Hook, Param_CellByRef, Param_CellByRef, Param_FloatByRef, Param_CellByRef, Param_CellByRef, Param_Array, Param_Array, Param_Cell);
	func.SetParam(6, Param_Array, VSHArrayType_Static, 3);
	func.SetParam(7, Param_Array, VSHArrayType_Static, 3);
	
	//Button functions
	SaxtonHaleFunction("OnButton", ET_Ignore, Param_CellByRef);
	SaxtonHaleFunction("OnButtonPress", ET_Ignore, Param_Cell);
	SaxtonHaleFunction("OnButtonHold", ET_Ignore, Param_Cell);
	SaxtonHaleFunction("OnButtonRelease", ET_Ignore, Param_Cell);
	
	//Building functions
	SaxtonHaleFunction("OnBuild", ET_Single, Param_Cell, Param_Cell);
	SaxtonHaleFunction("OnBuildObject", ET_Event, Param_Cell);
	SaxtonHaleFunction("OnDestroyObject", ET_Event, Param_Cell);
	SaxtonHaleFunction("OnObjectSapped", ET_Event, Param_Cell);
	
	//Retrieve array/strings
	func = SaxtonHaleFunction("GetModel", ET_Ignore, Param_String, Param_Cell);
	func.SetParam(1, Param_String, VSHArrayType_Dynamic, 2);
	
	func = SaxtonHaleFunction("GetSound", ET_Ignore, Param_String, Param_Cell, Param_Cell);
	func.SetParam(1, Param_String, VSHArrayType_Dynamic, 2);
	
	func = SaxtonHaleFunction("GetSoundKill", ET_Ignore, Param_String, Param_Cell, Param_Cell);
	func.SetParam(1, Param_String, VSHArrayType_Dynamic, 2);
	
	func = SaxtonHaleFunction("GetSoundAbility", ET_Ignore, Param_String, Param_Cell, Param_String);
	func.SetParam(1, Param_String, VSHArrayType_Dynamic, 2);
	
	func = SaxtonHaleFunction("GetRenderColor", ET_Ignore, Param_Array);
	func.SetParam(1, Param_Array, VSHArrayType_Static, 4);
	
	func = SaxtonHaleFunction("GetMusicInfo", ET_Ignore, Param_String, Param_Cell, Param_FloatByRef);
	func.SetParam(1, Param_String, VSHArrayType_Dynamic, 2);
	
	func = SaxtonHaleFunction("GetRageMusicInfo", ET_Ignore, Param_String, Param_Cell, Param_FloatByRef);
	func.SetParam(1, Param_String, VSHArrayType_Dynamic, 2);
	
	//Misc functions
	SaxtonHaleFunction("Precache", ET_Ignore);
	SaxtonHaleFunction("CalculateMaxHealth", ET_Single);
	SaxtonHaleFunction("AddRage", ET_Ignore, Param_Cell);
	SaxtonHaleFunction("CreateWeapon", ET_Single, Param_Cell, Param_String, Param_Cell, Param_Cell, Param_String);
	SaxtonHaleFunction("Destroy", ET_Ignore);
	
	//Register base constructor
	SaxtonHale_RegisterClass("SaxtonHaleBoss", VSHClassType_Core);
	SaxtonHale_RegisterClass("SaxtonHaleBossMulti", VSHClassType_Core);
	SaxtonHale_RegisterClass("SaxtonHaleModifiers", VSHClassType_Core);
	SaxtonHale_RegisterClass("SaxtonHaleAbility", VSHClassType_Core);
	
	//Register normal bosses
	SaxtonHale_RegisterClass("CSaxtonHale", VSHClassType_Boss);
	
	SaxtonHale_RegisterClass("CAnnouncer", VSHClassType_Boss);
	SaxtonHale_RegisterClass("CBlutarch", VSHClassType_Boss);
	SaxtonHale_RegisterClass("CBonkBoy", VSHClassType_Boss);
	SaxtonHale_RegisterClass("CBrutalSniper", VSHClassType_Boss);
	SaxtonHale_RegisterClass("CDemoPan", VSHClassType_Boss);
	SaxtonHale_RegisterClass("CDemoRobot", VSHClassType_Boss);
	SaxtonHale_RegisterClass("CGentleSpy", VSHClassType_Boss);
	SaxtonHale_RegisterClass("CHorsemann", VSHClassType_Boss);
	SaxtonHale_RegisterClass("CMerasmus", VSHClassType_Boss);
	SaxtonHale_RegisterClass("CPainisCupcake", VSHClassType_Boss);
	SaxtonHale_RegisterClass("CPyroCar", VSHClassType_Boss);
	SaxtonHale_RegisterClass("CRedmond", VSHClassType_Boss);
	SaxtonHale_RegisterClass("CScaldedPyromancer", VSHClassType_Boss);
	SaxtonHale_RegisterClass("CScorchedPyromancer", VSHClassType_Boss);
	SaxtonHale_RegisterClass("CSeeldier", VSHClassType_Boss);
	SaxtonHale_RegisterClass("CSeeMan", VSHClassType_Boss);
	SaxtonHale_RegisterClass("CUberRanger", VSHClassType_Boss);
	SaxtonHale_RegisterClass("CVagineer", VSHClassType_Boss);
	SaxtonHale_RegisterClass("CYeti", VSHClassType_Boss);
	
	//Register multi bosses
	SaxtonHale_RegisterClass("CMannBrothers", VSHClassType_BossMulti);
	SaxtonHale_RegisterClass("CPyromancers", VSHClassType_BossMulti);
	SaxtonHale_RegisterClass("CSeeManSeeldier", VSHClassType_BossMulti);
	
	//Register minions
	SaxtonHale_RegisterClass("CSeeldierMinion", VSHClassType_Boss);
	SaxtonHale_RegisterClass("CAnnouncerMinion", VSHClassType_Boss);
	SaxtonHale_RegisterClass("CMinionRanger", VSHClassType_Boss);
	SaxtonHale_RegisterClass("CZombie", VSHClassType_Boss);
	
	//Register ability
	SaxtonHale_RegisterClass("CBodyEat", VSHClassType_Ability);
	SaxtonHale_RegisterClass("CBomb", VSHClassType_Ability);
	SaxtonHale_RegisterClass("CBombProjectile", VSHClassType_Ability);
	SaxtonHale_RegisterClass("CBraveJump", VSHClassType_Ability);
	SaxtonHale_RegisterClass("CDashJump", VSHClassType_Ability);
	SaxtonHale_RegisterClass("CDropModel", VSHClassType_Ability);
	SaxtonHale_RegisterClass("CFloatJump", VSHClassType_Ability);
	SaxtonHale_RegisterClass("CForceForward", VSHClassType_Ability);
	SaxtonHale_RegisterClass("CGroundPound", VSHClassType_Ability);
	SaxtonHale_RegisterClass("CModelOverride", VSHClassType_Ability);
	SaxtonHale_RegisterClass("CRageAddCond", VSHClassType_Ability);
	SaxtonHale_RegisterClass("CRageFreeze", VSHClassType_Ability);
	SaxtonHale_RegisterClass("CRageGas", VSHClassType_Ability);
	SaxtonHale_RegisterClass("CRageGhost", VSHClassType_Ability);
	SaxtonHale_RegisterClass("CRageHop", VSHClassType_Ability);
	SaxtonHale_RegisterClass("CLightRage", VSHClassType_Ability);
	SaxtonHale_RegisterClass("CScareRage", VSHClassType_Ability);
	SaxtonHale_RegisterClass("CTeleportSwap", VSHClassType_Ability);
	SaxtonHale_RegisterClass("CTeleportView", VSHClassType_Ability);
	SaxtonHale_RegisterClass("CWallClimb", VSHClassType_Ability);
	SaxtonHale_RegisterClass("CWeaponBall", VSHClassType_Ability);
	SaxtonHale_RegisterClass("CWeaponCharge", VSHClassType_Ability);
	SaxtonHale_RegisterClass("CWeaponFists", VSHClassType_Ability);
	SaxtonHale_RegisterClass("CWeaponSpells", VSHClassType_Ability);
	
	//Register modifiers
	SaxtonHale_RegisterClass("CModifiersAngry", VSHClassType_Modifier);
	SaxtonHale_RegisterClass("CModifiersElectric", VSHClassType_Modifier);
	SaxtonHale_RegisterClass("CModifiersHot", VSHClassType_Modifier);
	SaxtonHale_RegisterClass("CModifiersIce", VSHClassType_Modifier);
	SaxtonHale_RegisterClass("CModifiersJumper", VSHClassType_Modifier);
	SaxtonHale_RegisterClass("CModifiersMagnet", VSHClassType_Modifier);
	SaxtonHale_RegisterClass("CModifiersOverload", VSHClassType_Modifier);
	SaxtonHale_RegisterClass("CModifiersSpeed", VSHClassType_Modifier);
	SaxtonHale_RegisterClass("CModifiersVampire", VSHClassType_Modifier);
	
	//Init our convars
	g_ConfigConvar.Create("vsh_force_load", "-1", "Force enable VSH on map start? (-1 for default, 0 for force disable, 1 for force enable)", _, true, -1.0, true, 1.0);
	g_ConfigConvar.Create("vsh_boss_ping_limit", "200", "Max ping/latency to allow player to play as boss (-1 for no limit)", _, true, -1.0);
	g_ConfigConvar.Create("vsh_telefrag_damage", "9001.0", "Damage amount to boss from telefrag", _, true, 0.0);
	g_ConfigConvar.Create("vsh_music_enable", "1", "Enable boss music?", _, true, 0.0, true, 1.0);
	g_ConfigConvar.Create("vsh_rps_enable", "1", "Allow everyone use Rock Paper Scissors Taunt?", _, true, 0.0, true, 1.0);
	
	//Incase of lateload, call client join functions
	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if (IsClientConnected(iClient))
			OnClientConnected(iClient);
		
		if (IsClientInGame(iClient))
		{
			OnClientPutInServer(iClient);
			OnClientPostAdminCheck(iClient);
		}
	}
}

public void OnLibraryAdded(const char[] sName)
{
	if (StrEqual(sName, "TF2Items"))
	{
		g_bTF2Items = true;
		
		//We cant allow TF2Items load while GiveNamedItem already hooked due to crash
		if (SDK_IsGiveNamedItemActive())
			PluginStop(true, "[VSH] DO NOT LOAD TF2ITEMS MIDGAME WHILE VSH IS ALREADY LOADED!!!!");
	}
}

public void OnLibraryRemoved(const char[] sName)
{
	if (StrEqual(sName, "TF2Items"))
	{
		g_bTF2Items = false;
		
		//TF2Items unloaded with GiveNamedItem unhooked, we can now safely hook GiveNamedItem ourself
		for (int iClient = 1; iClient <= MaxClients; iClient++)
			if (IsClientInGame(iClient))
				SDK_HookGiveNamedItem(iClient);
	}
}

public void OnPluginEnd()
{
	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if (SaxtonHale_IsValidBoss(iClient))
		{
			SaxtonHaleBase boss = SaxtonHaleBase(iClient);
			boss.CallFunction("Destroy");
		}
	}
	
	Plugin_Cvars(false);
}

void Plugin_Cvars(bool toggle)
{
	static bool bArenaUseQueue;
	static bool bArenaFirstBlood;
	static bool bForceCamera;

	static int iTeamsUnbalanceLimit;
	static int iDroppedWeaponLifetime;
	static int iDamageDisableSpread;

	static float flScoutHypePepMax;
	static float flFeignDeathActiveDamageScale;
	static float flFeignDeathDamageScale;
	static float flStealthDamageReduction;
	static float flFeignDeathDuration;
	static float flFeignDeathSpeed;

	static bool toggled = false; // Used to avoid a overwrite of default value if toggled twice

	if (toggle && !toggled)
	{
		toggled = true;

		bArenaUseQueue = tf_arena_use_queue.BoolValue;
		tf_arena_use_queue.BoolValue = false;

		bArenaFirstBlood = tf_arena_first_blood.BoolValue;
		tf_arena_first_blood.BoolValue = false;

		bForceCamera = mp_forcecamera.BoolValue;
		mp_forcecamera.BoolValue = false;

		iTeamsUnbalanceLimit = mp_teams_unbalance_limit.IntValue;
		mp_teams_unbalance_limit.IntValue = 0;

		iDroppedWeaponLifetime = tf_dropped_weapon_lifetime.IntValue;
		tf_dropped_weapon_lifetime.IntValue = 0;

		iDamageDisableSpread = tf_damage_disablespread.IntValue;
		tf_damage_disablespread.IntValue = 1;

		flScoutHypePepMax = tf_scout_hype_pep_max.FloatValue;
		tf_scout_hype_pep_max.FloatValue = 100.0;

		flFeignDeathActiveDamageScale = tf_feign_death_activate_damage_scale.FloatValue;
		tf_feign_death_activate_damage_scale.FloatValue = 1.0;

		flFeignDeathDamageScale = tf_feign_death_damage_scale.FloatValue;
		tf_feign_death_damage_scale.FloatValue = 1.0;

		flStealthDamageReduction = tf_stealth_damage_reduction.FloatValue;
		tf_stealth_damage_reduction.FloatValue = 1.0;

		flFeignDeathDuration = tf_feign_death_duration.FloatValue;
		tf_feign_death_duration.FloatValue = 7.0;

		flFeignDeathSpeed = tf_feign_death_speed_duration.FloatValue;
		tf_feign_death_speed_duration.FloatValue = 0.0;
	}
	else if (!toggle && toggled)
	{
		toggled = false;

		tf_arena_use_queue.BoolValue = bArenaUseQueue;
		tf_arena_first_blood.BoolValue = bArenaFirstBlood;
		mp_forcecamera.BoolValue = bForceCamera;

		mp_teams_unbalance_limit.IntValue = iTeamsUnbalanceLimit;
		tf_dropped_weapon_lifetime.IntValue = iDroppedWeaponLifetime;
		tf_damage_disablespread.IntValue = iDamageDisableSpread;

		tf_scout_hype_pep_max.FloatValue = flScoutHypePepMax;
		tf_feign_death_activate_damage_scale.FloatValue = flFeignDeathActiveDamageScale;
		tf_feign_death_damage_scale.FloatValue = flFeignDeathDamageScale;
		tf_stealth_damage_reduction.FloatValue = flStealthDamageReduction;
		tf_feign_death_duration.FloatValue = flFeignDeathDuration;
		tf_feign_death_speed_duration.FloatValue = flFeignDeathSpeed;
	}
}

void PluginStop(bool bError = false, const char[] sError = "")
{
	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		SaxtonHaleBase boss = SaxtonHaleBase(iClient);
		if (boss.bValid)
			boss.CallFunction("Destroy");
	}
	if (bError)
	{
		PrintToChatAll("\x07FF0000 !!!!ERROR!!! UNEXPECTED CODE EXECUTION DISABLING GAMEMODE..... \n Please contact an admin ASAP!");
		SetFailState(sError);
	}
}

public void OnMapStart()
{
	//Check if the map is a VSH map
	char sMapName[64];
	GetCurrentMap(sMapName, sizeof(sMapName));
	GetMapDisplayName(sMapName, sMapName, sizeof(sMapName));
	
	int iForceLoad = g_ConfigConvar.LookupInt("vsh_force_load");
	
	if (iForceLoad == 0)
	{
		g_bEnabled = false;
	}
	else if ((iForceLoad == 1)
		|| (StrContains(sMapName, "vsh_", false) != -1 && StrContains(sMapName, "vsh_dr_", false) == -1) 
		|| (StrContains(sMapName, "ff2_", false) != -1)
		|| (StrContains(sMapName, "arena_", false) != -1))
	{
		if (FindEntityByClassname(-1, "tf_logic_arena") == -1)
		{
			g_bEnabled = false;
			return;
		}

		Config_Refresh();

		//Precache every bosses/abilities/modifiers registered
		SaxtonHaleBase boss = SaxtonHaleBase(0); //client index doesn't matter
		ArrayList aClass = FuncClass_GetAll();
		
		int iLength = aClass.Length;
		for (int i = 0; i < iLength; i++)
		{
			char sType[MAX_TYPE_CHAR];
			aClass.GetString(i, sType, sizeof(sType));
			if (boss.StartFunction(sType, "Precache"))
				Call_Finish();
		}
		
		delete aClass;

		for (int i = 1; i <= 4; i++)
		{
			char sBackStabSound[PLATFORM_MAX_PATH];
			Format(sBackStabSound, sizeof(sBackStabSound), "vsh_rewrite/stab0%i.mp3", i);
			PrepareSound(sBackStabSound);
		}

		PrecacheParticleSystem("ExplosionCore_MidAir");
		PrecacheParticleSystem(PARTICLE_GHOST);

		PrecacheSound(SOUND_ALERT);
		PrecacheSound(SOUND_METERFULL);
		PrecacheSound(SOUND_BACKSTAB);
		PrecacheSound(SOUND_DOUBLEDONK);
		PrecacheSound(SOUND_NULL);
		
		g_iSpritesLaserbeam = PrecacheModel("materials/sprites/laserbeam.vmt", true);
		g_iSpritesGlow = PrecacheModel("materials/sprites/glow01.vmt", true);
		
		Dome_MapStart();
		
		CreateTimer(60.0, Timer_WelcomeMessage);
		CreateTimer(240.0, Timer_WelcomeMessage, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		
		g_bEnabled = true;
	}
	else
	{
		g_bEnabled = false;
	}
}

public void OnGameFrame()
{
	if (!g_bEnabled) return;
	if (g_iTotalRoundPlayed <= 0) return;

	int iHealthBar = FindEntityByClassname(-1, "monster_resource");
	g_iHealthBarHealth = 0;
	g_iHealthBarMaxHealth = 0;

	if (g_bRoundStarted)
	{
		for (int iClient = 1; iClient <= MaxClients; iClient++)
		{
			SaxtonHaleBase boss = SaxtonHaleBase(iClient);
			if (IsClientInGame(iClient) && TF2_GetClientTeam(iClient) == TFTeam_Boss && boss.bValid && !boss.bMinion)
			{
				if (IsPlayerAlive(iClient))
					g_iHealthBarHealth += GetEntProp(iClient, Prop_Send, "m_iHealth");
				g_iHealthBarMaxHealth += SDK_GetMaxHealth(iClient);
			}
		}

		int healthBarValue = RoundToCeil(float(g_iHealthBarHealth) / float(g_iHealthBarMaxHealth) * 255.0);
		if(healthBarValue > 255) healthBarValue = 255;

		SetEntProp(iHealthBar, Prop_Send, "m_iBossHealthPercentageByte", healthBarValue);
	}
	else
		SetEntProp(iHealthBar, Prop_Send, "m_iBossHealthPercentageByte", 0);
}

public void OnEntityCreated(int iEntity, const char[] sClassname)
{
	if (!g_bEnabled || iEntity <= 0 || iEntity > 2048)
		return;
	
	Network_ResetEntity(iEntity);
	
	for (int iClient = 1; iClient <= MaxClients; iClient++)
		if (SaxtonHale_IsValidBoss(iClient))
			SaxtonHaleBase(iClient).CallFunction("OnEntityCreated", iEntity, sClassname);
	
	if (StrContains(sClassname, "tf_projectile_") == 0)
	{
		SDKHook(iEntity, SDKHook_StartTouchPost, Tags_OnProjectileTouch);
	}
	else if (strncmp(sClassname, "item_healthkit_", 15) == 0
		|| strncmp(sClassname, "item_ammopack_", 14) == 0
		|| strcmp(sClassname, "tf_ammo_pack") == 0
		|| strcmp(sClassname, "func_regenerate") == 0)
	{
		SDKHook(iEntity, SDKHook_Touch, ItemPack_OnTouch);
	}
	else if (StrEqual(sClassname, "team_control_point_master"))
	{
		SDKHook(iEntity, SDKHook_Spawn, Dome_MasterSpawn);
	}
	else if (StrEqual(sClassname, "trigger_capture_area"))
	{
		SDKHook(iEntity, SDKHook_Spawn, Dome_TriggerSpawn);
		
		SDKHook(iEntity, SDKHook_StartTouch, Dome_TriggerTouch);
		SDKHook(iEntity, SDKHook_Touch, Dome_TriggerTouch);
		SDKHook(iEntity, SDKHook_EndTouch, Dome_TriggerTouch);
	}
	else if (StrEqual(sClassname, "game_end"))
	{
		//Superceding SetWinningTeam causes some maps to force a map change on capture
		AcceptEntityInput(iEntity, "Kill");
	}
	else if (StrContains(sClassname, "obj_") == 0)
	{
		SDKHook(iEntity, SDKHook_OnTakeDamage, Building_OnTakeDamage);
	}
}

public Action ItemPack_OnTouch(int iEntity, int iToucher)
{
	if (!g_bEnabled) return Plugin_Continue;
	if (g_iTotalRoundPlayed <= 0) return Plugin_Continue;
	
	//Don't allow valid non-attack players pick health and ammo packs
	if (!SaxtonHale_IsValidAttack(iToucher))
		return Plugin_Handled;

	return Plugin_Continue;
}

public void OnEntityDestroyed(int iEntity)
{
	if (0 < iEntity < 2049)
		Network_ResetEntity(iEntity);
}

void Frame_InitVshPreRoundTimer(int iTime)
{
	//Kill the timer created by the game
	int iGameTimer = -1;
	while ((iGameTimer = FindEntityByClassname(iGameTimer, "team_round_timer")) > MaxClients)
	{
		if (GetEntProp(iGameTimer, Prop_Send, "m_bShowInHUD"))
		{
			AcceptEntityInput(iGameTimer, "Kill");
			break;
		}
	}

	//Initiate our timer with our time
	int iTimer = CreateEntityByName("team_round_timer");
	DispatchKeyValue(iTimer, "show_in_hud", "1");
	DispatchSpawn(iTimer);

	SetVariantInt(iTime);
	AcceptEntityInput(iTimer, "SetTime");
	AcceptEntityInput(iTimer, "Resume");
	AcceptEntityInput(iTimer, "Enable");
	SetEntProp(iTimer, Prop_Send, "m_bAutoCountdown", false);

	GameRules_SetPropFloat("m_flStateTransitionTime", float(iTime)+GetGameTime());
	CreateTimer(float(iTime), Timer_EntityCleanup, EntIndexToEntRef(iTimer));

	Event event = CreateEvent("teamplay_update_timer");
	event.Fire();
}

public void Frame_CallJarate(DataPack data)
{
	data.Reset();
	int iClient = GetClientOfUserId(data.ReadCell());
	TagsParams tParams = data.ReadCell();
	
	if (iClient <= 0 || iClient > MaxClients || !IsClientInGame(iClient) || !IsPlayerAlive(iClient))
	{
		delete tParams;
		return;
	}
	
	TagsCore_CallAll(iClient, TagsCall_Jarate, tParams);
	delete tParams;
}

public void TF2_OnConditionAdded(int iClient, TFCond nCond)
{
	if (!g_bEnabled) return;
	if (g_iTotalRoundPlayed <= 0) return;
	
	if (!g_ConfigConvar.LookupInt("vsh_rps_enable"))
	{
		if (GetEntProp(iClient, Prop_Send, "m_iTauntItemDefIndex") == ITEM_ROCK_PAPER_SCISSORS)
		{
			TF2_RemoveCondition(iClient, TFCond_Taunting);
			PrintToChat(iClient, "%s%s Rock, Paper, Scissors taunt is disabled in this gamemode", TEXT_TAG, TEXT_ERROR);
		}
	}
}

public Action Timer_RoundStartSound(Handle hTimer, int iClient)
{
	SaxtonHaleBase boss = SaxtonHaleBase(iClient);
	if (0 < iClient <= MaxClients && IsClientInGame(iClient) && boss.bValid)
	{
		//Play boss intro sound
		char sSound[255];
		boss.CallFunction("GetSound", sSound, sizeof(sSound), VSHSound_RoundStart);
		if (!StrEmpty(sSound))
			BroadcastSoundToTeam(TFTeam_Spectator, sSound);
	}
}

public Action Timer_Music(Handle hTimer, SaxtonHaleBase boss)
{
	if (g_hTimerBossMusic != hTimer)
		return Plugin_Stop;
	
	if (!boss.bValid)
	{
		g_hTimerBossMusic = null;
		return Plugin_Stop;
	}
	
	if (StrEmpty(g_sBossMusic))
		return Plugin_Stop;

	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if (IsClientInGame(iClient))
		{
			//Stop current music before playing another one
			StopSound(iClient, SNDCHAN_AUTO, g_sBossMusic);
			
			if (Preferences_Get(iClient, VSHPreferences_Music))
				EmitSoundToClient(iClient, g_sBossMusic);
		}
	}

	return Plugin_Continue;
}

public Action Timer_WelcomeMessage(Handle hTimer)
{
	if (!g_bEnabled)
		return Plugin_Stop;
	
	PrintToChatAll("%s%s Welcome to Versus Saxton Hale: Rewrite! \nType %s/vsh%s for more info.", TEXT_TAG, TEXT_COLOR, TEXT_DARK, TEXT_COLOR);
	return Plugin_Continue;
}

public Action Timer_EntityCleanup(Handle hTimer, int iRef)
{
	int iEntity = EntRefToEntIndex(iRef);
	if(iEntity > MaxClients)
		AcceptEntityInput(iEntity, "Kill");
	return Plugin_Handled;
}

public void OnClientConnected(int iClient)
{
	Network_ResetClient(iClient);

	g_iPlayerDamage[iClient] = 0;
	g_iPlayerAssistDamage[iClient] = 0;
	g_iClientFlags[iClient] = 0;
	g_iClientOwner[iClient] = 0;

	ClassLimit_SetMainClass(iClient, TFClass_Unknown);
	ClassLimit_SetDesiredClass(iClient, TFClass_Unknown);
	
	//-1 as unknown
	Preferences_SetAll(iClient, -1);
	Queue_SetPlayerPoints(iClient, -1);
	Rank_SetCurrent(iClient, -1);
}

public void OnClientPutInServer(int iClient)
{
	SDK_HookGetMaxHealth(iClient);
	SDK_HookGiveNamedItem(iClient);
	SDKHook(iClient, SDKHook_PreThink, Client_OnThink);
	SDKHook(iClient, SDKHook_OnTakeDamageAlive, Client_OnTakeDamageAlive);
	SDKHook(iClient, SDKHook_WeaponSwitchPost, Client_OnWeaponSwitchPost);
	
	Cookies_OnClientJoin(iClient);
}

public void OnClientPostAdminCheck(int iClient)
{
	AdminId iAdmin = GetUserAdmin(iClient);
	if (iAdmin.HasFlag(Admin_RCON) || iAdmin.HasFlag(Admin_Root))
		Client_AddFlag(iClient, ClientFlags_Admin);
}

public void OnClientDisconnect(int iClient)
{
	SaxtonHaleBase boss = SaxtonHaleBase(iClient);
	
	if (Rank_GetClient() == iClient && Rank_IsEnabled())
	{
		//Ur not going anywhere kiddo
		int iRank = Rank_GetCurrent(iClient) - 1;
		if (iRank >= 0)
		{
			PrintToChatAll("%s %s%N%s's rank has %sdecreased%s to %s%d%s!", TEXT_TAG, TEXT_DARK, iClient, TEXT_COLOR, TEXT_NEGATIVE, TEXT_COLOR, TEXT_DARK, iRank, TEXT_COLOR);
			Rank_SetCurrent(iClient, iRank, true);
		}
		
		Rank_ClearClient();
	}
	
	if (boss.bValid)
	{
		boss.CallFunction("Destroy");
		CheckForceAttackWin(iClient);
	}

	g_iClientFlags[iClient] = 0;

	SDK_UnhookGiveNamedItem(iClient);

	ClassLimit_SetMainClass(iClient, TFClass_Unknown);
	ClassLimit_SetDesiredClass(iClient, TFClass_Unknown);
	
	Preferences_SetAll(iClient, -1);
	Queue_SetPlayerPoints(iClient, -1);
	Rank_SetCurrent(iClient, -1);
	
	NextBoss_DeleteClient(iClient);
}

public void OnClientDisconnect_Post(int iClient)
{
	TagsCore_RefreshClient(iClient);	//Free the memory
}

public void Client_OnThink(int iClient)
{
	if (!g_bEnabled) return;
	
	Dome_OnThink(iClient);
	
	if (g_iTotalRoundPlayed <= 0) return;
	
	SaxtonHaleBase boss = SaxtonHaleBase(iClient);
	if (boss.bValid)
		boss.CallFunction("OnThink");
	else
	{
		Tags_OnThink(iClient);
		
		TFClassType nClass = TF2_GetPlayerClass(iClient);
		
		int iActiveWep = GetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon");

		int iIndex = -1;
		int iSlot = -1;
		if (IsValidEntity(iActiveWep))
		{
			iIndex = GetEntProp(iActiveWep, Prop_Send, "m_iItemDefinitionIndex");
			iSlot = TF2_GetItemSlot(iIndex, nClass);
		}

		if (0 <= iSlot < sizeof(g_ConfigClass[]) && IsValidEntity(iActiveWep) && !TF2_IsPlayerInCondition(iClient, TFCond_Disguised) && !TF2_IsPlayerInCondition(iClient, TFCond_Cloaked))
		{
			//Get amount of active players
			int iPlayerCount = SaxtonHale_GetAliveAttackPlayers();
			
			//Check minicrit from index
			int iMinicrit = g_ConfigIndex.IsMinicrit(iIndex);
			if (iMinicrit == 1)
			{
				TF2_AddCondition(iClient, TFCond_Buffed, 0.05);
			}
			else if (iMinicrit != 0)	//not 0 in config
			{
				//Check minicrit from slot
				iMinicrit = g_ConfigClass[nClass][iSlot].IsMinicrit();
				if (iMinicrit == 1)
					TF2_AddCondition(iClient, TFCond_Buffed, 0.05);
				else if (iMinicrit != 0 && iPlayerCount <= 3)	//Give minicrit if less than 3 players and not 0 in config
					TF2_AddCondition(iClient, TFCond_Buffed, 0.05);
			}
			
			//Check crit from index
			int iCrit = g_ConfigIndex.IsCrit(iIndex);
			if (iCrit == 1)
			{
				TF2_AddCondition(iClient, TFCond_CritOnDamage, 0.05);
			}
			else if (iCrit != 0)	//not 0 in config
			{
				//Check minicrit from slot
				iCrit = g_ConfigClass[nClass][iSlot].IsCrit();
				if (iCrit == 1)
					TF2_AddCondition(iClient, TFCond_CritOnDamage, 0.05);
				else if (iCrit != 0 && iPlayerCount <= 1)	//Give crit if last man and not 0 in config
					TF2_AddCondition(iClient, TFCond_CritOnDamage, 0.05);
			}
		}
	}
	
	Hud_Think(iClient);
}

public Action Client_OnTakeDamageAlive(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if (!g_bEnabled) return Plugin_Continue;
	if (g_iTotalRoundPlayed <= 0) return Plugin_Continue;
	
	Action finalAction = Plugin_Continue;
	
	if (0 < victim <= MaxClients && IsClientInGame(victim) && GetClientTeam(victim) > 1)
	{
		SaxtonHaleBase bossVictim = SaxtonHaleBase(victim);
		SaxtonHaleBase bossAttacker = SaxtonHaleBase(attacker);
		
		Action action = Plugin_Continue;
		
		if (bossVictim.bValid)
		{
			action = bossVictim.CallFunction("OnTakeDamage", attacker, inflictor, damage, damagetype, weapon, damageForce, damagePosition, damagecustom);
			if (action > finalAction)
				finalAction = action;
		}
		
		if (0 < attacker <= MaxClients && victim != attacker && bossAttacker.bValid)
		{
			action = bossAttacker.CallFunction("OnAttackDamage", victim, inflictor, damage, damagetype, weapon, damageForce, damagePosition, damagecustom);
			if (action > finalAction)
				finalAction = action;
		}
		
		//Stop immediately if returning Plugin_Stop
		if (finalAction == Plugin_Stop)
			return finalAction;
		
		//Call damage tags
		action = TagsDamage_OnTakeDamage(victim, attacker, inflictor, damage, damagetype, weapon, damageForce, damagePosition, damagecustom);
		if (action > finalAction)
			finalAction = action;
		
		char sWeaponClass[64];
		if (weapon > MaxClients)
			GetEdictClassname(weapon, sWeaponClass, sizeof(sWeaponClass));
		
		if (0 < attacker <= MaxClients && IsClientInGame(attacker))
		{
			if (!bossAttacker.bValid)
			{
				if (bossVictim.bValid && !bossVictim.bMinion)
				{
					if (damagecustom == TF_CUSTOM_TELEFRAG && !TF2_IsUbercharged(victim))
					{
						int iTelefragDamage = g_ConfigConvar.LookupInt("vsh_telefrag_damage");
						damage = float(iTelefragDamage);
						PrintCenterText(attacker, "TELEFRAG! You are a pro.");
						PrintCenterText(victim, "TELEFRAG! Be careful around quantum tunneling devices!");
						
						//Try to retrieve the entity under the player, and hopefully this is the teleporter
						int iBuilder = 0;
						int iGroundEntity = GetEntPropEnt(attacker, Prop_Send, "m_hGroundEntity");
						if (iGroundEntity > MaxClients)
						{
							char strGroundEntity[32];
							GetEdictClassname(iGroundEntity, strGroundEntity, sizeof(strGroundEntity));
							if (strcmp(strGroundEntity, "obj_teleporter") == 0)
							{
								iBuilder = GetEntPropEnt(iGroundEntity, Prop_Send, "m_hBuilder");
								if (0 < iBuilder <= MaxClients && IsClientInGame(iBuilder))
								{
									if (attacker != iBuilder)
										g_iPlayerAssistDamage[attacker] = iTelefragDamage;
								}
								else
								{
									iBuilder = 0;
								}
							}
						}

						Forward_TeleportDamage(victim, attacker, iBuilder);
						finalAction = Plugin_Changed;
					}
				}
			}
		}
	}
	return finalAction;
}

public Action Client_OnWeaponSwitchPost(int iClient, int iWeapon)
{
	if (!g_bEnabled) return Plugin_Continue;
	if (g_iTotalRoundPlayed <= 0) return Plugin_Continue;
	
	SaxtonHaleBase boss = SaxtonHaleBase(iClient);
	
	if (0 < iClient <= MaxClients && boss.bValid)
		return boss.CallFunction("OnWeaponSwitchPost", iWeapon);
	
	return Plugin_Continue;
}

public Action Building_OnTakeDamage(int building, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if (!g_bEnabled) return Plugin_Continue;
	if (g_iTotalRoundPlayed <= 0) return Plugin_Continue;
	
	SaxtonHaleBase bossAttacker = SaxtonHaleBase(attacker);
	
	if (0 < attacker <= MaxClients && bossAttacker.bValid)
		return bossAttacker.CallFunction("OnAttackBuilding", building, inflictor, damage, damagetype, weapon, damageForce, damagePosition, damagecustom);
		
	return Plugin_Continue;
}

public bool BossTargetFilter(char[] sPattern, ArrayList aClients)
{
	bool bTargetBoss = StrContains(sPattern, "@!") == -1;
	
	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if (IsClientInGame(iClient) && aClients.FindValue(iClient) == -1)
		{
			bool bIsBoss = SaxtonHale_IsValidBoss(iClient, false);
			
			if (bTargetBoss && bIsBoss)
				aClients.Push(iClient);
			else if (!bTargetBoss && !bIsBoss)
				aClients.Push(iClient);
		}
	}
	
	return true;
}

public Action OnClientCommandKeyValues(int iClient, KeyValues kv)
{
	if (!g_bEnabled) return Plugin_Continue;
	if (iClient <= 0 || iClient > MaxClients || !IsClientInGame(iClient)) return Plugin_Continue;
	
	SaxtonHaleBase boss = SaxtonHaleBase(iClient);
	if (boss.bValid)
	{
		char sCommand[64];
		kv.GetSectionName(sCommand, sizeof(sCommand));
		
		return boss.CallFunction("OnCommandKeyValues", sCommand);
	}
	
	return Plugin_Continue;
}

public Action OnPlayerRunCmd(int iClient,int &buttons,int &impulse, float vel[3], float angles[3],int &weapon,int &subtype,int &cmdnum,int &tickcount,int &seed,int mouse[2])
{
	if (!g_bEnabled) return Plugin_Continue;
	if (g_iTotalRoundPlayed <= 0) return Plugin_Continue;
	if (iClient <= 0 || iClient > MaxClients || !IsClientInGame(iClient)) return Plugin_Continue;

	for (int i = 0; i < MAX_BUTTONS; i++)
	{
		int button = (1 << i);
		if ((buttons & button))
		{
			if (!(g_iPlayerLastButtons[iClient] & button))
				Client_OnButtonPress(iClient, button);
			else
				Client_OnButtonHold(iClient, button);
		}
		else if ((g_iPlayerLastButtons[iClient] & button))
		{
			Client_OnButtonRelease(iClient, button);
		}
	}

	g_iPlayerLastButtons[iClient] = buttons;
	Client_OnButton(iClient, buttons);

	if (g_iPlayerLastButtons[iClient] != buttons)
		return Plugin_Changed;

	return Plugin_Continue;
}

void Client_OnButton(int iClient, int &buttons)
{
	SaxtonHaleBase boss = SaxtonHaleBase(iClient);
	if (boss.bValid)
		boss.CallFunction("OnButton", buttons);
	else
		Tags_OnButton(iClient, buttons);
}

void Client_OnButtonPress(int iClient, int button)
{
	SaxtonHaleBase boss = SaxtonHaleBase(iClient);
	if (boss.bValid)
		boss.CallFunction("OnButtonPress", button);
}

void Client_OnButtonHold(int iClient, int button)
{
	SaxtonHaleBase boss = SaxtonHaleBase(iClient);
	if (boss.bValid)
		boss.CallFunction("OnButtonHold", button);
}

void Client_OnButtonRelease(int iClient, int button)
{
	SaxtonHaleBase boss = SaxtonHaleBase(iClient);
	if (boss.bValid)
		boss.CallFunction("OnButtonRelease", button);
}

public Action TF2_CalcIsAttackCritical(int iClient, int iWeapon, char[] sWepClassName, bool &bResult)
{
	if (!g_bEnabled) return Plugin_Continue;
	if (g_iTotalRoundPlayed <= 0) return Plugin_Continue;
	
	SaxtonHaleBase boss = SaxtonHaleBase(iClient);
	if (boss.bValid)
	{
		return boss.CallFunction("OnAttackCritical", iWeapon, bResult);
	}
	else
	{
		int iIndex = GetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex");
		int iSlot = TF2_GetItemSlot(iIndex, TF2_GetPlayerClass(iClient));
		
		if (WeaponSlot_Primary <= iSlot <= WeaponSlot_BuilderEngie)
		{
			TagsParams tParams = new TagsParams();
			TagsCore_CallSlot(iClient, TagsCall_Attack, iSlot, tParams);
			
			//Override crit result
			int iResult;
			if (tParams.GetIntEx("attackcrit", iResult))
			{
				bResult = !!iResult;
				delete tParams;
				return Plugin_Changed;
			}
			
			delete tParams;
		}
		
		return Plugin_Continue;
	}
}

public Action NormalSoundHook(int clients[MAXPLAYERS], int &numClients, char sample[PLATFORM_MAX_PATH], int &entity, int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
	if (0 < entity <= MaxClients && IsClientInGame(entity))
	{
		SaxtonHaleBase boss = SaxtonHaleBase(entity);
		if (boss.bValid)
			return boss.CallFunction("OnSoundPlayed", clients, numClients, sample, channel, volume, level, pitch, flags, soundEntry, seed);
	}
	return Plugin_Continue;
}

public Action TF2Items_OnGiveNamedItem(int client, char[] classname, int itemDefIndex, Handle &item)
{
	return GiveNamedItem(client, classname, itemDefIndex);
}

Action GiveNamedItem(int iClient, const char[] sClassname, int iIndex)
{
	if (!g_bEnabled) return Plugin_Continue;
	
	SaxtonHaleBase boss = SaxtonHaleBase(iClient);
	if (boss.bValid)
		return boss.CallFunction("OnGiveNamedItem", sClassname, iIndex);
	else if (g_ConfigIndex.IsRestricted(iIndex))
		return Plugin_Handled;
	
	return Plugin_Continue;
}

public Action Timer_DestroyLight(Handle hTimer, int iRef)
{
	int iLight = EntRefToEntIndex(iRef);
	if (iLight > MaxClients)
	{
		AcceptEntityInput(iLight, "TurnOff");
		RequestFrame(Frame_KillLight, iRef);
	}
}

void Frame_KillLight(int iRef)
{
	int iLight = EntRefToEntIndex(iRef);
	if (iLight > MaxClients)
		AcceptEntityInput(iLight, "Kill");
}