-- #TODO -----------------------------------------------------------------------

-- The following identifier and related code _may_ be obsolete since
-- replacement of checkboxes for 'single' 'stack' 'maximum' by craft buttons:
-- p_recipe.count, cache.qty, get_craft_count(), recipe.no_max,
-- process_max_label(), the corresponding code in FS_display_recipe() with
-- display_count which was to display the output count in front of all recipes.

-- GLOBALS --------------------------------------------------------------------

local crafting = crafting
local S = core.get_translator("crafting")
local tofstring = function(t) return table.concat(t,"") end

-- FUNCTIONS -------------------------------------------------------------------

-- Divide cache.recipes into 4 categories, depending on availability of inputs.
-- For input mode 'Use this' it depends also on whether hints a re-enabled and
-- whether the filter button binds sorting and highlighting to the input grid.
-- If a recipe is selected and cache.c_recipes was not reset, items in that
-- list remain at the top to not move the crafted recipe right after crafting.
local function sort_recipes_by_input_state(cache)
    local craftables = {} -- recipes with full sets of inputs in craftable list
    local possibles = {} -- all inputs available, but not all in craftable list
    local some_inputs = {} -- no full set of inputs, but some inputs available
    local no_inputs = {} -- no inputs at all

    -- if a recipe is selected and the list of craftable recipes was not reset
    -- -> keep items in that list to not move the recipe right after crafting
    local filtered = cache.input_filter
    local hints = cache.possible_hint
    if cache.selected_id and cache.c_recipes then
        craftables = cache.c_recipes -- keep craftable list
        -- resort player recipes in the following lists
        local lists = {cache.p_recipes, cache.ipa_recipes, cache.u_recipes}
        for _, list in ipairs (lists) do
            for _, result in ipairs (list) do
                -- add recipe to list unless it is filtered out by the search
                if result.craftable then
                    craftables[#craftables + 1] = result
                elseif not filtered and hints and result.possible then
                    possibles[#possibles + 1] = result
                elseif result.partial
                    or result.craftable_partial
                    or not filtered and hints and result.possible_partial then

                    some_inputs[#some_inputs + 1] = result
                else
                    no_inputs[#no_inputs + 1] = result
                end
            end
        end
    else
        for _, result in ipairs (cache.recipes) do
            -- add recipe to list unless it is filtered out by the search
            if result.craftable then
                craftables[#craftables + 1] = result
            elseif not filtered and hints and result.possible then
                if cache.hint_btn then
                    possibles[#possibles + 1] = result
                else
                    craftables[#craftables + 1] = result
                end
            elseif result.partial
                or result.craftable_partial
                or not filtered and hints and result.possible_partial then

                some_inputs[#some_inputs + 1] = result
            else
                no_inputs[#no_inputs + 1] = result
            end
        end
    end
    cache.c_recipes = craftables
    cache.p_recipes = possibles
    cache.ipa_recipes = some_inputs
    cache.u_recipes = no_inputs
end


-- update possible state if `possible` = true, else updates craftable state
local function update_list_input_state(r_table, item_hash, criteria)
    -- #TODO go back to unchecked list in that case ?
    if not item_hash then
        core.log("in 'crafting.recipe_list_update' : item_hash is missing") -- #TODO better check
        return
    end
    if not r_table or type(r_table) ~= "table" then
        core.log("recipe list to update is missing or wrong format in crafting.list_update_craftable_state")
        return
    end
    if criteria ~= "possible" then
        criteria = nil -- craftable by default
    end
    for _, r in pairs(r_table) do
        r:update_state(item_hash, criteria)
    end
end

-- Find multiplier of input needed to craft one max_stack of output items
-- #TODO update for multi output future recipes
local function calculate_stack_input(item)
    if type(item) == "string" then item = ItemStack(item) end
    local output_name = item:get_name()
    local per_input = item:get_count()
    local stack_size = core.registered_items[output_name].stack_max
    return math.floor(stack_size / per_input)
end

 -- TODO maybe improve dealing with cache.item_hash
 -- get craft count matching with cache.qty setting
local function get_craft_count(cache, r, item_hash)
    local qty = cache.qty
    local recipe = r.recipe
    if not qty then
        core.log("warning", "cache.qty is not given in 'get_craft_count' function, 1 is used by default")
        return 1
    -- only one requested? Max not allowed ? return 1
        elseif qty == 1 or recipe.no_max then
        return 1
    end
    -- more then single requested? find maxif all_possible
    -- case of nil itemhash will be made in find_max_craftable function
    -- #TODO I could reuse current state if present..
    local max_count = recipe:find_max_craftable(item_hash)

    if qty == 2 then -- stack requested so adjust max to max for stack.
        local stack_count = calculate_stack_input(recipe.output)
        if max_count > stack_count then
            max_count = stack_count
        end
    end
    return max_count
end

-- TODO pass as player_recipe function, so it can update on various change, like change of input, list, etc
 -- updates r.count on player_recipe
local function process_max_label (cache, r_lists)
    if not r_lists then
        r_lists = {cache.recipes}
    end
    if type(r_lists) ~= "table" then
        core.log ("in process_max_label in crafting, r_lists is not a table")
        return
    end
    for _, r_list in pairs(r_lists) do
        for _, r in pairs(r_list) do
            if r.craftable then
                if not cache.item_hash then -- shoudln't happen
                    -- unless I forgot to reset recipes states somewhere
                    core.log("warning", "cache.item_hash is nil in process_max_label. "
                    .."It shouldn't happen since recipe has a state")
                    cache.item_hash = cache:get_input_hash()
                end
                r.count = get_craft_count(cache, r, cache.item_hash)
            elseif r.possible then
                if not cache.possible_hash then -- shoudln't happen
                    -- unless I forgot to reset recipes states somewhere
                    core.log("warning", "cache.possible_hash is nil in process_max_label. "
                    .."It shouldn't happen since recipe has a state")
                    cache.possible_hash = cache:get_input_hash("total")
                end
                r.count = get_craft_count(cache, r, cache.possible_hash)
            else
                r.count = nil
            end
        end
    end
    -- TODO better way to refresh recipes panel ?
    cache.FS_recipes = nil
    return true -- need to redo formspec ?
end

crafting.register_cache_function("process_max_label", process_max_label)

--gets unlockeds recipes for that craft tab for that player
local function get_craft_tab_player_recipes(cache)
    local player_name =  cache.player_name
    if not cache.sTab or not cache.cTabs then
        core.log("not enough craft tabs info is given to get recipes")
        return nil
    end
    local ctype = cache.cTabs[cache.sTab]
    if not ctype then
        core.log("cTabs[sTab] is nil in cache, shouldn't happen")
    end
    return crafting.get_player_recipes(player_name, ctype, cache.sLevel)
end

-- reset all recipes item states with criteria, like [criteria .. "_have"]
local function reset_recipes_states(cache, criteria)
    criteria = criteria or {"craftable", "possible"}
    for _ , pr in pairs(cache.recipes) do
        -- don't reset if already nil (#TODO check if safe enough)
        if pr.craftable ~= nil then
            pr:reset_state(criteria) -- todo separate craftble and possible state
        end
    end
end

-- updates one recipe state
-- #TODO recipe.count could be updated in update_state I guesss
local function update_recipe_state(cache, p_recipe, criteria)
    if criteria ~= "possible" then -- craftable by default
        if not cache.item_hash then
            cache.item_hash = cache:get_input_hash()
        end
        -- updates craftable state
        p_recipe:update_state(cache.item_hash)
        -- update count label
        p_recipe.count = get_craft_count(cache, p_recipe, cache.item_hash)
    else -- "possible"
        if not cache.possible_hash then
            cache.possible_hash = cache:get_input_hash("total")
        end
        p_recipe:update_state(cache.possible_hash, "possible")
        -- update count label
        p_recipe.count = get_craft_count(cache, p_recipe, cache.possible_hash)
    end

end

--[[ updates recipes states.
    * renew item_hash if nil
]]
local function update_recipes_states(cache)
    if not cache.item_hash then
        cache.item_hash = cache:get_input_hash()
    end
    -- updates craftable state
    update_list_input_state(cache.recipes, cache.item_hash)
    if cache.possible_hint then -- update possible state
        if not cache.possible_hash then
            cache.possible_hash = cache:get_input_hash("total")
        end
        update_list_input_state(cache.recipes, cache.possible_hash, "possible")
    else -- reset possible state
        reset_recipes_states(cache, "possible")
    end
    -- update count label
    process_max_label (cache)
end

crafting.register_cache_function("update_recipes_states", update_recipes_states)

--[[ get all recipes to display in recipe panel,
    returns a list of lists
    containing a unique list if unsorter
    or 3 craftable/possible/uncraftabl lists if sorted
]]
--[[ #TODO apply_filter and update_recipe_states could maybe be applied on all player recipe (from recipes.lua)
on particular changes instead of being remade on each get]]
local function get_recipes_lists(cache)
    --[[if I don't have the recipes list yet, get it and set the cache
    this gets the total recipe list for that tab, unlocked for that player]]
    -- WARNING: it may have previous tested states if not resetted
    if not cache.recipes then
        cache.recipes = get_craft_tab_player_recipes(cache)
        if not cache.recipes then
            core.log ("in crafting.get_recipes_table : I couldn't get any recipes list,\nreturning {{}}")
            return {{}} -- #TODO check what it does
        end
    end

    local result
    if cache.sorted then -- currenlty hardcoded as true
        -- update craftable state
        update_recipes_states(cache)
        -- if we want to order the recipes (currently unused setting)
        -- always "true"
        if cache.order == true then
            -- if we want re_sort order per craftability and possible
            if cache.to_sort == true then
                sort_recipes_by_input_state(cache)
            end
            result = {cache.c_recipes, cache.p_recipes,
                      cache.ipa_recipes, cache.u_recipes}
        else
            result = {cache.recipes}
        end
    else
        --#TODO maybe we don't want to do the reset each time we display them
        -- that reset should be made elsewhere, when we trigger the "unsort" button, which currently doesn't exist.
        reset_recipes_states(cache)
        result = {cache.recipes}
    end

    -- reset search filter (displayed state in recipe)
    -- NOTE: needs to be after state update now that we use the state to filter per input
    cache:apply_filters()

    return result
end


-- Returns items from "input_items" back to "main" inventory list.
-- Try to add to main inventory
-- priorities: 1. fill up existing stacks
--             2. fill empty stacks from right to left
local function return_inputs_to_main(player)
    local pInv = player:get_inventory()
    if pInv:is_empty("input_items") then return end

    -- initial state
    local main_hash = crafting.get_item_hash(pInv, "main")
    local main_stacks = pInv:get_list("main")
    -- next slot in main to check whether it is free
    local try_next = pInv:get_size("main")

    -- Returns a list of stacks in main_stacks with item name matching
    -- search_name.
    local function get_matching_slots(search_name)
        if not main_stacks then return 0 end

        local slot_matches = {}
        for i, stack in ipairs(main_stacks) do
            if stack:get_name() == search_name then
                slot_matches[#slot_matches + 1] = i
            end
        end
        return slot_matches
    end

    -- Adds as much as possible from the given stack to an existing ones
    -- in "main" and returns the remaing part.
    local function add_to_existing_stacks(stack)
        local item_name = stack:get_name()
        if main_hash[item_name] then
            -- multiple stacks of that item may exist in main (usually not)
            local slots = get_matching_slots(item_name)
            for _, idx in ipairs(slots) do
                -- combine stacks if possible
                stack = main_stacks[idx]:add_item(stack)
                if stack:get_count() == 0 then
                    break
                end
            end
        end
        return stack
    end

    local function move_to_last_free_slot(stack)
        while try_next > 0 do
            if main_stacks[try_next]:is_empty() then
                main_stacks[try_next] = stack
                stack = ItemStack()
                break
            end
            try_next = try_next - 1
        end
        return stack
    end

    -- iterate over "input_items", to move items back to "main"
    for i = 1, pInv:get_size("input_items") do
        local stack = pInv:get_stack("input_items", i)
        if not stack:is_empty() then
        -- if stack:get_free_space() > 0 and not stack:get_meta() then
            if stack:get_free_space() > 0 then
                stack = add_to_existing_stacks(stack)
            end
            -- are some left?
            if not stack:is_empty() then
                -- move remaining stack to last free slot
                stack = move_to_last_free_slot(stack)
            end

            -- not enough room in "main"?
            if not stack:is_empty() then
                -- drop item
                core.item_drop(stack, player, player:get_pos())
                -- warns the player it went on the ground
                EXILE.warn_inv_full(player)
            end
            -- Set stack to empty stack in input_items inventory
            pInv:set_stack("input_items",i,ItemStack(""))
        end
    end

    -- update "main"
    pInv:set_list("main", main_stacks)
end

-- FORMSPEC generation ---------------------------------------------------------
--------------------------------------------------------------------------------
do
    local esc = core.formspec_escape
    local color_esc = core.get_color_escape_sequence

    -- generates item tool_tip to be displayed in recipe panel
    local function item_tool_tip(pr_it)
        local item = pr_it.def
        local have = pr_it.craftable_have
        if item.get_tooltip then
            return item:get_tooltip(have)
        end
        -- else use default tooltip
        local s = {} -- future tooltip for that item
        local h
        -- adds colors if needed
        local need = pr_it.get_needed()
        if have then
            local color = "#f66" -- default color if none available
            if have >= need then -- enough to craft
                color = "#6f6"
            elseif have > 0 then -- some available, but not enough to craft
                color = "#fb6"
            end
            s[#s +1] = color_esc(color)
            h = have
        else -- replace "have" number by "?" if we don't know
            h = "?"
        end

        s[#s +1] = S("@1:", item.short) -- to deal with space before : in other languages
                    .. " "..  h .."/".. need .. " "
                    .. color_esc("#ffffff")
        return tofstring(s)
    end

    -- generates tool tool_tip to be displayed in recipe panel
    -- `tool` is tool as defined in recipe def
    local function tool_tool_tip(pr_tool)
        local tool = pr_tool.def
        local s = {} -- future tooltip for that item
        -- adds colors if needed
        local have = pr_tool.craftable_have
        local need = pr_tool.get_needed()
        if have then
            local color = have >= need and "#6f6" or "#f66"
            s[#s +1] = color_esc(color)
        end

        s[#s +1] = tool.short
        s[#s +1] = color_esc("#ffffff")
        return tofstring(s)
    end

    -- generates recipe tool_tip to be displayed in recipe panel
    local function generate_tool_tip(pr)
        local item_desc = pr.recipe.desc
        if not item_desc then
            item_desc = ItemStack(pr.recipe.output):get_description()
        end
        -- add recipe's tooltip part 1 : output's description
        local t = {
            esc(item_desc .. "\n")
        }
        -- add indicator of number is stack or max
        if pr.count and pr.count > 1 then
            t[#t+1] = S("Will be crafted @1 times", tostring(pr.count))
                    .. "\n"
            -- TODO put in translation
        end
        -- add recipe's tool info if needed
        if pr.pr_tool then
            t[#t+1] = "\n" .. S("Tool (")
                    .. S("will not be consumed") .."): "
                    .. tool_tool_tip(pr.pr_tool)

        end
        -- add recipe's tooltip part 2 : inputs
        for _, row in ipairs(pr.pr_items) do
            local tool_tip ="\n"
            for j, item in ipairs(row) do
                -- adds "or" if not the first of the line
                if j ~= 1 then
                    tool_tip = tool_tip .. S("or") .. " "
                end
                tool_tip = tool_tip .. item_tool_tip(item)
            end
            t[#t+1] = esc(tool_tip)
        end
        -- return result as string
        return tofstring(t)
    end

    --[[ display individual recipe slot
        Returns associated formspec string
    ]]
    local function FS_display_recipe (cache, pr, x, y)
        local form_table={}
        -- place recipe
        local id = pr.recipe.id
        local bg_coords =  tostring(x) ..','.. y

        -- set background image
        local bg_image = cache:get_craft_mode().get_r_cbg(cache, pr)
        if bg_image then
            form_table[#form_table + 1] = "image[" .. bg_coords .. ";1,1;" .. bg_image .. "]"
        end

        -- Add button image
        local btn_coords =
        tostring( x + 0.1 ) .. ','..
        tostring( y + 0.1 )
        -- TODO issue doesn't dsplay count if not item image
        -- TODO dcide if I modify count or put an overlay for max... but then, how ? label ?

        -- multiple craft overlay
        if cache.qty ~=1
                and (pr.craftable or pr.possible) then
            if not pr.count then -- TODO shouldn't happen
                core.log("no pr.count for ".. pr.recipe.output .. ", shouldn't happen")
                pr.count = get_craft_count(cache,pr, cache.item_hash)
            end
        end
        -- copy of output to be displayed
        local display_o = ItemStack(pr.recipe.output)
        local o_count = display_o:get_count()
        local display_count = o_count -- final output count
        if pr.count and pr.count ~= 0 then -- leave 0 if non craftable
            display_count = o_count * pr.count
        end

        if pr.recipe._display then
            -- get fake "inventory image" and display it
            form_table[#form_table + 1] = tofstring({
                "style_type[image_button;border=false;bgimg_middle=]",
                'image_button[',
                btn_coords,
                ';.8,.8;',
                esc(pr.recipe._display),
                ';sResult_',
                id,
                ';]'
            })
            -- add a label with the output number
            if display_count > 1 then -- don't display if 0
                local label_coords = tostring( x + 0.2 ) .. ','
                                .. tostring( y + 0.75 )
                form_table[#form_table + 1] = "label["
                                        .. label_coords ..";"
                                        .. tostring(display_count) .. "]"
            end
        else
            if display_count ~= o_count then
                display_o:set_count(display_count)
            end
            form_table[#form_table + 1] = tofstring({
                "style_type[item_image_button;border=false;bgimg_middle=]",
                'item_image_button[',
                btn_coords,
                ';.8,.8;',
                display_o:to_string(),
                ';sResult_',
                id,
                ';]'
            })
        end

        form_table[#form_table + 1] = tofstring({
            'tooltip[sResult_',
            id,
            ';',
            generate_tool_tip(pr),
            ']'
            })
        return  tofstring(form_table)
    end

    -- generates recipe_panel formspec at an offset defined by `x` and `y`
    -- for input mode `mode`
    crafting.register_cache_function("get_recipes_panel", function(self, x, y,
                                                                   mode)

        local FS_recipes = {}         -- final fromspec
        -- this is for more clarity, choice of display settings
        --[[size of a square of recipe : 1*1 of image + 0.1 margins around,
        used to place them on a grid, including tabs]]
        local grid_size = 1.2 -- size of a tile of the grid

        -- Add recipes list -------------------------------------------------

        --[[ get recipes lists to display
            * `rawlist` is a list of lists to display
            like {l1, l2, l3} to display in that order
            * for each, recipes, `displayed` = true only if the recipes matching the filters parameter]]
        local raw_list = get_recipes_lists (self)
        --[[this gets the recipes to display
        (some may be hidden in case of search/filter active)]]
        local display_list={}
        -- ipairs is important to keep the c_recipes/p_recipes/ipa_recipes/u_recipes order
        for _, r_list in ipairs (raw_list) do
            --displays all recipes matchng with search field
            for i, pr in ipairs(r_list) do
                -- display if this recipe matches the filter
                if pr.displayed == true then
                    display_list[#display_list + 1] = pr
                end
            end
        end

         -- max dimensions of recipes grid
        local nb_recipes=#display_list
        -- max displayed lines and columns
        local lines_max = (mode ~= 2) and 3 or 4
        local columns = (mode ~= 2) and 6 or 5
        -- total lines for all recipes and how many are displayed actually
        local lines_total = math.ceil(nb_recipes / columns)
        local lines_actual = math.max(1, math.min(lines_max, lines_total))
        -- resulting height of the panel
        local panel_height = lines_actual * (grid_size) - 0.2

        -- add scrollbar if needed
        -- #TODO don't reset the recipe lists just because of the scrollbar
        local sScroll = self.sScroll or 0 -- default to 0 for top of scroll
        if lines_total > lines_actual then
            -- columns = columns -1 -- discard a line to make room for scrollbar
            local scroll_max = lines_total - lines_actual

            local page_height = 3 * lines_actual
            FS_recipes[#FS_recipes + 1] = tofstring(
                {
                    "scrollbaroptions[",
                    "max=" .. tonumber(3 * scroll_max) .. ";", -- max
                    -- move with arrow buttons/mouse wheel
                    "smallstep=" .. 1 .. ";",  -- a single line
                    -- move with page up/down key
                    "largestep=" .. page_height .. ";",
                    "thumbsize=3]"
                })

            local scroll_bar_x = columns * grid_size - 0.1
            FS_recipes[#FS_recipes + 1] = tofstring(
                {
                    "scrollbar[" .. scroll_bar_x .. "," .. y .. ";", -- position
                    "0.5," .. panel_height .. ";", -- width/height
                    "vertical;", -- orientation
                    "recipes_scroll;", -- name
                    sScroll .. "]" -- value
                })
        end

        -- create scroll container
        FS_recipes[#FS_recipes + 1] = tofstring(
            {
                "scroll_container[" .. x .. "," .. y .. ";",
                tostring(columns + 1),',', -- Width
                panel_height, -- Height
                ';recipes_scroll;vertical;', -- scrollbar name and orientation
                grid_size/3 , --optional scrollfactor
                ']'
            })

        -- Add recipe buttons in container  ------------------------------
        local x1 = 0
        local y1 = 0

        --#TODO make a version with unique list for non ordered list as asked by Meniptah
        -- display the recipes, using defined order.
        for i, pr in ipairs (display_list) do
            FS_recipes[#FS_recipes + 1] =
                FS_display_recipe(self, pr, x1 * grid_size, y1 * grid_size)

            x1 = x1 + 1
            if x1 >= columns  then
                x1 = 0
                y1 = y1 + 1
            end
        end

        FS_recipes[#FS_recipes + 1] = 'scroll_container_end[]'

        return  tofstring(FS_recipes), panel_height
    end)

    -- For the currently selected recipe, returns a table to offer up
    -- to 3 different quantities for crafting, or nil if there is no selection
    -- or the current id does not refer to a registered recipe.
    -- The first quantity is either 0 or 1. The last quantitiy is always the
    -- maximum possible with the available inputs. If a quantitiy 1 < q < max
    -- exists, then it would be the size of a stack devided by output count of
    -- the recipe if possible, or less otherwise.
    crafting.register_cache_function("get_output_quantities", function(self)
        if not self.selected_id then return nil end

        -- get player recipe
        local recipe = crafting.get_recipe(self.selected_id)
        if not recipe then return nil end

        local qty_max = recipe:find_max_craftable(self.item_hash)

        -- max is 0 or 1 -> return only a single quantity
        if qty_max < 2 then return {qty_max} end

        -- try to find a unique 2nd quantity 1 < qty_2 < qty_max
        -- start with stack limit devided by output count of recipe,
        -- but make it at least 2
        local stack_max = calculate_stack_input(recipe.output)
        local qty_2 = stack_max > 1 and stack_max or 2
        -- assure qty_2 < qty_max
        while (qty_2 >= qty_max) and (qty_2 > 1)  do
            qty_2 = math.ceil(qty_2 / 2)
        end

        -- build return value
        local quantities =  {1}
        -- do we have 3 unique quantities to offer?
        if qty_2 > 1 then
            -- does even a 4th quantity make sense?
            if qty_2 >= 12 then
                quantities[2] = (qty_2 > 12) and math.floor(qty_2 / 6)
                                or math.floor(qty_2 / 4)
            end
            quantities[#quantities + 1] = qty_2
        end
        quantities[#quantities + 1] = qty_max

        return quantities
    end)

    -- Resets id of selected recipe
    -- If "clear_input_items" is true, also returns all items from "input_list"
    -- back to main. In that case player must be given, too.
    crafting.register_cache_function("reset_selected_recipe",
                                     function(self, clear_input_items, player)
        self.selected_id = nil
        if clear_input_items and player then
            return_inputs_to_main(player)
        end
    end)

    -- Returns the selected player recipe.
    crafting.register_cache_function("get_selected_player_recipe",
                                      function(self)
        -- find player recipe among the currently displayed
        -- (could be any in cache.recipes, currently up to ~80)
        local id = self.selected_id
        for _, r in pairs(self.recipes) do
            if r.recipe.id == id then
                return r
            end
        end
        -- or return nil
    end)

    -- Returns an array of tool tipos for craft buttons.
    -- One tip per element in "quantities" is generated.
    -- "quantities" must be an array with at least 1 element,
    -- otherwise nil is returned.
    crafting.register_cache_function("get_craft_btn_tool_tips",
                                     function(self, quantities)
        -- safety checks
        if not quantities or type(quantities) ~= "table"
            or not quantities[1] then
            return
        end

        local tool_tips = {} -- array of tooltips per each quantity
        if quantities[1] and quantities[1] > 0 then -- crafting possible
            local player_recipe = self:get_selected_player_recipe()
            if not player_recipe then return end

            local stack = ItemStack(player_recipe.recipe.output)
            local item_desc = stack:get_short_description()
            -- need to remove the color escape for use tips
            item_desc = core.strip_colors(item_desc)

            -- get output count
            local count = stack:get_count()
            -- "Craft N x 2" but "Craft N x" instead of "Craft N x 1"
            local count_text = count > 1 and " x " .. count or ""

            -- generate all tips
            for _, qty in ipairs(quantities) do
                local tip = S("@1: Craft @2@3.", item_desc, qty, count_text)
                tool_tips[#tool_tips + 1] = tip
            end
        elseif self.selected_id then -- valid selection but missing inputs
            local player_recipe = self:get_selected_player_recipe()
            if not player_recipe then return end

            local recipe_tip = generate_tool_tip(player_recipe)
            tool_tips[1] = S("Missing required items!") .. "\n" .. recipe_tip
        else -- no recipe selected
            tool_tips[1] = S("First, select an item to craft.")
        end

        return tool_tips
    end)
end

-- FORMSPEC ACTIONS ------------------------------------------------------------
local function item_hashes_reset(cache)
    cache.item_hash = nil
    cache.possible_hash = nil
end

-- reset recipes in cache (list and formspec)
-- reorder
-- keep_ih = "true" if we need to keep existings item_hashes
local function reset_recipes (cache, keep_ih)
    if not keep_ih then
        item_hashes_reset(cache)
    end
    -- will force to resort recipes
    -- resets recipes lists
    cache.c_recipes = nil -- list of craftable recipes to display
    cache.p_recipes = nil -- list of possible recipes to display
    cache.ipa_recipes = nil -- list of recipes with input partially available
    cache.u_recipes = nil -- list of uncraftable recipes to display
    cache.recipes = nil -- list of all 3 above reunited, unsorted
    -- erases recipes panel formspec part
    cache.FS_recipes = nil
    -- reset scroll bar to top
    if cache.order == true and cache.to_sort == true then
        cache.sScroll = 0 -- reset scrollbar to top
    end
    -- TODO clean because there may be a better place
    -- make sure we resort recipe order
    cache.to_sort = true
end

crafting.register_cache_function("reset_recipes", reset_recipes)


-- Select or deselect player recipe with the given id.
-- 'id' must be a valid id of a player recipe.
-- Returns true when inventory lists might have changed, while nil
-- indicates no change.
local function push_recipe(cache, id, player, player_name)
    -- not a valid recipe?
    if type(id) ~= "number" then
        core.log ("warning", "id is not a number in cache:push_recipe()")
        return -- > failure, not a recipe -> no change
    end

    -- get the selected player recipe
    -- (could be any in cache.recipes, currently up to ~80)
    local p_recipe
    for _, r in pairs(cache.recipes) do
        if r.recipe.id == id then
            p_recipe = r
            break
        end
    end

    -- invalid recipe? -> no change but log a warning
    if not p_recipe then
        core.log("warning", "craft_selected(): invalid recipe id " .. tostring(id))
        return
    end

    -- select a recipe or replace current selection?
    if id ~= cache.selected_id then
        -- new selection:
        cache.selected_id = id

        -- no crafting from main? -> update inputs in input grid(s):
        -- 1) push current input items back to "main" and
        -- 2) pull input items for max output into "input_list"
        if cache:get_craft_mode().no_craft_from_main then
            return_inputs_to_main(player)

            -- update all states for p_recipe
            cache.item_hash = cache:get_input_hash()
            update_recipe_state(cache, p_recipe)
            cache.possible_hash = cache:get_input_hash("total")
            update_recipe_state(cache, p_recipe, "possible")

            -- recipe panel will also require an update, but keep order
            cache.FS_recipes = nil -- force recipes panel redraw
            cache.to_sort = false

            -- get max output count, based on what's in "main", now
            local inv = player:get_inventory()
            local item_hash = crafting.get_item_hash(inv, "main")
            local recipe = p_recipe.recipe
            local count = recipe:find_max_craftable(item_hash)
            -- If not enough to craft, pull what's available in order to
            -- visualize what's missing - in input grid and info text.
            local allow_partial = nil
            if count < 1 then
                count = 1
                allow_partial = true
            end

            -- all inputs are currently in "main" -> take it from there
            local from_list = "main"
            local transfer = p_recipe:get_to_move(inv, from_list, count,
                                                  allow_partial)

            --[[ transfer to input lists, if not everything fits in first one,
            then we will try second one with the leftover, etc etc ...]]
            local input_lists = cache:get_craft_input()
            for _, list in ipairs(input_lists) do
                transfer = crafting.transfer_items(player, inv, list, transfer)
            end

            item_hashes_reset(cache)

            -- if not everything could be transfered, leftover list is not empty
            if transfer and #transfer ~= 0 then
                EXILE.warn_message(player, player_name,
                                     S("Not enough room to transfer everything"))
            end

            -- not enough inputs?
            if not p_recipe.possible then
                EXILE.warn_message(player, player_name,
                                     S("Missing required items!"))

                return true -- changes: we pushed things back to main
            end
        else
            -- not enough inputs to craft?
            if not p_recipe.craftable then
                EXILE.warn_message(player, player_name,
                                     S("Missing required items!"))
            end

        end
    else
        -- given id matches the one that is currently selected
        -- -> clear selection
        cache.selected_id = nil
    end

    -- update of recipe panel required to show new selection; but keep order
    cache.FS_recipes = nil -- force recipes panel redraw
    cache.to_sort = false
    return true -- changes: at least the selected recipe changed
end

crafting.register_cache_function("push_recipe", push_recipe)


-- Checks whether the currently selected recipe can be crafted in the specified
-- quantity and executes its if possible.
-- NOTE 'qty' is actually an index to choose from the table returned by
-- get_output_quantities().
-- Returns true on success, which means changes in inventory, nil otherwise.
local function craft_selected(cache, qty)
    -- no change in unexpected cases
    if not qty or not cache.selected_id then return end

    local p_recipe = cache:get_selected_player_recipe()

    -- invalid selection? -> no change but log a warning
    if not p_recipe then
        core.log("warning", "craft_selected(): invalid recipe id "
                 .. tostring(cache.selected_id))
        return
    end

    -- craftable? -> do it
    if p_recipe.craftable then
        local quantities = cache:get_output_quantities()
        local count = quantities and quantities[qty] or nil
        local ctype = cache.cTabs[cache.sTab]
        local sLevel = cache.sLevel

        if not count or not crafting.can_craft(cache.player_name, ctype,
                                               sLevel, p_recipe.recipe) then

            core.log("warning", "Recipe should be craftable but is not!")
            return
        end

        -- try to craft
        -- from input list: cache:get_craft_input()
        -- to output list: "main"
        if crafting.perform_craft(cache.player_name, cache.pInv,
                                  cache:get_craft_input(), "main",
                                  p_recipe, ctype, count) then

            -- -> item_hashes and recipe panel require an update
            item_hashes_reset(cache)
            cache.FS_recipes = nil -- force recipes panel redraw
            -- update of recipe states will be made in get_recipes_panel()
            -- when formspec will be updated
            cache.to_sort = true
            return true -- > success, changes in inventory
        end
    end

    -- failure -> return nil
end

crafting.register_cache_function("craft_selected", craft_selected)
