local S = minetest.get_translator("crafting")

--[[Checks the state of each item in `item_list` compared to input `item_hash`
    * Returns `items` - a table with
        * index : item's name
        * value : a list with those parameters :
            * `name` = name of the item
            * have = the number we have in item_hash
            * need = the number we need for the recipe,
            * partial = `true` if we have some of the needed
            * available = `true` if we have more than needed
            * short = description of the item
    This will be used to display custom infotext on recipe panel
    #TODO currently not used in actual crafting I think (lili)
             ]]
local function peek_item(item_list, item_hash)
    local items = {}
    -- single item peeks need to be in table for processing
    if (type(item_list) ~= 'table') then
        item_list = { item_list }
    end
    for _, item in ipairs(item_list) do
        local gstats = crafting.get_group_stats(item)
        local stack = ItemStack(item)
        local def = table.copy(stack:get_definition())
        def.name = gstats and gstats.tag or def.name
        def.description = (gstats and S("Any @1",gstats.desc)) or def.description
        def._orig_desc = def._orig_desc or def.description
        local need =  stack:get_count()
        local have = item_hash[def.name] or 0
        -- has a specified number (and have isn't 0, don't search unnecessarily)
        if have ~= 0 and (gstats and gstats.num) then
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
        items[#items + 1] = {
            name = def.name,
            have = have,
            need = need,
            partial = (have > 0) and true or false,
            available = (have >= need) and true or false,
            description = def.description,
            short = def._orig_desc,
        }
    end
    return items
end

--[[get name of item associated with that group in current itemhash
    used in crafting.check_inputs]]
local function get_real_name(name)
    if name:sub(1, 6) == "group:" then
        return crafting.item_by_group[name]
    end
    return name
end

--[[ Parses available items in row @1 and @2 of given where condition
	to check in any fills it.
	recipe.where should look something like this:
		@1.material == @2.material
		@x where x is the input item row number
	Returns yes if a combination matches the condition, false else
	`items` is a list of items as stored in recipe after get_all
	]]
local function test_where_condition(recipe, items)
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
		local lName = get_real_name(left.name)
		-- if we have enough of this item,
		-- then test if condition is filled with him
		if left.available then
			-- for each item in row number rParam
			for _,right in ipairs(items[tonumber(rParam)]) do
				local rName = get_real_name(right.name)
				-- if that item is available, test if it matches the condition
				if right.available then
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

--[[Checks the state of `recipe` using `itemhash` to craft it
    Returns :
    * `craftable`, a number equal to
        * 1 if all required items are in set_item_hash
        * 2 if some of them are
        * 0 if none of them are in item_hash
    * `items` - an item table as build in peek_item function
]]
function crafting.check_inputs (recipe, item_hash)
    local craftable = true
    local on_the_way = false
    local items = {}
    -- Check what ingredients are available
    for recipe_row, rowItem in ipairs(recipe.items) do
        local rItems = {} -- row items
        local pickable = false

        for i,item in ipairs(peek_item(rowItem, item_hash)) do
            rItems[#rItems+1] = item
            -- if we have some item, even if not enough, marke the recipe as "on the way"
            if item.partial then
                on_the_way = true
            end
            -- if we have enough ingredient for that item, mark it as pickable
            if item.available then
                pickable = true -- at least one item is available
            end
        end

        items[recipe_row]=rItems -- save items by recipe input row
        -- if we don't have any of the needed ingredients for this row, recipe is not craftable
        -- #TODO with that system, it fails if we have the same item in multiple rows
        if not pickable then
            craftable = false
        end
    end
    -- check if we have a where clause only if its craftable
    if craftable and recipe.where then
        craftable = test_where_condition(recipe, items)
    end

    local result = 0
    if on_the_way then
        result = 2
    end
    if craftable then
        result = 1
    end

    return result, items
end

--[[ unused yet
    to be developed when we implement lvl/unlock maybe]]
function crafting.is_craftable (recipe, level, unlocked, item_hash)
    -- if I know that recipe
    if recipe.level <= level and (recipe.always_known
    or unlocked[recipe.output]) then
        return (crafting.check_inputs (recipe, item_hash) == 1)
    else
        --#TODO improve here
        return false
    end
end

--[[ get all unlocked recipes to display
    return a table with following format :
    t[i] = {
    recipe    - recipe def table
    items     - list of items as build in peek_item function
    craftable - as in crafting.check_inputs function
    displayed - true if recipe should be displayed in GUI
    ]]
function crafting.get_all(ctype, level, item_hash, unlocked)
    assert(crafting.recipes[ctype], "No such craft type!")
    local t = {}
    for _, recipe in pairs(crafting.recipes[ctype]) do
        -- if I know that recipe, add it to the list, else no
        if recipe.level <= level and (recipe.always_known
        or unlocked[recipe.output]) then
            local result, items = crafting.check_inputs (recipe, item_hash)
            t[#t + 1] = {
                recipe    = recipe,
                items     = items,
                craftable = result,
                displayed = true --(default if no filter)
            }
        end
    end
    return t
end

--[[old function currently unused
    Returns result of crafting.get_all called with
    * "main" player's inventory list as item_hash
    * unlocked recipe list for that player
    ]]
function crafting.get_all_for_player(player, ctype, level)
	local unlocked = crafting.get_unlocked(player:get_player_name())
	-- build player items hash
	local item_hash = {}
	-- reset group hash
	crafting.item_by_group = {}
	crafting.set_item_hashes_from_list(player:get_inventory(), "main", item_hash)
	-- Get all available recipies and mark craftible ones.
	local results =  crafting.get_all(ctype, level, item_hash, unlocked)
	return results
end


--[[Check ingredients in item hash to update result's table for that recipe,
    and update the result table containing craftable state, items and displayed state.
    #TODO : warning, only check inputs, do not check new unlocked recipes or change of level
    ]]
function crafting.update_craftable_state(result, item_hash)
    if not result or type(result) ~= "table" then
        core.log("in crafting/api.lua : there is no recipe to check")
        return -- #TODO check if we do better
    end

    local recipe = result.recipe
    if not recipe then
        core.log("in crafting/api.lua : recipe is missing")
        return -- #TODO check if we do better
    end

    result.craftable,result.items = crafting.check_inputs(recipe, item_hash)
    return result
end

-- craftable/uncraftable color sorting -----------------------------------------

--[[ take a recipe list with crafting.get_all return format and sort it in 2 lists :
    returns craftable and uncraftable table of results
    format of each table is the one documented for crafting.get_all
]]
function crafting.sort_craftable_recipes(t)
    local craftable_t = {}
    local possible_t = {}
    local uncraftable_t = {}

    for _, result in ipairs (t) do
        -- add recipe to list only if it matchs search
        if result.craftable == 1 then
            craftable_t[#craftable_t + 1] = result
        elseif result.possible == 1 then
            possible_t[#possible_t + 1] = result
        else
            uncraftable_t[#uncraftable_t + 1] = result
        end
    end
    return craftable_t,possible_t, uncraftable_t
end
