---------------------------------------------
---- Mapchunk shepherd
---------------------------------------------

-- Globals
mapchunk_shepherd = {}
mapchunk_shepherd.mod_storage = minetest.get_mod_storage()
mapchunk_shepherd.S = minetest.get_translator("mapchunk_shepherd")
local modpath = minetest.get_modpath('mapchunk_shepherd')

dofile(modpath.."/labels.lua")
dofile(modpath.."/chunk_utils.lua")
dofile(modpath.."/dogs.lua")
dofile(modpath.."/shepherd.lua")
