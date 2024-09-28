

local modpath = minetest.get_modpath(minetest.get_current_modname())

local colors = {
    white = "FFFFFF",
    red = "FF0000",
}

for color, hex in pairs(colors) do
    local desc = color:gsub("%a", string.upper, 1)
    desc = desc:gsub("_", " ")

    local def = {
        description = desc.." Cotton Hat",
        inventory_image = "clothing_inv_hat.png^[multiply:#"..hex,
        uv_image = "(clothing_uv_hat.png^[multiply:#"..hex..")",
        stack_max = 1,
        groups = {cloth = 1}, -- Hat
        temp_min = 2,
        temp_max = 2,
        on_equip = clothing.default_equip,
        on_unequip = clothing.default_unequip
    }
    minetest.register_craftitem("clothing:hat_"..color, def)

    def = {
        description = desc.." Cotton Shirt",
        inventory_image = "clothing_inv_shirt.png^[multiply:#"..hex,
        uv_image = "(clothing_uv_shirt.png^[multiply:#"..hex..")",
        groups = {cloth = 2}, -- Upper part
        temp_min = 4,
        temp_max = 2,
        on_equip = clothing.default_equip,
        on_unequip = clothing.default_unequip
    }
    minetest.register_craftitem("clothing:shirt_"..color, def)

    def = {
        description = desc.." Cotton Pants",
        inventory_image = "clothing_inv_pants.png^[multiply:#"..hex,
        uv_image = "(clothing_uv_pants.png^[multiply:#"..hex..")",
        groups = {cloth = 3}, -- Lower part
        temp_min = 3,
        temp_max = 2,
        on_equip = clothing.default_equip,
        on_unequip = clothing.default_unequip
    }
    minetest.register_craftitem("clothing:pants_"..color, def)

    def = {
        description = desc.." Cotton Cape",
        inventory_image = "clothing_inv_cape.png^[multiply:#"..hex,
        uv_image = "(clothing_uv_cape.png^[multiply:#"..hex..")",
        groups = {cloth = 5}, -- Cape
        temp_min = 1,
        temp_max = 1,
        on_equip = clothing.default_equip,
        on_unequip = clothing.default_unequip
    }
    minetest.register_craftitem("clothing:cape_"..color, def)

    def = {
        description = desc.." Shoes",
        inventory_image = "clothing_inv_shoes.png^[multiply:#"..hex,
        uv_image = "(clothing_uv_shoes.png^[multiply:#"..hex..")",
        groups = {cloth = 4}, -- Footwear
        temp_min = 1,
        temp_max = 1,
        on_equip = clothing.default_equip,
        on_unequip = clothing.default_unequip
    }
    minetest.register_craftitem("clothing:shoes_"..color, def)

end
