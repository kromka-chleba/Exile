ncrafting = ncrafting

-- figure out if a soil - gets soil underneath plants
local function get_soil_pos(pos, ndef)
    ndef = ndef or minimal.get_nodedef(pos)
    local groups = ndef and ndef.groups
    if not groups then return end
    -- if plant or seed, check underneath
    if groups.flora or groups.seed then
        pos.y = pos.y - 1
        ndef = minimal.get_nodedef(pos)
        groups = ndef and ndef.groups
        if not groups then return end
    end
    -- now to check if a sediment
    if groups.sediment or groups.dry_sediment or
      -- permit interactions with compost
      groups.compost or groups.undecomposed_compost then
        -- return pos and nodedef
        return pos, ndef
    end
end

-- provides "wet" as a suffix already, so that all that needs to be applied
-- is either nothing or "salty" to get "wet_salty"
-- may remove this in the future if different liquids exist
local function wet_soil(player, pos, suffix)
    if not vector.check(pos) then return end
    local node = minetest.get_node(pos)
    -- set suffix as empty or lowercase if provided
    suffix = type(suffix) ~= "string" and "" or suffix:lower()
    -- we define _wet later on, clear it - otherwise continue as normal
    suffix = (suffix == "wet" or suffix == "_wet") and "" or suffix
    -- add "_wet" prefix
    -- if not empty, add an underscore if not provided, otherwise add prefix to suffix normally
    suffix = suffix ~= "" and (suffix:sub(1,1) ~= "_" and "_wet_"..suffix or "_wet"..suffix) or "_wet"

    -- check if watered block exists
    local wet_node_name = node.name .. suffix

    -- if no watered version of this block, check if this is because
    -- depleted variant had different name :
    if not core.registered_nodes[wet_node_name]
        and node.name:match("depleted") then

        -- depleted nodes with roots have "depleted" behind the "roots", so
        --  I declare this if statement first
        -- IF the provided node is "depleted", look for its proper depleted
        --  wet variant
        wet_node_name = wet_node_name:gsub("_depleted","")
        wet_node_name = string.gsub(wet_node_name,"_depleted","")
        wet_node_name = wet_node_name.."_depleted"
        -- we didn't erase "_wet" from the name
    end
    -- if still no match, check roots variant
    if not minetest.registered_nodes[wet_node_name]
        and node.name:match("roots") then

        -- IF the provided node is "roots", look for its proper roots
        --  wet variant
        wet_node_name = wet_node_name:gsub("_roots","")
        wet_node_name = wet_node_name.."_roots"
        -- we didn't erase "_wet" from the name
    end
    -- if still no wet version, display a message
    if not minetest.registered_nodes[wet_node_name] then
        local message
        if suffix == "_wet_salty" then -- #TODO dirty
            -- #TODO translate
            message = "You can't water that node with salt water"
        else
            -- #TODO translate
            message = "You can't water that node with this liquid"
        end
        minimal.send_message(player, nil, message)
    else
        -- replace with watered version
        -- keeping the node orientation
        minetest.set_node(pos, {name = wet_node_name, param2 = node.param2})
        return true
    end

    return false
end

-- water soil with a watering can
function ncrafting.water_soil(itemstack, user, pointed_thing, node_suffix, empty_container)
    -- will apply "_wet" before node_suffix unless it is "_wet"
    -- empty_container can be an override, otherwise specified in storeddef
    assert(type(pointed_thing) == "table",
           "ncrafting.water_soil: provided pointed_thing is not a table! "..
           "got: "..type(pointed_thing))
    if itemstack and not empty_container then
        local storeddef = liquid_store.get_sl_def(itemstack:get_name())
        empty_container = storeddef and storeddef.nodename_empty
    end
    assert(type(empty_container) == "string","ncrafting.water_soil: "..
           "string expected for empty_container, got: "..
           type(empty_container))

    -- can only water nodes
    if pointed_thing.type == "node"
        and itemstack then
        local pos = get_soil_pos(pointed_thing.under)
        -- will only return a pos if a soil is found
        if pos and wet_soil(user, pos, node_suffix) then
            -- if position is good and can wet the soil
            -- check if player is in creative
            if minimal.player_in_creative(user) then
                return
            end
            -- if not in creative, empty the can out
            empty_container = ItemStack(empty_container)
            -- huh, how do you have more than one watering? ok then...
            if itemstack:get_count() > 1 then
                itemstack:take_item() -- take 1 from slot
                local inv = core.is_player(user) and user:get_inventory()
                if inv:room_for_item("main", empty_container) then
                    inv:add_item("main", empty_container)
                else
                    minimal.warn_inv_full(user)
                    core.add_item(user:get_pos(), empty_container)
                end
            -- not more than 1, replace
            else
                itemstack = empty_container
            end
            return itemstack, true
        end
    end

    -- continue as normal (with a twist)
    return liquid_store.on_use_filled_bucket(itemstack, user,
                                             pointed_thing, false)
end

-- fertilize soil with a fertilizer
-- 4th parameter boolean "wet" used to wet the soil on success
function ncrafting.fertilize(pos, puncher, itemstack, wet)
    assert(vector.check(pos),
           "ncrafting.fertilize: provided position is not a position!")
    local inv
    local replace_with = ""
    if minetest.is_player(puncher) then
        inv = puncher:get_inventory()
        itemstack = itemstack or puncher:get_wielded_item()
    end
    if not itemstack or itemstack:get_name() == "" then
        -- no itemstack, or have a hand? NO FERTILIZATION!
        return
    end

    pos = get_soil_pos(pos)
    if not pos then return end
    local ndef = minimal.get_nodedef(pos)
    local itemdef = itemstack:get_definition()
    -- no definition!
    if not (ndef and itemdef) then return end
    -- no groups??
    if not itemdef.groups then return end

    -- find all possible variations of a replaceable
    if type(itemdef._fertilize_replace_with) == "string" then
        replace_with = itemdef._fertilize_replace_with
    else
        local slab = itemdef.name:gsub(ndef.mod_origin..":","")
        slab = "stairs:slab_"..slab
        if minetest.registered_nodes[slab] then
            replace_with = slab
        end
    end
    -- convert to itemstack
    replace_with = ItemStack(replace_with)

    -- avoid having to set up a "fertilized" boolean to prevent another check over
    local function complete(node_name)
        -- allow a custom "after_fertilize" function
        if type(itemdef._after_fertilize) == "function" then
            return itemdef._after_fertilize(pos, itemstack, puncher)
        end
        if wet and node_name then
            wet_soil(puncher, pos)
        end
        -- proceed as usual
        if not replace_with then
            -- if replace_with somehow broke, ensure no error
            replace_with = ItemStack('')
        end
        itemstack:take_item()
        if inv then
            if itemstack:is_empty() then
                inv:remove_item("main",itemstack)
            end
            if inv:room_for_item("main",replace_with) then
                inv:add_item("main",replace_with)
            else
                minimal.warn_inv_full(puncher)
                minetest.item_drop(replace_with, puncher, pos)
            end
        else
            -- no inventory found
            if itemstack:get_count() > 0 then
                itemstack:take_item()
            end
            -- no inventory to place into
            minetest.item_drop(itemstack, puncher, pos)
        end
        return itemstack, replace_with, true
        -- give a third parameter telling the function that it went well
    end

    -- prioritize fertilizing/composting first
    local node_name = ndef._fertile_name
    if node_name == ndef.name then
        -- prevent the ability to fertilize something already fertilized lol
        return itemstack
    end
    if itemdef.groups.compost and type(node_name) == "string" then
        if not minetest.registered_nodes[node_name] then
            minetest.log("error","ncrafting.fertilize: "..node_name..
                         " is not a valid item/node!")
            return itemstack
        end
        minetest.swap_node(pos, {name = node_name})
        return complete(node_name)
    end

    -- prioritize enriching second
    node_name = ndef._rich_name
    if node_name == ndef.name then
        -- prevent the ability to enrich something already enriched lol
        return itemstack
    end
    if itemdef.groups.fertilizer and type(node_name) == "string" then
        if not minetest.registered_nodes[node_name] then
            minetest.log("error","ncrafting.fertilize: '"..node_name..
                         "' is not a valid item/node!")
            return itemstack
        end
        minetest.swap_node(pos, {name = node_name})
        return complete(node_name)
    end

    return itemstack
end
