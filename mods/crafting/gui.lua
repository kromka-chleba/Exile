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

local c_color= "#3d5a74" -- craftable color
local u_color = "#482d2d" -- uncraftable color
local p_color = "#8a8d48"-- possible color

-- Dealing with crafting tab in inventory formspec

--[[ The inventory formspec is cached for each player like this:
    inventoryFS_cache[player_name] = {
        -- station (on right click)
        -----------------------------
        `station` = {desc = "description" ; creator = "crafted by tag"}

        -- tools
        ------------------------------
        `tool_list` = list of tools I can use, currently {hand,station used}
        `sToolID` = selected tool index in list -- set to 1 by default
        `sTool`  = selected tool name

        -- craft types (subtabs)
        ------------------------------
        `sTab`   = 1 : index of selected_craft_tab
        `cTabs` = nil : "hand", "hand_tool", etc; all output tool type sections
        `sLevel` = selected craft_types'level

        -- recipes lists
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

        -- search panel
        ---------------------------
        `sSearch` = nil : current filter in search field

        -- The Following are tables of formspec strings
        -- to trigger redraw of a section, set the section to nil
        -- eg) to regenerate the recipes list, set
        -- cache.FS_recipes = nil
        -------------------------------------------------------
        `FS_tool_tabs` = nil -- tools
        `FS_ctabs` = nil -- craft tabs
        `FS_recipes` = nil -- recipes list panel
        `FS_search` = nil, -- search container
        `FS_input_list` =nil -- input panel

        -- player settings
        -------------------
        `lang` = player's lang code for translation
        `sorted` = true -- do I want the list to be sorted (order) or not ?
        --#TODO could be put as player setting, or in crafting sfinv as button

        `craft_input` = table of inv to use to craft
        `input_filter` = do put items in input panel trigger automatic filter ?
        -- #TODO make a checkbox for that/player setting.
        `possible_hint` = false -- true to display possible recipes
        -- #TODO : make a button to activate the hint
        `input_filter` = do put items in input panel trigger automatic filter ?
        -- #TODO make a checkbox for that/player setting.

        -- complet formspec to be displayed
        -- not really used anymore
        `output` = "",
    }
    If updated,a section should be set to nil to force a redraw.
    only sections cleared are recreated via make_crafting_formspec
]]
local inventoryFS_cache = {}

--Basic functions --------------------------------------------------------------

-- registering all craft type (tabs) and level available per tool
-- #TODO could be check once at login I guess
local tools_craft_tabs = {}
local tools_level = {}
local default_tool = 'tech:hand'

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
    elseif tools_level[tool] then
        return tools_level[tool]
    else
        -- go get it in registered table else
        local def = minetest.registered_nodes[tool]
            or minetest.registered_tools[tool]
            or minetest.registered_items[tool]
        if def and def.exile_crafting then
            tools_level[tool] = def.exile_crafting.craft_level
            return tools_level[tool]
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

--#TODO develop, to have a custom player setting telling if we want to craft with input + main or input only
--return table of inv to use, according to what we do with input panel.
local function get_craft_input(cache)
    -- Use only
    if not cache.craft_input or cache.craft_input == 1 then
        return {"input_items"}
    -- Do not use
    elseif cache.craft_input == 2 then
        return {'main'}
    -- Use first -- hidden in dropdown
    elseif cache.craft_input == 3 then
        return {"input_items",'main'}
    else
        core.log("craft_input value is not valid")
        return {"input_items"}
    end
end

local function get_input_hash(pInv,cache)
    return crafting.get_item_hash(pInv, get_craft_input(cache))
end

local function get_possible_hash(pInv,cache)
    return crafting.get_item_hash(pInv, {"main", "input_items"})
end

local function get_stringtable(pInv, list)
    local s = {}
    local l = pInv:get_list(list)
    for _,item in ipairs(l) do
        if not item:is_empty() then
            s[#s+1] = item:get_name()
        end
    end
    return s
end

local function apply_filters(cache, pInv)
    -- automatic filter in input field
    if cache.input_filter then
        -- #TODO dirty to make bette for less table parsing
        crafting.reset_search(cache.recipes)
        -- input field
        local st = get_stringtable(pInv, "input_items")
        crafting.apply_search_to_list(cache.recipes, st, cache.lang, true)
    end
    -- search field
    crafting.apply_search_to_list(cache.recipes, cache.sSearch, cache.lang)
end

-- Cache initialisations -------------------------------------------------------
--------------------------------------------------------------------------------

--[[ initiate or reset existing cache to default
    and saves it to inventoryFS_cache[player:get_name()]
    Returns that cache]]
local function initiate_cache(player)
    local player_name = player:get_player_name()
    -- creates empty table if needed
    if inventoryFS_cache[player_name] == nil then
        inventoryFS_cache[player_name] = {}
    end
    -- local shortcut to that cache
    local cache = inventoryFS_cache[player_name]
    -- erase cache
    for k,_ in pairs(cache) do
        cache[k] = nil
    end

    -- player's language for translations
    cache.lang = minetest.get_player_information(player_name).lang_code

    -- no station by default
    cache.station = nil

    -- tool
    cache.sTool = default_tool
    cache.tool_list = generate_tools_list()
    cache.sToolID =  1
    cache.sLevel = get_tool_level(default_tool)
    -- crafting tabs
    cache.sTab = 1 -- default to first tab
    cache.cTabs = get_craft_tabs(cache.sTool)
    -- recipes
    cache.sScroll = 0 -- reset scrollbar to top
    cache.sorted = true -- tell if we sort list or not #TODO for futur setting, currently always true

    -- quantity selector
    cache.qty = 1
    -- choice of craft_input. 1 by default.
    local meta = player:get_meta()
    cache.craft_input = meta:get_int("crafting:ingredients") or 2
    if cache.craft_input == 1 then
        cache.updated = true
    end
    cache.possible_hint = false
    cache.input_filter = (cache.craft_input == 1)

    return cache
end

local function get_FS_cache(player)
    -- get the FS cache if already existant
    local cache = inventoryFS_cache[player:get_player_name()]
    -- else generates it
    if not cache then
        -- that function modified player's cache and return that cache
        cache = initiate_cache(player)
    end
    return cache
end

-- Recipes list part -----------------------------------------------------------

--[[ take current craftable and uncraftable list and
    recheck if each one is craftable or not
    update those lists in cache
    #TODO : warning, only check inputs, do not check new unlocked recipes or change of level
]]
local function update_recipes_lists(player_name, pInv, cache, item_hash)
    local c_recipes = cache.c_recipes
    local p_recipes = cache.p_recipes
    local u_recipes = cache.u_recipes
    -- updates ingredients state and infotext in first list
    for i, result in ipairs(c_recipes) do
        crafting.update_craftable_state(result, item_hash)
        if cache.craft_input == 1 then
            -- get what is possible using both input + inventory
            -- #TODO this is only to sued with option one, improve that part
            local i_s = get_possible_hash(pInv,cache)
            result.possible = crafting.check_inputs(result.recipe, i_s)
        end
    end

    -- updates ingredients state and infotext in second list
    -- and move new craftable recipes to end of first one
    local new_p={}
    local new_u={}
    for _, r_list in ipairs({p_recipes,u_recipes}) do
        for i, result in ipairs(r_list) do
            crafting.update_craftable_state(result, item_hash)
            if result then
                -- if it became craftable, add to previous list and hide in this one
                if result.craftable == 1 then
                    c_recipes[#c_recipes + 1] = result
                elseif result.possible == 1 then
                    new_p[#new_p + 1] = result
                else -- else keep it in uncraftable list
                    new_u[#new_u + 1] = result
                end
            end
        end
    end
    cache.p_recipes = new_p
    cache.u_recipes = new_u
end


-- build recipes list to display in crafting tab
-- is search is not nil, it returns only the ones matching the search criteria
-- return sorted lists if sorted = true, unique list else
-- also return the size as 2nd return
local function get_recipes_list(cache, pInv, player_name, sorted)
    local cTabs = get_craft_tabs(cache.sTool)    -- Crafting tabs to display
    local sTab = cache.sTab      -- selected craft type tab
    local ctype = cTabs[sTab]

    cache.item_hash = get_input_hash(pInv,cache)

    -- if I don't have the recipes list yet, get it
    if not cache.recipes then
        local sLevel = cache.sLevel  -- level associated with selected craft type
        local unlocked = crafting.get_unlocked(player_name)
        cache.recipes = crafting.get_all(ctype, sLevel, cache.item_hash, unlocked)
    end

    -- apply search filters if needed
    apply_filters(cache, pInv)

    -- get what is possible using both input + inventory
    -- #TODO this is only to used with option one, improve that part
    if cache.craft_input == 1 and cache.possible_hint then
        for _,result in ipairs(cache.recipes) do
            -- check possible from inv
            local i_s = crafting.get_item_hash(pInv, {"main", "input_items"})
            result.possible = crafting.check_inputs(result.recipe, i_s)
        end
    end

    -- if we don't want to sort the recipes
    if not sorted then --sorted is false or non given
        return {cache.recipes} -- return unsorted list

    -- else sorte cache.recipes in craftable, uncraftable and possible lists
    elseif sorted == true then
        local c_recipes = cache.c_recipes
        local u_recipes = cache.u_recipes

        -- #TODO improve with possible recipes
        if not (c_recipes and u_recipes) then
            c_recipes, cache.p_recipes, u_recipes =
                crafting.sort_craftable_recipes(cache.recipes)
            -- save the lists in the cache
            cache.c_recipes= c_recipes
            cache.u_recipes= u_recipes
        else
            --[[ #TODO issue here for when we unlock recipes :
            when updating status only to keep the order,
            we only have current lists,
            so newly unlocked recipes won't be added to display.]]
            update_recipes_lists(player_name, pInv, cache, cache.item_hash)
        end
        return {cache.c_recipes, cache.p_recipes, cache.u_recipes}
    end
end

-- Formspec generations -------------------------------------------------------
--------------------------------------------------------------------------------
local esc = minetest.formspec_escape

--[[ This is the function to call to create or update the formspec.
    It returns the full crafting formspec to be displayed
    updates are triggered by the section to redraw set to nil :
    eg cache.FS_recipes = nil to redraw recipes list.
    * `context` is the context for sfinv if we are in inventory formspec.
    It is set to nil if we are at a station.
    ]]
local function make_crafting_formspec(player, context)
    local player_name = player:get_player_name()
    local pInv = player:get_inventory()
    if not (player_name and player_name ~= "") then
        return nil -- no player name
    end
    -- initiates inventoryFS_cache[player_name] if non existant
    local cache = get_FS_cache(player)

    -- context exists for inventory formspec only
    -- #TODO check that part, context mayeb work like current station
    -- that was used to generate different formspec for stations
    -- if not context and cache == 'closed' then
    --     return nil
    -- end

    -- output will be the formspec string
    local output = {
        'container[0,0]'
    }

    -- Inventory List part------------------------------------------------------

    output[#output + 1] = 'container[0.8,7.2]'

    -- if crafting panel is open
    if cache.updated == true or cache.station then
        local bg_color
        -- background color
        if cache.craft_input == 1 then
            if cache.possible_hint == true then
                bg_color = p_color
            else
                bg_color = u_color
            end
        else
            bg_color = c_color
        end
        if bg_color then
            -- output[#output + 1] = "box[-0.23,-0.2;10.2,2.65;".. bg_color .. "]"
            output[#output + 1] = "box[-0.18,-0.18;10.1,2.6;".. bg_color .. "]"
        end
    end

    output[#output + 1] = tofstring({
        'style_type[list;size=;spacing=]',
        'list[current_player;main;0,0;8,2;0]'
    }
    )
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
    if context and not cache.updated then
        output[#output + 1]= tofstring({
            --'style[refresh_r;bgimg=;bgimg_pressed=;border=;bgcolor=red; sound=]'
            'button[1.8,1.2;8,4;refresh_r;',
            S("Open recipes"),
            ']'
        })

        output[#output + 1] = 'container_end[]'

        return tofstring(output)
    end

    -- continues only if cache.updated -----------------------------------------

    -- Tool types part --------------------------------------------

    -- Draw the tool type part
    --[[Shouldn't need to rebuild this more then once per player per restart
        or when player adds to their craft_types
        See adding tools/benches to input_items list]]
    local function FS_tool_types()
        local selected = cache.sTool or default_tool -- default to hand crafting
        local tool_list = cache.tool_list or generate_tools_list()
        local FS_tool_tabs = {
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

            FS_tool_tabs[#FS_tool_tabs + 1] =
                "image[" .. coords .. ";0.9,0.9;" .. bg_image .. "]"

            if tool~="" then
                -- Dipslay item image
                FS_tool_tabs[#FS_tool_tabs + 1] =
                   'item_image_button[' .. coords .. ';0.9,0.9;'
                   .. tool ..';b_sTool_' .. i .. ';]'
                FS_tool_tabs[#FS_tool_tabs + 1] =
                    'tooltip[b_sTool_' .. i .. ';'
                    .. ItemStack(tool):get_short_description() .. ']'
            end
            x = x + 1
            if x > 1 then
                x = 0
                y = y + 1
            end
        end

        FS_tool_tabs[#FS_tool_tabs + 1] ='container_end[]'

        return tofstring(FS_tool_tabs)
    end

    if not cache.FS_tool_tabs then
        cache.FS_tool_tabs =  FS_tool_types()
    end
    output[#output + 1] = 'container[.4,0.6]'
    output[#output + 1] = cache.FS_tool_tabs
    output[#output + 1] = 'container_end[]'

    -- Optional CraftedBy string -----------------------------------------------
    --[[
    -- if we are not in hand crafting and we have a tag to display:
    if cache.sTool ~= default_tool and cache.station.creator then
        output[#output + 1] = tofstring({
            'container[0.45,',2.2,']',
            'label[0,0;',S("Station made by: "),']',
            'label[0.6,0.4;', cache.station.creator,']',
            'container_end[]'
        })
    end
    ]]

    -- Recipes List part -------------------------------------------------------

    -- Craft tabs FS generation --
    local function FS_craft_tabs()
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

        return tofstring(pan_t)
    end

    if cache.FS_ctabs == nil then
        cache.FS_ctabs = FS_craft_tabs()
    end

    -- Recipes list FS generation --
    -- Draws Recipe panel part of the formspec
    local function FS_recipes_panel()
        --[[ display individual recipe slot
            Returns associated formspec string
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
            if craftable == 1 then
                bg_image = 'crafting_slot_craftable.png'
            elseif result.possible == 1 and cache.possible_hint then
                bg_image = 'crafting_slot_possible.png'
            else
                bg_image = 'crafting_slot_uncraftable.png'
            end

            if bg_image then
                form_table[#form_table + 1] = "image[" .. bg_coords .. ";1,1;" .. bg_image .. "]"
            end

            -- Add button image
            local btn_coords =
            tostring( x + 0.1 ) .. ','..
            tostring( y + 0.3 )

            if result.recipe._display then
                form_table[#form_table + 1] = tofstring({
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
                form_table[#form_table + 1] = tofstring({
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
            form_table[#form_table + 1] = tofstring({
                'tooltip[sResult_',
                id,
                ';',
                minetest.formspec_escape(item_description .. "\n")
            })

            -- add recipe's tooltip part 2 : inputs
            local index = #form_table + 1
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

        local FS_recipes = {}         -- final fromspec
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
        local raw_list = get_recipes_list (cache, pInv, player_name, cache.sorted)
        local display_list={}
        for _, r_list in ipairs (raw_list) do
            --displays all recipes matchng with search field
            for i, result in ipairs(r_list) do
                -- display if this recipe matches the filter
                if result.displayed == true then
                    display_list[#display_list + 1] = result
                end
            end
        end
        local nb_recipes=#display_list

        local columns = 6 -- can show 6 items accross without scrollbar

        -- add scrollbar if needed
        -- #TODO don't reset the recipe lists just because of the scrollbar
        local sScroll = cache.sScroll or 0 -- default to 1 for top of scroll
        if nb_recipes > columns * line_number then
            -- columns = columns -1 -- discard a line to make room for scrollbar
            local scroll_max = math.ceil(nb_recipes / columns)-line_number
            FS_recipes[#FS_recipes + 1] =
            'scrollbaroptions[max=' .. tonumber(scroll_max) .. ';'
            .. 'smallstep=1;largestep=line_number;thumbsize=1]'
            FS_recipes[#FS_recipes + 1]
            = 'scrollbar[7.1,0.95;.5,' .. (1.14*line_number) .. ';vertical;recipes_scroll;'
            .. sScroll .. ']'
        end

        -- create scroll container
        FS_recipes[#FS_recipes + 1] = tofstring({'scroll_container[0,0.75;',
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
        for i, result in ipairs (display_list) do
            FS_recipes[#FS_recipes + 1] =
                FS_display_recipe(result, x * grid_size, y * grid_size)

            x = x + 1
            if x >= columns  then
                x = 0
                y = y + 1
            end
        end

        FS_recipes[#FS_recipes + 1] = 'scroll_container_end[]'

        return  tofstring(FS_recipes)
    end

    if cache.FS_recipes == nil then
        cache.FS_recipes = FS_recipes_panel()
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

        local bg_color
        -- background color
        if cache.craft_input ~= 2 then
            bg_color = c_color
        else
            bg_color = u_color
        end

        -- #TODO put as setting the color of craftable
        fs[#fs + 1] = "box[-0.07,-0.4;2.7,3.24;" .. bg_color .. "]"

        -- label
        -- replaced by dropdown, uncomment if you comment the dropdown
        -- fs[#fs + 1] = 'label[0,0;'..S("Ingredients:")..']',
        -- to hide if we don't want the option visible :D #TODO remove when test are finished
        fs[#fs + 1] = 'dropdown[0.1,-0.25;2.35,0.5;input_option;'
        fs[#fs + 1] = ' Use only, Do not use;'
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

    if cache.craft_input == 1 then
        output[#output + 1] = 'button[0.6,3.6;1.5,0.5;hint;'.. S("Hint") .. ']'
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

-- Cache modifications  -------------------------------------------------------
-------------------------------------------------------------------------------

-- reset recipes in cache (list and formspec)
local function cache_reset_recipes(cache)
    -- will force to resort recipes
    -- resets recipes lists
    cache.c_recipes = nil -- list of craftable recipes to display
    cache.p_recipes = nil -- list of possible recipes to display
    cache.u_recipes = nil -- list of uncraftable recipes to display
    cache.recipes = nil
    -- erases recipes panel formspec part
    cache.FS_recipes = nil
    -- reset scroll bar to top
    cache.sScroll = 0 -- reset scrollbar to top
end

-- set craft tabs in cache
local function cache_set_craft_tabs(cache, sTab, cTabs)
    cache.sTab = sTab or cache.sTab or 1
    cache.cTabs = cTabs or cache.cTabs or get_craft_tabs(cache.sTool)
    -- erases craft tabs formspec
    cache.FS_ctabs = nil
    -- reset recipes and erases recipes panel formspec
    cache_reset_recipes(cache)
end

-- Update cache on tool change
-- changes to default_tool if `tool` == `nil`
local function cache_tool_change(cache, tool)
    if cache == nil then
        core.log("cache shouldn't be nil in cache_tool_change")
    end

    if tool == nil then
        tool = default_tool
    end

    -- if I don't change the tool, don't change the tabs and recipes
    if cache.sTool ~= tool then
        cache.sToolID =  tool_to_ID(tool, cache)
        cache.sTool = tool
        cache.sLevel = get_tool_level(tool)
        cache_set_craft_tabs(cache, 1, get_craft_tabs(tool))
    end

    cache.FS_tool_tabs= nil
end

-- change Search field and reset formspec accordingly
-- return true is any change, to trigger formspec redraw
local function set_search_to(cache, s)
    local transformed = minimal.make_search_string(s)
    -- if I changed the text in the search field, reset recipes
    if cache.sSearch ~= transformed then
        cache.sSearch = transformed
        cache.FS_search = nil
        cache_reset_recipes(cache)
        return true
    else
        return false
    end
end

-- Formspec actions ------------------------------------------------------------
--------------------------------------------------------------------------------

-- Call when the inventory formspec is closed to clear cache
-- `player_name` param is optional
-- #TODO : would be good to still save the curent subtab instead of clearing everything
local function close_inventory_formspec(player, player_name)
    player_name = player_name or player:get_player_name()
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
                    pInv:add_item('main', stack)
                else
                    -- Drop item if no room in inventory
                    minetest.item_drop(stack, player, player:get_pos())
                    -- warns the player it went on the ground
                    minimal.warn_inv_full(player)
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
    -- update recipe list to have refresh button
    if cache.craft_input ~= 1 then cache.updated = false end
    cache_reset_recipes(cache)

    cache.possible_hint = false
end

--#TODO check how it is done and using itemhash and if it can be improved.
-- Quantity sets single, stack or maximum -- this finds how many we can craft
-- returns nothing but update recipe.items
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

-- function called when pushing a recipe button
local function craft_recipe(btn_id, cache, player, player_name, inv)
    local recipe = table.copy(crafting.get_recipe(tonumber(btn_id)))
    local ctype = get_craft_tabs(cache.sTool)[cache.sTab]
    local sLevel = cache.sLevel
    local qty = cache.qty or 1
    --#TODO I need to improve the way cache.item_hash is assigned/modified
    local item_hash = cache.item_hash or get_input_hash(inv,cache)

    process_qty(recipe, qty, item_hash)

    if not crafting.can_craft(player_name, ctype,
                              sLevel, recipe) then
        minetest.log("error", "[inventoryFS] Player clicked a "..
                     "button they shouldn't have been able to")
        return true
    -- try to craft
    -- get_craft_input(cache) is the input list
    -- 'main' is the output list
    elseif crafting.perform_craft(
        player_name, inv, get_craft_input(cache), 'main', recipe, ctype) then
        cache.FS_recipes = nil
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

-- return true if something changed, false else
local function process_receive_fields(player, formname, fields)
    --   if formname ~= '' or formname ~= 'exile:crafting' then return false; end -- Not our form.
    local player_name = player:get_player_name()
    local inv = player:get_inventory()

    local cache = inventoryFS_cache[player_name]
    -- #TODO cache should never be nil right ?
    -- maybe display an error in that case ?
    if not cache then
        core.log("player's crafting cache should be nil in process_receive_fields")
        cache = initiate_cache(player)
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

    -- flag to skip processing buttons and skip to saving changes.
    -- #TODO can't it be replaced by "return true" ?
    -- seems we do inventoryFS_cache[player_name] = cache first
    local done = false

    -- Process quit
    -- called when escaping the formspec using inventory key
    if fields.quit then
        close_inventory_formspec(player, player_name)
        return true
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
        local input_option = tonumber(fields.input_option)
        if input_option~= cache.craft_input then
            cache.craft_input = input_option
            if input_option == 1 then cache.updated = true end
            -- save in player's settings
            local meta = player:get_meta()
            meta:set_int("crafting:ingredients", input_option)
            -- refresh input panel
            cache.FS_input_list = nil
            -- refresh recipe panel
            cache.FS_recipes = nil
            done=true
        end
    end

    -- process search buttons
    -- clear search
    if fields.search_reset then
        return set_search_to(cache, nil)
    end
    -- search field change
    if fields.craft_filter or
        fields.key_enter_field == "crafting_search" then
        return set_search_to(cache, fields.crafting_search)
    end

    -- process input setting
    if fields.i_filter then
        cache.input_filter = (fields.i_filter == "true")
        -- #TODO improve that and the set_search to not recalculate all recipes craftable states
        cache_reset_recipes(cache)
    end

    -- process "hint" button"
    if fields.hint then
        cache.possible_hint = not cache.possible_hint
        -- #TODO improve the temporary part and reset button
        cache_reset_recipes(cache)
        -- #TODO check how to reset (or not) that part
        -- do I really need to cache it ?
        cache.FS_input_list = nil
        done = true -- #TODO what does it do ? do I want it he
    end

    -- process get recipes button
    if fields.refresh_r then
        cache.updated = true
        cache_reset_recipes(cache)
        done = true
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

    -- if skipping button is "false"
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
        --[[ elseif everything is unchecked, delete associated cache
        -- (it would be then put to 1(Single) as defaut in formspec creation.)]]
        elseif (fields.qty1=='false' or fields.qty2=='false' or fields.qty3=='false') then
            cache.qty = nil

        elseif btn_type then
            -- if we changed tool
            if btn_type == 'b_sTool' then
                local tool = cache.tool_list[tonumber(btn_id)]
                cache_tool_change(cache, tool)

            -- if we pushed a recipe button
            elseif btn_type == 'sResult' then
                return craft_recipe(btn_id, cache, player,  player_name, inv)
            end
            -- any button pushes require recipes to be redrawn
            -- #TODO was already done in craft_recipe
            cache.FS_recipes = nil
        end
    end
    inventoryFS_cache[player_name] = cache
    return true
end

-- Crafting formspec in inventory formspec -------------------------------------
--------------------------------------------------------------------------------

-- Register crafting formspec as inv tab
do
    if not minetest.global_exists("sfinv") then error("Sfinv is missing?") end

    local homepage = sfinv.get_homepage_name() -- get name of homepage
    sfinv.remove_page(homepage)

    sfinv.register_page(
        homepage, {
            title = S("Crafting"),
            get = function(self, player, context)
                local formspec = make_crafting_formspec(player,context)
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
--------------------------------------------------------------------------------

-- Generate the formspec outside sfinv
local function make_tool_formspec(player)
    local cache = get_FS_cache(player)

    local fs = {"formspec_version[5]",
                --"size[11.2,10.5]" ..
                "size[11.4,10]",
                "position[0.5,0.5]"}

    -- #TODO dirty, do better once we decide on definitive behavior
    if cache.sTool ~= default_tool then
        local desc = cache.station.desc
        local creator = cache.station.creator
        local title = S("You are using: @1", desc)
        if creator then
            title =  title .. "  |  " .. S("Crafted by: @1", creator)
        end
        fs[#fs + 1] = "tabheader[0,0;station_tab;" .. title .. ";1;;]"
    end

    fs[#fs + 1] =make_crafting_formspec(player, nil)

    return tofstring(fs)
end

-- return craftedby info for the given station, nil if not found
-- #TODO not sure it should stay on gui.lua
local function get_station_info(station, pos)
    -- if no station, no tag
    if station == nil then
        return nil
    end
    -- #TODO (for lili) go check on that
    -- see tech/stations for why we check _station or remove letters from name
    local idef = core.registered_items[station._tool]
        or core.registered_items[station:sub(1,-8)]
        or core.registered_items[station]

    local creator = nil
    local desc = nil
    -- if station is registered and has a groups field
    if idef then
        -- #TODO how do I get the short description ??
        desc = ItemStack(idef.name):get_short_description()
        if idef.groups then
            -- if there is a craftby field or savemeta in groups
            if idef.groups.craftedby or idef.groups.savemeta then
                local meta = core.get_meta(pos)
                -- get creator string for craftedby mechanics
                if meta then
                    creator = meta:get_string("creator")
                end
            end
        end
    end
    -- return nil if not found
    return {desc = desc, creator = creator}
end

-- quit station and reset tools to default
local function cache_quit_station(player)
    local cache = get_FS_cache(player)
    -- reset station
    cache.station = nil
    -- reset tool list
    cache.tool_list = generate_tools_list()
    -- unselect tool to default
    cache_tool_change(cache, nil)

end

local function cache_on_station(player, placed_tool, pos)
    if not placed_tool then
        core.log("invalid empty station to use on right click")
        return
    end
    local cache = get_FS_cache(player)
    -- adds station info
    cache.station = get_station_info(placed_tool, pos)
    -- generates corresponding tools list
    cache.tool_list = generate_tools_list(placed_tool)
    -- updates cache with new selected `placed_tool` as tool
    cache_tool_change(cache, placed_tool)
end

-- used when inventory tab was opened with right click on a tool
minetest.register_on_player_receive_fields(function(player, formname, fields)
        if formname ~= 'exile:crafting' then return false; end -- Not our form.

        local player_name = player:get_player_name()
        if fields.quit then
            -- reset tool list
            cache_quit_station(player)
            close_inventory_formspec(player, player_name)
            -- updates inventory formspec after reset of the cache
            -- this is because it won't be regenerated on opening
            -- (no inventory open callback in luanti, yet)
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
    -- did a player click ?
    if not minetest.is_player(clicker) then
        return
    end

    -- #TODO we should check it is a valid node before doingthat,
    -- since this is a global function
    cache_on_station(clicker, node.name, pos)

    -- generates and shows station's formspec
    local formspec = make_tool_formspec(clicker)
    local player_name = clicker:get_player_name()
    minetest.show_formspec(player_name,'exile:crafting',formspec)

    return itemstack
end

--------------------------------------------------------------------------------

--[[ Following part a lots of events functions because no "on open inventory" callback in Luanti yet
    So we update the recipes list as we can outside the mod, on external events
    crafting.refresh_recipes function is to be called by external mods

    If that changed, it could be simplied to keep only input_items inventory moves
]]

--------------------------------------------------------------------------------

-- Delete recipes list cache and update inventory formspec
function crafting.refresh_recipes_FS(player)
    local player_name = player:get_player_name()
    local cache = inventoryFS_cache[player_name]
    if cache then
        cache_reset_recipes(cache)
    end
    sfinv.set_player_inventory_formspec(player)
end

-- Refresh recipe list when items put in and out the input panel
local function update_input_list(player)
    -- #TODO I think it should be replaced by an other refresh on craftable state.
    -- That part still needs to be cleaned.
    crafting.refresh_recipes_FS (player)

    -- force redraw f formspec if we were in station
    local player_name = player:get_player_name()
    local cache = get_FS_cache(player)
    if cache.station then
        core.show_formspec(player_name,'exile:crafting',
                                        make_tool_formspec(player))
    end
end

minetest.register_on_player_inventory_action(function(player, action,
    inventory, inventory_info)
    local from_list = inventory_info.from_list
    local to_list = inventory_info.to_list
    local listname = inventory_info.listname

    if from_list == "input_items" or to_list == "input_items" then
        core.after(0.1, update_input_list, player)
    --if we get or drop things from main inventory, except for internal move to inputs, refresh recipes
    elseif from_list == "main" or to_list == "main"
                           or listname == "main" -- usefull ?
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
