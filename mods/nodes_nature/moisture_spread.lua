-------------------------------------------------------------
--MOISTURE SPREAD
--move wettness through sediment
--other water effects

local nodes_nature = nodes_nature
local rt = nodes_nature.replacement_types
local ms = mapchunk_shepherd
local seasons = seasons

----------------------------------------------------------------
--freeze water
local function water_freeze(pos, node)
	local n_name = node.name

	if climate.can_freeze(pos) then

		local water_type = minetest.get_item_group(n_name, "water")
		if water_type == 1 then
		   minetest.set_node(pos, {name = "nodes_nature:ice"})
		elseif water_type == 2 then
		   minetest.set_node(pos, {name = "nodes_nature:sea_ice"})
		end

	end
end

----------------------------------------------------------------
--evaporate water
local function water_evap(pos, node)

	--evaporation
	if climate.can_evaporate(pos) then
		--lose it's own water to the atmosphere
		minetest.remove_node(pos)
		return
	end

end

--------------------------
--move sources down, otherwise erosion leaves them stranded
local function fall_water(pos,node)

	local pos_under = {x = pos.x, y = pos.y - 1, z = pos.z}
	local under_name = minetest.get_node(pos_under).name

	if under_name == "nodes_nature:freshwater_flowing" or under_name == "nodes_nature:salt_water_flowing" then
		minetest.remove_node(pos)
		minetest.set_node(pos_under, {name = node.name})
		return pos
	end

	--Fresh water should not float on top of the ocean
	if ( under_name == "nodes_nature:salt_water_source" and
	     node.name == "nodes_nature:freshwater_source" ) then
	   minetest.remove_node(pos)
	   return nil
	end
	return pos
end

local function water_handler(pos, node)
   pos = fall_water(pos, node)
   if pos == nil then
      return -- the water is not there anymore
   end
   if climate.active_temp < 2 then
      water_freeze(pos, node)
   else
      water_evap(pos, node)
   end
end

--
minetest.register_abm({
	label = "Water Source Handling",
	nodenames = {"nodes_nature:freshwater_source", "nodes_nature:salt_water_source"},
	interval = 120,
	chance = 10,
	action = function(...)
		water_handler(...)
	end
})


----------------------------------------------------------------
--Thaw snow and ice

local function thaw_frozen(pos, node)
   --position gets overwritten by climate function otherwise,
   --not clear why
   local p = pos
   if climate.can_thaw(p) then

      local name = node.name
      if name == "nodes_nature:snow_block" then
	 minetest.set_node(p, {name = "nodes_nature:freshwater_source"})
      elseif name == "nodes_nature:snow" then
	 minetest.remove_node(p)
      elseif name == "nodes_nature:ice" then
	 local under = minetest.get_node({x = p.x, y = p.y-1, z =p.z})
	 if under.name == "nodes_nature:salt_water_source" then
	    minetest.remove_node(p)
	 else
	    minetest.set_node(p, {name = "nodes_nature:freshwater_source"})
	 end
      elseif name == "nodes_nature:sea_ice" then
	 minetest.set_node(p, {name = "nodes_nature:salt_water_source"})
	 return
      end
      minetest.check_for_falling(p)
      return
   end
end


minetest.register_abm({
	label = "Thaw Ice and snow",
	nodenames = {"nodes_nature:ice", "nodes_nature:snow_block", "nodes_nature:snow", "nodes_nature:sea_ice"},
	interval = 103,
	chance = 5,
	action = function(...)
		thaw_frozen(...)
	end
})



------------------------------------------------------------------
--
local function snow_accumulate(pos, node)
	if pos.y < -15 then
		return
	end

	--
	local posu = {x = pos.x, y = pos.y - 1, z = pos.z}
	local under_name = minetest.get_node(posu).name

	if under_name == "air" then
		return
	end

	--is snowing
	if not climate.get_snow(pos) then
		return
	end

	local nodedef = minetest.registered_nodes[under_name]
	if not nodedef then
		return
	end

	--walkable under i.e. not on water etc
	local walk = nodedef.walkable
	if not walk then
		return
	end

	--pile up snow
	if under_name == "nodes_nature:snow" then
		minetest.swap_node(posu, {name = "nodes_nature:snow_block"})
		return
	end

	--not on stairs, meshes etc
	local draw = nodedef.drawtype
	if draw ~= 'normal' then
		return
	end

	--thin snow
	minetest.set_node(pos, {name = "nodes_nature:snow"})

end


--
minetest.register_abm({
	label = "snow accumulate",
	nodenames = {"air", "nodes_nature:snow"},
	neighbors = {"group:crumbly","group:cracky", "group:snappy"},
	interval = 72,
	chance = 770,
	min_y = -15,
	action = function(...)
		snow_accumulate(...)
	end
})





--puddle detect
--check for sides that can hold water
--intended to be call for an air node with solid below
--i.e. somewhere to put a puddle
local function puddle_detect(pos)
	local sides = {
		{x = pos.x + 1, y = pos.y, z = pos.z},
		{x = pos.x - 1, y = pos.y, z = pos.z},
		{x = pos.x, y = pos.y, z = pos.z + 1},
		{x = pos.x, y = pos.y, z = pos.z - 1}
	}
	local puddle = true
	for i, v in ipairs(sides) do
		local s_name = minetest.get_node(v).name
		if minetest.get_item_group(s_name, "wet_sediment") == 0
		and minetest.get_item_group(s_name, "soft_stone") == 0
		and minetest.get_item_group(s_name, "masonry") == 0
		and minetest.get_item_group(s_name, "stone") == 0  then
			puddle = false
			break
		end
	end
	if puddle then
		return true
	else
		return false
	end
end

----------------------------------------------------------------
-- Wet nodes: move water down into dry sediment
--drain if exposed side or under
--evaporate at surface in hot sun

local function moisture_spread(pos, node)


	local nodename = node.name

	--dry version
	local nodedef = minetest.registered_nodes[nodename]
	local water_type = minetest.get_item_group(nodename, "wet_sediment")
        --1= fresh or 2 = salty
        
	if not nodedef or not water_type then
		return
	end

	--move through the soil, with a bias downwards
	local pos_sed = minetest.find_nodes_in_area(
		{x = pos.x - 1, y = pos.y - 1, z = pos.z - 1},
		{x = pos.x + 1, y = pos.y, z = pos.z + 1},
		{"group:sediment"})

	if #pos_sed > 0 then
		--select a random one
		local pos2 = pos_sed[math.random(#pos_sed)]
		--is it dry?
		local name2 = minetest.get_node(pos2).name
		if minetest.get_item_group(name2, "wet_sediment") == 0 then
			--lose it's own water, and move it
			tgcr.make_replacement(pos, rt.REPLACEMENT_DRY)
			--set wet version of what draining into
			local nodedef2 = minetest.registered_nodes[name2]
			if not nodedef2 then
				return
			end
			if water_type == 1 then
				tgcr.make_replacement(pos2, rt.REPLACEMENT_WET)
			else
				tgcr.make_replacement(pos2, rt.REPLACEMENT_SALTY)
			end
			return
		end
	end

	--leach out
	--move out of the soil, only downwards
	local pos_air = minetest.find_nodes_in_area(
		{x = pos.x - 1, y = pos.y - 1, z = pos.z - 1},
		{x = pos.x + 1, y = pos.y - 1, z = pos.z + 1},
		{"air"})

	if #pos_air > 0 then
		--select a random one
		local pos2 = pos_air[math.random(#pos_air)]
		--lose it's own water, and move it
		tgcr.make_replacement(pos, rt.REPLACEMENT_DRY)
		--source or flowing?
		if puddle_detect(pos2) then
			if water_type == 1 then
				minetest.set_node(pos2, {name = "nodes_nature:freshwater_source"})
			else
				minetest.set_node(pos2, {name = "nodes_nature:salt_water_source"})
			end
		else
			if water_type == 1 then
				minetest.set_node(pos2, {name = "nodes_nature:freshwater_flowing"})
			else
				minetest.set_node(pos2, {name = "nodes_nature:salt_water_flowing"})
			end
		end
		return
	end




end



minetest.register_abm({
	label = "Moisture Spread",
	nodenames = {"group:wet_sediment"},
	--neighbors = {"group:sediment"},
	interval = 121,
	chance = 15,
	action = moisture_spread
})


----------------------------------------------------------------
-- Water soaks into sediment
local function water_soak(pos, node)

	local nodename = node.name

	--move into the soil, with a bais downwards
	local pos_sed = minetest.find_nodes_in_area(
		{x = pos.x - 1, y = pos.y - 1, z = pos.z - 1},
		{x = pos.x + 1, y = pos.y, z = pos.z + 1},
		{"group:sediment"})

	if #pos_sed > 0 then
		--select a random one
		local pos2 = pos_sed[math.random(#pos_sed)]
		--is it dry?
		local name2 = minetest.get_node(pos2).name
		if minetest.get_item_group(name2, "wet_sediment") == 0 then
			--
			if nodename == "nodes_nature:freshwater_source" then
				--non-renew
				minetest.swap_node(pos, {name = "air"})
				--set wet version of what draining into
				local nodedef2 = minetest.registered_nodes[name2]
				if not nodedef2 then
					return
				end
				tgcr.make_replacement(pos2, rt.REPLACEMENT_WET)
				return
			else
				--set salty wet version of what draining into
				local nodedef2 = minetest.registered_nodes[name2]
				if not nodedef2 then
					return
				end
				tgcr.make_replacement(pos2, rt.REPLACEMENT_SALTY)
				return
			end
		end
	end

end

--
--
minetest.register_abm({
	label = "Water Soak",
	nodenames = {"nodes_nature:freshwater_source", "nodes_nature:salt_water_source"},
	neighbors = {"group:sediment"},
	interval = 147,
	chance = 100,
	action = function(...)
		water_soak(...)
	end
})



----------------------------------------------------------------
-- flowing Water erode
--will rearrange sediments until out of the path of flow..
--and cannot shift them anywhere else
--eventually getting a stable "river" bed shape if it can
local function water_erode(pos, node)
	--take the sediment under it and move it to the side
	local pos_under = {x = pos.x, y = pos.y - 1, z = pos.z}
	local under_name = minetest.get_node(pos_under).name
	if minetest.get_item_group(under_name, "sediment") > 0 then

		--move it to another part of water, so long as it is grounded
		local pos_flow = minetest.find_nodes_in_area(
			{x = pos.x - 1, y = pos.y - 1, z = pos.z - 1},
			{x = pos.x + 1, y = pos.y - 1, z = pos.z + 1},
			{"nodes_nature:freshwater_flowing", "nodes_nature:salt_water_flowing" })

		if #pos_flow > 0 then
			--select a random one
			local pos2 = pos_flow[math.random(#pos_flow)]
			--check under
			local pos_uf = {x = pos2.x, y = pos2.y - 1, z = pos2.z}
			local uf_name = minetest.get_node(pos_uf).name

			local nodedefu = minetest.registered_nodes[uf_name]
			if not nodedefu then
				return
			end

			if nodedefu.walkable then

				--shift the sediment and put the water in its place
				minetest.remove_node(pos)
				minetest.set_node(pos_under, {name = node.name})
				--set dropped
				local nodedef = minetest.registered_nodes[under_name]
				if not nodedef then
					return
				end
				minetest.set_node(pos2, {name = nodedef.drop})
			end
		end

	elseif minetest.get_item_group(under_name, "water") > 0 or under_name == "air" then
		--it is a water fall
		--take sediment from beside and move under to fill gap
		--move it to another part of water, so long as it is grounded
		local pos_flow = minetest.find_nodes_in_area(
			{x = pos.x - 1, y = pos.y, z = pos.z - 1},
			{x = pos.x + 1, y = pos.y, z = pos.z + 1},
			{"group:sediment"})

		if #pos_flow > 0 then
			--select a random one
			local pos2 = pos_flow[math.random(#pos_flow)]

			--check under is solid
			local pos_uf = {x = pos_under.x, y = pos_under.y - 1, z = pos_under.z}
			local uf_name = minetest.get_node(pos_uf).name

			local nodedefu = minetest.registered_nodes[uf_name]
			if not nodedefu then
				return
			end

			if nodedefu.walkable then
				--take it and drop it underneath
				--set dropped
				local side_name = minetest.get_node(pos2).name
				local nodedef = minetest.registered_nodes[side_name]
				if not nodedef then
					return
				end
				minetest.remove_node(pos2)
				minetest.set_node(pos_under, {name = nodedef.drop})
			end
		end

	end
end


--
--
minetest.register_abm({
	label = "Water Erode",
	nodenames = {"nodes_nature:freshwater_flowing", "nodes_nature:salt_water_flowing"},
	neighbors = {"group:sediment"},
	interval = 120,
	chance = 30,
	action = function(...)
		water_erode(...)
	end
})

-----------------------------------
-- Rain soak

ms.labels.register("last_rain")
ms.labels.register("last_evaporated")

local function get_dry_wet_pairs()
    local soil_pairs = {}
    for name, nodedef in pairs(minetest.registered_nodes) do
        if minetest.get_item_group(name, "dry_sediment") > 0 then
            soil_pairs[name] = nodedef._wet_name or name
        end
    end
    return soil_pairs
end

local dry_to_wet = get_dry_wet_pairs()

local function get_wet_dry_pairs()
    local soil_pairs = {}
    for name, nodedef in pairs(minetest.registered_nodes) do
        if minetest.get_item_group(name, "wet_sediment") > 0 then
            soil_pairs[name] = nodedef._dry_name or name
        end
    end
    return soil_pairs
end

local wet_to_dry = get_wet_dry_pairs()

minetest.log("error", dump(wet_to_dry))

local light_rain_replacer =
    ms.create_light_aware_replacer(
        {find_replace_pairs = dry_to_wet,
         add_labels = {"last_rain"},
         chance = 1/50,
         higher_than = 14,
        }
    )

local heavy_rain_replacer =
    ms.create_light_aware_replacer(
        {find_replace_pairs = dry_to_wet,
         add_labels = {"last_rain"},
         chance = 1/15,
         higher_than = 14,
        }
    )

local thunderstorm_replacer =
    ms.create_light_aware_replacer(
        {find_replace_pairs = dry_to_wet,
         add_labels = {"last_rain"},
         chance = 1/8,
         higher_than = 14,
        }
    )

local light_evaporator =
    ms.create_light_aware_replacer(
        {find_replace_pairs = wet_to_dry,
         add_labels = {"last_evaporated"},
         chance = 1/15,
         higher_than = 10,
        }
    )

-- The Evaporator - destroyer of worlds, the sovereign of drought and thirst
local the_evaporator =
    ms.create_light_aware_replacer(
        {find_replace_pairs = wet_to_dry,
         add_labels = {"last_evaporated"},
         chance = 1/2,
         higher_than = 10,
        }
    )

local rain_loop_interval = 5
local current_soaker = false
local soaker_running = false
local soaker_changed = true
local evaporator_running = false
local rain_replacer = false
local is_raining = false

local current_evaporator = false
local evap_replacer = false
local evap_interval = 10
local evap_changed = true

local function pick_rain_replacer(weather)
    local new_soaker = false
    is_raining = true
    if weather == "overcast_rain" then
        rain_replacer = light_rain_replacer
        new_soaker = "light"
    elseif weather == "overcast_heavy_rain" then
        rain_replacer = heavy_rain_replacer
        new_soaker = "heavy"
    elseif weather == "thunderstorm" or
        weather == "superstorm" then
        rain_replacer = thunderstorm_replacer
        new_soaker = "storm"
    else
        rain_replacer = false
        soaker_changed = false
        is_raining = false
    end

    if new_soaker ~= current_soaker then
        current_soaker = new_soaker
        soaker_changed = true
    end
end

local function pick_evaporator(season)
    local new_evaporator = false
    if season == "summer_early" or season == "summer_late" then
        evap_replacer = the_evaporator
        new_evaporator = "the_evaporator"
        evap_interval = 200
    else
        evap_replacer = light_evaporator
        new_evaporator = "light"
        evap_interval = 400
    end
    if current_evaporator ~= new_evaporator then
        current_evaporator = new_evaporator
        evap_changed = true
    end
end

local function rain_loop()
    local weather = climate.active_weather.name
    local season = seasons.get_season_name()
    pick_rain_replacer(weather)
    if is_raining then
        if not soaker_running or soaker_changed then
            soaker_running = true
            evaporator_running = false
            ms.remove_worker("evaporation_worker")
            ms.register_worker({name = "rain_soak_worker",
                                fun = rain_replacer,
                                has_one_of = {"spring_soil",
                                              "winter_soil"},
                                work_every = 10,
                                rework_labels = {"last_rain"},
            })
            soaker_changed = false
        end
    else
        pick_evaporator(season)
        if not evaporator_running or evap_changed then
            soaker_running = false
            evaporator_running = true
            ms.remove_worker("rain_soak_worker")
            ms.register_worker({name = "evaporation_worker",
                                fun = evap_replacer,
                                has_one_of = {"last_rain",
                                              "last_evaporated"},
                                work_every = evap_interval,
                                rework_labels = {"last_evaporated"},
            })
            evap_changed = false
        end
    end
    minetest.after(rain_loop_interval, rain_loop)
end

minetest.after(2, rain_loop)
