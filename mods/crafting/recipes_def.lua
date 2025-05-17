
--CRAFT TYPES and RECIPES registrations and calls ------------------------------

-- Crafting types --------------------------------------------------------------

--[[table of crafting types with follwing format :
    * [name] as index
    * following fields :
        * `label`     - label to display, is `name` if label not provided
        * `icon`      - icon to disply in tab
        * `recipes`   - table of possible recipes for that crafting type
        * `sound`
    ]]
local craft_types = {}

-- only here for tests/api_spec.lua
function crafting.reset_craft_types()
    craft_types = {}
end

function crafting.is_type_registered(name)
    if not craft_types[name] then
        return false
    else
        return true
    end
end

-- get type table for that `name`
function crafting.get_type(name)
    return craft_types[name]
end

-- get recipes table for that crafting type
function crafting.get_recipes_by_type(type)
    local tab = craft_types[type]
    if not tab then
        core.log (type .. " is not a valid registered type, returning nil")
        return nil
    else
        return craft_types[type].recipes
    end
end

-- gives a list of all registered crafting types' names
function crafting.get_registered_types_names()
    local t= {}
    for name, _ in pairs(craft_types) do
        t[#t+1] = name
    end
    return t
end

-- can go when exile_meals mod adapted
crafting.recipes = {}

--[[register craft types (used for stations and tabs):
    *name: the name of the type
    *label: what will be displayed in game (tab) and translated
    *icon_item_name: for image tab
    *sound: sound made when we craft a recipe of that type
]]
function crafting.register_type(name, label, icon_item_name, sound)
    if name == nil then
        core.log ("missing 'name' in crafting.register_type.\nRegistration cancelled")
        return
    end
    -- if type is already registered, warn the user
    -- #TODO make a function to modify it ??
    if craft_types[name] then
        core.log("warning", "type "
        .. name
        .. "is already registered. Use crafting.get_registered_types() to get the registered list.\n"
        .. "type will be overriden")
    end

    local new_type = {}
    new_type.name = name
    -- add a label for tabs - default to the name
    new_type.label = (label or name)
    new_type.icon = icon_item_name
    new_type.recipes = {}

    -- set up sound mechanism
    if type(sound) == "string" then
        sound = {name = sound}
    elseif sound and type(sound) ~= "table" then
        core.log ("wrong 'sound' type in crafting.register_type of " .. name)
    end
    if sound and type(sound.name) == "string" then
        sound.max_hear_distance = sound.max_hear_distance or 10
        new_type.sound = sound
    end

    craft_types[name] = new_type

    -- can go when exile_meals mod adapted
    crafting.recipes[name] = crafting.get_recipes_by_type(name)
end

-- Recipes ---------------------------------------------------------

--array of all registered recipes, by `id`
local recipes_by_id = {}

--#TODO still used ?
function crafting.get_recipes()
    return recipes_by_id
end

-- get recipe by ID
function crafting.get_recipe(id)
    if type(id) == "number" then
        return recipes_by_id[id]
    else
        core.log("wrong param type in crafting.get_recipe, number expected, got" .. type(id))
        return
    end
end

-- r_items (recipe's items) class --

local item_funcs = {}
item_funcs.__index = item_funcs

--[[ generate a list per input item of a recipe
* Returns `items` - a table with
TODO not uptodate
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
local function generate_item_details(input_item)
    if not input_item then
        return nil
    end
    local item_details
    -- if item is a function, use that one to generate
    if type(input_item) == "function" then
        item_details = input_item()
    else -- else, use default generation
        local gstats = crafting.get_group_stats(input_item)
        local stack = ItemStack(input_item)
        local def = table.copy(stack:get_definition())
        def.name = gstats and gstats.tag or def.name
        def.description = (gstats and gstats.desc) or def.description
        def._orig_desc = def._orig_desc or def.description
        item_details = {
            name = def.name,
            gstats = gstats, -- nil if not a group
            description = def.description,
            short = def._orig_desc,
            -- as function to avoid accidental modification
            need = stack:get_count()
        }
    end
    setmetatable(item_details, item_funcs)
    return item_details
end

-- recipe class --

local recipe_funcs = {}
recipe_funcs.__index = recipe_funcs

local function generate_items_table(recipe_items)
    local items_details = {}
    -- case string or function
    if type(recipe_items) ~= "table" then
        recipe_items = {recipe_items}
    end
    for row, rowItems in ipairs(recipe_items) do
        local t = {}
        -- single item peeks need to be in table for processing
        if (type(rowItems) ~= 'table') then
            rowItems = {rowItems}
        end
        for _, item in ipairs(rowItems) do
             t[#t + 1] = generate_item_details(item)
        end
         -- save items by recipe input row
        items_details[row] = t
    end
    return items_details
end

--[[register recipe using `def` table with following fields:
    * `id`           - ID of recipe, in order of registration'
    * `type`         - one of the registered types.
    * `output`       - the result of the craft, eg: `default:stone 3`.
    * `items`        - A list of ingredients, eg: `{"stone", "wood 3"}`.
    * `level`        - level of station required.
    * `always_known` - If true, this recipe will never need to be unlocked.
    * `replace`      - to deal with replacement
                       accepts 3 formats:
                          * `string`: then it gives it as additionnal outpur
                          * `table`: {[item_to_replace] = replacement_item}
                          * `function`: apply the function to generate the table
    * `sound`
    * `_display`     - string of image to display in recipe panel
    Register def in recipes_by_id[def.id]
    Returns id of recipe
    ]]
function crafting.register_recipe(def)
    local function recipe_error(txt)
        error("crafting.register_recipe: issue with "..def.output.." recipe; "..txt)
    end
    -- multiple output items unsupported due to minimal/interface/inventory.lua
    -- limitations, do replace instead
    assert(type(def.output) == "string",
           "crafting.register_recipe: 'output' needed in recipe definition (string only)")
    if not def.type then
        recipe_error("'type' is needed in recipe definition!")
    end
    if not def.items then
        recipe_error("'items' needs to be specified in recipe definition!")
    end

    -- crafting level
    def.level = def.level or 1
    if type(def.level) ~= "number" then
        recipe_error("expected number for 'level', got '"..type(def.level).."'")
    end
    -- always_known boolean, set to true unless otherwise specified
    def.always_known = type(def.always_known) ~= "boolean" and true or def.always_known
    -- Can be more then one craft station for a recipe
    -- Need to store as a table.
    def.type = type(def.type) == 'string' and {def.type} or def.type
    if type(def.type) ~= "table" then
        recipe_error("expected string or table for 'type', got '"..type(def.type).."'")
    end
    -- items table
    if type(def.items) == 'string'then
        def.items = {def.items}
    end
    if type(def.items) ~= "table" and type(def.items) ~= "function" then
        recipe_error("expected string, table or function for 'items', got '"..type(def.items).."'")
    end

    -- checks table format and remove if invalid
    if def.replace then
        local type = type(def.replace)
        if type ~= "string"
                        and type ~= "table"
                        and type ~= "function" then
            recipe_error("field 'replace' doesn't have correct format, format is " .. type
            .. "\nreplacement will not be applied.")
            def.replace =nil
        end
    end

    -- objects useds as tool and not to be consumed
    if def.tool and type(def.tool) ~= "string" then
        recipe_error("field 'tool' doesn't have correct format")
    end

    -- forbid max for tools outputs
    -- if not explicitely set on "I want max possible"
    local o_name = ItemStack(def.output):get_name()
    if minetest.registered_tools[o_name] and def.no_max ~= false then
        def.no_max = true
    end

    -- custom sound per recipe
    -- permits "false" to prevent playing of crafting station sound
    def.sound = type(def.sound) == "string" and {name = def.sound} or type(def.sound) == "table" and def.sound or
        def.sound ~= false and nil
    if def.sound then
        def.sound.max_hear_distance = def.sound.max_hear_distance or 10
    end
    -- custom preview for formspec
    def._display = def._display

    def.id = #recipes_by_id + 1

    -- default functions
    setmetatable(def, recipe_funcs)

    recipes_by_id[def.id] = def

    return def.id
end

-- is `p_level` (player level/crafting level) enough to craft that recipe
recipe_funcs.available_level = function (self, p_level)
    return (self.level <= p_level)
end

-- Check of recipe validity ---------------------------------------------------

do
    -- find every variant (item name) of a recipe item, including groups
    local function add_items_names(r_item, list)
        if r_item.get_items_names then
            local l = r_item.get_items_names()
            for _, name in ipairs(l) do
                table.insert(list, name)
            end
        else
            local itemName = r_item.name
            local group_stats = crafting.get_group_stats(itemName)
            if group_stats then
                local t = crafting.get_group_items(group_stats.name)
                        or crafting.get_group_items(group_stats.unit)
                if not t then
                    core.log("no items defined for group: " .. group_stats.tag )
                else
                    for _,it in ipairs(t) do
                        if group_stats:does_match(it) then
                            table.insert(list, it)
                        end
                    end
                end
            else
                table.insert(list, itemName)
            end
        end
        return list
    end

    -- TODO add to readme
    -- input is item or grouptag
    function crafting.get_input_variants(r_item)
        if r_item.get_items_names then
            return r_item.get_items_names()
        else
            return add_items_names(r_item, {})
        end
    end

    --[[ check if no duplicates inputs, which currentldy would make craft do unwanted things
    run after mods loaded
    ]]
    -- TODO improve/check with units/complex grouptag
    local function check_recipe_def(def)
        -- return a list with all needed item_names (including in group)
        local function input_item_to_nameslist(recipe_items)
            local result={}
            for i, row in ipairs(recipe_items) do
                for j,r_item in ipairs(row) do
                    add_items_names(r_item, result)
                end
            end
            return result
        end

        local t = input_item_to_nameslist(def.items)
        for i, name in ipairs(t) do
            for j, second in ipairs(t) do
                if i~=j and name == second then
                    core.log (def.output.. "\'s recipe uses " .. name .. " twice")
                    return false
                end
            end
        end
        return true -- recipe is ok
    end

    -- have to wait for all modules load before generating list fo recipes per crafting type
    minetest.register_on_mods_loaded( function ()
        for _,recipe in ipairs(recipes_by_id) do
            -- doing it now else items in recipes are not registered...
            recipe.items = generate_items_table(recipe.items)
            recipe.tool = generate_item_details(recipe.tool)
            check_recipe_def(recipe)
            if type(recipe.type) == "string" then
                recipe.type = { recipe.type }
            end
            for _,station in ipairs(recipe.type) do
                local t = craft_types[station]
                if not t then
                    core.log("Unknown craft type: " .. station)
                else
                    table.insert(t.recipes, recipe)
                end
            end
        end
    end)
end

-- Testing and Crafting functions -------------------------------------------

-- test if item is fully available or not in item_hash
-- doesn't update the item
-- WARNING, tool should not also be used as ingredient, because else it could give false posive
-- TODO maybe copy item_ash to modify it
-- have = 0 if not present
-- returns have --, available (boolean)
local function test_item (it, item_hash)
    if not item_hash then
        core.log("in recipes.lua 'test_item' : item_hash is missing") -- #TODO better check
        return
    end
    local have = 0
    local gstats = it.gstats
    if not gstats then -- if not a group, just take the items
        have = item_hash[it.name] and item_hash[it.name].count or 0
    else -- else parse item_hash to find matching items
        for name, t in pairs(item_hash) do
            if t.groups and gstats:does_match(nil, t.groups) then
                have = have + t.count
            end
        end
    end

    return have --, (have >= it.need)
end

-- default function, can be overriden by it.take function is defined
-- return 1) number took of input_stack + 2) current have
-- have what I initially have (for loops ?)
item_funcs.test_item = test_item

-- Find maximum number of outputs we can craft from our inventory
-- TODO update to not use that weird item_hash format
-- TODO could be improved to also get to_take table ?
local find_max_craftable = function (recipe, item_hash)
    if not item_hash then
        error("in find_max_craftable for recipe "
        .. recipe.output
        .. ": item_hash is missing") -- #TODO better check
        return
    end

    -- final result
    local max_count
    -- (we will continue parsing even if "false" already to be able to get the recipe_state)
    local states = {}

    -- (we will continue parsing even if "false" already to be able to get the recipe_state)
    -- test tool
    if recipe.tool then
        states.tool = {}
        states.tool.have = test_item(recipe.tool, item_hash)
        if states.tool.have < recipe.tool.need then
            max_count = 0  -- no tool, no craft !
        end
    end

    states.items = {}
    -- check each row of input items
    for i, row in ipairs(recipe.items) do
        states.items[i] = {}
        local row_max = 0
        -- adds the max for each item in the or list
        --   for a combined max per row
        for j, it in ipairs(row) do
            local it_state = {}
            it_state.have = it:test_item(item_hash)
            if it_state.have >= it.need then
                it_state.max = math.floor(it_state.have/it.need)
                row_max = row_max + it_state.max
            else
                it_state.max  = 0
            end
            -- store state
            states.items[i][j] = it_state
        end


        -- if the row is non craftable
        if row_max == 0 then
            max_count = 0
        end

        -- if this row has less max_count than current total, adjus max to it
        -- can't have a count bigger then any input row.
        if not max_count or max_count > row_max then
            max_count = row_max
        end
        -- elseif previous max_count is inferior to that row, don't up
    end

    --[[ if not item table
        (like for sleeping spot, free craft)
        then I didn't parse and max_count was not affected
        -> put 1 as default]]
    if not max_count then
        max_count = 1
    end

    return max_count, states
end

recipe_funcs.find_max_craftable = find_max_craftable
