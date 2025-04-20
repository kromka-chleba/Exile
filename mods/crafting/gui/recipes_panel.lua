local crafting = crafting
local S = core.get_translator("crafting")
local tofstring = function(t) return table.concat(t,"") end

-- FUNCTIONS -------------------------------------------------------------------

--[[ take a recipe list with crafting.get_all return format and sort it in 2 lists :
    returns craftable and uncraftable table of results
    format of each table is the one documented for crafting.get_all
    #TODO could be solved using single/max etc buttons
]]
local function sort_craftable_recipes(cache)
    local c_recipes = cache.c_recipes
    local p_recipes = cache.p_recipes
    local u_recipes = cache.u_recipes

    -- if I already had a craftable list, don't change the order to avoid missclick
    -- #TODO could probably be improved, or solved with craft buttons
    if c_recipes then
        -- updates ingredients state and infotext in second list
        -- and move new craftable recipes to end of first one
        local new_p={}
        local new_u={}
        for _, r_list in ipairs({p_recipes,u_recipes}) do
            for i, result in ipairs(r_list) do
                -- if it became craftable, add to previous list and hide in this one
                if result.craftable then
                    c_recipes[#c_recipes + 1] = result
                elseif cache.possible_hint and result.possible then
                    new_p[#new_p + 1] = result
                else -- else keep it in uncraftable list
                    new_u[#new_u + 1] = result
                end
            end
        end
        cache.p_recipes = new_p
        cache.u_recipes = new_u
    else
        local new_c = {}
        local new_p = {}
        local new_u = {}
        for _, result in ipairs (cache.recipes) do
            -- add recipe to list only if it matchs search
            if result.craftable then
                new_c[#new_c + 1] = result
            elseif cache.possible_hint and result.possible then
                new_p[#new_p + 1] = result
            else
                new_u[#new_u + 1] = result
            end
        end
        cache.c_recipes = new_c
        cache.p_recipes = new_p
        cache.u_recipes = new_u
    end
end

-- update possible state if `possible` = true, else updates craftable state
local function update_list_input_state(r_table, item_hash, possible)
    -- #TODO go back to unchecked list in that case ?
    if not item_hash then
        core.log("in 'crafting.recipe_list_update' : item_hash is missing") -- #TODO better check
        return
    end
    if not r_table or type(r_table) ~= "table" then
        core.log("recipe list to update is missing or wrong format in crafting.list_update_craftable_state")
        return
    end
    for _, r in pairs(r_table) do
        if possible then
            r:update_possible_state(item_hash)
        else
            r:update_craftable_state(item_hash)
        end
    end
end


-- #TODO change what is stored à recipe to store for all tabs and not recheck cratable state on each tab change...
-- store by ctype
-- build recipes list to display in crafting tab
-- is search is not nil, it returns only the ones matching the search criteria
-- return sorted lists if sorted = true, unique list else
-- also return the size as 2nd return


--[[ get all recipes to display in recipe panel, without craftable state
return a table with following format :
t[i] = {
*`recipe`    - recipe def table
*`displayed` - true if recipe should be displayed in GUI
]]
-- currently only used if cache.update is tru any way
local function get_recipes_list(cache, pInv)
        local player_name =  cache.player_name
        if not cache.sTab or not cache.cTabs then
            core.log("not engough craft tabs info is given to get recipes")
            return nil
        end

        local ctype = cache.cTabs[cache.sTab]
        if not ctype then
            core.log("cTabs[sTab] is nil in cache, shouldn't happen")
        end

        -- if I don't have the recipes list yet, get it and set the cache
        if not cache.recipes then
            cache.recipes = crafting.get_player_recipes(player_name, ctype)
            -- if  level or itemash is given, update current state
            if not cache.recipes then
                core.log ("in crafting.get_recipes_table : we have no recipes with type " .. tostring(ctype))
                return {{}} -- #TODO check what it does
            end
        end

        local t -- will be return as result

        --[[ if we have to dislay/cechk the list the lists,
            *check craftable and
            * check possible state if option is on
            * apply display filters]]
        -- #TODO could be an ther setting than "updated"
        if cache.updated then
            -- update craftable state
            -- #TODO change the way that itemhash is generated
            cache.item_hash = cache:get_input_hash(pInv)
            update_list_input_state(cache.recipes, cache.item_hash, false)

            -- get what is possible using both input + inventory
            -- #TODO this is only to used with option one, improve that part
            if cache.possible_hint then
                -- update possible state
                local i_s = crafting.get_item_hash(pInv, {"main"})
                update_list_input_state(cache.recipes, i_s, true)
            end

        -- if we want to sort order per craftability and possible
        if cache.sorted == true then
            sort_craftable_recipes(cache)
            t = {cache.c_recipes, cache.p_recipes, cache.u_recipes}
        end
    else
        t = {cache.recipes}
    end
    -- apply search filters if needed
    cache:apply_filters()

    return t
end

-- FORMSPEC generations --------------------------------------------------------
local esc = core.formspec_escape
local color_esc = core.get_color_escape_sequence

-- `player_name` and `pInv` are optional and would be rebuild from player
-- used only in get_recipes_list
-- #TODO check if I can change that call
crafting.register_cache_function("get_recipes_panel",
    function(self, pInv)

    local function item_tool_tip(item, j)
        local s = {} -- future tooltip for that item
        local h
        -- adds colors if needed
        if item.have then
            local color = item.have >= item.need and "#6f6" or "#f66"
            s[#s +1] = color_esc(color)
            h = item.have
        else -- replace "have" number by "?" if we don't know
            h = "?"
        end
        -- adds "or" if not the first of the line
        if j ~= 1 then
            s[#s +1] = S("or") .. " "
        end

        s[#s +1] = item.short .. ": "
                            ..  h .."/".. item.need .." "
                            .. color_esc("#ffffff")
        return tofstring(s)
    end

    local function tool_tool_tip(tool)
        local s = {} -- future tooltip for that item
        -- adds colors if needed
        if tool.have then
            local color = tool.have >= tool.need and "#6f6" or "#f66"
            s[#s +1] = color_esc(color)
        end

        s[#s +1] = tool.short
        s[#s +1] = color_esc("#ffffff")
        return tofstring(s)
    end

    -- generates tooltip of each recipe
    local function generate_tool_tip(result)
        local item_desc = ItemStack(result.recipe.output):get_description()
        -- add recipe's tooltip part 1 : output's description
        local t = {esc(item_desc .. "\n")}
        -- add recipe's tool info if needed
        if result.tool then
            t[#t+1] = "\n" .. S("Tool (")
                    .. S("will not be consumed") .."): "
                    .. tool_tool_tip(result.tool)

        end
        -- add recipe's tooltip part 2 : inputs
        for _, row in ipairs(result.it_details) do
            local tool_tip ="\n"
            for j, item in ipairs(row) do
                tool_tip = tool_tip .. item_tool_tip(item, j)
            end
            t[#t+1] = esc(tool_tip)
        end
        -- return result as string
        return tofstring(t)
    end

    --[[ display individual recipe slot
        Returns associated formspec string
    ]]
    local function FS_display_recipe(result, x, y)
        local form_table={}
        -- place recipe
        local id = result.recipe.id
        local bg_coords =  tostring(x) ..','.. tostring(y + 0.2)

        -- set background image
        local bg_image
        local craftable = result.craftable
        if craftable then
            bg_image = 'crafting_slot_craftable.png'
        elseif result.possible and self.possible_hint then
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
                esc(result.recipe._display),
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
                result.recipe.output,
                ';sResult_',
                id,
                ';]'
            })
        end

        form_table[#form_table + 1] = tofstring({
            'tooltip[sResult_',
            id,
            ';',
            generate_tool_tip(result),
            ']'
            })
        return  tofstring(form_table)
    end

    local FS_recipes = {}         -- final fromspec
    -- this is for more clarity, choice of display settings
    --[[size of a square of recipe : 1*1 of image + 0.1 margins around,
    used to place them on a grid, including tabs]]
    local line_number = 3 -- nb of lines of recipes displayed
    local grid_size = 1.2

    -- Add recipes list -------------------------------------------------

    --[[ get recipes lists to display
        * `rawlist` is a list of lists to display
        like {l1, l2, l3} to display in that order
        * for each, recipes, `displayed` = true only if the recipes matching the filters parameter]]
    local raw_list = get_recipes_list (self, pInv)
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
    local sScroll = self.sScroll or 0 -- default to 1 for top of scroll
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
end)


-- PROCESS -----------------------------------------------------------
-- reset recipes in cache (list and formspec)
crafting.register_cache_function("reset_recipes",
    function(self)
    -- will force to resort recipes
    -- resets recipes lists
    self.c_recipes = nil -- list of craftable recipes to display
    self.p_recipes = nil -- list of possible recipes to display
    self.u_recipes = nil -- list of uncraftable recipes to display
    self.recipes = nil
    -- erases recipes panel formspec part
    self.FS_recipes = nil
    -- reset scroll bar to top
    self.sScroll = 0 -- reset scrollbar to top
end)

-- Find maximum number of outputs we can craft from our inventory
local function find_max_craftable(recipe, item_hash)
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

    -- TODO check to do better later
    -- needed for sleeping spot where `items` is empty
    if max_count == 0 then
        max_count = 1
    end

    return max_count
end

-- Find multiplier of input needed to craft one max_stack of output items
-- #TODO update for multi output future recipes
local function calculate_stack_input(item)
    local output_name = item:get_name()
    local per_input = item:get_count()
    local stack_size = core.registered_items[output_name].stack_max
    return stack_size / per_input
end

local function get_craft_count(cache, r, item_hash)
    local qty = cache.qty
    if not qty then
        core.log("warning", "cache.qty is not given in 'get_craft_count' function, 1 is used by default")
        return 1
    -- only one requested? Max not allowed ? return 1
        elseif qty == 1 or r.recipe.no_max then
        return 1
    end
    -- more then single requested? find max
    item_hash = item_hash or cache.item_hash -- TODO to improve with player inv ?
    if not item_hash then
        core.log("warning", "cache.item_hash is not given in 'get_craft_count' function, 1 is used by default")
        return 1
    end

    local recipe = r.recipe
    local max_count = find_max_craftable(recipe, item_hash)

    if qty == 2 then -- stack requested so adjust max to max for stack.
        local stack_count = calculate_stack_input(ItemStack(recipe.output))
        if max_count > stack_count then
            max_count = stack_count
        end
    end
    return max_count
end

crafting.register_cache_function("get_craft_count", get_craft_count)

--#TODO check how it is done and using itemhash and if it can be improved.
-- Quantity sets single, stack or maximum -- this finds how many we can craft
-- returns nothing but update recipe.items
local function process_count(r, count, item_hash)
    -- TODO check if I change the parameter to "count"
    if count == 1 then
        return
    end
    -- set count to know how many output(s) to give
    r.count = count

    local pItems = {} -- picked items list
    -- set input items to values for max_count
    for i, row in ipairs(r.it_details) do
        local row_maxCount = count
        -- use max_count for each row's max
        for j,it in ipairs(row) do
            local iHave = item_hash[it.name] or 0
            local ioCount = math.floor(iHave / it.need)
            if ioCount > 0 then
                if ioCount > row_maxCount then
                    ioCount = row_maxCount
                    -- no more then max_count should be picked.
                end
                local taking = it.name .." "..ioCount * it.need
                pItems[#pItems+1] = taking
                row_maxCount = row_maxCount - ioCount
                if row_maxCount == 0 then
                    break
                end
            end
        end
    end
    r.to_take = pItems
end

-- TODO improve checking craft state
-- is more "pressing a button" thing I guess.
local function push_recipe(cache, btn_id, player, player_name, inv)
    if type(btn_id) ~= "number" then
        core.log ("btn_id is not a number in cache:craft_recipe")
    end
    -- get the recipe we clicked on ---------
    -- get current craftable recipes table, or if not sorted, full recipes
    local t = cache.c_recipes or cache.recipes
    local p_recipe
    for _, r in pairs(t) do
        if r.recipe.id == btn_id then
            p_recipe = r
            break
        end
    end

    -- not craftable
    if not p_recipe then
        if cache.p_recipes then
            -- check possible recipe, to laucnh other action
            for _, r in pairs(cache.p_recipes) do
                if r.recipe.id == btn_id then
                    p_recipe = r
                    break
                end
            end
            if p_recipe then
                -- do things with possible recipe
                return
            end
        -- else should be in uncraftable recipe
        -- #TODO double check that
        end
        minimal.warn_message(player, player_name,
                                 S("Missing required items!"))
        return
    end

    local ctype = cache.cTabs[cache.sTab]
    local sLevel = cache.sLevel
    --#TODO I need to improve the way cache.item_hash is assigned/modified
    local item_hash = cache.item_hash or cache:get_input_hash(inv)
    local max_count = get_craft_count(cache, p_recipe, item_hash)
    -- TODO store max_count in cache ?
    process_count(p_recipe, max_count, item_hash)
    if not crafting.can_craft(player_name, ctype,
                              sLevel, p_recipe.recipe) then
        minetest.log("error", "[inventoryFS] Player clicked a "..
                     "button they shouldn't have been able to")
        return true
    -- try to craft
    -- cache:get_craft_input() is the input list
    -- 'main' is the output list
    elseif crafting.perform_craft(
        player_name, inv, cache:get_craft_input(), 'main', p_recipe, ctype, max_count) then
        cache.FS_recipes = nil
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

crafting.register_cache_function("push_recipe", push_recipe)

-- -- function called when pushing a recipe button
-- function crafting.craft_recipe(btn_id, cache, player, player_name, inv)
--     local recipe = table.copy(crafting.get_recipe(tonumber(btn_id)))
--     local ctype = cache.cTabs[cache.sTab]
--     local sLevel = cache.sLevel
--     local qty = cache.qty or 1
--     --#TODO I need to improve the way cache.item_hash is assigned/modified
--     local item_hash = cache.item_hash or cache:get_input_hash(inv)
--     local max_count = get_craft_count(recipe, qty, item_hash)
--     -- TODO store max_count in cache ?
--     process_count(recipe, max_count, item_hash)
--     if not crafting.can_craft(player_name, ctype,
--                               sLevel, recipe) then
--         minetest.log("error", "[inventoryFS] Player clicked a "..
--                      "button they shouldn't have been able to")
--         return true
--     -- try to craft
--     -- cache:get_craft_input() is the input list
--     -- 'main' is the output list
--     elseif crafting.perform_craft(
--         player_name, inv, cache:get_craft_input(), 'main', recipe, ctype) then
--         cache.FS_recipes = nil
--         return true -- crafted
--     else
--         -- #TODO: see why this is duplicated in crafting/gui.lua
--         --  since that doesn't seem to be used
--         minimal.warn_message(player, player_name,
--                              S("Missing required items!"))
--         --minetest.chat_send_player(
--         --    player_name, ("Missing required items!"))
--         return true -- failed but we handled it
--     end
-- end
