-------------------------------------
--BED REST
--based on Minetest game Beds
------------------------------------
--
bed_rest = {}
bed_rest.player = {}
bed_rest.bed_position = {}
bed_rest.pos = {}
bed_rest.level = {}
bed_rest.store = minetest.get_mod_storage()

bed_rest.session_start = {}
bed_rest.session_limit = {}



local modpath = minetest.get_modpath("bed_rest")

-- Load files

dofile(modpath .. "/break_taker.lua")
dofile(modpath .. "/functions.lua")
dofile(modpath .. "/api.lua")
dofile(modpath .. "/bed_clear.lua")

local temp = minetest.deserialize(bed_rest.store:get_string("bedrest"), true)
if temp then
    bed_rest.level = temp["level"]
    bed_rest.player = temp["player"]
    bed_rest.pos = temp["pos"]
    bed_rest.bed_position = temp["bed_position"]
end
