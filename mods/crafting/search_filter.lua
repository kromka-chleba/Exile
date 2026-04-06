-- SEARCH part (filter) --------------------------------------------------------

-- #TODO generate hash of all string matching with a recipe after registering at start

-- Returns true if the search string is in item's short description
-- `desc` is optional, will be generated from ItemStack(name) if missing
local function item_does_match (search, lang_code, name, desc)
    if not search then
        return true
    elseif type(search) ~= "string" then -- shouldn't happen
        core.log("search param is not a string in item_does_match")
        return true
    end
    if not name then
        core.log("no name to search for in search (item_does_match)")
        return
    end

    search = EXILE.make_search_string(search) -- already done in cache.sSearch

    -- in case "search" is exactly the output/item's name
    if name == search then
        return true
    end

    -- else check item's desc to compare with search
    desc = desc or ItemStack(name):get_short_description()
    -- do not use unknown Item to search
    -- could happen if called with name not being a real item name
    -- (fake output for example)
    if desc == "Unknown Item" then
        desc = nil
    end
    if desc then
        -- #TODO warning maybe not compatible with old clients
        local tr_desc =  core.get_translated_string(lang_code or "en", desc)
        -- search should have had  EXILE.make_search_string applied already
        if string.find(EXILE.make_search_string(tr_desc), search) then
            return true
        end
    else
        return false
    end
end

-- r_item is a table as generated in recipe_def.lua from recipe
local function r_item_does_match(r_item, search, lang_code)
    -- check if search string matches the name or desc
    -- WARNING in case of custome item, name will be "function"
    if item_does_match (search, lang_code, r_item.name, r_item.short) then
        return true
    end
    -- if item/group's name didn't match, check list of item variants
    local items = r_item:get_items_names()
    for _, item_name in ipairs(items) do
        if item_does_match (search, lang_code, item_name) then
            return true
        end
    end
end

-- testing if searched name is in this row
-- search is a string
-- row is a table of ItemStacks or groups
local function row_does_contain (row, search, lang_code)
    -- else, testing it one of the ingredient matchs the filter
    if type(row) ~= "table" then
        row = {row}
    end
    for _,item in pairs(row) do
        if r_item_does_match(item, search, lang_code) then
            return true
        end
    end
    -- if nothing was found return false
    return false
end

--[[ modify displayed setting of recipes in recipe_list
*`r` is a player_recipe
*`search` is a string
*`lang_code` is the language of the player
return true if search is nil or was found, false else
]]
local function apply_string_search(r, search, lang_code)
    local recipe = r.recipe
    if search == nil then
        return true
    end
    if type(search) ~= "string" then
        core.log("error", "search need to be a string")
        return
    end
    local result = false
    -- does the ouput of recipe match the filter ?
    if item_does_match (search, lang_code, recipe.output) then
        result = true
    -- else, does the tool match ?
    elseif recipe.tool
                and r_item_does_match (recipe.tool, search, lang_code) then
            result = true
    -- else, do any of the possible input items match ?
    else
        for recipe_row, rowItem in ipairs(recipe.items) do
            -- if any input matches the filter, display
            if row_does_contain (rowItem, search, lang_code) then
                result = true
                break
            end
        end
    end
    return result
end

--[[ modify displayed setting of recipes in recipe_list
*`p_recipe` is a player_recipe
*`search` is a string or a table of strings
*`lang_code` is the language of the player
*'combine' is an optional parameter :
    used in case of multiple criteria (if search is a table)
    - true means any of the string in the search table has to be found (OR)
    - false (default) means all of them has to match (AND)
    Return true is search was found, false else
    ]]
function crafting.get_search_result(p_recipe, search, lang_code, combine)
    -- if no search, do nothing
    if search == nil or (type(search) == "table" and #search == 0) then
        return true
    end

    local result = false
    -- if search is a table, proceed according to "combine" parameter
    if type(search) == "table" then
        for _,s in ipairs(search) do
            result = crafting.get_search_result(p_recipe, s, lang_code, combine)
            -- if result found is true and "OR" activated, we are all good
            if result and combine then
                break
            -- else if result is false and "AND" actived, false already
            elseif not result and not combine then
                break
            end
            -- else continue
        end
    -- if search is a single string, just search the string
    elseif type(search) == "string" then
        result = apply_string_search(p_recipe, search, lang_code)
    else
        core.log("error", "search parameter in crafting.apply_search should be a string or a table of string")
        return
    end

    return result
end
