#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "0.6-survivor-voices-colors"

// HL2/L4D2 damage flags fallback.
#if !defined DMG_BURN
    #define DMG_BURN 8
#endif

#if !defined DMG_ENERGYBEAM
    #define DMG_ENERGYBEAM 1024
#endif

#if !defined SNDLEVEL_NONE
    #define SNDLEVEL_NONE 0
#endif


#define TEAM_SURVIVOR 2
#define TEAM_INFECTED 3
#define ZC_TANK 8

#define MAX_ENTITY_SAFE 2049

#define NUM_SURVIVORS 8
#define MAX_VOICE_LINES 10

enum
{
    SURV_NICK = 0,
    SURV_ROCHELLE,
    SURV_COACH,
    SURV_ELLIS,
    SURV_BILL,
    SURV_ZOEY,
    SURV_FRANCIS,
    SURV_LOUIS,
    SURV_UNKNOWN = -1
};

public Plugin myinfo =
{
    name = "[L4D2] Homelander Eye Laser",
    author = "OpenAI / Alexey",
    description = "Hold-to-fire survivor eye laser with damage, ignite, beam and sounds.",
    version = PLUGIN_VERSION,
    url = ""
};

ConVar g_cvEnable;
ConVar g_cvAdminOnly;
ConVar g_cvEllisOnly;

ConVar g_cvRange;
ConVar g_cvTick;
ConVar g_cvCooldown;

ConVar g_cvDamageCommon;
ConVar g_cvDamageSI;
ConVar g_cvDamageTank;
ConVar g_cvDamageWitch;
ConVar g_cvDamageSurvivor;
ConVar g_cvFriendlyFire;

ConVar g_cvIgnite;
ConVar g_cvIgniteTime;
ConVar g_cvIgniteInterval;

ConVar g_cvBeamModel;
ConVar g_cvBeamWidth;
ConVar g_cvBeamEndWidth;
ConVar g_cvBeamLife;
ConVar g_cvBeamAlpha;
ConVar g_cvBeamRed;
ConVar g_cvBeamGreen;
ConVar g_cvBeamBlue;
ConVar g_cvSurvivorBeamColors;
ConVar g_cvSurvivorColor[NUM_SURVIVORS];
ConVar g_cvBeamOffsetSide;
ConVar g_cvBeamOffsetUp;
ConVar g_cvBeamOffsetForward;

ConVar g_cvHitSparks;
ConVar g_cvHitSparksInterval;

ConVar g_cvDownloadSounds;
ConVar g_cvSoundStart;
ConVar g_cvSoundLoop;
ConVar g_cvSoundStop;
ConVar g_cvSoundVolume;
ConVar g_cvSoundEmitMode;
ConVar g_cvSoundLevel;
ConVar g_cvLoopInterval;

ConVar g_cvVoiceEnable;
ConVar g_cvVoiceVolume;
ConVar g_cvVoiceEmitMode;
ConVar g_cvVoiceLevel;
ConVar g_cvVoiceDownload;
ConVar g_cvVoiceCooldown;
ConVar g_cvVoice[NUM_SURVIVORS][MAX_VOICE_LINES];

ConVar g_cvNotifyCooldown;

bool g_bFiring[MAXPLAYERS + 1];
float g_fNextReady[MAXPLAYERS + 1];
float g_fNextLoopSound[MAXPLAYERS + 1];
float g_fNextVoice[MAXPLAYERS + 1];
float g_fNextSparks[MAXPLAYERS + 1];

float g_fNextIgnite[MAX_ENTITY_SAFE];

Handle g_hThinkTimer = null;
int g_iBeamModel = -1;

public void OnPluginStart()
{
    g_cvEnable = CreateConVar("l4d_homelaser_enable", "1", "Enable Homelander eye laser.");
    g_cvAdminOnly = CreateConVar("l4d_homelaser_admin_only", "0", "1=root admins only, 0=everyone.");
    g_cvEllisOnly = CreateConVar("l4d_homelaser_ellis_only", "0", "1=only Ellis can use, 0=all survivors can use.");

    g_cvRange = CreateConVar("l4d_homelaser_range", "2200.0", "Laser max range.");
    g_cvTick = CreateConVar("l4d_homelaser_tick", "0.07", "Laser think interval. Do not set too low.");
    g_cvCooldown = CreateConVar("l4d_homelaser_cooldown", "3.0", "Cooldown after releasing laser.");

    g_cvDamageCommon = CreateConVar("l4d_homelaser_damage_common", "100.0", "Damage per tick to common infected.");
    g_cvDamageSI = CreateConVar("l4d_homelaser_damage_si", "300.0", "Damage per tick to special infected.");
    g_cvDamageTank = CreateConVar("l4d_homelaser_damage_tank", "500.0", "Damage per tick to Tank.");
    g_cvDamageWitch = CreateConVar("l4d_homelaser_damage_witch", "100.0", "Damage per tick to Witch.");
    g_cvDamageSurvivor = CreateConVar("l4d_homelaser_damage_survivor", "25.0", "Damage per tick to survivors when friendly fire is enabled.");
    g_cvFriendlyFire = CreateConVar("l4d_homelaser_friendlyfire", "0", "1=laser can hurt survivors, 0=no survivor damage.");

    g_cvIgnite = CreateConVar("l4d_homelaser_ignite", "1", "1=ignite hit targets.");
    g_cvIgniteTime = CreateConVar("l4d_homelaser_ignite_time", "2.0", "Ignite duration on hit targets.");
    g_cvIgniteInterval = CreateConVar("l4d_homelaser_ignite_interval", "0.35", "Minimum time between IgniteEntity calls per entity.");

    g_cvBeamModel = CreateConVar("l4d_homelaser_beam_model", "materials/sprites/laserbeam.vmt", "Beam material.");
    g_cvBeamWidth = CreateConVar("l4d_homelaser_beam_width", "2.5", "Beam start width.");
    g_cvBeamEndWidth = CreateConVar("l4d_homelaser_beam_end_width", "0.8", "Beam end width.");
    g_cvBeamLife = CreateConVar("l4d_homelaser_beam_life", "0.09", "Beam temp entity life.");
    g_cvBeamAlpha = CreateConVar("l4d_homelaser_beam_alpha", "255", "Beam alpha 0-255.");
    g_cvBeamRed = CreateConVar("l4d_homelaser_beam_red", "255", "Fallback beam red color 0-255 when survivor colors are disabled or unknown.");
    g_cvBeamGreen = CreateConVar("l4d_homelaser_beam_green", "0", "Fallback beam green color 0-255 when survivor colors are disabled or unknown.");
    g_cvBeamBlue = CreateConVar("l4d_homelaser_beam_blue", "0", "Fallback beam blue color 0-255 when survivor colors are disabled or unknown.");
    g_cvSurvivorBeamColors = CreateConVar("l4d_homelaser_survivor_beam_colors", "1", "1=use per-survivor laser colors, 0=use global RGB cvars.");
    g_cvSurvivorColor[SURV_NICK] = CreateConVar("l4d_homelaser_color_nick", "0 80 255", "Nick laser RGB color.");
    g_cvSurvivorColor[SURV_ROCHELLE] = CreateConVar("l4d_homelaser_color_rochelle", "255 40 170", "Rochelle laser RGB color.");
    g_cvSurvivorColor[SURV_COACH] = CreateConVar("l4d_homelaser_color_coach", "180 0 255", "Coach laser RGB color.");
    g_cvSurvivorColor[SURV_ELLIS] = CreateConVar("l4d_homelaser_color_ellis", "255 0 0", "Ellis laser RGB color.");
    g_cvSurvivorColor[SURV_BILL] = CreateConVar("l4d_homelaser_color_bill", "0 255 70", "Bill laser RGB color.");
    g_cvSurvivorColor[SURV_ZOEY] = CreateConVar("l4d_homelaser_color_zoey", "255 0 0", "Zoey laser RGB color.");
    g_cvSurvivorColor[SURV_FRANCIS] = CreateConVar("l4d_homelaser_color_francis", "255 220 0", "Francis laser RGB color.");
    g_cvSurvivorColor[SURV_LOUIS] = CreateConVar("l4d_homelaser_color_louis", "255 255 255", "Louis laser RGB color.");
    g_cvBeamOffsetSide = CreateConVar("l4d_homelaser_eye_side_offset", "2.7", "Side offset for two eye beams.");
    g_cvBeamOffsetUp = CreateConVar("l4d_homelaser_eye_up_offset", "-1.0", "Up offset for eye beams.");
    g_cvBeamOffsetForward = CreateConVar("l4d_homelaser_eye_forward_offset", "4.0", "Forward offset for beam origin.");

    g_cvHitSparks = CreateConVar("l4d_homelaser_hit_sparks", "1", "1=small spark effect at hit point.");
    g_cvHitSparksInterval = CreateConVar("l4d_homelaser_hit_sparks_interval", "0.12", "Minimum time between spark effects per shooter.");

    g_cvDownloadSounds = CreateConVar("l4d_homelaser_download_sounds", "1", "1=add sound/homelaser files to downloads table.");
    g_cvSoundStart = CreateConVar("l4d_homelaser_sound_start", "homelaser/laser_start.mp3", "Sound played when laser starts. Empty disables.");
    g_cvSoundLoop = CreateConVar("l4d_homelaser_sound_loop", "homelaser/laser_loop.mp3", "Loop/repeated sound while firing. Empty disables.");
    g_cvSoundStop = CreateConVar("l4d_homelaser_sound_stop", "homelaser/laser_stop.mp3", "Sound played when laser stops. Empty disables.");
    g_cvSoundVolume = CreateConVar("l4d_homelaser_sound_volume", "1.0", "Laser sound volume. Source engine usually clamps above 1.0.");
    g_cvSoundEmitMode = CreateConVar("l4d_homelaser_sound_emit_mode", "1", "Laser sound mode: 0=3D for everyone, 1=shooter local + others 3D, 2=local/no attenuation for everyone, 3=3D for everyone + shooter local boost.");
    g_cvSoundLevel = CreateConVar("l4d_homelaser_sound_level", "100", "3D laser sound level for other players. 90=voice loud, 100=gunfire-ish, 110+=very far.");
    g_cvLoopInterval = CreateConVar("l4d_homelaser_loop_interval", "0.85", "How often to replay laser_loop.wav while firing.");

    g_cvVoiceEnable = CreateConVar("l4d_homelaser_voice_enable", "1", "1=play survivor battlecry on laser start.");
    g_cvVoiceVolume = CreateConVar("l4d_homelaser_voice_volume", "1.0", "Battlecry volume. Source engine usually clamps above 1.0.");
    g_cvVoiceEmitMode = CreateConVar("l4d_homelaser_voice_emit_mode", "1", "Voice mode: 0=3D for everyone, 1=shooter local + others 3D, 2=local/no attenuation for everyone, 3=3D for everyone + shooter local boost.");
    g_cvVoiceLevel = CreateConVar("l4d_homelaser_voice_level", "90", "3D voice sound level for other players. 80=normal, 90=loud voice, 100=very loud.");
    g_cvVoiceDownload = CreateConVar("l4d_homelaser_voice_download", "0", "1=add configured voice files to downloads table. Use this only for custom voice files.");
    g_cvVoiceCooldown = CreateConVar("l4d_homelaser_voice_cooldown", "4.0", "Voice cooldown per player.");

    g_cvVoice[SURV_NICK][0] = CreateConVar("l4d_homelaser_voice_nick_1", "player/survivor/voice/gambler/battlecry01.wav", "Nick voice line 1.");
    g_cvVoice[SURV_NICK][1] = CreateConVar("l4d_homelaser_voice_nick_2", "player/survivor/voice/gambler/battlecry02.wav", "Nick voice line 2.");
    g_cvVoice[SURV_NICK][2] = CreateConVar("l4d_homelaser_voice_nick_3", "player/survivor/voice/gambler/battlecry03.wav", "Nick voice line 3.");
    g_cvVoice[SURV_NICK][3] = CreateConVar("l4d_homelaser_voice_nick_4", "player/survivor/voice/gambler/battlecry04.wav", "Nick voice line 4.");

    g_cvVoice[SURV_ROCHELLE][0] = CreateConVar("l4d_homelaser_voice_rochelle_1", "player/survivor/voice/producer/battlecry01.wav", "Rochelle voice line 1.");
    g_cvVoice[SURV_ROCHELLE][1] = CreateConVar("l4d_homelaser_voice_rochelle_2", "player/survivor/voice/producer/battlecry02.wav", "Rochelle voice line 2.");

    g_cvVoice[SURV_COACH][0] = CreateConVar("l4d_homelaser_voice_coach_1", "player/survivor/voice/coach/battlecry01.wav", "Coach voice line 1.");
    g_cvVoice[SURV_COACH][1] = CreateConVar("l4d_homelaser_voice_coach_2", "player/survivor/voice/coach/battlecry02.wav", "Coach voice line 2.");
    g_cvVoice[SURV_COACH][2] = CreateConVar("l4d_homelaser_voice_coach_3", "player/survivor/voice/coach/battlecry03.wav", "Coach voice line 3.");
    g_cvVoice[SURV_COACH][3] = CreateConVar("l4d_homelaser_voice_coach_4", "player/survivor/voice/coach/battlecry04.wav", "Coach voice line 4.");
    g_cvVoice[SURV_COACH][4] = CreateConVar("l4d_homelaser_voice_coach_5", "player/survivor/voice/coach/battlecry05.wav", "Coach voice line 5.");
    g_cvVoice[SURV_COACH][5] = CreateConVar("l4d_homelaser_voice_coach_6", "player/survivor/voice/coach/battlecry06.wav", "Coach voice line 6.");
    g_cvVoice[SURV_COACH][6] = CreateConVar("l4d_homelaser_voice_coach_7", "player/survivor/voice/coach/battlecry07.wav", "Coach voice line 7.");
    g_cvVoice[SURV_COACH][7] = CreateConVar("l4d_homelaser_voice_coach_8", "player/survivor/voice/coach/battlecry08.wav", "Coach voice line 8.");
    g_cvVoice[SURV_COACH][8] = CreateConVar("l4d_homelaser_voice_coach_9", "player/survivor/voice/coach/battlecry09.wav", "Coach voice line 9.");

    g_cvVoice[SURV_ELLIS][0] = CreateConVar("l4d_homelaser_voice_ellis_1", "player/survivor/voice/mechanic/battlecry01.wav", "Ellis voice line 1.");
    g_cvVoice[SURV_ELLIS][1] = CreateConVar("l4d_homelaser_voice_ellis_2", "player/survivor/voice/mechanic/battlecry02.wav", "Ellis voice line 2.");
    g_cvVoice[SURV_ELLIS][2] = CreateConVar("l4d_homelaser_voice_ellis_3", "player/survivor/voice/mechanic/battlecry03.wav", "Ellis voice line 3.");
    g_cvVoice[SURV_ELLIS][3] = CreateConVar("l4d_homelaser_voice_ellis_4", "player/survivor/voice/mechanic/battlecry04.wav", "Ellis voice line 4.");

    g_cvVoice[SURV_BILL][0] = CreateConVar("l4d_homelaser_voice_bill_1", "player/survivor/voice/namvet/taunt01.wav", "Bill voice line 1.");
    g_cvVoice[SURV_BILL][1] = CreateConVar("l4d_homelaser_voice_bill_2", "player/survivor/voice/namvet/taunt02.wav", "Bill voice line 2.");
    g_cvVoice[SURV_BILL][2] = CreateConVar("l4d_homelaser_voice_bill_3", "player/survivor/voice/namvet/taunt07.wav", "Bill voice line 3.");
    g_cvVoice[SURV_BILL][3] = CreateConVar("l4d_homelaser_voice_bill_4", "player/survivor/voice/namvet/taunt08.wav", "Bill voice line 4.");
    g_cvVoice[SURV_BILL][4] = CreateConVar("l4d_homelaser_voice_bill_5", "player/survivor/voice/namvet/taunt09.wav", "Bill voice line 5.");

    g_cvVoice[SURV_ZOEY][0] = CreateConVar("l4d_homelaser_voice_zoey_1", "player/survivor/voice/teengirl/taunt39.wav", "Zoey voice line 1.");
    g_cvVoice[SURV_ZOEY][1] = CreateConVar("l4d_homelaser_voice_zoey_2", "player/survivor/voice/teengirl/taunt13.wav", "Zoey voice line 2.");
    g_cvVoice[SURV_ZOEY][2] = CreateConVar("l4d_homelaser_voice_zoey_3", "player/survivor/voice/teengirl/taunt18.wav", "Zoey voice line 3.");
    g_cvVoice[SURV_ZOEY][3] = CreateConVar("l4d_homelaser_voice_zoey_4", "player/survivor/voice/teengirl/taunt19.wav", "Zoey voice line 4.");
    g_cvVoice[SURV_ZOEY][4] = CreateConVar("l4d_homelaser_voice_zoey_5", "player/survivor/voice/teengirl/taunt20.wav", "Zoey voice line 5.");
    g_cvVoice[SURV_ZOEY][5] = CreateConVar("l4d_homelaser_voice_zoey_6", "player/survivor/voice/teengirl/taunt21.wav", "Zoey voice line 6.");
    g_cvVoice[SURV_ZOEY][6] = CreateConVar("l4d_homelaser_voice_zoey_7", "player/survivor/voice/teengirl/taunt34.wav", "Zoey voice line 7.");
    g_cvVoice[SURV_ZOEY][7] = CreateConVar("l4d_homelaser_voice_zoey_8", "player/survivor/voice/teengirl/taunt35.wav", "Zoey voice line 8.");

    g_cvVoice[SURV_FRANCIS][0] = CreateConVar("l4d_homelaser_voice_francis_1", "player/survivor/voice/biker/taunt01.wav", "Francis voice line 1.");
    g_cvVoice[SURV_FRANCIS][1] = CreateConVar("l4d_homelaser_voice_francis_2", "player/survivor/voice/biker/taunt02.wav", "Francis voice line 2.");
    g_cvVoice[SURV_FRANCIS][2] = CreateConVar("l4d_homelaser_voice_francis_3", "player/survivor/voice/biker/taunt03.wav", "Francis voice line 3.");
    g_cvVoice[SURV_FRANCIS][3] = CreateConVar("l4d_homelaser_voice_francis_4", "player/survivor/voice/biker/taunt04.wav", "Francis voice line 4.");
    g_cvVoice[SURV_FRANCIS][4] = CreateConVar("l4d_homelaser_voice_francis_5", "player/survivor/voice/biker/taunt05.wav", "Francis voice line 5.");
    g_cvVoice[SURV_FRANCIS][5] = CreateConVar("l4d_homelaser_voice_francis_6", "player/survivor/voice/biker/taunt06.wav", "Francis voice line 6.");
    g_cvVoice[SURV_FRANCIS][6] = CreateConVar("l4d_homelaser_voice_francis_7", "player/survivor/voice/biker/taunt07.wav", "Francis voice line 7.");
    g_cvVoice[SURV_FRANCIS][7] = CreateConVar("l4d_homelaser_voice_francis_8", "player/survivor/voice/biker/taunt08.wav", "Francis voice line 8.");
    g_cvVoice[SURV_FRANCIS][8] = CreateConVar("l4d_homelaser_voice_francis_9", "player/survivor/voice/biker/taunt09.wav", "Francis voice line 9.");
    g_cvVoice[SURV_FRANCIS][9] = CreateConVar("l4d_homelaser_voice_francis_10", "player/survivor/voice/biker/taunt10.wav", "Francis voice line 10.");

    g_cvVoice[SURV_LOUIS][0] = CreateConVar("l4d_homelaser_voice_louis_1", "player/survivor/voice/manager/taunt01.wav", "Louis voice line 1.");
    g_cvVoice[SURV_LOUIS][1] = CreateConVar("l4d_homelaser_voice_louis_2", "player/survivor/voice/manager/taunt02.wav", "Louis voice line 2.");
    g_cvVoice[SURV_LOUIS][2] = CreateConVar("l4d_homelaser_voice_louis_3", "player/survivor/voice/manager/taunt03.wav", "Louis voice line 3.");
    g_cvVoice[SURV_LOUIS][3] = CreateConVar("l4d_homelaser_voice_louis_4", "player/survivor/voice/manager/taunt04.wav", "Louis voice line 4.");
    g_cvVoice[SURV_LOUIS][4] = CreateConVar("l4d_homelaser_voice_louis_5", "player/survivor/voice/manager/taunt05.wav", "Louis voice line 5.");
    g_cvVoice[SURV_LOUIS][5] = CreateConVar("l4d_homelaser_voice_louis_6", "player/survivor/voice/manager/taunt06.wav", "Louis voice line 6.");
    g_cvVoice[SURV_LOUIS][6] = CreateConVar("l4d_homelaser_voice_louis_7", "player/survivor/voice/manager/taunt07.wav", "Louis voice line 7.");
    g_cvVoice[SURV_LOUIS][7] = CreateConVar("l4d_homelaser_voice_louis_8", "player/survivor/voice/manager/taunt08.wav", "Louis voice line 8.");
    g_cvVoice[SURV_LOUIS][8] = CreateConVar("l4d_homelaser_voice_louis_9", "player/survivor/voice/manager/taunt09.wav", "Louis voice line 9.");
    g_cvVoice[SURV_LOUIS][9] = CreateConVar("l4d_homelaser_voice_louis_10", "player/survivor/voice/manager/taunt10.wav", "Louis voice line 10.");

    g_cvNotifyCooldown = CreateConVar("l4d_homelaser_notify_cooldown", "0", "1=print cooldown messages to shooter.");

    RegConsoleCmd("+homelaser", Command_StartLaser);
    RegConsoleCmd("-homelaser", Command_StopLaser);
    RegConsoleCmd("sm_hlaser", Command_ToggleLaser);
    RegConsoleCmd("sm_homelaser", Command_ToggleLaser);
    RegConsoleCmd("sm_laser", Command_ToggleLaser);
    RegConsoleCmd("sm_hlaser_testsound", Command_TestLaserSound);
    RegConsoleCmd("sm_hlaser_soundinfo", Command_SoundInfo);

    HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
    HookEvent("player_team", Event_PlayerTeam, EventHookMode_Post);
    HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
    HookEvent("map_transition", Event_RoundEnd, EventHookMode_PostNoCopy);
    HookEvent("finale_win", Event_RoundEnd, EventHookMode_PostNoCopy);

    AutoExecConfig(true, "l4d2_homelander_laser");
}

public void OnMapStart()
{
    CacheAssets();

    for (int i = 0; i < MAX_ENTITY_SAFE; i++)
    {
        g_fNextIgnite[i] = 0.0;
    }
}

public void OnClientDisconnect(int client)
{
    StopLaser(client, false, false);
    g_fNextReady[client] = 0.0;
    g_fNextLoopSound[client] = 0.0;
    g_fNextVoice[client] = 0.0;
    g_fNextSparks[client] = 0.0;
}

public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (client > 0)
    {
        StopLaser(client, true, false);
    }

    return Plugin_Continue;
}

public Action Event_PlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (client > 0)
    {
        StopLaser(client, true, false);
    }

    return Plugin_Continue;
}

public Action Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
    for (int client = 1; client <= MaxClients; client++)
    {
        StopLaser(client, false, false);
    }

    return Plugin_Continue;
}

public Action Command_StartLaser(int client, int args)
{
    if (client <= 0)
    {
        return Plugin_Handled;
    }

    TryStartLaser(client);
    return Plugin_Handled;
}

public Action Command_StopLaser(int client, int args)
{
    if (client <= 0)
    {
        return Plugin_Handled;
    }

    StopLaser(client, true, true);
    return Plugin_Handled;
}

public Action Command_ToggleLaser(int client, int args)
{
    if (client <= 0)
    {
        return Plugin_Handled;
    }

    if (g_bFiring[client])
    {
        StopLaser(client, true, true);
    }
    else
    {
        TryStartLaser(client);
    }

    return Plugin_Handled;
}

void TryStartLaser(int client)
{
    if (!CanUseLaser(client))
    {
        return;
    }

    float now = GetGameTime();
    if (now < g_fNextReady[client])
    {
        if (g_cvNotifyCooldown.BoolValue)
        {
            PrintToChat(client, "[Laser] Cooldown: %.1f sec", g_fNextReady[client] - now);
        }
        return;
    }

    if (g_bFiring[client])
    {
        return;
    }

    g_bFiring[client] = true;
    g_fNextLoopSound[client] = 0.0;
    g_fNextSparks[client] = 0.0;

    PlayConfiguredSound(g_cvSoundStart, client);
    PlayStartVoice(client);

    EnsureThinkTimer();
}

void StopLaser(int client, bool playStopSound, bool applyCooldown)
{
    if (client <= 0 || client > MaxClients)
    {
        return;
    }

    if (!g_bFiring[client])
    {
        return;
    }

    g_bFiring[client] = false;

    if (playStopSound && IsClientInGame(client))
    {
        StopLoopSound(client);
        PlayConfiguredSound(g_cvSoundStop, client);
    }

    if (applyCooldown)
    {
        g_fNextReady[client] = GetGameTime() + g_cvCooldown.FloatValue;
    }
}

bool CanUseLaser(int client)
{
    if (!g_cvEnable.BoolValue)
    {
        return false;
    }

    if (!IsClientInGame(client) || !IsPlayerAlive(client))
    {
        return false;
    }

    if (GetClientTeam(client) != TEAM_SURVIVOR)
    {
        return false;
    }

    if (g_cvAdminOnly.BoolValue && !CheckCommandAccess(client, "homelaser_access", ADMFLAG_ROOT, true))
    {
        return false;
    }

    if (g_cvEllisOnly.BoolValue && GetSurvivorId(client) != SURV_ELLIS)
    {
        return false;
    }

    return true;
}

void EnsureThinkTimer()
{
    if (g_hThinkTimer != null)
    {
        return;
    }

    float interval = g_cvTick.FloatValue;
    if (interval < 0.03)
    {
        interval = 0.03;
    }

    g_hThinkTimer = CreateTimer(interval, Timer_LaserThink, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_LaserThink(Handle timer)
{
    bool any = false;

    for (int client = 1; client <= MaxClients; client++)
    {
        if (!g_bFiring[client])
        {
            continue;
        }

        if (!CanUseLaser(client))
        {
            StopLaser(client, true, true);
            continue;
        }

        any = true;
        ProcessLaserTick(client);
    }

    if (!any)
    {
        g_hThinkTimer = null;
        return Plugin_Stop;
    }

    return Plugin_Continue;
}

void ProcessLaserTick(int client)
{
    float start[3], angles[3], fwdVector[3], right[3], up[3], end[3], hit[3];
    GetClientEyePosition(client, start);
    GetClientEyeAngles(client, angles);

    GetAngleVectors(angles, fwdVector, right, up);

    float range = g_cvRange.FloatValue;
    end[0] = start[0] + fwdVector[0] * range;
    end[1] = start[1] + fwdVector[1] * range;
    end[2] = start[2] + fwdVector[2] * range;

    int hitEnt = -1;
    Handle trace = TR_TraceRayFilterEx(start, end, MASK_SHOT, RayType_EndPoint, TraceFilter_NoSelf, client);
    if (TR_DidHit(trace))
    {
        TR_GetEndPosition(hit, trace);
        hitEnt = TR_GetEntityIndex(trace);
    }
    else
    {
        hit[0] = end[0];
        hit[1] = end[1];
        hit[2] = end[2];
    }
    delete trace;

    DrawEyeBeams(client, start, hit, fwdVector, right, up);
    DamageHitEntity(client, hitEnt);
    PlayLoopSoundIfNeeded(client);
    SparksIfNeeded(client, hit);
}

public bool TraceFilter_NoSelf(int entity, int contentsMask, any data)
{
    int client = data;

    if (entity == client)
    {
        return false;
    }

    return true;
}

void DrawEyeBeams(int client, const float eye[3], const float hit[3], const float fwdVector[3], const float right[3], const float up[3])
{
    if (g_iBeamModel < 0)
    {
        return;
    }

    float side = g_cvBeamOffsetSide.FloatValue;
    float upOffset = g_cvBeamOffsetUp.FloatValue;
    float forwardOffset = g_cvBeamOffsetForward.FloatValue;

    float leftEye[3], rightEye[3];

    BuildEyePoint(eye, fwdVector, right, up, -side, upOffset, forwardOffset, leftEye);
    BuildEyePoint(eye, fwdVector, right, up, side, upOffset, forwardOffset, rightEye);

    int alpha = g_cvBeamAlpha.IntValue;
    if (alpha < 0) alpha = 0;
    if (alpha > 255) alpha = 255;

    int color[4];
    GetBeamColorForClient(client, color, alpha);

    float life = g_cvBeamLife.FloatValue;
    if (life < 0.03) life = 0.03;

    float width = g_cvBeamWidth.FloatValue;
    float endWidth = g_cvBeamEndWidth.FloatValue;

    TE_SetupBeamPoints(leftEye, hit, g_iBeamModel, 0, 0, 0, life, width, endWidth, 0, 0.0, color, 0);
    TE_SendToAll();

    TE_SetupBeamPoints(rightEye, hit, g_iBeamModel, 0, 0, 0, life, width, endWidth, 0, 0.0, color, 0);
    TE_SendToAll();
}

void BuildEyePoint(const float eye[3], const float fwdVector[3], const float right[3], const float up[3], float side, float upOffset, float forwardOffset, float output[3])
{
    output[0] = eye[0] + right[0] * side + up[0] * upOffset + fwdVector[0] * forwardOffset;
    output[1] = eye[1] + right[1] * side + up[1] * upOffset + fwdVector[1] * forwardOffset;
    output[2] = eye[2] + right[2] * side + up[2] * upOffset + fwdVector[2] * forwardOffset;
}

void DamageHitEntity(int attacker, int victim)
{
    if (victim <= 0)
    {
        return;
    }

    if (!IsValidEdict(victim) || !IsValidEntity(victim))
    {
        return;
    }

    float damage = GetLaserDamageForVictim(attacker, victim);
    if (damage <= 0.0)
    {
        return;
    }

    SDKHooks_TakeDamage(victim, attacker, attacker, damage, DMG_ENERGYBEAM | DMG_BURN);

    if (g_cvIgnite.BoolValue)
    {
        IgniteLaserTarget(victim);
    }
}

float GetLaserDamageForVictim(int attacker, int victim)
{
    if (victim >= 1 && victim <= MaxClients)
    {
        if (!IsClientInGame(victim) || !IsPlayerAlive(victim))
        {
            return 0.0;
        }

        int team = GetClientTeam(victim);
        if (team == TEAM_INFECTED)
        {
            int zclass = GetEntProp(victim, Prop_Send, "m_zombieClass");
            if (zclass == ZC_TANK)
            {
                return g_cvDamageTank.FloatValue;
            }

            return g_cvDamageSI.FloatValue;
        }

        if (team == TEAM_SURVIVOR)
        {
            if (victim == attacker)
            {
                return 0.0;
            }

            if (!g_cvFriendlyFire.BoolValue)
            {
                return 0.0;
            }

            return g_cvDamageSurvivor.FloatValue;
        }

        return 0.0;
    }

    char classname[64];
    GetEdictClassname(victim, classname, sizeof(classname));

    if (StrEqual(classname, "infected", false))
    {
        return g_cvDamageCommon.FloatValue;
    }

    if (StrEqual(classname, "witch", false))
    {
        return g_cvDamageWitch.FloatValue;
    }

    return 0.0;
}

void IgniteLaserTarget(int entity)
{
    if (entity <= 0 || entity >= MAX_ENTITY_SAFE)
    {
        return;
    }

    float now = GetGameTime();
    if (now < g_fNextIgnite[entity])
    {
        return;
    }

    g_fNextIgnite[entity] = now + g_cvIgniteInterval.FloatValue;
    IgniteEntity(entity, g_cvIgniteTime.FloatValue);
}

void SparksIfNeeded(int client, const float hit[3])
{
    if (!g_cvHitSparks.BoolValue)
    {
        return;
    }

    float now = GetGameTime();
    if (now < g_fNextSparks[client])
    {
        return;
    }

    g_fNextSparks[client] = now + g_cvHitSparksInterval.FloatValue;

    float dir[3];
    dir[0] = 0.0;
    dir[1] = 0.0;
    dir[2] = 1.0;

    TE_SetupSparks(hit, dir, 1, 1);
    TE_SendToAll();
}


public Action Command_TestLaserSound(int client, int args)
{
    if (client <= 0 || !IsClientInGame(client))
    {
        ReplyToCommand(client, "[HLaser] Run this command in-game: sm_hlaser_testsound");
        return Plugin_Handled;
    }

    char startSound[PLATFORM_MAX_PATH];
    char loopSound[PLATFORM_MAX_PATH];
    char stopSound[PLATFORM_MAX_PATH];
    g_cvSoundStart.GetString(startSound, sizeof(startSound));
    g_cvSoundLoop.GetString(loopSound, sizeof(loopSound));
    g_cvSoundStop.GetString(stopSound, sizeof(stopSound));

    ReplyToCommand(client, "[HLaser] Testing laser sounds locally. start='%s' loop='%s' stop='%s'", startSound, loopSound, stopSound);
    ReplyToCommand(client, "[HLaser] If you hear voice but not these sounds, check file download/path/format. For 3D sounds, export WAV as MONO, 44100 Hz, Signed 16-bit PCM.");

    PlayConfiguredSound(g_cvSoundStart, client);
    CreateTimer(1.0, Timer_TestLoopSound, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
    CreateTimer(2.1, Timer_TestStopSound, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
    return Plugin_Handled;
}

public Action Timer_TestLoopSound(Handle timer, any userid)
{
    int client = GetClientOfUserId(userid);
    if (client > 0 && IsClientInGame(client))
    {
        char sound[PLATFORM_MAX_PATH];
        g_cvSoundLoop.GetString(sound, sizeof(sound));
        if (sound[0] != '\0')
        {
            EmitLoudSound(sound, client, SNDCHAN_STATIC, g_cvSoundVolume.FloatValue, g_cvSoundEmitMode.IntValue, g_cvSoundLevel.IntValue);
        }
    }
    return Plugin_Stop;
}

public Action Timer_TestStopSound(Handle timer, any userid)
{
    int client = GetClientOfUserId(userid);
    if (client > 0 && IsClientInGame(client))
    {
        PlayConfiguredSound(g_cvSoundStop, client);
    }
    return Plugin_Stop;
}

public Action Command_SoundInfo(int client, int args)
{
    char startSound[PLATFORM_MAX_PATH];
    char loopSound[PLATFORM_MAX_PATH];
    char stopSound[PLATFORM_MAX_PATH];
    g_cvSoundStart.GetString(startSound, sizeof(startSound));
    g_cvSoundLoop.GetString(loopSound, sizeof(loopSound));
    g_cvSoundStop.GetString(stopSound, sizeof(stopSound));

    ReplyToCommand(client, "[HLaser] sound_start: %s", startSound);
    ReplyToCommand(client, "[HLaser] sound_loop : %s", loopSound);
    ReplyToCommand(client, "[HLaser] sound_stop : %s", stopSound);
    ReplyToCommand(client, "[HLaser] Server files must be under: left4dead2/sound/homelaser/");
    ReplyToCommand(client, "[HLaser] Client should have downloaded them under: left4dead2/download/sound/homelaser/");
    ReplyToCommand(client, "[HLaser] Client console test: play homelaser/laser_loop_long.mp3");
    return Plugin_Handled;
}

void PlayLoopSoundIfNeeded(int client)
{
    char sound[PLATFORM_MAX_PATH];
    g_cvSoundLoop.GetString(sound, sizeof(sound));
    if (sound[0] == '\0')
    {
        return;
    }

    float now = GetGameTime();
    if (now < g_fNextLoopSound[client])
    {
        return;
    }

    g_fNextLoopSound[client] = now + g_cvLoopInterval.FloatValue;
    EmitLoudSound(sound, client, SNDCHAN_STATIC, g_cvSoundVolume.FloatValue, g_cvSoundEmitMode.IntValue, g_cvSoundLevel.IntValue);
}

void StopLoopSound(int client)
{
    char sound[PLATFORM_MAX_PATH];
    g_cvSoundLoop.GetString(sound, sizeof(sound));
    if (sound[0] == '\0')
    {
        return;
    }

    StopSound(client, SNDCHAN_STATIC, sound);

    for (int target = 1; target <= MaxClients; target++)
    {
        if (IsClientInGame(target) && !IsFakeClient(target))
        {
            StopSound(target, SNDCHAN_STATIC, sound);
        }
    }
}

void PlayConfiguredSound(ConVar cvar, int client)
{
    char sound[PLATFORM_MAX_PATH];
    cvar.GetString(sound, sizeof(sound));
    if (sound[0] == '\0')
    {
        return;
    }

    EmitLoudSound(sound, client, SNDCHAN_STATIC, g_cvSoundVolume.FloatValue, g_cvSoundEmitMode.IntValue, g_cvSoundLevel.IntValue);
}

void EmitLoudSound(const char[] sound, int sourceClient, int channel, float volume, int mode, int soundLevel)
{
    if (sound[0] == '\0')
    {
        return;
    }

    if (sourceClient <= 0 || sourceClient > MaxClients || !IsClientInGame(sourceClient))
    {
        return;
    }

    if (volume <= 0.0)
    {
        return;
    }

    if (volume > 1.0)
    {
        volume = 1.0;
    }

    if (mode == 1)
    {
        int level = soundLevel;
        if (level <= 0)
        {
            level = 90;
        }

        for (int target = 1; target <= MaxClients; target++)
        {
            if (!IsClientInGame(target) || IsFakeClient(target))
            {
                continue;
            }

            if (target == sourceClient)
            {
                // The shooter hears their own laser clearly, with no distance attenuation.
                EmitSoundToClient(target, sound, sourceClient, channel, SNDLEVEL_NONE, SND_NOFLAGS, volume, SNDPITCH_NORMAL);
            }
            else
            {
                // Everyone else hears it as a normal positional sound coming from the shooter.
                EmitSoundToClient(target, sound, sourceClient, channel, level, SND_NOFLAGS, volume, SNDPITCH_NORMAL);
            }
        }
        return;
    }

    if (mode == 2)
    {
        for (int target = 1; target <= MaxClients; target++)
        {
            if (!IsClientInGame(target) || IsFakeClient(target))
            {
                continue;
            }

            // Debug/loud mode: every player hears the sound locally without attenuation.
            EmitSoundToClient(target, sound, target, channel, SNDLEVEL_NONE, SND_NOFLAGS, volume, SNDPITCH_NORMAL);
        }
        return;
    }

    if (mode == 3)
    {
        int level = soundLevel;
        if (level <= 0)
        {
            level = 90;
        }

        EmitSoundToAll(sound, sourceClient, channel, level, SND_NOFLAGS, volume, SNDPITCH_NORMAL);
        EmitSoundToClient(sourceClient, sound, sourceClient, channel, SNDLEVEL_NONE, SND_NOFLAGS, volume, SNDPITCH_NORMAL);
        return;
    }

    int level = soundLevel;
    if (level <= 0)
    {
        level = 90;
    }

    EmitSoundToAll(sound, sourceClient, channel, level, SND_NOFLAGS, volume, SNDPITCH_NORMAL);
}

void PlayStartVoice(int client)
{
    if (!g_cvVoiceEnable.BoolValue)
    {
        return;
    }

    int survivor = GetSurvivorId(client);
    if (survivor < 0 || survivor >= NUM_SURVIVORS)
    {
        return;
    }

    float now = GetGameTime();
    if (now < g_fNextVoice[client])
    {
        return;
    }

    char sounds[MAX_VOICE_LINES][PLATFORM_MAX_PATH];
    int count = 0;

    for (int i = 0; i < MAX_VOICE_LINES; i++)
    {
        if (g_cvVoice[survivor][i] == null)
        {
            continue;
        }

        g_cvVoice[survivor][i].GetString(sounds[count], sizeof(sounds[]));
        if (sounds[count][0] != '\0')
        {
            count++;
        }
    }

    if (count <= 0)
    {
        return;
    }

    int pick = GetRandomInt(0, count - 1);
    EmitLoudSound(sounds[pick], client, SNDCHAN_VOICE, g_cvVoiceVolume.FloatValue, g_cvVoiceEmitMode.IntValue, g_cvVoiceLevel.IntValue);

    g_fNextVoice[client] = now + g_cvVoiceCooldown.FloatValue;
}

void GetBeamColorForClient(int client, int color[4], int alpha)
{
    color[3] = alpha;

    if (g_cvSurvivorBeamColors.BoolValue)
    {
        int survivor = GetSurvivorId(client);
        if (survivor >= 0 && survivor < NUM_SURVIVORS && g_cvSurvivorColor[survivor] != null)
        {
            char buffer[64];
            g_cvSurvivorColor[survivor].GetString(buffer, sizeof(buffer));
            if (ParseRgbColor(buffer, color, alpha))
            {
                return;
            }
        }
    }

    color[0] = ClampInt(g_cvBeamRed.IntValue, 0, 255);
    color[1] = ClampInt(g_cvBeamGreen.IntValue, 0, 255);
    color[2] = ClampInt(g_cvBeamBlue.IntValue, 0, 255);
}

bool ParseRgbColor(const char[] input, int color[4], int alpha)
{
    char pieces[3][12];
    int count = ExplodeString(input, " ", pieces, sizeof(pieces), sizeof(pieces[]));
    if (count < 3)
    {
        return false;
    }

    color[0] = ClampInt(StringToInt(pieces[0]), 0, 255);
    color[1] = ClampInt(StringToInt(pieces[1]), 0, 255);
    color[2] = ClampInt(StringToInt(pieces[2]), 0, 255);
    color[3] = alpha;
    return true;
}

int ClampInt(int value, int minValue, int maxValue)
{
    if (value < minValue)
    {
        return minValue;
    }

    if (value > maxValue)
    {
        return maxValue;
    }

    return value;
}

int GetSurvivorId(int client)
{
    if (client <= 0 || client > MaxClients || !IsClientInGame(client))
    {
        return SURV_UNKNOWN;
    }

    if (GetClientTeam(client) != TEAM_SURVIVOR)
    {
        return SURV_UNKNOWN;
    }

    char model[PLATFORM_MAX_PATH];
    GetClientModel(client, model, sizeof(model));

    if (StrContains(model, "survivor_gambler", false) != -1 || StrContains(model, "gambler", false) != -1) return SURV_NICK;
    if (StrContains(model, "survivor_producer", false) != -1 || StrContains(model, "producer", false) != -1) return SURV_ROCHELLE;
    if (StrContains(model, "survivor_coach", false) != -1 || StrContains(model, "coach", false) != -1) return SURV_COACH;
    if (StrContains(model, "survivor_mechanic", false) != -1 || StrContains(model, "mechanic", false) != -1) return SURV_ELLIS;
    if (StrContains(model, "survivor_namvet", false) != -1 || StrContains(model, "namvet", false) != -1) return SURV_BILL;
    if (StrContains(model, "survivor_teenangst", false) != -1 || StrContains(model, "teenangst", false) != -1) return SURV_ZOEY;
    if (StrContains(model, "survivor_biker", false) != -1 || StrContains(model, "biker", false) != -1) return SURV_FRANCIS;
    if (StrContains(model, "survivor_manager", false) != -1 || StrContains(model, "manager", false) != -1) return SURV_LOUIS;

    static bool checkedProp = false;
    static bool hasSurvivorCharacterProp = false;

    if (!checkedProp)
    {
        hasSurvivorCharacterProp = (FindSendPropInfo("CTerrorPlayer", "m_survivorCharacter") != -1);
        checkedProp = true;
    }

    if (hasSurvivorCharacterProp)
    {
        int character = GetEntProp(client, Prop_Send, "m_survivorCharacter");
        switch (character)
        {
            case 0: return SURV_NICK;
            case 1: return SURV_ROCHELLE;
            case 2: return SURV_COACH;
            case 3: return SURV_ELLIS;
            case 4: return SURV_BILL;
            case 5: return SURV_ZOEY;
            case 6: return SURV_FRANCIS;
            case 7: return SURV_LOUIS;
        }
    }

    return SURV_UNKNOWN;
}

void CacheAssets()
{
    char beam[PLATFORM_MAX_PATH];
    g_cvBeamModel.GetString(beam, sizeof(beam));
    if (beam[0] != '\0')
    {
        g_iBeamModel = PrecacheModel(beam, true);
    }
    else
    {
        g_iBeamModel = -1;
    }

    PrecacheSoundCvar(g_cvSoundStart, true);
    PrecacheSoundCvar(g_cvSoundLoop, true);
    PrecacheSoundCvar(g_cvSoundStop, true);

    for (int survivor = 0; survivor < NUM_SURVIVORS; survivor++)
    {
        for (int i = 0; i < MAX_VOICE_LINES; i++)
        {
            if (g_cvVoice[survivor][i] != null)
            {
                PrecacheSoundCvar(g_cvVoice[survivor][i], g_cvVoiceDownload.BoolValue);
            }
        }
    }
}

void PrecacheSoundCvar(ConVar cvar, bool customDownload)
{
    char sound[PLATFORM_MAX_PATH];
    cvar.GetString(sound, sizeof(sound));

    if (sound[0] == '\0')
    {
        return;
    }

    bool precached = PrecacheSound(sound, true);
    if (!precached)
    {
        LogError("[HLaser] Failed to precache sound: %s", sound);
    }

    if (customDownload && g_cvDownloadSounds.BoolValue)
    {
        char path[PLATFORM_MAX_PATH];
        Format(path, sizeof(path), "sound/%s", sound);
        AddFileToDownloadsTable(path);
    }
}
