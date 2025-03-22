local hook = hook
local math = math
local player = player
local table = table
local timer = timer

local AddHook = hook.Add
local PlayerIterator = player.Iterator
local MathRandom = math.random
local TableInsert = table.insert

local ROLE = {}

ROLE.nameraw = "barrelmimic"
ROLE.name = "Barrel Mimic"
ROLE.nameplural = "Barrel Mimics"
ROLE.nameext = "a Barrel Mimic"
ROLE.nameshort = "bam"

ROLE.desc = [[You are {role}! Use your Barrel Transformer to become an explodable barrel!
If you explode as a barrel and kill another player, you win!
Time your transformations so you do the most damage.]]
ROLE.shortdesc = "Becomes an explodable barrel on demand. If it explodes and kills a player, they win!"

ROLE.team = ROLE_TEAM_JESTER

ROLE.convars = {
    {
        cvar = "ttt_barrelmimic_notify_mode",
        type = ROLE_CONVAR_TYPE_DROPDOWN,
        choices = {"None", "Detective and Traitor", "Traitor", "Detective", "Everyone"},
        isNumeric = true
    },
    {
        cvar = "ttt_barrelmimic_notify_killer",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_barrelmimic_notify_sound",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_barrelmimic_notify_confetti",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_barrelmimic_announce",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_barrelmimic_respawn_all_deaths",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_barrelmimic_respawn_delay",
        type = ROLE_CONVAR_TYPE_NUM
    }
}

ROLE.translations = {
    ["english"] = {
        ["bam_transformer_help_pri"] = "Use {primaryfire} to transform into an explodable barrel",
        ["bam_transformer_help_sec"] = "Use {secondaryfire} to transform back",
        ["ev_win_barrelmimic"] = "The {role} has exploded its way to victory!"
    }
}

RegisterRole(ROLE)

local announce = CreateConVar("ttt_barrelmimic_announce", "1", FCVAR_REPLICATED, "Whether to announce that there is a barrel mimic", 0, 1)
local respawn_all_deaths = CreateConVar("ttt_barrelmimic_respawn_all_deaths", "1", FCVAR_REPLICATED, "Whether to respawn when the Barrel Mimic is killed in any way. If disabled, they will only respawn when killed as a barrel", 0, 1)
local respawn_delay = CreateConVar("ttt_barrelmimic_respawn_delay", "15", FCVAR_REPLICATED, "The delay before the Barrel Mimic is killed without winning the round. If set to 0, they will not respawn", 0, 60)

hook.Add("TTTIsPlayerRespawning", "BarrelMimic_TTTIsPlayerRespawning", function(ply)
    if not IsPlayer(ply) then return end
    if ply:Alive() then return end
    if not ply:IsBarrelMimic() then return end

    if ply.BarrelMimicIsRespawning then
        return true
    end
end)

if SERVER then
    AddCSLuaFile()

    util.AddNetworkString("TTT_UpdateBarrelMimicWins")
    util.AddNetworkString("TTT_ResetBarrelMimicWins")

    CreateConVar("ttt_barrelmimic_notify_mode", "0", FCVAR_NONE, "The logic to use when notifying players that a barrel mimic was killed. Killer is notified unless \"ttt_barrelmimic_notify_killer\" is disabled", 0, 4)
    CreateConVar("ttt_barrelmimic_notify_killer", "0", FCVAR_NONE, "Whether to notify a barrel mimic's killer", 0, 1)
    CreateConVar("ttt_barrelmimic_notify_sound", "0", FCVAR_NONE, "Whether to play a cheering sound when a barrel mimic is killed", 0, 1)
    CreateConVar("ttt_barrelmimic_notify_confetti", "0", FCVAR_NONE, "Whether to throw confetti when a barrel mimic is a killed", 0, 1)

    -----------
    -- KARMA --
    -----------

    -- Attacking the Barrel Mimic does not penalize karma
    AddHook("TTTKarmaShouldGivePenalty", "BarrelMimic_TTTKarmaShouldGivePenalty", function(attacker, victim)
        if not IsPlayer(victim) or not victim:IsBarrelMimic() then return end
        return false
    end)

    ------------------
    -- ANNOUNCEMENT --
    ------------------

    -- Warn other players that there is a barrel mimic
    AddHook("TTTBeginRound", "BarrelMimic_Announce_TTTBeginRound", function()
        if not announce:GetBool() then return end

        timer.Simple(1.5, function()
            local hasBarrelMimic = false
            for _, v in PlayerIterator() do
                if v:IsBarrelMimic() then
                    hasBarrelMimic = true
                end
            end

            if hasBarrelMimic then
                for _, v in PlayerIterator() do
                    if v:IsBarrelMimic() then continue end
                    v:QueueMessage(MSG_PRINTBOTH, "There is " .. ROLE_STRINGS_EXT[ROLE_BARRELMIMIC] .. ".")
                end
            end
        end)
    end)

    -------------
    -- RESPAWN --
    -------------

    local function BarrelMimicKilledNotification(attacker, victim, verb)
        JesterTeamKilledNotification(attacker, victim,
            -- getkillstring
            function()
                return attacker:Nick() .. " " .. verb .. " the " .. ROLE_STRINGS[ROLE_BARRELMIMIC] .. "!"
            end)
    end

    local respawnTimers = {}
    local function ClearRespawnTimer(ply)
        local sid64 = ply:SteamID64()
        if respawnTimers[sid64] then
            ply:ClearProperty("BarrelMimicIsRespawning")
            timer.Remove("TTTBarrelMimicRespawn_" .. sid64)
            respawnTimers[sid64] = nil
        end
    end

    local function StartRespawnTimer(ply)
        ply.BarrelMimicEnt = nil

        local delay = respawn_delay:GetInt()
        if delay <= 0 then return end

        ply:QueueMessage(MSG_PRINTBOTH, "You've died without killing anyone as a barrel. You will respawn in " .. delay .. " seconds.")
        ply:SetProperty("BarrelMimicIsRespawning", true)

        local sid64 = ply:SteamID64()
        local respawnId = "TTTBarrelMimicRespawn_" .. sid64
        respawnTimers[sid64] = respawnId

        timer.Create(respawnId, delay, 1, function()
            if not IsValid(ply) then return end

            ClearRespawnTimer(ply)

            -- In case something else respawned them already
            if ply:Alive() then return end
            -- Just in case something changed their role while they were dead
            if not ply:IsBarrelMimic() then return end

            local body = ply.server_ragdoll or ply:GetRagdollEntity()
            ply:SpawnForRound(true)
            SafeRemoveEntity(body)

            -- Respawn the player at a random map spawn
            local spawns = GetSpawnEnts(true, false)
            local spawn = spawns[MathRandom(#spawns)]
            local spawnPos = spawn:GetPos()
            ply:SetPos(FindRespawnLocation(spawnPos) or spawnPos)

            -- Select the crowbar so their barrel thing isn't showing when they respawn
            ply:Give("weapon_zm_improvised")
            ply:SelectWeapon("weapon_zm_improvised")

            ply:QueueMessage(MSG_PRINTBOTH, "You have respawned. Good luck =)")
        end)
    end

    local barrelMimicWins = false
    -- Respawn the Barrel Mimic if their barrel explodes but they don't kill anyone
    -- This appears to happen AFTER the PlayerDeath hook so all we need to do is check if they've won
    AddHook("EntityRemoved", "BarrelMimic_EntityRemoved", function(ent)
        if barrelMimicWins then return end
        if not IsPlayer(ent.BarrelMimic) then return end

        local ply = ent.BarrelMimic
        -- Check active because we don't want to start a respawn timer if their barrel is removed because the round is ending
        if not ply:IsActiveBarrelMimic() then return end

        ply:Kill()
        ply.BarrelMimicEnt = nil
        StartRespawnTimer(ply)
    end)

    AddHook("PostEntityTakeDamage", "BarrelMimic_PostEntityTakeDamage", function(ent, dmginfo, wasDamageTaken)
        if not wasDamageTaken then return end
        local victim = ent.BarrelMimic
        if not IsPlayer(victim) then return end

        local attacker = dmginfo:GetAttacker()
        if not IsPlayer(attacker) then return end

        if victim == attacker then return end
        if dmginfo:GetDamage() < ent:GetMaxHealth() then return end

        BarrelMimicKilledNotification(dmginfo:GetAttacker(), ent.BarrelMimic, "exploded")
    end)

    AddHook("TTTStopPlayerRespawning", "BarrelMimic_TTTStopPlayerRespawning", function(ply)
        if not IsPlayer(ply) then return end
        if ply:Alive() then return end
        if not ply:IsBarrelMimic() then return end

        ClearRespawnTimer(ply)
    end)

    ----------------
    -- WIN CHECKS --
    ----------------

    AddHook("PlayerDeath", "BarrelMimic_PlayerDeath", function(victim, inflictor, attacker)
        if barrelMimicWins then return end

        if IsPlayer(victim) and victim:IsBarrelMimic() then
            local valid_kill = IsPlayer(attacker) and attacker ~= victim and GetRoundState() == ROUND_ACTIVE
            if not valid_kill then return end

            BarrelMimicKilledNotification(attacker, victim, "eliminated")

            -- Respawn this barrel mimic if they were killed while a barrel or all deaths allow respawn
            if IsValid(victim.BarrelMimicEnt) or respawn_all_deaths:GetBool() then
                StartRespawnTimer(victim)
            end
            return
        end

        if not IsValid(inflictor) then return end
        if not IsPlayer(inflictor.BarrelMimic) then return end
        if not inflictor.BarrelMimic:IsBarrelMimic() then return end

        barrelMimicWins = true
        net.Start("TTT_UpdateBarrelMimicWins")
        net.Broadcast()

        inflictor.BarrelMimic:QueueMessage(MSG_PRINTBOTH, "Success! Your barrel has killed a player!")
        inflictor.BarrelMimic:Kill()
        inflictor.BarrelMimic.BarrelMimicEnt = nil
    end)

    AddHook("Initialize", "BarrelMimic_Initialize", function()
        WIN_BARRELMIMIC = GenerateNewWinID(ROLE_BARRELMIMIC)
    end)

    -------------
    -- CLEANUP --
    -------------

    AddHook("TTTPrepareRound", "BarrelMimic_TTTPrepareRound", function()
        for _, v in PlayerIterator() do
            ClearRespawnTimer(v)
            -- If this player has a barrel attached to them (and vice versa), detach it
            if v.BarrelMimicEnt then
                v.BarrelMimicEnt = nil
                v:SetParent(nil)
            end
        end
        table.Empty(respawnTimers)

        barrelMimicWins = false
        net.Start("TTT_ResetBarrelMimicWins")
        net.Broadcast()
    end)

    AddHook("TTTBeginRound", "BarrelMimic_TTTBeginRound", function()
        barrelMimicWins = false
        net.Start("TTT_ResetBarrelMimicWins")
        net.Broadcast()
    end)
end

if CLIENT then
    ----------------
    -- WIN CHECKS --
    ----------------

    AddHook("TTTSyncWinIDs", "BarrelMimic_TTTSyncWinIDs", function()
        WIN_BARRELMIMIC = WINS_BY_ROLE[ROLE_BARRELMIMIC]
    end)

    local barrelMimicWins = false
    net.Receive("TTT_UpdateBarrelMimicWins", function()
        -- Log the win event with an offset to force it to the end
        barrelMimicWins = true
        CLSCORE:AddEvent({
            id = EVENT_FINISH,
            win = WIN_BARRELMIMIC
        }, 1)
    end)

    local function ResetBarrelMimicWin()
        barrelMimicWins = false
    end
    net.Receive("TTT_ResetBarrelMimicWins", ResetBarrelMimicWin)
    AddHook("TTTPrepareRound", "BarrelMimic_WinTracking_TTTPrepareRound", ResetBarrelMimicWin)
    AddHook("TTTBeginRound", "BarrelMimic_WinTracking_TTTBeginRound", ResetBarrelMimicWin)

    AddHook("TTTScoringSecondaryWins", "BarrelMimic_TTTScoringSecondaryWins", function(wintype, secondary_wins)
        if barrelMimicWins then
            TableInsert(secondary_wins, ROLE_BARRELMIMIC)
        end
    end)

    ------------
    -- EVENTS --
    ------------

    AddHook("TTTEventFinishText", "BarrelMimic_TTTEventFinishText", function(e)
        if e.win == WIN_BARRELMIMIC then
            return LANG.GetParamTranslation("ev_win_barrelmimic", { role = string.lower(ROLE_STRINGS[ROLE_BARRELMIMIC]) })
        end
    end)

    AddHook("TTTEventFinishIconText", "BarrelMimic_TTTEventFinishIconText", function(e, win_string, role_string)
        if e.win == WIN_BARRELMIMIC then
            return "ev_win_icon_also", ROLE_STRINGS[ROLE_BARRELMIMIC]
        end
    end)

    --------------
    -- TUTORIAL --
    --------------

    AddHook("TTTTutorialRoleText", "BarrelMimic_TTTTutorialRoleText", function(role, titleLabel)
        if role ~= ROLE_BARRELMIMIC then return end

        local roleColor = ROLE_COLORS[ROLE_BARRELMIMIC]
        local html = "The " .. ROLE_STRINGS[ROLE_BARRELMIMIC] .. " is a <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>jester</span> role who wins by transforming into a barrel, being exploded, and killing other players."

        if announce:GetBool() then
            html = html .. "<span style='display: block; margin-top: 10px;'>The presence of " .. ROLE_STRINGS_EXT[ROLE_BARRELMIMIC] .. " is <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>announced</span> to everyone!</span>"
        end

        local delay = respawn_delay:GetInt()
        if delay > 0 then
            html = html .. "<span style='display: block; margin-top: 10px;'>If the " .. ROLE_STRINGS[ROLE_BARRELMIMIC] .. " is "
            if respawn_all_deaths:GetBool() then
                html = html .. "killed"
            else
                html = html .. "exploded as a barrel"
            end
            html = html .. " <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>without killing another player first</span>, they respawn after " .. delay .. " seconds!</span>"
        end

        return html
    end)
end