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

-- TODO: Missionary role descriptions
ROLE.desc = [[You are {role}!]]
ROLE.shortdesc = ""

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
        ["mis_proselytizer_help_pri"] = "Hold {primaryfire} to deputize a player.",
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
    ------------------
    -- TRANSLATIONS --
    ------------------

    AddHook("Initialize", "Missionary_Translations_Initialize", function()
        -- This needs to happen after the Monk, Zealot and Hermit have been registered so we can't put it in ROLE.translations
        LANG.AddToLanguage("english", "mis_proselytizer_help_sec", "The target player will become " .. ROLE_STRINGS_EXT[ROLE_MONK] .. ", " .. ROLE_STRINGS[ROLE_ZEALOT] .. ", or " .. ROLE_STRINGS[ROLE_HERMIT])
    end)

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

    -- TODO: Missionary tutorial
end