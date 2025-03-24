
local cam = cam
local CurTime = CurTime
local draw = draw
local hook = hook
local Material = Material
local math = math
local net = net
local surface = surface
local table = table
local util = util

local AddHook = hook.Add
local CamPopModelMatrix = cam.PopModelMatrix
local CamPushModelMatrix = cam.PushModelMatrix
local DrawNoTexture = draw.NoTexture
local DrawSimpleTextOutlined = draw.SimpleTextOutlined
local FormatTime = util.SimpleTime
local MathCos = math.cos
local MathMin = math.min
local MathRad = math.rad
local MathRand = math.random
local MathSin = math.sin
local SurfaceDrawPoly = surface.DrawPoly
local SurfaceDrawText = surface.DrawText
local SurfaceDrawTexturedRect = surface.DrawTexturedRect
local SurfaceGetTextSize = surface.GetTextSize
local SurfacePlaySound = surface.PlaySound
local SurfaceSetDrawColor = surface.SetDrawColor
local SurfaceSetFont = surface.SetFont
local SurfaceSetMaterial = surface.SetMaterial
local SurfaceSetTextColor = surface.SetTextColor
local SurfaceSetTextPos = surface.SetTextPos
local TableInsert = table.insert

local hide_role = GetConVar("ttt_hide_role")

local wheel_time = GetConVar("ttt_wheelboy_wheel_time")
local wheel_recharge_time = GetConVar("ttt_wheelboy_wheel_recharge_time")
local spins_to_win = GetConVar("ttt_wheelboy_spins_to_win")
local wheel_end_wait_time = GetConVar("ttt_wheelboy_wheel_end_wait_time")
local announce_text = GetConVar("ttt_wheelboy_announce_text")
local announce_sound = GetConVar("ttt_wheelboy_announce_sound")
local swap_on_kill = GetConVar("ttt_wheelboy_swap_on_kill")

local wheel_offset_x = CreateClientConVar("ttt_wheelboy_wheel_offset_x", "0", true, false, "The screen offset from the right to render the wheel at, on the x axis (left-and-right)")
local wheel_offset_y = CreateClientConVar("ttt_wheelboy_wheel_offset_y", "0", true, false, "The screen offset from the center to render the wheel at, on the y axes (up-and-down)")
local old_wheel_design = CreateClientConVar("ttt_wheelboy_old_wheel_design", "0", true, false, "Should Wheel Boy's wheel use the old design instead of the current one")

local wheelRadius = 250

local wheelStartTime = nil
local wheelEndTime = nil
local wheelStartAngle = nil
local lastSegment = nil
local blinkStart = nil
local anglesPerSegment = nil
local function ResetWheelState()
    wheelStartTime = nil
    wheelEndTime = nil
    wheelStartAngle = nil
    lastSegment = nil
    blinkStart = nil
    anglesPerSegment = nil
end

-------------
-- CONVARS --
-------------

concommand.Add("ttt_wheelboy_wheel_offset_reset", function()
    wheel_offset_x:SetInt(wheel_offset_x:GetDefault())
    wheel_offset_y:SetInt(wheel_offset_y:GetDefault())
end)

AddHook("TTTSettingsRolesTabSections", "WheelBoy_TTTSettingsRolesTabSections", function(role, parentForm)
    if role ~= ROLE_WHEELBOY then return end

    -- Let the user move the wheel within the bounds of the window
    local height = (ScrH() / 2) - wheelRadius
    parentForm:NumSlider(LANG.GetTranslation("wheelboy_config_wheel_offset_x"), "ttt_wheelboy_wheel_offset_x", 0, ScrW() - (wheelRadius * 2), 0)
    parentForm:NumSlider(LANG.GetTranslation("wheelboy_config_wheel_offset_y"), "ttt_wheelboy_wheel_offset_y", -height, height, 0)
    parentForm:Button(LANG.GetTranslation("wheelboy_config_wheel_offset_reset"), "ttt_wheelboy_wheel_offset_reset")
    parentForm:CheckBox(LANG.GetTranslation("wheelboy_old_wheel_design"), "ttt_wheelboy_old_wheel_design")
    return true
end)

----------------
-- ROLE POPUP --
----------------

AddHook("TTTRolePopupParams", "WheelBoy_TTTRolePopupParams", function(cli)
    if cli:IsWheelBoy() then
        return { times = spins_to_win:GetInt() }
    end
end)

---------
-- HUD --
---------

AddHook("TTTHUDInfoPaint", "WheelBoy_TTTHUDInfoPaint", function(client, label_left, label_top, active_labels)
    if hide_role:GetBool() then return end
    if not client:IsActiveWheelBoy() then return end

    local curTime = CurTime()
    local nextSpinTime = client:GetNWInt("WheelBoyNextSpinTime", nil)
    local nextSpinLabel
    if nextSpinTime == nil or curTime >= nextSpinTime then
        nextSpinLabel = LANG.GetTranslation("wheelboy_spin_hud_now")
    else
        nextSpinLabel = FormatTime(nextSpinTime - curTime, "%02i:%02i")
    end

    SurfaceSetFont("TabLarge")
    SurfaceSetTextColor(255, 255, 255, 230)

    local text = LANG.GetParamTranslation("wheelboy_spin_hud", { time = nextSpinLabel })
    local _, h = SurfaceGetTextSize(text)

    -- Move this up based on how many other labels here are
    label_top = label_top + (20 * #active_labels)

    SurfaceSetTextPos(label_left, ScrH() - label_top - h)
    SurfaceDrawText(text)

    -- Track that the label was added so others can position accurately
    TableInsert(active_labels, "wheelboy")
end)

----------------
-- WIN CHECKS --
----------------

AddHook("TTTSyncWinIDs", "WheelBoy_TTTSyncWinIDs", function()
    WIN_WHEELBOY = WINS_BY_ROLE[ROLE_WHEELBOY]
end)

local wheelboyWins = false
net.Receive("TTT_UpdateWheelBoyWins", function()
    if wheelboyWins then return end

    SurfacePlaySound("whl/win.mp3")

    -- Log the win event with an offset to force it to the end
    wheelboyWins = true
    CLSCORE:AddEvent({
        id = EVENT_FINISH,
        win = WIN_WHEELBOY
    }, 1)
end)

local function ResetWheelBoyWin()
    wheelboyWins = false
    ResetWheelState()
end
net.Receive("TTT_ResetWheelBoyWins", ResetWheelBoyWin)
AddHook("TTTPrepareRound", "WheelBoy_WinTracking_TTTPrepareRound", ResetWheelBoyWin)
AddHook("TTTBeginRound", "WheelBoy_WinTracking_TTTBeginRound", ResetWheelBoyWin)

AddHook("TTTScoringSecondaryWins", "WheelBoy_TTTScoringSecondaryWins", function(wintype, secondary_wins)
    if wheelboyWins then
        TableInsert(secondary_wins, {
            rol = ROLE_WHEELBOY,
            txt = LANG.GetParamTranslation("hilite_wheelboy", { role = string.upper(ROLE_STRINGS[ROLE_WHEELBOY]) }),
            col = ROLE_COLORS[ROLE_WHEELBOY]
        })
    end
end)

------------
-- EVENTS --
------------

AddHook("TTTEventFinishText", "WheelBoy_TTTEventFinishText", function(e)
    if e.win == WIN_WHEELBOY then
        return LANG.GetParamTranslation("ev_win_wheelboy", { role = string.lower(ROLE_STRINGS[ROLE_WHEELBOY]) })
    end
end)

AddHook("TTTEventFinishIconText", "WheelBoy_TTTEventFinishIconText", function(e, win_string, role_string)
    if e.win == WIN_WHEELBOY then
        return "ev_win_icon_also", ROLE_STRINGS[ROLE_WHEELBOY]
    end
end)

-------------
-- SCORING --
-------------

-- Show who the current wheelboy killed (if anyone)
AddHook("TTTScoringSummaryRender", "WheelBoy_TTTScoringSummaryRender", function(ply, roleFileName, groupingRole, roleColor, name, startingRole, finalRole)
    if not IsPlayer(ply) then return end

    if ply:IsWheelBoy() then
        local wheelboyKilled = ply:GetNWString("WheelBoyKilled", "")
        if #wheelboyKilled > 0 then
            return roleFileName, groupingRole, roleColor, name, wheelboyKilled, LANG.GetTranslation("score_wheelboy_killed")
        end
    end
end)

------------------
-- ANNOUNCEMENT --
------------------

net.Receive("TTT_WheelBoyAnnounceSound", function()
    SurfacePlaySound("whl/announce.mp3")
end)

-----------
-- WHEEL --
-----------

surface.CreateFont("WheelBoyLabels", {
    font = "Tahoma",
    size = 16,
    weight = 1000
})

-- Start/Stop --

net.Receive("TTT_WheelBoySpinWheel", function()
    if wheelStartTime ~= nil then return end

    wheelStartTime = CurTime()
    wheelEndTime = wheelStartTime + wheel_time:GetInt()
    wheelStartAngle = MathRand() * 360
end)

net.Receive("TTT_WheelBoyStopWheel", function()
    ResetWheelState()
end)

-- Effects --

net.Receive("TTT_WheelBoyStartEffect", function()
    local client = LocalPlayer()
    if not IsPlayer(client) then return end

    local effectIdx = net.ReadUInt(4)
    if effectIdx > 0 and effectIdx <= #WHEELBOY.Effects then
        local result = WHEELBOY.Effects[effectIdx]
        if result.times == nil then
            result.times = 0
        end
        result.times = result.times + 1
        result.start(client, result)
    end
end)

net.Receive("TTT_WheelBoyFinishEffect", function()
    local effectIdx = net.ReadUInt(4)
    if effectIdx > 0 and effectIdx <= #WHEELBOY.Effects then
        WHEELBOY.Effects[effectIdx].finish()
    end
end)

-- Pointer --

local pointerOutlinePoints = {
    { x = 0, y = -237 },
    { x = -11, y = -253 },
    { x = -10, y = -257 },
    { x = -8, y = -261 },
    { x = -4, y = -263 },
    { x = 0, y = -264 },
    { x = 4, y = -263 },
    { x = 8, y = -261 },
    { x = 10, y = -257 },
    { x = 10, y = -253 }
}
local pointerPoints = {
    { x = 0, y = -238 },
    { x = -10, y = -253 },
    { x = -9, y = -257 },
    { x = -7, y = -260 },
    { x = -4, y = -262 },
    { x = 0, y = -263 },
    { x = 4, y = -262 },
    { x = 7, y = -260 },
    { x = 9, y = -257 },
    { x = 10, y = -253 }
}
local oldPointerOutlinePoints = {
    { x = 0, y = -237 },
    { x = -16, y = -247 },
    { x = -16, y = -264 },
    { x = 16, y = -264 },
    { x = 16, y = -247 }
}
local oldPointerPoints = {
    { x = 0, y = -238 },
    { x = -15, y = -248 },
    { x = -15, y = -263 },
    { x = 15, y = -263 },
    { x = 15, y = -248 }
}
local function DrawPointer(x, y)
    -- Draw the same shape but slightly larger and black
    local outlineSegments = {}
    for _, point in ipairs(old_wheel_design:GetBool() and oldPointerOutlinePoints or pointerOutlinePoints) do
        TableInsert(outlineSegments, { x = point.x + x, y = point.y + y })
    end

    SurfaceSetDrawColor(0, 0, 0, 255)
    DrawNoTexture()
    SurfaceDrawPoly(outlineSegments)

    -- Draw the pointer itself
    local pointerSegments = {}
    for _, point in ipairs(old_wheel_design:GetBool() and oldPointerPoints or pointerPoints) do
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
    Color(87, 58, 138, 255),
    Color(64, 143, 210, 255),
    Color(39, 179, 255, 255),
    Color(50, 163, 28, 255),
    Color(214, 184, 0, 255),
    Color(248, 90, 3, 255),
    Color(254, 61, 113, 255),
    Color(87, 58, 138, 255),
    Color(64, 143, 210, 255),
    Color(39, 179, 255, 255),
    Color(50, 163, 28, 255),
    Color(214, 184, 0, 255),
    Color(248, 90, 3, 255),
    Color(254, 61, 113, 255)
}

local old_colors = {
    Color(76, 170, 231, 255),
    Color(209, 98, 175, 255),
    Color(249, 67, 46, 255),
    Color(239, 224, 99, 255),
    Color(55, 24, 102, 255),
    Color(21, 106, 46, 255),
    Color(249, 67, 46, 255),
    Color(76, 170, 231, 255),
    Color(209, 98, 175, 255),
    Color(249, 67, 46, 255),
    Color(239, 224, 99, 255),
    Color(55, 24, 102, 255),
    Color(21, 106, 46, 255),
    Color(249, 67, 46, 255)
}

local logoMat = Material("materials/vgui/ttt/roles/whl/logo.png")
local oldLogoMat = Material("materials/vgui/ttt/roles/whl/old_logo.png")
local function DrawLogo(x, y)
    if old_wheel_design:GetBool() then
        SurfaceSetMaterial(oldLogoMat)
    else
        SurfaceSetMaterial(logoMat)
    end
    SurfaceSetDrawColor(COLOR_WHITE)
    SurfaceDrawTexturedRect(x - 25, y - 25, 50, 50)
end

-- Thanks to Angela from the Lonely Yogs for the algorithm!
local function DrawCircleSegment(segmentIdx, segmentCount, anglePerSegment, pointsPerSegment, radius, blink)
    local text = WHEELBOY.Effects[segmentIdx].name
    local color = colors[segmentIdx]
    if old_wheel_design:GetBool() then
        color = old_colors[segmentIdx]
    end

    -- If we're blinking, make this segment darker
    if blink then
        local h, s, l = ColorToHSL(color)
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
        DrawSimpleTextOutlined(text, "WheelBoyLabels", 0, textRenderDisplacement, COLOR_WHITE, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, 1, COLOR_BLACK)
    CamPopModelMatrix()
end

local function DrawSegmentedCircle(x, y, radius, segmentCount, anglePerSegment, pointsPerSegment, currentAngle, angleOffset, blink)
    local mat = Matrix()
    mat:Translate(Vector(x, y, 0))
    mat:Rotate(Angle(0, currentAngle, 0))
    mat:Scale(Vector(radius, radius, radius))

    CamPushModelMatrix(mat)
        for segmentIdx = 1, segmentCount do
            -- Rotate to the angle of this segment
            local segmentMat = Matrix()
            local segmentAng = ((segmentIdx - 1) * anglePerSegment) + angleOffset
            segmentMat:Rotate(Angle(0, -segmentAng, 0))

            CamPushModelMatrix(segmentMat, true)
                DrawCircleSegment(segmentIdx, segmentCount, anglePerSegment, pointsPerSegment, radius, blink and segmentIdx == lastSegment)
            CamPopModelMatrix()
        end
    CamPopModelMatrix()
end

local function ReduceAngle(ang)
    while ang < 0 do
        ang = ang + 360
    end
    while ang > 360 do
        ang = ang - 360
    end
    return ang
end

AddHook("HUDPaint", "WheelBoy_Wheel_HUDPaint", function()
    if not wheelStartTime then return end

    local segmentCount = #colors
    local anglePerSegment = (360 / segmentCount)

    -- Start at 90deg offset so the start is the top instead of the right
    -- Offset by an additional 1/2 segment so the arrow points to the middle instead of the edge
    local angleOffset = 90 + (anglePerSegment / 2)

    -- Precalculate the angle ranges for each segment, used to determine the current segment later
    if anglesPerSegment == nil then
        anglesPerSegment = {}
        local halfAngle = anglePerSegment / 2
        for segmentIdx = 1, segmentCount do
            anglesPerSegment[segmentIdx] = {
                min = halfAngle * ((2 * (segmentIdx - 1)) - 1),
                max = halfAngle * ((2 * (segmentIdx - 1)) + 1)
            }
        end
    end

    local curTime = CurTime()
    -- Once we've spun for the desired time, stop rotating at that point
    local baseTime = MathMin(curTime, wheelEndTime)
    local totalTime = wheelEndTime - wheelStartTime
    local timeElapsed = baseTime - wheelStartTime
    -- Rotate at variable speed, decreasing over time
    local anglePerSecond = 250 * (1 - (timeElapsed / (2 * totalTime)))
    -- Loop back around to 0 after we exceed 360
    local currentAngle = ReduceAngle(wheelStartAngle + (anglePerSecond * timeElapsed))

    -- Get the current segment from the wheel, using the current angle
    -- Adjust by the angle offset so our 0 points to index 1
    local adjustedAngle = ReduceAngle(currentAngle + angleOffset)
    local currentSegment
    for segmentIdx, angles in pairs(anglesPerSegment) do
        -- For some reason the segment indexes were offset by 4
        -- I don't really understand why, but subtracting 4 from the found index produced the expected result, so here we are
        if adjustedAngle >= angles.min and adjustedAngle < angles.max then
            currentSegment = segmentIdx - 4
            break
        end

        -- Handle case of a negative minimum value
        if angles.min < 0 and
            -- Between the normalized minimum and the maximum degree of a circle. Handles [-12.6->347.4, 360)
            ((adjustedAngle >= (angles.min + 360) and adjustedAngle < 360) or
            -- Between 0 and the maximum. Handles [0, max)
                (adjustedAngle >= 0 and adjustedAngle < angles.max)) then
            currentSegment = segmentIdx - 4
            break
        end
    end

    -- Roll this over if we exceed the max
    if currentSegment <= 0 then
        currentSegment = currentSegment + segmentCount
    end

    -- Keep track of when the segment changes and use that to play the clicking sound
    if currentSegment ~= lastSegment then
        if lastSegment ~= nil then
            SurfacePlaySound("whl/click.mp3")
        end
        lastSegment = currentSegment
    end

    local waitTime = wheel_end_wait_time:GetInt()
    local blink = false
    -- If we just finished the spin, start blinking the color to indicate which was selected
    if blinkStart == nil and curTime >= wheelEndTime then
        -- Display message telling wheelboy what was chosen if there is a delay before it takes effect
        if waitTime > 0 then
            LocalPlayer():QueueMessage(MSG_PRINTBOTH, "The wheel has landed on '" .. WHEELBOY.Effects[currentSegment].name .. "'! It will take effect in " .. waitTime .. " second(s)")
        end
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
    local x = ScrW() - wheelRadius - wheel_offset_x:GetInt()
    local y = (ScrH() / 2) - wheel_offset_y:GetInt()
    DrawCircle(x, y, 247, 60)
    DrawSegmentedCircle(x, y, wheelRadius, segmentCount, anglePerSegment, 30, currentAngle, angleOffset, blink)
    DrawPointer(x, y)
    DrawLogo(x, y)

    -- Wait extra time and then clear everything and send it to the server
    if curTime >= wheelEndTime + waitTime then
        ResetWheelState()

        net.Start("TTT_WheelBoySpinResult")
            net.WriteUInt(currentSegment, 4)
        net.SendToServer()
    end
end)

--------------
-- TUTORIAL --
--------------

AddHook("TTTTutorialRoleText", "WheelBoy_TTTTutorialRoleText", function(role, titleLabel)
    if role ~= ROLE_WHEELBOY then return end

    local roleColor = ROLE_COLORS[ROLE_WHEELBOY]
    local traitorColor = ROLE_COLORS[ROLE_TRAITOR]
    local html = ROLE_STRINGS[ROLE_WHEELBOY] .. " is a <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>jester</span> role who can spin their wheel to apply a random effect to everyone."

    html = html .. "<span style='display: block; margin-top: 10px;'>Some of the effects are <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>beneficial</span>, while others are <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>annoying</span>.</span>"
    html = html .. "<span style='display: block; margin-top: 10px;'>The wheel can be spun <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>every " .. wheel_recharge_time:GetInt() .. " second(s)</span>.</span>"
    html = html .. "<span style='display: block; margin-top: 10px;'>" .. ROLE_STRINGS[ROLE_WHEELBOY] .. " wins by <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>spinning their wheel " .. spins_to_win:GetInt() .. " time(s)</span> before the end of the round.</span>"

    local announceText = announce_text:GetBool()
    local announceSound = announce_sound:GetBool()
    if announceText or announceSound then
        html = html .. "<span style='display: block; margin-top: 10px;'>The presence of " .. ROLE_STRINGS[ROLE_WHEELBOY] .. " is <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>announced</span> to everyone via "
        if announceText then
            html = html .. "on-screen text"
            if announceSound then
                    html = html .. " and "
            end
        end
        if announceSound then
            html = html .. "a sound clip"
        end
        html = html .. "!</span>"
    end

    if swap_on_kill:GetBool() then
        html = html .. "<span style='display: block; margin-top: 10px;'>If " .. ROLE_STRINGS[ROLE_WHEELBOY] .. " <span style='color: rgb(" .. traitorColor.r .. ", " .. traitorColor.g .. ", " .. traitorColor.b .. ")'>is killed</span> before they win, their killer will <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>become the new " .. ROLE_STRINGS[ROLE_WHEELBOY] .. "</span>!</span>"
    end

    return html
end)