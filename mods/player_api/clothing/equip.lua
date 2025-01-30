-- Here is the inventory tab generated and all the dealing with moving clothing in and out the clothing spots --
--[[
Shift moving uses a player's inventory lis "temp_slot" once check that this is a cloth, to automatically redirect it to the correct cloth slot when equipping

Only one cloth is allowed in each slot.

Temperatures and formspec are updated at each equip/unequip action.
]]

-- #TODO regrouping with the action on form effects ?
-- like where do we refresh ? I would like to keep in memory the rotation of the model
player_api = player_api
sfinv = sfinv

-- Internationalization---------------------------------------------------------
local S = minetest.get_translator("player_api")
local FS = function(...)
    return minetest.formspec_escape(S(...))
end
--------------------------------------------------------------------------------

-- Inventory page to create "clothing" tab formspec-----------------------------
--[[ It will be put in a size[10.5,10.9] formspec
    (see function sfinv.make_formspec_for_exile in mods/sfinv for integration) ]]

-- Generate the listring loop to deal with shif-click use
local function generate_shiftclick_ring()
    local ring = {
    -- from main to temporary slot where it will be automatically dealed with
    "listring[current_player;main]",
    "listring[current_player;temp_slot]",
    -- from each cloth slot to main
    "listring[current_player;hat]",
    "listring[current_player;main]",
    "listring[current_player;shirt]",
    "listring[current_player;main]",
    "listring[current_player;pants]",
    "listring[current_player;main]",
    "listring[current_player;shoes]",
    "listring[current_player;main]",
    "listring[current_player;cape]",
    "listring[current_player;main]",
    "listring[current_player;blanket]",
    "listring[current_player;main]"
    }
    return table.concat(ring)
end

-- Generate the page container
local clothing_page = {
    title = S("Clothing"),
    get = function(self, player, context)
        local meta = player:get_meta()
        local cur_tmin = climate.get_temp_string(meta:get_int("clothing_temp_min"), meta)
        local cur_tmax = climate.get_temp_string(meta:get_int("clothing_temp_max"), meta)
        local basetex = minetest.formspec_escape(
            player_api.get_current_texture(player) )

        local formspec = {
            "container[0,0]",
            "label[4,1;" .. FS("Min Temperature Tolerance: @1", cur_tmin) .. " ]",
            "label[4,1.5;" .. FS("Max Temperature Tolerance: @1", cur_tmax) .. " ]",

            --model overview
            -- #TODO do not change rotation angle when changing clothes,
            --  if possible, maybe saving the current angle in context/cache
            --  like in crafting tab
            "model[5.25,2.45;2.6,3.9;character;character.b3d;"..basetex..
            ";-20,160;;true;;]",

            --2) inventories
            -- for tests with shift only
            --"list[current_player;temp_slot;8,2;1,1;]" ..
            -- #TODO add images or tooltips to indicate what goes where
            "list[current_player;hat;4.08,2;1,1;]",
            "list[current_player;shirt;4.08,3.25;1,1;]",
            "list[current_player;pants;4.08,4.5;1,1;]",
            "list[current_player;shoes;4.08,5.75;1,1;]",
            "list[current_player;cape;7.88,3.25;1,1;]",
            "list[current_player;blanket;7.88,5.75;1,1;]",
            --player inventory display : currently done in sfinv/api.lua
            --"list[current_player;main;0.35,7.3;8,1;]"..
            --"list[current_player;main;0.35,8.55;8,3;8]" ..
            "label[0.35,10.2;Tip : use \"shift\" key to switch clothes]",

            -- enable equip with "shift" key.
            generate_shiftclick_ring(),

            "container_end[]"
            }
            -- call a function making a size[10.5,10.9] formspec with that content and adding tabs if needed
        return sfinv.make_formspec_for_exile(player, context,
                                   table.concat(formspec), true)
    end
}

--register the page as tab in the formspec called when pressing "inventory" key
sfinv.register_page("clothing:clothing", clothing_page)
--------------------------------------------------------------------------------

-- Equip/unequip system --------------------------------------------------------
--[[ Check if the item we want to equip are valid cloths
    If yes put it in the correct spot
    Allow use of shift in formspec as shortcut
    Allow equip on right-click on secondary use
]]

-- Refuse or accept move of this stack to clothing slots
-- return the number allowed and the destination inventory name
local function allow_cloth_equip (player, inventory, stack, to_slot)
    if stack then
        local item_group = minimal.is_group(stack:get_name(),"cloth")
        -- refuse the move if not a cloth
        if not item_group then
            return 0
        end
        -- else refuse if this is a blanket and I am not in bed
        if item_group == 6 and player_api.get_state(player, "health"):is("resting") == false then
            minimal.send_message(
                player, nil,
                S("You can't equip a blanket outside of a bed."))
            return 0
        end

        local rightplace = player_api.get_inv_name_from_group(item_group)
        if to_slot and to_slot ~= rightplace then
            return 0 -- This is the wrong slot
        end
        -- else, if I am already wearing the same thing
        if inventory:get_stack(rightplace, 1):get_name() == stack:get_name() then
            minimal.send_message(
                player, nil,
                S("You already wear that!"))
            return 0
            -- else allow 1 to destination
        else
            return 1, rightplace
        end
    end
end

-- Allow equip if item is cloth only
-- block blanket equip if not in bed
-- Always allow unequip
minetest.register_allow_player_inventory_action(
function(player, action,inventory, inventory_info)
    -- close old cloths
    -- used for shift click, cloths as transitory inv
    local dest_slot = inventory_info.to_list
    if dest_slot == "temp_slot" then
        if action == "move" then
            local stack = inventory:get_stack(inventory_info.from_list,
                                              inventory_info.from_index)
            if allow_cloth_equip(player, inventory, stack) == 0 then
                return 0
            else
                -- (if I allow only 1, shift-click process will repeat it anyway    untile it did the whole stack)
                return
            end
        end
    end

    if player_api.is_clothing_slot(dest_slot) then
        if action == "move" then
            local stack = inventory:get_stack(inventory_info.from_list,
                                              inventory_info.from_index)
            return allow_cloth_equip(player, inventory, stack, dest_slot)
        end
    end
    -- in any other cases, allow the action
end)

-- Redirect cloths to the correct inventory if shift-click was used to equip
local function redirect(player, inventory, from_list, from_index, fromslot)
    if inventory:is_empty(fromslot) then
        minetest.log("Something got wrong, slot to take from is empty")
        return
    end
    local stack = inventory:get_stack(fromslot, 1)
    -- if stack bigger than 1, give back the rest to the source
    local too_much = stack:get_count()-1
    if too_much>0 then
        local give_back = stack:take_item(too_much)
        inventory:set_stack(from_list,from_index, give_back)
    end
    -- at this step we checked before that has a correct cloth group
    -- and there is only 1 item in stack
    local item_group = minimal.is_group(stack:get_name(),"cloth")
    local destination = player_api.get_inv_name_from_group(item_group)
    -- take cloth already in spot if there is some
    local in_dest = inventory:get_stack(destination, 1)
    -- replacing it with new cloth
    inventory:set_stack(destination,1,stack)
    -- returning old cloth to source, or on the ground if no room
    if inventory:room_for_item(from_list,in_dest) then
        inventory:add_item(from_list,in_dest)
    else
        minetest.item_drop(in_dest, player, player:get_pos())
        --minimal.send_message(player, nil, ("Inventory is full : the clothing you wore was thrown on the floor."),2)
        minimal.warn_inv_full(player)
    end
    -- empty cloths slot
    inventory:set_stack(fromslot,1,ItemStack(""))
end

-- Update player's inventory and settings if cloths change
minetest.register_on_player_inventory_action(function(player, action,
    inventory, inventory_info)
    local from_list = inventory_info.from_list
    local to_list = inventory_info.to_list
    local listname = inventory_info.listname
    -- update player settings if we add/remove cloths
    if player_api.is_clothing_slot(from_list) or
        player_api.is_clothing_slot(to_list) or
        player_api.is_clothing_slot(listname) then
        -- update texture and temp settings
        --[[#TODO I am not sure why I need a delay to not break shift-click moving by refreshing/loosing focus during the process since I added setting button in sfinv : it seems this is linked to the fact that the gear button gets the focus]]
        core.after(0.1, player_api.update_player, player)
    end
    -- if shift click brought item from inventory to be redirected
    if to_list == "temp_slot" then
        redirect(player,inventory, from_list, inventory_info.from_index,"temp_slot")
        -- update texture and temp settings
        --[[#TODO I am not sure why I need a delay to not break shift-click moving by refreshing/loosing focus during the process since I added setting button in sfinv : it seems this is linked to the fact that the gear button gets the focus]]
        core.after(0.1, player_api.update_player, player)
    end
end)

-- This is used to equip cloths from HUD main inventory with right click
-- the player move the arms until I rotate... #TODO ?
function player_api.on_rightclick(itemstack, user, pointed_thing)
    -- deletes items (or reproduces if programmed differently - gotta fix)
    if not (minetest.is_player(user) and itemstack) then
        return
    end

    -- stop if equip is not allowed
    local p_inv = user:get_inventory()
    local allowed, destination = allow_cloth_equip (user, p_inv, itemstack)
    if allowed == 0 then
        --not allowed to move in
        return
    end

    -- else, equip and return modified itemstack if needed
    if not destination then -- shouldn't happen, but well..
        local item_group = minimal.is_group(itemstack:get_name(),"cloth")
        destination = player_api.get_inv_name_from_group(item_group)
    end

    -- take 1 item from source
    local new_cloth = itemstack:take_item()
    -- if destination is not empty, get a copy and empty it
        -- note : allow function already checked if they were identical (meaning had the same name)

    local in_dest
    if not p_inv:is_empty(destination) then
        in_dest = p_inv:get_stack(destination, 1)
        p_inv:set_stack(destination,1,ItemStack(""))
    end

    -- add it in destination
    p_inv:add_item(destination, new_cloth)
    minimal.send_message(user, nil, S("@1 equipped!", new_cloth:get_short_description()))
    -- update player settings
    player_api.update_player(user)

    -- if I have the old equipment to deal with :
    if in_dest then
        -- returning old cloth to source, or on the ground if no room
            -- warning, inv itemstack is updated only after end of call, so room is not free before
        if (itemstack:get_count() == 0) then
            -- if this stack is about to be cleared... tell him to put in_dest in source slot at the end of the call
            return in_dest
        elseif p_inv:room_for_item("main",in_dest) then
            p_inv:add_item("main",in_dest)
            return itemstack
        else
            minetest.item_drop(in_dest, user, user:get_pos())
            --minimal.send_message(user, nil, ("Inventory is full : the clothing you wore was thrown on the floor."))
            minimal.warn_inv_full(user)
            return itemstack
        end
    else
        return itemstack
    end
end
