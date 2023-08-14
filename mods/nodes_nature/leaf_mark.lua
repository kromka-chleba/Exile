-- Internationalization
local S = nodes_nature.S

local nn = nodes_nature

local function register_leaf_marker(name)
    minetest.register_node(
        "nodes_nature:"..name.."_marker", {
            description = S("Leaf Marker"),
            drawtype = "airlike",
            paramtype = "light",
            sunlight_propagates = true,
            walkable = false,
            pointable = false,
            diggable = false,
            buildable_to = true,
            drop = "",
            groups = {not_in_creative_inventory = 1,
                      leaf_marker = 1},
    })
end

nn.leaves_to_mark = {}
nn.mark_to_leaves = {}

for name, nodedef in pairs(minetest.registered_nodes) do
    if minetest.get_item_group(name, "drops_leaves") > 0 then
        local b = string.find(name, ":")
        local without_modname = string.sub(name, b + 1, #name)
        register_leaf_marker(without_modname)
        local mark_name = "nodes_nature:"..without_modname.."_marker"
        nn.leaves_to_mark[name] = mark_name
        nn.mark_to_leaves[mark_name] = name
    end
end
