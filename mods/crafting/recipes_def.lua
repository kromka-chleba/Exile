
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
    new_type.icon_item_name = icon_item_name
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

-- array of all registered recipes, by `id`
local recipes_by_id = {}

-- returns an array of all registered recipes where the indices match the
-- ids of the recipes
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
* Returns `item_details` - a table with
    * index : item's name
    * value : a list with those parameters :
        * `name` = name of the item
        * `gstats` = groups stats if item is a group, nil else
        * `description` = description of the item
        * `short` = description of the item to be displayed in recipe panel
        * `need` = the number we need for the recipe
This will be used to display custom infotext on recipe panel
]]
local function generate_item_details(input_item)
    local item_details
    -- if item is a function, use that one to generate
    if type(input_item) == "function" then
        -- custom table generation
        item_details = input_item()
    -- else if no input_item or type is not string
    -- (maybe format is alread transdormed if the caller used the same item table for many recipes)
    elseif type(input_item) ~= "string"  then
        return nil
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
            need = stack:get_count()
        }
    end
    -- adds item_functs dedicated default functions
    setmetatable(item_details, item_funcs)
    return item_details
end

--[[ Returns how many ItemStacks matches with `it` in `item_hash`
    * doesn't update the item
    * returns 0 if none present]]
--[[WARNING, tool should not be also used as ingredient, because else it could give false posive.
For that, TODO maybe copy item_hash to modify it]]

-- returns have --, available (boolean)]]
-- TODO (not sure yet if I keep sending the second info or not)
local function get_have (it, item_hash)
    if not item_hash then
        core.log("in recipes.lua 'get_have' : item_hash is missing") -- #TODO better check
        return
    end
    local have = 0
    local gstats = it.gstats
    -- if it is not a group, just count the number of it I have in item_hash
    if not gstats then
        have = item_hash[it.name] and item_hash[it.name].count or 0
    -- else parse item_hash to find matching items with it group
    else
        for name, t in pairs(item_hash) do
            if t.groups and gstats:does_match(nil, t.groups) then
                have = have + t.count
            end
        end
    end
    return have --, (have >= it.need)
end

-- TODO returns to_pick (can be weight in custom recipe) for it in this stack
local function match (it, stack_name)
    local gstats = it.gstats
    -- if it is not a group, just count the number of it I have in item_hash
    if not gstats then
        return (it.name == stack_name)
    -- else parse item_hash to find matching items with it group
    else
        return gstats:does_match(stack_name)
    end
end

item_funcs.match = match

--unused
item_funcs.take = function(it, input_stack, still_needed)
    -- if stack matches the item's conditions
    if it:match(input_stack:get_name()) then
        local found = ItemStack(input_stack)
        if found:get_count() > still_needed then
            found:set_count(still_needed)
        end
        -- return found ItemStack and still_needed
        return found, still_needed - found:get_count()
    end
end

-- default function, can be overriden by it.take function is defined
-- return 1) number took of input_stack + 2) current have
-- have what I initially have (for loops ?)
item_funcs.get_have = get_have

-- get max of this item we can craft
-- returns state table {have= ..., max = ...}
local function get_state(it, item_hash)
    if not item_hash then
        core.log("in recipes.lua 'get_have' : item_hash is missing") -- #TODO better check
        return
    end
    local it_state = {}
    it_state.have = it:get_have(item_hash)
    if it_state.have >= it.need then
        it_state.max = math.floor(it_state.have/it.need)
    else
        it_state.max  = 0
    end
    return it_state
end

item_funcs.get_state = get_state


--[[ Returns a list of all item names matching this input
    * find every variant (item name) of a recipe item, including groups
    * `existing_list is optional, if provided, item names will be added to it`
]]--
local function get_items_names(r_item, existing_list)
    existing_list = existing_list or {}
    local group_stats = r_item.gstats
    if group_stats then
        -- get items matching group name, or item matching unit if nothing in name
        -- (case of group:/pot for example)
        local t = crafting.get_group_items(group_stats.name)
                or crafting.get_group_items(group_stats.unit)
        if not t then
            core.log("no items defined for group: " .. group_stats.tag )
        else
            for _,it in ipairs(t) do
                if group_stats:does_match(it) then
                    table.insert(existing_list, it)
                end
            end
        end
    else
        table.insert(existing_list, r_item.name)
    end
    return existing_list
end

item_funcs.get_items_names = get_items_names

-- recipe class --

local recipe_funcs = {}
recipe_funcs.__index = recipe_funcs

-- returns input items in a unified format: list of lists of alternatives
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
    * `tool`         - An item used as tool (not consumed)
                       eg: `"nodes__nature:sand"`.
                       WARNING: we curently can use only one tool
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
    if type(def.always_known) ~= "boolean" then
        def.always_known = true
    end
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
    if type(def.sound) == "string" then
        def.sound = {name = def.sound}
    end
    -- if invalid sound, remove
    -- permits "false" to prevent playing of crafting station sound
    if type(def.sound) ~= "table" and def.sound ~= false then
        def.sound = nil
    end

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

-- Check of recipe validity and generationg of item and tool table
 ----------------------------------------------------------------------

--[[ checks for duplicate inputs, which currently would make craft do unwanted
things; runs after mods loaded
pre: group_tables in groups.lua initialized
]]
-- TODO improve/check with units/complex grouptag
local function check_recipe_def(def)
    -- return a list with all needed item_names (including in group)
    local function input_item_to_nameslist(recipe_items)
        local result={}
        for i, row in ipairs(recipe_items) do
            for j,r_item in ipairs(row) do
                get_items_names(r_item, result)
            end
        end
        return result
    end

    local t = input_item_to_nameslist(def.items)
    for i, name in ipairs(t) do
        for j, second in ipairs(t) do
            -- if j <= i we already tested it
            if i<j and name == second then
                core.log (def.output.. "\'s recipe uses " .. name .. " twice")
                return false
            end
        end
    end
    return true -- recipe is ok
end

-- Fully initialize all recipes in recipes_by_id, i.e. replace 'items' and
-- 'tool' by more detailed tables for crafting, then check for any cases of
-- the same input item being required twice in the same recipe, e.g.
--    1) explicitly and
--    2) as a member of a group.
-- Also sets up the recipe lists for all craft types, see 'craft_types'.
-- pre: Has to wait until all modules are loaded before generating lists of
-- recipes per craft type.
-- costs: takes about 20ms @3GHz
minetest.register_on_mods_loaded( function ()
    for _,recipe in ipairs(recipes_by_id) do
        -- doing it now else items in recipes are not registered...
        recipe.items = generate_items_table(recipe.items)
        recipe.tool = generate_item_details(recipe.tool)
        check_recipe_def(recipe)
        if type(recipe.type) == "string" then
            recipe.type = { recipe.type }
        end
        -- add recipe to recipe lists of all valid 'craft types'
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


-- Testing and Crafting functions -------------------------------------------

-- Find maximum number of times we can craft that recipe with what it in tiem_hash provided
-- TODO update to not use that weird item_hash format
-- TODO could be improved to also get to_take table ?
recipe_funcs.find_max_craftable = function(recipe, item_hash)
    if not item_hash then
        core.log("in find_max_craftable for recipe ".. recipe.output
        .. ": item_hash is missing")
        return 0 --#TODO or nil to trhow errors ?
    end

    -- final results
    local max_count -- max time we can craft the recipe
    -- (we will continue parsing even if "false" already to be able to get the recipe_state)
    local states = {} -- recipe state

    -- (we will continue parsing even if "false" already to be able to get the recipe_state)
    -- test tool
    if recipe.tool then
        states.tool = {}
        states.tool.have = get_have(recipe.tool, item_hash)
        if states.tool.have < recipe.tool.need then
            max_count = 0  -- no tool, no craft !
        end
    end

    states.items = {} -- stores the have/max state of items
    -- check each row of input items
    for i, row in ipairs(recipe.items) do
        states.items[i] = {}
        local row_max = 0
        -- adds the max for each item in the or list
        --   for a combined max per row
        for j, it in ipairs(row) do
            local it_state = get_state(it, item_hash)
            row_max = row_max + it_state.max
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

    --[[ if not item table (like for sleeping spot, free craft)
        then I didn't parse and max_count was not affected
        -> put 1 as default]]
    if not max_count then
        max_count = 1
    end

    return max_count, states
end
