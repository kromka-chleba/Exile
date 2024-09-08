---------------------------------------------------------
-- Seasonal changes for Exile
--

-- Internationalization
local S = nodes_nature.S

---------------------------------------

local nsl = naturalslopeslib
local ms = mapchunk_shepherd
local nn = nodes_nature

nn.seasons = {}
local seasons = nn.seasons

seasons.season_names = {
    "spring_early",
    "spring_late",
    "summer_early",
    "summer_late",
    "fall_early",
    "fall_late",
    "winter_early",
    "winter_late",
}

local season_names = seasons.season_names
local set_day_please = false
local days_to_skip
local set_day_pending = false

-- the variable below controls the season
local current_season = ""

-- life is a tragedy but sometimes also a comedy
-- there's no /set_date command in minetest so we wrote one
local function move_time_forward(days)
    local old_time = minetest.get_timeofday()
    local function loop()
        if days > 0 then
            days = days - 1
            minetest.set_timeofday(1)
            minetest.after(0.05, loop)
        else
            minetest.after(0.05, function () minetest.set_timeofday(old_time) end)
            minetest.after(0.5, climate.refresh)
            set_day_pending = false
        end
    end
    loop()
end

local function request_set_day(days)
    days_to_skip = days
    set_day_please = true
end

minetest.register_chatcommand(
    "set_day", {
        params = S("<day>"),
        description = S("Sets date."),
        privs = {settime = true},
        func = function(_name, param)
            if set_day_pending then
                return false, S("I'm setting day, wait!")
            end
            if param == "" or not tonumber(param) then
                return false, S("Wrong argument, needs a number!")
            end
            local day = math.floor(param)
            local current_day = minetest.get_day_count() % 80 + 1
            if day > current_day then
                days_to_skip = day - current_day
            elseif day < current_day then
                days_to_skip = 80 - current_day + day
            else
                return true, S("Nothing to change, the date stays as is.")
            end
            request_set_day(days_to_skip)
            return true, S("Date change requested!")
        end,
})

-- Don't use this in the seasonal loop
function seasons.get_season_and_day()
    -- days into the current year
    local days = minetest.get_day_count() % 80
    local season_days = days % 20 + 1
    -- season_nr: Birth - 1, Thirst - 2, Retreat - 3, Hunger - 4
    local season_nr = math.floor(days/20) + 1
    return season_nr, season_days
end

-- This one is only for the seasonal loop
local function update_season()
    local season, day = seasons.get_season_and_day()
    local season_name = ""
    if season == 1 then
        season_name = "spring"
    elseif season == 2 then
        season_name = "summer"
    elseif season == 3 then
        season_name = "fall"
    elseif season == 4 then
        season_name = "winter"
    end

    if day > 0 and day <= 10 then
        season_name = season_name.."_early"
    else
        season_name = season_name.."_late"
    end

    if season_name ~= current_season then
        current_season = season_name
    end
end

-- Gives you the current season as set in the seasonal loop
-- may be slightly outdated by whatever the current loop interval is
-- but prevents race conditions.
-- See "season_loop_interval" and "season_loop".
function seasons.get_season_name()
    return current_season
end

function seasons.is_winter(season_name)
    local season = season_name or seasons.get_season_name()
    if season == "winter_early" or
        season == "winter_late" then
        return true
    end
    return false
end

local function get_seasonal_soil_names(include_slopes, include_roots)
    local soil_names = {}
    for name, nodedef in pairs(minetest.registered_nodes) do
        if minetest.get_item_group(name, "spreading") > 0 then
            local slope = minetest.get_item_group(name, "natural_slope")
            if slope == 0 then
                table.insert(soil_names, name)
            end
            if include_slopes and slope > 0 then
                table.insert(soil_names, name)
            end
        elseif minetest.get_item_group(name, "roots") > 0 and
            minetest.get_item_group(name, "winter_soil") == 0 and
            include_roots then
            table.insert(soil_names, name)
        end
    end
    return soil_names
end

local function spring_to_winter_pairs(include_slopes, include_roots)
    local soil_pairs = {}
    local spring_soils = get_seasonal_soil_names(include_slopes, include_roots)
    for _, name in pairs(spring_soils) do
        local nodedef = minetest.registered_nodes[name]
        if not nodedef then
            minetest.log("error", name)
        end
        local winter_name = nodedef._winter_name
        local slope = minetest.get_item_group(name, "natural_slope")
        if slope > 0 then
            winter_name = nsl.get_all_slopes(winter_name)[slope]
        end
        soil_pairs[name] = winter_name
    end
    return soil_pairs
end

local function get_winter_soil_names(include_slopes, include_roots)
    local spring_to_winter = spring_to_winter_pairs(include_slopes,
                                                    include_roots)
    local names = {}
    for _, winter in pairs(spring_to_winter) do
        table.insert(names, winter)
    end
    return names
end

local function winter_to_spring_pairs(include_slopes, include_roots)
    local soil_pairs = {}
    local spring_to_winter = spring_to_winter_pairs(include_slopes,
                                                    include_roots)
    for spring, winter in pairs(spring_to_winter) do
        soil_pairs[winter] = spring
    end
    return soil_pairs
end

local spring_soils = get_seasonal_soil_names()
local winter_soils = get_winter_soil_names()
local spring_to_winter = spring_to_winter_pairs(true, true)
local winter_to_spring = winter_to_spring_pairs(true, true)

local spring_soil_replacer =
    ms.create_simple_replacer(
        {find_replace_pairs = spring_to_winter,
         add_labels = {"winter_soil"},
         remove_labels = {"spring_soil"},
         not_found_labels = {"no_spring_soil"},
         not_found_remove = {"spring_soil"},
        }
    )

local winter_soil_replacer =
    ms.create_simple_replacer(
        {find_replace_pairs = winter_to_spring,
         add_labels = {"spring_soil"},
         remove_labels = {"winter_soil"},
         not_found_labels = {"no_winter_soil"},
         not_found_remove = {"winter_soil"}
        }
    )

local current_soil_replacer = ""

local function swap_soils(season_name)
    local winter = seasons.is_winter(season_name)
    if winter and current_soil_replacer ~= "winter" then
        ms.remove_worker("winter_soil_replacer")
        local worker = ms.worker.new(
            {name = "spring_soil_replacer",
             fun = spring_soil_replacer,
             needed_labels = {"spring_soil"}})
        worker:register()
        current_soil_replacer = "winter"
    end

    if not winter and current_soil_replacer ~= "spring" then
        ms.remove_worker("spring_soil_replacer")
        local worker = ms.worker.new(
            {name = "winter_soil_replacer",
             fun = winter_soil_replacer,
             needed_labels = {"winter_soil"}})
        worker:register()
        current_soil_replacer = "spring"
    end
end

local function get_seasonal_plant_names()
    local plant_names = {}
    for name, nodedef in pairs(minetest.registered_nodes) do
        if minetest.get_item_group(name, "seasonal") > 0 then
            table.insert(plant_names, name)
        end
    end
    return plant_names
end

local function get_plant_season_pairs(season_param)
    local plant_pairs = {}
    for name, nodedef in pairs(minetest.registered_nodes) do
        if minetest.get_item_group(name, "seasonal") > 0 then
            local replacement = nodedef["_"..season_param]
            if replacement then
                plant_pairs[name] = replacement
            end
        end
    end
    return plant_pairs
end

local function get_plant_labels_but_this(season_name)
    local labels = {}
    for _, season in pairs(season_names) do
        if season ~= season_name then
            table.insert(labels, season.."_plants")
        end
    end
    return table.copy(labels)
end

local pairs_by_season = {}
local plant_replacer = false
local current_plant_replacer = ""

local function initialize_plant_replacer(season_name)
    local labels = get_plant_labels_but_this(season_name)
    table.insert(labels, "seasonal_plants")
    plant_replacer =
        ms.create_param2_aware_replacer(
            {find_replace_pairs = pairs_by_season[season_name],
             add_labels = {season_name.."_plants"},
             remove_labels = labels,
             lower_than = 64, --exclude domesticated and half-wild
             not_found_remove = labels,
            }
        )
    ms.remove_worker("seasonal_plant_worker")
    local worker = ms.worker.new(
        {name = "seasonal_plant_worker",
         fun = plant_replacer,
         has_one_of = labels})
    worker:register()
    current_plant_replacer = season_name
end

local function swap_plants(season_name)
    -- Turning this off because now we have mapgen scanners in the shepherd
    -- leaving for testing the shepherd
    -- initialize_plant_scanner()
    if not pairs_by_season[season_name] then
        pairs_by_season[season_name] = get_plant_season_pairs(season_name)
    end
    if season_name ~= current_plant_replacer then
        initialize_plant_replacer(season_name)
    end
end

--------------------
-- Leaf drop

local function total_leaf_dropper()
    return ms.create_simple_replacer(
        {find_replace_pairs = nn.leaves_to_mark,
         add_labels = {"leaves_dropped"},
         remove_labels = {"seasonal_trees", "leaves"},
        }
    )
end

local function spring_leaf_grower()
    return ms.create_neighbor_aware_replacer(
        {find_replace_pairs = nn.mark_to_leaves,
         add_labels = {"leaves"},
         neighbors = nn.tree_neighbors,
        }
    )
end

local function total_leaf_grower()
    return ms.create_simple_replacer(
        {find_replace_pairs = nn.mark_to_leaves,
         add_labels = {"leaves"},
         remove_labels = {"leaves_dropped"},
        }
    )
end

local current_leaf_worker = ""

local function start_total_leaf_dropper(season_name)
    ms.remove_worker("seasonal_leaf_worker")
    local worker = ms.worker.new(
        {name = "seasonal_leaf_worker",
         fun = total_leaf_dropper(),
         has_one_of = {"seasonal_trees",
                       "leaves"}})
    worker:register()
    current_leaf_worker = season_name
end

local function start_total_leaf_grower(season_name)
    ms.remove_worker("seasonal_leaf_worker")
    local worker = ms.worker.new(
        {name = "seasonal_leaf_worker",
         fun = total_leaf_grower(),
         needed_labels = {"leaves_dropped"}})
    worker:register()
    current_leaf_worker = season_name
end

local function start_spring_leaf_grower(season_name)
    ms.remove_worker("seasonal_leaf_worker")
    local worker = ms.worker.new(
        {name = "seasonal_leaf_worker",
         fun = spring_leaf_grower(),
         work_every = 200,
         chance = 1/30,
         rework_labels = {"leaves"},
         needed_labels = {"leaves_dropped"}})
    worker:register()
    current_leaf_worker = season_name
end

local function swap_leaves(season_name)
    if current_leaf_worker == season_name then
        return
    end

    if seasons.is_winter(season_name) then
        start_total_leaf_dropper(season_name)
    elseif season_name == "spring_early" then
        start_spring_leaf_grower(season_name)
    else
        start_total_leaf_grower(season_name)
    end
end

local season_loop_interval = 5

local function season_loop()
    if set_day_please then
        set_day_pending = true
        set_day_please = false
        move_time_forward(days_to_skip)
    end
    -- Prevent running stuff when date is changed to avoid glitches
    if not set_day_pending then
        update_season()
        local season_name = seasons.get_season_name()
        swap_plants(season_name)
        swap_soils(season_name)
        swap_leaves(season_name)
    end
    minetest.after(season_loop_interval, season_loop)
end

-- starts the loop after 2 seconds after everything (hopefully) finishes loading
-- starting this right away caused a crash because minetest.get_day_count()
-- returned nil

minetest.register_on_mods_loaded(function ()
        minetest.after(2, season_loop)
end)

-- Turning this off because now we have mapgen scanners in the shepherd
-- ms.register_scanner({name = "spring_soil_finder",
--                      fun = spring_soil_finder})

local spring_labels = {
    "spring_soil",
    "seasonal_plants",
}

minetest.register_lbm({
        name = "nodes_nature:spring_chunk_lbm",
        label = "Spring soil finder for mapchunk shepherd",
        nodenames = spring_soils,
        run_at_every_load = false,
        action = function(pos, _node)
            local hash = ms.mapchunk_hash(pos)
            if not ms.contains_labels(hash, spring_labels) then
                ms.handle_labels(hash, spring_labels)
            end
        end,
})

local winter_labels = {
    "winter_soil",
    "seasonal_plants",
}

minetest.register_lbm({
        name = "nodes_nature:winter_chunk_lbm",
        label = "Winter soil finder for mapchunk shepherd",
        nodenames = winter_soils,
        run_at_every_load = false,
        action = function(pos, _node)
            local hash = ms.mapchunk_hash(pos)
            if not ms.contains_labels(hash, winter_labels) then
                ms.handle_labels(hash, winter_labels)
            end
        end,
})
