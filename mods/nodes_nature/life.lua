---------------------------------------------------------
-- Sea weeds and glowing worms

-- Internationalization
local S = nodes_nature.S

---------------------------------------
local random = math.random
local floor = math.floor
local c_alpha = minimal.compat_alpha

plant_base_growing_time = plant_base_growing_time
plant_base_timer = plant_base_timer
exile_add_food_hooks = exile_add_food_hooks
wielded_light = wielded_light

----------------------------------------------------------------------
--SEA LIFE

local function rooted_place(itemstack, placer, pointed_thing, node_name, substrate_name, height_min, height_max)
	-- Call on_rightclick if the pointed node defines it
	if pointed_thing.type == "node" and placer and
			not placer:get_player_control().sneak then
		local node_ptu = minetest.get_node(pointed_thing.under)
		local def_ptu = minetest.registered_nodes[node_ptu.name]
		if def_ptu and def_ptu.on_rightclick then
			return def_ptu.on_rightclick(pointed_thing.under, node_ptu, placer,
				itemstack, pointed_thing)
		end
	end

	local pos = pointed_thing.under
	if minetest.get_node(pos).name ~= substrate_name then
		return itemstack
	end

	local height = math.random(height_min, height_max)
	local pos_top = {x = pos.x, y = pos.y + height, z = pos.z}
	local node_top = minetest.get_node(pos_top)
	local def_top = minetest.registered_nodes[node_top.name]
	local player_name = ""
	if placer then
	   player_name = placer:get_player_name()
	end

	if def_top and def_top.liquidtype == "source" and
			minetest.get_item_group(node_top.name, "water") > 0 then
		if not minetest.is_protected(pos, player_name) and
				not minetest.is_protected(pos_top, player_name) then
			minetest.swap_node(pos, {name = node_name,
				param2 = height * 16})
			if not (minimal.player_in_creative(player_name)) then
				itemstack:take_item()
			end
		else
			minetest.chat_send_player(player_name, "Node is protected")
			minetest.record_protection_violation(pos, player_name)
		end
	end

	return itemstack
end



--Underwater Rooted plants

searooted_list = searooted_list
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
		minetest.register_node("nodes_nature:"..name, {
			description = desc,
			drawtype = "plantlike_rooted",
			waving = 1,
			tiles = {substrate_tile},
			special_tiles = {{name = "nodes_nature_"..name..".png", tileable_vertical = true}},
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

			on_place = function(itemstack, placer, pointed_thing)
				return rooted_place(itemstack, placer, pointed_thing, "nodes_nature:"..name, substrate, height_min, height_max)
			end,

			after_destruct  = function(pos, oldnode)
				minetest.swap_node(pos, {name = substrate})
			end
		})

	else
		minetest.register_node("nodes_nature:"..name, {
			description = desc,
			drawtype = "plantlike_rooted",
			waving = 1,
			tiles = {substrate_tile},
			special_tiles = {{name = "nodes_nature_"..name..".png", tileable_vertical = true}},
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

			on_place = function(itemstack, placer, pointed_thing)
				return rooted_place(itemstack, placer, pointed_thing, "nodes_nature:"..name, substrate, height_min, height_max)
			end,

			after_destruct  = function(pos, oldnode)
				minetest.swap_node(pos, {name = substrate})
			end,
		})
	end
	exile_add_food_hooks("nodes_nature:"..name)

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
        groups = {snappy = 3, flammable = 5, temp_pass = 1, bioluminescent = 1},
        sounds = nodes_nature.node_sound_leaves_defaults(),
        selection_box = {
            type = "fixed",
            fixed = {-0.3, 0.5, -0.3, 0.3, 0.35, 0.3},
            floodable = true,
            sunlight_propagates = true,
            walkable = false,
            buildable_to = true,
            groups = {snappy = 3, flammable = 5, temp_pass = 1, bioluminescent = 1},
            sounds = nodes_nature.node_sound_leaves_defaults(),
            selection_box = {
                type = "fixed",
                fixed = {-0.3, 0.5, -0.3, 0.3, 0.35, 0.3},
            },
        },
})
