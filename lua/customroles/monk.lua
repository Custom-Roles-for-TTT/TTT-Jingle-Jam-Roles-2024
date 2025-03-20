local hook = hook

local AddHook = hook.Add

local ROLE = {}

ROLE.nameraw = "monk"
ROLE.name = "Monk"
ROLE.nameplural = "Monks"
ROLE.nameext = "a Monk"
ROLE.nameshort = "mon"
ROLE.team = ROLE_TEAM_INNOCENT

-- TODO: Monk role descriptions
ROLE.desc = [[You are {role}!]]
ROLE.shortdesc = ""

RegisterRole(ROLE)

if SERVER then
    AddCSLuaFile()

    ----------------
    -- MONK DEATH --
    ----------------

    local ghostwhisperer_max_abilities = GetConVar("ttt_ghostwhisperer_max_abilities")

    AddHook("PlayerDeath", "Monk_PlayerDeath", function(victim, inflictor, attacker)
        if not IsPlayer(victim) then return end
        if not victim:IsMonk() then return end

        local ragdoll = victim.server_ragdoll or victim:GetRagdollEntity()
        if ragdoll then
            ragdoll:Dissolve()
        end

        local message = "You have died but you can still talk with the living"
        if ghostwhisperer_max_abilities:GetInt() > 0 then
            message = message .. " and can now buy abilities"
        end
        message = message .. "!"
        victim:QueueMessage(MSG_PRINTBOTH, message)

        victim:SetProperty("TTTIsGhosting", true, victim)
    end)
end

if CLIENT then
    -- TODO: Monk tutorial
end