-- Internationalization
local S = nodes_nature.S

nodes_nature = nodes_nature
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
nn.tree_neighbors = {}

for name, nodedef in pairs(minetest.registered_nodes) do
    if minetest.get_item_group(name, "drops_leaves") > 0 then
        local b = string.find(name, ":")
        local without_modname = string.sub(name, b + 1, #name)
        register_leaf_marker(without_modname)
        local mark_name = "nodes_nature:"..without_modname.."_marker"
        nn.leaves_to_mark[name] = mark_name
        nn.mark_to_leaves[mark_name] = name
        table.insert(nn.tree_neighbors, name)
    end
    if minetest.get_item_group(name, "tree") > 0 then
        table.insert(nn.tree_neighbors, name)
    end
end

-- #860 Exile PR changes names for certain fruits for standardization
-- update old nodenames
minetest.register_alias_force("nodes_nature:maraka_nut_marker",
                              "nodes_nature:maraka_fruit_marker")
minetest.register_alias_force("nodes_nature:kagum_pod_marker",
                              "nodes_nature:kagum_fruit_marker")
minetest.register_alias_force("nodes_nature:amma_nut_marker",
                              "nodes_nature:amma_fruit_marker")
minetest.register_alias_force("nodes_nature:daoja_berry_marker",
                              "nodes_nature:daoja_fruit_marker")
