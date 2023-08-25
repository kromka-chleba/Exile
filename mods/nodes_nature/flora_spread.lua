-------------------------------------------------------------
--SPREAD PLANTS
--grow "flora" on sediment in light,
--grow mushrooms on sediment in darker
-- cane growth
--spreading surfaces

local nsl = naturalslopeslib
local ms = mapchunk_shepherd
local plant = plant

----------------------------------------------------------------
-- Flora & mushrooms
--

local function flora_spread(pos, node)
    local pos_under = minimal.get_pos_under(pos)
    if minimal.get_group(pos_under, "sediment") == 0 then
        return
    end
    local under = minetest.get_node(pos_under)
    -- prevent spreading to slopes
    local under_nodedef = minimal.get_nodedef(pos_under)
    local slope = under_nodedef.groups.natural_slope
    local under_name = under.name
    if slope then
        under_name = nsl.get_regular_node_name(under.name)
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
            local above_soil = minimal.get_pos_above(soil)
            if soil_name == under_name then
                minetest.set_node(above_soil, {name = seed_name})
                ms.labels_to_position(above_soil,
                                      {"seasonal_plants"})
            end
        end
    end
end

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
	nodenames = {"group:mature_flora", "group:fruiting_plant"},
	interval = 260,
	chance = 60,
	max_y = 400,
	min_y = -2000,
	action = function(pos, node)
            -- plants and mushrooms
            flora_spread(pos, node)
	end,
})

minetest.register_abm({
	label = "Sea flora spread",
	nodenames = {"group:flora_sea"},
	interval = 260,
	chance = 60,
	max_y = 1,
	min_y = -15,
	action = function(pos, node)
            undersea_flora_spread(pos, node)
	end,
})

---------------------------------
local function grow_cane(pos, node)
    local current_pos = vector.new(pos)
    local current_node = node.name
    local kill = false

    while ((minetest.get_item_group(current_node, "sediment") == 0 and
            pos.y - current_pos.y < 9)) do
        if minetest.get_item_group(current_node, "cane_plant") ~= 1 then
            kill = true
        end
        current_pos.y = current_pos.y - 1
        current_node = minetest.get_node(current_pos).name
    end

    local wet_sediment = minetest.get_item_group(current_node, "wet_sediment")
    local sediment = minetest.get_item_group(current_node, "sediment")

    if wet_sediment == 2 or sediment <= 0 then
        -- kill if salty or not sediment
        kill = true
    elseif wet_sediment <= 0 then
        -- dry so no growing
        return
    end

    if kill then
        for i = 1, 8 do
            current_pos.y = current_pos.y + 1
            current_node = minetest.get_node(pos).name
            if minetest.get_item_group(current_node, "cane_plant") > 0 then
                plant.kill(current_pos, true)
            end
        end
        return
    end

    ---extreme stop growth
    local temp = climate.get_point_temp(pos)
    if temp < 10 or temp > 40 then
        return
    end

    local plant_name = node.name

    local height = 0
    while node.name == plant_name and height < 6 do
        height = height + 1
        pos.y = pos.y + 1
        node = minetest.get_node(pos)
    end

    if height == 6 or node.name ~= "air" then
        return
    end

    if minimal.get_daylight(pos) < 13 then
        return
    end
    local nodedef = minetest.registered_nodes[plant_name]
    minetest.set_node(pos, {name = plant_name, param2 = nodedef.place_param2})
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
                        ms.labels_to_position(pos,
                                              {"spring_soil"},
                                              {"no_spring_soil", "no_soil",
                                               "bare_soil"})
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

minetest.register_abm({
	label = "Ziarnoplon mutation",
	nodenames = {"nodes_nature:ziarnoplon_flowering",
                     "nodes_nature:srebroplon_flowering"},
	interval = 301,
	chance = 500,
	catch_up = false,
        min_y = -30,
        max_y = 500,
	action = function(pos, node)
            if node.name == "nodes_nature:ziarnoplon_flowering" then
                if math.random() > 0.99 then
                    minimal.force_place_keep_param2(pos, "nodes_nature:srebroplon_flowering")
                end
            else
                if math.random() > 0.70 then
                    minimal.force_place_keep_param2(pos, "nodes_nature:ziarnoplon_flowering")
                end
            end
	end
})

minetest.register_abm({
	label = "Root regrowth",
	nodenames = {"group:roots"},
	interval = 1600,
	chance = 3,
	catch_up = true,
	action = function(pos, node)
            local meta = minetest.get_meta(pos)
            local name = meta:get_string("root_name")
            local nr = meta:get_float("root_nr")
            local pos_above = minimal.get_pos_above(pos)
            local above_name = minetest.get_node(pos_above).name
            if above_name ~= "air" or name == "" then
                return
            end
            local temp = climate.get_point_temp(pos_above)
            local winter = seasons.is_winter()
            if temp <= 10 and winter or
                temp < 5 and not winter then
                return
            end
            if nr >= 1 then
                local seedling_name = string.gsub(name, "_root", "_seedling5")
                minetest.place_node(pos_above, {name = seedling_name})
            else
                local seedling_name = string.gsub(name, "_root", "_seedling2")
                minetest.place_node(pos_above, {name = seedling_name})
            end
	end
})
