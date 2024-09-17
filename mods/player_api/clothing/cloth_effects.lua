-- Regroup all non visual effects of clothes

-- Internationalization---------------------------------------------------------
local S = minetest.get_translator("player_api")
--------------------------------------------------------------------------------

-- temperatures dealing --------------------------------------------------------

-- set clothing and update comfortable temperature range
-- also set armor (but we don't have armor in clothes def yet)
-- 2nd arg is optionnal as shortcut to say "don't bother checking the equipment, I am naked", like after kill/restart
-- This function also update the clothing formspec
player_api.update_equipment_effects = function(player, naked)

    --[[
        clothing temp_min: subtracted from minimum temperature tolerance
        clothing temp_max: added to maximum temperature tolerance

        e.g. if current comfort range is 21 to 35 then...
        temp_min: 6
        temp_max: -8
        new range = 15 to 28 (e.g. you put on a warm coat)

        note: ranges are
        -comfort zone: no energy drain
        -stress zone: some energy drain
        -danger zone: large energy drain
        -extreme zone: direct damage

    ]]

    -- default range, no clothes yet
    local defaults = HEALTH.get_default_attributes()
    local temp_min = assert(defaults.clothing_temp_min)
    local temp_max = assert(defaults.clothing_temp_max)

    if not player then
        return
    end
    
    local armorgroups = {fleshy = 100}
    if not naked then
        -- check clothes if not naked
        local inv = player:get_inventory()    
        for _, name in ipairs(player_api.get_inv_names()) do
            local stack = inv:get_stack(name, 1)
            if stack:get_count() == 1 then -- should always be the case
                local def = stack:get_definition()
                -- set comfortable temperature range
                if def.temp_min and def.temp_max then
                    temp_min = temp_min - def.temp_min
                    temp_max = temp_max + def.temp_max
                end
                if def.adminclothes then
                    armorgroups.immortal = 1
                end
                if def.armor then
                    armorgroups.fleshy = armorgroups.fleshy - def.armor
                end
            end
        end
    end
    -- apply new temperature comfort range
    local meta = player:get_meta()
    meta:set_int("clothing_temp_min", temp_min)
    meta:set_int("clothing_temp_max", temp_max )
    -- Apply armorgroups changes
    if minetest.settings:get_bool("enable_damage") then
        player:set_armor_groups(armorgroups)
    end
    -- update clothing tab formspec
    sfinv.set_player_inventory_formspec(player)
end

player_api.reset_equipment_effects = function(player)
    return player_api.update_equipment_effects (player, naked)
end
