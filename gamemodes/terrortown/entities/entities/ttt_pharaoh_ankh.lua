if SERVER then
    AddCSLuaFile()
end

local move_ankh = CreateConVar("ttt_pharaoh_move_ankh", "1", FCVAR_REPLICATED, "Whether an Ankh's owner can move it", 0, 1)

if CLIENT then
    local hint_params = {usekey = Key("+use", "USE")}

    ENT.TargetIDHint = function(ankh)
        local client = LocalPlayer()
        if not IsPlayer(client) then return end

        local name
        if not IsValid(ankh) or ankh:GetPlacer() ~= client then
            name = LANG.GetTranslation("phr_ankh_name")
        else
            name = LANG.GetParamTranslation("phr_ankh_name_health", { current = ankh:Health(), max = ankh:GetMaxHealth() })
        end

        return {
            name = name,
            hint = "phr_ankh_hint",
            fmt  = function(ent, txt)

                local hint = txt
                if ent:GetPlacer() ~= client then
                    -- Pharaoh can always steal
                    if not client:IsPharaoh() then
                        local roleTeam = client:GetRoleTeam(true)
                        local teamName = GetRawRoleTeamName(roleTeam)
                        local canSteal = cvars.Bool("ttt_pharaoh_" .. teamName .. "_steal", false)
                        -- Don't tell the user they can steal it when they can't
                        if not canSteal then return end
                    end

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
ENT.Model = Model("models/cr_pharaoh/w_cr_pharaoh_ankh.mdl")

ENT.CanUseKey = true

AccessorFuncDT(ENT, "Pharaoh", "Pharaoh")
AccessorFuncDT(ENT, "Placer", "Placer")

local ankh_heal_rate = CreateConVar("ttt_pharaoh_ankh_heal_rate", "1", FCVAR_REPLICATED, "How often (in seconds) the Pharaoh should heal when they are near the Ankh. Set to 0 to disable", 0, 60)
local ankh_heal_amount = CreateConVar("ttt_pharaoh_ankh_heal_amount", "1", FCVAR_REPLICATED, "How much to heal the Pharaoh per tick when they are near the Ankh. Set to 0 to disable", 0, 100)
local ankh_repair_rate = CreateConVar("ttt_pharaoh_ankh_repair_rate", "1", FCVAR_REPLICATED, "How often (in seconds) the Ankh should repair when their Pharaoh is near. Set to 0 to disable", 0, 60)
local ankh_repair_amount = CreateConVar("ttt_pharaoh_ankh_repair_amount", "5", FCVAR_REPLICATED, "How much to repair the Ankh per tick when their Pharaoh is near it. Set to 0 to disable", 0, 500)
local ankh_heal_repair_dist = CreateConVar("ttt_pharaoh_ankh_heal_repair_dist", "100", FCVAR_REPLICATED, "The maximum distance away the Pharaoh can be for the heal and repair to occur. Set to 0 to disable", 0, 2000)
local ankh_aura_color_mode = CreateConVar("ttt_pharaoh_ankh_aura_color_mode", "2", FCVAR_REPLICATED, "Determines what color the Ankh's aura should be. 0 - Disable. 1 - White. 2 - The placer's role color (same as 3 if \"simplified\" color mode is set). 3 - The placer's team color.", 0, 3)

if SERVER then
    ENT.PlaceSound = Sound("phr/choir_and_bell_short.wav")
    CreateConVar("ttt_pharaoh_ankh_place_sound", "1", FCVAR_NONE, "Whether to play a sound when the Ankh is placed down", 0, 1)
end

function ENT:SetupDataTables()
   self:DTVar("Entity", 0, "Pharaoh")
   self:DTVar("Entity", 1, "Placer")
end

function ENT:Initialize()
    self:SetModel(self.Model)

    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)

    local mins = Vector(-5, -5, -5)
    local maxs = Vector(5, 5, 32)
    self:SetCollisionBounds(mins, maxs)
    self:SetCollisionGroup(COLLISION_GROUP_WEAPON)

    if SERVER then
        self:WeldToGround(true)
        self:SetUseType(CONTINUOUS_USE)

        if GetConVar("ttt_pharaoh_ankh_place_sound"):GetBool() then
            self:EmitSound(self.PlaceSound)
        end
    end

    if CLIENT then
        self.HealRadius = ankh_heal_repair_dist:GetInt()
        self:SetRenderBounds(mins, maxs, Vector(self.HealRadius, self.HealRadius, 0))
    end
end

if SERVER then
    local math = math

    local MathMin = math.min

    local damage_own_ankh = CreateConVar("ttt_pharaoh_damage_own_ankh", "0", FCVAR_NONE, "Whether an Ankh's owner can damage it", 0, 1)
    local warn_damage = CreateConVar("ttt_pharaoh_warn_damage", "1", FCVAR_NONE, "Whether an Ankh's owner is warned when it is damaged", 0, 1)
    local warn_destroy = CreateConVar("ttt_pharaoh_warn_destroy", "1", FCVAR_NONE, "Whether an Ankh's owner is warned when it is destroyed", 0, 1)

    function ENT:OnTakeDamage(dmginfo)
        local att = dmginfo:GetAttacker()
        local placer = self:GetPlacer()
        if not IsPlayer(placer) then return end

        if att:ShouldActLikeJester() then return end
        if att == placer and not damage_own_ankh:GetBool() then return end

        self:SetHealth(self:Health() - dmginfo:GetDamage())

        if IsPlayer(att) then
            DamageLog(Format("DMG: \t %s [%s] damaged ankh %s [%s] for %d dmg", att:Nick(), ROLE_STRINGS[att:GetRole()], placer:Nick(), ROLE_STRINGS[placer:GetRole()], dmginfo:GetDamage()))
        end

        if self:Health() <= 0 then
            self:DestroyAnkh()
            if warn_destroy:GetBool() then
                placer:QueueMessage(MSG_PRINTBOTH, "Your Ankh has been destroyed!")
            end
        elseif warn_damage:GetBool() then
            LANG.Msg(placer, "phr_ankh_damaged")
        end
    end

    function ENT:Use(activator)
        if not IsPlayer(activator) then return end
        -- Don't let them pick up the ankh if they already have the weapon
        if activator:HasWeapon("weapon_phr_ankh") then return end

        local placer = self:GetPlacer()
        if not IsPlayer(placer) then return end

        -- If placer, pick up
        if activator == placer then
            if not move_ankh:GetBool() then return end

            local wep = activator:Give("weapon_phr_ankh")
            -- Save the health remaining
            wep.RemainingHealth = self:Health()
            self:SetPlacer(nil)
            self:Remove()
            return
        end

        -- Pharaoh can always steal
        if not activator:IsPharaoh() then
            -- Make sure this player's team is allowed to steal the ankh
            local roleTeam = activator:GetRoleTeam(true)
            local teamName = GetRawRoleTeamName(roleTeam)
            local canSteal = cvars.Bool("ttt_pharaoh_" .. teamName .. "_steal", false)
            if not canSteal then return end
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

    -- If placer is a Pharaoh and they are nearby, heal each other at configurable rate
    local nextHealTime = nil
    local nextRepairTime = nil
    function ENT:Think()
        local placer = self:GetPlacer()
        if not IsPlayer(placer) then return end

        if placer:IsPharaoh() and placer:IsRoleAbilityDisabled() then return end

        local distance = ankh_heal_repair_dist:GetInt()
        if distance <= 0 then return end

        local distanceSqr = distance * distance

        if self:GetPos():DistToSqr(placer:GetPos()) <= distanceSqr then
            local curTime = CurTime()
            local healRate = ankh_heal_rate:GetInt()
            local healAmount = ankh_heal_amount:GetInt()
            if healRate > 0 and healAmount > 0 and (nextHealTime == nil or nextHealTime <= curTime) then
                -- Don't heal the first tick
                if nextHealTime ~= nil then
                    local hp = placer:Health()
                    local maxHp = placer:GetMaxHealth()
                    local newHp = MathMin(maxHp, hp + healAmount)
                    if hp ~= newHp then
                        placer:SetHealth(newHp)
                    end
                end

                nextHealTime = curTime + healRate
            end

            local repairRate = ankh_repair_rate:GetInt()
            local repairAmount = ankh_repair_amount:GetInt()
            if repairRate > 0 and repairAmount > 0 and (nextRepairTime == nil or nextRepairTime <= curTime) then
                -- Don't repair the first tick
                if nextRepairTime ~= nil then
                    local hp = self:Health()
                    local maxHp = self:GetMaxHealth()
                    local newHp = MathMin(maxHp, hp + repairAmount)
                    if hp ~= newHp then
                        self:SetHealth(newHp)
                    end
                end

                nextRepairTime = curTime + repairRate
            end
        else
            nextHealTime = nil
            nextRepairTime = nil
        end
    end

    function ENT:DestroyAnkh()
        self:WeldToGround(false)

        local effect = EffectData()
        effect:SetOrigin(self:GetPos())
        util.Effect("cball_explode", effect)
        self:Remove()
    end

    -- Copied from C4
    function ENT:WeldToGround(state)
        if state then
           -- getgroundentity does not work for non-players
           -- so sweep ent downward to find what we're lying on
           local ignore = player.GetAll()
           table.insert(ignore, self)

           local tr = util.TraceEntity({ start = self:GetPos(), endpos = self:GetPos() - Vector(0, 0, 16), filter = ignore, mask = MASK_SOLID }, self)

           -- Start by increasing weight/making uncarryable
           local phys = self:GetPhysicsObject()
           if IsValid(phys) then
              -- Could just use a pickup flag for this. However, then it's easier to
              -- push it around.
              self.OrigMass = phys:GetMass()
              phys:SetMass(150)
           end

           if tr.Hit and (IsValid(tr.Entity) or tr.HitWorld) then
              -- "Attach" to a brush if possible
              if IsValid(phys) and tr.HitWorld then
                 phys:EnableMotion(false)
              end

              -- Else weld to objects we cannot pick up
              local entphys = tr.Entity:GetPhysicsObject()
              if IsValid(entphys) and entphys:GetMass() > CARRY_WEIGHT_LIMIT then
                 constraint.Weld(self, tr.Entity, 0, 0, 0, true)
              end

              -- Worst case, we are still uncarryable
           end
        else
           constraint.RemoveConstraints(self, "Weld")
           local phys = self:GetPhysicsObject()
           if IsValid(phys) then
              phys:EnableMotion(true)
              phys:SetMass(self.OrigMass or 10)
           end
        end
     end
end

if CLIENT then
    local cam = cam
    local render = render

    local CamStart3D = cam.Start3D
    local CamEnd3D = cam.End3D
    local RenderDrawQuadEasy = render.DrawQuadEasy
    local RenderSetMaterial = render.SetMaterial

    local auraTexture = Material("cr_pharaoh/decals/ankh_floor_decal.vmt")
    local auraNormal = Vector(0, 0, 1)

    function ENT:Draw()
        self:DrawModel()
        self:DrawShadow(true)

        local aura_color_mode = ankh_aura_color_mode:GetInt()
        if aura_color_mode <= PHARAOH_AURA_COLOR_MODE_DISABLE then return end

        local placer = self:GetPlacer()
        if not IsPlayer(placer) then return end

        local pos = self:GetPos()
        local size = self.HealRadius * 2

        local color
        if aura_color_mode == PHARAOH_AURA_COLOR_MODE_WHITE then
            color = COLOR_WHITE
        elseif aura_color_mode == PHARAOH_AURA_COLOR_MODE_ROLE then
            color = ROLE_COLORS[placer:GetRole()]
        else
            local roleTeam = player.GetRoleTeam(placer:GetRole())
            _, color = GetRoleTeamInfo(roleTeam, true)
        end
        CamStart3D()
            RenderSetMaterial(auraTexture)
            RenderDrawQuadEasy(pos, auraNormal, size, size, color)
        CamEnd3D()
    end

    function ENT:Think()
    end
end