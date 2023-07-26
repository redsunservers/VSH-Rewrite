static int g_iPlayerPreferences[MAXPLAYERS] = {-1, ...};

bool Preferences_Get(int iClient, SaxtonHalePreferences nPreferences)
{
	if (g_iPlayerPreferences[iClient] == -1)
		return false;
	
	return !(g_iPlayerPreferences[iClient] & RoundToNearest(Pow(2.0, float(view_as<int>(nPreferences)))));
}

bool Preferences_Set(int iClient, SaxtonHalePreferences nPreferences, bool bEnable)
{
	if (g_iPlayerPreferences[iClient] == -1)
		return false;
	
	//since the initial value is 0 to enable all preferences, we set 0 if true, 1 if false
	bEnable = !bEnable;
	
	if (bEnable)
		g_iPlayerPreferences[iClient] |= RoundToNearest(Pow(2.0, float(view_as<int>(nPreferences))));
	else
		g_iPlayerPreferences[iClient] &= ~RoundToNearest(Pow(2.0, float(view_as<int>(nPreferences))));
	
	Cookies_SavePreferences(iClient, g_iPlayerPreferences[iClient]);
	return true;
}

void Preferences_SetAll(int iClient, int iPreferences)
{
	//No checks if it -1, and no forwards. Be careful with it
	
	g_iPlayerPreferences[iClient] = iPreferences;
}