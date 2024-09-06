local yoff = 0.15

local witt_huds = {}
local hud_type = minimal.hud_type

local function clean_meta(meta)
    -- #TODO: Remove this on or after v4 release
    meta:set_string('wit:background_left', "")
    meta:set_string('wit:background_middle', "")
    meta:set_string('wit:background_right', "")
    meta:set_string('wit:image', "")
    meta:set_string('wit:name', "")
    meta:set_string('wit:pointed_thing', "")
    meta:set_string('wit:item_type_in_pointer', "")
end

minetest.register_on_joinplayer(function(player)

        local meta = player:get_meta()
        if meta:get("wit:image") then clean_meta(meta) end

        local background_id_left = player:hud_add({
                [hud_type] = "image",
                position = {x = 0.5, y = yoff},
                scale = {x = 2, y = 2},
                text = '',
                offset = {x = -50, y = 35},
        })
        local background_id_middle = player:hud_add({
                [hud_type] = "image",
                position = {x = 0.5, y = yoff},
                scale = {x = 2, y = 2},
                text = '',
                alignment = {x = 1},
                offset = {x = -37.5, y = 35},
        })
        local background_id_right = player:hud_add({
                [hud_type] = "image",
                position = {x = 0.5, y = yoff},
                scale = {x = 2, y = 2},
                text = '',
                offset = {x = 0, y = 35},
        })

        local image_id = player:hud_add({
                [hud_type] = "image",
                position = {x = 0.5, y = yoff},
                scale = {x = 0.3, y = yoff + 0.3},
                offset = {x = -35, y = 35},
        })
        local name_id = player:hud_add({
                [hud_type] = "text",
                position = {x = 0.5, y = yoff},
                scale = {x = 0.3, y = yoff + 0.3},
                number = 0xffffff,
                alignment = {x = 1},
                offset = {x = 0, y = 22},
                style = 4
        })

        local w = {}
        w.bg_left = background_id_left
        w.bg_mid = background_id_middle
        w.bg_right = background_id_right
        w.image = image_id
        w.name = name_id
        w.hidden = true

        local pname = player:get_player_name()
        witt_huds[pname] = w
end)

minetest.register_on_leaveplayer(function(player)
        local pname = player:get_player_name()
        witt_huds[pname] = nil
end)

local what_is_this_uwu = {
}

local font_size = minetest.settings:get('font_size') or 16
local default_char_width = math.floor(font_size * 0.65) or 10
local char_width = {
    ja = font_size,
    ko = font_size,
    zh_CN = font_size,
    zh_TW = font_size
}

local function string_to_pixels(str, lang_code)
    local size = 0
    for uchar in string.gmatch(str, "([%z\1-\127\194-\244][\128-\191]*)") do
        size = size + (char_width[lang_code] or default_char_width)
    end
    return size
end

local function inventorycube(img1, img2, img3)
    if not img1 then
        return ""
    end

    local images = { img1, img2, img3 }
    for i = 1, 3 do
        images[i] = images[i] .. "^[resize:16x16"
        images[i] = images[i]:gsub("%^", "&")
    end

    return "[inventorycube{" .. table.concat(images, "{")
end

function what_is_this_uwu.split_item_name(item_name)
    local splited = {}
    for char in item_name:gmatch("[^:]+") do
        table.insert(splited, char)
    end
    return splited[1], splited[2]
end

function what_is_this_uwu.get_node_tiles(node_name)
    local node = minetest.registered_nodes[node_name]
    if not node or (not node.tiles and not node.inventory_image) then
        return "ignore", "node", false
    end

    if node.groups["not_in_creative_inventory"] then
        local drop = node.drop
        if drop and type(drop) == "string" and drop ~= "" then
            node = minetest.registered_nodes[drop]
                or minetest.registered_craftitems[drop]
        end
    end

    local tiles = node.tiles or {}

    if node.inventory_image:sub(1, 14) == "[inventorycube" then
        return node.inventory_image .. "^[resize:146x146", "node", node
    elseif node.inventory_image ~= "" then
        return node.inventory_image .. "^[resize:16x16", "craft_item", node
    elseif node.drawtype == "nodebox" or node.drawtype == "mesh" then
        return "", "node", node
    else
        tiles[3] = tiles[3] or tiles[1]
        tiles[6] = tiles[6] or tiles[3]

        if type(tiles[1]) == "table" then
            tiles[1] = tiles[1].name
        end
        if type(tiles[3]) == "table" then
            tiles[3] = tiles[3].name
        end
        if type(tiles[6]) == "table" then
            tiles[6] = tiles[6].name
        end

        return inventorycube(tiles[1], tiles[6], tiles[3]), "node", node
    end
end

function what_is_this_uwu.show_background(player, whud)
    player:hud_change(whud.bg_left, "text", "wit_left_side.png")
    player:hud_change(whud.bg_mid, "text", "wit_middle.png")
    player:hud_change(whud.bg_right, "text", "wit_right_side.png")
end


local function update_size(...)
    local player, whud, _, node_description, _, item_type, lang_code = ...
    local size = string_to_pixels(node_description, lang_code) - 18
    local desize = false
    if item_type == "entity" then
        desize = true
        size = size + 18
    end

    player:hud_change(whud.bg_mid, "scale", { x = size / 16 + 1.5, y = 2 })
    player:hud_change(whud.bg_mid, "offset", { x = -size / 2 - 9.5, y = 35 })
    player:hud_change(whud.bg_right, "offset", { x = size / 2 + 30, y = 35 })
    player:hud_change(whud.bg_left, "offset", { x = -size / 2 - 25, y = 35 })
    player:hud_change(whud.image, "offset", { x = -size / 2 - 12.5, y = 35 })
    player:hud_change(whud.name, "offset",
                      { x = -size / 2 + ( desize and 0 or 16.5), y = 35 })
end

function what_is_this_uwu.show(player, form_view, desc, node_name, item_type)
    local pname = player:get_player_name()
    local w = witt_huds[pname]

    if w.hidden == true then
        what_is_this_uwu.show_background(player, w)
    end

    if item_type ~= "entity" then
        if minetest.registered_items[node_name]
            and minetest.registered_items[node_name]._orig_desc then
            desc = minetest.registered_items[node_name]._orig_desc
        end
    end
    w.hidden = false
    local info = minetest.get_player_information(player:get_player_name())
    local desc_tr = minetest.get_translated_string(info.lang_code, desc)

    update_size(player, w, form_view, desc_tr, node_name,
                item_type, info.lang_code)
    player:hud_change(w.image, "text", form_view)

    player:hud_change(w.name, "text", desc_tr)

    local scale = { x = 0.3, y = 0.3 }
    if item_type ~= "node" then
        scale = { x = 2.5, y = 2.5 }
    end

    player:hud_change(w.image, "scale", scale)
end

function what_is_this_uwu.unshow(player)
    local pname = player:get_player_name()
    local w = witt_huds[pname]
    if not w or w.hidden then
        return
    end
    local hud_elements = {
        "bg_left",
        "bg_mid",
        "bg_right",
        "name",
        "image",
    }

    for _, element in ipairs(hud_elements) do
        player:hud_change(w[element], "text", "")
    end
    w.hidden = true
end

return what_is_this_uwu
