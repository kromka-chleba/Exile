volcano = {}

local modpath = minetest.get_modpath(minetest.get_current_modname())
local ms = mapchunk_shepherd

ms.labels.register("volcano")

dofile(modpath.."/magma_veins.lua")
dofile(modpath.."/volcano_utils.lua")
minetest.register_mapgen_script(modpath.."/voxelarea_iterator.lua")
minetest.register_mapgen_script(modpath.."/volcanoes.lua")
