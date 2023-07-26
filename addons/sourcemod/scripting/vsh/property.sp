static bool g_bValid[MAXPLAYERS];
static bool g_bModifiers[MAXPLAYERS];
static bool g_bMinion[MAXPLAYERS];
static bool g_bSuperRage[MAXPLAYERS];
static bool g_bModel[MAXPLAYERS];
static bool g_bHealthPerPlayerAlive[MAXPLAYERS];
static float g_flSpeed[MAXPLAYERS];
static float g_flSpeedMult[MAXPLAYERS];
static float g_flEnvDamageCap[MAXPLAYERS];
static float g_flGlowTime[MAXPLAYERS];
static float g_flRageLastTime[MAXPLAYERS];
static float g_flMaxRagePercentage[MAXPLAYERS];
static float g_flHealthExponential[MAXPLAYERS];
static float g_flHealthMultiplier[MAXPLAYERS];
static int g_iMaxHealth[MAXPLAYERS];
static int g_iBaseHealth[MAXPLAYERS];
static int g_iHealthPerPlayer[MAXPLAYERS];
static int g_iRageDamage[MAXPLAYERS];
static int g_iMaxRageDamage[MAXPLAYERS];
static TFClassType g_nClass[MAXPLAYERS];

void Property_AskLoad()
{
	CreateNative("SaxtonHaleBase.bValid.set", Property_SetValid);
	CreateNative("SaxtonHaleBase.bValid.get", Property_GetValid);
	CreateNative("SaxtonHaleBase.bModifiers.set", Property_SetModifiers);
	CreateNative("SaxtonHaleBase.bModifiers.get", Property_GetModifiers);
	CreateNative("SaxtonHaleBase.bMinion.set", Property_SetMinion);
	CreateNative("SaxtonHaleBase.bMinion.get", Property_GetMinion);
	CreateNative("SaxtonHaleBase.bSuperRage.set", Property_SetSuperRage);
	CreateNative("SaxtonHaleBase.bSuperRage.get", Property_GetSuperRage);
	CreateNative("SaxtonHaleBase.bModel.set", Property_SetModel);
	CreateNative("SaxtonHaleBase.bModel.get", Property_GetModel);
	CreateNative("SaxtonHaleBase.bHealthPerPlayerAlive.set", Property_SetHealthPerPlayerAlive);
	CreateNative("SaxtonHaleBase.bHealthPerPlayerAlive.get", Property_GetHealthPerPlayerAlive);
	CreateNative("SaxtonHaleBase.flSpeed.set", Property_SetSpeed);
	CreateNative("SaxtonHaleBase.flSpeed.get", Property_GetSpeed);
	CreateNative("SaxtonHaleBase.flSpeedMult.set", Property_SetSpeedMult);
	CreateNative("SaxtonHaleBase.flSpeedMult.get", Property_GetSpeedMult);
	CreateNative("SaxtonHaleBase.flEnvDamageCap.set", Property_SetEnvDamageCap);
	CreateNative("SaxtonHaleBase.flEnvDamageCap.get", Property_GetEnvDamageCap);
	CreateNative("SaxtonHaleBase.flGlowTime.set", Property_SetGlowTime);
	CreateNative("SaxtonHaleBase.flGlowTime.get", Property_GetGlowTime);
	CreateNative("SaxtonHaleBase.flRageLastTime.set", Property_SetRageLastTime);
	CreateNative("SaxtonHaleBase.flRageLastTime.get", Property_GetRageLastTime);
	CreateNative("SaxtonHaleBase.flMaxRagePercentage.set", Property_SetMaxRagePercentage);
	CreateNative("SaxtonHaleBase.flMaxRagePercentage.get", Property_GetMaxRagePercentage);
	CreateNative("SaxtonHaleBase.flHealthExponential.set", Property_SetHealthExponential);
	CreateNative("SaxtonHaleBase.flHealthExponential.get", Property_GetHealthExponential);
	CreateNative("SaxtonHaleBase.flHealthMultiplier.set", Property_SetHealthMultiplier);
	CreateNative("SaxtonHaleBase.flHealthMultiplier.get", Property_GetHealthMultiplier);
	CreateNative("SaxtonHaleBase.iMaxHealth.set", Property_SetMaxHealth);
	CreateNative("SaxtonHaleBase.iMaxHealth.get", Property_GetMaxHealth);
	CreateNative("SaxtonHaleBase.iBaseHealth.set", Property_SetBaseHealth);
	CreateNative("SaxtonHaleBase.iBaseHealth.get", Property_GetBaseHealth);
	CreateNative("SaxtonHaleBase.iHealthPerPlayer.set", Property_SetHealthPerPlayer);
	CreateNative("SaxtonHaleBase.iHealthPerPlayer.get", Property_GetHealthPerPlayer);
	CreateNative("SaxtonHaleBase.iRageDamage.set", Property_SetRageDamage);
	CreateNative("SaxtonHaleBase.iRageDamage.get", Property_GetRageDamage);
	CreateNative("SaxtonHaleBase.iMaxRageDamage.set", Property_SetMaxRageDamage);
	CreateNative("SaxtonHaleBase.iMaxRageDamage.get", Property_GetMaxRageDamage);
	CreateNative("SaxtonHaleBase.nClass.set", Property_SetClass);
	CreateNative("SaxtonHaleBase.nClass.get", Property_GetClass);
}

public any Property_SetValid(Handle hPlugin, int iNumParams)
{
	g_bValid[GetNativeCell(1)] = GetNativeCell(2);
	return 0;
}

public any Property_GetValid(Handle hPlugin, int iNumParams)
{
	return g_bValid[GetNativeCell(1)];
}

public any Property_SetModifiers(Handle hPlugin, int iNumParams)
{
	g_bModifiers[GetNativeCell(1)] = GetNativeCell(2);
	return 0;
}

public any Property_GetModifiers(Handle hPlugin, int iNumParams)
{
	return g_bModifiers[GetNativeCell(1)];
}

public any Property_SetMinion(Handle hPlugin, int iNumParams)
{
	g_bMinion[GetNativeCell(1)] = GetNativeCell(2);
	return 0;
}

public any Property_GetMinion(Handle hPlugin, int iNumParams)
{
	return g_bMinion[GetNativeCell(1)];
}

public any Property_SetSuperRage(Handle hPlugin, int iNumParams)
{
	g_bSuperRage[GetNativeCell(1)] = GetNativeCell(2);
	return 0;
}

public any Property_GetSuperRage(Handle hPlugin, int iNumParams)
{
	return g_bSuperRage[GetNativeCell(1)];
}

public any Property_SetModel(Handle hPlugin, int iNumParams)
{
	g_bModel[GetNativeCell(1)] = GetNativeCell(2);
	return 0;
}

public any Property_GetModel(Handle hPlugin, int iNumParams)
{
	return g_bModel[GetNativeCell(1)];
}

public any Property_SetHealthPerPlayerAlive(Handle hPlugin, int iNumParams)
{
	g_bHealthPerPlayerAlive[GetNativeCell(1)] = GetNativeCell(2);
	return 0;
}

public any Property_GetHealthPerPlayerAlive(Handle hPlugin, int iNumParams)
{
	return g_bHealthPerPlayerAlive[GetNativeCell(1)];
}

public any Property_SetSpeed(Handle hPlugin, int iNumParams)
{
	g_flSpeed[GetNativeCell(1)] = GetNativeCell(2);
	return 0;
}

public any Property_GetSpeed(Handle hPlugin, int iNumParams)
{
	return g_flSpeed[GetNativeCell(1)];
}

public any Property_SetSpeedMult(Handle hPlugin, int iNumParams)
{
	g_flSpeedMult[GetNativeCell(1)] = GetNativeCell(2);
	return 0;
}

public any Property_GetSpeedMult(Handle hPlugin, int iNumParams)
{
	return g_flSpeedMult[GetNativeCell(1)];
}

public any Property_SetEnvDamageCap(Handle hPlugin, int iNumParams)
{
	g_flEnvDamageCap[GetNativeCell(1)] = GetNativeCell(2);
	return 0;
}

public any Property_GetEnvDamageCap(Handle hPlugin, int iNumParams)
{
	return g_flEnvDamageCap[GetNativeCell(1)];
}

public any Property_SetGlowTime(Handle hPlugin, int iNumParams)
{
	g_flGlowTime[GetNativeCell(1)] = GetNativeCell(2);
	return 0;
}

public any Property_GetGlowTime(Handle hPlugin, int iNumParams)
{
	return g_flGlowTime[GetNativeCell(1)];
}

public any Property_SetRageLastTime(Handle hPlugin, int iNumParams)
{
	g_flRageLastTime[GetNativeCell(1)] = GetNativeCell(2);
	return 0;
}

public any Property_GetRageLastTime(Handle hPlugin, int iNumParams)
{
	return g_flRageLastTime[GetNativeCell(1)];
}

public any Property_SetMaxRagePercentage(Handle hPlugin, int iNumParams)
{
	g_flMaxRagePercentage[GetNativeCell(1)] = GetNativeCell(2);
	return 0;
}

public any Property_GetMaxRagePercentage(Handle hPlugin, int iNumParams)
{
	return g_flMaxRagePercentage[GetNativeCell(1)];
}

public any Property_SetHealthExponential(Handle hPlugin, int iNumParams)
{
	g_flHealthExponential[GetNativeCell(1)] = GetNativeCell(2);
	return 0;
}

public any Property_GetHealthExponential(Handle hPlugin, int iNumParams)
{
	return g_flHealthExponential[GetNativeCell(1)];
}

public any Property_SetHealthMultiplier(Handle hPlugin, int iNumParams)
{
	g_flHealthMultiplier[GetNativeCell(1)] = GetNativeCell(2);
	return 0;
}

public any Property_GetHealthMultiplier(Handle hPlugin, int iNumParams)
{
	return g_flHealthMultiplier[GetNativeCell(1)];
}

public any Property_SetMaxHealth(Handle hPlugin, int iNumParams)
{
	g_iMaxHealth[GetNativeCell(1)] = GetNativeCell(2);
	return 0;
}

public any Property_GetMaxHealth(Handle hPlugin, int iNumParams)
{
	return g_iMaxHealth[GetNativeCell(1)];
}

public any Property_SetBaseHealth(Handle hPlugin, int iNumParams)
{
	g_iBaseHealth[GetNativeCell(1)] = GetNativeCell(2);
	return 0;
}

public any Property_GetBaseHealth(Handle hPlugin, int iNumParams)
{
	return g_iBaseHealth[GetNativeCell(1)];
}

public any Property_SetHealthPerPlayer(Handle hPlugin, int iNumParams)
{
	g_iHealthPerPlayer[GetNativeCell(1)] = GetNativeCell(2);
	return 0;
}

public any Property_GetHealthPerPlayer(Handle hPlugin, int iNumParams)
{
	return g_iHealthPerPlayer[GetNativeCell(1)];
}

public any Property_SetRageDamage(Handle hPlugin, int iNumParams)
{
	g_iRageDamage[GetNativeCell(1)] = GetNativeCell(2);
	return 0;
}

public any Property_GetRageDamage(Handle hPlugin, int iNumParams)
{
	return g_iRageDamage[GetNativeCell(1)];
}

public any Property_SetMaxRageDamage(Handle hPlugin, int iNumParams)
{
	g_iMaxRageDamage[GetNativeCell(1)] = GetNativeCell(2);
	return 0;
}

public any Property_GetMaxRageDamage(Handle hPlugin, int iNumParams)
{
	return g_iMaxRageDamage[GetNativeCell(1)];
}

public any Property_SetClass(Handle hPlugin, int iNumParams)
{
	g_nClass[GetNativeCell(1)] = GetNativeCell(2);
	return 0;
}

public any Property_GetClass(Handle hPlugin, int iNumParams)
{
	return g_nClass[GetNativeCell(1)];
}