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

local S = minetest.get_translator("minimal")
local tofstring = function(t) return table.concat(t,"") end

minimal = minimal
crafting = crafting
sfinv = sfinv

--[[ Thoses functions where made by Izzy and not used anymore...
    Seems to be used to clean old cache
    Commenting them untile I can talk with him #TODO

local function debug_keys(table)
    local output=""
    for k,v in pairs(table) do
        output = output .. v .. ','
    end
    return output
end

local function debug_cache(table)
    local output=""
    for k,v in pairs(table) do
        if (string.match(k, '.*FS$') or k == 'output') then
            output = output .. k
        else
            if type(v) == 'table' then
                v = debug_keys(v)
            end
            output = output .. k .. ' = ' .. v
        end
        output = output ..', '
    end
    return output
end
]]

--[[ The inventory formspec is cached for each player like this:
    inventoryFS_cache[player_name] = {
        epoch  = os.time(),             -- Used to expire cache
        tool_list -- list of tools I can use
        sToolID = selected tool index in list -- set to 1 by default
        sTool  = selected tool name
        sTab   = selected_craft_tab     -- index of selected tab in craft_types  - default = 1
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

        recipesFS = {},
        searchFS= "", -- search container
        inventoryFS = {},
        output = "",
    }
    output is cleared if any of the elements is updated to force a redraw
    each section of the formspec is cached as string.  If updated,
    a section should be set to nil and output set to "" to force a redraw.
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

-- process "quantity" setting
local function process_qty(recipe,qty,item_hash)
    if qty > 1 then -- more then single requested find max
        local oItem = ItemStack(recipe.output)
        local oName = oItem:get_name()
        local oCount = oItem:get_count() or 1
        local max_count = 0
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
        end
        if qty == 2 then -- stack requested so adjust max to max for stack.
            local def = minetest.registered_nodes[oName]
                or minetest.registered_craftitems[oName]
                or minetest.registered_tools[oName]
            local stack_count = def.stack_max or 1
            if max_count > stack_count then
                max_count = stack_count
            end
        end
        -- set output to max_count
        recipe.output = oName .." "..max_count * oCount
        -- adjust replace
        for i,rItem in pairs(recipe.replace) do -- index, Replace Item
            rItem = ItemStack(rItem)
            rItem:set_count((rItem:get_count() or 1)
                * max_count) -- qty is weird, use max_count
            recipe.replace[i] = rItem:to_string() -- to_string works as of 5.0+
        end
        local pItems = {} -- picked items list
        -- set input items to values for max_count
        for i,input in ipairs(recipe.items) do
            if type(input) == 'string' then
                local iItem = ItemStack(input)
                local iCount = iItem:get_count()
                if iCount > 0 then
                    local count = iCount * max_count
                    pItems[#pItems+1] = iItem:get_name() .. " " .. count
                end
            else
                local row_maxCount = max_count
                -- use max_count for each row's max
                for j,iRow in ipairs(input) do
                    local iItem = ItemStack(iRow)
                    local iName = iItem:get_name()
                    local iEach = iItem:get_count()
                    local iHave = item_hash[iName] or 0
                    local oCount = math.floor(iHave / iEach)
                    if oCount > 0 then
                        if oCount > row_maxCount then
                            oCount = row_maxCount
                            -- no more then max_count should be picked.
                        end
                        pItems[#pItems+1] = iName .." "..oCount * iEach
                        row_maxCount = row_maxCount - oCount
                        if row_maxCount == 0 then
                            break
                        end
                    end
                end
            end
        end
        recipe.items = pItems
    end
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
    for i, result in ipairs(c_recipes) do
        -- if not craftable anymore, change backgound/status
        if not crafting.is_craftable (cache.sLevel, item_hash, unlocked, result.recipe) then
            result.craftable = false
        end
    end
    local new_u={}
    cache.u_recipes = new_u
    for i, result in ipairs(u_recipes) do
        -- if it became craftable, add to previous list and hide in this one
        if crafting.is_craftable (cache.sLevel, item_hash, unlocked, result.recipe) then
            result.craftable = true
            c_recipes[#c_recipes + 1] = result
        else -- else keep it in uncraftable list
            new_u[#new_u + 1] = result
        end
    end
end

-- build recipes list to display in crafting tab
-- is search is not nil, it returns only the ones matching the search criteria
local function recipes_for_player(cache, pInv, player_name, ctype, level, search)
    local unlocked = crafting.get_unlocked(player_name)
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
    -- save item_hash to cache
    cache.item_hash = item_hash
    -- Get all available recipies and mark craftible ones.
    -- #TODO maybe just pass the player and cache and not have that many parameters
    local c_recipes = cache.c_recipes
    local u_recipes = cache.u_recipes
    if not (c_recipes and u_recipes) then
        c_recipes, u_recipes =  crafting.get_all_sorted(ctype, level, item_hash, unlocked, search, minetest.get_player_information(player_name).lang_code)
        -- save the lists in the cache
        cache.c_recipes=c_recipes
        cache.u_recipes=u_recipes
    else
        update_recipes_lists(player_name, cache, item_hash)
    end

    return cache.c_recipes, cache.u_recipes
end

-- Formspec generations -------------------------------------------------------
--------------------------------------------------------------------------------

-- Tools part ------------------------------------------------------------------

-- Draw the tool type part
--[[Shouldn't need to rebuild this more then once per player per restart
    or when player adds to their craft_types
    See adding tools/benches to input_items list]]
local function FS_tool_types_to_cache(cache)
    local selected = cache.sTool or default_tool -- default to hand crafting
    local tool_list = cache.tool_list or generate_tools_list()
    local tool_tabsFS = {
        'label[0,0;'..S("Tool used")..']',
        -- 'box[0,.2;2.5,1.9;black]',
        'container[0,0.3]',
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
        else
            -- display empty space #TODO unused right now
            tool_tabsFS[#tool_tabsFS + 1] =
            'image[' ..coords..';0.8,0.8;crafting_slot_empty.png]'
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

-- Tabs and Recipes part -------------------------------------------------------

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

--[[Recreated Recipe part of the formspec
- updated = true : displays refreshed recipe list.
needs to be triggered when the craft_type, craft_tab, input_items,
or selected inventory changes
- updated = false : displays a button in recipe panel to indicate that the  recipe list is not up-to-date (but as it was when the formspec was closed)
This is because there is currently no callback for "I opened the inventory" so closng it will create a formspec that will be the one dsplayed on re-opening
needs to be triggered when we close the formspec
]]
--#TODO I think this is called too many times and could be optimized ?
local function FS_recipes_to_cache(cache, player_name, pInv, updated)
    local recipesFS = {}         -- final fromspec
    local sTool = cache.sTool    -- craft type Item selected
    local sTab = cache.sTab      -- selected craft type tab
    local sLevel = cache.sLevel  -- level associated with selected craft type
    local cTabs = get_craft_tabs(sTool)    -- Crafting tabs to display
    local sScroll = cache.sScroll or 0 -- default to 1 for top of scroll
    local sSearch = cache.sSearch

    -- this is for more clarity, choice of display settings
    --[[size of a square of recipe : 1*1 of image + 0.1 margins around,
    used to place them on a grid, including tabs]]
    local line_number = 3 -- nb of lines of recipes displayed
    local grid_size = 1.2

    -- Add tab header -------------------------------------------------

    -- generate formspec for crafting tabs

    local pan_t = {
        --style 1 : no border
        "style_type[item_image_button;border=false;bgimg_middle=4]",

        --[[ style 2 : with border
        "style_type[item_image_button;border=true;bgimg_middle=4]",
        --if this tab is selected, change style
        "style[sCraftTab_"..sTab..";bgcolor=#FFFFFF]"]]
    }

    local coords
    for i=1, #cTabs do
        coords = tostring((i - 1) * 0.85) ..',0'
        ---------------------------------------------------------------
        local item_name = crafting.icon_item_name[cTabs[i]]
        or 'crafting:placeholder'
        -- #TODO new version to check/integrate :
        --local button_type = 'item_image_button['
        --local suffix = ']'
        --if item_name == string.gsub(item_name, ":", "") then -- not an item
        --    button_type = 'image_button['
        --    -- item_image_button and image_button formats differ, so..
        --    suffix = ';;false]' -- hide borders on item_, which has extra fields
        --end
        --recipesFS[#recipesFS + 1] = button_type..(leftPoint)..
        --    ',0.3;0.6,0.6;'.. item_name .. ';sCraftTab_'..i..';'..suffix

        --set focus on selected tab
        if i == sTab then
            pan_t[#pan_t + 1] =
            'set_focus[sCraftTab_' .. i .. ';true]'
            -- style 1 : no border
            pan_t[#pan_t + 1] =
            "image[" .. coords .. ";0.8,0.8;selected.png]"

        else
            -- style 1 : no border
            --[[uncomment this to activate background of tabs
            pan_t[#pan_t + 1] =
            "image[" .. coords .. ";0.8,0.8;not_selected.png]"
            ]]
        end

        pan_t[#pan_t + 1] = 'item_image_button['..coords..';0.8,0.8;'.. item_name .. ';sCraftTab_'..i..';]'

        pan_t[#pan_t + 1] = 'tooltip[sCraftTab_'.. i ..
        ';' .. minetest.formspec_escape((crafting.tab_labels[cTabs[i]]
        or cTabs[i])) ..
        ';#000000;#ffffff]'
    end

    -- add tabs to the global recipes formspec
    recipesFS[#recipesFS + 1] = tofstring(pan_t)

    -- Add recipes list -------------------------------------------------

    -- #TODO needs to be cleaned, doing 2 sperate functions maybe
    -- also not sure about the cache.output part (still used ?)
    if updated == false then
        recipesFS[#recipesFS + 1]= tofstring({
            'button[0.25,1.75;6,2;refresh_r;',
            S("Get list of recipes"),
            ']',
        })
    else
        -- add Scrollable container for recipes --------------------------
        -- get recipe list to display
        -- this list indicates if the recipe is craftable or not
        -- it contains only the recipes matching the search parameter
        local c_recipes, u_recipes = recipes_for_player(cache, pInv,        player_name, cTabs[sTab], sLevel, sSearch)

        local columns = 6 -- can show 6 items accross without scrollbar
        local nb_recipes = #c_recipes+#u_recipes

        -- add scrollbar if needed
        if nb_recipes > columns * line_number then
            -- columns = columns -1 -- discard a line to make room for scrollbar
            local scroll_max = math.ceil(nb_recipes / columns)-line_number
            recipesFS[#recipesFS + 1] =
            'scrollbaroptions[max=' .. tonumber(scroll_max) .. ';'
            .. 'smallstep=1;largestep=line_number;thumbsize=1]'
            recipesFS[#recipesFS + 1]
            = 'scrollbar[7.2,0.95;.5,' .. (1.14*line_number) .. ';vertical;recipes_scroll;'
            .. sScroll .. ']'
        end

        -- create scroll container
        recipesFS[#recipesFS + 1] = tofstring({
            'scroll_container[0,0.75;',
            tostring(columns + 1),',',(1.25 * line_number),
            ';recipes_scroll;vertical;', grid_size , ']'
        })

        -- Add recipe buttons in container  ------------------------------
        local x = 0
        local y = 0

        --#TODO make a version with unique list for non ordered list as asked by Meniptah
        for _, r_list in ipairs ({c_recipes, u_recipes}) do
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
    end

    -- saving new cache
    cache.recipesFS = tofstring(recipesFS)
    cache.output = ""
    return cache
end

-- Search field part -------------------------------------------------------

-- Build search field to be in container
local function FS_search_field_to_cache(cache)
    local result={
        'field_close_on_enter[crafting_search;false]',
        --'field[0,0;3.0,0.6;crafting_search;'.. S("Search")..';'.. (sSearch or "") .. ']'
        'field[0,0;3.0,0.6;crafting_search;;'.. (cache.sSearch or "") .. ']',
        --recipesFS[#recipesFS + 1] = 'button[3.7,9.5;0.6,0.5;crafting_filter;?]'
        'image_button[3.1,0;0.6,0.6;creative_search_icon.png;crafting_filter;]',
        'image_button[3.8,0;0.6,0.6;creative_clear_icon.png;crafting_clear;]'
    }

    -- saving new cache
    cache.searchFS = tofstring(result)
    cache.output = ""
    return cache
end

-- Inventory Lists part--------------------------------------------------------

-- Generated Input inventory List Cache
-- Shouldn't need to be rebuilt more then once per player per restart
local function FS_input_list_to_cache(cache, pInv)
    local inputs = pInv:get_list('input_items')
    if not inputs or #inputs ~= 6 then
        -- create inputs inventory list and draw formspec for input_itmes
        pInv:set_size('input_items', 6)
    end

    local input_listFS = {
        'label[0,0;'..S("Input Items")..']',
        --                'box[0,.2;2.5,2.5;black]',
        'style_type[list;size=.7,.7;spacing=.1]',
        'list[current_player;input_items;.1,.3;2,3;0]',
    }
    cache.input_listFS = tofstring(input_listFS)
    cache.output = ""
    return cache
end

-- Generated Main inventory List Cache
-- Shouldn't need to be rebuilt more then once per player per restart
local function FS_player_inventory_to_cache(cache)
    local inventory = {
        'style_type[list;size=;spacing=]',
        'list[current_player;main;0,0;8,2;0]'
    }
    cache.inventoryFS = tofstring(inventory);
    cache.output = ""
    return cache
end


-- Cache initialisations -------------------------------------------------------

-- initiate or reset existing cache to default
local function initiate_cache(player)
    local cache = inventoryFS_cache[player:get_player_name()] or {}
    -- erase cache
    for _,v in pairs(cache) do
        v = nil
    end
    cache.epoch = os.time()

    -- tool and crafting recipes
    cache.sTool = default_tool
    cache.tool_list = generate_tools_list()
    cache.sToolID =  1
    cache.sLevel = get_tool_level(default_tool)
    cache.sTab = 1 -- default to first tab
    cache.sScroll = 0 -- reset scrollbar to top

    -- quantity selector
    cache.qty = 1
    -- Search field
    cache.sSearch = nil --current filter in search field
    FS_search_field_to_cache(cache)
    -- Inventory fields
    FS_player_inventory_to_cache(cache)
    FS_input_list_to_cache(cache, player:get_inventory())

    -- final formspec
    cache.output = ""

    -- saving
    inventoryFS_cache[player:get_player_name()] = cache
    return inventoryFS_cache[player:get_player_name()]

end

-- This is the function to call to create or update the formspec.
-- It returns the cache value unless something has updated or it times out
-- updates are triggered by setting cache.output = "" and the section to
-- redraw is set to nil - eg cache.recipesFS = nil to redraw recipes list.
local function make_inventory_formspec(player,context)
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
    -- Any updates to the form contents must set cache.output = "" to bypass
    if not cache or cache == 'closed' then
        cache = initiate_cache(player)
    end


    --IB-test    if cache and cache.output and cache.output ~= "" then
    --IB-test            if os.time() > cache.epoch + __inventoryFS_cache_timeout then
    --IB-test                    inventoryFS_cache[player_name].epoch=os.time()
    --IB-test            else
    --IB-test                    return cache.output
    --IB-test            end
    --IB-test    end
    --reset epoch and draw formspec from cached values unless cleared
    cache.epoch = os.time()

    local qtyID = cache.qty or 1
    local qtytab = { 'false', 'false', 'false' }
    local qtylab = { S("Single"), S("Stack"), S("Maximum") }
    qtytab[qtyID] = 'true'
    qtylab[qtyID] = minetest.colorize("cyan", qtylab[qtyID])

    local output = {
        --'formspec_version[5]',
        --'size[10.5,10.9]',
        --'position[0.5,0.48]',
        'container[0,0]'
    }

    -- Tool types part --------------------------------------------

    if not cache.tool_tabsFS then
        cache =  FS_tool_types_to_cache(cache)
    end
    output[#output + 1] = 'container[.4,.6]'
    output[#output + 1] = cache.tool_tabsFS
    output[#output + 1] = 'container_end[]'

    -- Recipes List part -------------------------------------------------------

    -- #TODO improve the way different caches are updated
    if cache.recipesFS == nil then
        FS_recipes_to_cache(cache,player_name,pInv, true)
    end
    output[#output + 1] = 'container[3, 0.45]'
    output[#output + 1] = cache.recipesFS
    output[#output + 1] = 'container_end[]'

    -- Search field part -------------------------------------------------------

    output[#output + 1] = 'container[3, 5.2]'
    if cache.searchFS == nil then
        FS_search_field_to_cache(cache)
    end
    output[#output + 1] = cache.searchFS
    output[#output + 1] = 'container_end[]'

    -- Quantity buttons part ---------------------------------------------------

    output[#output + 1] = 'container[0.45,6.4]'
    local qty_b = {
        -- 'container[0.35,7.2]',
        'label[0,0;'..S("Quantity")..':]',
        'checkbox[2.6,0;qty1;'..qtylab[1]..';'..qtytab[1]..']',
        'checkbox[4.65,0;qty2;'..qtylab[2]..';'..qtytab[2]..']' ,
        'checkbox[6.65,0;qty3;'..qtylab[3]..';'..qtytab[3]..']'
    }
    output[#output + 1] = tofstring(qty_b)
    output[#output + 1] = 'container_end[]'

    -- Inventory List part------------------------------------------------------

    if not cache.inventoryFS then
    FS_player_inventory_to_cache(cache)
    end
    output[#output + 1] = 'container[0.8,7.2]'
    output[#output + 1] = cache.inventoryFS
    output[#output + 1] = 'container_end[]'

    -- Input List part----------------------------------------------------------

    if not cache.input_listFS then
    cache = FS_input_list_to_cache(cache,pInv)
    end
    output[#output + 1] = 'container[.4,2.8]'
    output[#output + 1] = cache.input_listFS
    output[#output + 1] = 'container_end[]'

    -- listring between input and main inv -------------------------------------
    output[#output + 1] = 'listring[]'

    -- Save output to cache and update -----------------------------------------
    output[#output + 1] = 'container_end[]'
    local result = table.concat(output)
    cache.output = result
    inventoryFS_cache[player_name] = cache
    return result
end

-- Cache modifications  -------------------------------------------------------

-- reset recipes in cache (list and formspec)
local function cache_reset_recipes(cache)
    -- will force to resort recipes
    cache.c_recipes = nil -- list of craftable recipes to display
    cache.u_recipes =nil -- list of uncraftable recipes to display
    cache.recipesFS = nil -- delete recipes formspect from cache
    cache.sScroll = 0 -- reset scrollbar to top
end

-- optional cache
-- change to hand if tool==nil
local function cache_tool_change(player, tool, cache)
    tool = tool or default_tool
    local cache =  cache or inventoryFS_cache[player:get_player_name()]

    -- if no cache, then generate it ? #TODO
    if not cache then
        cache = initiate_cache(player)
    end
    -- if I don't change the tool, do nothing
    if cache.sTool == tool then
        return

    -- else change tool
    else
        cache.sToolID =  tool_to_ID(tool, cache)
        cache.sTool = tool or default_tool
        cache.sLevel = get_tool_level(tool)
        cache.sTab = 1 -- default to first tab
        FS_tool_types_to_cache(cache)
        cache.craft_itemsFS = nil
        cache_reset_recipes(cache)
        cache.output=""
    end
end

-- remove tool
-- cache parameter is optional
local function cache_tool_remove(player, cache)
    local cache =  cache or inventoryFS_cache[player:get_player_name()]
    -- if no cache, then generate it
    if not cache then
        cache = initiate_cache(player)
    end
    cache.tool_list = generate_tools_list()
    -- unselect tool to default
    cache_tool_change(player, nil, cache)
end

local function cache_tool_add(player, a_tool, cache)
    if not a_tool then
        return
    end
    local cache =  cache or inventoryFS_cache[player:get_player_name()]
    -- if no cache, then generate it
    if not cache then
        cache = initiate_cache(player)
    end
    -- for now, we can only have one tool at the time, so I just reset to hand
    -- later we could remove r_tool
    cache.tool_list = generate_tools_list(a_tool)
    -- unselect tool to default
    cache_tool_change(player, a_tool, cache)
end

-- change Search field and reset formspec accordingly
-- return true is any change, to trigger formspec redraw
local function set_search_to(cache, s)
    local transformed = minimal.make_search_string(s)
    -- if I changed the text in the search field, reset recipes
    if cache.sSearch ~= transformed then
        cache.sSearch = s
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
    -- update recipe list to have refresh button
    FS_recipes_to_cache(cache,player_name,pInv, false)
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
        -- added to reset quantity to "single" when we close the inventory
        --  and avoid accidentaly max
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
    -- process craft tabs.
    if fields.sCraftTab then
        cache.sTab = tonumber(fields.sCraftTab)
        cache_reset_recipes(cache)
        cache.output = ""
        -- crafting.sort_order_by_player[player_name] = nil
        done = true
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
    -- process get recipes button
    if fields.refresh_r then
        cache.sScroll= 0 -- reset scrolling bar on top
        FS_recipes_to_cache(cache, player_name, inv, true)
        cache.output = ""
        done = true
    end
    -- process new craft tabs
    for i = 1, #(get_craft_tabs(cache.sTool)), 1 do
        if fields['sCraftTab_'..i] then
            if cache.sTab ~=i then
                cache.sTab = i
                cache_reset_recipes(cache)
                cache.output = ""
            end
            done = true
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
        if cache.qty ~= 1 and fields.qty1 then
            cache.qty = 1
        elseif cache.qty ~= 2 and fields.qty2 then
            cache.qty = 2
        elseif cache.qty ~= 3 and fields.qty3 then
            cache.qty = 3

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

                process_qty(recipe,qty, item_hash)
                if not crafting.can_craft(player_name, ctype,
                                          sLevel, recipe) then
                    minetest.log("error", "[inventoryFS] Player clicked a "..
                                 "button they shouldn't have been able to")
                    return true
                -- try to craft, checking first "input_items" list
                elseif crafting.perform_craft(
                    player_name, inv, {"input_items",'main'}, 'main', recipe) then
                    cache.recipesFS = nil
                    cache.output = ""
                    inventoryFS_cache[player_name] = cache
                    return true -- crafted
                else
                    -- #TODO: see why this is duplicated in crafting/gui.lua
                    --  since that doesn't seem to be used
                    minimal.warn_message(player_name,
                                         S("Missing required items!"))
                    --minetest.chat_send_player(
                    --    player_name, S("Missing required items!"))
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

-- Register crafting formspec as inv tab
do
    if minetest.global_exists("sfinv") then
        local homepage = sfinv.get_homepage_name() -- get name of homepage
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
                    local player_name = player:get_player_name()
                    print ("--------------------------]ENTER[-------------------")
                    --set_cache(player:get_player_name(),player:get_inventory())
                end,
                on_leave = function(self, player, context)
                    local player_name = player:get_player_name()
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
end

local function make_tool_formspec(player)
    return tofstring({
            "formspec_version[5]",
    		--"size[11.2,10.5]" ..
    		"size[11.2,10]",
    		"position[0.5,0.5]",
            make_inventory_formspec(player)
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
function minimal.crafting_item_on_rightclick(pos,node,clicker,
                                             itemstack,pointed_thing)
    local craft_item = node.name
    if not minetest.is_player(clicker) then
        return
    end
    local player_name = clicker:get_player_name()

    local cache = inventoryFS_cache[player_name] or initiate_cache(clicker)

    cache_tool_add(clicker, craft_item, cache)

    local formspec = make_tool_formspec(clicker)
    minetest.show_formspec(player_name,'exile:crafting',formspec)
    return itemstack
end
