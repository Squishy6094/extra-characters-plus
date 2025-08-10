-- Custom Geo Functions --

--- @param m MarioState
--- @return integer
--- Returns from directions between 1-8 depending on the camera angle
function mario_yaw_from_camera(m)
    local l = gLakituState
    local tau = math.pi * 2

    local vector = {X = l.pos.x - m.pos.x, Y = l.pos.y - m.pos.y,  Z = l.pos.z - m.pos.z}
    local r0 = math.rad((m.faceAngle.y * 360) / 0x10000)
    local r1 = r0 < 0 and tau - math.abs(r0) or r0
    local a0 = math.atan(vector.Z, vector.X) + math.pi * 0.5

    local a1
    --[[if pitch == 2 or pitch == -2 then
        a1 = math.rad((limit_angle(o.oFaceAngleYaw - l.yaw) * 360) / 0x10000)
    else]]
    a1 = ((a0 < 0 and tau - math.abs(a0) or a0) + r1)

    local a2 = (a1 % tau) * 8 / tau
    local angle = (math.round(a2) % 8) + 1
    --djui_chat_message_create(tostring(angle))
    return angle
end

-- Sonic Spin/Ball Acts --

local sSonicSpinBallActs = {
    [ACT_SPIN_JUMP]        = true,
    [ACT_SPIN_DASH]        = true,
    [ACT_AIR_SPIN]         = true,
    [ACT_HOMING_ATTACK]    = true,
}

local sSonicSpinDashActs = {
    [ACT_SPIN_DASH_CHARGE] = true,
}

--- @param n GraphNode | FnGraphNode
--- Switches between the spin and ball models during a spin/ball actions
function geo_ball_switch(n)
    local switch = cast_graph_node(n)
    local m = geo_get_mario_state()
    if sSonicSpinBallActs[m.action] then
        switch.selectedCase = ((m.actionTimer - 1) % 4 // 2 + 1)
    elseif sSonicSpinDashActs[m.action] then
        switch.selectedCase = 3
    else
        switch.selectedCase = 0
    end
end

-- Mouth Switch --

SONIC_MOUTH_NORMAL    = 0 --- @type SonicMouthGSCId
SONIC_MOUTH_FROWN     = 1 --- @type SonicMouthGSCId
SONIC_MOUTH_GRIMACING = 2 --- @type SonicMouthGSCId
SONIC_MOUTH_HAPPY     = 3 --- @type SonicMouthGSCId

local sGrimacingActs = {
    [ACT_HOLD_HEAVY_IDLE]    = true,
    [ACT_SHIVERING]          = true,
    [ACT_HOLD_HEAVY_WALKING] = true,
    [ACT_SHOCKED]            = true,
    [ACT_HEAVY_THROW]        = true,
}

--- @param n GraphNode | FnGraphNode
--- Switches the mouth state
function geo_switch_mario_mouth(n)
    local switch = cast_graph_node(n)
    local m = geo_get_mario_state()

    if m.marioBodyState.eyeState == MARIO_EYES_DEAD or m.action == ACT_PANTING then
        switch.selectedCase = SONIC_MOUTH_FROWN
    elseif sGrimacingActs[m.action] then
        switch.selectedCase = SONIC_MOUTH_GRIMACING
    elseif m.marioBodyState.handState == MARIO_HAND_PEACE_SIGN then
        switch.selectedCase = SONIC_MOUTH_HAPPY
    else
        switch.selectedCase = SONIC_MOUTH_NORMAL
    end
end

-- Mouth Side Switch --

SONIC_MOUTH_LEFT  = 0 --- @type SonicMouthSideGSCId
SONIC_MOUTH_RIGHT = 1 --- @type SonicMouthSideGSCId

--- @param n GraphNode | FnGraphNode
--- Switches the side that the mouth is being displayed on
function geo_switch_mario_mouth_side(n)
    local switch = cast_graph_node(n)
    local m = geo_get_mario_state()
    local angle = mario_yaw_from_camera(m)

    if angle <= 4 then
        switch.selectedCase = SONIC_MOUTH_RIGHT
    else
        switch.selectedCase = SONIC_MOUTH_LEFT
    end
end

-- Wapeach Axe Acts --

local sWapeachAxeActs = {
    [ACT_AXE_CHOP]      = true,
    [ACT_AXE_SPIN]      = true,
    [ACT_AXE_SPIN_AIR]   = true,
    [ACT_AXE_SPIN_DIZZY] = true,
}

--- @param n GraphNode | FnGraphNode
--- Switches between normal hands and axe hands during axe actions
function geo_custom_hand_switch(n)
    local switch = cast_graph_node(n)
    local m = geo_get_mario_state()
    if sWapeachAxeActs[m.action] then
        switch.selectedCase = 1
    else
        switch.selectedCase = 0
    end
end

-- Donkey Kong Angry Acts --

local sDonkeyKongAngryActs = {}

--- @param n GraphNode | FnGraphNode
--- Switches between normal head and angry head during angry actions
function geo_custom_dk_head_switch(n)
    local switch = cast_graph_node(n)
    local m = geo_get_mario_state()
    if sDonkeyKongAngryActs[m.action] then
        switch.selectedCase = 1
    else
        switch.selectedCase = 0
    end
end
