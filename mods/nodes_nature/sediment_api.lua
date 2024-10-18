---------------------------------------------------------
--SEDIMENT "API"
--
----------------------------------------------------------

-- Internationalization
local S = nodes_nature.S

mapchunk_shepherd = mapchunk_shepherd
local ms = mapchunk_shepherd

local c_alpha = minimal.compat_alpha
local c = nodes_nature.replacement_types
tgcr = tgcr
nodes_nature = nodes_nature
local nn = nodes_nature

nn.sediment = {}
local sediment = nn.sediment
nn.registered_sediments = {}
local registered_sediments = nn.registered_sediments

nn.soil = {}
local soil = nn.soil

local do_slopes_for_node_name
do
    local doslopes = minetest.settings:get_bool('exile_enableslopes')
    local slopechance = minetest.settings:get('exile_slopechance') or 20
    if doslopes then
        do_slopes_for_node_name = function(node_name)
            naturalslopeslib.register_slope(node_name, {}, slopechance)
        end
    else
        do_slopes_for_node_name = function(node_name) end
    end
end

-- Useful objects for node definitions
sediment.hardness = {
    soft = 3,
    medium = 2,
    hard = 1,
}

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

-- Utility functions
-----------------------------------

local merge_tables = minimal.merge_tables

-- the next two lines cannot be merged into "local defer_tgcr = {", because
-- defer_tgcr.perform_deferred_registration would not see the defer_tgcr local
-- variable
local defer_tgcr
defer_tgcr = {
    data = {},
    register_replacement = function(source_node_name, target_node_name,
                                    replacement_kind, activation_source_name)
        defer_tgcr.data[1+#defer_tgcr.data] = function()
            tgcr.register_replacement(source_node_name, target_node_name,
                                      replacement_kind, activation_source_name)
        end
    end,
    perform_deferred_registration = function()
        for _, f in ipairs(defer_tgcr.data) do
            f()
        end
    end,
}



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
            if minetest.registered_nodes[new] then
                minetest.swap_node(pos, {name = new})
            end
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
         density = args.density,
         -- soil density (clay - dense, loam - not), values 0-4
        }
    -- added support for the sediment data table containing groups.
    if args.groups ~= nil then
        groups = merge_tables(groups, args.groups)
    end
    local mod_name = minetest.get_current_modname()
    -- allows making artificial soils
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
        after_place_node = function(pos, placer, itemstack, pointed_thing)
            if pos.y < -15 then
                -- No labels when underground
                return
            end
            local labels = {}
            local remove_labels = {"no_soil"}
            if minimal.pos_group(pos, "spreading") then
                table.insert(labels, "spring_soil")
                table.insert(remove_labels, "no_spring_soil")
                table.insert(remove_labels, "bare_soil")
            elseif minimal.pos_group(pos, "winter_soil") then
                table.insert(labels, "winter_soil")
                table.insert(remove_labels, "no_winter_soil")
                table.insert(remove_labels, "bare_soil")
            else
                table.insert(labels, "bare_soil")
            end
            ms.labels_to_position(pos, labels, remove_labels)
        end,
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
    props.groups.dry_sediment = 1
    return merge_tables(sediment.get_base_props(sed), props)
end

function sediment.register_dry(sed)
    local props = sediment.get_dry_node_props(sed)
    props = table.copy(props)
    props.groups.bare_sediment = 1
    local dry_name = sediment.get_dry_name(sed.name)
    minetest.register_node(dry_name, props)
    sediment.do_slopes(dry_name)
    defer_tgcr.register_replacement(dry_name,
                                    sediment.get_wet_name(sed.name),
                                    c.REPLACEMENT_WET)
    defer_tgcr.register_replacement(dry_name,
                                    sediment.get_wet_salty_name(sed.name),
                                    c.REPLACEMENT_SALTY)
    table.insert(registered_sediments, dry_name)
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
    local wet_name = sediment.get_wet_name(sed.name)
    minetest.register_node(wet_name, props)
    sediment.do_slopes(wet_name)
    defer_tgcr.register_replacement(wet_name,
                                    sediment.get_dry_name(sed.name),
                                    c.REPLACEMENT_DRY)
    table.insert(registered_sediments, wet_name)
end

function sediment.get_wet_salty_node_props(sed)
    local props = {
        description = S("Salty Wet @1", sed.description),
        tiles = {sediment.get_wet_salty_texture_name(sed.texture_name
                                                     or sed.name)},
        groups = sed.groups_wet_salty,
        drop = sediment.get_wet_salty_name(sed.name),
        sounds = sed.sound_wet,
    }
    return merge_tables(sediment.get_base_props(sed), props)
end

function sediment.register_wet_salty(sed)
    local props = sediment.get_wet_salty_node_props(sed)
    local wet_salty_name = sediment.get_wet_salty_name(sed.name)
    minetest.register_node(wet_salty_name, props)
    sediment.do_slopes(wet_salty_name)
    defer_tgcr.register_replacement(wet_salty_name,
                                    sediment.get_dry_name(sed.name),
                                    c.REPLACEMENT_DRY)
    --table.insert(registered_sediments, wet_salty_name) -- #TODO: FIXME?
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
        S("@1 Stair", sed.description),
        S("@1 Slab", sed.description),
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
        sed.groups,
        {sediment.get_dry_texture_name(sed.name)},
        S("@1 Slab", sed.description),
        minimal.stack_max_bulky * 2,
        sed.sound
    )
end

sediment.do_slopes = do_slopes_for_node_name

-- Soils
-----------------------------------

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
    return sediment.get_dry_texture_name(sedname)..
        "^"..soil.get_dry_texture_name(basename.."_side")
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
    return soil.get_winter_side_texture_name(basename, sedname)..
        "^"..textures.wet
end

function soil.new(args)
    local newsoil = {
        name = args.name,
        description = args.description,
        sediment = args.sediment,
    }
    return newsoil
end

--Till soil
function soil.till(itemstack, puncher, pointed_thing)
    --agriculture
    if pointed_thing.type ~= "node" then
        return
    end
    local under = minetest.get_node(pointed_thing.under)
    local node_name = under.name
    local nodedef = minetest.registered_nodes[node_name]
    if not nodedef then
        return
    end
    --living surface level sediment
    if minetest.get_item_group(node_name, "spreading") == 1 or
        minetest.get_item_group(node_name, "fertile_soil") >= 1 then
        --figure out what soil it is from dropped
        local ag_soil = nodedef._ag_soil
        minimal.switch_node(pointed_thing.under, {name = ag_soil})
    end
end

function soil.get_base_props(soil_desc)
    local sed = soil_desc.sediment
    local props = {
        _ag_soil = sed.ag_soil,
        _dry_name = soil.get_dry_name(soil_desc.name),
        _wet_name = soil.get_wet_name(soil_desc.name),
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
                         {name = soil.get_side_texture_name(soil_desc.name,
                                                            sed.name)}},
                _ag_soil = agricultural_soil.get_dry_name(sed.name),
                _winter_name = soil.get_winter_name(soil_desc.name),
        })
    return merge_tables(props, soil.get_base_props(soil_desc))
end

function soil.register_dry(soil_desc)
    local dry_name = soil.get_dry_name(soil_desc.name)
    minetest.register_node(dry_name, soil.get_dry_node_props(soil_desc))
    soil.do_slopes(dry_name)
    defer_tgcr.register_replacement(dry_name,
                                    soil.get_wet_name(soil_desc.name),
                                    c.REPLACEMENT_WET)
    defer_tgcr.register_replacement(dry_name,
                                    sediment.get_wet_salty_name(
                                        soil_desc.sediment.name),
                                    c.REPLACEMENT_SALTY)
    table.insert(registered_sediments, dry_name)
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
                         {name = soil.get_wet_side_texture_name(soil_desc.name,
                                                                sed.name)}},
                _ag_soil = agricultural_soil.get_wet_name(sed.name),
                _winter_name = soil.get_winter_wet_name(soil_desc.name),
        })
    return merge_tables(props, soil.get_base_props(soil_desc))
end

function soil.register_wet(soil_desc)
    local wet_name = soil.get_wet_name(soil_desc.name)
    minetest.register_node(wet_name, soil.get_wet_node_props(soil_desc))
    soil.do_slopes(wet_name)
    defer_tgcr.register_replacement(wet_name,
                                    soil.get_dry_name(soil_desc.name),
                                    c.REPLACEMENT_DRY)
    table.insert(registered_sediments, wet_name)
end

function soil.get_winter_props(soil_desc)
    local sed = soil_desc.sediment
    local props = table.copy(soil.get_dry_node_props(soil_desc))
    props.description = S("Frosty Winter @1", soil_desc.description)
    props.groups.spreading = nil
    props.groups.winter_soil = 1
    if props.groups.sediment == 2 then -- clay
        props.groups.crumbly = nil
        props.groups.cracky = 2
    else -- sand, gravel, silt
        if props.groups.crumbly then
            props.groups.crumbly = 1
        end
        props.groups.cracky = 3
    end
    props.tiles = {soil.get_winter_texture_name(soil_desc.name, sed.name),
                   sediment.get_dry_texture_name(sed.name),
                   {name = soil.get_winter_side_texture_name(soil_desc.name,
                                                             sed.name)}}
    props._dry_name = soil.get_winter_name(soil_desc.name)
    props._wet_name = soil.get_winter_wet_name(soil_desc.name)
    props._non_winter_name = soil.get_dry_name(soil_desc.name)
    return props
end

function soil.register_winter(soil_desc)
    local winter_name = soil.get_winter_name(soil_desc.name)
    local props = soil.get_winter_props(soil_desc)
    props.sounds = nodes_nature.node_sound_grassysnow_defaults()
    minetest.register_node(winter_name, props)
    soil.do_slopes(winter_name)
    local winter_wet_name = soil.get_winter_wet_name(soil_desc.name)
    defer_tgcr.register_replacement(winter_name,
                                    winter_wet_name,
                                    c.REPLACEMENT_WET)
    defer_tgcr.register_replacement(winter_name,
                                    sediment.get_wet_salty_name(
                                        soil_desc.sediment.name),
                                    c.REPLACEMENT_SALTY)
    table.insert(registered_sediments, winter_name)
end

function soil.register_winter_wet(soil_desc)
    local winter_wet_name = soil.get_winter_wet_name(soil_desc.name)
    local props = table.copy(soil.get_winter_props(soil_desc))
    local sed = soil_desc.sediment
    props.description = S("Frosty Winter Wet @1", soil_desc.description)
    props.groups.spreading = nil
    props.groups.winter_soil = 1
    props.tiles = {
        soil.get_winter_wet_texture_name(soil_desc.name, sed.name),
        sediment.get_wet_texture_name(sed.name),
        {name = soil.get_winter_wet_side_texture_name(soil_desc.name, sed.name)}
    }
    props.sounds = nodes_nature.node_sound_grassysnow_defaults()--sed.sound_wet
    props.drop = sediment.get_wet_name(sed.name)
    props._non_winter_name = soil.get_wet_name(soil_desc.name)
    minetest.register_node(winter_wet_name, props)
    soil.do_slopes(winter_wet_name)
    defer_tgcr.register_replacement(winter_wet_name,
                                    soil.get_winter_name(soil_desc.name),
                                    c.REPLACEMENT_DRY)
    table.insert(registered_sediments, winter_wet_name)
end

soil.do_slopes = do_slopes_for_node_name

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
        _wet_salty_name = sediment.get_wet_salty_name(sed.name),
    }
    return props
end

function fertile_soil.get_dry_node_props(soil_desc)
    local sed = soil_desc.sediment
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
                _ag_soil = agricultural_soil.get_dry_name(sed.name..
                                                          "_fertile_soil"),
        })
    return merge_tables(props, fertile_soil.get_base_props(soil_desc))
end

function fertile_soil.register_dry(soil_desc)
    local dry_name = fertile_soil.get_dry_name(soil_desc.sediment.name)
    minetest.register_node(dry_name, fertile_soil.get_dry_node_props(soil_desc))
    fertile_soil.do_slopes(dry_name)
    defer_tgcr.register_replacement(dry_name,
                                    fertile_soil.get_wet_name(
                                        soil_desc.sediment.name),
                                    c.REPLACEMENT_WET)
    defer_tgcr.register_replacement(dry_name,
                                    sediment.get_wet_salty_name(
                                        soil_desc.sediment.name),
                                    c.REPLACEMENT_SALTY)
    table.insert(registered_sediments, dry_name)
end

function fertile_soil.get_wet_node_props(soil_desc)
    local sed = soil_desc.sediment
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
                _ag_soil = agricultural_soil.get_wet_name(sed.name..
                                                          "_fertile_soil"),
        })
    return merge_tables(props, fertile_soil.get_base_props(soil_desc))
end

function fertile_soil.register_wet(soil_desc)
    local wet_name = fertile_soil.get_wet_name(soil_desc.sediment.name)
    minetest.register_node(wet_name, fertile_soil.get_wet_node_props(soil_desc))
    fertile_soil.do_slopes(wet_name)
    defer_tgcr.register_replacement(wet_name,
                                    fertile_soil.get_dry_name(
                                        soil_desc.sediment.name),
                                    c.REPLACEMENT_DRY)
    table.insert(registered_sediments, wet_name)
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

fertile_soil.do_slopes = do_slopes_for_node_name

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
                    agricultural_soil.get_dry_texture_name(sed.name,
                                                           ag_soil.texture_name)},
                _depleted_name = depleted_name,
                _fertile_name = agricultural_soil.get_dry_name(sed.name..
                                                               "_fertile_soil"),
                on_timer = function(pos, elapsed)
                    return erode_deplete_ag_soil(pos)
                end,
        })
    return merge_tables(props, agricultural_soil.get_base_props(ag_soil))
end

function agricultural_soil.register_dry(ag_soil)
    local name = ag_soil.name
    local dry_name = agricultural_soil.get_dry_name(name)
    minetest.register_node(dry_name,
                           agricultural_soil.get_dry_node_props(ag_soil))
    defer_tgcr.register_replacement(dry_name,
                                    agricultural_soil.get_wet_name(name),
                                    c.REPLACEMENT_WET)
    defer_tgcr.register_replacement(dry_name,
                                    sediment.get_wet_salty_name(
                                        ag_soil.sediment.name),
                                    c.REPLACEMENT_SALTY)
    table.insert(registered_sediments, dry_name)
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
                    {agricultural_soil.get_wet_texture_name(sed.name,
                                                            ag_soil.texture_name)},
                _depleted_name = depleted_name,
                _fertile_name = agricultural_soil.get_wet_name(sed.name..
                                                               "_fertile_soil"),
                on_timer = function(pos, elapsed)
                    return erode_deplete_ag_soil(pos)
                end,
        })
    return merge_tables(props, agricultural_soil.get_base_props(ag_soil))
end

function agricultural_soil.register_wet(ag_soil)
    local name = ag_soil.name
    local wet_name = agricultural_soil.get_wet_name(name)
    minetest.register_node(wet_name,
                           agricultural_soil.get_wet_node_props(ag_soil))
    defer_tgcr.register_replacement(wet_name,
                                    agricultural_soil.get_dry_name(name),
                                    c.REPLACEMENT_DRY)
    table.insert(registered_sediments, wet_name)
end

function agricultural_soil.get_dry_depleted_node_props(ag_soil)
    local sed = ag_soil.sediment
    local props =
        merge_tables(
            sediment.get_dry_node_props(sed), {
                description = S("Depleted @1", ag_soil.description),
                groups = merge_tables(sed.groups,
                                      {depleted_agricultural_soil = 1}),
                _rich_name = agricultural_soil.get_dry_name(sed.name),
                _fertile_name = agricultural_soil.get_dry_name(sed.name..
                                                               "_fertile_soil"),
                tiles =
                    {agricultural_soil.get_dry_depleted_texture_name(
                         sed.name, ag_soil.texture_name)},
        })
    return merge_tables(props, agricultural_soil.get_base_props(ag_soil))
end

function agricultural_soil.register_depleted(ag_soil)
    local name = ag_soil.name
    local depleted_name = agricultural_soil.get_dry_depleted_name(name)
    minetest.register_node(depleted_name,
                           agricultural_soil.get_dry_depleted_node_props(
                               ag_soil))
    defer_tgcr.register_replacement(depleted_name,
                                    agricultural_soil.get_wet_depleted_name(
                                        name),
                                    c.REPLACEMENT_WET)
    defer_tgcr.register_replacement(depleted_name,
                                    sediment.get_wet_salty_name(
                                        ag_soil.sediment.name),
                                    c.REPLACEMENT_SALTY)
    table.insert(registered_sediments, depleted_name)
end

function agricultural_soil.get_wet_depleted_node_props(ag_soil)
    local sed = ag_soil.sediment
    local props =
        merge_tables(
            sediment.get_wet_node_props(sed), {
                description = S("Wet Depleted @1", ag_soil.description),
                groups = merge_tables(sed.groups_wet,
                                      {depleted_agricultural_soil = 1}),
                _rich_name = agricultural_soil.get_wet_name(sed.name),
                _fertile_name = agricultural_soil.get_wet_name(sed.name..
                                                               "_fertile_soil"),
                tiles =
                    {agricultural_soil.get_wet_depleted_texture_name(
                         sed.name, ag_soil.texture_name)},
        })
    return merge_tables(props, agricultural_soil.get_base_props(ag_soil))
end

function agricultural_soil.register_wet_depleted(ag_soil)
    local name = ag_soil.name
    local wet_depleted_name = agricultural_soil.get_wet_depleted_name(name)
    minetest.register_node(wet_depleted_name,
                           agricultural_soil.get_wet_depleted_node_props(
                               ag_soil))
    defer_tgcr.register_replacement(wet_depleted_name,
                                    agricultural_soil.get_dry_depleted_name(
                                        name),
                                    c.REPLACEMENT_DRY)
    table.insert(registered_sediments, wet_depleted_name)
end

-- Registers sediments, their slabs, wet, salty, slopes etc. and crafting recipes
function sediment.register_sed_variants(sed)
    sediment.register_dry(sed)
    sediment.register_wet(sed)
    sediment.register_wet_salty(sed)
    sediment.register_stair_and_slab(sed)
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
                 description = S("@1 Fertile Agricultural Soil",
                                 sed.description),
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

minetest.register_on_mods_loaded(function()
        defer_tgcr.perform_deferred_registration()
end)

-- vim: set ts=4 sw=4 :

--- TPH REVISION

sediment2 = {
    registered_sediments = {}
}

local function soil_modify_tiles(tiles, texture)
    -- modify tiles accordingly
    for i, tile in pairs(tiles) do
        -- account for a tile that is actually a table, check name
        if type(tile) == "table" and tile.name then
            tile.name = tile.name"^"..texture
        -- just a regular string, continue as normal
        elseif type(tile) == "string" then
            tiles[i] = tile.."^"..texture
        end
    end
end

-- get properties according to provided dry, wet, and wet_salty tables, return all 3 inside of a table
-- dry table is required, wet and wet_salty tables are not required
-- if wet or wet_salty tables are defined as false, will not create them
-- returns a table of property tables under the indexes of "dry", "wet", and "wet_salty"
-- defaults to silt soil properties if not provided or lackluster
-- provides predicted soil type according to soil properties (nn_soil_type)
-- following properties are used for calculation: density and rocky_substrate
-- automatically gets sounds according to predicted soil type if sounds aren't provided
function sediment2.create_soil_props(dry, wet, wet_salty)
    assert(type(dry) == "table","sediment.create_soil: no base dry sediment table provided")
    assert(type(dry.name) == "string","sediment.create_soil: no name provided for dry sediment (specify in table)")
    -- props of dry
    -- groups
    local groups = dry.groups or {}
    groups.falling_node = 1
    groups.bare_sediment = 1 -- no grass, we're bare!
    -- silt basics (if not provided)
    groups.crumbly = groups.crumbly or 3 -- softness, 3 is very soft, 2 is clay-soft, 1 is... idk we don't have a soil for that yet
    -- inorganic matter content 0-4
    groups.rocky_substrate = groups.rocky_substrate or 1
    -- organic matter content 0-4
    groups.organic_substrate = groups.organic_substrate or 3
    -- values 0-4 (+ 2 for fertile soils)
    groups.fertility = groups.fertility or 3
    -- soil density (clay - dense, loam - not), values 0-4 
    groups.density = groups.density or 3
    -- set groups
    dry.groups = groups
    -- provide "soil_like" for what type of sounds to get
    local soil_like = groups.rocky_substrate > 3 and (groups.density > 2 and "gravel" or "sand") or
        groups.rocky_substrate > 1 and groups.density > 3 and groups.crumbly < 3 and "clay" or "silt"
    dry.nn_soil_like = soil_like
    -- set up mod_origin and name using mod_origin
    dry.mod_origin = minetest.get_current_modname()
    dry.name = dry.name:sub(1,1) == ":" and dry.mod_origin..dry.name or
        (not dry.name:match(":")) and dry.mod_origin..":"..dry.name or dry.name
    -- other params
    dry.description = dry.description or dry.name -- you wanna be silly and not provide description, we'll get silly
    dry.stack_max = dry.stack_max or minimal.stack_max_bulky
    dry.drawtype = dry.drawtype or "normal"
    dry.tiles = type(dry.tiles) == "table" and dry.tiles or {dry.name:gsub(":","_")..".png"}
    dry.use_texture_alpha = dry.use_texture_alpha or c_alpha.clip
    dry.paramtype = dry.paramtype or "light"
    dry.drop = dry.name
    -- custom params
    dry._dry_name = dry.name
    -- functions
    dry.after_place_node = dry.after_place_node or function(pos, placer, itemstack, pointed_thing)
        if pos.y < -15 then
            -- No labels when underground
            return
        end
        -- labels, remove_labels
        ms.labels_to_position(pos, {"bare_soil"}, {"no_soil"})
    end
    -- props of wet variant (do not create or add to props if false)
    wet = type(wet) == 'table' and wet or wet ~= false and {} or nil
    if wet then
        -- pre-merge modifications
        wet.description = wet.description or S("Wet @1",dry.description)
        -- modify tiles accordingly
        if not wet.tiles then
            wet.tiles = table.copy(dry.tiles)
            soil_modify_tiles(wet.tiles, textures.wet)
        end
        -- name and drop
        wet.name = dry.name.."_wet"
        wet.drop = wet.drop or wet.name
        -- merge and stats
        dry._wet_name = wet.name
        wet = merge_tables(dry, wet)
        -- actual registration
        wet.groups = merge_tables(groups, wet.groups)
        wet.groups.wet_sediment = 1
        wet.groups.puts_out_fire = 1
        -- sound
        wet.sounds = wet.sounds or (soil_like == "gravel" and table.copy(sediment.sounds.gravel_wet))
            or (soil_like == "sand" and table.copy(sediment.sounds.sand_wet))
            or table.copy(sediment.sounds.dirt_wet)
    end
    -- register wet_salty (do not create or add to props if false)
    wet_salty = type(wet_salty) == 'table' and wet_salty
        or wet_salty ~= false and {} or nil
    if wet_salty then
        -- pre-merge modifications
        wet_salty.description = wet_salty.description or S("Salty Wet @1",dry.description)
        -- modify tiles accordingly
        if not wet_salty.tiles then
            wet_salty.tiles = table.copy(dry.tiles) -- be sure to copy as to not overwrite!
            -- provide tiles table, texture modifier
            soil_modify_tiles(wet_salty.tiles,textures.wet.."^"..textures.salty)
        end
        -- name and drop
        wet_salty.name = dry.name.."_wet_salty"
        wet_salty.drop = wet_salty.name
        -- merge and stats
        dry._wet_salty_name = wet_salty.name
        wet_salty = merge_tables(dry, wet_salty)
        wet_salty._wet_name = wet and wet.name or nil
        if wet then
            wet._wet_salty_name = wet_salty.name
        end
        -- actual registration
        wet_salty.groups = merge_tables(groups, wet_salty.groups)
        wet_salty.groups.wet_sediment = 2
        wet_salty.groups.puts_out_fire = 1
        -- sound (prioritize provided wet_salty sounds, then provided wet sounds, then create one if still non-existent)
        wet_salty.sounds = wet_salty.sounds or wet and wet.sounds and table.copy(wet.sounds) or
            (soil_like == "gravel" and table.copy(sediment.sounds.gravel_wet))
            or (soil_like == "sand" and table.copy(sediment.sounds.sand_wet))
            or table.copy(sediment.sounds.dirt_wet)
    end
    -- post-wet definitions
    groups.dry_sediment = 1
    -- remove groups with numbers lower than 0
    for _,data in pairs({dry,wet,wet_salty}) do
        for grpname, grpnum in pairs(data.groups) do -- groupname, groupnumber
            -- if less than 1, remove
            if grpnum < 1 then
                data.groups[grpname] = nil
            end
        end
    end
    -- sound
    dry.sounds = dry.sounds or (soil_like == "gravel" and table.copy(sediment.sounds.gravel)) or
            (soil_like == "sand" and table.copy(sediment.sounds.sand)) or table.copy(sediment.sounds.dirt)
    -- return for calling party to register
    return {dry=dry,wet=wet,wet_salty=wet_salty}
end

-- automatically register as a node, add sediment ID, returns sediment ID
-- utilizes create_soil_props to get properties
-- same parameters as create_soil_props
-- 4th "gen_props" boolean option, default true, if false then does not attempt to run through getting more properties
function sediment2.register_soil(dry, wet, wet_salty, gen_props)
    gen_props = type(gen_props) ~= "boolean" and true or gen_props
    -- add properties to provided soils or go along as is if gen_props is false
    local soils = gen_props and sediment2.create_soil_props(dry, wet, wet_salty)
        or {dry, wet, wet_salty}
    -- get total count of registered sediments, add 1
    local sed_num = #sediment2.registered_sediments + 1
    sediment2.registered_sediments[sed_num] = soils.dry.name
    -- iterate over to add said sediment number
    for _, data in pairs(soils) do
        data.groups.sediment = sed_num
        minetest.register_node(data.name, data)
        -- see about other stuff like slopes
    end
    return sed_num
end

local sediment2_list = {
    {
      name = "eloam",
        description = S("Loam"),
        tiles = {"nodes_nature_loam.png"},
        groups = {
            rocky_substrate = 1,
            organic_substrate = 4,
            fertility = 4,
            density = 1,
        }
    },
    {
      name = "eclay",
        description = S("Clay"),
        tiles = {"nodes_nature_clay.png"},
        groups = {
            crumbly = 2,
            rocky_substrate = 2,
            organic_substrate = 2,
            fertility = 2,
            density = 4,
        },
    },
    {
      name = "esilt",
        description = S("Silt"),
        tiles = {"nodes_nature_silt.png"},
        groups = {
            rocky_substrate = 1,
            organic_substrate = 3,
            fertility = 3,
            density = 3,
        }
    },
    {
      name = "esand",
        description = S("Sand"),
        tiles = {"nodes_nature_sand.png"},
        groups = {
            rocky_substrate = 4,
            organic_substrate = 0,
            fertility = 1,
            density = 2,
        }
    },
    {
      name = "egravel",
        description = S("Gravel"),
        tiles = {"nodes_nature_gravel.png"},
        groups = {
            rocky_substrate = 4,
            organic_substrate = 0,
            fertility = 1,
            density = 4,
            gravel = 1
        }
    },
    {
      name = "evolcanic_ash",
        description = S("Volcanic Ash"),
        tiles = {"nodes_nature_volcanic_ash.png"},
        groups = {
            rocky_substrate = 4,
            organic_substrate = 0,
            fertility = 4,
            density = 1,
        }
    },
}

for _,new_sedi in pairs(sediment2_list) do
    sediment2.register_soil(new_sedi)
end

--
function sediment2.create_grassy_props(def, soil)
    assert(type(def) == "table",
        "sediment.create_grassy_props: no base grassy table provided for definition, got type "..type(def))
    assert(type(def.name) == "string",
        "sediment.create_grassy_props: no name provided for grassy, got type "..type(def.name))
    -- get mod_origin, create name, set _dry_name, get soildef
    def.mod_origin = minetest.get_current_modname()
    def.name = def.name:sub(1,1) == ":" and def.mod_origin..def.name or
        (not def.name:match(":")) and def.mod_origin..":"..def.name or def.name
    def._dry_name = def.name
    local soildef = minetest.registered_nodes[soil]
    assert(soildef,
        "sediment.create_grassy_props: missing soil definition (expected string, could not find in "..
        "minetest.registered_nodes) to base off of for '"..def.name.."'")
    -- basic params
    def.description = def.description or def.name -- you wanna be silly and not provide description, we'll get silly
    def.nn_soil_like = soildef.nn_soil_like
    def._bare_name = soildef.name
    -- figure out tiles
    local grasscolor = def.grasscolor or nil
    def.grasscolor = nil
    def.tiles = def.tiles or {}
    -- check top, bottom, and basic side tile
    for i=1,3 do
        if not def.tiles[i] then
            def.tiles[i] = i == 1 and soildef.tiles[i] or i == 2 and (soildef.tiles[i] or soildef.tiles[1]) or
                i == 3 and (soildef.tiles[i] or soildef.tiles[1])
            if type(def.tiles[i]) == "table" then
                def.tiles[i].name = def.tiles[i].name..(i ~= 2 and
                    (grasscolor and "^(@grass^[multiply:"..grasscolor..")" or "^@grass") or "")
            else
                def.tiles[i] = def.tiles[i]..(i ~= 2 and 
                    (grasscolor and "^(@grass^[multiply:"..grasscolor..")" or "^@grass") or "")
            end
        end
    end
    -- fix other side tiles
    for i=4,6 do
        def.tiles[i] = def.tiles[i] or def.tiles[3]
    end
    -- adjust tiles
    for tilenum, tile in ipairs(def.tiles) do
        local tilestring = type(tile) == "table" and tile.name or tile
        local optimal_soil_tile
        for i=tilenum,1,-1 do
            optimal_soil_tile = soildef.tiles[i]
            if optimal_soil_tile then break end
        end

        tilestring = tilestring:gsub("@soil",optimal_soil_tile)
        tilestring = tilestring:gsub("@grass",(tilenum < 3 and "nodes_nature_grassy_grayscale.png" or
            "nodes_nature_grassy_grayscale_side.png"))
        --tilestring = tilestring:gsub("@grdetail",(tilenum < 3 and "nodes_nature_grass_detail.png" or
            --"nodes_nature_grassy_grayscale_side.png"))
        if type(tile) == "table" then
            tile.name = tilestring
        else
            def.tiles[tilenum] = tilestring
        end
    end
    -- groups
    def.groups = def.groups or {}
    def.groups = merge_tables(soildef.groups, def.groups)
    def.groups.spreading = def.groups.spreading or 1
    def.groups.bare_sediment = nil
    -- functions
    def.after_place_node = def.after_place_node or function(pos, placer, itemstack, pointed_thing)
        if pos.y < -15 then
            -- No labels when underground
            return
        end
        -- labels, remove_labels
        ms.labels_to_position(pos, {"spring_soil"}, {"no_spring_soil","bare_soil"})
    end
    -- get and check wet variant
    local wet_soildef = minetest.registered_nodes[soildef._wet_name]
    local wet = def.wet_def or def.wet
    -- clear
    def.wet_def = nil
    def.wet = nil
    -- can exclude grassy wet if false
    wet = type(wet) == "table" and wet or wet ~= false and {} or nil
    -- remove wet definition if wet_soildef doesn't exist
    wet = wet_soildef and wet or nil
    if wet then
        -- modify tiles accordingly
        if not wet.tiles then
            wet.tiles = table.copy(def.tiles)
            soil_modify_tiles(wet.tiles, textures.wet)
        end
        -- names and description
        wet.name = def.name.."_wet"
        wet._dry_name = def.name
        def._wet_name = wet.name
        wet._bare_name = wet_soildef.name
        wet.description = wet.description or S("Wet @1",def.description)
        -- wet groups
        wet.groups = wet.groups or {}
        wet.groups.spreading = def.groups.spreading or 1
        wet.groups = merge_tables(wet_soildef.groups, wet.groups)
        wet.groups.bare_sediment = nil
        -- merge wet_soildef properties into wet grassy
        wet = merge_tables(wet_soildef, wet)
    end
    -- get rest of properties from soildef
    def = merge_tables(soildef, def)
    return {dry=def, wet=wet}
end

-- register_grassy
function sediment2.register_grassy(def, soil)
    local grasses = sediment2.create_grassy_props(def, soil)
    -- iterate over to register
    for _, data in pairs(grasses) do
        minetest.register_node(data.name, data)
        -- see about other stuff like slopes
    end
    return true
end

sediment2.register_grassy({
    name = "birmingham",
      description = "Birmingham",
      grasscolor = "#a0b62d"--"#f5dd42",
  },
"nodes_nature:esilt")

--[[
function sediment.get_base_props(sed)
    local props = {
        stack_max = minimal.stack_max_bulky,
        _dry_name = sediment.get_dry_name(sed.name),
        _wet_name = sediment.get_wet_name(sed.name),
        _wet_salty_name = sediment.get_wet_salty_name(sed.name),
        use_texture_alpha = c_alpha.clip,
        after_place_node = function(pos, placer, itemstack, pointed_thing)
            if pos.y < -15 then
                -- No labels when underground
                return
            end
            local labels = {}
            local remove_labels = {"no_soil"}
            if minimal.pos_group(pos, "spreading") then
                table.insert(labels, "spring_soil")
                table.insert(remove_labels, "no_spring_soil")
                table.insert(remove_labels, "bare_soil")
            elseif minimal.pos_group(pos, "winter_soil") then
                table.insert(labels, "winter_soil")
                table.insert(remove_labels, "no_winter_soil")
                table.insert(remove_labels, "bare_soil")
            else
                table.insert(labels, "bare_soil")
            end
            ms.labels_to_position(pos, labels, remove_labels)
        end,
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
    props.groups.dry_sediment = 1
    return merge_tables(sediment.get_base_props(sed), props)
end

function sediment.register_dry(sed)
    local props = sediment.get_dry_node_props(sed)
    props = table.copy(props)
    props.groups.bare_sediment = 1
    local dry_name = sediment.get_dry_name(sed.name)
    minetest.register_node(dry_name, props)
    sediment.do_slopes(dry_name)
    defer_tgcr.register_replacement(dry_name,
                                    sediment.get_wet_name(sed.name),
                                    c.REPLACEMENT_WET)
    defer_tgcr.register_replacement(dry_name,
                                    sediment.get_wet_salty_name(sed.name),
                                    c.REPLACEMENT_SALTY)
    table.insert(registered_sediments, dry_name)
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
--]]