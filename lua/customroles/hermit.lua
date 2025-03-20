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
}

ROLE.translations = {
    ["english"] = {
    }
}

RegisterRole(ROLE)

if SERVER then
    AddCSLuaFile()
end

if CLIENT then
    -------------------
    -- ROUND SUMMARY --
    -------------------

    hook.Add("TTTScoringSummaryRender", "Zealot_TTTScoringSummaryRender", function(ply, roleFileName, groupingRole, roleColor, name, startingRole, finalRole)
        -- Make the traitor team Hermit appear as the Hermit instead of Soulbound in the round summary
        if finalRole == ROLE_SOULBOUND and TRAITOR_ROLES[ROLE_HERMIT] and ply:GetNWInt("TTTSoulboundOldRole", -1) == ROLE_HERMIT then
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