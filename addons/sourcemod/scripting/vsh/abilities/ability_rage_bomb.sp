#define BOMB_NUKE_PARTICLE	"dooms_nuke_collumn"
#define BOMB_PARTICLE		"ExplosionCore_MidAir"
#define BOMB_NUKE_SOUND 	"misc/doomsday_missile_explosion.wav"

static float g_flBombSpawnInterval[TF_MAXPLAYERS+1];
static float g_flBombSpawnDuration[TF_MAXPLAYERS+1];
static float g_flBombSpawnRadius[TF_MAXPLAYERS+1];
static float g_flBombRadius[TF_MAXPLAYERS+1];
static float g_flBombDamage[TF_MAXPLAYERS+1];
static float g_flNukeRadius[TF_MAXPLAYERS+1];
static float g_flBombEndTime[TF_MAXPLAYERS+1];
static float g_flLastExplosionTime[TF_MAXPLAYERS+1];

methodmap CBomb < SaxtonHaleBase
{
	property float flBombSpawnInterval
	{
		public set(float flVal)
		{
			g_flBombSpawnInterval[this.iClient] = flVal;
		}
		public get()
		{
			return g_flBombSpawnInterval[this.iClient];
		}
	}
	
	property float flBombSpawnDuration
	{
		public set (float flVal)
		{
			g_flBombSpawnDuration[this.iClient] = flVal;
		}
		public get()
		{
			return g_flBombSpawnDuration[this.iClient];
		}
	}
	
	property float flBombSpawnRadius
	{
		public set (float flVal)
		{
			g_flBombSpawnRadius[this.iClient] = flVal;
		}
		public get()
		{
			return g_flBombSpawnRadius[this.iClient];
		}
	}
	
	property float flBombRadius
	{
		public set (float flVal)
		{
			g_flBombRadius[this.iClient] = flVal;
		}
		public get()
		{
			return g_flBombRadius[this.iClient];
		}
	}
	
	property float flBombDamage
	{
		public set (float flVal)
		{
			g_flBombDamage[this.iClient] = flVal;
		}
		public get()
		{
			return g_flBombDamage[this.iClient];
		}
	}
	
	property float flNukeRadius
	{
		public set (float flVal)
		{
			g_flNukeRadius[this.iClient] = flVal;
		}
		public get()
		{
			return g_flNukeRadius[this.iClient];
		}
	}
	
	public CBomb(CBomb ability)
	{
		g_flBombSpawnInterval[ability.iClient] = 0.1;
		g_flBombSpawnDuration[ability.iClient] = 5.0;
		g_flBombSpawnRadius[ability.iClient] = 500.0;
		g_flBombRadius[ability.iClient] = 200.0;
		g_flBombDamage[ability.iClient] = 150.0;
		g_flNukeRadius[ability.iClient] = 200.0;
		g_flBombEndTime[ability.iClient] = 0.0;
		g_flLastExplosionTime[ability.iClient] = 0.0;
	}

	public void OnRage()
	{
		g_flBombEndTime[this.iClient] = GetGameTime() + this.flBombSpawnDuration;
		FakeClientCommand(this.iClient, "taunt");
		SetEntityMoveType(this.iClient, MOVETYPE_NONE);
		
		int iFlags = GetCommandFlags("thirdperson");
		SetCommandFlags("thirdperson", iFlags & (~FCVAR_CHEAT));
		ClientCommand(this.iClient, "thirdperson");
		SetCommandFlags("thirdperson", iFlags);
	}
	
	public void OnThink()
	{
		if (g_flBombEndTime[this.iClient] == 0.0) return;
		
		float flGameTime = GetGameTime();
		if (flGameTime <= g_flBombEndTime[this.iClient])
		{
			if (g_flLastExplosionTime[this.iClient] != 0.0 && g_flLastExplosionTime[this.iClient]+this.flBombSpawnInterval > flGameTime) return;
			
			g_flLastExplosionTime[this.iClient] = flGameTime;
			
			float vecExplosionPos[3], vecExplosionOrigin[3];
			GetClientAbsOrigin(this.iClient, vecExplosionOrigin);
			
			for (int i = 0; i < 2; i++)
			{
				vecExplosionPos = vecExplosionOrigin;
				vecExplosionPos[0] += GetRandomFloat(-this.flBombSpawnRadius, this.flBombSpawnRadius);
				vecExplosionPos[1] += GetRandomFloat(-this.flBombSpawnRadius, this.flBombSpawnRadius);
				vecExplosionPos[2] += GetRandomFloat(-this.flBombSpawnRadius, this.flBombSpawnRadius);
				
				char sSound[255];
				Format(sSound, sizeof(sSound), "weapons/airstrike_small_explosion_0%i.wav", GetRandomInt(1,3));
				TF2_Explode(this.iClient, vecExplosionPos, this.flBombDamage, this.flBombRadius, BOMB_PARTICLE, sSound);
			}
		}
		else
		{
			if (this.bSuperRage)
			{
				float vecExplosionOrigin[3];
				GetClientAbsOrigin(this.iClient, vecExplosionOrigin);
				TF2_Explode(this.iClient, vecExplosionOrigin, 9999999.0, this.flNukeRadius, BOMB_NUKE_PARTICLE, BOMB_NUKE_SOUND);
				EmitSoundToAll(BOMB_NUKE_SOUND);
			}
			g_flBombEndTime[this.iClient] = 0.0;
			g_flLastExplosionTime[this.iClient] = 0.0;
			TF2_RemoveCondition(this.iClient, TFCond_Taunting);
			SetEntityMoveType(this.iClient, MOVETYPE_WALK);
			
			int iFlags = GetCommandFlags("firstperson");
			SetCommandFlags("firstperson", iFlags & (~FCVAR_CHEAT));
			ClientCommand(this.iClient, "firstperson");
			SetCommandFlags("firstperson", iFlags);
		}
	}
	
	public static void Precache()
	{
		PrecacheSound(BOMB_NUKE_SOUND);
		PrecacheParticleSystem(BOMB_NUKE_PARTICLE);
		PrecacheParticleSystem(BOMB_PARTICLE);
	}
};