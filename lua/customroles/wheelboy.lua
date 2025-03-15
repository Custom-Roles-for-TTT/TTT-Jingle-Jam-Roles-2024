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
TableInsert(ROLE.convars, {
    cvar = "ttt_wheelboy_wheel_time",
    type = ROLE_CONVAR_TYPE_NUM
})
TableInsert(ROLE.convars, {
    cvar = "ttt_wheelboy_wheel_end_wait_time",
    type = ROLE_CONVAR_TYPE_NUM
})

RegisterRole(ROLE)

-- TODO: Change default value
local wheelboy_wheel_time = CreateConVar("ttt_wheelboy_wheel_time", 10, FCVAR_REPLICATED, "How long the wheel should spin for", 1, 30)
local wheelboy_wheel_end_wait_time = CreateConVar("ttt_wheelboy_wheel_end_wait_time", 10, FCVAR_REPLICATED, "How long the wheel should wait at the end, showing the result, before it hides", 1, 30)

-- TODO
local wheelEffects = {
    { name = "Slow movement", fn = function() end },
    { name = "Slow firing", fn = function() end },
    { name = "Fast stamina consumption", fn = function() end },
    { name = "Lorem ipsum", fn = function() end },
    { name = "Etc and stuff", fn = function() end },
    { name = "More things", fn = function() end },
    { name = "This is for testing", fn = function() end },
    { name = "More words", fn = function() end },
    { name = "Words and things", fn = function() end },
    { name = "Sometimes I can even spell", fn = function() end },
    { name = "Sometimes I can't", fn = function() end },
    { name = "Aaaaaaaaaaaaaaaaah", fn = function() end },
    { name = "Just yelling into the void", fn = function() end },
    { name = "And things", fn = function() end }
}

if SERVER then
    AddCSLuaFile()

    util.AddNetworkString("TTT_WheelboySpinWheel")
    util.AddNetworkString("TTT_WheelboySpinResult")

    concommand.Add("ttt_wheelboy_test", function(ply)
        net.Start("TTT_WheelboySpinWheel")
        net.Send(ply)
    end)

    net.Receive("TTT_WheelboySpinResult", function(len, ply)
        if not IsPlayer(ply) then return end
        -- TODO: Uncomment this
        --if not ply:IsActiveWheelboy() then return end

        local chosenSegment = net.ReadUInt(4)
        local result = wheelEffects[chosenSegment]

        -- TODO
        print("Selected", result.name)
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
    local SurfacePlaySound = surface.PlaySound
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
    local lastSegment = nil
    local blinkStart = nil
    net.Receive("TTT_WheelboySpinWheel", function()
        if wheelStartTime ~= nil then return end

        wheelStartTime = CurTime()
        wheelEndTime = wheelStartTime + wheelboy_wheel_time:GetInt()
        wheelOffset = MathRand() * 360
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

    local logoMat = Material("materials/vgui/ttt/roles/whl/logo.png")
    local function DrawLogo(x, y)
        SurfaceSetMaterial(logoMat)
        SurfaceSetDrawColor(COLOR_WHITE)
        SurfaceDrawTexturedRect(x - 25, y - 25, 50, 50)
    end

    -- Thanks to Angela from the Lonely Yogs for the algorithm!
    local function DrawCircleSegment(segmentIdx, segmentCount, anglePerSegment, pointsPerSegment, radius, blink)
        local text = wheelEffects[segmentIdx].name
        local color = colors[segmentIdx]

        -- If we're blinking, make this segment darker
        if blink then
            local h, s, l = ColorToHSL(colors[segmentIdx])
            color = HSLToColor(h, s, math.max(l - 0.125, 0.125))
        end

        -- Generate all the points on the polygon
        local polySegments = {
            { x = 0, y = 0 }
        }
        for i = 0, pointsPerSegment do
            TableInsert(
                polySegments,
                {
                    x = MathCos(i * MathRad(anglePerSegment) / pointsPerSegment),
                    y = MathSin(i * MathRad(anglePerSegment) / pointsPerSegment)
                }
            )
        end

        local polyMat = Matrix()
        local scaleDown = 0.95
        -- Rotate and move the segment to the origin before applying the scaling and moving/rotating it back
        -- This is needed so the scaling is applied against the outer edge of the segment
        polyMat:Rotate(Angle(0, anglePerSegment / 2, 0))
        polyMat:Translate(Vector(0.5, 0, 0))
        polyMat:Scale(Vector(scaleDown, scaleDown, 1))
        polyMat:Translate(Vector(-0.5, 0, 0))
        polyMat:Rotate(Angle(0, -anglePerSegment / 2, 0))

        CamPushModelMatrix(polyMat, true)
            SurfaceSetDrawColor(color.r, color.g, color.b, color.a)
            DrawNoTexture()
            SurfaceDrawPoly(polySegments)
        CamPopModelMatrix()

        -- Move out from the center slightly and rotate to re-align the text with the center of the segment
        local textRenderDisplacement = 10
        local textMat = Matrix()
        textMat:Rotate(Angle(0, anglePerSegment / 2, 0))

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

    local function DrawSegmentedCircle(x, y, radius, segmentCount, anglePerSegment, pointsPerSegment, currentAngle, blink)
        local mat = Matrix()
        mat:Translate(Vector(x, y, 0))
        mat:Rotate(Angle(0, currentAngle, 0))
        mat:Scale(Vector(radius, radius, radius))

        -- Start at 90deg offset so the start is the top instead of the right
        -- Offset by an additional 1/2 segment so the arrow points to the middle instead of the edge
        local angleOffset = 90 + (anglePerSegment / 2)
        CamPushModelMatrix(mat)
            for segmentIdx = 1, segmentCount do
                -- Rotate to the angle of this segment
                local segmentMat = Matrix()
                segmentMat:Rotate(Angle(0, ((segmentIdx - 1) * anglePerSegment) - angleOffset, 0))

                CamPushModelMatrix(segmentMat, true)
                    DrawCircleSegment(segmentIdx, segmentCount, anglePerSegment, pointsPerSegment, radius, blink and segmentIdx == lastSegment)
                CamPopModelMatrix()
            end
        CamPopModelMatrix()
    end

    AddHook("HUDPaint", "Wheelboy_Wheel_HUDPaint", function()
        if not wheelStartTime then return end

        local segmentCount = #colors
        local anglePerSegment = (360 / segmentCount)

        local curTime = CurTime()
        -- Once we've spun for the desired time, stop rotating at that point
        local baseTime = MathMin(curTime, wheelEndTime)

        -- TODO: Rotate at variable speed, decreasing over time
        local currentAngle = wheelOffset + (baseTime * 150)
        -- Loop back around to 0 after we exceed 360
        while currentAngle > 360 do
            currentAngle = currentAngle - 360
        end

        -- TODO: Get the current segment from the wheel, using "currentAngle"
        local currentSegment = 1

        -- Keep track of when the segment changes and use that to play the clicking sound
        if currentSegment ~= lastSegment then
            SurfacePlaySound("whl/click.mp3")
            lastSegment = currentSegment
        end

        local blink = false
        -- If we just finished the spin, start blinking the color to indicate which was selected
        if blinkStart == nil and curTime >= wheelEndTime then
            blinkStart = curTime
        end

        -- If we've started blinking and enough time has exceed
        if blinkStart ~= nil and curTime >= blinkStart then
            -- Stop blinking after 1/2 second, but start again in another 0.5 second
            if curTime >= blinkStart + 0.5 then
                blinkStart = curTime + 0.5
            else
                blink = true
            end
        end

        -- Draw everything
        local centerX, centerY = ScrW() / 2, ScrH() / 2
        DrawCircle(centerX, centerY, 247, 60)
        DrawSegmentedCircle(centerX, centerY, 250, segmentCount, anglePerSegment, 30, currentAngle, blink)
        DrawPointer(centerX, centerY)
        DrawLogo(centerX, centerY)

        -- Wait extra time and then clear everything and send it to the server
        if curTime >= wheelEndTime + wheelboy_wheel_end_wait_time:GetInt() then
            wheelStartTime = nil
            wheelEndTime = nil
            wheelOffset = nil
            lastSegment = nil
            blinkStart = nil

            net.Start("TTT_WheelboySpinResult")
                net.WriteUInt(currentSegment, 4)
            net.SendToServer()
        end
    end)

    --------------
    -- TUTORIAL --
    --------------

    AddHook("TTTTutorialRoleText", "Wheelboy_TTTTutorialRoleText", function(role, titleLabel)
        if role ~= ROLE_WHEELBOY then return end

        -- TODO
    end)
end