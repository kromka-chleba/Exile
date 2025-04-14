-- SEARCH part (filter) --------------------------------------------------------

-- #TODO generate hash of all string matching with a recipe after registering at start

-- Returns true if the search string is in item's short description
local function item_does_match (item, search, lang_code)
    if not search then
        return true
    elseif type(search) ~= "string" then -- shouldn't happen
        core.log("search param is not a string")
        return true
    end
    local name = item.name or ItemStack(item):get_name()
    local desc = item.short or ItemStack(item):get_short_description()
    -- used for the case of check with items name in inv
    if name and name == search then
        return true
    elseif desc then
        -- #TODO warning maybe not compatible wiht old clients
        local tr_desc =  core.get_translated_string(lang_code or "en", desc)
        -- search should have had  minimal.make_search_string applied already
        if string.find(minimal.make_search_string(tr_desc), minimal.make_search_string(search)) then
            return true
        end
    else
        return false
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
        -- if single item or group check short desc
        if item_does_match (item, search, lang_code) then
            return true
        end
        --[[ if item/group didn't match, and it is a group,
        check items of the group]]
        local gstats = crafting.get_group_stats(item.name)
        --#TODO maybe create at loading time a table of items for each recipe
        if gstats then
            local g_items = crafting.get_group_items(gstats.name)
            for _, item_name in ipairs(g_items) do
                if item_does_match (item_name,search, lang_code) then
                    return true
                end
            end
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
    if search == nil then
        return true
    end
    if type(search) ~= "string" then
        core.log("error", "search need to be a string")
        return
    end
    local result = false
    if item_does_match (r.recipe.output, search, lang_code) then
        result = true
    else
        for recipe_row, rowItem in ipairs(r.it_details) do
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
