---------------------------------------------------------
--API for Plants and Mushrooms

-- Internationalization
local S = nodes_nature.S

---------------------------------------------------------

local random = math.random
local floor = math.floor
local c_alpha = minimal.compat_alpha

crop_rewind = crop_rewind
exile_add_food_hooks = exile_add_food_hooks
creative = creative
wielded_light = wielded_light

-- Globals
plant_base_growing_time = 200
plant_base_timer = 40
seed_growing_time = 40

soil_preferences = {}

local seasonal_types = {
    early = {
        _spring_early = "_seedling3",
        _spring_late = "_flowering",
        _summer_early = "_fruiting",
        _summer_late = "_fruiting",
        _fall_early = "_fruiting",
        _fall_late = "_dead",
        _winter_early = "_dead",
        _winter_late = "_seed",
    },
    medium = {
        _spring_early = "_seed",
        _spring_late = "_seedling3",
        _summer_early = "_flowering",
        _summer_late = "_fruiting",
        _fall_early = "_fruiting",
        _fall_late = "_dead",
        _winter_early = "_dead",
        _winter_late = "_dead",
    },
    late = {
        _spring_early = "_dead",
        _spring_late = "_seed",
        _summer_early = "_seedling3",
        _summer_late = "_flowering",
        _fall_early = "_fruiting",
        _fall_late = "_dead",
        _winter_early = "_dead",
        _winter_late = "_dead",
    },
    whole_season = {
        _spring_early = "_seedling5",
        _spring_late = "",
        _summer_early = "",
        _summer_late = "",
        _fall_early = "",
        _fall_late = "",
        _winter_early = "_dead",
        _winter_late = "_dead",
    },
    whole_season_woody = {
        _spring_early = "",
        _spring_late = "",
        _summer_early = "",
        _summer_late = "",
        _fall_early = "",
        _fall_late = "",
        _winter_early = "_dead",
        _winter_late = "_dead",
    }
}

function soil_preferences.new(args)
    local prefs = {
        rocky_substrate = args.rocky_substrate,
        organic_substrate = args.organic_substrate,
        density = args.density,
    }
    return prefs
end

function soil_preferences.is_sediment_good(sed_name, plant_prefs)
    local rocky_substrate = minetest.get_item_group(sed_name, "rocky_substrate")
    local organic_substrate = minetest.get_item_group(sed_name, "organic_substrate")
    local density = minetest.get_item_group(sed_name, "density")
    if not plant_prefs then return true end
    if rocky_substrate then
        if not (rocky_substrate >= plant_prefs.rocky_substrate.min
                and rocky_substrate <= plant_prefs.rocky_substrate.max) then
            return false
        end
    end
    if organic_substrate then
        if not (organic_substrate >= plant_prefs.organic_substrate.min
                and organic_substrate <= plant_prefs.organic_substrate.max) then
            return false
        end
    end
    if density then
        if not (density >= plant_prefs.density.min
                and density <= plant_prefs.density.max) then
            return false
        end
    end
    return true
end

------------------------------
-- Seeds/seedling soil timers
-- if the soil quality changes under the seed it will slow/speed the timer
-- this procedure returns a timer
local function seed_soil_response(pos, soil_prefs)
    local pos_under = {x = pos.x, y = pos.y - 1, z = pos.z}
    local node_under = minetest.get_node(pos_under).name
    local sediment = minetest.get_item_group(node_under, "sediment")
    if sediment == 0 then
        return 0
    end
    local wetness = minetest.get_item_group(node_under, "wet_sediment")
    local progress = 1
    if wetness == 1 then
        progress = progress + 2
    elseif wetness == 2 then -- salty
        return 0
    end
    local is_soil_good = soil_preferences.is_sediment_good(node_under, soil_prefs)
    local ag_soil = minetest.get_item_group(node_under, "agricultural_soil")
    local fertile_soil = minetest.get_item_group(node_under, "fertile_soil")
    if is_soil_good then
        progress = progress + 2
    end
    -- normal and fertile agri soils can partially cancell effects of bad soil
    if fertile_soil == 1 or ag_soil == 1 then
        progress = progress + 1
    elseif not is_soil_good then
        return 0
    end
    local fertility = minetest.get_item_group(node_under, "fertility")
    if fertility > 0 then
        progress = progress + fertility
    end
    return progress
end

local function is_on_sediment(pos)
    local pos_under = {x = pos.x, y = pos.y - 1, z = pos.z}
    local node_under = minetest.get_node(pos_under)
    return minetest.get_item_group(node_under.name, "sediment") > 0
end

local function is_mushroom(pos)
    local plant_name = minetest.get_node(pos).name
    local nodedef = minetest.registered_nodes[plant_name]
    return minetest.get_item_group(plant_name, "mushroom") > 0
end

local function is_dark(pos)
    local light = minimal.get_daylight({x=pos.x, y=pos.y + 1, z=pos.z})
    return not light or light < 3
end

local function is_temperature_extreme(pos)
    local temp = climate.get_point_temp(pos)
    return temp < -30 or temp > 60
end

local function is_temperature_good(pos)
    local temp = climate.get_point_temp(pos)
    return temp > 0 or temp < 40
end

local function are_conditions_good(pos)
    --if not on sediment abort
    if not is_on_sediment(pos) then
        return false
    end
    --semi-extreme temps stop growth
    if not is_temperature_good(pos) then
        return false
    end
    --cannot grow indoors (unless a mushroom)
    if not is_mushroom(pos) and is_dark(pos) then
        return false
    end
    return true
end

-- returns growth to catch up or false if the plant has died 
local function catch_up_timer(pos, elapsed, last_updated, growing_left, growth_rate)
    local temp = climate.get_point_temp(pos)
    local mushroom = is_mushroom(pos)
    local elapsed = elapsed - last_updated
    if elapsed > plant_base_timer then
        if pos.y < -15 and temp >= 0 or temp <= 40 then
            if mushroom then
                --This is an underground shroom, assume steady temp
                return growing_left - growth_rate * ( elapsed / plant_base_timer)
            else
                -- underground plant, but we've got light so give it 50%
                return growing_left - growth_rate * ( elapsed / plant_base_timer / 2)
            end
        else
            -- change only takes rain, sun and temp into account
            local change = crop_rewind(elapsed, plant_base_timer, mushroom)
            if change == -1 then
                --Exteme heat or cold killed the plant
                minetest.remove_node(pos)
                return false -- kill the timer
            end
            -- growth_rate is comes from soil quality
            return growing_left - change - growth_rate * (elapsed / plant_base_timer / 2)
        end
    end
    return growing_left -- we weren't away actually
end

local function catch_up_life_stage(pos, growing_time, growing_left)
    while growing_left < 0 do
        local node_name = minetest.get_node(pos).name
        local nodedef = minetest.registered_nodes[node_name]
        if nodedef._next_life_stage then
            local p2 = nodedef.place_param2
            minetest.remove_node(pos)
            minetest.place_node(pos, {name = nodedef._next_life_stage,
                                    param2 = p2})
        end
        growing_left = growing_left + growing_time
    end
    local meta = minetest.get_meta(pos)
    meta:set_int("growth", growing_left)
end

local function deplete_soil(pos)
    local node_name = minetest.get_node(pos).name
    local nodedef = minetest.registered_nodes[node_name]
    if nodedef._depleted_name then
        minetest.swap_node(pos, {name = nodedef._depleted_name})
    end
end

local function kill_or_stop_growing(pos)
    -- extreme temps will kill
    if is_temperature_extreme(pos) then
        minetest.remove_node(pos)
        return true
    end
    -- stop growth if conditions not suitable
    if not are_conditions_good(pos) then
        return true
    end
    -- the plant survives this time
    return false
end

local function grow_seed(pos)
    local node_name = minetest.get_node(pos).name
    local nodedef = minetest.registered_nodes[node_name]
    if kill_or_stop_growing(pos) then
        return true -- unless dead, try again when conditions are good
    end
    minetest.remove_node(pos)
    minetest.place_node(pos, {name = nodedef._next_life_stage})
    return false -- the seed becomes a seedling (stops the timer)
end

-- Grows a plant
local function grow_plant(pos, elapsed, growing_time, soil_prefs)
    local pos_under = {x = pos.x, y = pos.y - 1, z = pos.z}
    local meta = minetest.get_meta(pos)
    local growing_left = meta:get_int("growth")
    local last_updated = meta:get_int("last_updated") or elapsed
    --We've been away, let's catch up on missing growth
    local progress = seed_soil_response(pos, soil_prefs)
    growing_left = catch_up_timer(pos, elapsed, last_updated, growing_left, progress)
    -- if catch_up_timer returns false it means the plant has died
    -- due to extreme weather
    if not growing_left then return false end
    -- new plant, or grow
    local plant_name = minetest.get_node(pos).name
    local plant_nodedef = minetest.registered_nodes[plant_name]
    if growing_left < 0 then
        catch_up_life_stage(pos, growing_time, growing_left)
        return false
    end
    if kill_or_stop_growing(pos) then
        return true -- the plant can't grow, waits for better times
    end
    --still growing
    --chance to deplete soil
    if math.random() <= 0.0001 then
        deplete_soil(pos_under)
    end
    if progress <= 0 then
        return true -- soil is terrible, no growing here
    end
    growing_left = growing_left - progress
    --grow faster in rain
    if climate.get_rain(pos) then
        growing_left = growing_left - 4
    end
    meta:set_int("growth", growing_left)
    meta:set_int("last_updated", elapsed)
    return true
end

---------------------------
-- Save/restore seedling timers on dig/place
--
local on_dig_seedling = function(pos, node, digger)
    if not digger then return false end

    if minetest.is_protected(pos, digger:get_player_name()) then
        return false
    end
    local meta = minetest.get_meta(pos)
    local growing_left = meta:get_int("growth")
    if not growing_left then growing_left = plant_base_growing_time end

    local new_stack = ItemStack(node.name)
    local stack_meta = new_stack:get_meta()
    stack_meta:set_int("growth", growing_left)

    minetest.remove_node(pos)
    local player_inv = digger:get_inventory()
    if player_inv:room_for_item("main", new_stack) then
        player_inv:add_item("main", new_stack)
    else
        minetest.add_item(pos, new_stack)
    end
end

local after_place_seedling = function(pos, placer, itemstack, pointed_thing)
    local meta = minetest.get_meta(pos)
    local stack_meta = itemstack:get_meta()
    local growing_left = stack_meta:get_int("growth")
    if growing_left == 0 then -- new seeds have no meta
        growing_left = meta:get_int("growth") -- but it's set on the node already
    end
    if not growing_left then growing_left = plant_base_growing_time end
    meta:set_int("growth", growing_left)
end

---------------------------
-- Prevent placing seed anywhere but sediment
--
local on_place_seedling = function(itemstack, placer, pointed_thing)
    local ground = minetest.get_node(pointed_thing.under)
    local above = minetest.get_node(pointed_thing.above)
    if minetest.get_item_group(ground.name,"sediment") == 0
        or above.name ~= "air" then
        local udef = minetest.registered_nodes[ground.name]
        if udef and udef.on_rightclick and
            not (placer and placer:is_player() and
                 placer:get_player_control().sneak) then
	    return udef.on_rightclick(pointed_thing.under, ground,
				      placer, itemstack,
				      pointed_thing) or itemstack
        else
            return itemstack
        end
    end

    return minetest.item_place_node(itemstack,placer,pointed_thing)
end

---------------------------
-- Dig upwards
--

local function dig_up(pos, node, digger)
	if digger == nil then return end
	local lnode = wielded_light.get_unlit_node(node)
	local np = {x = pos.x, y = pos.y + 1, z = pos.z}
	local unode = wielded_light.get_unlit_node(minetest.get_node(np))
	if lnode.name == unode.name then
		minetest.node_dig(np, unode, digger)
	end
end

local sounds = {
    ["default_leaves"] = nodes_nature.node_sound_leaves_defaults(),
    ["woody_plant"] = nodes_nature.node_sound_wood_defaults(),
    ["bamboo"] = nodes_nature.node_sound_wood_defaults(),
}

local base_groups = {
    base = {temp_pass = 1, attached_node = 1, flora = 1},
    mushroom = {mushroom = 1},
    seed = {
        seed = 1,
        flammable = 2,
        dig_immediate = 3,
        falling_node = 1,
    },
    spore = {
        seed = 1,
        snappy = 3,
        flammable = 3,
        dig_immediate = 2
    },
    seedling = {
        snappy = 3,
        herbaceous_plant = 1,
        attached_node = 1,
        flammable = 2,
        seedling = 1,
        not_in_creative_inventory = 1,
    },
}

local plant_groups = {
    ["moss"] = {
        crumbly = 3,
        herbaceous_plant = 1,
        flammable = 5,
    },
    ["woody_plant"] = {
        choppy = 3,
        woody_plant = 1,
        flammable = 2,
    },
    ["herbaceous_plant"] = {
        snappy = 3,
        herbaceous_plant = 1,
        flammable = 3,
    },
    ["fibrous_plant"] = {
        snappy = 3,
        fibrous_plant = 1,
        flammable = 1,
    },
    ["mushroom"] = {
        snappy = 3,
        flammable = 3,
    },
    ["cane"] = {
        snappy = 3,
        fibrous_plant = 1,
        flammable = 1,
        cane_plant = 1,
    },
    ["bamboo"] = {
        choppy = 3,
        woody_plant = 1,
        flammable = 1,
        cane_plant = 1,
    },
}

plant = {}

-- args.mesh_type
-- Currently the following meshes are choosable:
--   * 0 = a "x" shaped plant (ordinary plant)
--   * 1 = a "+" shaped plant (just rotated 45 degrees)
--   * 2 = a "*" shaped plant with 3 faces instead of 2
--   * 3 = a "#" shaped plant with 4 faces instead of 2
--   * 4 = a "#" shaped plant with 4 faces that lean

function plant.new(args)
    local waving
    if args.waving then
        waving = 1
    end
    local thorns
    if args.thorns then thorns = 1 end
    local seasons = args.seasons
    if not args.seasons and args.seasonal_type then
        seasons = seasonal_types[args.seasonal_type]
    end
    local def = {
        name = args.name,
        description = args.description,
        soil_preferences = args.soil_preferences,
        growing_time = args.growing_time,
        light_range = args.light_range,
        mesh_type = args.mesh_type, -- see the comment above
        drawtype = args.drawtype, -- plantlike, nodebox, mesh
        bioluminescence = args.bioluminescence,
        lifeform_type = args.lifeform_type,
        seedling_number = args.seedling_number or 5,
        plant_type = args.plant_type,
        texture_scale = args.texture_scale or 1,
        seasons = seasons,
        extra_groups = args.extra_groups,
        lbm = args.lbm or false,
        dye_candidate = args.dye_candidate or false,
        dominant_color = args.dominant_color,
        fruit = args.fruit,
        thorns = thorns,
        climbable = args.climbable,
        nodebox = args.nodebox or {-0.4, -0.5, -0.4, 0.4, -0.2, 0.4},
        seedling_nodebox = args.seedling_nodebox or {-0.2, -0.5, -0.2, 0.2, -0.3, 0.2},
        waving = waving,
        seed_number = args.seed_number or 6,
    }
    return def
end

function plant.get_name(basename)
    local mod_name = minetest.get_current_modname()
    return mod_name..":"..basename
end

function plant.get_seed_name(basename)
    local mod_name = minetest.get_current_modname()
    return mod_name..":"..basename.."_seed"
end

function plant.get_seedling_name(basename, nr)
    local nr = nr or ""
    local mod_name = minetest.get_current_modname()
    return mod_name..":"..basename.."_seedling"..nr
end

function plant.get_texture_name(basename)
    local mod_name = minetest.get_current_modname()
    return mod_name.."_"..basename..".png"
end

function plant.get_seedling_texture_name(basename)
    local mod_name = minetest.get_current_modname()
    return mod_name.."_"..basename.."_seedling.png"
end

function plant.get_flowering_name(basename)
    local mod_name = minetest.get_current_modname()
    return mod_name..":"..basename.."_flowering"
end

function plant.get_fruiting_name(basename)
    local mod_name = minetest.get_current_modname()
    return mod_name..":"..basename.."_fruiting"
end

function plant.get_fruit_name(basename)
    local mod_name = minetest.get_current_modname()
    return mod_name..":"..basename.."_fruit"
end

function plant.get_fruitless_name(basename)
    local mod_name = minetest.get_current_modname()
    return mod_name..":"..basename.."_fruitless"
end

function plant.get_dead_name(basename)
    local mod_name = minetest.get_current_modname()
    return mod_name..":"..basename.."_dead"
end

function plant.get_dead_fruitless_name(basename)
    local mod_name = minetest.get_current_modname()
    return mod_name..":"..basename.."_dead_fruitless"
end

function plant.get_flowering_texture_name(basename)
    local mod_name = minetest.get_current_modname()
    return mod_name.."_"..basename.."_flowering"..".png"
end

function plant.get_fruiting_texture_name(basename)
    local mod_name = minetest.get_current_modname()
    return mod_name.."_"..basename.."_fruiting"..".png"
end

function plant.get_fruit_texture_name(basename)
    local mod_name = minetest.get_current_modname()
    return mod_name.."_"..basename.."_fruit"..".png"
end

function plant.get_fruitless_texture_name(basename)
    local mod_name = minetest.get_current_modname()
    return mod_name.."_"..basename.."_fruitless"..".png"
end

function plant.get_dead_fruitless_texture_name(basename)
    local mod_name = minetest.get_current_modname()
    return mod_name.."_"..basename.."_dead_fruitless"..".png"
end

function plant.get_dead_texture_name(basename)
    local mod_name = minetest.get_current_modname()
    return mod_name.."_"..basename.."_dead"..".png"
end

function plant.get_groups(plant_def)
    local plant_type = plant_def.plant_type
    local groups = plant_groups[plant_type]
    local base = base_groups.base
    if plant_def.lifeform_type == "mushroom" then
        base = minimal.merge_tables(base, base_groups.mushroom)
    end
    if plant_def.bioluminescence then
        base = minimal.merge_tables(base, {bioluminescent = 1})
    end
    if plant_def.extra_groups then
        base = minimal.merge_tables(base, plant_def.extra_groups)
    end
    if plant_def.seasons or plant_def.seasonal_type then
        base = minimal.merge_tables(base, {seasonal = 1})
    end
    return minimal.merge_tables(groups, base)
end

function plant.get_seedling_groups(plant_def)
    local base = {}
    if plant_def.lifeform_type == "mushroom" then
        base = minimal.merge_tables(
            plant_groups["mushroom"],
            base_groups.mushroom)
    end
    if plant_def.seasons or plant_def.seasonal_type then
        base = minimal.merge_tables(base, {seasonal = 1})
    end
    return minimal.merge_tables(base, base_groups.seedling)
end

function plant.get_seed_groups(plant_def)
    local base = {}
    if plant_def.lifeform_type == "mushroom" then
        base = minimal.merge_tables(
            base_groups.spore,
            base_groups.mushroom)
    else
        base = base_groups.seed
    end
    if plant_def.seasons or plant_def.seasonal_type then
        base = minimal.merge_tables(base, {seasonal = 1})
    end
    return minimal.merge_tables(base, base_groups.seed)
end

function plant.get_sounds(plant_def)
    if sounds[plant_def.plant_type] then
        return sounds[plant_def.plant_type]
    else
        return sounds["default_leaves"]
    end
end

function plant.get_base_props(plant_def)
    local name = plant.get_name(plant_def.name)
    local seasons = plant_def.seasons
    local props = {
        description = plant_def.description,
        tiles = {plant.get_texture_name(plant_def.name)},
        stack_max = minimal.stack_max_medium,
        paramtype = "light",
        visual_scale = plant_def.texture_scale,
        light_source = plant_def.bioluminescence,
        floodable = true,
        sunlight_propagates = true,
        walkable = false,
        buildable_to = true,
        climbable = plant_def.climbable,
        damage_per_second = plant_def.thorns,
        selection_box = {
            type = "fixed",
            fixed = plant_def.nodebox,
        },
        groups = plant.get_groups(plant_def),
        sounds = plant.get_sounds(plant_def),
    }
    if seasons then
        props = minimal.merge_tables(
            props, {
                _spring_early = name..seasons._spring_early,
                _spring_late = name..seasons._spring_late,
                _summer_early = name..seasons._summer_early,
                _summer_late = name..seasons._summer_late,
                _fall_early = name..seasons._fall_early,
                _fall_late = name..seasons._fall_late,
                _winter_early = name..seasons._winter_early,
                _winter_late = name..seasons._winter_late,
        })
    end
    return props
end

function plant.get_plantlike_props(plant_def)
    local props = {
        inventory_image = plant.get_texture_name(plant_def.name),
        wield_image = plant.get_texture_name(plant_def.name),
        drawtype = "plantlike",
        paramtype2 = "meshoptions",
        place_param2 = plant_def.mesh_type,
        waving = plant_def.waving,
    }
    return minimal.merge_tables(plant.get_base_props(plant_def), props)
end

function plant.get_canelike_props(plant_def)
    local base = plant.get_plantlike_props(plant_def)
    base.place_param2 = 2
    base.selection_box = {
        type = "fixed",
        fixed = {-0.1875, -0.5, -0.1875, 0.1875, 0.5, 0.1875},
    }
    base.groups.attached_node = 0
    base.after_dig_node = function(pos, node, metadata, digger)
        dig_up(pos, node, digger)
    end
    base.floodable = false
    local plant_name = plant.get_name(plant_def.name)
    base.on_place = function(itemstack, placer, pointed_thing)
        local under = pointed_thing.under
        local node = minetest.get_node(under)
        local udef = minetest.registered_nodes[node.name]

        if node.name == plant_name then
            return
        end
        -- Run any on_rightclick function of pointed node
        if udef and udef.on_rightclick and
            not (placer and placer:is_player() and
                 placer:get_player_control().sneak) then
            return udef.on_rightclick(under, node, placer,
                                      itemstack, pointed_thing) or itemstack
        end
        local face = vector.direction(pointed_thing.above,
                                      pointed_thing.under)
        if face.y == -1 then
            minetest.item_place_node(itemstack, placer,
                                     pointed_thing)
            return itemstack
        else
            return itemstack
        end
    end
    return base
end

function plant.register_canelike(plant_def)
    minetest.register_node(
        plant.get_name(plant_def.name),
        plant.get_canelike_props(plant_def))
end

function plant.get_bamboolike_props(plant_def)
    local base = plant.get_canelike_props(plant_def)
    base.buildable_to = false
    return base
end

function plant.register_bamboolike(plant_def)
    minetest.register_node(
        plant.get_name(plant_def.name),
        plant.get_bamboolike_props(plant_def))
end

local function start_growing_plant(pos, growing_time)
    local timer_min = plant_base_timer - 0.1 * plant_base_timer
    local timer_max = plant_base_timer + 0.1 * plant_base_timer
    local meta = minetest.get_meta(pos)
    meta:set_int("growth", growing_time)
    meta:set_int("last_updated", 0)
    local timer = minetest.get_node_timer(pos)
    if not timer:is_started() then
        timer:start(math.random(timer_min, timer_max))
    end
end

function plant.get_seedling_base_props(plant_def)
    local plantname = plant.get_name(plant_def.name)
    local props = {
        description = S("Young @1", plant_def.description),
        groups = plant.get_seedling_groups(plant_def),
        _next_life_stage = plantname,
        on_timer = function(pos, elapsed)
            return grow_plant(pos, elapsed,
                              plant_def.growing_time,
                              plant_def.soil_preferences)
        end,
        on_place = function(itemstack, placer, pointed_thing)
            return on_place_seedling(itemstack, placer, pointed_thing)
        end,
        after_place_node = function(pos, placer, itemstack, pointed_thing)
            after_place_seedling(pos, placer, itemstack, pointed_thing)
            start_growing_plant(pos, plant_def.growing_time)
        end,
        on_dig = function(pos, node, digger)
            on_dig_seedling(pos, node, digger)
        end,
    }
    return minimal.merge_tables(plant.get_base_props(plant_def), props)
end

function plant.get_plantlike_seedling_props(plant_def)
    local base = minimal.merge_tables(
        plant.get_plantlike_props(plant_def),
        plant.get_seedling_base_props(plant_def))
    local props = {
        tiles = {plant.get_seedling_texture_name(plant_def.name)},
        inventory_image = plant.get_seedling_texture_name(plant_def.name),
        wield_image = plant.get_seedling_texture_name(plant_def.name),
    }
    return minimal.merge_tables(base, props)
end

function plant.register_plantlike_seedlings(plant_def)
    local nr = plant_def.seedling_number
    for i = 1, nr - 1 do
        local props = plant.get_plantlike_seedling_props(plant_def)
        props._next_life_stage = plant.get_seedling_name(plant_def.name, i + 1)
        props.visual_scale = i / nr
        local seedling_name = plant.get_seedling_name(plant_def.name, i)
        minetest.register_node(seedling_name, props)
    end
    -- the last seedling
    local props = plant.get_plantlike_seedling_props(plant_def)
    if plant_def.fruit then
        props._next_life_stage = plant.get_flowering_name(plant_def.name)
    end
    minetest.register_node(plant.get_seedling_name(plant_def.name, nr), props)
end

function plant.get_plantlike_flowering_props(plant_def)
    local base = plant.get_plantlike_props(plant_def)
    base.description = S("Flowering @1", plant_def.description)
    base.tiles = {plant.get_flowering_texture_name(plant_def.name)}
    base._next_life_stage = plant.get_fruiting_name(plant_def.name)
    base.inventory_image = plant.get_flowering_texture_name(plant_def.name)
    base.wield_image = plant.get_flowering_texture_name(plant_def.name)
    base.on_timer = function(pos, elapsed)
        return grow_plant(pos, elapsed,
                          plant_def.growing_time,
                          plant_def.soil_preferences)
    end
    base.on_place = function(itemstack, placer, pointed_thing)
        return on_place_seedling(itemstack, placer, pointed_thing)
    end
    base.after_place_node = function(pos, placer, itemstack, pointed_thing)
        after_place_seedling(pos, placer, itemstack, pointed_thing)
        start_growing_plant(pos, plant_def.growing_time)
    end
    base.on_dig = function(pos, node, digger)
        on_dig_seedling(pos, node, digger)
    end
    if plant_def.dye_candidate then
        base.groups.ncrafting_dye_candidate = 1
    end
    return base
end

function plant.get_plantlike_fruiting_props(plant_def)
    local base = plant.get_plantlike_flowering_props(plant_def)
    base.description = S("Fruiting @1", plant_def.description)
    base.tiles = {plant.get_fruiting_texture_name(plant_def.name)}
    base._fruitless_name = plant.get_fruitless_name(plant_def.name)
    base._fruit_name = plant.get_fruit_name(plant_def.name)
    base.inventory_image = plant.get_fruiting_texture_name(plant_def.name)
    base.wield_image = plant.get_fruiting_texture_name(plant_def.name)
    base.on_punch = function(pos, node, puncher, pointed_thing)
        local node_name = minetest.get_node(pos).name
        local nodedef = minetest.registered_nodes[node_name]
        if nodedef._fruitless_name then
            local p2 = nodedef.place_param2
            minetest.remove_node(pos)
            minetest.place_node(pos, {name = nodedef._fruitless_name,
                                    param2 = p2})
        end
        local inv = puncher:get_inventory()
        local new_stack = ItemStack(nodedef._fruit_name)
        if inv:room_for_item("main", new_stack) then
            inv:add_item("main", new_stack)
        else
            minetest.add_item(pos, new_stack)
        end
    end
    return base
end

function plant.get_plantlike_dead_fruitless_props(plant_def)
    local base = plant.get_plantlike_props(plant_def)
    base.description = S("Dead Fruitless @1", plant_def.description)
    base.inventory_image = plant.get_dead_fruitless_texture_name(plant_def.name)
    base.wield_image = plant.get_dead_fruitless_texture_name(plant_def.name)
    base.tiles = {plant.get_dead_fruitless_texture_name(plant_def.name)}
    return base
end

function plant.register_plantlike_dead_fruitless(plant_def)
    local props = plant.get_plantlike_dead_fruitless_props(plant_def)
    minetest.register_node(plant.get_dead_fruitless_name(plant_def.name), props)
end

function plant.get_plantlike_dead_props(plant_def)
    local base = plant.get_plantlike_props(plant_def)
    base.tiles = {plant.get_dead_texture_name(plant_def.name)}
    base.inventory_image = plant.get_dead_texture_name(plant_def.name)
    base.wield_image = plant.get_dead_texture_name(plant_def.name)
    base._next_life_stage = ""
    base.description = S("Dead @1", plant_def.description)
    if plant_def.fruit then
        base.description = S("Dead Fruiting @1", plant_def.description)
        base._fruitless_name = plant.get_dead_fruitless_name(plant_def.name)
        base._fruit_name = plant.get_fruit_name(plant_def.name)
        base.on_punch = function(pos, node, puncher, pointed_thing)
            local node_name = minetest.get_node(pos).name
            local nodedef = minetest.registered_nodes[node_name]
            if nodedef._fruitless_name then
                local p2 = nodedef.place_param2
                minetest.remove_node(pos)
                minetest.place_node(pos, {name = nodedef._fruitless_name,
                                          param2 = p2})
            end
            local inv = puncher:get_inventory()
            local new_stack = ItemStack(nodedef._fruit_name)
            if inv:room_for_item("main", new_stack) then
                inv:add_item("main", new_stack)
            else
                minetest.add_item(pos, new_stack)
            end
        end
    end
    return base
end

function plant.register_plantlike_dead_fruiting(plant_def)
    local props = plant.get_plantlike_dead_props(plant_def)
    minetest.register_node(plant.get_dead_name(plant_def.name), props)
end

plant.register_plantlike_dead = plant.register_plantlike_dead_fruiting

function plant.register_fruit(plant_def)
    local props = {
        description = S("@1 Fruit", plant_def.description),
        inventory_image = plant.get_fruit_texture_name(plant_def.name),
        groups = {},
        wield_image = plant.get_fruit_texture_name(plant_def.name),
        stack_max = minimal.stack_max_medium,
    }
    if plant_def.dye_candidate then
        props.groups.ncrafting_dye_candidate = 1
        props._ncrafting_dye_dcolor = plant_def.dominant_color
    end
    minetest.register_craftitem(plant.get_fruit_name(plant_def.name), props)
    exile_add_food_hooks(plant.get_fruit_name(plant_def.name))
end

function plant.get_plantlike_fruitless_props(plant_def)
    local base = plant.get_plantlike_flowering_props(plant_def)
    base.description = S("Fruitless @1", plant_def.description)
    base.inventory_image = plant.get_fruitless_texture_name(plant_def.name)
    base.wield_image = plant.get_fruitless_texture_name(plant_def.name)
    base._next_life_stage = plant.get_flowering_name(plant_def.name)
    base.tiles = {plant.get_fruitless_texture_name(plant_def.name)}
    return base
end

function plant.register_plantlike_flowering(plant_def)
    local props = plant.get_plantlike_flowering_props(plant_def)
    -- adding dyes here to avoid seedlings as dye candidates
    if plant_def.dye_candidate then
        props.groups.ncrafting_dye_candidate = 1
        props._ncrafting_dye_dcolor = plant_def.dominant_color
    end
    minetest.register_node(plant.get_flowering_name(plant_def.name), props)
    exile_add_food_hooks(plant.get_flowering_name(plant_def.name))
end

function plant.register_plantlike_fruiting(plant_def)
    local props = plant.get_plantlike_fruiting_props(plant_def)
    minetest.register_node(plant.get_fruiting_name(plant_def.name), props)
    exile_add_food_hooks(plant.get_fruiting_name(plant_def.name))
end

function plant.register_plantlike_fruitless(plant_def)
    local props = plant.get_plantlike_fruitless_props(plant_def)
    minetest.register_node(plant.get_fruitless_name(plant_def.name), props)
    exile_add_food_hooks(plant.get_fruitless_name(plant_def.name))
end

function plant.get_3D_props(plant_def)
    local props = {
        drawtype = "nodebox",
        paramtype = "light",
        paramtype2 = "facedir",
        is_ground_content = false,
        sunlight_propagates = true,
        node_box = {
            type = "fixed",
            fixed = plant_def.nodebox,
        },
        selection_box = {
            type = "fixed",
            fixed = plant_def.nodebox,
        },
    }
    return minimal.merge_tables(plant.get_base_props(plant_def), props)
end

function plant.register_3D(plant_def)
    local props = plant.get_3D_props(plant_def)
    if plant_def.dye_candidate then
        props.groups.ncrafting_dye_candidate = 1
        props._ncrafting_dye_dcolor = plant_def.dominant_color
    end
    minetest.register_node(plant.get_name(plant_def.name),
                           props)
end

function plant.get_3D_seedling_props(plant_def)
    local base = minimal.merge_tables(
        plant.get_3D_props(plant_def),
        plant.get_seedling_base_props(plant_def))
    local props = {
        tiles = {plant.get_texture_name(plant_def.name)},
        node_box = {
            type = "fixed",
            fixed = plant_def.seedling_nodebox,
        },
        selection_box = {
            type = "fixed",
            fixed = plant_def.seedling_nodebox,
        },
    }
    return minimal.merge_tables(base, props)
end

function plant.register_3D_seedling(plant_def)
    minetest.register_node(plant.get_seedling_name(plant_def.name, 1),
                           plant.get_3D_seedling_props(plant_def))
end

function plant.register_plantlike(plant_def)
    local props = plant.get_plantlike_props(plant_def)
    -- adding dyes here to avoid seedlings as dye candidates
    if plant_def.dye_candidate then
        props.groups.ncrafting_dye_candidate = 1
        props._ncrafting_dye_dcolor = plant_def.dominant_color
    end
    minetest.register_node(plant.get_name(plant_def.name), props)
end

function plant.register_plantlike_seedling(plant_def)
    minetest.register_node(plant.get_seedling_name(plant_def.name, 1),
                           plant.get_plantlike_seedling_props(plant_def))
end

local function start_growing_seed(pos)
    local timer_min = seed_growing_time - 0.25 * seed_growing_time
    local timer_max = seed_growing_time + 0.25 * seed_growing_time
    local timer = minetest.get_node_timer(pos)
    if not timer:is_started() then
        timer:start(math.random(timer_min, timer_max))
    end
end

function plant.get_seed_base_props(plant_def)
    local plantname = plant.get_name(plant_def.name)
    local seed_name = plant.get_seed_name(plant_def.name)
    local next_life_stage = plant.get_seedling_name(plant_def.name, 1)
    local seed_texture, seed_description
    if plant_def.lifeform_type == "mushroom" or
        plant_def.plant_type == "moss" then
        seed_texture = "nodes_nature_spores.png"
        seed_description = S("@1 Spores", plant_def.description)
    else
        seed_texture = "nodes_nature_seeds.png"
        seed_description = S("@1 Seeds", plant_def.description)
    end
    local props = {
        description = plant_def.seed_description or seed_description,
        tiles = {seed_texture},
        inventory_image = seed_texture,
        wield_image = seed_texture,
        stack_max = minimal.stack_max_light,
        use_texture_alpha = c_alpha.clip,
        drawtype = "nodebox",
        groups = plant.get_seed_groups(plant_def),
        sounds = nodes_nature.node_sound_defaults(),
        node_box = {
            type = "fixed",
            fixed = {-0.3, -0.5, -0.3,  0.3, -0.48, 0.3},
        },
        selection_box = {
            type = "fixed",
            fixed = {-0.3, -0.5, -0.3,  0.3, -0.48, 0.3},
        },
        _next_life_stage = next_life_stage,
        on_timer = function(pos,elapsed)
            return grow_seed(pos)
        end,
        after_place_node = function(pos, placer, itemstack, pointed_thing)
            after_place_seedling(pos, placer, itemstack, pointed_thing)
            start_growing_seed(pos)
        end,
        on_dig = function(pos, node, digger)
            on_dig_seedling(pos, node, digger)
        end,
        on_place = function(itemstack, placer, pointed_thing)
            return on_place_seedling(itemstack, placer, pointed_thing)
        end,
    }
    return minimal.merge_tables(plant.get_base_props(plant_def), props)
end

function plant.register_seed(plant_def)
    minetest.register_node(
        plant.get_seed_name(plant_def.name),
        plant.get_seed_base_props(plant_def))
end

function plant.register_fuel(plant_def)
    minetest.register_craft({
            type = "fuel",
            recipe = plant.get_name(plant_def.name),
            burntime = 1,
    })
end

function plant.register_threshing_recipes(plant_def)
    local function reg_recipe(source)
        crafting.register_recipe({
                type = "threshing_spot",
                output = plant.get_seed_name(plant_def.name).." "..plant_def.seed_number,
                items = {source},
                level = 1,
                always_known = true,
        })
        crafting.register_recipe({
                type = "threshing_spot",
                output = plant.get_seed_name(plant_def.name).." "..plant_def.seed_number * 6,
                items = {source.." 6"},
                level = 1,
                always_known = true,
        })
    end
    if plant_def.fruit then
        reg_recipe(plant.get_fruit_name(plant_def.name))
        reg_recipe(plant.get_fruiting_name(plant_def.name))
    else
        reg_recipe(plant.get_name(plant_def.name))
    end
end

function plant.add_food_hooks(plant_def)
    exile_add_food_hooks(plant.get_seed_name(plant_def.name))
    exile_add_food_hooks(plant.get_name(plant_def.name))
end

function plant.register_timer_start_lbm(plant_def)
    local plant_name = plant.get_name(plant_def.name)
    local name_list = {
        plant.get_seed_name(plant_def.name),
        plant.get_flowering_name(plant_def.name),
        --we don't have plant aging yet
        --plant.get_fruiting_name(plant_def.name),
        plant.get_fruitless_name(plant_def.name),
    }
    for i = 1, plant_def.seedling_number do
        local name = plant.get_seedling_name(plant_def.name, i)
        table.insert(name_list, name)
    end
    local mesh_type = plant_def.mesh_type
    minetest.register_lbm({
            label = "Starts plant timers",
            name = plant_name.."timer_starter",
            nodenames = name_list,
            run_at_every_load = true,
            action = function(pos, node, dtime_s)
                minetest.remove_node(pos)
                minetest.place_node(pos, {name = node.name,
                                          param2 = mesh_type})
            end,
    })
end

function plant.register_all(plant_def_list)
    for _, plant_def in ipairs(plant_def_list) do
        plant_def = plant.new(plant_def)
        plant.register_seed(plant_def)
        if plant_def.drawtype == "nodebox" then
            plant.register_3D_seedling(plant_def)
            plant.register_3D(plant_def)
        elseif plant_def.drawtype == "plantlike" then
            if plant_def.plant_type == "cane" then
                plant.register_canelike(plant_def)
            elseif plant_def.plant_type == "bamboo" then
                plant.register_bamboolike(plant_def)
            elseif not plant_def.fruit then
                --register mature plant only when we don't have fruits and flowers
                plant.register_plantlike(plant_def)
            end
            plant.register_plantlike_seedlings(plant_def, 5)
            if plant_def.lbm then
                plant.register_timer_start_lbm(plant_def)
            end
        end
        if plant_def.fruit then
            plant.register_plantlike_flowering(plant_def)
            plant.register_plantlike_fruiting(plant_def)
            plant.register_plantlike_fruitless(plant_def)
            plant.register_fruit(plant_def)
            minetest.register_alias(plant.get_name(plant_def.name),
                                    plant.get_fruiting_name(plant_def.name))
            if plant_def.seasonal_type or plant_def.seasons then
                plant.register_plantlike_dead_fruiting(plant_def)
                plant.register_plantlike_dead_fruitless(plant_def)
            end
        elseif plant_def.seasonal_type or plant_def.seasons then
            plant.register_plantlike_dead_fruiting(plant_def)
        end
        plant.register_threshing_recipes(plant_def)
        plant.add_food_hooks(plant_def)
    end
end
