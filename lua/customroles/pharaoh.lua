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

ROLE.desc = [[You are {role}!]]
ROLE.shortdesc = "TODO"

ROLE.team = ROLE_TEAM_INNOCENT

ROLE.convars = {
    {
        cvar = "ttt_pharaoh_is_independent",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_pharaoh_move_ankh",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_pharaoh_steal_time",
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
    }
}

ROLE.translations = {
    ["english"] = {
        ["phr_ankh_name"] = "Ankh",
        ["phr_ankh_hint"] = "Press {usekey} to pick up. Stay near to heal.",
        ["phr_ankh_hint_steal"] = "Hold {usekey} to steal",
        ["phr_ankh_hint_unmovable"] = "Stay near to heal",
        ["phr_ankh_help_pri"] = "Use {primaryfire} to place your Ankh on the ground",
        ["phr_ankh_help_sec"] = "Stay near it to heal",
        ["phr_ankh_damaged"] = "Your Ankh has been damaged!",
        ["pharaoh_stealing"] = "STEALING"
    }
}

RegisterRole(ROLE)

local pharaoh_is_independent = CreateConVar("ttt_pharaoh_is_independent", 0, FCVAR_REPLICATED, "Whether Pharaohs should be treated as independent")
local pharaoh_steal_time = CreateConVar("ttt_pharaoh_steal_time", "10", FCVAR_REPLICATED, "The amount of time it takes to steal an Ankh", 1, 60)
--[[local pharaoh_innocent_steal = ]]CreateConVar("ttt_pharaoh_innocent_steal", "0", FCVAR_REPLICATED, "Whether innocents are allowed to steal the Ankh", 0, 1)
--[[local pharaoh_traitor_steal = ]]CreateConVar("ttt_pharaoh_traitor_steal", "1", FCVAR_REPLICATED, "Whether traitors are allowed to steal the Ankh", 0, 1)
--[[local pharaoh_jester_steal = ]]CreateConVar("ttt_pharaoh_jester_steal", "0", FCVAR_REPLICATED, "Whether jesters are allowed to steal the Ankh", 0, 1)
--[[local pharaoh_independent_steal = ]]CreateConVar("ttt_pharaoh_independent_steal", "1", FCVAR_REPLICATED, "Whether independents are allowed to steal the Ankh", 0, 1)
--[[local pharaoh_monster_steal = ]]CreateConVar("ttt_pharaoh_monster_steal", "1", FCVAR_REPLICATED, "Whether monsters are allowed to steal the Ankh", 0, 1)
local pharaoh_respawn_delay = CreateConVar("ttt_pharaoh_respawn_delay", 10, FCVAR_REPLICATED, "How long (in seconds) after death a Pharaoh should respawn if they placed down an Ankh. Set to 0 to disable respawning", 0, 180)

-----------------
-- TEAM CHANGE --
-----------------

AddHook("TTTUpdateRoleState", "Pharaoh_TTTUpdateRoleState", function()
    local is_independent = pharaoh_is_independent:GetBool()
    INDEPENDENT_ROLES[ROLE_PHARAOH] = is_independent
    INNOCENT_ROLES[ROLE_PHARAOH] = not is_independent
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

    local pharaoh_warn_steal = CreateConVar("ttt_pharaoh_warn_steal", "1", FCVAR_NONE, "Whether to warn an Ankh's owner is warned when it is stolen", 0, 1)
    local pharaoh_respawn_warn_pharaoh = CreateConVar("ttt_pharaoh_respawn_warn_pharaoh", 1, FCVAR_NONE, "Whether the original Pharaoh owner of an Ankh should be notified when it's used by someone else", 0, 1)

    local function ResetState(ply)
        timer.Remove("TTTPharaohAnkhRespawn_" .. ply:SteamID64())
        ply:ClearProperty("PharaohStealTarget", ply)
        ply:ClearProperty("PharaohStealStart", ply)
        ply.PharaohLastStealTime = nil
        ply.PharaohAnkh = nil
    end

    ----------------
    -- RESPAWNING --
    ----------------

    AddHook("PostPlayerDeath", "Pharaoh_PostPlayerDeath", function(ply)
        if not IsPlayer(ply) then return end
        if not IsValid(ply.PharaohAnkh) then return end

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
        if curTime - ply.PharaohLastStealTime >= 0 then
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

    --------------
    -- TUTORIAL --
    --------------

    AddHook("TTTTutorialRoleText", "Pharaoh_TTTTutorialRoleText", function(role, titleLabel)
        if role ~= ROLE_PHARAOH then return end
    end)
end