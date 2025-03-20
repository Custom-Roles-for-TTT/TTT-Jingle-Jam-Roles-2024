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
    -- TODO: Hermit tutorial
end