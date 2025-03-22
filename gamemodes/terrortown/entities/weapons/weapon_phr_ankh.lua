AddCSLuaFile()

if CLIENT then
    SWEP.PrintName          = "Ankh"
    SWEP.Slot               = 8

    SWEP.ViewModelFOV       = 60
    SWEP.DrawCrosshair      = false
    SWEP.ViewModelFlip      = false
end

SWEP.ViewModel              = "models/cr_pharaoh/c_cr_pharaoh_ankh.mdl"
SWEP.WorldModel             = "models/cr_pharaoh/w_cr_pharaoh_ankh.mdl"
SWEP.Weight                 = 2

SWEP.Base                   = "weapon_tttbase"
SWEP.Category               = WEAPON_CATEGORY_ROLE

SWEP.Spawnable              = false
SWEP.AutoSpawnable          = false
SWEP.HoldType               = "normal"
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

SWEP.GhostMinBounds         = Vector(-5, -5, -5)
SWEP.GhostMaxBounds         = Vector(5, 5, 5)

SWEP.RemainingHealth        = 0

local ankh_health = CreateConVar("ttt_pharaoh_ankh_health", "500", FCVAR_REPLICATED, "How much health the Ankh should have", 1, 2000)

function SWEP:Initialize()
    if CLIENT then
        self:AddHUDHelp("phr_ankh_help_pri", "phr_ankh_help_sec", true)
    end
    return self.BaseClass.Initialize(self)
end

function SWEP:SetupDataTables()
    self:NetworkVar("Float", 0, "NextIdle")
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

    self:SendWeaponAnim(ACT_VM_DOWN)
    timer.Simple(self:SequenceDuration(), function()
        if not IsPlayer(owner) then return end
        if not IsValid(self) then return end

        local ankh = ents.Create("ttt_pharaoh_ankh")
        local eyeAngles = owner:EyeAngles()

        -- Spawn the ankh
        ankh:SetPos(tr.HitPos)
        ankh:SetAngles(Angle(0, eyeAngles.y, 0))
        ankh:SetPharaoh(owner)
        ankh:SetPlacer(owner)
        owner.PharaohAnkh = ankh

        local health = ankh_health:GetInt()
        if self.RemainingHealth > 0 then
            ankh:SetHealth(self.RemainingHealth)
        else
            ankh:SetHealth(health)
        end
        ankh:SetMaxHealth(health)

        ankh:Spawn()

        self:Remove()
    end)
end

function SWEP:SecondaryAttack()
end

if CLIENT then
    SWEP.GhostEnt = ClientsideModel(SWEP.WorldModel)
    -- Scale this down to match (roughly) the size it will be in the world
    SWEP.GhostEnt:SetModelScale(0.53)
end

function SWEP:ViewModelDrawn()
    if SERVER then return end

    local owner = self:GetOwner()
    if not IsPlayer(owner) then return end

    -- Draw a box where the ankh will be placed, colored GREEN for a good location and RED for a bad one
    local tr, hit = self:GetAimTrace(owner)
    local eyeAngles = owner:EyeAngles()

    render.Model({
        model = self.WorldModel,
        pos = tr.HitPos,
        angle = Angle(0, eyeAngles.y, 0)
    }, self.GhostEnt)
    render.DrawWireframeBox(tr.HitPos + Vector(0, 0, 5), Angle(0, eyeAngles.y, 0), Vector(-5, -5, -5), Vector(5, 5, 12), hit and COLOR_GREEN or COLOR_RED, true)
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

function SWEP:Think()
    self:Idle()
end

function SWEP:Idle()
    -- Update idle anim
    local curtime = CurTime()
    if curtime < self:GetNextIdle() then return false end

    self:SendWeaponAnim(ACT_VM_IDLE)
    self:SetNextIdle(curtime + self:SequenceDuration())

    return true
end

function SWEP:DrawWorldModel()
end

function SWEP:DrawWorldModelTranslucent()
end