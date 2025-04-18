------------------------------------
--CRAFTING STATIONS
--work tables etc
-----------------------------------
-------------------------------------------------

-- Declare globals
minimal = minimal
crafting = crafting
nodes_nature = nodes_nature
tech = tech

-- Internationalization
local S = tech.S

local c_alpha = minimal.compat_alpha
local legacy_stations = true
local legacy_station_recipes = false

--if not minetest.is_creative_enabled() then
--    crafting.make_global_inventory_tab("crafting", ("Crafting"), "hand")
--    crafting.make_global_inventory_tab("pottery", ("Pottery"), "hand_pottery")
--    crafting.make_global_inventory_tab("wattle", ("Wattle"), "hand_wattle")
--    crafting.make_global_inventory_tab("mixing", ("Mixing"), "hand_mixing")
--end

--Register
--some crafts are more convienently registered at the same time as the resource,
--hence why not all are here.
crafting.register_type("crafting_spot",
                       S("Crafting Spot"),
                       "tech:stick")
--crafting.register_type("mixing_spot")...has to be done in nodes_nature
--crafting.register_type("threshing_spot")...has to be done in nodes_nature
crafting.register_type("weaving_frame",
                       S("Weaving"),
                       "tech:woven_poncho",
                       "nodes_nature_grass_footstep")
crafting.register_type("weaving_frame_mixing",
                       S("Mixing"),
                       "tech:weaving_frame")
crafting.register_type("grinding_stone",
                       S("Grinding stone"),
                       "tech:grinding_stone_granite")
crafting.register_type("mortar_and_pestle",
                       S("Mortar and pestle"),
                       "tech:mortar_pestle_granite")
--crafting.register_type("chopping_block")...has to be done in nodes_nature
--crafting.register_type("hammering_block")...has to be done in nodes_nature
crafting.register_type("anvil",
                       S("Crafting"),
                       "tech:anvil",
                       {name = "tech_anvil_craft", pitch = {0.65,1}})
crafting.register_type("anvil_mixing",
                       S("Mixing"),
                       "stairs:stair_slag",
                       {name = "tech_rock_crush", pitch = {0.8, 0.95}})
crafting.register_type("carpentry_bench",
                       S("Carpentry Bench"),
                       "tech:carpentry_bench",
                       {name = "nodes_nature_dig_choppy", pitch={0.9,1.3}}) -- TODO: maybe use a saw sound?
--crafting.register_type("masonry_bench")...has to be done in nodes_nature
--crafting.register_type("masonry_mixing")...has to be done in nodes_nature
crafting.register_type("brick_makers_bench",
                       S("Crafting"),
                       "tech:brick_makers_bench",
                       "nodes_nature_hard_footstep")
crafting.register_type("brick_makers_bench_bricks",
                       S("Bricks"),
                       "stairs:stair_limestone_brick_mortar",
                       "nodes_nature_hard_footstep")
crafting.register_type("brick_makers_bench_blocks",
                       S("Blocks"),
                       "tech:conglomerate_block_mortar",
                       "nodes_nature_hard_footstep")
crafting.register_type("brick_makers_bench_mixing",
                       S("Mixing"),
                       "stairs:stair_mudbrick",
                       "nodes_nature_hard_footstep")

crafting.register_type("spinning_wheel",
                       S("Spinning Wheel"),
                       "tech:spinning_wheel")
crafting.register_type("loom",
                       S("Loom"),
                       "tech:loom")
crafting.register_type("glass_furnace",
                       S("Glass furnace"),
                       "tech:glass_furnace")

-- Tool based crafting stations
crafting.register_type("hand", -- Empty hand tool; Replace crafting spot
                       S("Crafting"),
                       "tech:stick")
-- crafting.register_type("hand_create", ("Create"), "tech:brick_makers_bench")
   -- Assemble crafting stations by hand.
crafting.register_type("hand_pottery",
                       S("Pottery"),
                       "tech:clay_water_pot",     -- Pottery tab
                       {name = "nodes_nature_dirt_footstep", pitch={0.6, 0.85}})
-- crafting.register_type("hand_wattle", ("Wattle"), "tech:wattle")            -- Wattle Tab
crafting.register_type("hand_tools",
                       S("Tools"),
                       "tech:hammer_basalt")  -- Tools Tab
crafting.register_type("hand_mixing",
                       S("Mixing"),
                       "stairs:stair_thatch")       -- Mixing Tab

-- TODO: see about a knife-like sound for knife crafting
crafting.register_type("knife",
                       S("Crafting"),
                       "tech:stone_chopper")    -- Replace some of the crafting spot
crafting.register_type("knife_stations",
                       S("Stations"),
                       "tech:stone_chopper")   -- Replace some of the crafting spot
crafting.register_type("knife_wattle",
                       S("Wattle"),
                       "tech:wattle", -- Replace some of the crafting spot
                       {name = "nodes_nature_wood_footstep", pitch={1, 1.1}, gain=0.3})
crafting.register_type("knife_mixing",
                       S("Mixing"),
                       "tech:wood_ash")
crafting.register_type("hammer",
                       S("Crafting"),
                       "tech:hammer_basalt",   -- Hammering spot replacement
                       {name = "tech_rock_crush", pitch = {0.7, 0.95}})
crafting.register_type("hammer_mixing",
                       S("Mixing"),
                       "nodes_nature:limestone_boulder",
                       {name = "tech_rock_crush", pitch = {0.7, 0.95}})
crafting.register_type('shovel',
                       S("Crafting"),
                       "tech:shovel_iron")     -- farming tools - including digging stick; replace threshing spot
crafting.register_type("shovel_agriculture",
                       S("Agriculture"),
                       "nodes_nature:loam_agricultural_soil", -- compost, etc.
                       "nodes_nature_dirt_footstep")
crafting.register_type('soil_mixing',
                       S("Mixing"),
                       "stairs:stair_loam",         -- tab for shovel
                       "nodes_nature_dirt_footstep")
crafting.register_type('axe',
                       S("Crafting"),           -- includes adze - replace chopping bock
                       "tech:axe_iron",
                       {name = "nodes_nature_dig_choppy", pitch={0.9,1.3}})
crafting.register_type('axe_mixing',
                       S("Mixing"),
                       "stairs:stair_tangkal_log",
                       {name = "nodes_nature_dig_choppy", pitch={0.9,1.3}})
crafting.register_type('cobble')        -- Replacing grinding stone
crafting.register_type('pickaxe',
                       S("Pickaxe"),
                       "tech:pickaxe_iron")    -- nothing yet
-- food-based crafting stations
crafting.register_type('breadmaking',
                        S("Breadmaking"),
                        "tech_breadmaking_crafticon.png",
                        {name = "nodes_nature_mud", gain = 0.15})

-- location limit craft spots --------------------
-- grouplist/banlistg {{group1, group_number}, {'stone', 1}}
-- nodelist/banlistn {node_name, 'nodes_nature:sandstone'}
-- msg string "stone or sandstone"
local function on_place_loclim_spot(itemstack, placer, pointed_thing,
                                    grouplist, nodelist, msg, banlistg,
                                    banlistn)
    local ground = minetest.get_node(pointed_thing.under)

    --check lists to see if it's a valid substrate
    local valid = false
    local vcheck = false

    if grouplist and #grouplist >= 1 then
        vcheck = true
        for i in ipairs(grouplist) do
            local group = grouplist[i][1]
            local num = grouplist[i][2]
            if minetest.get_item_group(
                ground.name,group) == num then
                valid = true
                break
            end
        end
    end

    if nodelist and #nodelist >= 1 then
        vcheck = true
        local gname = ground.name
        for i in ipairs(nodelist) do
            local name = nodelist[i]
            if gname == name then
                valid = true
                break
            end
        end
    end

    local banned
    if banlistg and #banlistg >= 1 then
        for i in ipairs(banlistg) do
            local group = banlistg[i][1]
            local num = banlistg[i][2]
            if minetest.get_item_group(ground.name,group) == num then
                banned = true
                break
            end
        end
    end

    if banlistn and #banlistn >= 1 then
        local gname = ground.name
        for i in ipairs(banlistn) do
            local name = banlistn[i]
            if gname == name then
                banned = true
                break
            end
        end
    end


    --block invalid
    if banned == true
    --or above.name ~= "air"
        or (vcheck == true and valid == false) then

        minetest.chat_send_player(
            placer:get_player_name(),
            S("Cannot place here! Needs a whole block of: ")..msg..".")

        if not (minetest.is_player(placer)
                and placer:get_player_control().sneak) then
            local on_click = minimal.on_rightclick(itemstack, placer,
                                                   pointed_thing)
            if on_click ~= false then
                return on_click or itemstack
            end
        end
    end

    return minetest.item_place_node(itemstack,placer,pointed_thing)
end


---- Stations ---------------------------
--Entry level --equivalent to sitting down to make stuff
--crafting spot--basic crafts
minetest.register_node(
    "tech:crafting_spot", {
        description   = S("Crafting Spot"),
        tiles         = {"tech_station_crafting_spot.png"},
        exile_crafting = {
            craft_types  = {'hand','hand_tools','hand_pottery','hand_mixing',
                            'weaving_frame','threshing_spot'},
            craft_level  = 2,
        },
        drawtype      = "nodebox",
        node_box      = {
            type  = "fixed",
            fixed = {-0.5, -0.5, -0.5, 0.5, -0.45, 0.5},
        },
        selection_box = {
            type  = "fixed",
            fixed = {-0.5, -0.5, -0.5, 0.5, -0.25, 0.5},
        },
        stack_max     = 1,
        paramtype     = "light",
        use_texture_alpha = c_alpha.clip,
        walkable      = false,
        buildable_to  = true,
        floodable     = true,
        groups        = {dig_immediate=3, falling_node = 1, temp_pass = 1,
                         nobones = 1, unclaimable = 1},
        sounds        = nodes_nature.node_sound_wood_defaults(),
        sunlight_propagates = true,
        on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
            return crafting.crafting_item_on_rightclick(pos,node,clicker,
                                                       itemstack,pointed_thing)
        end,
        -- on_rightclick = crafting.make_on_rightclick("crafting_spot", 2, { x = 8, y = 3 }),
        on_punch      = function(pos, node, player)
            minetest.remove_node(pos)
        end
})
--Mixing spot
--rearranging previously existing stuff (e.g. stairs, slabs)
minetest.register_node(
    "tech:mixing_spot", {
        description   = S("Mixing Spot"),
        exile_crafting = {
            craft_types  = 'mixing_spot',
            craft_level  = 1,
        },
        tiles         = {"tech_station_mixing_spot.png"},
        drawtype      = "nodebox",
        node_box      = {
            type  = "fixed",
            fixed = {-0.5, -0.5, -0.5, 0.5, -0.45, 0.5},
        },
        selection_box = {
            type  = "fixed",
            fixed = {-0.5, -0.5, -0.5, 0.5, -0.25, 0.5},
        },
        stack_max     = 1,
        paramtype     = "light",
        use_texture_alpha = c_alpha.clip,
        walkable      = false,
        buildable_to  = true,
        floodable     = true,
        groups        = {dig_immediate=3, falling_node = 1, temp_pass = 1,
                         nobones = 1, unclaimable = 1},
        sounds        = nodes_nature.node_sound_wood_defaults(),
        sunlight_propagates = true,
        on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
            return crafting.crafting_item_on_rightclick(pos,node,clicker,
                                                       itemstack,pointed_thing)
        end,
        --on_rightclick = crafting.make_on_rightclick("mixing_spot", 2, { x = 8, y = 3 }),
        on_punch      = function(pos, node, player)
            minetest.remove_node(pos)
        end
})
--Threshing spot
--extracting seeds from plants
minetest.register_node(
    "tech:threshing_spot", {
        description       = S("Threshing Spot"),
        tiles             = {"tech_station_threshing_spot.png"},
        exile_crafting    = {
            craft_types  = {'threshing_spot','soil_mixing'},
            craft_level      = 2,
        },
        drawtype          = "nodebox",
        node_box          = {
            type  = "fixed",
            fixed = {-0.5, -0.5, -0.5, 0.5, -0.45, 0.5},
        },
        selection_box     = {
            type  = "fixed",
            fixed = {-0.5, -0.5, -0.5, 0.5, -0.25, 0.5},
        },
        stack_max         = 1,
        paramtype         = "light",
        use_texture_alpha = c_alpha.clip,
        walkable          = false,
        buildable_to      = true,
        floodable         = true,
        groups            = {dig_immediate = 3, falling_node = 1,
                             temp_pass = 1, nobones = 1, unclaimable = 1},
        sounds            = nodes_nature.node_sound_wood_defaults(),
        sunlight_propagates = true,
        on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
            return crafting.crafting_item_on_rightclick(pos,node,clicker,
                                                       itemstack,pointed_thing)
        end,
        --on_rightclick     = crafting.make_on_rightclick("threshing_spot", 2, { x = 8, y = 3 }),
        on_place = function(itemstack, placer, pointed_thing)
            return
                on_place_loclim_spot(itemstack, placer, pointed_thing, {},
                                     {}, "dry ground",
                                     {{'puts_out_fire', 1}}, {})
        end,
        on_punch          = function(pos, node, player)
            minetest.remove_node(pos)
        end
})


--Location limited --------------------

--weaving spot
minetest.register_node(
    "tech:weaving_spot",{
        description   = S("Weaving Spot"),
        exile_crafting = {
            craft_types       = 'weaving_frame',
            craft_level  = 1,
        },
        tiles         = {"tech_station_weaving_spot.png"},
        drawtype      = "nodebox",
        node_box      = {
            type  = "fixed",
            fixed = {-0.5, -0.5, -0.5, 0.5, -0.45, 0.5},
        },
        selection_box = {
            type  = "fixed",
            fixed = {-0.5, -0.5, -0.5, 0.5, -0.25, 0.5},
        },
        stack_max     = 1,
        paramtype     = "light",
        use_texture_alpha = c_alpha.clip,
        walkable      = false,
        buildable_to  = true,
        floodable     = true,
        groups        = {dig_immediate=3, attached_node = 1, temp_pass = 1,
                         nobones = 1, unclaimable = 1},
        sounds        = nodes_nature.node_sound_stone_defaults(),
        sunlight_propagates = true,
        on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
            return crafting.crafting_item_on_rightclick(pos,node,clicker,
                                                       itemstack,pointed_thing)
        end,
        --on_rightclick = crafting.make_on_rightclick("weaving_frame", 2, { x = 8, y = 3 }),
        on_place = function(itemstack, placer, pointed_thing)
            return on_place_loclim_spot(itemstack, placer, pointed_thing, {},
                                        {}, "dry ground",
                                        {{'puts_out_fire', 1}}, {})
        end,
        on_punch      = function(pos, node, player)
            minetest.remove_node(pos)
        end
})
--grinding spot
--for grinding stone tools
minetest.register_node(
    "tech:grinding_spot",{
        description   = S("Grinding Spot"),
        exile_crafting = {
            craft_types       = 'grinding_spot',
            craft_level  = 2,
        },
        tiles         = {"tech_station_grinding_spot.png"},
        drawtype      = "nodebox",
        node_box      = {
            type  = "fixed",
            fixed = {-0.5, -0.5, -0.5, 0.5, -0.45, 0.5},
        },
        selection_box = {
            type  = "fixed",
            fixed = {-0.5, -0.5, -0.5, 0.5, -0.25, 0.5},
        },
        stack_max     = 1,
        paramtype     = "light",
        use_texture_alpha = c_alpha.clip,
        walkable      = false,
        buildable_to  = true,
        floodable     = true,
        groups        = {dig_immediate=3, attached_node = 1, temp_pass = 1,
                         nobones = 1, unclaimable = 1},
        sounds        = nodes_nature.node_sound_stone_defaults(),
        sunlight_propagates = true,
        on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
            return crafting.crafting_item_on_rightclick(pos,node,clicker,
                                                       itemstack,pointed_thing)
        end,
        --on_rightclick = crafting.make_on_rightclick("grinding_stone", 2, { x = 8, y = 3 }),
        on_place = function(itemstack, placer, pointed_thing)
            return on_place_loclim_spot(itemstack, placer,
                                        pointed_thing, {{'stone', 1},
                                            {'masonry', 1}, {'boulder', 1}},
                                        {'nodes_nature:sandstone'},
                                        "hard stone, masonry, or sandstone")
        end,
        on_punch      = function(pos, node, player)
            minetest.remove_node(pos)
        end
})
--hammering_block
--crude hammering crushing jobs,
minetest.register_node(
    "tech:hammering_spot",{
        description   = S("Hammering Spot"),
        exile_crafting = {
            craft_types       = 'hammering_spot',
            craft_level  = 2,
        },
        tiles         = {"tech_station_hammering_spot.png"},
        drawtype      = "nodebox",
        node_box      = {
            type  = "fixed",
            fixed = {-0.5, -0.5, -0.5, 0.5, -0.45, 0.5},
        },
        selection_box = {
            type  = "fixed",
            fixed = {-0.5, -0.5, -0.5, 0.5, -0.25, 0.5},
        },
        stack_max     = 1,
        paramtype     = "light",
        use_texture_alpha = c_alpha.clip,
        walkable      = false,
        buildable_to  = true,
        floodable     = true,
        groups        = {dig_immediate=3, attached_node = 1, temp_pass = 1,
                         nobones = 1, unclaimable = 1},
        sounds        = nodes_nature.node_sound_stone_defaults(),
        sunlight_propagates = true,
        on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
            return crafting.crafting_item_on_rightclick(pos,node,clicker,
                                                       itemstack,pointed_thing)
        end,
        --on_rightclick = crafting.make_on_rightclick("hammering_block", 2, { x = 8, y = 3 }),
        on_place = function(itemstack, placer, pointed_thing)
            return on_place_loclim_spot(
                itemstack, placer, pointed_thing,
                {{'stone', 1}, {'masonry', 1}, {'boulder', 1},
                    {'soft_stone', 1}, {'tree', 1}, {'log', 1}},
                {}, "stone, masonry, tree, or a log")
        end,
        on_punch      = function(pos, node, player)
            minetest.remove_node(pos)
        end
})

------------------------------
--Tool based
--chopping_block (stone knife/adze/axe)
-- To do... but fiddly...
-- placing tool down creates the crafting spot,
-- carry around the tool, not the lump of wood.
-- better tool opens up more crafts

--IB ----Duplicate and depricated. See legacy stations below
--IB --chopping_block --crude wood crafts,
--IB minetest.register_node("tech:chopping_block", {
--IB    description   = ("Chopping Block"),
--IB    tiles         = {
--IB            "tech_chopping_block_top.png",
--IB            "tech_chopping_block_top.png",
--IB            "tech_chopping_block.png",
--IB            "tech_chopping_block.png",
--IB            "tech_chopping_block.png",
--IB            "tech_chopping_block.png",
--IB            },
--IB    drawtype      = "nodebox",
--IB    node_box      = {
--IB            type  = "fixed",
--IB            fixed = {-0.43, -0.5, -0.43, 0.43, 0.38, 0.43},
--IB            },
--IB    stack_max     = minimal.stack_max_bulky,
--IB    paramtype     = "light",
--IB    groups        = {dig_immediate = 3, falling_node = 1, temp_pass = 1, craftedby = 1},
--IB    sounds        = nodes_nature.node_sound_wood_defaults(),
--IB    on_rightclick = crafting.make_on_rightclick("chopping_block", 2, { x = 8, y = 3 }),
--IB    })
--IB

-- used for transferring meta between placeable stations and their itemstacks to save creator meta
local function station_preserve_metadata(pos, oldnode, oldmeta, drops)
    local item = drops[1]
    local imeta = item:get_meta()
    -- just steal meta from oldmeta (which will be fields)
    imeta:from_table({fields = oldmeta})
end
-- ditto to above
local function station_after_place(pos, placer, itemstack, pointed_thing)
    local imeta = itemstack:get_meta()
    local meta = core.get_meta(pos)
    -- transfer from itemstack to node
    meta:from_table(imeta:to_table())
end


-- Mortar and pestle. for grinding food etc ----------------
----------------------------------------------

-- def can be description (tag)
local function register_mortar_and_pestle(name, def, sand_needed)
    def = type(def) == "string" and {tag = def} or type(def) == "table" and def or {}
    def.description = def.description or def.tag and S("@1 Mortar and Pestle", def.tag) or nil
    def.tag = nil -- remove from def
    -- grab recipe if provided
    local recipe = def.recipe or {}
    def.recipe = nil
    -- set up exile crafting
    local exile_crafting = def.exile_crafting or {}
    local craft_types = exile_crafting.craft_types or {}
    craft_types[#craft_types + 1] = 'mortar_and_pestle'
    craft_types[#craft_types + 1] = 'breadmaking'
    exile_crafting.craft_types = craft_types
    exile_crafting.craft_level = exile_crafting.craft_level or 1
    def.exile_crafting = exile_crafting
    -- now for actual node things
    def.drawtype = def.drawtype or "nodebox"
    def.node_box = def.node_box or def.drawtype == "nodebox" and
      {
          type  = "fixed",
          fixed = {
              {-0.3750, -0.5000, -0.3750,  0.3750, -0.4375,  0.3750},
              {-0.4375, -0.4375, -0.4375,  0.4375, -0.3125,  0.4375},
              {-0.4375, -0.3125, -0.4375,  0.4375,  0.2500, -0.3125},
              {-0.4375, -0.3125,  0.3125,  0.4375,  0.2500,  0.4375},
              {-0.4375, -0.3125, -0.3125, -0.3125,  0.2500,  0.3125},
              { 0.3125, -0.3125, -0.3125,  0.4375,  0.2500,  0.3125},
              {-0.2500, -0.3125,  0.1250, -0.0625,  0.4375,  0.3125},
          }
      } or nil
    def.tiles = def.tiles or {"nodes_nature_"..name..".png"}
    def.stack_max = def.stack_max or minimal.stack_max_bulky * 2
    def.paramtype = "light"
    def.paramtype2 = def.paramtype2 or "facedir"
    def.sounds = def.sounds or nodes_nature.node_sound_stone_defaults()
    -- set up groups
    def.groups = def.groups or {}
    def.groups.falling_node = def.groups.falling_node or 1
    def.groups.dig_immediate = def.groups.dig_immediate or 3
    def.groups.craftedby = def.groups.craftedby or 1
    -- show crafting
    def.on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
        return crafting.crafting_item_on_rightclick(pos,node,clicker,itemstack,pointed_thing)
    end
    -- metadata functions (if craftedby)
    if def.groups.craftedby > 0 then
        def.preserve_metadata = station_preserve_metadata
        def.after_place_node = station_after_place
    end
    -- register node
    local nodename = "tech:mortar_pestle_"..name
    core.register_node(nodename, def)
    -- register recipe
    recipe.type = recipe.type or {"hand_tools", "grinding_stone"}
    recipe.output = nodename
    -- add sand as tool is sand is needed
    if sand_needed then
        recipe.tool = "nodes_nature:sand"
    end
    -- recipe.items are given for wooden already, else it is stone ones
    recipe.items = recipe.items or {"nodes_nature:"..name.."_boulder", "group:"..name.."_cobble"}
    recipe.level = 1
    recipe.always_known = true
    crafting.register_recipe(recipe)
end

-- need to change old tech:mortar_pestle to tech:mortar_pestle_limestone
-- less translation work needed if we just use the nodes_nature description lol
register_mortar_and_pestle("basalt", core.registered_nodes["nodes_nature:basalt"].description, true)
register_mortar_and_pestle("granite", core.registered_nodes["nodes_nature:granite"].description, true)
register_mortar_and_pestle("limestone", core.registered_nodes["nodes_nature:limestone"].description, true)
-- wooden mortar and pestle
register_mortar_and_pestle(
    "wooden",
    {
        description = S("Wooden Mortar and Pestle"),
        tiles = {"tech_primitive_wood.png"},
        sounds = nodes_nature.node_sound_wood_defaults(),
        recipe = {
            type = {"axe", "carpentry_bench"},
            items = {'group:log 2'}
            }
        },
    false
)


--------------------------------------------------------------

--IB-20240226 ---- Boulders ----
--IB-20240226 --grind a mortar_and_pestle
--IB-20240226 -- crafting.register_recipe({
--IB-20240226 --        type   = "grinding_stone",
--IB-20240226 --        output = "tech:mortar_pestle_basalt",
--IB-20240226 --        items  = {'nodes_nature:limestone_boulder', "group:limestone_cobble", 'nodes_nature:sand'},
--IB-20240226 --        level  = 1,
--IB-20240226 --        always_known = true,
--IB-20240226 --        })
--IB-20240226 -- crafting.register_recipe({
--IB-20240226 --        type   = "grinding_stone",
--IB-20240226 --        output = "tech:mortar_pestle_granite",
--IB-20240226 --        items  = {'nodes_nature:granite_boulder', "group:granite_cobble", 'nodes_nature:sand'},
--IB-20240226 --        level  = 1,
--IB-20240226 --        always_known = true,
--IB-20240226 --        })

-- Brick_makers_bench
--     for fired bricks and associated crafts
minetest.register_node(
    "tech:brick_makers_bench", {
        description   = S("Brick Maker's Bench"),
        exile_crafting = {
            craft_types = {
                "brick_makers_bench", "brick_makers_bench_blocks",
                "brick_makers_bench_bricks", "brick_makers_bench_mixing"
            },
            craft_level = 2,
        },
        tiles         = {"nodes_nature_maraka_log.png"},
        drawtype      = "nodebox",
        node_box      = {
            type  = "fixed",
            fixed = {
                {-0.4375,  0.000, -0.3750,  0.4375,  0.1250,  0.3750}, -- NodeBox1
                {-0.3750, -0.500, -0.3125, -0.2500,  0.0000, -0.1875}, -- NodeBox2
                { 0.2500, -0.500, -0.3125,  0.3750,  0.0000, -0.1875}, -- NodeBox3
                { 0.2500, -0.500,  0.1875,  0.3750,  0.0000,  0.3125}, -- NodeBox4
                {-0.3750, -0.500,  0.1875, -0.2500,  0.0000,  0.3125}, -- NodeBox5
                {-0.3750, -0.125, -0.1875, -0.2500,  2.42144e-008, 0.1875}, -- NodeBox6
                { 0.2500, -0.125, -0.1875,  0.3750, -3.72529e-009, 0.1875}, -- NodeBox7
                {-0.2500, -0.125, -0.3125,  0.2500,  5.7742e-008, -0.1875}, -- NodeBox8
                {-0.2500, -0.125,  0.1875,  0.2500, -2.23517e-008, 0.3125}, -- NodeBox9
                {-0.2500,  0.125,  0.1875,  0.2500,  0.2500,  0.2500}, -- NodeBox10
                {-0.2500,  0.125, -0.0625,  0.2500,  0.2500,  1.86265e-009}, -- NodeBox11
                {-0.3125,  0.125, -0.0625, -0.2500,  0.2500,  0.2500}, -- NodeBox12
                { 0.2500,  0.125, -0.0625,  0.3125,  0.2500,  0.2500}, -- NodeBox13
                { 0.1875,  0.125, -0.3125,  0.2500,  0.1875, -0.1250}, -- NodeBox14
            }
        },
        stack_max     = minimal.stack_max_bulky,
        paramtype     = "light",
        paramtype2    = "facedir",
        groups        = {dig_immediate=3, falling_node = 1, temp_pass = 1,
                         flammable = 8, craftedby = 1},
        sounds        = nodes_nature.node_sound_wood_defaults(),
        on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
            return crafting.crafting_item_on_rightclick(pos,node,clicker,
                                                       itemstack,pointed_thing)
        end,
        preserve_metadata = station_preserve_metadata,
        after_place_node = station_after_place
        --on_rightclick = crafting.make_on_rightclick(
        --      {"brick_makers_bench", "brick_makers_bench_blocks",
        --       "brick_makers_bench_bricks", "brick_makers_bench_mixing"},
                           --      2, { x = 8, y = 3 }),
})

crafting.register_recipe({ -- from sticks
        type   = {"crafting_spot", "hand_tools"},
        output = "tech:brick_makers_bench",
        items  = {'tech:stick 24'},
        level  = 1,
        always_known = true,
})

--------------------------------------------

-- Metal working, and things dependant on it

--------------------------------------------

-- Anvil : metal working
minetest.register_node(
    "tech:anvil", {
        description   = S("Anvil"),
        exile_crafting = {
            craft_types = {"anvil","anvil_mixing"},
            craft_level = 2,
        },
        tiles         = {"tech_iron.png"},
        drawtype      = "nodebox",
        node_box      = {
            type  = "fixed",
            fixed = {
                {-0.50, -0.5, -0.30, 0.50, -0.4, 0.30},
                {-0.35, -0.4, -0.25, 0.35, -0.3, 0.25},
                {-0.30, -0.3, -0.15, 0.30, -0.1, 0.15},
                {-0.35, -0.1, -0.20, 0.35,  0.1, 0.20},
            },
        },
        stack_max     = minimal.stack_max_bulky,
        paramtype     = "light",
        paramtype2    = "facedir",
        groups        = {dig_immediate=3, falling_node = 1,
                         temp_pass = 1, craftedby = 1},
        sounds        = tech.node_sound_metal_defaults(),
        on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
            return crafting.crafting_item_on_rightclick(pos,node,clicker,
                                                       itemstack,pointed_thing)
        end,
        preserve_metadata = station_preserve_metadata,
        after_place_node = station_after_place
        --on_rightclick = crafting.make_on_rightclick({"anvil","anvil_mixing"}, 2, { x = 8, y = 3 }),
})

crafting.register_recipe({ -- crafted from ingots, using hammer
        type   = {"hammer"},
        output = "tech:anvil",
        items  = {'tech:iron_ingot 4'},
        level  = 1,
        always_known = true,
        sound = {name="tech_metal_dig", pitch={0.6,0.85}}
})


-- Carpentry_bench : more sophisticated wood working
minetest.register_node(
    "tech:carpentry_bench", {
        description   = S("Carpentry Bench"),
        exile_crafting = {
            craft_types = {"carpentry_bench"},
            craft_level = 2,
        },
        tiles         = {"nodes_nature_maraka_log.png"},
        drawtype      = "nodebox",
        node_box      = {
            type  = "fixed",
            fixed = {
                {-0.5000,  0.000, -0.3125,  0.5000,  0.250,  0.3750},
                {-0.5000, -0.125, -0.2500,  0.5000,  0.000,  0.3125},
                { 0.3125, -0.500, -0.2500,  0.4375, -0.125, -0.1250},
                { 0.3125, -0.500,  0.1875,  0.4375, -0.125,  0.3125},
                {-0.4375, -0.500,  0.1875, -0.3125, -0.125,  0.3125},
                {-0.4375, -0.500, -0.2500, -0.3125, -0.125, -0.1250},
            }
        },
        stack_max     = minimal.stack_max_bulky,
        paramtype     = "light",
        paramtype2    = "facedir",
        groups        = {dig_immediate=3, falling_node = 1, temp_pass = 1,
                         flammable = 8, craftedby = 1},
        sounds        = nodes_nature.node_sound_wood_defaults(),
        on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
            return crafting.crafting_item_on_rightclick(pos,node,clicker,
                                                       itemstack,pointed_thing)
        end,
        preserve_metadata = station_preserve_metadata,
        after_place_node = station_after_place
        --on_rightclick = crafting.make_on_rightclick("carpentry_bench", 2, { x = 8, y = 3 }),
})

crafting.register_recipe({ -- from logs for bench and iron for tools
        type   = {"axe"},
        output = "tech:carpentry_bench",
        items  = {'tech:iron_ingot 4', 'group:hard_wood 2'},
        level  = 1,
        always_known = true,
})


-- Masonry_bench : more sophisticated stone crafts
minetest.register_node(
    "tech:masonry_bench", {
        description   = S("Masonry Bench"),
        exile_crafting = {
            craft_types = {"masonry_bench","masonry_bench_blocks","masonry_bench_bricks", "masonry_bench_mixing"},
            craft_level = 2,
        },
        tiles         = {"nodes_nature_maraka_log.png"},
        drawtype      = "nodebox",
        node_box      = {
            type  = "fixed",
            fixed = {
                {-0.5000,  0.0000, -0.5000,  0.5000, 0.25,  0.5000},
                {-0.5000, -0.5000, -0.5000, -0.3125, 0.00, -0.3125},
                { 0.3125, -0.5000, -0.5000,  0.5000, 0.00, -0.3125},
                { 0.3125, -0.5000,  0.3125,  0.5000, 0.00,  0.5000},
                {-0.5000, -0.5000,  0.3125, -0.3125, 0.00,  0.5000},
                {-0.4375, -0.1875, -0.3125, -0.3125, 0.00,  0.3125},
                { 0.3125, -0.1875, -0.3125,  0.4375, 0.00,  0.3125},
                {-0.3750, -0.1875, -0.4375,  0.3125, 0.00, -0.3125},
                {-0.3750, -0.1875,  0.3125,  0.3750, 0.00,  0.4375},
            }
        },
        stack_max     = minimal.stack_max_bulky,
        paramtype     = "light",
        paramtype2    = "facedir",
        groups        = {dig_immediate=3, falling_node = 1,
                         temp_pass = 1, craftedby = 1},
        sounds        = nodes_nature.node_sound_wood_defaults(),
        on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
            return crafting.crafting_item_on_rightclick(pos,node,clicker,
                                                       itemstack,pointed_thing)
        end,
        preserve_metadata = station_preserve_metadata,
        after_place_node = station_after_place
        --on_rightclick = crafting.make_on_rightclick(
        --      {"masonry_bench","masonry_bench_blocks","masonry_bench_bricks", "masonry_bench_mixing"},
                           --      2, { x = 8, y = 3 }),
})

crafting.register_recipe({ -- from logs for bench and iron for tools
        type   = {"carpentry_bench"},
        output = "tech:masonry_bench",
        items  = {'tech:iron_ingot 4', 'group:hard_wood 2'},
        level  = 1,
        always_known = true,
})


-- Spinning_wheel :
-- turn raw fibres into spun fibre
-- including steps here that in reality would require their own equipment
minetest.register_node(
    "tech:spinning_wheel", {
        description   = S("Spinning Wheel"),
        exile_crafting = {
            craft_types = {"spinning_wheel"},
            craft_level = 1,
        },
        tiles         = {"nodes_nature_maraka_log.png"},
        drawtype      = "nodebox",
        node_box      = {
            type  = "fixed",
            fixed = {
                {-0.2500, -0.5000, -0.1875,  0.5000, -0.2500,  0.1875}, -- NodeBox1
                {-0.2500, -0.2500, -0.1875, -0.0625,  0.1875, -0.0625}, -- NodeBox2
                {-0.2500, -0.2500,  0.0625, -0.0625,  0.1875,  0.1875}, -- NodeBox3
                {-0.1875, -0.1875, -0.0625, -0.1250,  0.5000,  0.0625}, -- NodeBox4
                {-0.5000,  0.1250, -0.0625, -0.2500,  0.1875,  0.0625}, -- NodeBox5
                {-0.0625,  0.1250, -0.0625,  0.1875,  0.1875,  0.0625}, -- NodeBox6
                { 0.3750, -0.2500, -0.0625,  0.5000, -0.1250,  0.0625}, -- NodeBox7
            }
        },
        stack_max     = minimal.stack_max_bulky,
        paramtype     = "light",
        paramtype2    = "facedir",
        groups        = {dig_immediate=3, falling_node = 1, temp_pass = 1,
                         flammable = 8, craftedby = 1},
        sounds        = nodes_nature.node_sound_wood_defaults(),
        on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
            return crafting.crafting_item_on_rightclick(pos,node,clicker,
                                                       itemstack,pointed_thing)
        end,
        preserve_metadata = station_preserve_metadata,
        after_place_node = station_after_place
        --on_rightclick = crafting.make_on_rightclick("spinning_wheel", 2, { x = 8, y = 3 }),
})

crafting.register_recipe({  -- from wood
        type   = {"axe", "carpentry_bench"},
        output = "tech:spinning_wheel",
        items  = {'group:log 2'},
        level  = 1,
        always_known = true,
})


-- Loom : turn fibre into fabric items
minetest.register_node(
    "tech:loom", {
        description   = S("Loom"),
        exile_crafting = {
            craft_types = {"loom"},
            craft_level = 1,
        },
        tiles         = {"nodes_nature_maraka_log.png"},
        drawtype      = "nodebox",
        paramtype     = "light",
        node_box      = {
            type  = "fixed",
            fixed = {
                {-0.5000, -0.5000, -0.1250, -0.3750,  0.5000,  0.1875}, -- NodeBox1
                { 0.3750, -0.5000, -0.1250,  0.5000,  0.5000,  0.1875}, -- NodeBox3
                {-0.3750, -0.5000, -0.5000,  0.3750, -0.4375,  0.5000}, -- NodeBox4
                {-0.5000,  0.0000, -0.1250,  0.5000,  0.0625,  0.1875}, -- NodeBox5
                {-0.5000,  0.3125,  0.1875,  0.5000,  0.5000,  0.2500}, -- NodeBox6
                {-0.5000,  0.3125, -0.1875,  0.5000,  0.5000, -0.1250}, -- NodeBox7
                {-0.3750, -0.1875, -0.5000, -0.3125, -0.1250,  0.5000}, -- NodeBox8
                { 0.3125, -0.1875, -0.5000,  0.3750, -0.1250,  0.5000}, -- NodeBox9
                {-0.4375, -0.1875, -0.5000,  0.4375, -0.1250, -0.4375}, -- NodeBox10
                {-0.4375, -0.1875,  0.4375,  0.4375, -0.1250,  0.5000}, -- NodeBox11
                {-0.3750, -0.5000,  0.3750, -0.3125, -0.1250,  0.4375}, -- NodeBox12
                { 0.3125, -0.5000,  0.3750,  0.3750, -0.1250,  0.4375}, -- NodeBox13
                {-0.3750, -0.5000, -0.4375, -0.3125, -0.1250, -0.3750}, -- NodeBox14
                { 0.3125, -0.5000, -0.4375,  0.3750, -0.1250, -0.3750}, -- NodeBox15
                {-0.3125, -0.4375, -0.2500,  0.3125,  0.0000,  0.2500}, -- NodeBox16
            }
        },
        paramtype2    = "facedir",
        groups        = {dig_immediate=3, falling_node = 1, temp_pass = 1,
                         flammable = 8, craftedby = 1},
        sounds        = nodes_nature.node_sound_wood_defaults(),
        on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
            return crafting.crafting_item_on_rightclick(pos,node,clicker,
                                                       itemstack,pointed_thing)
        end,
        preserve_metadata = station_preserve_metadata,
        after_place_node = station_after_place
        --on_rightclick = crafting.make_on_rightclick("loom", 2, { x = 8, y = 3 }),
})

crafting.register_recipe({ -- from wood and fibre for mechanisms
        type   = {"axe", "carpentry_bench"} ,
        output = "tech:loom",
        items  = {'group:log 2', 'tech:coarse_fibre 12'},
        level  = 1,
        always_known = true,
})


-- Glassworking Furnace :
-- Glassblowing and similar
minetest.register_node(
    "tech:glass_furnace", {
        description   = S("Glass furnace"),
        exile_crafting = {
            craft_types = {"glass_furnace"},
            craft_level = 1,
        },
        tiles         = {
            "tech_bricks_and_mortar.png",
            "tech_bricks_and_mortar.png",
            "tech_bricks_and_mortar.png",
            "tech_bricks_and_mortar.png",
            "tech_bricks_and_mortar.png",
            "tech_glassfurnace_front.png",
        },
        drawtype      = "nodebox",
        node_box      = {
            type  = "fixed",
            fixed = {-0.47, -0.5, -0.47, 0.47, 0.31, 0.47},
        },
        stack_max     = minimal.stack_max_bulky,
        paramtype     = "light",
        paramtype2    = "facedir",
        groups        = {dig_immediate=3, falling_node = 1,
                         temp_pass = 1, craftedby = 1},
        sounds        = nodes_nature.node_sound_wood_defaults(),
        on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
            return crafting.crafting_item_on_rightclick(pos,node,clicker,
                                                       itemstack,pointed_thing)
        end,
        preserve_metadata = station_preserve_metadata,
        after_place_node = station_after_place
        --on_rightclick = crafting.make_on_rightclick("glass_furnace", 2, { x = 8, y = 3 }),
})

crafting.register_recipe({ -- from bricks for the main structure and iron for the tools
        type   = {"brick_makers_bench"},
        output = "tech:glass_furnace",
        items  = {'tech:iron_ingot', 'tech:loose_brick 3', 'tech:lime_mortar'},
        level  = 1,
        always_known = true,
})

--------------------------------------------

-- Others

--------------------------------------------

-- Weaving_frame needs to return for tool based crafting
minetest.register_node(
    "tech:weaving_frame",{
        description   = S("Weaving Frame"),
        exile_crafting = {
            craft_types = {'weaving_frame','weaving_frame_mixing'},
            craft_level = 1,
        },
        drawtype      = "nodebox",
        tiles         = {"tech_stick.png"},
        stack_max     = minimal.stack_max_bulky,
        paramtype     = "light",
        paramtype2    = "facedir",
        groups        = {falling_node = 1, dig_immediate = 3, craftedby = 1},
        node_box      = {
            type  = "fixed",
            fixed = {
                {-0.3750, -0.3750, -0.3750,  0.3750, -0.2500, -0.2500}, -- NodeBox1
                {-0.5000, -0.5000, -0.3750, -0.3750, -0.1250, -0.2500}, -- NodeBox2
                { 0.3750, -0.5000, -0.3750,  0.5000, -0.1250, -0.2500}, -- NodeBox3
                { 0.3750, -0.5000,  0.3750,  0.5000,  0.0625,  0.5000}, -- NodeBox4
                {-0.5000, -0.5000,  0.3750, -0.3750,  0.0625,  0.5000}, -- NodeBox5
                {-0.3750, -0.0625,  0.3750,  0.3750,  0.0625,  0.5000}, -- NodeBox6
                {-0.3125, -0.5000,  0.3750, -0.2500, -0.0625,  0.4375}, -- NodeBox7
                { 0.2500, -0.5000,  0.3750,  0.3125, -0.0625,  0.4375}, -- NodeBox8
                { 0.1250, -0.5000,  0.3750,  0.1875, -0.0625,  0.4375}, -- NodeBox9
                {-0.1875, -0.5000,  0.3750, -0.1250, -0.0625,  0.4375}, -- NodeBox10
                {-0.0625, -0.5000,  0.3750,  0.0625, -0.0625,  0.5000}, -- NodeBox11
                {-0.5000, -0.0625,  0.3125,  0.5000,  0.0000,  0.3750}, -- NodeBox12
                {-0.5000, -0.4375,  0.3125,  0.5000, -0.3750,  0.3750}, -- NodeBox13
            }
        },
        sounds        = nodes_nature.node_sound_wood_defaults(),
        on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
            return crafting.crafting_item_on_rightclick(pos,node,clicker,
                                                       itemstack,pointed_thing)
        end,
        preserve_metadata = station_preserve_metadata,
        after_place_node = station_after_place
        --on_rightclick = crafting.make_on_rightclick({"weaving_frame",
        --                     "weaving_frame_mixing"}, 2, { x = 8, y = 3 }),
})

--IB-20240226
--IB-20240226 -- lowered crafting requirements as a trade off to it no longer being free again
--IB-20240226    crafting.register_recipe({ --weaving_frame
--IB-20240226    type   = {"crafting_spot","hand_create"},
--IB-20240226    output = "tech:weaving_frame",
--IB-20240226 --         items  = {'tech:stick 12', 'group:fibrous_plant 8'},
--IB-20240226    items  = {'tech:stick 6', 'group:fibrous_plant 4'},
--IB-20240226    level  = 1,
--IB-20240226    always_known = true,
--IB-20240226    })
--IB-20240226

--IB-20240226 ----Wood chopping_block
--IB-20240226 crafting.register_recipe({
--IB-20240226   type   = {"crafting_spot", "chopping_block", "hand_create"},
--IB-20240226   output = "tech:chopping_block",
--IB-20240226   items  = {'group:log'},
--IB-20240226   level  = 1,
--IB-20240226   always_known = true,
--IB-20240226   })

--Granite grinding stone
--for grinding stone tools
minetest.register_node(
    "tech:grinding_stone_granite",{
        description = S("Granite Grinding Stone"),
        exile_crafting = {
            craft_types       = 'grinding_stone',
            craft_level  = 1,
        },
        drawtype = "mesh",
        mesh = "grinding_stone.obj",
        tiles = {"tech_grinding_stone_granite.png"},
        stack_max = minimal.stack_max_bulky,
        paramtype = "light",
        paramtype2 = "facedir",
        groups = {falling_node = 1, dig_immediate = 3, craftedby = 1},
        node_box = {
            type = "fixed",
            fixed = {-0.5, -0.5, -0.5, 0.5, -0.45, 0.5},
        },
        selection_box = {
            type = "fixed",
            fixed = {-0.5, -0.5, -0.5, 0.5, -0.25, 0.5},
        },
        sounds = nodes_nature.node_sound_stone_defaults(),
        on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
            return crafting.crafting_item_on_rightclick(pos,node,clicker,
                                                       itemstack,pointed_thing)
        end
        --on_rightclick = crafting.make_on_rightclick("grinding_stone", 2, { x = 8, y = 3 }),
})

--IB-20240226 crafting.register_recipe({
--IB-20240226         type   = {"crafting_spot", "hand_create"},
--IB-20240226         output = "tech:grinding_stone_granite",
--IB-20240226         items  = {"nodes_nature:granite_boulder", "group:granite_cobble", "nodes_nature:sand 3"},
--IB-20240226         level  = 1,
--IB-20240226         always_known = true,
--IB-20240226 })

--Limestone grinding stone
--for grinding stone tools
minetest.register_node(
    "tech:grinding_stone_limestone",{
        description = S("Limestone Grinding Stone"),
        exile_crafting = {
            craft_types       = 'grinding_stone',
            craft_level  = 1,
        },
        drawtype = "mesh",
        mesh = "grinding_stone.obj",
        tiles = {"tech_grinding_stone_limestone.png"},
        stack_max = minimal.stack_max_bulky,
        paramtype = "light",
        paramtype2 = "facedir",
        groups = {falling_node = 1, dig_immediate = 3, craftedby = 1},
        use_texture_alpha = c_alpha.clip,
        node_box = {
            type = "fixed",
            fixed = {-0.5, -0.5, -0.5, 0.5, -0.45, 0.5},
        },
        selection_box = {
            type = "fixed",
            fixed = {-0.5, -0.5, -0.5, 0.5, -0.25, 0.5},
        },
        sounds = nodes_nature.node_sound_stone_defaults(),
        on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
            return crafting.crafting_item_on_rightclick(pos,node,clicker,
                                                       itemstack,pointed_thing)
        end
        --on_rightclick = crafting.make_on_rightclick("grinding_stone", 2, { x = 8, y = 3 }),
})

--IB-20240226 crafting.register_recipe({
--IB-20240226         type   = {"crafting_spot", "hand_create"},
--IB-20240226         output = "tech:grinding_stone_limestone",
--IB-20240226         items  = {"nodes_nature:limestone_boulder", "group:limestone_cobble", "nodes_nature:sand 3"},
--IB-20240226         level  = 1,
--IB-20240226         always_known = true,
--IB-20240226 })

--Basalt grinding stone
--for grinding stone tools
minetest.register_node(
    "tech:grinding_stone_basalt",{
        description = S("Basalt Grinding Stone"),
        exile_crafting = {
            craft_types       = 'grinding_stone',
            craft_level  = 1,
        },
        drawtype = "mesh",
        mesh = "grinding_stone.obj",
        tiles = {"tech_grinding_stone_basalt.png"},
        stack_max = minimal.stack_max_bulky,
        paramtype = "light",
        paramtype2 = "facedir",
        groups = {falling_node = 1, dig_immediate = 3, craftedby = 1},
        node_box = {
            type = "fixed",
            fixed = {-0.5, -0.5, -0.5, 0.5, -0.45, 0.5},
        },
        selection_box = {
            type = "fixed",
            fixed = {-0.5, -0.5, -0.5, 0.5, -0.25, 0.5},
        },
        sounds = nodes_nature.node_sound_stone_defaults(),
        on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
            return crafting.crafting_item_on_rightclick(pos,node,clicker,
                                                       itemstack,pointed_thing)
        end,
        --on_rightclick = crafting.make_on_rightclick("grinding_stone", 2, { x = 8, y = 3 }),
})

--IB-20240226 crafting.register_recipe({
--IB-20240226         type   = {"crafting_spot", "hand_create"},
--IB-20240226         output = "tech:grinding_stone_basalt",
--IB-20240226         items  = {"nodes_nature:basalt_boulder", "group:basalt_cobble", "nodes_nature:sand 3"},
--IB-20240226         level  = 1,
--IB-20240226         always_known = true,
--IB-20240226 })

-- legacy stations -----------------

if legacy_stations == true then
    --chopping_block --crude wood crafts,
    minetest.register_node(
        "tech:chopping_block", {
            description   = S("Chopping Block"),
            exile_crafting = {
                craft_types       = 'chopping_block',
                craft_level  = 1,
            },
            tiles         = {
                "tech_chopping_block_top.png",
                "tech_chopping_block_top.png",
                "tech_chopping_block.png",
                "tech_chopping_block.png",
                "tech_chopping_block.png",
                "tech_chopping_block.png",
            },
            drawtype      = "nodebox",
            node_box      = {
                type  = "fixed",
                fixed = {-0.43, -0.5, -0.43, 0.43, 0.38, 0.43},
            },
            stack_max     = minimal.stack_max_bulky,
            paramtype     = "light",
            groups        = {dig_immediate = 3, falling_node = 1,
                             temp_pass = 1, craftedby = 1},
            sounds        = nodes_nature.node_sound_wood_defaults(),
            on_rightclick = function(pos, node,
                                     clicker, itemstack,
                                     pointed_thing)
                return
                    crafting.crafting_item_on_rightclick(
                        pos,node,clicker,itemstack,
                        pointed_thing)
            end
            --on_rightclick = crafting.make_on_rightclick("chopping_block", 2, { x = 8, y = 3 }),
    })

    --hammering_block
    --crude hammering crushing jobs,
    minetest.register_node(
        "tech:hammering_block", {
            description   = S("Hammering Block"),
            exile_crafting = {
                craft_types       = 'hammering_block',
                craft_level  = 1,
            },
            tiles         = {
                "tech_hammering_block_top.png",
                "tech_chopping_block_top.png",
                "tech_chopping_block.png",
                "tech_chopping_block.png",
                "tech_chopping_block.png",
                "tech_chopping_block.png",
            },
            drawtype      = "nodebox",
            node_box      = {
                type  = "fixed",
                fixed = {-0.47, -0.5, -0.47, 0.47, 0.31, 0.47},
            },
            stack_max     = minimal.stack_max_bulky,
            paramtype     = "light",
            groups        = {dig_immediate=3, falling_node = 1,
                             temp_pass = 1, craftedby = 1},
            sounds        = nodes_nature.node_sound_wood_defaults(),
            on_rightclick = function(pos, node, clicker, itemstack,
                                     pointed_thing)
                return crafting.crafting_item_on_rightclick(
                    pos,node,clicker,itemstack,pointed_thing)
            end
            --on_rightclick = crafting.make_on_rightclick("hammering_block", 2, { x = 8, y = 3 }),
    })
end

if legacy_station_recipes == true then
    --grinding_stone from craft spot
    crafting.register_recipe({ --chopping_block
            type   = {"crafting_spot", "chopping_block", "hand",'knife'},
            output = "tech:chopping_block",
            items  = {'group:log'},
            level  = 1,
            always_known = true,
    })
    crafting.register_recipe({ --hammering block
            type   = "chopping_block",
            output = "tech:hammering_block",
            items  = {'group:log'},
            level  = 1,
            always_known = true,
    })
end
