local hook = hook
local player = player

local AddHook = hook.Add
local PlayerIterator = player.Iterator

local ROLE = {}

ROLE.nameraw = "missionary"
ROLE.name = "Missionary"
ROLE.nameplural = "Missionaries"
ROLE.nameext = "a Missionary"
ROLE.nameshort = "mis"
ROLE.team = ROLE_TEAM_DETECTIVE

ROLE.desc = [[You are {role}! As {adetective}, HQ has given you special resources to find the {traitors}.
You have a Proselytizer that can grant a player powerful abilities if they die.
Be careful, though! If used on a bad player, they might use those abilities against you!

Press {menukey} to receive your equipment!]]
ROLE.shortdesc = "Can use their proselytizer to turn a player into a Monk, Zealot, or Hermit."

ROLE.loadout = {"weapon_mis_proselytizer"}

local missionary_prevent_monk = CreateConVar("ttt_missionary_prevent_monk", "1", FCVAR_REPLICATED, "Whether to only spawn the Missionary when there isn't already a Monk, Zealot, or Hermit in the round", 0, 1)
ROLE.selectionpredicate = function()
    if not ROLE_SOULBOUND then return false end
    if not missionary_prevent_monk:GetBool() then return true end

    for _, p in PlayerIterator() do
        if p:IsMonk() or p:IsZealot() or p:IsHermit() then
            return false
        end
    end
    return true
end

ROLE.convars = {
    {
        cvar = "ttt_missionary_proselytizer_time",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 0
    },
    {
        cvar = "ttt_missionary_announce_proselytize",
        type = ROLE_CONVAR_TYPE_DROPDOWN,
        choices = {"Don't announce", "Announce as Missionary", "Announce as Marshal"},
        isNumeric = true
    },
    {
        cvar = "ttt_missionary_prevent_monk",
        type = ROLE_CONVAR_TYPE_BOOL
    }
}

ROLE.translations = {
    ["english"] = {
        ["mis_proselytizer_help_pri"] = "Hold {primaryfire} to proselytize a player.",
        ["mis_proselytizer_help_sec"] = "The target player will become {amonk}, {zealot}, or {hermit}",
        ["missionary_proselytize_announce"] = "{amissionary} has proselytized {target}",
        ["ev_missionary_proselytize"] = "{target} was proselytized by {missionary}"
    }
}

RegisterRole(ROLE)

local missionary_announce_proselytize = CreateConVar("ttt_missionary_announce_proselytize", "1", FCVAR_REPLICATED, "How a player being proselytized will be announced to everyone", 0, 2)

MISSIONARY_ANNOUNCE_NONE = 0
MISSIONARY_ANNOUNCE_AS_MISSIONARY = 1
MISSIONARY_ANNOUNCE_AS_MARSHAL = 2

if SERVER then
    AddCSLuaFile()

    ------------
    -- EVENTS --
    ------------

    AddHook("Initialize", "Missionary_Initialize", function()
        EVENT_PROSELYTIZED = GenerateNewEventID(ROLE_MISSIONARY)
    end)
end

if CLIENT then
    ------------
    -- EVENTS --
    ------------

    AddHook("TTTSyncEventIDs", "Missionary_TTTSyncEventIDs", function()
        EVENT_PROSELYTIZED = EVENTS_BY_ROLE[ROLE_MISSIONARY]
        local convert_icon = Material("icon16/star.png")
        local Event = CLSCORE.DeclareEventDisplay
        local PT = LANG.GetParamTranslation
        Event(EVENT_PROSELYTIZED, {
            text = function(e)
                return PT("ev_missionary_proselytize", {target = e.tar, missionary = e.ply})
            end,
            icon = function(e)
                return convert_icon, "Proselytized"
            end})
    end)

    local marshal_announce_deputy = GetConVar("ttt_marshal_announce_deputy")
    local detectives_hide_special_mode = GetConVar("ttt_detectives_hide_special_mode")

    net.Receive("TTT_Proselytized", function(len)
        local missionaryname = net.ReadString()
        local targetname = net.ReadString()
        local targetsid = net.ReadString()
        CLSCORE:AddEvent({
            id = EVENT_PROSELYTIZED,
            tar = targetname,
            ply = missionaryname,
            sid64 = targetsid,
            bonus = 1
        })

        local announce_proselytize = missionary_announce_proselytize:GetInt()
        local hide_special_mode = detectives_hide_special_mode:GetInt()

        if announce_proselytize ~= MISSIONARY_ANNOUNCE_NONE then
            local PT = LANG.GetParamTranslation
            local client = LocalPlayer()

            if announce_proselytize == MISSIONARY_ANNOUNCE_AS_MISSIONARY or hide_special_mode == SPECIAL_DETECTIVE_HIDE_NONE then
                local message = PT("missionary_proselytize_announce", {
                    target = targetname,
                    amissionary = string.Capitalize(ROLE_STRINGS_EXT[ROLE_MISSIONARY])
                })
                client:QueueMessage(MSG_PRINTBOTH, message)
            elseif announce_proselytize == MISSIONARY_ANNOUNCE_AS_MARSHAL and marshal_announce_deputy:GetBool() then
                local message = PT("marshal_deputize_announce", {
                    target = targetname,
                    amarshal = string.Capitalize(ROLE_STRINGS_EXT[ROLE_MARSHAL]),
                    adeputy = ROLE_STRINGS_EXT[ROLE_DEPUTY]
                })
                client:QueueMessage(MSG_PRINTBOTH, message)
            end
        end
    end)

    --------------
    -- TUTORIAL --
    --------------

    AddHook("TTTTutorialRoleText", "Missionary_TTTTutorialRoleText", function(role, titleLabel)
        if role ~= ROLE_MISSIONARY then return end

        local roleColor = ROLE_COLORS[ROLE_DETECTIVE]
        local innocentColor = ROLE_COLORS[ROLE_INNOCENT]
        local traitorColor = ROLE_COLORS[ROLE_TRAITOR]
        local hermitTeam = player.GetRoleTeam(ROLE_HERMIT, true)
        local _, hermitColor = GetRoleTeamInfo(hermitTeam, true)

        local html = "The " .. ROLE_STRINGS[ROLE_MISSIONARY] .. " is a " .. ROLE_STRINGS[ROLE_DETECTIVE] .. " and a member of the <span style='color: rgb(" .. innocentColor.r .. ", " .. innocentColor.g .. ", " .. innocentColor.b .. ")'>innocent team</span> whose job is to find and eliminate their enemies."

        html = html .. "<span style='display: block; margin-top: 10px;'>Instead of getting a DNA Scanner like a vanilla <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>" .. ROLE_STRINGS[ROLE_DETECTIVE] .. "</span>, they have the ability to proselytize another player to grant them special abilities if they die.</span>"

        html = html .. "<span style='display: block; margin-top: 10px;'>Proselytized innocents will become <span style='color: rgb(" .. innocentColor.r .. ", " .. innocentColor.g .. ", " .. innocentColor.b .. ")'>" .. ROLE_STRINGS_PLURAL[ROLE_MONK] .. "</span>, traitors will become <span style='color: rgb(" .. traitorColor.r .. ", " .. traitorColor.g .. ", " .. traitorColor.b .. ")'>" .. ROLE_STRINGS_PLURAL[ROLE_ZEALOT] .. "</span>, and anyone else will become <span style='color: rgb(" .. hermitColor.r .. ", " .. hermitColor.g .. ", " .. hermitColor.b .. ")'>" .. ROLE_STRINGS_EXT[ROLE_HERMIT] .. "</span>.</span>"

        local announce_proselytize = missionary_announce_proselytize:GetInt()
        if announce_proselytize ~= MISSIONARY_ANNOUNCE_NONE then
            if announce_proselytize == MISSIONARY_ANNOUNCE_AS_MISSIONARY or detectives_hide_special_mode:GetInt() == SPECIAL_DETECTIVE_HIDE_NONE then
                html = html .. "<span style='display: block; margin-top: 10px;'>When a player is proselytized it will be <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>announced to everybody</span>.</span>"
            elseif announce_proselytize == MISSIONARY_ANNOUNCE_AS_MARSHAL and marshal_announce_deputy:GetBool() then
                html = html .. "<span style='display: block; margin-top: 10px;'>When a player is proselytized it will be <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>announced to everybody</span>, however it will appear as if " .. ROLE_STRINGS_EXT[ROLE_MARSHAL] .. " has promoted a player.</span>"
            end
        end

        return html
    end)
end