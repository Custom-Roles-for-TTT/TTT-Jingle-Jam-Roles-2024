local hook = hook
local math = math
local player = player
local table = table

local AddHook = hook.Add
local MathMax = math.max
local PlayerIterator = player.Iterator
local TableInsert = table.insert
local RemoveHook = hook.Remove

local ROLE = {}

ROLE.nameraw = "wheelboy"
ROLE.name = "Wheel Boy"
ROLE.nameplural = "Wheel Boys"
ROLE.nameext = "a Wheel Boy"
ROLE.nameshort = "whl"

ROLE.desc = [[You are {role}! Spin your wheel
to trigger random effects for everyone.

Spin {times} time(s) and you win!]]
ROLE.shortdesc = "Can spin a wheel to apply random effects to everyone. Spin enough times and they win."

ROLE.team = ROLE_TEAM_JESTER
ROLE.startinghealth = 150
ROLE.maxhealth = 150

ROLE.convars =
{
    {
        cvar = "ttt_wheelboy_notify_mode",
        type = ROLE_CONVAR_TYPE_DROPDOWN,
        choices = {"None", "Detective and Traitor", "Traitor", "Detective", "Everyone"},
        isNumeric = true
    },
    {
        cvar = "ttt_wheelboy_notify_killer",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_wheelboy_notify_sound",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_wheelboy_notify_confetti",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_wheelboy_wheel_recharge_time",
        type = ROLE_CONVAR_TYPE_NUM
    },
    {
        cvar = "ttt_wheelboy_spins_to_win",
        type = ROLE_CONVAR_TYPE_NUM
    },
    {
        cvar = "ttt_wheelboy_wheel_time",
        type = ROLE_CONVAR_TYPE_NUM
    },
    {
        cvar = "ttt_wheelboy_wheel_end_wait_time",
        type = ROLE_CONVAR_TYPE_NUM
    },
    {
        cvar = "ttt_wheelboy_swap_on_kill",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_wheelboy_announce_text",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_wheelboy_announce_sound",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_wheelboy_speed_mult",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 1
    },
    {
        cvar = "ttt_wheelboy_sprint_recovery",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 2
    }
}

ROLE.translations = {
    ["english"] = {
        ["whl_spinner_help_pri"] = "Use {primaryfire} to spin the wheel",
        ["whl_spinner_help_sec"] = "Use {secondaryfire} to transform back",
        ["ev_win_wheelboy"] = "The {role} has spun its way to cake!",
        ["hilite_wheelboy"] = "AND {role} GOT CAKE!",
        ["wheelboy_spin_hud"] = "Next wheel spin: {time}",
        ["wheelboy_spin_hud_now"] = "NOW",
        ["score_wheelboy_killed"] = "Killed",
        ["wheelboy_config_wheel_offset_x"] = "Wheel position, X-axis offset",
        ["wheelboy_config_wheel_offset_y"] = "Wheel position, Y-axis offset",
        ["wheelboy_config_wheel_offset_reset"] = "Reset wheel position to default"
    }
}

RegisterRole(ROLE)

CreateConVar("ttt_wheelboy_wheel_time", "15", FCVAR_REPLICATED, "How long the wheel should spin for", 1, 30)
CreateConVar("ttt_wheelboy_wheel_recharge_time", "60", FCVAR_REPLICATED, "How long wheel boy must wait between wheel spins", 1, 180)
CreateConVar("ttt_wheelboy_spins_to_win", "5", FCVAR_REPLICATED, "How many times wheel boy must spin their wheel to win", 1, 20)
CreateConVar("ttt_wheelboy_wheel_end_wait_time", "5", FCVAR_REPLICATED, "How long the wheel should wait at the end, showing the result, before it hides", 1, 30)
CreateConVar("ttt_wheelboy_announce_text", "1", FCVAR_REPLICATED, "Whether to announce that there is a wheel boy via text", 0, 1)
CreateConVar("ttt_wheelboy_announce_sound", "1", FCVAR_REPLICATED, "Whether to announce that there is a wheel boy via a sound clip", 0, 1)
local speed_mult = CreateConVar("ttt_wheelboy_speed_mult", "1.2", FCVAR_REPLICATED, "The multiplier to use on wheel boy's movement speed (e.g. 1.2 = 120% normal speed)", 1, 2)
local sprint_recovery = CreateConVar("ttt_wheelboy_sprint_recovery", "0.12", FCVAR_REPLICATED, "The amount of stamina to recover per tick", 0, 1)
CreateConVar("ttt_wheelboy_swap_on_kill", "0", FCVAR_REPLICATED, "Whether wheel boy's killer should become the new wheel boy (if they haven't won yet)", 0, 1)

local function ScalePlayerHeads(mult)
    local scale = Vector(mult, mult, mult)
    for _, p in PlayerIterator() do
        local boneId = p:LookupBone("ValveBiped.Bip01_Head1")
        if boneId ~= nil then
            p:ManipulateBoneScale(boneId, scale)
        end
    end
end

WHEELBOY = WHEELBOY or {}
WHEELBOY.Effects = {
    {
        -- 80% speed, compounded by the number of times it hits
        -- e.g. 80% -> 64% -> 51.2% -> 41%
        name = "Slow movement",
        shared = true,
        start = function(p, this)
            local speedMult = 0.8 * this.times
            AddHook("TTTSpeedMultiplier", "WheelBoy_SlowMovement_TTTSpeedMultiplier", function(ply, mults)
                if IsPlayer(ply) then
                    TableInsert(mults, speedMult)
                end
            end)
        end,
        finish = function()
            RemoveHook("TTTSpeedMultiplier", "WheelBoy_SlowMovement_TTTSpeedMultiplier")
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
            AddHook("TTTSprintStaminaPost", "WheelBoy_MoreStaminaConsumption_TTTSprintStaminaPost", function(ply, stamina, sprintTimer, consumption)
                if IsPlayer(ply) then
                    return stamina - staminaLoss
                end
            end)
        end,
        finish = function()
            RemoveHook("TTTSprintStaminaPost", "WheelBoy_MoreStaminaConsumption_TTTSprintStaminaPost")
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
        name = "Temporary \"Big Head Mode\"",
        start = function(p, this)
            local timerId = "WheelBoy_HeadEffect"
            -- If this effect is already active, add another 30 seconds
            if timer.Exists(timerId) then
                local timeLeft = timer.TimeLeft(timerId)
                timer.Adjust(timerId, timeLeft + 30)
                return
            end

            ScalePlayerHeads(2)

            timer.Create(timerId, 30, 1, function()
                this.finish()
            end)
        end,
        finish = function()
            ScalePlayerHeads(1)
            timer.Remove("WheelBoy_HeadEffect")
        end
    },
    {
        -- 15% less gravity each time it hits
        name = "Less gravity",
        start = function(p, this)
            local targetGravity = 1 - (0.15 * this.times)
            AddHook("TTTPlayerAliveThink", "WheelBoy_LessGravity_TTTPlayerAliveThink", function(ply)
                if IsPlayer(ply) and ply:GetGravity() ~= targetGravity then
                    ply:SetGravity(targetGravity)
                end
            end)
        end,
        finish = function()
            for _, ply in PlayerIterator() do
                ply:SetGravity(1)
            end
            RemoveHook("TTTPlayerAliveThink", "WheelBoy_LessGravity_TTTPlayerAliveThink")
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
            AddHook("TTTSpeedMultiplier", "WheelBoy_FastMovement_TTTSpeedMultiplier", function(ply, mults)
                if IsPlayer(ply) then
                    TableInsert(mults, speedMult)
                end
            end)
        end,
        finish = function()
            RemoveHook("TTTSpeedMultiplier", "WheelBoy_FastMovement_TTTSpeedMultiplier")
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
            AddHook("TTTSprintStaminaPost", "WheelBoy_LessStaminaConsumption_TTTSprintStaminaPost", function(ply, stamina, sprintTimer, consumption)
                if IsPlayer(ply) then
                    return stamina + staminaGain
                end
            end)
        end,
        finish = function()
            RemoveHook("TTTSprintStaminaPost", "WheelBoy_LessStaminaConsumption_TTTSprintStaminaPost")
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
            local timerId = "WheelBoy_AmmoEffect"
            -- If this effect is already active, add another 30 seconds
            if timer.Exists(timerId) then
                local timeLeft = timer.TimeLeft(timerId)
                timer.Adjust(timerId, timeLeft + 30)
                return
            end

            AddHook("TTTPlayerAliveThink", "WheelBoy_InfiniteAmmo_TTTPlayerAliveThink", function(ply)
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
            timer.Remove("WheelBoy_AmmoEffect")
            RemoveHook("TTTPlayerAliveThink", "WheelBoy_InfiniteAmmo_TTTPlayerAliveThink")
        end
    },
    {
        -- 15% more gravity each time it hits
        name = "More gravity",
        start = function(p, this)
            local targetGravity = 1 + (0.15 * this.times)
            AddHook("TTTPlayerAliveThink", "WheelBoy_MoreGravity_TTTPlayerAliveThink", function(ply)
                if IsPlayer(ply) and ply:GetGravity() ~= targetGravity then
                    ply:SetGravity(targetGravity)
                end
            end)
        end,
        finish = function()
            for _, ply in PlayerIterator() do
                ply:SetGravity(1)
            end
            RemoveHook("TTTPlayerAliveThink", "WheelBoy_MoreGravity_TTTPlayerAliveThink")
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

AddHook("TTTSprintStaminaRecovery", "WheelBoy_TTTSprintStaminaRecovery", function(ply, recovery)
    if IsPlayer(ply) and ply:IsActiveWheelBoy() then
        return sprint_recovery:GetFloat()
    end
end)

AddHook("TTTSpeedMultiplier", "WheelBoy_TTTSpeedMultiplier", function(ply, mults)
    if IsPlayer(ply) and ply:IsActiveWheelBoy() then
        TableInsert(mults, speed_mult:GetFloat())
    end
end)