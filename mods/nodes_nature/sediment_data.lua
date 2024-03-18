---------------------------------------------------------
--SEDIMENT DATA
--Nodes and recipes are defined here
--
----------------------------------------------------------

-- Internationalization
local S = nodes_nature.S
---------------------------------------------

local c_alpha = minimal.compat_alpha

-- list of sediments to be used for mapgen
local sediment_list = {
    sand = sediment.new(
        {name = "sand",
         description = S("Sand"), hardness = sediment.hardness.soft,
         id = 4, sound = sediment.sounds.sand,
         sound_wet = sediment.sounds.sand_wet,
         rocky_substrate = 4,
         organic_substrate = 0,
         fertility = 1,
         density = 2,
    }),
    silt = sediment.new(
        {name = "silt",
         description = S("Silt"), hardness = sediment.hardness.soft,
         id = 3, sound = sediment.sounds.dirt,
         sound_wet = sediment.sounds.dirt_wet,
         rocky_substrate = 1,
         organic_substrate = 3,
         fertility = 3,
         density = 3,
    }),
    clay = sediment.new(
        {name = "clay",
         description = S("Clay"), hardness = sediment.hardness.medium,
         id = 2, sound = sediment.sounds.dirt,
         sound_wet = sediment.sounds.dirt_wet,
         rocky_substrate = 2,
         organic_substrate = 2,
         fertility = 2,
         density = 4,
    }),
    gravel = sediment.new(
        {name = "gravel",
         description = S("Gravel"), hardness = sediment.hardness.soft,
         id = 5, sound = sediment.sounds.gravel,
		 groups = {gravel = 1},
         sound_wet = sediment.sounds.gravel_wet,
         rocky_substrate = 4,
         organic_substrate = 0,
         fertility = 1,
         density = 4,
    }),
    loam = sediment.new(
        {name = "loam",
         description = S("Loam"), hardness = sediment.hardness.soft,
         id = 1, sound = sediment.sounds.dirt,
         sound_wet = sediment.sounds.dirt_wet,
         rocky_substrate = 1,
         organic_substrate = 4,
         fertility = 4,
         density = 1,
    }),
    volcanic_ash = sediment.new(
        {name = "volcanic_ash",
         description = S("Volcanic ash"),
         hardness = sediment.hardness.soft,
         id = 1, sound = sediment.sounds.sand,
         sound_wet = sediment.sounds.sand_wet,
         rocky_substrate = 4,
         organic_substrate = 0,
         fertility = 4,
         density = 1,
    }),
}

-- this is only for paint
local red_ochre = sediment.new(
    {name = "red_ochre",
     description = S("Red Ochre"),
     hardness = sediment.hardness.medium,
     id = 2, sound = sediment.sounds.dirt,
     sound_wet = sediment.sounds.dirt_wet,
     rocky_substrate = 2,
     organic_substrate = 2,
     fertility = 2,
     density = 4,
})
sediment.register_dry(red_ochre)
sediment.register_wet(red_ochre)
sediment.register_wet_salty(red_ochre)



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
    soil.new({name = "upland_grassland_soil", description = S("Upland Grassland Soil"),
              sediment = sediment_list.clay}),
    soil.new({name = "upland_shrubland_soil", description = S("Upland Shrubland Soil"),
              sediment = sediment_list.clay}),

    --Barrenland & Duneland
    soil.new({name = "coastal_barrenland_soil",
              description = S("Coastal Barren Grassland Soil"),
              sediment = sediment_list.gravel}),
    soil.new({name = "barrenland_soil",
	      description = S("Barren Grassland Soil"),
	      sediment = sediment_list.gravel}),
    soil.new({name = "upland_barrenland_soil",
              description = S("Upland Barren Grassland Soil"),
              sediment = sediment_list.gravel}),
    soil.new({name = "coastal_duneland_soil",
              description = S("Coastal Duneland Soil"),
              sediment = sediment_list.sand}),
    soil.new({name = "duneland_soil",
	      description = S("Duneland Soil"),
	      sediment = sediment_list.sand}),
    soil.new({name = "upland_duneland_soil",
              description = S("Upland Duneland Soil"),
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
sediment.register_all_sed_derivatives(sediment_list)
sediment.register_soil_variants(soil_list)

-- Soils with roots
for i = 1, #registered_sediments do
    local name = registered_sediments[i]
    local nodedef = minetest.registered_nodes[name]
    local props = table.copy(nodedef)
    props.description = S("@1 With Roots", props.description)
    props.groups.roots = 1
    props.groups.spreading = 0
    props.use_texture_alpha = c_alpha.blend
    local root_texture = ""
    if props.groups.winter_soil and props.groups.winter_soil > 0 then
        root_texture = "nodes_nature_roots_winter.png"
    else
        root_texture = "nodes_nature_roots.png"
    end
    if props.groups.agricultural_soil and
        props.groups.agricultural_soil > 0 or
        props.groups.depleted_agricultural_soil and
        props.groups.depleted_agricultural_soil > 0 then
        props.tiles = {
            {name = props.tiles[1].."^[combine:32x32:0,0="
                 .."("..root_texture..")"..":0,16="
            },
            props.tiles[2],
            props.tiles[3]
        }
    else
        props.tiles = {
            {name = props.tiles[1].."^"..root_texture},
            props.tiles[2],
            props.tiles[3]
        }
    end
    if props._non_winter_name then
        props._non_winter_name = props._non_winter_name.."_roots"
    end
    if props._winter_name then
        props._winter_name = props._winter_name.."_roots"
    end
    props._dry_name = props._dry_name.."_roots"
    props._wet_name = props._wet_name.."_roots"
    if not props.on_dig then
        props.on_dig = function(pos, node, digger)
            if not minetest.is_player(digger) then return false end
            if minetest.is_protected(pos, digger:get_player_name()) then
                return false
            end
            local meta = minetest.get_meta(pos)
            local number_of_roots = math.floor(meta:get_float("root_nr"))
            local root_name = meta:get_string("root_name")
            local player_inv = digger:get_inventory()
            local root_stack = ItemStack(root_name.." "..number_of_roots)
            if player_inv:room_for_item("main", root_stack) then
                player_inv:add_item("main", root_stack)
            else
                minetest.add_item(pos, root_stack)
            end
            local w_item = digger:get_wielded_item()
            if not minimal.in_group(w_item,"hoe") then
              local sed_stack = ItemStack(nodedef.drop)
              if player_inv:room_for_item("main", sed_stack) then
                  player_inv:add_item("main", sed_stack)
              else
                  minetest.add_item(pos, sed_stack)
              end
              minetest.remove_node(pos)
            else -- replace roots with regular sediment (roots were tilled)
              minetest.set_node(pos,{name = name})
            end
            
            if not minimal.player_in_creative(digger) then
              -- set toolwear
              --[[
              local tool_cap = w_item:get_tool_capabilities()
              local gc = tool_cap.groucaps
              if gc then
                local uses = gc.tilling and gc.tilling.uses or gc.crumbly and gc.crumbly.uses
                if uses then
                  local digparams = {wear = 65535/uses)
                  w_item:add_wear_by_uses(uses)
                  digger:set_wielded_item(w_item)
                end
              end
              --]]
            end

            minetest.check_for_falling(pos)
        end
    end
    minetest.register_node(name.."_roots", props)
end
