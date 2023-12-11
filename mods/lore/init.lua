-------------------------------------
--LORE
------------------------------------


lore = {}
lore.S = minetest.get_translator("lore")
lore.FS = function(...)
    return minetest.formspec_escape(lore.S(...))
end

local modpath = minetest.get_modpath('lore')


dofile(modpath..'/appearance.lua')
dofile(modpath..'/namegen.lua')
dofile(modpath..'/bio_gen.lua')
dofile(modpath..'/char_tab.lua')
dofile(modpath..'/exile_letter.lua')
dofile(modpath..'/login.lua')

dofile(modpath..'/restart.lua')
-------------------------------
