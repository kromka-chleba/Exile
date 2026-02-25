local function restore_sieve(pos, node)
    local now = core.get_node(pos)

    if now.name ~= node.name.."_sieve" then return end -- Broken!
    core.swap_node(pos, node)
end
function ncrafting.register_sieve(name)
    local node_def = core.registered_nodes[name]
    local def = table.copy(node_def)
    local groups = table.copy(node_def.groups)
    groups["sieve"] = 1 -- add the sieve group to the base node
    groups["timer"] = 1 -- so the ABM will restart this if it dies
    core.override_item(name, { groups = groups })

    local sieve_name = name.."_sieve"
    def.walkable = false
    def.timer = 1
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

local function check_for_sieve(pos, node)
    if core.get_item_group(node.name, "sievable") > 0 then
        local underpos = pos + vector.new(0,-1,0)
        local under = core.get_node(underpos)
        if core.get_item_group(under.name, "sieve") > 0 then
            under.name = under.name.."_sieve"

            core.swap_node(underpos, under)
            core.get_node_timer(underpos):start(1)
            return false
        end
    end
end

function ncrafting.placement_physics(pos, newnode, _placer, _old, _item, _point)
    -- Ignore salt water, because oceans, and players don't build with it
    if newnode.name == "nodes_nature:salt_water_source" then return end

    check_for_sieve(pos, newnode)
    -- #TODO: Check for weight and break sticks if over it
end

core.register_on_placenode(ncrafting.placement_physics)
