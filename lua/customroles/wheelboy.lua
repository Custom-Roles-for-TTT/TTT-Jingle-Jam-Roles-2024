local hook = hook
local net = net
local table = table

local AddHook = hook.Add
local TableInsert = table.insert

local ROLE = {}

ROLE.nameraw = "wheelboy"
ROLE.name = "Wheelboy"
ROLE.nameplural = "Wheelboys"
ROLE.nameext = "a Wheelboy"
ROLE.nameshort = "whl"

ROLE.desc = [[You are {role}! TODO]]
ROLE.shortdesc = "TODO"

ROLE.team = ROLE_TEAM_JESTER

ROLE.convars = {}

RegisterRole(ROLE)

if SERVER then
    AddCSLuaFile()

    util.AddNetworkString("TTT_WheelboySpinWheel")

    concommand.Add("ttt_wheelboy_test", function(ply)
        net.Start("TTT_WheelboySpinWheel")
        net.Send(ply)
    end)
end

if CLIENT then
    local cam = cam
    local draw = draw
    local math = math
    local surface = surface

    local CamPopModelMatrix = cam.PopModelMatrix
    local CamPushModelMatrix = cam.PushModelMatrix
    local DrawNoTexture = draw.NoTexture
    local DrawDrawText = draw.DrawText
    local MathCos = math.cos
    local MathRad = math.rad
    local MathSin = math.sin
    local SurfaceSetDrawColor = surface.SetDrawColor
    local SurfaceDrawPoly = surface.DrawPoly

    local wheelStartTime = nil
    net.Receive("TTT_WheelboySpinWheel", function()
        wheelStartTime = CurTime()
    end)

    local pointerOutlinePoints = {
        { x = 0, y = -194 },
        { x = -16, y = -204 },
        { x = -16, y = -221 },
        { x = 16, y = -221 },
        { x = 16, y = -204 }
    }
    local pointerPoints = {
        { x = 0, y = -195 },
        { x = -15, y = -205 },
        { x = -15, y = -220 },
        { x = 15, y = -220 },
        { x = 15, y = -205 }
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

    -- Derived from the surface.DrawPoly example on the GMod wiki
    local function DrawCircle(x, y, radius, seg)
        local cir = {}

        table.insert(cir, { x = x, y = y })
        for i = 0, seg do
            local a = MathRad((i / seg) * -360)
            table.insert(cir, { x = x + MathSin(a) * radius, y = y + MathCos(a) * radius })
        end

        local a = MathRad(0) -- This is needed for non absolute segment counts
        table.insert(cir, { x = x + MathSin(a) * radius, y = y + MathCos(a) * radius })

        SurfaceSetDrawColor(0, 0, 0, 255)
        DrawNoTexture()
        surface.DrawPoly(cir)
    end

    local colors = {
        Color(76, 170, 231, 255),
        Color(249, 67, 46, 255),
        Color(16, 212, 128, 255),
        Color(55, 24, 102, 255),
        Color(239, 224, 99, 255),
        Color(249, 67, 46, 255),
        Color(209, 98, 175, 255),
        Color(76, 170, 231, 255),
        Color(249, 67, 46, 255),
        Color(16, 212, 128, 255),
        Color(55, 24, 102, 255),
        Color(239, 224, 99, 255),
        Color(249, 67, 46, 255),
        Color(209, 98, 175, 255)
    }
    local effectNames = {
        "Slow movement",
        "Slow firing",
        "Fast stamina consumption",
        "Lorem ipsum",
        "Etc and stuff",
        "More things",
        "This is for testing",
        "More words",
        "Words and things",
        "Sometimes I can even spell",
        "Sometimes I can't",
        "Aaaaaaaaaaaaaaaaah",
        "Just yelling into the void",
        "And things"
    }

    -- Thanks to Angela from the Lonely Yogs for the algorithm!
    local function DrawCircleSegment(segmentIdx, segmentAngle, segmentCount, polyCount, radius)
        local text = effectNames[segmentIdx]
        local color = colors[segmentIdx]

        -- Draw each of the polygons except the first and last to create a gap between segments
        for polyIdx = 2, polyCount - 1 do
            -- Rotate to the angle of this polygon
            local polyMat = Matrix()
            polyMat:Rotate(Angle(0, (polyIdx - 1) * (segmentAngle / polyCount), 0))

            -- Draw a triangle
            local polySegments = {
                { x = 0.05, y = 0 },
                { x = 1   , y = 0 },
                { x = MathCos(MathRad(segmentAngle) / polyCount), y = MathSin(MathRad(segmentAngle) / polyCount) }
            }

            CamPushModelMatrix(polyMat, true)
                SurfaceSetDrawColor(color.r, color.g, color.b, color.a)
                DrawNoTexture()
                SurfaceDrawPoly(polySegments)
            CamPopModelMatrix()
        end

        local textMat = Matrix()

        -- Multiply by the inverse to undo the scaling, because the scaled text is huge
        local textMatInvert = textMat:GetInverse()
        textMat:Scale(Vector(1 / radius, 1 / radius, 1 / radius))
        textMat:Mul(textMatInvert)

        -- Move out from the center slightly and rotate to re-align the text with the center of the segment
        textMat:Translate(Vector(35, 0, 0))
        textMat:Rotate(Angle(0, segmentAngle / 2, 0))

        CamPushModelMatrix(textMat, true)
            DrawDrawText(text, "DefaultBold", 0, 0, COLOR_WHITE, TEXT_ALIGN_LEFT)
        CamPopModelMatrix()
    end

    local function DrawSegmentedCircle(x, y, radius, seg)
        local segmentCount = #colors
        local segmentAngle = (360 / segmentCount)

        -- TODO: Rotate at variable speed, decreasing over time
        local ang = RealTime() * 50
        local mat = Matrix()
        mat:Translate(Vector(x, y, 0))
        mat:Rotate(Angle(0, ang, 0))
        mat:Scale(Vector(radius, radius, radius))

        CamPushModelMatrix(mat)
            for segmentIdx = 1, segmentCount do
                -- Rotate to the angle of this segment
                local segmentMat = Matrix()
                segmentMat:Rotate(Angle(0, (segmentIdx - 1) * segmentAngle, 0))

                CamPushModelMatrix(segmentMat, true)
                    DrawCircleSegment(segmentIdx, segmentAngle, segmentCount, seg, radius)
                CamPopModelMatrix()
            end
        CamPopModelMatrix()
    end

    AddHook("HUDPaint", "Wheelboy_Wheel_HUDPaint", function()
        if not wheelStartTime then return end

        local centerX, centerY = ScrW() / 2, ScrH() / 2
        DrawCircle(centerX, centerY, 205, 60)
        DrawSegmentedCircle(centerX, centerY, 200, 30)
        DrawPointer(centerX, centerY)

        -- TODO: Play clicking sound at roughly rotation interval
        -- TODO: When it stops rotating:
        --       1. Send the result to the server
        --       2. Wait X seconds before hiding
    end)

    --------------
    -- TUTORIAL --
    --------------

    AddHook("TTTTutorialRoleText", "Wheelboy_TTTTutorialRoleText", function(role, titleLabel)
        if role ~= ROLE_WHEELBOY then return end

        -- TODO
    end)
end