-- Globals
deco = deco or {}
local ms = mapchunk_shepherd

-- Import
local path = minetest.get_modpath("mapgen")
local rns = dofile(path.."/rocks_and_soils.lua")
local trees = dofile(path.."/trees.lua")
local canes = dofile(path.."/canes.lua")
local fnw = dofile(path.."/fibrous_and_woody.lua")
local ent = dofile(path.."/edible_and_toxic.lua")
local caves = dofile(path.."/caves.lua")
local eggs = dofile(path.."/eggs.lua")
local ocean = dofile(path.."/ocean.lua")

----Register----

function register_from_list(name, decor_list)
    if not decor_list then
        minetest.log("error", "Mapgen: Deco: "..name.." is nil!")
        return
    end
    for i = 1, #decor_list do
        minetest.register_decoration(decor_list[i])
    end
end

register_from_list("Boulders", rns.boulders)
register_from_list("Extra Soils", rns.extra_soils)
register_from_list("Trees", trees.tree_list)
register_from_list("Canes", canes.cane_list)
register_from_list("Cobbles", rns.cobbles)
register_from_list("Fibrous Plants", fnw.fibrous_plants)
register_from_list("Woody Plants", fnw.woody_plants)
register_from_list("Moss", fnw.moss_and_stuff)
register_from_list("Edible Plants", ent.edible_plants)
register_from_list("Kind of Edible Plants", ent.kind_of_edible_plants)
register_from_list("Toxic Plants", ent.toxic_plants)
register_from_list("Cave Sediments", caves.cave_sediments)
register_from_list("Cave Life", caves.cave_life)
register_from_list("Sea Weeds", ocean.sea_weeds)
register_from_list("Eggs", eggs.eggs)

-- Calls function 'fun' for every decoration named 'deco_name'
-- just after generation.
-- fun is a function with arguments:
-- pos, minp, maxp, blockseed, extra_args (an object)
local function do_after_generation(deco_name, fun, extra_args)
    local id = minetest.get_decoration_id(deco_name)
    minetest.set_gen_notify({decoration = true}, {id})
    minetest.register_on_generated(
        function(minp, maxp, blockseed)
            local gennotify = minetest.get_mapgen_object("gennotify")
            local pos_list = gennotify["decoration#"..id] or {}
            for _, pos in ipairs(pos_list) do
                local pos = minimal.get_pos_above(pos)
                fun(pos, minp, maxp, blockseed, extra_args)
            end
        end
    )
end

---- Start node timers ----
local egg_names = {  -- list of strings
    "animals:gundu_eggs",
    "animals:sarkamos_eggs",
    "animals:impethu_eggs",
    "animals:kubwakubwa_eggs",
    "animals:kubwakubwa_eggs_forest",
    "animals:kubwakubwa_eggs_barren",
    "animals:darkasthaan_eggs",
    "animals:pegasun_eggs",
    "animals:pegasun_eggs_badland",
    "animals:sneachan_eggs",
    "animals:sneachan_eggs_badland",
}

local function start_egg_timers(pos, minp, maxp, blockseed, extra_args)
    minetest.get_node_timer(pos):start(1)
end

local function remove_floating_canes(pos, minp, maxp, blockseed, extra_args)
    if minimal.in_group(pos, "cane_plant") then
        return
    end
    local pos_top = {x = pos.x, y = pos.y + 8, z = pos.z}
    local floating_canes =
        minetest.find_nodes_in_area(pos, pos_top, {"group:cane_plant"})
    for i = 1, #floating_canes do
        minetest.remove_node(floating_canes[i])
    end
end

local function add_roots(pos, minp, maxp, blockseed, extra_args)
    local plant_nodedef = minimal.get_nodedef(pos)
    if not plant_nodedef.groups.plant_with_roots
        or plant_nodedef.groups.plant_with_roots == 0 then
        return
    end
    local pos_under = minimal.get_pos_under(pos)
    local name_under = minetest.get_node(pos_under).name
    if minetest.get_item_group(name_under, "sediment") == 0 then
        return
    elseif minetest.get_item_group(name_under, "roots") == 0 then
        minetest.set_node(pos_under, {name = name_under.."_roots"})
    end
    local meta = minetest.get_meta(pos_under)
    meta:set_string("root_name", plant_nodedef._root_name)
    local max_root_nr = plant_nodedef.groups.plant_with_roots
    meta:set_int("root_nr", math.ceil(math.random(0, max_root_nr)))
end

-- List of decoration names
local plants_with_tubers = {
    "dl_nn:anperla",
    "bl_nn:anperla",
    "dl_nn:barszcz",
    "gl_nn:barszcz",
}

--------------------------------------------------------------------
-- Modifying decorations after generation
--------------------------------------------------------------------

-- Start egg timers
for _, egg in ipairs(egg_names) do
    do_after_generation(egg, start_egg_timers)
end

-- Removes floating canes after generation (the final solution)
for _, cane in ipairs(canes.cane_list) do
    do_after_generation(cane.name, remove_floating_canes)
end

-- Adds root soil and tubers under plants with roots
for _, plant in ipairs(plants_with_tubers) do
    do_after_generation(plant, add_roots)
end

ms.create_deco_finder({
        deco_list = fnw.fibrous_plants,
        add_labels = {
            "spring_soil",
            "seasonal_plants",
        }
})

ms.create_deco_finder({
        deco_list = fnw.woody_plants,
        add_labels = {
            "spring_soil",
            "seasonal_plants",
        }
})

ms.create_deco_finder({
        deco_list = trees.tree_list,
        add_labels = {
            "seasonal_trees",
        }
})
