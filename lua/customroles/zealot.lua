local hook = hook

local AddHook = hook.Add

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
    -- TODO: Zealot tutorial
end