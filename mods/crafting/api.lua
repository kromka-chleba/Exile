-- Crafting Mod - semi-realistic crafting in minetest
-- Copyright (C) 2018 rubenwardy <rw@rubenwardy.com>
--
-- This library is free software; you can redistribute it and/or
-- modify it under the terms of the GNU Lesser General Public
-- License as published by the Free Software Foundation; either
-- version 2.1 of the License, or (at your option) any later version.
--
-- This library is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
-- Lesser General Public License for more details.
--
-- You should have received a copy of the GNU Lesser General Public
-- License along with this library; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA


-- Warning: this is a circular dependency; minimal depends on crafting, too
--minimal = minimal

crafting = {
    recipes = {},
    tab_labels = {},
    recipes_by_id = {},
    recipes_by_output = {},
    registered_on_crafts = {},
    item_by_group = {}, -- hash group:groupname to an item name.
    -- only last inventory item from group is stored.
    sort_order_by_player = {},
    -- hash of recipe id to display order in sorted array
    icon_item_name = {},
    -- hash of node identifiers to display the crafting type in the interface
}

local S = minetest.get_translator("crafting")

-- list og items by crafing group
local groups_table = {}

-- generate list of items by groups
-- to be called in minetest.register_on_mods_loaded
local function sort_by_group()
    for name, itemdef in pairs(minetest.registered_items) do
        for group_name, value in pairs(itemdef.groups) do
            if value >= 1 then
                if not groups_table[group_name] then
                    groups_table[group_name] = {name}
                else
                    table.insert(groups_table[group_name], name)
                end
            end
        end
    end
end

-- Group names from recipes for the translation script
-- The translation will be performed when descriptions are generated
-- Note : cobble's group could be passed as nodes_nature:xxx-cobble1
--   item instead of group since we only can drop cobble1 type
-- #TODO do we need it this we translation group desc in gstat ?
local groupNameForTranslations = {
    S("log"), S("fibrous plant"), S("sand"), S("compostable"),
    S("hard wood"), S("cana"), S("woody plant"), S("woodslab"),
    S("bioluminescent"),  S("pottery"),
    S("gravel"),  S("bundleable fiber"),
    S("limestone cobble"), S("basalt cobble"), S("granite cobble"),
    S("ironstone cobble"), S("jade cobble")
}

function crafting.register_type(name, label, icon_item_name)
    crafting.recipes[name] = {}
    -- add a label for tabs - default to the name
    crafting.tab_labels[name] = (label or name)
    crafting.icon_item_name[name] = icon_item_name
end

function crafting.register_recipe(def)
    -- multiple output items unsupported due to minimal/interface/inventory.lua
    -- limitations, do replace instead
    assert(type(def.output) == "string",
           "Output needed in recipe definition (string only)")
    assert(def.type,   "Type needed in recipe definition")
    assert(def.items,  "Items needed in recipe definition")

    def.level = def.level or 1
    -- Can be more then one craft station for a recipe
    -- Need to store as a table.
    if type(def.type) == 'string' then
        def.type = { def.type }
    end
    -- convert into table to iterate through
    if type(def.replace) ~= "table" then
        def.replace = {def.replace}
    end
    def.id = #crafting.recipes_by_id + 1
    crafting.recipes_by_output[def.output] = def
    crafting.recipes_by_id[def.id] = def
    return def.id
end

-- have to wait for all modules load before generating
-- station lists
minetest.register_on_mods_loaded( function ()
        sort_by_group()
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

function crafting.get_recipe(id)
    return crafting.recipes_by_id[id]
end

-- returns table of details relating to information/parameters noted in a string

-- permits format of:
-- group:<groupname>,<groupnumcondition>,<desc>
-- groupname being the group that is necessary
-- groupnumcondition is the required group's number (3,8) or condition (>2 or <6)
-- desc being a custom description (recipe-local)
--  for what the group should be called
-- custom 'correct' function allows one to determine groupnumcondition
--  values that have a condition
-- following can become indexes of 'stats':
--  'name', 'tag', 'num' (number), 'num_cmd', 'desc', 'correct' (function)
-- num and num_cmd will NOT always be valid indexes

function crafting.get_group_stats(grouptag)
    -- string must contain "group:" or will return nil
    grouptag = (type(grouptag) == "string" and grouptag:sub(1,6) == "group:")
        and grouptag or nil
    if not grouptag then return end
    --grouptag = grouptag:sub(7,#grouptag) -- remove 'group:'
    local str_len = #grouptag
    local stats = {} -- table of "stats" to return
    -- has parameters to check through
    if string.match(grouptag,",") then
        local reader = 7 -- start at 7th character, after "group:"
        while true do -- use while loop for custom iterator addition+remove
            if reader >= str_len then break end -- stop if we're over string length
            local read_char = grouptag:sub(reader,reader)
            if read_char == "," then -- found parameter
                if not stats.tag then -- create stats.tag
                    stats.tag = grouptag:sub(1,reader-1)
                end
                reader=reader+1 -- skip ahead to read char after parameter separator
                if not stats.num then -- assume 1st parameter is custom group num
                    stats.num = ""
                    -- add to stats num value with found characters until end
                    for i=reader,str_len do
                        read_char = grouptag:sub(i,i)
                        if read_char == "," then
                            break -- found end via new parameter line, end
                        end
                        stats.num = stats.num..read_char
                    end
                    reader=reader+(#stats.num)-1 -- subtract 1 to get parameter lines properly
                elseif not stats.desc then
                    -- assume 2nd parameter is custom description
                    stats.desc = ""
                    for i=reader,str_len do
                        read_char = grouptag:sub(i,i)
                        if read_char == "," then break end
                        stats.desc = stats.desc..read_char
                    end
                    reader=reader+(#stats.desc)-1
                else -- no more commands to do, end iteration
                    break
                end
            end
            reader=reader+1 -- gradually increase to iterate through string
        end
    end
    -- if no stats.tag set by parameter line then assume normal
    if not stats.tag then
        stats.tag = grouptag
    end
    -- sterilize of itemstack parameters
    if stats.tag:match(" ") then
        for i=7,#stats.tag do -- start at 7th char
            if stats.tag:sub(i,i) == " " then -- found it, get only the tag from it
                stats.tag = stats.tag:sub(1,i-1)
            end
        end
    end
    -- set up group name
    stats.name = stats.tag:sub(7,#stats.tag)
    -- revert to name
    if not stats.desc then
        -- Add a translation of the group name
        stats.desc = S(stats.name:gsub("%_", " ") or "")
    end
    -- remove nil indexes
    for stat,val in pairs(stats) do
        if val == "" or val:lower() == "nil" then
            stats[stat] = nil
        end
    end
    -- separate num and condition command
    if stats.num then
        local num = tonumber(stats.num) -- if nil then needs to separate
        if not num then -- separating
            stats.num_cmd = stats.num:sub(1,1) -- command at beginning
            num = tonumber(stats.num:sub(2,#stats.num))
        end
        if not num then -- you did a command too long likely
            -- (should only be 1 char) or placed the command after the number
            error("crafting.get_group_stats: could not properly assess "..
                  "'num' parameter for grouptag: "..stats.grouptag)
        end
        stats.num = num
    end
    -- add "correct" function to determine whether or not the
    --  group-based item can be used for crafting
    stats.correct = function(amount)
        local num = stats.num
        if not num then return true end -- no stats.num value, can be crafted
        local cmd = stats.num_cmd
        if num == amount and not cmd then
            return true -- no "cmd", can be crafted
        end
        -- calculate cmd
        if cmd == "<" and amount < num then
            return true
        elseif cmd == ">" and amount > num then
            return true
        end
        return false
    end
    return stats
end

function crafting.peek_item(item_list, item_hash)
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
            available = (have >= need) and true or false,
            description = def.description,
            short = def._orig_desc,
        }
    end
    return items
end

local function get_real_name(name)
    if name:sub(1, 6) == "group:" then
        return crafting.item_by_group[name]
    end
    return name
end

-- Returns true if the search string is in item's short description
-- accept string or ItemStack

-- TODO not working, desc is not good
-- also is maybe called for too many recipes
local function item_does_match (item,search, lang_code)
    if not search then
        return true
    elseif type(search) ~= "string" then -- should happend
        minetest.log("not a string")
        return true
    else
        local item = ItemStack(item)
        local test = item:get_short_description()
        -- #TODO warning maybe not compatible wiht old clients
        local desc =  minetest.get_translated_string(lang_code or "en", item:get_short_description())
        -- search should have had  minimal.make_search_string applied already
        if string.find( minimal.make_search_string(desc), search) then
            return true
        else
            return false
        end
    end
end

-- #TODO generate hash of all string matching with a recipe after registering at start

-- testing if searched name is in this row
-- search is a string
-- row is a table of ItemStacks or groups
local function row_does_contain (row, search, lang_code)
    -- else, testing it one of the ingredient matchs the filter
    if type(row) ~= "table" then
        row = {row}
    end
    for _,item in pairs(row) do
        local gstats = crafting.get_group_stats(item)
        -- if this is a groupe, get item names in it
        if gstats then
            local g_name = gstats.name
            for _, item_name in ipairs(groups_table[g_name]) do
                if item_does_match (item_name,search, lang_code) then
                    return true
                end
            end
        -- if this is a single item
        else
            local item = ItemStack(item) -- #TODO not sure it is usefull            
            if item_does_match (item,search, lang_code) then
                return true
            end
        end
    end
    return false
end

-- get all possible recipes to display
function crafting.get_all(ctype, level, item_hash, unlocked, search, lang_code)
    assert(crafting.recipes[ctype], "No such craft type!")
    assert(not search or type(search) == "string", "search need to be a string")
    local results = {}
    for _, recipe in pairs(crafting.recipes[ctype]) do
        local craftable = true
        local displayed = (not search) -- true if no search, false else
        if recipe.level <= level and (recipe.always_known
                                      or unlocked[recipe.output]) then
            -- display if output matchs search
            if item_does_match (recipe.output,search, lang_code) then
                 displayed = true
            end

            local items = {}
            -- Check what ingredients are available
            for recipe_row, rowItem in ipairs(recipe.items) do
                local rItems = {} -- row items
                local pickable = false
                -- display if any input matchs search)
                if row_does_contain (rowItem, search, lang_code) then
                    displayed = true
                end
                for i,item in ipairs(crafting.peek_item(rowItem, item_hash)) do
                    rItems[#rItems+1] = item
                    if item.available then
                        pickable = true -- at least one item is available
                    end
                end
                items[recipe_row]=rItems -- save items by recipe input row
                if not pickable then
                    craftable = false
                    -- don't have any of the needed ingredients from this row.
                end
            end
            -- check if we have a where clause only if its craftable
            if craftable and recipe.where then
                craftable = false -- assume this failes unless we find a match.
                -- recipe.where should look something like this:
                --   @1.material == @2.material
                --   @x where x is the input item row number
                local lParam, lKey, test, rParam, rKey =
                    string.match(
                        recipe.where, "@(%d+)%.(%w+)%s*(.-)%s*@(%d+)%.(%w+)$")
                for _,left in ipairs( items[tonumber(lParam)] ) do
                    local lName = get_real_name(left.name)
                    if left.available then
                        for _,right in ipairs(items[tonumber(rParam)]) do
                            local rName = get_real_name(right.name)
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
            end
            -- add recipe to list only if it matchs search
            if displayed then
                results[#results + 1] = {
                    recipe    = recipe,
                    items     = items,
                    craftable = craftable,
                }                
            end
        end
    end

    return results
end


function crafting.set_item_hashes_from_list(inv, listname, item_hash)
    for _, stack in pairs(inv:get_list(listname)) do
        if not stack:is_empty() then
            local itemname = stack:get_name()
            item_hash[itemname] = (item_hash[itemname] or 0) + stack:get_count()
            local def = minetest.registered_items[itemname]
            if def and def.groups then
                for groupname,groupvalue in pairs(def.groups) do
                    local group = "group:" .. groupname
                    crafting.item_by_group[group] = itemname
                    item_hash[group] = (item_hash[group] or 0) + stack:get_count()
                    -- alternative for pickier crafts (adds preferred number)
                    item_hash[group..groupvalue] =
                        (item_hash[group..groupvalue] or 0) + stack:get_count()
                end
            end
        end
    end
end

function crafting.get_all_for_player(player, ctype, level, search)
    local pname = player:get_player_name()
    local unlocked = crafting.get_unlocked(pname)
    -- build player items hash
    local item_hash = {}
    -- reset group hash
    crafting.item_by_group = {}
    crafting.set_item_hashes_from_list(player:get_inventory(), "main", item_hash)
    -- Get all available recipies and mark craftible ones.
    local lang_code = minetest.get_player_information(pname).lang_code
    local results =  crafting.get_all(ctype, level, item_hash, unlocked, search, lang_code)
    return results
end

function crafting.can_craft(name, ctype, level, recipe)
    local unlocked = crafting.get_unlocked(name)
    if type(ctype) == 'string' then
        ctype = { ctype }
    end
    local rtypes = recipe.type
    if type(recipe.type) == 'string' then
        rtypes = { recipe.type }
    end
    for _,station in ipairs(ctype) do
        for _,rec_type in ipairs(rtypes) do
            if rec_type == station and recipe.level <= level and
                (recipe.always_known or unlocked[recipe.output]) then
                return true
            end
        end
    end
    return false
end

local function give_all_to_player(inv, list)
    for _, item in pairs(list) do
        inv:add_item("main", item)
    end
end


function crafting.parse_where(recipe, items, item_idx, num_added)
    if recipe.where or type(recipe.where) ~= 'string' then
        return nil
    end
    local result = recipe.where_results or recipe.where

    -- @1.material == @2.material
    --   local input1,key1,test,input2,key2 =
    --print("where: "..recipe.where)
    --print(dump( string.match(recipe.where, "@(%d+)%.(%w+)%s*(.*)%s*@(%d+)%.(%w+)$") ))
end

-- not in original mod
--[[ Search inventory list given to find the required item
    stop when required quantity is found
    return a table of items to pick per list :
    {[list1] = {stack1, stack2, ...}, [list2] = {stack1, stack2}, ...}
    return nil if not found/not enough ]]
-- currently only used in local
function crafting.pick_required_item(inv, lists, item)
    local picked_table ={}
    item = ItemStack(item)
    local itemName = item:get_name()
    --print("Attempting to pick ",itemName)
    local group_stats = crafting.get_group_stats(itemName)
    local required = item:get_count()
    -- pars list my order of priority
    for _, list in ipairs(lists) do
        -- search stacks in provided inv lists
        for i = 1, inv:get_size(list) do
            local stack = inv:get_stack(list, i)
            --print("Checking ",stack:get_name()," ",stack:get_count())
            local def = minetest.registered_items[stack:get_name()]
            local found, group
            if group_stats then -- Is it in group?
                group = def and def.groups and def.groups[group_stats.name]
            end
            if required > 0 and ( group and group_stats.correct(group)
                                  or stack:get_name() == item:get_name() )then
                found = ItemStack(stack)
            end
            if found then
                if found:get_count() > required then
                    found:set_count(required)
                end
                -- add itemstack to the ones to take from that list
                if picked_table [list] then
                    table.insert(picked_table[list], found)
                else
                    picked_table [list] = {found}
                end
                required = required - found:get_count()
            end
            -- if I don't need more, stop parsing the list
            if required <= 0 then
                break
            end
        end
        -- if I don't need more, stop parsing the lists
        if required <= 0 then
            break
        end
    end
    -- if I couldn't find enough, return nil
    if required > 0 then
        return nil
    else
        return picked_table
    end
end

-- Choose items to take from inv in case of conditional list
local function pick_alternate_items(inv, listname, item)
    if (type(item) == 'table') then
        -- create intermediate pick table of possible choices
        local temp_p_t = {}
        -- find conItem in lists and put the result in pick_table[j]
        for _, conItem in ipairs(item) do
            local pri = crafting.pick_required_item(inv, listname,
            conItem)
            if pri then
                --[[ optionnal shortcut :
                if the first item has items in the first inv list,
                stop and take that one]]
                if pri [listname[1]] then
                    return pri
                else
                    table.insert(temp_p_t, pri)
                end
            end
        end
        --[[if no one was in the first list, choose the one to pick:
        take the 1st one who had some item in higher priority list]]
        if next(temp_p_t) then
            for i, source in ipairs(listname) do
                for _, pt in ipairs(temp_p_t) do
                    if pt[source] then
                        return pt
                    end
                end
            end
        end
        -- if none was found
        return nil
    else
        return crafting.pick_required_item(inv, listname, item)
    end
end

--[[ in external mod :
    Returns a list of stacks to take, or nil if the required items could not
    be found.

    Modified for Exile to deal with table in listname
    where items are taken from inventories in order passed
    Returns a list of what was found per list

    {[list1] = {stack1, stack2, ...}, [list2] = {stack1, stack2}, ...}

    To keep compatibility with external mod,
    Returns a list of stack if listname only had one element.

    Returns nil if not found or not enought for recipe
]]
function crafting.find_required_items(inv, listname, recipe)
    if not listname then
        return nil
    end
    -- added to deal with multple input lists but keep compatibility
    if type(listname) ~= 'table' then
        listname = { listname }
    end
    -- to store found items
    local found_table = {}
    -- initiate ound_table
    for i, list in ipairs(listname) do
        found_table[list]={}
    end
    --print("Recipe Items: "..dump(recipe.items))
    for i, item in ipairs(recipe.items) do
        -- Conditional input list to process
        local pick_table = pick_alternate_items(inv, listname, item)
        -- if this part is found, add it to found_table
        if pick_table then
            for list, picked_litems in pairs (pick_table) do
                for _,picked_stack in pairs(picked_litems) do
                    table.insert(found_table[list],picked_stack)
                end
            end
        -- if this part is not found, stop
        else
            return nil
        end
    end

    -- Return found list
    if #listname == 1 then
        --if we had only one list, return only a list of stack to keep mod compatibility
        return found_table[listname[1]]
    else
        return found_table
    end
end

function crafting.has_required_items(inv, listname, recipe)
    return crafting.find_required_items(inv, listname, recipe) ~= nil
end

function crafting.register_on_craft(func)
    table.insert(crafting.registered_on_crafts, func)
end

--[[ In external mod
* Will try to take itemsfrom `listname` and put output in the `outlistname` list in `inv`.
* Returns true on success.
]]
function crafting.perform_craft(name, inv, listname, outlistname, recipe)
    -- get list of items required for the recipe (if found)
    local founditems = crafting.find_required_items(inv, listname, recipe)
    if not founditems then
        return false
    end

    --[[ updated to allow passing of a table of listnames
    -- items are taken from inventories in order passed
    -- this converts old use of this function to new use]]
    if type(listname) ~= 'table' then
        founditems = {[listname] = founditems}
    end

    -- Take items from inventory
    local taken = {}

    for source, items in pairs(founditems) do
        for _,item in pairs(items) do
            local took = inv:remove_item(source, item)
            if took:get_count() > 0 then
                taken[#taken + 1] = took
            end
        end
    end

    for i=1, #crafting.registered_on_crafts do
        crafting.registered_on_crafts[i](name, recipe)
    end
    -- create item
    local material
    if recipe.material then
        local material_def = ItemStack(taken[recipe.material]):get_definition()
        material = material_def.exile_crafting
        and material_def.exile_crafting.material
        if not material then -- issue #814
            error("crafting.perform_craft: missing exile_crafting or "
            .."exile_crafting.material but got material '"
            ..tostring(recipe.material).."' known as in taken: '"
            ..tostring(taken[recipe.material]).."' from '"
            ..material_def.name..";;"..material_def.description
            .."' to craft '"..recipe.output
            .."'. Crafting commenced by "..tostring(name))
        end
    end


    local make_output = recipe.output
    if recipe.material_output then
        make_output = string.gsub(recipe.material_output,
        "%%material%%", material)
    end
    local itemstack = ItemStack(make_output)
    local imeta = itemstack:get_meta()
    local idef = itemstack:get_definition()
    local sdesc = itemstack:get_short_description()
    -- Set Creator
    if minetest.get_item_group(itemstack:get_name(), 'craftedby') > 0 then
        imeta:set_string('creator', name)
        -- don't add creator name to sort description for single player
        if not minetest.is_singleplayer() then
            sdesc = name .. "'s " .. sdesc
        end
        imeta:set_string('short_description', sdesc)
    end

    -- set material
    if material then
        imeta:set_string('material', material)
        if recipe.tiles_name then
            local image = string.gsub(recipe.tiles_name, '%%material%%', material)
            imeta:set_string('inventory_tiles', image)
        end
        if recipe.real_name then
            local image = string.gsub(recipe.tiles_name, '%%material%%', material)
            imeta:set_string('inventory_tiles', image)
        end

    end

    -- Add Tool Tips to Description

    if idef._tool_tips and idef._tool_tips ~= '' then
        --imeta:set_string('description',sdesc .. idef._tool_tips)

    end
    local items_to_add = {}
    local count = itemstack:get_count()
    -- fix for tools not being added properly
    -- (have to manually get the count from the string...)
    if minetest.registered_tools[itemstack:get_name()]
    and string.match(make_output," ") then
        local toolcount = make_output:sub(#itemstack:get_name()+1,
        #make_output):gsub(" ", "" )
        count = ""
        for i=1,#toolcount do
            local char = toolcount:sub(i,i) -- individual char
            if #count > 0 and not tonumber(char) then
                -- we already got a number, we're going too far!
                break
            elseif tonumber(char) then
                count = count..char -- add more numbers
            end
        end
        -- get itemstack count just incase, don't want nil!
        count = tonumber(count) or itemstack:get_count()
    end
    local max_amt = itemstack:get_stack_max() -- use stack's size for iterating
    local subtract_loop = math.ceil(count / max_amt)
    -- crafted stack size divided by its stack max then ceil'd
    -- (so a stack max and a half will not be 1.5 but rather 2)
    for _ = 1, subtract_loop do
        local item = ItemStack(itemstack) -- clone locally
        if count > max_amt then
            item:set_count(max_amt) -- set stack to max
            count = count - max_amt -- lower count by stack max
        else
            item:set_count(count)
        end
        if count > 0 then -- just in case something goes wrong and
            --  an itemstack below or equal to 0 in count is made
            items_to_add[#items_to_add + 1] = item
        end
    end
    -- replace system
    if recipe.replace then
        -- iterate over recipe replace array
        for _,replace in pairs(recipe.replace) do
            items_to_add[#items_to_add + 1] = ItemStack(replace) -- replace item
        end
    end
    -- time to iterate through items and add to inventory or ground
    local warn = false
    local player = minetest.get_player_by_name(name)
    local pos = player:get_pos()
    for _,item in pairs(items_to_add) do
        if inv:room_for_item(outlistname, item) then
            inv:add_item(outlistname, item)
        else
            warn = true
            minetest.add_item(vector.new(pos.x,pos.y+1,pos.z), item)
        end
    end
    if warn then minimal.warn_inv_full(player) end
    return true
end

local function to_hex(str)
    return (str:gsub('.', function (c)
                         return string.format('%02X', string.byte(c))
    end))
end

function crafting.calc_inventory_list_hash(inv, listname)
    local str = ""
    for _, stack in pairs(inv:get_list(listname)) do
        str = str .. stack:get_name() .. stack:get_count()
    end
    return minetest.sha1(to_hex(str))
end
