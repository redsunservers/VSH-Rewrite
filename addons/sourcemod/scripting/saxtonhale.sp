/* !!! YOU MUST USE SOURCEPAWN PUBLIC METHODMAP COMPILER TO COMPILE THIS PLUGIN CORRECTLY !!! */
#if !defined __sourcepawn_methodmap__
	#warning This plugin should be compiled with SourcePawn Public Methodmap to be compiled correctly!
#endif

#define SAXTONHALE_MAIN_PLUGIN

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <clientprefs>
#include <tf2>
#include <tf2_stocks>
#include <tf2attributes>
#include <tf_econ_data>
#include <dhooks>
#include "include/saxtonhale.inc"

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.1.4"

#define MAX_BUTTONS 		26
#define MAX_TYPE_CHAR		32	//Max char size of methodmaps name
#define MAXLEN_CONFIG_VALUE 256	//Max config string buffer size

#define	TFTeam_Unassigned 	0
#define	TFTeam_Spectator 	1
#define TFTeam_Red 			2
#define TFTeam_Blue 		3

#define TF_MAXPLAYERS		32

#define BOSS_TEAM			TFTeam_Blue
#define ATTACK_TEAM			TFTeam_Red

#define ATTRIB_CRITBOOST_ON_KILL		31
#define ATTRIB_HEAL_ON_KILL				180
#define ATTRIB_HEALTH_PACK_ON_KILL  	203
#define ATTRIB_DECAPITATE_TYPE			219
#define ATTRIB_HEAL_ON_KILL_BASE_HEALTH	220
#define ATTRIB_MELEE_RANGE_MULTIPLIER	264
#define ATTRIB_BIDERECTIONAL			276
#define ATTRIB_JUMP_HEIGHT				326
#define ATTRIB_SENTRYATTACKSPEED		343
#define ATTRIB_FOCUS_ON_KILL			387
#define ATTRIB_MELEE_KILL_CHARGE_METER	2034

#define ITEM_ROCK_PAPER_SCISSORS	1110

#define SOUND_ALERT			"ui/system_message_alert.wav"
#define SOUND_METERFULL		"player/recharged.wav"
#define SOUND_BACKSTAB		"player/spy_shield_break.wav"
#define SOUND_DOUBLEDONK	"player/doubledonk.wav"

#define PARTICLE_GHOST 		"ghost_appearation"

#define FL_EDICT_CHANGED	(1<<0)	// Game DLL sets this when the entity state changes
									// Mutually exclusive with FL_EDICT_PARTIAL_CHANGE.

#define FL_EDICT_FREE		(1<<1)	// this edict if free for reuse
#define FL_EDICT_FULL		(1<<2)	// this is a full server entity

#define FL_EDICT_FULLCHECK	(0<<0)  // call ShouldTransmit() each time, this is a fake flag
#define FL_EDICT_ALWAYS		(1<<3)	// always transmit this entity
#define FL_EDICT_DONTSEND	(1<<4)	// don't transmit this entity
#define FL_EDICT_PVSCHECK	(1<<5)	// always transmit entity, but cull against PVS

#define VSH_TAG				"\x07E19300[\x07E17100VSH REWRITE\x07E19300]\x01"
#define VSH_TEXT_COLOR		"\x07E19F00"
#define VSH_TEXT_DARK		"\x07E17100"
#define VSH_TEXT_POSITIVE	"\x0744FF11"
#define VSH_TEXT_NEGATIVE	"\x07FF4411"
#define VSH_TEXT_NEUTRAL	"\x07EEEEEE"
#define VSH_ERROR_COLOR		"\x07FF2F00"

enum haleClientFlags( <<=1 )
{
	haleClientFlags_BossTeam = 1,
	haleClientFlags_Admin,
	haleClientFlags_Punishment,
};

enum halePreferences( <<=1 )
{
	halePreferences_PickAsBoss = 1,
	halePreferences_Winstreak,
	halePreferences_MultiBoss,
	halePreferences_Music,
	halePreferences_Revival,
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

enum MinigunState
{
	MinigunState_Idle = 0,
	MinigunState_Lowering,
	MinigunState_Shooting,
	MinigunState_Spinning,
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

char g_strPreferencesName[][32] = {
	"Boss Selection",
	"Winstreak",
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
	VSH_TEXT_POSITIVE,
	VSH_TEXT_POSITIVE,
	VSH_TEXT_NEGATIVE,
	VSH_TEXT_NEGATIVE,
	VSH_TEXT_NEUTRAL,
	VSH_TEXT_NEUTRAL
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

bool g_bEnabled = false;
bool g_bRoundStarted = false;
bool g_bBlockRagdoll = false;
bool g_bIceRagdoll = false;

bool g_bSpecialRound = false;
TFClassType g_nSpecialRoundNextClass = TFClass_Unknown;

int g_iSpritesLaserbeam;
int g_iSpritesGlow;

//Main boss data
enum struct NextBoss
{
	int iUserId;
	char sBoss[MAX_TYPE_CHAR];
	char sModifiers[MAX_TYPE_CHAR];
}

ArrayList g_aNextBoss;			//ArrayList of NextBoss struct

ArrayList g_aBossesType;		//ArrayList of string bosses type
ArrayList g_aMiscBossesType;	//ArrayList of ArrayList string bosses type
ArrayList g_aAllBossesType; 	//ArrayList of all bosses
ArrayList g_aModifiersType;		//ArrayList of modifiers

Handle g_hTimerBossMusic = null;
char g_sBossMusic[PLATFORM_MAX_PATH];
int g_iHealthBarHealth;
int g_iHealthBarMaxHealth;

//Player data
float g_flPlayerSpeedMultiplier[TF_MAXPLAYERS+1];
int g_iPlayerLastButtons[TF_MAXPLAYERS+1];
int g_iPlayerDamage[TF_MAXPLAYERS+1];
int g_iPlayerAssistDamage[TF_MAXPLAYERS+1];
bool g_bPlayerTriggerSpecialRound[TF_MAXPLAYERS+1];
int g_iClientOwner[TF_MAXPLAYERS+1];

int g_iClientFlags[TF_MAXPLAYERS+1];

//Game state data
int g_iTotalRoundPlayed;
int g_iTotalAttackCount;

//SDK functions
Handle g_hHookGetMaxHealth = null;
Handle g_hHookShouldTransmit = null;
Handle g_hSDKGetMaxHealth = null;
Handle g_hSDKGetMaxAmmo = null;
Handle g_hSDKSendWeaponAnim = null;
Handle g_hSDKGetMaxClip = null;
Handle g_hSDKRemoveWearable = null;
Handle g_hSDKGetEquippedWearable = null;
Handle g_hSDKEquipWearable = null;

#include "vsh/base_ability.sp"
#include "vsh/base_modifiers.sp"
#include "vsh/base_boss.sp"

#include "vsh/abilities/ability_body_eat.sp"
#include "vsh/abilities/ability_brave_jump.sp"
#include "vsh/abilities/ability_drop_model.sp"
#include "vsh/abilities/ability_rage_bomb.sp"
#include "vsh/abilities/ability_rage_conditions.sp"
#include "vsh/abilities/ability_rage_ghost.sp"
#include "vsh/abilities/ability_rage_light.sp"
#include "vsh/abilities/ability_rage_scare.sp"
#include "vsh/abilities/ability_teleport_swap.sp"
#include "vsh/abilities/ability_wallclimb.sp"
#include "vsh/abilities/ability_weapon_charge.sp"
#include "vsh/abilities/ability_weapon_fists.sp"
#include "vsh/abilities/ability_weapon_spells.sp"

#include "vsh/bosses/boss_hale.sp"
#include "vsh/bosses/boss_painiscupcakes.sp"
#include "vsh/bosses/boss_vagineer.sp"
#include "vsh/bosses/boss_demorobot.sp"
#include "vsh/bosses/boss_gentlespy.sp"
#include "vsh/bosses/boss_demopan.sp"
#include "vsh/bosses/boss_brutalsniper.sp"
#include "vsh/bosses/boss_announcer.sp"
#include "vsh/bosses/boss_horsemann.sp"
#include "vsh/bosses/boss_seeman.sp"
#include "vsh/bosses/boss_seeldier.sp"
#include "vsh/bosses/boss_blutarch.sp"
#include "vsh/bosses/boss_redmond.sp"
#include "vsh/bosses/boss_zombie.sp"
#include "vsh/bosses/boss_merasmus.sp"

#include "vsh/modifiers/modifiers_speed.sp"
#include "vsh/modifiers/modifiers_jump.sp"
#include "vsh/modifiers/modifiers_hot.sp"
#include "vsh/modifiers/modifiers_ice.sp"
#include "vsh/modifiers/modifiers_electric.sp"
#include "vsh/modifiers/modifiers_angry.sp"

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

#include "vsh/classlimit.sp"
#include "vsh/command.sp"
#include "vsh/cookies.sp"
#include "vsh/dome.sp"
#include "vsh/forward.sp"
#include "vsh/function.sp"
#include "vsh/hud.sp"
#include "vsh/native.sp"
#include "vsh/network.sp"
#include "vsh/nextboss.sp"
#include "vsh/preferences.sp"
#include "vsh/queue.sp"
#include "vsh/winstreak.sp"

public Plugin myinfo =
{
	name = "Versus Saxton Hale Rewrite",
	author = "42, Kenzzer",
	description = "Popular VSH Gamemode Rewritten from scrach",
	version = PLUGIN_VERSION,
	url = "https://github.com/redsunservers/VSH-Rewrite",
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	Forward_AskLoad();
	Native_AskLoad();
	RegPluginLibrary("saxtonhale");
	
	return APLRes_Success;
}

public void OnPluginStart()
{
	HookEvent("teamplay_round_start", Event_RoundStart, EventHookMode_Pre);
	HookEvent("teamplay_round_selected", Event_RoundSelected);
	HookEvent("arena_round_start", Event_RoundArenaStart);
	HookEvent("teamplay_round_win", Event_RoundEnd);
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
	HookEvent("post_inventory_application", Event_PlayerInventoryUpdate);
	HookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Pre);
	HookEvent("deploy_buff_banner", Event_BuffBannerDeployed);
	HookEvent("player_chargedeployed", Event_UberDeployed);
	HookEvent("teamplay_broadcast_audio", Event_BroadcastAudio, EventHookMode_Pre);
	HookEvent("player_builtobject", Event_BuiltObject, EventHookMode_Pre);
	HookEvent("object_destroyed", Event_DestroyObject, EventHookMode_Pre);
	HookEvent("player_sapped_object", Event_SappedObject, EventHookMode_Pre);

	HookUserMessage(GetUserMessageId("PlayerJarated"), Event_Jarated);

	AddCommandListener(Client_VoiceCommand, "voicemenu");
	AddCommandListener(Client_KillCommand, "kill");
	AddCommandListener(Client_KillCommand, "explode");
	AddCommandListener(Client_JoinTeamCommand, "jointeam");
	AddCommandListener(Client_JoinTeamCommand, "autoteam");
	AddCommandListener(Client_JoinTeamCommand, "spectate");
	AddCommandListener(Client_JoinClass, "joinclass");
	AddCommandListener(Client_BuildCommand, "build");

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
	Client_AddFlag(0, haleClientFlags_Admin);
	
	//Client 0 also used to call boss function and fetch data without needing active boss (precache, menus etc)
	//Modifiers should always be enabled, so modifiers function can be called
	SaxtonHaleBase boss = SaxtonHaleBase(0);
	boss.bModifiers = true;
	
	g_aNextBoss = new ArrayList(sizeof(NextBoss));
	g_aBossesType = new ArrayList(MAX_TYPE_CHAR);
	g_aMiscBossesType = new ArrayList();
	g_aAllBossesType = new ArrayList(MAX_TYPE_CHAR);
	g_aModifiersType = new ArrayList(MAX_TYPE_CHAR);
	
	Config_Init();
	SDK_Init();
	
	ClassLimit_Init();
	Command_Init();
	Cookies_Init();
	Dome_Init();
	Function_Init();
	Menu_Init();
	NextBoss_Init();
	TagsCall_Init();
	TagsCore_Init();
	TagsName_Init();
	Winstreak_Init();
	
	//Register normal bosses
	SaxtonHale_RegisterBoss("CSaxtonHale");
	SaxtonHale_RegisterBoss("CPainisCupcake");
	SaxtonHale_RegisterBoss("CVagineer");
	SaxtonHale_RegisterBoss("CDemoRobot");
	SaxtonHale_RegisterBoss("CGentleSpy");
	SaxtonHale_RegisterBoss("CDemoPan");
	SaxtonHale_RegisterBoss("CBrutalSniper");
	SaxtonHale_RegisterBoss("CAnnouncer");
	SaxtonHale_RegisterBoss("CHorsemann");
	SaxtonHale_RegisterBoss("CMerasmus");
	
	//Register misc bosses
	SaxtonHale_RegisterBoss("CSeeMan", "CSeeldier");
	SaxtonHale_RegisterBoss("CBlutarch", "CRedmond");
	
	//Register minions
	SaxtonHale_RegisterBoss("CSeeldierMinion");
	SaxtonHale_RegisterBoss("CAnnouncerMinion");
	SaxtonHale_RegisterBoss("CZombie");
	
	//Register modifiers
	SaxtonHale_RegisterModifiers("CModifiersSpeed");
	SaxtonHale_RegisterModifiers("CModifiersJump");
	SaxtonHale_RegisterModifiers("CModifiersHot");
	SaxtonHale_RegisterModifiers("CModifiersIce");
	SaxtonHale_RegisterModifiers("CModifiersElectric");
	SaxtonHale_RegisterModifiers("CModifiersAngry");
	
	//Register ability
	SaxtonHale_RegisterAbility("CBodyEat");
	SaxtonHale_RegisterAbility("CBraveJump");
	SaxtonHale_RegisterAbility("CDropModel");
	SaxtonHale_RegisterAbility("CBomb");
	SaxtonHale_RegisterAbility("CRageAddCond");
	SaxtonHale_RegisterAbility("CRageGhost");
	SaxtonHale_RegisterAbility("CLightRage");
	SaxtonHale_RegisterAbility("CScareRage");
	SaxtonHale_RegisterAbility("CTeleportSwap");
	SaxtonHale_RegisterAbility("CWallClimb");
	SaxtonHale_RegisterAbility("CWeaponCharge");
	SaxtonHale_RegisterAbility("CWeaponFists");
	SaxtonHale_RegisterAbility("CWeaponSpells");
	
	//Init our convars
	g_ConfigConvar.Create("vsh_force_load", "-1", "Force enable VSH on map start? (-1 for default, 0 for force disable, 1 for force enable)", _, true, -1.0, true, 1.0);
	g_ConfigConvar.Create("vsh_boss_ping_limit", "200", "Max ping/latency to allow player to play as boss (-1 for no limit)", _, true, -1.0);
	g_ConfigConvar.Create("vsh_telefrag_damage", "9001.0", "Damage amount to boss from telefrag", _, true, 0.0);
	
	Config_Refresh();
	
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

		//Precache every bosses
		int iLength = g_aAllBossesType.Length;
		for (int i = 0; i < iLength; i++)
		{
			char sBossType[MAX_TYPE_CHAR];
			g_aAllBossesType.GetString(i, sBossType, sizeof(sBossType));
			
			SaxtonHaleBase boss = SaxtonHaleBase(0);
			boss.CallFunction("SetBossType", sBossType);
			boss.CallFunction("Precache");
		}

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
			if (IsClientInGame(iClient) && GetClientTeam(iClient) == BOSS_TEAM && boss.bValid && !boss.bMinion)
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
	if (!g_bEnabled) return;

	if (0 < iEntity < 2049) Network_ResetEntity(iEntity);
	
	if (StrContains(sClassname, "tf_projectile_") == 0)
	{
		SDKHook(iEntity, SDKHook_StartTouchPost, Tags_OnProjectileTouch);
	}
	
	if (strcmp(sClassname, "tf_projectile_healing_bolt") == 0)
	{
		SDKHook(iEntity, SDKHook_StartTouch, Crossbow_OnTouch);
	}
	else if(strncmp(sClassname, "item_healthkit_", 15) == 0
		|| strncmp(sClassname, "item_ammopack_", 14) == 0
		|| strcmp(sClassname, "tf_ammo_pack") == 0
		|| strcmp(sClassname, "func_regenerate") == 0)
	{
		SDKHook(iEntity, SDKHook_Touch, ItemPack_OnTouch);
	}
	else if (g_bBlockRagdoll && strcmp(sClassname, "tf_ragdoll") == 0)
	{
		AcceptEntityInput(iEntity, "Kill");
		g_bBlockRagdoll = false;
	}
	else if (g_bIceRagdoll && strcmp(sClassname, "tf_ragdoll") == 0)
	{
		RequestFrame(Ice_RagdollSpawn, EntIndexToEntRef(iEntity));
		g_bIceRagdoll = false;
	}
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

public Action Event_RoundStart(Event event, const char[] sName, bool bDontBroadcast)
{
	if (!g_bEnabled || GameRules_GetProp("m_bInWaitingForPlayers")) return;

	// Start dome stuffs regardless if first round
	Dome_RoundStart();

	// Play one round of arena
	if (g_iTotalRoundPlayed <= 0) return;

	// Arena has a very dumb logic, if all players from a team leave the round will end and then restart without reseting the game state...
	// Catch that issue and don't run our logic!
	int iRed = 0, iBlu = 0;
	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if (IsClientInGame(iClient))
		{
			if (GetClientTeam(iClient) == TFTeam_Red)
				iRed++;
			else if (GetClientTeam(iClient) == TFTeam_Blue)
				iBlu++;
		}
	}
	// Both team must have at least one player!
	if (iRed == 0 || iBlu == 0)
	{
		if (iRed + iBlu >= 2) //If we have atleast 2 players in red or blue, force one person to other team and try again
		{
			for (int iClient = 1; iClient <= MaxClients; iClient++)
			{
				if (IsClientInGame(iClient))
				{
					//Once we found someone whos in red or blue, swap his team
					if (GetClientTeam(iClient) == TFTeam_Red)
					{
						TF2_ForceTeamJoin(iClient, TFTeam_Blue);
						return;
					}
					else if (GetClientTeam(iClient) == TFTeam_Blue)
					{
						TF2_ForceTeamJoin(iClient, TFTeam_Red);
						return;
					}
				}
			}
		}
		//If we reach that part, either nobody is in server or people in spectator
		return;
	}

	g_hTimerBossMusic = null;
	g_bRoundStarted = false;

	// New round started
	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		//Clean up any boss(es) that is/are still active
		SaxtonHaleBase boss = SaxtonHaleBase(iClient);
		if (boss.bValid)
			boss.CallFunction("Destroy");

		Client_RemoveFlag(iClient, haleClientFlags_BossTeam);

		g_iPlayerDamage[iClient] = 0;
		g_iPlayerAssistDamage[iClient] = 0;
		g_iClientOwner[iClient] = 0;

		int iColor[4];
		iColor[0] = 255; iColor[1] = 255; iColor[2] = 255; iColor[3] = 255;
		Hud_SetColor(iClient, iColor);

		if (!IsClientInGame(iClient)) continue;
		if (GetClientTeam(iClient) <= 1) continue;

		// Put every players in same team & pick the boss later
		TF2_ForceTeamJoin(iClient, ATTACK_TEAM);
	}

	PickNextBoss();	//Set boss

	g_iTotalAttackCount = SaxtonHale_GetAliveAttackPlayers();	//Update amount of attack players

	Winstreak_RoundStart();

	RequestFrame(Frame_InitVshPreRoundTimer, tf_arena_preround_time.IntValue);
}

public Action Event_RoundSelected(Event event, const char[] sName, bool bDontBroadcast)
{
	if (!g_bEnabled || GameRules_GetProp("m_bInWaitingForPlayers")) return;

	//Play one round of arena
	if (g_iTotalRoundPlayed <= 0) return;

	Dome_RoundSelected(event);
}

public Action Event_RoundArenaStart(Event event, const char[] sName, bool bDontBroadcast)
{
	if (!g_bEnabled || GameRules_GetProp("m_bInWaitingForPlayers")) return;

	//Play one round of arena
	if (g_iTotalRoundPlayed <= 0)
	{
		Dome_Start();
		return;
	}

	g_bRoundStarted = true;
	g_iTotalAttackCount = SaxtonHale_GetAliveAttackPlayers();

	//New round started
	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if (!IsClientInGame(iClient)) continue;

		g_iPlayerDamage[iClient] = 0;
		g_iPlayerAssistDamage[iClient] = 0;
		ClassLimit_SetMainClass(iClient, TFClass_Unknown);
		
		if (!SaxtonHale_IsValidAttack(iClient)) continue;

		//Display weapon balances in chat
		TFClassType nClass = TF2_GetPlayerClass(iClient);

		ClassLimit_SetMainClass(iClient, nClass);

		for (int iSlot = 0; iSlot <= WeaponSlot_InvisWatch; iSlot++)
		{
			int iWeapon = TF2_GetItemInSlot(iClient, iSlot);
			
			if (IsValidEdict(iWeapon))
			{
				int iIndex = GetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex");
				for (int i = 0; i <= 1; i++)
				{					
					char sDesp[255];
					
					// Desp for all weapon in class slot
					if (i == 0)
						g_ConfigClass[nClass][iSlot].GetDesp(sDesp, sizeof(sDesp));
					// Desp for specific index
					else if (i == 1)
						g_ConfigIndex.GetDesp(iIndex, sDesp, sizeof(sDesp));

					if (!StrEmpty(sDesp))
					{
						//Color tags
						for (int iColor = 0; iColor < sizeof(g_strColorTag); iColor++)
							ReplaceString(sDesp, sizeof(sDesp), g_strColorTag[iColor], g_strColorCode[iColor]);
	
						//Bug with single % not showing, use %% to have % appeared once
						ReplaceString(sDesp, sizeof(sDesp), "%", "%%");
	
						//Add VSH color at start
						Format(sDesp, sizeof(sDesp), "%s%s", VSH_TEXT_COLOR, sDesp);
						PrintToChat(iClient, sDesp);
					}
				}
			}
		}
	}
	
	//Play boss music if there is one
	for (int iBoss = 1; iBoss <= MaxClients; iBoss++)
	{
		if (SaxtonHale_IsValidBoss(iBoss, false))
		{
			SaxtonHaleBase boss = SaxtonHaleBase(iBoss);
			
			//Check if there still enough players while winstreak is on, otherwise quick snipe disable it
			if (g_iTotalAttackCount < Winstreak_GetPlayerRequirement(iBoss))
				Winstreak_SetEnable(false);
			
			float flMusicTime;
			boss.CallFunction("GetMusicInfo", g_sBossMusic, sizeof(g_sBossMusic), flMusicTime);
			if (!StrEmpty(g_sBossMusic))
			{
				for (int i = 1; i <= MaxClients; i++)
					if (IsClientInGame(i) && Preferences_Get(i, halePreferences_Music))
						EmitSoundToClient(i, g_sBossMusic);
				
				if (flMusicTime > 0.0)
					g_hTimerBossMusic = CreateTimer(flMusicTime, Timer_Music, boss, TIMER_REPEAT);
				
				break;
			}
		}
	}

	//Refresh boss health from winstreak disable & player count
	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		SaxtonHaleBase boss = SaxtonHaleBase(iClient);
		if (boss.bValid)
		{
			int iHealth = boss.CallFunction("CalculateMaxHealth");
			boss.iMaxHealth = iHealth;
			boss.iHealth = iHealth;
		}
	}
	
	char sMessage[2048], sBuffer[256], sPreviousModifiers[256];
	int iColor[4] = {255, 255, 255, 255};
	bool bAllowModifiersColor = true;
	
	//Loop through each bosses to display
	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		SaxtonHaleBase boss = SaxtonHaleBase(iClient);
		if (!IsClientInGame(iClient) || !boss.bValid || boss.bMinion) continue;
		
		if (!StrEmpty(sMessage)) StrCat(sMessage, sizeof(sMessage), "\n");
		
		//Get client name
		Format(sMessage, sizeof(sMessage), "%s%N became", sMessage, iClient);
		
		//Display text who is what boss and modifiers with health
		if (boss.bModifiers)
		{
			boss.CallFunction("GetModifiersName", sBuffer, sizeof(sBuffer));
			Format(sMessage, sizeof(sMessage), "%s %s", sMessage, sBuffer);
			
			if (!StrEmpty(sPreviousModifiers) && !StrEqual(sPreviousModifiers, sBuffer))
			{
				//More than 1 different modifiers, dont allow colors
				bAllowModifiersColor = false;
			}
			else
			{
				boss.CallFunction("GetRenderColor", iColor);
			}
			
			Format(sPreviousModifiers, sizeof(sPreviousModifiers), sBuffer);
		}
		
		//Get Boss name and health
		boss.CallFunction("GetBossName", sBuffer, sizeof(sBuffer));
		Format(sMessage, sizeof(sMessage), "%s %s with %d health!", sMessage, sBuffer, boss.iMaxHealth);
	
		//Get Winstreak
		if (Winstreak_IsEnabled() && Winstreak_GetCurrent(iClient) > 0)
			Format(sMessage, sizeof(sMessage), "%s\n%d Winstreak (-%.0f%%%% health)", sMessage, Winstreak_GetCurrent(iClient), Winstreak_GetPrecentageLoss(iClient) * 100.0);
	}
	
	if (!bAllowModifiersColor)
		for (int iRGB = 0; iRGB < sizeof(iColor); iRGB++)
			iColor[iRGB] = 255;
	
	float flHUD[2];
	flHUD[0] = -1.0;
	flHUD[1] = 0.3;
	
	float flFade[2];
	flFade[0] = 0.4;
	flFade[1] = 0.4;

	for (int i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i))
			Hud_Display(i, CHANNEL_INTRO, sMessage, flHUD, 5.0, iColor, 0, 0.0, flFade);

	Dome_RoundArenaStart();

	//Display chat on who is next boss
	int iNextPlayer = Queue_GetPlayerFromRank(1);
	if (0 < iNextPlayer <= MaxClients && IsClientInGame(iNextPlayer))
	{
		char sFormat[512];
		Format(sFormat, sizeof(sFormat), "%s================\nYou are about to be the next boss!\n", VSH_TEXT_COLOR);

		if (g_bPlayerTriggerSpecialRound[iNextPlayer])
			Format(sFormat, sizeof(sFormat), "%sYour round will be a special round", sFormat);
		else if (!Preferences_Get(iNextPlayer, halePreferences_Winstreak))
			Format(sFormat, sizeof(sFormat), "%sYour winstreak preference is currently disabled", sFormat);
		else if (Winstreak_IsAllowed(iNextPlayer))
			Format(sFormat, sizeof(sFormat), "%sYou currently have %d winstreak", sFormat, Winstreak_GetCurrent(iNextPlayer));
		else
			Format(sFormat, sizeof(sFormat), "%sYou need %d enemy players to have your %d winstreak counted", sFormat, Winstreak_GetPlayerRequirement(iNextPlayer), Winstreak_GetCurrent(iNextPlayer));
		
		Format(sFormat, sizeof(sFormat), "%s\n================", sFormat);
		PrintToChat(iNextPlayer, sFormat);
	}

	GameRules_SetPropFloat("m_flCapturePointEnableTime", 31536000.0+GetGameTime());
}

public Action Event_RoundEnd(Event event, const char[] sName, bool bDontBroadcast)
{
	if (!g_bEnabled) return;

	g_hTimerBossMusic = null;
	g_bRoundStarted = false;

	int iWinningTeam = event.GetInt("team");

	g_iTotalRoundPlayed++;
	if (g_iTotalRoundPlayed <= 1)
	{
		if (g_iTotalRoundPlayed == 1)//Arena round ended disable arena logic!
			Plugin_Cvars(true);
		return;
	}

	int iMainBoss = GetMainBoss();
	
	if (iWinningTeam == BOSS_TEAM)
	{
		if (0 < iMainBoss <= MaxClients && IsClientInGame(iMainBoss))//Play our win line
		{
			SaxtonHaleBase boss = SaxtonHaleBase(iMainBoss);
			if (boss.bValid)
			{
				char sSound[255];
				boss.CallFunction("GetSound", sSound, sizeof(sSound), VSHSound_Win);
				if (!StrEmpty(sSound))
					BroadcastSoundToTeam(TFTeam_Spectator, sSound);

				Forward_BossWin(BOSS_TEAM);

				if (Winstreak_IsEnabled())
					Winstreak_SetCurrent(iMainBoss, Winstreak_GetCurrent(iMainBoss) + 1, true);
			}
		}
	}
	else
	{
		if (0 < iMainBoss <= MaxClients && IsClientInGame(iMainBoss))//Play our lose line
		{
			SaxtonHaleBase boss = SaxtonHaleBase(iMainBoss);
			if (boss.bValid)
			{
				char sSound[255];
				boss.CallFunction("GetSound", sSound, sizeof(sSound), VSHSound_Lose);
				if (!StrEmpty(sSound))
					BroadcastSoundToTeam(TFTeam_Spectator, sSound);

				Forward_BossLose(BOSS_TEAM);

				if (Winstreak_IsEnabled())
					Winstreak_SetCurrent(iMainBoss, 0, true);
			}
		}
	}

	Winstreak_SetEnable(false);

	ArrayList aPlayersList = new ArrayList();
	
	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if (IsClientInGame(iClient))
		{
			//End music
			if (!StrEmpty(g_sBossMusic))
				StopSound(iClient, SNDCHAN_AUTO, g_sBossMusic);
			
			if (GetClientTeam(iClient) > 1 && (!SaxtonHale_IsValidBoss(iClient, false)))
			{				
				aPlayersList.Push(iClient);
				
				if (!Client_HasFlag(iClient, haleClientFlags_Punishment))
				{
					int iAddQueue = 10 + RoundToFloor(float(SaxtonHale_GetScore(iClient)) / 300.0);
					if (iAddQueue > 20)
						iAddQueue = 20;
					Queue_AddPlayerPoints(iClient, iAddQueue);
				}
			}
		}
	}
	
	g_sBossMusic = "";

	char sPlayerNames[3][70];
	sPlayerNames[0] = "----";
	sPlayerNames[1] = "----";
	sPlayerNames[2] = "----";

	for (int iRank = 0; iRank < 3; iRank++)
	{
		int iBestPlayerIndex = -1;
		int iLength = aPlayersList.Length;
		int iBestScore = 0;

		for (int i = 0; i < iLength; i++)
		{
			int iPlayer = aPlayersList.Get(i);
			int iPlayerScore = SaxtonHale_GetScore(iPlayer);
			if (iPlayerScore > iBestScore)
			{
				iBestScore = iPlayerScore;
				iBestPlayerIndex = i;
			}
		}

		if (iBestPlayerIndex != -1)
		{
			char sBufferName[59];
			int iPlayer = aPlayersList.Get(iBestPlayerIndex);

			GetClientName(iPlayer, sBufferName, sizeof(sBufferName));
			Format(sPlayerNames[iRank], sizeof(sPlayerNames[]), "%s - %i", sBufferName, SaxtonHale_GetScore(iPlayer));
			aPlayersList.Erase(iBestPlayerIndex);
		}
	}

	delete aPlayersList;

	float flHUD[2];
	flHUD[0] = -1.0;
	flHUD[1] = 0.3;

	char sMessage[2048], sBuffer[256];
	
	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		SaxtonHaleBase boss = SaxtonHaleBase(iClient);
		if (boss.bValid && !boss.bMinion)
		{
			if (!StrEmpty(sMessage)) StrCat(sMessage, sizeof(sMessage), "\n");
			Format(sMessage, sizeof(sMessage), "%s%N as", sMessage, iClient);
			
			//Get Modifiers name
			if (boss.bModifiers)
			{
				boss.CallFunction("GetModifiersName", sBuffer, sizeof(sBuffer));
				Format(sMessage, sizeof(sMessage), "%s %s", sMessage, sBuffer);
			}
			
			//Get Boss name
			boss.CallFunction("GetBossName", sBuffer, sizeof(sBuffer));
			
			//Format with health
			if (IsPlayerAlive(iClient))
				Format(sMessage, sizeof(sMessage), "%s %s had %d of %d health left", sMessage, sBuffer, boss.iHealth, boss.iMaxHealth);
			else
				Format(sMessage, sizeof(sMessage), "%s %s died with %d max health", sMessage, sBuffer, boss.iMaxHealth);
		}
	}

	Format(sMessage, sizeof(sMessage), "%s\n1) %s \n2) %s \n3) %s ", sMessage, sPlayerNames[0], sPlayerNames[1], sPlayerNames[2]);

	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if (IsClientInGame(iClient))
		{
			Format(sBuffer, sizeof(sBuffer), sMessage);

			if (!SaxtonHale_IsValidBoss(iClient, false))
				Format(sBuffer, sizeof(sBuffer), "%s\nYour damage: %d | Your assist: %d", sBuffer, g_iPlayerDamage[iClient], g_iPlayerAssistDamage[iClient]);

			Hud_Display(iClient, CHANNEL_INTRO, sBuffer, flHUD, 10.0);
		}
	}	
}

public void Event_BroadcastAudio(Event event, const char[] sName, bool bDontBroadcast)
{
	if (!g_bEnabled) return;
	if (g_iTotalRoundPlayed <= 0) return;

	char strSound[50];
	event.GetString("sound", strSound, sizeof(strSound));

	if (strcmp(strSound, "Game.TeamWin3") == 0
	|| strcmp(strSound, "Game.YourTeamLost") == 0
	|| strcmp(strSound, "Game.YourTeamWon") == 0
	|| strcmp(strSound, "Announcer.AM_RoundStartRandom") == 0
	|| strcmp(strSound, "Game.Stalemate") == 0)
		SetEventBroadcast(event, true);
}

public Action Event_PlayerSpawn(Event event, const char[] sName, bool bDontBroadcast)
{
	if (!g_bEnabled) return;
	if (g_iTotalRoundPlayed <= 0) return;

	int iClient = GetClientOfUserId(event.GetInt("userid"));
	int iTeam = GetClientTeam(iClient);
	if (iTeam <= 1) return;
	
	if (g_bRoundStarted && SaxtonHale_IsValidAttack(iClient))
	{
		//Latespawn... get outa here
		ForcePlayerSuicide(iClient);
		return;
	}
	
	TFClassType iOldClass = view_as<TFClassType>(event.GetInt("class"));
	TFClassType iNewClass = ClassLimit_GetNewClass(iClient);
	
	if (iOldClass != iNewClass && iNewClass != TFClass_Unknown)
	{
		TF2_SetPlayerClass(iClient, iNewClass);
		Frame_RespawnPlayer(GetClientUserId(iClient));
		return;
	}

	// Player spawned, if they are a boss, call their spawn function
	SaxtonHaleBase boss = SaxtonHaleBase(iClient);
	if (boss.bValid)
		boss.CallFunction("OnSpawn");
}

void Frame_VerifyTeam(int userid)
{
	int iClient = GetClientOfUserId(userid);
	if (iClient <= 0 || !IsClientInGame(iClient)) return;

	int iTeam = GetClientTeam(iClient);
	if (iTeam <= 1) return;

	if (Client_HasFlag(iClient, haleClientFlags_BossTeam))
	{
		if (iTeam == ATTACK_TEAM)	//Check if player is in attack team, if so put it back to boss team
		{
			ChangeClientTeam(iClient, BOSS_TEAM);
			TF2_RespawnPlayer(iClient);
		}
	}
	else
	{
		if (iTeam == BOSS_TEAM)		//Check if attack players is in boss team, if so put it back to attack team
		{
			ChangeClientTeam(iClient, ATTACK_TEAM);
			TF2_RespawnPlayer(iClient);
		}
	}
}

void Frame_RespawnPlayer(int userid)
{
	int iClient = GetClientOfUserId(userid);
	if (iClient <= 0 || !IsClientInGame(iClient) || GetClientTeam(iClient) <= 1) return;
	
	TF2_RespawnPlayer(iClient);
}

public Action Event_BuiltObject(Event event, const char[] sName, bool bDontBroadcast)
{	
	if (!g_bEnabled) return Plugin_Continue;
	if (g_iTotalRoundPlayed <= 0) return Plugin_Continue;

	int iClient = GetClientOfUserId(event.GetInt("userid"));

	SaxtonHaleBase boss = SaxtonHaleBase(iClient);
	if (boss.bValid)
		return boss.CallFunction("OnBuildObject", event);
	
	return Plugin_Continue;
}

public Action Event_DestroyObject(Event event, const char[] sName, bool bDontBroadcast)
{
	if (!g_bEnabled) return Plugin_Continue;
	if (g_iTotalRoundPlayed <= 0) return Plugin_Continue;

	int iClient = GetClientOfUserId(event.GetInt("attacker"));

	SaxtonHaleBase boss = SaxtonHaleBase(iClient);
	if (boss.bValid)
	{
		char sSound[255];
		boss.CallFunction("GetSound", sSound, sizeof(sSound), VSHSound_KillBuilding);
		if (!StrEmpty(sSound))
			EmitSoundToAll(sSound, iClient, SNDCHAN_VOICE, SNDLEVEL_SCREAMING);
		
		return boss.CallFunction("OnDestroyObject", event);
	}
	
	return Plugin_Continue;
}

public Action Event_SappedObject(Event event, const char[] sName, bool bDontBroadcast)
{
	if (!g_bEnabled) return Plugin_Continue;
	if (g_iTotalRoundPlayed <= 0) return Plugin_Continue;

	int iVictim = GetClientOfUserId(event.GetInt("ownerid"));

	SaxtonHaleBase boss = SaxtonHaleBase(iVictim);
	if (boss.bValid)
		return boss.CallFunction("OnObjectSapped", event);
	
	return Plugin_Continue;
}

public Action Event_PlayerDeath(Event event, const char[] sName, bool bDontBroadcast)
{
	if (!g_bEnabled) return Plugin_Continue;
	if (g_iTotalRoundPlayed <= 0) return Plugin_Continue;
	if (!g_bRoundStarted) return Plugin_Continue;

	int iVictim = GetClientOfUserId(event.GetInt("userid"));
	int iAttacker = GetClientOfUserId(event.GetInt("attacker"));

	int iVictimTeam = GetClientTeam(iVictim);
	if (iVictimTeam <= 1) return Plugin_Continue;

	SaxtonHaleBase bossVictim = SaxtonHaleBase(iVictim);
	SaxtonHaleBase bossAttacker = SaxtonHaleBase(iAttacker);

	bool bDeadRinger = (event.GetInt("death_flags") & TF_DEATHFLAG_DEADRINGER) != 0;

	int iSentry = MaxClients+1;
	while((iSentry = FindEntityByClassname(iSentry, "obj_sentrygun")) > MaxClients)
	{
		if (GetEntPropEnt(iSentry, Prop_Send, "m_hBuilder") == iVictim)
		{
			SetVariantInt(999999);
			AcceptEntityInput(iSentry, "RemoveHealth");
		}
	}
	
	if (bossVictim.bValid)
	{
		//Call boss death
		bossVictim.CallFunction("OnDeath", event);
		CheckForceAttackWin(iVictim);
	}
	
	if (0 < iAttacker <= MaxClients && iVictim != iAttacker && IsClientInGame(iAttacker))
	{	
		//Call boss kill
		if (bossAttacker.bValid)
			bossAttacker.CallFunction("OnPlayerKilled", event, iVictim);
	}
	
	if (SaxtonHale_IsValidAttack(iVictim) && !bDeadRinger)
	{
		//Victim who died is still "alive" during this event, so we subtract by 1 to not count victim
		int iLastAlive = SaxtonHale_GetAliveAttackPlayers() - 1;

		Dome_PlayerDeath(iLastAlive);
		
		if (iLastAlive >= 2)
		{
			//Play boss kill voiceline
			if ((GetRandomInt(0, 1)) && 0 < iAttacker <= MaxClients && bossAttacker.bValid)
			{
				char sSound[255];
				bossAttacker.CallFunction("GetSoundKill", sSound, sizeof(sSound), TF2_GetPlayerClass(iVictim));
				if (!StrEmpty(sSound))
					EmitSoundToAll(sSound, iAttacker, SNDCHAN_VOICE, SNDLEVEL_SCREAMING);
			}
		}
		
		if (iLastAlive == 1)
		{
			//Play last man voiceline
			int iBoss = 0;
			if (0 < iAttacker <= MaxClients && IsClientInGame(iAttacker))
			{
				iBoss = iAttacker;
			}
			else
			{
				for (int iClient = 1; iClient <= MaxClients; iClient++)
				{
					if (SaxtonHale_IsValidBoss(iClient, false) && IsPlayerAlive(iClient))
					{
						iBoss = iClient;
						break;
					}
				}
			}
			
			SaxtonHaleBase boss = SaxtonHaleBase(iBoss);
			if (iBoss != 0 && boss.bValid)
			{
				char sSound[255];
				boss.CallFunction("GetSound", sSound, sizeof(sSound), VSHSound_Lastman);
				if (!StrEmpty(sSound))
					BroadcastSoundToTeam(TFTeam_Spectator, sSound);
			}
		}

		if (iLastAlive == 0)
		{
			//Kill any minions that are still alive
			for (int i = 1; i <= MaxClients; i++)
				if (IsClientInGame(i) && IsPlayerAlive(i) && i != iVictim && GetClientTeam(i) == iVictimTeam)
					SDKHooks_TakeDamage(i, 0, i, 99999.0);
		}
	}
	
	//Reset flags
	if (!bDeadRinger)
	{
		g_iClientOwner[iVictim] = 0;
		Client_RemoveFlag(iVictim, haleClientFlags_BossTeam);
	}

	return Plugin_Changed;
}

public Action Event_PlayerInventoryUpdate(Event event, const char[] sName, bool bDontBroadcast)
{
	if (!g_bEnabled) return;

	int iClient = GetClientOfUserId(event.GetInt("userid"));
	if (GetClientTeam(iClient) <= 1) return;

	if (!SaxtonHale_IsValidBoss(iClient))
	{
		/*Balance or restrict specific weapons*/
		TFClassType nClass = TF2_GetPlayerClass(iClient);
		for (int iSlot = 0; iSlot <= WeaponSlot_InvisWatch; iSlot++)
		{
			int iWeapon = TF2_GetItemInSlot(iClient, iSlot);

			if (IsValidEdict(iWeapon))
			{
				int iIndex = GetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex");
				
				// Restrict weapons, including 1st eound
				if (g_ConfigIndex.IsRestricted(iIndex))
				{
					TF2_RemoveItemInSlot(iClient, iSlot);
					
					//Get default weapon index for class and slot
					iIndex = g_iDefaultWeaponIndex[view_as<int>(nClass)][iSlot];
					if (iIndex < 0)
					{
						char sError[256];
						Format(sError, sizeof(sError), "[VSH] UNABLE TO GET DEFAULT WEAPON INDEX FOR CLASS %d SLOT %d!!!!", nClass, iSlot);
						PluginStop(true, sError);
						return;
					}
					
					iWeapon = TF2_CreateAndEquipWeapon(iClient, iIndex, .bAttrib = true);
				}

				if (g_iTotalRoundPlayed <= 0)
					continue;

				// Balance weapons, not including 1st round
				if (SaxtonHale_IsValidAttack(iClient))
				{
					for (int i = 0; i <= 1; i++)
					{
						char sAttrib[255], atts[32][32];
						
						// Give attribs in class slot and specific index
						switch (i)
						{
							case 0: g_ConfigClass[nClass][iSlot].GetAttrib(sAttrib, sizeof(sAttrib));
							case 1: g_ConfigIndex.GetAttrib(iIndex, sAttrib, sizeof(sAttrib));
						}
						
						int count = ExplodeString(sAttrib, " ; ", atts, 32, 32);
						if (count > 1)
						{
							for (int j = 0; j < count; j+= 2)
								TF2Attrib_SetByDefIndex(iWeapon, StringToInt(atts[j]), StringToFloat(atts[j+1]));

							TF2Attrib_ClearCache(iWeapon);
						}
						
						// Set clip size to weapon in both class slot and specific index
						int iClip = -1;
						switch (i)
						{
							case 0: iClip = g_ConfigClass[nClass][iSlot].GetClip();
							case 1: iClip = g_ConfigIndex.GetClip(iIndex);
						}
						
						if (iClip > -1)
							SetEntProp(iWeapon, Prop_Send, "m_iClip1", iClip);
					}
				}
			}
		}
	}

	if (g_iTotalRoundPlayed <= 0) return;
	
	Tags_ResetClient(iClient);
	TagsCore_RefreshClient(iClient);
	
	if (SaxtonHale_IsValidAttack(iClient))
		TagsCore_CallAll(iClient, TagsCall_Spawn);
	
	RequestFrame(Frame_VerifyTeam, GetClientUserId(iClient));
}

public Action Event_PlayerHurt(Event event, const char[] sName, bool bDontBroadcast)
{
	if (!g_bEnabled) return;
	if (g_iTotalRoundPlayed <= 0) return;

	int iClient = GetClientOfUserId(event.GetInt("userid"));
	if (GetClientTeam(iClient) <= 1) return;
	
	SaxtonHaleBase boss = SaxtonHaleBase(iClient);
	if (boss.bValid)
	{
		int iAttacker = GetClientOfUserId(event.GetInt("attacker"));
		int iDamageAmount = event.GetInt("damageamount");
		Tags_OnPlayerHurt(iClient, iAttacker, iDamageAmount);
		
		if (0 < iAttacker <= MaxClients && IsClientInGame(iAttacker) && iClient != iAttacker)
		{
			boss.CallFunction("AddRage", iDamageAmount);
			
			if (boss.bMinion) return;
			
			g_iPlayerDamage[iAttacker] += iDamageAmount;
			int iAttackTeam = GetClientTeam(iAttacker);

			//Award assist damage if Client has a owner
			int iOwner = g_iClientOwner[iAttacker];
			if (0 < iOwner <= MaxClients && IsClientInGame(iOwner))
				g_iPlayerAssistDamage[iOwner] += iDamageAmount;

			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && GetClientTeam(i) == iAttackTeam && i != iAttacker)
				{
					int iSecondaryWep = GetPlayerWeaponSlot(i, WeaponSlot_Secondary);
					char weaponSecondaryClass[32];
					if (iSecondaryWep >= 0) GetEdictClassname(iSecondaryWep, weaponSecondaryClass, sizeof(weaponSecondaryClass));

					//Award damage assit to healers
					if (strcmp(weaponSecondaryClass, "tf_weapon_medigun") == 0)
					{
						int iHealTarget = GetEntPropEnt(iSecondaryWep, Prop_Send, "m_hHealingTarget");
						if (iHealTarget == iAttacker)
						{
							g_iPlayerAssistDamage[i] += iDamageAmount;
						}
						else if (iHealTarget > MaxClients)	//Buildings
						{
							char sClassname[64];
							GetEdictClassname(iHealTarget, sClassname, sizeof(sClassname));
							//Check if healer is healing sentry gun, with attacker as builder
							if (strcmp(sClassname, "obj_sentrygun") == 0 && GetEntPropEnt(iHealTarget, Prop_Send, "m_hBuilder") == iAttacker)
							{
								g_iPlayerAssistDamage[i] += iDamageAmount;
							}
						}
					}
				}
			}
		}
	}
}

public Action Event_BuffBannerDeployed(Event event, const char[] sName, bool bDontBroadcast)
{
	if (!g_bEnabled) return;
	if (g_iTotalRoundPlayed <= 0) return;

	int iClient = GetClientOfUserId(event.GetInt("buff_owner"));
	if (GetClientTeam(iClient) <= 1 || SaxtonHale_IsValidBoss(iClient)) return;

	TagsCore_CallAll(iClient, TagsCall_Banner);
}

public Action Event_UberDeployed(Event event, const char[] sName, bool bDontBroadcast)
{
	if (!g_bEnabled) return;
	if (g_iTotalRoundPlayed <= 0) return;

	int iClient = GetClientOfUserId(GetEventInt(event, "userid"));
	if (GetClientTeam(iClient) <= 1 || SaxtonHale_IsValidBoss(iClient)) return;

	TagsCore_CallAll(iClient, TagsCall_Uber);
}

public Action Event_Jarated(UserMsg msg_id, Handle msg, const int[] players, int playersNum, bool reliable, bool init)
{
	if (!g_bEnabled) return;
	if (g_iTotalRoundPlayed <= 0) return;

	int iThrower = BfReadByte(msg);
	int iVictim = BfReadByte(msg);
	
	if (GetClientTeam(iThrower) <= 1 || SaxtonHale_IsValidBoss(iThrower)) return;
	
	SaxtonHaleBase bossVictim = SaxtonHaleBase(iVictim);
	if (GetClientTeam(iVictim) <= 1 || !bossVictim.bValid) return;
	
	TagsParams tParams = new TagsParams();
	tParams.SetInt("victim", iVictim);
	
	//Possible crash if called in same frame
	DataPack data = new DataPack();
	data.WriteCell(GetClientUserId(iThrower));
	data.WriteCell(tParams);
	RequestFrame(Frame_CallJarate, data);
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
	
	int iTaunt = GetEntProp(iClient, Prop_Send, "m_iTauntItemDefIndex");
	if (iTaunt == ITEM_ROCK_PAPER_SCISSORS)		//Disable this taunt due to possible stall in last man and easy 999 damage from that taunt
	{
		TF2_RemoveCondition(iClient, TFCond_Taunting);
		PrintToChat(iClient, "%s%s Rock, Paper, Scissors taunt is disabled in this gamemode", VSH_TAG, VSH_ERROR_COLOR);
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
			
			if (Preferences_Get(iClient, halePreferences_Music))
				EmitSoundToClient(iClient, g_sBossMusic);
		}
	}

	return Plugin_Continue;
}

public Action Timer_WelcomeMessage(Handle hTimer)
{
	if (!g_bEnabled)
		return Plugin_Stop;
	
	PrintToChatAll("%s%s Welcome to Versus Saxton Hale: Rewrite! \nType %s/vsh%s for more info about it.", VSH_TAG, VSH_TEXT_COLOR, VSH_TEXT_DARK, VSH_TEXT_COLOR);
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

	g_flPlayerSpeedMultiplier[iClient] = 1.0;
	g_iPlayerDamage[iClient] = 0;
	g_iPlayerAssistDamage[iClient] = 0;
	g_iClientFlags[iClient] = 0;
	g_bPlayerTriggerSpecialRound[iClient] = false;
	g_iClientOwner[iClient] = 0;

	ClassLimit_SetMainClass(iClient, TFClass_Unknown);
	ClassLimit_SetDesiredClass(iClient, TFClass_Unknown);
	
	//-1 as unknown
	Preferences_SetAll(iClient, -1);
	Queue_SetPlayerPoints(iClient, -1);
	Winstreak_SetCurrent(iClient, -1);
}

public void OnClientPutInServer(int iClient)
{
	DHookEntity(g_hHookGetMaxHealth, false, iClient);
	SDKHook(iClient, SDKHook_PreThink, Client_OnThink);
	SDKHook(iClient, SDKHook_OnTakeDamage, Client_OnTakeDamage);
	
	Cookies_OnClientJoin(iClient);
}

public void OnClientPostAdminCheck(int iClient)
{
	AdminId iAdmin = GetUserAdmin(iClient);
	if (iAdmin.HasFlag(Admin_RCON) || iAdmin.HasFlag(Admin_Root))
		Client_AddFlag(iClient, haleClientFlags_Admin);
}

public void OnClientDisconnect(int iClient)
{
	SaxtonHaleBase boss = SaxtonHaleBase(iClient);
	
	if (boss.bValid && !boss.bMinion && SaxtonHale_IsWinstreakEnable())
	{
		//Ur not going anywhere kiddo
		Winstreak_SetCurrent(iClient, 0, true);
	}
	
	if (boss.bValid)
	{
		boss.CallFunction("Destroy");
		CheckForceAttackWin(iClient);
	}

	g_iClientFlags[iClient] = 0;

	ClassLimit_SetMainClass(iClient, TFClass_Unknown);
	ClassLimit_SetDesiredClass(iClient, TFClass_Unknown);
	
	Preferences_SetAll(iClient, -1);
	Queue_SetPlayerPoints(iClient, -1);
	Winstreak_SetCurrent(iClient, -1);
}

public void OnClientDisconnect_Post(int iClient)
{
	TagsCore_RefreshClient(iClient);	//Free the memory
}

public void Client_OnThink(int iClient)
{
	if (!g_bEnabled) return;
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
			iSlot = TF2_GetSlotInItem(iIndex, nClass);
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

public Action Client_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
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
				//Dont do anything if boss is ubered
				if (bossVictim.bValid && !bossVictim.bMinion && !TF2_IsUbercharged(victim))
				{
					if (damagecustom == TF_CUSTOM_TELEFRAG)
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
					
					if (inflictor > MaxClients)
					{
						char strInflictor[32];
						GetEdictClassname(inflictor, strInflictor, sizeof(strInflictor));
						if(strcmp(strInflictor, "tf_projectile_sentryrocket") == 0 || strcmp(strInflictor, "obj_sentrygun") == 0)
						{
							damagetype |= DMG_PREVENT_PHYSICS_FORCE;
							finalAction = Plugin_Changed;
						}
					}
				}
			}
		}
	}
	return finalAction;
}

public Action Client_VoiceCommand(int iClient, const char[] sCommand, int iArgs)
{
	if (!g_bEnabled) return Plugin_Continue;
	if (g_iTotalRoundPlayed <= 0) return Plugin_Continue;
	if (iArgs < 2) return Plugin_Handled;

	char sCmd1[8], sCmd2[8];

	GetCmdArg(1, sCmd1, sizeof(sCmd1));
	GetCmdArg(2, sCmd2, sizeof(sCmd2));

	Action action = Plugin_Continue;
	SaxtonHaleBase boss = SaxtonHaleBase(iClient);
	if (boss.bValid && IsPlayerAlive(iClient))
	{
		action = boss.CallFunction("OnVoiceCommand", sCmd1, sCmd2);
		
		if (sCmd1[0] == '0' && sCmd2[0] == '0' && boss.iMaxRageDamage != -1 && (boss.iRageDamage >= boss.iMaxRageDamage))
		{
			boss.CallFunction("OnRage");
			action = Plugin_Handled;
		}
	}
	
	return action;
}

public Action Client_KillCommand(int iClient, const char[] sCommand, int iArgs)
{
	if (!g_bEnabled) return Plugin_Continue;
	if (g_iTotalRoundPlayed <= 0) return Plugin_Continue;

	if (g_bRoundStarted && SaxtonHale_IsValidBoss(iClient, false))
	{
		PrintToChat(iClient, "%s%s Do not suicide and waste round as Boss. Use !vshbosstoggle instead.", VSH_TAG, VSH_ERROR_COLOR);
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

public Action Client_JoinTeamCommand(int iClient, const char[] sCommand, int iArgs)
{
	if (!g_bEnabled) return Plugin_Continue;
	if (g_iTotalRoundPlayed <= 0) return Plugin_Continue;

	char sTeam[64];
	if (strcmp(sCommand, "spectate") == 0)
		Format(sTeam, sizeof(sTeam), sCommand);
	
	if (strcmp(sCommand, "jointeam") == 0 && iArgs > 0)
		GetCmdArg(1, sTeam, sizeof(sTeam));
	
	if (strcmp(sTeam, "spectate") == 0)
	{
		if (SaxtonHale_IsValidBoss(iClient, false))
		{
			if (g_bRoundStarted || GameRules_GetRoundState() == RoundState_Preround)
			{
				PrintToChat(iClient, "%s%s Do not suicide and waste round as Boss. Use !vshbosstoggle instead.", VSH_TAG, VSH_ERROR_COLOR);
				return Plugin_Handled;
			}
		}
		
		return Plugin_Continue;
	}
	
	//Check if we have active boss, otherwise we assume a VSH round is not on
	bool bBoss = false;
	for (int iBoss = 1; iBoss <= MaxClients; iBoss++)
	{
		if (SaxtonHale_IsValidBoss(iClient))
		{
			bBoss = true;
			break;
		}
	}
	
	if (!bBoss) return Plugin_Continue;

	if (Client_HasFlag(iClient, haleClientFlags_BossTeam))
		ChangeClientTeam(iClient, BOSS_TEAM);
	else
		ChangeClientTeam(iClient, ATTACK_TEAM);

	int iTeam = GetClientTeam(iClient);
	ShowVGUIPanel(iClient, iTeam == TFTeam_Blue ? "class_blue" : "class_red");

	return Plugin_Handled;
}

public Action Client_JoinClass(int iClient, const char[] sCommand, int iArgs)
{
	if (!g_bEnabled) return Plugin_Continue;
	if (iArgs < 1) return Plugin_Continue;
	
	char sClass[64];
	GetCmdArg(1, sClass, sizeof(sClass));
	TFClassType nClass = TF2_GetClassType(sClass);
	
	if (nClass == TFClass_Unknown)
		return Plugin_Continue;
	
	//Since player want to play as that class, set desired class
	ClassLimit_SetDesiredClass(iClient, nClass);
	
	if (g_iTotalRoundPlayed <= 0)
		return Plugin_Continue;
	
	//Check whenever if allow change to that class
	return ClassLimit_JoinClass(iClient, nClass);
}

public Action Client_BuildCommand(int iClient, const char[] sCommand, int iArgs)
{
	if (!g_bEnabled) return Plugin_Continue;
	if (g_iTotalRoundPlayed <= 0) return Plugin_Continue;

	SaxtonHaleBase boss = SaxtonHaleBase(iClient);
	if (!boss.bValid)
		return Plugin_Continue;

	if (iArgs == 0)
		return Plugin_Handled;

	// https://wiki.teamfortress.com/wiki/Scripting#Buildings

	char sType[2], sMode[2];
	GetCmdArg(1, sType, sizeof(sType));

	TFObjectType nType = view_as<TFObjectType>(StringToInt(sType));
	TFObjectMode nMode = TFObjectMode_None;

	if (iArgs >= 2)
	{
		GetCmdArg(2, sMode, sizeof(sMode));
		nMode = view_as<TFObjectMode>(StringToInt(sMode));
	}
	else if (nType == view_as<TFObjectType>(3))	//Possible to use 3 as Teleporter Exit with only 1 arg
	{
		nType = TFObject_Teleporter;
		nMode = TFObjectMode_Exit;
	}
	
	return boss.CallFunction("OnBuild", nType, nMode);
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

void Client_AddHealth(int iClient, int iAdditionalHeal, int iMaxOverHeal=0)
{
	int iMaxHealth = SDK_GetMaxHealth(iClient);
	int iHealth = GetEntProp(iClient, Prop_Send, "m_iHealth");
	int iTrueMaxHealth = iMaxHealth+iMaxOverHeal;

	if (iHealth < iTrueMaxHealth)
	{
		iHealth += iAdditionalHeal;
		if (iHealth > iTrueMaxHealth) iHealth = iTrueMaxHealth;
		SetEntProp(iClient, Prop_Send, "m_iHealth", iHealth);
	}
}

public void Client_AddFlag(int iClient, haleClientFlags flag)
{
	g_iClientFlags[iClient] |= view_as<int>(flag);
}

public void Client_RemoveFlag(int iClient, haleClientFlags flag)
{
	g_iClientFlags[iClient] &= ~view_as<int>(flag);
}

public bool Client_HasFlag(int iClient, haleClientFlags flag)
{
	return !!(g_iClientFlags[iClient] & view_as<int>(flag));
}

stock int Client_GetEyeTarget(int iClient)
{
	float vecPos[3], vecAng[3];
	GetClientEyePosition(iClient, vecPos);
	GetClientEyeAngles(iClient, vecAng);
	
	Handle hTrace = TR_TraceRayFilterEx(vecPos, vecAng, MASK_PLAYERSOLID, RayType_Infinite, TraceRay_DontHitEntity, iClient);
	int iHit = TR_GetEntityIndex(hTrace);
	delete hTrace;
	
	return iHit;
}

stock int Client_GetBuilding(int iClient, const char[] sBuilding)
{
	int iBuilding = MaxClients+1;
	while((iBuilding = FindEntityByClassname(iBuilding, sBuilding)) > MaxClients)
	{
		//Check if same builder
		if (GetEntPropEnt(iBuilding, Prop_Send, "m_hBuilder") == iClient)
			return iBuilding;
	}
	
	return -1;
}

public Action Crossbow_OnTouch(int iEntity, int iToucher)
{
	if (!SaxtonHale_IsValidBoss(iToucher))
		return Plugin_Continue;
	
	int iClient = GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity");
	SaxtonHaleBase boss = SaxtonHaleBase(iToucher);
	if (!boss.bCanBeHealed && GetClientTeam(iClient) == GetClientTeam(iToucher))
	{
		//Dont allow crossbows heal boss, kill arrow
		AcceptEntityInput(iEntity, "Kill");
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
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
		int iSlot = TF2_GetSlotInItem(iIndex, TF2_GetPlayerClass(iClient));
		
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

void SDK_Init()
{
	GameData hGameData = new GameData("sdkhooks.games");
	if (hGameData == null) SetFailState("Could not find sdkhooks.games gamedata!");

	//This function is used to control player's max health
	int iOffset = hGameData.GetOffset("GetMaxHealth");
	g_hHookGetMaxHealth = DHookCreate(iOffset, HookType_Entity, ReturnType_Int, ThisPointer_CBaseEntity, Hook_GetMaxHealth);
	if (g_hHookGetMaxHealth == null) LogMessage("Failed to create hook: CTFPlayer::GetMaxHealth!");

	//This function is used to retreive player's max health
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGameData, SDKConf_Virtual, "GetMaxHealth");
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	g_hSDKGetMaxHealth = EndPrepSDKCall();
	if (g_hSDKGetMaxHealth == null)
		LogMessage("Failed to create call: CTFPlayer::GetMaxHealth!");

	delete hGameData;

	hGameData = new GameData("sm-tf2.games");
	if (hGameData == null) SetFailState("Could not find sm-tf2.games gamedata!");

	int iRemoveWearableOffset = hGameData.GetOffset("RemoveWearable");

	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetVirtual(iRemoveWearableOffset);
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	g_hSDKRemoveWearable = EndPrepSDKCall();
	if (g_hSDKRemoveWearable == null)
		LogMessage("Failed to create call: CBasePlayer::RemoveWearable!");

	// This call allows us to equip a wearable
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetVirtual(iRemoveWearableOffset-1);//In theory the virtual function for EquipWearable is rigth before RemoveWearable,
													//if it's always true (valve don't put a new function between these two), then we can use SM auto update offset for RemoveWearable and find EquipWearable from it
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	g_hSDKEquipWearable = EndPrepSDKCall();
	if(g_hSDKEquipWearable == null)
		LogMessage("Failed to create call: CBasePlayer::EquipWearable!");

	delete hGameData;

	hGameData = new GameData("vsh");
	if (hGameData == null) SetFailState("Could not find vsh gamedata!");

	// This call gets the weapon max ammo
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTFPlayer::GetMaxAmmo");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	g_hSDKGetMaxAmmo = EndPrepSDKCall();
	if (g_hSDKGetMaxAmmo == null)
		LogMessage("Failed to create call: CTFPlayer::GetMaxAmmo!");

	// This call gets wearable equipped in loadout slots
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTFPlayer::GetEquippedWearableForLoadoutSlot");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
	g_hSDKGetEquippedWearable = EndPrepSDKCall();
	if (g_hSDKGetEquippedWearable == null)
		LogMessage("Failed to create call: CTFPlayer::GetEquippedWearableForLoadoutSlot!");
	
	//This function is used to play the blocked knife animation
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(hGameData, SDKConf_Virtual, "CTFWeaponBase::SendWeaponAnim");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	g_hSDKSendWeaponAnim = EndPrepSDKCall();
	if (g_hSDKSendWeaponAnim == null)
		LogMessage("Failed to create call: CTFWeaponBase::SendWeaponAnim!");

	// This call gets the maximum clip 1 for a given weapon
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(hGameData, SDKConf_Virtual, "CTFWeaponBase::GetMaxClip1");
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	g_hSDKGetMaxClip = EndPrepSDKCall();
	if (g_hSDKGetMaxClip == null)
		LogMessage("Failed to create call: CTFWeaponBase::GetMaxClip1!");

	// This hook allows entity to always transmit
	iOffset = hGameData.GetOffset("CBaseEntity::ShouldTransmit");
	g_hHookShouldTransmit = DHookCreate(iOffset, HookType_Entity, ReturnType_Int, ThisPointer_CBaseEntity, Hook_EntityShouldTransmit);
	if (g_hHookShouldTransmit == null)
		LogMessage("Failed to create hook: CBaseEntity::ShouldTransmit!");
	else
		DHookAddParam(g_hHookShouldTransmit, HookParamType_ObjectPtr);

	// This hook allows to change max speed
	Handle hHook = DHookCreateFromConf(hGameData, "CTFPlayer::TeamFortress_CalculateMaxSpeed");
	if (hHook == null)
		LogMessage("Failed to create hook: CTFPlayer::TeamFortress_CalculateMaxSpeed!");
	else
		DHookEnableDetour(hHook, false, Hook_CalculateMaxSpeed);
	
	delete hHook;
	
	// This hook allows to allow/block medigun heals
	hHook = DHookCreateFromConf(hGameData, "CWeaponMedigun::AllowedToHealTarget");
	if (hHook == null)
		LogMessage("Failed to create hook: CWeaponMedigun::AllowedToHealTarget!");
	else
		DHookEnableDetour(hHook, false, Hook_AllowedToHealTarget);
	
	delete hHook;
	
	// This hook allows to allow/block dispenser heals
	hHook = DHookCreateFromConf(hGameData, "CObjectDispenser::CouldHealTarget");
	if (hHook == null)
		LogMessage("Failed to create hook: CObjectDispenser::CouldHealTarget!");
	else
		DHookEnableDetour(hHook, false, Hook_CouldHealTarget);
	
	delete hHook;
	delete hGameData;
}

public MRESReturn Hook_GetMaxHealth(int iClient, Handle hReturn)
{
	SaxtonHaleBase boss = SaxtonHaleBase(iClient);
	if (boss.bValid && boss.iMaxHealth > 0)
	{
		DHookSetReturn(hReturn, boss.iMaxHealth);
		return MRES_Supercede;
	}
	return MRES_Ignored;
}

public MRESReturn Hook_EntityShouldTransmit(int iEntity, Handle hReturn, Handle hParams)
{
	DHookSetReturn(hReturn, FL_EDICT_ALWAYS);
	return MRES_Supercede;
}

public MRESReturn Hook_CalculateMaxSpeed(int iClient, Handle hReturn, Handle hParams)
{
	if (g_flPlayerSpeedMultiplier[iClient] != 1.0)
	{
		float flSpeed = DHookGetReturn(hReturn);
		flSpeed *= g_flPlayerSpeedMultiplier[iClient];
		DHookSetReturn(hReturn, flSpeed);
		return MRES_Supercede;
	}
	
	return MRES_Ignored;
}

public MRESReturn Hook_AllowedToHealTarget(int iMedigun, Handle hReturn, Handle hParams)
{
	if (!g_bEnabled) return MRES_Ignored;
	if (g_iTotalRoundPlayed <= 0) return MRES_Ignored;
	
	int iHealTarget = DHookGetParam(hParams, 1);
	int iClient = GetEntPropEnt(iMedigun, Prop_Send, "m_hOwnerEntity");
	
	if (0 < iClient <= MaxClients && IsClientInGame(iClient))
	{
		SaxtonHaleBase boss = SaxtonHaleBase(iHealTarget);
		if (0 < iHealTarget <= MaxClients && boss.bValid && !boss.bCanBeHealed)
		{
			//Dont allow medics heal boss
			DHookSetReturn(hReturn, false);
			return MRES_Supercede;
		}
		
		TagsParams tParams = new TagsParams();
		TagsCore_CallSlot(iClient, TagsCall_Heal, WeaponSlot_Secondary, tParams);
		
		//Override heal result
		int iResult;
		if (tParams.GetIntEx("healbuilding", iResult))
		{
			bool bResult = !!iResult;
			DHookSetReturn(hReturn, bResult);
			delete tParams;
			return MRES_Supercede;
		}
		
		delete tParams;
	}
	
	return MRES_Ignored;
}

public MRESReturn Hook_CouldHealTarget(int iDispenser, Handle hReturn, Handle hParams)
{
	int iHealTarget = DHookGetParam(hParams, 1);
	
	if (0 < iHealTarget <= MaxClients)
	{
		SaxtonHaleBase boss = SaxtonHaleBase(iHealTarget);
		if (boss.bValid && !boss.bCanBeHealed)
		{
			//Dont allow dispensers heal boss
			DHookSetReturn(hReturn, false);
			return MRES_Supercede;
		}
	}
	
	return MRES_Ignored;
}

int SDK_GetMaxAmmo(int iClient, int iSlot)
{
	if(g_hSDKGetMaxAmmo != null)
		return SDKCall(g_hSDKGetMaxAmmo, iClient, iSlot, -1);
	return -1;
}

void SDK_SendWeaponAnim(int weapon, int anim)
{
	if (g_hSDKSendWeaponAnim != null)
		SDKCall(g_hSDKSendWeaponAnim, weapon, anim);
}

int SDK_GetMaxClip(int iWeapon)
{
	if(g_hSDKGetMaxClip != null)
		return SDKCall(g_hSDKGetMaxClip, iWeapon);
	return -1;
}

int SDK_GetMaxHealth(int iClient)
{
	if (g_hSDKGetMaxHealth != null)
		return SDKCall(g_hSDKGetMaxHealth, iClient);
	return 0;
}

void SDK_RemoveWearable(int client, int iWearable)
{
	if(g_hSDKRemoveWearable != null)
		SDKCall(g_hSDKRemoveWearable, client, iWearable);
}

int SDK_GetEquippedWearable(int client, int iSlot)
{
	if(g_hSDKGetEquippedWearable != null)
		return SDKCall(g_hSDKGetEquippedWearable, client, iSlot);
	return -1;
}

void SDK_EquipWearable(int client, int iWearable)
{
	if(g_hSDKEquipWearable != null)
		SDKCall(g_hSDKEquipWearable, client, iWearable);
}

public bool TraceRay_DontHitEntity(int iEntity, int contentsMask, int data)
{
	if (iEntity == data) return false;

	return true;
}

public bool TraceRay_DontHitPlayers(int entity, int mask, any data)
{
	if (entity > 0 && entity <= MaxClients) return false;
	return true;
}

stock int GetMainBoss()
{
	int iBoss = 0;
	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if (SaxtonHale_IsValidBoss(iClient, false))
		{
			if (iBoss != 0) return 0;	//If more than 1 boss active, return 0
			iBoss = iClient;
		}
	}
	
	return iBoss;
}

stock void TF2_ForceTeamJoin(int iClient, int iTeam)
{
	TFClassType class = TF2_GetPlayerClass(iClient);
	if (class == TFClass_Unknown)
	{
		// Player hasn't chosen a class. Choose one for him.
		TF2_SetPlayerClass(iClient, view_as<TFClassType>(GetRandomInt(1, 9)), true, true);
	}

	SetEntProp(iClient, Prop_Send, "m_lifeState", LifeState_Dead);
	ChangeClientTeam(iClient, iTeam);
	SetEntProp(iClient, Prop_Send, "m_lifeState", LifeState_Alive);

	TF2_RespawnPlayer(iClient);
}

stock int TF2_CreateGlow(int iEnt, int iColor[4])
{
	char oldEntName[64];
	GetEntPropString(iEnt, Prop_Data, "m_iName", oldEntName, sizeof(oldEntName));

	char strName[126], strClass[64];
	GetEntityClassname(iEnt, strClass, sizeof(strClass));
	Format(strName, sizeof(strName), "%s%i", strClass, iEnt);
	DispatchKeyValue(iEnt, "targetname", strName);

	int ent = CreateEntityByName("tf_glow");
	DispatchKeyValue(ent, "targetname", "entity_glow");
	DispatchKeyValue(ent, "target", strName);
	DispatchKeyValue(ent, "Mode", "0");
	DispatchSpawn(ent);

	AcceptEntityInput(ent, "Enable");
	SetEntPropString(iEnt, Prop_Data, "m_iName", oldEntName);

	SetVariantColor(iColor);
	AcceptEntityInput(ent, "SetGlowColor");

	SetVariantString("!activator");
	AcceptEntityInput(ent, "SetParent", iEnt);

	return ent;
}

stock bool TF2_FindAttribute(int iClient, int iAttrib, float &flVal)
{
	Address addAttrib = TF2Attrib_GetByDefIndex(iClient, iAttrib);
	if (addAttrib != Address_Null)
	{
		flVal = TF2Attrib_GetValue(addAttrib);
		return true;
	}
	return false;
}

stock bool TF2_WeaponFindAttribute(int iWeapon, int iAttrib, float &flVal)
{
	Address addAttrib = TF2Attrib_GetByDefIndex(iWeapon, iAttrib);
	if (addAttrib == Address_Null)
	{
		int iItemDefIndex = GetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex");
		int iAttributes[16];
		float flAttribValues[16];

		int iMaxAttrib = TF2Attrib_GetStaticAttribs(iItemDefIndex, iAttributes, flAttribValues);
		for (int i = 0; i < iMaxAttrib; i++)
		{
			if (iAttributes[i] == iAttrib)
			{
				flVal = flAttribValues[i];
				return true;
			}
		}
		return false;
	}
	flVal = TF2Attrib_GetValue(addAttrib);
	return true;
}

stock void TF2_AddAttributeStack(int iClient, int iAttrib, float flAddVal)
{
	float flVal = 1.0;
	if (TF2_FindAttribute(iClient, iAttrib, flVal))
		TF2Attrib_RemoveByDefIndex(iClient, iAttrib);

	if ((flVal + flAddVal) != 1.0)
		TF2Attrib_SetByDefIndex(iClient, iAttrib, (flVal + flAddVal));

	TF2Attrib_ClearCache(iClient);
}

stock bool TF2_IsUbercharged(int iClient)
{
	return (TF2_IsPlayerInCondition(iClient, TFCond_Ubercharged) ||
		TF2_IsPlayerInCondition(iClient, TFCond_UberchargedHidden) ||
		TF2_IsPlayerInCondition(iClient, TFCond_UberchargedOnTakeDamage) ||
		TF2_IsPlayerInCondition(iClient, TFCond_UberchargedCanteen));
}

stock bool TF2_IsForceCrit(int iClient)
{
	return (TF2_IsPlayerInCondition(iClient, TFCond_HalloweenCritCandy) ||
		TF2_IsPlayerInCondition(iClient, TFCond_CritCanteen) ||
		TF2_IsPlayerInCondition(iClient, TFCond_CritDemoCharge) ||
		TF2_IsPlayerInCondition(iClient, TFCond_CritOnFirstBlood) ||
		TF2_IsPlayerInCondition(iClient, TFCond_CritOnWin) ||
		TF2_IsPlayerInCondition(iClient, TFCond_CritOnFlagCapture) ||
		TF2_IsPlayerInCondition(iClient, TFCond_CritOnKill) ||
		TF2_IsPlayerInCondition(iClient, TFCond_CritMmmph) ||
		TF2_IsPlayerInCondition(iClient, TFCond_CritOnDamage) ||
		TF2_IsPlayerInCondition(iClient, TFCond_CritRuneTemp));
}

stock TFClassType TF2_GetClassType(const char[] sClass)
{
	for (int iClass = 1; iClass < sizeof(g_strClassName); iClass++)
	{
		if (StrContains(g_strClassName[iClass], sClass, false) != -1)
			return view_as<TFClassType>(iClass);
		
		if (StrContains(sClass, g_strClassName[iClass], false) != -1)
			return view_as<TFClassType>(iClass);
	}
	
	return TFClass_Unknown;
}

stock int TF2_GetSlotFromWeapon(int iWeapon)
{
	if (iWeapon <= MaxClients) return -1;
	
	int iClient = GetEntPropEnt(iWeapon, Prop_Send, "m_hOwnerEntity");
	for (int iSlot = 0; iSlot <= WeaponSlot_BuilderEngie; iSlot++)
		if (TF2_GetItemInSlot(iClient, iSlot) == iWeapon)
			return iSlot;
	
	return -1;
}

stock int TF2_GetSlotInItem(int iIndex, TFClassType nClass)
{
	int iSlot = TF2Econ_GetItemSlot(iIndex, nClass);
	if (iSlot >= 0)
	{
		//Spy slots is a bit messy
		if (nClass == TFClass_Spy)
		{
			if (iSlot == 1) iSlot = WeaponSlot_Primary;		//Revolver
			if (iSlot == 4) iSlot = WeaponSlot_Secondary;	//Sapper
			if (iSlot == 6) iSlot = WeaponSlot_InvisWatch;	//Invis Watch
		}
	}
	
	return iSlot;
}

stock int TF2_GetItemInSlot(int iClient, int iSlot)
{
	int iWeapon = GetPlayerWeaponSlot(iClient, iSlot);
	if (!IsValidEdict(iWeapon))
	{
		//If weapon not found in slot, check if it a wearable
		int iWearable = SDK_GetEquippedWearable(iClient, iSlot);
		if (IsValidEdict(iWearable))
			iWeapon = iWearable;
	}
	
	return iWeapon;
}

stock void TF2_RemoveItemInSlot(int client, int slot)
{
	TF2_RemoveWeaponSlot(client, slot);

	int iWearable = SDK_GetEquippedWearable(client, slot);
	if (iWearable > MaxClients)
	{
		SDK_RemoveWearable(client, iWearable);
		AcceptEntityInput(iWearable, "Kill");
	}
}

stock int TF2_GetPatient(int iClient)
{
	if (iClient <= 0 || iClient > MaxClients || !IsClientInGame(iClient) || !IsPlayerAlive(iClient))
		return -1;
	
	int iWeapon = TF2_GetItemInSlot(iClient, WeaponSlot_Secondary);
	if (!IsValidEdict(iWeapon))
		return -1;
			
	char sClassname[256];
	GetEntityClassname(iWeapon, sClassname, sizeof(sClassname));
	if (!StrEqual(sClassname, "tf_weapon_medigun"))
		return -1;
	
	return GetEntPropEnt(iWeapon, Prop_Send, "m_hHealingTarget");
}

stock int TF2_CreateAndEquipWeapon(int iClient, int iIndex, char[] sClassnameTemp = NULL_STRING, int iLevel = 0, TFQuality iQuality = TFQual_Normal, char[] sAttrib = NULL_STRING, bool bAttrib = false)
{
	char sClassname[256];
	if (StrEmpty(sClassnameTemp))
		TF2Econ_GetItemClassName(iIndex, sClassname, sizeof(sClassname));
	else
		strcopy(sClassname, sizeof(sClassname), sClassnameTemp);
	
	int iWeapon = CreateEntityByName(sClassname);
	
	if (IsValidEntity(iWeapon))
	{
		SetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex", iIndex);
		SetEntProp(iWeapon, Prop_Send, "m_bInitialized", 1);
		SetEntProp(iWeapon, Prop_Send, "m_bOnlyIterateItemViewAttributes", !bAttrib);	//Whenever if weapon should have default attribs or not
		
		//Allow quality / level override by updating through the offset.
		char sNetClass[64];
		GetEntityNetClass(iWeapon, sNetClass, sizeof(sNetClass));
		SetEntData(iWeapon, FindSendPropInfo(sNetClass, "m_iEntityQuality"), iQuality);
		SetEntData(iWeapon, FindSendPropInfo(sNetClass, "m_iEntityLevel"), iLevel);
		
		SetEntProp(iWeapon, Prop_Send, "m_iEntityQuality", iQuality);
		SetEntProp(iWeapon, Prop_Send, "m_iEntityLevel", iLevel);
		
		DispatchSpawn(iWeapon);
		SetEntProp(iWeapon, Prop_Send, "m_bValidatedAttachedEntity", true);
		
		if (StrContains(sClassname, "tf_wearable") == 0)
		{
			SDK_EquipWearable(iClient, iWeapon);
		}
		else
		{
			EquipPlayerWeapon(iClient, iWeapon);
			
			//Make sure max ammo is set correctly
			int iSlot = TF2_GetSlotInItem(iIndex, TF2_GetPlayerClass(iClient));
			int iMaxAmmo = SDK_GetMaxAmmo(iClient, iSlot);
			int iAmmoType = GetEntProp(iWeapon, Prop_Send, "m_iPrimaryAmmoType");
			
			if (iMaxAmmo > 0 && iAmmoType > -1)
				SetEntProp(iClient, Prop_Send, "m_iAmmo", iMaxAmmo, 4, iAmmoType);
		}
		
		char atts[32][32];
		int count = ExplodeString(sAttrib, " ; ", atts, 32, 32);
		if (count > 1)
		{
			for (int j = 0; j < count; j+= 2)
				TF2Attrib_SetByDefIndex(iWeapon, StringToInt(atts[j]), StringToFloat(atts[j+1]));

			TF2Attrib_ClearCache(iWeapon);
		}
	}
	
	return iWeapon;
}

stock void CheckForceAttackWin(int iVictim=0)
{
	//Check if all main bosses died while minions still alive, if so force make round end
	int iBossCount = 0;
	int iMinionCount = 0;
	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if (iClient != iVictim && IsClientInGame(iClient) && IsPlayerAlive(iClient) && GetClientTeam(iClient) == BOSS_TEAM)
		{
			if (SaxtonHale_IsValidBoss(iClient, false))
				iBossCount++;
			else
				iMinionCount++;
		}
	}
	
	if (iBossCount == 0 && iMinionCount > 0)
	{
		int iRoundWin = CreateEntityByName("game_round_win"); 
		DispatchSpawn(iRoundWin);
		
		SetVariantString("force_map_reset 1");
		AcceptEntityInput(iRoundWin, "AddOutput");
		SetVariantInt(ATTACK_TEAM);
		AcceptEntityInput(iRoundWin, "SetTeam");
		AcceptEntityInput(iRoundWin, "RoundWin");
	}
}

stock void TF2_Explode(int iAttacker = -1, float flPos[3], float flDamage, float flRadius, const char[] strParticle, const char[] strSound)
{
	int iBomb = CreateEntityByName("tf_generic_bomb");
	DispatchKeyValueVector(iBomb, "origin", flPos);
	DispatchKeyValueFloat(iBomb, "damage", flDamage);
	DispatchKeyValueFloat(iBomb, "radius", flRadius);
	DispatchKeyValue(iBomb, "health", "1");
	DispatchKeyValue(iBomb, "explode_particle", strParticle);
	DispatchKeyValue(iBomb, "sound", strSound);
	DispatchSpawn(iBomb);

	if (iAttacker == -1)
		AcceptEntityInput(iBomb, "Detonate");
	else
		SDKHooks_TakeDamage(iBomb, 0, iAttacker, 9999.0);
}

stock int TF2_SpawnParticle(char[] sParticle, float vecOrigin[3] = NULL_VECTOR, float flAngles[3] = NULL_VECTOR, bool bActivate = true, int iEntity = 0, int iControlPoint = 0)
{
	int iParticle = CreateEntityByName("info_particle_system");
	TeleportEntity(iParticle, vecOrigin, flAngles, NULL_VECTOR);
	DispatchKeyValue(iParticle, "effect_name", sParticle);
	DispatchSpawn(iParticle);
	
	if (0 < iEntity && IsValidEntity(iEntity))
	{
		SetVariantString("!activator");
		AcceptEntityInput(iParticle, "SetParent", iEntity);
	}
	
	if (0 < iControlPoint && IsValidEntity(iControlPoint))
	{
		//Array netprop, but really only need element 0 anyway
		SetEntPropEnt(iParticle, Prop_Send, "m_hControlPointEnts", iControlPoint, 0);
		SetEntProp(iParticle, Prop_Send, "m_iControlPointParents", iControlPoint, _, 0);
	}
	
	if (bActivate)
	{
		ActivateEntity(iParticle);
		AcceptEntityInput(iParticle, "Start");
	}
	
	//Return ref of entity
	return EntIndexToEntRef(iParticle);
}

stock void TF2_TeleportSwap(int iClient[2])
{
	float vecOrigin[2][3];
	float vecAngles[2][3];
	float vecVel[2][3];
	
	for (int i = 0; i <= 1; i++)
	{
		//Remove Sniper scope before teleporting, otherwise huge server hang can happen
		if (TF2_IsPlayerInCondition(iClient[i], TFCond_Zoomed)) TF2_RemoveCondition(iClient[i], TFCond_Zoomed);
		if (TF2_IsPlayerInCondition(iClient[i], TFCond_Slowed)) TF2_RemoveCondition(iClient[i], TFCond_Slowed);
		
		//Get its origin, angles and vel
		GetClientAbsOrigin(iClient[i], vecOrigin[i]);
		GetClientAbsAngles(iClient[i], vecAngles[i]);
		GetEntPropVector(iClient[i], Prop_Data, "m_vecVelocity", vecVel[i]);
		
		//Create particle
		CreateTimer(3.0, Timer_EntityCleanup, TF2_SpawnParticle(PARTICLE_GHOST, vecOrigin[i], vecAngles[i]));
	}
	
	for (int i = 0; i <= 1; i++)
	{
		int j = ((i == 1) ? 0 : 1);
		
		TeleportEntity(iClient[j], vecOrigin[i], vecAngles[i], vecVel[i]);
		
		if (GetEntProp(iClient[i], Prop_Send, "m_bDucking") || GetEntProp(iClient[i], Prop_Send, "m_bDucked"))
		{
			SetEntProp(iClient[j], Prop_Send, "m_bDucking", true);
			SetEntProp(iClient[j], Prop_Send, "m_bDucked", true);
			SetEntityFlags(iClient[j], GetEntityFlags(iClient[j])|FL_DUCKING);
		}
	}
}

stock int TF2_CreateLightEntity(float flRadius, int iColor[4], int iBrightness)
{
	int iGlow = CreateEntityByName("light_dynamic");
	if (iGlow != -1)
	{			
		char sLigthColor[60];
		Format(sLigthColor, sizeof(sLigthColor), "%i %i %i", iColor[0], iColor[1], iColor[2]);
		DispatchKeyValue(iGlow, "rendercolor", sLigthColor);
		
		SetVariantFloat(flRadius);
		AcceptEntityInput(iGlow, "spotlight_radius");
		
		SetVariantFloat(flRadius);
		AcceptEntityInput(iGlow, "distance");
		
		SetVariantInt(iBrightness);
		AcceptEntityInput(iGlow, "brightness");
		
		SetVariantInt(1);
		AcceptEntityInput(iGlow, "cone");
		
		DispatchSpawn(iGlow);
		
		ActivateEntity(iGlow);
		AcceptEntityInput(iGlow, "TurnOn");
		SetEntityRenderFx(iGlow, RENDERFX_SOLID_SLOW);
		SetEntityRenderColor(iGlow, iColor[0], iColor[1], iColor[2], iColor[3]);
		
		int iFlags = GetEdictFlags(iGlow);
		if (!(iFlags & FL_EDICT_ALWAYS))
		{
			iFlags |= FL_EDICT_ALWAYS;
			SetEdictFlags(iGlow, iFlags);
		}
	}
	
	return iGlow;
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

stock void CreateFade(int iClient, int iDuration = 2000, int iRed = 255, int iGreen = 255, int iBlue = 255, int iAlpha = 255)
{
	BfWrite bf = UserMessageToBfWrite(StartMessageOne("Fade", iClient));
	bf.WriteShort(iDuration);	//Fade duration
	bf.WriteShort(0);
	bf.WriteShort(0x0001);
	bf.WriteByte(iRed);			//Red
	bf.WriteByte(iGreen);		//Green
	bf.WriteByte(iBlue);		//Blue
	bf.WriteByte(iAlpha);		//Alpha
	EndMessage();
}

stock void BroadcastSoundToTeam(int team, const char[] strSound)
{
	switch (team)
	{
		case TFTeam_Red, TFTeam_Blue:
		{
			for (int iClient = 1; iClient <= MaxClients; iClient++)
				if (IsClientInGame(iClient) && !IsFakeClient(iClient) && GetClientTeam(iClient) == team)
					ClientCommand(iClient, "playgamesound %s", strSound);
		}
		default:
		{
			for (int iClient = 1; iClient <= MaxClients; iClient++)
				if(IsClientInGame(iClient) && !IsFakeClient(iClient))
					ClientCommand(iClient, "playgamesound %s", strSound);
		}
	}
}

stock bool StrEmpty(char[] sBuffer)
{
	return sBuffer[0] == '\0';
}

stock void StrToLower(char[] sBuffer)
{
	int iLength = strlen(sBuffer);
	for (int i = 0; i < iLength; i++)
		sBuffer[i] = CharToLower(sBuffer[i]);
}

stock void PrepareSound(const char[] sSoundPath)
{
	PrecacheSound(sSoundPath, true);
	char s[PLATFORM_MAX_PATH];
	Format(s, sizeof(s), "sound/%s", sSoundPath);
	AddFileToDownloadsTable(s);
}

stock int PrecacheParticleSystem(const char[] particleSystem)
{
	static int particleEffectNames = INVALID_STRING_TABLE;
	if (particleEffectNames == INVALID_STRING_TABLE)
	{
		if ((particleEffectNames = FindStringTable("ParticleEffectNames")) == INVALID_STRING_TABLE)
		{
			return INVALID_STRING_INDEX;
		}
	}

	int index = FindStringIndex2(particleEffectNames, particleSystem);
	if (index == INVALID_STRING_INDEX)
	{
		int numStrings = GetStringTableNumStrings(particleEffectNames);
		if (numStrings >= GetStringTableMaxStrings(particleEffectNames))
		{
			return INVALID_STRING_INDEX;
		}

		AddToStringTable(particleEffectNames, particleSystem);
		index = numStrings;
	}

	return index;
}

stock int FindStringIndex2(int tableidx, const char[] str)
{
	char buf[1024];
	int numStrings = GetStringTableNumStrings(tableidx);
	for (int i = 0; i < numStrings; i++)
	{
		ReadStringTable(tableidx, i, buf, sizeof(buf));
		if (StrEqual(buf, str))
		{
			return i;
		}
	}

	return INVALID_STRING_INDEX;
}
