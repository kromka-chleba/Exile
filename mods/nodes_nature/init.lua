nodes_nature = {}

-- Internationalization
nodes_nature.S = minetest.get_translator("nodes_nature")

local S = nodes_nature.S

-- Load files
local path = minetest.get_modpath("nodes_nature")


--crafting spots
crafting.register_type("mixing_spot")
crafting.register_type("threshing_spot", S("Threshing"),
                       "nodes_nature:galanta_seed")
crafting.register_type("hammering_block")
crafting.register_type("weaving_spot")
crafting.register_type("grinding_spot")
crafting.register_type("chopping_block")
crafting.register_type("masonry_bench", S("Crafting"), "tech:masonry_bench")
crafting.register_type("masonry_bench_bricks", S("Bricks"),
                       "stairs:stair_limestone_brick")
crafting.register_type("masonry_bench_bricks_mortar", S("Bricks & Mortar"),
                       "stairs:stair_limestone_brick_mortar")
crafting.register_type("masonry_bench_blocks", S("Blocks"),
                       "stairs:stair_limestone_block")
crafting.register_type("masonry_bench_blocks_mortar", S("Blocks & Mortar"),
                       "stairs:stair_limestone_block_mortar")
crafting.register_type("masonry_bench_mixing", S("Mixing"),
                       "tech:limestone_block_mortar")
--------------------------------

dofile(path.."/replacement_types.lua")
dofile(path.."/shepherd_labels.lua")
dofile(path.."/sounds.lua")
dofile(path.."/sediment_api.lua")
dofile(path.."/compost.lua")
dofile(path.."/sediment_data.lua")
dofile(path.."/seasons.lua")
dofile(path.."/plant_seasonal_types.lua")
dofile(path.."/plant_growth.lua")
dofile(path.."/plant_api.lua")
dofile(path.."/trees.lua")
dofile(path.."/data_plant.lua")
dofile(path.."/data_rock.lua")
dofile(path.."/rock.lua")
dofile(path.."/ore.lua")
dofile(path.."/plants_and_mushrooms.lua")
dofile(path.."/life.lua")
dofile(path.."/leaf_mark.lua")
dofile(path.."/liquids.lua")
dofile(path.."/flora_spread.lua")
dofile(path.."/dripping_water.lua")
dofile(path.."/complex_workers.lua")
dofile(path.."/moisture_spread.lua")
