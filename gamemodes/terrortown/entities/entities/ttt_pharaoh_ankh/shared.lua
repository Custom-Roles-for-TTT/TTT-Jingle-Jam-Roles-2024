if SERVER then
    AddCSLuaFile("shared.lua")
end

local move_ankh = CreateConVar("ttt_pharaoh_move_ankh", "1", FCVAR_REPLICATED, "Whether an Ankh's owner can move it", 0, 1)

if CLIENT then
    local hint_params = {usekey = Key("+use", "USE")}

    ENT.TargetIDHint = function()
        return {
            name = LANG.GetTranslation("phr_ankh_name"),
            hint = "phr_ankh_hint",
            fmt  = function(ent, txt)
                local hint = txt
                if ent:GetOwner() ~= LocalPlayer() then
                    hint = hint .. "_steal"
                elseif move_ankh:GetBool() then
                    hint = hint .. "_unmovable"
                end

                return LANG.GetParamTranslation(txt, hint_params)
            end
        }
    end
end

ENT.Type = "anim"
ENT.Model = Model("models/props/cs_office/microwave.mdl")

ENT.CanUseKey = true

AccessorFunc(ENT, "Pharaoh", "Pharaoh")
AccessorFunc(ENT, "Placer", "Placer")

function ENT:Initialize()
    self:SetModel(self.Model)

    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_BBOX)

    -- TODO: Modify this to match model
    local b = 32
    self:SetCollisionBounds(Vector(-b, -b, -b), Vector(b,b,b))

    self:SetCollisionGroup(COLLISION_GROUP_WEAPON)

    -- TODO: Make this configurable
    local health = 200

    if SERVER then
        self:SetMaxHealth(health)

        local phys = self:GetPhysicsObject()
        if IsValid(phys) then
            phys:SetMass(200)
        end

        self:SetUseType(CONTINUOUS_USE)
    end
    self:SetHealth(health)
end

if SERVER then
    local damage_own_ankh = CreateConVar("ttt_pharaoh_damage_own_ankh", "0", FCVAR_NONE, "Whether an Ankh's owner can damage it", 0, 1)
    local warn_steal = CreateConVar("ttt_pharaoh_warn_steal", "1", FCVAR_NONE, "Whether to warn an Ankh's owner is warned when it is stolen", 0, 1)
    local warn_damage = CreateConVar("ttt_pharaoh_warn_damage", "1", FCVAR_NONE, "Whether to warn an Ankh's owner is warned when it is damaged", 0, 1)
    local warn_destroy = CreateConVar("ttt_pharaoh_warn_destroy", "1", FCVAR_NONE, "Whether to warn an Ankh's owner is warned when it is destroyed", 0, 1)

    function ENT:OnTakeDamage(dmginfo)
        local placer = self:GetPlacer()
        if not IsPlayer(placer) then return end

        if dmginfo:GetAttacker() == placer and not damage_own_ankh:GetBool() then return end

        self:TakePhysicsDamage(dmginfo)
        self:SetHealth(self:Health() - dmginfo:GetDamage())

        if self:Health() <= 0 then
            self:Remove()
            util.EquipmentDestroyed(self:GetPos())
            if warn_destroy:GetBool() then
                LANG.Msg(placer, "phr_ankh_destroyed")
            end
        elseif warn_damage:GetBool() then
            LANG.Msg(placer, "phr_ankh_damaged")
        end
    end

    function ENT:UseOverride(activator)
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

        -- TODO: If not placer, hold to steal
        if warn_steal:GetBool() then
            LANG.Msg(placer, "phr_ankh_stolen")
        end
    end

    -- TODO: If placer is nearby, heal eachother at configurable rate
end