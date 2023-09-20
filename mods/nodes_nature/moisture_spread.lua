-------------------------------------------------------------
--MOISTURE SPREAD
--move wettness through sediment
--other water effects

local nn = nodes_nature
local rt = nn.replacement_types
local ms = mapchunk_shepherd
local seasons = seasons

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

local function get_dry_wet_pairs()
    local soil_pairs = {}
    for name, nodedef in pairs(minetest.registered_nodes) do
        if minetest.get_item_group(name, "dry_sediment") > 0 then
            local replacement = tgcr.find_replacement(name, rt.REPLACEMENT_WET)
            if name ~= replacement then
                soil_pairs[name] = replacement
            end
        end
    end
    return table.copy(soil_pairs)
end

local function get_wet_dry_pairs()
    local soil_pairs = {}
    for name, nodedef in pairs(minetest.registered_nodes) do
        if minetest.get_item_group(name, "wet_sediment") == 1 then
            local replacement = tgcr.find_replacement(name, rt.REPLACEMENT_DRY)
            if name ~= replacement then
                soil_pairs[name] = replacement
            end
        end
    end
    return table.copy(soil_pairs)
end

local soil_labels =
    {"spring_soil",
     "winter_soil",
     "coast",
     "volcano",
     "mountains",
     "bare_soil"}

local function soaker()
    return ms.create_light_aware_replacer(
        {find_replace_pairs = get_dry_wet_pairs(),
         add_labels = {"last_rain"},
         higher_than = 14,
         not_found_labels = {"no_soil"},
         not_found_remove = soil_labels,
        }
    )
end

local current_soaker = false
local soaker_running = false
local soaker_changed = true
local evaporator_running = false
local rain_replacer = false
local is_raining = false
local soak_chance = 1/40

local function pick_rain_replacer(weather)
    local new_soaker = false
    is_raining = true
    if weather == "overcast_light_rain" or
        weather == "light_rain" then
        soak_chance = 1/40
        new_soaker = "light"
    elseif weather == "overcast_heavy_rain" then
        soak_chance = 1/10
        new_soaker = "heavy"
    elseif weather == "thunderstorm" or
        weather == "superstorm" then
        soak_chance = 1/4
        new_soaker = "storm"
    else
        rain_replacer = false
        soaker_changed = false
        is_raining = false
    end

    if new_soaker ~= current_soaker then
        current_soaker = new_soaker
        rain_replacer = soaker()
        soaker_changed = true
    end
end

-----------------------
-- Evaporation

local function get_evap_pairs()
    local evap_pairs = get_wet_dry_pairs()
    evap_pairs["nodes_nature:freshwater_source"] = "air"
    return evap_pairs
end

local current_evaporator = false
local evap_replacer = false
local evap_interval = 500
local evap_changed = true
local evap_chance = 1/20

local function evaporator()
    return nn.create_evaporator(
        {find_replace_pairs = get_evap_pairs(),
         water_names = {"nodes_nature:freshwater_source"},
         neighbors = {"air"},
         add_labels = {"last_evaporated"},
        }
    )
end

local function pick_evaporator(season)
    local new_evaporator = false
    if season == "summer_early" or season == "summer_late" then
        -- The Evaporator - destroyer of worlds, the sovereign of drought and thirst
        new_evaporator = "the_evaporator"
        evap_chance = 1/2
    else
        new_evaporator = "light"
        evap_chance = 1/20
    end
    if current_evaporator ~= new_evaporator then
        current_evaporator = new_evaporator
        evap_replacer = evaporator()
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

local function snow()
    return ms.create_light_aware_top_placer(
        {to_find = get_nodes_for_snow(),
         find_replace_pairs = snow_replace_pairs,
         add_labels = {"last_snow"},
         higher_than = 14,
        }
    )
end

local current_snower = false
local snow_placer = false
local snower_changed = true
local is_snowing = false
local snower_running = false
local snower_chance = 1/50

local function pick_snower(weather)
    local new_snower = false
    is_snowing = true
    if weather == "overcast_snow" or
        weather == "light_snow" or
        weather == "overcast_light_snow" then
        snower_chance = 1/50
        new_snower = "light"
    elseif weather == "overcast_heavy_snow" then
        snower_chance = 1/15
        new_snower = "heavy"
    elseif weather == "snowstorm" then
        snower_chance = 1/8
        new_snower = "storm"
    else
        ms.remove_worker("snow_place_worker")
        snow_placer = false
        snower_changed = false
        is_snowing = false
    end

    if new_snower ~= current_snower then
        current_snower = new_snower
        snow_placer = snow()
        snower_changed = true
    end
end

local function initialize_soaker()
    soaker_running = true
    evaporator_running = false
    ms.remove_worker("evaporation_worker")
    evap_chance = 0
    ms.remove_worker("snow_place_worker")
    local function register()
        ms.register_worker(
            {name = "rain_soak_worker",
             fun = rain_replacer,
             has_one_of = soil_labels,
             work_every = 60,
             rework_labels = {"last_rain"},
             chance = soak_chance,
        })
    end
    -- delay before it gets starts soaking
    minetest.after(25, register)
    soaker_changed = false
end

local function initialize_snower()
    soaker_running = false
    evaporator_running = false
    snower_running = true
    ms.remove_worker("evaporation_worker")
    evap_chance = 0
    ms.remove_worker("rain_soak_worker")
    local function register()
        ms.register_worker({name = "snow_place_worker",
                            fun = snow_placer,
                            has_one_of = soil_labels,
                            rework_labels = {"last_snow"},
                            work_every = 80,
                            chance = snower_chance,
        })
    end
    -- delay before it gets starts snowing
    minetest.after(25, register)
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
                                      "last_evaporated",
                                      "moisture_spread",
                                      "water_gravity"},
                        work_every = evap_interval,
                        rework_labels = {"last_evaporated"},
                        chance = evap_chance,
    })
    evap_changed = false
end

----------------------
-- Thawing

local thaw_pairs = {
    ["nodes_nature:snow"] = "air",
    ["nodes_nature:sea_ice"] = "nodes_nature:salt_water_source",
    ["nodes_nature:ice"] = "nodes_nature:freshwater_source",
    ["nodes_nature:snow_block"] = "nodes_nature:freshwater_source",
}

local light_thawer =
    ms.create_simple_replacer(
        {find_replace_pairs = thaw_pairs,
         add_labels = {"last_thawed"},
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
                            rework_labels = {"last_thawed"},
                            work_every = 120,
                            chance = 1/7,
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
                            chance = 1,
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
local icer_interval = 60

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

ms.create_biome_finder({
        biome_list = {
            "Highland",
            "Highland Scree",
            "Highland Rock",
        },
        add_labels = {
            "mountains",
        }
})

local freeze_pairs = {
    ["nodes_nature:salt_water_source"] = "nodes_nature:sea_ice",
    ["nodes_nature:freshwater_source"] = "nodes_nature:ice",
}

local icer =
    ms.create_light_aware_replacer(
        {find_replace_pairs = freeze_pairs,
         add_labels = {"last_freezed"},
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
                                fun = icer,
                                work_every = icer_interval,
                                has_one_of = {"ocean", "coast"},
                                rework_labels = {"last_freezed"},
                                chance = 1/25,
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
                                fun = icer,
                                work_every = icer_interval,
                                has_one_of = {"ocean", "coast"},
                                rework_labels = {"last_freezed"},
                                chance = 1/5,
            })
            icer_running = true
            current_icer = "ice_queen"
        end
    end
end

local function get_buildable_to()
    local good = {}
    table.insert(good, "air")
    for name, nodedef in pairs(minetest.registered_nodes) do
        local floodable = nodedef.floodable
        -- if floodable and string.find(name, "nodes_nature") then
        --     table.insert(good, name)
        -- end
        if nodedef.liquidtype == "flowing" then
            table.insert(good, name)
        end
    end
    return good
end

local seawater = {
    "nodes_nature:salt_water_source",
}

local moisture_spread_interval = 120

local function moisture_spread(pos)
    local node = minetest.get_node(pos)
    local nodename = node.name

    --dry version
    local nodedef = minetest.registered_nodes[nodename]
    local water_type = minetest.get_item_group(nodename, "wet_sediment")
    --1= fresh or 2 = salty

    if not nodedef or not water_type then
        return
    end


    if evap_chance > 0 then
        -- evaporation
        local pos_above = vector.new(pos)
        pos_above.y = pos_above.y + 1
        local light = minimal.get_daylight(pos, 0.5) or 0
        if math.random() < evap_chance *
            (moisture_spread_interval / evap_interval) *
            (light / 15) then
            tgcr.make_replacement(pos, rt.REPLACEMENT_DRY)
            return
        end
    end

    --move through the soil, with a bias downwards
    local dry_table = minetest.find_nodes_in_area(
        {x = pos.x - 1, y = pos.y - 1, z = pos.z - 1},
        {x = pos.x + 1, y = pos.y, z = pos.z + 1},
        {"group:dry_sediment"})

    if #dry_table > 0 then
        local dry_pos = dry_table[math.random(1, #dry_table)]
        local dry_name = minetest.get_node(dry_pos).name
        if minetest.get_item_group(dry_name, "wet_sediment") == 0 then
            tgcr.make_replacement(pos, rt.REPLACEMENT_DRY)
            tgcr.make_replacement(dry_pos, rt.REPLACEMENT_WET)
        end
        return
    end

    local wet_table = minetest.find_nodes_in_area(
        {x = pos.x - 1, y = pos.y, z = pos.z - 1},
        {x = pos.x + 1, y = pos.y + 1, z = pos.z + 1},
        {"group:wet_sediment"})

    -- don't leach out if less than 15 / 18 wet neighbors
    if #wet_table < 15 then
        return
    end

    local air_table = minetest.find_nodes_in_area(
        {x = pos.x - 1, y = pos.y - 1, z = pos.z - 1},
        {x = pos.x + 1, y = pos.y - 1, z = pos.z + 1},
        {"air"})

    if #air_table >= 2 then
        --select a random one
        local pos_air = air_table[math.random(1, #air_table)]
        --lose it's own water, and move it
        local pos_above = vector.new(pos_air)
        pos_above.y = pos_above.y + 1
        local node_above = minetest.get_node(pos_above)
        if node_above.name == "air" then
            -- only leach out if there are 2 nodes of air
            tgcr.make_replacement(pos, rt.REPLACEMENT_DRY)
            minetest.set_node(pos_air, {name = "nodes_nature:freshwater_source"})
        end
    end
end

-- I set this below after all mods get loaded
local buildable_to = {}

local function water_source_down(pos)
    local node = minetest.get_node(pos)

    minetest.check_for_falling(pos)
    node = minetest.get_node(pos)

    if minetest.get_item_group(node.name, "water") == 0 then
        -- not water
        return
    end

    if evap_chance > 0 then
        -- evaporation
        local pos_above = vector.new(pos)
        pos_above.y = pos_above.y + 1
        local light = minimal.get_daylight(pos, 0.5) or 0
        if math.random() < evap_chance *
            (moisture_spread_interval / evap_interval) *
            (light / 15) * 1/5
        then
            minetest.remove_node(pos)
            return
        end
    end

    local dry_table = minetest.find_nodes_in_area(
        {x = pos.x - 1, y = pos.y - 1, z = pos.z - 1},
        {x = pos.x + 1, y = pos.y, z = pos.z + 1},
        {"group:dry_sediment"})

    if #dry_table > 0 then
        -- soak into dry sediment
        local dry_pos = dry_table[math.random(1, #dry_table)]
        local dry_name = minetest.get_node(dry_pos).name
        if minetest.get_item_group(dry_name, "wet_sediment") == 0 then
            minetest.remove_node(pos)
            tgcr.make_replacement(dry_pos, rt.REPLACEMENT_WET)
            return
        end
    end

    local air_table = minetest.find_nodes_in_area(
        {x = pos.x - 1, y = pos.y - 1, z = pos.z - 1},
        {x = pos.x + 1, y = pos.y - 1, z = pos.z + 1},
        buildable_to)

    if #air_table > 0 then
        --select a random one
        local air_pos = air_table[math.random(#air_table)]
        minetest.remove_node(pos)
        minetest.set_node(air_pos, {name = node.name})
        minetest.check_for_falling(air_pos)
        return
    end

    local pos_under = vector.new(pos)
    pos_under.y = pos_under.y - 1
    local node_under = minetest.get_node(pos_under)

    --Fresh water should not float on top of the ocean
    if pos_under.name == "nodes_nature:salt_water_source" and
        node.name == "nodes_nature:freshwater_source" then
        minetest.remove_node(pos)
        return
    end
end

nn.moisture_orphans = {}
nn.water_orphans = {}

local function handle_sediment_orphans(hash)
    local orphans = nn.moisture_orphans[hash]
    for _, pos in pairs(orphans) do
        moisture_spread(pos)
    end
    nn.moisture_orphans[hash] = {}
end

local function handle_water_orphans(hash)
    local orphans = nn.water_orphans[hash]
    for _, pos in pairs(orphans) do
        water_source_down(pos)
    end
    nn.water_orphans[hash] = {}
end

local function start_moisture_spread()
    local buildable_to_liquid = {}
    for _, name in pairs(buildable_to) do
        buildable_to_liquid[name] = "nodes_nature:freshwater_source"
    end
    local moisture_spread_worker =
        nn.create_soak_out_move_down({
                wet_to_dry = get_wet_dry_pairs(),
                buildable_to_liquid = buildable_to_liquid,
                air = "air",
                add_labels = {"moisture_spread"},
        })
    ms.register_worker({name = "moisture_spread_worker",
                        fun = moisture_spread_worker,
                        work_every = moisture_spread_interval,
                        has_one_of = soil_labels,
                        rework_labels = {"moisture_spread"},
                        afterworker = handle_sediment_orphans,
    })

    local soak_in_grav =
        nn.create_gravity_soak_in({
                wet_to_dry = get_wet_dry_pairs(),
                buildable_to_liquid = buildable_to_liquid,
                seawater = seawater,
                air = "air",
                add_labels = {"water_gravity"},
        })
    ms.register_worker({name = "soak_in_gravity_worker",
                        fun = soak_in_grav,
                        work_every = 50,
                        has_one_of = soil_labels,
                        rework_labels = {"water_gravity"},
                        afterworker = handle_water_orphans,
    })
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
        buildable_to = get_buildable_to()
        start_moisture_spread()
end)
