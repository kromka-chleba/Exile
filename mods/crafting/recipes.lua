local crafting = crafting

-- check craftable states , get details of recipes per player and itemhash -----
--------------------------------------------------------------------------------
local function generate_pr_item(recipe_item)
    -- could happen if called with recipe.tool and we have no tool
    if recipe_item == nil then
        return nil
    else
        return {
             def = recipe_item,
             --[[ we can add following fields with "criteria_" as prefix
                [criteria.. "_have"] - number I have
                [criteria.. "_have"] - max craft number
             ]]
             -- acces functions to avoid accidentally update original recipe
             get_name = function() return recipe_item.name end,
             get_needed = function() return recipe_item.need end
        }
    end
end

local function generate_pr_items(recipe_items)
    local pr_items = {}
    for row, rowItems in ipairs(recipe_items) do
        local pr_it = {}
        for _, it in ipairs(rowItems) do
             pr_it[#pr_it + 1] = generate_pr_item(it)
        end
         -- save items by recipe input row
        pr_items[row] = pr_it
    end
    return pr_items
end

-- Recipes level ---------------------------------------------------------------
local player_recipe = {}
player_recipe.__index = player_recipe

--[[generate a detailled table associated to the recipe, with following fields:
    result = {
        *`recipe`    - recipe def table
        *`it_details` - list of items as build in get_items_details function
        *`craftable` - as in player_recipe.update_craftable_state function
        *`displayed` - true if recipe should be displayed in GUI
    }
]]
-- player state
-- TODO update the doc
-- WARNING: we can only have one tool
local function generate_p_recipe(recipe)
    local result = {
        recipe = recipe,
        pr_items = generate_pr_items(recipe.items),
        --[[ we can add following fields with "criteria_" as prefix
           [criteria.. "_have"] - number I have
           [criteria.. "_have"] - max craft number
        ]]
        pr_tool = generate_pr_item(recipe.tool),
        -- #TODO separate desc and craftable
        unlocked = nil, -- is unlocked
        displayed = true -- will it be displayed in GUI
    }
    setmetatable(result, player_recipe)
    return result
end

crafting.generate_p_recipe = generate_p_recipe

-- list of available------------------------------------------------------------

-- rebuilt at each first request after login
local p_recipes_per_id = {}
local p_recipes_per_type = {}

-- initiate p_recipes_per_id and p_recipes_per_type for player_name
-- #TODO appeler au log ? ou à la demande ?
local function register_player_recipes(player_name)
    p_recipes_per_id[player_name] = {}
    p_recipes_per_type[player_name] = {}
    local unlocked = crafting.get_unlocked(player_name)
    for id, recipe in pairs(crafting.get_recipes()) do
        local result = generate_p_recipe(recipe)
        -- if I know that recipe, add it to the list, else no
        if recipe.always_known or unlocked[recipe.output] then
            result.unlocked = true
        end
        -- adds the result to p_recipes_per_id for player
        p_recipes_per_id[player_name][id] = result
        -- adds the result to p_recipes_per type for player
        for _,type in ipairs(recipe.type) do
            local t = p_recipes_per_type[player_name][type] or {}
            t[#t+1] = result
            p_recipes_per_type[player_name][type] = t
        end
    end
end

-- #TODO do the same for crafting caches...
core.register_on_leaveplayer(function(player)
    local p_name = player:get_player_name()
        p_recipes_per_id[p_name] = nil
        p_recipes_per_type[p_name] = nil
    end)


-- update craftable or possible state of a recipe
-- pr player_recipe table
local function update_state (pr, item_hash, criteria)
    if not criteria then criteria = "craftable" end
    if not item_hash then
        core.log("in recipe.lua in 'get_state' : item_hash is missing") -- #TODO better check
        return
    end
    local max, pr_states = pr.recipe:find_max_craftable (item_hash)

    -- update tool `have`
    if pr.pr_tool then
        pr.pr_tool[criteria .. "_have"] = pr_states.tool.have
    end

    -- update pr items state
    for i, row in pairs(pr_states.items) do
        for j, it_state in pairs(row) do
            local pr_it = pr.pr_items[i][j]
            pr_it[criteria .. "_have"] = it_state.have
            pr_it[criteria .. "_max"] = it_state.max
        end
    end
    -- register max to player_recipe matching field
    pr[criteria .. "_max"] = max
    pr[criteria] = (max > 0)
    -- returns true if max >0
    return (max >0)
end

-- #TODO update readme when finished
--[[Check ingredients in item hash to update result's table for that recipe
    #TODO : warning, only check inputs, do not check new unlocked recipes
]]
player_recipe.update_state = update_state

-- TODO ------------
-- >>>>>>>


--#TODO check how it is done and using itemhash and if it can be improved.
-- Quantity sets single, stack or maximum -- this finds how many we can craft
-- returns nothing but update recipe.items
-- #TODO that function doesn't remove things from item stack, so may fail in case of same input used multiple times
-- TODO change the system to first fill with prioritary inv, then the others, instead of first item in each row first ?
local function get_to_take(r, count)
    -- TODO check if useful
    if not count then count = 1 end
    -- set count to know how many output(s) to give
    -- TODO unused yet, not sure if I modifu recipe output, or display detailled items,
    --meant to display a xcount everywhere
    r.count = count

    local pItems = {} -- picked items list
    -- set input items to values for max_count
    for i, row in ipairs(r.pr_items) do
        local to_take_in_row = count
        -- use max_count for each row's max
        for j, it in ipairs(row) do
            -- WARNING it.have will remain the same, one item in recipe has to only be used once.
            local can_take = it.craftable_max
            if can_take > 0 then
                -- dont take more that required
                if can_take > to_take_in_row then
                    can_take = to_take_in_row
                end
                -- TODO here we can adjust with custom functions
                local taking = it.get_name() .." "..can_take * it.get_needed()
                pItems[#pItems+1] = taking
                to_take_in_row = to_take_in_row - can_take
                if to_take_in_row == 0 then
                    -- I have verything I need in the row
                    break
                end
            end
        end
    end
    return pItems
end

player_recipe.get_to_take = get_to_take

--transfer for possible recipes
-- move max possible TODO even overriding the max possible or not ?
-- like "move all" instead of "move max" ? by double click or button ?
local function get_to_move(r, count)
    -- TODO check if useful
    if not count then count = 1 end
    -- set count to know how many output(s) to give
    -- TODO unused yet, not sure if I modifu recipe output, or display detailled items,
    --meant to display a xcount everywhere
    r.count = count

    local to_move = {}
    -- move tool if needed
    if r.pr_tool then
        local missing = r.pr_tool.get_needed() - r.pr_tool.craftable_have
        if missing > 0 then
            to_move[#to_move+1] = r.pr_tool.get_name() .." ".. tostring(missing)
        end
    end
    -- set input items to values for max_count
    for i, row in ipairs(r.pr_items) do
        local to_take_in_row = count
        -- use max_count for each row's max
        for j, it in ipairs(row) do
            local can_take = it.possible_max
            if can_take > 0 then
                if can_take > to_take_in_row then
                    can_take = to_take_in_row
                    -- no more then max_count should be picked.
                    -- TODO except if I want to move all
                end
                -- get what is missing
                local missing = can_take * it.get_needed() - it.craftable_have
                -- WARNING it.have will remain the same, one item in recipe has to only be used once.
                if missing > 0 then
                    to_move[#to_move+1] = it.get_name() .." ".. tostring(missing)
                end
                to_take_in_row = to_take_in_row - can_take
                if to_take_in_row == 0 then
                    -- I have verything I need in the row
                    -- TODO except if I want to move all
                    break
                end
            end
        end
    end
    return to_move
end

player_recipe.get_to_move = get_to_move


-- Recipe lists part ---------------------------------------------------------

--[[get a details table of available recipes
    *`player_name`is mandatory to get available recipes for that player
    *`level` is optional: if missing, level condition won't be checked
    *`itemhash` is option: if present, we add craftable infos
    *return a table with following format :
    r_list[i] = {
        *`recipe`    - recipe def table
        *`items`     - list of items as build in get_items_details function
        *`craftable` - as in player_recipe.update_craftable_state function
        *`displayed` - true if recipe should be displayed in GUI
    }
]]
function crafting.get_player_recipes(player_name, ctype, sLevel)
    -- if lists are not generated for player yet
    local player = core.get_player_by_name(player_name)
    if not player then
        core.log("Can't get recipes of offline players")
        return nil
    end

    -- if we didn't initiate the recipes for that player yet, do it
    if not p_recipes_per_id[player_name]
                or not p_recipes_per_type[player_name] then
        register_player_recipes(player:get_player_name())
    end
    -- if crafting type is missing, return all recipes
    if not ctype then
        return p_recipes_per_id
    else
        local ct_recipes = p_recipes_per_type[player_name][ctype]
        if not ct_recipes then
            core.log ("warning", "no recipe is registered with type ".. tostring(ctype))
            return {}
        else
            -- get available list for that ctype and lvl
            if not sLevel then
                return ct_recipes
            else
                local t = {}
                for _, r in ipairs(ct_recipes) do
                    if r.recipe.level <= sLevel then
                        t[#t + 1] = r -- TODO maybe get recipes only, generate details later.
                    end
                end
                return t
            end
        end
    end
end
