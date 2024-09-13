--------------------------------------------------------------
--MAP

--------------------------------------------------------------

local S = artifacts.S

-- Update HUD flags


local function update_hud_flags(player)
    local minimap_enabled = minimal.player_in_creative(player) or
        player:get_inventory():contains_item("main", "artifacts:mapping_kit")
    --local radar_enabled = creative_enabled

    player:hud_set_flags({
            minimap = minimap_enabled,
            minimap_radar = minimap_enabled
    })
end


-- Set HUD flags 'on joinplayer'

minetest.register_on_joinplayer(function(player)
        update_hud_flags(player)
end)


-- Cyclic update of HUD flags

local function cyclic_update()
    for _, player in ipairs(minetest.get_connected_players()) do
        update_hud_flags(player)
    end
    minetest.after(5.3, cyclic_update)
end

minetest.after(5.3, cyclic_update)


-- Mapping kit item

local mapkit = {
    description = S("Geosurveyor".. "\n" .. "Use with 'Minimap' key"),
    inventory_image = "artifacts_mapping_kit.png",
    stack_max = 1,
    --groups = {flammable = 1},

    on_use = function(itemstack, user, pointed_thing)
        update_hud_flags(user)
    end,
}

minetest.register_craftitem("artifacts:mapping_kit", mapkit)
