static bool g_bValid[TF_MAXPLAYERS+1];
static bool g_bModifiers[TF_MAXPLAYERS+1];
static bool g_bMinion[TF_MAXPLAYERS+1];
static bool g_bSuperRage[TF_MAXPLAYERS+1];
static bool g_bModel[TF_MAXPLAYERS+1];
static bool g_bCanBeHealed[TF_MAXPLAYERS+1];
static bool g_bHealthPerPlayerAliveOnly[TF_MAXPLAYERS+1];
static float g_flSpeed[TF_MAXPLAYERS+1];
static float g_flSpeedMult[TF_MAXPLAYERS+1];
static float g_flEnvDamageCap[TF_MAXPLAYERS+1];
static float g_flWeighDownTimer[TF_MAXPLAYERS+1];
static float g_flWeighDownForce[TF_MAXPLAYERS+1];
static float g_flGlowTime[TF_MAXPLAYERS+1];
static float g_flRageLastTime[TF_MAXPLAYERS+1];
static float g_flMaxRagePercentage[TF_MAXPLAYERS+1];
static float g_flHealthMultiplier[TF_MAXPLAYERS+1];
static int g_iMaxHealth[TF_MAXPLAYERS+1];
static int g_iBaseHealth[TF_MAXPLAYERS+1];
static int g_iHealthPerPlayer[TF_MAXPLAYERS+1];
static int g_iRageDamage[TF_MAXPLAYERS+1];
static int g_iMaxRageDamage[TF_MAXPLAYERS+1];
static TFClassType g_nClass[TF_MAXPLAYERS+1];

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
	CreateNative("SaxtonHaleBase.bCanBeHealed.set", Property_SetCanBeHealed);
	CreateNative("SaxtonHaleBase.bCanBeHealed.get", Property_GetCanBeHealed);
	CreateNative("SaxtonHaleBase.bHealthPerPlayerAliveOnly.set", Property_SetHealthPerPlayerAliveOnly);
	CreateNative("SaxtonHaleBase.bHealthPerPlayerAliveOnly.get", Property_GetHealthPerPlayerAliveOnly);
	CreateNative("SaxtonHaleBase.flSpeed.set", Property_SetSpeed);
	CreateNative("SaxtonHaleBase.flSpeed.get", Property_GetSpeed);
	CreateNative("SaxtonHaleBase.flSpeedMult.set", Property_SetSpeedMult);
	CreateNative("SaxtonHaleBase.flSpeedMult.get", Property_GetSpeedMult);
	CreateNative("SaxtonHaleBase.flEnvDamageCap.set", Property_SetEnvDamageCap);
	CreateNative("SaxtonHaleBase.flEnvDamageCap.get", Property_GetEnvDamageCap);
	CreateNative("SaxtonHaleBase.flWeighDownTimer.set", Property_SetWeighDownTimer);
	CreateNative("SaxtonHaleBase.flWeighDownTimer.get", Property_GetWeighDownTimer);
	CreateNative("SaxtonHaleBase.flWeighDownForce.set", Property_SetWeighDownForce);
	CreateNative("SaxtonHaleBase.flWeighDownForce.get", Property_GetWeighDownForce);
	CreateNative("SaxtonHaleBase.flGlowTime.set", Property_SetGlowTime);
	CreateNative("SaxtonHaleBase.flGlowTime.get", Property_GetGlowTime);
	CreateNative("SaxtonHaleBase.flRageLastTime.set", Property_SetRageLastTime);
	CreateNative("SaxtonHaleBase.flRageLastTime.get", Property_GetRageLastTime);
	CreateNative("SaxtonHaleBase.flMaxRagePercentage.set", Property_SetMaxRagePercentage);
	CreateNative("SaxtonHaleBase.flMaxRagePercentage.get", Property_GetMaxRagePercentage);
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
}

public any Property_GetValid(Handle hPlugin, int iNumParams)
{
	return g_bValid[GetNativeCell(1)];
}

public any Property_SetModifiers(Handle hPlugin, int iNumParams)
{
	g_bModifiers[GetNativeCell(1)] = GetNativeCell(2);
}

public any Property_GetModifiers(Handle hPlugin, int iNumParams)
{
	return g_bModifiers[GetNativeCell(1)];
}

public any Property_SetMinion(Handle hPlugin, int iNumParams)
{
	g_bMinion[GetNativeCell(1)] = GetNativeCell(2);
}

public any Property_GetMinion(Handle hPlugin, int iNumParams)
{
	return g_bMinion[GetNativeCell(1)];
}

public any Property_SetSuperRage(Handle hPlugin, int iNumParams)
{
	g_bSuperRage[GetNativeCell(1)] = GetNativeCell(2);
}

public any Property_GetSuperRage(Handle hPlugin, int iNumParams)
{
	return g_bSuperRage[GetNativeCell(1)];
}

public any Property_SetModel(Handle hPlugin, int iNumParams)
{
	g_bModel[GetNativeCell(1)] = GetNativeCell(2);
}

public any Property_GetModel(Handle hPlugin, int iNumParams)
{
	return g_bModel[GetNativeCell(1)];
}

public any Property_SetCanBeHealed(Handle hPlugin, int iNumParams)
{
	g_bCanBeHealed[GetNativeCell(1)] = GetNativeCell(2);
}

public any Property_GetCanBeHealed(Handle hPlugin, int iNumParams)
{
	return g_bCanBeHealed[GetNativeCell(1)];
}

public any Property_SetHealthPerPlayerAliveOnly(Handle hPlugin, int iNumParams)
{
	g_bHealthPerPlayerAliveOnly[GetNativeCell(1)] = GetNativeCell(2);
}

public any Property_GetHealthPerPlayerAliveOnly(Handle hPlugin, int iNumParams)
{
	return g_bHealthPerPlayerAliveOnly[GetNativeCell(1)];
}

public any Property_SetSpeed(Handle hPlugin, int iNumParams)
{
	g_flSpeed[GetNativeCell(1)] = GetNativeCell(2);
}

public any Property_GetSpeed(Handle hPlugin, int iNumParams)
{
	return g_flSpeed[GetNativeCell(1)];
}

public any Property_SetSpeedMult(Handle hPlugin, int iNumParams)
{
	g_flSpeedMult[GetNativeCell(1)] = GetNativeCell(2);
}

public any Property_GetSpeedMult(Handle hPlugin, int iNumParams)
{
	return g_flSpeedMult[GetNativeCell(1)];
}

public any Property_SetEnvDamageCap(Handle hPlugin, int iNumParams)
{
	g_flEnvDamageCap[GetNativeCell(1)] = GetNativeCell(2);
}

public any Property_GetEnvDamageCap(Handle hPlugin, int iNumParams)
{
	return g_flEnvDamageCap[GetNativeCell(1)];
}

public any Property_SetWeighDownTimer(Handle hPlugin, int iNumParams)
{
	g_flWeighDownTimer[GetNativeCell(1)] = GetNativeCell(2);
}

public any Property_GetWeighDownTimer(Handle hPlugin, int iNumParams)
{
	return g_flWeighDownTimer[GetNativeCell(1)];
}

public any Property_SetWeighDownForce(Handle hPlugin, int iNumParams)
{
	g_flWeighDownForce[GetNativeCell(1)] = GetNativeCell(2);
}

public any Property_GetWeighDownForce(Handle hPlugin, int iNumParams)
{
	return g_flWeighDownForce[GetNativeCell(1)];
}

public any Property_SetGlowTime(Handle hPlugin, int iNumParams)
{
	g_flGlowTime[GetNativeCell(1)] = GetNativeCell(2);
}

public any Property_GetGlowTime(Handle hPlugin, int iNumParams)
{
	return g_flGlowTime[GetNativeCell(1)];
}

public any Property_SetRageLastTime(Handle hPlugin, int iNumParams)
{
	g_flRageLastTime[GetNativeCell(1)] = GetNativeCell(2);
}

public any Property_GetRageLastTime(Handle hPlugin, int iNumParams)
{
	return g_flRageLastTime[GetNativeCell(1)];
}

public any Property_SetMaxRagePercentage(Handle hPlugin, int iNumParams)
{
	g_flMaxRagePercentage[GetNativeCell(1)] = GetNativeCell(2);
}

public any Property_GetMaxRagePercentage(Handle hPlugin, int iNumParams)
{
	return g_flMaxRagePercentage[GetNativeCell(1)];
}

public any Property_SetHealthMultiplier(Handle hPlugin, int iNumParams)
{
	g_flHealthMultiplier[GetNativeCell(1)] = GetNativeCell(2);
}

public any Property_GetHealthMultiplier(Handle hPlugin, int iNumParams)
{
	return g_flHealthMultiplier[GetNativeCell(1)];
}

public any Property_SetMaxHealth(Handle hPlugin, int iNumParams)
{
	g_iMaxHealth[GetNativeCell(1)] = GetNativeCell(2);
}

public any Property_GetMaxHealth(Handle hPlugin, int iNumParams)
{
	return g_iMaxHealth[GetNativeCell(1)];
}

public any Property_SetBaseHealth(Handle hPlugin, int iNumParams)
{
	g_iBaseHealth[GetNativeCell(1)] = GetNativeCell(2);
}

public any Property_GetBaseHealth(Handle hPlugin, int iNumParams)
{
	return g_iBaseHealth[GetNativeCell(1)];
}

public any Property_SetHealthPerPlayer(Handle hPlugin, int iNumParams)
{
	g_iHealthPerPlayer[GetNativeCell(1)] = GetNativeCell(2);
}

public any Property_GetHealthPerPlayer(Handle hPlugin, int iNumParams)
{
	return g_iHealthPerPlayer[GetNativeCell(1)];
}

public any Property_SetRageDamage(Handle hPlugin, int iNumParams)
{
	g_iRageDamage[GetNativeCell(1)] = GetNativeCell(2);
}

public any Property_GetRageDamage(Handle hPlugin, int iNumParams)
{
	return g_iRageDamage[GetNativeCell(1)];
}

public any Property_SetMaxRageDamage(Handle hPlugin, int iNumParams)
{
	g_iMaxRageDamage[GetNativeCell(1)] = GetNativeCell(2);
}

public any Property_GetMaxRageDamage(Handle hPlugin, int iNumParams)
{
	return g_iMaxRageDamage[GetNativeCell(1)];
}

public any Property_SetClass(Handle hPlugin, int iNumParams)
{
	g_nClass[GetNativeCell(1)] = GetNativeCell(2);
}

public any Property_GetClass(Handle hPlugin, int iNumParams)
{
	return g_nClass[GetNativeCell(1)];
}