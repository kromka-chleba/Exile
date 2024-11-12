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
    -- retain for its use of description if a different node is sought for its tiles/inventory_image
    local return_node = node
    -- checks for nodes that are variations of other cubic ones
    if node and node.groups then
        -- show proper image for sediments if slope
        if node.node_box and node.groups.sediment then
            node_name = node.groups.wet_sediment == 2 and node._wet_salty_name or
            node.groups.wet_sediment == 1 and node._wet_name or node._dry_name
        elseif node.mesh and node.groups.cracky then
            -- boulder or cobble
            if node.groups.boulder or node.groups.temp_flow then
                node_name = node.name:sub(1,-9)
            end
        end
        node = type(node_name) == "string" and minetest.registered_nodes[node_name] or node
    end
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

        return inventorycube(tiles[1], tiles[6], tiles[3]), "node", return_node
    end
end

function what_is_this_uwu.show_background(player, whud)
    player:hud_change(whud.bg_left, "text", "wit_left_side.png")
    player:hud_change(whud.bg_mid, "text", "wit_middle.png")
    player:hud_change(whud.bg_right, "text", "wit_right_side.png")
end


local function calculate_size(strings, lang_code)
    local x_size = 0 local count = #strings

    for i = 1, count do
        strings[i] = core.get_translated_string(lang_code, strings[i])
        local size = string_to_pixels(strings[i], lang_code) - 18
        if size > x_size then x_size = size end
    end

    local _, extra_lines = string.gsub(strings[1], "%\n", "") -- multiline desc
    count = count + extra_lines - 2
    if count < 0 then count = 0 end
    local y_size = 2 + (count / 2)
    return x_size, y_size

end
local function format_strings(strings, lang_code)
    local lf_added = {}
    for i = 1, #strings do
        local foo = table.concat({ strings[i],
                (i < #strings and "\n" or nil )
        })
        lf_added[i] = foo
    end
    local out = table.concat(lf_added)
    return out
end

local function update_size(...)
    local player, whud, fm_view, descriptions, _, item_type, lang_code = ...
    local sizex, sizey = calculate_size(descriptions, lang_code)
    local y_scale = sizey
    local y_off = 33 + 2 * sizey
    player:hud_change(whud.bg_mid, "scale", { x = sizex / 16 + 1.5,
                                              y = y_scale })
    player:hud_change(whud.bg_mid, "offset", { x = -sizex / 2 - 9.5,
                                               y = y_off })
    player:hud_change(whud.bg_right, "offset", { x = sizex / 2 + 30,
                                                 y = y_off })
    player:hud_change(whud.bg_right, "scale", { x = 2,
                                              y = y_scale })
    player:hud_change(whud.bg_left, "offset", { x = -sizex / 2 - 25,
                                                y = y_off })
    player:hud_change(whud.bg_left, "scale", { x = 2,
                                              y = y_scale })
    player:hud_change(whud.image, "offset", { x = -sizex / 2 - 12.5,
                                              y = y_off })
    player:hud_change(whud.name, "offset",
                      { x = -sizex / 2 + (fm_view == "" and -3.5 or 16.5), y = y_off })
end

function what_is_this_uwu.show(player, form_view, descs, node_name,
                               item_type, extra)
    local pname = player:get_player_name()
    local w = witt_huds[pname]

    if w.hidden == true then
        what_is_this_uwu.show_background(player, w)
    end

    if item_type ~= "entity" then
        if minetest.registered_items[node_name]
            and minetest.registered_items[node_name]._orig_desc then
            descs[1] = minetest.registered_items[node_name]._orig_desc
        end
    end
    w.hidden = false
    local info = minetest.get_player_information(player:get_player_name())

    update_size(player, w, form_view, descs, node_name,
                item_type, info.lang_code)
    player:hud_change(w.image, "text", form_view)

    local tr_descs = format_strings(descs, info.lang_code)

    player:hud_change(w.name, "text", tr_descs)

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
