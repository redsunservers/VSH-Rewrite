static Handle g_hForwardBossWin;
static Handle g_hForwardBossLose;
static Handle g_hForwardTeleportDamage;
static Handle g_hForwardChainStabs;
static Handle g_hForwardUpdatePreferences;
static Handle g_hForwardUpdateQueue;
static Handle g_hForwardUpdateWinstreak;

void Forward_AskLoad()
{
	g_hForwardBossWin = CreateGlobalForward("SaxtonHale_OnBossWin", ET_Ignore, Param_Cell);
	g_hForwardBossLose = CreateGlobalForward("SaxtonHale_OnBossLose", ET_Ignore, Param_Cell);
	g_hForwardTeleportDamage = CreateGlobalForward("SaxtonHale_OnTeleportDamage", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
	g_hForwardChainStabs = CreateGlobalForward("SaxtonHale_OnChainStabs", ET_Ignore, Param_Cell, Param_Cell);
	g_hForwardUpdatePreferences = CreateGlobalForward("SaxtonHale_OnUpdatePreferences", ET_Ignore, Param_Cell, Param_Cell);
	g_hForwardUpdateQueue = CreateGlobalForward("SaxtonHale_OnUpdateQueue", ET_Ignore, Param_Cell, Param_Cell);
	g_hForwardUpdateWinstreak = CreateGlobalForward("SaxtonHale_OnUpdateWinstreak", ET_Ignore, Param_Cell, Param_Cell);
}

void Forward_BossWin(int iTeam)
{
	Call_StartForward(g_hForwardBossWin);
	Call_PushCell(iTeam);
	Call_Finish();
}

void Forward_BossLose(int iTeam)
{
	Call_StartForward(g_hForwardBossLose);
	Call_PushCell(iTeam);
	Call_Finish();
}

void Forward_TeleportDamage(int iVictim, int iAttacker, int iBuilder)
{
	Call_StartForward(g_hForwardTeleportDamage);
	Call_PushCell(iVictim);
	Call_PushCell(iAttacker);
	Call_PushCell(iBuilder);
	Call_Finish();
}

void Forward_ChainStab(int iAttacker, int iVictim)
{
	Call_StartForward(g_hForwardChainStabs);
	Call_PushCell(iAttacker);
	Call_PushCell(iVictim);
	Call_Finish();
}

void Forward_UpdatePreferences(int iClient, int iValue)
{
	Call_StartForward(g_hForwardUpdatePreferences);
	Call_PushCell(iClient);
	Call_PushCell(iValue);
	Call_Finish();
}

void Forward_UpdateQueue(int iClient, int iValue)
{
	Call_StartForward(g_hForwardUpdateQueue);
	Call_PushCell(iClient);
	Call_PushCell(iValue);
	Call_Finish();
}

void Forward_UpdateWinstreak(int iClient, int iValue)
{
	Call_StartForward(g_hForwardUpdateWinstreak);
	Call_PushCell(iClient);
	Call_PushCell(iValue);
	Call_Finish();
}