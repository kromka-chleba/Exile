-- Placement physics
-- This is called whenever a player places a node, or when a falling node stops
-- It handles nodes that should fall through others, and supports that break
--  under weight.


--------------------------------------------------------------------------
-- Sieve mechanics

-- Register a node that sieveable nodes can fall through
--
-- This will register a second no-collision version of the node which will
--  briefly appear and allow sand or whatever to pass through, before reverting
--  to its original, solid form.

function ncrafting.register_sieve(name)
    local function restore_sieve(pos, node)
        local now = core.get_node(pos)

        if now.name ~= node.name.."_sieve" then return end -- Broken!
        core.swap_node(pos, node)
    end

    local node_def = core.registered_nodes[name]
    local def = table.copy(node_def)
    local groups = table.copy(node_def.groups)
    groups["sieve"] = 1 -- add the sieve group to the base node
    core.override_item(name, { groups = groups })

    local sieve_name = name.."_sieve"
    def.walkable = false
    def.groups["timer"] = 1 -- so the ABM will restart this if it dies
    def.on_timer = function(pos, elapsed)
        core.check_for_falling(pos)
        local this = core.get_node(pos)
        this.name = name -- Change the name, but keep param data
        -- first, check to make sure no falling nodes are inside the node's space
        if #core.get_objects_inside_radius(pos, 0.5) == 0 then
            core.after(1, restore_sieve, pos, this) -- All clear, done sieving!
        else
            return true -- not clear, restart the timer and try again
        end
    end
    core.register_node(sieve_name, def)
end

local underpos, under

local function check_for_sieve(pos, node)
    if core.get_item_group(node.name, "sievable") > 0 then
        underpos = pos + vector.new(0,-1,0)
        under = core.get_node(underpos)
        if core.get_item_group(under.name, "sieve") > 0 then
            under.name = under.name.."_sieve"

            core.swap_node(underpos, under)
            core.get_node_timer(underpos):start(1)
            return false
        end
    end
end

--------------------------------------------------------------------------
-- Handling for group:weight and group:support

-- Any stack of falling nodes that exceeds this can't be sitting on a support
local highest_support_value = 0

local function calculate_highest_support_value()
    for name, def in pairs(core.registered_nodes) do
        if def.groups.support and def.groups.support > highest_support_value then
            highest_support_value = def.groups.support
        end
    end
end

core.after(1, calculate_highest_support_value)

local function add_weight(name, def, weight)
    if not def or not def.groups then return weight end -- unknown node?
    if def.groups.weight then return weight + def.weight end

    -- Fake up a default weight, 2 for regular nodes, 1 for slabs/stairs
    if string.match(name, "stairs:") then
        return weight + 1
    else
        return weight + 2
    end
end

-- This scans the nodes below for falling nodes, calculates their total weight
-- If there's a support found before we exceed max possible weight, then we check
-- whether the weight + the new node exceeds its support value, and break it

-- This assumes that nodes will always build from bottom up, as is normal for
-- falling nodes whether stacked by the player or dropped from above.
-- If nodes in the middle of a stack have their weight changed somehow, this
-- will not respond properly
local function check_for_support(pos, node)
    if not underpos and not under then -- We could have the first node cached
        underpos = pos + vector.new(0,-1,0)
        under = core.get_node(underpos)
    end
    local weight = 0
    local def
    local safety_count = 0 -- escape clause for a technically infinite loop
    local safety_max = highest_support_value * 2.5
    -- Should never be needed, but can't hurt either
    repeat
        safety_count = safety_count + 1
        def = core.registered_nodes[under.name] or { }
        if safety_count > safety_max then return end
        if under.name == "ignore" then return end -- can't be helped
        if not def.groups then return end -- unknown node, treat as falling = 0
        if weight > highest_support_value then return end -- not supportable
        if def.groups.support then break end -- support found
        if not def.groups.falling_node then return end -- no support needed


        -- still adding weights, so move down, check next
        weight = add_weight(under.name, def, weight)
        underpos = underpos + vector.new(0,-1,0)
        under = core.get_node(underpos)
    until false
    weight = add_weight(node.name, core.registered_nodes[node.name], weight)
    if def.groups.support < weight then
        core.dig_node(underpos)
    end
end

--------------------------------------------------------------------------
-- Handle the suitability of a node's attachment surface

-- Node definitions: _attach, _attach_side, _attach_top, _attach_bottom
--  Uses a table like: _attach_side = { "my:node", "group:foo", "all" }

local function check_attached_node(pos, newnode, point, old)

    if not point or point.type ~= "node" then return end

    local def = core.registered_nodes[newnode.name]
    if not ( def and def.groups and -- Check if we even handle this at all
             (def._attach or def._attach_side or
              def._attach_top or def._attach_bottom ) ) then return true end

    -- Get the node we're attaching to
    local dir = point.above - point.under
    local target = core.get_node(point.under)
    if dir.y == 1 then -- Y + 1 means we're above the target, so:
        underpos = point.under ; under = target -- cache it for later functions
    end

    local function check_attach(list)
        if list[1] == "all" then return true end
        for i = 1, #list do
            if list[i] == target.name then return true end
            if list[i]:sub(1,6) == "group:" then
                if core.get_item_group(target.name, list[i]:sub(7)) > 0 then
                    return true
                end
            end
        end
    end

    if def._attach_bottom and dir.y == 1 then
        if check_attach(def._attach_bottom) then return true end
    end
    if def._attach_side and ( dir.x ~= 0 or dir.z ~= 0 ) then
        if check_attach(def._attach_side) then return true end
    end
    if def._attach_top and dir.y == -1 then
        if check_attach(def._attach_top) then return true end
    end
    if def._attach then
        if check_attach(def._attach) then return true end
    end

    -- No matching _attach_* entry found? Play a sound and handle failure
    core.sound_play("nodes_nature_hard_footstep", { pos = pos, gain = 0.5 })
    core.set_node(pos, old) -- Swap the node back and don't take the item
    return false
end


function ncrafting.placement_physics(pos, newnode, _placer, old, item, point)
    -- Ignore salt water, because oceans, and players don't build with it
    if newnode.name == "nodes_nature:salt_water_source" then return end

    if check_attached_node(pos, newnode, point, old) == false then
        return true -- We can't place, don't take the item
    end

    if core.get_item_group(newnode.name, "falling_node") == 0 then return end

    check_for_sieve(pos, newnode)
    check_for_support(pos, newnode) -- Warning: under/underpos get moved here
    under = nil ; underpos = nil -- Clear cache for next call
end

core.register_on_placenode(ncrafting.placement_physics)
