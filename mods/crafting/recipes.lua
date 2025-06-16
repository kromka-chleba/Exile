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
        unlocked = nil, -- is unlocked
        displayed = true -- will it be displayed in GUI, true by default
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
-- #TODO not sure I should store them, I could generate it on every call in recipes panel.
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

--[[Check ingredients in item hash to update result's table for that recipe
    #TODO : warning, only check inputs, do not check new unlocked recipes
]]
player_recipe.update_state = update_state

-- reset all item states with criteria, like [criteria .. "_have"]
player_recipe.reset_state = function(pr, criteria)
    if type(criteria) == "string" then criteria = {criteria} end
    if type(criteria) ~="table" then
        core.log ("no valid criteria given in player_recipe.reset_state"
                  .. "so nothing will be done")
        return
    end

    for _, crit in pairs (criteria) do
        -- reset tool `have`
        if pr.pr_tool then
            pr.pr_tool[crit .. "_have"] = nil
        end

        -- update pr items state
        for _, row in pairs(pr.pr_items) do
            for _, pr_it in pairs(row) do
                pr_it[crit .. "_have"] = nil
                pr_it[crit .. "_max"] = nil
            end
        end
        -- register max to player_recipe matching field
        pr[crit .. "_max"] = nil
        pr[crit] = nil
    end
end

-- required is the number of item/weight we need to make with that item
local function pick_item(it, inv, lists, required)
    -- to write to pick item
    local picked_table ={}
    local to_take = ItemStack(it)
    local name = to_take:get_name()
    --print("Attempting to pick ",itemName)

    -- parse list my order of priority
    for _, list in ipairs(lists) do
        picked_table[list] = {}
        -- search stacks in provided inv lists
        for i = 1, inv:get_size(list) do
            local stack = inv:get_stack(list, i)
            --print("Checking ",stack:get_name()," ",stack:get_count())
            local found, still_needed = it:take(stack, required)
            if found then
                required = still_needed
                -- add itemstack to the ones to take from that list
                table.insert(picked_table[list], found)
                -- if I don't need more, stop parsing the list
                if required <= 0 then
                    break
                end
            end
        end
        -- if I don't need more, stop parsing the lists
        if required <= 0 then
            break
        end
    end

    -- if I couldn't find enough, return nil
    if required > 0 then
        core.log("I couldn't find in inventory the ingredient I was supposed to take"
        .. " I was looking for " .. name
        .. ". I needed: " .. to_take:get_count()
        .. " and " .. tostring(required) .. " are missing.")
        return nil
    else
        return picked_table
    end
end

--pItems list of take functions to run
--[[WARNING it.have will remain the same,
one item in recipe has to only be used once, else the same input can be used multiple times]]
--[[ criteria is "possible" or "craftable"
    if "possible" we will only pick in lists
    what is needed for the recipe
    but we do'nt have in craftable part yet.]]
local function pick_input_items(pr, inv, lists, count, criteria)
    if not criteria then criteria = "craftable" end
    if criteria ~= "craftable" and criteria ~= "possible" then
        core.log("incorrect criteria given to pick_input_items" ..
        "it has to be nil, 'craftable' or 'possible'")
        return nil
    end
    -- TODO check if useful
    if not count then count = 1 end

    --meant to display a "x count" everywhere
    pr.count = count

    -- TODO better check
    if type(lists) == "string" then
        lists = {lists}
    end

    -- to store found items
    local found_table = {}
    -- initiate found_table
    for i, list in ipairs(lists) do
        found_table[list]={}
    end

    if criteria == "possible" then -- to move
        -- move tool if needed
        if pr.pr_tool then
            local missing = pr.pr_tool.get_needed() - pr.pr_tool.craftable_have
            if missing > 0 then
                found_table =  pick_item(it, inv, lists, missing)
                -- if this part is found, add it to found_table
                if not found_table then
                    core.log("I couldn't find the tool to move")
                    return nil
                end
            end
        end
    end

    -- set input items to values for max_count
    for i, row in ipairs(pr.pr_items) do
        local to_take_in_row = count
        -- use max_count for each row's max
        for j, pr_it in ipairs(row) do
            --local can_take = pr_it.craftable_max
            local can_take = pr_it[criteria .. "_max"]
            if can_take > 0 then
                -- dont take more that required
                if can_take > to_take_in_row then
                    can_take = to_take_in_row
                end
                local it = pr_it.def

                local required = it.need * can_take
                -- only move the one we don't already have if "possible"
                if criteria == "possible" then
                    required = required - pr_it.craftable_have
                end

                if required > 0 then
                    local pick_table =  pick_item(it, inv, lists, required)
                    -- if this part is found, add it to found_table
                    if pick_table then
                        for list, p_litems in pairs (pick_table) do
                            for _, p_stack in pairs(p_litems) do
                                table.insert(found_table[list], p_stack)
                            end
                        end
                    -- if this part is not found, stop
                    else
                        core.log("I couldn't find in inventory all the ingredients I was supposed to take"
                        .. " I was looking for " .. pr_it:get_name()
                        .. ". I wanted to craft/move " .. tostring(can_take)
                        .. " times, but couldn't found enough.")
                        return
                    end
                end

                to_take_in_row = to_take_in_row - can_take
                if to_take_in_row == 0 then
                    -- I have verything I need in the row
                    break
                end
            end
        end
    end
    -- Return found list
    return found_table
end

--[[ Get a table of items to pick for the craft
    * Format is {{["listname"] = {list of itemstack}}}
    * `lists` is the inv lists where to take item
    * `count` is the number of craft(s) we want to do
    WARNING one item in recipe has to only be used once,
else the same input can be used multiple times.
]]
player_recipe.pick_input_items = pick_input_items

--transfer for possible recipes
-- move max possible TODO even overriding the max possible or not ?
-- like "move all" instead of "move max" ? by double click or button ?

local function get_to_move(pr, inv, lists, count)
    return pick_input_items(pr, inv, lists, count, 'possible')
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
