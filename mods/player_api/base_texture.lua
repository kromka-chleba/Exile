player_api.hair_colors = {
    black = {
        color = "#000000",
        ratio = 175,
    },
    gray = nil,
    brown = {
        color = "#7a4c20",
        ratio = 150,
    },
    red = {
        color = "#ed6800",
        ratio = 140,
    },
    blonde = {
        color = "#a79d46",
        ratio = 150,
    },
}

-- Color parameters used to customize textures based on a player's skin color.
-- `color` and `ratio` are used to modify the rgb image player_skin.png  using
-- `[colorize ...` while `multiply_color` is used to modify the greyscale image
-- `player_hand.png` using `multiply` resulting in the same skin colors, while
-- retaining shading.
player_api.skin_colors = {
    tan = {
        -- for adapting skin texture
        color = "#e1bc9e",
        ratio = 255,
        -- NOTE: ratio = 255 replaces the texture entirely! This value was
        --       applied implicitly before it got added here for readability.
        multiply_color = "#ebc4a5",
    },
    pale = {
        color = "#ddeded",
        ratio = 150,
        multiply_color = "#e8e2d5",
    },
    red = {
        color = "#b04d20",
        ratio = 150,
        multiply_color = "#cd8057",
    },
    yellow = {
        color = "#ada540",
        ratio = 150,
        multiply_color = "#cbb66b",
    },
    brown = {
        color = "#a56d40",
        ratio = 220,
        multiply_color = "#b57d50",
    },
    black = {
        color = "#462409",
        ratio = 240,
        multiply_color = "#522e12",
    },
    --unnatural colors
    greenmen = {
        color = "#21b31e",
        ratio = 160,
        multiply_color = "#6dbe4d",
    },
    bluemen = {
        color = "#0031c3",
        ratio = 140,
        multiply_color = "#6a74ba",
    },
    graymen = {
        color = "#909090",
        ratio = 250,
        multiply_color = "#989796",
    },
    redmen = {
        color = "#ff1010",
        ratio = 250,
        multiply_color = "#ff1413",
    },
}

---register wieldhand skin variants for each skin texture
for nm, val in pairs(player_api.skin_colors) do
    local newdef = table.copy(minetest.registered_items["player_api:hand"])
    newdef.wield_image = "player_hand.png" ..
        "^[multiply:" .. val.multiply_color
        core.log("skin variant " .. newdef.wield_image .. " " .. nm)
    newdef.inventory_image = newdef.wield_image
    minetest.register_item("player_api:hand_"..nm, newdef)
end

function player_api.load_base_texture_table(player)
    local meta = player:get_meta()
    local base_texture_str = meta:get_string("base_texture")
    if base_texture_str == nil or base_texture_str == "" then
        player_api.set_base_textures(player)
        base_texture_str = player:get_meta():get_string("base_texture")
    end
    local base_texture = minetest.deserialize(base_texture_str)
    return base_texture
end

function player_api.save_base_texture(player, base_texture)
    local meta = player:get_meta()
    meta:set_string("base_texture", minetest.serialize(base_texture))
end

function player_api.set_base_textures(player)
    local base_texture = {}
    local gender = player_api.get_gender(player)
    if gender == "male" then
        --base_texture["eyebrowns"] = {texture = "player_eyebrowns_default.png", color = nil}
        base_texture["eye"] = "player_brown_eye.png"
        base_texture["mouth"] = {texture = "player_male_mouth_default.png",
                                 color = nil}
        base_texture["hair"] = {texture = "player_male_hair_default.png",
                                color = "brown"}
    else
        --base_texture["eyebrowns"] = {texture = "player_eyebrowns_default.png", color = nil}
        base_texture["eye"] = "player_blue_eye.png"
        base_texture["mouth"] = {texture = "player_female_mouth_default.png",
                                 color = nil}
        base_texture["hair"] = {texture = "player_female_hair_default.png",
                                color = "brown"}
    end
    base_texture["skin"] = {texture = "player_skin.png", color = "normal"}
    player_api.save_base_texture(player, base_texture)
end

function player_api.colorize_texture(player, what, texture)
    local base_texture = player_api.load_base_texture_table(player)
    if base_texture[what]["color"] then
        local value
        if what == "skin" then
            value = player_api.skin_colors[base_texture[what]["color"]]
        else --"hair"
            value = player_api.hair_colors[base_texture[what]["color"]]
        end
        if value then
            return texture .. "\\^\\[colorize\\:\\"..
                value.color.."\\:"..tostring(value.ratio)
        else
            return texture
        end
    else
        return texture
    end
end

function player_api.compose_base_texture(player, def)
    local base_texture = player_api.load_base_texture_table(player)
    local texture = player_api.colorize_texture(
        player, "skin", "[combine:"..def.canvas_size..":0,0="..def.skin_texture)
    local inv = player:get_inventory()
    local handstring = "player_api:hand_"..base_texture["skin"]["color"]
    inv:set_stack("hand", 1, handstring)

    local ordered_keys = {}

    for key in pairs(base_texture) do
        table.insert(ordered_keys, key)
    end

    table.sort(ordered_keys)

    for i = 1, #ordered_keys do
        local key, value = ordered_keys[i], base_texture[ordered_keys[i]]
        if key == "eyebrowns" then
            --value.texture = player_api.colorize_texture(player, "eyebrowns", value.texture)
            --texture = texture .. ":"..def.eyebrowns_pos.."="..value.texture
        elseif key == "eye" then
            texture = texture .. ":"..def.eye_right_pos.."="..value
        elseif key == "mouth" then
            texture = texture .. ":"..def.mouth_pos.."="..value.texture
        elseif key == "hair" then
            if def.hair_preview then
                value.texture = string.sub(value.texture, 0, -5).."_preview.png"
            end
            value.texture = player_api.colorize_texture(player, "hair",
                                                        value.texture)
            texture = texture .. ":"..def.hair_pos.."="..value.texture
        end
    end
    return texture
end
