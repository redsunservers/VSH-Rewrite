#define BOMB_NUKE_PARTICLE	"dooms_nuke_collumn"
#define BOMB_PARTICLE		"ExplosionCore_MidAir"
#define BOMB_NUKE_SOUND 	"misc/doomsday_missile_explosion.wav"

static float g_flBombEndTime[MAXPLAYERS];
static float g_flLastExplosionTime[MAXPLAYERS];

public void Bomb_Create(SaxtonHaleBase boss)
{
	g_flBombEndTime[boss.iClient] = 0.0;
	g_flLastExplosionTime[boss.iClient] = 0.0;
	
	boss.SetPropFloat("Bomb", "BombSpawnInterval", 0.1);
	boss.SetPropFloat("Bomb", "BombSpawnDuration", 5.0);
	boss.SetPropFloat("Bomb", "BombSpawnRadius", 500.0);
	boss.SetPropFloat("Bomb", "BombRadius", 200.0);
	boss.SetPropFloat("Bomb", "BombDamage", 150.0);
	boss.SetPropFloat("Bomb", "NukeRadius", 200.0);
}

public void Bomb_OnRage(SaxtonHaleBase boss)
{
	g_flBombEndTime[boss.iClient] = GetGameTime() + boss.GetPropFloat("Bomb", "BombSpawnDuration");
	FakeClientCommand(boss.iClient, "taunt");
	SetEntityMoveType(boss.iClient, MOVETYPE_NONE);
	
	//Force thirdperson view
	SetVariantInt(1);
	AcceptEntityInput(boss.iClient, "SetForcedTauntCam");
}

public void Bomb_OnThink(SaxtonHaleBase boss)
{
	if (g_flBombEndTime[boss.iClient] == 0.0) return;
	
	float flGameTime = GetGameTime();
	if (flGameTime <= g_flBombEndTime[boss.iClient])
	{
		if (g_flLastExplosionTime[boss.iClient] != 0.0 && g_flLastExplosionTime[boss.iClient]+boss.GetPropFloat("Bomb", "BombSpawnInterval") > flGameTime) return;
		
		g_flLastExplosionTime[boss.iClient] = flGameTime;
		
		float vecExplosionPos[3], vecExplosionOrigin[3];
		GetClientAbsOrigin(boss.iClient, vecExplosionOrigin);
		
		for (int i = 0; i < 2; i++)
		{
			vecExplosionPos = vecExplosionOrigin;
			vecExplosionPos[0] += GetRandomFloat(-boss.GetPropFloat("Bomb", "BombSpawnRadius"), boss.GetPropFloat("Bomb", "BombSpawnRadius"));
			vecExplosionPos[1] += GetRandomFloat(-boss.GetPropFloat("Bomb", "BombSpawnRadius"), boss.GetPropFloat("Bomb", "BombSpawnRadius"));
			vecExplosionPos[2] += GetRandomFloat(-boss.GetPropFloat("Bomb", "BombSpawnRadius"), boss.GetPropFloat("Bomb", "BombSpawnRadius"));
			
			char sSound[255];
			Format(sSound, sizeof(sSound), "weapons/airstrike_small_explosion_0%i.wav", GetRandomInt(1,3));
			TF2_Explode(boss.iClient, vecExplosionPos, boss.GetPropFloat("Bomb", "BombDamage"), boss.GetPropFloat("Bomb", "BombRadius"), BOMB_PARTICLE, sSound);
		}
	}
	else
	{
		if (boss.bSuperRage)
		{
			float vecExplosionOrigin[3];
			GetClientAbsOrigin(boss.iClient, vecExplosionOrigin);
			TF2_Explode(boss.iClient, vecExplosionOrigin, 9999999.0, boss.GetPropFloat("Bomb", "NukeRadius"), BOMB_NUKE_PARTICLE, BOMB_NUKE_SOUND);
			EmitSoundToAll(BOMB_NUKE_SOUND);
		}
		g_flBombEndTime[boss.iClient] = 0.0;
		g_flLastExplosionTime[boss.iClient] = 0.0;
		TF2_RemoveCondition(boss.iClient, TFCond_Taunting);
		SetEntityMoveType(boss.iClient, MOVETYPE_WALK);
		
		//Set view back to first person
		SetVariantInt(0);
		AcceptEntityInput(boss.iClient, "SetForcedTauntCam");
	}
}

public void Bomb_Precache(SaxtonHaleBase boss)
{
	PrecacheSound(BOMB_NUKE_SOUND);
	PrecacheParticleSystem(BOMB_NUKE_PARTICLE);
	PrecacheParticleSystem(BOMB_PARTICLE);
}

