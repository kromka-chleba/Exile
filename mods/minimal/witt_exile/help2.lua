local yoff = 0.15

local witt_huds = {}

minetest.register_on_joinplayer(function(player)
      local pname = player:get_player_name()
      local inv = minetest.get_inventory({type = "player",
					   name = pname})
      inv:set_size("witt", 1)

      local background_id_left = player:hud_add({
	    hud_elem_type = "image",
	    position = {x = 0.5, y = yoff},
	    scale = {x = 2.5, y = 2.5},
	    text = '',
	    offset = {x = -50, y = 35},
      })
      local background_id_middle = player:hud_add({
	    hud_elem_type = "image",
	    position = {x = 0.5, y = yoff},
	    scale = {x = 2.5, y = 2.5},
	    text = '',
	    alignment = {x = 1},
	    offset = {x = -37.5, y = 35},
      })
      local background_id_right = player:hud_add({
	    hud_elem_type = "image",
	    position = {x = 0.5, y = yoff},
	    scale = {x = 2.5, y = 2.5},
	    text = '',
	    offset = {x = 0, y = 35},
      })

      local image_id = player:hud_add({
	    hud_elem_type = "inventory",
	    text="witt",
	    number = 1,
	    item = 1,
	    position = {x = 0.48, y = yoff - .025},
	    offset = {x = -35, y = 35},
      })
      local image_bar = player:hud_add({
	    hud_elem_type = "image",
	    text="",
	    number = 0,
	    item = 1,
	    position = {x = 0.479, y = yoff + 0.001},
	    z_index = 1,
	    scale = {x = 1.02 , y = 1.02 },
	    offset = {x = -35, y = 35},
      })
      local name_id = player:hud_add({
	    hud_elem_type = "text",
	    position = {x = 0.5, y = yoff},
	    scale = {x = 0.3, y = yoff + 0.3},
	    number = 0xffffff,
	    z_index = 2,
	    alignment = {x = 1},
	    offset = {x = 0, y = 22}
      })


      local w = {}
      w.bg_left = background_id_left
      w.bg_mid = background_id_middle
      w.bg_right = background_id_right
      w.image = image_id
      w.image_bar = image_bar
      w.name = name_id
      w.point = 'ignore'
      w.hidden = false

      witt_huds[pname] = w
end)

local what_is_this_uwu = {
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

local function inventoryslot(pname, name)
   if not minetest.registered_nodes[name] then
      minetest.log("error", "WITT: Tried to view inventory image of non-node "..
		   "item: "..dump(name))
   end
   local Inv = minetest.get_inventory({type="player",
				       name = pname})
   Inv:set_stack("witt", 1, ItemStack(name))
   return
end

function what_is_this_uwu.split_item_name(item_name)
	local splited = {}
	for char in item_name:gmatch("[^:]+") do
		table.insert(splited, char)
	end
	return splited[1], splited[2]
end

function what_is_this_uwu.show_background(player, whud)
	player:hud_change(whud.bg_left, "text", "wit_left_side.png")
	player:hud_change(whud.bg_mid, "text", "wit_middle.png")
	player:hud_change(whud.bg_right, "text", "wit_right_side.png")
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

	player:hud_change(meta:get_string("wit:background_middle"), "scale", { x = size / 16 + 1.5, y = 2.5 })
	player:hud_change(meta:get_string("wit:background_middle"), "offset", { x = -size / 2 - 9.5, y = 35 })
	player:hud_change(meta:get_string("wit:background_right"), "offset", { x = size / 2 + 30, y = 35 })
	player:hud_change(meta:get_string("wit:background_left"), "offset", { x = -size / 2 - 25, y = 35 })
	player:hud_change(meta:get_string("wit:image"), "offset", { x = -size / 2 - 12.5, y = 35 })
	player:hud_change(meta:get_string("wit:name"), "offset", { x = -size / 2 + ( desize and 0 or 16.5), y = 35 })
end

function what_is_this_uwu.show(player, meta, _, desc, node_name, item_type)
   local pname = player:get_player_name()
   local w = witt_huds[pname]
   if w.point == "ignore" then
      what_is_this_uwu.show_background(player, w)
   end
   inventoryslot(pname, node_name)
   w.point = node_name
   if item_type ~= "entity" then
      if minetest.registered_items[node_name]
	 and minetest.registered_items[node_name]._orig_desc then
	 desc = minetest.registered_items[node_name]._orig_desc
      end
   end
   w.hidden = false
   local info = minetest.get_player_information(player:get_player_name())
   local desc_tr = minetest.get_translated_string(info.lang_code, desc)
   update_size(player, meta, nil, desc_tr, node_name, item_type)
   --player:hud_change(w.image, "text", form_view)
   player:hud_change(w.name, "text", desc_tr)
   player:hud_change(w.image, "text", "witt")
   player:hud_change(w.image, "type", "inventory")
   player:hud_change(w.image_bar, "text", "gui_hotbar_blackout.png" )
   --player:hud_change(meta:get_string("wit:image"), "scale", scale)
end

function what_is_this_uwu.unshow(player, meta)
   local pname = player:get_player_name()
   local w = witt_huds[pname]
   if not w or w.hidden then
      return
   end
   w.point = "ignore"

	local hud_elements = {
		"bg_left",
		"bg_mid",
		"bg_right",
		"name",
		"image",
		"image_bar",
	}
	player:hud_change(w.image, "type", "none")

	for _, element in ipairs(hud_elements) do
	   player:hud_change(w[element], "text", "")
	end
	w.hidden = true
end

return what_is_this_uwu
