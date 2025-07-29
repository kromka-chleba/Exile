minimal = {
    stack_max_bulky = 2,
    stack_max_medium = 24,
    stack_max_light = 288,
    --hand base abilities
    hand_punch_int = 0.8,
    hand_max_lvl = 1,
    hand_crac = 3.5,
    hand_chop = 1.5,
    hand_crum = 1.0,
    hand_snap = 0.5,
    hand_dmg = 1,

    t_scale2 = 3,
    t_scale1 = 6,

}
exile = minimal -- Adding to begin transition to renamed minimal as exile.
minimal.S = minetest.get_translator("minimal")
minimal.FS = function(...)
    return minetest.formspec_escape(minimal.S(...))
end
local modpath=minetest.get_modpath('minimal')
dofile(modpath..'/debug.lua')
dofile(modpath..'/compat.lua')
dofile(modpath..'/settingswarn.lua')
dofile(modpath..'/aliases.lua')
dofile(modpath..'/overrides.lua')
dofile(modpath..'/protection.lua')
dofile(modpath..'/metadata.lua')
dofile(modpath..'/triggers.lua')
dofile(modpath..'/zones.lua')
dofile(modpath..'/utility/init.lua')
dofile(modpath..'/interface/init.lua')
dofile(modpath..'/witt_exile/init.lua')
dofile(modpath..'/buildclip.lua')

dofile(modpath..'/currentrevision.lua')
dofile(modpath..'/storage_watcher_api.lua')
dofile(modpath..'/storage_api.lua')


-- to force tabs order in sfinv, not sure where to put that.
-- adds a dependency to sfinv
core.register_on_mods_loaded( function ()
    local tab_list = {}
    if core.global_exists("creative") then
        for _, name in ipairs(creative.tab_list) do
            tab_list[#tab_list +1] = "creative:"..name
        end
    end
    -- register Exile's pages
    if core.global_exists("crafting") then
         tab_list[#tab_list +1] = "crafting:crafting"
    end
    if core.global_exists("player_api") then
        tab_list[#tab_list +1] = "clothing:clothing"
    end
    if core.global_exists("lore") then
        tab_list[#tab_list +1] = "lore:char_tab"
    end
    sfinv.set_tabs(tab_list)
end)

minetest.register_on_joinplayer(function(player)
        local p_name = player:get_player_name()
        --Custom small inventory
        minetest.get_inventory({type="player", name=p_name}):set_size("main", 16)
        if player.set_lighting then
            player:set_lighting({
                    shadows = { intensity = 0.33 }
            })
        end
end)
