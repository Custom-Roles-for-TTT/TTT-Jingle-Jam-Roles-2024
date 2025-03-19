AddCSLuaFile()

if CLIENT then
    SWEP.PrintName          = "Ankh"
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

SWEP.InLoadoutFor           = {ROLE_PHARAOH}
SWEP.InLoadoutForDefault    = {ROLE_PHARAOH}

SWEP.Primary.Delay          = 0.25
SWEP.Primary.Automatic      = false
SWEP.Primary.Cone           = 0
SWEP.Primary.Ammo           = nil
SWEP.Primary.Sound          = ""

SWEP.GhostMinBounds = Vector(-5, -5, -5)
SWEP.GhostMaxBounds = Vector(5, 5, 5)

function SWEP:Initialize()
    if CLIENT then
        self:AddHUDHelp("phr_ankh_help_pri", "phr_ankh_help_sec", true)
    end
    return self.BaseClass.Initialize(self)
end

function SWEP:GetAimTrace(owner)
    local aimStart = owner:EyePos()
    local aimDir = owner:GetAimVector()
    local len = 96

    local aimTrace = util.TraceHull({
        start = aimStart,
        endpos = aimStart + aimDir * len,
        mins = self.GhostMinBounds,
        maxs = self.GhostMaxBounds,
        filter = owner
    })

    -- This only counts as hitting if the thing we hit is below us
    return aimTrace, aimTrace.Hit and aimTrace.HitNormal.z > 0.7
end

function SWEP:PrimaryAttack()
    if CLIENT then return end

    local owner = self:GetOwner()
    if not IsPlayer(owner) then return end

    local tr, hit = self:GetAimTrace(owner)
    if not hit then return end

    local ankh = ents.Create("ttt_pharaoh_ankh")
    local eyeAngles = owner:EyeAngles()

    -- Spawn the ankh
    ankh:SetPos(tr.HitPos)
    ankh:SetAngles(Angle(0, eyeAngles.y, 0))
    ankh:SetPharaoh(owner)
    ankh:SetPlacer(owner)
    ankh:Spawn()
    ankh:PhysWake()
    owner:SetNWEntity("PharaohAnkh", ankh)

    -- Lock it in place
    local phys = ankh:GetPhysicsObject()
    if IsValid(phys) then
        phys:EnableMotion(false)
    end

    self:Remove()
end

function SWEP:SecondaryAttack()
end

function SWEP:ViewModelDrawn()
    if SERVER then return end

    local owner = self:GetOwner()
    if not IsPlayer(owner) then return end

    -- Draw a box where the ankh will be placed, colored GREEN for a good location and RED for a bad one
    local tr, hit = self:GetAimTrace(owner)
    local eyeAngles = owner:EyeAngles()
    render.DrawWireframeBox(tr.HitPos, Angle(0, eyeAngles.y, 0), self.GhostMinBounds, self.GhostMaxBounds, hit and COLOR_GREEN or COLOR_RED, true)
end

function SWEP:Reload()
   return false
end

function SWEP:OnDrop()
    self:Remove()
end

function SWEP:OnRemove()
    if CLIENT and IsValid(self:GetOwner()) and self:GetOwner() == LocalPlayer() and self:GetOwner():Alive() then
        RunConsoleCommand("lastinv")
    end
end