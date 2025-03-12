local hook = hook
local player = player

local AddHook = hook.Add
local PlayerIterator = player.Iterator

local ROLE = {}

ROLE.nameraw = "hoodoo"
ROLE.name = "Hoodoo"
ROLE.nameplural = "Hoodoos"
ROLE.nameext = "a Hoodoo"
ROLE.nameshort = "hoo"
ROLE.team = ROLE_TEAM_TRAITOR
ROLE.desc = [[You are {role}! {comrades}]]
ROLE.shortdesc = "Can buy Traitor-focused Randomat events from their shop to help or to hurt."

ROLE.shop = {"weapon_ttt_randomat"}

ROLE.loadout = {}
ROLE.startingcredits = 0
ROLE.selectionpredicate = function() return Randomat and type(Randomat.IsInnocentTeam) == "function" end

ROLE.convars = {
    {
        cvar = "ttt_hoodoo_banned_randomats",
        type = ROLE_CONVAR_TYPE_TEXT
    },
    {
        cvar = "ttt_hoodoo_guaranteed_categories",
        type = ROLE_CONVAR_TYPE_TEXT
    },
    {
        cvar = "ttt_hoodoo_banned_categories",
        type = ROLE_CONVAR_TYPE_TEXT
    },
    {
        cvar = "ttt_hoodoo_guaranteed_randomats",
        type = ROLE_CONVAR_TYPE_TEXT
    },
    {
        cvar = "ttt_hoodoo_guarantee_pockets_event",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_hoodoo_event_on_unbought_death",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_hoodoo_choose_event_on_drop",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_hoodoo_choose_event_on_drop_count",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 0
    },
    {
        cvar = "ttt_hoodoo_prevent_auto_randomat",
        type = ROLE_CONVAR_TYPE_BOOL
    }
}

RegisterRole(ROLE)

local hoodoo_prevent_auto_randomat = CreateConVar("ttt_hoodoo_prevent_auto_randomat", 1, FCVAR_REPLICATED, "Prevent auto-randomat triggering if there is a hoodoo at the start of the round", 0, 1)

if SERVER then
    local hoodoo_event_on_unbought_death = CreateConVar("ttt_hoodoo_event_on_unbought_death", 0, FCVAR_NONE, "Whether a randomat should trigger if a hoodoo dies and never bought anything that round", 0, 1)
    local hoodoo_choose_event_on_drop = CreateConVar("ttt_hoodoo_choose_event_on_drop", 1, FCVAR_NONE, "Whether the held randomat item should always trigger \"Choose an event!\" after being bought by a hoodoo and dropped on the ground", 0, 1)
    local hoodoo_choose_event_on_drop_count = CreateConVar("ttt_hoodoo_choose_event_on_drop_count", 5, FCVAR_NONE, "The number of events a player should be able to choose from when using a dropped randomat", 1, 10)

    -- Prevents auto-randomat triggering if there is a Hoodoo alive
    AddHook("TTTRandomatShouldAuto", "StopAutoRandomatWithHoodoo", function()
        if hoodoo_prevent_auto_randomat:GetBool() and player.IsRoleLiving(ROLE_HOODOO) then return false end
    end)

    local blockedEvents = {
        ["blackmarket"] = "removes the main feature of the role",
        ["credits"] = "makes their role overpowered",
        ["future"] = "can't consistently work with the dynamic shop events"
    }

    -- Prevents a randomat from ever triggering if there is a hoodoo in the round
    AddHook("TTTRandomatCanEventRun", "Hoodoo_TTTRandomatCanEventRun", function(event)
        if not blockedEvents[event.Id] then return end

        for _, ply in PlayerIterator() do
            if ply:IsHoodoo() then return false, "There is " .. ROLE_STRINGS_EXT[ROLE_HOODOO] .. " in the round and this event " .. blockedEvents[event.Id] end
        end
    end)

    local boughtAsHoodoo = {}
    AddHook("TTTOrderedEquipment", "Hoodoo_TTTOrderedEquipment", function(ply, id, is_item, from_randomat)
        if not ply:IsHoodoo() then return end

        -- Let the hoodoo be able to drop the randomat
        if id == "weapon_ttt_randomat" then
            local wep = ply:GetWeapon("weapon_ttt_randomat")

            if IsValid(wep) then
                wep.AllowDrop = true

                -- If the convar is enabled and the hoodoo drops this item, it is guaranteed to trigger "Choose an event!" on being picked up and used,
                -- which gives the player a choice of 5 randomats to trigger.
                -- This is so the hoodoo is able to give other players an interesting item, most notably for players that are the beggar role
                if hoodoo_choose_event_on_drop:GetBool() then
                    function wep:OnDrop()
                        self.EventId = "choose"
                        -- Vote, DeadCanVote, VotePredicate, ChoiceCount
                        self.EventArgs = {false, false, nil, hoodoo_choose_event_on_drop_count:GetInt()}
                        self.EventSilent = true
                    end
                end
            end
        end

        -- Detecting if the hoodoo has bought anything
        if not from_randomat then
            boughtAsHoodoo[ply] = true
        end
    end)

    AddHook("TTTPrepareRound", "Hoodoo_TTTPrepareRound", function()
        table.Empty(boughtAsHoodoo)
    end)

    -- Triggering a random event if the hoodoo dies and hasn't bought anything, and the convar is enabled
    AddHook("PostPlayerDeath", "Hoodoo_PostPlayerDeath", function(ply)
        if GetRoundState() ~= ROUND_ACTIVE then return end
        if not hoodoo_event_on_unbought_death:GetBool() then return end
        if not ply:IsHoodoo() then return end
        if not boughtAsHoodoo[ply] then return end

        Randomat:TriggerRandomEvent(ply)
        -- Just in case the hoodoo somehow respawns, only trigger a randomat on death once
        boughtAsHoodoo[ply] = true
    end)
end

if CLIENT then
    --------------
    -- TUTORIAL --
    --------------

    AddHook("TTTTutorialRoleText", "Hoodoo_TTTTutorialRoleText", function(role, titleLabel)
        if role ~= ROLE_HOODOO then return end

        local T = LANG.GetTranslation
        local roleColor = ROLE_COLORS[ROLE_TRAITOR]

        local html = "The " .. ROLE_STRINGS[ROLE_HOODOO] .. " is a member of the <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>" .. T("traitor") .. " team</span> who is able to buy " .. T("traitor") .. "-focused randomat events, rather than items."

        html = html .. "<span style='display: block; margin-top: 10px;'>The available randomat events <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>change each round</span>, and are shared between everyone who is a " .. ROLE_STRINGS[ROLE_HOODOO] .. ".<br><br>Some randomat events <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>cannot be bought</span>, such as ones that are supposed to start secretly.</span>"

        if hoodoo_prevent_auto_randomat:GetBool() and GetConVar("ttt_randomat_auto"):GetBool() then
            html = html .. "<span style='display: block; margin-top: 10px;'>If " .. ROLE_STRINGS_EXT[ROLE_HOODOO] .. " spawns at the start of the round, <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>no randomat automatically triggers</span>.</span>"
        end

        return html
    end)
end
