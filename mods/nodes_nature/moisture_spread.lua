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
		-- elseif water_type == 2 then
		--    minetest.set_node(pos, {name = "nodes_nature:sea_ice"})
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
      elseif name == "nodes_nature:ice" then
	 local under = minetest.get_node({x = p.x, y = p.y-1, z =p.z})
	 if under.name == "nodes_nature:salt_water_source" then
	    minetest.remove_node(p)
	 else
	    minetest.set_node(p, {name = "nodes_nature:freshwater_source"})
	 end
      end
      minetest.check_for_falling(p)
      return
   end
end

minetest.register_abm({
	label = "Thaw Ice and snow",
	nodenames = {"nodes_nature:ice", "nodes_nature:snow_block"},
	interval = 103,
	chance = 5,
	action = function(...)
		thaw_frozen(...)
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
ms.labels.register("last_snow")
ms.labels.register("last_evaporated")
ms.labels.register("last_thawed")
ms.labels.register("last_freezed")
ms.labels.register("ocean")
ms.labels.register("coast")


local function get_dry_wet_pairs()
    local soil_pairs = {}
    for name, nodedef in pairs(minetest.registered_nodes) do
        if minetest.get_item_group(name, "dry_sediment") > 0 then
            soil_pairs[name] = tgcr.find_replacement(name, rt.REPLACEMENT_WET)
        end
    end
    return soil_pairs
end

local function get_wet_dry_pairs()
    local soil_pairs = {}
    for name, nodedef in pairs(minetest.registered_nodes) do
        if minetest.get_item_group(name, "wet_sediment") > 0 then
            soil_pairs[name] = tgcr.find_replacement(name, rt.REPLACEMENT_DRY)
        end
    end
    return soil_pairs
end

local function light_rain_replacer()
    return ms.create_light_aware_replacer(
        {find_replace_pairs = get_dry_wet_pairs(),
         add_labels = {"last_rain"},
         chance = 1/40,
         higher_than = 14,
        }
    )
end

local function heavy_rain_replacer()
    return ms.create_light_aware_replacer(
        {find_replace_pairs = get_dry_wet_pairs(),
         add_labels = {"last_rain"},
         chance = 1/10,
         higher_than = 14,
        }
    )
end

local function thunderstorm_replacer()
    return ms.create_light_aware_replacer(
        {find_replace_pairs = get_dry_wet_pairs(),
         add_labels = {"last_rain"},
         chance = 1/4,
         higher_than = 14,
        }
    )
end

local current_soaker = false
local soaker_running = false
local soaker_changed = true
local evaporator_running = false
local rain_replacer = false
local is_raining = false

local function pick_rain_replacer(weather)
    local new_soaker = false
    is_raining = true
    if weather == "overcast_light_rain" or
        weather == "light_rain" then
        rain_replacer = light_rain_replacer()
        new_soaker = "light"
    elseif weather == "overcast_heavy_rain" then
        rain_replacer = heavy_rain_replacer()
        new_soaker = "heavy"
    elseif weather == "thunderstorm" or
        weather == "superstorm" then
        rain_replacer = thunderstorm_replacer()
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

-----------------------
-- Evaporation

local current_evaporator = false
local evap_replacer = false
local evap_interval = 10
local evap_changed = true

local function light_evaporator()
    return ms.create_light_aware_replacer(
        {find_replace_pairs = get_wet_dry_pairs(),
         add_labels = {"last_evaporated"},
         chance = 1/15,
         higher_than = 10,
        }
    )
end

-- The Evaporator - destroyer of worlds, the sovereign of drought and thirst
local function the_evaporator()
    return ms.create_light_aware_replacer(
        {find_replace_pairs = get_wet_dry_pairs(),
         add_labels = {"last_evaporated"},
         chance = 1/2,
         higher_than = 10,
        }
    )
end

local function pick_evaporator(season)
    local new_evaporator = false
    if season == "summer_early" or season == "summer_late" then
        evap_replacer = the_evaporator()
        new_evaporator = "the_evaporator"
        evap_interval = 200
    else
        evap_replacer = light_evaporator()
        new_evaporator = "light"
        evap_interval = 400
    end
    if current_evaporator ~= new_evaporator then
        current_evaporator = new_evaporator
        evap_changed = true
    end
end

---------------
-- Snow

local function get_nodes_for_snow()
    local good = {}
    for name, nodedef in pairs(minetest.registered_nodes) do
        --walkable under i.e. not on water etc
        local walk = nodedef.walkable
        --not on stairs, meshes etc
        local draw = nodedef.drawtype
        if (minetest.get_item_group(name, "crumbly") > 0 or
            minetest.get_item_group(name, "cracky") > 0 or
            minetest.get_item_group(name, "snappy") > 0) and
            walk and draw == "normal"
        then
            table.insert(good, name)
        end
    end
    return good
end

local snow_replace_pairs = {
    ["air"] = "nodes_nature:snow",
}

local function light_snow_placer()
    return ms.create_light_aware_top_placer(
        {to_find = get_nodes_for_snow(),
         find_replace_pairs = snow_replace_pairs,
         add_labels = {"last_snow"},
         chance = 1/50,
         higher_than = 14,
        }
    )
end

local function heavy_snow_placer()
    return ms.create_light_aware_top_placer(
        {to_find = get_nodes_for_snow(),
         find_replace_pairs = snow_replace_pairs,
         add_labels = {"last_snow"},
         chance = 1/15,
         higher_than = 14,
        }
    )
end

local function snowstorm_placer()
    return ms.create_light_aware_top_placer(
        {to_find = get_nodes_for_snow(),
         find_replace_pairs = snow_replace_pairs,
         add_labels = {"last_snow"},
         chance = 1/8,
         higher_than = 14,
        }
    )
end

local current_snower = false
local snow_placer = false
local snower_changed = true
local snow_interval = 20
local is_snowing = false
local snower_running = false

local function pick_snower(weather)
    local new_snower = false
    is_snowing = true
    if weather == "overcast_snow" or
        weather == "light_snow" or
        weather == "overcast_light_snow" then
        snow_placer = light_snow_placer()
        new_snower = "light"
    elseif weather == "overcast_heavy_snow" then
        snow_placer = heavy_snow_placer()
        new_snower = "heavy"
    elseif weather == "snowstorm" then
        snow_placer = snowstorm_placer()
        new_snower = "storm"
    else
        snow_placer = false
        snower_changed = false
        is_snowing = false
    end

    if new_snower ~= current_snower then
        current_snower = new_snower
        snower_changed = true
    end
end

local function initialize_soaker()
    soaker_running = true
    evaporator_running = false
    ms.remove_worker("evaporation_worker")
    ms.remove_worker("snow_place_worker")
    ms.register_worker({name = "rain_soak_worker",
                        fun = rain_replacer,
                        has_one_of = {"spring_soil",
                                      "winter_soil"},
                        work_every = 40,
                        rework_labels = {"last_rain"},
    })
    soaker_changed = false
end

local function initialize_snower()
    soaker_running = false
    evaporator_running = false
    snower_running = true
    ms.remove_worker("evaporation_worker")
    ms.remove_worker("rain_soak_worker")
    ms.register_worker({name = "snow_place_worker",
                        fun = snow_placer,
                        has_one_of = {"spring_soil",
                                      "winter_soil"},
                        work_every = 45,
                        rework_labels = {"last_snow"},
    })
    snower_changed = false
end

local function initialize_evaporator()
    soaker_running = false
    evaporator_running = true
    snower_running = false
    ms.remove_worker("rain_soak_worker")
    ms.remove_worker("snow_place_worker")
    ms.register_worker({name = "evaporation_worker",
                        fun = evap_replacer,
                        has_one_of = {"last_rain",
                                      "last_evaporated"},
                        work_every = evap_interval,
                        rework_labels = {"last_evaporated"},
    })
    evap_changed = false
end

----------------------
-- Thawing

local thaw_pairs = {
    ["nodes_nature:snow"] = "air",
    ["nodes_nature:sea_ice"] = "nodes_nature:salt_water_source",
}

local light_thawer =
    ms.create_simple_replacer(
        {find_replace_pairs = thaw_pairs,
         add_labels = {"last_thawed"},
         chance = 1/5,
        }
    )

local total_thawer =
    ms.create_simple_replacer(
        {find_replace_pairs = thaw_pairs,
         remove_labels = {"last_snow",
                          "last_thawed",
                          "last_freezed"},
        }
    )

local current_thawer = false
local thawer_changed = true
local thawer_running = false
local thawer_interval = false
local thawer = false

local function disable_thawer()
    if thawer_running then
        ms.remove_worker("thawing_worker")
        thawer_running = false
        current_thawer = "none"
    end
end

local function start_light_thawer()
    if current_thawer ~= "light" then
        disable_thawer()
        ms.register_worker({name = "thawing_worker",
                            fun = light_thawer,
                            has_one_of = {"last_snow",
                                          "last_freezed"},
                            work_every = 120,
                            rework_labels = {"last_evaporated"},
        })
        thawer_running = true
        current_thawer = "light"
    end
end

local function start_total_thawer()
    if current_thawer ~= "total" then
        disable_thawer()
        ms.register_worker({name = "thawing_worker",
                            fun = total_thawer,
                            has_one_of = {"last_snow",
                                          "last_freezed"},
        })
        thawer_running = true
        current_thawer = "total"
    end
end

--------------------
--- Icer

local icer_running = false
local current_icer = false
local icer_changed = true
local icer_interval = 70

-- Finds ocean
ms.create_biome_finder({
        biome_list = {
            "Shallow Water",
            "Deep Water",
            "Sandy Beach",
            "Silty Beach",
            "Gravel Beach",
            "Sandy Coast",
            "Silty Coast",
            "Gravel Coast",
        },
        add_labels = {
            "ocean",
        }
})

ms.create_biome_finder({
        biome_list = {
            "Sandy Beach",
            "Silty Beach",
            "Gravel Beach",
            "Sandy Coast",
            "Silty Coast",
            "Gravel Coast",
        },
        add_labels = {
            "coast",
        }
})

local freeze_pairs = {
    ["nodes_nature:salt_water_source"] = "nodes_nature:sea_ice"
}

local light_icer =
    ms.create_light_aware_replacer(
        {find_replace_pairs = freeze_pairs,
         add_labels = {"last_freezed"},
         chance = 1/25,
         higher_than = 14,
        }
    )

local ice_queen =
    ms.create_light_aware_replacer(
        {find_replace_pairs = freeze_pairs,
         add_labels = {"last_freezed"},
         chance = 1/5,
         higher_than = 14,
        }
    )

local function disable_icer()
    if icer_running then
        ms.remove_worker("freezing_worker")
        icer_running = false
        current_icer = "none"
    end
end

local function start_light_icer()
    if not icer_running or icer_changed then
        if current_icer ~= "light" then
            disable_icer()
            ms.register_worker({name = "freezing_worker",
                                fun = light_icer,
                                work_every = icer_interval,
                                has_one_of = {"ocean", "coast"},
                                rework_labels = {"last_freezed"},
            })
            icer_running = true
            current_icer = "light"
        end
    end
end

local function start_ice_queen()
    if not icer_running or icer_changed then
        if current_icer ~= "ice_queen" then
            disable_icer()
            ms.register_worker({name = "freezing_worker",
                                fun = ice_queen,
                                work_every = icer_interval,
                                has_one_of = {"ocean", "coast"},
                                rework_labels = {"last_freezed"},
            })
            icer_running = true
            current_icer = "ice_queen"
        end
    end
end

local weather_loop_interval = 5

local function weather_loop()
    local weather = climate.active_weather.name
    local season = seasons.get_season_name()
    pick_rain_replacer(weather)
    pick_snower(weather)
    if is_raining then
        if not soaker_running or soaker_changed then
            initialize_soaker()
        end
    elseif is_snowing then
        if not snower_running or snower_changed then
            initialize_snower()
        end
    else
        pick_evaporator(season)
        if not evaporator_running or evap_changed then
            initialize_evaporator()
        end
    end

    local freezing = climate.freezing_temp()

    if freezing then
        if climate.get_active_temp() <= -10 then
            start_ice_queen()
        else
            start_light_icer()
        end
        -- no thawer
        disable_thawer()
    elseif season ~= "spring_early" and
        not seasons.is_winter() then
        -- total thawer
        start_total_thawer()
        disable_icer()
    else
        -- light thawer
        start_light_thawer()
        disable_icer()
    end

    minetest.after(weather_loop_interval, weather_loop)
end

-- Start the weather loop
minetest.register_on_mods_loaded(function ()
        minetest.after(2, weather_loop)
end)
