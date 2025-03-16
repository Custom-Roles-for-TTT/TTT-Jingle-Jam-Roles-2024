local hook = hook
local math = math
local net = net
local player = player
local table = table

local AddHook = hook.Add
local MathMax = math.max
local PlayerIterator = player.Iterator
local TableInsert = table.insert
local RemoveHook = hook.Remove
local RunHook = hook.Run

local ROLE = {}

ROLE.nameraw = "wheelboy"
ROLE.name = "Wheelboy"
ROLE.nameplural = "Wheelboys"
ROLE.nameext = "a Wheelboy"
ROLE.nameshort = "whl"

ROLE.desc = [[You are {role}! Spin your wheel
to trigger random effects for everyone.

Spin enough times and you win!]]
ROLE.shortdesc = "Can spin a wheel to apply random effects to everyone. Spin enough times and they win."

ROLE.team = ROLE_TEAM_JESTER
ROLE.startinghealth = 150
ROLE.maxhealth = 150

ROLE.convars = {}
TableInsert(ROLE.convars, {
    cvar = "ttt_wheelboy_wheel_recharge_time",
    type = ROLE_CONVAR_TYPE_NUM
})
TableInsert(ROLE.convars, {
    cvar = "ttt_wheelboy_wheels_to_win",
    type = ROLE_CONVAR_TYPE_NUM
})
TableInsert(ROLE.convars, {
    cvar = "ttt_wheelboy_wheel_time",
    type = ROLE_CONVAR_TYPE_NUM
})
TableInsert(ROLE.convars, {
    cvar = "ttt_wheelboy_wheel_end_wait_time",
    type = ROLE_CONVAR_TYPE_NUM
})
TableInsert(ROLE.convars, {
    cvar = "ttt_wheelboy_swap_on_kill",
    type = ROLE_CONVAR_TYPE_BOOL
})
TableInsert(ROLE.convars, {
    cvar = "ttt_wheelboy_announce_text",
    type = ROLE_CONVAR_TYPE_BOOL
})
TableInsert(ROLE.convars, {
    cvar = "ttt_wheelboy_announce_sound",
    type = ROLE_CONVAR_TYPE_BOOL
})
TableInsert(ROLE.convars, {
    cvar = "ttt_wheelboy_speed_mult",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 1
})
TableInsert(ROLE.convars, {
    cvar = "ttt_wheelboy_sprint_recovery",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 2
})

ROLE.translations = {
    ["english"] = {
        ["whl_spinner_help_pri"] = "Use {primaryfire} to spin the wheel",
        ["whl_spinner_help_sec"] = "Use {secondaryfire} to transform back",
        ["ev_win_wheelboy"] = "The {role} has spun its way to cake!",
        ["hilite_wheelboy"] = "AND THE {role} GOT CAKE!",
        ["wheelboy_spin_hud"] = "Next wheel spin: {time}",
        ["wheelboy_spin_hud_now"] = "NOW",
        ["score_wheelboy_killed"] = "Killed"
    }
}

RegisterRole(ROLE)

local wheel_time = CreateConVar("ttt_wheelboy_wheel_time", "15", FCVAR_REPLICATED, "How long the wheel should spin for", 1, 30)
local wheel_recharge_time = CreateConVar("ttt_wheelboy_wheel_recharge_time", "60", FCVAR_REPLICATED, "How long wheelboy must wait between wheel spins", 1, 180)
local wheels_to_win = CreateConVar("ttt_wheelboy_wheels_to_win", "5", FCVAR_REPLICATED, "How many times wheelboy must spin their wheel to win", 1, 20)
local wheel_end_wait_time = CreateConVar("ttt_wheelboy_wheel_end_wait_time", "5", FCVAR_REPLICATED, "How long the wheel should wait at the end, showing the result, before it hides", 1, 30)
local announce_text = CreateConVar("ttt_wheelboy_announce_text", "1", FCVAR_REPLICATED, "Whether to announce that there is a wheelboy via text", 0, 1)
local announce_sound = CreateConVar("ttt_wheelboy_announce_sound", "1", FCVAR_REPLICATED, "Whether to announce that there is a wheelboy via a sound clip", 0, 1)
local speed_mult = CreateConVar("ttt_wheelboy_speed_mult", "1.2", FCVAR_REPLICATED, "The multiplier to use on wheelboy's movement speed (e.g. 1.2 = 120% normal speed)", 1, 2)
local sprint_recovery = CreateConVar("ttt_wheelboy_sprint_recovery", "0.12", FCVAR_REPLICATED, "The amount of stamina to recover per tick", 0, 1)
local swap_on_kill = CreateConVar("ttt_wheelboy_swap_on_kill", "0", FCVAR_REPLICATED, "Whether wheelboy's killer should become the new wheelboy (if they haven't won yet)", 0, 1)

local wheelEffects = {
    {
        -- 80% speed, compounded by the number of times it hits
        -- e.g. 80% -> 64% -> 51.2% -> 41%
        name = "Slow movement",
        shared = true,
        start = function(p, this)
            local speedMult = 0.8 * this.times
            AddHook("TTTSpeedMultiplier", "Wheelboy_SlowMovement_TTTSpeedMultiplier", function(ply, mults)
                if IsPlayer(ply) then
                    TableInsert(mults, speedMult)
                end
            end)
        end,
        finish = function()
            RemoveHook("TTTSpeedMultiplier", "Wheelboy_SlowMovement_TTTSpeedMultiplier")
        end
    },
    {
        -- 20% speed increase each time it hits
        name = "Fast time",
        start = function(p, this)
            game.SetTimeScale(1 + (0.2 * this.times))
        end,
        finish = function()
            game.SetTimeScale(1)
        end
    },
    {
        -- This runs after stamina has already been taken, so take some more
        name = "More stamina consumption",
        shared = true,
        start = function(p, this)
            local staminaLoss = 0.3 * this.times
            AddHook("TTTSprintStaminaPost", "Wheelboy_MoreStaminaConsumption_TTTSprintStaminaPost", function(ply, stamina, sprintTimer, consumption)
                if IsPlayer(ply) then
                    return stamina - staminaLoss
                end
            end)
        end,
        finish = function()
            RemoveHook("TTTSprintStaminaPost", "Wheelboy_MoreStaminaConsumption_TTTSprintStaminaPost")
        end
    },
    {
        -- 50 extra HP for everyone
        name = "Extra health",
        start = function(p, this)
            for _, v in PlayerIterator() do
                if not IsPlayer(v) then continue end
                if not v:Alive() or v:IsSpec() then continue end

                local hp = v:Health()
                local maxHp = v:GetMaxHealth()
                v:SetHealth(hp + 50)
                v:SetMaxHealth(maxHp + 50)
            end
        end,
        finish = function() end
    },
    {
        name = "Temporary \"Bad Trip\"",
        start = function(p, this)
            -- TODO
            print("OH NO")
        end,
        finish = function()
            -- TODO
            print("OH YEA")
        end
    },
    {
        -- 15% less gravity each time it hits
        name = "Less gravity",
        start = function(p, this)
            local targetGravity = 1 - (0.15 * this.times)
            AddHook("TTTPlayerAliveThink", "Wheelboy_LessGravity_TTTPlayerAliveThink", function(ply)
                if IsPlayer(ply) and ply:GetGravity() ~= targetGravity then
                    ply:SetGravity(targetGravity)
                end
            end)
        end,
        finish = function()
            for _, ply in PlayerIterator() do
                ply:SetGravity(1)
            end
            RemoveHook("TTTPlayerAliveThink", "Wheelboy_LessGravity_TTTPlayerAliveThink")
        end
    },
    {
        name = "Lose a credit",
        start = function(p, this)
            for _, v in PlayerIterator() do
                if not IsPlayer(v) then continue end
                if not v:Alive() or v:IsSpec() then continue end

                local credits = v:GetCredits()
                if credits > 0 then
                    v:SetCredits(credits - 1)
                end
            end
        end,
        finish = function() end
    },
    {
        -- 120% speed, compounded by the number of times it hits
        -- e.g. 120% -> 144% -> 172.8% -> 207.36%
        name = "Fast movement",
        shared = true,
        start = function(p, this)
            local speedMult = 1.2 * this.times
            AddHook("TTTSpeedMultiplier", "Wheelboy_FastMovement_TTTSpeedMultiplier", function(ply, mults)
                if IsPlayer(ply) then
                    TableInsert(mults, speedMult)
                end
            end)
        end,
        finish = function()
            RemoveHook("TTTSpeedMultiplier", "Wheelboy_FastMovement_TTTSpeedMultiplier")
        end
    },
    {
        -- 20% speed decrease each time it hits
        name = "Slow time",
        start = function(p, this)
            game.SetTimeScale(1 - (0.2 * this.times))
        end,
        finish = function()
            game.SetTimeScale(1)
        end
    },
    {
        -- This runs after stamina has already been taken, so add some back
        name = "Less stamina consumption",
        shared = true,
        start = function(p, this)
            local staminaGain = 0.15 * this.times
            AddHook("TTTSprintStaminaPost", "Wheelboy_LessStaminaConsumption_TTTSprintStaminaPost", function(ply, stamina, sprintTimer, consumption)
                if IsPlayer(ply) then
                    return stamina + staminaGain
                end
            end)
        end,
        finish = function()
            RemoveHook("TTTSprintStaminaPost", "Wheelboy_LessStaminaConsumption_TTTSprintStaminaPost")
        end
    },
    {
        -- 25 less HP for everyone
        name = "Health reduction",
        start = function(p, this)
            for _, v in PlayerIterator() do
                if not IsPlayer(v) then continue end
                if not v:Alive() or v:IsSpec() then continue end

                -- Don't go below 1
                local hp = MathMax(v:Health() - 25, 1)
                local maxHp = MathMax(v:GetMaxHealth() - 25, 1)
                v:SetHealth(hp)
                v:SetMaxHealth(maxHp)
            end
        end,
        finish = function() end
    },
    {
        name = "Temporary \"Infinite Ammo\"",
        start = function(p, this)
            local timerId = "Wheelboy_AmmoEffect"
            -- If this effect is already active, add another 30 seconds
            if timer.Exists(timerId) then
                local timeLeft = timer.TimeLeft(timerId)
                timer.Adjust(timerId, timeLeft + 30)
                return
            end

            AddHook("TTTPlayerAliveThink", "Wheelboy_InfiniteAmmo_TTTPlayerAliveThink", function(ply)
                if not IsPlayer(ply) then return end

                local active_weapon = ply:GetActiveWeapon()
                if IsValid(active_weapon) and active_weapon.Primary and active_weapon.AutoSpawnable then
                    active_weapon:SetClip1(active_weapon.Primary.ClipSize)
                end
            end)

            timer.Create(timerId, 30, 1, function()
                this.finish()
            end)
        end,
        finish = function()
            timer.Remove("Wheelboy_AmmoEffect")
            RemoveHook("TTTPlayerAliveThink", "Wheelboy_InfiniteAmmo_TTTPlayerAliveThink")
        end
    },
    {
        -- 15% more gravity each time it hits
        name = "More gravity",
        start = function(p, this)
            local targetGravity = 1 + (0.15 * this.times)
            AddHook("TTTPlayerAliveThink", "Wheelboy_MoreGravity_TTTPlayerAliveThink", function(ply)
                if IsPlayer(ply) and ply:GetGravity() ~= targetGravity then
                    ply:SetGravity(targetGravity)
                end
            end)
        end,
        finish = function()
            for _, ply in PlayerIterator() do
                ply:SetGravity(1)
            end
            RemoveHook("TTTPlayerAliveThink", "Wheelboy_MoreGravity_TTTPlayerAliveThink")
        end
    },
    {
        name = "Gain a credit",
        start = function(p, this)
            for _, v in PlayerIterator() do
                if not IsPlayer(v) then continue end
                if not v:Alive() or v:IsSpec() then continue end

                local credits = v:GetCredits()
                v:SetCredits(credits + 1)
            end
        end,
        finish = function() end
    }
}

AddHook("TTTSprintStaminaRecovery", "Wheelboy_TTTSprintStaminaRecovery", function(ply, recovery)
    if IsPlayer(ply) and ply:IsActiveWheelboy() then
        return sprint_recovery:GetFloat()
    end
end)

AddHook("TTTSpeedMultiplier", "Wheelboy_TTTSpeedMultiplier", function(ply, mults)
    if IsPlayer(ply) and ply:IsActiveWheelboy() then
        TableInsert(mults, speed_mult:GetFloat())
    end
end)


if SERVER then
    AddCSLuaFile()

    util.AddNetworkString("TTT_UpdateWheelboyWins")
    util.AddNetworkString("TTT_ResetWheelboyWins")
    util.AddNetworkString("TTT_WheelboyAnnounceSound")
    util.AddNetworkString("TTT_WheelboySpinWheel")
    util.AddNetworkString("TTT_WheelboyStopWheel")
    util.AddNetworkString("TTT_WheelboySpinResult")
    util.AddNetworkString("TTT_WheelboyStartEffect")
    util.AddNetworkString("TTT_WheelboyFinishEffect")

    ------------------
    -- ANNOUNCEMENT --
    ------------------

    -- Warn other players that there is a wheelboy
    AddHook("TTTBeginRound", "Wheelboy_Announce_TTTBeginRound", function()
        if not announce_text:GetBool() and not announce_sound:GetBool() then return end

        timer.Simple(1.5, function()
            local hasWheelboy = false
            for _, v in PlayerIterator() do
                if v:IsWheelboy() then
                    hasWheelboy = true
                end
            end

            if hasWheelboy then
                if announce_text:GetBool() then
                    for _, v in PlayerIterator() do
                        if v:IsWheelboy() then continue end
                        v:QueueMessage(MSG_PRINTBOTH, "There is " .. ROLE_STRINGS_EXT[ROLE_WHEELBOY] .. ".")
                    end
                end

                if announce_sound:GetBool() then
                    net.Start("TTT_WheelboyAnnounceSound")
                    net.Broadcast()
                end
            end
        end)
    end)

    -----------
    -- KARMA --
    -----------

    -- Attacking the Wheelboy does not penalize karma
    AddHook("TTTKarmaShouldGivePenalty", "Wheelboy_TTTKarmaShouldGivePenalty", function(attacker, victim)
        if not IsPlayer(victim) or not victim:IsWheelboy() then return end
        return false
    end)

    ----------------
    -- WIN CHECKS --
    ----------------

    AddHook("Initialize", "Wheelboy_Initialize", function()
        WIN_WHEELBOY = GenerateNewWinID(ROLE_WHEELBOY)
    end)

    -----------------------
    -- WHEEL SPIN RESULT --
    -----------------------

    local spinCount = 0;
    net.Receive("TTT_WheelboySpinResult", function(len, ply)
        if not IsPlayer(ply) then return end
        if not ply:IsActiveWheelboy() then return end

        local chosenSegment = net.ReadUInt(4)
        local result = wheelEffects[chosenSegment]
        if not result then return end

        -- If we haven't already won
        if spinCount ~= nil then
            -- Increase the tracker
            spinCount = spinCount + 1
            -- And check if they win this time
            if spinCount >= wheels_to_win:GetInt() then
                spinCount = nil
                net.Start("TTT_UpdateWheelboyWins")
                net.Broadcast()
            end
        end

        -- Run the associated function with the chosen result
        if result.times == nil then
            result.times = 0
        end
        result.times = result.times + 1
        result.start(ply, result)
        -- If this effect is shared, then send a message to the client so it knows to do something too
        if result.shared then
            net.Start("TTT_WheelboyStartEffect")
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
    AddHook("TTTRandomatCanEventRun", "Wheelboy_TTTRandomatCanEventRun", function(event)
        if not blockedEvents[event.Id] then return end

        for _, ply in PlayerIterator() do
            if ply:IsWheelboy() then
                return false, ROLE_STRINGS[ROLE_WHEELBOY] .. " is in the round and this event " .. blockedEvents[event.Id]
            end
        end
    end)

    ---------------
    -- ROLE SWAP --
    ---------------

    AddHook("PlayerDeath", "Wheelboy_Swap_PlayerDeath", function(victim, infl, attacker)
        -- This gets set to nil when the spin count exceeds the win condition (aka, the wheelboy has won)
        if spinCount == nil then return end
        if not swap_on_kill:GetBool() then return end

        local valid_kill = IsPlayer(attacker) and attacker ~= victim and GetRoundState() == ROUND_ACTIVE
        if not valid_kill then return end
        if not victim:IsWheelboy() then return end

        -- Keep track o the killer for the scoreboard
        attacker:SetNWString("WheelboyKilled", victim:Nick())

        -- Swap roles
        victim:SetRole(attacker:GetRole())
        attacker:MoveRoleState(victim)
        attacker:SetRole(ROLE_WHEELBOY)
        attacker:StripRoleWeapons()
        RunHook("PlayerLoadout", attacker)
        SendFullStateUpdate()

        -- TODO: Tell the new wheelboy what happened and what to do now
    end)

    -------------
    -- CLEANUP --
    -------------

    local function ClearEffects()
        -- End all of the effects
        for effectIdx, effect in ipairs(wheelEffects) do
            effect.finish()

            -- If this effect is shared, then send a message to the client so it knows to do something too
            if effect.shared then
                net.Start("TTT_WheelboyFinishEffect")
                    net.WriteUInt(effectIdx, 4)
                net.Broadcast()
            end
        end
    end

    AddHook("TTTPrepareRound", "Wheelboy_TTTPrepareRound", function()
        ClearEffects()
        spinCount = 0
        net.Start("TTT_ResetWheelboyWins")
        net.Broadcast()
    end)

    AddHook("TTTBeginRound", "Wheelboy_TTTBeginRound", function()
        ClearEffects()
        spinCount = 0
        net.Start("TTT_ResetWheelboyWins")
        net.Broadcast()
    end)

    local function ClearEffectsAndWheel(ply)
        ClearEffects()
        net.Start("TTT_WheelboyStopWheel")
        if IsPlayer(ply) then
            net.Send(ply)
        else
            net.Broadcast()
        end
    end

    AddHook("TTTEndRound", "Wheelboy_TTTBeginRound", function()
        ClearEffectsAndWheel()
    end)

    hook.Add("TTTPlayerRoleChanged", "Wheelboy_TTTPlayerRoleChanged", function(ply, oldRole, newRole)
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
end

if CLIENT then
    local cam = cam
    local CurTime = CurTime
    local draw = draw
    local Material = Material
    local surface = surface
    local util = util

    local CamPopModelMatrix = cam.PopModelMatrix
    local CamPushModelMatrix = cam.PushModelMatrix
    local DrawNoTexture = draw.NoTexture
    local DrawSimpleTextOutlined = draw.SimpleTextOutlined
    local FormatTime = util.SimpleTime
    local MathCos = math.cos
    local MathMin = math.min
    local MathRad = math.rad
    local MathRand = math.random
    local MathSin = math.sin
    local SurfaceDrawPoly = surface.DrawPoly
    local SurfaceDrawText = surface.DrawText
    local SurfaceDrawTexturedRect = surface.DrawTexturedRect
    local SurfaceGetTextSize = surface.GetTextSize
    local SurfacePlaySound = surface.PlaySound
    local SurfaceSetDrawColor = surface.SetDrawColor
    local SurfaceSetFont = surface.SetFont
    local SurfaceSetMaterial = surface.SetMaterial
    local SurfaceSetTextColor = surface.SetTextColor
    local SurfaceSetTextPos = surface.SetTextPos

    local hide_role = GetConVar("ttt_hide_role")

    local wheelStartTime = nil
    local wheelEndTime = nil
    local wheelOffset = nil
    local lastSegment = nil
    local blinkStart = nil
    local anglesPerSegment = nil
    local function ResetWheelState()
        wheelStartTime = nil
        wheelEndTime = nil
        wheelOffset = nil
        lastSegment = nil
        blinkStart = nil
        anglesPerSegment = nil
    end

    ---------
    -- HUD --
    ---------

    AddHook("TTTHUDInfoPaint", "Wheelboy_TTTHUDInfoPaint", function(client, label_left, label_top, active_labels)
        if hide_role:GetBool() then return end
        if not client:IsActiveWheelboy() then return end

        local curTime = CurTime()
        local nextSpinTime = client:GetNWInt("WheelboyNextSpinTime", nil)
        local nextSpinLabel
        if nextSpinTime == nil or curTime >= nextSpinTime then
            nextSpinLabel = LANG.GetTranslation("wheelboy_spin_hud_now")
        else
            nextSpinLabel = FormatTime(nextSpinTime - curTime, "%02i:%02i")
        end

        SurfaceSetFont("TabLarge")
        SurfaceSetTextColor(255, 255, 255, 230)

        local text = LANG.GetParamTranslation("wheelboy_spin_hud", { time = nextSpinLabel })
        local _, h = SurfaceGetTextSize(text)

        -- Move this up based on how many other labels here are
        label_top = label_top + (20 * #active_labels)

        SurfaceSetTextPos(label_left, ScrH() - label_top - h)
        SurfaceDrawText(text)

        -- Track that the label was added so others can position accurately
        TableInsert(active_labels, "wheelboy")
    end)

    ----------------
    -- WIN CHECKS --
    ----------------

    AddHook("TTTSyncWinIDs", "Wheelboy_TTTSyncWinIDs", function()
        WIN_WHEELBOY = WINS_BY_ROLE[ROLE_WHEELBOY]
    end)

    local wheelboyWins = false
    net.Receive("TTT_UpdateWheelboyWins", function()
        if wheelboyWins then return end

        SurfacePlaySound("whl/win.mp3")

        -- Log the win event with an offset to force it to the end
        wheelboyWins = true
        CLSCORE:AddEvent({
            id = EVENT_FINISH,
            win = WIN_WHEELBOY
        }, 1)
    end)

    local function ResetWheelboyWin()
        wheelboyWins = false
        ResetWheelState()
    end
    net.Receive("TTT_ResetWheelboyWins", ResetWheelboyWin)
    AddHook("TTTPrepareRound", "Wheelboy_WinTracking_TTTPrepareRound", ResetWheelboyWin)
    AddHook("TTTBeginRound", "Wheelboy_WinTracking_TTTBeginRound", ResetWheelboyWin)

    AddHook("TTTScoringSecondaryWins", "Wheelboy_TTTScoringSecondaryWins", function(wintype, secondary_wins)
        if wheelboyWins then
            TableInsert(secondary_wins, {
                rol = ROLE_WHEELBOY,
                txt = LANG.GetParamTranslation("hilite_wheelboy", { role = string.upper(ROLE_STRINGS[ROLE_WHEELBOY]) }),
                col = ROLE_COLORS[ROLE_WHEELBOY]
            })
        end
    end)

    ------------
    -- EVENTS --
    ------------

    AddHook("TTTEventFinishText", "Wheelboy_TTTEventFinishText", function(e)
        if e.win == WIN_WHEELBOY then
            return LANG.GetParamTranslation("ev_win_wheelboy", { role = string.lower(ROLE_STRINGS[ROLE_WHEELBOY]) })
        end
    end)

    AddHook("TTTEventFinishIconText", "Wheelboy_TTTEventFinishIconText", function(e, win_string, role_string)
        if e.win == WIN_WHEELBOY then
            return "ev_win_icon_also", ROLE_STRINGS[ROLE_WHEELBOY]
        end
    end)

    -------------
    -- SCORING --
    -------------

    -- Show who the current wheelboy killed (if anyone)
    AddHook("TTTScoringSummaryRender", "Wheelboy_TTTScoringSummaryRender", function(ply, roleFileName, groupingRole, roleColor, name, startingRole, finalRole)
        if not IsPlayer(ply) then return end

        if ply:IsWheelboy() then
            local wheelboyKilled = ply:GetNWString("WheelboyKilled", "")
            if #wheelboyKilled > 0 then
                return roleFileName, groupingRole, roleColor, name, wheelboyKilled, LANG.LANG.GetTranslation("score_wheelboy_killed")
            end
        end
    end)

    ------------------
    -- ANNOUNCEMENT --
    ------------------

    net.Receive("TTT_WheelboyAnnounceSound", function()
        SurfacePlaySound("whl/announce.mp3")
    end)

    -----------
    -- WHEEL --
    -----------

    surface.CreateFont("WheelboyLabels", {
        font = "Tahoma",
        size = 16,
        weight = 1000
    })

    -- Start/Stop --

    net.Receive("TTT_WheelboySpinWheel", function()
        if wheelStartTime ~= nil then return end

        wheelStartTime = CurTime()
        wheelEndTime = wheelStartTime + wheel_time:GetInt()
        wheelOffset = MathRand() * 360
    end)

    net.Receive("TTT_WheelboyStopWheel", function()
        ResetWheelState()
    end)

    -- Effects --

    net.Receive("TTT_WheelboyStartEffect", function()
        local client = LocalPlayer()
        if not IsPlayer(client) then return end

        local effectIdx = net.ReadUInt(4)
        if effectIdx > 0 and effectIdx <= #wheelEffects then
            wheelEffects[effectIdx].start(client)
        end
    end)

    net.Receive("TTT_WheelboyFinishEffect", function()
        local effectIdx = net.ReadUInt(4)
        if effectIdx > 0 and effectIdx <= #wheelEffects then
            wheelEffects[effectIdx].finish()
        end
    end)

    -- Pointer --

    local pointerOutlinePoints = {
        { x = 0, y = -237 },
        { x = -16, y = -247 },
        { x = -16, y = -264 },
        { x = 16, y = -264 },
        { x = 16, y = -247 }
    }
    local pointerPoints = {
        { x = 0, y = -238 },
        { x = -15, y = -248 },
        { x = -15, y = -263 },
        { x = 15, y = -263 },
        { x = 15, y = -248 }
    }
    local function DrawPointer(x, y)
        -- Draw the same shape but slightly larger and black
        local outlineSegments = {}
        for _, point in ipairs(pointerOutlinePoints) do
            TableInsert(outlineSegments, { x = point.x + x, y = point.y + y })
        end

        SurfaceSetDrawColor(0, 0, 0, 255)
        DrawNoTexture()
        SurfaceDrawPoly(outlineSegments)

        -- Draw the pointer itself
        local pointerSegments = {}
        for _, point in ipairs(pointerPoints) do
            TableInsert(pointerSegments, { x = point.x + x, y = point.y + y })
        end

        SurfaceSetDrawColor(255, 0, 0, 255)
        DrawNoTexture()
        SurfaceDrawPoly(pointerSegments)
    end

    -- Background --

    -- Derived from the surface.DrawPoly example on the GMod wiki
    local function DrawCircle(x, y, radius, seg)
        local cir = {}

        TableInsert(cir, { x = x, y = y })
        for i = 0, seg do
            local a = MathRad((i / seg) * -360)
            TableInsert(cir, { x = x + MathSin(a) * radius, y = y + MathCos(a) * radius })
        end

        local a = MathRad(0) -- This is needed for non absolute segment counts
        TableInsert(cir, { x = x + MathSin(a) * radius, y = y + MathCos(a) * radius })

        SurfaceSetDrawColor(0, 0, 0, 255)
        DrawNoTexture()
        surface.DrawPoly(cir)
    end

    -- Wheel --

    local colors = {
        Color(76, 170, 231, 255),
        Color(209, 98, 175, 255),
        Color(249, 67, 46, 255),
        Color(239, 224, 99, 255),
        Color(55, 24, 102, 255),
        Color(21, 106, 46, 255),
        Color(249, 67, 46, 255),
        Color(76, 170, 231, 255),
        Color(209, 98, 175, 255),
        Color(249, 67, 46, 255),
        Color(239, 224, 99, 255),
        Color(55, 24, 102, 255),
        Color(21, 106, 46, 255),
        Color(249, 67, 46, 255)
    }

    local logoMat = Material("materials/vgui/ttt/roles/whl/logo.png")
    local function DrawLogo(x, y)
        SurfaceSetMaterial(logoMat)
        SurfaceSetDrawColor(COLOR_WHITE)
        SurfaceDrawTexturedRect(x - 25, y - 25, 50, 50)
    end

    -- Thanks to Angela from the Lonely Yogs for the algorithm!
    local function DrawCircleSegment(segmentIdx, segmentCount, anglePerSegment, pointsPerSegment, radius, blink)
        local text = wheelEffects[segmentIdx].name
        local color = colors[segmentIdx]

        -- If we're blinking, make this segment darker
        if blink then
            local h, s, l = ColorToHSL(colors[segmentIdx])
            color = HSLToColor(h, s, math.max(l - 0.125, 0.125))
        end

        -- Generate all the points on the polygon
        local polySegments = {
            { x = 0, y = 0 }
        }
        for i = 0, pointsPerSegment do
            TableInsert(
                polySegments,
                {
                    x = MathCos(i * MathRad(anglePerSegment) / pointsPerSegment),
                    y = MathSin(i * MathRad(anglePerSegment) / pointsPerSegment)
                }
            )
        end

        local polyMat = Matrix()
        local scaleDown = 0.95
        -- Rotate and move the segment to the origin before applying the scaling and moving/rotating it back
        -- This is needed so the scaling is applied against the outer edge of the segment
        polyMat:Rotate(Angle(0, anglePerSegment / 2, 0))
        polyMat:Translate(Vector(0.5, 0, 0))
        polyMat:Scale(Vector(scaleDown, scaleDown, 1))
        polyMat:Translate(Vector(-0.5, 0, 0))
        polyMat:Rotate(Angle(0, -anglePerSegment / 2, 0))

        CamPushModelMatrix(polyMat, true)
            SurfaceSetDrawColor(color.r, color.g, color.b, color.a)
            DrawNoTexture()
            SurfaceDrawPoly(polySegments)
        CamPopModelMatrix()

        -- Move out from the center slightly and rotate to re-align the text with the center of the segment
        local textRenderDisplacement = 10
        local textMat = Matrix()
        textMat:Rotate(Angle(0, anglePerSegment / 2, 0))

        -- This is a really crude attempt at centering the text...
        textMat:Translate(Vector(0.5 - #text / 90, 0, 0))
        textMat:Scale(Vector(1 / radius, 1 / radius, 1))

        -- Undo text displacement
        textMat:Translate(Vector(0, -textRenderDisplacement, 0))

        CamPushModelMatrix(textMat, true)
            -- Displace to ensure the text doesn't get cut off below y=0 (in text render space)
            DrawSimpleTextOutlined(text, "WheelboyLabels", 0, textRenderDisplacement, COLOR_WHITE, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, 1, COLOR_BLACK)
        CamPopModelMatrix()
    end

    local function DrawSegmentedCircle(x, y, radius, segmentCount, anglePerSegment, pointsPerSegment, currentAngle, angleOffset, blink)
        local mat = Matrix()
        mat:Translate(Vector(x, y, 0))
        mat:Rotate(Angle(0, currentAngle, 0))
        mat:Scale(Vector(radius, radius, radius))

        CamPushModelMatrix(mat)
            for segmentIdx = 1, segmentCount do
                -- Rotate to the angle of this segment
                local segmentMat = Matrix()
                local segmentAng = ((segmentIdx - 1) * anglePerSegment) + angleOffset
                segmentMat:Rotate(Angle(0, -segmentAng, 0))

                CamPushModelMatrix(segmentMat, true)
                    DrawCircleSegment(segmentIdx, segmentCount, anglePerSegment, pointsPerSegment, radius, blink and segmentIdx == lastSegment)
                CamPopModelMatrix()
            end
        CamPopModelMatrix()
    end

    local function ReduceAngle(ang)
        while ang < 0 do
            ang = ang + 360
        end
        while ang > 360 do
            ang = ang - 360
        end
        return ang
    end

    AddHook("HUDPaint", "Wheelboy_Wheel_HUDPaint", function()
        if not wheelStartTime then return end

        local segmentCount = #colors
        local anglePerSegment = (360 / segmentCount)

        -- Start at 90deg offset so the start is the top instead of the right
        -- Offset by an additional 1/2 segment so the arrow points to the middle instead of the edge
        local angleOffset = 90 + (anglePerSegment / 2)

        -- Precalculate the angle ranges for each segment, used to determine the current segment later
        if anglesPerSegment == nil then
            anglesPerSegment = {}
            local halfAngle = anglePerSegment / 2
            for segmentIdx = 1, segmentCount do
                anglesPerSegment[segmentIdx] = {
                    min = halfAngle * ((2 * (segmentIdx - 1)) - 1),
                    max = halfAngle * ((2 * (segmentIdx - 1)) + 1)
                }
            end
        end

        local curTime = CurTime()
        -- Once we've spun for the desired time, stop rotating at that point
        local baseTime = MathMin(curTime, wheelEndTime)

        -- TODO: Rotate at variable speed, decreasing over time
        -- Loop back around to 0 after we exceed 360
        local currentAngle = ReduceAngle(wheelOffset + (baseTime * 150))

        -- Get the current segment from the wheel, using the current angle
        -- Adjust by the angle offset so our 0 points to index 1
        local adjustedAngle = ReduceAngle(currentAngle + angleOffset)
        local currentSegment
        for segmentIdx, angles in pairs(anglesPerSegment) do
            -- For some reason the segment indexes were offset by 4
            -- I don't really understand why, but subtracting 4 from the found index produced the expected result, so here we are
            if adjustedAngle >= angles.min and adjustedAngle < angles.max then
                currentSegment = segmentIdx - 4
                break
            end

            -- Handle case of a negative minimum value
            if angles.min < 0 and
                -- Between the normalized minimum and the maximum degree of a circle. Handles [-12.6->347.4, 360)
                ((adjustedAngle >= (angles.min + 360) and adjustedAngle < 360) or
                -- Between 0 and the maximum. Handles [0, max)
                 (adjustedAngle >= 0 and adjustedAngle < angles.max)) then
                currentSegment = segmentIdx - 4
                break
            end
        end

        -- Roll this over if we exceed the max
        if currentSegment <= 0 then
            currentSegment = currentSegment + segmentCount
        end

        -- Keep track of when the segment changes and use that to play the clicking sound
        if currentSegment ~= lastSegment then
            if lastSegment ~= nil then
                SurfacePlaySound("whl/click.mp3")
            end
            lastSegment = currentSegment
        end

        local blink = false
        -- If we just finished the spin, start blinking the color to indicate which was selected
        if blinkStart == nil and curTime >= wheelEndTime then
            blinkStart = curTime
        end

        -- If we've started blinking and enough time has exceed
        if blinkStart ~= nil and curTime >= blinkStart then
            -- Stop blinking after 1/2 second, but start again in another 0.5 second
            if curTime >= blinkStart + 0.5 then
                blinkStart = curTime + 0.5
            else
                blink = true
            end
        end

        -- Draw everything
        local centerX, centerY = ScrW() / 2, ScrH() / 2
        DrawCircle(centerX, centerY, 247, 60)
        DrawSegmentedCircle(centerX, centerY, 250, segmentCount, anglePerSegment, 30, currentAngle, angleOffset, blink)
        DrawPointer(centerX, centerY)
        DrawLogo(centerX, centerY)

        -- Wait extra time and then clear everything and send it to the server
        if curTime >= wheelEndTime + wheel_end_wait_time:GetInt() then
            ResetWheelState()

            net.Start("TTT_WheelboySpinResult")
                net.WriteUInt(currentSegment, 4)
            net.SendToServer()
        end
    end)

    --------------
    -- TUTORIAL --
    --------------

    AddHook("TTTTutorialRoleText", "Wheelboy_TTTTutorialRoleText", function(role, titleLabel)
        if role ~= ROLE_WHEELBOY then return end

        local roleColor = ROLE_COLORS[ROLE_WHEELBOY]
        local traitorColor = ROLE_COLORS[ROLE_TRAITOR]
        local html = ROLE_STRINGS[ROLE_WHEELBOY] .. " is a <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>jester</span> role who can spin their wheel to apply a random effect to everyone."

        html = html .. "<span style='display: block; margin-top: 10px;'>Some of the effects are <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>beneficial</span>, while others are <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>annoying</span>.</span>"
        html = html .. "<span style='display: block; margin-top: 10px;'>The wheel can be spun <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>every ".. wheel_recharge_time:GetInt() .. " second(s)</span>.</span>"
        html = html .. "<span style='display: block; margin-top: 10px;'>" .. ROLE_STRINGS[ROLE_WHEELBOY] .. " wins by <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>spinning their wheel " .. wheels_to_win:GetInt() .. " time(s)</span> before the end of the round.</span>"

        local announceText = announce_text:GetBool()
        local announceSound = announce_sound:GetBool()
        if announceText or announceSound then
            html = html .. "<span style='display: block; margin-top: 10px;'>The presence of " .. ROLE_STRINGS[ROLE_WHEELBOY] .. " is <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>announced</span> to everyone via "
            if announceText then
                html = html .. "on-screen text"
                if announceSound then
                     html = html .. " and "
                end
            end
            if announceSound then
                html = html .. "a sound clip"
            end
            html = html .. "!</span>"
        end

        if swap_on_kill:GetBool() then
           html = html .. "<span style='display: block; margin-top: 10px;'>If " .. ROLE_STRINGS[ROLE_WHEELBOY] .. " <span style='color: rgb(" .. traitorColor.r .. ", " .. traitorColor.g .. ", " .. traitorColor.b .. ")'>is killed</span> before they win, their killer will <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>become the new " .. ROLE_STRINGS[ROLE_WHEELBOY] .. "</span>!</span>"
        end

        return html
    end)
end