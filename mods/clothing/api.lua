----------------------------------------------------------

clothing = clothing
local S = clothing.S

-- Integration: without this skinsdb crashes
clothing.register_on_update = function() end


-- This is used to equip cloths from HUD main inventory with right click
function clothing.on_rightclick(itemstack, user, pointed_thing)
    -- deletes items (or reproduces if programmed differently - gotta fix)
    if not (minetest.is_player(user) and itemstack) then
        return
    end

    local item_group = minimal.is_group(itemstack:get_name(),"cloth")
    -- if item is not a clothing or a blanket, do nothing
    if (not item_group or item_group == 6) then
        return
    end
    -- else, itemstack is a clothing. Pich one of them
    local new_cloth = itemstack:take_item()
    -- check correct destination
    local p_inv = user:get_inventory()
    local destination = player_api.get_inv_name_from_group(item_group)
    -- if nothing in here, just put the picked clothing in it
    if p_inv:is_empty(destination) then
        p_inv:add_item(destination, new_cloth)
        minetest.chat_send_player(user:get_player_name(), new_cloth:get_short_description().. " " .. S("equipped!"))
        -- else gets what is in here for an exchange
    else
        local in_dest = p_inv:get_stack(destination, 1)
        -- check that count is 1 (should always be the case, but...)
        if in_dest:get_count()>1 then
            minetest.log("We should have more than 1 clothing in that slot !")
        end
        -- check if this is the same clothing, if yes do nothing
        if new_cloth:equals(in_dest) then
            minetest.chat_send_player(user:get_player_name(), S("You already wear the same clothing."))
            -- don't return itemstack to not modify the source itemstack
            return
        else
            -- put new clothing in destination
            p_inv:set_stack(destination,1,new_cloth)
            minetest.chat_send_player(user:get_player_name(), new_cloth:get_short_description().. " " .. S("equipped!"))
            -- returning old cloth to source, or on the ground if no room
            -- warning, inv itemstack is updated only after end of call, so room is not free before
            if p_inv:room_for_item("main",in_dest) then
                if (itemstack:get_count() == 0) then
                  -- if this stack is about to be cleared... return in_dest, it will be added to inventory at the end of the call
                  itemstack = in_dest
                else
                  p_inv:add_item("main",in_dest)
                end
            else
                minetest.item_drop(in_dest, user, user:get_pos())
                minetest.chat_send_player(user:get_player_name(),S("Inventory is full : the clothing you wore was thrown on the floor."))
            end
        end
    end
    -- update player settings
    player_api.update_player(user)
    return itemstack
end
