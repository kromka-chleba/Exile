local crafting = crafting

--TYPES and RECIPES registrations and calls ------------------------------------

local recipes_by_id = {}
local recipes_by_output = {}

--[[register craft types (used for stations and tabs):
    *name : the name of the type
    *label : what will be displayed in game (tab) and translated
    *icon_item_name : for image tab
    *sound
]]
function crafting.register_type(name, label, icon_item_name, sound)
    crafting.recipes[name] = {}
    -- add a label for tabs - default to the name
    crafting.tab_labels[name] = (label or name)
    crafting.icon_item_name[name] = icon_item_name
    -- set up sound mechanism
    sound = type(sound) == "string" and {name = sound} or type(sound) == "table" and sound
    if sound and type(sound.name) == "string" then
        sound.max_hear_distance = sound.max_hear_distance or 10
        crafting.sounds[name] = sound
    end
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
        recipes_by_output[def.output]
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
    def.replace = type(def.replace) == "string" and {def.replace} or type(def.replace) == "table" and def.replace or nil
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
    recipes_by_output[def.output] = def
    recipes_by_id[def.id] = def
    return def.id
end

-- get recipe by ID or output, according to param type
function crafting.get_recipe(param)
    if type(param) == "number" then
        return recipes_by_id[param]
    elseif type(param) == "string" then
        return recipes_by_output[param]
    else
        core.log("wrong param type in crafting.get_recipe")
        return
    end
end

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

-- to check if no duplicates inputs, which currentldy would make craft do unwated things
local function check_recipe_def(def)
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
                local tab = crafting.recipes[station]
                assert(tab,        "Unknown craft type " .. station)
                tab[#tab + 1] = recipe
            end
        end
end)

-- LOCK/UNLOCK recipe per player -----------------------------------------------

local unlocked_cache = {}

function crafting.get_unlocked(name)
    local player = minetest.get_player_by_name(name)
    if not player then
        minetest.log(
            "warning",
            "Crafting doesn't support getting unlocks for offline players")
        return {}
    end

    local retval = unlocked_cache[name]
    if not retval then
        retval = minetest.parse_json(
            player:get_meta():get("crafting:unlocked") or "{}")
        unlocked_cache[name] = retval
    end

    assert(retval)

    return retval
end

if minetest then
    minetest.register_on_leaveplayer(function(player)
            unlocked_cache[player:get_player_name()] = nil
    end)
end

local function write_json_dictionary(value)
    if next(value) then
        return minetest.write_json(value)
    else
        return "{}"
    end
end

function crafting.lock_all(name)
    local player = minetest.get_player_by_name(name)
    if not player then
        minetest.log(
            "warning",
            "Crafting doesn't support setting unlocks for offline players")
        return {}
    end

    local unlocked = crafting.get_unlocked(name)

    for key, _ in pairs(unlocked) do
        unlocked[key] = nil
    end

    unlocked_cache[name] = unlocked

    player:get_meta():set_string("crafting:unlocked",
                                 write_json_dictionary(unlocked))
end

function crafting.unlock(name, output)
    local player = minetest.get_player_by_name(name)
    if not player then
        minetest.log(
            "warning",
            "Crafting doesn't support setting unlocks for offline players")
        return {}
    end

    local unlocked = crafting.get_unlocked(name)

    if type(output) == "table" then
        for i=1, #output do
            unlocked[output[i]] = true
            minetest.chat_send_player(name, "You've unlocked " .. output[i])
        end
    else
        unlocked[output] = true
        minetest.chat_send_player(name, "You've unlocked " .. output)
    end

    unlocked_cache[name] = unlocked
    player:get_meta():set_string("crafting:unlocked",
                                 write_json_dictionary(unlocked))
end
