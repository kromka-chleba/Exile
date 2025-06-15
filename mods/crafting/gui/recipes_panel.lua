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
        local new_u={}
        -- deal with old possible list
        for i, result in ipairs(p_recipes) do
            -- move only if cache.possible_hint is disabled
            if not cache.possible_hint then
                if result.craftable then
                    c_recipes[#c_recipes + 1] = result
                else
                    new_u[#new_u + 1] = result
                end
            end
        end
        -- deal with old uncraftable list
        for i, result in ipairs(u_recipes) do
            -- if we have a possible list, add it at the end of it so that we don't move the rest
            if result.craftable then
                if cache.possible_hint and p_recipes and #p_recipes ~=0 then
                    p_recipes[#p_recipes + 1] = result
                else
                    c_recipes[#c_recipes + 1] = result
                end
            elseif cache.possible_hint and result.possible then
                p_recipes = p_recipes or {}
                p_recipes[#p_recipes + 1] = result
            else -- else keep it in uncraftable list
                new_u[#new_u + 1] = result
            end
        end
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
    return stack_size / per_input
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

    -- reset search filter (displayed state in recipe)
    cache:apply_filters()

    if cache.sorted then -- currenlty hardcoded as true
        -- update craftable state
        update_recipes_states(cache)
        -- if we want to order the recipes (currently unused setting)
        -- always "true"
        if cache.order == true then
            -- if we want re_sort order per craftability and possible
            if cache.to_sort == true then
                sort_craftable_recipes(cache)
            end
            return {cache.c_recipes, cache.p_recipes, cache.u_recipes}
        else
            return {cache.recipes}
        end
    else
        --#TODO maybe we don't want to do the reset each time we display them
        -- that reset should be made elsewhere, when we trigger the "unsort" button, which currently doesn't exist.
        reset_recipes_states(cache)
        return {cache.recipes}
    end
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
            local color = (have >= need) and "#6f6" or "#f66"
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
        local bg_coords =  tostring(x) ..','.. tostring(y + 0.2)

        -- set background image
        local bg_image = cache:get_craft_mode().get_r_cbg(cache, pr)
        if bg_image then
            form_table[#form_table + 1] = "image[" .. bg_coords .. ";1,1;" .. bg_image .. "]"
        end

        -- Add button image
        local btn_coords =
        tostring( x + 0.1 ) .. ','..
        tostring( y + 0.3 )
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
                --local label_coords = tostring( x + 0.1 ) .. ','
                --                .. tostring( y + 0.45 )
                local label_coords = tostring( x + 0.2 ) .. ','
                                .. tostring( y + 0.95 )
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

    -- `player_name` and `pInv` are optional and would be rebuild from player
    -- generates recipe_panel formspec.
    crafting.register_cache_function("get_recipes_panel", function(self)

        local FS_recipes = {}         -- final fromspec
        -- this is for more clarity, choice of display settings
        --[[size of a square of recipe : 1*1 of image + 0.1 margins around,
        used to place them on a grid, including tabs]]
        local line_number = 3 -- nb of lines of recipes displayed
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
        -- ipairs is important to keep the c_recipes/p_recipes/u_recipes order
        for _, r_list in ipairs (raw_list) do
            --displays all recipes matchng with search field
            for i, pr in ipairs(r_list) do
                -- display if this recipe matches the filter
                if pr.displayed == true then
                    display_list[#display_list + 1] = pr
                end
            end
        end
        local nb_recipes=#display_list

        local columns = 6 -- can show 6 items accross without scrollbar

        -- add scrollbar if needed
        -- #TODO don't reset the recipe lists just because of the scrollbar
        local sScroll = self.sScroll or 0 -- default to 0 for top of scroll
        if nb_recipes > columns * line_number then
            -- columns = columns -1 -- discard a line to make room for scrollbar
            local scroll_max = math.ceil(nb_recipes / columns)-line_number

            FS_recipes[#FS_recipes + 1] = tofstring(
                {
                    'scrollbaroptions[',
                    'max=' .. tonumber(scroll_max) .. ';', -- max
                    -- move with click/mouse scroll
                    'smallstep=' .. line_number .. ';',
                    -- move with page up/down key
                    'largestep=' .. line_number .. ';',
                    'thumbsize=1]'
                })

            FS_recipes[#FS_recipes + 1] = tofstring(
                {
                    'scrollbar[',
                    '7.1,0.95;', -- position
                    '0.5,' .. (1.14*line_number).. ';', -- width/height
                    'vertical;', -- orientation
                    'recipes_scroll;', -- name
                    sScroll .. ']' -- value
                })
        end

        -- create scroll container
        FS_recipes[#FS_recipes + 1] = tofstring(
            {
                'scroll_container[0,0.75;', --X,Y position
                tostring(columns + 1),',', -- Width
                (1.25 * line_number), -- Height
                ';recipes_scroll;vertical;', -- scrollbar name and orientation
                grid_size , --optional scrollfactor
                ']'
            })

        -- Add recipe buttons in container  ------------------------------
        local x = 0
        local y = 0

        --#TODO make a version with unique list for non ordered list as asked by Meniptah
        -- display the recipes, using defined order.
        for i, pr in ipairs (display_list) do
            FS_recipes[#FS_recipes + 1] =
                FS_display_recipe(self, pr, x * grid_size, y * grid_size)

            x = x + 1
            if x >= columns  then
                x = 0
                y = y + 1
            end
        end

        FS_recipes[#FS_recipes + 1] = 'scroll_container_end[]'

        return  tofstring(FS_recipes)
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


-- TODO improve checking craft state
-- is more "pressing a button" thing I guess.
local function push_recipe(cache, btn_id, player, player_name)
    if type(btn_id) ~= "number" then
        core.log ("btn_id is not a number in cache:craft_recipe")
    end
    -- get the recipe we clicked on ---------
    -- get current craftable recipes table, or if not sorted, full recipes
    -- TODO better parse
    local p_recipe
    for _, r in pairs(cache.recipes) do
        if r.recipe.id == btn_id then
            p_recipe = r
            break
        end
    end

    -- not craftable
    if not p_recipe then
        core.log("error in crafting mod, push_recipe: no recipe matching btn_id ".. tostring(btn_id) .." was found")
        return
    end

    -- if we can craft, craft
    if p_recipe.craftable then
        local ctype = cache.cTabs[cache.sTab]
        local sLevel = cache.sLevel
        local count = get_craft_count(cache, p_recipe, cache.item_hash)

        if not crafting.can_craft(player_name, ctype,
                                  sLevel, p_recipe.recipe) then
            minetest.log("error", "[inventoryFS] Player clicked a "..
                         "button they shouldn't have been able to")
            return false -- don't update formspec
        -- try to craft
        -- cache:get_craft_input() is the input list
        -- 'main' is the output list
        elseif crafting.perform_craft(
            player_name, cache.pInv, cache:get_craft_input(), 'main', p_recipe, ctype, count) then
            -- udpate recipes
            item_hashes_reset(cache) -- item_hash changed
            cache.FS_recipes = nil -- force recipes panel redraw
            -- update of recipe states will be made in get_recipes
            -- when formspec will be updated
            return true -- need to refresh formspec
        end
    -- else if recipe is possible, transfer
    elseif p_recipe.possible ~= false then
        -- indicates we have no possible state (hint button off)
        if p_recipe.possible == nil then
            -- lets still transfer it if possible !
            -- update possible state
            update_recipe_state(cache, p_recipe, "possible")
            -- if after that, still not possible -> impossible
            if p_recipe.possible == false then
                minimal.warn_message(player, player_name, S("Missing required items!"))
                return false -- do not refresh recipe_panel
            end
            --else continue #TODO make separate function for clarity
        end

        -- get possible count
        local count = get_craft_count(cache, p_recipe, cache.possible_hash)
        local inputs = cache:get_craft_input()
        local inv = player:get_inventory()
        -- get what lists to transfer from
        local from = cache:get_craft_input("possible")
        --[[ TODO we could improve the way we choose item to move,
        checking what is already in input panel
        to take the same items in priority]]
        local transfer = p_recipe:get_to_move(inv, from,  count)
        --[[ transfer to input lists, if not everything fits in first one,
        Then we will try second one with the leftover, etc etc ...]]
        for _, list in ipairs(inputs) do
            transfer = crafting.transfer_items(player, inv, list, transfer)
        end
        -- if not everythign could be transferd, leftover list is not empty
        if #transfer ~= 0 then
            minimal.warn_message(player, player_name, "Not enough room in to transfer everything")
        end
        -- input item_hash changed, update recipe states
        cache.item_hash = cache:get_input_hash()
        cache.FS_recipes = nil -- force recipes panel redraw
        -- update of recipe states will be made in get_recipes
        -- when formspec will be updated
        cache.to_sort = false -- to avoid resort when formspec is redrawn
        return true -- needed to refresh formspec
    else
        minimal.warn_message(player, player_name, S("Missing required items!"))
        return false -- do not refresh recipe_panel
    end
end

crafting.register_cache_function("push_recipe", push_recipe)
