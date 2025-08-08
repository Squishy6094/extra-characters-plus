----------------------
-- Rosalina Moveset --
----------------------

if not charSelect then return end

_G.ACT_JUMP_TWIRL = allocate_mario_action(ACT_GROUP_AIRBORNE | ACT_FLAG_AIR | ACT_FLAG_ATTACKING)
E_MODEL_TWIRL_EFFECT = smlua_model_util_get_id("spin_attack_geo")

---@param o Object
local function bhv_spin_attack_init(o)
    o.oFlags = OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE -- Allows you to change the position and angle
end

---@param o Object
local function bhv_spin_attack_loop(o)
    cur_obj_set_pos_relative_to_parent(0, 20, 0)                            -- Makes it move to its parent's position

    o.oFaceAngleYaw = o.oFaceAngleYaw + 0x2000                              -- Rotates it
    local m = get_mario_state_from_object(o.parentObj)

    if m.action ~= ACT_JUMP_TWIRL then                                       -- Deletes itself once the action changes
        obj_mark_for_deletion(o)
    end
end

local id_bhvTwirlEffect = hook_behavior(nil, OBJ_LIST_GENACTOR, true, bhv_spin_attack_init, bhv_spin_attack_loop, "bhvTwirlEffect")

-- Spinable actions, these are actions you can spin out of
local spinActs = {
    [ACT_LONG_JUMP] = true,
    [ACT_BACKFLIP]  = true
}

-- Spin overridable actions, these are overriden instantly
local spinOverrides = {
    [ACT_PUNCHING]      = true,
    [ACT_MOVE_PUNCHING] = true,
    [ACT_JUMP_KICK]     = true,
    [ACT_DIVE]          = true
}

local ROSALINA_SOUND_SPIN = audio_sample_load("spin_attack.ogg") -- Load audio sample

---@param m MarioState
function act_jump_twirl(m)
    if m.actionTimer >= 15 then
        return set_mario_action(m, ACT_FREEFALL, 0) -- End the action
    end

    if m.actionTimer == 0 then
        play_character_sound(m, CHAR_SOUND_HELLO)                    -- Plays the character sound
        audio_sample_play(ROSALINA_SOUND_SPIN, m.pos, 1)             -- Plays the spin sound sample
        m.particleFlags = m.particleFlags | ACTIVE_PARTICLE_SPARKLES -- Spawns sparkle particles

        m.vel.y = 30                                                 -- Initial upward velocity
        m.marioObj.hitboxRadius = 100                                -- Damage hitbox

        -- Spawn the spin effect
        spawn_sync_object(id_bhvTwirlEffect, E_MODEL_TWIRL_EFFECT, m.pos.x, m.pos.y, m.pos.z, function(o)
            o.parentObj = m.marioObj
            o.globalPlayerIndex = m.marioObj.globalPlayerIndex
        end)
    else
        m.marioObj.hitboxRadius = 37 -- Reset the hitbox after initial hit
    end

    common_air_action_step(m, ACT_FREEFALL_LAND, CHAR_ANIM_BEND_KNESS_RIDING_SHELL, AIR_STEP_NONE)

    m.marioBodyState.handState = MARIO_HAND_PEACE_SIGN -- Hand State

    -- Increments the action timer
    m.actionTimer = m.actionTimer + 1
end

---@param m MarioState
---@param o Object
---@param intType InteractionType
function rosalina_on_interact(m, o, intType)
    local e = gCharacterStates[m.playerIndex]
    if intType == INTERACT_GRABBABLE and o.oInteractionSubtype & INT_SUBTYPE_NOT_GRABBABLE == 0 then
        e.rosalina.canGrab = true
    end
end

---@param m MarioState
function rosalina_update(m)
    local e = gCharacterStates[m.playerIndex]

    if e.rosalina.canSpin and spinActs[m.action] and m.controller.buttonPressed & B_BUTTON ~= 0 then
        e.rosalina.canSpin = false
        return set_mario_action(m, ACT_JUMP_TWIRL, 0)
    end

    if m.action & ACT_FLAG_AIR == 0 and m.playerIndex == 0 then
        e.rosalina.canSpin = true
    end

    if m.action ~= ACT_JUMP_TWIRL and m.marioObj.hitboxRadius ~= 37 then
        m.marioObj.hitboxRadius = 37
    end
end

---@param m MarioState
function rosalina_before_action(m, action)
    local e = gCharacterStates[m.playerIndex]

    if e.rosalina.canSpin and (not e.rosalina.canGrab) and spinOverrides[action] and m.input & (INPUT_Z_DOWN | INPUT_A_DOWN) == 0 then
        e.rosalina.canSpin = false
        return ACT_JUMP_TWIRL
    end

    if not action then return end -- So bitwise operations don't fail

    if action & ACT_FLAG_AIR == 0 then
        if not e.rosalina.canSpin then
            play_sound_with_freq_scale(SOUND_GENERAL_COIN_SPURT_EU, m.marioObj.header.gfx.cameraToObject, 1.6)
            if m.playerIndex == 0 then
                spawn_sync_object(id_bhvSparkle, E_MODEL_SPARKLES_ANIMATION, m.pos.x, m.pos.y + 200, m.pos.z, function(o) obj_scale(o, 0.75) end)
            end
        end
        e.rosalina.canGrab = false
        e.rosalina.canSpin = true
    end
end

hook_mario_action(ACT_JUMP_TWIRL, act_jump_twirl, INT_KICK)
