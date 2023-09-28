storage = {}

local modname = "storage"

local S = minetest.get_translator("storage")

local function get_storage_formspec(pos, w, h, meta)
	local creator = meta:get_string('creator')
  local label = minimal.sanitize_string(meta:get_string('label'))
	minimal.infotext_merge(pos, 'Label: '..label, meta)
	local formspec_size_h = 3.85 + h
	local main_offset = 0.25 + h
	local trash_offset = 0.45 + h + 2
	local label_offset = trash_offset + .35
	local creator_offset_x =  (3*(30-string.len(creator))/30/2) + 5
	local craftedby_offset_x = 6.05 -- 3*(30-string.len('crafted by'))/30/2 + 5

	local formspec = {
		"size[8,"..formspec_size_h.."]",
		"list[current_name;main;0,0;"..w..","..h.."]",
		"list[current_player;main;0,"..main_offset..";8,2]",
		"listring[current_name;main]",
		"listring[current_player;main]",
		"list[detached:creative_trash;main;0,"..trash_offset..";1,1;]",
		"image[0.05,"..(trash_offset+.10)..
		   ";0.8,0.8;creative_trash_icon.png]",
		"field[1.5,"..label_offset..";4,1;label;Label:;"..label.."]",
		"field_close_on_enter[label;false]",
		--"label["..craftedby_offset_x..","..trash_offset..";Crafted by:]",
		--"label["..creator_offset_x..","..(trash_offset+.35)..";"..creator.."]",
	}
  if (creator and creator ~= '') then
    formspec[#formspec + 1] = "label["..craftedby_offset_x..","..trash_offset..";Crafted by:]"
    formspec[#formspec + 1] = "label["..creator_offset_x..","..(trash_offset+.35)..";"..creator.."]"
  end
	return table.concat(formspec, "")
end


local function is_owner(pos, name)
	if minetest.is_protected(pos, name) then
    -- you are NOT the owner!
    return false
  end
  -- returns true if the node isn't protected from the player lol
  return true
end

local on_construct = function(pos, width, height)
	local meta = minetest.get_meta(pos)

	local form = get_storage_formspec(pos, width, height, meta)
	meta:set_string("formspec", form)

	local inv = meta:get_inventory()
	inv:set_size("main", width*height)
end

local on_receive_fields = function(pos, formname, fields, sender, width, height)
  local label = fields.label
  if (label and (minetest.is_player(sender) and is_owner(pos,sender))) then
    local meta = minetest.get_meta(pos)
    local cleanlabel = minimal.sanitize_string(label)
    meta:set_string('label', cleanlabel)
    minimal.infotext_merge(pos,'Label: '..cleanlabel, meta)
    on_construct(pos, width, height)
  end
end

function storage.register_storage(name,def)
  assert(type(name) == "string","mods/"..modname..".register_storage: No string provided for name!")
  assert(type(def) == "table","mods/"..modname..".register_storage: No table provided for definition!")
  
  local basedef = {
    drawtype = "nodebox",
    paramtype = "light",
    stack_max = minimal.stack_max_bulky,
    node_box = {
      type = "fixed",
      fixed = {
        {-0.375, -0.5, -0.375, 0.375, -0.375, 0.375},
        {-0.375, 0.375, -0.375, 0.375, 0.5, 0.375},
        {-0.4375, -0.375, -0.4375, 0.4375, -0.25, 0.4375},
        {-0.4375, 0.25, -0.4375, 0.4375, 0.375, 0.4375},
        {-0.5, -0.25, -0.5, 0.5, 0.25, 0.5},
      }
		},
    groups = {dig_immediate = 3, storage = 1},
    -- formspec
    formspec_width = 8,
    formspec_height = 4,
    -- functions
    can_dig = function(pos, player)
      local inv = minetest.get_meta(pos):get_inventory()
      return is_owner(pos, name) and inv:is_empty("main")
    end,
    
    allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
      if is_owner(pos, player) then
        return count
      end
      return 0
    end,
    
    allow_metadata_inventory_put = function(pos, listname, index, stack, player)
      if is_owner(pos, player:get_player_name())
      and not string.match(stack:get_name(), "backpacks:") then
        return stack:get_count()
      end
      return 0
    end,

    allow_metadata_inventory_take = function(pos, listname, index, stack, player)
      if is_owner(pos, player) then
        return stack:get_count()
      end
      return 0
    end,

    on_blast = function(pos)
    end,
  }
  
  -- add stuff from definition table
  for var_name,var in pairs(def) do
    if (var_name == "groups") then
      basedef.groups = minimal.merge_tables(basedef.groups,var)
    else
      basedef[var_name] = var
    end
  end
  
  -- formspec details (necessary for some functions)
  local width = basedef.formspec_width
  local height = basedef.formspec_height
  -- adding further functions
  if not basedef.on_construct then
    basedef.on_construct = function(pos)
      on_construct(pos, width, height)
    end
  end
  if not basedef.after_place_node then
    basedef.after_place_node = function(pos, placer, itemstack, pointed_thing)
      --Update formspec and infotext
      on_construct(pos, width, height)
    end
  end
  if not basedef.on_receive_fields then
    basedef.on_receive_fields = function(pos, formname, fields, sender)
      on_receive_fields(pos, formname, fields, sender, width, height)
    end
  end
  
  -- register the node
  minetest.register_node(name,basedef)
end