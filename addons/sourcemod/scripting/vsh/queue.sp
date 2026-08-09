static int g_iClientQueuePoints[MAXPLAYERS] = {-1, ...};

int Queue_GetPlayerFromRank(int iRank)
{	
	ArrayList aQueue = new ArrayList(2, MaxClients);
	int iLength = 0;
	
	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if (Queue_IsClientAllowed(iClient))
		{
			aQueue.Set(iLength, Queue_PlayerGetPoints(iClient), 0);	//block 0 gets sorted
			aQueue.Set(iLength, iClient, 1);
			iLength++;
		}
	}
	
	if (iRank > iLength || iLength <= 0)
		return 0;
	
	aQueue.Resize(iLength);
	aQueue.Sort(Sort_Descending, Sort_Integer);
	int iClient = aQueue.Get(iRank-1, 1);
	delete aQueue;
	
	return iClient;
}

bool Queue_IsClientAllowed(int iClient)
{
	if (0 < iClient <= MaxClients
		&& IsClientInGame(iClient)
		&& GetClientTeam(iClient) > 1			//Is client not in spectator
		&& Queue_PlayerGetPoints(iClient) != -1	//Does client have his queue point loaded
		&& !Client_HasFlag(iClient, ClientFlags_Punishment)	//Is client not in punishment
		&& Preferences_Get(iClient, VSHPreferences_PickAsBoss)	//Is client not in boss disable preferences
		&& (IsFakeClient(iClient) || (GetClientAvgLatency(iClient, NetFlow_Outgoing) * 1024.0) < g_ConfigConvar.LookupFloat("vsh_boss_ping_limit")))	//Is client under the ping limit
	{
		return true;
	}
	else
	{
		return false;
	}
}

void Queue_AddPlayerPoints(int iClient, int iPoints)
{
	if (g_iClientQueuePoints[iClient] == -1)
	{
		PrintToChat(iClient, "%s%s Your queue points do not seem to have loaded.", TEXT_TAG, TEXT_ERROR);
		return;
	}
	else if (!Preferences_Get(iClient, VSHPreferences_PickAsBoss))
	{
		PrintToChat(iClient, "%s%s You have not been awarded any queue points based on your boss preferences.", TEXT_TAG, TEXT_COLOR);
		return;
	}

	g_iClientQueuePoints[iClient] += iPoints;
	Cookies_SaveQueue(iClient, Queue_PlayerGetPoints(iClient));
	
	PrintToChat(iClient, "%s%s You have been awarded %d queue points! (Total: %i)", TEXT_TAG, TEXT_COLOR, iPoints, g_iClientQueuePoints[iClient]);
}

void Queue_SetPlayerPoints(int iClient, int iPoints)
{
	//No checks if it -1, and no forwards. Be careful with it
	
	g_iClientQueuePoints[iClient] = iPoints;
}

void Queue_ResetPlayer(int iClient)
{
	if (g_iClientQueuePoints[iClient] == -1) return;
	
	g_iClientQueuePoints[iClient] = 0;
	Cookies_SaveQueue(iClient, Queue_PlayerGetPoints(iClient));
}

int Queue_PlayerGetPoints(int iClient)
{
	return g_iClientQueuePoints[iClient];
}