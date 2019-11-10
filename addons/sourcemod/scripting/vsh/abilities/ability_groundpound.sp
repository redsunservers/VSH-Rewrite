#define IMPACT_SOUND	"player/taunt_yeti_land.wav"
#define IMPACT_PARTICLE	"hammer_impact_button"

static float g_flImpactRadius[TF_MAXPLAYERS + 1];
static int g_iImpactDamage[TF_MAXPLAYERS + 1];

methodmap CGroundPound < SaxtonHaleBase
{
	property float flImpactRadius
	{
		public set(float flVal)
		{
			g_flImpactRadius[this.iClient] = flVal;
		}
		public get()
		{
			return g_flImpactRadius[this.iClient];
		}
	}
	
	property int iImpactDamage
	{
		public set(int iVal)
		{
			g_iImpactDamage[this.iClient] = iVal;
		}
		public get()
		{
			return g_iImpactDamage[this.iClient];
		}
	}
	
	public CGroundPound(CGroundPound ability)
	{
		ability.flImpactRadius = 100.0;
		ability.iImpactDamage = 100;
	}
	
	public Action OnTakeDamage(int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
	{
		if (!(damagetype & DMG_FALL))
			return Plugin_Continue;
		
		float flOrigin[3];
		GetEntPropVector(this.iClient, Prop_Data, "m_vecOrigin", flOrigin);
		EmitAmbientSound(IMPACT_SOUND, flOrigin, _, SNDLEVEL_SCREAMING);
		TF2_Shake(flOrigin, 10.0, 100.0, 1.0, 0.5);
		CreateParticle(IMPACT_PARTICLE, flOrigin);
		
		// TODO: This does not work yet
		float flImpulseDir[3] =  { -90.0, 0.0, 0.0 }; // launch player upwards
		float flRadius[3] =  { 200.0, 200.0, 200.0 };
		TF2_Impulse(flOrigin, flRadius, flImpulseDir, 200.0);
		
		return Plugin_Continue;
	}
	
	public static void Precache()
	{
		PrecacheSound(IMPACT_SOUND);
	}
};

stock void CreateParticle(char[] particle, float pos[3])
{
	int tblidx = FindStringTable("ParticleEffectNames");
	char tmp[256];
	int count = GetStringTableNumStrings(tblidx);
	int stridx = INVALID_STRING_INDEX;
	for (int i = 0; i < count; i++)
	{
		ReadStringTable(tblidx, i, tmp, sizeof(tmp));
		if (StrEqual(tmp, particle, false))
		{
			stridx = i;
			break;
		}
	}
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsValidEntity(i))continue;
		if (!IsClientInGame(i))continue;
		TE_Start("TFParticleEffect");
		TE_WriteFloat("m_vecOrigin[0]", pos[0]);
		TE_WriteFloat("m_vecOrigin[1]", pos[1]);
		TE_WriteFloat("m_vecOrigin[2]", pos[2]);
		TE_WriteNum("m_iParticleSystemIndex", stridx);
		TE_WriteNum("entindex", -1);
		TE_WriteNum("m_iAttachType", 2);
		TE_SendToClient(i, 0.0);
	}
}

stock void TF2_Shake(float flOrigin[3], float flAmplitude, float flRadius, float flDuration, float flFrequency)
{
	int iShake = CreateEntityByName("env_shake");
	if (iShake != -1)
	{
		DispatchKeyValueVector(iShake, "origin", flOrigin);
		DispatchKeyValueFloat(iShake, "amplitude", flAmplitude);
		DispatchKeyValueFloat(iShake, "radius", flRadius);
		DispatchKeyValueFloat(iShake, "duration", flDuration);
		DispatchKeyValueFloat(iShake, "frequency", flFrequency);
		
		DispatchSpawn(iShake);
		AcceptEntityInput(iShake, "StartShake");
	}
}

stock void TF2_Impulse(const float flOrigin[3], const float flRadius[3], const float flImpulseDir[3], const float flForce)
{
	int iImpulse = CreateEntityByName("trigger_apply_impulse");
	if (iImpulse != -1)
	{
		DispatchKeyValueVector(iImpulse, "impulse_dir", flImpulseDir);
		DispatchSpawn(iImpulse);
		
		SetEntPropFloat(iImpulse, Prop_Data, "m_flForce", flForce);
		TeleportEntity(iImpulse, flOrigin, NULL_VECTOR, NULL_VECTOR);
		
		float flMinBounds[3];
		float flMaxBounds[3];
		for (int i = 0; i < sizeof(flRadius); i++)
		{
			flMinBounds[i] = i != sizeof(flRadius) - 1 ? flRadius[i] / 2 : 0.0;
			flMinBounds[i] = i != sizeof(flRadius) - 1 ? flRadius[i] / 2 : flRadius[i];
		}
		SetEntPropVector(iImpulse, Prop_Send, "m_vecMins", flMinBounds);
		SetEntPropVector(iImpulse, Prop_Send, "m_vecMaxs", flMaxBounds);
		SetEntProp(iImpulse, Prop_Send, "m_nSolidType", 2);
		ActivateEntity(iImpulse);
		AcceptEntityInput(iImpulse, "ApplyImpulse");
	}
} 