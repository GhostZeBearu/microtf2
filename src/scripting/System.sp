/**
 * MicroTF2 - System.inc
 * 
 * Implements main system
 */

#define TOTAL_GAMEMODES 100
#define TOTAL_SYSMUSIC 6
#define TOTAL_SYSFX_VOCAL_TYPES 2
#define TOTAL_SYSFX_VOCALS 7
#define TOTAL_SYSOVERLAYS 10

#define SYSMUSIC_PREMINIGAME 0
#define SYSMUSIC_BOSSTIME 1
#define SYSMUSIC_SPEEDUP 2
#define SYSMUSIC_GAMEOVER 3
#define SYSMUSIC_FAILURE 4
#define SYSMUSIC_WINNER 5

#define SYSMUSIC_WAITINGFORPLAYERS "stsv/microtf2/sys/waitingforplayers.wav"
#define SYSMUSIC_SPECIALROUND "stsv/microtf2/sys/specialround.mp3"
#define SYSMUSIC_SPECIALROUND_SELECTED "stsv/microtf2/sys/fx/beep.mp3"
#define SYSMUSIC_MAPEND "stsv/microtf2/sys/mapend.mp3"
#define SYSFX_CLOCK "stsv/microtf2/sys/fx/clock.mp3"
#define SYSFX_WINNER "stsv/microtf2/sys/fx/bing.wav"

#define SYSFX_VOCAL_POSITIVE 0
#define SYSFX_VOCAL_NEGATIVE 1

#define SYSMUSIC_MAXSTRINGLENGTH 192

#define OVERLAY_BLANK ""
#define OVERLAY_MINIGAMEBLANK "gemidyne/warioware/overlays/minigame_blank"
#define OVERLAY_WON	 "gemidyne/warioware/overlays/minigame_success"
#define OVERLAY_FAIL "gemidyne/warioware/overlays/minigame_failure"
#define OVERLAY_SPEEDUP "gemidyne/warioware/overlays/system_speedup"
#define OVERLAY_SPEEDDN	"gemidyne/warioware/overlays/system_speeddown"
#define OVERLAY_BOSS "gemidyne/warioware/overlays/system_bossevent"
#define OVERLAY_GAMEOVER "gemidyne/warioware/overlays/system_gameover"
#define OVERLAY_WELCOME "stsv/microtf2/overlays/waitingforplayers"
#define OVERLAY_SPECIALROUND "gemidyne/warioware/overlays/system_specialround"

char SystemNames[TOTAL_GAMEMODES+1][32];
char SystemMusic[TOTAL_GAMEMODES+1][TOTAL_SYSMUSIC+1][SYSMUSIC_MAXSTRINGLENGTH];
float SystemMusicLength[TOTAL_GAMEMODES+1][TOTAL_SYSMUSIC+1];
char SystemVocal[TOTAL_SYSFX_VOCAL_TYPES+1][TOTAL_SYSFX_VOCALS+1][SYSMUSIC_MAXSTRINGLENGTH];

int GamemodeID = 0;
int MaxGamemodesSelectable = 0;

Handle HudSync_Score;
Handle HudSync_Special;
Handle HudSync_Round;
Handle HudSync_Caption;

stock void InitializeSystem()
{
	LogMessage("Initializing System...");
	
	InitializeForwards();
	LoadOffsets();
	InitializeCommands();
	InitializeSpecialRounds();

	SystemVocal[SYSFX_VOCAL_POSITIVE][0] = "microtf2/vo/mtf2_response01.mp3";
	SystemVocal[SYSFX_VOCAL_POSITIVE][1] = "microtf2/vo/mtf2_response07.mp3";
	SystemVocal[SYSFX_VOCAL_POSITIVE][2] = "microtf2/vo/mtf2_response08.mp3";
	SystemVocal[SYSFX_VOCAL_POSITIVE][3] = "microtf2/vo/mtf2_response09.mp3";
	SystemVocal[SYSFX_VOCAL_POSITIVE][4] = "microtf2/vo/mtf2_response10.mp3";
	SystemVocal[SYSFX_VOCAL_POSITIVE][5] = "microtf2/vo/mtf2_response11.mp3";
	SystemVocal[SYSFX_VOCAL_POSITIVE][6] = "microtf2/vo/mtf2_response12.mp3";

	SystemVocal[SYSFX_VOCAL_NEGATIVE][0] = "microtf2/vo/mtf2_response02.mp3";
	SystemVocal[SYSFX_VOCAL_NEGATIVE][1] = "microtf2/vo/mtf2_response03.mp3";
	SystemVocal[SYSFX_VOCAL_NEGATIVE][2] = "microtf2/vo/mtf2_response04.mp3";
	SystemVocal[SYSFX_VOCAL_NEGATIVE][3] = "microtf2/vo/mtf2_response05.mp3";
	SystemVocal[SYSFX_VOCAL_NEGATIVE][4] = "microtf2/vo/mtf2_response06.mp3";

	HudSync_Score = CreateHudSynchronizer();
	HudSync_Special = CreateHudSynchronizer();
	HudSync_Round = CreateHudSynchronizer();
	HudSync_Caption = CreateHudSynchronizer();

	char gamemodeManifestPath[128];
	BuildPath(Path_SM, gamemodeManifestPath, sizeof(gamemodeManifestPath), "data/microtf2/gamemodes.txt");

	Handle kv = CreateKeyValues("Gamemodes");
	FileToKeyValues(kv, gamemodeManifestPath);
 
	if (KvGotoFirstSubKey(kv))
	{
		do
		{
			int gamemodeID = GetGamemodeIDFromSectionName(kv);

			LoadSysMusicType(gamemodeID, SYSMUSIC_PREMINIGAME, kv, "SysMusic_PreMinigame");
			LoadSysMusicType(gamemodeID, SYSMUSIC_BOSSTIME, kv, "SysMusic_BossTime");
			LoadSysMusicType(gamemodeID, SYSMUSIC_SPEEDUP, kv, "SysMusic_SpeedUp");
			LoadSysMusicType(gamemodeID, SYSMUSIC_GAMEOVER, kv, "SysMusic_GameOver");

			// These 2 cannot have the different lengths; they're played at the same time
			KvGetString(kv, "SysMusic_Failure", SystemMusic[gamemodeID][SYSMUSIC_FAILURE], SYSMUSIC_MAXSTRINGLENGTH);
			KvGetString(kv, "SysMusic_Winner", SystemMusic[gamemodeID][SYSMUSIC_WINNER], SYSMUSIC_MAXSTRINGLENGTH);

			KvGetString(kv, "FriendlyName", SystemNames[gamemodeID], 32);

			if (KvGetNum(kv, "Selectable", 0) == 1)
			{
				// Selectable Gamemodes must be at the start of the Gamemodes.txt file
				MaxGamemodesSelectable++;
			}

			LogMessage("Loaded gamemode %d - %s", gamemodeID, SystemNames[gamemodeID]);
		}
		while (KvGotoNextKey(kv));
	}
 
	CloseHandle(kv);

	AddToForward(GlobalForward_OnMapStart, INVALID_HANDLE, System_OnMapStart);
	InitializeMinigames();
	InitialisePrecacheSystem();
	InitialiseSecuritySystem();

	InitialiseWeapons();
}

public void System_OnMapStart()
{
	MinigameID = 0;
	BossgameID = 0;
	PreviousMinigameID = 0;
	PreviousBossgameID = 0;
	SpecialRoundID = 0;
	ScoreAmount = 1;
	MinigamesPlayed = 0;
	BossGameThreshold = 20;
	MaxRounds = GetConVarInt(ConVar_MTF2MaxRounds);
	RoundsPlayed = 0;
	SpeedLevel = 1.0;

	IsMinigameActive = false;
	IsMinigameEnding = false;
	IsMapEnding = false;
	IsBonusRound = false;
	IsBlockingTaunts = true;
	IsBlockingDeathCommands = true;
	IsBlockingDamage = true;
	IsOnlyBlockingDamageByPlayers = false;

	// Preload (Precache and Add To Downloads Table) all Sounds needed for every gamemode
	char buffer[192];

	for (int g = 0; g < TOTAL_GAMEMODES; g++)
	{
		for (int i = 0; i < TOTAL_SYSMUSIC; i++)
		{
			buffer = SystemMusic[g][i];

			if (strlen(buffer) > 0)
			{
				PreloadSound(SystemMusic[g][i]);
			}
		}
	}

	for (int t = 0; t < TOTAL_SYSFX_VOCAL_TYPES; t++)
	{
		for (int i = 0; i < TOTAL_SYSFX_VOCALS; i++)
		{
			buffer = SystemVocal[t][i];

			if (strlen(buffer) > 0)
			{
				PreloadSound(SystemVocal[t][i]);
			}
		}
	}

	PreloadSound(SYSMUSIC_WAITINGFORPLAYERS);
	PreloadSound(SYSMUSIC_SPECIALROUND);
	PreloadSound(SYSMUSIC_SPECIALROUND_SELECTED);
	PreloadSound(SYSMUSIC_MAPEND);
	PreloadSound(SYSFX_CLOCK);
	PreloadSound(SYSFX_WINNER);

	PrecacheSound("ui/system_message_alert.wav", true);
	PrecacheSound("vo/announcer_ends_10sec.wav", true);
	PrecacheSound("vo/announcer_ends_5sec.wav", true);
	PrecacheSound("vo/announcer_ends_4sec.wav", true);
	PrecacheSound("vo/announcer_ends_3sec.wav", true);
	PrecacheSound("vo/announcer_ends_2sec.wav", true);
	PrecacheSound("vo/announcer_ends_1sec.wav", true);
	PrecacheSound("vo/announcer_success.wav", true);

	PrecacheMaterial(OVERLAY_MINIGAMEBLANK);
	PrecacheMaterial(OVERLAY_WON);
	PrecacheMaterial(OVERLAY_FAIL);
	PrecacheMaterial(OVERLAY_SPEEDUP);
	PrecacheMaterial(OVERLAY_SPEEDDN);
	PrecacheMaterial(OVERLAY_BOSS);
	PrecacheMaterial(OVERLAY_GAMEOVER);
	PrecacheMaterial(OVERLAY_WELCOME);
	PrecacheMaterial(OVERLAY_SPECIALROUND);
}

stock int GetGamemodeIDFromSectionName(Handle kv)
{
	char buffer[16];

	KvGetSectionName(kv, buffer, sizeof(buffer));

	return StringToInt(buffer);
}

stock void LoadSysMusicType(int gamemodeID, int musicType, Handle kv, const char[] key)
{
	Handle sndfile = INVALID_HANDLE;

	KvGetString(kv, key, SystemMusic[gamemodeID][musicType], SYSMUSIC_MAXSTRINGLENGTH);
	sndfile = OpenSoundFile(SystemMusic[gamemodeID][musicType]);

	if (sndfile == INVALID_HANDLE)
	{
		LogError("Failed to get sound length for \"%s\" - %s", key, SystemMusic[gamemodeID][musicType]);
	}
	else
	{
		SystemMusicLength[gamemodeID][musicType] = GetSoundLengthFloat(sndfile);
		CloseHandle(sndfile);
	}
}

stock void LoadOffsets()
{
	Offset_Collision = TryFindSendPropInfo("CBaseEntity", "m_CollisionGroup");
	Offset_WeaponBaseClip1 = TryFindSendPropInfo("CTFWeaponBase", "m_iClip1");
	Offset_PlayerActiveWeapon = TryFindSendPropInfo("CTFPlayer", "m_hActiveWeapon");
	Offset_PlayerAmmo = FindSendPropInfo("CTFPlayer", "m_iAmmo");
}

stock void PrecacheMaterial(const char[] material)
{
	char path[64];

	Format(path, sizeof(path), "materials/%s", material);

	PrecacheGeneric(path, true);
}

stock int TryFindSendPropInfo(const char[] cls, const char[] prop)
{
	int offset = FindSendPropInfo(cls, prop);

	if (offset <= 0)
	{
		char message[64];

		Format(message, sizeof(message), "Unable to find %s prop on %s.", prop, cls);

		SetFailState(message);
	}

	return offset;
}