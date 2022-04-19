static StringMap g_mFuncHook[2];	//PrivateForward of hooks ([2] from amount of SaxtonHaleHookMode)

void FuncHook_Init()
{
	for (int i = 0; i < sizeof(g_mFuncHook); i++)
		g_mFuncHook[i] = new StringMap();
}

void FuncHook_Add(const char[] sName, Handle hPlugin, Function callback, SaxtonHaleHookMode hookType)	// Function as SaxtonHaleHookCallback
{
	PrivateForward hPrivateForward;
	if (!g_mFuncHook[hookType].GetValue(sName, hPrivateForward))	//Get existing private forward
	{
		//If does not exist, create new private forward
		hPrivateForward = new PrivateForward(ET_Hook, Param_Cell, Param_CellByRef);
		g_mFuncHook[hookType].SetValue(sName, hPrivateForward);
	}
	
	hPrivateForward.AddFunction(hPlugin, callback);
}

void FuncHook_Remove(const char[] sName, Handle hPlugin, Function callback, SaxtonHaleHookMode hookType)	// Function as SaxtonHaleHookCallback
{
	PrivateForward hPrivateForward;
	if (!g_mFuncHook[hookType].GetValue(sName, hPrivateForward))	//Get private forward to remove
		return;	//No hook functions to unhook
	
	hPrivateForward.RemoveFunction(hPlugin, callback);
	
	if (hPrivateForward.FunctionCount == 0)
	{
		//No more hooks in forward
		delete hPrivateForward;
		g_mFuncHook[hookType].Remove(sName);
	}
}

bool FuncHook_Call(SaxtonHaleBase boss, FuncStack funcStack, SaxtonHaleHookMode nHookMode)
{
	PrivateForward hPrivateForward;
	if (!g_mFuncHook[nHookMode].GetValue(funcStack.sFunction, hPrivateForward))
		return true;
	
	if (hPrivateForward.FunctionCount == 0)
	{
		//One of plugin unloaded, caused function count 0. Don't need to keep handle now
		delete hPrivateForward;
		g_mFuncHook[nHookMode].Remove(funcStack.sFunction);
		return true;
	}
	
	FuncStack_Set(funcStack);	//Set current stack for hooks to get new params
	
	FuncStack funcClone;
	FuncStack_Clone(funcClone);	//Clone with new, old handle values
	
	//Start call
	Call_StartForward(hPrivateForward);
	Call_PushCell(boss);
	
	any returnValue = funcStack.returnValue;
	Call_PushCellRef(returnValue);
	
	Action action;
	int iError = Call_Finish(action);
	if (iError != SP_ERROR_NONE)
		ThrowError("Unable to call hook forward (Function %s, error code %d)", funcStack.sFunction, iError);
	
	//If new action is stop, set return and stop chain
	if (action == Plugin_Stop)
	{
		funcClone.Delete();
		FuncStack_Get(funcStack);
		funcStack.returnValue = returnValue;
		funcStack.action = Plugin_Stop;
		return false;
	}
	
	//If new action is changed and current action not handled, get new params and set new return value
	else if (action >= Plugin_Changed && funcStack.action != Plugin_Handled)
	{
		funcClone.Delete();
		FuncStack_Get(funcStack);
		funcStack.returnValue = returnValue;
		funcStack.action = action;
	}
	
	//Prevent any changed handles
	else
	{
		funcStack.Delete();
		funcStack = funcClone;
	}
	
	return true;
}