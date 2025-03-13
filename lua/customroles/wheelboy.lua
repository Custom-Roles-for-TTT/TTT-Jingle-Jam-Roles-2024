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
    local CurTime = CurTime
    local draw = draw
    local Material = Material
    local math = math
    local surface = surface

    local CamPopModelMatrix = cam.PopModelMatrix
    local CamPushModelMatrix = cam.PushModelMatrix
    local DrawNoTexture = draw.NoTexture
    local DrawSimpleTextOutlined = draw.SimpleTextOutlined
    local MathCos = math.cos
    local MathMin = math.min
    local MathRad = math.rad
    local MathRand = math.random
    local MathSin = math.sin
    local SurfaceDrawPoly = surface.DrawPoly
    local SurfaceDrawTexturedRect = surface.DrawTexturedRect
    local SurfaceSetDrawColor = surface.SetDrawColor
    local SurfaceSetMaterial = surface.SetMaterial

    -----------
    -- WHEEL --
    -----------

    surface.CreateFont("WheelboyLabels", {
        font = "Tahoma",
        size = 16,
        weight = 1000
    })

    -- Start/Stop --

    local wheelStartTime = nil
    local wheelEndTime = nil
    local wheelOffset = nil
    net.Receive("TTT_WheelboySpinWheel", function()
        wheelStartTime = CurTime()
        wheelOffset = MathRand() * 360
        -- TODO: Make the time configurable?
        wheelEndTime = wheelStartTime + 10
    end)

    -- Pointer --

    local pointerOutlinePoints = {
        { x = 0, y = -237 },
        { x = -16, y = -247 },
        { x = -16, y = -264 },
        { x = 16, y = -264 },
        { x = 16, y = -247 }
    }
    local pointerPoints = {
        { x = 0, y = -238 },
        { x = -15, y = -248 },
        { x = -15, y = -263 },
        { x = 15, y = -263 },
        { x = 15, y = -248 }
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

    -- Background --

    -- Derived from the surface.DrawPoly example on the GMod wiki
    local function DrawCircle(x, y, radius, seg)
        local cir = {}

        TableInsert(cir, { x = x, y = y })
        for i = 0, seg do
            local a = MathRad((i / seg) * -360)
            TableInsert(cir, { x = x + MathSin(a) * radius, y = y + MathCos(a) * radius })
        end

        local a = MathRad(0) -- This is needed for non absolute segment counts
        TableInsert(cir, { x = x + MathSin(a) * radius, y = y + MathCos(a) * radius })

        SurfaceSetDrawColor(0, 0, 0, 255)
        DrawNoTexture()
        surface.DrawPoly(cir)
    end

    -- Wheel --

    local colors = {
        Color(76, 170, 231, 255),
        Color(249, 67, 46, 255),
        Color(21, 106, 46, 255),
        Color(55, 24, 102, 255),
        Color(239, 224, 99, 255),
        Color(249, 67, 46, 255),
        Color(209, 98, 175, 255),
        Color(76, 170, 231, 255),
        Color(249, 67, 46, 255),
        Color(21, 106, 46, 255),
        Color(55, 24, 102, 255),
        Color(239, 224, 99, 255),
        Color(249, 67, 46, 255),
        Color(209, 98, 175, 255)
    }
    -- TODO
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

    local logoMat = Material("materials/vgui/ttt/roles/whl/logo.png")
    local function DrawLogo(x, y)
        SurfaceSetMaterial(logoMat)
        SurfaceSetDrawColor(COLOR_WHITE)
        SurfaceDrawTexturedRect(x - 25, y - 25, 50, 50)
    end

    -- Thanks to Angela from the Lonely Yogs for the algorithm!
    local function DrawCircleSegment(segmentIdx, segmentAngle, segmentCount, curvePointCount, radius)
        local text = effectNames[segmentIdx]
        local color = colors[segmentIdx]

        -- Generate all the points on the polygon
        local polySegments = {
            { x = 0, y = 0 }
        }
        for i = 0, curvePointCount do
            TableInsert(
                polySegments,
                {
                    x = MathCos(i * MathRad(segmentAngle) / curvePointCount),
                    y = MathSin(i * MathRad(segmentAngle) / curvePointCount)
                }
            )
        end

        local polyMat = Matrix()
        local scaleDown = 0.95
        -- Rotate and move the segment to the origin before applying the scaling and moving/rotating it back
        -- This is needed so the scaling is applied against the outer edge of the segment
        polyMat:Rotate(Angle(0, segmentAngle / 2, 0))
        polyMat:Translate(Vector(0.5, 0, 0))
        polyMat:Scale(Vector(scaleDown, scaleDown, 1))
        polyMat:Translate(Vector(-0.5, 0, 0))
        polyMat:Rotate(Angle(0, -segmentAngle / 2, 0))

        CamPushModelMatrix(polyMat, true)
            SurfaceSetDrawColor(color.r, color.g, color.b, color.a)
            DrawNoTexture()
            SurfaceDrawPoly(polySegments)
        CamPopModelMatrix()

        -- Move out from the center slightly and rotate to re-align the text with the center of the segment
        local textRenderDisplacement = 10
        local textMat = Matrix()
        textMat:Rotate(Angle(0, segmentAngle / 2, 0))

        -- This is a really crude attempt at centering the text...
        textMat:Translate(Vector(0.5 - #text / 90, 0, 0))
        textMat:Scale(Vector(1 / radius, 1 / radius, 1))

        -- Undo text displacement
        textMat:Translate(Vector(0, -textRenderDisplacement, 0))

        CamPushModelMatrix(textMat, true)
            -- Displace to ensure the text doesn't get cut off below y=0 (in text render space)
            DrawSimpleTextOutlined(text, "WheelboyLabels", 0, textRenderDisplacement, COLOR_WHITE, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, 1, COLOR_BLACK)
        CamPopModelMatrix()
    end

    local function DrawSegmentedCircle(x, y, radius, seg)
        local segmentCount = #colors
        local segmentAngle = (360 / segmentCount)

        -- Once we've spun for the desired time, stop rotating at that point
        local baseTime = MathMin(CurTime(), wheelEndTime)
        -- TODO: Rotate at variable speed, decreasing over time
        local ang = wheelOffset + (baseTime * 150)

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
        DrawCircle(centerX, centerY, 247, 60)
        DrawSegmentedCircle(centerX, centerY, 250, 30)
        DrawPointer(centerX, centerY)
        DrawLogo(centerX, centerY)

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