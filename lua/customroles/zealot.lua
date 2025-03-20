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

-- TODO: Zealot role descriptions
ROLE.desc = [[You are {role}! {comrades}]]
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

RegisterRole(ROLE)

if SERVER then
    AddCSLuaFile()

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

        -- TODO: Change this to a less wordy and more flavourful message
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
    end)
end

if CLIENT then
    -------------------
    -- ROUND SUMMARY --
    -------------------

    hook.Add("TTTScoringSummaryRender", "Zealot_TTTScoringSummaryRender", function(ply, roleFileName, groupingRole, roleColor, name, startingRole, finalRole)
        -- Make the Zealot appear as the Zealot instead of Soulbound in the round summary
        if finalRole == ROLE_SOULBOUND and ply:GetNWInt("TTTSoulboundOldRole", -1) == ROLE_ZEALOT then
            return ROLE_STRINGS_SHORT[ROLE_ZEALOT]
        end
    end)

    -- TODO: Zealot tutorial
end

AddHook("TTTRoleSpawnsArtificially", "Zealot_TTTRoleSpawnsArtificially", function(role)
    if role == ROLE_ZEALOT and util.CanRoleSpawn(ROLE_MISSIONARY) then
        return true
    end
end)