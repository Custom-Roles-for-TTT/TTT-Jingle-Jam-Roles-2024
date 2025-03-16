AddCSLuaFile()

if CLIENT then
    SWEP.PrintName          = "Wheel Spinner"
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

SWEP.InLoadoutFor           = {ROLE_WHEELBOY}
SWEP.InLoadoutForDefault    = {ROLE_WHEELBOY}

SWEP.Primary.Delay          = 0.25
SWEP.Primary.Automatic      = false
SWEP.Primary.Cone           = 0
SWEP.Primary.Ammo           = nil
SWEP.Primary.Sound          = ""

function SWEP:Initialize()
    self:SendWeaponAnim(ACT_SLAM_DETONATOR_DRAW)

    if CLIENT then
        self:AddHUDHelp("whl_spinner_help_pri", "whl_spinner_help_sec", true)
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
    if GetRoundState() ~= ROUND_ACTIVE then return end

    self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
    self:SendWeaponAnim(ACT_SLAM_DETONATOR_DETONATE)

    local owner = self:GetOwner()
    if not IsPlayer(owner) then return end

    local curTime = CurTime()
    local nextSpinTime = owner:GetNWInt("WheelboyNextSpinTime", nil)
    if nextSpinTime == nil or curTime >= nextSpinTime then
        local recharge_time = GetConVar("ttt_wheelboy_wheel_recharge_time"):GetInt()
        owner:SetNWInt("WheelboyNextSpinTime", curTime + recharge_time)
        net.Start("TTT_WheelboySpinWheel")
        net.Send(owner)
    else
        owner:QueueMessage(MSG_PRINTCENTER, "Your weak muscles haven't recovered enough to spin again yet...")
    end
end

function SWEP:SecondaryAttack()
end

function SWEP:OnDrop()
    self:Remove()
end