-------------------------------------------------------------
--SPREAD PLANTS
--grow "flora" on sediment in light,
--grow mushrooms on sediment in darker
-- cane growth
--spreading surfaces

nsl = naturalslopeslib

----------------------------------------------------------------
-- Flora
--


local function flora_spread(pos, node)
    pos.y = pos.y - 1
    local under = minetest.get_node(pos)
    -- prevent spreading to slopes
    local under_nodedef = minimal.get_nodedef(pos)
    local slope = under_nodedef.groups.natural_slope
    local under_name = under.name
    if slope then
        under_name = nsl.get_regular_node_name(under.name)
    end
    pos.y = pos.y + 1
    if minetest.get_item_group(under_name, "sediment") == 0 then
        return
    end
    local pos0 = vector.subtract(pos, 4)
    local pos1 = vector.add(pos, 4)
    -- Testing shows that a threshold of 3 results in an appropriate maximum
    -- density of approximately 7 flora per 9x9 area.
    if #minetest.find_nodes_in_area(pos0, pos1, "group:flora") > 3 then
        return
    end
    local plant_nodedef = minimal.get_nodedef(pos)
    local seed_name = plant_nodedef._seed_name
    local soils = minetest.find_nodes_in_area_under_air(
        pos0, pos1, "group:sediment")
    local num_soils = #soils
    if num_soils >= 1 then
        for si = 1, math.random(1, num_soils) do
            local soil = soils[math.random(num_soils)]
            local soil_name = minetest.get_node(soil).name
            local above_soil = {x = soil.x, y = soil.y + 1, z = soil.z}
            if soil_name == under_name then
                minetest.set_node(above_soil, {name = seed_name})
            end
        end
    end
end

minetest.register_lbm({
	label = "Add roots under plants",
        name = "nodes_nature:root_lbm",
	nodenames = {"group:plant_with_roots"},
        run_at_every_load = true,
        min_y = -10,
        max_y = 300,
	action = function(pos, node)
            local pos_under = {x = pos.x, y = pos.y - 1, z = pos.z}
            local plant_name = node.name
            local plant_nodedef = minetest.registered_nodes[plant_name]
            local name_under = minetest.get_node(pos_under).name
            local nodedef_under = minetest.registered_nodes[name_under]
            local timer = minetest.get_node_timer(pos)
            if timer:is_started() then
                return
            end
            if not nodedef_under.groups.sediment then
                return
            elseif not nodedef_under.groups.roots then
                minetest.set_node(pos_under, {name = name_under.."_roots"})
            end
            local meta = minetest.get_meta(pos_under)
            meta:set_string("root_name", plant_nodedef._root_name)
            local max_root_nr = plant_nodedef.groups.plant_with_roots
            meta:set_int("root_nr", math.ceil(math.random(0, max_root_nr)))
        end
})

local function undersea_flora_spread(pos, node)
   local nodedef = minetest.registered_nodes[node.name]
   local substrate = nodedef.node_dig_prediction
   local pos0 = vector.subtract(pos, 4)
   local pos1 = vector.add(pos, 4)
   -- Testing shows that a threshold of 3 results in an appropriate maximum
   -- density of approximately 7 flora per 9x9 area.
   if #minetest.find_nodes_in_area(pos0, pos1, "group:flora") > 3 then
      return
   end
   pos0 = vector.subtract(pos, {x=4,y=2,z=4})
   pos1 = vector.add(pos, {x=4,y=2,z=4})
   --find a random saltwater node
   local tgts = minetest.find_nodes_in_area(pos0, pos1,
				       "nodes_nature:salt_water_source")
   if #tgts == 0 then return end
   local tgt = tgts[math.random(1,#tgts)]
   -- seek down until we hit the seabed
   local down = vector.new(0, -1, 0)
   local under = vector.add(tgt, down)
   local uname = minetest.get_node(under).name
   while uname == "nodes_nature:salt_water_source" do
      tgt = under
      under = vector.add(tgt, down)
      uname = minetest.get_node(under).name
   end
   if uname ~= substrate then -- it's not the right soil for this plant
      return
   end
   minetest.place_node(tgt, { name = node.name })
end

---------------

minetest.register_abm({
	label = "Flora spread",
	nodenames = {"group:flora"},
	interval = 260,
	chance = 60,
	max_y = 800,
	min_y = -15,
	action = function(pos, node)
	   if minetest.get_item_group(node.name, "flora_sea") == 0 then
	      flora_spread(pos, node)
	   else
	      undersea_flora_spread(pos, node)
	   end
	end,
})


------------------------------------------------------------
-- Mushrooms
--


-- Mushroom spread
local function mushroom_spread(pos, node)
	--don't do for young
	if minetest.get_item_group(node.name, "seedling") >= 1 then
		return
	end

	pos.y = pos.y - 1
	local under = minetest.get_node(pos)
	pos.y = pos.y + 1


	if minetest.get_item_group(under.name, "sediment") == 0 then
		return
	end

	--extreme temps will kill, semi-extreme stop growth
	local temp = climate.get_point_temp(pos)
	if temp < -30 or temp > 60 then
		minetest.remove_node(pos)
	elseif temp < 0 or temp > 40 then
		return
	end

	local positions = minetest.find_nodes_in_area_under_air(
		{x = pos.x - 1, y = pos.y - 2, z = pos.z - 1},
		{x = pos.x + 1, y = pos.y + 1, z = pos.z + 1},
		{"group:sediment"})

	if #positions == 0 then
		return
	end

	local pos2 = positions[math.random(#positions)]
	pos2.y = pos2.y + 1
	if minimal.get_daylight(pos, 0.5) <= 14 and
	   minimal.get_daylight(pos2, 0.5) <= 14 then
		local plant = node.name
		local seedling_nodedef = minetest.registered_nodes[plant.."_seed"]
		if not seedling_nodedef then
			--use adult plant
			local nodedef = minetest.registered_nodes[plant]
			minetest.set_node(pos2, {name = plant, param2= nodedef.place_param2})
		else
			--use seedling
			minetest.set_node(pos2, {name = plant.."_seed"})
		end
	end
end

----------------------
minetest.register_abm({
	label = "Mushroom spread",
	nodenames = {"group:mushroom"},
	interval = 280,
	chance = 80,
	catch_up = true,
	action = function(...)
		mushroom_spread(...)
	end,
})




---------------------------------
local function grow_cane(pos, node)
	pos.y = pos.y - 1
	local under = minetest.get_node(pos)
	pos.y = pos.y + 1

	if minetest.get_item_group(under.name, "wet_sediment") ~= 1 then
		return
	end

	---extreme stop growth
	local temp = climate.get_point_temp(pos)
	if temp < 10 or temp > 40 then
		return
	end

	local plant_name = node.name

	local height = 0
	while node.name == plant_name and height < 5 do
		height = height + 1
		pos.y = pos.y + 1
		node = minetest.get_node(pos)
	end

	if height == 5 or node.name ~= "air" then
		return
	end

	if minimal.get_daylight(pos) < 13 then
		return
	end
	local nodedef = minetest.registered_nodes[plant_name]
	minetest.set_node(pos, {name = plant_name, param2= nodedef.place_param2})
	return true
end


minetest.register_abm({
	label = "Grow cane",
	nodenames = {"group:cane_plant"},
	neighbors = {"group:sediment"},
	interval = 220,
	chance = 3,
	catch_up = true,
	action = function(...)
		grow_cane(...)
	end
})



-------------------------------------------------------------
-- Spreading Surfaces
--

minetest.register_abm({
	label = "Surface spread",
	nodenames = {"group:bare_sediment"},
	neighbors = {"group:spreading"},
	interval = 161,
        min_y = 5,
	chance = 15,
	catch_up = false,
        min_y = -30,
        max_y = 500,
	action = function(pos, node)
            local pos_above = {x = pos.x, y = pos.y + 1, z = pos.z}
            local above_name = minetest.get_node(pos_above).name
            if above_name ~= "air" and minimal.get_group(pos_above, "flora") <= 0 then
                return
            end
            -- Don't spread at night
            local tod = minetest.get_timeofday()
            if tod < 0.2 or tod > 0.8 then return end
            local positions = minetest.find_nodes_in_area_under_air(
                {x = pos.x - 1, y = pos.y - 2, z = pos.z - 1},
                {x = pos.x + 1, y = pos.y + 2, z = pos.z + 1},
                {"group:spreading"})
            if #positions == 0 then
                return
            end
            local sed_nodedef = minetest.registered_nodes[node.name]
            local light_above = minimal.get_daylight(pos_above, 0.5)
            for i = 1, #positions do
                local soil_pos = positions[i]
                local soil_name = minetest.get_node(soil_pos).name
                local soil_nodedef = minetest.registered_nodes[soil_name]
                local drop = string.gsub(soil_nodedef.drop, "_wet", "")
                if drop == string.gsub(sed_nodedef.drop, "_wet", "") then
                    if light_above and light_above >= 13 then
                        local replace_with = ""
                        if minetest.get_item_group(node.name, "wet_sediment") == 1 then
                            replace_with = soil_nodedef._wet_name
                        else
                            replace_with = soil_nodedef._dry_name
                        end
                        if sed_nodedef.groups.roots then
                            replace_with = replace_with.."_roots"
                        end
                        local id = sed_nodedef.groups.natural_slope
                        if id then -- We're a slope, preserve that
                            replace_with = nsl.get_all_slopes(replace_with)[id]
                        end
                        minetest.set_node(pos, {name = replace_with, param2 = node.param2})
                        break
                    end
                end
            end
        end
})

minetest.register_abm({
	label = "Remove buried and covered grass",
	nodenames = {"group:spreading"},
	interval = 211,
	chance = 1,
	catch_up = false,
        min_y = -30,
        max_y = 500,
	action = function(pos, node)
            local pos_above = {x = pos.x, y = pos.y + 1, z = pos.z}
            local soil_nodedef = minetest.registered_nodes[node.name]
            local light_above = minimal.get_daylight(pos_above, 0.5)
            if not light_above or light_above < 10 then
                minetest.set_node(pos, {name = soil_nodedef.drop})
            end
	end
})
