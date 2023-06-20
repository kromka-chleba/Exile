-- Globals
deco = deco or {}

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
register_from_list("Cobbles", rns.cobbles)
register_from_list("Trees", trees.tree_list)
register_from_list("Canes", canes.cane_list)
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

---- Start node timers ----
local egg_names = {  -- list of strings
    "gundu_eggs",
    "sarkamos_eggs",
    "impethu_eggs",
    "kubwakubwa_eggs",
    "kubwakubwa_eggs_forest",
    "kubwakubwa_eggs_barren",
    "darkasthaan_eggs",
    "pegasun_eggs",
    "pegasun_eggs_badland",
    "sneachan_eggs",
    "sneachan_eggs_badland",
}

local eggs_nearby = {}  -- list of decoration IDs
for i in ipairs(egg_names) do -- get decoration IDs
    table.insert(eggs_nearby, minetest.get_decoration_id("animals:"..egg_names[i])) -- add the current egg found
end
minetest.set_gen_notify({decoration = true}, eggs_nearby)
minetest.register_on_generated(
    function(minp, maxp, blockseed) -- start node timers
        local gennotify = minetest.get_mapgen_object("gennotify")
        local poslist = {}
        for i in ipairs(egg_names) do -- iterate across the list of strings
            for j, pos in ipairs(gennotify["decoration#"..eggs_nearby[i]] or {}) do -- iterate across the
                local eggs_pos = {x = pos.x, y = pos.y + 1, z = pos.z}
                table.insert(poslist, eggs_pos) -- append this position to the list
            end
        end
        if #poslist ~= 0 then
            for i = 1, #poslist do
                local pos = poslist[i] -- grab this position from the list
                minetest.get_node_timer(pos):start(1) -- start the node timer for this egg
            end
        end
    end
)
