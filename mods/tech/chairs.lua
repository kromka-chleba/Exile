--- CHAIRS ---

local mod_name = core.get_current_modname()

-- Internationalization
local S = tech.S
local FS = tech.FS

-- Globals
local minimal = minimal
local nn = nodes_nature

--------------------------------------------------------------------------
-- Straw sitting mat
bed_rest.register_seat(
    "tech:sitting_mat", {
        description = S("Sitting Mat"),
        -- inventory_image = "tech_sleeping_mat.png",
        -- wield_image = "tech_sleeping_mat.png",
        stack_max = minimal.stack_max_medium/2,
        tiles = {
                "tech_thatch.png^[transformR90",
                "tech_thatch.png",
                "tech_thatch.png",
                "tech_thatch.png^[transformfx",
                "tech_thatch.png"
        },
        nodebox =      {-0.5, -0.5, -0.5, 0.5, -0.4, 0.5},
        selectionbox = {-0.5, -0.5, -0.5, 0.5, -0.4, 0.5},
        sounds =  nodes_nature.node_sound_leaves_defaults(),
        groups = {snappy = 3, dig_immediate = 3, flammable = 3, bed = 1,
                  temp_pass = 1, fall_damage_add_percent = -5},
        bed_level = 0.75,
})

--sitting_mat from cheap thatch
crafting.register_recipe({
        type = "hand",
        output = "tech:sitting_mat",
        -- slab will be used in priority
        items = {{"stairs:slab_thatch", "tech:thatch" }},
        -- if we used a full block, give back a slab
        replace = {["tech:thatch"] = "stairs:slab_thatch"},
        -- no max craft on it
        no_max = true,
        level = 1,
        always_known = true,
})

--------------------------------------------------------------------------
-- Wooden stools
local trees = nn.trees.list

local creative = 0
local function stool_registration(log_name, tile_def)
    local base_name = log_name:gsub("^.*:", "")
    local stool_name = "tech:"..base_name.."_stool"
    bed_rest.register_seat(
        stool_name, {
            description = S("Stool"),
            drawtype = "mesh",
            mesh = mod_name.."_stool.glb",
            selectionbox = {-5/16, -8/16, -5/16, 5/16, 0/16, 5/16},
            tiles = tile_def,
            paramtype2 = "none",
            stack_max = minimal.stack_max_bulky,
            groups = {dig_immediate=3, craftedby = 1, bed = 1,
                      flammable = 8, not_in_creative_inventory = creative },
            sounds = nn.node_sound_wood_defaults(),
            bed_level = 0.85,
    })
    if creative == 0 then creative = 1 end -- don't add any more than 1

crafting.register_recipe({
        type = "chopping_block",
        output = stool_name,
        -- slab will be used in priority
        items = {{ log_name }},
        -- no max craft on it
        no_max = true,
        level = 1,
        always_known = true,
})

end

for _, tree in pairs(trees) do
    stool_registration(tree.log, tree.log_tiles)
end
