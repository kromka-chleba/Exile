local S = minetest.get_translator("spears")

function spears_register_spear(
        spear_type, desc, base_damage, toughness, material, exilectype)

    minetest.register_tool(
        "spears:spear_" .. spear_type, {
            description = S("@1 spear", desc),
            wield_image = "spears_spear_" .. spear_type ..
                ".png^[transform4",
            inventory_image = "spears_spear_" .. spear_type .. ".png",
            wield_scale= {x = 1.5, y = 1.5, z = 1.5},
            on_secondary_use = function(itemstack, user, pointed_thing)
                local thrown = spears_throw(itemstack, user,
                                            pointed_thing)
                if thrown == true and not EXILE.player_in_creative(user) then
                    itemstack:take_item()
                end
                return itemstack
            end,
            on_place = function(itemstack, user, pointed_thing)
                local thrown = spears_throw(itemstack, user, pointed_thing)
                if thrown == true and not EXILE.player_in_creative(user) then
                    itemstack:take_item()
                end
                return itemstack
            end,
            tool_capabilities = {
                full_punch_interval = 1.5,
                max_drop_level=1,
                damage_groups = {fleshy=base_damage},
            },
            sound = {breaks = "default_tool_breaks"},
            groups = {flammable = 1}
    })

    local SPEAR_ENTITY = spears_set_entity(spear_type, base_damage, toughness)

    minetest.register_entity(
        "spears:spear_" .. spear_type .. "_entity", SPEAR_ENTITY)

    if minetest.get_modpath("exile_game") then
        crafting.register_recipe({
                type = exilectype,
                output = 'spears:spear_' .. spear_type,
                items = {'tech:stick 2', material},
                level = 1,
                always_known = true,
        })
    end
end

if minetest.get_modpath("exile_game") then
    --TODO Make spears_register_spear() allow registering multiple crafting stations
    spears_register_spear('stone', S('Stone'), 8, 20,
                          'tech:stone_chopper', "hand_tools")
    spears_register_spear('iron', S('Iron'), 14, 30,
                          'tech:iron_ingot', "anvil")
    minetest.register_alias("spears:spear_steel",
                            "spears:spear_iron")
end
