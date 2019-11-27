static int g_iPlayerPreferences[TF_MAXPLAYERS+1] = -1;

bool Preferences_Get(int iClient, Preferences preferences)
{
	if (g_iPlayerPreferences[iClient] == -1) return false;
	
	return !(g_iPlayerPreferences[iClient] & view_as<int>(preferences));
}

bool Preferences_Set(int iClient, Preferences preferences, bool bEnable)
{
	if (g_iPlayerPreferences[iClient] == -1) return false;
	
	//since the initial value is 0 to enable all preferences, we set 0 if true, 1 if false
	bEnable = !bEnable;
	
	if (bEnable)
		g_iPlayerPreferences[iClient] |= view_as<int>(preferences);
	else
		g_iPlayerPreferences[iClient] &= ~view_as<int>(preferences);
	
	Cookies_SavePreferences(iClient, g_iPlayerPreferences[iClient]);
	
	return true;
}

void Preferences_SetAll(int iClient, int ipreferences)
{
	//No checks if it -1, and no forwards. Be careful with it
	
	g_iPlayerPreferences[iClient] = ipreferences;
}