-- cloth composing -------------------------------------------------------------

-- Internationalization---------------------------------------------------------
local S = minetest.get_translator("player_api")
--------------------------------------------------------------------------------

local cloth_pos = {
    "48,0",
    "32,32",
    "0,32",
    "0,32",
    "0,0",
    "0,32",
}

function player_api.compose_cloth(player)
    if not minetest.is_player(player) then print("NOT A PLAYER") return end
    local gender = player_api.get_gender(player)
    local inv = player:get_inventory()
    local upper_ItemStack, lower_ItemStack, footwear_ItemStack, head_ItemStack, cape_ItemStack, blanket_ItemStack
    local underwear = false
    local bra = false
    local attached_cloth = {}
    local blanket = false

    for _, name in ipairs(player_api.get_inv_names()) do
        local stack = inv:get_stack(name, 1)
        local item_name = stack:get_name()
        local cloth_itemstack = minetest.registered_items[item_name]
        --minetest.chat_send_all(item_name)
        local cloth_type = minetest.get_item_group(item_name, "cloth")
        --if cloth_type then minetest.chat_send_all(cloth_type) end
        local color = ""
        local indx = stack:get_meta():get_int("palette_index") / 8
        local dye = dye_to_colorstring(indx)
        if indx and indx > 0 and not ( dye == "" ) then
            color = "\\^\\[multiply\\:\\"..dye
        end
        if cloth_type == 1 then
            head_ItemStack = cloth_itemstack._cloth_texture..color
        elseif cloth_type == 2 then
            upper_ItemStack = cloth_itemstack._cloth_texture..color
            bra = true
        elseif cloth_type == 3 then
            lower_ItemStack = cloth_itemstack._cloth_texture..color
            underwear = true
        elseif cloth_type == 4 then
            footwear_ItemStack = cloth_itemstack._cloth_texture..color
        elseif cloth_type == 5 then
            cape_ItemStack = cloth_itemstack._cloth_texture..color
        elseif cloth_type == 6 then
            blanket_ItemStack = cloth_itemstack._cloth_texture..color
            blanket = true
        end
        if cloth_itemstack and cloth_itemstack._cloth_attach then
            attached_cloth[#attached_cloth+1] = cloth_itemstack._cloth_attach
        end
    end
    local naked = false
    if not(bra) and gender == "female" then
        upper_ItemStack = "cloth_upper_underwear_default.png"
    end
    if not(underwear) then
        lower_ItemStack = "cloth_lower_underwear_default.png"
        naked = true
    end
    local st = player_api.get_state(player)
    if naked == true and blanket == false then
        st:add_basic("naked", S("Naked"))
    elseif st:is("naked") then
        st:clear("naked")
    end
    local base_texture = player_api.compose_base_texture(
        player, {
            canvas_size ="128x64",
            skin_texture = "player_skin.png",
            eyebrowns_pos = "16,16",
            eye_right_pos = "18,20",
            eye_left_pos = "26,24",
            mouth_pos = "16,28",
            hair_preview = false,
            hair_pos = "0,0",
    })
    local cloth = base_texture.."^".."[combine:128x64"
    if head_ItemStack then
        cloth = cloth .. ":"..cloth_pos[1].."="..head_ItemStack
    end
    if upper_ItemStack then
        cloth = cloth .. ":"..cloth_pos[2].."="..upper_ItemStack
    end
    if lower_ItemStack then
        cloth = cloth .. ":"..cloth_pos[3].."="..lower_ItemStack
    end
    if footwear_ItemStack then
        cloth = cloth .. ":"..cloth_pos[4].."="..footwear_ItemStack
    end
    if cape_ItemStack then
        cloth = cloth .. ":"..cloth_pos[5].."="..cape_ItemStack
    end
    if blanket_ItemStack then
        cloth = cloth .. ":"..cloth_pos[6].."="..blanket_ItemStack
    end
    --Now attached cloth
    if not(next(attached_cloth) == nil) then
        for i = 1, #attached_cloth do
            local attached_item_name = attached_cloth[i]
            local attached_itemstack =
                minetest.registered_items[attached_item_name]
            local attached_cloth_type =
                minetest.get_item_group(attached_item_name, "cloth")
            cloth = cloth .. ":"..cloth_pos[attached_cloth_type]..
                "="..attached_itemstack._cloth_texture
        end
    end
    return cloth
end
