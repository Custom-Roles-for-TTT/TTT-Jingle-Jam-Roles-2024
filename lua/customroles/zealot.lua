local hook = hook
local player = player

local AddHook = hook.Add
local PlayerIterator = player.Iterator

local ROLE = {}

ROLE.nameraw = "zealot"
ROLE.name = "Zealot"
ROLE.nameplural = "Zealots"
ROLE.nameext = "a Zealot"
ROLE.nameshort = "zea"
ROLE.team = ROLE_TEAM_TRAITOR

ROLE.desc = [[You are {role}! {comrades}

When you die you will become {asoulbound} who can speak with
the living and use powerful abilities to help your comrades.

Press {menukey} to receive your special equipment!]]
ROLE.shortdesc = "Becomes a Soulbound who can speak with the living and use powerful abilities when they die."

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

ROLE.translations = {
    ["english"] = {
        ["ev_zealot_killed"] = "The {zealot} ({ply}) died and became a ghost"
    }
}

RegisterRole(ROLE)

if SERVER then
    AddCSLuaFile()

    util.AddNetworkString("TTT_ZealotKilled")

    ------------------
    -- ZEALOT DEATH --
    ------------------

    local soulbound_max_abilities = GetConVar("ttt_soulbound_max_abilities")

    AddHook("PlayerDeath", "Zealot_PlayerDeath", function(victim, inflictor, attacker)
        if not IsPlayer(victim) then return end
        if not victim:IsZealot() then return end

        local ragdoll = victim.server_ragdoll or victim:GetRagdollEntity()
        if ragdoll then
            ragdoll:Dissolve()
        end

        local message = "You have died but you can still talk with the living"
        if soulbound_max_abilities:GetInt() > 0 then
            message = message .. " and can now buy abilities"
        end
        message = message .. "!"
        victim:QueueMessage(MSG_PRINTBOTH, message)

        victim:SetProperty("TTTIsGhosting", true, victim)
        victim:SetNWInt("TTTSoulboundOldRole", ROLE_ZEALOT)
        victim:SetRole(ROLE_SOULBOUND)
        SendFullStateUpdate()

        net.Start("TTT_ZealotKilled")
        net.WriteString(victim:Nick())
        net.Broadcast()
    end)

    hook.Add("TTTDeathNotifyOverride", "Zealot_TTTDeathNotifyOverride", function(victim, inflictor, attacker, reason, killerName, role)
        if GetRoundState() ~= ROUND_ACTIVE then return end
        if not IsValid(inflictor) or not IsValid(attacker) then return end
        if not attacker:IsPlayer() then return end
        if victim == attacker then return end
        if not victim:IsZealot() then return end

        return reason, killerName, ROLE_NONE
    end)

    ------------
    -- EVENTS --
    ------------

    AddHook("Initialize", "Zealot_Initialize", function()
        EVENT_ZEALOTDIED = GenerateNewEventID(ROLE_ZEALOT)
    end)
end

if CLIENT then
    ------------
    -- EVENTS --
    ------------

    AddHook("TTTSyncEventIDs", "Zealot_TTTSyncEventIDs", function()
        EVENT_ZEALOTDIED = EVENTS_BY_ROLE[ROLE_ZEALOT]
        local ghost_icon = Material("icon16/status_offline.png")
        local Event = CLSCORE.DeclareEventDisplay
        local PT = LANG.GetParamTranslation
        Event(EVENT_ZEALOTDIED, {
            text = function(e)
                return PT("ev_zealot_died", {ply = e.ply, zealot = ROLE_STRINGS[ROLE_ZEALOT]})
            end,
            icon = function(e)
                return ghost_icon, "Ghosted"
            end})
    end)

    net.Receive("TTT_ZealotKilled", function(len)
        local zealotname = net.ReadString()
        CLSCORE:AddEvent({
            id = EVENT_ZEALOTDIED,
            ply = zealotname
        })
    end)

    -------------------
    -- ROUND SUMMARY --
    -------------------

    AddHook("TTTScoringSummaryRender", "Zealot_TTTScoringSummaryRender", function(ply, roleFileName, groupingRole, roleColor, name, startingRole, finalRole)
        -- Make the Zealot appear as the Zealot instead of Soulbound in the round summary
        if ROLE_SOULBOUND and finalRole == ROLE_SOULBOUND and ply:GetNWInt("TTTSoulboundOldRole", -1) == ROLE_ZEALOT then
            return ROLE_STRINGS_SHORT[ROLE_ZEALOT]
        end
    end)

    ----------------
    -- ROLE POPUP --
    ----------------

    hook.Add("TTTRolePopupParams", "Zealot_TTTRolePopupParams", function(cli)
        if cli:IsZealot() then
            return { asoulbound = ROLE_STRINGS_EXT[ROLE_SOULBOUND] }
        end
    end)

    -- TODO: Zealot tutorial
end

AddHook("TTTRoleSpawnsArtificially", "Zealot_TTTRoleSpawnsArtificially", function(role)
    if role == ROLE_ZEALOT and util.CanRoleSpawn(ROLE_MISSIONARY) then
        return true
    end
end)