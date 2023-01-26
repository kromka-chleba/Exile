---------------------------------------------------------
--SEDIMENT "API"
--
----------------------------------------------------------

-- Internationalization
local S = nodes_nature.S

local c_alpha = minimal.compat_alpha

registered_sediments = {}

-- Useful objects for node definitions
sediment = {}
sediment.hardness = {
   soft = 3,
   medium = 2,
   hard = 1,
}
local hardness = sediment.hardness

local textures = {
    wet = "nodes_nature_mud.png",
    salty = "nodes_nature_mud_salt.png",
    agri_top = "nodes_nature_ag_top.png",
    agri_side = "nodes_nature_ag_side.png",
    agri_top_depleted = "nodes_nature_ag_dep_top.png",
    agri_side_depleted = "nodes_nature_ag_dep_side.png",
    tilled_soil = "nodes_nature_tilled_soil.png",
    tilled_soil_depleted = "nodes_nature_tilled_soil_depleted.png",
    fertile_soil = "nodes_nature_fertile_soil.png",
    winter = "nodes_nature_winter.png",
    winter_side = "nodes_nature_winter_side.png",
}

sediment.sounds = {
    dirt = nodes_nature.node_sound_dirt_defaults(),
    dirt_wet = nodes_nature.node_sound_dirt_defaults({
            footstep = {name = "nodes_nature_mud", gain = 0.4},
            dug = {name = "nodes_nature_mud", gain = 0.4}}),

    sand = nodes_nature.node_sound_sand_defaults(),
    sand_wet = nodes_nature.node_sound_sand_defaults({
            footstep = {name = "nodes_nature_mud", gain = 0.4},
            dug = {name = "nodes_nature_mud", gain = 0.4}}),

    gravel = nodes_nature.node_sound_gravel_defaults(),
    gravel_wet = nodes_nature.node_sound_gravel_defaults({
            footstep = {name = "nodes_nature_mud", gain = 0.4},
            dug = {name = "nodes_nature_mud", gain = 0.4}}),
}
local sounds = sediment.sounds

-- Utility functions
-----------------------------------

local function merge_tables (t1, t2)
    local new_table = {}
    --copy table
    for key, value in pairs(t1) do
        new_table[key] = value
    end
    --merge tables
    for key, value in pairs(t2) do
        new_table[key] = value
    end
    return new_table
end

-- Soil erosion and fertilizers
-----------------------------------

--soil degrades from farming
local function erode_deplete_ag_soil(pos)
    local depletion_probability = 0.01
    local erosion_probability = 0.04
    --rain makes this more likely (erosive, washes nutrient out)
    if climate.get_rain(pos) then
        depletion_probability = 0.02
        erosion_probability = 0.08
    end
    if math.random() <= erosion_probability then
        --erode if exposed, and near water or raining
        local positions = minetest.find_nodes_in_area(
            {x = pos.x - 1, y = pos.y, z = pos.z - 1},
            {x = pos.x + 1, y = pos.y, z = pos.z + 1},
            {"group:water", "air"})

        if #positions >= 1 then
            local name = minetest.get_node(pos).name
            local new = name:gsub("%_depleted","")
            new = new:gsub("%_agricultural_soil","")
            if math.random() <= 0.60 then
                -- prevents infinite supply of fertile soil
                -- 60% chance to get sediment
                new = new:gsub("%_fertile_soil","")
            end
            --would prefer stairs:slab, but sand/etc lacks wet
            new = new:gsub("%nature:","%nature:slope_pike_")
            minetest.swap_node(pos, {name = new})
            return false
        end
    end
    local node_name = minetest.get_node(pos).name
    local nodedef = minetest.registered_nodes[node_name]
    if minetest.get_item_group(node_name, "fertile_soil") then
        depletion_probability = depletion_probability / 3
    end
    if math.random() <= depletion_probability then
        if minetest.get_node({x=pos.x, y=(pos.y+1), z=pos.z}).name == 'air' then
            -- ^ don't deplete a planted node; already handled in life.lua
            -- and a 1-2% chance to be depleted via neglect
            minetest.set_node(pos, {name = nodedef._depleted_name})
            return false
        end
    end
    return true
end

-- dirt particles
function dirt_particle(pos, node_name)
    return {
        amount = 10,
        time = 0.5,
        minpos = {x = pos.x - 0.5, y = pos.y - 0.50, z = pos.z - 0.5},
        maxpos = {x = pos.x + 0.5, y = pos.y, z = pos.z + 0.5},
        minvel = {x= -0.1, y= 2, z= -0.1},
        maxvel = {x= 0.1, y= 4, z= 0.1},
        minacc = {x= 0, y= -10, z= 0},
        maxacc = {x= 0, y= -10, z= 0},
        minexptime = 1.5,
        maxexptime = 1.5,
        minsize = 0.4,
        maxsize = 1,
        collisiondetection = true,
        vertical = false,
        node = {name = node_name, param2 = 0},
    }
end

--For using fertilizer on punch
local function fertilize_ag_soil(pos, puncher)
    --hit it with fertilizer to restore
    local itemstack = puncher:get_wielded_item()
    local item_name = itemstack:get_name()
    local node_name = minetest.get_node(pos).name
    local nodedef = minetest.registered_nodes[node_name]
    local inv = puncher:get_inventory()
    local fertilized = false
    local replace_with = ""
    if minetest.get_item_group(item_name, "fertilizer") >= 1
        and nodedef._rich_name then
        minetest.swap_node(pos, {name = nodedef._rich_name})
        if item_name == "tech:wood_ash_block" then
            replace_with = "tech:wood_ash"
        end
        fertilized = true
    end

    if nodedef._fertile_name and
        not string.find(node_name, "fertile") then
        if item_name == "nodes_nature:compost" or
            item_name == "nodes_nature:compost_wet" then
            replace_with = "stairs:slab_compost"
            fertilized = true
            minetest.swap_node(pos, {name = nodedef._fertile_name})
        elseif item_name == "stairs:slab_compost" then
            replace_with = ""
            fertilized = true
            minetest.swap_node(pos, {name = nodedef._fertile_name})
        end
    end
    if fertilized then
        inv:remove_item("main", item_name)
        inv:add_item("main", replace_with)
    end
end

-- Sediments
-----------------------------------
function sediment.get_dry_name(basename)
    local mod_name = minetest.get_current_modname()
    return mod_name..":"..basename
end

function sediment.get_wet_name(basename)
    return sediment.get_dry_name(basename).."_wet"
end

function sediment.get_wet_salty_name(basename)
    return sediment.get_wet_name(basename).."_salty"
end

function sediment.get_dry_texture_name(basename)
    local mod_name = minetest.get_current_modname()
    return mod_name.."_"..basename..".png"
end

function sediment.get_wet_texture_name(basename)
    local texture_name = sediment.get_dry_texture_name(basename)
    return texture_name.."^"..textures.wet
end

function sediment.get_wet_salty_texture_name(basename)
    local texture_name = sediment.get_wet_texture_name(basename)
    return texture_name.."^"..textures.salty
end

function sediment.new(args)
    local groups =
        {falling_node = 1, crumbly = args.hardness,
         sediment = args.id,
         rocky_substrate = args.rocky_substrate, -- inorganic matter content 0-4
         organic_substrate = args.organic_substrate, -- organic matter content 0-4
         fertility = args.fertility, -- values 0-4 (+ 2 for fertile soils)
         density = args.density, -- soil density (clay - dense, loam - not), values 0-4
        }
    local mod_name = minetest.get_current_modname() -- allows making artificial soils
    local sed = {
        name = args.name,
        description = args.description,
        hardness = args.hardness,
        id = args.id,
        texture_name = args.texture_name,
        sound = args.sound,
        sound_wet = args.sound_wet,
        groups = groups,
        groups_wet =
            merge_tables(groups, {wet_sediment = 1, puts_out_fire = 1}),
        groups_wet_salty =
            merge_tables(groups, {wet_sediment = 2, puts_out_fire = 1}),
        mod_name = mod_name,
    }
    return sed
end

function sediment.get_base_props(sed)
    local props = {
        stack_max = minimal.stack_max_bulky,
        _dry_name = sediment.get_dry_name(sed.name),
        _wet_name = sediment.get_wet_name(sed.name),
        _wet_salty_name = sediment.get_wet_salty_name(sed.name),
        use_texture_alpha = c_alpha.clip,
    }
    return props
end

function sediment.get_dry_node_props(sed)
    local props = {
        description = sed.description,
        tiles = {sediment.get_dry_texture_name(sed.name)},
        groups = sed.groups,
        drop = sediment.get_dry_name(sed.name),
        sounds = sed.sound,
    }
    return merge_tables(sediment.get_base_props(sed), props)
end

function sediment.register_dry(sed)
    local props = sediment.get_dry_node_props(sed)
    props = table.copy(props)
    props.groups.bare_sediment = 1
    minetest.register_node(sediment.get_dry_name(sed.name), props)
    table.insert(registered_sediments, sediment.get_dry_name(sed.name))
end

function sediment.get_wet_node_props(sed)
    local props = {
        description = S("Wet @1", sed.description),
        tiles = {sediment.get_wet_texture_name(sed.texture_name or sed.name)},
        groups = sed.groups_wet,
        drop = sediment.get_wet_name(sed.name),
        sounds = sed.sound_wet,
    }
    return merge_tables(sediment.get_base_props(sed), props)
end

function sediment.register_wet(sed)
    local props = sediment.get_wet_node_props(sed)
    props = table.copy(props)
    props.groups.bare_sediment = 1
    minetest.register_node(sediment.get_wet_name(sed.name), props)
    table.insert(registered_sediments, sediment.get_wet_name(sed.name))
end

function sediment.get_wet_salty_node_props(sed)
    local props = {
        description = S("Salty Wet @1", sed.description),
        tiles = {sediment.get_wet_salty_texture_name(sed.texture_name or sed.name)},
        groups = sed.groups_wet_salty,
        drop = sediment.get_wet_salty_name(sed.name),
        sounds = sed.sound_wet,
    }
    return merge_tables(sediment.get_base_props(sed), props)
end

function sediment.register_wet_salty(sed)
    local props = sediment.get_wet_salty_node_props(sed)
    minetest.register_node(sediment.get_wet_salty_name(sed.name), props)
end

function sediment.register_stair_and_slab(sed)
    stairs.register_stair_and_slab(
        sed.name,
        sediment.get_dry_name(sed.name),
	{"mixing_spot","soil_mixing"},
        "true",
	{"mixing_spot","soil_mixing"},
        {falling_node = 1, crumbly = sed.hardness},
        {sediment.get_dry_texture_name(sed.name)},
        sed.description.." Stair",
        sed.description.." Slab",
        minimal.stack_max_bulky * 2,
        sed.sound
    )
end

function sediment.register_slab(sed)
    stairs.register_slab(
        sed.name,
        sediment.get_dry_name(sed.name),
	{"mixing_spot","soil_mixing"},
        "true",
	{"mixing_spot","soil_mixing"},
        {falling_node = 1, crumbly = sed.hardness},
        {sediment.get_dry_texture_name(sed.name)},
        sed.description.." Slab",
        minimal.stack_max_bulky * 2,
        sed.sound
    )
end

function sediment.do_slopes(sed)
    local doslopes = minetest.settings:get_bool('exile_enableslopes')
    local slopechance = minetest.settings:get('exile_slopechance') or 20
    if doslopes then
        naturalslopeslib.register_slope(sediment.get_dry_name(sed.name), {}, slopechance)
        naturalslopeslib.register_slope(sediment.get_wet_name(sed.name), {}, slopechance)
        naturalslopeslib.register_slope(sediment.get_wet_salty_name(sed.name), {}, slopechance)
    end
end

-- Soils
-----------------------------------
soil = {}

soil.get_dry_name = sediment.get_dry_name
soil.get_wet_name = sediment.get_wet_name
soil.get_dry_texture_name = sediment.get_dry_texture_name
soil.get_wet_texture_name = sediment.get_wet_texture_name

function soil.get_winter_name(basename)
    local name = soil.get_dry_name(basename)
    return name.."_winter"
end

function soil.get_winter_wet_name(basename)
    local name = soil.get_dry_name(basename)
    return name.."_winter_wet"
end

function soil.get_side_texture_name(basename, sedname)
    return sediment.get_dry_texture_name(sedname).."^"..soil.get_dry_texture_name(basename.."_side")
end

function soil.get_wet_side_texture_name(basename, sedname)
    return soil.get_side_texture_name(basename, sedname).."^"..textures.wet
end

function soil.get_winter_texture_name(basename, sedname)
    return soil.get_dry_texture_name(basename).."^[colorize:#3b2914:150"
end

function soil.get_winter_side_texture_name(basename, sedname)
    return sediment.get_dry_texture_name(sedname).."^("..
        soil.get_dry_texture_name(basename.."_side").."^[colorize:#3b2914:150)"
end

function soil.get_winter_wet_texture_name(basename, sedname)
    return soil.get_winter_texture_name(basename, sedname).."^"..textures.wet
end

function soil.get_winter_wet_side_texture_name(basename, sedname)
    return soil.get_winter_side_texture_name(basename, sedname).."^"..textures.wet
end

function soil.new(args)
    local soil = {
        name = args.name,
        description = args.description,
        sediment = args.sediment,
    }
    return soil
end

--Till soil
function soil.till(itemstack, puncher, pointed_thing)
    --agriculture
    if pointed_thing.type ~= "node" then
        return
    end
    local under = minetest.get_node(pointed_thing.under)
    local p = {x=pointed_thing.under.x, y=pointed_thing.under.y+1, z=pointed_thing.under.z}
    local above = minetest.get_node(p)
    local node_name = under.name
    local nodedef = minetest.registered_nodes[node_name]
    if not nodedef then
        return
    end
    if not minetest.registered_nodes[above.name] then
        return
    end
    -- check if the node above the pointed thing is air
    if above.name ~= "air" then
        return
    end
    --living surface level sediment
    if minetest.get_item_group(node_name, "spreading") == 1 or
        minetest.get_item_group(node_name, "fertile_soil") then
        --figure out what soil it is from dropped
        local ag_soil = nodedef._ag_soil
        minimal.switch_node(pointed_thing.under, {name = ag_soil})
        local uses = itemstack:get_tool_capabilities().groupcaps.tilling.uses
        local player_inv = puncher:get_inventory()
        itemstack:add_wear(65535 / uses)
        puncher:set_wielded_item(itemstack)
    end
end

--Soil on_punch tilling
local function soil_on_punch(pos, node, puncher, pointed_thing)
    local itemstack = puncher.get_wielded_item(puncher)
    local tool_name = itemstack:get_name()
    if tool_name == "" then
        return
    end
    if not minetest.registered_tools[tool_name] then
        return
    end
    if minetest.registered_tools[tool_name].groups.hoe == 1 then
        local above = {x = pos.x, y = pos.y + 1, z = pos.z}
        local particle = dirt_particle(above, node.name)
        minetest.add_particlespawner(particle)
        -- minetest.sound_play("nodes_nature_dig_crumbly", {pos = pos, gain = 0.5})
        local punch_number = minetest.registered_tools[tool_name]._punch_number
        local timer = minetest.get_node_timer(pos)
        local meta = minetest.get_meta(pos)
        if not timer:is_started() then
            timer:start(10)
            meta:set_int("till_number", 1)
        else
            local till_number = meta:get_int("till_number")
            if till_number < punch_number - 1 then
                meta:set_int("till_number", till_number + 1)
            else
                meta:set_int("till_number", 0)
                soil.till(itemstack, puncher, pointed_thing)
            end
        end
    end
end

function soil.get_base_props(soil_desc)
    local sed = soil_desc.sediment
    local props = {
        _ag_soil = sed.ag_soil,
        _dry_name = soil.get_dry_name(soil_desc.name),
        _wet_name = soil.get_wet_name(soil_desc.name),
        on_punch = soil_on_punch,
    }
    return props
end

function soil.get_dry_node_props(soil_desc)
    local sed = soil_desc.sediment
    local props =
        merge_tables(
            sediment.get_dry_node_props(sed), {
                description = soil_desc.description,
                groups = merge_tables(sed.groups, {spreading = 1}),
                tiles = {soil.get_dry_texture_name(soil_desc.name),
                         sediment.get_dry_texture_name(sed.name),
                         {name = soil.get_side_texture_name(soil_desc.name, sed.name)}},
                _ag_soil = agricultural_soil.get_dry_name(sed.name),
                _winter_name = soil.get_winter_name(soil_desc.name),
        })
    return merge_tables(props, soil.get_base_props(soil_desc))
end

function soil.register_dry(soil_desc)
    minetest.register_node(soil.get_dry_name(soil_desc.name),
                           soil.get_dry_node_props(soil_desc))
    soil.do_slopes(soil.get_dry_name(soil_desc.name))
    table.insert(registered_sediments, soil.get_dry_name(soil_desc.name))
end

function soil.get_wet_node_props(soil_desc)
    local sed = soil_desc.sediment
    local props =
        merge_tables(
            sediment.get_wet_node_props(sed), {
                description = S("Wet @1", soil_desc.description),
                groups = merge_tables(sed.groups_wet, {spreading = 1}),
                tiles = {soil.get_wet_texture_name(soil_desc.name),
                         sediment.get_wet_texture_name(sed.name),
                         {name = soil.get_wet_side_texture_name(soil_desc.name, sed.name)}},
                _ag_soil = agricultural_soil.get_wet_name(sed.name),
                _winter_name = soil.get_winter_wet_name(soil_desc.name),
        })
    return merge_tables(props, soil.get_base_props(soil_desc))
end

function soil.register_wet(soil_desc)
    minetest.register_node(soil.get_wet_name(soil_desc.name),
                           soil.get_wet_node_props(soil_desc))
    soil.do_slopes(soil.get_wet_name(soil_desc.name))
    table.insert(registered_sediments, soil.get_wet_name(soil_desc.name))
end

function soil.get_winter_props(soil_desc)
    local sed = soil_desc.sediment
    local props = table.copy(soil.get_dry_node_props(soil_desc))
    props.description = S("Winter @1", soil_desc.description)
    props.groups.spreading = nil
    props.groups.winter_soil = 1
    props.tiles = {soil.get_winter_texture_name(soil_desc.name, sed.name),
                   sediment.get_dry_texture_name(sed.name),
                   {name = soil.get_winter_side_texture_name(soil_desc.name, sed.name)}}
    props._dry_name = soil.get_winter_name(soil_desc.name)
    props._wet_name = soil.get_winter_wet_name(soil_desc.name)
    props._non_winter_name = soil.get_dry_name(soil_desc.name)
    return props
end

function soil.register_winter(soil_desc)
    local props = soil.get_winter_props(soil_desc)
    minetest.register_node(soil.get_winter_name(soil_desc.name),
                           props)
    soil.do_slopes(soil.get_winter_name(soil_desc.name))
    table.insert(registered_sediments, soil.get_winter_name(soil_desc.name))
end

function soil.register_winter_wet(soil_desc)
    local props = table.copy(soil.get_winter_props(soil_desc))
    local sed = soil_desc.sediment
    props.description = S("Winter Wet @1", soil_desc.description)
    props.groups.spreading = nil
    props.groups.winter_soil = 1
    props.tiles = {soil.get_winter_wet_texture_name(soil_desc.name, sed.name),
                   sediment.get_wet_texture_name(sed.name),
                   {name = soil.get_winter_wet_side_texture_name(soil_desc.name, sed.name)}}
    props.sounds = sed.sound_wet
    props.drop = sediment.get_wet_name(sed.name)
    props._non_winter_name = soil.get_wet_name(soil_desc.name)
    minetest.register_node(soil.get_winter_wet_name(soil_desc.name),
                           props)
    soil.do_slopes(soil.get_winter_wet_name(soil_desc.name))
    table.insert(registered_sediments, soil.get_winter_wet_name(soil_desc.name))
end

function soil.do_slopes(node_name)
    local doslopes = minetest.settings:get_bool('exile_enableslopes')
    local slopechance = minetest.settings:get('exile_slopechance') or 20
    if doslopes then
        naturalslopeslib.register_slope(node_name, {}, slopechance)
    end
end

-- Fertile soil mixes
-----------------------------------
fertile_soil = {}

function fertile_soil.get_dry_name(basename)
    return sediment.get_dry_name(basename).."_fertile_soil"
end

function fertile_soil.get_wet_name(basename)
    return fertile_soil.get_dry_name(basename).."_wet"
end

function fertile_soil.get_wet_salty_name(basename)
    return fertile_soil.get_wet_name(basename).."_salty"
end

function fertile_soil.get_dry_texture_name(basename)
    return sediment.get_dry_texture_name(basename).."^"..textures.fertile_soil
end

function fertile_soil.get_wet_texture_name(basename)
    return fertile_soil.get_dry_texture_name(basename).."^"..textures.wet
end

function fertile_soil.get_wet_salty_texture_name(basename)
    return fertile_soil.get_wet_texture_name(basename).."^"..textures.salty
end

function fertile_soil.new(args)
    local soil_desc = {
        name = args.sediment.name.."_fertile_soil",
        description = args.description,
        sediment = args.sediment,
    }
    return soil_desc
end

function fertile_soil.get_base_props(soil_desc)
    local sed = soil_desc.sediment
    local props = {
        _dry_name = fertile_soil.get_dry_name(sed.name),
        _wet_name = fertile_soil.get_wet_name(sed.name),
        _wet_salty_name = fertile_soil.get_wet_salty_name(sed.name),
        on_punch = soil_on_punch,
    }
    return props
end

function fertile_soil.get_dry_node_props(soil_desc)
    local sed = soil_desc.sediment
    local name = fertile_soil.get_dry_name(sed.name)
    local props =
        merge_tables(
            sediment.get_dry_node_props(sed), {
                description = soil_desc.description,
                tiles = {fertile_soil.get_dry_texture_name(sed.name)},
                groups = merge_tables(sed.groups,
                                      {fertile_soil = 1,
                                       fertility = sed.groups.fertility + 2}),
                drop = fertile_soil.get_dry_name(sed.name),
                _depleted_name = agricultural_soil.get_dry_name(sed.name),
                _ag_soil = agricultural_soil.get_dry_name(sed.name.."_fertile_soil"),
        })
    return merge_tables(props, fertile_soil.get_base_props(soil_desc))
end

function fertile_soil.register_dry(soil_desc)
    minetest.register_node(fertile_soil.get_dry_name(soil_desc.sediment.name),
                           fertile_soil.get_dry_node_props(soil_desc))
    table.insert(registered_sediments, fertile_soil.get_dry_name(soil_desc.sediment.name))
end

function fertile_soil.get_wet_node_props(soil_desc)
    local sed = soil_desc.sediment
    local name = fertile_soil.get_wet_name(sed.name)
    local props =
        merge_tables(
            sediment.get_wet_node_props(sed), {
                description = S("Wet @1", soil_desc.description),
                tiles = {fertile_soil.get_wet_texture_name(sed.name)},
                groups = merge_tables(sed.groups_wet,
                                      {fertile_soil = 1,
                                       fertility = sed.groups.fertility + 2}),
                drop = fertile_soil.get_wet_name(sed.name),
                _depleted_name = agricultural_soil.get_wet_name(sed.name),
                _ag_soil = agricultural_soil.get_wet_name(sed.name.."_fertile_soil"),
        })
    return merge_tables(props, fertile_soil.get_base_props(soil_desc))
end

function fertile_soil.register_wet(soil_desc)
    minetest.register_node(fertile_soil.get_wet_name(soil_desc.sediment.name),
                           fertile_soil.get_wet_node_props(soil_desc))
    table.insert(registered_sediments, fertile_soil.get_wet_name(soil_desc.sediment.name))
end

function fertile_soil.register_crafting_recipe_dry(soil_desc)
    local sed = soil_desc.sediment
    crafting.register_recipe({
            type = "shovel_agriculture",
            output = fertile_soil.get_dry_name(sed.name).." 2",
            items = {sediment.get_dry_name(sed.name),
                     "nodes_nature:compost"},
            level = 1,
            always_known = true,
    })
    crafting.register_recipe({
            type = "shovel_agriculture",
            output = fertile_soil.get_dry_name(sed.name),
            items = {sediment.get_dry_name(sed.name),
                     "stairs:slab_compost"},
            level = 1,
            always_known = true,
    })
end

function fertile_soil.register_crafting_recipe_wet(soil_desc)
    local sed = soil_desc.sediment
    crafting.register_recipe({
            type = "shovel_agriculture",
            output = fertile_soil.get_wet_name(sed.name),
            items = {sediment.get_wet_name(sed.name),
                     "stairs:slab_compost"},
            level = 1,
            always_known = true,
    })
    crafting.register_recipe({
            type = "shovel_agriculture",
            output = fertile_soil.get_wet_name(sed.name).." 2",
            items = {sediment.get_wet_name(sed.name),
                     "nodes_nature:compost"},
            level = 1,
            always_known = true,
    })
end

function fertile_soil.do_slopes(soil_desc)
    local doslopes = minetest.settings:get_bool('exile_enableslopes')
    local slopechance = minetest.settings:get('exile_slopechance') or 20
    if doslopes then
        naturalslopeslib.register_slope(
            fertile_soil.get_dry_name(soil_desc.sediment.name), {}, slopechance)
        naturalslopeslib.register_slope(
            fertile_soil.get_wet_name(soil_desc.sediment.name), {}, slopechance)
    end
end

-- Agricultural soils
-----------------------------------
agricultural_soil = {}

function agricultural_soil.get_dry_name(basename)
    return sediment.get_dry_name(basename.."_agricultural_soil")
end

function agricultural_soil.get_wet_name(basename)
    return agricultural_soil.get_dry_name(basename).."_wet"
end

function agricultural_soil.get_dry_depleted_name(basename)
    return agricultural_soil.get_dry_name(basename).."_depleted"
end

function agricultural_soil.get_wet_depleted_name(basename)
    return agricultural_soil.get_wet_name(basename).."_depleted"
end

function agricultural_soil.get_base_texture_name(sedname, texture_name)
    local base_texture = sediment.get_dry_texture_name(sedname)
    if texture_name then
        base_texture = texture_name
    end
    return "[combine:32x32:0,0="
        .."("..base_texture..")"..":0,16="
        .."("..base_texture..")"..":16,0="
        .."("..base_texture..")"
end

function agricultural_soil.get_dry_texture_name(sedname, texture_name)
    return
        agricultural_soil.get_base_texture_name(sedname, texture_name)..
        "^"..textures.tilled_soil
end

function agricultural_soil.get_wet_texture_name(sedname, texture_name)
    return
        agricultural_soil.get_dry_texture_name(sedname, texture_name)..
        "^"..textures.wet
end

function agricultural_soil.get_dry_depleted_texture_name(sedname, texture_name)
    return
        agricultural_soil.get_base_texture_name(sedname, texture_name)..
        "^"..textures.tilled_soil_depleted
end

function agricultural_soil.get_wet_depleted_texture_name(sedname, texture_name)
    return
        agricultural_soil.get_dry_depleted_texture_name(sedname, texture_name)..
        "^"..textures.wet
end

function agricultural_soil.new(args)
    if args.depleted_name then
        args.depleted_name_wet = args.depleted_name.."_wet"
    end
    local ag_soil = {
        name = args.name,
        depleted_name = args.depleted_name,
        depleted_name_wet = args.depleted_name_wet,
        description = args.description,
        sediment = args.sediment,
        texture_name = args.texture_name,
    }
    return ag_soil
end

function agricultural_soil.get_base_props(ag_soil)
    local props = {
        drawtype = "mesh",
        mesh = "nodes_nature_tilled_soil.obj",
        paramtype = "light",
        _dry_name = agricultural_soil.get_dry_name(ag_soil.name),
        _wet_name = agricultural_soil.get_wet_name(ag_soil.name),
        _wet_salty_name = sediment.get_wet_salty_name(ag_soil.sediment.name),
        on_construct = function(pos)
            --speed of erosion, degrade to depleted
            minetest.get_node_timer(pos):start(math.random(90, 300))
        end,
    }
    return props
end

function agricultural_soil.get_dry_node_props(ag_soil)
    local sed = ag_soil.sediment
    local depleted_name = ag_soil.depleted_name or
        agricultural_soil.get_dry_depleted_name(sed.name)
    local props =
        merge_tables(
            sediment.get_dry_node_props(sed), {
                description = ag_soil.description,
                groups = merge_tables(sed.groups, {agricultural_soil = 1}),
                tiles = {
                    agricultural_soil.get_dry_texture_name(sed.name, ag_soil.texture_name)},
                _depleted_name = depleted_name,
                _fertile_name = agricultural_soil.get_dry_name(sed.name.."_fertile_soil"),
                on_timer = function(pos, elapsed)
                    return erode_deplete_ag_soil(pos)
                end,
                on_punch = function(pos, node, puncher, pointed_thing)
                    fertilize_ag_soil(pos, puncher)
                end,
        })
    return merge_tables(props, agricultural_soil.get_base_props(ag_soil))
end

function agricultural_soil.register_dry(ag_soil)
    local name = ag_soil.name
    minetest.register_node(agricultural_soil.get_dry_name(name),
                           agricultural_soil.get_dry_node_props(ag_soil))
    table.insert(registered_sediments, agricultural_soil.get_dry_name(name))
end

function agricultural_soil.get_wet_node_props(ag_soil)
    local sed = ag_soil.sediment
    local depleted_name = ag_soil.depleted_name_wet or
        agricultural_soil.get_wet_depleted_name(sed.name)
    local props =
        merge_tables(
            sediment.get_wet_node_props(sed), {
                description = S("Wet @1", ag_soil.description),
                groups = merge_tables(sed.groups_wet, {agricultural_soil = 1}),
                tiles =
                    {agricultural_soil.get_wet_texture_name(sed.name, ag_soil.texture_name)},
                _depleted_name = depleted_name,
                _fertile_name = agricultural_soil.get_wet_name(sed.name.."_fertile_soil"),
                on_timer = function(pos, elapsed)
                    return erode_deplete_ag_soil(pos)
                end,
                on_punch = function(pos, node, puncher, pointed_thing)
                    fertilize_ag_soil(pos, puncher)
                end,
        })
    return merge_tables(props, agricultural_soil.get_base_props(ag_soil))
end

function agricultural_soil.register_wet(ag_soil)
    local name = ag_soil.name
    minetest.register_node(agricultural_soil.get_wet_name(name),
                           agricultural_soil.get_wet_node_props(ag_soil))
    table.insert(registered_sediments, agricultural_soil.get_wet_name(name))
end

function agricultural_soil.get_dry_depleted_node_props(ag_soil)
    local sed = ag_soil.sediment
    local props =
        merge_tables(
            sediment.get_dry_node_props(sed), {
                description = S("Depleted @1", ag_soil.description),
                groups = merge_tables(sed.groups, {depleted_agricultural_soil = 1}),
                _rich_name = agricultural_soil.get_dry_name(sed.name),
                _fertile_name = agricultural_soil.get_dry_name(sed.name.."_fertile_soil"),
                tiles =
                    {agricultural_soil.get_dry_depleted_texture_name(sed.name, ag_soil.texture_name)},
                on_punch = function(pos, node, puncher, pointed_thing)
                    fertilize_ag_soil(pos, puncher)
                end,
        })
    return merge_tables(props, agricultural_soil.get_base_props(ag_soil))
end

function agricultural_soil.register_depleted(ag_soil)
    local name = ag_soil.name
    minetest.register_node(agricultural_soil.get_dry_depleted_name(name),
                           agricultural_soil.get_dry_depleted_node_props(ag_soil))
    table.insert(registered_sediments, agricultural_soil.get_dry_depleted_name(name))
end

function agricultural_soil.get_wet_depleted_node_props(ag_soil)
    local sed = ag_soil.sediment
    local props =
        merge_tables(
            sediment.get_wet_node_props(sed), {
                description = S("Wet Depleted @1", ag_soil.description),
                groups = merge_tables(sed.groups_wet, {depleted_agricultural_soil = 1}),
                _rich_name = agricultural_soil.get_wet_name(sed.name),
                _fertile_name = agricultural_soil.get_wet_name(sed.name.."_fertile_soil"),
                tiles =
                    {agricultural_soil.get_wet_depleted_texture_name(sed.name, ag_soil.texture_name)},
                on_punch = function(pos, node, puncher, pointed_thing)
                    fertilize_ag_soil(pos, puncher)
                end,
        })
    return merge_tables(props, agricultural_soil.get_base_props(ag_soil))
end

function agricultural_soil.register_wet_depleted(ag_soil)
    local name = ag_soil.name
    minetest.register_node(agricultural_soil.get_wet_depleted_name(name),
                           agricultural_soil.get_wet_depleted_node_props(ag_soil))
    table.insert(registered_sediments, agricultural_soil.get_wet_depleted_name(name))
end

-- Registers sediments, their slabs, wet, salty, slopes etc. and crafting recipes
function sediment.register_sed_variants(sed)
    sediment.register_dry(sed)
    sediment.register_wet(sed)
    sediment.register_wet_salty(sed)
    sediment.register_stair_and_slab(sed)
    sediment.do_slopes(sed)
end

-- Registers agricultural soils and their variants
-- (dry, wet, depleted) and recipes to craft them
function agricultural_soil.register_all_variants(agri)
    agricultural_soil.register_dry(agri)
    agricultural_soil.register_wet(agri)
    if not agri.depleted_name then
        agricultural_soil.register_depleted(agri)
        agricultural_soil.register_wet_depleted(agri)
    end
end

function fertile_soil.register_all_variants(fs)
    fertile_soil.register_dry(fs)
    fertile_soil.register_wet(fs)
    fertile_soil.register_crafting_recipe_dry(fs)
    fertile_soil.register_crafting_recipe_wet(fs)
    fertile_soil.do_slopes(fs)
end

-- Registers soils with "grasses" and their variants including slopes
function sediment.register_soil_variants(soil_list)
    for _, s in ipairs(soil_list) do
        soil.register_dry(s)
        soil.register_wet(s)
        soil.register_winter(s)
        soil.register_winter_wet(s)
    end
end

-- Registers sediments, their variants (slabs, wet, salty, etc.) and agricultural soils
-- including crafting recipes
function sediment.register_all_sed_derivatives(sed_list)
    for _, sed in pairs(sed_list) do
        local agri =
            agricultural_soil.new(
                {name = sed.name,
                 description = S("@1 Agricultural Soil", sed.description),
                 sediment = sed
            })
        local fs =
            fertile_soil.new(
                {name = sed.name,
                 description = S("@1 Fertile Soil", sed.description),
                 sediment = sed
            })
        local agri_fs =
            agricultural_soil.new(
                {name = fs.name,
                 description = S("@1 Fertile Agricultural Soil", sed.description),
                 sediment = sed,
                 texture_name = fertile_soil.get_dry_texture_name(sed.name),
                 depleted_name = agricultural_soil.get_dry_name(sed.name),
            })
        sediment.register_sed_variants(sed)
        agricultural_soil.register_all_variants(agri)
        fertile_soil.register_all_variants(fs)
        agricultural_soil.register_all_variants(agri_fs)
    end
end
