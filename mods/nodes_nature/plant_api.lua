---------------------------------------------------------
--API for Plants and Mushrooms
---------------------------------------------------------
-- functions in this file handle creating and registering
-- node definitions of plants and mushrooms

-- Internationalization
local S = nodes_nature.S

---------------------------------------------------------

local c_alpha = minimal.compat_alpha

-- Globals
nodes_nature = nodes_nature
wielded_light = wielded_light

local nn = nodes_nature
local seasons = nn.seasons
local seasonal_types = nn.seasonal_types
local add_food_hooks = HEALTH.add_food_hooks
local plant = nodes_nature.plant

---------------------------
-- Prevent placing seed anywhere but sediment
--
local on_place_plant = function(itemstack, placer, pointed_thing)
    local ground = minimal.get_nodedef(pointed_thing.under)
    local above = minetest.get_node(pointed_thing.above)
    if not ( minimal.is_group(ground.name, "sediment")
             and minimal.is_group(above.name, "air") ) then
        -- no sediment below/air above
        if not (minetest.is_player(placer) -- if player not sneakin'
                and placer:get_player_control().sneak) then
            local on_click = minimal.on_rightclick(itemstack, placer,
                                                   pointed_thing)
            if on_click ~= false then
                return on_click or itemstack
            end
        end

        return itemstack
    end
    return minetest.item_place_node(itemstack, placer, pointed_thing)
end

local sounds = {
    ["default_leaves"] = nodes_nature.node_sound_leaves_defaults(),
    ["woody_plant"] = nodes_nature.node_sound_wood_defaults(),
    ["bamboo"] = nodes_nature.node_sound_wood_defaults(),
}

local base_groups = {
    base = {temp_pass = 1, attached_node = 1, flora = 1},
    mushroom = {mushroom = 1, flora = 1},
    seed = {
        seed = 1,
        flammable = 2,
        dig_immediate = 3,
        falling_node = 1,
        temp_pass = 1,
    },
    spore = {
        seed = 1,
        snappy = 3,
        flammable = 3,
        dig_immediate = 2,
        temp_pass = 1,
    },
    seedling = {
        snappy = 3,
        herbaceous_plant = 1,
        attached_node = 1,
        flammable = 2,
        seedling = 1,
        not_in_creative_inventory = 1,
        temp_pass = 1,
    },
}

local plant_groups = {
    ["moss"] = {
        crumbly = 3,
        herbaceous_plant = 1,
        flammable = 5,
        compostable = 1,
    },
    ["woody_plant"] = {
        choppy = 3,
        woody_plant = 1,
        flammable = 2,
        compostable = 1,
    },
    ["herbaceous_plant"] = {
        snappy = 3,
        herbaceous_plant = 1,
        flammable = 3,
    },
    ["fibrous_plant"] = {
        snappy = 3,
        fibrous_plant = 1,
        bundleable_fiber = 1,
        flammable = 1,
        compostable = 1,
    },
    ["mushroom"] = {
        snappy = 3,
        flammable = 3,
    },
    ["cane"] = {
        snappy = 3,
        fibrous_plant = 1,
        bundleable_fiber = 1,
        flammable = 1,
        cane_plant = 1,
        compostable = 1,
    },
    ["bamboo"] = {
        choppy = 3,
        woody_plant = 1,
        flammable = 1,
        cane_plant = 1,
        compostable = 1,
    },
}

-- args.mesh_type
-- Currently the following meshes are choosable:
--   * 0 = a "x" shaped plant (ordinary plant)
--   * 1 = a "+" shaped plant (just rotated 45 degrees)
--   * 2 = a "*" shaped plant with 3 faces instead of 2
--   * 3 = a "#" shaped plant with 4 faces instead of 2
--   * 4 = a "#" shaped plant with 4 faces that lean

function plant.new(def)
    if type(def) ~= "table" then
        error("plant.new: got non-table for definition, got type '"..type(def).."'")
    elseif type(def.name) ~= "string" then
        error("plant.new: got non-string for name, got type '"..type(def.name).."'")
    end
    -- permit plant_type to be derived from lifeform_type
    def.plant_type = def.plant_type or def.lifeform_type
    if not def.plant_type then
        error("plant.new: needs plant_type to be specified, please specify as either:\n"..
            "herbaceous_plant, woody_plant, mushroom, fibrous_plant, moss, cane, or bamboo")
    end
    local mod_origin = minetest.get_current_modname()
    -- add mod_origin to name if not provided
    def.name = def.name:sub(1,1) == ":" and mod_origin..def.name or
        not def.name:match(":") and mod_origin..":"..def.name
    def.mod_origin = mod_origin
    -- graphical
    def.drawtype = def.drawtype or "plantlike" -- plantlike, nodebox, mesh
    def.texture_scale = def.texture_scale or 1
    def.nodebox = def.nodebox
        or {-0.4, -0.5, -0.4, 0.4, -0.2, 0.4}
    def.seedling_nodebox = def.seedling_nodebox
        or {-0.2, -0.5, -0.2, 0.2, -0.3, 0.2}
    def.dye_candidate = def.dye_candidate or false
    -- fruit mechanics
    -- set winter_fruit to true if only_dead_fruit is provided
    def.winter_fruit = def.winter_fruit or def.only_dead_fruit and true or false
    -- set fruit to true if winter_fruit or dry_fruit
    def.fruit = def.fruit or
        (def.winter_fruit or def.dry_fruit) and true or false
    -- growing mechanics
    def.seedling_number = def.seedling_number or 5 -- number of seedlings the plant has
    def.growing_time = def.growing_time or nn.plant_base_growing_time
    -- season mechanics
    def.seasons = def.seasons or def.seasonal_type
        and seasonal_types[def.seasonal_type] or nil
    -- how many seeds upon crafting
    def.seed_number = def.seed_number or 6
    -- nil if not provided
    def.thorns = def.thorns and 1 or nil
    def.waving = def.waving and 1 or nil
    -- light range
    local light_range = def.light_range or {}
    light_range.min = light_range.min or light_range[1]
    light_range.max = light_range.max or light_range[2]
    light_range[1] = nil
    light_range[2] = nil
    if def.lifeform_type == "mushroom" then
        light_range.min = light_range.min or 0
        light_range.max = light_range.max or 4
    elseif def.plant_type == "cane" then
        light_range.min = light_range.min or 14
        light_range.max = light_range.max or 15
    else
        light_range.min = light_range.min or 4
        light_range.max = light_range.max or 15
    end
    def.light_range = light_range
    -- temp range
    local temp_range = def.temp_range or {}
    temp_range.min = temp_range.min or temp_range[1]
    temp_range.max = temp_range.max or temp_range[2]
    temp_range[1] = nil
    temp_range[2] = nil
    -- usual range: 5 to 40C
    temp_range.min = temp_range.min or 5
    temp_range.max = temp_range.max or temp_range.min + 35
    def.temp_range = temp_range
    --[[ other custom values checked for definition:
        soil_preferences
        mesh_type -- see the comment above
        bioluminescence
        move_resistance
        climbable
        dry_fruit, only_dead_fruit
        roots
        climbable
        seed_type, seed_texture, seed_description
        fruit_description
        root_description, root_tiles
    --]]
    return def
end

--[[return the registered name of given variant of the plant.
    var is optional and has to be a string
    var can take following values :
        - nil (base texture)
        - dead
        - dead_fruitless
        - flowering
        - fruit
        - fruiting
        - fruitless
        - seed
        - seedling
        - root
    nr is mandatory for "seedling"
    ]]
-- plant name, variant, number (for seedlings)
function plant.get_name(basename, var, nr)
    -- nil or empty string is "base plant"
    var = not var and "" or var
    if type(basename) ~= "string" then
        error("plant.get_name: got non-string plant name for getting name, got '"..type(basename).."'")
    elseif type(var) ~= "string" then
        error("plant.get_name: plant variant for '"..basename.."' has to be a string or nil, got type '"..type(var).."'")
    end  
    -- remove underscore from beginning if found (incase underscore is provided)
    -- underscore is used to check if we got a valid variant
    var = var ~= "" and var:sub(1,1) == "_" and var:sub(2) or var
    -- seedling, get number
    if var == "seedling" then
        -- set number if not provided
        nr = type(nr) == "number" and nr or 1
        var = "_"..var..nr
    -- check if valid variant
    elseif var ~= "" then
        -- variants list
        local vars = {
            "dead",
            "dead_fruitless",
            "flowering",
            "fruit",
            "fruiting",
            "fruitless",
            "seed",
            "root"
        }
        -- verify it's a valid variant
        for _,v in ipairs(vars) do
            -- valid variant, break checking loop
            if var == v then
                var = "_"..var
                break
            end
        end
        -- error if invalid variant (check if has "_" at beginning)
        -- print valid variants out by concat'ing table
        if var:sub(1,1) ~= "_" then
            error("plant.get_name: invalid plant variant for "..basename..", got '"..var.."', needs to be following:\n"..
                table.concat(vars,", "))
        end
    end

    -- return name type
    return basename..var
end

local get_name = plant.get_name

--[[return texture (string) of given variant of the plant.
    var is optional and has to be a string
    var can take following values :
        - nil (base texture)
        - dead
        - dead_fruitless
        - flowering
        - fruit
        - fruiting
        - fruitless
        - seedling
        - root
    ]]
-- uses what get_name provides, but turns it into a texture!
function plant.get_texture(basename, var)
    local texture
    -- why reword what we did above?? let's just use get_name lol
    local success, info = pcall(function()
        texture = get_name(basename, var)
    end)
    -- if there's an error, then error!
    -- except sneakily replace get_name with get_texture lol
    if not success then
        -- info can be nil? well dang, we don't know what happened
        info = info or "plant.get_texture: unexpected error"
        error(info:gsub("get_name:","get_texture:"))
    end
    -- if seedling, cut number off
    if texture:match("seedling") then
        texture = texture:sub(1,-2)
    end
    -- return texture with .png extension
    -- replace the ":" with "_" for image
    return texture:gsub(":","_")..".png"
end
local get_texture = plant.get_texture

-- #TODO kind of dirty since plant_def can be either a plant props def table, or a registered item def table
function plant.get_base_image(plant_def)
    local basename = plant_def.name
    if plant_def and plant_def.drawtype == "nodebox" then
        return basename:gsub(":","_").."_display.png"
    else
        return plant.get_texture(basename)
    end
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
    if plant_def.roots then
        base = minimal.merge_tables(base, {plant_with_roots = plant_def.roots})
    end
    if plant_def.extra_groups then
        base = minimal.merge_tables(base, plant_def.extra_groups)
    end
    if plant_def.seasons or plant_def.seasonal_type then
        base = minimal.merge_tables(base, {seasonal = 1})
    end
    return table.copy(minimal.merge_tables(groups, base))
end

function plant.get_seedling_groups(plant_def)
    local base = plant.get_groups(plant_def)
    if plant_def.lifeform_type == "mushroom" then
        base = minimal.merge_tables(
            plant_groups["mushroom"],
            base_groups.mushroom)
    end
    if plant_def.plant_type == "fibrous_plant" then
        base = minimal.merge_tables(base, {fibrous_plant = 1})
    end
    if plant_def.seasons or plant_def.seasonal_type then
        base = minimal.merge_tables(base, {seasonal = 1})
    end
    return table.copy(minimal.merge_tables(base, base_groups.seedling))
end

function plant.get_seed_groups(plant_def)
    local base
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
    return table.copy(minimal.merge_tables(base, base_groups.seed))
end

function plant.get_sounds(plant_def)
    if sounds[plant_def.plant_type] then
        return sounds[plant_def.plant_type]
    else
        return sounds["default_leaves"]
    end
end

function plant.get_seasonal_props(plant_def)
    local name = get_name(plant_def.name)
    local seasons = plant_def.seasons
    if seasons then
        return {
            _spring_early = name..seasons._spring_early,
            _spring_late = name..seasons._spring_late,
            _summer_early = name..seasons._summer_early,
            _summer_late = name..seasons._summer_late,
            _fall_early = name..seasons._fall_early,
            _fall_late = name..seasons._fall_late,
            _winter_early = name..seasons._winter_early,
            _winter_late = name..seasons._winter_late,
            _dead_name = get_name(plant_def.name, "dead"),
        }
    end
    return {}
end

function plant.get_base_props(plant_def)
    local props = {
        description = plant_def.description,
        tiles = {get_texture(plant_def.name)},
        stack_max = minimal.stack_max_medium,
        paramtype = "light",
        visual_scale = plant_def.texture_scale,
        light_source = plant_def.bioluminescence,
        floodable = true,
        sunlight_propagates = true,
        move_resistance = plant_def.move_resistance,
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
        _seed_name = get_name(plant_def.name,"seed"),

        after_place_node = function(pos, placer, itemstack, pointed_thing)
            if minetest.is_player(placer) and
                not (minimal.player_in_creative(placer)) then

                plant.set_to_domesticated(pos)
                plant.death_chance_on_replant(pos)
            end
        end,
    }
    if plant_def.roots then
        props._root_name = get_name(plant_def.name,"root")
    end
    if plant_def.thorns then
        props.on_punch = function(pos, node, puncher, pointed_thing)
            local itemstack = puncher:get_wielded_item()
            local item_name = itemstack:get_name()
            if item_name == "" then
                local hp = puncher:get_hp()
                puncher:set_hp(hp-1)
            end
        end
    end
    if plant_def.fruit and plant_def.winter_fruit then
        props = minimal.merge_tables(
            props, {
                _dead_fruitless_name =
                    get_name(plant_def.name,"dead_fruitless"),
        })
    end
    return minimal.merge_tables(props, plant.get_seasonal_props(plant_def))
end

function plant.get_plantlike_props(plant_def)
    local props = {
        inventory_image = get_texture(plant_def.name),
        wield_image = get_texture(plant_def.name),
        drawtype = "plantlike",
        paramtype2 = "meshoptions",
        place_param2 = plant_def.mesh_type,
        waving = plant_def.waving,
        groups = plant.get_groups(plant_def)
    }
    return table.copy(minimal.merge_tables(plant.get_base_props(plant_def),
                                           props))
end

function plant.get_plantlike_mature_props(plant_def)
    local base = plant.get_plantlike_props(plant_def)
    base.groups.mature_flora = 1
    return table.copy(base)
end

-- Mature cane plant, seedlings defined elsewhere
function plant.get_canelike_props(plant_def)
    local base = plant.get_plantlike_mature_props(plant_def)
    base.place_param2 = plant_def.mesh_type or 2
    base.selection_box = {
        type = "fixed",
        fixed = {-0.1875, -0.5, -0.1875, 0.1875, 0.5, 0.1875},
    }
    base.groups.attached_node = 0
    base.on_dig = function(pos, node, digger)
        return minimal.dig_up(pos, node, digger)
    end
    base.floodable = false
    local plant_name = get_name(plant_def.name)
    if plant_def.dye_candidate then
        base.groups.ncrafting_dye_candidate = 1
    end
    base.move_resistance = plant_def.move_resistance or 2
    base.on_place = function(itemstack, placer, pointed_thing)
        local under = pointed_thing.under
        local node = minetest.get_node(under)
        local udef = minetest.registered_nodes[node.name]

        if node.name == plant_name and not minetest.is_creative_enabled() then
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
    return table.copy(base)
end

function plant.register_canelike(plant_def)
    minetest.register_node(
        get_name(plant_def.name),
        plant.get_canelike_props(plant_def))
end

function plant.get_bamboolike_props(plant_def)
    local base = plant.get_canelike_props(plant_def)
    base.buildable_to = false
    base.move_resistance = plant_def.move_resistance or 5
    return table.copy(base)
end

function plant.register_bamboolike(plant_def)
    minetest.register_node(
        get_name(plant_def.name),
        plant.get_bamboolike_props(plant_def))
end

function plant.get_seedling_base_props(plant_def)
    local plantname = get_name(plant_def.name)
    local props = {
        description = S("Young @1", plant_def.description),
        groups = plant.get_seedling_groups(plant_def),
        _next_life_stage = plantname,
        on_timer = function(pos, elapsed)
            return plant.grow_plant(pos, elapsed,
                                    plant_def.growing_time,
                                    plant_def.soil_preferences)
        end,
        on_place = function(itemstack, placer, pointed_thing)
            return on_place_plant(itemstack, placer, pointed_thing)
        end,
        on_construct = function(pos)
            plant.start_growing_plant(pos, plant_def.growing_time)
        end,
    }
    return table.copy(minimal.merge_tables(plant.get_base_props(plant_def),
                                           props))
end

function plant.get_plantlike_seedling_props(plant_def)
    local base = minimal.merge_tables(
        plant.get_plantlike_props(plant_def),
        plant.get_seedling_base_props(plant_def))
    local texture = get_texture(plant_def.name, "seedling")
    local props = {
        tiles = {texture},
        inventory_image = texture,
        wield_image = texture,
    }
    return table.copy(minimal.merge_tables(base, props))
end

function plant.register_plantlike_seedlings(plant_def)
    local nr = plant_def.seedling_number
    for i = 1, nr - 1 do
        local props = plant.get_plantlike_seedling_props(plant_def)
        props._next_life_stage = get_name(plant_def.name,"seedling", i + 1)
        props.visual_scale = i / nr
        props.groups.seedling = i
        local seedling_name = get_name(plant_def.name,"seedling", i)
        minetest.register_node(seedling_name, props)
        if plant_def.edible_seedling then
            add_food_hooks(seedling_name)
        end
    end
    -- the last seedling
    local props = plant.get_plantlike_seedling_props(plant_def)
    if plant_def.fruit and plant_def.lifeform_type ~= "mushroom" then
        props._next_life_stage = get_name(plant_def.name,"flowering")
    end
    props.groups.seedling = 5
    minetest.register_node(get_name(plant_def.name,"seedling", nr), props)
    if plant_def.edible_seedling then
        add_food_hooks(get_name(plant_def.name,"seedling", nr))
    end
    -- compatibility with old worlds
    minetest.register_alias(get_name(plant_def.name).."_seedling",
                            get_name(plant_def.name,"seedling", nr))
end

function plant.get_plantlike_flowering_props(plant_def)
    local base = plant.get_plantlike_props(plant_def)
    base.description = S("Flowering @1", plant_def.description)
    local texture = get_texture(plant_def.name, "flowering")
    base.tiles = {texture}
    base._next_life_stage = get_name(plant_def.name,"fruiting")
    base.inventory_image = texture
    base.wield_image = texture
    base.groups = minimal.merge_tables(base.groups, {flowering_plant = 1})
    base.on_timer = function(pos, elapsed)
        return plant.grow_plant(pos, elapsed,
                                plant_def.growing_time,
                                plant_def.soil_preferences)
    end
    base.on_place = function(itemstack, placer, pointed_thing)
        return on_place_plant(itemstack, placer, pointed_thing)
    end
    base.on_construct = function(pos)
        plant.start_growing_plant(pos, plant_def.growing_time)
    end
    if plant_def.dye_candidate then
        base.groups.ncrafting_dye_candidate = 1
    end
    return table.copy(base)
end

local function fruiting_on_punch(pos, node, puncher, pointed_thing)
    local nodedef = minetest.registered_nodes[minetest.get_node(pos).name]
    -- what, we're just going to let you constantly grab fruit??
    if not nodedef._fruitless_name then return end
    local function replace()
        if node.param2 < 64 then
            plant.set_to_half_wild(pos)
        end
        minimal.force_place_keep_param2(pos, nodedef._fruitless_name)
    end
    local inv = puncher and puncher:get_inventory()
    local new_stack = ItemStack(nodedef._fruit_name)
    if inv and inv:room_for_item("main", new_stack) then
        replace()
        inv:add_item("main", new_stack)
    elseif not minimal.stop_on_inv_full(puncher) then
        replace()
        minetest.add_item(pos, new_stack)
    end
end

function plant.get_plantlike_fruiting_props(plant_def)
    local base = plant.get_plantlike_flowering_props(plant_def)
    base.description = S("Fruiting @1", plant_def.description)
    local texture = get_texture(plant_def.name, "fruiting")
    base.tiles = {texture}
    base._fruitless_name = get_name(plant_def.name, "fruitless")
    base._fruit_name = get_name(plant_def.name, "fruit")
    base.inventory_image = texture
    base.groups.fruiting_plant = 1
    base.groups.flowering_plant = nil
    base.groups.mature_flora = 1
    base.groups.ncrafting_dye_candidate = nil
    base.wield_image = texture
    base.on_punch = fruiting_on_punch
    return table.copy(base)
end

function plant.get_plantlike_dead_fruitless_props(plant_def)
    local base = plant.get_plantlike_props(plant_def)
    base.description = S("Dead Fruitless @1", plant_def.description)
    local texture = get_texture(plant_def.name, "dead_fruitless")
    base.inventory_image = texture
    base.wield_image = texture
    base.tiles = {texture}
    base.groups.compostable = 1
    base.after_place_node = function(pos)
        if minimal.get_param2(pos) < 64 then
            plant.set_to_domesticated(pos)
        end
    end
    base.on_construct = function(pos)
        if minimal.get_param2(pos) >= 128 then
            plant.set_to_wild(pos)
        end
    end
    for i = 1, #seasons.season_names, 1 do
        local lifestage = base["_"..seasons.season_names[i]]
        if string.find(lifestage, "dead") then
            base["_"..seasons.season_names[i]] = get_name(plant_def.name,"dead_fruitless")
        end
    end
    return table.copy(base)
end

function plant.register_plantlike_dead_fruitless(plant_def)
    local props = plant.get_plantlike_dead_fruitless_props(plant_def)
    minetest.register_node(get_name(plant_def.name,"dead_fruitless"), props)
end

function plant.get_plantlike_dead_props(plant_def)
    local base = plant.get_plantlike_props(plant_def)
    if plant_def.plant_type == "cane" then
        base = plant.get_canelike_props(plant_def)
        base.groups.cane_plant = 2 --dead
    elseif plant_def.plant_type == "bamboo" then
        base = plant.get_bamboolike_props(plant_def)
    end
    base.groups.ncrafting_dye_candidate = nil
    base.groups.compostable = 1
    local texture = get_texture(plant_def.name, "dead")
    base.tiles = {texture}
    base.inventory_image = texture
    base.wield_image = texture
    base._next_life_stage = false
    base.description = S("Dead @1", plant_def.description)
    base.after_place_node = function(pos)
        if minimal.get_param2(pos) < 64 then
            plant.set_to_domesticated(pos)
        end
    end
    if plant_def.fruit and plant_def.winter_fruit then
        base.description = S("Dead Fruiting @1", plant_def.description)
        base._fruitless_name = get_name(plant_def.name,"dead_fruitless")
        base._fruit_name = get_name(plant_def.name,"fruit")
        base.on_punch = fruiting_on_punch
        base.groups.fruiting_plant = 1
    end
    return table.copy(base)
end

function plant.register_plantlike_dead_fruiting(plant_def)
    local props = plant.get_plantlike_dead_props(plant_def)
    minetest.register_node(get_name(plant_def.name, "dead"), props)
end

plant.register_plantlike_dead = plant.register_plantlike_dead_fruiting

function plant.register_fruit(plant_def)
    local props = {
        -- permit custom fruit description, or do dry fruit description if dry fruit
        -- otherwise do regular fruit description
        description = plant_def.fruit_description or
            plant_def.dry_fruit and S("@1 Dry Fruit", plant_def.description)
            or S("@1 Fruit", plant_def.description),
        inventory_image = get_texture(plant_def.name,"fruit"),
        groups = {fruit=1},
        wield_image = get_texture(plant_def.name,"fruit"),
        stack_max = minimal.stack_max_medium,
    }
    if plant_def.dye_candidate then
        props.groups.ncrafting_dye_candidate = 1
        props._ncrafting_dye_dcolor = plant_def.dominant_color
    end
    local fruit_name = get_name(plant_def.name, "fruit")
    minetest.register_craftitem(fruit_name, props)
    add_food_hooks(fruit_name)
end

function plant.get_plantlike_fruitless_props(plant_def)
    local base = plant.get_plantlike_flowering_props(plant_def)
    base.description = S("Fruitless @1", plant_def.description)
    local texture = get_texture(plant_def.name, "fruitless")
    base.inventory_image = texture
    base.wield_image = texture
    base._next_life_stage = get_name(plant_def.name,"flowering")
    base.tiles = {texture}
    return table.copy(base)
end

function plant.register_plantlike_flowering(plant_def)
    local props = plant.get_plantlike_flowering_props(plant_def)
    -- adding dyes here to avoid seedlings as dye candidates
    if plant_def.dye_candidate then
        props.groups.ncrafting_dye_candidate = 1
        props._ncrafting_dye_dcolor = plant_def.dominant_color
    end
    local name = get_name(plant_def.name,"flowering")
    minetest.register_node(name, props)
    add_food_hooks(name)
end

function plant.register_plantlike_fruiting(plant_def)
    local props = plant.get_plantlike_fruiting_props(plant_def)
    local name = get_name(plant_def.name,"fruiting")
    minetest.register_node(name, props)
    add_food_hooks(name)
end

function plant.register_plantlike_fruitless(plant_def)
    local props = plant.get_plantlike_fruitless_props(plant_def)
    local name = get_name(plant_def.name, "fruitless")
    minetest.register_node(name, props)
    add_food_hooks(name)
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
    props.groups.mature_flora = 1
    minetest.register_node(get_name(plant_def.name),
                           props)
end

function plant.get_3D_seedling_props(plant_def)
    local base = minimal.merge_tables(
        plant.get_3D_props(plant_def),
        plant.get_seedling_base_props(plant_def))
    local props = {
        tiles = {get_texture(plant_def.name)},
        node_box = {
            type = "fixed",
            fixed = plant_def.seedling_nodebox,
        },
        selection_box = {
            type = "fixed",
            fixed = plant_def.seedling_nodebox,
        },
    }
    return table.copy(minimal.merge_tables(base, props))
end

function plant.register_3D_seedling(plant_def)
    minetest.register_node(get_name(plant_def.name,"seedling", 1),
                           plant.get_3D_seedling_props(plant_def))
    -- compatibility with old worlds
    minetest.register_alias(get_name(plant_def.name).."_seedling",
                            get_name(plant_def.name,"seedling", 1))
end

-- A mature, non-seasonal plant. Grasses and such.
function plant.register_plantlike(plant_def)
    local props = plant.get_plantlike_mature_props(plant_def)
    -- adding dyes here to avoid seedlings as dye candidates
    if plant_def.dye_candidate then
        props.groups.ncrafting_dye_candidate = 1
        props._ncrafting_dye_dcolor = plant_def.dominant_color
    end
    minetest.register_node(get_name(plant_def.name), props)
end

function plant.register_plantlike_seedling(plant_def)
    minetest.register_node(get_name(plant_def.name,"seedling", 1),
                           plant.get_plantlike_seedling_props(plant_def))
end

function plant.get_seed_base_props(plant_def)
    local next_life_stage = get_name(plant_def.name,"seedling", 1)
    -- [[get dead fruiting texture if only_dead_fruit, get fruiting texture if fruiting, or otherwise use regular plant texture]]
    local plant_img = plant_def.only_dead_fruit and get_texture(plant_def.name, "dead") or
        plant_def.fruit and get_texture(plant_def.name, "fruiting") or
        plant.get_base_image(plant_def)

    -- spores or seeds
    local seed_type = plant_def.seed_type or
        (plant_def.lifeform_type == "mushroom" or plant_def.plant_type == "moss") and "spores" or
        "seeds"
    -- get seed texture (permits custom "seed_texture" field)
    -- spores if spores, otherwise default to seeds
    local seed_texture = plant_def.seed_texture or
        seed_type == "spores" and "nodes_nature_spores.png" or
        "nodes_nature_seeds.png"
    -- get seed desc (permits custom "seed_description" field)
    -- Spores if spores, otherwise default to Seeds
    local seed_description = plant_def.seed_description or
        seed_type == "spores" and S("@1 Spores", plant_def.description) or
        S("@1 Seeds", plant_def.description)
    -- create inventory image for seed
    local inventory_seed_image = "((" .. plant_img.."^[resize:32x32)^[opacity:100)"..
    "^[combine:32x32:8,0="..seed_texture.."\\^[resize\\:24x24"

    local props = {
        description = plant_def.seed_description or seed_description,
        tiles = {seed_texture},
        inventory_image = inventory_seed_image,
        wield_image = seed_texture,
        use_texture_alpha = c_alpha.clip,
        stack_max = minimal.stack_max_light,
        paramtype = "light",
        drawtype = "nodebox",
        floodable = true,
        sunlight_propagates = true,
        walkable = false,
        buildable_to = true,
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
        _seed_name = get_name(plant_def.name,"seed"),
        on_timer = function(pos, elapsed)
            return plant.grow_seed(pos, elapsed)
        end,
        on_construct = function(pos)
            plant.set_to_half_wild(pos)
            plant.start_growing_seed(pos)
        end,
        on_place = function(itemstack, placer, pointed_thing)
            local stack_name = itemstack:get_name()
            -- will get cleared by on_place_plant, get before

            local return_itmstk = on_place_plant(itemstack, placer,
                                                 pointed_thing)
            -- return_itemstack
            if ( minetest.is_player(placer) and
                 type(return_itmstk) == "userdata"
                 and return_itmstk:get_count() <= 0 ) then
                local stack_index = placer:get_wield_index()
                -- get index to avoid getting emptying stack

                -- should not run if in creative (you're not losing any seeds!)
                local p_inv = placer:get_inventory()
                local inv_table = p_inv:get_list("main")
                if inv_table then
                    for itm_index,itm_stk in pairs(inv_table) do
                        -- itemstack index, itemstack
                        if ( stack_index ~= itm_index
                             and itm_stk:get_name() == stack_name ) then
                            -- use itemstack's index to get and remove it
                            return_itmstk = p_inv:get_stack("main",itm_index)
                            p_inv:set_stack("main",itm_index,ItemStack(''))
                            break
                        end
                    end
                end
            end
            return return_itmstk
        end,
        after_place_node = function(pos, placer, itemstack, pointed_thing)
            plant.set_to_domesticated(pos)
        end,
    }
    return minimal.merge_tables(props, plant.get_seasonal_props(plant_def))
end

function plant.register_seed(plant_def)
    minetest.register_node(
        get_name(plant_def.name,"seed"),
        plant.get_seed_base_props(plant_def))
end

function plant.register_root(plant_def)
    local props = plant.get_seed_base_props(plant_def)
    local root_texture = get_texture(plant_def.name,"root")
    props.inventory_image = root_texture
    props.wield_image = root_texture
    props.tiles = plant_def.root_tiles or {"nodes_nature_silt.png"}
    props.description = plant_def.root_description or S("@1 Root", plant_def.description)
    props.node_box = {
        type = "fixed",
        fixed = {-0.15, -0.5, -0.15,  0.15, -0.35, 0.15},
    }
    props.selection_box = nil -- clear seed selection_box
    props.stack_max = minimal.stack_max_medium
    props.walkable = true
    minetest.register_node(
        get_name(plant_def.name,"root"),
        props)
end

function plant.register_fuel(plant_def)
    minetest.register_craft({
            type = "fuel",
            recipe = get_name(plant_def.name),
            burntime = 1,
    })
end

-- return a texture to be used as output display in recipe panel
local function get_seed_recipe_display(plant_def, source)
    local source_img

    local source_def = minetest.registered_items[source] or minetest.registered_nodes[source]
    if source_def then
        source_img = source_def.inventory_image
    end
    -- This is the case for some moss/mushroom types (nodebox)
    if not source_img or source_img=="" then
        source_img =plant.get_base_image(source_def)
    end

    if plant_def.lifeform_type == "mushroom" or
        plant_def.plant_type == "moss" then

        return "((".. source_img.."^[resize:32x32)^[opacity:100)^[combine:32x32:12,0=nodes_nature_spores.png\\^[resize\\:20x20"
    else
        -- #TODO I fear some perf issue with the resize, on loading recipe panel
        return "((".. source_img.."^[resize:32x32)^[opacity:140)^[combine:32x32:12,0=nodes_nature_seeds.png\\^[resize\\:20x20"
    end
end

function plant.register_threshing_recipes(plant_def)
    local function reg_recipe(source)
        crafting.register_recipe({
                type = "threshing_spot",
                output = get_name(plant_def.name,"seed").." "..
                    plant_def.seed_number,
                items = {source},
                level = 1,
                always_known = true,
                _display=get_seed_recipe_display(plant_def, source)
        })
        --IB        crafting.register_recipe({
        --IB                type = "threshing_spot",
        --IB                output = get_name(plant_def.name,"seed").." "..plant_def.seed_number * 6,
        --IB                items = {source.." 6"},
        --IB                level = 1,
        --IB                always_known = true,
        --IB        })
    end
    if plant_def.fruit and not plant_def.only_dead_fruit then
        reg_recipe(get_name(plant_def.name,"fruit"))
        reg_recipe(get_name(plant_def.name,"fruiting"))
    else
        reg_recipe(get_name(plant_def.name))
    end
    if plant_def.only_dead_fruit then
        reg_recipe(get_name(plant_def.name,"fruit"))
    end
end

function plant.add_food_hooks(plant_def)
    add_food_hooks(get_name(plant_def.name,"seed"))
    add_food_hooks(get_name(plant_def.name))
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
        end
        if plant_def.fruit then
            plant.register_fruit(plant_def)
            -- for Zufani ambers
            if not plant_def.only_dead_fruit then
                plant.register_plantlike_flowering(plant_def)
                plant.register_plantlike_fruiting(plant_def)
                plant.register_plantlike_fruitless(plant_def)
                -- compatibility with old worlds
                minetest.register_alias(get_name(plant_def.name),
                                        get_name(plant_def.name,"fruiting"))
            else
                -- here only Zufani
                plant.register_plantlike(plant_def)
            end
            if plant_def.seasonal_type or plant_def.seasons then
                plant.register_plantlike_dead_fruiting(plant_def)
                if plant_def.winter_fruit then
                    plant.register_plantlike_dead_fruitless(plant_def)
                end
            end
        end
        if plant_def.seasonal_type or plant_def.seasons then
            plant.register_plantlike_dead(plant_def)
        end
        if plant_def.roots then
            plant.register_root(plant_def)
        end
        plant.register_threshing_recipes(plant_def)
        plant.add_food_hooks(plant_def)
    end
end
