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
            r:update_state(item_hash, "possible")
        else
            r:update_state(item_hash)
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
            cache.recipes = crafting.get_player_recipes(player_name, ctype, cache.sLevel)
            -- if  level or itemash is given, update current state
            if not cache.recipes then
                core.log ("in crafting.get_recipes_table : I couldn't get any recipes list,\nreturning {{}}")
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
            cache:process_max_label ()

            -- get what is possible using both input + inventory
            -- #TODO this is only to used with option one, improve that part
            if cache.possible_hint then
                -- update possible state
                -- TODO better dealing with choices of item_hash
                local i_s = crafting.get_item_hash(pInv, {"input_items", "main"})
                update_list_input_state(cache.recipes, i_s, true)
            end

        -- if we want to sort order per craftability and possible
        if cache.sorted == true then
            -- if we need to re-sort the list
            if cache.to_sort == true then
                sort_craftable_recipes(cache)
            end
            t = {cache.c_recipes, cache.p_recipes, cache.u_recipes}
        end
    else
        t = {cache.recipes}
    end
    -- apply search filters if needed
    cache:apply_filters()

    return t
end

-- PROCESS -----------------------------------------------------------
-- reset recipes in cache (list and formspec)
crafting.register_cache_function("reset_recipes",
    function(self)
    -- will force to resort recipes
    -- resets recipes lists
    self.c_recipes = nil -- list of craftable recipes to display
    self.p_recipes = nil -- list of possible recipes to display
    self.u_recipes = nil -- list of uncraftable recipes to display
    self.recipes = nil -- list of all 3 above reunited, unsorted
    -- erases recipes panel formspec part
    self.FS_recipes = nil
    -- reset scroll bar to top
    self.sScroll = 0 -- reset scrollbar to top
    -- TODO clean because there may be a better place
    -- make sure we resort recipe order
    self.to_sort = true
end)


-- Find multiplier of input needed to craft one max_stack of output items
-- #TODO update for multi output future recipes
local function calculate_stack_input(item)
    local output_name = item:get_name()
    local per_input = item:get_count()
    local stack_size = core.registered_items[output_name].stack_max
    return stack_size / per_input
end

 -- TODO maybe improve dealing with cache.item_hash
local function get_craft_count(cache, r, item_hash)
    local qty = cache.qty
    if not qty then
        core.log("warning", "cache.qty is not given in 'get_craft_count' function, 1 is used by default")
        return 1
    -- only one requested? Max not allowed ? return 1
        elseif qty == 1 or r.recipe.no_max then
        return 1
    end
    -- more then single requested? find maxif all_possible
    item_hash = item_hash or cache.item_hash
    if not item_hash then
        core.log("no item_hsah available to get_craft_count")
    end
    local max_count = r.recipe:find_max_craftable(item_hash)

    if qty == 2 then -- stack requested so adjust max to max for stack.
        local stack_count = calculate_stack_input(ItemStack(r.recipe.output))
        if max_count > stack_count then
            max_count = stack_count
        end
    end
    return max_count
end

crafting.register_cache_function("get_craft_count", get_craft_count)

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

crafting.register_cache_function("process_max_label", process_max_label)

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

    local inv = player:get_inventory()

    -- if we can craft, craft
    if p_recipe.craftable then
        local ctype = cache.cTabs[cache.sTab]
        local sLevel = cache.sLevel
        --#TODO I need to improve the way cache.item_hash is assigned/modified
        if not cache.item_hash then
            cache.item_hash = cache:get_input_hash(inv)
        end

        local count = get_craft_count(cache, p_recipe, cache.item_hash)

        if not crafting.can_craft(player_name, ctype,
                                  sLevel, p_recipe.recipe) then
            minetest.log("error", "[inventoryFS] Player clicked a "..
                         "button they shouldn't have been able to")
            return true
        -- try to craft
        -- cache:get_craft_input() is the input list
        -- 'main' is the output list
        elseif crafting.perform_craft(
            player_name, inv, cache:get_craft_input(), 'main', p_recipe, ctype, count) then
            -- TODO I think I reset in double ? because I reset after in process
            cache.FS_recipes = nil
            cache.to_sort = true
            return true -- need to refresh formspec
        end

    -- else if recipe is possible, transfer
    elseif p_recipe.possible then
        -- TODO input setting
        -- could be a setting too, to have "what is possible"
        local item_hash = crafting.get_item_hash(inv, {"main", "input_items"})

        local count = get_craft_count(cache, p_recipe, item_hash)
        -- TODO stop storing it.check that part (done already ?)
        local to_move = p_recipe:get_to_move(count)
        local inputs = cache:get_craft_input()
        -- TODO setting for where we can take it from
        local transfer = crafting.find_required_items(inv, "main", to_move)
        for _, list in ipairs(inputs) do
            -- TODO improve because here, groups were replaced with non group items
            -- maybe we had room for other choices too....
            -- we could check what is already in input to choose same alternate item from group,
            -- mixing it with get_to_move in the same function.
            transfer = crafting.transfer_items(player, inv, list, "main", transfer)
        end
        cache.FS_recipes = nil
        cache.to_sort = false -- to avoid sort
        -- (was put to true on reset)
        -- TODO clean that, it is confusing
        return true -- needed to refresh formspec
        -- TODO ah but I change order when it passes to craftable !!
    else
        minimal.warn_message(player, player_name, S("Missing required items!"))
        return false -- do not refresh recipe_panel
    end
end

crafting.register_cache_function("push_recipe", push_recipe)

-- FORMSPEC generations --------------------------------------------------------
local esc = core.formspec_escape
local color_esc = core.get_color_escape_sequence

local function item_tool_tip(pr_it)
    local item = pr_it.def
    if item.get_tooltip then
        return item:get_tooltip(pr_it.have)
    end
    -- else use default tooltip
    local s = {} -- future tooltip for that item
    local h
    -- adds colors if needed
    local have = pr_it.craftable_have
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

-- generates tooltip of each recipe
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
    local bg_image
    local craftable = pr.craftable
    if craftable then -- craftable
        bg_image = 'crafting_slot_craftable.png'
    elseif pr.possible and cache.possible_hint then
        -- possible
        bg_image = 'crafting_slot_possible.png'
    elseif craftable == false then -- uncraftable
        bg_image = 'crafting_slot_uncraftable.png'
    else -- unknown
        bg_image = 'crafting_slot_empty.png'
    end

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
            pr.count = get_craft_count(cache,pr, cache.item_hash)
        end
    end

    if pr.recipe._display then
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
        if pr.count and pr.count > 1 then
            local label_coords = tostring( x + 0.1 ) .. ','
                            .. tostring( y + 0.45 )
            form_table[#form_table + 1] = "label["
                                    .. label_coords ..";"
                                    .. tostring(pr.count) .. "]"
        end
    else
        local display_o = ItemStack(pr.recipe.output)
        local count = display_o:get_count()
        if pr.count and pr.count ~= 0 then -- check when 0 happen
            display_o:set_count(count * pr.count)
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
-- used only in get_recipes_list
-- #TODO check if I can change that call
crafting.register_cache_function("get_recipes_panel",
    function(self, pInv)

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
