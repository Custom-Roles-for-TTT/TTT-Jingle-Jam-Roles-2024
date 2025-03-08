local hook = hook
local player = player
local timer = timer

local AddHook = hook.Add
local PlayerIterator = player.Iterator

local ROLE = {}

ROLE.nameraw = "barrelmimic"
ROLE.name = "Barrel Mimic"
ROLE.nameplural = "Barrel Mimic"
ROLE.nameext = "a Barrel Mimic"
ROLE.nameshort = "bam"

ROLE.desc = [[You are {role}! Use your Barrel Transformer to become an explodable barrel!
If you explode as a barrel and kill another player, you win!
Time your transformations so you do the most damage.]]
ROLE.shortdesc = "Becomes an explodable barrel on demand. If it explodes and kills a player, they win!"

ROLE.team = ROLE_TEAM_JESTER

ROLE.convars = {}

ROLE.translations = {
    ["english"] = {
        ["bam_transformer_help_pri"] = "Use {primaryfire} to transform into an explodable barrel",
        ["bam_transformer_help_sec"] = "Use {secondaryfire} to transform back"
    }
}

RegisterRole(ROLE)

if SERVER then
    AddCSLuaFile()

    util.AddNetworkString("TTT_UpdateBarrelMimicWins")
    util.AddNetworkString("TTT_ResetBarrelMimicWins")

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

    ----------------
    -- WIN CHECKS --
    ----------------

    local barrelMimicWins = false
    AddHook("PlayerDeath", "BarrelMimic_PlayerDeath", function(victim, inflictor, attacker)
        if barrelMimicWins then return end

        if IsPlayer(victim) and victim:IsBarrelMimic() then
            -- TODO: Respawn after a delay
            return
        end

        if not IsValid(inflictor) then return end
        if not IsPlayer(inflictor.BarrelMimic) then return end
        if not inflictor.BarrelMimic:IsBarrelMimic() then return end

        barrelMimicWins = true
        net.Start("TTT_UpdateBarrelMimicWins")
        net.Broadcast()
    end)

    AddHook("Initialize", "BarrelMimic_Initialize", function()
        WIN_BARRELMIMIC = GenerateNewWinID(ROLE_BARRELMIMIC)
    end)

    AddHook("TTTPrintResultMessage", "BarrelMimic_TTTPrintResultMessage", function(type)
        if type == WIN_BARRELMIMIC then
            LANG.Msg("win_barrelmimic", { role = ROLE_STRINGS[ROLE_BARRELMIMIC] })
            ServerLog("Result: " .. ROLE_STRINGS[ROLE_BARRELMIMIC] .. " wins.\n")
            return true
        end
    end)

    -------------
    -- CLEANUP --
    -------------

    AddHook("TTTPrepareRound", "BarrelMimic_TTTPrepareRound", function()
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
end