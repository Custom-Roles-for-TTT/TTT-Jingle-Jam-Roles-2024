local hook = hook
local player = player

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

-----------------
-- TEAM CHANGE --
-----------------

AddHook("TTTUpdateRoleState", "Pharaoh_TTTUpdateRoleState", function()
    local is_independent = pharaoh_is_independent:GetBool()
    INDEPENDENT_ROLES[ROLE_PHARAOH] = is_independent
    INNOCENT_ROLES[ROLE_PHARAOH] = not is_independent
end)

if SERVER then
    AddCSLuaFile()

    local pharaoh_warn_steal = CreateConVar("ttt_pharaoh_warn_steal", "1", FCVAR_NONE, "Whether to warn an Ankh's owner is warned when it is stolen", 0, 1)

    -- TODO: On death:
        -- Resurrect after configurable delay (and ankh isn't destroyed in the meantime)
        -- If Ankh owner isn't Pharaoh, warn original Pharaoh that their Ankh has been used (if configured to do so)
        -- Destroy ankh
        -- Reset state

    local function ResetState(ply)
        ply:ClearProperty("PharaohStealTarget", ply)
        ply:ClearProperty("PharaohStealStart", ply)
        ply.PharaohLastStealTime = nil
    end

    ----------------
    -- DISCONNECT --
    ----------------

    -- On disconnect, destroy ankh if they have one
    AddHook("PlayerDisconnected", "Pharaoh_PlayerDisconnected", function(ply)
        if not IsPlayer(ply) then return end
        SafeRemoveEntity(ply.PharaohStealTarget)
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