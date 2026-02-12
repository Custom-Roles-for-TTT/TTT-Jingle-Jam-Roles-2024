local hook = hook
local player = player
local timer = timer

local AddHook = hook.Add
local PlayerIterator = player.Iterator

local ROLE = {}

ROLE.nameraw = "pharaoh"
ROLE.name = "Pharaoh"
ROLE.nameplural = "Pharaohs"
ROLE.nameext = "a Pharaoh"
ROLE.nameshort = "phr"

ROLE.desc = [[You are {role}! You have an Ankh that can be placed down somewhere
and which serves as a single-use respawn anchor.

If you die with the Ankh placed, you'll respawn at it's location (once).

Be careful, though, the Ankh can be destroyed by other players (and maybe stolen too)!]]
ROLE.shortdesc = "Has an Ankh that can be placed in the world. On death, they respawn at the Ankh one time"

ROLE.team = ROLE_TEAM_INNOCENT

ROLE.convars = {
    {
        cvar = "ttt_pharaoh_is_detective",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_pharaoh_is_independent",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_pharaoh_move_ankh",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_pharaoh_ankh_place_sound",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_pharaoh_steal_time",
        type = ROLE_CONVAR_TYPE_NUM
    },
    {
        cvar = "ttt_pharaoh_respawn_delay",
        type = ROLE_CONVAR_TYPE_NUM
    },
    {
        cvar = "ttt_pharaoh_damage_own_ankh",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_pharaoh_warn_steal",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_pharaoh_warn_damage",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_pharaoh_warn_destroy",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_pharaoh_respawn_warn_pharaoh",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_pharaoh_respawn_block_win",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_pharaoh_ankh_health",
        type = ROLE_CONVAR_TYPE_NUM
    },
    {
        cvar = "ttt_pharaoh_ankh_heal_repair_dist",
        type = ROLE_CONVAR_TYPE_NUM
    },
    {
        cvar = "ttt_pharaoh_ankh_heal_rate",
        type = ROLE_CONVAR_TYPE_NUM
    },
    {
        cvar = "ttt_pharaoh_ankh_heal_amount",
        type = ROLE_CONVAR_TYPE_NUM
    },
    {
        cvar = "ttt_pharaoh_ankh_repair_rate",
        type = ROLE_CONVAR_TYPE_NUM
    },
    {
        cvar = "ttt_pharaoh_ankh_repair_amount",
        type = ROLE_CONVAR_TYPE_NUM
    },
    {
        cvar = "ttt_pharaoh_innocent_steal",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_pharaoh_traitor_steal",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_pharaoh_jester_steal",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_pharaoh_independent_steal",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_pharaoh_monster_steal",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_pharaoh_can_see_jesters",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_pharaoh_update_scoreboard",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_pharaoh_ankh_aura_color_mode",
        type = ROLE_CONVAR_TYPE_DROPDOWN,
        choices = {"Disable", "White", "Role", "Team"},
        isNumeric = true
    }
}

ROLE.translations = {
    ["english"] = {
        ["ev_win_pharaoh"] = "The mystic {role} has won the round!",
        ["win_pharaoh"] = "The {role} has outlasted you all!",
        ["phr_ankh_name"] = "Ankh",
        ["phr_ankh_name_health"] = "Ankh ({current}/{max})",
        ["phr_ankh_hint"] = "Press {usekey} to pick up. Stay near to heal.",
        ["phr_ankh_hint_steal"] = "Hold {usekey} to steal",
        ["phr_ankh_hint_unmovable"] = "Stay near to heal",
        ["phr_ankh_help_pri"] = "Use {primaryfire} to place your Ankh on the ground",
        ["phr_ankh_help_sec"] = "Stay near it to heal",
        ["phr_ankh_damaged"] = "Your Ankh has been damaged!",
        ["pharaoh_stealing"] = "STEALING",
        ["info_popup_pharaoh_detective"] = [[You are {role}! As {adetective}, HQ has given you special resources to find the {traitors}.
You have an Ankh that can be placed down somewhere and which serves as a single-use respawn anchor.
If you die with the Ankh placed, you'll respawn at it's location (once).
Be careful, though, the Ankh can be destroyed by other players (and maybe stolen too)!

Press {menukey} to receive your equipment!]]
    }
}

RegisterRole(ROLE)

PHARAOH_AURA_COLOR_MODE_DISABLE = 0
PHARAOH_AURA_COLOR_MODE_WHITE = 1
PHARAOH_AURA_COLOR_MODE_ROLE = 2
PHARAOH_AURA_COLOR_MODE_TEAM = 3

local pharaoh_is_detective = CreateConVar("ttt_pharaoh_is_detective", 0, FCVAR_REPLICATED, "Whether Pharaohs should be treated as a detective role", 0, 1)
local pharaoh_is_independent = CreateConVar("ttt_pharaoh_is_independent", 0, FCVAR_REPLICATED, "Whether Pharaohs should be treated as independent. Ignored when \"ttt_pharaoh_is_detective\" is enabled", 0, 1)
local pharaoh_steal_time = CreateConVar("ttt_pharaoh_steal_time", "15", FCVAR_REPLICATED, "The amount of time it takes to steal an Ankh", 1, 60)
local pharaoh_innocent_steal = CreateConVar("ttt_pharaoh_innocent_steal", "0", FCVAR_REPLICATED, "Whether innocents are allowed to steal the Ankh", 0, 1)
local pharaoh_traitor_steal = CreateConVar("ttt_pharaoh_traitor_steal", "1", FCVAR_REPLICATED, "Whether traitors are allowed to steal the Ankh", 0, 1)
local pharaoh_jester_steal = CreateConVar("ttt_pharaoh_jester_steal", "0", FCVAR_REPLICATED, "Whether jesters are allowed to steal the Ankh", 0, 1)
local pharaoh_independent_steal = CreateConVar("ttt_pharaoh_independent_steal", "1", FCVAR_REPLICATED, "Whether independents are allowed to steal the Ankh", 0, 1)
local pharaoh_monster_steal = CreateConVar("ttt_pharaoh_monster_steal", "1", FCVAR_REPLICATED, "Whether monsters are allowed to steal the Ankh", 0, 1)
local pharaoh_respawn_delay = CreateConVar("ttt_pharaoh_respawn_delay", 20, FCVAR_REPLICATED, "How long (in seconds) after death a Pharaoh should respawn if they placed down an Ankh. Set to 0 to disable respawning", 0, 180)
-- Independent ConVars
CreateConVar("ttt_pharaoh_can_see_jesters", "0", FCVAR_REPLICATED)
CreateConVar("ttt_pharaoh_update_scoreboard", "0", FCVAR_REPLICATED)
-- Detective ConVars
CreateConVar("ttt_pharaoh_credits_starting", "1", FCVAR_REPLICATED)
CreateConVar("ttt_pharaoh_shop_sync", "0", FCVAR_REPLICATED)
CreateConVar("ttt_pharaoh_shop_random_percent", "0", FCVAR_REPLICATED, "The percent chance that a weapon in the shop will not be shown for the pharaoh", 0, 100)
CreateConVar("ttt_pharaoh_shop_random_enabled", "0", FCVAR_REPLICATED, "Whether shop randomization should run for the pharaoh")

-----------------
-- TEAM CHANGE --
-----------------

AddHook("TTTUpdateRoleState", "Pharaoh_TTTUpdateRoleState", function()
    local is_detective = pharaoh_is_detective:GetBool()
    -- If they are a detective it doesn't matter what the other convar is set to
    local is_independent = not is_detective and pharaoh_is_independent:GetBool()
    INDEPENDENT_ROLES[ROLE_PHARAOH] = is_independent
    INNOCENT_ROLES[ROLE_PHARAOH] = not is_independent
    DETECTIVE_ROLES[ROLE_PHARAOH] = is_detective
    SHOP_ROLES[ROLE_PHARAOH] = is_detective or is_independent
end)

----------------
-- RESPAWNING --
----------------

AddHook("TTTIsPlayerRespawning", "Pharaoh_TTTIsPlayerRespawning", function(ply)
    if not IsPlayer(ply) then return end
    if ply:Alive() then return end

    if timer.Exists("TTTPharaohAnkhRespawn_" .. ply:SteamID64()) then
        return true
    end
end)

if SERVER then
    AddCSLuaFile()

    local pharaoh_warn_steal = CreateConVar("ttt_pharaoh_warn_steal", "1", FCVAR_NONE, "Whether an Ankh's owner is warned when it is stolen", 0, 1)
    local pharaoh_respawn_block_win = CreateConVar("ttt_pharaoh_respawn_block_win", 1, FCVAR_NONE, "Whether a player respawning via the Ankh blocks other teams from winning", 0, 1)
    local pharaoh_respawn_warn_pharaoh = CreateConVar("ttt_pharaoh_respawn_warn_pharaoh", 1, FCVAR_NONE, "Whether the original Pharaoh owner of an Ankh should be notified when it's used by someone else", 0, 1)
    local pharaoh_steal_grace_time = CreateConVar("ttt_pharaoh_steal_grace_time", 0.25, FCVAR_NONE, "How long (in seconds) before the steal progress of an Ankh is reset when a player stops looking at it", 0, 1)

    local function ResetStealState(ply)
        ply:ClearProperty("PharaohStealTarget", ply)
        ply:ClearProperty("PharaohStealStart", ply)
        ply.PharaohLastStealTime = nil
    end

    local function ResetState(ply)
        ResetStealState(ply)
        timer.Remove("TTTPharaohAnkhRespawn_" .. ply:SteamID64())
        ply.PharaohAnkh = nil
    end

    ----------------
    -- RESPAWNING --
    ----------------

    -- Something else respawned this player, stop the timer and don't use the ankh
    AddHook("TTTPlayerSpawnForRound", "Pharaoh_TTTPlayerSpawnForRound", function(ply, dead_only)
        if dead_only and ply:Alive() and not ply:IsSpec() then return end
        timer.Remove("TTTPharaohAnkhRespawn_" .. ply:SteamID64())
    end)

    AddHook("PostPlayerDeath", "Pharaoh_PostPlayerDeath", function(ply)
        if not IsPlayer(ply) then return end

        -- If a player died the can't be stealing the ankh anymore, so clear that state
        ResetStealState(ply)

        if not IsValid(ply.PharaohAnkh) then return end
        if ply:IsPharaoh() and ply:IsRoleAbilityDisabled() then
            ply.PharaohAnkh:DestroyAnkh()
            return
        end

        local respawn_delay = pharaoh_respawn_delay:GetInt()
        if respawn_delay > 0 then
            ply:QueueMessage(MSG_PRINTBOTH, "Using Ankh to respawn in " .. respawn_delay .. " second(s)...")

            -- Check if someone else is using the Ankh a Pharaoh originally placed and whether they should be warned
            local pharaoh = ply.PharaohAnkh:GetPharaoh()
            local someoneElseWarning = pharaoh_respawn_warn_pharaoh:GetBool() and IsPlayer(pharaoh) and ply ~= pharaoh
            if someoneElseWarning then
                pharaoh:QueueMessage(MSG_PRINTBOTH, "Someone else is using your Ankh!")
            end

            timer.Create("TTTPharaohAnkhRespawn_" .. ply:SteamID64(), respawn_delay, 1, function()
                if not IsPlayer(ply) then return end
                local ankh = ply.PharaohAnkh
                ResetState(ply)

                -- If we're warning a Pharaoh that the Ankh was used and the Pharaoh still exists, let them know it's gone now
                if someoneElseWarning and IsPlayer(pharaoh) then
                    pharaoh:QueueMessage(MSG_PRINTBOTH, "Someone else has used your Ankh!")
                end

                if not IsValid(ankh) then
                    ply:QueueMessage(MSG_PRINTBOTH, "Oh no! Your Ankh was destroyed or stolen while you were dead =(")
                    return
                end

                ply:QueueMessage(MSG_PRINTBOTH, "You have used your Ankh to respawn")

                local body = ply.server_ragdoll or ply:GetRagdollEntity()
                ply:SpawnForRound(true)
                SafeRemoveEntity(body)

                local ankhPos = ankh:GetPos()
                ply:SetPos(FindRespawnLocation(ankhPos) or ankhPos)
                ply:SetEyeAngles(Angle(0, ankh:GetAngles().y, 0))

                ankh:DestroyAnkh()
            end)
        else
            ply.PharaohAnkh:DestroyAnkh()
            ResetState(ply)
        end
    end)

    hook.Add("TTTStopPlayerRespawning", "Pharaoh_TTTStopPlayerRespawning", function(ply)
        if not IsPlayer(ply) then return end
        if ply:Alive() then return end

        if timer.Exists("TTTPharaohAnkhRespawn_" .. ply:SteamID64()) then
            timer.Remove("TTTPharaohAnkhRespawn_" .. ply:SteamID64())
        end
    end)

    ----------------
    -- DISCONNECT --
    ----------------

    -- On disconnect, destroy ankh if they have one
    AddHook("PlayerDisconnected", "Pharaoh_PlayerDisconnected", function(ply)
        if not IsPlayer(ply) then return end
        SafeRemoveEntity(ply.PharaohStealTarget)
        ResetState(ply)
    end)

    --------------------
    -- STEAL TRACKING --
    --------------------

    AddHook("TTTPlayerAliveThink", "Pharaoh_TTTPlayerAliveThink", function(ply)
        if ply.PharaohLastStealTime == nil then return end

        local stealTarget = ply.PharaohStealTarget
        if not IsValid(stealTarget) then return end

        local stealStart = ply.PharaohStealStart
        if not stealStart or stealStart <= 0 then return end

        local curTime = CurTime()

        -- If it's been too long since the user used the ankh, stop tracking their progress
        if curTime - ply.PharaohLastStealTime >= pharaoh_steal_grace_time:GetFloat() then
            ply.PharaohLastStealTime = nil
            ply:SetProperty("PharaohStealTarget", nil, ply)
            ply:SetProperty("PharaohStealStart", 0, ply)
            return
        end

        -- If they haven't used this item long enough then keep waiting
        if curTime - stealStart < pharaoh_steal_time:GetInt() then return end

        local placer = stealTarget:GetPlacer()
        if IsPlayer(placer) and pharaoh_warn_steal:GetBool() then
            placer:QueueMessage(MSG_PRINTBOTH, "Your Ankh has been stolen!")
        end

        ply:Give("weapon_phr_ankh")
        stealTarget:SetPlacer(nil)
        stealTarget:Remove()
    end)

    ----------------
    -- WIN CHECKS --
    ----------------

    AddHook("TTTWinCheckBlocks", "Pharaoh_TTTWinCheckBlocks", function(win_blocks)
        if not pharaoh_respawn_block_win:GetBool() then return end

        table.insert(win_blocks, function(win)
            for _, v in PlayerIterator() do
                if timer.Exists("TTTPharaohAnkhRespawn_" .. v:SteamID64()) then
                    -- Don't bother blocking the win if this player's team is the one winning
                    local roleTeam = v:GetRoleTeam(true)
                    if (roleTeam == ROLE_TEAM_INNOCENT and win == WIN_INNOCENT) or
                        (roleTeam == ROLE_TEAM_TRAITOR and win == WIN_TRAITOR) then
                        continue
                    end
                    return WIN_NONE
                end
            end
        end)
    end)

    AddHook("Initialize", "Pharaoh_Initialize", function()
        WIN_PHARAOH = GenerateNewWinID(ROLE_PHARAOH)
    end)

    AddHook("TTTCheckForWin", "Pharaoh_CheckForWin", function()
        if not INDEPENDENT_ROLES[ROLE_PHARAOH] then return end

        local pharaoh_alive = false
        local other_alive = false
        for _, v in PlayerIterator() do
            if v:Alive() and v:IsTerror() then
                if v:IsPharaoh() then
                    pharaoh_alive = true
                elseif not v:ShouldActLikeJester() and not ROLE_HAS_PASSIVE_WIN[v:GetRole()] then
                    other_alive = true
                end
            end
        end

        if pharaoh_alive and not other_alive then
            return WIN_PHARAOH
        elseif pharaoh_alive then
            return WIN_NONE
        end
    end)

    AddHook("TTTPrintResultMessage", "Pharaoh_PrintResultMessage", function(type)
        if type == WIN_PHARAOH then
            LANG.Msg("win_pharaoh", { role = ROLE_STRINGS[ROLE_PHARAOH] })
            ServerLog("Result: " .. ROLE_STRINGS[ROLE_PHARAOH] .. " wins.\n")
            return true
        end
    end)

    -------------
    -- CLEANUP --
    -------------

    AddHook("TTTPrepareRound", "Pharaoh_TTTPrepareRound", function()
        for _, v in PlayerIterator() do
            ResetState(v)
        end
    end)

    AddHook("TTTBeginRound", "Pharaoh_TTTBeginRound", function()
        for _, v in PlayerIterator() do
            ResetState(v)
        end
    end)
end

if CLIENT then

    ----------------
    -- WIN EVENTS --
    ----------------

    AddHook("TTTSyncWinIDs", "Pharaoh_TTTWinIDsSynced", function()
        WIN_PHARAOH = WINS_BY_ROLE[ROLE_PHARAOH]
    end)

    AddHook("TTTEventFinishText", "Pharaoh_EventFinishText", function(e)
        if e.win == WIN_PHARAOH then
            return LANG.GetParamTranslation("ev_win_pharaoh", { role = string.lower(ROLE_STRINGS[ROLE_PHARAOH]) })
        end
    end)

    AddHook("TTTEventFinishIconText", "Pharaoh_EventFinishIconText", function(e, win_string, role_string)
        if e.win == WIN_PHARAOH then
            return win_string, ROLE_STRINGS[ROLE_PHARAOH]
        end
    end)

    AddHook("TTTScoringWinTitle", "Pharaoh_ScoringWinTitle", function(wintype, wintitles, title, secondaryWinRole)
        if wintype == WIN_PHARAOH then
            return { txt = "hilite_win_role_singular", params = { role = string.upper(ROLE_STRINGS[ROLE_PHARAOH]) }, c = ROLE_COLORS[ROLE_PHARAOH] }
        end
    end)

    --------------------
    -- STEAL PROGRESS --
    --------------------

    local client
    AddHook("HUDPaint", "Pharaoh_HUDPaint", function()
        if not client then
            client = LocalPlayer()
        end

        local stealTarget = client.PharaohStealTarget
        if not IsValid(stealTarget) then return end

        local stealStart = client.PharaohStealStart
        if not stealStart or stealStart <= 0 then return end

        local curTime = CurTime()
        local stealTime = pharaoh_steal_time:GetInt()
        local endTime = stealStart + stealTime
        local progress = math.min(1, 1 - ((endTime - curTime) / stealTime))

        local text = LANG.GetTranslation("pharaoh_stealing")

        local x = ScrW() / 2
        local y = ScrH() / 2
        local w = 300
        CRHUD:PaintProgressBar(x, y, w, COLOR_GREEN, text, progress)
    end)

    ----------------
    -- ROLE POPUP --
    ----------------

    hook.Add("TTTRolePopupRoleStringOverride", "Pharaoh_TTTRolePopupRoleStringOverride", function(cli, roleString)
        if not IsPlayer(cli) or not cli:IsPharaoh() then return end

        if DETECTIVE_ROLES[ROLE_PHARAOH] then
            return roleString .. "_detective"
        end
    end)

    --------------
    -- TUTORIAL --
    --------------

    AddHook("TTTTutorialRoleText", "Pharaoh_TTTTutorialRoleText", function(role, titleLabel)
        if role ~= ROLE_PHARAOH then return end

        local roleColor = ROLE_COLORS[ROLE_PHARAOH]
        local roleTeam = player.GetRoleTeam(ROLE_PHARAOH)
        local roleTeamName, _ = GetRoleTeamInfo(roleTeam)

        local article = "an"
        if roleTeam == ROLE_TEAM_DETECTIVE then
            roleTeamName = LANG.GetTranslation("detective")
            article = "a"
        end
        local html = "The " .. ROLE_STRINGS[ROLE_PHARAOH] .. " is " .. article .. " <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>" .. roleTeamName .. "</span> role who is given an Ankh which they can place in the world."

        local delay = pharaoh_respawn_delay:GetInt()
        if delay > 0 then
            html = html .. "<span style='display: block; margin-top: 10px;'>If the " .. ROLE_STRINGS[ROLE_PHARAOH] .. " dies <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>after placing their Ankh</span>, they respawn at it's location after " .. delay .. " second(s)!</span>"
        end

        local innocent_steal = pharaoh_innocent_steal:GetBool()
        local traitor_steal = pharaoh_traitor_steal:GetBool()
        local jester_steal = pharaoh_jester_steal:GetBool()
        local independent_steal = pharaoh_independent_steal:GetBool()
        local monster_steal = pharaoh_monster_steal:GetBool()

        if innocent_steal or traitor_steal or jester_steal or independent_steal or monster_steal then
            html = html .. "<span style='display: block; margin-top: 10px;'>Beware though, the " .. ROLE_STRINGS[ROLE_PHARAOH] .. "'s Ankh <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>can be stolen</span> by "
            if innocent_steal and traitor_steal and jester_steal and independent_steal and monster_steal then
                html = html .. "any player"
            else
                local stealTeams = {}
                if innocent_steal then
                    table.insert(stealTeams, LANG.GetTranslation("innocents"))
                end
                if traitor_steal then
                    table.insert(stealTeams, LANG.GetTranslation("traitors"))
                end
                if jester_steal then
                    table.insert(stealTeams, LANG.GetTranslation("jesters"))
                end
                if independent_steal then
                    table.insert(stealTeams, LANG.GetTranslation("independents"))
                end
                if monster_steal then
                    table.insert(stealTeams, LANG.GetTranslation("monsters"))
                end

                local teamsLabel = table.concat(stealTeams, ", ", 1, #stealTeams - 1)
                if #stealTeams == 1 then
                    teamsLabel = stealTeams[1]
                else
                    if #stealTeams > 2 then
                        teamsLabel = teamsLabel .. ","
                    end
                    teamsLabel = teamsLabel .. " or " .. stealTeams[#stealTeams]
                end

                html = html .. teamsLabel
            end
            html = html .. " if they <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>interact with it</span> for " .. pharaoh_steal_time:GetInt() .. " second(s)!</span>"
        end

        local heal_rate = GetConVar("ttt_pharaoh_ankh_heal_rate"):GetInt()
        local heal_amount = GetConVar("ttt_pharaoh_ankh_heal_amount"):GetInt()
        local repair_rate = GetConVar("ttt_pharaoh_ankh_repair_rate"):GetInt()
        local repair_amount = GetConVar("ttt_pharaoh_ankh_repair_amount"):GetInt()
        local healing = heal_rate > 0 and heal_amount > 0
        local repairing = repair_rate > 0 and repair_amount > 0
        if healing or repairing then
            html = html .. "<span style='display: block; margin-top: 10px;'>If the " .. ROLE_STRINGS[ROLE_PHARAOH] .. " is close enough to their Ankh, "
            if healing then
                html = html .. "they are <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>healed for " .. heal_amount .. "hp</span> every " .. heal_rate .. " second(s)"
                if repairing then
                    html = html .. " and "
                end
            end
            if repairing then
                html = html .. "the Ankh is <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>repaired for " .. repair_amount .. "hp</span> every " .. repair_rate .. " second(s)"
            end
            html = html .. ".</span>"
        end

        return html
    end)
end