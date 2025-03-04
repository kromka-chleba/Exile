-- Crafting Mod - semi-realistic crafting in minetest
-- Copyright (C) 2018 rubenwardy <rw@rubenwardy.com>
-- Copyright (C) 2022 Jan Wielkiewicz <tona_kosmicznego_smiecia@interia.pl>
--
-- This library is free software; you can redistribute it and/or
-- modify it under the terms of the GNU Lesser General Public
-- License as published by the Free Software Foundation; either
-- version 2.1 of the License, or (at your option) any later version.
--
-- This library is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
-- Lesser General Public License for more details.
--
-- You should have received a copy of the GNU Lesser General Public
-- License along with this library; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA


-- This mod adds a "exile_crafting" key to node definitions.

-- exile_crafting = {
-- name of craft type, or table of craft types.
--  A table produces tabs of recipes.
--      -- Must be registered with crafting.register_type().
--      craft_types = {'hand','hand_mixing'}
--      -- craft_types = 'craft_spot'           -- for single tab
--      craft_level = 1                         -- crafting level of node/item
--              }

--   * Items that have this key will auto transfer to the craft_type
--          inventory if moved into the input_items inventory.
--

minimal = minimal
crafting = crafting
sfinv = sfinv

local S = minetest.get_translator("crafting")
local tofstring = function(t) return table.concat(t,"") end

-- Dealing with crafting tab in inventory formspec

--[[ The inventory formspec is cached for each player like this:
    inventoryFS_cache[player_name] = {
        epoch  = os.time(),             -- Used to expire cache
        tool_list -- list of tools I can use
        sToolID = selected tool index in list -- set to 1 by default
        sTool  = selected tool name
        sTab   = selected_craft_tab     -- index of selected tab in craft_types  - default = 1
        cTabs = nil -- "hand", "hand_tool", etc; all output tool type sections
        sLevel = selected craft_type_level -- set by craft type item selected
        sScroll = selected scroll level -- needed to draw scroll container
        sSearch = current filter in search field
        -- The Following are tables of formspec strings
        -- Set output = "" to force redraw using cashed details
        -- to trigger redraw of a section, set the section to nil
        -- eg) to regenerate the recipes list, set
        -- cache.recipesFS = nil, and cache.output = ""
        tool_tabsFS = {},
        craft_itemsFS = {},

        --model of follwing table is :
            -- recipes =  {
            --     recipe    = recipe,
            --     items     = items,
            --     craftable = craftable,
            --     displayed = displayed
            -- }
        c_recipes= nil -- list of craftable recipes to display
        u_recipes=nil -- list of uncraftable recipes to display
        recipes = nil -- unsorter list of recipes
        sorted = true -- do I want the list to be sorted or not ?
        --#TODO could be put as player setting, or in crafting sfinv as button

        FS_craftabs = nil
        recipesFS = {},
        searchFS= "", -- search container
        output = "",
    }
    If updated,a section should be set to nil to force a redraw.
    only sections cleared are recreated via make_inventory_formspec
]]
local inventoryFS_cache = {}

--Basic functions --------------------------------------------------------------

-- registering all craft type (tabs) and level available per tool
local tools_craft_tabs = {}
local tools_level = {}
local default_tool = 'tech:crafting_spot'

-- Load craft type : buttons on the top left "tool used"
--[[#TODO right now, only one tool can be used at the same time (placed tool)
but we could imagine using tool in inventory like knifes too
In that case, this could be modified to have "craft_item" being a list]]
local function generate_tools_list(craft_item)
    if not craft_item or craft_item == default_tool then
        return {default_tool}
    else
        return {default_tool, craft_item}
    end
end

-- return level for that tool (#TODO I think this is unused, not sure yet)
-- set by def.exile_crafting.craft_level of registered tool/item/node
local function get_tool_level(tool)
    if not tool then
        return get_tool_level(default_tool)
    -- use the data we already have in local
    elseif tools_level.tool then
        return tools_level.tool
    else
        -- go get it in registered table else
        local def = minetest.registered_nodes[tool]
            or minetest.registered_tools[tool]
            or minetest.registered_items[tool]
        if def and def.exile_crafting then
            return def.exile_crafting.craft_level
        else
            print('ERROR: Missing exile_crafting level definition for '..tool)
        end
    end
end

local function tool_to_ID(tool, cache)
    for i,t in pairs(cache.tool_list) do
        if t==tool then
            return i
        end
    end
end

-- return table of craft subtabs for tool in parameter
-- set by def.exile_crafting.craft_type of registered tool/item/node
local function get_craft_tabs(tool)
    -- use the data we already have
    if tools_craft_tabs[tool] then
        return tools_craft_tabs[tool]
    end
    -- generate the list if not enough data
    local def = minetest.registered_nodes[tool]
        or minetest.registered_tools[tool]
        or minetest.registered_items[tool]
    if def and def.exile_crafting then
        local tabs = def.exile_crafting.craft_types
        if not tabs then
            error('no tabs defined for '.. tool)
        end
        if type(tabs) ~= 'table' then
            tabs = { tabs }
        end
        tools_craft_tabs[tool] = tabs
        return tabs
    else
        print('ERROR: Missing exile_crafting craft_types definition for '..tool)
    end
end

-- Cache initialisations -------------------------------------------------------

-- initiate or reset existing cache to default
local function initiate_cache(player)
    local cache = inventoryFS_cache[player:get_player_name()] or {}
    -- erase cache
    for k,_ in pairs(cache) do
        cache[k] = nil
    end
    cache.epoch = os.time()

    -- tool and crafting recipes
    cache.sTool = default_tool
    cache.tool_list = generate_tools_list()
    cache.sToolID =  1
    cache.sLevel = get_tool_level(default_tool)
    cache.sTab = 1 -- default to first tab
    cache.cTabs = get_craft_tabs(cache.sTool)
    cache.sScroll = 0 -- reset scrollbar to top
    cache.sorted = true -- tell if we sort list or not #TODO for futur setting, currently always true

    -- quantity selector
    cache.qty = 1

    -- final formspec
    cache.output = ""

    -- saving
    inventoryFS_cache[player:get_player_name()] = cache
    return inventoryFS_cache[player:get_player_name()]
end

-- Recipes list part -----------------------------------------------------------

--[[ take current craftable and uncraftable list and
    recheck if each one is craftable or not
    update those lists in cache
]]
local function update_recipes_lists(player_name, cache, item_hash)
    local c_recipes = cache.c_recipes
    local u_recipes = cache.u_recipes
    local unlocked = crafting.get_unlocked(player_name)
    local search = cache.sSearch
    local lang_code = minetest.get_player_information(player_name).lang_code
    -- updates ingredients state and infotext in first list
    for i, result in ipairs(c_recipes) do
        crafting.update_recipe_state(result, cache.sLevel, unlocked, item_hash, search, lang_code)
    end

    -- updates ingredients state and infotext in second list
    -- and move new craftable recipes to end of first one
    local new_u={}
    for i, result in ipairs(u_recipes) do
        crafting.update_recipe_state(result, cache.sLevel, unlocked, item_hash, search, lang_code)
        -- if it became craftable, add to previous list and hide in this one
        if result.craftable then
            c_recipes[#c_recipes + 1] = result
        else -- else keep it in uncraftable list
            new_u[#new_u + 1] = result
        end
    end
    cache.u_recipes = new_u
end

local function get_item_hash(pInv)
    -- build player items hash
    local item_hash = {}
    -- add input_items inventory
    if pInv:get_size('input_items') > 0 then
        crafting.set_item_hashes_from_list(pInv, 'input_items', item_hash)
    end
    -- add main inventory
    if pInv:get_size('main') > 0 then
        crafting.set_item_hashes_from_list(pInv,'main', item_hash)
    end

    return item_hash
end

-- build recipes list to display in crafting tab
-- is search is not nil, it returns only the ones matching the search criteria
-- return sorted lists if sorted = true, unique list else
-- also return the size as 2nd return
local function get_recipes_list(cache, pInv, player_name, sorted)
    local cTabs = get_craft_tabs(cache.sTool)    -- Crafting tabs to display
    local sTab = cache.sTab      -- selected craft type tab
    local ctype = cTabs[sTab]
    local sLevel = cache.sLevel  -- level associated with selected craft type
    local sSearch = cache.sSearch
    local unlocked = crafting.get_unlocked(player_name)

    cache.item_hash = get_item_hash(pInv)

    -- Get all available recipies and mark craftible ones.
    if sorted == true then
        local c_recipes = cache.c_recipes
        local u_recipes = cache.u_recipes
        if not (c_recipes and u_recipes) then
            c_recipes, u_recipes =
                crafting.get_all_sorted(ctype, sLevel, cache.item_hash,
                                        unlocked, sSearch,
                                        minetest.get_player_information(
                                            player_name).lang_code)
            -- save the lists in the cache
            cache.c_recipes=c_recipes
            cache.u_recipes=u_recipes
        else
            update_recipes_lists(player_name, cache, cache.item_hash)
        end
        return {cache.c_recipes, cache.u_recipes},
                (#cache.c_recipes + #cache.u_recipes)
    elseif not sorted then --sorted is false or non given
        if not cache.recipes then
            cache.recipes = crafting.get_all(ctype, sLevel, cache.item_hash,
                                             unlocked, sSearch,
                                             minetest.get_player_information(
                                                 player_name).lang_code)
        end
        return {cache.recipes}, #cache.recipes
    end
end

-- Formspec generations -------------------------------------------------------
--------------------------------------------------------------------------------

-- Draw the tool type part
--[[Shouldn't need to rebuild this more then once per player per restart
    or when player adds to their craft_types
    See adding tools/benches to input_items list]]
local function FS_tool_types_to_cache(cache)
    local selected = cache.sTool or default_tool -- default to hand crafting
    local tool_list = cache.tool_list or generate_tools_list()
    local tool_tabsFS = {
        'label[0,0;'..S("Tool used")..']',
        'container[0.1,0.3]',
        'style_type[item_image_button;border=false;bgimg_middle=]'
    }

    local x = 0
    local y = 0
    local coords
    local bg_image
    for i,tool in ipairs(tool_list) do
        coords = tostring(x * 1.0) ..','.. tostring(y * 1.0)
        if tool == selected then
            bg_image = 'selected.png'
        else
            bg_image = 'not_selected.png'
        end

        tool_tabsFS[#tool_tabsFS + 1] =
            "image[" .. coords .. ";0.9,0.9;" .. bg_image .. "]"

        if tool~="" then
            -- Dipslay item image
            tool_tabsFS[#tool_tabsFS + 1] =
               'item_image_button[' .. coords .. ';0.9,0.9;'
               .. tool ..';b_sTool_' .. i .. ';]'
            tool_tabsFS[#tool_tabsFS + 1] =
                'tooltip[b_sTool_' .. i .. ';'
                .. ItemStack(tool):get_short_description() .. ']'
        end
        x = x + 1
        if x > 1 then
            x = 0
            y = y + 1
        end
    end

    tool_tabsFS[#tool_tabsFS + 1] ='container_end[]'

    cache.tool_tabsFS=tofstring(tool_tabsFS);
    cache.output = ""
    return cache
end

--[[ display individual recipe slot
Return associated formspec string
]]
local function FS_display_recipe(result, x, y)
    local form_table={}
    -- place recipe
    local recipe_output = result.recipe.output
    local item_description=ItemStack(recipe_output):get_description()

    local id = result.recipe.id
    local bg_coords =  tostring(x) ..','.. tostring(y + 0.2)

    -- set background image
    local bg_image
    local craftable = result.craftable
    if craftable then
        bg_image = 'crafting_slot_craftable.png'
    else
        bg_image = 'crafting_slot_uncraftable.png'
    end
    form_table[1] = "image[" .. bg_coords .. ";1,1;" .. bg_image .. "]"

    -- Add button image
    local btn_coords =
    tostring( x + 0.1 ) .. ','..
    tostring( y + 0.3 )

    if result.recipe._display then
        form_table[2] = tofstring({
            "style_type[image_button;border=false;bgimg_middle=]",
            'image_button[',
            btn_coords,
            ';.8,.8;',
            minetest.formspec_escape(result.recipe._display),
            ';sResult_',
            id,
            ';]'
        })
    else
        form_table[2] = tofstring({
            "style_type[item_image_button;border=false;bgimg_middle=]",
            'item_image_button[',
            btn_coords,
            ';.8,.8;',
            recipe_output,
            ';sResult_',
            id,
            ';]'
        })
    end

    -- add recipe's tooltip part 1 : output's description
    form_table[3] = tofstring({
        'tooltip[sResult_',
        id,
        ';',
        minetest.formspec_escape(item_description .. "\n")
    })

    -- add recipe's tooltip part 2 : inputs
    local index = 4
    for _, row in ipairs(result.items) do
        local tool_tip ="\n"
        for _, item in ipairs(row) do
            local color = item.have >= item.need and "#6f6" or "#f66"
            if tool_tip ~= "\n" then
                tool_tip = tool_tip ..  minetest.get_color_escape_sequence(color) .. S("or") .. " "
            else
                tool_tip = tool_tip ..  minetest.get_color_escape_sequence(color)
            end
            tool_tip = tool_tip
            ..  item.short .. ": "
            ..  item.have .."/".. item.need .." "
        end
        form_table[index] = minetest.formspec_escape(tool_tip)
        index = index +1
    end
    -- #TODO check the use/placement of following line
    form_table[#form_table+1]=
    minetest.get_color_escape_sequence("#ffffff") .. ']'
    -- return result as string
    return tofstring(form_table)
end

--Recreated Recipe part of the formspec
local function FS_recipes_to_cache(cache, player_name, pInv)
    local recipesFS = {}         -- final fromspec
    -- this is for more clarity, choice of display settings
    --[[size of a square of recipe : 1*1 of image + 0.1 margins around,
    used to place them on a grid, including tabs]]
    local line_number = 3 -- nb of lines of recipes displayed
    local grid_size = 1.2

    -- Add recipes list -------------------------------------------------

    -- add Scrollable container for recipes --------------------------
    -- get recipe list to display
    -- this list indicates if the recipe is craftable or not
    -- displayed = true only if the recipes matching the search parameter
    local to_display, nb_recipes = get_recipes_list (cache, pInv, player_name, cache.sorted)

    local columns = 6 -- can show 6 items accross without scrollbar

    -- add scrollbar if needed
    -- #TODO don't reset the recipe lists just because of the scrollbar
    local sScroll = cache.sScroll or 0 -- default to 1 for top of scroll
    if nb_recipes > columns * line_number then
        -- columns = columns -1 -- discard a line to make room for scrollbar
        local scroll_max = math.ceil(nb_recipes / columns)-line_number
        recipesFS[#recipesFS + 1] =
        'scrollbaroptions[max=' .. tonumber(scroll_max) .. ';'
        .. 'smallstep=1;largestep=line_number;thumbsize=1]'
        recipesFS[#recipesFS + 1]
        = 'scrollbar[7.1,0.95;.5,' .. (1.14*line_number) .. ';vertical;recipes_scroll;'
        .. sScroll .. ']'
    end

    -- create scroll container
    recipesFS[#recipesFS + 1] = tofstring({'scroll_container[0,0.75;',
                                        tostring(columns + 1),',',
                                        (1.25 * line_number),
                                        ';recipes_scroll;vertical;',
                                         grid_size ,
                                          ']'
                                        })

    -- Add recipe buttons in container  ------------------------------
    local x = 0
    local y = 0

    --#TODO make a version with unique list for non ordered list as asked by Meniptah
    for _, r_list in ipairs (to_display) do
        --displays all recipes matchng with search field
        for i, result in ipairs(r_list) do
            -- display if this recipe matches the filter
            if result.displayed == true then
                recipesFS[#recipesFS + 1] =
                    FS_display_recipe(result, x * grid_size, y * grid_size)

                x = x + 1
                if x >= columns  then
                    x = 0
                    y = y + 1
                end
            end
        end
    end

    recipesFS[#recipesFS + 1] = 'scroll_container_end[]'

    -- saving new cache
    cache.recipesFS = tofstring(recipesFS)
    cache.output = ""
    return cache
end

-- This is the function to call to create or update the formspec.
-- It returns the cache value unless something has updated or it times out
-- updates are triggered by setting cache.output = "" and the section to
-- redraw is set to nil - eg cache.recipesFS = nil to redraw recipes list.
-- istool boolean - moves buttons about to show space for a potential craftedby
local function make_inventory_formspec(player,context,istool)
    local player_name = player:get_player_name()
    local pInv = player:get_inventory()
    if not (player_name and player_name ~= "") then
        return nil -- no player name
    end
    local cache = inventoryFS_cache[player_name]

    -- context exists for inventory formspec only
    if not context and cache == 'closed' then
        return nil
    end

    -- return prepared formspec if we have one and it hasn't timed out
    if not cache or cache == 'closed' then
        cache = initiate_cache(player)
    end

    local output = {
        'container[0,0]'
    }

    -- Tool types part --------------------------------------------

    if not cache.tool_tabsFS then
        cache =  FS_tool_types_to_cache(cache)
    end
    output[#output + 1] = 'container[.4,0.6]'
    output[#output + 1] = cache.tool_tabsFS
    output[#output + 1] = 'container_end[]'

    -- Recipes List part -------------------------------------------------------

    -- Tab header -------------------------------------------------
    if cache.FS_craftabs == nil then
        -- generate formspec for crafting tabs
        local cTabs = cache.cTabs or get_craft_tabs(cache.sTool)

        local pan_t = {
            --style 1 : no border
            "style_type[item_image_button;border=false;bgimg_middle=4]",
            "style_type[image_button;border=false;bgimg_middle=4]"

            --[[ style 2 : with border
            "style_type[item_image_button;border=true;bgimg_middle=4]",
            --if this tab is selected, change style
            "style[sCraftTab_"..sTab..";bgcolor=#FFFFFF]"]]
        }

        local coords
        for i=1, #cTabs do -- go over recipe tabs: hand, tools, weaving, etc
            coords = tostring((i - 1) * 0.85) ..',0'
            ---------------------------------------------------------------
            --set focus on selected tab
            if i == cache.sTab then
                pan_t[#pan_t + 1] =
                'set_focus[sCraftTab_' .. i .. ';true]'
                -- style 1 : no border
                pan_t[#pan_t + 1] =
                "image[" .. coords .. ";0.8,0.8;selected.png]"
            --else
                -- style 1 : no border
                --[[uncomment this to activate background of tabs
                pan_t[#pan_t + 1] =
                "image[" .. coords .. ";0.8,0.8;not_selected.png]"
                ]]
            end

            local item_name = crafting.icon_item_name[cTabs[i]]
            or 'crafting:placeholder'

            -- checking if given field is an image or not.
            local button_type = 'item_image_button['
            if item_name == string.gsub(item_name, ":", "") then -- not an item
                button_type = 'image_button['
            end

            pan_t[#pan_t + 1] = button_type .. coords .. ';0.8,0.8;'.. item_name .. ';sCraftTab_'..i..';]'

            pan_t[#pan_t + 1] = 'tooltip[sCraftTab_'.. i ..
            ';' .. minetest.formspec_escape((crafting.tab_labels[cTabs[i]]
            or cTabs[i])) ..
            ';#000000;#ffffff]'
        end
        -- save in cache #TODO see reset needs
        cache.FS_craftabs = tofstring(pan_t)
    end

    if cache.recipesFS == nil then
        FS_recipes_to_cache(cache,player_name,pInv)
    end

    output[#output + 1] = 'container[3.5, 0.45]'
    output[#output + 1] = cache.FS_craftabs
    output[#output + 1] = cache.recipesFS
    output[#output + 1] = 'container_end[]'

    -- Search field part -------------------------------------------------------

    output[#output + 1] = 'container[3.5, 5.2]'
    if cache.searchFS == nil then
        -- Build search field to be in container
        cache.searchFS = tofstring({
            'field_close_on_enter[crafting_search;false]',
            'field[0,0;3.0,0.6;crafting_search;;'.. (cache.sSearch or "") .. ']',
            'image_button[3.1,0;0.6,0.6;creative_search_icon.png;crafting_filter;]',
            'image_button[3.8,0;0.6,0.6;creative_clear_icon.png;crafting_clear;]'
        }
    )
    end
    output[#output + 1] = cache.searchFS
    output[#output + 1] = 'container_end[]'

    -- short break for figuring out how much space to add ----------------------

    local ycoord = istool and 7.4 or 6.4

    -- Optional CraftedBy string -----------------------------------------------

    -- do not display in hand crafting
    if istool and cache.sTool ~= default_tool and cache.creatortag and cache.creatortag ~= "" then
        output[#output + 1] = tofstring({
            'container[0.45,',ycoord-1,']',
            'label[0,0;',S("Crafted by: @1", cache.creatortag),']',
            'container_end[]'
        })
    end

    -- Quantity buttons part ---------------------------------------------------

    cache.qty = cache.qty or 1 --remember what box was checked
    local qtytab = { 'false', 'false', 'false' }
    local qtylab = { S("Single"), S("Stack"), S("Maximum") }
    qtytab[cache.qty] = 'true'
    qtylab[cache.qty] = minetest.colorize("cyan", qtylab[cache.qty])

    output[#output + 1] = table.concat({'container[0.45,',ycoord,']'})
    output[#output + 1] = tofstring({
            'label[0,0;'..S("Quantity")..':]',
            'checkbox[2.6,0;qty1;'..qtylab[1]..';'..qtytab[1]..']',
            'checkbox[4.65,0;qty2;'..qtylab[2]..';'..qtytab[2]..']' ,
            'checkbox[6.65,0;qty3;'..qtylab[3]..';'..qtytab[3]..']'
        }
    )
    output[#output + 1] = 'container_end[]'

    -- Inventory List part------------------------------------------------------

    ycoord = ycoord + 0.8
    output[#output + 1] = table.concat({'container[0.8,',ycoord,']'})
    output[#output + 1] = tofstring({
        'style_type[list;size=;spacing=]',
        'list[current_player;main;0,0;8,2;0]'
    }
    )
    output[#output + 1] = 'container_end[]'

    -- Input List part----------------------------------------------------------

    if not cache.input_listFS then
        -- Generated Input inventory List Cache
        -- Shouldn't need to be rebuilt more then once per player per restart
        local inputs = pInv:get_list('input_items')
        if not inputs or #inputs ~= 9 then
            -- create inputs inventory list and draw formspec for input_itmes
            pInv:set_size('input_items', 9)
        end

        cache.input_listFS = tofstring({
            'label[0,0;'..S("Use first:")..']',
            'style_type[list;size=.7,.7;spacing=.1]',
            'list[current_player;input_items;0.1,0.4;3,3;0]',
        }
    )
    end
    output[#output + 1] = 'container[.4,2.8]'
    output[#output + 1] = cache.input_listFS
    output[#output + 1] = 'container_end[]'

    -- listring between input and main inv -------------------------------------
    output[#output + 1] = 'listring[]'

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

    -- Save output to cache and update -----------------------------------------
    output[#output + 1] = 'container_end[]'

    cache.output = tofstring(output)

    inventoryFS_cache[player_name] = cache
    return cache.output
end

-- Cache modifications  -------------------------------------------------------

-- reset recipes in cache (list and formspec)
local function cache_reset_recipes(cache)
    -- will force to resort recipes
    cache.c_recipes = nil -- list of craftable recipes to display
    cache.u_recipes = nil -- list of uncraftable recipes to display
    cache.recipes = nil
    cache.recipesFS = nil -- delete recipes formspect from cache
    cache.sScroll = 0 -- reset scrollbar to top
end

-- set craft tabs in cache
local function cache_set_craft_tabs(cache, sTab, cTabs)
    cache.sTab = sTab or cache.sTab or 1
    cache.cTabs = cTabs or cache.cTabs or get_craft_tabs(cache.sTool)
    cache.FS_craftabs = nil
    cache_reset_recipes(cache)
end

-- change to hand if tool==nil
local function cache_tool_change(player, tool, inputcache, pos, meta)
    tool = tool or default_tool
    local cache =  inputcache or inventoryFS_cache[player:get_player_name()]

    -- if no cache, then generate it ? #TODO
    if not cache then
        cache = initiate_cache(player)
    end

    -- if I don't change the tool, don't change the tabs and recipes
    if cache.sTool ~= tool then
        cache.sToolID =  tool_to_ID(tool, cache)
        cache.sTool = tool
        cache.sLevel = get_tool_level(tool)
        cache_set_craft_tabs(cache, 1, get_craft_tabs(tool))
        -- save pos and meta for more unique interactions (this only gets updated on tool change)
        cache.pos = cache.pos or type(pos) == "table" and vector.check(pos) and pos or nil
        -- don't try to update if default
        if tool ~= default_tool and not cache.meta then
            local idef = core.registered_items[tool]
            -- see tech/tools for why we check _tool or remove letters from name
            idef = core.registered_items[tool._tool] or core.registered_items[tool:sub(1,-8)] or idef
            cache.meta = idef and idef.groups and (idef.groups.craftedby or idef.groups.savemeta) and
                cache.pos and core.get_meta(pos) or nil
            -- get creator string for craftedby mechanics
            if cache.meta then
                cache.creatortag = cache.meta:get_string("creator")
            end
        end
    end

    cache.tool_tabsFS= nil
end

-- remove tool
-- cache parameter is optional
local function cache_tool_remove(player, inputcache)
    local cache =  inputcache or inventoryFS_cache[player:get_player_name()]
    -- if no cache, then generate it
    if not cache then
        cache = initiate_cache(player)
    -- clear out node specific cache
    else
        cache.pos = nil
        cache.meta = nil
        cache.creatortag = nil
    end

    cache.tool_list = generate_tools_list()
    -- unselect tool to default
    cache_tool_change(player, nil, cache)
end

local function cache_tool_add(player, a_tool, inputcache, pos, meta)
    if not a_tool then
        return
    end
    local cache = inputcache or inventoryFS_cache[player:get_player_name()]
    -- if no cache, then generate it
    if not cache then
        cache = initiate_cache(player)
    end
    -- for now, we can only have one tool at the time, so I just reset to hand
    -- later we could remove r_tool
    cache.tool_list = generate_tools_list(a_tool)
    -- unselect tool to default
    cache_tool_change(player, a_tool, cache, pos, meta)
end

-- change Search field and reset formspec accordingly
-- return true is any change, to trigger formspec redraw
local function set_search_to(cache, s)
    local transformed = minimal.make_search_string(s)
    -- if I changed the text in the search field, reset recipes
    if cache.sSearch ~= transformed then
        cache.sSearch = transformed
        cache.searchFS = nil
        cache_reset_recipes(cache)
        cache.output = ""
        return true
    else
        return false
    end
end

-- Formspec actions ------------------------------------------------------------

-- Call when the inventory formspec is closed to clear cache
-- #TODO : would be good to still save the curent subtab instead of clearing everything
local function close_inventory_formspec(player)
    local player_name = player:get_player_name()
    if not (player_name and player_name ~= "") then
        return nil -- no player name
    end

    -- Return Items in input_items list to player
    local pInv = player:get_inventory()
    if not pInv:is_empty('input_items') then
        for i=1, pInv:get_size('input_items') do
            local stack = pInv:get_stack('input_items', i)
            if not stack:is_empty() then
                -- Try to add to main inventory
                if pInv:room_for_item('main', stack) then
                    stack = pInv:add_item('main', stack)
                end
                -- Drop item if no room in inventory
                if not stack:is_empty() then
                    minetest.item_drop(stack, player, player:get_pos())
                end
                -- Set stack to empty stack in input_items inventory
                pInv:set_stack('input_items',i,ItemStack(''))
            end
        end
    end

    local cache = inventoryFS_cache[player_name]

    --[[ added to reset quantity to "single" when we close the inventory
    and avoid accidentaly max]]
    cache.qty = 1
    -- reset and redraw Search field
    set_search_to(cache, nil)
    -- update recipe list #TODO this is only to resort list, improve to just do that, not the whole test
    cache_reset_recipes(cache)
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


-- Quantity sets single, stack or maximum -- this finds how many we can craft
local function process_qty(recipe,qty,item_hash)
    if qty == 1 then return end -- only one requested? not our problem

    -- Find multiplier of input needed to craft one max_stack of output items
    local function calculate_stack_input(item)
        local output_name = item:get_name()
        local per_input = item:get_count()
        local stack_size = core.registered_items[output_name].stack_max
        return stack_size / per_input
    end

    -- Find maximum number of outputs we can craft from our inventory
    local function find_max_craftable()
        --local oItem = ItemStack(recipe.output)
        --local oName = oItem:get_name()
        local max_count = 0 -- how many of these we'll try to craft
        local prior_count -- how many we can do with previous ingredient

        if not item_hash then error() end -- item_hash should never be nil

        -- check each row of input items
        for i,input in ipairs(recipe.items) do
            -- single item inputs need to be processed in table form
            if type(input) == 'string' then
                input = { input }
            end
            local row_max = 0
            -- adds the max for each item in the or list
            --   for a combined max per row
            for j,iRow in ipairs(input) do
                local iItem = ItemStack(iRow)
                local iName = iItem:get_name()
                local iNeed = iItem:get_count()
                local iHave = item_hash[iName] or 0
                local max = math.floor(iHave/iNeed)
                row_max = row_max + max
            end

            if max_count == 0 or max_count > row_max then
                max_count = row_max
                -- can't have a count bigger then any input row.
            end
            if prior_count and prior_count < max_count then
                -- if we could only craft 2 total with the prior ingredient,
                -- we can't craft 8 now just 'cause we have lots of this one
                max_count = prior_count
            else
                prior_count = max_count
            end
        end
        return max_count
    end

    local function handle_input_alternates(input, craft_count, pItems)
        local row_maxCount = craft_count
        -- use max_count for each row's max
        for j,iRow in ipairs(input) do
            local iItem = ItemStack(iRow)
            local iName = iItem:get_name()
            local iEach = iItem:get_count()
            local iHave = item_hash[iName] or 0
            local ioCount = math.floor(iHave / iEach)
            if ioCount > 0 then
                if ioCount > row_maxCount then
                    ioCount = row_maxCount
                    -- no more then max_count should be picked.
                end
                local taking = iName .." "..ioCount * iEach
                pItems[#pItems+1] = taking
                row_maxCount = row_maxCount - ioCount
                if row_maxCount == 0 then
                    break
                end
            end
        end
    end


    -- more then single requested? find max
    local oItem = ItemStack(recipe.output)
    local oName = oItem:get_name()
    local max_count = find_max_craftable()

    if qty == 2 then -- stack requested so adjust max to max for stack.
        local stack_count = calculate_stack_input(oItem)
        if max_count > stack_count then
            max_count = stack_count
        end
    end
    -- set output to max_count
    local per_input = oItem:get_count() -- How many we get for one input set
    recipe.output = oName .." ".. per_input * max_count
    -- adjust replace
    for i,rItem in pairs(recipe.replace or {}) do -- index, Replace Item
        rItem = ItemStack(rItem)
        rItem:set_count((rItem:get_count() or 1)
            * max_count)
        recipe.replace[i] = rItem:to_string()
    end
    local pItems = {} -- picked items list
    -- set input items to values for max_count
    for i,input in ipairs(recipe.items) do
        if type(input) == 'string' then
            local iItem = ItemStack(input)
            local iCount = iItem:get_count()
            if iCount > 0 then
                local count = iCount * max_count
                local take = iItem:get_name() .. " " .. count
                pItems[#pItems+1] = take
            end
        else
            handle_input_alternates(input, max_count, pItems)
        end
    end
    recipe.items = pItems
end

-- return true if something changed, false else
local function process_receive_fields(player, formname, fields)
    --   if formname ~= '' or formname ~= 'exile:crafting' then return false; end -- Not our form.
    local player_name = player:get_player_name()
    local inv = player:get_inventory()
    local cache = inventoryFS_cache[player_name]
    if not cache or cache == 'closed' then
        cache = initiate_cache(player)
    end
    local done =
        false -- flag to skip processing buttons and skip to saving changes.
    -- Process quit
    -- called when escaping the formspec using inventory key
    if fields.quit then
        close_inventory_formspec(player)
        return true -- cache updated in close
    end
    -- process scrollbar
    if fields.recipes_scroll then
        local value = fields.recipes_scroll
        local scroll = tonumber(string.match(value, "CHG:([0-9]+)"))
        if scroll and scroll ~= cache.sScroll then
            cache.sScroll = scroll
            cache.recipesFS = nil
            cache.output = ""
            done = true
        else
            scroll = tonumber(string.match(value, "VAL:([0-9]+)"))
            if scroll and scroll ~= cache.sScroll then
                cache.sScroll = scroll
                cache.recipesFS = nil
                cache.output = ""
                done = false
                -- VAL: scrollbar responses produced on button pushes
            end
        end
    end
    -- process search buttons
    if fields.crafting_clear then
        return set_search_to(cache, nil)
    end
    if fields.crafting_filter or
        fields.key_enter_field == "crafting_search" then
        -- redraw if filter changed
        return set_search_to(cache, fields.crafting_search)
    end
    -- process new craft tabs
    for i = 1, #(get_craft_tabs(cache.sTool)), 1 do
        if fields['sCraftTab_'..i] then
            if cache.sTab ~=i then
                cache_set_craft_tabs(cache, i, cache.cTabs)
                -- indicates we need to refresh the form
                return true
            end
            return false
        end
    end
    if not done then
        --[[ process all fields for button pushes.
            used for recipes crafting]]
        local btn_type
        local btn_id
        for btn, value in pairs(fields) do
            btn_type,btn_id = process_button(
                btn,{'sResult','b_sTool','qty1','qty2','qty3'})
            if btn_type ~= nil then
                break       -- We found a button
            end
        end

        -- processing quantity buttons
        -- if user checks something to true, register that in cache
        if cache.qty ~= 1 and fields.qty1=='true' then
            cache.qty = 1
        elseif cache.qty ~= 2 and fields.qty2=='true' then
            cache.qty = 2
        elseif cache.qty ~= 3 and fields.qty3=='true' then
            cache.qty = 3
        -- elseif everything is unchecked,  delete associated cache (it would be then put to 1(Single) as defaut in formspec creation).
        elseif (fields.qty1=='false' or fields.qty2=='false' or fields.qty3=='false') then
            cache.qty = nil

        elseif btn_type then
            -- if we changed tool
            if btn_type == 'b_sTool' then
                local tool = cache.tool_list[tonumber(btn_id)]
                cache_tool_change(player, tool, cache)

            -- if we pushed a recipe button
            elseif btn_type == 'sResult' then
                local recipe = table.copy(crafting.get_recipe(tonumber(btn_id)))

                local ctype = get_craft_tabs(cache.sTool)[cache.sTab]
                local sLevel = cache.sLevel
                local qty = cache.qty or 1
                --#TODO I need to improve the way cache.item_hash is assigned/modified
                local item_hash = cache.item_hash or get_item_hash(inv)

                process_qty(recipe,qty, item_hash)

                if not crafting.can_craft(player_name, ctype,
                                          sLevel, recipe) then
                    minetest.log("error", "[inventoryFS] Player clicked a "..
                                 "button they shouldn't have been able to")
                    return true
                -- try to craft, checking first "input_items" list
                elseif crafting.perform_craft(
                    player_name, inv, {"input_items",'main'}, 'main', recipe, ctype) then
                    cache.recipesFS = nil
                    cache.output = ""
                    inventoryFS_cache[player_name] = cache
                    return true -- crafted
                else
                    -- #TODO: see why this is duplicated in crafting/gui.lua
                    --  since that doesn't seem to be used
                    minimal.warn_message(player, player_name,
                                         S("Missing required items!"))
                    --minetest.chat_send_player(
                    --    player_name, ("Missing required items!"))
                    return true -- failed but we handled it
                end
            end
            -- any button pushes require recipes to be redrawn
            cache.output = ""
            cache.recipesFS = nil
        end
    end
    inventoryFS_cache[player_name] = cache
    return true
end

-- Crafting formspec in inventory formspec -------------------------------------

-- Register crafting formspec as inv tab
do
    if not minetest.global_exists("sfinv") then error("Sfinv is missing?") end

    local homepage = sfinv.get_homepage_name() -- get name of homepage
    sfinv.remove_page(homepage)

    sfinv.register_page(
        homepage, {
            title = S("Crafting"),
            get = function(self, player, context)
                local formspec = make_inventory_formspec(player,context)
                return sfinv.make_formspec_for_exile(player, context,
                                                     formspec, false)
            end,
            on_player_receive_fields = function(self, player,
                                                context, fields)
                -- if something changed, redraw the page
                if process_receive_fields(player, "", fields) then
                    sfinv.set_player_inventory_formspec(player, context)
                end
            end,
            -- selecting the tab from an other tab
            on_enter = function(self, player, context)
                --local player_name = player:get_player_name()
                print ("--------------------------]ENTER[-------------------")
                --set_cache(player:get_player_name(),player:get_inventory())
            end,
            on_leave = function(self, player, context)
                --local player_name = player:get_player_name()
                --cache = "closed" -- #TODO not sure about that
                print ("--------------------------]LEAVE[-------------------")
            end,
            --  on_enter = function(self, player, context)
            --          local player_name = player:get_player_name()
            --          local cache=inventoryFS_cache[player_name]
            --          if cache and type(cache) == table then
            --              cache.c_recipes=nil
            --              cache.u_recipes=nil
            --          end
            --          sfinv.set_player_inventory_formspec(player,context)
            --  end
    })
end

-- Crafting formspec on tool station -------------------------------------------

-- Generate the formspec outside sfinv
local function make_tool_formspec(player)
    return tofstring({
            "formspec_version[5]",
            --"size[11.2,10.5]" ..
            "size[11.2,11]",
            "position[0.5,0.5]",
            make_inventory_formspec(player, nil, true)
        })
end

-- used when inventory tab was opened with right click on a tool
minetest.register_on_player_receive_fields(function(player, formname, fields)
        if formname ~= 'exile:crafting' then return false; end -- Not our form.

        local player_name = player:get_player_name()
        if fields.quit then
            -- reset tool list
            cache_tool_remove(player)
            close_inventory_formspec(player)
            sfinv.set_player_inventory_formspec(player)
            return true -- cache updated in close
        end

        if process_receive_fields(player, formname, fields) then
            local formspec = make_tool_formspec(player)
            if formspec then
                minetest.show_formspec(player_name,'exile:crafting',formspec)
            end
        end
end)

-- display craft form on right click on a tool
function crafting.crafting_item_on_rightclick(pos,node,clicker,
                                             itemstack,pointed_thing)
    local craft_item = node.name
    if not minetest.is_player(clicker) then
        return
    end
    local player_name = clicker:get_player_name()

    local cache = inventoryFS_cache[player_name] or initiate_cache(clicker)

    cache_tool_add(clicker, craft_item, cache, pos)

    local formspec = make_tool_formspec(clicker)
    minetest.show_formspec(player_name,'exile:crafting',formspec)
    return itemstack
end

-- update recipe list on inventory action outside the formspec
-- #TODO do better when we can
-- to come, we hope ! #TODO
-- minetest.register_on_inventory_open(function(inventory)
-- end)

function crafting.refresh_recipes_FS(player)
    local player_name = player:get_player_name()
    local cache = inventoryFS_cache[player_name]
    if cache then
        cache_reset_recipes(cache)
    end
    sfinv.set_player_inventory_formspec(player)
end

minetest.register_on_player_inventory_action(function(player, action,
    inventory, inventory_info)
    local from_list = inventory_info.from_list
    local to_list = inventory_info.to_list
    local listname = inventory_info.listname

    if from_list == "main" or to_list == "main"
                           or listname == "main"
                           or listname == "input_items" then

        if from_list == "input_items" or to_list == "input_items" then
            return
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
