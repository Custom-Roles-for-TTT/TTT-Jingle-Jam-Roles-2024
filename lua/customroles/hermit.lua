local hook = hook
local player = player

local AddHook = hook.Add
local PlayerIterator = player.Iterator

local ROLE = {}

ROLE.nameraw = "hermit"
ROLE.name = "Hermit"
ROLE.nameplural = "Hermits"
ROLE.nameext = "a Hermit"
ROLE.nameshort = "her"
ROLE.team = ROLE_TEAM_JESTER

-- TODO: Hermit role descriptions
ROLE.desc = [[You are {role}!]]
ROLE.shortdesc = ""

ROLE.selectionpredicate = function()
    if not ROLE_SOULBOUND then return false end
    if not GetConVar("ttt_missionary_prevent_monk"):GetBool() then return true end

    for _, p in PlayerIterator() do
        if p:IsMissionary() then
            return false
        end
    end
    return true
end

ROLE.convars = {
    {
        cvar = "ttt_hermit_notify_mode",
        type = ROLE_CONVAR_TYPE_DROPDOWN,
        choices = {"None", "Detective and Traitor", "Traitor", "Detective", "Everyone"},
        isNumeric = true
    },
    {
        cvar = "ttt_hermit_notify_killer",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_hermit_notify_sound",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_hermit_notify_confetti",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_hermit_is_independent",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_hermit_reveal_traitor",
        type = ROLE_CONVAR_TYPE_DROPDOWN,
        choices = {"No one", "Everyone", "Traitors", "Innocents", "Roles that can see jesters"},
        isNumeric = true
    },
    {
        cvar = "ttt_hermit_reveal_innocent",
        type = ROLE_CONVAR_TYPE_DROPDOWN,
        choices = {"No one", "Everyone", "Traitors", "Innocents", "Roles that can see jesters"},
        isNumeric = true
    },
    {
        cvar = "ttt_hermit_keep_begging",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_hermit_ignore_empty_weapons",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_hermit_ignore_empty_weapons_warning",
        type = ROLE_CONVAR_TYPE_BOOL
    }
}

ROLE.translations = {
    ["english"] = {
        ["ev_hermit_converted"] = "The {hermit} ({victim}) was converted to {team} by {attacker}",
        ["ev_hermit_killed"] = "The {hermit} ({ply}) died and became a ghost"
    }
}

RegisterRole(ROLE)

local hermit_is_independent = CreateConVar("ttt_hermit_is_independent", "0", FCVAR_REPLICATED, "Whether Hermits should be treated as members of the independent team", 0, 1)
local hermit_reveal_traitor = CreateConVar("ttt_hermit_reveal_traitor", "1", FCVAR_REPLICATED, "Who the Hermit is revealed to when they join the traitor team", 0, 4)
local hermit_reveal_innocent = CreateConVar("ttt_hermit_reveal_innocent", "2", FCVAR_REPLICATED, "Who the Hermit is revealed to when they join the innocent team", 0, 4)
local hermit_announce_delay = CreateConVar("ttt_hermit_announce_delay", "0", FCVAR_REPLICATED, "How long the delay between the Hermit's role change and announcement should be")
local hermit_keep_begging = CreateConVar("ttt_hermit_keep_begging", "0", FCVAR_REPLICATED, "Whether the Hermit should be able to keep begging after joining a team and switch teams multiple times", 0, 1)

if SERVER then
    AddCSLuaFile()

    util.AddNetworkString("TTT_HermitConverted")
    util.AddNetworkString("TTT_HermitKilled")
    util.AddNetworkString("TTT_HermitChangeTeam")
    util.AddNetworkString("TTT_HermitResetTeam")

    CreateConVar("ttt_hermit_notify_mode", "0", FCVAR_NONE, "The logic to use when notifying players that a Hermit was killed. Killer is notified unless \"ttt_hermit_notify_killer\" is disabled", 0, 4)
    CreateConVar("ttt_hermit_notify_killer", "1", FCVAR_NONE, "Whether to notify a Hermit's killer", 0, 1)
    CreateConVar("ttt_hermit_notify_sound", "0", FCVAR_NONE, "Whether to play a cheering sound when a Hermit is killed", 0, 1)
    CreateConVar("ttt_hermit_notify_confetti", "0", FCVAR_NONE, "Whether to throw confetti when a Hermit is a killed", 0, 1)

    local hermit_ignore_empty_weapons = CreateConVar("ttt_hermit_ignore_empty_weapons", "1", FCVAR_NONE, "Whether the Hermit should not change teams if they are given a weapon with no ammo", 0, 1)
    local hermit_ignore_empty_weapons_warning = CreateConVar("ttt_hermit_ignore_empty_weapons_warning", "1", FCVAR_NONE, "Whether the Hermit should receive a chat message warning on receiving an empty weapon", 0, 1)

    -----------------
    -- TEAM CHANGE --
    -----------------

    local function AnnounceTeamChange(ply, team)
        for _, v in PlayerIterator() do
            local hermitMode
            if ply:IsTraitorTeam() then
                hermitMode = hermit_reveal_traitor:GetInt()
            elseif ply:IsInnocentTeam() then
                hermitMode = hermit_reveal_innocent:GetInt()
            end

            local traitorTeam = v:IsTraitorTeam() and (hermitMode == BEGGAR_REVEAL_TRAITORS or hermitMode == BEGGAR_REVEAL_ROLES_THAT_CAN_SEE_JESTER)
            local innocentTeam = v:IsInnocentTeam() and hermitMode == BEGGAR_REVEAL_INNOCENTS
            local monsterTeam = v:IsMonsterTeam() and hermitMode == BEGGAR_REVEAL_ROLES_THAT_CAN_SEE_JESTER
            local indepTeam = v:IsIndependentTeam() and hermitMode == BEGGAR_REVEAL_ROLES_THAT_CAN_SEE_JESTER and cvars.Bool("ttt_" .. ROLE_STRINGS_RAW[self:GetRole()] .. "_can_see_jesters", false)

            if hermitMode == BEGGAR_REVEAL_ALL or traitorTeam or innocentTeam or monsterTeam or indepTeam then
                v:QueueMessage(MSG_PRINTBOTH, "The " .. ROLE_STRINGS[ROLE_HERMIT] .. " has joined the " .. team .. " team")
            end
        end
    end

    AddHook("WeaponEquip", "Hermit_WeaponEquip", function(wep, ply)
        if not IsValid(wep) or not wep.CanBuy or wep.AutoSpawnable then return end
        -- We only care about Hermits here
        if not IsPlayer(ply) or not ply:IsHermit() then return end
        -- If a Hermit or a Beggar is the owner of this weapon then it should no longer change ownership or convert Hermits as it has already been 'used'
        if not IsPlayer(wep.BoughtBy) or wep.BoughtBy:IsHermit() or wep.BoughtBy:IsBeggar() then return end
        -- Hermits can only become a traitor or an innocent, so ignore everyone else
        if not wep.BoughtBy:IsTraitorTeam() and not wep.BoughtBy:IsInnocentTeam() then return end

        if hermit_ignore_empty_weapons:GetBool() and wep:GetMaxClip1() > 0 and wep:Clip1() == 0 then
            if hermit_ignore_empty_weapons_warning:GetBool() then
                ply:PrintMessage(HUD_PRINTTALK, "Empty weapons don't convert the " .. ROLE_STRINGS[ROLE_HERMIT])
            end
            return
        end

        local role
        if wep.BoughtBy:IsTraitorTeam() and not TRAITOR_ROLES[ROLE_HERMIT] then
            role = ROLE_ZEALOT
        elseif wep.BoughtBy:IsInnocentTeam() and not INNOCENT_ROLES[ROLE_HERMIT] then
            role = ROLE_MONK
        end

        if hermit_keep_begging:GetBool() then
            wep.BoughtBy = ply -- Make the Hermit the owner of this weapon, thus preventing it from converting any Hermits again
            if not role then return end -- If the Hermit has been given an item from the team they are already part of then we don't need to change anything else

            JESTER_ROLES[ROLE_HERMIT] = false
            INDEPENDENT_ROLES[ROLE_HERMIT] = false
            net.Start("TTT_HermitChangeTeam")
            if role == ROLE_MONK then
                INNOCENT_ROLES[ROLE_HERMIT] = true
                TRAITOR_ROLES[ROLE_HERMIT] = false
                net.WriteBool(true)
            elseif role == ROLE_ZEALOT then
                INNOCENT_ROLES[ROLE_HERMIT] = false
                TRAITOR_ROLES[ROLE_HERMIT] = true
                net.WriteBool(false)
            end
            net.Broadcast()
        else
            ply:SetRole(role)
        end

        local team = ROLE_STRINGS[ROLE_INNOCENT]
        local team_ext = ROLE_STRINGS_EXT[ROLE_INNOCENT]
        if role == ROLE_ZEALOT then
            team = ROLE_STRINGS[ROLE_TRAITOR]
            team_ext = ROLE_STRINGS_EXT[ROLE_TRAITOR]
        end
        ply:QueueMessage(MSG_PRINTBOTH, "You have joined the " .. team .. " team")
        timer.Simple(0.5, function() SendFullStateUpdate() end) -- Slight delay to avoid flickering from Hermit to the new role and back to Hermit

        local announceDelay = hermit_announce_delay:GetInt()
        if announceDelay > 0 then
            timer.Create(ply:Nick() .. "HermitAnnounce", announceDelay, 1, function()
                if not IsPlayer(ply) then return end
                AnnounceTeamChange(ply, team)
            end)
        else
            AnnounceTeamChange(ply, team)
        end

        net.Start("TTT_HermitConverted")
        net.WriteString(ply:Nick())
        net.WriteString(wep.BoughtBy:Nick())
        net.WriteString(team_ext)
        net.WriteString(ply:SteamID64())
        net.Broadcast()
    end)

    AddHook("TTTCanTransferWeaponOwnership", "Hermit_TTTCanTransferWeaponOwnership", function(ply, wep)
        if IsPlayer(ply) and ply:IsHermit() then return false end
    end)

    ------------------
    -- HERMIT DEATH --
    ------------------

    local function HermitKilledNotification(attacker, victim)
        JesterTeamKilledNotification(attacker, victim,
            -- getkillstring
            function()
                return attacker:Nick() .. " cruelly killed the lowly " .. ROLE_STRINGS[ROLE_HERMIT] .. "!"
            end)
    end

    AddHook("DoPlayerDeath", "Hermit_DoPlayerDeath", function(ply, attacker, dmg)
        if not IsPlayer(attacker) or attacker == victim or GetRoundState() ~= ROUND_ACTIVE then return end
        if INNOCENT_ROLES[ROLE_HERMIT] or TRAITOR_ROLES[ROLE_HERMIT] then return end

        HermitKilledNotification(attacker, ply)
        local role = ROLE_MONK
        if attacker:IsInnocentTeam() then
            role = ROLE_ZEALOT
        end

        if hermit_keep_begging:GetBool() then
            JESTER_ROLES[ROLE_HERMIT] = false
            INDEPENDENT_ROLES[ROLE_HERMIT] = false
            net.Start("TTT_HermitChangeTeam")
            if role == ROLE_MONK then
                INNOCENT_ROLES[ROLE_HERMIT] = true
                TRAITOR_ROLES[ROLE_HERMIT] = false
                net.WriteBool(true)
            elseif role == ROLE_ZEALOT then
                INNOCENT_ROLES[ROLE_HERMIT] = false
                TRAITOR_ROLES[ROLE_HERMIT] = true
                net.WriteBool(false)
            end
            net.Broadcast()
        else
            ply:SetRole(role)
            SendFullStateUpdate()
        end

        local team = ROLE_STRINGS[ROLE_INNOCENT]
        if role == ROLE_ZEALOT then
            team = ROLE_STRINGS[ROLE_TRAITOR]
        end
        ply:QueueMessage(MSG_PRINTBOTH, "You have joined the " .. team .. " team")
    end)

    local ghostwhisperer_max_abilities = GetConVar("ttt_ghostwhisperer_max_abilities")
    local soulbound_max_abilities = GetConVar("ttt_soulbound_max_abilities")

    AddHook("PlayerDeath", "Hermit_PlayerDeath", function(victim, inflictor, attacker)
        if not IsPlayer(victim) then return end
        if not victim:IsHermit() then return end

        local ragdoll = victim.server_ragdoll or victim:GetRagdollEntity()
        if ragdoll then
            ragdoll:Dissolve()
        end

        -- TODO: Change this to a less wordy and more flavourful message
        local max_abilities = ghostwhisperer_max_abilities:GetInt()
        if TRAITOR_ROLES[ROLE_HERMIT] then
            max_abilities = soulbound_max_abilities:GetInt()
        end
        local message = "You have died but you can still talk with the living"
        if max_abilities > 0 then
            message = message .. " and can now buy abilities"
        end
        message = message .. "!"
        victim:QueueMessage(MSG_PRINTBOTH, message)

        victim:SetProperty("TTTIsGhosting", true, victim)
        if TRAITOR_ROLES[ROLE_HERMIT] then
            victim:SetNWInt("TTTSoulboundOldRole", ROLE_HERMIT)
            victim:SetRole(ROLE_SOULBOUND)
            SendFullStateUpdate()
        end

        net.Start("TTT_HermitKilled")
        net.WriteString(victim:Nick())
        net.Broadcast()
    end)

    hook.Add("TTTDeathNotifyOverride", "Hermit_TTTDeathNotifyOverride", function(victim, inflictor, attacker, reason, killerName, role)
        if GetRoundState() ~= ROUND_ACTIVE then return end
        if not IsValid(inflictor) or not IsValid(attacker) then return end
        if not attacker:IsPlayer() then return end
        if victim == attacker then return end
        if not victim:IsHermit() then return end

        return reason, killerName, ROLE_NONE
    end)

    ------------
    -- EVENTS --
    ------------

    AddHook("Initialize", "Hermit_Initialize", function()
        EVENT_HERMITCONVERTED = GenerateNewEventID(ROLE_HERMIT)
        EVENT_HERMITDIED = GenerateNewEventID(ROLE_HERMIT)
    end)

    -------------
    -- CLEANUP --
    -------------

    AddHook("TTTPrepareRound", "Hermit_PrepareRound", function()
        for _, v in PlayerIterator() do
            timer.Remove(v:Nick() .. "HermitAnnounce")
        end
        INNOCENT_ROLES[ROLE_HERMIT] = false
        TRAITOR_ROLES[ROLE_HERMIT] = false
        if hermit_is_independent:GetBool() then
            INDEPENDENT_ROLES[ROLE_HERMIT] = true
        else
            JESTER_ROLES[ROLE_HERMIT] = true
        end
        net.Start("TTT_HermitResetTeam")
        net.Broadcast()
    end)
end

if CLIENT then
    ------------
    -- EVENTS --
    ------------

    AddHook("TTTSyncEventIDs", "Hermit_TTTSyncEventIDs", function()
        local hermit_events = EVENTS_BY_ROLE[ROLE_HERMIT]
        EVENT_HERMITCONVERTED = hermit_events[1]
        EVENT_HERMITDIED = hermit_events[2]
        local ghost_icon = Material("icon16/status_offline.png")
        local innocent_icon = Material("icon16/user_green.png")
        local traitor_icon = Material("icon16/user_red.png")
        local Event = CLSCORE.DeclareEventDisplay
        local PT = LANG.GetParamTranslation
        Event(EVENT_HERMITCONVERTED, {
            text = function(e)
                return PT("ev_hermit_converted", {victim = e.vic, attacker = e.att, team = e.team, hermit = ROLE_STRINGS[ROLE_HERMIT]})
            end,
            icon = function(e)
                if e.team == ROLE_STRINGS_EXT[ROLE_INNOCENT] then
                    return innocent_icon, "Converted"
                else
                    return traitor_icon, "Converted"
                end
            end})
        Event(EVENT_HERMITDIED, {
            text = function(e)
                return PT("ev_hermit_died", {ply = e.ply, hermit = ROLE_STRINGS[ROLE_HERMIT]})
            end,
            icon = function(e)
                return ghost_icon, "Ghosted"
            end})
    end)

    net.Receive("TTT_HermitConverted", function(len)
        local victim = net.ReadString()
        local attacker = net.ReadString()
        local team = net.ReadString()
        local vicsid = net.ReadString()
        CLSCORE:AddEvent({
            id = EVENT_HERMITCONVERTED,
            vic = victim,
            att = attacker,
            team = team,
            sid64 = vicsid,
            bonus = 2
        })
    end)

    net.Receive("TTT_HermitKilled", function(len)
        local hermitname = net.ReadString()
        CLSCORE:AddEvent({
            id = EVENT_HERMITDIED,
            ply = hermitname
        })
    end)

    ---------------
    -- TEAM SYNC --
    ---------------

    net.Receive("TTT_HermitChangeTeam", function(len)
        local isInnocent = net.ReadBool()
        JESTER_ROLES[ROLE_HERMIT] = false
        INDEPENDENT_ROLES[ROLE_HERMIT] = false
        if isInnocent then
            INNOCENT_ROLES[ROLE_HERMIT] = true
            TRAITOR_ROLES[ROLE_HERMIT] = false
        else
            INNOCENT_ROLES[ROLE_HERMIT] = false
            TRAITOR_ROLES[ROLE_HERMIT] = true
        end
        UpdateRoleColours()
    end)

    net.Receive("TTT_HermitResetTeam", function(len)
        INNOCENT_ROLES[ROLE_HERMIT] = false
        TRAITOR_ROLES[ROLE_HERMIT] = false
        if hermit_is_independent:GetBool() then
            INDEPENDENT_ROLES[ROLE_HERMIT] = true
        else
            JESTER_ROLES[ROLE_HERMIT] = true
        end
        UpdateRoleColours()
    end)

    -------------------
    -- ROUND SUMMARY --
    -------------------

    AddHook("TTTScoringSummaryRender", "Hermit_TTTScoringSummaryRender", function(ply, roleFileName, groupingRole, roleColor, name, startingRole, finalRole)
        -- Make the traitor team Hermit appear as the Hermit instead of Soulbound in the round summary
        if ROLE_SOULBOUND and finalRole == ROLE_SOULBOUND and TRAITOR_ROLES[ROLE_HERMIT] and ply:GetNWInt("TTTSoulboundOldRole", -1) == ROLE_HERMIT then
            return ROLE_STRINGS_SHORT[ROLE_HERMIT]
        end
    end)

    -- TODO: Hermit tutorial
end

AddHook("TTTRoleSpawnsArtificially", "Hermit_TTTRoleSpawnsArtificially", function(role)
    if role == ROLE_HERMIT and util.CanRoleSpawn(ROLE_MISSIONARY) then
        return true
    end
end)

AddHook("TTTUpdateRoleState", "Hermit_TTTUpdateRoleState", function()
    if INNOCENT_ROLES[ROLE_HERMIT] or TRAITOR_ROLES[ROLE_HERMIT] then return end

    local is_independent = hermit_is_independent:GetBool()
    INDEPENDENT_ROLES[ROLE_HERMIT] = is_independent
    JESTER_ROLES[ROLE_HERMIT] = not is_independent
end)