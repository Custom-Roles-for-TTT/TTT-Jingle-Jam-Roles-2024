AddCSLuaFile()

local IsValid = IsValid
local math = math
local util = util

if SERVER then
    util.AddNetworkString("TTT_WerewolfLeapStart")
    util.AddNetworkString("TTT_WerewolfLeapEnd")
end

if CLIENT then
    SWEP.PrintName = "Claws"
    SWEP.EquipMenuData = {
        type = "Weapon",
        desc = "Left click to attack. Right click to leap."
    };

    SWEP.Slot = 8 -- add 1 to get the slot number key
    SWEP.ViewModelFOV = 54
    SWEP.ViewModelFlip = false
end

SWEP.Base = "weapon_tttbase"
SWEP.Category = WEAPON_CATEGORY_ROLE

SWEP.HoldType = "knife"

SWEP.ViewModel = Model("models/weapons/c_arms.mdl")
SWEP.WorldModel = ""

SWEP.HitDistance = 250

SWEP.Primary.Damage = 75
SWEP.Primary.ClipSize = 1
SWEP.Primary.DefaultClip = 1
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "none"
SWEP.Primary.Delay = 0.7

SWEP.Secondary.ClipSize = 5
SWEP.Secondary.DefaultClip = 5
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"
SWEP.Secondary.Delay = 2

SWEP.Kind = WEAPON_ROLE

SWEP.UseHands = true
SWEP.AllowDrop = false
SWEP.IsSilent = false

SWEP.NextReload = CurTime()

-- Pull out faster than standard guns
SWEP.DeploySpeed = 2

local hitSounds = {
    "npc/zombie/claw_strike1.wav",
    "npc/zombie/claw_strike2.wav",
    "npc/zombie/claw_strike3.wav"
}
local swingSounds = {
    "npc/zombie/claw_miss1.wav",
    "npc/zombie/claw_miss2.wav"
}
local attackSounds = {
    "npc/antlion_guard/angry1.wav",
    "npc/antlion_guard/angry2.wav",
    "npc/antlion_guard/angry3.wav"
}
local fleshSounds = {
    "physics/flesh/flesh_squishy_impact_hard1.wav",
    "physics/flesh/flesh_squishy_impact_hard2.wav",
    "physics/flesh/flesh_squishy_impact_hard3.wav",
    "physics/flesh/flesh_squishy_impact_hard4.wav"
}
local leapSounds = {
    "wwf/leap1.wav",
    "wwf/leap2.wav",
    "wwf/leap3.wav"
}

local werewolf_leap_enabled = CreateConVar("ttt_werewolf_leap_enabled", "1", FCVAR_REPLICATED)
local werewolf_attack_damage = CreateConVar("ttt_werewolf_attack_damage", "75", FCVAR_REPLICATED, "The amount of a damage Werewolves do with their claws", 1, 100)
local werewolf_attack_delay = CreateConVar("ttt_werewolf_attack_delay", "0.7", FCVAR_REPLICATED, "The amount of time between Werewolves' claw attacks", 0.1, 3)

function SWEP:Initialize()
    if CLIENT then
        if werewolf_leap_enabled:GetBool() then
            self:AddHUDHelp("wwf_claws_help_pri", "wwf_claws_help_sec", true)
        else
            self:AddHUDHelp("wwf_claws_help_pri", nil,true)
        end
    end
    return self.BaseClass.Initialize(self)
end

function SWEP:SetWeaponHoldType(t)
    self.BaseClass.SetWeaponHoldType(self, t)

    -- Sanity check, this should have been set up by the BaseClass.SetWeaponHoldType call above
    if not self.ActivityTranslate then
        self.ActivityTranslate = {}
    end

    self.ActivityTranslate[ACT_MP_ATTACK_STAND_PRIMARYFIRE]    = ACT_GMOD_GESTURE_RANGE_ZOMBIE
    self.ActivityTranslate[ACT_MP_ATTACK_CROUCH_PRIMARYFIRE]   = ACT_GMOD_GESTURE_RANGE_ZOMBIE
    self.ActivityTranslate[ACT_RANGE_ATTACK1]                  = ACT_GMOD_GESTURE_RANGE_ZOMBIE
end

function SWEP:PlayAnimation(sequence, anim)
    local owner = self:GetOwner()
    local vm = owner:GetViewModel()
    vm:SendViewModelMatchingSequence(vm:LookupSequence(anim))
    owner:SetAnimation(sequence)
end

--[[
Claw Attack
]]

function SWEP:PrimaryAttack()
    self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)

    local owner = self:GetOwner()
    if not IsValid(owner) then return end

    if owner.LagCompensation then -- for some reason not always true
        owner:LagCompensation(true)
    end

    local anim = math.random() < 0.5 and "fists_right" or "fists_left"
    self:PlayAnimation(PLAYER_ATTACK1, anim)
    owner:ViewPunch(Angle( 4, 4, 0 ))

    local spos = owner:GetShootPos()
    local sdest = spos + (owner:GetAimVector() * 70)
    local kmins = Vector(1,1,1) * -10
    local kmaxs = Vector(1,1,1) * 10

    local tr_main = util.TraceHull({start=spos, endpos=sdest, filter=owner, mask=MASK_SHOT_HULL, mins=kmins, maxs=kmaxs})
    local hitEnt = tr_main.Entity

    if SERVER then
        owner:EmitSound(table.Random(swingSounds))
        owner:EmitSound(table.Random(attackSounds), 60)
    end

    if IsValid(hitEnt) or tr_main.HitWorld then
        self:SendWeaponAnim(ACT_VM_HITCENTER)

        if not (CLIENT and (not IsFirstTimePredicted())) then
            local edata = EffectData()
            edata:SetStart(spos)
            edata:SetOrigin(tr_main.HitPos)
            edata:SetNormal(tr_main.Normal)
            edata:SetSurfaceProp(tr_main.SurfaceProps)
            edata:SetHitBox(tr_main.HitBox)
            edata:SetEntity(hitEnt)

            if hitEnt:IsPlayer() or hitEnt:GetClass() == "prop_ragdoll" then
                util.Effect("BloodImpact", edata)
                owner:LagCompensation(false)
                owner:FireBullets({ Num = 1, Src = spos, Dir = owner:GetAimVector(), Spread = vector_origin, Tracer = 0, Force = 1, Damage = 0 })

                owner:EmitSound(table.Random(fleshSounds), 75)
            else
                util.Effect("Impact", edata)

                owner:EmitSound(table.Random(hitSounds), 75)
            end
        end
    else
        self:SendWeaponAnim(ACT_VM_MISSCENTER)
    end

    if not CLIENT and IsPlayer(hitEnt) and not hitEnt:ShouldActLikeJester() then
        local dmg = DamageInfo()
        dmg:SetDamage(self.Primary.Damage)
        dmg:SetAttacker(owner)
        dmg:SetInflictor(self)
        dmg:SetDamageForce(owner:GetAimVector() * 5)
        dmg:SetDamagePosition(owner:GetPos())
        dmg:SetDamageType(DMG_SLASH)

        hitEnt:DispatchTraceAttack(dmg, spos + (owner:GetAimVector() * 3), sdest)
    end

    if owner.LagCompensation then
        owner:LagCompensation(false)
    end
end

--[[
Jump Attack
]]

function SWEP:SecondaryAttack()
    if not werewolf_leap_enabled:GetBool() then return end

    local owner = self:GetOwner()
    if not IsValid(owner) then return end

    if not self:CanSecondaryAttack() or not owner:IsOnGround() then return end

    self:SetNextSecondaryFire(CurTime() + self.Secondary.Delay)

    if SERVER then
        owner:SetVelocity(owner:GetForward() * 200 + Vector(0,0,400))
        owner:EmitSound(table.Random(leapSounds))
    end

    -- Make this use the leap animation
    self.ActivityTranslate[ACT_MP_JUMP] = ACT_ZOMBIE_LEAPING

    -- Make it look like the player is jumping
    hook.Run("DoAnimationEvent", owner, PLAYERANIMEVENT_JUMP)

    -- Sync this jump override to the other players so they can see it too
    if SERVER then
        net.Start("TTT_WerewolfLeapStart")
        net.WritePlayer(owner)
        net.Broadcast()
    end
end

function SWEP:Think()
    if self.ActivityTranslate[ACT_MP_JUMP] == nil then return end

    local owner = self:GetOwner()
    if not IsValid(owner) or owner.m_bJumping then return end

    -- When the player hits the ground or lands in water, reset the animation back to normal
    if owner:IsOnGround() or owner:WaterLevel() > 0 then
        self.ActivityTranslate[ACT_MP_JUMP] = nil

        -- Sync clearing the override to the other players as well
        if SERVER then
            net.Start("TTT_WerewolfLeapEnd")
            net.WritePlayer(owner)
            net.Broadcast()
        end
    end
end

function SWEP:OnDrop()
    self:Remove()
end

function SWEP:Deploy()
    self.Primary.Damage = werewolf_attack_damage:GetInt()
    self.Primary.Delay = werewolf_attack_delay:GetFloat()

    local vm = self:GetOwner():GetViewModel()
    vm:SendViewModelMatchingSequence(vm:LookupSequence("fists_draw"))
end

function SWEP:Holster()
    return false
end

if CLIENT then
    net.Receive("TTT_WerewolfLeapStart", function()
        local ply = net.ReadPlayer()
        if not IsPlayer(ply) then return end

        hook.Run("DoAnimationEvent", ply, PLAYERANIMEVENT_JUMP)

        local wep = ply:GetActiveWeapon()
        if IsValid(wep) and WEPS.GetClass(wep) == "weapon_wwf_claws" and wep.ActivityTranslate then
            wep.ActivityTranslate[ACT_MP_JUMP] = ACT_ZOMBIE_LEAPING
        end
    end)

    net.Receive("TTT_WerewolfLeapEnd", function()
        local ply = net.ReadPlayer()
        if not IsPlayer(ply) then return end

        local wep = ply:GetActiveWeapon()
        if IsValid(wep) and WEPS.GetClass(wep) == "weapon_wwf_claws" and wep.ActivityTranslate then
            wep.ActivityTranslate[ACT_MP_JUMP] = nil
        end
    end)
end