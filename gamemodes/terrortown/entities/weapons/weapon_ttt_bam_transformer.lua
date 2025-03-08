local ents = ents

local EntsCreate = ents.Create

AddCSLuaFile()

if CLIENT then
    SWEP.PrintName          = "Barrel Transformer"
    SWEP.Slot               = 8

    SWEP.ViewModelFOV       = 60
    SWEP.DrawCrosshair      = false
    SWEP.ViewModelFlip      = false
end

SWEP.ViewModel              = "models/weapons/c_slam.mdl"
SWEP.WorldModel             = "models/weapons/w_slam.mdl"
SWEP.Weight                 = 2

SWEP.Base                   = "weapon_tttbase"
SWEP.Category               = WEAPON_CATEGORY_ROLE

SWEP.Spawnable              = false
SWEP.AutoSpawnable          = false
SWEP.HoldType               = "slam"
SWEP.Kind                   = WEAPON_ROLE

SWEP.DeploySpeed            = 4
SWEP.AllowDrop              = false
SWEP.NoSights               = true
SWEP.UseHands               = true
SWEP.LimitedStock           = true
SWEP.AmmoEnt                = nil

SWEP.InLoadoutFor           = {ROLE_BARRELMIMIC}
SWEP.InLoadoutForDefault    = {ROLE_BARRELMIMIC}

SWEP.Primary.Delay          = 0.25
SWEP.Primary.Automatic      = false
SWEP.Primary.Cone           = 0
SWEP.Primary.Ammo           = nil
SWEP.Primary.Sound          = ""

SWEP.Secondary.Delay        = 3
SWEP.Secondary.Automatic    = false
SWEP.Secondary.Cone         = 0
SWEP.Secondary.Ammo         = nil
SWEP.Secondary.Sound        = ""

SWEP.Barrel                 = nil

function SWEP:Initialize()
    self:SendWeaponAnim(ACT_SLAM_DETONATOR_DRAW)

    if CLIENT then
        self:AddHUDHelp("bam_transformer_help_pri", "bam_transformer_help_sec", true)
    end
    return self.BaseClass.Initialize(self)
end

function SWEP:Equip()
end

function SWEP:Deploy()
    self:SendWeaponAnim(ACT_SLAM_DETONATOR_DRAW)
    return true
end

function SWEP:PrimaryAttack()
    if CLIENT then return end
    if self:GetNextPrimaryFire() > CurTime() then return end
    if IsValid(self.Barrel) then return end

    self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
    self:SendWeaponAnim(ACT_SLAM_DETONATOR_DETONATE)

    local owner = self:GetOwner()
    if IsPlayer(owner) then
        local ent = EntsCreate("prop_physics")
        if not IsValid(ent) then return end

        local pos = owner:GetPos()
        local velocity = owner:GetVelocity()

        ent:SetModel("models/props_c17/oildrum001_explosive.mdl")
        ent:SetPos(pos)
        ent.BarrelMimic = self
        ent:Spawn()

        local phys = ent:GetPhysicsObject()
        if not IsValid(phys) then ent:Remove() return end

        phys:SetVelocity(velocity)

        owner:SetParent(ent)

        owner:Spectate(OBS_MODE_CHASE)
        owner:SpectateEntity(ent)

        -- The transformer stays in their hand so hide it from view
        owner:DrawViewModel(false)
        owner:DrawWorldModel(false)

        self.Barrel = ent
        self:SetNextSecondaryFire(CurTime() + self.Secondary.Delay)
    end
end

function SWEP:SecondaryAttack()
    if CLIENT then return end
    if self:GetNextSecondaryFire() > CurTime() then return end
    if not IsValid(self.Barrel) then return end

    owner:SetParent(nil)
    owner:SpectateEntity(nil)
    owner:UnSpectate()
    owner:DrawViewModel(true)
    owner:DrawWorldModel(true)

    self.Barrel:Remove()
    self.Barrel = nil
end

function SWEP:OnDrop()
    self:Remove()
end