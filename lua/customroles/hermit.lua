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
    }
}

ROLE.translations = {
    ["english"] = {
    }
}

RegisterRole(ROLE)

if SERVER then
    AddCSLuaFile()

    CreateConVar("ttt_hermit_notify_mode", "0", FCVAR_NONE, "The logic to use when notifying players that a hermit was killed. Killer is notified unless \"ttt_hermit_notify_killer\" is disabled", 0, 4)
    CreateConVar("ttt_hermit_notify_killer", "0", FCVAR_NONE, "Whether to notify a hermit's killer", 0, 1)
    CreateConVar("ttt_hermit_notify_sound", "0", FCVAR_NONE, "Whether to play a cheering sound when a hermit is killed", 0, 1)
    CreateConVar("ttt_hermit_notify_confetti", "0", FCVAR_NONE, "Whether to throw confetti when a hermit is a killed", 0, 1)
end

if CLIENT then
    -------------------
    -- ROUND SUMMARY --
    -------------------

    hook.Add("TTTScoringSummaryRender", "Zealot_TTTScoringSummaryRender", function(ply, roleFileName, groupingRole, roleColor, name, startingRole, finalRole)
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