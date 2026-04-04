-- Custom alternative to core.get_item_group(name, group_name)
-- `name` is the name of the item to test, `group_name` the name of the group
-- * returns nil if item is not in group or if the value is <= 0
-- * returns the group value if > 0
--[[NOTE: to compare, core.get_item_group(name, group_name) returns:
--  * the value even if negative (range is [-32767, 32767])
--  * 0 if not in group
-- ]]
function EXILE.is_group(name, group_name)
    if not core.registered_items[name] then
        return
    end
    local group_val = core.get_item_group(name, group_name)
    if group_val > 0 then
        return group_val
    end
end

function EXILE.swap_tool(player, wielded_item, newtool)
    local wear = wielded_item:get_wear()
    local meta = wielded_item:get_meta():to_table()
    local newstack = ItemStack(newtool)
    newstack:set_wear(wear)
    newstack:get_meta():from_table(meta)
    player:set_wielded_item(newstack)
end


function EXILE.item_pickup(clicker, pointed_thing)
    if (minetest.is_player(clicker) and type(pointed_thing) == "table") then
        if pointed_thing.type == "object" then
            local pt_ref = pointed_thing.ref
            local ent
            if pt_ref then
                ent = pt_ref:get_luaentity()
            end
            if ent then
                if ent.itemstring and ent.itemstring ~= "" then
                    -- itemstring seems to save item metadata and wear :o
                    local itemstack = ItemStack(ent.itemstring)
                    local inv = clicker:get_inventory()

                    if inv:room_for_item("main",itemstack) then
                        inv:add_item("main",itemstack)
                        pointed_thing.ref:remove()
                    else
                        EXILE.warn_inv_full(clicker)
                    end

                    return true
                end
            end
        end
    end

    return false
end

-- itemstack storage functions
-- itemstack_equals - itemstack equals (NOT INTENDED FOR EXTERIOR USAGE)
-- itemstack1 and itemstack2 are to be itemstacks and the code will
--  check their name, and then metadata to see if they're equal
local function itemstack_equals(itemstack1,itemstack2)
    if type(itemstack1) ~= "userdata" or type(itemstack2) ~= "userdata" then
        return false
    end
    -- check if an itemstack equals the other by checking name
    --  and then meta if applicable
    if itemstack1:get_name() == itemstack2:get_name() then
        if itemstack1:get_meta() == itemstack2:get_meta() then
            return true
        end
    end
    return false
end
-- create_inventory_object - create inventory object
--   (NOT INTENDED FOR EXTERIOR USAGE)
-- items is a serialized table found in an itemstack's metadata (for inventory)
--   will also accept a regular table
-- (OPTIONAL) lengthoverride is a number to increase the custom returned
--   inventory's table (will not decrease size)
local function create_inventory_object(items, lengthoverride)
    -- returns a table with custom functions for inventory management
    --   including the ability to convert back into a serialized table
    if type(items) == "string" then
        if items == "" then
            items = {}
        else
            items = minetest.deserialize(items)
        end
    end
    if type(items) ~= "table" then
        return
    end
    -- create separate copy to use internally
    items = table.copy(items)
    -- check for and create proper inventory system
    for index,item in pairs(items) do
        -- convert or purify
        if type(item) ~= "userdata" or not item["is_empty"] then
            if type(item) == "string" then
                items[index] = ItemStack(item)
            else
                items[index] = ItemStack('')
            end
        end
    end
    -- add more slots if list is too small and lengthoverride specified
    if type(lengthoverride) == "number" then
        if #items < lengthoverride then
            for i = 1, lengthoverride do
                items[i] = ItemStack('')
            end
        end
    end
    -- create custom functions for inventory object
    local inv = {}
    -- basic functions
    function inv:get_list()
        -- gets the table for the items
        return items
    end
    function inv:get_size()
        -- get the total slot capacity of the inventory
        return #items
    end
    function inv:to_string()
        -- convert inventory into a serialized table
        for index,item in ipairs(items) do
            if item:get_name() ~= "" then
                -- convert itemstack to string for serialization
                items[index] = item:to_string()
            else
                -- remove em
                items[index] = ""
            end
        end
        return minetest.serialize(items)
    end
    -- alias
    function inv:convert()
        return inv:to_string()
    end
    -- full, partial, empty gets
    function inv:get_full()
        -- get slots that are full
        local slots = {}
        for index,item in ipairs(items) do
            if item:get_count() >= item:get_stack_max() then
                slots[#slots + 1] = index
            end
        end
        -- return table of slots + number
        return slots,#slots
    end
    function inv:get_partial()
        -- get slots that are partially full
        local slots = {}
        for index,item in ipairs(items) do
            if item:get_count() < item:get_stack_max()
                and not item:is_empty() then

                slots[#slots + 1] = index
            end
        end
        return slots,#slots
    end
    function inv:get_empty()
        -- get slots that are empty
        local slots = {}
        for index,item in ipairs(items) do
            if item:is_empty() then
                slots[#slots + 1] = index
            end
        end
        return slots,#slots
    end
    -- misc inventory functions
    function inv:is_empty()
        if #inv:get_empty() == inv:get_size() then
            return true
        end
        return false
    end
    function inv:get_full_partial_empty_count()
        -- get data of how many slots are full, partial, and empty
        local data = {
            full = {inv:get_full()},
            empty = {inv:get_empty()}
        }
        -- get second parameter, the count
        data.full = data.full[2]
        data.empty = data.empty[2]
        -- why run inv:get_partial() when we can calculating using full and empty?
        data.partial = inv:get_size() - (data.full + data.empty)
        return data
    end
    function inv:get_item_amounts()
        -- figure out how many items of a type exist (count), their collective max_count, and how many slots they own
        local data = {}
        if inv:is_empty() then
            data = {slots = {inv:get_empty()}, count = 0, max = 0}
            data.slots = data.slots[2]
            -- we still should be a list, wrap it!
            data = {[""] = data}
            -- we're actually empty, tell any code calling us that we are with second parameter
            return data, true
        end
        for _, item in ipairs(items) do
            if not item:is_empty() then
                local item_name = item:get_name()
                local item_data = data[item_name] or {slots = 0, count = 0, max = 0}
                item_data.slots = item_data.slots + 1
                item_data.count = item_data.count + item:get_count()
                item_data.max = item_data.max + item:get_stack_max()
                data[item_name] = item_data
            end
        end
        return data
    end
    function inv:get_most_popular_stats(mode)
        -- get stats of most popular item in inventory
        -- permit "modes" to determine which popular item this is;
        -- accepts "count" or "max"/"max_count", otherwise defaults to determining by slots occupied
        mode = type(mode) == "string" and mode:lower() or mode
        mode = mode == "max_count" and "max" or mode
        local data,is_empty = inv:get_item_amounts()
        if not is_empty then
            local stats = {name = "", num = 0}
            for item_name, info in pairs(data) do
                -- defaults to 'slots'
                local num = mode == "count" and info.count or mode == "max" and info.max or info.slots
                if num > stats.num then
                    stats.name = item_name
                    stats.num = num
                end
            end
            -- returning most popular
            data = data[stats.name]
            data.name = stats.name -- add name
        -- empty, get_item_amounts still acts like a list, get the wrapped empty value
        else
            data = data[""]
            data.name = ""
        end
        return data
    end
    -- itemstack interactions
    function inv:room_for_item(itemstack,index)
        -- return false if cannot fit, return true if can fit,
        -- return false + number if full itemstack cannot fit but some of it can
        if type(itemstack) ~= "userdata" or not itemstack["get_meta"] then
            error(debug.traceback(
                      "inv:room_for_item: itemstack is not an ItemStack, got '"
                      ..tostring(itemstack).."'",2))
        end
        if itemstack:is_empty() then
            -- of course there's room for an empty itemstack!
            return true
        end
        index = type(index) == "number" and math.ceil(index) or nil
        if not index then
            local free_space = 0
            for _,item in ipairs(items) do
                if item:get_name() == "" then
                    -- check empty slots
                    return true
                elseif itemstack_equals(item, itemstack) then
                    -- look at familiar itemstacks
                    if item:item_fits(itemstack) then
                        -- if there's enough room for me to be added to
                        return true
                    else
                        -- add to free_space (for return false + number
                        --   or return true if enough space among)
                        free_space = free_space + item:get_free_space()
                    end
                end
            end
            if free_space > 0 then
                -- haven't found precise room
                --  check if we can fit amongst inventory or
                --  if not, return false + what'd be leftover from adding to
                free_space = free_space - itemstack:get_count()
                if free_space >= 0 then
                    -- enough room among the spreadout inventory
                    return true
                end
                -- return false, but say that you'd have this leftover
                --  (negative free_space) from adding to the total inventory
                return false,math.abs(free_space)
            end
        elseif EXILE.math_clamp(index,1,#items) == index then
            -- index provided and is able to be indexed, check available room
            local item = items[index]
            if item:get_name() == "" then
                return true
            elseif itemstack_equals(itemstack, item) then
                if item:item_fits(itemstack) then
                    return true
                else
                    return false,itemstack:get_count() - item:get_free_space()
                end
            end
        end
        -- can't fit it
        return false
    end
    function inv:add_item(itemstack, index, take_count)
        -- add itemstack and return leftover
        if type(itemstack) ~= "userdata" or not itemstack["get_meta"] then
            error(debug.traceback(
                      "inv:add_item: itemstack is not an ItemStack, got '"..
                      tostring(itemstack).."'",2))
        end
        if itemstack:is_empty() then
            -- you gave it... an empty itemstack? how odd lol
            return itemstack
        end
        index = type(index) == "number" and math.ceil(index) or nil
        -- get count and figure out how much we should take away (custom number or itemstack count)
        -- clamp to lowest number - shouldn't be trying to take more than the actual itemstack count
        local count = itemstack:get_count()
        local giveaway = type(take_count) == "number" and math.min(count, take_count) or count
        local function itemstack_take(num)
            -- only do calculations if num is provided
            if num then
                count = count - num
                giveaway = giveaway - num
            end
            -- empty out itemstack if total count is 0
            if count == 0 then
                return ItemStack('')
            else
                itemstack:set_count(count)
            end
            return itemstack
        end
        if not index then
            -- add normally
            for item_index,item in ipairs(items) do
                -- if item equals provided itemstacked and there's space inside
                if item:get_free_space() > 0 and itemstack_equals(
                    item,itemstack) then
                    -- get the smallest number between the itemstack's count
                    --   or the amount of space left
                    local amt = math.min(giveaway,
                                         item:get_free_space())
                    itemstack_take(amt)
                    item:set_count(item:get_count() + amt)
                end
                -- we're done giving away
                if giveaway == 0 then
                    return itemstack_take()
                end
            end
            -- could not be added to an equal stack, add to empty
            for item_index,item in pairs(items) do
                if item:get_name() == "" then
                    items[item_index] = itemstack:take_item(giveaway)
                    return itemstack_take(giveaway)
                end
            end
        elseif EXILE.math_clamp(index,1,#items) == index then
            -- index provided and is able to be indexed, add itemstack to index
            local item = items[index]
            if item:get_name() == "" then
                -- it's empty, fill it up
                items[index] = itemstack:take_item(giveaway)
                return itemstack_take(giveaway)
            elseif itemstack_equals(item,itemstack) then
                if item:item_fits(itemstack) then
                    itemstack = item:add_item(itemstack)
                else
                    local amt = math.min(giveaway,
                                         item:get_free_space())
                    itemstack_take(amt)
                    item:set_count(item:get_count() + amt)
                end
            end
        end
        return itemstack_take()
    end
    function inv:remove_item(index,amount)
        index = type(index) == "number" and math.ceil(index) or nil
        -- take amount of item from an index
        if not index or EXILE.math_clamp(index,1,#items) ~= index then
            -- if not a number or number is not in range of items list then
            return ItemStack('')
        end
        -- only if index is in range
        amount = type(amount) == "number" and math.max(amount,1)
            or 1 -- amount to take (cannot be less than 1)
        local item = items[index]
        -- what to return
        local itemstack = item:take_item(math.min(item:get_count(),amount))
        if item:is_empty() then
            items[index] = ItemStack('')
        end
        return itemstack
    end
    return inv
end
-- get_item_inventory - get item inventory
-- itemstack is the item to get the inventory from
-- (OPTIONAL) metadata parameter to allow one to not have to call get_meta()
--   again - otherwise calls metadata of itemstack
-- (OPTIONAL) inv_name parameter to allow for a custom inventory value access
--    must be string or otherwise defaults to "inv_main"
function EXILE.get_item_inventory(itemstack, metadata, inv_name)
    if type(itemstack) ~= "userdata" or not itemstack["get_meta"] then
        error(debug.traceback("exile_core.get_item_inventory: itemstack is "..
                              "not an ItemStack, got '"..
                              tostring(itemstack).."'",2))
    end
    -- get meta if not given or valid
    if type(metadata) ~= "userdata" then
        metadata =itemstack:get_meta()
    end

    -- if inv_name not given or invalid string, set to default
    if type(inv_name) ~= "string" then
        inv_name = "inv_main"
    end

    local inv = metadata:get(inv_name)
    if not inv then
        return
    end
    local tool_def = itemstack:get_definition()
    -- get full size of storage indexes
    local size = (tool_def.formspec_width or 8) * (tool_def.formspec_height or 4)
    -- returns a table with custom functions for inventory management
    return create_inventory_object(inv,size)
end
-- set_item_inventory - set item inventory

-- "itemstack" is the item to save the inventory to
-- (OPTIONAL) metadata parameter to allow one to not have to call get_meta()
--   again - otherwise calls metadata of itemstack
-- (OPTIONAL) inv_name parameter to allow for a custom inventory value access,
--   must be string or otherwise defaults to "inv_main"

-- inv parameter - special table type returned by get_item_inventory's
--   create_inventory_object or a list of numbered items

-- CANNOT have stringed indexes if it is not a special table type
function EXILE.set_item_inventory(itemstack, metadata, inv_name, inv)
    if type(itemstack) ~= "userdata" or not itemstack["get_meta"] then
        error(debug.traceback("exile_core.set_item_inventory: itemstack is "..
                              "not an ItemStack, got '"..
                              tostring(itemstack).."'",2))
    end
    if type(inv) ~= "string" then
        if type(inv) ~= "table" then
            error(debug.traceback("exile_core.set_item_inventory: could not "..
                                  "get an inventory to set with, got '"..
                                  tostring(inv).."'",2))
        end
        if type(inv["convert"]) == "function" then
            -- utilize to_string function
            inv = inv:convert()
        elseif type(inv["to_string"]) == "function" then
            inv = inv:to_string()
        else
            -- convert into an inventory object if no string indexes, otherwise return
            for index,value in pairs(inv) do
                if type(index) ~= "number" then
                    error(debug.traceback(
                              "exile_core.set_item_inventory: got an improver "..
                              "inv table to set inventory with",2))
                end
            end
            inv = create_inventory_object(inv)
            inv = inv:convert()
        end
    end
    metadata = type(metadata) == "userdata" and metadata
        or itemstack:get_meta()
    inv_name = type(inv_name) == "string" and inv_name
        or "inv_main"
    metadata:set_string(inv_name,inv)
end
-- convert_node_inventory - convert node inventory
-- inventory is expected to be metadata or the :get_inventory() result from a metadata - also accepts position
-- (OPTIONAL) inv_name is the name of the node's inventory to be accessed (default "main")
function EXILE.convert_node_inventory(inventory, inv_name)
    -- gets and converts a node's metadata into a custom inventory
    if type(inv_name) ~= "string" then
        inv_name = "main"
    end

    if type(inventory) == "table" then
        -- get pos if provided
        if type(inventory.x) == "number"
            and type(inventory.y) == "number"
            and type(inventory.z) == "number" then

            inventory = minetest.get_meta(inventory)
        end
    end
    -- get inventory from node metadata
    if type(inventory) == "userdata" and inventory["get_inventory"] then
        inventory = inventory:get_inventory()
    end
    -- get inventory list from inventory metadata
    if type(inventory) == "userdata" and inventory["get_list"] then
        inventory = inventory:get_list(inv_name)
    end
    -- if we still couldn't get a table, return nil
    if type(inventory) ~= "table" then
        return
    end
    return create_inventory_object(inventory)
end
