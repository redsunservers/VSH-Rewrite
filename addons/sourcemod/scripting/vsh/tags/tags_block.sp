methodmap TagsBlock < ArrayList
{
	public TagsBlock()
	{
		return view_as<TagsBlock>(new ArrayList());
	}
	
	public bool IsBlocked(int iClient)
	{
		if (this == null)
			return false;
		
		int iLength = this.Length;
		for (int i = 0; i < iLength; i++)
		{
			int iCoreId = this.Get(i);
			if (TagsCore_IsAllowed(iClient, iCoreId))	//Does client have id, and not filtered
				return true;
		}
		
		return false;
	}
}