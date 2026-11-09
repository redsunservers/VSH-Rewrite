#define AFK_CHECK_TIME	20.0
#define AFK_ALERT_TIME	7.0

static char g_sAfkCommands[][] = { "say", "say_team", "menuselect", "voicemenu", "taunt", "+taunt", "joinclass", "+inspect_server", "+use_action_slot_item_server" };

static int g_iAfkRound;
static bool g_bAfkWindow;
static int g_iAfkInputUserId[MAXPLAYERS];
static int g_iAfkTrackedUserId[MAXPLAYERS];
static bool g_bAfkLive;
static float g_flAfkLiveTime;
static float g_flAfkLastInput[MAXPLAYERS];
static bool g_bAfkAlerted[MAXPLAYERS];

void Afk_Init()
{
	for (int i = 0; i < sizeof(g_sAfkCommands); i++)
		AddCommandListener(Afk_CommandListener, g_sAfkCommands[i]);
}

public Action Afk_CommandListener(int iClient, const char[] sCommand, int iArgc)
{
	Afk_MarkInput(iClient);
	return Plugin_Continue;
}

void Afk_OnPlayerRunCmd(int iClient, int iButtons, int iImpulse, int iWeapon, const int iMouse[2])
{
	if (iButtons != 0 || iImpulse != 0 || iWeapon != 0 || iMouse[0] != 0 || iMouse[1] != 0)
		Afk_MarkInput(iClient);
	else if (g_bAfkLive)
		Afk_CheckIdle(iClient);
}

static void Afk_MarkInput(int iClient)
{
	if (g_bAfkWindow && 0 < iClient <= MaxClients && IsClientInGame(iClient))
	{
		g_iAfkInputUserId[iClient] = GetClientUserId(iClient);
		g_flAfkLastInput[iClient] = GetGameTime();
		g_bAfkAlerted[iClient] = false;
	}
}

static void Afk_CheckIdle(int iClient)
{
	if (!g_bRoundStarted || g_bAfkAlerted[iClient] || g_iAfkTrackedUserId[iClient] != GetClientUserId(iClient))
		return;
	
	if (TF2_GetClientTeam(iClient) != TFTeam_Attack)
		return;
	
	float flIdleSince = (g_flAfkLastInput[iClient] > g_flAfkLiveTime) ? g_flAfkLastInput[iClient] : g_flAfkLiveTime;
	if (GetGameTime() - flIdleSince < AFK_ALERT_TIME)
		return;
	
	g_bAfkAlerted[iClient] = true;
	EmitSoundToClient(iClient, SOUND_ALERT);
}

void Afk_RoundStart()
{
	g_iAfkRound++;
	g_bAfkWindow = true;
	g_bAfkLive = false;
	
	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		g_iAfkInputUserId[iClient] = 0;
		g_iAfkTrackedUserId[iClient] = 0;
		g_flAfkLastInput[iClient] = 0.0;
		g_bAfkAlerted[iClient] = false;
	}
}

void Afk_RoundArenaStart()
{
	g_bAfkWindow = true;
	
	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		g_iAfkTrackedUserId[iClient] = 0;
		g_bAfkAlerted[iClient] = false;
		if (SaxtonHale_IsValidAttack(iClient) && IsPlayerAlive(iClient))
			g_iAfkTrackedUserId[iClient] = GetClientUserId(iClient);
	}
	
	g_bAfkLive = true;
	g_flAfkLiveTime = GetGameTime();
	CreateTimer(AFK_CHECK_TIME, Afk_Timer_Check, g_iAfkRound, TIMER_FLAG_NO_MAPCHANGE);
}

public Action Afk_Timer_Check(Handle hTimer, int iRound)
{
	if (iRound != g_iAfkRound)
		return Plugin_Continue;
	
	g_bAfkLive = false;
	if (!g_bEnabled || !g_bRoundStarted)
		return Plugin_Continue;
	
	g_bAfkWindow = false;
	
	int iAfk = 0;
	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		int iUserId = g_iAfkTrackedUserId[iClient];
		if (iUserId == 0 || !IsClientInGame(iClient) || GetClientUserId(iClient) != iUserId)
			continue;
		
		if (TF2_GetClientTeam(iClient) != TFTeam_Attack || g_iAfkInputUserId[iClient] == iUserId)
			continue;
		
		iAfk++;
	}
	
	if (iAfk > 0)
	{
		int iRemoved = Afk_RemoveBossHealth(iAfk);
		if (iRemoved > 0)
			PrintToChatAll("%s%s %d players were afk at the start of a round removing %d Health from the boss to compensate", TEXT_TAG, TEXT_COLOR, iAfk, iRemoved);
	}
	
	return Plugin_Continue;
}

static int Afk_RemoveBossHealth(int iAfk)
{
	int iCount = g_iTotalAttackCount;
	int iRemaining = iCount - iAfk;
	if (iRemaining < 1)
		iRemaining = 1;
	
	if (iRemaining >= iCount)
		return 0;
	
	int iTotal = 0;
	
	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if (!IsClientInGame(iClient) || !IsPlayerAlive(iClient))
			continue;
		
		SaxtonHaleBase boss = SaxtonHaleBase(iClient);
		if (!boss.bValid || boss.bMinion)
			continue;
		
		int iFull = boss.CallFunction("CalculateMaxHealth");
		g_iTotalAttackCount = iRemaining;
		int iReduced = boss.CallFunction("CalculateMaxHealth");
		g_iTotalAttackCount = iCount;
		
		int iRemove = iFull - iReduced;
		if (iRemove <= 0)
			continue;
		
		int iMaxHealth = boss.iMaxHealth - iRemove;
		if (iMaxHealth < 1)
			iMaxHealth = 1;
		
		int iHealth = boss.iHealth - iRemove;
		if (iHealth < 1)
			iHealth = 1;
		
		iTotal += boss.iMaxHealth - iMaxHealth;
		boss.iMaxHealth = iMaxHealth;
		boss.iHealth = iHealth;
	}
	
	return iTotal;
}
