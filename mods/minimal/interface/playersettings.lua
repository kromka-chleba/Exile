-- Player Settings
-- Stores and sets all player-facing settings through a formspec

minimal = minimal

local S = minimal.S
local mtshowstats = minetest.settings:get_bool("exile_hud_show_stats") or true
local mtwidehud = minetest.settings:get_bool("exile_hud_wide_hotbar") or false
local mtnobreak = minetest.settings:get_bool('exile_nobreaktaker') or false
local mttempscale = minetest.settings:get('exile_temp_scale') or "Celsius"
local temp_tonum = { ["Celsius"] = "1", ["Fahrenheit"] = "2", ["Kelvin"] = "3" }
local temp_fromnum = { "Celsius", "Fahrenheit", "Kelvin" }
local mtcraftmode = minetest.settings:get("exile_craft_mode") or "Use this"
local craft_mode_tonum = { ["Save this"] = 1, ["Use this"] = 2 }
local craft_mode_fromnum = { "Save this", "Use this" }
local mthintbtn = minetest.settings:get_bool("exile_hint_button") or false
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

-- invalid craft mode setting? -> set default
if not craft_mode_tonum[mtcraftmode] then
    mtcraftmode = "Use this"
end

-- Generate Player's settings formspec
-- see (*) comment below on why this is a separate function
local function get_form(playername, meta)
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
    local craft_mode = meta:get("crafting:mode") or mtcraftmode
    local craftnum = craft_mode_tonum[craft_mode] or temp_tonum[mtcraftmode]
    local craft_mode_titles = S("'Save this'") .. "," .. S("'Use this'")
    local hint_btn_plyr = meta:get("crafting:hint_button")
    local recipe_order = meta:get_string("crafting:no_reorder")
    local nomusic = tostring(meta:get("disable_music") or mtnomusic )

    -- is player's hint button setting valid?
    if hint_btn_plyr then
        if (hint_btn_plyr ~= "true") and  (hint_btn_plyr ~= "false") then
            hint_btn_plyr = nil
        end
    end
    -- if not valid -> use server's default
    if not hint_btn_plyr then hint_btn_plyr = tostring(mthintbtn) end

    -- hint button setting only applies with 'Use this'
    local hint_btn_formspec = ""
    if craft_mode == "Use this" then
        hint_btn_formspec = "checkbox[1.5,3.5;hint_button;  "
        .. S("Recipe hints require pressing a button") .. ";"
        .. hint_btn_plyr .. "]"
    end

    local spec =
        "formspec_version[6]"..
        "size[10,8]"..
        "button_exit[9,0.2;0.8,0.75;exit_form;X]"..
        -- Wide HUDbar
        "checkbox[1,1;hud16;  "..
        S("Enable wide HUDbar")..";"..tostring(hud16).."]"..
        -- Numeric stats
        "checkbox[1,1.5;showstats;  "..
        S("Show numeric stats")..";"..tostring(showstats).."]"..
        -- Breaktaker
        "checkbox[1,2;breaktaker;  "..S("Enable Break-taker popup")..";"..
        tostring(breaktaker).."]"..
        -- Full inventory digging
        "checkbox[1,2.5;invburst;  "..
        S("Allow digging with a full inventory")..";"..
        tostring(invburst).."]"..
        -- Craft mode settings
        "label[1,3;" .. S("Crafting mode") .. ":]" ..
        "dropdown[5,2.75;3,0.5;craftmode;" .. craft_mode_titles .. ";" ..
        craftnum .. ";true]" ..
        -- Show hint button
        hint_btn_formspec ..
        -- Fix order for recipes
        "checkbox[1,4;recipe_order;  "..
        S("Keep fixed order for recipes")..";".. recipe_order.."]"..
        -- Music setting
        "checkbox[1,4.5;nomusic;  "..S("Disable music")..";"..nomusic.."]"..
        -- Temperature scale setting
        "label[1,5.25;"..S("Temperature scale")..":]"..
        "dropdown[5,5;3,0.5;tempscale;Celsius,Fahrenheit,Kelvin;"..
        tempnum..";true]"..
        -- GUI theme setting
        "label[1,5.75;"..S("GUI theme")..":]"..
        "dropdown[5,5.5;3,0.5;gui_theme;"..themelist..";"..themenum..";true]"..
        -- HUD Opacity
        "label[1,6.5;"..S("HUD Opacity")..":]"..
        "scrollbaroptions[min=0;max=255;largestep=50]"..
        "scrollbar[2,7;5,0.5;horizontal;HudOpac;"..opacity.."]"
    return spec
end

-- Displays the formspec
-- see (*) comment below on why I separated get_form function
function minimal.show_player_settings(playername, meta)
    minetest.show_formspec(playername, "player_settings",  get_form(playername, meta))
end

-- permit check for settings by other mods
local changed_callbacks = {}
-- player, setting name, setting value, meta
local function setting_changed(player, name, value, meta)
    for _, func in ipairs(changed_callbacks) do
        func(player, name, value, meta)
    end
end

-- not sure it is good/usefull, but adding global function
-- to be able to change break_taker setting outside here
minimal.setting_changed = setting_changed
-- TODO: probably better to define each function in concerned mod
-- here, my concern is I think setting changed does nothing for breaktaker, but I am not sure...

minimal.register_on_player_setting_change = function(func)
    if type(func) ~= "function" then
        error("minimal.register_on_player_setting_change: expected function, got type '"..type(func).."'")
    end
    -- add func to callbacks
    changed_callbacks[#changed_callbacks + 1] = func
end

-- to deal with clicking on the button in sfinv
minetest.register_on_player_receive_fields(function(player, formname, fields)
    -- check if we are in sfinv form
	if formname ~= "" or not sfinv.enabled then
		return false
	end
    -- Get Context
    local name = player:get_player_name()
    local context = sfinv.contexts[name]
    if not context then -- shouldn't happen since opening sfinv generates it
        return false
    end
    -- was settings button pushed ?
    if fields.player_settings then
        -- leave current page (= run the function to close them)
        local oldpage = sfinv.pages[context.page]
        -- run quit function of the old page
        if oldpage and oldpage.on_player_receive_fields then
            oldpage:on_player_receive_fields(player, context, {quit = true})
        end
        --sfinv.set_page(player, "minimal:player_settings")
        minimal.show_player_settings(name, player:get_meta())
        return true -- don't call remaining functions
    end
end)

-- return true if something changed, false else
-- see (*) comment below on why this is a separate function
local function process_receive_fields(player, formname, fields)
    local name = player:get_player_name()
    local meta = player:get_meta()
    -- dropdowns always return a value, so we check if it's changed
    local oldtheme = meta:get("gui_theme") or "default"
    local oldtempscale = meta:get("tempscale") or mttempscale

    -- changing GUI theme
    local num = tonumber(fields.gui_theme) -- table[1] ~= table["1"] !
    if theme_fromnum[num] and theme_fromnum[num] ~= oldtheme then
        meta:set_string("gui_theme", theme_fromnum[num])
        minimal.apply_gui_theme(player, meta, theme_fromnum[num])
        setting_changed(player, "gui_theme", theme_fromnum[num], meta)
        --#TODO we need to close and reopen here
        minimal.show_player_settings(name, meta)
        return true
    end
    num = tonumber(fields.tempscale)
    if temp_fromnum[num] and temp_fromnum[num] ~= oldtempscale then
        meta:set_string("tempscale", temp_fromnum[num])
        setting_changed(player, "tempscale", temp_fromnum[num], meta)
    end

    -- setting HUD Opacity
    if fields.HudOpac then
        local ev = minetest.explode_scrollbar_event(fields.HudOpac)
        if ev.type == "CHG" then
            meta:set_string("hud_opacity", ev.value)
            setting_changed(player, "hud_opacity", tonumber(ev.value), meta)
        end
    end
    -- setting large HUD
    if fields.hud16 then
        meta:set_string("hud16", fields.hud16)
        minimal.set_hotbar(player, fields.hud16)
        setting_changed(player, "hud16", tobool(fields.hud16), meta)
    end
    -- setting numeric stats
    if fields.showstats then
        meta:set_string("hud_show_stats", fields.showstats)
        setting_changed(player, "hud_show_stats", tobool(fields.showstats), meta)
    end
    -- setting Breaktaker pop-up on/off
    if fields.breaktaker then
        meta:set_string("breaktaker", fields.breaktaker)
        setting_changed(player, "breaktaker", tobool(fields.breaktaker), meta)
    end
    -- setting possibility to drop item on full inv
    if fields.invburst then
        meta:set_string("drop_on_full_inv", fields.invburst)
        setting_changed(player, "drop_on_full_inv", tobool(fields.invburst), meta)
    end
    -- setting craft mode
    if fields.craftmode then
        num = tonumber(fields.craftmode)
        local old_craft_mode = meta:get("crafting:mode") or mtcraftmode
        local mode = craft_mode_fromnum[num]
        if mode and mode ~= old_craft_mode then
            meta:set_string("crafting:mode", mode)
            setting_changed(player, "crafting:mode", mode, meta)
            -- update formspec
            local playername = player:get_player_name()
            minetest.show_formspec(playername, "player_settings",
                                   get_form(playername, meta))
        end
    end
    if fields.hint_button then
        meta:set_string("crafting:hint_button", fields.hint_button)
        setting_changed(player, "crafting:hint_button", tobool(fields.hint_button), meta)
    end
    if fields.recipe_order then
        meta:set_string("crafting:no_reorder", fields.recipe_order)
        setting_changed(player, "crafting:no_reorder", tobool(fields.recipe_order), meta)
    end
    -- setting music on/off
    if fields.nomusic then
        meta:set_string("disable_music", fields.nomusic)
        setting_changed(player, "disable_music", tobool(fields.nomusic), meta)
        --[[ #TODO: put music handling into minimal where it belongs
        (now handled in lore fully instead, what do we do now?)]]
    end
end

-- see (*) comment below on why I separated process_receive_fields
minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname ~= "player_settings" then
		return false
	else
        return process_receive_fields(player, formname, fields)
    end
end)

--(*)
--[[ Following (+ the separation of get_formspec and process_receive_field)
    was made in order to be able to pass that formspec in sfinv.
    However, this leads to some issue do to the fact that :

    1) since it is not a real tab (but a button),
    we can't move to "crafting tab" again when clicking on it,
    because tab1 is already selected by default.
    This point could change if we one day use buttons instead of tabs

    2) I didn't find a good way to close/reopen inv formspec to update the theme (refresh) when changing them,
    without leaving and coming back with inv key.
    Manually reopening with minetest.show_formspec(player_name, "", "")
    reopens it but... then the update are not redisplayed, unless we use the inv key to close and reopen again.
    We would need a way to simulate that key.
    I don't know how to do it, or if it is possible, so this is pending for now.

    I leave following code and functions changes in case someone wants to try it again, with more knowledge,
    or if minetest's code evolves to give us those needed functionnality on closing/reopening inv formspec in code.
    ]]

-- Register player_setting formspec as inv tab
--[[do
    if minetest.global_exists("sfinv") then
        sfinv.register_page(
        "minimal:player_settings", {
            title = ("Settings"),
            is_in_nav = function(player, context) return false end,
            get = function(self, player, context)
                local formspec = get_form(player:get_player_name(), player:get_meta())
                return sfinv.make_formspec_for_exile(player, context, formspec, false)
            end,
            on_player_receive_fields = function(self, player,
                context, fields)
                -- if something changed, redraw the page
                if process_receive_fields(player, "", fields) then
                    sfinv.set_player_inventory_formspec(player, context)
                end
            end,
        })
    end
end]]
