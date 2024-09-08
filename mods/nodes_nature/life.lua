---------------------------------------------------------
-- Sea weeds and glowing worms

-- Internationalization
local S = nodes_nature.S

---------------------------------------

nodes_nature = nodes_nature
local nn = nodes_nature

local add_food_hooks = HEALTH.add_food_hooks
wielded_light = wielded_light

----------------------------------------------------------------------
--SEA LIFE

local function rooted_place(itemstack, placer, pointed_thing, node_name,
                            substrate_name, height_min, height_max)
    -- Call on_rightclick if the pointed node defines it
    if ( pointed_thing.type == "node" and minetest.is_player(placer)
         and not placer:get_player_control().sneak ) then
        local on_click = minimal.on_rightclick(itemstack, placer, pointed_thing)
        if on_click ~= false then
            return on_click
        end
    end

    local pos = pointed_thing.under
    if minetest.get_node(pos).name ~= substrate_name then
        return itemstack
    end

    local height = math.random(height_min, height_max)
    local pos_top = {x = pos.x, y = pos.y + height, z = pos.z}
    local def_top = minimal.get_nodedef(pos_top)
    local player_name = ""
    if minetest.is_player(placer) then
        player_name = placer:get_player_name()
    end

    if (def_top and def_top.liquidtype == "source" and
        minimal.is_group(def_top.name, "water") ) then
        if not minetest.is_protected(pos, player_name) and
            not minetest.is_protected(pos_top, player_name) then
            minetest.swap_node(pos, {name = node_name,
                                     param2 = height * 16})
            if not (minimal.player_in_creative(player_name)) then
                itemstack:take_item()
            end
        else
            minetest.chat_send_player(player_name, S("Node is protected"))
            minetest.record_protection_violation(pos, player_name)
        end
    end

    return itemstack
end



--Underwater Rooted plants

local searooted_list = nn.searooted_list
for i in ipairs(searooted_list) do
    local name = searooted_list[i][1]
    local desc = searooted_list[i][2]
    local selbox = searooted_list[i][3]
    local type = searooted_list[i][4]
    local substrate = searooted_list[i][5]
    local substrate_tile = searooted_list[i][6]
    local sound_table = searooted_list[i][7]
    local height_min = searooted_list[i][8]
    local height_max = searooted_list[i][9]
    local pillar = searooted_list[i][10]
    local dyecandidate = searooted_list[i][11]
    local dominantcolor = searooted_list[i][12] or "green"

    local g = {snappy = 3, flora = 1, flora_sea = 1}
    --use seaweed as fertilizer
    if type == "seaweed" then
        g.fertilizer = 1
    end

    if dyecandidate then
        g.ncrafting_dye_candidate = dyecandidate
    else
        g.ncrafting_dye_candidate = 1
    end

    if pillar then
        minetest.register_node(
            "nodes_nature:"..name, {
                description = desc,
                drawtype = "plantlike_rooted",
                waving = 1,
                tiles = {substrate_tile},
                special_tiles = {{name = "nodes_nature_"..
                                      name..".png",
                                  tileable_vertical = true}},
                inventory_image = "nodes_nature_"..name..".png",
                paramtype = "light",
                paramtype2 = "leveled",
                groups = g,
                selection_box = {
                    type = "fixed",
                    fixed = {
                        {-0.5, -0.5, -0.5, 0.5, 0.5, 0.5},
                        selbox,
                    },
                },
                stack_max = minimal.stack_max_medium,
                node_dig_prediction = substrate,
                node_placement_prediction = "",
                sounds = sound_table,
                _ncrafting_dye_dcolor = dominantcolor,

                on_place = function(itemstack, placer,
                                    pointed_thing)
                    return rooted_place(itemstack, placer,
                                        pointed_thing,
                                        "nodes_nature:"..name,
                                        substrate, height_min,
                                        height_max)
                end,

                after_destruct  = function(pos, oldnode)
                    minetest.swap_node(pos, {name = substrate})
                end
        })

    else
        minetest.register_node(
            "nodes_nature:"..name, {
                description = desc,
                drawtype = "plantlike_rooted",
                waving = 1,
                tiles = {substrate_tile},
                special_tiles = {{name = "nodes_nature_"..
                                      name..".png",
                                  tileable_vertical = true}},
                inventory_image = "nodes_nature_"..name..".png",
                paramtype = "light",
                groups = g,
                selection_box = {
                    type = "fixed",
                    fixed = {
                        {-0.5, -0.5, -0.5, 0.5, 0.5, 0.5},
                        selbox,
                    },
                },
                stack_max = minimal.stack_max_medium,
                node_dig_prediction = substrate,
                node_placement_prediction = "",
                sounds = sound_table,
                _ncrafting_dye_dcolor = dominantcolor,

                on_place = function(itemstack, placer,
                                    pointed_thing)
                    return rooted_place(itemstack, placer,
                                        pointed_thing,
                                        "nodes_nature:"..name,
                                        substrate, height_min,
                                        height_max)
                end,

                after_destruct  = function(pos, oldnode)
                    minetest.swap_node(pos, {name = substrate})
                end,
        })
    end
    add_food_hooks("nodes_nature:"..name)

end

--a bit experimental, doesn't reproduce
minetest.register_node(
    "nodes_nature:glow_worm", {
        description = S("Glow Worm"),
        drawtype = "plantlike",
        waving = 1,
        visual_scale = 1,
        light_source = 2,
        tiles = {"nodes_nature_glow_worm.png"},
        stack_max = minimal.stack_max_medium,
        inventory_image = "nodes_nature_glow_worm.png",
        wield_image = "nodes_nature_glow_worm.png",
        paramtype = "light",
        paramtype2 = "meshoptions",
        place_param2 = 3,
        floodable = true,
        sunlight_propagates = true,
        walkable = false,
        buildable_to = true,
        groups = {snappy = 3, flammable = 5,
                  temp_pass = 1, bioluminescent = 1},
        sounds = nodes_nature.node_sound_leaves_defaults(),
        selection_box = {
            type = "fixed",
            fixed = {-0.3, 0.5, -0.3, 0.3, 0.35, 0.3},
            floodable = true,
            sunlight_propagates = true,
            walkable = false,
            buildable_to = true,
            groups = {snappy = 3, flammable = 5,
                      temp_pass = 1, bioluminescent = 1},
            sounds = nodes_nature.node_sound_leaves_defaults(),
            selection_box = {
                type = "fixed",
                fixed = {-0.3, 0.5, -0.3, 0.3, 0.35, 0.3},
            },
        },
})
