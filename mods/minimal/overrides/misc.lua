--Alters base Luanti functions for:
--item_place
--digging
--fall damage

minetest = minetest
core = core

local fall_damage_multiplier = 1.5

--Increase fall damage
minetest.register_on_player_hpchange(function(player, hp_change, reason)
        if reason.type == "fall" then
            hp_change = hp_change*fall_damage_multiplier
        end
        return hp_change
end, true)

minetest.override_item("air", { groups = { air = 1,
                                           not_in_creative_inventory = 1} })

-- check for/do on_rightclick() of pointed_thing,
-- required for our minetest.item_place() and
-- for items with a custom on_place() which does not use minetest.item_place()
function minimal.pointed_thing_on_rightclick(itemstack, placer, pointed_thing)
    if pointed_thing.type == "node" and minetest.is_player(placer) then
        local ndef = minimal.get_nodedef( pointed_thing.under )

        if ndef and (ndef.override_sneak == true
                     or not placer:get_player_control().sneak) then
            local on_click = minimal.on_rightclick(itemstack, placer,
                                                   pointed_thing)
            if on_click ~= false then
                return on_click or itemstack
            end
        end
    end
    -- case not yet handled or on_rightclick() allowed more to be done
    return false
end


--A new item_place that allows disabling sneak-rightclick behavior for nodes
--Needed for tech:stick
function minetest.item_place(itemstack, placer, pointed_thing, param2)
    -- Call on_rightclick if the pointed node defines it
    local on_click = minimal.pointed_thing_on_rightclick(itemstack, placer,
                                                         pointed_thing)
    if on_click ~= false then
        return on_click or itemstack
    end
    if itemstack:get_definition( ).type == "node" then
        return minetest.item_place_node( itemstack, placer,
                                         pointed_thing, param2 )
    end
    return itemstack, nil
end

local old_node_dig = minetest.node_dig
function minetest.node_dig(pos, node, digger)
    -- Return protection nail if node was nailed
    minimal.protection_on_dig(pos,node,digger)
    if minetest.is_player(digger)
        and not minimal.player_in_creative(digger) then

        local witem = digger:get_wielded_item()
        local drops = minetest.get_node_drops(node, witem)
        local inv = digger:get_inventory()
        local full = inv:room_for_item("main", node.name)
        if drops then -- drops something else, maybe multiple items. handle them
            full = false
            inv:set_size("temp", inv:get_size("main"))
            inv:set_list("temp", inv:get_list("main"))
            for k, v in pairs(drops) do
                if not full and inv:room_for_item("temp", drops[k]) then
                    inv:add_item("temp", drops[k])
                else
                    full = true
                end
            end
            inv:set_list("temp", {})
            inv:set_size("temp", 0)
        end
        if full then
            if minimal.stop_on_inv_full(digger) then
                return false
            end
        end
    end
    return old_node_dig(pos, node, digger)
end