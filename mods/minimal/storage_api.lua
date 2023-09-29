storage = {}

local modname = "minimal/storage_api.lua"

local function S(...)
  return minimal.S(...)
end

function storage.get_storage_formspec(pos, w, h, meta)
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
    "button[5,"..label_offset..";1,0.25;labelset;Set]",
		--"label["..craftedby_offset_x..","..trash_offset..";Crafted by:]",
		--"label["..creator_offset_x..","..(trash_offset+.35)..";"..creator.."]",
	}
  if (creator and creator ~= '') then
    formspec[#formspec + 1] = "label["..craftedby_offset_x..","..trash_offset..";Crafted by:]"
    formspec[#formspec + 1] = "label["..creator_offset_x..","..(trash_offset+.35)..";"..creator.."]"
  end
	return table.concat(formspec, "")
end


local function can_interact(pos, name)
	if minetest.is_protected(pos, name) then
    -- you are NOT the owner!
    return false
  end
  -- returns true if the node isn't protected from the player lol
  return true
end

function storage.can_dig(pos,player,can_grab)
  local inv_empty = true
  
  if not can_grab then
    local inv = minetest.get_meta(pos):get_inventory()
    inv_empty = inv:is_empty("main")
  end
  
  return can_interact(pos, player) and inv_empty
end

function storage.get_inventory(pos)
  if (type(pos.x) == "number" and type(pos.y) == "number" and type(pos.z) == "number") then
    return minetest.get_meta(pos):get_inventory()
  elseif (type(pos["get_inventory"]) == "function") then
    -- allow meta as an argument
    return pos:get_inventory()
  end
end

function storage.on_construct(pos, width, height)
	local meta = minetest.get_meta(pos)

	local form = storage.get_storage_formspec(pos, width, height, meta)
	meta:set_string("formspec", form)

	local inv = storage.get_inventory(meta)
	inv:set_size("main", width*height)
end

function storage.on_receive_fields(pos, formname, fields, sender, width, height)
  local label = fields.label
  if (label and (minetest.is_player(sender) and can_interact(pos,sender))) then
    local meta = minetest.get_meta(pos)
    local cleanlabel = minimal.sanitize_string(label)
    meta:set_string('label', cleanlabel)
    minimal.infotext_merge(pos,'Label: '..cleanlabel, meta)
    storage.on_construct(pos, width, height)
  end
end

function storage.dump_inventory(pos)
  assert(type(pos) == "table","mods/"..modname.."dump_inventory: Invalid pos provided!")
  assert( (type(pos.x) == "number" and type(pos.y) == "number" and type(pos.z) == "number"),
    "mods/"..modname.."dump_inventory: Invalid pos provided!")
  
  -- verify if the dumped inventory belongs to a storage container
  local stor_node = minetest.get_node(pos)
  if minetest.get_item_group(stor_node.name,"storage") == 0 then
    return
  end
  
  -- don't attempt to empty out an empty inventory
  local inv = minetest.get_meta(pos):get_inventory()
  if inv:is_empty("main") then
    return
  end
  
  -- empty it out!
  local dump_pos = {x = pos.x, y = pos.y + 1, z = pos.z}
  for _,itemstack in pairs(inv:get_list("main")) do
    itemstack = inv:remove_item("main",itemstack)
    
    -- drop items
    minetest.item_drop(itemstack, nil, dump_pos)
  end
end

local function to_burnt(pos)
  local stor_node = minetest.get_node(pos)
  if minetest.get_item_group(stor_node.name,"storage") == 0 then
    return
  end
  stor_node = minetest.registered_nodes[stor_node.name]
  local burnable = stor_node.burnable
  local burn_to = stor_node.burn_to
  if (type(burn_to) ~= "string" or not burnable) then
    -- can't be burned lol
    return
  end
  if burn_to == "" then
    burn_to = "air"
  end
  burn_to = minetest.registered_nodes[burn_to]
  if not burn_to then
    -- could not find burn_to node
    return
  end
  -- check if burn_to node is a storage
  if minetest.get_item_group(burn_to.name,"storage") == 0 then
    if type(stor_node["_on_dump"]) == "function" then
      -- run on_dump code
      stor_node._on_dump(pos)
    end
    -- do not continue code
    return
  end
  
  -- get formspec width and height
  local width = stor_node.formspec_width or 8
  local height = stor_node.formspec_height or 4
  
  local meta = minetest.get_meta(pos) -- set formspec_width and formspec_height as meta_int
  meta:set_int("formspec_width",width)
  meta:set_int("formspec_height",height)
  
  -- does the inventory saving for me :D \/ (as well as saves owner, label, and the width and height metadata)
  minimal.switch_node(pos,{name = burn_to.name})
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
    -- other values
    protected = false, -- whether or not the storage placed is protected
    can_dig_when_inventory = false, -- can be dug when the storage has inventory
    burn_to = "minimal:burnt_storage_pile",
    -- functions
    allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
      if can_interact(pos, player) then
        return count
      end
      return 0
    end,
    
    allow_metadata_inventory_put = function(pos, listname, index, stack, player)
      if can_interact(pos, player)
      and minetest.get_item_group(stack:get_name(),"backpack") == 0 then
        return stack:get_count()
      end
      return 0
    end,

    allow_metadata_inventory_take = function(pos, listname, index, stack, player)
      if can_interact(pos, player) then
        return stack:get_count()
      end
      return 0
    end,

    on_blast = function(pos)
    end,
    _on_dump = function(pos)
      storage.dump_inventory(pos)
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
  
  -- remove base node_box if drawtype isn't a nodebox
  if basedef.drawtype ~= "nodebox" then
    basedef.node_box = nil
  end
  
  -- don't be silly, we don't like floats
  basedef.formspec_width = math.ceil(basedef.formspec_width)
  basedef.formspec_height = math.ceil(basedef.formspec_height)
  
  -- formspec details (necessary for some functions)
  local width = basedef.formspec_width
  local height = basedef.formspec_height
  -- adding further functions
  if not basedef.can_dig then
    basedef.can_dig = function(pos, player)
      return storage.can_dig(pos, player, basedef.can_dig_when_inventory)
    end
  end
  if not basedef.on_construct then
    basedef.on_construct = function(pos)
      storage.on_construct(pos, width, height)
    end
  end
  if not basedef.after_place_node then
    basedef.after_place_node = function(pos, placer, itemstack, pointed_thing)
      --Update formspec and infotext
      if (minetest.is_player(placer) and basedef.protected == true) then
        local p_name = placer:get_player_name() or ""
        minetest.get_meta(pos):set_string("owner", p_name)
      end
      storage.on_construct(pos, width, height)
    end
  end
  if not basedef.on_receive_fields then
    basedef.on_receive_fields = function(pos, formname, fields, sender)
      storage.on_receive_fields(pos, formname, fields, sender, width, height)
    end
  end
  
  -- if a flammable group is specified, set as burnable
  if (basedef.groups.flammable and basedef.groups.flammable > 0) then
    basedef.burnable = true
  end
  -- custom burnable
  if basedef.burnable == true then
    if not basedef.on_burn then
      basedef.on_burn = function(pos)
        to_burnt(pos)
      end
    end
    -- add "flammable" group if not specified
    local found_flammable = false
    for group_name,value in pairs(basedef.groups) do
      if (group_name == "flammable" and value > 0) then
        found_flammable = true
      end
    end
    if (found_flammable == false) then
      basedef.groups.flammable = 1
    end
  end
  
  -- register the node
  minetest.register_node(name,basedef)
end

-- burnt storage pile code
local burnt_storage = {
  description = S("Burnt Storage Pile"),
  tiles = {"minimal_burnt_pile.png"},
  
  node_box = {
    type = "fixed",
    fixed = {
      {-0.45 , -0.5, -0.45,   0.45, -0.3, 0.45}, -- first layer
      {-0.35 , -0.3, -0.35,   0.35, -0.2, 0.35},
      {-0.2 , -0.2, -0.2,   0.2, -0.15, 0.2},
    },
  },
  
  groups = {burnt = 1},
  
  on_construct = function(pos)
    local meta = minetest.get_meta(pos)
    local width = meta:get_int("formspec_width")
    local height = meta:get_int("formspec_height")
    if (width ~= 0 and height ~= 0) then
      storage.on_construct(pos,width,height)
    else
      storage.on_construct(pos,8,4)
    end
  end,
  allow_metadata_inventory_put = function(pos, listname, index, stack, player)
    -- do not allow players to use the burnt storage
    return 0
  end,
  -- make after_place_node and on_receive_fields nil
  after_place_node = function()
  end,
  on_receive_fields = function()
  end,
}

storage.register_storage("minimal:burnt_storage_pile",burnt_storage)