-------------------------
-- Donkey Kong Moveset --
-------------------------

if not charSelect then return end

--- @param m MarioState
--- Applies gravity to donkey kong
function apply_donkey_kong_gravity(m)
    if m.action == ACT_TWIRLING and m.vel.y < 0.0 then
        apply_twirl_gravity(m)
    elseif m.action == ACT_SHOT_FROM_CANNON then
        m.vel.y = math.max(-75, m.vel.y - 1.5)
    elseif m.action == ACT_LONG_JUMP or m.action == ACT_SLIDE_KICK or m.action == ACT_BBH_ENTER_SPIN then
        m.vel.y = math.max(-75, m.vel.y - 3.0)
    elseif m.action == ACT_LAVA_BOOST or m.action == ACT_FALL_AFTER_STAR_GRAB then
        m.vel.y = math.max(-65, m.vel.y - 4.8)
    elseif m.action == ACT_GETTING_BLOWN then
        m.vel.y = math.max(-75, m.vel.y - (1.5 * m.unkC4))
    elseif should_strengthen_gravity_for_jump_ascent(m) ~= 0 then
        m.vel.y = m.vel.y / 4.0
    elseif m.action & ACT_FLAG_METAL_WATER ~= 0 then
        m.vel.y = math.max(-16, m.vel.y - 2.4)
    elseif m.flags & MARIO_WING_CAP ~= 0 and m.vel.y < 0.0 and m.input & INPUT_A_DOWN ~= 0 then
        m.marioBodyState.wingFlutter = 1

        m.vel.y = m.vel.y - 3.0
        if m.vel.y < -37.5 then
            m.vel.y = math.min(-37.5, m.vel.y + 4)
        end
    else
        if m.vel.y < 0 then
            m.vel.y = math.max(-75, m.vel.y - 6)
        else
            m.vel.y = math.max(-75, m.vel.y - 4.25)
        end
    end
end

--- @param m MarioState
--- @param stepArg integer
--- @return integer
--- Performs an air step for donkey kong
function perform_donkey_kong_air_step(m, stepArg)
    local intendedPos = gVec3fZero()
    local quarterStepResult
    local stepResult = AIR_STEP_NONE

    m.wall = nil

    for i = 0, 4 do
        local step = gVec3fZero()
        step = {
            x = m.vel.x / 4.0,
            y = m.vel.y / 4.0,
            z = m.vel.z / 4.0,
        }

        intendedPos.x = m.pos.x + step.x
        intendedPos.y = m.pos.y + step.y
        intendedPos.z = m.pos.z + step.z

        vec3f_normalize(step)
        -- vec3f_copy(gFindWallDirection, step)

        gFindWallDirectionActive = true
        gFindWallDirectionAirborne = true
        quarterStepResult = perform_air_quarter_step(m, intendedPos, stepArg)
        gFindWallDirectionAirborne = false
        gFindWallDirectionActive = false

        --! On one qf, hit OOB/ceil/wall to store the 2 return value, and continue
        -- getting 0s until your last qf. Graze a wall on your last qf, and it will
        -- return the stored 2 with a sharply angled reference wall. (some gwks)

        if (quarterStepResult ~= AIR_STEP_NONE) then
            stepResult = quarterStepResult
        end

        if (quarterStepResult == AIR_STEP_LANDED or quarterStepResult == AIR_STEP_GRABBED_LEDGE
                or quarterStepResult == AIR_STEP_GRABBED_CEILING
                or quarterStepResult == AIR_STEP_HIT_LAVA_WALL) then
            break
        end
    end

    if (m.vel.y >= 0.0) then
        m.peakHeight = m.pos.y
    end

    m.terrainSoundAddend = mario_get_terrain_sound_addend(m)

    if (m.action ~= ACT_FLYING and m.action ~= ACT_BUBBLED) then
        apply_donkey_kong_gravity(m)
    end
    apply_vertical_wind(m)

    vec3f_copy(m.marioObj.header.gfx.pos, m.pos)
    vec3s_set(m.marioObj.header.gfx.angle, 0, m.faceAngle.y, 0)

    return stepResult
end

function before_donkey_kong_phys_step(m, stepType, stepArg)
    if stepType == STEP_TYPE_GROUND then
        -- return perform_donkey_kong_ground_step(m) -- TBA
    elseif stepType == STEP_TYPE_AIR then
        return perform_donkey_kong_air_step(m, stepArg)
    elseif stepType == STEP_TYPE_WATER then
        -- return perform_donkey_kong_water_step(m) -- TBA
    elseif stepType == STEP_TYPE_HANG then
        -- return perform_donkey_kong_hanging_step(m) -- TBA
    end
end
