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

local function set_force(dir, adjust)
    local function fixed(axis)
        local force = 6
        -- set it in the selected direction
        return abs(axis) / axis * force * adjust
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

local function check_for_build_clip(pos, newnode, placer)
    if not core.is_player(placer) then return end

    -- adjust effect based on what we're placing
    local adj = 1
    if core.get_item_group(newnode.name, "ladder") > 0 then adj = 0.25 end
    if newnode.name == "tech:stick" then adj = 0.25 end

    local def = core.registered_nodes[newnode.name]
    if def then
        if def.walkable == false then return end -- Ignore this one
    end

    local ppos = placer:get_pos()
    ppos.y = ppos.y + .5 -- Player y offset

    local distance = pos:distance(ppos)

    if distance < 1 then
        local dir = pos:direction(ppos)
        placer:add_velocity(set_force(dir, adj))
    end
end

core.register_on_placenode(check_for_build_clip)
