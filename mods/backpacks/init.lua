backpacks = {}
-- Internationalization
local S = minetest.get_translator("backpacks")

local more_info = minetest.settings:get_bool('exile_backpacks_spreadsheet')

local colours = {
  full = "#90c8fc", -- pastel blue
  partial = "#90fca0", -- pastel green
  neutral = "#ffffff", -- white
  item_name = "#ffff7a" -- pastel yellow
}

local function get_formspec(pos, w, h)
	local meta = minetest.get_meta(pos)
	local creator = meta:get_string('creator')
	local label = minimal.sanitize_string(meta:get_string('label'))

	local formspec_size_h = 3.85 + h
	local main_offset = 1.85 + h
	local label_offset = 0.85 + h
	local creator_offset_x =  (3*(30-string.len(creator))/30/2) + 5
	local craftedby_offset_x = 6.05 -- 3*(30-string.len('crafted by'))/30/2 + 5

	local formspec = {
		"size[8,"..formspec_size_h.."]",
		"list[current_name;main;0,0.3;"..w..","..h.."]",
		"field[0.5,"..label_offset..";5,1;label;Label:;"..label.."]",
		"field_close_on_enter[label;false]",
		"button[5,"..label_offset..";1,0.25;labelset;Set]",
		"label["..craftedby_offset_x..","..(label_offset-.35)..";Crafted by:]",
		"label["..creator_offset_x..","..label_offset..";"..creator.."]",
		"list[current_player;main;0,"..main_offset..";8,2]",
		"listring[current_name;main]",
		"listring[current_player;main]",
	}
	minimal.infotext_merge(pos,'Label: '..label, meta)
	return table.concat(formspec, "")
end

local packdump_forms = {}
local function show_packdump_formspec(pos,playername,itemstack,can_dump,can_pack)
  if not (can_dump or can_pack) then return end
  playername = type(playername) == "string" and playername or type(playername) == "userdata" and playername:get_player_name() or nil
  if not playername then return end
  if type(itemstack) ~= "userdata" then return end -- not an itemstack
  local h = 2
  local buttons = {
    dump = can_dump and "button_exit[1.5,dumpheight;4,1;Dump;"..S("Dump Into Storage").."]",
    pack = can_pack and "button_exit[1.5,packheight;4,1;Pack;"..S("Pack Up Storage").."]"
  }
  local spec = ("formspec_version[3]"..
    "size[7,specheight]"..
    "hypertext[0.5,0.75;7,3;introtext;"..itemstack:get_description().."]")
  for bname,button in pairs(buttons) do
    if button then
      spec = spec..(button:gsub(bname.."height",h))
      h = h + 1.5
    end
  end
  spec = spec:gsub("specheight",h)
  minetest.show_formspec(
    playername, "backpacks:packdump",
    spec
  )
  packdump_forms[playername] = pos
end
minetest.register_on_player_receive_fields(function(player,
  formname,fields)
  if formname ~= "backpacks:packdump" then return end
  if not (fields.Dump or fields.Pack) then return end -- don't go through the effort if they didn't press anything
  local pname = player:get_player_name()
  local pos = packdump_forms[pname]
  if not pos then return end
  -- function to remove info
  local function clear()
    packdump_forms[pname] = nil
    return
  end
  local itemstack = player:get_wielded_item() -- this will be important for later
  if itemstack:is_empty() then return clear() end -- or not, we don't even exist!
  -- get node meta + inventory
  local meta = minetest.get_meta(pos)
  local inv = meta:get_inventory()
  if not inv then return clear() end
  -- get node inventory
  local node_inv = minimal.convert_node_inventory(inv,"main")
  if not node_inv then return clear()  end
  -- item metadata (only access if we can get node inventory)
  local item_meta = itemstack:get_meta()
  -- get item inventory object, create an empty inventory if none found
  if not item_meta:get("inv_main") then item_meta:set_string("inv_main","return {}") end -- create inventory to use
  local item_inv = minimal.get_item_inventory(itemstack, item_meta, "inv_main")
  if not item_inv then return clear() end
  -- get inventory lists
  local node_list = node_inv:get_list()
  local item_list = item_inv:get_list()
  -- simply updates inventory
  local function update_inv()
    inv:set_list("main",node_list)
    minimal.set_item_inventory(itemstack, item_meta, "inv_main", item_inv)
    player:set_wielded_item(itemstack)
  end
  -- dump it all into that storage!
  if fields.Dump and (#node_inv:get_full() < node_inv:get_size() and #item_inv:get_empty() ~= #item_list) then
    for index,item in pairs(item_list) do
      item = node_inv:add_item(item)
      item_list[index] = item
    end
    update_inv()
  -- pack up that storage
  elseif fields.Pack and (#item_inv:get_full() < item_inv:get_size()) then
    for index,item in pairs(node_list) do
      item = item_inv:add_item(item)
      node_list[index] = item
    end
    update_inv()
  end
  clear() 
end)

local function get_description(node,meta,bag_name,add_string)
	local desc = bag_name--minetest.registered_nodes[node.name].description
	local label = meta:get_string('label')
	if label ~= '' then
		desc = desc.." - "..label
	end
  if type(add_string) == "string" and add_string ~= "" then
    desc = desc..add_string
  end
	return desc
end

local after_place_node = function(pos, placer, itemstack, pointed_thing)
	local node = minetest.get_node(pos)
	local meta = minetest.get_meta(pos)
	local imeta = itemstack:get_meta()

	-- Load inventory
	local inv_main = imeta:get_string('inv_main')
	local inv=meta:get_inventory()
	-- compatability for worlds created earlier then v0.3.9
	-- minetest.get_metadata() deprecated but old maps used it
	-- causes contents of backpacks stored in inventory to be forgotton
	local stuff = minetest.deserialize(itemstack:get_metadata())
	if stuff then
		local deprecated_inventory = stuff.inventory.main
		-- inv_main will be empty if stuff exists so safe to overwrite
		inv_main = minetest.serialize(deprecated_inventory)
	end
	if inv_main then
		inv:set_list('main',minetest.deserialize(inv_main))
	end
	-- set color
	if minetest.is_player(placer) == true then
	   local face = { x = 0, y = 0, z = 1}
	   local axis = { x = 0, y = 1, z = 0}
	   local ldir = placer:get_look_horizontal()
	   ldir = vector.rotate_around_axis(face, axis, ldir)
	   local ndir = minetest.dir_to_wallmounted(ldir)
	   local color = minetest.strip_param2_color(node.param2,
						     "colorwallmounted")
	   node.param2 = color + ndir
	   minetest.swap_node(pos, node)
	end
  if not minimal.player_in_creative(placer) then
    itemstack:take_item()
  end
end

local preserve_metadata = function(pos, oldnode, oldmeta, drops,width,height)
	local item = drops[1]
	local imeta = item:get_meta()
  local idef = item:get_definition()
  local bag_name = idef.description
	-- Transfer inventory to item
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	local list = {}
  local for_calculation = {}
  local space_taken = {0,0,0} -- full, partial, empty
	for i, stack in ipairs(inv:get_list("main")) do
		if stack:get_name() == "" then
			list[i] = ""
      space_taken[3] = space_taken[3] + 1 -- nothing in itemstack, considered "empty"
		else
			list[i] = stack:to_string()
      local stack_count = stack:get_count()
      local stack_max = stack:get_stack_max()
      if (stack_count >= stack_max) then
        -- allow for a stack count greater than its stack max in case of weirdness
        -- to calculate for "full"
        space_taken[1] = space_taken[1] + 1
      else
        -- less than stack_max, considered "partial"
        space_taken[2] = space_taken[2] + 1
      end
      local stack_table = for_calculation[stack:get_name()]
      if not stack_table then
        stack_table = {1, stack_count, stack_max} -- item_name, indexes filled, total count, total counted max capacity
      else
        stack_table[1] = stack_table[1] + 1 -- indexes occupied
        stack_table[2] = stack_table[2] + stack_count
        stack_table[3] = stack_table[3] + stack_max
      end
      for_calculation[stack:get_name()] = stack_table
		end
	end
  local list_size = space_taken[1] + space_taken[2] -- full + partial
  local add_string
  if list_size > 0 then
    imeta:set_string('inv_main', minetest.serialize(list)) -- set list as "inv_main" metadata for item
    local highest_data
    for item_name,data in pairs(for_calculation) do
      -- highest_data calculation
      if not highest_data then
        highest_data = data
        table.insert(highest_data,1,item_name) -- add item's name to beginning of table
      elseif data[1] > highest_data[2] then
        highest_data = data
        table.insert(highest_data,1,item_name)
      end
    end
    -- add the "[[" to the beginning to see what has to be removed to remove popular_item (other parts of code will become unnecessary)
    local popular_item = ItemStack(highest_data[1])
    if popular_item then
      if popular_item:get_short_description() then
        popular_item = popular_item:get_short_description()
      else
        popular_item = popular_item:get_description()
      end
      popular_item = popular_item.." "..highest_data[3].."/"..highest_data[4] -- amount of items/amount of max possible items
    else
      popular_item = ""
    end
    --]]
    local inv_max = inv:get_size("main")
    if list_size == inv_max then
      -- full or near full, set full_name
      bag_name = idef._full_name
    end
    local text_colours = {
      minetest.get_color_escape_sequence(colours["full"]), -- full
      minetest.get_color_escape_sequence(colours["partial"]), -- partial
      minetest.get_color_escape_sequence(colours["neutral"]), -- empty
      minetest.get_color_escape_sequence(colours["item_name"]) -- item_name
    }
    popular_item = text_colours[4]..popular_item -- remove if removing popular_item
    space_taken[1] = text_colours[1]..(more_info and S("@1 full", space_taken[1]) or space_taken[1])
    space_taken[2] = text_colours[2]..(more_info and S("@1 partial", space_taken[2]) or space_taken[2])
    space_taken[3] = text_colours[3]..(more_info and S("@1 empty", space_taken[3]) or space_taken[3])
    if more_info then
      space_taken = text_colours[3]..S("Slots: @1, @2, @3", space_taken[1], space_taken[2], space_taken[3])
      add_string = "\n"..popular_item.."\n"..space_taken -- remove "popular_item.."\n".." if removing popular_item
    else
      add_string = " - "..S("@1/@2/@3", space_taken[1]..text_colours[3], space_taken[2]..text_colours[3], space_taken[3])
      -- add_string = " - "..S("@1/@2/@3", space_taken[1], space_taken[2], space_taken[3])
    end
    
  else
    -- empty, no items, set empty_name
    bag_name = idef._empty_name
    imeta:set_string("inv_main","")
  end
	-- Set color
	local color = minetest.strip_param2_color(oldnode.param2,
						  "colorwallmounted")
	imeta:set_int('palette_index', color)
	-- Set Description
	imeta:set_string('description', get_description(oldnode, meta, bag_name, add_string))
	-- Set Formspec
	imeta:set_string('formspec', get_formspec(pos,width,height))
end

local on_dig = function(pos, node, digger, width, height)
	if minetest.is_protected(pos, digger:get_player_name()) then
		return false
	end
	local player_inv = digger:get_inventory()
	-- See if it fits in invenotry
	local new = ItemStack(node)
	if player_inv:room_for_item("main", new) then
		--Call default node_dig() to remove node and make item
		--Causes preserve_metadata() to be called.
		return minetest.node_dig(pos, node, digger)
	end
	return false
end

local allow_metadata_inventory_put = function(pos, listname, index, stack, player)
	if not string.match(stack:get_name(), "backpacks:") then
		return stack:get_count()
	else
		return 0
	end
end

local wallmount_box = {
   type = "fixed",
   fixed = {
      {-0.4375, -0.375, -0.5, 0.4375, 0.375, 0.5}, -- NodeBox1
      {0.125, -0.5, -0.375, 0.375, -0.4375, 0.3125}, -- NodeBox2
      {-0.375, -0.5, -0.375, -0.125, -0.4375, 0.3125}, -- NodeBox3
      {0.125, -0.4375, 0.1875, 0.375, -0.375, 0.375}, -- NodeBox4
      {-0.375, -0.4375, 0.1875, -0.125, -0.375, 0.375}, -- NodeBox5
      {0.125, -0.4375, -0.375, 0.375, -0.375, -0.25}, -- NodeBox6
      {-0.375, -0.4375, -0.375, -0.125, -0.375, -0.25}, -- NodeBox7
      {-0.3125, 0.375, -0.375, 0.3125, 0.4375, 0.1875}, -- NodeBox8
      {-0.25, 0.4375, -0.315, 0.25, 0.5, 0.125}, -- NodeBox9
   }
}


-- backpacks
function backpacks.register_backpack(name, def)
  -- cause errors if incorrect values given
  assert(type(name) == "string","backpacks.register_backpack: given 'name' is not a string! Got '"..type(name).."'")
  assert(type(def) == "table","backpacks.register_backpack: Incorrect value given for expected definition table, got '"..type(def).."'")
  assert(type(def.sounds) == "table","backpacks.register_backpack: did not get a proper sounds table, got '"..type(def.sounds).."'")
  -- correct values
  def.description = def.description or ""
  def.groups = def.groups or {}
  -- permit a tiles override
  if type(def.tiles) ~= "table" then -- create one
    def.tiles = {
      -- rotated onto its back for correct wallmounted dirs
      "backpacks_backpack_front.png", -- Front
      "backpacks_backpack_back.png",      -- Back
      "backpacks_backpack_sides-rotated.png",-- Right Side
      "backpacks_backpack_sides-rotated.png",-- Left Side
		  "backpacks_backpack_topbottom.png", -- Top
		  "backpacks_backpack_topbottom.png", -- Bottom
    }
    -- permit different "textures" name for "texture"
    local texture = def.texture or def.textures
    if type(texture) == "string" then
      -- add texture to backpack
      for tile_index,tile in pairs(def.tiles) do
        def.tiles[tile_index] = texture.."^"..tile
      end
    end
  end
  -- custom "empty_name" and "full_name"
  def._empty_name = def._empty_name or def.empty_name or def.description
  def._full_name = def._full_name or def.full_name or def.description
  -- can_dump and can_pack
  def.can_dump = type(def.can_dump) ~= "boolean" and true or def.can_dump
  def.can_pack = type(def.can_pack) ~= "boolean" and true or def.can_pack
  -- use tip related (use_tips do not properly display)
  --def._use_tip = (def.can_dump and def.can_pack and "Dump or pack" or def.can_dump and "Dump" or def.can_pack and "Pack") or nil
  --def._use_tip = def._use_tip and S("@1 into storage",S(def._use_tip))
  -- formspec params
  def.formspec_width = def.formspec_width or def.width
  def.formspec_height = def.formspec_height or def.height
  -- cleanup of def
  def.empty_name = nil
  def.full_name = nil
  def.width = nil
  def.height = nil
  -- basic def stuff
  def.paramtype2 = def.paramtype2 or "colorwallmounted"
  def.palette = "natural_dyes.png"
  def.drawtype = def.drawtype or "nodebox"
  def.node_box = def.node_box or def.drawtype == "nodebox" and wallmount_box
  def.stack_max = def.stack_max or 1
  def.node_placement_prediction = def.node_placement_prediction or ""
  def.can_dig_when_inventory = type(def.can_dig_when_inventory) ~= "boolean" and true or def.can_dig_when_inventory
  -- functions
  def.after_place_node = def.after_place_node or function(pos, placer, itemstack, pointed_thing)
    after_place_node(pos, placer, itemstack, pointed_thing)
    storage.on_construct(pos, def.formspec_width, def.formspec_height)
  end
  def.on_dig = def.on_dig or function(pos, node, digger)
    on_dig(pos, node, digger, def.formspec_width, def.formspec_height)
  end
  def.preserve_metadata = def.preserve_metadata or function(pos, oldnode, oldmeta, drops)
    preserve_metadata(pos, oldnode, oldmeta, drops, def.formspec_width, def.formspec_height)
  end
  def._on_use_item = function(player, itemstack, pointed_thing)
    if not (pointed_thing and pointed_thing.under) then return end
    local pos = pointed_thing.under
    local node = minetest.get_node(pos)
    if not minimal.in_group(node,"storage") then return end
    if minimal.in_group(node,"no_packdump") then return end
    local pname = player:get_player_name()
    if minetest.is_protected(pos,pname) then return end
    show_packdump_formspec(pos, player, itemstack, 
      (def.can_dump and not minimal.in_group(pos,"no_dump")), 
      (def.can_pack and not minimal.in_group(pos,"no_pack")))
  end
  -- register backpack through storage.register_storage()
  storage.register_storage(":backpacks:backpack_"..name,def)
end