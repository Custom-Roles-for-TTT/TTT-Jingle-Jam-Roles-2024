AddCSLuaFile()

local hook = hook
local net = net
local player = player

local AddHook = hook.Add
local PlayerIterator = player.Iterator
local RunHook = hook.Run

util.AddNetworkString("TTT_UpdateWheelBoyWins")
util.AddNetworkString("TTT_ResetWheelBoyWins")
util.AddNetworkString("TTT_WheelBoyAnnounceSound")
util.AddNetworkString("TTT_WheelBoySpinWheel")
util.AddNetworkString("TTT_WheelBoyStopWheel")
util.AddNetworkString("TTT_WheelBoySpinResult")
util.AddNetworkString("TTT_WheelBoyStartEffect")
util.AddNetworkString("TTT_WheelBoyFinishEffect")

CreateConVar("ttt_wheelboy_reveal_spin", "0", FCVAR_NONE, "Whether the spinning wheel should be shown to everyone", 0, 1)

CreateConVar("ttt_wheelboy_notify_mode", "0", FCVAR_NONE, "The logic to use when notifying players that wheel boy was killed. Killer is notified unless \"ttt_wheelboy_notify_killer\" is disabled", 0, 4)
CreateConVar("ttt_wheelboy_notify_killer", "0", FCVAR_NONE, "Whether to notify wheel boy's killer", 0, 1)
CreateConVar("ttt_wheelboy_notify_sound", "0", FCVAR_NONE, "Whether to play a cheering sound when wheel boy is killed", 0, 1)
CreateConVar("ttt_wheelboy_notify_confetti", "0", FCVAR_NONE, "Whether to throw confetti when wheel boy is a killed", 0, 1)

local spins_to_win = GetConVar("ttt_wheelboy_spins_to_win")
local announce_text = GetConVar("ttt_wheelboy_announce_text")
local announce_sound = GetConVar("ttt_wheelboy_announce_sound")
local swap_on_kill = GetConVar("ttt_wheelboy_swap_on_kill")

------------------
-- ANNOUNCEMENT --
------------------

-- Warn other players that there is a wheelboy
AddHook("TTTBeginRound", "WheelBoy_Announce_TTTBeginRound", function()
    if not announce_text:GetBool() and not announce_sound:GetBool() then return end

    timer.Simple(1.5, function()
        local hasWheelBoy = false
        for _, v in PlayerIterator() do
            if v:IsWheelBoy() then
                hasWheelBoy = true
            end
        end

        if hasWheelBoy then
            if announce_text:GetBool() then
                for _, v in PlayerIterator() do
                    if v:IsWheelBoy() then continue end
                    v:QueueMessage(MSG_PRINTBOTH, "There is " .. ROLE_STRINGS_EXT[ROLE_WHEELBOY] .. ".")
                end
            end

            if announce_sound:GetBool() then
                net.Start("TTT_WheelBoyAnnounceSound")
                net.Broadcast()
            end
        end
    end)
end)

-----------
-- KARMA --
-----------

-- Attacking Wheel Boy does not penalize karma
AddHook("TTTKarmaShouldGivePenalty", "WheelBoy_TTTKarmaShouldGivePenalty", function(attacker, victim)
    if not IsPlayer(victim) or not victim:IsWheelBoy() then return end
    return false
end)

----------------
-- WIN CHECKS --
----------------

AddHook("Initialize", "WheelBoy_Initialize", function()
    WIN_WHEELBOY = GenerateNewWinID(ROLE_WHEELBOY)
end)

-----------------------
-- WHEEL SPIN RESULT --
-----------------------

local spinCount = 0;
net.Receive("TTT_WheelBoySpinResult", function(len, ply)
    if not IsPlayer(ply) then return end
    if not ply:IsActiveWheelBoy() then return end
    if ply:IsRoleAbilityDisabled() then return end

    local chosenSegment = net.ReadUInt(4)
    local result = WHEELBOY.Effects[chosenSegment]
    if not result then return end

    -- If we haven't already won
    if spinCount ~= nil then
        -- Increase the tracker
        spinCount = spinCount + 1
        -- And check if they win this time
        if spinCount >= spins_to_win:GetInt() then
            spinCount = nil
            net.Start("TTT_UpdateWheelBoyWins")
            net.Broadcast()
        end
    end

    -- Let everyone know what the wheel landed on
    for _, p in PlayerIterator() do
        p:QueueMessage(MSG_PRINTBOTH, ROLE_STRINGS[ROLE_WHEELBOY] .. "'s wheel has landed on '" .. result.name .. "'!")
    end

    -- Run the associated function with the chosen result
    if result.times == nil then
        result.times = 0
    end
    result.times = result.times + 1
    result.start(ply, result)
    -- If this effect is shared, then send a message to the client so it knows to do something too
    if result.shared then
        net.Start("TTT_WheelBoyStartEffect")
            net.WriteUInt(chosenSegment, 4)
        net.Broadcast()
    end
end)

local blockedEvents = {
    -- Time scale
    ["timewarp"] = "conflicts with one of their effects",
    ["reversetimewarp"] = "conflicts with one of their effects",
    ["timeflip"] = "conflicts with one of their effects",
    ["flash"] = "conflicts with one of their effects",
    -- Stamina consumption
    ["olympicsprint"] = "conflicts with one of their effects",
    -- Gravity
    ["moongravity"] = "conflicts with one of their effects",
    ["scoutsonly"] = "conflicts with one of their effects",
    -- Credits
    ["credits"] = "conflicts with one of their effects",
    -- Infinite ammo
    ["ammo"] = "conflicts with one of their effects"
}

-- Prevents a randomat from ever triggering if wheelboy is in the round
AddHook("TTTRandomatCanEventRun", "WheelBoy_TTTRandomatCanEventRun", function(event)
    if not blockedEvents[event.Id] then return end

    for _, ply in PlayerIterator() do
        if ply:IsWheelBoy() then
            return false, ROLE_STRINGS[ROLE_WHEELBOY] .. " is in the round and this event " .. blockedEvents[event.Id]
        end
    end
end)

---------------
-- ROLE SWAP --
---------------

local function WheelBoyKilledNotification(attacker, victim)
    JesterTeamKilledNotification(attacker, victim,
        -- getkillstring
        function()
            return attacker:Nick() .. " silenced " .. ROLE_STRINGS[ROLE_WHEELBOY] .. "!"
        end)
end

AddHook("PlayerDeath", "WheelBoy_Swap_PlayerDeath", function(victim, infl, attacker)
    -- This gets set to nil when the spin count exceeds the win condition (aka, the wheelboy has won)
    if spinCount == nil then return end
    if not swap_on_kill:GetBool() then return end

    local valid_kill = IsPlayer(attacker) and attacker ~= victim and GetRoundState() == ROUND_ACTIVE
    if not valid_kill then return end
    if not victim:IsWheelBoy() then return end

    WheelBoyKilledNotification(attacker, victim)

    -- Keep track o the killer for the scoreboard
    attacker:SetNWString("WheelBoyKilled", victim:Nick())

    -- Swap roles
    victim:SetRole(attacker:GetRole())
    attacker:MoveRoleState(victim)
    attacker:SetRole(ROLE_WHEELBOY)
    attacker:StripRoleWeapons()
    RunHook("PlayerLoadout", attacker)
    SendFullStateUpdate()

    -- Tell the new wheelboy what happened and what to do now
    attacker:QueueMessage(MSG_PRINTBOTH, "You killed " .. ROLE_STRINGS[ROLE_WHEELBOY] .. " and have become the new " .. ROLE_STRINGS[ROLE_WHEELBOY])
    attacker:QueueMessage(MSG_PRINTBOTH, "Spin your wheel " .. spins_to_win:GetInt() .. " time(s) to win")
end)

-------------
-- CLEANUP --
-------------

local function ClearEffects()
    -- End all of the effects
    for effectIdx, effect in ipairs(WHEELBOY.Effects) do
        effect.finish()

        -- If this effect is shared, then send a message to the client so it knows to do something too
        if effect.shared then
            net.Start("TTT_WheelBoyFinishEffect")
                net.WriteUInt(effectIdx, 4)
            net.Broadcast()
        end
    end
end

local function ResetFullState()
    for _, p in PlayerIterator() do
        p:SetNWInt("WheelBoyNextSpinTime", 0)
    end
    ClearEffects()
    spinCount = 0
    net.Start("TTT_ResetWheelBoyWins")
    net.Broadcast()
end

AddHook("TTTPrepareRound", "WheelBoy_TTTPrepareRound", function()
    ResetFullState()
end)

AddHook("TTTBeginRound", "WheelBoy_TTTBeginRound", function()
    ResetFullState()
end)

local function ClearEffectsAndWheel(ply)
    if IsPlayer(ply) then
        ply:SetNWInt("WheelBoyNextSpinTime", 0)
    end

    ClearEffects()

    net.Start("TTT_WheelBoyStopWheel")
    net.Broadcast()
end

AddHook("TTTEndRound", "WheelBoy_TTTBeginRound", function()
    ClearEffectsAndWheel()
end)

AddHook("TTTPlayerRoleChanged", "WheelBoy_TTTPlayerRoleChanged", function(ply, oldRole, newRole)
    if oldRole == newRole then return end
    -- Clear effects if wheelboy's role is changed
    -- This has the secondary effect of encouraging people to
    -- kill wheelboy to stop any current annoying effects
    if oldRole == ROLE_WHEELBOY then
        ClearEffectsAndWheel(ply)
    -- If there's a new wheelboy, reset the spin count so
    -- they can't just build on the previous one's success
    elseif newRole == ROLE_WHEELBOY then
        spinCount = 0
    end
end)

AddHook("PlayerDisconnected", "WheelBoy_PlayerDisconnected", function(ply)
    if not IsPlayer(ply) then return end
    if not ply:IsWheelBoy() then return end
    ClearEffectsAndWheel(ply)
end)