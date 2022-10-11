static GlobalForward g_hForwardBossWin;
static GlobalForward g_hForwardBossLose;
static GlobalForward g_hForwardTeleportDamage;
static GlobalForward g_hForwardChainStabs;
static GlobalForward g_hForwardUpdatePreferences;
static GlobalForward g_hForwardUpdateQueue;

void Forward_AskLoad()
{
	g_hForwardBossWin = new GlobalForward("SaxtonHale_OnBossWin", ET_Ignore, Param_Cell);
	g_hForwardBossLose = new GlobalForward("SaxtonHale_OnBossLose", ET_Ignore, Param_Cell);
	g_hForwardTeleportDamage = new GlobalForward("SaxtonHale_OnTeleportDamage", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
	g_hForwardChainStabs = new GlobalForward("SaxtonHale_OnChainStabs", ET_Ignore, Param_Cell, Param_Cell);
	g_hForwardUpdatePreferences = new GlobalForward("SaxtonHale_OnUpdatePreferences", ET_Ignore, Param_Cell, Param_Cell);
	g_hForwardUpdateQueue = new GlobalForward("SaxtonHale_OnUpdateQueue", ET_Ignore, Param_Cell, Param_Cell);
}

void Forward_BossWin(TFTeam nTeam)
{
	Call_StartForward(g_hForwardBossWin);
	Call_PushCell(nTeam);
	Call_Finish();
}

void Forward_BossLose(TFTeam nTeam)
{
	Call_StartForward(g_hForwardBossLose);
	Call_PushCell(nTeam);
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