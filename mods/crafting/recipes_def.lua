--CRAFT TYPES and RECIPES registrations and calls ------------------------------
--------------------------------------------------------------------------------

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
    * `replace`      - to deal with replacement
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

    def.id = #crafting.recipes_by_id + 1
    crafting.recipes_by_output[def.output] = def
    crafting.recipes_by_id[def.id] = def
    return def.id
end

-- have to wait for all modules load before generating
-- station lists
minetest.register_on_mods_loaded( function ()
        for _,recipe in ipairs(crafting.recipes_by_id) do
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

function crafting.get_recipe(id)
    return crafting.recipes_by_id[id]
end
