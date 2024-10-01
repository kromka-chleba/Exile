-- Player Settings
-- Stores and sets all player-facing settings through a formspec

minimal = minimal
lore = lore or {}

local S = minimal.S
local mtshowstats = minetest.settings:get_bool("exile_hud_show_stats") or true
local mtwidehud = minetest.settings:get_bool("exile_hud_wide_hotbar") or false
local mtnobreak = minetest.settings:get_bool('exile_nobreaktaker') or false
local mttempscale = minetest.settings:get('exile_temp_scale') or "Celsius"
local temp_tonum = { ["Celsius"] = "1", ["Fahrenheit"] = "2", ["Kelvin"] = "3" }
local temp_fromnum = { "Celsius", "Fahrenheit", "Kelvin" }
local mthudopacity = tonumber(minetest.settings:get(
                                  "exile_hud_icon_transparency")) or 127
local mtinvburst = minetest.settings:get_bool("exile_drop_on_full_inv") or false
local mtnomusic = minetest.settings:get_bool("exile_disable_music") or false

local theme_fromnum = minimal.get_gui_theme_list() -- numeric table of theme names
local theme_tonum = {} -- A reverse lookup, enter theme name, get index number
for i = 1, #theme_fromnum do
    theme_tonum[theme_fromnum[i]] = i
end

local function tobool(check)
    if check == "true" then
        return true
    elseif check == "false" then
        return false
    end
end

if not temp_tonum[mttempscale] then
    -- invalid setting, warned in settingswarn.lua
    mttempscale = "Celsius"
end

function minimal.show_player_settings(playername, meta)
    local hud16 = meta:get("hud16") or mtwidehud
    local showstats = meta:get("hud_show_stats") or mtshowstats
    local breaktaker = meta:get("breaktaker") or (not mtnobreak)
    local tempscale = meta:get("tempscale") or mttempscale
    local tempnum = temp_tonum[tempscale] or temp_tonum[mttempscale]
    local theme = meta:get("gui_theme") or "default"
    local themelist = table.concat(minimal.get_gui_theme_titles(),",")
    local themenum = tostring(theme_tonum[theme])
    local opacity = tostring(meta:get("hud_opacity") or mthudopacity)
    local invburst = tostring(meta:get("drop_on_full_inv") or mtinvburst)
    local nomusic = tostring(meta:get("disable_music") or mtnomusic )

    local spec =
        "formspec_version[6]"..
        "size[10,7]"..
        "button_exit[9,0.2;0.8,0.75;exit_form;X]"..
        "checkbox[1,1;hud16;  "..
        S("Enable wide HUDbar")..";"..tostring(hud16).."]"..
        "checkbox[1,1.5;showstats;  "..
        S("Show numeric stats")..";"..tostring(showstats).."]"..
        "checkbox[1,2;breaktaker;  "..S("Enable Break-taker popup")..";"..
        tostring(breaktaker).."]"..
        "checkbox[1,2.5;invburst;  "..
        S("Allow digging with a full inventory")..";"..
        tostring(invburst).."]"..
        "checkbox[1,3;nomusic;  "..S("Disable music")..";"..nomusic.."]"..
        "label[1,4;"..S("Temperature scale")..":]"..
        "dropdown[5,3.75;3,0.5;tempscale;Celsius,Fahrenheit,Kelvin;"..
        tempnum..";true]"..
        "label[1,4.75;"..S("GUI theme")..":]"..
        "dropdown[5,4.5;3,0.5;gui_theme;"..themelist..";"..themenum..";true]"..
        "label[1,5.8;"..S("HUD Opacity level")..":]"..
        "scrollbaroptions[min=0;max=255;largestep=50]"..
        "scrollbar[4,5.5.5;5,0.5;horizontal;HudOpac;"..opacity.."]"
    minetest.show_formspec(playername, "player_settings", spec)
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
        local name = player:get_player_name()
        if fields.player_settings == "" then
            -- Pressed a button named "player_settings", from char tab or elsewhere
            local meta = player:get_meta()
            minetest.after(0.1, function()
                               minimal.show_player_settings(name, meta)
            end)
        end
        if formname == "player_settings" then
            local meta = player:get_meta()
            -- dropdowns always return a value, so we check if it's changed
            local oldtheme = meta:get("gui_theme") or "default"
            local oldtempscale = meta:get("tempscale") or mttempscale

            local reopen = false
            local num = tonumber(fields.gui_theme) -- table[1] ~= table["1"] !
            local new_theme = theme_fromnum[num]
            if new_theme and new_theme ~= oldtheme then
                meta:set_string("gui_theme", new_theme)
                minimal.apply_gui_theme(player, meta, new_theme)
                reopen = true
            end
            num = tonumber(fields.tempscale)
            if temp_fromnum[num] and temp_fromnum[num] ~= oldtempscale then
                meta:set_string("tempscale", temp_fromnum[num])
            end
            if fields.HudOpac then
                local ev = minetest.explode_scrollbar_event(fields.HudOpac)
                if ev.type == "CHG" then
                    meta:set_string("hud_opacity", ev.value)
                    HEALTH.hud_update_settings(name, { opacity = ev.value })
                end
            end
            if fields.hud16 then
                meta:set_string("hud16", fields.hud16)
                minimal.set_hotbar(player, fields.hud16)
            end
            if fields.showstats then
                meta:set_string("hud_show_stats", fields.showstats)
                HEALTH.hud_update_settings(name,
                                           { showstats = tobool(
                                                 fields.showstats) })
            end
            if fields.breaktaker then
                meta:set_string("breaktaker", fields.breaktaker)
            end
            if fields.invburst then
                meta:set_string("drop_on_full_inv", fields.invburst)
            end
            if fields.nomusic then
                meta:set_string("disable_music", fields.nomusic)
                if fields.nomusic == "true" then lore.stopmusic(name) end
            end
            if reopen == true then
                minetest.close_formspec(name, "player_settings")
                minetest.after(0.2, function()
                                   minimal.show_player_settings(name, meta)
                end)
            end
        end
end)
