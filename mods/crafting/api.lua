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

local S = minetest.get_translator("crafting")
-- for @1's @2 translation
local mS = minetest.get_translator("minimal")

--[[#TODO comment better
 table where functions to launch at craft are stored, like unlocking recipes, level, awards..
   currently only one is registered in init.lua in case we have an "awards" global var ]]
-- also TODO: check what happen in case of max craft
local registered_on_crafts = {}

-- register a function to be called at each craft
function crafting.register_on_craft(func)
    table.insert(registered_on_crafts, func)
end

-- PERFORM CRAFT ---------------------------------------------------------------

--[[
Iterates through a list in inv and adds or updates entries in item_hash.
itemhash beeing a table with format:
    {["item name"] = {
    count = item count in inventory
    groups = groups from item's definition table
    }
]]
local function set_item_hash_from_list(inv, listname, item_hash)
    item_hash = item_hash or {}
    -- for every stack in inventory listname
    for _, stack in pairs(inv:get_list(listname)) do
        -- if stack is not empty
        if not stack:is_empty() then
            local itemname = stack:get_name()
            local def = minetest.registered_items[itemname]
            if not def then
                -- happends if a mod is missing, with unknown items
                core.log("no def ! for " .. itemname)
            end
            -- add its count to item_hash[its name]
            if not item_hash[itemname] then
                item_hash[itemname] = {
                    count = stack:get_count(),
                    groups = def and def.groups or {}
                }
            else
                item_hash[itemname].count = item_hash[itemname].count + stack:get_count()
            end
        end
    end
    return item_hash
end

crafting.set_item_hash_from_list = set_item_hash_from_list

--[[returns an item_list from all selected inv list
    returns like crafting.set_item_hash_from_list but mixing all lists given in inv_list as one list.

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
            set_item_hash_from_list(pInv, inv_name, item_hash)
        end
    end
    return item_hash
end

-- checks if ctype is a correct recipe's type
-- and recipe level is ok, and recipe is unlocked
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

function crafting.get_material_from(item)
    local material_def = ItemStack(item):get_definition().exile_crafting
    local material = material_def and material_def.material
    if not material then -- issue #814
        error("crafting.get_material_from : missing exile_crafting or "
        .."exile_crafting.material for item: " .. tostring(item))
    end
    return material
end

local function set_output_meta(output, player_name)
    if output then -- at this point it is an ItemStack, don't copy it !
        -- Set Creator
        if core.get_item_group(output:get_name(), 'craftedby') > 0 then
            -- don't add creator name to sort description for single player
            if not core.is_singleplayer() then
                -- get its meta (`imeta`) and short description (`sdesc`)
                local imeta = output:get_meta()
                local sdesc = output:get_short_description()
                imeta:set_string('creator', player_name)
                -- add creator's name to the desc
                sdesc = mS("@1's @2", player_name, sdesc)
                -- #TODO I am not sure I have to add both short_desc and desc meta
                -- in case we want to override short_desc later, it could probably be rebuilt
                -- I commented it because, right now, backpack code updated description meta but not shot_desc meta
                -- so that we loose the detailled info in shot desc if we erase if we set it here.
                --[[
                imeta:set_string('short_description', sdesc)
                --]]

                -- if we already have a tool_tip for the item,
                -- readd it to the new def
                local idef = output:get_definition()
                -- if we already have a tool_tip for the item
                if idef._tool_tips and idef._tool_tips ~= '' then
                    sdesc = sdesc .. idef._tool_tips
                end
                -- add final desc to meta
                imeta:set_string('description', sdesc)
            end

        end
    end
end

-- split stacks if need to respect stack_max of item
-- adds them to player inventory
-- drop and trigger warn if needed.
local function split_and_add (stack, pInv, outlistname, pos)
    -- time to add stacks
    local n_tocraft = stack:get_count()
    -- use stack's size for iterating
    local max_amt = stack:get_stack_max()
    local subtract_loop = math.ceil(n_tocraft / max_amt)
    -- will tell us if inventory is full
    local warn = false
    -- crafted stack size divided by its stack max then ceil'd
    -- (so a stack max and a half will not be 1.5 but rather 2)
    for _ = 1, subtract_loop do
        local item = ItemStack(stack) -- clone locally
        if n_tocraft > max_amt then
            item:set_count(max_amt) -- set stack to max
            n_tocraft = n_tocraft - max_amt -- lower count by stack max
        else
            item:set_count(n_tocraft)
        end
        -- put item in player's inventory
        if n_tocraft > 0 then -- just in case something goes wrong and
            --  an itemstack below or equal to 0 in count is made
            if pInv:room_for_item(outlistname, item) then
                pInv:add_item(outlistname, item)
            else
                warn = true
                minetest.add_item(vector.new(pos.x,pos.y+1,pos.z), item)
            end
        end
    end
    return warn
end

-- for replacement as string or array (old format)
-- this is called after we picked the items, as general replacement
-- (meaning: doesn't depend of the items picked)
-- format can be an ItemString or a table of ItemStrings.
local function give_replacement(replace, count, give_back)
    give_back = give_back or {}
    -- if no replacement to make, end
    if not replace then
        return {}
    -- if replace field is a string, give it back
    -- use count to mulitply replacement by number of craft
    elseif type(replace)== "string" then
        local stack = ItemStack(replace)
        stack:set_count(stack:get_count() * count)
        table.insert(give_back, stack)
    -- if replace field is a table, parse he table
    elseif type(replace)== "table" and #replace > 0 then
        for _ ,r in ipairs(replace) do
            give_replacement(r, count, give_back)
        end
    end -- else bad format or new format
    return give_back
end

--[[ apply replacement according to item used
    This is called with all picked items.
    * `recipe` is the recipe
    * `took` is the ItemStack took in picked items

    accepts 2 formats of `replace` field:
    - table: {[item_to_replace] = replacement_item}
    - function: apply the function

    Both of them have a 1 size ItemStack string as param/index
    and an ItemStack as result/value
    if `took` has a count > 1,
    the replacement count will me multiplied accordinglyy
]]
local function get_replacement(replace, took)
    -- if no replacement to make, end
    if not replace then
        return nil
    -- if replace field is a table, parse the table
    -- use number of item used to get replacement number
    -- stops at the first matching item found in table
    elseif type(replace) == "table" and #replace == 0 then
        for i, o in pairs (replace) do
            i = ItemStack(i)
            if i:get_name() == took:get_name() then
                -- TODO ok but better to fix i:get_cout() to 1
                local factor = math.floor(took:get_count() / i:get_count())
                o = ItemStack(o)
                o:set_count(o:get_count() * factor)
                return o
            end
        end
    -- if replace is a function, generate table
    -- TODO right now, only ok if 1 size item stack in replacement function
    elseif type(replace) == "function" then
        local o = replace(took:get_name())
        if not o then
            return nil
        else
            o = ItemStack(o)
            o:set_count(o:get_count() * took:get_count())
            return o
        end
    else -- wrong format or old format
        return nil
    end
end

-- #TODO simpliy/reunite the functions
-- regroup the calls
crafting.give_replacement = give_replacement
crafting.get_replacement = get_replacement


-- TODO make one with simple recipe, generating player_recipe
local function perform_craft(r, name, inv, listname, outlistname, craft_count, sound)
    -- if player recipe
    -- update player_recipe state
    if r.craftable == nil then -- TODO do it anyway in case of ??
        r:update_craftable_state(crafting.get_item_hash(inv, listname))
    end

    local player = minetest.get_player_by_name(name)
    -- if ot craftable, stop
    if not r.craftable then
        minimal.warn_message(player, name, S("Missing required items!"))
        return false
    end

    local recipe = r.recipe

    -- get list of items required for the recipe (if found)
    local founditems = r:pick_input_items(inv, listname, craft_count)
    if not founditems then
        core.log ("recipe " .. recipe.output .. "couldn't be crafted")
        return false
    end

    -- Removes item present in founditems from inventories ---------------------
    -- And add outpute and replacement (if needed) in `items_to_add` table
    local items_to_add = {} -- item to add in inventory later

    -- create outputs items and add them to `items_to_add` table
    -- TODO keep meta when keeping pots ? in replacement ?
    local output
    if recipe.output_func then --if custom output function is here
        output = recipe.output_func()
    else
        output = recipe.output
    end
    if output then
        -- convert string to ItemStack
        output = ItemStack(output)
        -- apply craft count
        output:set_count(output:get_count() * craft_count)
        -- set creator tag and infotext
        set_output_meta(output, name)
        -- adds it to the list to add
        items_to_add[1] = output
    end

    -- generate replacement table if needed
    local replace = recipe.replace

    -- old formats:
    local give_back = give_replacement(replace, craft_count)
    -- add replacement items if present
    if give_back then
        for _,item in pairs(give_back) do
            table.insert (items_to_add, item)
        end
    end

    -- Take founditems from inventory and replaces them if need
    for source, s_items in pairs(founditems) do
        for _,item in pairs(s_items) do
            local took = inv:remove_item(source, item)
            -- replace if needed
            if took:get_count() > 0  then
                local replacement = get_replacement(replace, took)
                if replacement then
                    table.insert (items_to_add, replacement)
                end
            end
        end
    end

    -- iterate through items_to_add table to split stacks if needed
    -- then adding them to inventory or ground if not enought room
    local pos = player:get_pos() -- to know were to drop items if inventory full
    local warn = false  -- will tell us if inventory is full
    -- Note: not sure the "ipairs" matters (to have output given first in case of full inventory)
    for _, stack in ipairs(items_to_add) do
        split_and_add (stack, inv, outlistname, pos)
    end
    if warn then minimal.warn_inv_full(player) end

    -- play sound ----------------------------------------------------
    sound  = sound or r.recipe.sound
    if sound then
        minimal.sound_play(minimal.merge_tables(sound, {pos = pos}))
    end

    --[[ #TODO comment more : seems to play all function in the table,
        but we only defined one ?
        this can be used for unlocking recipes, currently only used for awards
    ]]
    for i=1, #registered_on_crafts do
        registered_on_crafts[i](name, recipe)
    end

    return true
end

local function get_sound (recipe, ctype)
    local sound = recipe.sound
    -- if recipe as no sound and not "false", get crafting type's one
    if not sound and sound ~= false then
        sound = crafting.get_type(ctype).sound
    end
    return sound
end

--[[ In external mod
* Will try to take itemsfrom `listname` and put output in the `outlistname` list in `inv`.
*`r` is a player recipe, as in get_all function
* Returns true on success.
]]
-- ctype needs for sound TODO improve
-- TODO test if recipe is player_recipe or not
function crafting.perform_craft (player_name, inv, listname, outlistname, recipe, ctype, count)
    local r = recipe
    if not r.recipe then
        r = crafting.generate_p_recipe(recipe)
    end
    return perform_craft(r, player_name, inv, listname, outlistname, count, get_sound (recipe, ctype))
end

--[[transfer all items from `item_list` arraw to 'to_list' in player inventory's, if possible
return remaining item_list if they didn't all fit in
]]
function crafting.transfer_items(player, pInv, to_list, transfer_table)
    if not player then
        core.log ("in crafting.transfer_items, no player to transfer to")
        return
    end
    -- if no item_list specified, stop
    if not transfer_table then
        core.log("no item to transfer in crafting.transfer_items")
        return
    end
    -- if no destination specified, stop
    if not to_list then
        core.log("no destination specified in crafting.transfer_items")
        return
    end
    local new_list = {}
    for from_list, item_list in pairs(transfer_table) do
        for _, item in ipairs (item_list) do
            if not pInv:remove_item(from_list, item) then
                core.log("item " .. tostring(item) .. "couldn't be found to be transfered")
                -- TODO cancel the transfer then
            end
            -- Try to add to main inventory
            local left = pInv:add_item(to_list, item)
            if not left:is_empty() then
                new_list[#new_list + 1] = left:to_string()
                -- give it back to from_list
                pInv:add_item(from_list, left)
            end
        end
    end
    -- returns leftover
    return new_list
end

-- CURRENTLY UNUSED IN EXILE ---------------------------------------------------

-- not in original mod
--[[ Search inventory list given to find the required item
    stop when required quantity is found
    return a table of items to pick per list :
    {[list1] = {stack1, stack2, ...}, [list2] = {stack1, stack2}, ...}
    return nil if not found/not enough ]]
-- currently only used in local in pick_alternate_items function
local function pick_required_item(inv, lists, to_take)
    local picked_table ={}
    local name = to_take:get_name()
    local required = to_take:get_count()
    local gstats = crafting.get_group_stats(name)
    --print("Attempting to pick ",itemName)

    -- parse list my order of priority
    for _, list in ipairs(lists) do
        -- search stacks in provided inv lists
        for i = 1, inv:get_size(list) do
            local stack = inv:get_stack(list, i)
            --print("Checking ",stack:get_name()," ",stack:get_count())
            local found
            local match

            if gstats then -- Is it in group?
                match = gstats:does_match(stack:get_name())
            else
                match = (stack:get_name()== name)
            end
            if match then
                found = ItemStack(stack)
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
        core.log("I couldn't find in inventory the ingredients I was supposed to take to craft."
        .. " I was looking for " .. name
        .. ". I needed: " .. to_take:get_count()
        .. " and " .. tostring(required) .. " are missing.")
        return nil
    else
        return picked_table
    end
end


--[[ new in Exile :
    Returns a list of what was found per list

    {[list1] = {stack1, stack2, ...}, [list2] = {stack1, stack2}, ...}

    Returns nil if not found or not enought for recipe
]]
local function find_required_items_in_invs(inv, lists, to_take_list)
        -- to store found items
        local found_table = {}
        -- initiate found_table
        for i, list in ipairs(lists) do
            found_table[list]={}
        end

        for i, item in ipairs(to_take_list) do
            item = ItemStack(item)
            -- Conditional input list to process
            local pick_table = pick_required_item(inv, lists, item)
            -- if this part is found, add it to found_table
            if pick_table then
                for list, picked_litems in pairs (pick_table) do
                    for _,picked_stack in pairs(picked_litems) do
                        table.insert(found_table[list],picked_stack)
                    end
                end
            -- if this part is not found, stop
            else
                core.log("I couldn't find in inventory all the ingredients I was supposed to take to craft."
                .. " I was looking for " .. item:get_name()
                .. ". I needed: " .. item:get_count()
                .. " but couldn't found them.")
                return false
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
function crafting.find_required_items(inv, listname, items)
    if not listname then
        return nil
    end
    -- added to deal with multple input lists but keep compatibility
    if type(listname) ~= 'table' then
        listname = { listname }
    end

    local found_table = find_required_items_in_invs(inv, listname, items)
    -- if not found, stop and return false, something went wrong.
    if not found_table then return false end

    -- else:
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
function crafting.has_required_items(inv, listname, items)
    return crafting.find_required_items(inv, listname, items) ~= nil
end
