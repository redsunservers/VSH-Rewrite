static bool g_bModelOverrideEnable[TF_MAXPLAYERS+1];
static int g_iModelOverrideRef[TF_MAXPLAYERS+1][2];
static int g_iModelOverrideSkin[TF_MAXPLAYERS+1];
static float g_flModelOverrideScale[TF_MAXPLAYERS+1];
static char g_sModelOverrideModel[TF_MAXPLAYERS+1][PLATFORM_MAX_PATH];

methodmap CModelOverride < SaxtonHaleBase
{
	property bool bEnable
	{
		public set(bool bVal)
		{
			g_bModelOverrideEnable[this.iClient] = bVal;
			
			int iModel = EntRefToEntIndex(g_iModelOverrideRef[this.iClient][0]);
			if (iModel > MaxClients)
				SetEntityRenderMode(this.iClient, bVal ? RENDER_NORMAL : RENDER_NONE);
			
			iModel = EntRefToEntIndex(g_iModelOverrideRef[this.iClient][1]);
			if (iModel > MaxClients)
				SetEntityRenderMode(this.iClient, bVal ? RENDER_NORMAL : RENDER_NONE);
		}
		public get()
		{
			return g_bModelOverrideEnable[this.iClient];
		}
	}
	
	property int iSkin
	{
		public set(int iVal)
		{
			g_iModelOverrideSkin[this.iClient] = iVal;
			
			int iModel = EntRefToEntIndex(g_iModelOverrideRef[this.iClient][0]);
			if (iModel > MaxClients)
				SetEntProp(iModel, Prop_Send, "m_nSkin", iVal);
			
			iModel = EntRefToEntIndex(g_iModelOverrideRef[this.iClient][1]);
			if (iModel > MaxClients)
				SetEntProp(iModel, Prop_Send, "m_nSkin", iVal);
		}
		public get()
		{
			return g_iModelOverrideSkin[this.iClient];
		}
	}
	
	property float flScale
	{
		public set(float flVal)
		{
			g_flModelOverrideScale[this.iClient] = flVal;
			
			int iModel = EntRefToEntIndex(g_iModelOverrideRef[this.iClient][0]);
			if (iModel > MaxClients)
				DispatchKeyValueFloat(iModel, "modelscale", flVal);
			
			iModel = EntRefToEntIndex(g_iModelOverrideRef[this.iClient][1]);
			if (iModel > MaxClients)
				DispatchKeyValueFloat(iModel, "modelscale", flVal);
		}
		public get()
		{
			return g_flModelOverrideScale[this.iClient];
		}
	}
	
	public CModelOverride(CModelOverride ability)
	{
		ability.bEnable = true;
		ability.iSkin = 0;
		ability.flScale = 1.0;
		
		g_iModelOverrideRef[ability.iClient][0] = 0;
		g_iModelOverrideRef[ability.iClient][1] = 0;
	}
	
	public void SetModel(char[] sModel)
	{
		strcopy(g_sModelOverrideModel[this.iClient], sizeof(g_sModelOverrideModel[]), sModel);
	}
	
	public int CreateModel()
	{
		int iModel = CreateEntityByName("prop_dynamic_override");
		if (iModel > MaxClients)
		{
			SetEntProp(iModel, Prop_Send, "m_CollisionGroup", COLLISION_GROUP_WEAPON);
			SetEntProp(iModel, Prop_Send, "m_fEffects", EF_BONEMERGE|EF_NOSHADOW|EF_BONEMERGE_FASTCULL|EF_PARENT_ANIMATES);
			DispatchKeyValue(iModel, "model", g_sModelOverrideModel[this.iClient]);
			DispatchKeyValueFloat(iModel, "modelscale", this.flScale);
			
			SetEntityRenderMode(iModel, this.bEnable ? RENDER_NORMAL : RENDER_NONE);
			SetEntProp(iModel, Prop_Send, "m_nSkin", this.iSkin);
			SetEntProp(iModel, Prop_Send, "m_hOwnerEntity", this.iClient);
			
			DispatchSpawn(iModel);
			
			return iModel;
		}
		
		return -1;
	}
	
	public void DeleteModel()
	{
		int iModel = EntRefToEntIndex(g_iModelOverrideRef[this.iClient][0]);
		if (iModel > MaxClients)
			AcceptEntityInput(iModel, "Kill");
		
		iModel = EntRefToEntIndex(g_iModelOverrideRef[this.iClient][1]);
		if (iModel > MaxClients)
			AcceptEntityInput(iModel, "Kill");
		
		g_iModelOverrideRef[this.iClient][0] = 0;
		g_iModelOverrideRef[this.iClient][1] = 0;
	}
	
	public void OnSpawn()
	{
		this.DeleteModel();
		
		//We need to create 2 props to make this work. iModel[0] parented to iModel[1] parented to client
		int iModel[2];
		iModel[0] = this.CreateModel();
		iModel[1] = this.CreateModel();
		
		if (!IsValidEdict(iModel[0]) || !IsValidEdict(iModel[1]))
			return;
		
		SetVariantString("!activator");
		AcceptEntityInput(iModel[0], "SetParent", iModel[1]);
		
		SetVariantString("head");
		AcceptEntityInput(iModel[0], "SetParentAttachment");
		
		SetVariantString("!activator");
		AcceptEntityInput(iModel[1], "SetParent", this.iClient);
		
		SetVariantString("head");
		AcceptEntityInput(iModel[1], "SetParentAttachment");
		
		g_iModelOverrideRef[this.iClient][0] = EntIndexToEntRef(iModel[0]);
		g_iModelOverrideRef[this.iClient][1] = EntIndexToEntRef(iModel[1]);
		SetEntityRenderMode(this.iClient, RENDER_NONE);
	}
	
	public void OnDeath()
	{
		this.DeleteModel();
		
		if (!this.bEnable) return;
		
		//Just so we can get nice looking ragdoll
		SetVariantString(g_sModelOverrideModel[this.iClient]);
		AcceptEntityInput(this.iClient, "SetCustomModel");
	}
	
	public void Destroy()
	{
		this.DeleteModel();
		SetEntityRenderMode(this.iClient, RENDER_NORMAL);
	}
}