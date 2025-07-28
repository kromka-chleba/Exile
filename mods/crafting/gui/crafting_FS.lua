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
            local status = p_recipe.craftable
            if status then -- craftable
                return 'crafting_slot_craftable.png'
            elseif p_recipe.possible then
                -- possible
                return 'crafting_slot_possible.png'
            elseif status == false then -- uncraftable
            -- replace by following to have black recipes if hint is off
            -- so that uncraftable may be transferred
            --[[
            elseif status == false and cache.possible_hint then
                uncraftable and hint is ON
            --]]
                return 'crafting_slot_uncraftable.png'
            else -- uncraftable but hint OFF, or unknows craftable state
                return 'crafting_slot_empty.png'
            end
        end,
        hint_btn = true, -- is the hint button available ?
        -- when is the recipe panel tag as "updated" ?
        updated = function(cache) return not(cache.possible_hint) end
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
            local status = p_recipe.craftable
            if status then -- craftable
                return 'crafting_slot_craftable.png'
            elseif status == false then -- uncraftable
                return 'crafting_slot_uncraftable.png'
            else -- unknows craftable state
                return 'crafting_slot_empty.png'
            end
        end,
        hint_btn = false,
        updated = function(cache) return false end -- updated at arrival
    },
    -- [3] = {
    --     label = " Use first",
    --     craftable_lists = {"input_items",'main'},
    --     i_color = c_color,
    --     m_color = c_color
    -- }
}

-- option "Do not use" by default
local default_option = 1

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
        `u_recipes` = nil : list of uncraftable recipes to display
        `recipes` = nil : unsorted list of recipes
        `updated` = false if inventoryFS was closed and recipes crafting state is not uptodate.
            This is because there is currently no callback for "I opened the inventory"

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
        `possible_hint` = false --  is the "hint" button activated ?
        `input_filter` = do put items in input panel trigger automatic filter ?

        `sorted` = true -- do we sort the recipes (color and order) ?
        `to_sort` = true -- do I need to resort order of the recipes ?
        `order` -- do we want recipes to be ordered by crafting state ?

        `closed` -- is the cache closed.
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
        .. input_options[default_option].label )
        self.craft_input = default_option
        return input_options[default_option][criteria .. "_lists"]
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
        .. input_options[default_option].label )
        self.craft_input = default_option
        return input_options[default_option]
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

local function get_hint_state(i_option, player_meta)
    --[[ option to initiate with player's meta
    if input_options[i_option].hint_btn then
        --  it is on in player_settings (I left with on)
        -- remember the setting. Note: new player will have 0 in meta
        return (player_meta:get_int("crafting:possible_hint") == 1)
    else
        return false
    end]]
    -- option to initiate it with always false
    return false
end

-- saves input option in cache and updates hint button state accordingly
local function set_cache_input_options(cache, option, player_meta)
    cache.craft_input = option
    -- updates Hint button's state
    cache.possible_hint = get_hint_state(option, player_meta)
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

cache_func.set_station = cache_set_station

-- generate a new cache and put is in FS_cache[player_name]
local function new_cache(player)
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
    local option = meta:get_int("crafting:ingredients")
    if option == 0 then -- if field was not present in meta
        option = default_option
        meta:set_int("crafting:ingredients", option) -- set meta
    end
    set_cache_input_options(cache, option, meta)
    -- Automatic filter checkbox --
    cache.input_filter = false -- never active on opening.

    -- are recipe updated when we arrive ?
    -- depends on activated options
    -- used to trigger refresh recipe button/system
    cache.updated = input_options[option].updated(cache)

    -- adds modification and initiate functions metatable
    setmetatable(cache, cache_func)

    -- set station, tools, tabs and recipes
    cache_set_station(cache, nil)

    -- recipes panel ---
    -- tell if we sort list or not
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
function crafting.get_FS_cache(player, generate)
    if not player then return nil end
    -- get the FS cache if already existant
    local cache = FS_cache[player:get_player_name()]
    -- else generates it
    if not cache then
        if generate then
            -- that function modified player's cache and return that cache
            cache = new_cache(player)
        end
    end
    return cache
end

function crafting.reset_FS_cache(player)
    FS_cache[player:get_player_name()] = new_cache(player)
end

-- localize
local get_FS_cache = crafting.get_FS_cache

-- register action in case order field is changed in player_setting
minimal.register_on_player_setting_change(
    function(player, meta_name, value, meta)
        if meta_name == "crafting:no_reorder" then
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
-- `open` = true (boolean) means we are sure the inv fs is open
function crafting.make_crafting_formspec(player, open)
    local player_name = player:get_player_name()
    if not (player_name and player_name ~= "") then
        return nil -- no player name
    end
    -- initiates FS_cache[player_name] if non existant
    local cache = get_FS_cache(player, true)

    -- if we are sure the formspec is open, then update if needed
    if open and not cache.updated then
        -- updates item_hash and recipes
        cache:reset_recipes()
        cache.updated = true -- no need for refresh button
        cache.closed = false -- formspec open
    end

    -- output will be the formspec string
    local output = {
        'container[0,0]'
    }

    -- Inventory List part------------------------------------------------------

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

    -- re-add worldedit gui button if that exists ------------------------------
    if minetest.global_exists("worldedit")
        and minetest.get_modpath("worldedit_gui")
        and minetest.check_player_privs(player, {worldedit=true}) then
        output[#output + 1] = tofstring({
            "image_button[9.75,0.5;0.75,0.75;inventory_plus_worldedit_gui.png;",
            "worldedit_gui;]",
            "tooltip[worldedit_gui;Edit your World!]"
        })
    end

    -- Trash -------------------------------------------------------------------

    output[#output + 1] = 'image[9.6,5.93;0.8,0.8;creative_trash_icon.png]'
    output[#output + 1] ='list[detached:creative_trash;main;9.52,5.8;1,1;]'

    -- Tool types part ---------------------------------------------------------

    if not cache.FS_tool_panel then
        -- build in gui/tools_and_stations.lua
        cache.FS_tool_panel = cache:get_tool_panel()
    end
    output[#output + 1] = 'container[.4,0.6]'
    output[#output + 1] = cache.FS_tool_panel
    output[#output + 1] = 'container_end[]'

    -- Recipes List part (Tabs + Recipes list block) ---------------------------
    output[#output + 1] = 'container[3.5, 0.45]'

    -- Craft tabs above the recipes panel
    if not cache.FS_ctabs then
        -- in gui/tools_and_types.lua
        cache.FS_ctabs = cache:get_craft_tabs()
    end
    output[#output + 1] = cache.FS_ctabs

    --[[ uncomment to bring back the recipe button
    -- Recipes panel drawing, button if recipes are not uptodate
    if not cache.updated then
        -- recipe refrehs button
        -- TODO put a textarea : "Click on any tabs or button, including this one to get the matching recipes"
        output[#output + 1]=  "style[refresh_r; border=true]"
        output[#output + 1]= 'button[0,1;7,3.5;refresh_r;'
                            .. S("Open recipes") ..']'
    else
        if not cache.FS_recipes then
            -- in gui/recipes_panel.lua
            cache.FS_recipes = cache:get_recipes_panel()
        end
        output[#output + 1] = cache.FS_recipes
    end
    ]]--

    if not cache.FS_recipes then
        -- in gui/recipes_panel.lua
        cache.FS_recipes = cache:get_recipes_panel()
    end
    output[#output + 1] = cache.FS_recipes

    output[#output + 1] = 'container_end[]'

    -- Search field part -------------------------------------------------------

    output[#output + 1] = 'container[3.5, 5.2]'
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
    -- #TODO hacky placement to test filter with other options
    if cache.craft_input ~= 2 then
        output[#output + 1] = 'checkbox[4.6,0.3;i_filter;'
                                .. S(" Automatic\n Filter") .. ';'
                                .. tostring(cache.input_filter) .. ']'
    end
    output[#output + 1] = 'container_end[]'

    -- Quantity buttons part ---------------------------------------------------

    cache.qty = cache.qty or 1 --remember what box was checked
    local qtytab = { 'false', 'false', 'false' }
    local qtylab = { S("Single"), S("Stack"), S("Maximum") }
    qtytab[cache.qty] = 'true'
    qtylab[cache.qty] = minetest.colorize("cyan", qtylab[cache.qty])

    output[#output + 1] = table.concat({'container[3.5,',6.4,']'})
    output[#output + 1] = tofstring({
            --'label[0,0;'..S("Quantity")..':]',
            'checkbox[0,0;qty1;'..qtylab[1]..';'..qtytab[1]..']',
            'checkbox[1.6,0;qty2;'..qtylab[2]..';'..qtytab[2]..']' ,
            'checkbox[3.6,0;qty3;'..qtylab[3]..';'..qtytab[3]..']'
        }
    )
    output[#output + 1] = 'container_end[]'

    -- Input List part----------------------------------------------------------

    local function FS_input_list ()
        local fs = {}
        -- background color
        local input_color = cache:get_craft_mode().i_color
        -- #TODO put as setting the color of craftable
        fs[#fs + 1] = "box[-0.07,-0.4;2.7,3.24;" .. input_color .. "]"

        -- label
        -- fs[#fs + 1] = 'label[0,0;'..S("Ingredients:")..']',
        --[[ to hide and replace by label above
            if we don't want the option visible
            #TODO remove when test are finished ?
            ]]
        fs[#fs + 1] = 'dropdown[0.1,-0.25;2.35,0.5;input_option;'
        for i, mode in ipairs (input_options) do
            if i>1 then fs[#fs + 1] = ',' end
            fs[#fs + 1] = mode.label
        end
        fs[#fs + 1] = ';'
        fs[#fs + 1] = cache.craft_input
        fs[#fs + 1] = ';true]'

        -- input inventory
        local pInv = player:get_inventory() -- #TODO could be cache.pInv, not sure which is better
        local inputs = pInv:get_list('input_items')
        if not inputs or #inputs ~= 9 then
            -- create inputs inventory list and draw formspec for input_itmes
            pInv:set_size('input_items', 9)
        end

        fs[#fs + 1] = 'style_type[list;size=.7,.7;spacing=.1]'
        fs[#fs + 1] = 'list[current_player;input_items;0.1,0.4;3,3;0]'

        return tofstring(fs)
    end

    -- #TODO check how to reset (or not) that part
    -- do I really need to cache it ?
    if not cache.FS_input_list then
        cache.FS_input_list = FS_input_list ()
    end

    output[#output + 1] = 'container[.5,2.5]'
    output[#output + 1] = cache.FS_input_list

    if cache:get_craft_mode().hint_btn  then
        if cache.possible_hint then
            output[#output + 1] = "style[hint;bgcolor=white; bgcolor_hovered=white; bgcolor_pressed=white]"
        else
            output[#output + 1] = "style[hint;bgimg=;bgcolor=black]"
        end

        output[#output + 1] = 'button[0.6,3.6;1.5,0.5;hint;'.. S("Hint") .. ']'
    end
    --#TODO to replace with proper setting/condition
    if cache.craft_input == 2 then
        output[#output + 1] = 'checkbox[0,3.2;i_filter;'
                            .. S("Automatic Filter") .. ';'
                            .. tostring(cache.input_filter) .. ']'
    end
    output[#output + 1] = 'container_end[]'

    -- listring between input and main inv -------------------------------------
    output[#output + 1] = 'listring[current_player;input_items]'
    output[#output + 1] = 'listring[current_player;main]'

    -- return formspec
    output[#output + 1] = 'container_end[]'
    return tofstring(output)
end

-- Formspec actions ------------------------------------------------------------
--------------------------------------------------------------------------------
-- allow exteranl mod to call this page with specific craft tab
-- (used in player_api to let clothing tab send us to clothing craft tab)
-- TODO maybe make/get a function to get the number from the name ?
function crafting.set_page(player, selected_tab_number)
    -- will register cache for player if cache is newly generated
    local cache = get_FS_cache(player, true)
    -- set tab to the selected tab number
    cache:set_craft_tabs(selected_tab_number)
    sfinv.set_page(player, "crafting:crafting")
end

-- give back items in input panel to main inventory
local function get_inputs_back_in_inv(player)
    -- Return Items in input_items list to player
    local pInv = player:get_inventory()
    if not pInv:is_empty('input_items') then
        for i=1, pInv:get_size('input_items') do
            local stack = pInv:get_stack('input_items', i)
            if not stack:is_empty() then
                -- Try to add to main inventory
                local left = pInv:add_item('main', stack)
                if not left:is_empty() then
                    -- Drop item if no room in inventory
                    minetest.item_drop(left, player, player:get_pos())
                    -- warns the player it went on the ground
                    minimal.warn_inv_full(player)
                end
                -- Set stack to empty stack in input_items inventory
                pInv:set_stack('input_items',i,ItemStack(''))
            end
        end
    end
end

--[[ Called when the inventory formspec is closed to clear cache
    * get input items back in main
    * returns name of next sfinv opening page
]]
function crafting.close_crafting_formspec(player, cache)
    -- fives back items in input panel to main inv
    get_inputs_back_in_inv(player)

    -- cache changes
    if not cache then -- no cache in param
        local player_name = player:get_player_name()
        cache = FS_cache[player_name]

        -- cache already deleted sometimes when called by "on_leave"
        if not cache then  --- no player's cache ?
            -- no change to make
            return nil -- TODO check if I can improve/clarify the return
        end
    end

    --various updates
    cache.possible_hint = false -- disable "hint"
    cache.input_filter = false -- disable filter
    cache.qty = 1 -- back to "Single" craft
    -- reset recipes panel and item_hashes for next opening
    cache:reset_recipes() -- needed after getting back the inputs

    -- set updated status and next opening page
    cache.updated = input_options[cache.craft_input].updated(cache)

    cache.closed = true -- formspec closed

    -- put below things to do in that case
    ------------------------------------
    --[[ to bring clothing page
    -- if current craft input option trigger the need of recipe refresh system
    if not cache.updated then
        -- delete cache
        FS_cache[player:get_player_name()] = nil
        -- if clothing page is here
        if core.global_exists("player_api") then
            -- set page to clothing formspec
            return "clothing:clothing"
        end
    end
    ]]

    -- else open directly on crafting page, with or without recipe button
    return "crafting:crafting"
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
        --[[ to bring clothing page, with above closing code
        -- get input items back in main
        -- updates/delete player's cache and returns opening page
        local next_page = crafting.close_crafting_formspec(player, cache)
        -- updated sfinv page state for next opening
        sfinv.set_page(player, next_page)
        return false -- no need to refresh sfinv, it was just done
        ]]
        crafting.close_crafting_formspec(player, cache)
        return cache
    end
    -- else mark formspec as open
    cache.closed = false

    -- updates scrollbar value if it changed
    if fields.recipes_scroll then
        local value = fields.recipes_scroll
        -- if there is any change
        local scroll = tonumber(string.match(value, "CHG:([0-9]+)"))
        if scroll and scroll ~= cache.sScroll then
            cache.sScroll = scroll
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
    if fields.input_option then
        local option = tonumber(fields.input_option)
        if option ~= cache.craft_input then
            local meta = player:get_meta()
            -- save in player's settings
            meta:set_int("crafting:ingredients", option)-- updates Hint button's state
            set_cache_input_options(cache, option, meta)
            -- refresh input panel
            cache.FS_input_list = nil
            -- reset item_hashes and recipe panel
            cache:reset_recipes()
            return cache
        end
    end

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
        cache.input_filter = (fields.i_filter == "true")
        -- #TODO improve that and the set_text_search to not recalculate all recipes craftable states
        return cache:apply_filters()
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

    -- process get recipes button
    if fields.refresh_r then
        cache.updated = true
        -- reset item_hashes and recipe panel
        cache:reset_recipes()
        return cache
    end
    -- process new craft tabs
    for i = 1, #(cache.cTabs), 1 do
        if fields['sCraftTab_'..i] then
            if cache.sTab ~=i then
                cache:set_craft_tabs(i, cache.cTabs)
                return cache -- indicates we need to refresh the form
            end
            -- else do nothing (return nil)
        end
    end

    -- processing quantity buttons
    -- if user checks something to true, register that in cache
    for i, ibtn in ipairs({'qty1','qty2','qty3'}) do
        -- if we check the box, change the quantity
        if fields[ibtn] then
            local j -- new value to put in
            -- if I activate an other qty
            if fields[ibtn] == 'true' and cache.qty ~= i then
                j= i
            -- if I desactivate selected qty, pass back to "Single"
            elseif fields[ibtn] == 'false' then
                j =1
            end
            if j then -- if change is needed
                cache.qty = j
                cache:process_max_label () -- updates label on ecipes
                return cache -- force redraw of formspec
            end -- else do nothing (return nil)
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
-- update recipe list on inventory action outside the formspec
--[[ #TODO do better when we can
    This is all because we don't have a callback for inventory opening
    to come, we hope, a core.register_on_inventory_open(function(inventory)
]]

-- Delete recipes list cache and update inventory formspec
function crafting.refresh_recipes_FS(player)
    local player_name = player:get_player_name()
    local cache = FS_cache[player_name]
    if cache then
        -- do nothing if cache is closed and doesn't need an update
        if cache.closed and cache.updated then
            return
        end
        -- reset item_hashes and recipe panel, and reorder
        cache:reset_recipes()
        -- refresh formspec
        -- #TODO remove check and second case when crafting in inventory gets removed
        if cache.station then --TODO may not be the proper way
            core.show_formspec(player_name,'exile:crafting',
                            crafting.make_tool_formspec(player, cache))
        else -- else sfinv
            sfinv.set_player_inventory_formspec(player)
        end
    --[[ happens if other moves to inventory,
        triggered by inventory moves in clothing formspec too]]
    -- else
    --     core.log("no cache in crafting.refresh_recipes_FS")
    end
end

-- Refresh recipe list when items are moved/dragged in and out of main and input panel inventories
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

        -- if input_items is concerned, it means formspec is open
        if from_list == "input_items"
                or to_list == "input_items"
                or listname == "input_items" then
            local cache = FS_cache[player:get_player_name()]
            -- cache shouldn't be nil anyway, if we have access to input_list
            if cache then
                cache.closed = false
            else
                core.log("cache shouldn't be nil "
                .. "since we moved things in input_items list (in on_player_inventory_action)")
                return
            end
        end

        core.after(0.1, crafting.refresh_recipes_FS , player)
    end
end
)

if minetest.register_on_item_pickup then
    minetest.register_on_item_pickup(function(itemstack, picker)
            if picker and picker:is_player() then
                core.after(0.1, crafting.refresh_recipes_FS , picker)
            end
    end
    )
end

minetest.register_on_placenode(function(pos, newnode, placer, oldnode, itemstack, pointed_thing)
    if placer and placer:is_player() then
        core.after(0.1, crafting.refresh_recipes_FS , placer)
    end
end
)

minetest.register_on_dignode(function(pos, oldnode, digger)
    if digger and digger:is_player() then
        core.after(0.1, crafting.refresh_recipes_FS , digger)
    end
end
)

-- #TODO useless for now (we use on_use and _on_consume)
minetest.register_on_item_eat(function(itemstack, picker)
    if picker:is_player() then
        core.after(0.1, crafting.refresh_recipes_FS , picker)
    end
end
)
