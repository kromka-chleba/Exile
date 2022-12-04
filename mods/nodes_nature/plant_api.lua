---------------------------------------------------------
--Plants and Mushrooms (and all things growing)

-- Internationalization
local S = nodes_nature.S

---------------------------------------------------------

local random = math.random
local floor = math.floor
local c_alpha = minimal.compat_alpha

plant_base_growth = plant_base_growth
plant_base_timer = plant_base_timer
crop_rewind = crop_rewind
exile_add_food_hooks = exile_add_food_hooks
creative = creative
wielded_light = wielded_light

------------------------------
-- Seeds/seedling soil timers
--if the soil quality changes under the seed it will slow/speed the timer
local function seed_soil_response(pos)

    local pos_under = {x = pos.x, y = pos.y - 1, z = pos.z}
    local node_under = minetest.get_node(pos_under).name

    local sediment = minetest.get_item_group(node_under, "sediment")
    if sediment == 0 then
        return false
    end

    local wetness = minetest.get_item_group(node_under, "wet_sediment")
    local ag_soil = minetest.get_item_group(node_under, "agricultural_soil")
    local dep_ag_soil = minetest.get_item_group(node_under, "depleted_agricultural_soil")

    local timer_min = plant_base_timer


    --apply bonus or penalty by by soil type and wetness
    if wetness == 1 then
        --moisture is good
        timer_min = timer_min * 0.75
    elseif wetness == 2 then
        --salt water is very bad
        timer_min = timer_min * 1000
    end

    if sediment == 1 then
        --loam is best
        timer_min = timer_min * .80
    elseif sediment == 3 then
        --silt is nearly as good as loam
        timer_min = timer_min * .90
    elseif sediment == 2 then
        --clay is poor, needs to be broken up; i.e. into ag_soil
        timer_min = timer_min * 1.50
    elseif sediment == 4 or sediment == 5 then
        --sand and gravel are terrible
        timer_min = timer_min * 1.80
    end

    if ag_soil == 1 then
        --cultivation boom
        timer_min = timer_min * 0.60
    elseif dep_ag_soil == 1 then
        --lesser cultivation boom
        timer_min = timer_min * 0.80
    end

    local timer_max = timer_min * 1.1
    return timer_min, timer_max
end


-- Seeds growth
local function grow_seed(pos, seed_name, plant_name, place_p2, timer_avg, elapsed)

    local pos_under = {x = pos.x, y = pos.y - 1, z = pos.z}
    local node_under = minetest.get_node(pos_under)
    local mushroom = false

    --if not on sediment abort
    if minetest.get_item_group(node_under.name, "sediment") == 0 then
        return
    end

    --cannot grow indoors (unless a mushroom)
    if minetest.get_item_group(plant_name, "mushroom") == 0 then
        local light = minimal.get_daylight({x=pos.x, y=pos.y + 1, z=pos.z}, 0.5)
        if not light or light < 13 then
            return
        end
    else mushroom = true
    end

    --extreme temps will kill
    local temp = climate.get_point_temp(pos)
    if temp < -30 or temp > 60 then
        minetest.remove_node(pos)
        return true -- this plant's done
    end

    --
    local meta = minetest.get_meta(pos)
    local growth = meta:get_int("growth")
    --happens if they fall, no meta is set
    if growth == 0 then
        growth = plant_base_growth
    end

    --We've been away, let's catch up on missing growth
    if elapsed and elapsed > timer_avg then
        if pos.y < -15 and  temp >= 0 or temp <= 40 then
            if mushroom then
                --This is an underground shroom, assume steady temp
                growth = growth - ( elapsed / timer_avg )
            else
                -- underground plant, but we've got light so give it 50%
                growth = growth - ( elapsed / timer_avg / 2)
            end
        else
            local change = crop_rewind(elapsed, timer_avg, mushroom)
            if change == -1 then
                --Exteme heat or cold killed the plant
                minetest.remove_node(pos)
                return true
            end
            growth = growth - change
        end
    end

    --after first cycle turn seeds into seedlings
    if seed_name ~= nil then
        if minetest.get_item_group(seed_name, "seed") == 1 then
            minetest.set_node(pos, {name = plant_name.."_seedling", param2= place_p2})
            meta:set_int("growth", growth)
            --return
        end
    end

    --semi-extreme temps stop growth
    if temp < 0 or temp > 40 then
        return
    end
    -- new plant, or grow
    if growth <= 1 then
        minetest.set_node(pos, {name = plant_name, param2= place_p2})
        return true
    else
        --still growing
        --chance to deplete soil
        if minetest.get_item_group(node_under.name, "agricultural_soil") >= 1 then
            if math.random()<0.0001 then
                local deplete_name = node_under.name.."_depleted"
                minetest.swap_node(pos_under, {name = deplete_name})
            end
        end
        --grow faster in rain
        if climate.get_rain(pos) then
            growth = growth - 4
            if growth < 1 then
                growth = 1
            end
            meta:set_int("growth", growth)
        else
            growth = growth - 1
            if growth < 1 then
                growth = 1
            end
            meta:set_int("growth", growth)
        end
    end
end

---------------------------
-- Save/restore seedling timers on dig/place
--
local on_dig_seedling = function(pos,node, digger)
    if not digger then return false end

    if minetest.is_protected(pos, digger:get_player_name()) then
        return false
    end
    local meta = minetest.get_meta(pos)
    local growth = meta:get_int("growth")
    if not growth then growth = plant_base_growth end

    local new_stack = ItemStack(node.name)
    local stack_meta = new_stack:get_meta()
    stack_meta:set_int("growth", growth)

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
    local growth = stack_meta:get_int("growth")
    if growth == 0 then -- new seeds have no meta
        growth = meta:get_int("growth") -- but it's set on the node already
    end
    if not growth then growth = plant_base_growth end
    meta:set_int("growth", growth)
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
}

local base_groups = {
    base = {temp_pass = 1, attached_node = 1},
    plant = {flora = 1},
    mushroom = {mushroom = 1},
    seed = {
        seed = 1,
        snappy = 3,
        flammable = 2,
        dig_immediate = 2
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
    },
    -- not sure if default is needed
    default = {
        snappy = 3,
        flammable = 2,
    },
}

local plant_groups = {
    ["crumbly"] = {
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
    ["mushroom"] = {
        snappy = 3,
        flammable = 3,
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
    local def = {
        name = args.name,
        description = args.description,
        soil_preferences = args.soil_preferences,
        growth = args.growth,
        light_range = args.light_range,
        mesh_type = args.mesh_type, -- see the comment above
        drawtype = args.drawtype, -- plantlike, nodebox, mesh
        bioluminescence = args.bioluminescence,
        plant_type = args.plant_type,
        texture_scale = args.texture_scale or 1,
        dye = args.dye,
        selection_box = args.selection_box or {-0.4, -0.5, -0.4, 0.4, -0.2, 0.4},
        seedling_selection_box = args.seedling_selection_box or {-0.2, -0.5, -0.2, 0.2, -0.3, 0.2},
        waving = waving,
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

function plant.get_seedling_name(basename)
    local mod_name = minetest.get_current_modname()
    return mod_name..":"..basename.."_seedling"
end

function plant.get_texture_name(basename)
    local mod_name = minetest.get_current_modname()
    return mod_name.."_"..basename..".png"
end

function plant.get_seedling_texture_name(basename)
    local mod_name = minetest.get_current_modname()
    return mod_name.."_"..basename.."_seedling.png"
end

function plant.get_groups(plant_def)
    local plant_type = plant_def.plant_type
    local groups = plant_groups[plant_type]
    local base = base_groups.base
    if plant_def.dyecandidate then
        groups.ncrafting_dye_candidate = 1
    end
    if plant_type == "mushroom" then
        base = minimal.merge_tables(base, base_groups.mushroom)
    else
        base = minimal.merge_tables(base, base_groups.plant)
    end
    return minimal.merge_tables(base, groups)
end

function plant.get_seedling_groups(plant_def)
    local base = base_groups.seedling
    base.ncrafting_dye_candidate = nil -- can't make dyes from seedlings
    if plant_type == "mushroom" then
        base = minimal.merge_tables(
            plant_groups["mushroom"],
            base_groups.mushroom)
    end
    return minimal.merge_tables(base, base_groups.seedling)
end

function plant.get_seed_groups(plant_def)
    local base = {}
    base.ncrafting_dye_candidate = nil -- can't make dyes from seeds
    if plant_type == "mushroom" then
        base = minimal.merge_tables(
            base_groups.spore,
            base_groups.mushroom)
    else
        base = base_groups.seed
    end
    return minimal.merge_tables(base, base_groups.seedling)
end

function plant.get_sounds(plant_def)
    if sounds[plant_def.plant_type] then
        return sounds[plant_def.plant_type]
    else
        return sounds["default_leaves"]
    end
end

function plant.get_base_props(plant_def)
    local props = {
        description = plant_def.description,
        tiles = {plant.get_texture_name(plant_def.name)},
        inventory_image = plant.get_texture_name(plant_def.name),
        wield_image = plant.get_texture_name(plant_def.name),
        stack_max = minimal.stack_max_medium,
        drawtype = "plantlike",
        paramtype = "light",
        paramtype2 = "meshoptions",
        place_param2 = plant_def.mesh_type or 1,
        waving = plant_def.waving,
        visual_scale = plant_def.texture_scale,
        floodable = true,
        sunlight_propagates = true,
        walkable = false,
        buildable_to = true,
        drawtype = "plantlike",
        selection_box = {
            type = "fixed",
            fixed = plant_def.selection_box,
        },
        groups = plant.get_groups(plant_def),
        sounds = plant.get_sounds(plant_def),
    }
    return props
end

function plant.get_seedling_base_props(plant_def)
    local plantname = plant.get_name(plant_def.name)
    local props = {
        description = S("Young @1", plant_def.description),
        tiles = {plant.get_seedling_texture_name(plant_def.name)},
        inventory_image = plant.get_seedling_texture_name(plant_def.name),
        wield_image = plant.get_seedling_texture_name(plant_def.name),
        groups = plant.get_seedling_groups(plant_def),
        on_construct = function(pos)
            --set initial timer, growth rate depends on soil
            local timer_min, timer_max = seed_soil_response(pos)
            if timer_min then
                minetest.get_node_timer(pos):start(math.random(timer_min, timer_max))
            else
                minetest.get_node_timer(pos):start(plant_base_timer)
            end
        end,
        on_timer = function(pos, elapsed)
            local timer_min, timer_max = seed_soil_response(pos)
            if not timer_min then
                if minetest.get_node(pos).name ~= "ignore" then
                    return false -- not on soil anymore? Stop timer
                else
                    return true -- it's unloaded, skip the timer
                end
            end
            local timer_avg = timer_min + timer_max / 2
            elapsed = elapsed - timer_max
            if grow_seed(pos, nil, plantname, nil, timer_avg, elapsed) then
                return false -- done
            else
                minetest.get_node_timer(pos):start(math.random(timer_min, timer_max))
            end
        end,
        after_place_node = function(pos, placer, itemstack, pointed_thing)
            after_place_seedling(pos, placer, itemstack, pointed_thing)
        end,
        on_dig = function(pos, node, digger)
            on_dig_seedling(pos, node, digger)
        end,
    }
    return minimal.merge_tables(plant.get_base_props(plant_def), props)
end

function plant.get_3D_props(plant_def)
    local props = {
        drawtype = "nodebox",
        paramtype = "light",
        paramtype2 = "facedir",
        -- we don't want to inherit these, hence "nil"
        inventory_image = nil,
        wield_image = nil,
        is_ground_content = false,
        sunlight_propagates = true,
        node_box = {
            type = "fixed",
            fixed = {
                plant_def.selection_box,
            },
        },
        
    }
    return minimal.merge_tables(plant.get_base_props(plant_def), props)
end

function plant.register_3D(plant_def)
    minetest.register_node(plant.get_name(plant_def.name),
                           plant.get_3D_props(plant_def))
end

function plant.get_3D_seedling_props(plant_def)
    local props = minimal.merge_tables(
        plant.get_3D_props(plant_def), {
            node_box = {
                type = "fixed",
                fixed = {
                    plant_def.seedling_selection_box,
                },
                selection_box = {
                    type = "fixed",
                    fixed = plant_def.seedling_selection_box,
                },
            },
    })
    return minimal.merge_tables(
        plant.get_seedling_base_props(plant_def), props)
end

function plant.register_3D_seedling(plant_def)
    minetest.register_node(plant.get_seedling_name(plant_def.name),
                           plant.get_3D_seedling_props(plant_def))
end

function plant.register_plantlike(plant_def)
    minetest.register_node(plant.get_name(plant_def.name),
                           plant.get_base_props(plant_def))
end

function plant.register_seedling(plant_def)
    minetest.register_node(plant.get_seedling_name(plant_def.name),
                           plant.get_seedling_base_props(plant_def))
end

function plant.get_seed_base_props(plant_def)
    local plantname = plant.get_name(plant_def.name)
    local seed_name = plant.get_seed_name(plant_def.name)
    local growth = plant_def.growth
    local seed_texture, seed_description
    if plant_def.plant_type == "mushroom" then
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
        waving = 0,
        drawtype = "nodebox",
        groups = plant.get_seed_groups(plant_def),
        sounds = nodes_nature.node_sound_defaults(),
        node_box = {
            type = "fixed",
            fixed = {-0.3, -0.5, -0.3,  0.3, -0.48, 0.3},
        },
        on_construct = function(pos)
            --duration of growth, per species
            local meta = minetest.get_meta(pos)
            meta:set_int("growth", growth)
            --set initial timer, growth rate depends on soil
            local timer_min, timer_max = seed_soil_response(pos)
            if timer_min then
                minetest.get_node_timer(pos):start(math.random(timer_min, timer_max))
            else
                minetest.get_node_timer(pos):start(plant_base_timer)
            end
        end,
        on_timer = function(pos,elapsed)
            local timer_min, timer_max = seed_soil_response(pos)
            if not timer_min then
                if minetest.get_node(pos).name ~= "ignore" then
                    return false -- not on soil anymore? Stop timer
                else
                    return true -- it's unloaded, skip the timer
                end
            end
            local timer_avg = timer_min + timer_max / 2
            elapsed = elapsed - timer_max
            if grow_seed(pos, seed_name, plantname,
                         p2, timer_avg, elapsed) then
                return
            else
                minetest.get_node_timer(pos):start(math.random(timer_min, timer_max))
            end
        end,
        after_place_node = function(pos, placer, itemstack, pointed_thing)
            after_place_seedling(pos, placer, itemstack, pointed_thing)
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

function plant.make_threshing_recipes(plant_def)
    crafting.register_recipe({
            type = "threshing_spot",
            output = plant.get_seed_name(plant_def.name).." 6",
            items = {plant.get_name(plant_def.name)},
            level = 1,
            always_known = true,
    })
end

function plant.add_food_hooks(plant_def)
    exile_add_food_hooks(plant.get_seed_name(plant_def.name))
    exile_add_food_hooks(plant.get_name(plant_def.name))
end

local wrotycz =
    plant.new({name = "wrotycz", description = S("Wrotycz"),
               drawtype = "plantlike", mesh_type = 1,
               plant_type = "herbaceous_plant", waving = true,
               growth = 3})

plant.register_seed(wrotycz)
plant.register_seedling(wrotycz)
plant.register_plantlike(wrotycz)
