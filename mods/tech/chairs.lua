--- CHAIRS ---

local mod_name = minetest.get_current_modname()

-- Internationalization
local S = tech.S
local FS = tech.FS

-- Globals
local minimal = minimal
local nn = nodes_nature

local trees = nn.trees.list


function register_stool(base_name, top_texture, side_texture)
    minetest.register_node(
        "tech:"..base_name.."_stool", {
            description = S("Stool"),
            drawtype = "mesh",
            mesh = mod_name.."_stool.glb",
            tiles = {
                {name = top_texture},
                {name = side_texture},
            },
            stack_max = minimal.stack_max_bulky,
            paramtype = "light",
            groups = {dig_immediate=3, craftedby = 1, chair = 1},
            sounds = nn.node_sound_wood_defaults(),
    })
end

for _, tree in pairs(trees) do
    local name = tree.log
    local tiles = tree.log_tiles
    local base_name = name:gsub("^.*:", "")
    register_stool(base_name, tiles[1], tiles[3])
end
