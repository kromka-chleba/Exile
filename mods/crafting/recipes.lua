local crafting = crafting
local S = core.get_translator("crafting")

-- check craftable states , get details of recipes per player and itemhash -----
--------------------------------------------------------------------------------

-- Items level -----------------------------------------------------------------

-- test if item is fully available or not in item_hash
-- doesn't update the item
local function test_item (it, needed, item_hash)
    if not item_hash then
        core.log("in recipes.lua 'test_item' : item_hash is missing") -- #TODO better check
        return
    end
    local gstats = it.gstats
    local have = item_hash[it.name] or 0
    local available = false

    -- has a specified number (and have isn't 0, don't search unnecessarily)
    -- search number of group
    if have > 0 then
        -- if item is a groupe
        if (gstats and gstats.num) then
            have = item_hash[gstats.tag..gstats.num] or 0
            local cmd = gstats.num_cmd
            -- found command, check anew
            if cmd then
                have = 0
                -- start at gstats.num (-1 if less, otherwise +1)
                -- if less than, work down to 1 (-1), otherwise check until 256
                for i = (cmd == "<" and gstats.num-1 or gstats.num+1),
                    (cmd == "<" and 1 or 256), (cmd == "<" and -1 or 1)
                do
                    have = have + (item_hash[gstats.tag..i] or 0)
                end
            end
        end
        if (have >= needed) then
            available = true
        end
    end

    return available, have
end

-- updates detailled item list in recipe according to item_hash
local function update_item (it, item_hash)
    it.available, it.have = test_item (it, it.need, item_hash)
    return it
end

--[[ generate a list per input item of a recipe
* Returns `items` - a table with
    * index : item's name
    * value : a list with those parameters :
        * `name` = name of the item
        * `short` = description of the item to be displayed in recipe panel
        * `need` = the number we need for the recipe
        -- if itemhash is given (else added in update_item function)
        * `have` = the number we have in item_hash
        * `partial` = `true` if we have some of the needed
        * `available` = `true` if we have more than needed
This will be used to display custom infotext on recipe panel
#TODO currently not used in actual crafting I think (lili)
]]
-- #TODO dscription field could be common for all player, in main recipe
local function generate_item_details(input_item, item_hash)
    local gstats = crafting.get_group_stats(input_item)
    local stack = ItemStack(input_item)
    local def = table.copy(stack:get_definition())
    def.name = gstats and gstats.tag or def.name
    def.description = (gstats and S("Any @1",gstats.desc)) or def.description
    def._orig_desc = def._orig_desc or def.description
    local item_details = {
        name = def.name,
        gstats = gstats, -- nil if not a group
        description = def.description,
        short = def._orig_desc,
        need = stack:get_count(),
        -- following are unknown if we didn't check craftability
        -- update_item(item_details, item_hash) would fill it
        available = nil,
        have = nil,
    }
    -- if item_hash was given, test craftability
    if item_hash then
        update_item(item_details, item_hash)
    end
    return item_details
end

-- Recipes level ---------------------------------------------------------------

local player_recipe = {}
player_recipe.__index = player_recipe

local function generate_items_table(recipe, item_hash)
    local items_details = {}
    for row, rowItems in ipairs(recipe.items) do
        local t = {}
        -- single item peeks need to be in table for processing
        if (type(rowItems) ~= 'table') then
            rowItems = {rowItems}
        end
        for _, item in ipairs(rowItems) do
             t[#t + 1] = generate_item_details(item, item_hash)
        end
         -- save items by recipe input row
        items_details[row] = t
    end
    return items_details
end

--[[generate a detailled table associated to the recipe, with following fields:
    result = {
        *`recipe`    - recipe def table
        *`it_details` - list of items as build in get_items_details function
        *`craftable` - as in player_recipe.update_input_state function
        *`displayed` - true if recipe should be displayed in GUI
    }
]]
local function generate_p_recipe(recipe, item_hash)
    local result = {
        recipe = recipe,
        it_details = generate_items_table(recipe, item_hash),
        -- #TODO separate desc and craftable
        displayed = true
    }
    setmetatable(result, player_recipe)
    return result
end

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
            result.available = true
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

--[[ Parses available items in row @1 and @2 of given where condition
	to check in any fills it.
	recipe.where should look something like this:
		@1.material == @2.material
		@x where x is the input item row number
	Returns yes if a combination matches the condition, false else
	`items` is a list of items as stored in recipe after get_all
	]]
local function test_where_condition(recipe, items, criteria)
    --[[get name of item associated with that group in current itemhash
        used in player_recipe.update_input_state]]
    local function get_real_name(name)
        if name:sub(1, 6) == "group:" then
            return crafting.item_by_group[name]
        end
        return name
    end

	local craftable = false
	local lParam, lKey, test, rParam, rKey =
		string.match(recipe.where, "@(%d+)%.(%w+)%s*(.-)%s*@(%d+)%.(%w+)$")
	--[[lParam is the item row number for first item
		rParam is the item row number for second item
		lKey and rKey are the key to check: for example "material"
		test is the condition to check: "==" or "~="
	]]
	--#TODO maybe check format is correct

	-- for each item in row number lParam
	for _,left in ipairs( items[tonumber(lParam)] ) do
		--lName is item's name, or if a group, matching item's name
        -- TODO seems wierd since it is the last object used, but maybe not the only one ??
		local lName = get_real_name(left.name)
		-- if we have enough of this item,
		-- then test if condition is filled with him
		if left[criteria] then
			-- for each item in row number rParam
			for _,right in ipairs(items[tonumber(rParam)]) do
				local rName = get_real_name(right.name)
				-- if that item is available, test if it matches the condition
				if right[criteria] then
					local left_def = ItemStack(lName):get_definition()
					local lValue = left_def.exile_crafting[lKey]
					local right_def = ItemStack(rName):get_definition()
					local rValue = right_def.exile_crafting[rKey]
					-- find the operator
					if test == '==' and lValue == rValue then
						craftable = true
					end
					if test == '~=' and lValue ~= rValue then
						craftable = true
					end
				end
			end
		end
	end
	return craftable
end

-- #TODO update readme when finished
--[[Check ingredients in item hash to update result's table for that recipe
    if `modify` = `true` : update the result table containing craftable state, items and displayed state.
    #TODO : warning, only check inputs, do not check new unlocked recipes
    ]]
player_recipe.update_input_state = function(self, item_hash, modify)
    if not item_hash then
        core.log("in 'player_recipe.update_input_state' : item_hash is missing") -- #TODO better check
        return
    end
    local craftable = true
    -- Check what ingredients are available
    for row, rowItems in ipairs(self.it_details) do
        local pickable = false
        for i, item in ipairs(rowItems) do
            if modify then
                update_item(item, item_hash)
                -- if we have enough ingredient for that item,
                -- mark it as pickable
                if item.available then
                    pickable = true -- at least one item is available
                    break
                end
            else
                local missing = item.need - item.have
                -- if we have enough ingredient for that item,
                -- mark it as pickable
                item.possible = test_item(item, missing, item_hash)
                if missing <1 or item.possible then
                    pickable = true
                    break
                end
            end
        end
        -- if none of the item of the row was pickable, recipe is not craftable
        if not pickable then
            craftable = false
        end
    end
    -- at this point, craftable and partial are uptodate
    -- check if we have a where clause only if its craftable
    -- #TODO needs to be improve for possible recipes.
    if craftable and self.recipe.where then
        -- do we check available or possible items
        local criteria = modify and "available" or "possible"
        craftable = test_where_condition(self.recipe, self.it_details, criteria)
    end

    if modify then
        self.craftable = craftable
    else
        self.possible = craftable
    end
    return craftable
end


player_recipe.available_level = function (self, p_level)
    return (self.recipe.level <= p_level)
end

-- Recipe lists part ---------------------------------------------------------

function crafting.recipe_list_update(r_table, item_hash, modify)
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
        r:update_input_state(item_hash, modify)
    end
end

--[[get a details table of available recipes
    *`player_name`is mandatory to get available recipes for that player
    *`level` is optional: if missing, level condition won't be checked
    *`itemhash` is option: if present, we add craftable infos
    *return a table with following format :
    r_list[i] = {
        *`recipe`    - recipe def table
        *`items`     - list of items as build in get_items_details function
        *`craftable` - as in player_recipe.update_input_state function
        *`displayed` - true if recipe should be displayed in GUI
    }
]]
function crafting.get_player_recipes(player_name, ctype)
    -- if lists are not generated for player yet
    local player = core.get_player_by_name(player_name)
    if not player then
        minetest.log(
            "warning",
            "Can't get recipes of offline players")
        return {}
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
        -- get available list for that player and ctype
        return p_recipes_per_type[player_name][ctype]
    end
end
