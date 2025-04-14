local crafting = crafting
local S = core.get_translator("crafting")
local tofstring = function(t) return table.concat(t,"") end

-- FUNCTIONS -------------------------------------------------------------------

local function get_possible_hash(pInv,cache)
    return crafting.get_item_hash(pInv, {"main", "input_items"})
end

--[[ take current craftable and uncraftable list and
    recheck if each one is craftable or not
    update those lists in cache, without changing the order (keeping ex-craftable one first)
    #TODO could be solved using single/max etc buttons
    #TODO : warning, only check inputs, do not check new unlocked recipes or change of level
]]
local function update_recipes_lists(player_name, pInv, cache, item_hash)
    local c_recipes = cache.c_recipes
    local p_recipes = cache.p_recipes
    local u_recipes = cache.u_recipes
    -- updates ingredients state and infotext in first list
    for i, result in ipairs(c_recipes) do
        result:update_input_state(item_hash, true)
        if cache.possible_hint then
            -- get what is possible using both input + inventory
            -- #TODO this is only to sued with option one, improve that part
            local i_s = get_possible_hash(pInv,cache)
            -- #TODO issue it modified result
            result.possible = result:update_input_state(i_s, false)
        else
            result.possible = nil
        end
    end

    -- updates ingredients state and infotext in second list
    -- and move new craftable recipes to end of first one
    local new_p={}
    local new_u={}
    for _, r_list in ipairs({p_recipes,u_recipes}) do
        for i, result in ipairs(r_list) do
            result:update_input_state(item_hash)
            -- if it became craftable, add to previous list and hide in this one
            if result.craftable then
                c_recipes[#c_recipes + 1] = result
            elseif result.possible then
                new_p[#new_p + 1] = result
            else -- else keep it in uncraftable list
                new_u[#new_u + 1] = result
            end
        end
    end
    cache.p_recipes = new_p
    cache.u_recipes = new_u
end

--[[ take a recipe list with crafting.get_all return format and sort it in 2 lists :
    returns craftable and uncraftable table of results
    format of each table is the one documented for crafting.get_all
]]
local function sort_craftable_recipes(t)
    local craftable_t = {}
    local possible_t = {}
    local uncraftable_t = {}

    for _, result in ipairs (t) do
        -- add recipe to list only if it matchs search
        if result.craftable then
            craftable_t[#craftable_t + 1] = result
        elseif result.possible then
            possible_t[#possible_t + 1] = result
        else
            uncraftable_t[#uncraftable_t + 1] = result
        end
    end
    return craftable_t,possible_t, uncraftable_t
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

        if cache.updated then
            -- check craftable state
            -- #TODO change the way that itemhash is generated
            cache.item_hash = cache:get_input_hash(pInv)
            crafting.recipe_list_update(cache.recipes, cache.item_hash, true)
        end

        -- apply search filters if needed
        cache:apply_filters(cache.recipes)

        -- get what is possible using both input + inventory
        -- #TODO this is only to used with option one, improve that part
        if cache.possible_hint then
            for _,result in ipairs(cache.recipes) do
                -- check possible from inv
                local i_s = crafting.get_item_hash(pInv, {"main"})
                result.possible = result:update_input_state (i_s, false)
            end
        end

        -- if we don't want to sort the recipes
        if not cache.sorted then
            return {cache.recipes} -- return unsorted list

        -- else sort cache.recipes in craftable, uncraftable and possible lists
        elseif cache.sorted == true then
            local c_recipes = cache.c_recipes
            local u_recipes = cache.u_recipes

            -- #TODO improve with possible recipes
            if not (c_recipes and u_recipes) then
                c_recipes, cache.p_recipes, u_recipes =
                    sort_craftable_recipes(cache.recipes)
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

-- FORMSPEC generations --------------------------------------------------------
local esc = core.formspec_escape
local color_esc = core.get_color_escape_sequence

-- `player_name` and `pInv` are optional and would be rebuild from player
-- used only in get_recipes_list
-- #TODO check if I can change that call
crafting.register_cache_function("get_recipes_panel",
    function(self, pInv)

    -- generates tooltip of each recipe
    local function generate_tool_tip(result)
        local item_desc = ItemStack(result.recipe.output):get_description()
        -- add recipe's tooltip part 1 : output's description
        local t = {esc(item_desc .. "\n")}
        -- add recipe's tooltip part 2 : inputs
        for _, row in ipairs(result.it_details) do
            local tool_tip ="\n"
            for j, item in ipairs(row) do
                local h
                -- adds colors if needed
                if item.have then
                    local color = item.have >= item.need and "#6f6" or "#f66"
                    tool_tip = tool_tip .. color_esc(color)
                    h = item.have
                else -- replace "have" number by "?" if we don't know
                    h = "?"
                end
                -- adds "or" if not the first of the line
                if j ~= 1 then
                    tool_tip = tool_tip .. S("or") .. " "
                end

                tool_tip = tool_tip ..  item.short .. ": "
                                    ..  h .."/".. item.need .." "
                                    .. color_esc("#ffffff")
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

    -- add Scrollable container for recipes --------------------------
    -- get recipe list to display
    -- this list indicates if the recipe is craftable or not
    -- displayed = true only if the recipes matching the search parameter
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
function crafting.craft_recipe(btn_id, cache, player, player_name, inv)
    local recipe = table.copy(crafting.get_recipe(tonumber(btn_id)))
    local ctype = cache.cTabs[cache.sTab]
    local sLevel = cache.sLevel
    local qty = cache.qty or 1
    --#TODO I need to improve the way cache.item_hash is assigned/modified
    local item_hash = cache.item_hash or cache:get_input_hash(inv)

    process_qty(recipe, qty, item_hash)
    if not crafting.can_craft(player_name, ctype,
                              sLevel, recipe) then
        minetest.log("error", "[inventoryFS] Player clicked a "..
                     "button they shouldn't have been able to")
        return true
    -- try to craft
    -- cache:get_craft_input() is the input list
    -- 'main' is the output list
    elseif crafting.perform_craft(
        player_name, inv, cache:get_craft_input(), 'main', recipe, ctype) then
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
