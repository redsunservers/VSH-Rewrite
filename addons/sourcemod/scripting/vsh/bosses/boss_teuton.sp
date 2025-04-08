//static int g_iTeutonCape;
static int g_iTeutonHelmet;

public void Teuton_Create(SaxtonHaleBase boss)
{
	boss.CreateClass("WallClimb");
	boss.SetPropFloat("WallClimb", "MaxHeight", 600.0);
	boss.SetPropFloat("WallClimb", "HorizontalSpeedMult", 1.0);
	boss.SetPropFloat("WallClimb", "MaxHorizontalVelocity", 400.0);

	boss.iBaseHealth = 1;
	boss.nClass = TFClass_DemoMan;
	boss.flSpeed = 340.0;
	boss.flSpeedMult = 0.0;
	boss.iMaxRageDamage = -1;
	boss.bMinion = true;
}

public void Teuton_GetModel(SaxtonHaleBase boss, char[] sModel, int length)
{
	strcopy(sModel, length, DEMO_ROBOT_MODEL);
}

public void Teuton_Precache(SaxtonHaleBase boss)
{
	PrecacheModel(DEMO_ROBOT_MODEL);

	//g_iTeutonCape = PrecacheModel("models/workshop/player/items/soldier/bak_caped_crusader/bak_caped_crusader.mdl");
	g_iTeutonHelmet = PrecacheModel("models/workshop/player/items/soldier/dec17_brass_bucket/dec17_brass_bucket.mdl");
}

public bool Teuton_IsBossHidden(SaxtonHaleBase boss)
{
	return true;
}

public void Teuton_OnSpawn(SaxtonHaleBase boss)
{
	int iItem = boss.CallFunction("CreateWeapon", 132, "tf_weapon_sword", 5, TFQual_Unique, "1 ; 0.4615 ; 5 ; 1.3 ; 412 ; 0.0 ; 775 ; 0.0 ; 820 ; 1");
	if (iItem > MaxClients)
		SetEntPropEnt(boss.iClient, Prop_Send, "m_hActiveWeapon", iItem);
	
	//iItem = boss.CallFunction("CreateWeapon", 30727, "tf_wearable", 5, TFQual_Unique, "");
	//if (iItem > MaxClients)
	//	SetEntProp(iItem, Prop_Send, "m_nModelIndexOverrides", g_iTeutonCape);

	iItem = boss.CallFunction("CreateWeapon", 30969, "tf_wearable", 5, TFQual_Unique, "");
	if (iItem > MaxClients)
		SetEntProp(iItem, Prop_Send, "m_nModelIndexOverrides", g_iTeutonHelmet);
	
	SetEntPropFloat(boss.iClient, Prop_Send, "m_flModelScale", 0.6);
	SetEntityCollisionGroup(boss.iClient, COLLISION_GROUP_DEBRIS);
	TF2_AddCondition(boss.iClient, TFCond_DisguisedAsDispenser);	// Makes Sentries ignore the player
}

public void Teuton_OnThink(SaxtonHaleBase boss)
{
}

public Action Teuton_OnVoiceCommand(SaxtonHaleBase boss, char sCmd1[8], char sCmd2[8])
{
	return Plugin_Handled;
}

public Action Teuton_CanHealTarget(SaxtonHaleBase boss, int iTarget, bool &bResult)
{
	if (SaxtonHale_IsValidBoss(iTarget))
	{
		bResult = false;
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}

public void Teuton_Destroy(SaxtonHaleBase boss)
{
	SetEntPropFloat(boss.iClient, Prop_Send, "m_flModelScale", 1.0);
	SetEntityCollisionGroup(boss.iClient, COLLISION_GROUP_PLAYER);
}
