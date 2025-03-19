if SERVER then
    AddCSLuaFile()
end

local move_ankh = CreateConVar("ttt_pharaoh_move_ankh", "1", FCVAR_REPLICATED, "Whether an Ankh's owner can move it", 0, 1)
local ankh_health = CreateConVar("ttt_pharaoh_ankh_health", "500", FCVAR_REPLICATED, "How much health the Ankh should have", 1, 2000)

if CLIENT then
    local hint_params = {usekey = Key("+use", "USE")}

    ENT.TargetIDHint = function()
        return {
            name = LANG.GetTranslation("phr_ankh_name"),
            hint = "phr_ankh_hint",
            fmt  = function(ent, txt)
                local hint = txt
                if ent:GetPlacer() ~= LocalPlayer() then
                    hint = hint .. "_steal"
                elseif not move_ankh:GetBool() then
                    hint = hint .. "_unmovable"
                end

                return LANG.GetParamTranslation(hint, hint_params)
            end
        }
    end
    ENT.AutomaticFrameAdvance = true
end

ENT.Type = "anim"
ENT.Model = Model("models/props/cs_office/microwave.mdl")

ENT.CanUseKey = true

AccessorFuncDT(ENT, "Pharaoh", "Pharaoh")
AccessorFuncDT(ENT, "Placer", "Placer")

function ENT:SetupDataTables()
   self:DTVar("Entity", 0, "Pharaoh")
   self:DTVar("Entity", 1, "Placer")
end

function ENT:Initialize()
    self:SetModel(self.Model)

    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_BBOX)

    -- TODO: Modify this to match model
    local b = 32
    self:SetCollisionBounds(Vector(-b, -b, -b), Vector(b,b,b))

    self:SetCollisionGroup(COLLISION_GROUP_WEAPON)

    local health = ankh_health:GetInt()
    if SERVER then
        self:SetMaxHealth(health)

        local phys = self:GetPhysicsObject()
        -- Make it un-moveable
        if IsValid(phys) then
            phys:EnableMotion(false)
        end

        self:SetUseType(CONTINUOUS_USE)
    end
    self:SetHealth(health)
end

if SERVER then
    local damage_own_ankh = CreateConVar("ttt_pharaoh_damage_own_ankh", "0", FCVAR_NONE, "Whether an Ankh's owner can damage it", 0, 1)
    local warn_damage = CreateConVar("ttt_pharaoh_warn_damage", "1", FCVAR_NONE, "Whether to warn an Ankh's owner is warned when it is damaged", 0, 1)
    local warn_destroy = CreateConVar("ttt_pharaoh_warn_destroy", "1", FCVAR_NONE, "Whether to warn an Ankh's owner is warned when it is destroyed", 0, 1)

    function ENT:OnTakeDamage(dmginfo)
        local placer = self:GetPlacer()
        if not IsPlayer(placer) then return end

        if dmginfo:GetAttacker() == placer and not damage_own_ankh:GetBool() then return end

        self:SetHealth(self:Health() - dmginfo:GetDamage())

        if self:Health() <= 0 then
            self:Remove()
            util.EquipmentDestroyed(self:GetPos())
            if warn_destroy:GetBool() then
                placer:QueueMessage(MSG_PRINTBOTH, "Your Ankh has been destroyed!")
            end
        elseif warn_damage:GetBool() then
            LANG.Msg(placer, "phr_ankh_damaged")
        end
    end

    function ENT:Use(activator)
        if not IsPlayer(activator) then return end

        local placer = self:GetPlacer()
        if not IsPlayer(placer) then return end

        -- If placer, pick up
        if activator == placer then
            if not move_ankh:GetBool() then return end

            activator:Give("weapon_phr_ankh")
            self:Remove()
            return
        end

        local curTime = CurTime()

        -- If this is a new activator, start tracking how long they've been using it for
        local stealTarget = activator.PharaohStealTarget
        if self ~= stealTarget then
            activator:SetProperty("PharaohStealTarget", self, activator)
            activator:SetProperty("PharaohStealStart", curTime, activator)
        end

        -- Keep track of the last time they used it so we can time it out
        activator.PharaohLastStealTime = curTime
    end

    -- TODO: If placer is nearby, heal eachother at configurable rate
end