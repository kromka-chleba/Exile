local crafting = crafting

--TYPES and RECIPES registrations and calls ------------------------------------
--------------------------------------------------------------------------------

--array of all registered recipes, by `id`
local recipes_by_id = {}

function crafting.get_recipes()
    return recipes_by_id
end

-- get recipe by ID, according to param type
function crafting.get_recipe(id)
    if type(id) == "number" then
        return recipes_by_id[id]
    else
        core.log("wrong param type in crafting.get_recipe, number expected, got" .. type(id))
        return
    end
end

--[[table of crafting types with follwing format :
    * [name] as index
    * following fields :
        * `label`     - label to display, is `name` if label not provided
        * `icon`      - icon to disply in tab
        * `recipes`   - table of possible recipes for that crafting type
        * `sound`
    ]]
local craft_types = {}

-- get type table for that `name`
function crafting.get_type(name)
    return craft_types[name]
end

-- get recipes table for that crafting type
function crafting.get_recipes_by_type(type)
    local tab = craft_types[type]
    if not tab then
        core.log (type .. " is not a valid registered type")
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
end

--[[register recipe using `def` table with following fields:
    * `id`           - ID of recipe, in order of registration'
    * `type`         - one of the registered types.
    * `output`       - the result of the craft, eg: `default:stone 3`.
    * `items`        - A list of ingredients, eg: `{"stone", "wood 3"}`.
    * `level`        - level of station required.
    * `always_known` - If true, this recipe will never need to be unlocked.
    * `replace`
    * `sound`
    * `_display`     - string of image to display in recipe panel
    Register def in
        recipes_by_id[def.id]
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
    def.items = type(def.items) == 'string' and {def.items} or def.items
    if type(def.items) ~= "table" then
        recipe_error("expected string or table for 'items', got '"..type(def.items).."'")
    end
    -- convert into table to iterate through or remove if invalid
    if def.replace then
        if type(def.replace) == "string" then
            def.replace= {def.replace}
        elseif type(def.replace) == "function" then
            def.replace = def.replace()
        elseif type(def.replace) ~= "table" then
            recipe_error("field 'replace' doesn't have correct format")
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
    if minetest.registered_tools[o_name] then
        if def.no_max ~= false then
            def.no_max = true
        end
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

    recipes_by_id[def.id] = def
    return def.id
end

--[[ check if no duplicates inputs, which currentldy would make craft do unwanted things
run after mods loaded
]]
local function check_recipe_def(def)
    -- return a list with all needed item_names (including in group)
    local function input_item_to_nameslist(recipe_input)
        local function add_name(item, list)
            local itemName = ItemStack(item):get_name()
            local group_stats = crafting.get_group_stats(itemName)
            if group_stats then
                for _,it in ipairs(crafting.get_group_items(group_stats.name)) do
                    table.insert(list, ItemStack(it):get_name())
                end
            else
                table.insert(list, itemName)
            end
        end
        local result={}
        for i, itema in ipairs(recipe_input) do
            if type(itema)=="table" then
                for j,itemb in ipairs(itema) do
                    add_name(itemb, result)
                end
            else
                add_name(itema, result)
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

-- have to wait for all modules load before generating station lists
minetest.register_on_mods_loaded( function ()
        for _,recipe in ipairs(recipes_by_id) do
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
