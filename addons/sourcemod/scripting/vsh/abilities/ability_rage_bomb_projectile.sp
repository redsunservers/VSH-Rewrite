#define BOMBPROJECTILE_MODEL	"models/props_lakeside_event/bomb_temp.mdl"

static float g_flBombProjectileNext[MAXPLAYERS];
static float g_flBombProjectileEnd[MAXPLAYERS];

	
public void BombProjectile_Create(SaxtonHaleBase boss)
{
	g_flBombProjectileNext[boss.iClient] = 0.0;
	g_flBombProjectileEnd[boss.iClient] = 0.0;
	
	boss.SetPropFloat("BombProjectile", "Rate", 0.16);
	boss.SetPropFloat("BombProjectile", "Duration", 6.0);
	boss.SetPropFloat("BombProjectile", "Radius", 100.0);
	boss.SetPropFloat("BombProjectile", "Damage", 100.0);
	boss.SetPropFloat("BombProjectile", "MaxDistance", 600.0);
	boss.SetPropFloat("BombProjectile", "MinHeight", 500.0);
	boss.SetPropFloat("BombProjectile", "MaxHeight", 1000.0);
	
	PrecacheModel(BOMBPROJECTILE_MODEL);
}

public void BombProjectile_OnRage(SaxtonHaleBase boss)
{
	g_flBombProjectileNext[boss.iClient] = GetGameTime();
	g_flBombProjectileEnd[boss.iClient] = GetGameTime() + boss.GetPropFloat("BombProjectile", "Duration");
}

public void BombProjectile_OnThink(SaxtonHaleBase boss)
{
	if (g_flBombProjectileEnd[boss.iClient] == 0.0)
		return;
	
	float flGameTime = GetGameTime();
	if (flGameTime <= g_flBombProjectileEnd[boss.iClient])
	{
		if (g_flBombProjectileNext[boss.iClient] > flGameTime) return;
	
		if (boss.bSuperRage)
			g_flBombProjectileNext[boss.iClient] = flGameTime + (boss.GetPropFloat("BombProjectile", "Rate") / 2.0);
		else
			g_flBombProjectileNext[boss.iClient] = flGameTime + boss.GetPropFloat("BombProjectile", "Rate");
		
		float vecOrigin[3], vecVelocity[3], vecAngleVelocity[3];
		GetClientAbsOrigin(boss.iClient, vecOrigin);
		vecOrigin[2] += 42.0;
		
		int iBomb = CreateEntityByName("tf_weaponbase_merasmus_grenade");
		if (iBomb > MaxClients)
		{
			//Create random velocity, but keep it upwards
			for (int i = 0; i < 2; i++)
				vecVelocity[i] = GetRandomFloat(-boss.GetPropFloat("BombProjectile", "MaxDistance"), boss.GetPropFloat("BombProjectile", "MaxDistance"));
			
			vecVelocity[2] = GetRandomFloat(boss.GetPropFloat("BombProjectile", "MinHeight"), boss.GetPropFloat("BombProjectile", "MaxHeight"));
			
			//Create random angle velocity
			for (int i = 0; i < 3; i++)
				vecAngleVelocity[i] = GetRandomFloat(0.0, 360.0);
			
			DispatchKeyValueVector(iBomb, "origin", vecOrigin);
			SetEntityModel(iBomb, BOMBPROJECTILE_MODEL);
			SetEntProp(iBomb, Prop_Send, "m_iTeamNum", GetClientTeam(boss.iClient));
			SetEntPropEnt(iBomb, Prop_Send, "m_hThrower", boss.iClient);
			SetEntPropEnt(iBomb, Prop_Send, "m_hOwnerEntity", boss.iClient);
			
			DispatchSpawn(iBomb);
			
			TeleportEntity(iBomb, NULL_VECTOR, vecAngleVelocity, vecVelocity);
			
			SetEntPropFloat(iBomb, Prop_Send, "m_flDamage", boss.GetPropFloat("BombProjectile", "Damage"));
			SDK_SetFuseTime(iBomb, GetGameTime() + 2.0);	//Fuse time
			SetEntProp(iBomb, Prop_Send, "m_CollisionGroup", 24);
		}
	}
	else
	{
		g_flBombProjectileEnd[boss.iClient] = 0.0;
	}
}

public void BombProjectile_Precache(SaxtonHaleBase boss)
{
	PrecacheModel(BOMBPROJECTILE_MODEL);
}
