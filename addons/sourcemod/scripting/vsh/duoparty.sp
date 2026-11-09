#define DUOPARTY_NAME_LENGTH	64
#define DUOPARTY_AWAY_TIME	120.0
#define DUOPARTY_TEXT_COLOR	"\x07FFE600"
#define DUOPARTY_SOUND_INVITE	"ui/notification_alert.wav"
#define DUOPARTY_SOUND_FORMED	"ui/cyoa_node_activate.wav"
#define DUOPARTY_SOUND_OPTIN	"ui/duel_challenge.wav"
#define DUOPARTY_SOUND_DISBAND	"ui/chat_display_text.wav"

enum struct DuoParty
{
	int iAccountA;
	int iAccountB;
	char sNameA[MAX_NAME_LENGTH];
	char sNameB[MAX_NAME_LENGTH];
	char sPartyName[DUOPARTY_NAME_LENGTH];
	float flAwaySince;
}

static ArrayList g_aDuoParties;
static Cookie g_hCookiesDuoOptIn;
static int g_iDuoPartner[MAXPLAYERS];
static bool g_bDuoOptIn[MAXPLAYERS];
static int g_iDuoInviteFrom[MAXPLAYERS];
static bool g_bDuoNaming[MAXPLAYERS];

void DuoParty_Init()
{
	g_aDuoParties = new ArrayList(sizeof(DuoParty));
	g_hCookiesDuoOptIn = PrefSave_NewCookie("vsh_duo_optin", "VSH opt in to only play as duo boss", CookieAccess_Private);

	Command_Create("duopref", DuoParty_Command_Menu);
	RegConsoleCmd("sm_duopref", DuoParty_Command_Menu);
	RegConsoleCmd("sm_accept", DuoParty_Command_Accept);
	RegConsoleCmd("sm_optin", DuoParty_Command_OptIn);
	RegConsoleCmd("sm_partyname", DuoParty_Command_PartyName);

	CreateTimer(5.0, DuoParty_Timer_CheckAway, _, TIMER_REPEAT);
}

void DuoParty_OnMapStart()
{
	PrecacheSound(DUOPARTY_SOUND_INVITE);
	PrecacheSound(DUOPARTY_SOUND_FORMED);
	PrecacheSound(DUOPARTY_SOUND_OPTIN);
	PrecacheSound(DUOPARTY_SOUND_DISBAND);
}

void DuoParty_LoadOptIn(int iClient)
{
	g_bDuoOptIn[iClient] = false;
	if (!DuoParty_UseCookies(iClient))
		return;

	char sValue[4];
	g_hCookiesDuoOptIn.Get(iClient, sValue, sizeof(sValue));
	g_bDuoOptIn[iClient] = (StringToInt(sValue) == 1);
}

static bool DuoParty_UseCookies(int iClient)
{
	return (!IsFakeClient(iClient) && AreClientCookiesCached(iClient) && g_ConfigConvar.LookupBool("vsh_cookies_preferences"));
}

void DuoParty_OnClientJoin(int iClient)
{
	g_iDuoInviteFrom[iClient] = 0;
	g_bDuoNaming[iClient] = false;

	int iIndex = DuoParty_FindIndex(iClient);
	if (iIndex == -1)
		return;

	DuoParty party;
	g_aDuoParties.GetArray(iIndex, party);
	if (party.iAccountA == GetSteamAccountID(iClient))
		GetClientName(iClient, party.sNameA, MAX_NAME_LENGTH);
	else
		GetClientName(iClient, party.sNameB, MAX_NAME_LENGTH);

	DuoParty_RefreshPartners();
	if (g_iDuoPartner[iClient] > 0)
		party.flAwaySince = 0.0;

	g_aDuoParties.SetArray(iIndex, party);
}

void DuoParty_OnClientLeave(int iClient)
{
	g_iDuoInviteFrom[iClient] = 0;
	g_bDuoNaming[iClient] = false;
	g_bDuoOptIn[iClient] = false;

	int iIndex = DuoParty_FindIndex(iClient);
	if (iIndex != -1)
	{
		DuoParty party;
		g_aDuoParties.GetArray(iIndex, party);
		party.flAwaySince = GetEngineTime();
		g_aDuoParties.SetArray(iIndex, party);
	}

	DuoParty_RefreshPartners(iClient);
}

public Action DuoParty_Timer_CheckAway(Handle hTimer)
{
	float flNow = GetEngineTime();
	bool bChanged = false;

	for (int i = g_aDuoParties.Length - 1; i >= 0; i--)
	{
		DuoParty party;
		g_aDuoParties.GetArray(i, party);
		if (party.flAwaySince <= 0.0 || flNow - party.flAwaySince < DUOPARTY_AWAY_TIME)
			continue;

		int iClientA = DuoParty_FindClient(party.iAccountA);
		int iClientB = DuoParty_FindClient(party.iAccountB);
		if (iClientA > 0 && iClientB > 0)
		{
			party.flAwaySince = 0.0;
			g_aDuoParties.SetArray(i, party);
			continue;
		}

		g_aDuoParties.Erase(i);
		bChanged = true;

		int iStayed = (iClientA > 0) ? iClientA : iClientB;
		if (iStayed > 0)
		{
			g_bDuoNaming[iStayed] = false;
			PrintToChat(iStayed, "%s%s Party has disbanded due to player leaving your party", TEXT_TAG, DUOPARTY_TEXT_COLOR);
			EmitSoundToClient(iStayed, DUOPARTY_SOUND_DISBAND);
		}
	}

	if (bChanged)
		DuoParty_RefreshPartners();

	return Plugin_Continue;
}

public Action DuoParty_Command_Menu(int iClient, int iArgs)
{
	if (!g_bEnabled) return Plugin_Continue;

	if (iClient == 0)
	{
		ReplyToCommand(iClient, "This command can only be used in-game.");
		return Plugin_Handled;
	}

	MenuDuoParty_Display(iClient);
	return Plugin_Handled;
}

public Action DuoParty_Command_Accept(int iClient, int iArgs)
{
	if (!g_bEnabled) return Plugin_Continue;

	if (iClient == 0)
	{
		ReplyToCommand(iClient, "This command can only be used in-game.");
		return Plugin_Handled;
	}

	int iInviter = GetClientOfUserId(g_iDuoInviteFrom[iClient]);
	g_iDuoInviteFrom[iClient] = 0;
	if (iInviter <= 0 || iInviter == iClient || !IsClientInGame(iInviter) || GetSteamAccountID(iInviter) == 0 || GetSteamAccountID(iClient) == 0
		|| DuoParty_FindIndex(iClient) != -1 || DuoParty_FindIndex(iInviter) != -1)
	{
		PrintToChat(iClient, "%s%s No invites have been sent to you", TEXT_TAG, TEXT_ERROR);
		return Plugin_Handled;
	}

	DuoParty_Create(iInviter, iClient);
	return Plugin_Handled;
}

public Action DuoParty_Command_OptIn(int iClient, int iArgs)
{
	if (!g_bEnabled) return Plugin_Continue;

	if (iClient == 0)
	{
		ReplyToCommand(iClient, "This command can only be used in-game.");
		return Plugin_Handled;
	}

	DuoParty_SetOptIn(iClient, true);
	PrintToChat(iClient, "%s%s You have chosen to opt in to always become a duo boss", TEXT_TAG, DUOPARTY_TEXT_COLOR);
	return Plugin_Handled;
}

public Action DuoParty_Command_PartyName(int iClient, int iArgs)
{
	if (!g_bEnabled) return Plugin_Continue;

	if (iClient == 0)
	{
		ReplyToCommand(iClient, "This command can only be used in-game.");
		return Plugin_Handled;
	}

	DuoParty_StartNaming(iClient);
	return Plugin_Handled;
}

void DuoParty_Invite(int iClient, int iTarget)
{
	if (iTarget <= 0 || iTarget == iClient || !IsClientInGame(iTarget) || IsFakeClient(iTarget))
		return;

	if (DuoParty_FindIndex(iClient) != -1)
	{
		PrintToChat(iClient, "%s%s You cannot invite a player to your party as its already full", TEXT_TAG, TEXT_ERROR);
		return;
	}

	if (DuoParty_FindIndex(iTarget) != -1)
	{
		PrintToChat(iClient, "%s%s The player you tried to invite is already in a party", TEXT_TAG, TEXT_ERROR);
		return;
	}

	g_iDuoInviteFrom[iTarget] = GetClientUserId(iClient);
	PrintToChat(iTarget, "%s%s You have been invited to be a duo boss partner for %N during their next duo boss round, type %s/accept%s to accept.", TEXT_TAG, DUOPARTY_TEXT_COLOR, iClient, TEXT_POSITIVE, DUOPARTY_TEXT_COLOR);
	EmitSoundToClient(iTarget, DUOPARTY_SOUND_INVITE);
	PrintToChat(iClient, "%s%s Invite sent to %N", TEXT_TAG, DUOPARTY_TEXT_COLOR, iTarget);
}

static void DuoParty_Create(int iInviter, int iInvitee)
{
	DuoParty party;
	party.iAccountA = GetSteamAccountID(iInviter);
	party.iAccountB = GetSteamAccountID(iInvitee);
	GetClientName(iInviter, party.sNameA, MAX_NAME_LENGTH);
	GetClientName(iInvitee, party.sNameB, MAX_NAME_LENGTH);
	g_aDuoParties.PushArray(party);

	for (int i = 1; i <= MaxClients; i++)
	{
		int iFrom = GetClientOfUserId(g_iDuoInviteFrom[i]);
		if (i == iInviter || i == iInvitee || iFrom == iInviter || iFrom == iInvitee)
			g_iDuoInviteFrom[i] = 0;
	}

	DuoParty_RefreshPartners();

	PrintToChat(iInviter, "%s%s Party formed, return to Duo Preference menu or type %s!duopref%s to access party settings", TEXT_TAG, DUOPARTY_TEXT_COLOR, TEXT_POSITIVE, DUOPARTY_TEXT_COLOR);
	PrintToChat(iInvitee, "%s%s Party formed, return to Duo Preference menu or type %s!duopref%s to access party settings", TEXT_TAG, DUOPARTY_TEXT_COLOR, TEXT_POSITIVE, DUOPARTY_TEXT_COLOR);
	EmitSoundToClient(iInviter, DUOPARTY_SOUND_FORMED);
	EmitSoundToClient(iInvitee, DUOPARTY_SOUND_FORMED);

	if (g_bDuoOptIn[iInviter] && !g_bDuoOptIn[iInvitee])
		DuoParty_AskOptIn(iInvitee);
	else if (g_bDuoOptIn[iInvitee] && !g_bDuoOptIn[iInviter])
		DuoParty_AskOptIn(iInviter);
}

static void DuoParty_AskOptIn(int iClient)
{
	PrintToChat(iClient, "%s%s The other player in your party wants to opt in to always play as duo boss, type %s/optin%s to confirm this choice", TEXT_TAG, DUOPARTY_TEXT_COLOR, TEXT_POSITIVE, DUOPARTY_TEXT_COLOR);
	EmitSoundToClient(iClient, DUOPARTY_SOUND_OPTIN);
}

static void DuoParty_SetOptIn(int iClient, bool bOptIn)
{
	g_bDuoOptIn[iClient] = bOptIn;

	if (DuoParty_UseCookies(iClient))
	{
		char sValue[4];
		IntToString(view_as<int>(bOptIn), sValue, sizeof(sValue));
		PrefSave_SetCookie(iClient, g_hCookiesDuoOptIn, sValue);
	}

	int iPartner = DuoParty_GetPartner(iClient);
	if (bOptIn)
	{
		if (iPartner > 0 && !g_bDuoOptIn[iPartner])
			DuoParty_AskOptIn(iPartner);
	}
	else
	{
		g_bDuoNaming[iClient] = false;
		if (iPartner > 0)
			g_bDuoNaming[iPartner] = false;
	}
}

void DuoParty_ToggleOptIn(int iClient)
{
	DuoParty_SetOptIn(iClient, !g_bDuoOptIn[iClient]);
}

void DuoParty_StartNaming(int iClient)
{
	if (!DuoParty_IsOptedInPair(iClient))
	{
		PrintToChat(iClient, "%s%s Party cannot be named unless both party members opt in to always be a duo boss", TEXT_TAG, TEXT_ERROR);
		return;
	}

	g_bDuoNaming[iClient] = true;
	PrintToChat(iClient, "%s%s type in chat what you want to name your party", TEXT_TAG, DUOPARTY_TEXT_COLOR);
}

void DuoParty_Disband(int iClient)
{
	int iIndex = DuoParty_FindIndex(iClient);
	if (iIndex == -1)
		return;

	DuoParty party;
	g_aDuoParties.GetArray(iIndex, party);
	g_aDuoParties.Erase(iIndex);

	int iMembers[2];
	iMembers[0] = DuoParty_FindClient(party.iAccountA);
	iMembers[1] = DuoParty_FindClient(party.iAccountB);
	for (int i = 0; i < sizeof(iMembers); i++)
	{
		if (iMembers[i] <= 0)
			continue;

		g_bDuoNaming[iMembers[i]] = false;
		PrintToChat(iMembers[i], "%s%s %N has disbanded the party", TEXT_TAG, DUOPARTY_TEXT_COLOR, iClient);
		EmitSoundToClient(iMembers[i], DUOPARTY_SOUND_DISBAND);
	}

	DuoParty_RefreshPartners();
}

public Action OnClientSayCommand(int iClient, const char[] sCommand, const char[] sArgs)
{
	if (iClient <= 0 || iClient > MaxClients || !g_bDuoNaming[iClient])
		return Plugin_Continue;

	g_bDuoNaming[iClient] = false;

	int iIndex = DuoParty_FindIndex(iClient);
	if (iIndex == -1)
		return Plugin_Continue;

	char sName[DUOPARTY_NAME_LENGTH];
	DuoParty_CleanName(sArgs, sName, sizeof(sName));
	if (sName[0] == '\0')
		return Plugin_Handled;

	DuoParty party;
	g_aDuoParties.GetArray(iIndex, party);
	strcopy(party.sPartyName, DUOPARTY_NAME_LENGTH, sName);
	g_aDuoParties.SetArray(iIndex, party);

	PrintToChat(iClient, "%s%s Party has been renamed to %s", TEXT_TAG, DUOPARTY_TEXT_COLOR, sName);
	return Plugin_Handled;
}

static void DuoParty_CleanName(const char[] sText, char[] sName, int iLength)
{
	char sBuffer[256];
	strcopy(sBuffer, sizeof(sBuffer), sText);
	StripQuotes(sBuffer);
	TrimString(sBuffer);

	int iOut = 0;
	int i = 0;
	while (sBuffer[i] != '\0')
	{
		int iBytes = GetCharBytes(sBuffer[i]);
		if (iBytes <= 1 && (sBuffer[i] < ' ' || sBuffer[i] == '%'))
		{
			i++;
			continue;
		}

		if (iOut + iBytes >= iLength)
			break;

		for (int j = 0; j < iBytes && sBuffer[i] != '\0'; j++)
			sName[iOut++] = sBuffer[i++];
	}

	sName[iOut] = '\0';
	TrimString(sName);
}

int DuoParty_GetPartner(int iClient)
{
	if (iClient <= 0 || iClient > MaxClients)
		return 0;

	return g_iDuoPartner[iClient];
}

bool DuoParty_IsInParty(int iClient)
{
	return (DuoParty_FindIndex(iClient) != -1);
}

bool DuoParty_IsOptedIn(int iClient)
{
	return g_bDuoOptIn[iClient];
}

bool DuoParty_IsOptedInPair(int iClient)
{
	int iPartner = DuoParty_GetPartner(iClient);
	return (iPartner > 0 && g_bDuoOptIn[iClient] && g_bDuoOptIn[iPartner]);
}

int DuoParty_GetQueuePartner(int iClient)
{
	if (!DuoParty_IsOptedInPair(iClient))
		return 0;

	int iPartner = DuoParty_GetPartner(iClient);
	if (!Queue_IsClientAllowed(iPartner))
		return 0;

	return iPartner;
}

int DuoParty_GetBossPartner(int iClient, ArrayList aNonBosses)
{
	int iPartner = DuoParty_GetPartner(iClient);
	if (iPartner <= 0 || aNonBosses.FindValue(iPartner) == -1 || !Queue_IsClientAllowed(iPartner))
		return 0;

	return iPartner;
}

void DuoParty_GetEntryName(int iClient, char[] sName, int iLength)
{
	int iIndex = DuoParty_FindIndex(iClient);
	if (iIndex == -1)
	{
		GetClientName(iClient, sName, iLength);
		return;
	}

	DuoParty party;
	g_aDuoParties.GetArray(iIndex, party);
	if (party.sPartyName[0] != '\0')
	{
		strcopy(sName, iLength, party.sPartyName);
		return;
	}

	char sNameA[MAX_NAME_LENGTH], sNameB[MAX_NAME_LENGTH];
	DuoParty_GetMember(iClient, 0, sNameA, sizeof(sNameA));
	DuoParty_GetMember(iClient, 1, sNameB, sizeof(sNameB));
	Format(sName, iLength, "%s and %s", sNameA, sNameB);
}

int DuoParty_GetMember(int iClient, int iMember, char[] sName, int iLength)
{
	sName[0] = '\0';
	int iIndex = DuoParty_FindIndex(iClient);
	if (iIndex == -1)
		return 0;

	DuoParty party;
	g_aDuoParties.GetArray(iIndex, party);

	int iMemberClient;
	if (iMember == 0)
	{
		iMemberClient = DuoParty_FindClient(party.iAccountA);
		strcopy(sName, iLength, party.sNameA);
	}
	else
	{
		iMemberClient = DuoParty_FindClient(party.iAccountB);
		strcopy(sName, iLength, party.sNameB);
	}

	if (iMemberClient > 0)
		GetClientName(iMemberClient, sName, iLength);

	return iMemberClient;
}

void DuoParty_GetPartnerName(int iClient, char[] sName, int iLength)
{
	sName[0] = '\0';
	int iIndex = DuoParty_FindIndex(iClient);
	if (iIndex == -1)
		return;

	DuoParty party;
	g_aDuoParties.GetArray(iIndex, party);
	if (party.iAccountA == GetSteamAccountID(iClient))
		DuoParty_GetMember(iClient, 1, sName, iLength);
	else
		DuoParty_GetMember(iClient, 0, sName, iLength);
}

static int DuoParty_FindIndex(int iClient)
{
	if (iClient <= 0 || iClient > MaxClients || !IsClientConnected(iClient) || IsFakeClient(iClient))
		return -1;

	int iAccount = GetSteamAccountID(iClient);
	if (iAccount == 0)
		return -1;

	int iIndex = g_aDuoParties.FindValue(iAccount, 0);
	if (iIndex == -1)
		iIndex = g_aDuoParties.FindValue(iAccount, 1);

	return iIndex;
}

static int DuoParty_FindClient(int iAccount, int iIgnore = 0)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (i != iIgnore && IsClientInGame(i) && !IsFakeClient(i) && GetSteamAccountID(i) == iAccount)
			return i;
	}

	return 0;
}

static void DuoParty_RefreshPartners(int iIgnore = 0)
{
	for (int i = 1; i <= MaxClients; i++)
		g_iDuoPartner[i] = 0;

	int iLength = g_aDuoParties.Length;
	for (int i = 0; i < iLength; i++)
	{
		DuoParty party;
		g_aDuoParties.GetArray(i, party);
		int iClientA = DuoParty_FindClient(party.iAccountA, iIgnore);
		int iClientB = DuoParty_FindClient(party.iAccountB, iIgnore);
		if (iClientA > 0 && iClientB > 0)
		{
			g_iDuoPartner[iClientA] = iClientB;
			g_iDuoPartner[iClientB] = iClientA;
		}
	}
}
