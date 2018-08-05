/**
 * MicroTF2 - Minigame 19
 *
 * Change Class!
 */

public Minigame19_EntryPoint()
{
	AddToForward(GlobalForward_OnPlayerClassChange, INVALID_HANDLE, Minigame19_OnPlayerClassChange);
	AddToForward(GlobalForward_OnMinigameSelectedPre, INVALID_HANDLE, Minigame19_OnMinigameSelectedPre);
}

public bool:Minigame19_OnCheck()
{
#if defined NEW_HUD
	// While using the new hud, TF2 will block class changes through the UI. We can
	return false;
#else
	return true;
#endif
}

public Minigame19_OnMinigameSelectedPre()
{
	if (MinigameID == 19)
	{
		IsBlockingDeaths = false;
	}
}

public Minigame19_OnPlayerClassChange(client)
{
	if (IsMinigameActive && MinigameID == 19 && IsClientValid(client) && IsPlayerParticipant[client])
	{
		ClientWonMinigame(client);
	}
}