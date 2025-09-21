-- #TODO -----------------------------------------------------------------------

-- - remove commented get_hint_state() (replaced by init_hint_states())

-- The following should be obsolete since 'Use this' or 'Save this' is to be
-- switched by a setting instead of a dropdown in the crafting formspec:
-- - commented code for the dropbox 'input_option' in FS_input_list() and
-- - process_receive_fields()

-- Dealing with crafting tab in inventory formspec

local minimal = minimal
local crafting = crafting

local S = minetest.get_translator("crafting")
local tofstring = function(t) return table.concat(t,"") end

local c_color= "#3d5a74" -- craftable color
local u_color = "#482d2d" -- uncraftable color
local p_color = "#5a553c"-- possible color

-- input inventory to use for crafting (player setting)
--[[ format of table is :
    `id` = index in dropdown
    label` = label in formspec
    `inputs` = table of inv lists to use for inputs
    `no_craft_from_main` = set true if "main" is not in craftable_list
    `i_color` = color of input list's background
    `get_m_color` = returns color of main list's background
    `get_r_bg` = returns background image(color) of a recipe
    `hint_btn` = if hint button is displayed or not
    )
]]
local input_options = {
    [2] = {
        label = " Use only", -- label in dropdown
        craftable_lists = {"input_items"}, -- inv list used for craft
        possible_lists = {"main"}, -- used to check what could be transferred
        total_lists = {"input_items", "main"},
        no_craft_from_main = true,
        i_color = c_color, -- bgcolor behind input inventory
        get_m_color = function(cache) -- bgcolor behind main inventory
            if cache.possible_hint then -- hint btn activated
                return p_color -- possible color
            else
                return u_color
                -- replace by following line to get "no color"
                -- return nil -- no color if "hint" disabled.
            end
        end,
        get_r_cbg = function(cache, p_recipe)
            local selected = (cache.selected_id == p_recipe.recipe.id)
            local suffix = selected and "_selected.png" or ".png"

            local status = p_recipe.craftable
            local hints = cache.possible_hint
            local filter = cache.input_filter
            if status then
                -- craftable
                return "crafting_slot_craftable" .. suffix

            elseif not filter and p_recipe.possible then
                -- possible
                if cache.hint_btn then
                    return "crafting_slot_possible" .. suffix
                else
                    -- effectively the same as craftable, because pressing
                    -- the recipe button will result in the same state
                    return "crafting_slot_craftable" .. suffix
                end
            elseif p_recipe.craftable_partial
                or hints and not filter and p_recipe.possible_partial then

                -- some inputs missing
                return "crafting_slot_partial" .. suffix

            elseif status == false then -- uncraftable
            -- replace by following to have black recipes if hint is off
            -- so that uncraftable may be transferred
            --[[
            elseif status == false and cache.possible_hint then
                uncraftable and hint is ON
            --]]
                return "crafting_slot_uncraftable" .. suffix
            else -- uncraftable but hint OFF, or unknows craftable state
                return 'crafting_slot_empty.png'
            end
        end,
        has_hint_btn = function(player_meta) -- is the hint button enabled?
            local player_settg = player_meta:get_string("crafting:hint_button")
            if (player_settg ~= "") then -- > use existing player setting
                return (player_settg == "true")
            end
            -- player setting does not yet exist
            -- if present, use server setting, otherwise use Exile's default
            local dflt_exile = false
            local dflt_srv = minetest.settings:get_bool("exile_hint_button")
            local result = (dflt_srv ~= nil) and dflt_srv or dflt_exile
            player_meta:set_string("crafting:hint_button", tostring(result))
            return result
        end,
    },
    [1] = {
        label = " Do not use",
        craftable_lists = {'main'},
        possible_lists = {},
        total_lists = {'main'},
        i_color = u_color,
        get_m_color = function(cache) -- bgcolor behind main inventory
            return c_color
            -- replace by following line to get "no color"
            -- return nil -- no color if "hint" disabled.
        end,
        get_r_cbg = function(cache, p_recipe)
            local selected = (cache.selected_id == p_recipe.recipe.id)
            local suffix = selected and "_selected.png" or ".png"

            local status = p_recipe.craftable
            if status then -- craftable
                return "crafting_slot_craftable" .. suffix

            elseif p_recipe.craftable_partial then -- some inputs missing
                return "crafting_slot_partial" .. suffix

            elseif status == false then -- uncraftable
                return "crafting_slot_uncraftable" .. suffix

            else -- unknows craftable state
                return 'crafting_slot_empty.png'

            end
        end,
        has_hint_btn = function(player_meta) -- is the hint button enabled?
            return false
        end,
    },
    -- [3] = {
    --     label = " Use first",
    --     craftable_lists = {"input_items",'main'},
    --     i_color = c_color,
    --     m_color = c_color
    -- }
}

-- option "Use this" for new player by default, but setting has precedence
local default_option_exile = "Use this"
local option_to_idx = { ["Save this"] = 1, ["Use this"] = 2 }
local default_option_server = minetest.settings:get("exile_craft_mode")
local default_option_name = default_option_server or default_option_exile
local default_option_idx = option_to_idx[default_option_name]

-- Cache initialisations -------------------------------------------------------

-- table of crafting cache per player
--[[The inventory formspec is cached for each player like this:
    FS_cache[player_name] = {
        `player_name` = name of the player as in index
        `pInv` = player inventory, in order to be able to just pass cache as parameter

        -- station (on right click)
        -----------------------------
        `station` = {name = .., title= ...}

        -- tools (in tools_ant_types.lua)
        ------------------------------
        `tool_list` = list of tools I can use, currently {hand,station used}
        `sToolID` = selected tool index in list -- set to 1 by default
        `sTool`  = selected tool name

        -- craft types (subtabs) (in tools_ant_types.lua)
        ------------------------------
        `sTab`   = 1 : index of selected_craft_tab
        `cTabs` = nil : "hand", "hand_tool", etc; all output tool type sections
        `sLevel` = selected craft_types'level

        -- recipes lists (in recipe_panel.lua)
        -----------------------------
        `c_recipes` = nil : list of craftable recipes to display
        `p_recipes` = nil : list of possible recipe if everything is used
        `ipa_recipes` = nil : list of recipes with inputs partially available
        `u_recipes` = nil : list of uncraftable recipes to display
        `recipes` = nil : unsorted list of recipes
        `selected_id` = nil : id of selected recipe

        -- recipe panel
        ---------------------------
        `sScroll` = selected scroll level -- needed to draw scroll container

        -- search panel (functions in apply_filters.lua)
        ---------------------------
        `sSearch` = nil : current filter in search field

        -- The Following are tables of formspec strings
        -- to trigger redraw of a section, set the section to nil
        -- eg) to regenerate the recipes list, set
        -- cache.FS_recipes = nil
        -------------------------------------------------------
        `FS_tool_panel` = nil -- tools
        `FS_ctabs` = nil -- craft tabs
        `FS_recipes` = nil -- recipes list panel
        `FS_search` = nil, -- search container
        `FS_input_list` =nil -- input panel

        -- player settings
        -------------------
        `lang` = player's lang code for translation

        `craft_input` = table of inv to use to craft
        `hint_btn` = hint button visible?
        `possible_hint` = false --  is the "hint" button activated ?
        `input_filter` = do put items in input panel trigger automatic filter ?

        `sorted` = true -- do we sort the recipes (color and order) ?
        `to_sort` = true -- do I need to resort order of the recipes ?
        `order` -- do we want recipes to be ordered by crafting state ?

        `open` -- formspec's name IF it is open. nil else.
        Will be reopen by any action on the formspec
        (since no open inventory callback, it seems to be the best we can do)
        WARNING: Will be "nil" at cache creation,
        probably ok since currently cache is created only on first arrival on the page (clothing page as default)
    }
    If updated, a section should be set to nil to force a redraw.
    only sections cleared are recreated via crafting.make_crafting_formspec
]]
local FS_cache = {}

-- functions for instance of "cache"
local cache_func = {}
cache_func.__index = cache_func

--Basic functions --------------------------------------------------------------

--[[return table of inv lists to use for input
according to player's setting in cache]]
-- criteria is currently only "craftable","possible" or "total"
function cache_func:get_craft_input(criteria)
    if not (criteria == "possible" or criteria == "total") then
        if criteria and criteria ~= "craftable" then
            -- not nil but invalid, warn
            core.log ("error", "wrong criteria was passed to cache:get_craft_input function")
        end
        criteria = "craftable"
    end
    local option = input_options[self.craft_input]
    if option then
        return option[criteria .. "_lists"]
    else
        core.log("warning", "invalid 'craft_input' setting in crafting cache,"
                 .. "  using default setting "
                 .. default_option_name)
        self.craft_input = default_option_idx
        return input_options[default_option_idx][criteria .. "_lists"]
    end
end

--return table of settings matching cache's `craft_input` setting
-- if invalid option, returns the first one
-- #TODO could it be passed local ?
function cache_func:get_craft_mode()
    local option = input_options[self.craft_input]
    if option then
        return option
    else
        core.log("warning", "invalid 'craft_input' setting in crafting cache,"
                 .. "  using default setting "
                 .. default_option_name)
        self.craft_input = default_option_idx
        return input_options[default_option_idx]
    end
end

-- gets itemhash matching input inv setting
-- #TODO not sure to keep this item_hash things in here
-- criteria is currently only "craftable","possible" or "total)
function cache_func:get_input_hash(criteria, pInv)
    pInv = pInv or self.pInv
    return crafting.get_item_hash(pInv, self:get_craft_input(criteria))
end

-- to register instance functions from outside
function crafting.register_cache_function (name, func)
    cache_func[name] = func
end

-- local function get_hint_state(i_option, player_meta)
    --[[ option to initiate with player's meta
    if input_options[i_option].hint_btn then
        --  it is on in player_settings (I left with on)
        -- remember the setting. Note: new player will have 0 in meta
        return (player_meta:get_int("crafting:possible_hint") == 1)
    else
        return false
    end]]
    -- option to initiate it with always false
--    return false
-- end

-- Updates whether the hint button and hints are enabled.
local function init_hint_states(cache, player_meta)
    -- hints require pressing a button? (default: false)
    cache.hint_btn = input_options[cache.craft_input].has_hint_btn(player_meta)
    -- updates hint's state
    if cache.hint_btn then
        -- start with hints disabled
        cache.possible_hint = false
    else
        -- enable hints
        cache.possible_hint = true
    end
end

-- saves input option in cache and updates hints state accordingly
local function set_cache_input_options(cache, option_name, player_meta)
    local idx = option_to_idx[option_name]
    if not idx then -- invalid -> replace by default option
        idx = default_option_idx
        player_meta:set_string("crafting:mode", default_option_name)
    end

    if idx ~= cache.craft_input then
        cache.craft_input = idx
        -- updates hint button's state
        init_hint_states(cache, player_meta)
        -- assure refresh for input panel (background)
        cache.FS_input_list = nil
    end
end

-- save station's info in cache and update tool list/reset tabs if needed
local function cache_set_station(cache, station)
    -- add station's info to cache
    cache.station = station
    -- set tools and craft tabs (in tools_and_types.lua)
    local station_name = station and station.name
    -- generates corresponding tools list
    cache.tool_list = crafting.generate_tools_list(station_name)
    -- set tool panel and crafting tabs
    cache:set_tool(station_name) -- recipes panel will be reset here
end

-- generate a new cache and put is in FS_cache[player_name]
-- `station` is optional, same format as in cache.station
local function new_cache(player, station)
    if not player then
        core.log ("no player to initiate crafting cache for")
        return nil
    end

    -- creates empty table
    local cache = {}

    -- player's language for translations
    local player_name = player:get_player_name()
    cache.player_name = player_name -- TODO store it or regenerate it ?
    cache.pInv = player:get_inventory() -- TODO store it or regenerate it ?
    cache.lang = minetest.get_player_information(player_name).lang_code

    -- player settings and input mode ---------------------
    -- input mode--
    local meta = player:get_meta()
    -- do we want recipes to be reordered by crafting state ?
    -- order, unless explicity specifiate not too (no_order == "false")
    cache.order = (meta:get_string("crafting:no_reorder") ~= "true")

    local option = meta:get("crafting:mode")
    set_cache_input_options(cache, option, meta)

    -- Automatic filter checkbox --
    cache.input_filter = false -- never active on opening.

    -- adds modification and initiate functions metatable
    setmetatable(cache, cache_func)

    -- set station, tools, tabs and recipes
    cache_set_station(cache, station)

    -- recipes panel ---
    -- tell if we want to sort recipes list or not (colors)
    cache.sorted = true --TODO for future setting, currently always true

    FS_cache[player_name] = cache
    return cache
end

-- empty table when player leave :#TODO should we or not ?
core.register_on_leaveplayer(function(player)
    local player_name = player:get_player_name()
        FS_cache[player_name] = nil
    end)

-- get player's cache
-- if `generate` is true, generate it if non existant
-- `station` is optional, same format as in cache.station
function crafting.get_FS_cache(player, generate, station)
    if not player then return nil end
    -- get the FS cache if already existant
    local cache = FS_cache[player:get_player_name()]
    -- else generates it
    if not cache then
        if generate then
            -- that function modified player's cache and return that cache
            cache = new_cache(player, station)
        end
    end
    return cache
end

function crafting.reset_FS_cache(player)
    FS_cache[player:get_player_name()] = new_cache(player)
end

-- localize
local get_FS_cache = crafting.get_FS_cache

-- set crafting station to given station
--[[
    * `station` is a table with following fields:
    {
    `name`: the name of the station (has to be a valid station)
    `title`: string to be displayed above the formspec
    }
    * `cache` is optional, will be get from player if missing
--]]
function crafting.set_station(player, station, cache)
    -- get cache if not given
    cache = cache or get_FS_cache(player, true, station)
    -- updates station info if we changed station
    cache_set_station(cache, station)
    return cache
end

-- register action in case order field is changed in player_setting
minimal.register_on_player_setting_change(
    function(player, meta_name, value, meta)
        if meta_name == "crafting:mode" then
            local cache = crafting.get_FS_cache(player)
            -- no need to change if cache does not yet exists
            -- initialization is done during cache generation
            if cache then
                set_cache_input_options(cache, value, meta)
            end
        elseif meta_name == "crafting:hint_button" then
            local cache = crafting.get_FS_cache(player)
            -- no need to change if cache does not yet exists
            -- initialization is done during cache generation
            if cache then
                init_hint_states(cache, meta)
            end
        elseif meta_name == "crafting:no_reorder" then
            local cache = crafting.get_FS_cache(player)
            -- no need to change if no cache
            -- field will be check when cache is generated
            if cache then
                cache.order =  not value
            end
        end
    end)

-- Formspec generation ---------------------------------------------------------

local esc = minetest.formspec_escape

--[[ This is the function to call to create or update the formspec.
    It returns the full crafting formspec to be displayed
    updates are triggered by the section to redraw set to nil :
    eg cache.FS_recipes = nil to redraw recipes list.
    ]]
-- `cache` is optional and will be get from player if not given
function crafting.make_crafting_formspec(player, cache)
    local player_name = player:get_player_name()
    if not (player_name and player_name ~= "") then
        return nil -- no player name
    end
    -- initiates FS_cache[player_name] if non existant
    -- in that case station will be "nil"
    cache = cache or get_FS_cache(player, true)

    -- output will be the formspec string
    local output = {
        'container[0,0]'
    }

    local mode = cache.craft_input

    -- Inventory List part-----------------------------------------------------

    output[#output + 1] = 'container[0.8,7.2]'

    -- adds background color under the main inventory list, if needed
    local input_mode = cache:get_craft_mode()
    local main_color = input_mode.get_m_color(cache)
    if main_color then
        output[#output + 1] = "box[-0.18,-0.18;10.1,2.6;".. main_color .. "]"
    end

    -- display main inventory list
    output[#output + 1] = tofstring({
        'style_type[list;size=;spacing=]',
        'list[current_player;main;0,0;8,2;0]'
    })

    output[#output + 1] = 'container_end[]'

    -- re-add worldedit gui button if that exists -----------------------------
    local we_x = (mode == 2) and "3.5" or "9.75"

    if minetest.global_exists("worldedit")
        and minetest.get_modpath("worldedit_gui")
        and minetest.check_player_privs(player, {worldedit=true}) then
        output[#output + 1] = tofstring({
            "image_button[" .. we_x .. ",0.5;0.75,0.75;",
            "inventory_plus_worldedit_gui.png;worldedit_gui;]",
            "tooltip[worldedit_gui;Edit your World!]"
        })
    end

    -- Trash ------------------------------------------------------------------

    if mode == 2 then
        output[#output + 1] ="image[0.48,5.93;0.8,0.8;creative_trash_icon.png]"
        output[#output + 1] = "list[detached:creative_trash;main;0.4,5.8;1,1;]"
    else
        output[#output + 1] = "image[9.6,5.93;0.8,0.8;creative_trash_icon.png]"
        output[#output + 1] ="list[detached:creative_trash;main;9.52,5.8;1,1;]"
    end

    -- Tool types part --------------------------------------------------------

    if not cache.FS_tool_panel then
        -- build in gui/tools_and_stations.lua
        cache.FS_tool_panel = cache:get_tool_panel(mode)
    end
    if mode == 2 then
        output[#output + 1] = "container[.4,0.45]"
    else
        output[#output + 1] = "container[.4,0.6]"
    end
    output[#output + 1] = cache.FS_tool_panel
    output[#output + 1] = "container_end[]"

    -- Recipes List part (Tabs + Recipes list block) --------------------------
    local recipes_y = 0.45
    local panel_offset = (mode == 2) and "4.7" or "3.5"
    output[#output + 1] = "container[" .. panel_offset
    output[#output + 1] = "," .. recipes_y .. "]"

    -- Craft tabs above the recipes panel
    if not cache.FS_ctabs then
        -- in gui/tools_and_types.lua
        cache.FS_ctabs = cache:get_craft_tabs()
    end
    output[#output + 1] = cache.FS_ctabs

    if not cache.FS_recipes then
        -- in gui/recipes_panel.lua
        local height
        cache.FS_recipes, height = cache:get_recipes_panel(0, 0.75,
                                                           mode)
        cache.recipes_height = height + 0.75
    end
    output[#output + 1] = cache.FS_recipes

    output[#output + 1] = 'container_end[]'

    -- Search field part ------------------------------------------------------

    local spos_x = (mode == 2) and "4.7," or "3.5,"
    local spos_y_offset = (mode == 2) and 0 or 0.15
    local spos = spos_x .. (recipes_y + cache.recipes_height + spos_y_offset)

    output[#output + 1] = "container[" .. spos .. "]"
    if cache.FS_search == nil then
        -- Build search field to be in container
        cache.FS_search = tofstring({
            'style_type[image_button;border=false;bgimg_middle=0]',
            'field_close_on_enter[crafting_search;false]',
            'field[0,0;3.0,0.6;crafting_search;;'.. (cache.sSearch or "") .. ']',
            'image_button[3.1,0;0.6,0.6;creative_search_icon.png;craft_filter;]',
            'image_button[3.8,0;0.6,0.6;creative_clear_icon.png;search_reset;]',
            "tooltip[craft_filter;" .. esc(S("Filter")) .. "]",
            "tooltip[search_reset;" .. esc(S("Reset")) .. "]"
        }
    )
    end
    output[#output + 1] = cache.FS_search

    -- hint button - attached to search bar
    if cache.hint_btn then
        if cache.possible_hint then
            output[#output + 1] = "style[hint;bgcolor=white; bgcolor_hovered=white; bgcolor_pressed=white]"
        else
            output[#output + 1] = "style[hint;bgimg=;bgcolor=black]"
        end

        output[#output + 1] = 'button[4.5,0;1.5,0.6;hint;'.. S("Hint") .. ']'
    end
    output[#output + 1] = 'container_end[]'

    -- Craft buttons part -----------------------------------------------------

    -- determine possible quantities and button image
    local quantities = nil
    local btnimg = "selected.png"
    if cache.selected_id then
       quantities = cache:get_output_quantities()
       local min = quantities and quantities[1]
       if min and min > 0 then btnimg = "crafting_craft_button_enabled.png" end
    end
    quantities = quantities or {0}

    -- add one button + tool tip per quantity
    local tool_tips = cache:get_craft_btn_tool_tips(quantities)

    -- arrange buttons depending on input mode
    if mode == 2 then
        output[#output + 1] = "container[3.5,1.4,]"

        -- dynamic positions of the buttons - depending on #quantities
        local pos = 1.4 - (#quantities - 1) * 0.467

        for i, q in ipairs(quantities) do
            local qty_id = "qty_" .. i
            local text = q > 0 and q .. "x" or core.colorize("#000", q .. "x")
            output[#output + 1] = "image_button[0," .. pos .. ";1,0.6;"
            output[#output + 1] = btnimg .. ';'..qty_id..';' .. text
            output[#output + 1] = ";;;" .. btnimg .. "^[transformFY]"
            if tool_tips and tool_tips[i] then
                output[#output + 1] = "tooltip[" .. qty_id .. ";"
                output[#output + 1] = tool_tips[i] .. "]"
            end
            output[#output + 1] = "label[-0.3," .. (pos + 0.325) .. ";>]"
            pos = pos + 0.933
        end

    -- filter button for 'Use this' mode -------------------------------------
        -- hides / unhides uncraftable recipes (and the sleeping spot) based
        -- on what's in the input grid
        -- #NOTE: When off the highlighting depends on what's available in
        --        both inventory lists

        pos = math.max(pos, 3.1 + 0.35 * (#quantities - 2))
        local btn_bg
        local btn_pos
        if cache.input_filter then
            btn_bg = "crafting_filter_on_bg.png"
            btnimg = "crafting_filter_on.png"
            output[#output + 1] = "label[-0.35," .. (pos + 0.325) .. ";>]"
            output[#output + 1] = "label[0.95," .. (pos + 0.325) .. ";>]"
            btn_pos = "-0.13," .. pos
        else
            btn_bg = "crafting_filter_off_bg.png"
            btnimg = "crafting_filter_on.png"
            btn_pos = "0," .. pos
        end

        output[#output + 1] = "image[" .. btn_pos .. ";1,0.6;" .. btn_bg .. "]"
        output[#output + 1] = "image_button[" .. btn_pos .. ";1,0.6;"
        output[#output + 1] = btnimg .. ";i_filter;]"

        output[#output + 1] = "container_end[]"
    else
        output[#output + 1] = "container[3.5,6.0,]"

        -- dynamic positions of the buttons - depending on #quantities
        local pos = 1.8 - (#quantities - 1) * 0.6

        for i, q in ipairs(quantities) do
            local qty_id = "qty_" .. i
            local text = q > 0 and q .. "x" or core.colorize("#000", q .. "x")
            output[#output + 1] = "image_button[" .. pos .. ",0;1,0.6;"
            output[#output + 1] = btnimg .. ";" .. qty_id .. ";" .. text
            output[#output + 1] = ";;;" .. btnimg .. "^[transformFY]"
            if tool_tips and tool_tips[i] then
                output[#output + 1] = "tooltip[" .. qty_id .. ";"
                output[#output + 1] = tool_tips[i] .. "]"
            end
            output[#output + 1] = "label[" .. (pos + 0.45) .. ",0.9;^]"
            pos = pos + 1.2
        end

    -- filter button for 'Save this' mode -------------------------------------
        -- hides / unhides uncraftable recipes (and the sleeping spot)
        pos = 4.8
        output[#output + 1] = "label[" .. (pos + 0.45) .. ",0.9;^]"

        local btn_bg
        if cache.input_filter then
            btn_bg = "crafting_filter_on_bg.png"
            btnimg = "crafting_filter_on.png"
        else
            btn_bg = "crafting_filter_on_bg.png"
            btnimg = "crafting_filter_off.png"
        end

        output[#output + 1] = "image[" .. pos .. ",0;1,0.6;" .. btn_bg .. "]"
        output[#output + 1] = "image_button[" .. pos .. ",0;1,0.6;"
        output[#output + 1] = btnimg .. ";i_filter;]"

        output[#output + 1] = "container_end[]"
    end

    -- Input List part---------------------------------------------------------

    local function FS_input_list ()
        local fs = {}
        -- background color
        local input_color = cache:get_craft_mode().i_color
        -- #TODO put as setting the color of craftable
        if mode == 2 then
            fs[#fs + 1] = "box[0,-0.4;2.7,3.4;" .. input_color .. "]"
        else
            fs[#fs + 1] = "box[0,0.25;1.9,2.6;" .. input_color .. "]"
        end

        -- label
        -- fs[#fs + 1] = 'label[0,0;'..S("Ingredients:")..']',
        --[[ to hide and replace by label above
            if we don't want the option visible
            #TODO remove when test are finished ?
            ]]
        --fs[#fs + 1] = 'dropdown[0.1,-0.25;2.35,0.5;input_option;'
        --for i, mode in ipairs (input_options) do
        --    if i>1 then fs[#fs + 1] = ',' end
        --    fs[#fs + 1] = mode.label
        --end
        --fs[#fs + 1] = ';'
        --fs[#fs + 1] = cache.craft_input
        --fs[#fs + 1] = ';true]'

        -- input inventory
        local pInv = player:get_inventory() -- #TODO could be cache.pInv, not sure which is better
        local inputs = pInv:get_list('input_items')
        -- create or check whether to the size adjust size
        -- 'Use this': 12   'Save this': 6
        local input_size = (mode == 2) and 12 or 6
        if not inputs or #inputs ~= input_size then
            -- create inputs inventory list and draw formspec for input_itmes
            pInv:set_size('input_items', input_size)
        end

        fs[#fs + 1] = 'style_type[list;size=.7,.7;spacing=.1]'
        if mode == 2 then
            fs[#fs + 1] = "list[current_player;input_items;0.2,-0.25;3,4;0]"
        else
            fs[#fs + 1] = "list[current_player;input_items;0.2,0.4;2,3;0]"
        end

        return tofstring(fs)
    end

    -- #TODO check how to reset (or not) that part
    -- do I really need to cache it ?
    if not cache.FS_input_list then
        cache.FS_input_list = FS_input_list ()
    end

    output[#output + 1] = 'container[.4,2.2]'
    -- label
    if mode ~= 2 then
        output[#output + 1] = "label[0,0;" .. S("Save this") .. ":]"
    end
    output[#output + 1] = cache.FS_input_list

    output[#output + 1] = 'container_end[]'

    -- listring between input and main inv ------------------------------------
    output[#output + 1] = 'listring[current_player;input_items]'
    output[#output + 1] = 'listring[current_player;main]'

    -- return formspec
    output[#output + 1] = 'container_end[]'
    return tofstring(output)
end

-- Formspec actions ------------------------------------------------------------
--------------------------------------------------------------------------------
-- allow external mod to call this page with specific craft tab
-- (used in player_api to let clothing tab send us to clothing craft tab)
-- #TODO make a function to get the number from the name and call this one with the name ?
function crafting.set_page(player, selected_tab_number)
    -- will register cache for player if cache is newly generated
    local cache = get_FS_cache(player, true)
    -- set tab to the selected tab number
    cache:set_craft_tabs(selected_tab_number)
end

-- mark the formspec open
-- `cache` is optional
function crafting.open_formspec(player, fs_name, cache)
    -- initiates FS_cache[player_name] if non existant
    cache = cache or crafting.get_FS_cache(player, true)

    -- flag formspec as open (or not if fs_name = nil)
    cache.open = fs_name

    -- returns cache in case we need it
    -- to avoid an other call to crafting.get_FS_cache
    return cache
end

--[[ Called when the inventory formspec is closed to clear cache
    * get input items back in main
    * returns name of next sfinv opening page
]]
function crafting.close_crafting_formspec(player, cache)
    -- get cache if not given
    cache = cache or FS_cache[player:get_player_name()]
    -- if no cache or formspec already close, do nothing
    if type(cache) ~= "table" or not cache.open then
        -- no change to make
         -- #TODO we could add a message or other behavior in this case ?
        return nil
    end

    -- reset selection and clear "input_list" inventory into "main" inv
    cache:reset_selected_recipe(true, player)
    -- switch recipe hints off if hints' button is enabled
    cache.possible_hint = cache.hint_btn ~= true
    cache.input_filter = false -- disable filter
    cache.qty = 1 -- back to "Single" craft
    -- reset recipes panel and item_hashes for next opening
    cache:reset_recipes() -- needed after getting back the inputs
    -- no updates to the cache while formspec is closed
    cache.open = nil
    -- reset station if leaving a non nil station
    cache_set_station(cache, nil)
end

-- return the cache to update formspec if something changed, false else
function crafting.process_receive_fields(player, formname, fields)
    --   if formname ~= '' or formname ~= 'exile:crafting' then return false; end -- Not our form.
    local player_name = player:get_player_name()

    local cache = FS_cache[player_name]
    -- #TODO cache should never be nil right ?
    -- maybe display an error in that case ?
    if not cache then
        core.log("player's crafting cache shouldn't be nil in process_receive_fields")
        -- cache = get_FS_cache(player)
        -- #TODO should i do as above or just return nil ?
        return
    end

    -- Process quit
    -- called when escaping the formspec using inventory key
    if fields.quit then
        -- get input items back in main
        -- resets player's cache
        crafting.close_crafting_formspec(player, cache)

        return false -- no need to refresh the formspec
    end

    -- updates scrollbar value if it changed
    if fields.recipes_scroll then
        -- if there is any change
        local event = core.explode_scrollbar_event(fields.recipes_scroll)
        if event.type == "CHG" then
            cache.sScroll = event.value
            -- no refresh needed, it is included in the engine formspec dealing
            return false
        end
        --[[ NOTE: if the scollbar value didn't change
        -- we still do to check the other fields, since we will have a
        -- fields.recipes_scroll value as long as we have a scrollbar
        -- even if it didn't change value
        -- so keep the "return false" inside the if block.]]
    end

    --process input setting
    --if fields.input_option then
    --    local option = tonumber(fields.input_option)
    --    if option ~= cache.craft_input then
    --        -- some clean up before changing input option
    --        cache:reset_selected_recipe(true, player)

    --        -- save in player's settings
    --        local meta = player:get_meta()
    --        meta:set_int("crafting:ingredients", option)-- updates Hint button's state
    --        set_cache_input_options(cache, option, meta)
    --        -- refresh input panel
    --        cache.FS_input_list = nil
    --        -- reset item_hashes and recipe panel
    --        cache:reset_recipes()
    --        return cache
    --    end
    --end

    -- process search buttons
    -- clear search
    if fields.search_reset then
        if cache:set_text_search_to(nil) then
            return cache
        end
    end
    -- search field change
    if fields.craft_filter or fields.key_enter_field == "crafting_search" then
        if cache:set_text_search_to(fields.crafting_search) then
            return cache
        end
    end

    -- process input filter
    if fields.i_filter then
        cache.input_filter = not cache.input_filter
        -- #TODO improve that and the set_text_search to not recalculate all recipes craftable states
        -- without forcing an update it only happens if at least one recipe
        -- gets hidden or becomes visible
        return cache:apply_filters(nil, true)
    end

    -- process "hint" button"
    if fields.hint then
        cache.possible_hint = not cache.possible_hint
        --[[ activate that to save in player's meta
        -- save in player's settings
        local meta = player:get_meta()
        meta:set_int("crafting:possible_hint", cache.possible_hint and 1 or 0)
        ]]--

        -- reset recipes panel, but keep existing cache's item_hashes
        cache:reset_recipes(true)
        return cache
    end

    -- process new craft tabs
    for i = 1, #(cache.cTabs), 1 do
        if fields['sCraftTab_'..i] then
            if cache.sTab ~=i then
                cache:set_craft_tabs(i, cache.cTabs)
                -- prevent accidental crafting of hidden recipes
                cache:reset_selected_recipe()
                return cache -- indicates we need to refresh the form
            end
            -- else do nothing (return nil)
        end
    end

    -- process craft buttons
    for i, qty_id in ipairs({"qty_1", "qty_2", "qty_3", "qty_4"}) do
        -- user clicked nth button to craft and a recipe is selected?
        if fields[qty_id] and cache.selected_id then
            if cache:craft_selected(i) then
                return cache
            end
        end
    end

    -- processin buttons with id
    local function process_button(key,btypes)
        for _,prefix in ipairs(btypes) do
            if key:sub(1, #prefix) == prefix then
                local num = string.match(key, prefix.."_([0-9]+)")
                if num then
                    return prefix, num
                end
            end
        end
        return nil,nil -- button types not found
    end
    --[[ process all fields for button pushes.
        used for recipes crafting]]
    local btn_type
    local btn_id
    for btn, value in pairs(fields) do
        btn_type,btn_id = process_button( btn,{'sResult','b_sTool'})
        if btn_type ~= nil then
            break       -- We found a button
        end
    end

    if btn_type then
        -- if we changed tool
        if btn_type == 'b_sTool' then
            local tool = cache.tool_list[tonumber(btn_id)]
            -- don't update if we clicked on the already selected tool
            if cache.sTool ~= tool then
                cache:set_tool(tool)
                -- prevent accidental crafting of hidden recipes
                cache:reset_selected_recipe()
                return cache
            else
                return false
            end
        -- if we pushed a recipe button
        elseif btn_type == 'sResult' then
            if cache:push_recipe(tonumber(btn_id), player,  player_name) then
                return cache
            end
        end
    end
end

--------------------------------------------------------------------------------
-- following part is for update when inventory actions
--------------------------------------------------------------------------------
-- Update recipe list on inventory action inside a station formspec
local function refresh_recipes_FS(player)
    -- refresh only required if formspec is open for player
    local player_name = player:get_player_name()
    local cache = FS_cache[player_name]
    if cache then
        -- do nothing if cache is not open
        local fs_name = cache.open
        if not fs_name then
            return
        end
        -- reset item_hashes and recipe panel and sorting
        cache:reset_recipes()
        -- update formspec (case `~= ""`: just safety)
        if type(fs_name) == "string" and fs_name ~= "" then
            crafting.show_station_formspec(player, cache)
        end
    end
end

-- Refresh recipe list when items are moved/dragged in and out of main and input
-- panel inventories by the player while a station formspec is open. This includes
-- putting items into the trash bin or dropping them, but not crafting.
-- (also called with inventory moves in clothing formspec, into bags, ..., but
-- not when equipping clothes with right click)
minetest.register_on_player_inventory_action(function(player, action,
                                                    inventory, inventory_info)
    local from_list = inventory_info.from_list -- for move
    local to_list = inventory_info.to_list -- for move
    local listname = inventory_info.listname -- for put and take
    --if we get or drop things from main inventory, or move things between main and input_items, refresh recipes
    -- do nothing if the move is inside the same list
    if from_list == to_list and from_list ~= nil then
        return
    end

    if from_list == "main"
        or to_list == "main"
        or listname == "main"
        or from_list == "input_items"
        or to_list == "input_items"
        or listname == "input_items" then

        -- crafting formspec is open? -> trigger refresh
        local cache = FS_cache[player:get_player_name()]
        if cache and cache.open then
            core.after(0.1, refresh_recipes_FS , player)
        end
    end
end
)
