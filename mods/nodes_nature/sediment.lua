---------------------------------------------------------
--SEDIMENT
--
----------------------------------------------------------

-- TODO:
-- inherit "drop" somehow

-- Internationalization
local S = nodes_nature.S

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
local function erode_deplete_ag_soil(pos, depleted_name)
	local c = math.random()
	--rain makes this more likely (erosive, washes nutrient out)
	local adjust = 1
	if climate.get_rain(pos) then
	   adjust = 2
	end

	if c < (0.05 * adjust) then -- 90-95% chance nothing happens
	   return true
	end
	--4-8% chance of rain/water erosion
	if c > (0.01 * adjust) then
		--erode if exposed, and near water or raining
		local positions = minetest.find_nodes_in_area(
			{x = pos.x - 1, y = pos.y, z = pos.z - 1},
			{x = pos.x + 1, y = pos.y, z = pos.z + 1},
			{"group:water", "air"})

		if #positions >= 1 then
			local name = minetest.get_node(pos).name
			local new = name:gsub("%_depleted","")
			new = new:gsub("%_agricultural_soil","")
			--would prefer stairs:slab, but sand/etc lacks wet
			new = new:gsub("%nature:","%nature:slope_pike_")
			minetest.swap_node(pos, {name = new})
			return false
		end

	elseif minetest.get_node({x=pos.x, y=(pos.y+1), z=pos.z}) == 'air' then
	        -- ^ don't deplete a planted node; already handled in life.lua
		-- and a 1-2% chance to be depleted via neglect
		minetest.swap_node(pos, {name = depleted_name})
		return false
	end
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
local function fertilize_ag_soil(pos, puncher, restored_name)
   --hit it with fertilizer to restore
   local itemstack = puncher:get_wielded_item()
   local ist_name = itemstack:get_name()

   if minetest.get_item_group(ist_name, "fertilizer") >= 1 then
      minetest.swap_node(pos, {name = restored_name})
      local inv = puncher:get_inventory()
      inv:remove_item("main", ist_name)
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

-- function sediment.get_dry_agri_soil_name(basename)
--     local node_name = sediment.get_dry_name(basename)
--     return node_name:gsub(basename, basename.."_agricultural_soil")
-- end

-- function sediment.get_wet_agri_soil_name(basename)
--     local node_name = sediment.get_wet_name(basename)
--     return node_name:gsub(basename, basename.."_agricultural_soil")
-- end

function sediment.new(args)
    local groups =
        {falling_node = 1, crumbly = args.hardness, sediment = args.fertility}
    local mod_name = minetest.get_current_modname() -- allows making artificial soils
    local sed = {
        name = args.name,
        description = args.description,
        hardness = args.hardness,
        fertility = args.fertility,
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
    minetest.register_node(sediment.get_dry_name(sed.name), props)
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
    minetest.register_node(sediment.get_wet_name(sed.name), props)
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

function soil.get_side_texture_name(basename, sedname)
    return sediment.get_dry_texture_name(sedname).."^"..soil.get_dry_texture_name(basename.."_side")
end

function soil.get_wet_side_texture_name(basename, sedname)
    return soil.get_side_texture_name(basename, sedname).."^"..textures.wet
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
    if minetest.get_item_group(node_name, "spreading") ~= 0 then
        --figure out what soil it is from dropped
        local ag_soil = nodedef._ag_soil
        minetest.swap_node(pointed_thing.under, {name = ag_soil})
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
                tiles = {soil.get_dry_texture_name(soil_desc.name), sediment.get_dry_texture_name(sed.name),
                         {name = soil.get_side_texture_name(soil_desc.name, sed.name)}},
        })
    return merge_tables(props, soil.get_base_props(soil_desc))
end

function soil.register_dry(soil_desc)
    minetest.register_node(soil.get_dry_name(soil_desc.name),
                           soil.get_dry_node_props(soil_desc))
end

function soil.get_wet_node_props(soil_desc)
    local sed = soil_desc.sediment
    local props =
        merge_tables(
            sediment.get_wet_node_props(sed), {
                description = S("Wet @1", soil_desc.description),
                groups = merge_tables(sed.groups_wet, {spreading = 1}),
                tiles = {soil.get_wet_texture_name(soil_desc.name), sediment.get_wet_texture_name(sed.name),
                         {name = soil.get_wet_side_texture_name(soil_desc.name, sed.name)}},
        })
    return merge_tables(props, soil.get_base_props(soil_desc))
end

function soil.register_wet(soil_desc)
    minetest.register_node(soil.get_wet_name(soil_desc.name),
                           soil.get_wet_node_props(soil_desc))
end

function soil.do_slopes(soil_desc)
    local doslopes = minetest.settings:get_bool('exile_enableslopes')
    local slopechance = minetest.settings:get('exile_slopechance') or 20
    if doslopes then
        naturalslopeslib.register_slope(soil.get_dry_name(soil_desc.name), {}, slopechance)
        naturalslopeslib.register_slope(soil.get_wet_name(soil_desc.name), {}, slopechance)
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

function agricultural_soil.get_base_texture_name(sedname)
    return "[combine:32x32:0,0="
        ..sediment.get_dry_texture_name(sedname)..":0,16="
        ..sediment.get_dry_texture_name(sedname)..":16,0="
        ..sediment.get_dry_texture_name(sedname)
end

function agricultural_soil.get_dry_texture_name(sedname)
    return agricultural_soil.get_base_texture_name(sedname).."^"..textures.tilled_soil
end

function agricultural_soil.get_wet_texture_name(sedname)
    return agricultural_soil.get_dry_texture_name(sedname).."^"..textures.wet
end

function agricultural_soil.get_dry_depleted_texture_name(sedname)
    return agricultural_soil.get_base_texture_name(sedname).."^"..textures.tilled_soil_depleted
end

function agricultural_soil.get_wet_depleted_texture_name(sedname)
    return agricultural_soil.get_dry_depleted_texture_name(sedname).."^"..textures.wet
end

function agricultural_soil.new(args)
    local ag_soil = {
        name = args.name,
        description = args.description,
        sediment = args.sediment,
        texture_name = textures.agri_top,
    }
    return ag_soil
end

function agricultural_soil.get_base_props(ag_soil)
    local props = {
        drawtype = "mesh",
        mesh = "nodes_nature_tilled_soil.obj",
        _dry_name = agricultural_soil.get_dry_name(ag_soil.name),
        _wet_name = agricultural_soil.get_wet_name(ag_soil.name),
        _wet_salty_name = sediment.get_wet_salty_name(ag_soil.sediment.name),
        on_construct = function(pos)
            --speed of erosion, degrade to depleted
            minetest.get_node_timer(pos):start(math.random(90, 300))
        end,
        on_timer = function(pos, elapsed)
            return erode_deplete_ag_soil(pos, ag_soil.depleted_node_name)
        end,
    }
    return props
end

function agricultural_soil.get_dry_node_props(ag_soil)
    local sed = ag_soil.sediment
    local props =
        merge_tables(
            sediment.get_dry_node_props(sed), {
                description = ag_soil.description,
                groups = merge_tables(sed.groups, {agricultural_soil = 1}),
                tiles = {agricultural_soil.get_dry_texture_name(sed.name)},
        })
    return merge_tables(props, agricultural_soil.get_base_props(ag_soil))
end

function agricultural_soil.register_dry(ag_soil)
    local name = ag_soil.name
    minetest.register_node(agricultural_soil.get_dry_name(name),
                           agricultural_soil.get_dry_node_props(ag_soil))
end

function agricultural_soil.get_wet_node_props(ag_soil)
    local sed = ag_soil.sediment
    local props =
        merge_tables(
            sediment.get_wet_node_props(sed), {
                description = S("Wet @1", ag_soil.description),
                groups = merge_tables(sed.groups_wet, {agricultural_soil = 1}),
                tiles = {agricultural_soil.get_wet_texture_name(sed.name)},
        })
    return merge_tables(props, agricultural_soil.get_base_props(ag_soil))
end

function agricultural_soil.register_wet(ag_soil)
    local name = ag_soil.name
    minetest.register_node(agricultural_soil.get_wet_name(name),
                           agricultural_soil.get_wet_node_props(ag_soil))
end

function agricultural_soil.get_dry_depleted_node_props(ag_soil)
    local sed = ag_soil.sediment
    local props =
        merge_tables(
            sediment.get_dry_node_props(sed), {
                description = S("Depleted @1", ag_soil.description),
                groups = merge_tables(sed.groups, {depleted_agricultural_soil = 1}),
                tiles = {agricultural_soil.get_dry_depleted_texture_name(sed.name)},
                on_punch = function(pos, node, puncher, pointed_thing)
                    fertilize_ag_soil(pos, puncher, ag_soil.dry_node_name)
                end,
        })
    return merge_tables(props, agricultural_soil.get_base_props(ag_soil))
end

function agricultural_soil.register_depleted(ag_soil)
    local name = ag_soil.name
    minetest.register_node(agricultural_soil.get_dry_depleted_name(name),
                           agricultural_soil.get_dry_depleted_node_props(ag_soil))
end

function agricultural_soil.get_wet_depleted_node_props(ag_soil)
    local sed = ag_soil.sediment
    local props =
        merge_tables(
            sediment.get_wet_node_props(sed), {
                description = S("Wet Depleted @1", ag_soil.description),
                groups = merge_tables(sed.groups_wet, {depleted_agricultural_soil = 1}),
                tiles = {agricultural_soil.get_wet_depleted_texture_name(sed.name)},
                on_punch = function(pos, node, puncher, pointed_thing)
                    fertilize_ag_soil(pos, puncher, ag_soil.dry_node_name)
                end,
        })
    return merge_tables(props, agricultural_soil.get_base_props(ag_soil))
end

function agricultural_soil.register_wet_depleted(ag_soil)
    local name = ag_soil.name
    minetest.register_node(agricultural_soil.get_wet_depleted_name(name),
                           agricultural_soil.get_wet_depleted_node_props(ag_soil))
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
function sediment.register_agri_soil_variants(sed)
    local agri =
        agricultural_soil.new({name = sed.name,
                               description = S("@1 Agricultural Soil", sed.description),
                               sediment = sed})
    agricultural_soil.register_dry(agri)
    agricultural_soil.register_wet(agri)
    agricultural_soil.register_depleted(agri)
    agricultural_soil.register_wet_depleted(agri)
end

-- Registers soils with "grasses" and their variants including slopes
function sediment.register_soil_variants(soil_list)
    for _, s in ipairs(soil_list) do
        soil.register_dry(s)
        soil.register_wet(s)
        soil.do_slopes(s)
    end
end

-- Registers sediments, their variants (slabs, wet, salty, etc.) and agricultural soils
-- including crafting recipes
function sediment.register_all_sed_and_agri_variants(sed_list)
    for _, sed in pairs(sed_list) do
        sediment.register_sed_variants(sed)
        sediment.register_agri_soil_variants(sed)
    end
end

---------------------------------------------
-- Nodes and recipes are defined here
---------------------------------------------

-- list of sediments to be used for mapgen
local sediment_list = {
   sand = sediment.new({name = "sand",
			description = S("Sand"), hardness = hardness.soft,
			fertility = 4, sound = sounds.sand,
			sound_wet = sounds.sand_wet}),
   silt = sediment.new({name = "silt",
			description = S("Silt"), hardness = hardness.soft,
			fertility = 3, sound = sounds.dirt,
			sound_wet = sounds.dirt_wet}),
   clay = sediment.new({name = "clay",
			description = S("Clay"), hardness = hardness.medium,
			fertility = 2, sound = sounds.dirt,
			sound_wet = sounds.dirt_wet}),
   gravel = sediment.new({name = "gravel",
			  description = S("Gravel"), hardness = hardness.soft,
			  fertility = 5, sound = sounds.gravel,
			  sound_wet = sounds.gravel_wet}),
   loam = sediment.new({name = "loam",
			description = S("Loam"), hardness = hardness.soft,
			fertility = 1, sound = sounds.dirt,
			sound_wet = sounds.dirt_wet}),
   volcanic_ash = sediment.new({name = "volcanic_ash",
				description = S("Volcanic ash"),
				hardness = hardness.soft,
				fertility = 1, sound = sounds.sand,
				sound_wet = sounds.sand_wet}),
}

-- this is only for paint
local red_ochre = sediment.new({name = "red_ochre",
				description = S("Red Ochre"),
				hardness = hardness.medium,
                                fertility = 2, sound = sounds.dirt,
				sound_wet = sounds.dirt_wet})
sediment.register_dry(red_ochre)
sediment.register_wet(red_ochre)
sediment.register_wet_salty(red_ochre)
sediment.do_slopes(red_ochre)



local soil_list = {
    --Forest & Woodland
   soil.new({name = "rich_forest_soil",
	     description = S("Rich Forest Soil"),
	     sediment = sediment_list.loam}),
   soil.new({name = "rich_woodland_soil",
	     description = S("Rich Woodland Soil"),
	     sediment = sediment_list.loam}),
   soil.new({name = "forest_soil",
	     description = S("Forest Soil"),
	     sediment = sediment_list.silt}),
   soil.new({name = "woodland_soil",
	     description = S("Woodland Soil"),
	     sediment = sediment_list.silt}),
   soil.new({name = "upland_forest_soil",
	     description = S("Upland Forest Soil"),
	     sediment = sediment_list.clay}),
   soil.new({name = "upland_woodland_soil",
	     description = S("Upland Woodland Soil"),
	     sediment = sediment_list.clay}),

    --Wetlands
   soil.new({name = "marshland_soil",
	     description = S("Marshland Soil"),
	     sediment = sediment_list.silt}),
   soil.new({name = "swamp_forest_soil",
	     description = S("Swamp Forest Soil"),
	     sediment = sediment_list.silt}),

    --Shrubland & Grassland
    soil.new({name = "coastal_shrubland_soil",
	      description = S("Coastal Shrubland Soil"),
	      sediment = sediment_list.silt}),
    soil.new({name = "coastal_grassland_soil",
	      description = S("Coastal Grassland Soil"),
	      sediment = sediment_list.clay}),
    soil.new({name = "grassland_soil", description = S("Grassland Soil"),
	      sediment = sediment_list.clay}),
    soil.new({name = "shrubland_soil", description = S("Shrubland Soil"),
	      sediment = sediment_list.clay}),

    --Barrenland & Duneland
    soil.new({name = "barrenland_soil",
	      description = S("Barren Grassland Soil"),
	      sediment = sediment_list.gravel}),
    soil.new({name = "duneland_soil",
	      description = S("Duneland Soil"),
	      sediment = sediment_list.sand}),

    -- Highland
    soil.new({name = "highland_soil",
	      description = S("Highland Soil"),
	      sediment = sediment_list.gravel}),

    --Legacy
    soil.new({name = "grassland_barren_soil",
	      description = S("Barren Grassland Soil"),
	      sediment = sediment_list.gravel}),
    soil.new({name = "woodland_dry_soil",
	      description = S("Dry Woodland Soil"),
	      sediment = sediment_list.silt}),
}

-- Recipes for loam

crafting.register_recipe({
	type = "mixing_spot",
	output = "nodes_nature:loam 3",
	items = {"nodes_nature:clay 1","nodes_nature:silt 1","nodes_nature:sand 1"},
	level = 1,
	always_known = true,
})

crafting.register_recipe({
	type = "mixing_spot",
	output = "nodes_nature:loam_wet 3",
	items = {"nodes_nature:clay_wet 1","nodes_nature:silt_wet 1","nodes_nature:sand_wet 1"},
	level = 1,
	always_known = true,
})

-- Actually registers (almost) all soils in the game
-- see red_ochre above
sediment.register_all_sed_and_agri_variants(sediment_list)
sediment.register_soil_variants(soil_list)
