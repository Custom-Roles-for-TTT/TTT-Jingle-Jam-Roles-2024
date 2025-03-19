local hook = hook

local AddHook = hook.Add

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
        ["phr_ankh_destroyed"] = "Your Ankh has been destroyed!",
        ["phr_ankh_stolen"] = "Your Ankh has been stolen!"
    }
}

RegisterRole(ROLE)

local pharaoh_is_independent = CreateConVar("ttt_pharaoh_is_independent", 0, FCVAR_REPLICATED, "Whether Pharaohs should be treated as independent")

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

    -- TODO: On disconnect, destroy ankh
    -- TODO: On death, resurrect and destroy ankh
    -- TODO: If the resurrected player is not the Pharaoh, notify them (if enabled)
end

if CLIENT then
    --------------
    -- TUTORIAL --
    --------------

    AddHook("TTTTutorialRoleText", "Pharaoh_TTTTutorialRoleText", function(role, titleLabel)
        if role ~= ROLE_PHARAOH then return end
    end)
end