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
    `m_color` =color of main list's background
    `hint_btn` = if hint button is displayed or not
    )
]]
local input_options = {
    [2] = {
        label = " Use only", -- label in dropdown
        inputs = {"input_items"}, -- inv list used for craft
        i_color = c_color, -- bgcolor behind input inventory
        m_color = u_color, -- bgcolor behind main inventory
        hint_btn = true, -- is the hint button available ?
        -- when is the recipe panel tag as "updated" ?
        updated = function(cache) return not(cache.possible_hint) end
    },
    [1] = {
        label = " Do not use",
        inputs = {'main'},
        i_color = u_color,
        m_color = c_color,
        hint_btn = false,
        updated = function(cache) return false end -- updated at arrival
    },
    -- [3] = {
    --     label = " Use first",
    --     inputs = {"input_items",'main'},
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
        `station` = {desc = "description" ; creator = "crafted by tag"}

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
        `recipes` = nil : unsorter list of recipes
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
        `sorted` = true -- do I want the list to be sorted (order) or not ?
        `to_sort` = true -- d I need to resort it ?
        --#TODO could be put as player setting, or in crafting sfinv as button

        `craft_input` = table of inv to use to craft
        `possible_hint` = false -- true to display possible recipes
        `input_filter` = do put items in input panel trigger automatic filter ?

        -- complete formspec to be displayed
        -- not really used anymore
        `output` = "",
    }
    If updated,a section should be set to nil to force a redraw.
    only sections cleared are recreated via crafting.make_crafting_formspec
]]
local FS_cache = {}

-- functions for instance of "cache"
local cache_func = {}
cache_func.__index = cache_func

--Basic functions --------------------------------------------------------------

--[[return table of inv lists to use for input
according to player's setting in cache]]
function cache_func:get_craft_input()
    local option = input_options[self.craft_input]
    if option then
        return option.inputs
    else
        core.log("warning", "invalid 'craft_input' setting in crafting cache,"
        .. "  using default setting "
        .. input_options[default_option].label )
        self.craft_input = default_option
        return input_options[default_option].inputs
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
-- #TODO not sure to keep thise item_hash things in here
function cache_func:get_input_hash(pInv)
    return crafting.get_item_hash(pInv, self:get_craft_input())
end

-- to register instance functions from outside
function crafting.register_cache_function (name, func)
    cache_func[name] = func
end

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
    local option = meta:get_int("crafting:ingredients")
    if option == 0 then -- if field was not present in meta
        option = default_option
        meta:set_int("crafting:ingredients", option) -- set meta
    end
    cache.craft_input = option

    -- Hint button --
    -- if input option allows it
    if input_options[option].hint_btn then
        --  it is on in player_settings (I left with on)
        -- remember the setting. Note: new player will have 0 in meta
        cache.possible_hint = (meta:get_int("crafting:possible_hint") == 1)
        -- cache.possible_hint = false -- alaternative to no rememeber it
    else
        cache.possible_hint = false
    end
    -- Automatic filter checkbox --
    cache.input_filter = false -- never active on opening.

    -- are recipe updated when we arrive ?
    -- depends on activated options
    -- used to trigger refresh recipe button/system
    cache.updated = input_options[option].updated(cache)


    -- adds modification and initiate functions metatable
    setmetatable(cache, cache_func)

    -- no station by default
    cache.station = nil
    cache.tool_list = crafting.generate_tools_list()

    -- tool panel and crafting tabs
    cache:set_tool() -- in tools_and_types.lua

    -- recipes panel ---
    -- reset scrollbar to top
    cache.sScroll = 0 -- reset scrollbar to top
    -- tell if we sort list or not
    cache.sorted = true --TODO for futur setting, currently always true
    -- tells if the recipes needs to be sorted again (order change)
    cache.to_sort = true

    -- quantity selector
    cache.qty = 1 -- single by default on opening

    FS_cache[player_name] = cache
    return cache
end

-- empty table when player leave :#TODO should we or not ?
--[[core.register_on_leaveplayer(function(player)
    local player_name = player:get_player_name()
        FS_cache[player_name] = nil
    end)
    ]]

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
        else
            core.log("no crafting cache for player " .. player:get_player_name())
        end
    end
    return cache
end

-- localize
local get_FS_cache = crafting.get_FS_cache


-- Formspec generation ---------------------------------------------------------

local esc = minetest.formspec_escape

--[[ This is the function to call to create or update the formspec.
    It returns the full crafting formspec to be displayed
    updates are triggered by the section to redraw set to nil :
    eg cache.FS_recipes = nil to redraw recipes list.
    ]]
function crafting.make_crafting_formspec(player)
    local player_name = player:get_player_name()
    local pInv = player:get_inventory()
    if not (player_name and player_name ~= "") then
        return nil -- no player name
    end
    -- initiates FS_cache[player_name] if non existant
    local cache = get_FS_cache(player, true)

    -- output will be the formspec string
    local output = {
        'container[0,0]'
    }

    -- Inventory List part------------------------------------------------------

    output[#output + 1] = 'container[0.8,7.2]'

    -- if crafting panel is open, color it
    if cache.updated == true then
        local input_mode = cache:get_craft_mode()
        local bg_color = input_mode.m_color
        -- background color of main inventory list
        -- #TODO maybe change that in table
        if cache.possible_hint then
                bg_color = p_color  -- possible color
        end
        if bg_color then
            output[#output + 1] = "box[-0.18,-0.18;10.1,2.6;".. bg_color .. "]"
        end
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

    -- stop if not cache.updated -----------------------------------------------
    -- #TODO needs to be cleaned, doing 2 sperate functions maybe
    if not cache.updated then
        output[#output + 1]= tofstring({
            --'style[refresh_r;bgimg=;bgimg_pressed=;border=;bgcolor=red; sound=]'
            'button[1.8,1.2;8,4;refresh_r;',
            S("Open recipes"),
            ']',
        })

        output[#output + 1] = 'container_end[]'
        return tofstring(output)
    end

    -- continues only if cache.updated -----------------------------------------

    -- Tool types part ---------------------------------------------------------

    if not cache.FS_tool_panel then
        -- build in gui/tools_and_stations.lua
        cache.FS_tool_panel = cache:get_tool_panel()
    end
    output[#output + 1] = 'container[.4,0.6]'
    output[#output + 1] = cache.FS_tool_panel
    output[#output + 1] = 'container_end[]'

    -- Recipes List part -------------------------------------------------------

    -- Craft tabs above the recipes panel
    if not cache.FS_ctabs then
        -- in gui/tools_and_types.lua
        cache.FS_ctabs = cache:get_craft_tabs()
    end

    -- Recipes panel drawing
    if not cache.FS_recipes then
        -- in gui/recipes_panel.lua
        cache.FS_recipes = cache:get_recipes_panel(pInv)
    end

    -- Tabs + Recipes list block --
    output[#output + 1] = 'container[3.5, 0.45]'
    output[#output + 1] = cache.FS_ctabs
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
        local bg_color = cache:get_craft_mode().i_color
        -- #TODO put as setting the color of craftable
        fs[#fs + 1] = "box[-0.07,-0.4;2.7,3.24;" .. bg_color .. "]"

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

local function activate_refresh_page(player, cache)
    local player_name = player:get_player_name()
    -- back to clothing tab home_page if updated is false
    if not cache then -- no cache in param
        cache = FS_cache[player_name]
        if not cache then  --- no player's cache ?
            core.log("in crafting.close_crafting_formspec: "
            .. player_name .. "'s crafting cache shouldn't be nil")
            return false
        end
    end
    -- if current craft input option trigger the need of recipe refresh system
    if not input_options[cache.craft_input].updated(cache) then
        -- set default page to clothing formspec if mod is here
        if core.global_exists("player_api") then
            -- fomspec refreshed to be clothing page
            sfinv.set_page(player, "clothing:clothing")
            return true
        else  -- else, will launch the recipe button
            return false
        end
    end
end

-- Call when the inventory formspec is closed to clear cache
-- `player_name` param is optional
function crafting.close_crafting_formspec(player)
    -- fives back items in input panel to main inv
    get_inputs_back_in_inv(player)

    -- deleting cache
    -- setting it to nil also avoid unecesseray update of recipes
    -- when refresh_recipes_FS is triggeres by inventory changes
    FS_cache[player:get_player_name()] = nil
end

-- TODO pass as player_recipe function, so it can update on various change, like change of input, list, etc
local function process_max_label (cache, r_lists)
    if not r_lists then
        r_lists = {cache.recipes}
    end
    if type(r_lists) ~= "table" then
        core.log ("in process_max_label in crafting, r_lists is not a table")
        return
    end
    local inv = cache.pInv -- TODO improve
    for _, r_list in pairs(r_lists) do
        for _, r in pairs(r_list) do
            if r.craftable then
                --#TODO I need to improve the way cache.item_hash is assigned/modified
                if not cache.item_hash then
                -- TODO shoudln't happen right ?
                    cache.item_hash = cache:get_input_hash(inv)
                end
                r.count = cache:get_craft_count(r, cache.item_hash)
            elseif r.possible then
                local item_hash = crafting.get_item_hash(inv, {"main", "input_items"})
                r.count = cache:get_craft_count(r, item_hash)
            else
                r.count = nil
            end
        end
    end
    -- TODO better way to refresh recipes panel ?
    cache.FS_recipes = nil
    return true -- need to redo formspec ?
end

-- currently unused, but could be usefull in recipes_panel.lua ?
cache_func.process_max_label = process_max_label

-- return true if something changed, false else
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

    -- flag to skip processing buttons and skip to saving changes.
    -- #TODO can't it be replaced by "return true" ?
    -- seems we do FS_cache[player_name] = cache first
    local done = false

    -- Process quit
    -- called when escaping the formspec using inventory key
    if fields.quit then
        local refresh = activate_refresh_page(player, cache)
        crafting.close_crafting_formspec(player)
        return not refresh -- trigger sinv fs refresh if not already done
    end
    -- process scrollbar
    if fields.recipes_scroll then
        local value = fields.recipes_scroll
        local scroll = tonumber(string.match(value, "CHG:([0-9]+)"))
        if scroll and scroll ~= cache.sScroll then
            cache.sScroll = scroll
            cache.FS_recipes = nil
            --stop processing fields and go to saving changes
            done = true
        else
            scroll = tonumber(string.match(value, "VAL:([0-9]+)"))
            if scroll and scroll ~= cache.sScroll then
                cache.sScroll = scroll
                cache.FS_recipes = nil
                -- continue processing fields
                done = false
                -- VAL: scrollbar responses produced on button pushes
            end
        end
    end

    --process input setting
    if fields.input_option then
        local option = tonumber(fields.input_option)
        if option ~= cache.craft_input then
            cache.craft_input = option
            -- update availability or "hint button" if new option forbid it
            if input_options[option].hint_btn == false then
                cache.possible_hint = false
            end
            -- save in player's settings
            local meta = player:get_meta()
            meta:set_int("crafting:ingredients", option)
            -- refresh input panel
            cache.FS_input_list = nil
            -- refresh recipe panel
            cache:reset_recipes()
            done=true -- #TODO check the use
        end
    end

    -- process search buttons
    -- clear search
    if fields.search_reset then
        return cache:set_text_search_to(nil)
    end
    -- search field change
    if fields.craft_filter or
        fields.key_enter_field == "crafting_search" then
        return cache:set_text_search_to(fields.crafting_search)
    end

    -- process input filter
    if fields.i_filter then
        cache.input_filter = (fields.i_filter == "true")
        -- #TODO improve that and the set_text_search to not recalculate all recipes craftable states
        cache:apply_filters()
    end

    -- process "hint" button"
    if fields.hint then
        cache.possible_hint = not cache.possible_hint
        -- save in player's settings
        local meta = player:get_meta()
        meta:set_int("crafting:possible_hint", cache.possible_hint and 1 or 0)
        -- #TODO improve the temporary part and reset button
        cache:reset_recipes()
        done = true -- #TODO what does it do ? do I want it here ?
    end

    -- process get recipes button
    if fields.refresh_r then
        cache.updated = true
        cache:reset_recipes()
        done = true
    end
    -- process new craft tabs
    for i = 1, #(cache.cTabs), 1 do
        if fields['sCraftTab_'..i] then
            if cache.sTab ~=i then
                cache:set_craft_tabs(i, cache.cTabs)
                -- indicates we need to refresh the form
                return true
            end
            return false
        end
    end

    -- if skipping button is "false"
    if not done then
        -- processing quantity buttons
        -- if user checks something to true, register that in cache
        for i, ibtn in ipairs({'qty1','qty2','qty3'}) do
            -- if we check the box, change the quantity
            if fields[ibtn] then
                -- if I activate an other qty
                if fields[ibtn] == 'true' and cache.qty ~= i then
                    cache.qty = i
                    process_max_label (cache)
                    cache.FS_recipes = nil -- reset recipe panel
                    return true -- force redraw of formspec
                -- if I desactivate selected qty, pass back to "Single"
                elseif fields[ibtn] == 'false' then
                    cache.qty = 1
                    process_max_label (cache)
                    cache.FS_recipes = nil -- reset recipe panel
                    return true -- force redraw of formspec
                else -- else do nothing
                    return false
                end
            end
        end

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
            btn_type,btn_id = process_button(
                btn,{'sResult','b_sTool'})
            if btn_type ~= nil then
                break       -- We found a button
            end
        end
        if btn_type then
            -- if we changed tool
            if btn_type == 'b_sTool' then
                local tool = cache.tool_list[tonumber(btn_id)]
                cache:tool_change(tool)

            -- if we pushed a recipe button
            elseif btn_type == 'sResult' then
                return cache:push_recipe(tonumber(btn_id), player,  player_name)
            end
            -- any button pushes require recipes to be redrawn
            -- #TODO was already done in craft_recipe
            cache.FS_recipes = nil
        end
    end
    FS_cache[player_name] = cache
    return true
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
        -- reset recipe
        cache:reset_recipes()
        -- refresh formspec
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
    --if we get or drop things from main inventory, or move things betweent main and input_items, refresh recipes
    if from_list == "main"
            or to_list == "main"
            or listname == "main"
            or from_list == "input_items"
            or to_list == "input_items"
            or listname == "input_items" then
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
