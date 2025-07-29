-- Build_where_you_stand, disabled by default, allows you to place nodes
--  on the spot where you're standing, IE bury yourself in rock or whatever

if core.settings:get_bool("enable_build_where_you_stand") == true then
    return -- Player wants to do it, so forget all this below
end

-- But it doesn't work very well, particularly in the negative directions,
--  so you can still end up inside nodes that you've placed
-- This applies a workaround for that by pushing the player out of the node

local round = math.round
local abs = math.abs

local function set_force(dir)
    local function fixed(axis)
        local force = 1 -- can't get as far in on the positive side
        if axis < 0 then force = 4 end -- as you can on the negative

        return abs(axis) / axis * force -- set it in the selected direction
    end

    local vec = vector.new()
    if abs(dir.x) > abs(dir.y) and -- find which direction to push the player
        abs(dir.x) > abs(dir.z) then

        vec.x = fixed(dir.x)

    elseif abs(dir.y) > abs(dir.z) then
        vec.y = fixed(dir.y)

    else
        vec.z = fixed(dir.z)
    end

    return vec
end

local function check_for_build_clip(pos, _, placer)
    if not core.is_player(placer) then return end

    local ppos = placer:get_pos()
    ppos.y = ppos.y + .5 -- Player y offset

    local distance = pos:distance(ppos)
    if distance < 1 then
        local dir = pos:direction(ppos)
        placer:add_velocity(set_force(dir))
    end
end

core.register_on_placenode(check_for_build_clip)
