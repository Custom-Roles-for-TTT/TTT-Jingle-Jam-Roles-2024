local ROLE = {}

ROLE.nameraw = "missionary"
ROLE.name = "Missionary"
ROLE.nameplural = "Missionaries"
ROLE.nameext = "a Missionary"
ROLE.nameshort = "mis"
ROLE.team = ROLE_TEAM_DETECTIVE

-- TODO: Missionary role descriptions
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
    -- TODO: Missionary tutorial
end