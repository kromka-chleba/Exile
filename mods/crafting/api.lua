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
--
-- modified by various Exile devs, lately Izzy for performing craft, and lili for refactoring.

-- Warning: this is a circular dependency; minimal depends on crafting, too
--minimal = minimal

local crafting = crafting
local S = minetest.get_translator("crafting")

--[[#TODO comment better
 seems to be a table where function to launch at craft are stored, like unlocking recipes, level, awards..
   currently only used in init.lua in case we have an "awards" global var ]]
local registered_on_crafts = {}

-- register a function to be called at each craft
function crafting.register_on_craft(func)
    table.insert(registered_on_crafts, func)
end

-- PERFORM CRAFT ---------------------------------------------------------------

crafting.item_by_group = {} -- hash group:groupname to an item name.

--[[in original mod :
Iterates through a list in inv and adds or updates entries in item_hash.
itemhash beeing a table with {item name = item count in inventory} format

modified adding groupvalue setting
meaning item_hash also had "group:" .. groupname index
and "group:"" .. groupname .. groupvalue index

In addition,
crafting.item_by_group["group:"" .. groupname] is filled with last stack's name matching that group in inventory list
#TODO not sure how it is used yet, (lili)
]]
function crafting.set_item_hashes_from_list(inv, listname, item_hash)
    -- for every stack in inventory listname
    for _, stack in pairs(inv:get_list(listname)) do
        -- if stack is not empty
        if not stack:is_empty() then
            local itemname = stack:get_name()
            -- add its count to item_hash[its name]
            item_hash[itemname] = (item_hash[itemname] or 0) + stack:get_count()
            --[[ if this stack is part of a group:
            + add its count to item_hash["group:"" .. groupname]
             and to item_hash["group:"" .. groupname .. groupvalue]
            + defines crafting.item_by_group["group:"" .. groupname] = itemname
            ]]
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

--[[returns an item_list from all selected inv list
    returns like crafting.set_item_hashes_from_list but mixing all lists given in inv_list as one list.

    is used for display and process_qty
    but I think actual craft doesn't use it and is called with inv list
    (#TODO : maybe improve that point, reuniting display and craft process)
    ]]
function crafting.get_item_hash(pInv, inv_lists)
    if type(inv_lists) ~= 'table' then
        inv_lists = {inv_lists}
    end
    -- build player items hash
    local item_hash = {}
    for _,inv_name in ipairs(inv_lists) do
        if pInv:get_size(inv_name) > 0 then
            crafting.set_item_hashes_from_list(pInv, inv_name, item_hash)
        end
    end
    return item_hash
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

--[[seems unused since commit 7cb89e779a : was created by Izzy in 2024 in commit f1a5fe20ae]]
--[[function crafting.parse_where(recipe, items, item_idx, num_added)
    if recipe.where or type(recipe.where) ~= 'string' then
        return nil
    end
    local result = recipe.where_results or recipe.where

    -- @1.material == @2.material
    --   local input1,key1,test,input2,key2 =
    --print("where: "..recipe.where)
    --print(dump( string.match(recipe.where, "@(%d+)%.(%w+)%s*(.*)%s*@(%d+)%.(%w+)$") ))
end]]

-- not in original mod
--[[ Search inventory list given to find the required item
    stop when required quantity is found
    return a table of items to pick per list :
    {[list1] = {stack1, stack2, ...}, [list2] = {stack1, stack2}, ...}
    return nil if not found/not enough ]]
-- currently only used in local in pick_alternate_items function
local function pick_required_item(inv, lists, item)
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
            local pri = pick_required_item(inv, listname,
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
        return pick_required_item(inv, listname, item)
    end
end

--[[ new in Exile :
    Returns a list of what was found per list

    {[list1] = {stack1, stack2, ...}, [list2] = {stack1, stack2}, ...}

    Returns nil if not found or not enought for recipe
]]
local function find_required_items_in_invs(inv, listname, recipe)
        if not listname then
            return nil
        end
        -- added to deal with multple input lists but keep compatibility
        if type(listname) ~= 'table' then
            listname = { listname }
        end

        -- to store found items
        local found_table = {}
        -- initiate found_table
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
        return found_table
end

--unused in Exile, for mod compatibility
--it returns a list of stack, all source together, instead of a table of lists per source
--[[ in external mod :
    Returns a list of stacks to take, or nil if the required items could not
    be found.

    Returns nil if not found or not enought for recipe
]]
function crafting.find_required_items(inv, listname, recipe)
    local found_table = find_required_items_in_invs(inv, listname, recipe)
    -- Return found list
    if #listname == 1 then
        --if we had only one list, return only a list of stack to keep mod compatibility
        return found_table[listname[1]]
    else
        local result = {}
        for _,l in ipairs(listname) do
            for _,stack in ipairs(l) do
                table.insert(result,stack)
            end
        end
        return result
    end
end

--[[in original mod. Unused in Exile
Returns true if the listname list in inv contains the required items.]]
--#TODO could be adapted to check craftable/uncraftable, instead of our additionnal functions
function crafting.has_required_items(inv, listname, recipe)
    return crafting.find_required_items(inv, listname, recipe) ~= nil
end

--[[ In external mod
* Will try to take itemsfrom `listname` and put output in the `outlistname` list in `inv`.
* Returns true on success.
]]
function crafting.perform_craft(name, inv, listname, outlistname, recipe, ctype)
    -- get list of items required for the recipe (if found)
    local founditems = find_required_items_in_invs(inv, listname, recipe)
    if not founditems then
        return false
    end

    -- Take items from inventory
    local taken = {}

    -- Removes item present in founditems from inventories
    -- Replaces them if need
    for source, items in pairs(founditems) do
        for _,item in pairs(items) do
            local took = inv:remove_item(source, item)
            if took:get_count() > 0 then
                taken[#taken + 1] = took
            end
        end
    end

    --[[ #TODO comment more : seems to play all function in the table,
        but we only defined one ?
        this can be used for unlocking recipes, currently only used for awards
    ]]
    for i=1, #registered_on_crafts do
        registered_on_crafts[i](name, recipe)
    end

    -- create item -------------------------------------------------------------
    local material
    if recipe.material then
        local material_def = ItemStack(taken[recipe.material]):get_definition()
        material = material_def.exile_crafting
        and material_def.exile_crafting.material -- TODO when was it added and why ?
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

    -- get ouptut itemstack, its meta (`imeta`) and short description (`sdesc`)
    local itemstack = ItemStack(make_output)
    local imeta = itemstack:get_meta()
    local sdesc = itemstack:get_short_description()

    -- Set Creator
    if core.get_item_group(itemstack:get_name(), 'craftedby') > 0 then
        imeta:set_string('creator', name)
        -- don't add creator name to sort description for single player
        if not minetest.is_singleplayer() then
            -- player's so-and-so
            sdesc = S("@1's @2",name, sdesc)
        end
        imeta:set_string('short_description', sdesc)
    end

    -- Add Tool Tips to Description

    --[[ changed by Mantar 11 months ago, commented and replaces by get_short function in GUI
    -- #TODO dig in to see why following part was commented
    -- related to issue https://codeberg.org/Mantar/Exile/issues/1137
    ]]
    local idef = itemstack:get_definition()
    -- if we already have a tool_tip for the item,
    -- adds specific meta things to it
    if idef._tool_tips and idef._tool_tips ~= '' then
        imeta:set_string('description',sdesc .. idef._tool_tips)
    end

    -- set material
    --from Izzy to deal with conditional material in recipes
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
    -- end of "from Izzy" part

    --end
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
    -- get a crafting sound
    local sound = recipe.sound
    -- #TODO investigate next line
    sound = sound or sound ~= false and crafting.get_type(ctype).sound
    if sound then
        minimal.sound_play(minimal.merge_tables(sound, {pos = pos}))
    end
    return true
end
