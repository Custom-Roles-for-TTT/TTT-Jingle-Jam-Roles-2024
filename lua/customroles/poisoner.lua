local hook = hook
local player = player

local AddHook = hook.Add
local PlayerIterator = player.Iterator

local ROLE = {}

ROLE.nameraw = "poisoner"
ROLE.name = "Poisoner"
ROLE.nameplural = "Poisoners"
ROLE.nameext = "a Poisoner"
ROLE.nameshort = "pnr"

ROLE.desc = [[You are {role}! {comrades}

Use your Poison Gun to disable a player's role ability to help your team win!

Press {menukey} to receive your special equipment!]]
ROLE.shortdesc = "Can poison a player, disabling their role ability"

ROLE.team = ROLE_TEAM_TRAITOR

ROLE.convars = {
    {
        cvar = "ttt_poisoner_is_independent",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_poisoner_target_jesters",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_poisoner_target_independents",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_poisoner_block_shop_roles",
        type = ROLE_CONVAR_TYPE_TEXT
    },
    {
        cvar = "ttt_poisoner_cure_on_death",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_poisoner_notify_start",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_poisoner_notify_end",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_poisoner_poison_duration",
        type = ROLE_CONVAR_TYPE_NUM
    },
    {
        cvar = "ttt_poisoner_can_see_jesters",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_poisoner_update_scoreboard",
        type = ROLE_CONVAR_TYPE_BOOL
    }
}

ROLE.selectionpredicate = function()
    return CRVersion("2.2.9")
end

ROLE.translations = {
    ["english"] = {
        ["poisoner_poisoned"] = "POISONED",
        ["ev_poisonerpoison"] = "{victim} was poisoned by {source}",
        ["poisoner_body_poisoned"] = "They were poisoned {time} ago by {apoisoner}!",
        ["ev_win_poisoner"] = "The deadly {role} has won the round!",
        ["win_poisoner"] = "The {role} has devastated you all!",
        ["info_popup_poisoner_indep"] = [[You are {role}!

Use your Poison Gun to disable a player's role ability to help your team win!]]
    }
}

RegisterRole(ROLE)

local poisoner_is_independent = CreateConVar("ttt_poisoner_is_independent", 0, FCVAR_REPLICATED, "Whether Poisoners should be treated as independent", 0, 1)
local poisoner_target_jesters = CreateConVar("ttt_poisoner_target_jesters", "0", FCVAR_REPLICATED, "Whether the Poisoner can target jesters", 0, 1)
local poisoner_target_independents = CreateConVar("ttt_poisoner_target_independents", "1", FCVAR_REPLICATED, "Whether the Poisoner can target independents", 0, 1)
local poisoner_block_shop_roles = CreateConVar("ttt_poisoner_block_shop_roles", "mercenary", FCVAR_REPLICATED, "Names of roles that have their shop blocked when poisoned, separated with commas. Do not include spaces or capital letters")
local poisoner_poison_duration = CreateConVar("ttt_poisoner_poison_duration", "0", FCVAR_REPLICATED, "How long a Poisoner's poison should last on their target. Poisoner is refunded Poison Gun ammo when it expires. Set to 0 to have it be permanent", 0, 300)
local poisoner_cure_on_death = CreateConVar("ttt_poisoner_cure_on_death", "1", FCVAR_REPLICATED, "Whether a Poisoner's target should be cured if the Poisoner dies", 0, 1)
-- Independent ConVars
CreateConVar("ttt_poisoner_can_see_jesters", "0", FCVAR_REPLICATED)
CreateConVar("ttt_poisoner_update_scoreboard", "0", FCVAR_REPLICATED)

local blockedShopRoles = {}
AddHook("TTTPrepareRound", "Poisoner_ShopRoles_TTTPrepareRound", function()
    local blockedShopRolesString = poisoner_block_shop_roles:GetString()
    if #blockedShopRolesString == 0 then return end

    local blockedShopRolesStrings = string.Explode(",", blockedShopRolesString)
    blockedShopRoles = {}
    for r, s in pairs(ROLE_STRINGS_RAW) do
        if table.HasValue(blockedShopRolesStrings, s) then
            blockedShopRoles[r] = true
        end
    end
end)

-----------------
-- REFUND AMMO --
-----------------

local function RefundPoisonAmmo(ply)
    if not SERVER then return end

    local poisonGun = ply:GetWeapon("weapon_pnr_poisongun")
    if not IsValid(poisonGun) then return end
    poisonGun:SetClip1(poisonGun:Clip1() + 1)
    ply:QueueMessage(MSG_PRINTBOTH, "You have been refunded ammunition for your Poison Gun!")
end

-----------------
-- TEAM CHANGE --
-----------------

AddHook("TTTUpdateRoleState", "Poisoner_TTTUpdateRoleState", function()
    local is_independent = poisoner_is_independent:GetBool()
    INDEPENDENT_ROLES[ROLE_POISONER] = is_independent
    TRAITOR_ROLES[ROLE_POISONER] = not is_independent
end)

----------
-- CURE --
----------

AddHook("TTTCanCureableRoleSpawn", "Poisoner_TTTCanCureableRoleSpawn", function()
    if util.CanRoleSpawn(ROLE_POISONER) then
        return true
    end
end)

--------------------
-- PLAYER METHODS --
--------------------

local plymeta = FindMetaTable("Player")

function plymeta:RemovePoisonerPoison()
    if SERVER then
        local poisonerSid64 = self.TTTPoisonerPoisonedBy
        local poisoner = player.GetBySteamID64(poisonerSid64)
        if IsPlayer(poisoner) then
            poisoner:ClearProperty("TTTPoisonerPoisonTarget")
        end
        self:ClearProperty("TTTPoisonerPoisonedBy")

        self:ClearProperty("TTTPoisonerStartTime")
        self:ClearProperty("TTTPoisonerPoisoned")

        net.Start("TTT_PoisonerUnpoisoned")
            net.WritePlayer(self)
        net.Broadcast()

        if blockedShopRoles[self:GetRole()] then
            self:EnableShopPurchases()
        end
    end
    self:EnableRoleAbility()
end

function plymeta:AddPoisonerPoison(poisoner)
    if self:IsJesterTeam() and not poisoner_target_jesters:GetBool() then
        return false
    elseif self:IsIndependentTeam() and not poisoner_target_independents:GetBool() then
        return false
    end

    if SERVER then
        poisoner:SetProperty("TTTPoisonerPoisonTarget", self:SteamID64())
        self:SetProperty("TTTPoisonerPoisonedBy", poisoner:SteamID64())

        self:SetProperty("TTTPoisonerStartTime", CurTime())
        self:SetProperty("TTTPoisonerPoisoned", true)

        net.Start("TTT_PoisonerPoisoned")
            net.WritePlayer(self)
            net.WritePlayer(poisoner)
        net.Broadcast()

        if blockedShopRoles[self:GetRole()] then
            self:DisableShopPurchases()
        end
    end
    self:DisableRoleAbility()

    return true
end

function plymeta:IsPoisonerPoisoned()
    return self.TTTPoisonerPoisoned == true
end

if SERVER then
    AddCSLuaFile()

    util.AddNetworkString("TTT_PoisonerPoisoned")
    util.AddNetworkString("TTT_PoisonerUnpoisoned")

    local poisoner_refund_on_death = CreateConVar("ttt_poisoner_refund_on_death", "0", FCVAR_NONE, "Whether a Poisoner should get their Poison Gun ammo refunded if their target dies", 0, 1)
    local poisoner_refund_on_death_delay = CreateConVar("ttt_poisoner_refund_on_death_delay", "0", FCVAR_NONE, "How long after a Poisoner's target dies before they should be refunded their Poison Gun ammo. Only used when \"ttt_poisoner_refund_on_death\" is enabled", 0, 120)
    local poisoner_notify_start = CreateConVar("ttt_poisoner_notify_start", "0", FCVAR_NONE, "Whether to notify a Poisoner's target when they are poisoned", 0, 1)
    local poisoner_notify_end = CreateConVar("ttt_poisoner_notify_end", "0", FCVAR_NONE, "Whether to notify a Poisoner's target when they are unpoisoned", 0, 1)

    ----------
    -- INIT --
    ----------

    AddHook("Initialize", "Poisoner_Initialize", function()
        WIN_POISONER = GenerateNewWinID(ROLE_POISONER)
        EVENT_POISONERPOISONED = GenerateNewEventID(ROLE_POISONER)
    end)

    ------------
    -- NOTIFY --
    ------------

    local function OnPoisoned(ply)
        if not poisoner_notify_start:GetBool() then return end
        if not IsPlayer(ply) then return end
        if not ply:IsPoisonerPoisoned() then return end
        ply:QueueMessage(MSG_PRINTBOTH, "You're feeling a little weak...")
    end

    local function OnUnpoisoned(ply)
        if not poisoner_notify_start:GetBool() then return end
        if not poisoner_notify_end:GetBool() then return end
        if not IsPlayer(ply) then return end
        if not ply:IsPoisonerPoisoned() then return end
        ply:QueueMessage(MSG_PRINTBOTH, "You're feeling better =)")
    end

    AddHook("TTTOnRoleAbilityDisabled", "Poisoner_Notify_TTTOnRoleAbilityDisabled", OnPoisoned)
    AddHook("TTTOnRoleAbilityEnabled", "Poisoner_Notify_TTTOnRoleAbilityEnabled", OnUnpoisoned)
    AddHook("TTTOnShopPurchaseDisabled", "Poisoner_Notify_TTTOnShopPurchaseDisabled", OnPoisoned)
    AddHook("TTTOnShopPurchaseEnabled", "Poisoner_Notify_TTTOnShopPurchaseEnabled", OnUnpoisoned)

    -----------------
    -- REFUND AMMO --
    -----------------

    AddHook("PostPlayerDeath", "Poisoner_Refund_PostPlayerDeath", function(ply)
        if not poisoner_refund_on_death:GetBool() then return end
        if not ply.TTTPoisonerPoisoned then return end

        local poisonerSid64 = ply.TTTPoisonerPoisonedBy
        local poisoner = player.GetBySteamID64(poisonerSid64)
        if not IsPlayer(poisoner) then return end

        local delay = poisoner_refund_on_death_delay:GetInt()
        if delay > 0 then
            timer.Create("TTTPoisonerRefundDelay_" .. poisonerSid64, delay, 1, function()
                if not IsPlayer(poisoner) then return end
                RefundPoisonAmmo(poisoner)
            end)
        else
            RefundPoisonAmmo(poisoner)
        end
    end)

    AddHook("PlayerDisconnected", "Poisoner_Refund_PlayerDisconnected", function(ply)
        if not ply.TTTPoisonerPoisoned then return end

        local poisonerSid64 = ply.TTTPoisonerPoisonedBy
        local poisoner = player.GetBySteamID64(poisonerSid64)
        if not IsPlayer(poisoner) then return end

        RefundPoisonAmmo(poisoner)
    end)

    ----------
    -- CURE --
    ----------

    AddHook("PostPlayerDeath", "Poisoner_Cure_PostPlayerDeath", function(ply)
        if not ply:IsPoisoner() then return end
        if not poisoner_cure_on_death:GetBool() then return end

        local targetSid64 = ply.TTTPoisonerPoisonTarget
        local target = player.GetBySteamID64(targetSid64)
        if not IsPlayer(target) then return end

        target:RemovePoisonerPoison()
    end)

    AddHook("TTTPlayerAliveThink", "Poisoner_TTTPlayerAliveThink", function(ply)
        if not IsValid(ply) or ply:IsSpec() or GetRoundState() ~= ROUND_ACTIVE then return end
        local duration = poisoner_poison_duration:GetInt()
        if duration <= 0 then return end

        local curTime = CurTime()
        for _, p in PlayerIterator() do
            if not p:Alive() or p:IsSpec() then continue end
            if not p.TTTPoisonerPoisoned then continue end

            local poisonStartTime = p.TTTPoisonerStartTime
            if curTime >= poisonStartTime + duration then
                local poisonerSid64 = p.TTTPoisonerPoisonedBy
                local poisoner = player.GetBySteamID64(poisonerSid64)
                if IsPlayer(poisoner) then
                    RefundPoisonAmmo(poisoner)
                end

                p:RemovePoisonerPoison()
            end
        end
    end)

    AddHook("TTTCanPlayerBeCured", "Poisoner_TTTCanPlayerBeCured", function(ply)
        if ply:IsPoisonerPoisoned() then
            return true
        end
    end)

    AddHook("TTTCurePlayer", "Poisoner_TTTCurePlayer", function(ply)
        if not ply:IsPoisonerPoisoned() then return end
        ply:RemovePoisonerPoison()
    end)

    ----------------
    -- WIN CHECKS --
    ----------------

    AddHook("TTTCheckForWin", "Poisoner_CheckForWin", function()
        if not INDEPENDENT_ROLES[ROLE_POISONER] then return end

        local poisoner_alive = false
        local other_alive = false
        for _, v in PlayerIterator() do
            if v:Alive() and v:IsTerror() then
                if v:IsPoisoner() then
                    poisoner_alive = true
                elseif not v:ShouldActLikeJester() and not ROLE_HAS_PASSIVE_WIN[v:GetRole()] then
                    other_alive = true
                end
            end
        end

        if poisoner_alive and not other_alive then
            return WIN_POISONER
        elseif poisoner_alive then
            return WIN_NONE
        end
    end)

    AddHook("TTTPrintResultMessage", "Poisoner_PrintResultMessage", function(type)
        if type == WIN_POISONER then
            LANG.Msg("win_poisoner", { role = ROLE_STRINGS[ROLE_POISONER] })
            ServerLog("Result: " .. ROLE_STRINGS[ROLE_POISONER] .. " wins.\n")
            return true
        end
    end)

    -------------
    -- CLEANUP --
    -------------

    local function ResetState(ply)
        timer.Remove("TTTPoisonerRefundDelay_" .. ply:SteamID64())
        ply:ClearProperty("TTTPoisonerPoisonTarget")
        ply:ClearProperty("TTTPoisonerPoisonedBy")
        ply:ClearProperty("TTTPoisonerStartTime")
        ply:ClearProperty("TTTPoisonerPoisoned")
    end

    AddHook("TTTPrepareRound", "Poisoner_TTTPrepareRound", function()
        for _, v in PlayerIterator() do
            ResetState(v)
        end
    end)

    AddHook("TTTBeginRound", "Poisoner_TTTBeginRound", function()
        for _, v in PlayerIterator() do
            ResetState(v)
        end
    end)
end

if CLIENT then
    ---------------
    -- TARGET ID --
    ---------------

    -- Show "POISONED" label on players who have been infected
    AddHook("TTTTargetIDPlayerText", "Poisoner_TTTTargetIDPlayerText", function(ent, cli, text, col, secondaryText)
        if GetRoundState() < ROUND_ACTIVE then return end
        if not IsPlayer(ent) then return end
        if not cli:IsPoisoner() then return end

        if not ent:IsPoisonerPoisoned() then return end

        local T = LANG.GetTranslation
        if text == nil then
            return T("poisoner_poisoned"), ROLE_COLORS[ROLE_TRAITOR]
        end
        return text, col, T("poisoner_poisoned"), ROLE_COLORS[ROLE_TRAITOR]
    end)

    -- NOTE: ROLE_IS_TARGETID_OVERRIDDEN is not required since only secondary text is being changed and that is not tracked there

    --------------------
    -- BODY SEARCHING --
    --------------------

    AddHook("TTTBodySearchPopulate", "Poisoner_TTTBodySearchPopulate", function(search, raw)
        local rag = Entity(raw.eidx)
        if not IsValid(rag) then return end

        local ply = CORPSE.GetPlayer(rag)
        if not IsPlayer(ply) then return end

        local poison_start = ply.TTTPoisonerStartTime
        if not poison_start then return end

        local time = util.SimpleTime(CurTime() - poison_start, "%02i:%02i")
        local message = LANG.GetParamTranslation("poisoner_body_poisoned", {time = time, apoisoner = ROLE_STRINGS_EXT[ROLE_POISONER]})

        search["poisonerpoison"] = {
            text = message,
            img = "vgui/ttt/icon_poisonerpoison",
            text_icon = time,
            p = 10
        }
    end)

    -------------
    -- SCORING --
    -------------

    AddHook("TTTSyncEventIDs", "Poisoner_TTTSyncEventIDs", function()
        EVENT_POISONERPOISONED = EVENTS_BY_ROLE[ROLE_POISONER]
        local poisoner_icon = Material("icon16/asterisk_yellow.png")
        local Event = CLSCORE.DeclareEventDisplay
        local PT = LANG.GetParamTranslation

        Event(EVENT_POISONERPOISONED, {
            text = function(e)
                return PT("ev_poisonerpoison", {victim = e.vic, source = e.src})
            end,
            icon = function(e)
                return poisoner_icon, "Poisoned"
            end})
    end)

    net.Receive("TTT_PoisonerPoisoned", function(len)
        local victim = net.ReadPlayer()
        local source = net.ReadPlayer()
        CLSCORE:AddEvent({
            id = EVENT_POISONERPOISONED,
            vic = victim:Nick(),
            src = source:Nick()
        })
        victim:AddPoisonerPoison(source)
    end)

    net.Receive("TTT_PoisonerUnpoisoned", function(len)
        local victim = net.ReadPlayer()
        victim:RemovePoisonerPoison()
    end)

    ----------------
    -- WIN EVENTS --
    ----------------

    AddHook("TTTSyncWinIDs", "Poisoner_TTTWinIDsSynced", function()
        WIN_POISONER = WINS_BY_ROLE[ROLE_POISONER]
    end)

    AddHook("TTTEventFinishText", "Poisoner_EventFinishText", function(e)
        if e.win == WIN_POISONER then
            return LANG.GetParamTranslation("ev_win_poisoner", { role = string.lower(ROLE_STRINGS[ROLE_POISONER]) })
        end
    end)

    AddHook("TTTEventFinishIconText", "Poisoner_EventFinishIconText", function(e, win_string, role_string)
        if e.win == WIN_POISONER then
            return win_string, ROLE_STRINGS[ROLE_POISONER]
        end
    end)

    AddHook("TTTScoringWinTitle", "Poisoner_ScoringWinTitle", function(wintype, wintitles, title, secondaryWinRole)
        if wintype == WIN_POISONER then
            return { txt = "hilite_win_role_singular", params = { role = string.upper(ROLE_STRINGS[ROLE_POISONER]) }, c = ROLE_COLORS[ROLE_POISONER] }
        end
    end)

    ----------------
    -- ROLE POPUP --
    ----------------

    hook.Add("TTTRolePopupRoleStringOverride", "Poisoner_TTTRolePopupRoleStringOverride", function(cli, roleString)
        if not IsPlayer(cli) or not cli:IsPoisoner() then return end

        if INDEPENDENT_ROLES[ROLE_POISONER] then
            return roleString .. "_indep"
        end
    end)

    --------------
    -- TUTORIAL --
    --------------

    AddHook("TTTTutorialRoleText", "Poisoner_TTTTutorialRoleText", function(role, titleLabel)
        if role ~= ROLE_POISONER then return end

        local roleColor = ROLE_COLORS[ROLE_POISONER]
        local roleTeam = player.GetRoleTeam(ROLE_POISONER)
        local roleTeamName, _ = GetRoleTeamInfo(roleTeam)

        local article = "a"
        if roleTeam == ROLE_TEAM_INDEPENDENT then
            article = "an"
        end
        local html = "The " .. ROLE_STRINGS[ROLE_POISONER] .. " is " .. article .. " <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>" .. roleTeamName .. "</span> role that can use their Poison Gun to poison another player."

        local duration = poisoner_poison_duration:GetInt()
        html = html .. "<span style='display: block; margin-top: 10px;'>A poisoned player <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>has their role ability disabled</span> "
        if duration > 0 then
            html = html .. "for " .. duration .. " second(s)"
        elseif poisoner_cure_on_death:GetBool() then
            html = html .. "until the " .. ROLE_STRINGS[ROLE_POISONER] .. " is killed"
        else
            html = html .. "for the remainder of the round"
        end
        html = html .. ".</span>"

        html = html .. "<span style='display: block; margin-top: 10px;'>The " .. ROLE_STRINGS[ROLE_POISONER] .. " can target <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>any player"
        local target_jesters = poisoner_target_jesters:GetBool()
        local target_independents = poisoner_target_independents:GetBool()
        if not target_jesters or not target_independents then
            html = html .. " except "
            if not target_jesters then
                html = html .. LANG.GetTranslation("jesters")
                if not target_independents then
                    html = html .. " and "
                end
            end
            if not target_independents then
                html = html .. LANG.GetTranslation("independents")
            end
        end
        html = html .. "</span>.</span>"

        return html
    end)
end