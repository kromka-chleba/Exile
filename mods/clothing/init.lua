------------------------------------------------------------
--CLOTHING init
------------------------------------------------------------
clothing = {
    registered_callbacks = {
        on_update = {},
        on_equip = {},
        on_unequip = {},
    },
    player_textures = {},
    elements = {
        "hat",
        "shirt",
        "pants",
        "cape",
        "shoes",
        "gloves",
        "blanket"
    },
}

sfinv = sfinv

-- Internationalization
local S = minetest.get_translator("clothing")
local FS = function(...)
    return minetest.formspec_escape(S(...))
end

local modpath = minetest.get_modpath(minetest.get_current_modname())

dofile(modpath.."/api.lua")
--dofile(modpath.."/test_clothing.lua") --bug testing


--Not available except through creative
minetest.override_item("player_api:cloth_unisex_footwear_default", {
                           temp_min = 50,
                           temp_max = 50,
                           adminclothes = true,
})

------------------------------------------------------------
-- Inventory page

-- #TODO I think size is useless now, maybe make containers later
local clothing_formspec = "size[10.5,10.9]"

local clothing_page = {
    title = S("Clothing"),
    get = function(self, player, context)
        local meta = player:get_meta()
        local cur_tmin = climate.get_temp_string(
            meta:get_int("clothing_temp_min"), meta)
        local cur_tmax = climate.get_temp_string(
            meta:get_int("clothing_temp_max"), meta)
        local basetex = minetest.formspec_escape(
            player_api.get_current_texture(player) )

        local formspec = clothing_formspec..
            "label[4,1;" .. FS("Min Temperature Tolerance: @1", cur_tmin) .. " ]"..
            "label[4,1.5;" .. FS("Max Temperature Tolerance: @1", cur_tmax) .. " ]"..

            -- clothes display
            "list[current_player;cloths;0.75,0.75;2,3;]" ..
            --player inventory display : currently done in sfinv/api.lua
            --"list[current_player;main;0.35,7.3;8,1;]"..
            --"list[current_player;main;0.35,8.55;8,3;8]" ..
            "label[0.35,10.2;Tip : use \"shift\" key to switch clothes]" ..

            -- enable to move clothes from one inventory to another with shift
            "listring[current_player;cloths]"..
            "listring[current_player;main]"..


            -- overview of what it looks like
            -- #TODO do not change rotation angle when changing clothes,
            --  if possible, maybe saving the current angle in context/cache
            --  like in crafting tab
            "model[5.2,2.45;2.6,3.9;character;character.b3d;"..basetex..
            ";-20,160;;true;;]"
        return sfinv.make_formspec_for_exile(player, context,
                                   formspec, true)
    end
}

sfinv.register_page("clothing:clothing", clothing_page)


minetest.register_on_player_inventory_action(function(player, action,
                                                      inventory, inventory_info)
        if inventory_info.to_list == "cloths"
            or inventory_info.from_list == "cloths" then
            clothing.update_player(player)
        end
end)


minetest.register_allow_player_inventory_action(function(player, action,
                                                         inventory,
                                                         inventory_info)
        local stack, from_inv, to_index
        if action == "move" and inventory_info.to_list == "cloths" then
            if inventory_info.from_list == inventory_info.to_list then
                --for moving inside the 'cloths' inventory
                return 1
            end
            --for moving items from player inventory list 'main' to 'cloths'
            from_inv = "main"
            to_index = inventory_info.to_index
            stack = inventory:get_stack(inventory_info.from_list
                                        , inventory_info.from_index)
        elseif action == "put" and inventory_info.listname == "cloths" then
            --for moving from node inventory 'closet' to player inventory 'cloths'
            from_inv = "closet"
            to_index = inventory_info.index
            stack = inventory_info.stack
        else -- we're taking something out or doing some unrelated inv action
            return
        end
        if stack then
            local item_group = minimal.is_group(stack:get_name(),"cloth")
            if not item_group -- not a cloth
                or item_group == 6 then -- is a blanket
                return 0
            end

            local player_inv = player:get_inventory()
            local cloth_list = player_inv:get_list("cloths")

            for _,itemstack in pairs(cloth_list) do
                local cloth_name = itemstack:get_name()
                if (minimal.is_group(cloth_name,"cloth") == item_group) then
                    -- if same type of clothing article found then
                    if (from_inv == "main") then
                        -- if new itemstack is coming from player inventory
                        local removed = player_inv:remove_item(
                            "cloths", itemstack)
                        -- take the old itemstack
                        if player_inv:room_for_item("main",removed) then
                            -- add to player inventory
                            player_inv:add_item("main",removed)
                            return 1
                        else
                            -- throw it to the ground
                            minetest.item_drop(removed, player, player:get_pos())
                        end
                    end
                end
            end
            return 1
        end
        return 0
end)

--functions


local function load_clothing_metadata(player)
    -- Exile clothing was stored as a metadata string, migrate to new inv
    local player_inv = player:get_inventory()
    local meta = player:get_meta()
    local clothing_meta = meta:get_string("clothing:inventory")
    local clothes = clothing_meta and minetest.deserialize(clothing_meta) or {}
    if clothing_meta == "" then
        return
    end
    -- Fill detached slots
    --clothing_inv:set_size("clothing", 6)
    for i = 1, 6 do
        player_inv:set_stack("cloths", i, clothes[i] or "")
        --overwrite current clothes, but it will be empty on first migration
    end
    meta:set_string("clothing:inventory", "")
end

minetest.register_on_joinplayer(function(player)
        --import old clothing
        load_clothing_metadata(player)
        player_api.set_texture(player)
        clothing:update_temp(player)
end)
