local yoff = 0.15

minetest.register_on_joinplayer(function(player)
	local meta = player:get_meta()

	local background_id_left = player:hud_add({
		hud_elem_type = "image",
		position = {x = 0.5, y = yoff},
		scale = {x = 2, y = 2},
		text = '',
		offset = {x = -50, y = 35},
	})
	local background_id_middle = player:hud_add({
		hud_elem_type = "image",
		position = {x = 0.5, y = yoff},
		scale = {x = 2, y = 2},
		text = '',
		alignment = {x = 1},
		offset = {x = -37.5, y = 35},
	})
	local background_id_right = player:hud_add({
		hud_elem_type = "image",
		position = {x = 0.5, y = yoff},
		scale = {x = 2, y = 2},
		text = '',
		offset = {x = 0, y = 35},
	})

	local image_id = player:hud_add({
		hud_elem_type = "image",
		position = {x = 0.5, y = yoff},
		scale = {x = 0.3, y = yoff + 0.3},
		offset = {x = -35, y = 35},
	})
	local name_id = player:hud_add({
		hud_elem_type = "text",
		position = {x = 0.5, y = yoff},
		scale = {x = 0.3, y = yoff + 0.3},
		number = 0xffffff,
		alignment = {x = 1},
		offset = {x = 0, y = 22}
	})

	meta:set_string('wit:background_left', background_id_left)
	meta:set_string('wit:background_middle', background_id_middle)
	meta:set_string('wit:background_right', background_id_right)
	meta:set_string('wit:image', image_id)
	meta:set_string('wit:name', name_id)
	meta:set_string('wit:pointed_thing', 'ignore')
	meta:set_string('wit:item_type_in_pointer', 'node')
end)

local what_is_this_uwu = {
	players = {},
	players_set = {},
}

local char_width = {
	A = 12,
	B = 10,
	C = 13,
	D = 12,
	E = 11,
	F = 9,
	G = 13,
	H = 12,
	I = 3,
	J = 9,
	K = 11,
	L = 9,
	M = 13,
	N = 11,
	O = 13,
	P = 10,
	Q = 13,
	R = 12,
	S = 10,
	T = 11,
	U = 11,
	V = 10,
	W = 15,
	X = 11,
	Y = 11,
	Z = 10,
	a = 10,
	b = 8,
	c = 8,
	d = 9,
	e = 9,
	f = 5,
	g = 9,
	h = 9,
	i = 2,
	j = 6,
	k = 8,
	l = 4,
	m = 13,
	n = 8,
	o = 10,
	p = 8,
	q = 10,
	r = 4,
	s = 8,
	t = 5,
	u = 8,
	v = 8,
	w = 12,
	x = 8,
	y = 8,
	z = 8,
	[" "] = 5,
	["_"] = 9,
}

local function string_to_pixels(str)
	local size = 0
	for char in str:gmatch(".") do
		size = size + (char_width[char] or 14)
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

function what_is_this_uwu.destrange(str)
	if not str:match("") then
		return str
	end

	local reading = true
	local between_parenthesis = false
	local temp_str = ""

	for char in str:gmatch(".") do
	   between_parenthesis = between_parenthesis or char == "("
	   if char:match("") then
	      reading = false
	   elseif reading and not between_parenthesis then
	      temp_str = temp_str .. char
	   else
	      reading = true
	   end
	   between_parenthesis =  (between_parenthesis and char ~= ")")

	end

	return temp_str
end

function what_is_this_uwu.register_player(player, name)
	if what_is_this_uwu.players_set[name] then
		return
	end

	table.insert(what_is_this_uwu.players, player)
	what_is_this_uwu.players_set[name] = true
end

function what_is_this_uwu.remove_player(name)
	if not what_is_this_uwu.players_set[name] then
		return
	end

	what_is_this_uwu.players_set[name] = false

	for i, player in ipairs(what_is_this_uwu.players) do
		if player == name then
			table.remove(what_is_this_uwu.players, i)
			break
		end
	end
end

function what_is_this_uwu.get_pointed_thing(player)
	local playerName = player:get_player_name()
	if not what_is_this_uwu.players_set[playerName] then
		return
	end

	local player_pos = player:get_pos() + vector.new(0, player:get_properties().eye_height, 0) + player:get_eye_offset()

	local node_name = minetest.get_node(player_pos).name
	local see_liquid = minetest.registered_nodes[node_name].drawtype ~= "liquid"

	local tool_range = player:get_wielded_item():get_definition().range or minetest.registered_items[""].range or 5
	local end_pos = player_pos + player:get_look_dir() * tool_range

	local ray = minetest.raycast(player_pos, end_pos, false, see_liquid)
	return ray:next()
end

function what_is_this_uwu.get_node_tiles(node_name)
	local node = minetest.registered_nodes[node_name]
	if not node or (not node.tiles and not node.inventory_image) then
		return "ignore", "node", false
	end

	if node.groups["not_in_creative_inventory"] then
		local drop = node.drop
		if drop and type(drop) == "string" and drop ~= "" then
			node = minetest.registered_nodes[drop] or minetest.registered_craftitems[drop]
		end
	end

	local tiles = node.tiles or {}

	if node.inventory_image:sub(1, 14) == "[inventorycube" then
		return node.inventory_image .. "^[resize:146x146", "node", node
	elseif node.inventory_image ~= "" then
		return node.inventory_image .. "^[resize:16x16", "craft_item", node
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

function what_is_this_uwu.show_background(player, meta)
	player:hud_change(meta:get_string("wit:background_left"), "text", "wit_left_side.png")
	player:hud_change(meta:get_string("wit:background_middle"), "text", "wit_middle.png")
	player:hud_change(meta:get_string("wit:background_right"), "text", "wit_right_side.png")
end


local function update_size(...)
	local player, meta, _, node_description, _, item_type = ...
	local size
	size = string_to_pixels(node_description) - 18
	local desize = false
	if item_type == "entity" then
	   desize = true
	   size = size + 18
	end

	player:hud_change(meta:get_string("wit:background_middle"), "scale", { x = size / 16 + 1.5, y = 2 })
	player:hud_change(meta:get_string("wit:background_middle"), "offset", { x = -size / 2 - 9.5, y = 35 })
	player:hud_change(meta:get_string("wit:background_right"), "offset", { x = size / 2 + 30, y = 35 })
	player:hud_change(meta:get_string("wit:background_left"), "offset", { x = -size / 2 - 25, y = 35 })
	player:hud_change(meta:get_string("wit:image"), "offset", { x = -size / 2 - 12.5, y = 35 })
	player:hud_change(meta:get_string("wit:name"), "offset", { x = -size / 2 + ( desize and 0 or 16.5), y = 35 })
end

function what_is_this_uwu.show(player, meta, form_view, desc, node_name, item_type)
	if meta:get_string("wit:pointed_thing") == "ignore" then
		what_is_this_uwu.show_background(player, meta)
	end

	meta:set_string("wit:pointed_thing", node_name)

	if item_type ~= "entity" then
	   if minetest.registered_items[node_name]
	      and minetest.registered_items[node_name]._orig_desc then
	      desc = minetest.registered_items[node_name]._orig_desc
	   end
	end
	local info = minetest.get_player_information(player:get_player_name())
	local desc_tr = minetest.get_translated_string(info.lang_code, desc)

	update_size(player, meta, form_view, desc_tr, node_name, item_type)
	player:hud_change(meta:get_string("wit:image"), "text", form_view)

	player:hud_change(meta:get_string("wit:name"), "text", desc_tr)

	local scale = { x = 0.3, y = 0.3 }
	if item_type ~= "node" then
		scale = { x = 2.5, y = 2.5 }
	end

	meta:set_string("wit:item_type_in_pointer", item_type)
	player:hud_change(meta:get_string("wit:image"), "scale", scale)
end

function what_is_this_uwu.unshow(player, meta)
	if not meta then
		return
	end
	meta:set_string("wit:pointed_thing", "ignore")

	local hud_elements = {
		"wit:background_left",
		"wit:background_middle",
		"wit:background_right",
		"wit:image",
		"wit:name",
	}

	for _, element in ipairs(hud_elements) do
		player:hud_change(meta:get_string(element), "text", "")
	end
end

return what_is_this_uwu
